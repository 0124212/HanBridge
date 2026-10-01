"""translatepy backend — uses the `translate` package which routes through
multiple free translation services (MyMemory, LibreTranslate, etc.).

No API key required. Works as a reliable fallback when Google is rate-limited.
Uses placeholder protection (phrase-level API).
"""

from __future__ import annotations

import time
from collections.abc import Sequence

from palimpsest.translate.backend import Cost, TranslationContext, TranslationResult

OFFLINE_MSG = "网络连不上翻译服务，请稍后再试"


class OfflineError(RuntimeError):
    """Network unreachable — message already in friendly Chinese."""


class TranslatepyBackend:
    name = "translatepy"
    prefers_batch = False
    uses_placeholder_protection = True

    def __init__(self, attempts: int = 3, retry_pause: float = 1.0, max_batch: int = 20):
        self.attempts = attempts
        self.retry_pause = retry_pause
        self.max_batch = max_batch

    def _do_translate(self, text: str, source: str, target: str) -> str | None:
        from translate import Translator
        t = Translator(from_lang=source, to_lang=target)
        try:
            result = t.translate(text)
        except (TimeoutError, ConnectionError, OSError) as e:
            # OSError covers requests' ConnectionError/Timeout (via RequestException).
            raise OfflineError(f"{OFFLINE_MSG}（{e}）") from e
        return result if result else None

    def translate(self, text: str, ctx: TranslationContext) -> TranslationResult:
        last: str | None = None
        for attempt in range(self.attempts):
            try:
                result = self._do_translate(text, ctx.source_lang, ctx.target_lang)
                if result:
                    return TranslationResult(text=result, status="ok")
                last = "empty response"
            except OfflineError as e:
                last = str(e)
                if attempt >= 1:
                    break  # single retry only for network errors
            except Exception as e:
                last = str(e)
            time.sleep(self.retry_pause * (attempt + 1))
        return TranslationResult(text=None, status="failed", detail=last)

    def translate_batch(
        self, texts: Sequence[str], ctx: TranslationContext
    ) -> list[TranslationResult]:
        return [self.translate(t, ctx) for t in texts]

    def estimate(self, texts: Sequence[str], ctx: TranslationContext) -> Cost | None:
        total_chars = sum(len(t) for t in texts)
        return Cost(input_tokens=total_chars, output_tokens=total_chars, usd=None)
