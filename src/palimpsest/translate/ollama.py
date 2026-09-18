"""Ollama translation backend — fully offline, no API keys.

Requires a running Ollama instance with a translation-capable model
(e.g. qwen2.5, deepseek-v2, llama3). Set OLLAMA_HOST if not localhost.

Uses LLM-style prompt (no placeholder protection needed).
"""

from __future__ import annotations

import json
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


class OllamaBackend:
    name = "ollama"
    prefers_batch = True
    uses_placeholder_protection = False  # LLM handles entities via prompt

    def __init__(
        self,
        model: str = "qwen2.5",
        host: str = "http://localhost:11434",
        attempts: int = 2,
        retry_pause: float = 2.0,
        max_batch: int = 10,
    ):
        self.model = model
        self.host = host.rstrip("/")
        self.attempts = attempts
        self.retry_pause = retry_pause
        self.max_batch = max_batch

    def _build_prompt(self, texts: Sequence[str], ctx: TranslationContext, batch: bool = False) -> str:
        target = _lang_name(ctx.target_lang)
        source = _lang_name(ctx.source_lang)

        entity_hint = ""
        if ctx.entities:
            entity_hint = f"\nProtected entities (keep verbatim): {', '.join(ctx.entities[:20])}"

        glossary_hint = ""
        if ctx.glossary:
            pairs = [f"{k} → {v}" for k, v in list(ctx.glossary.items())[:20]]
            glossary_hint = f"\nGlossary:\n" + "\n".join(pairs)

        if batch:
            numbered = "\n".join(f"[{i+1}] {t}" for i, t in enumerate(texts))
            return (
                f"Translate each line from {source} to {target}. "
                f"Keep the [N] prefix. Translate only the text, keep all formatting.{entity_hint}{glossary_hint}\n\n"
                f"{numbered}"
            )
        return (
            f"Translate the following text from {source} to {target}. "
            f"Keep all formatting, line breaks, and structure. "
            f"Return ONLY the translation, no explanations.{entity_hint}{glossary_hint}\n\n"
            f"{texts[0]}"
        )

    def _call_ollama(self, prompt: str) -> str | None:
        resp = requests.post(
            f"{self.host}/api/generate",
            json={
                "model": self.model,
                "prompt": prompt,
                "stream": False,
                "options": {"temperature": 0.1},
            },
            timeout=120,
        )
        resp.raise_for_status()
        return resp.json().get("response", "").strip()

    def translate(self, text: str, ctx: TranslationContext) -> TranslationResult:
        prompt = self._build_prompt([text], ctx, batch=False)
        last: str | None = None
        for attempt in range(self.attempts):
            try:
                result = self._call_ollama(prompt)
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
            prompt = self._build_prompt(texts, ctx, batch=True)
            try:
                result = self._call_ollama(prompt)
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
        # Fallback to individual
        return [self.translate(t, ctx) for t in texts]

    def estimate(self, texts: Sequence[str], ctx: TranslationContext) -> Cost | None:
        total_chars = sum(len(t) for t in texts)
        return Cost(input_tokens=total_chars, output_tokens=total_chars, usd=None)
