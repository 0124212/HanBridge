"""Baidu Translate backend — China-native, no VPN required.

Free tier: 50,000 chars/day. Requires APP_ID + SECRET_KEY from
https://fanyi-api.baidu.com/product/11

Uses placeholder protection (phrase-level API, same as Google).
"""

from __future__ import annotations

import hashlib
import random
import time
from collections.abc import Sequence

import requests

from palimpsest.translate.backend import Cost, TranslationContext, TranslationResult

_LANG_MAP = {
    "zh": "zh",
    "en": "en",
    "ko": "kor",
    "ja": "jp",
    "es": "spa",
    "fr": "fra",
    "de": "de",
    "ru": "ru",
    "pt": "pt",
    "it": "it",
    "ar": "ara",
    "th": "th",
    "vi": "vie",
}


def _baidu_lang(code: str) -> str:
    return _LANG_MAP.get(code, code)


class BaiduBackend:
    name = "baidu"
    prefers_batch = False
    uses_placeholder_protection = True

    API_URL = "https://fanyi-api.baidu.com/api/trans/vip/translate"

    def __init__(
        self,
        app_id: str,
        secret_key: str,
        attempts: int = 3,
        retry_pause: float = 1.0,
        max_batch: int = 20,
    ):
        self.app_id = app_id
        self.secret_key = secret_key
        self.attempts = attempts
        self.retry_pause = retry_pause
        self.max_batch = max_batch

    def _sign(self, query: str, salt: str) -> str:
        raw = f"{self.app_id}{query}{salt}{self.secret_key}"
        return hashlib.md5(raw.encode("utf-8")).hexdigest()

    def _call_api(self, query: str, source: str, target: str) -> str | None:
        salt = str(random.randint(32768, 65536))
        sign = self._sign(query, salt)
        resp = requests.post(
            self.API_URL,
            data={
                "q": query,
                "from": _baidu_lang(source),
                "to": _baidu_lang(target),
                "appid": self.app_id,
                "salt": salt,
                "sign": sign,
            },
            timeout=30,
        )
        resp.raise_for_status()
        data = resp.json()
        if "error_code" in data:
            raise RuntimeError(f"Baidu error {data['error_code']}: {data.get('error_msg', '')}")
        return "".join(r.get("dst", "") for r in data.get("trans_result", []))

    def translate(self, text: str, ctx: TranslationContext) -> TranslationResult:
        last: str | None = None
        for attempt in range(self.attempts):
            try:
                result = self._call_api(text, ctx.source_lang, ctx.target_lang)
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
        # Baidu supports newline-separated batch (up to 6000 chars total)
        combined = "\n".join(texts)
        if len(combined) <= 6000:
            try:
                result = self._call_api(combined, ctx.source_lang, ctx.target_lang)
                if result:
                    parts = result.split("\n")
                    # Pad if Baidu merged/split differently
                    while len(parts) < len(texts):
                        parts.append(texts[len(parts)])
                    return [
                        TranslationResult(text=p, status="ok")
                        for p in parts[: len(texts)]
                    ]
            except Exception:
                pass
        # Fallback: individual calls
        return [self.translate(t, ctx) for t in texts]

    def estimate(self, texts: Sequence[str], ctx: TranslationContext) -> Cost | None:
        total_chars = sum(len(t) for t in texts)
        # Baidu free tier is free; paid is ~49 RMB/1M chars
        return Cost(input_tokens=total_chars, output_tokens=total_chars, usd=None)
