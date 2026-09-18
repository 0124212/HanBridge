"""WorkBuddy translation backend — spends Dad's WorkBuddy (Tencent TokenHub)
token quota via any OpenAI-compatible `chat/completions` endpoint.

Configuration (environment variables, never committed):
    WORKBUDDY_API_BASE  e.g. https://tokenhub-intl.tencentcloudmaas.com/v1
                        or the full .../v1/chat/completions URL
                        (Token Plan example:
                        https://tokenhub-intl.tencentcloudmaas.com/plan/v3)
    WORKBUDDY_API_KEY   Tencent Cloud API key with TokenHub/Token Plan scope
    WORKBUDDY_MODEL     exact model ID, e.g. deepseek-v4-pro
    WORKBUDDY_TIMEOUT   seconds per request (default 120)
    WORKBUDDY_TEMPERATURE (default 0.1)
    WORKBUDDY_MAX_TOKENS  (default 2000, 0 = omit)

LLM-style backend: entities/glossary go in the prompt, verified after
the fact by `Translator` — so `uses_placeholder_protection = False`.
"""

from __future__ import annotations

import logging
import time
from collections.abc import Sequence

import requests

from palimpsest.translate.backend import Cost, TranslationContext, TranslationResult

log = logging.getLogger(__name__)

_LANG_NAMES = {
    "zh": "Chinese",
    "en": "English",
    "ko": "Korean",
    "ja": "Japanese",
    "es": "Spanish",
    "fr": "French",
    "de": "German",
    "ru": "Russian",
    "pt": "Portuguese",
    "it": "Italian",
    "ar": "Arabic",
    "th": "Thai",
    "vi": "Vietnamese",
}


def _lang_name(code: str) -> str:
    return _LANG_NAMES.get(code, code)


def _completions_url(base: str) -> str:
    base = base.rstrip("/")
    if base.endswith("/chat/completions"):
        return base
    return base + "/chat/completions"


class WorkbuddyBackend:
    name = "workbuddy"
    prefers_batch = True
    uses_placeholder_protection = False

    def __init__(
        self,
        api_base: str,
        api_key: str,
        model: str,
        timeout: float = 120.0,
        temperature: float = 0.1,
        max_tokens: int = 2000,
        attempts: int = 2,
        retry_pause: float = 2.0,
        max_batch: int = 10,
    ):
        if not api_base or not api_key or not model:
            raise ValueError("WORKBUDDY_API_BASE, WORKBUDDY_API_KEY and WORKBUDDY_MODEL are all required")
        self.url = _completions_url(api_base)
        self.api_key = api_key
        self.model = model
        self.timeout = timeout
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.attempts = attempts
        self.retry_pause = retry_pause
        self.max_batch = max_batch

    def _build_messages(self, texts: Sequence[str], ctx: TranslationContext, batch: bool = False) -> list[dict]:
        target = _lang_name(ctx.target_lang)
        source = _lang_name(ctx.source_lang)

        entity_hint = ""
        if ctx.entities:
            entity_hint = f"\nProtected entities (keep verbatim): {', '.join(ctx.entities[:20])}"

        glossary_hint = ""
        if ctx.glossary:
            pairs = [f"{k} → {v}" for k, v in list(ctx.glossary.items())[:20]]
            glossary_hint = "\nGlossary:\n" + "\n".join(pairs)

        if batch:
            numbered = "\n".join(f"[{i+1}] {t}" for i, t in enumerate(texts))
            user = (
                f"Translate each line from {source} to {target}. "
                f"Keep the [N] prefix. Translate only the text, keep all formatting."
                f"{entity_hint}{glossary_hint}\n\n{numbered}"
            )
        else:
            user = (
                f"Translate the following text from {source} to {target}. "
                f"Keep all formatting, line breaks, and structure. "
                f"Return ONLY the translation, no explanations."
                f"{entity_hint}{glossary_hint}\n\n{texts[0]}"
            )
        return [
            {"role": "system", "content": "You are a professional translator. Output only the translation."},
            {"role": "user", "content": user},
        ]

    def _call(self, texts: Sequence[str], ctx: TranslationContext, batch: bool) -> str | None:
        payload: dict = {
            "model": self.model,
            "messages": self._build_messages(texts, ctx, batch=batch),
            "temperature": self.temperature,
        }
        if self.max_tokens and self.max_tokens > 0:
            payload["max_tokens"] = self.max_tokens
        resp = requests.post(
            self.url,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=self.timeout,
        )
        resp.raise_for_status()
        data = resp.json()
        choices = data.get("choices") or []
        if not choices:
            return None
        content = (choices[0].get("message") or {}).get("content")
        return content.strip() if content else None

    def translate(self, text: str, ctx: TranslationContext) -> TranslationResult:
        last: str | None = None
        for attempt in range(self.attempts):
            try:
                result = self._call([text], ctx, batch=False)
                if result:
                    return TranslationResult(text=result, status="ok")
                last = "empty response"
            except Exception as e:
                last = str(e)
            time.sleep(self.retry_pause * (attempt + 1))
        return TranslationResult(text=None, status="failed", detail=last)

    def translate_batch(
        self, texts: Sequence[str], ctx: TranslationContext
    ) -> list[TranslationResult]:
        if len(texts) <= self.max_batch:
            try:
                result = self._call(texts, ctx, batch=True)
                if result:
                    parts = []
                    for line in result.split("\n"):
                        line = line.strip()
                        if line.startswith("[") and "]" in line:
                            parts.append(line.split("]", 1)[1].strip())
                    if len(parts) == len(texts):
                        return [TranslationResult(text=p, status="ok") for p in parts]
            except Exception:
                pass
        return [self.translate(t, ctx) for t in texts]

    def estimate(self, texts: Sequence[str], ctx: TranslationContext) -> Cost | None:
        total_chars = sum(len(t) for t in texts)
        # Rough heuristic: ~2 chars per token for CJK-heavy text
        tokens = max(1, total_chars // 2)
        return Cost(input_tokens=tokens, output_tokens=tokens, usd=None)
