# HanBridge Portable — 3 steps

No install. No admin rights needed.

## How to use

1. **Unzip** — extract the zip to a SHORT path, e.g. `C:\hanbridge`.
   (Paths over ~100 chars break the embedded Python. Avoid deep Desktop folders.)
2. **Unblock** — right-click `HanBridge.bat` → Properties → check
   **Unblock** at the bottom → OK.
   (If SmartScreen warns, click "More info" → "Run anyway".)
3. **Double-click** — double-click `HanBridge.bat` to open the translator window.
   Or **drag a PDF onto** the `HanBridge.bat` icon to translate it directly.

## Where do outputs go?

- Translated files land in a **`translated` folder next to your original**.
  E.g. `report.pdf` → `translated\report-韩文版.pdf` plus a bilingual对照 PDF.
- Scanned/image PDFs are OCR'd automatically (incl. Chinese recognition).

## Good to know

- **Internet required** — translation uses the free translatepy backend.
- If WorkBuddy tokens are set on the machine, they are used first (else free).
- Default target language is Korean.
