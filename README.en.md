# palimpsest-cn — Quick Guide (English)

Translate Chinese documents (PDF / Word / PowerPoint / Excel) into **Korean or English**
with the **original layout preserved** — same fonts, positions, tables, and images.
Only the words change language.

## 1. Requirements

- Windows 10/11, macOS, or Linux
- Python 3.11 or newer
- Your document file (`.pdf`, `.docx`, `.pptx`, `.xlsx`)
- For use in China (no VPN): a free Baidu Translate key **or** Ollama for fully offline use

## 2. Install

**Windows (PowerShell):**

```powershell
git clone https://github.com/0124212/palimpsest-cn.git
cd palimpsest-cn
py -3.11 -m venv .venv
.venv\Scripts\activate
pip install -e ".[all]"
```

**macOS / Linux:**

```bash
git clone https://github.com/0124212/palimpsest-cn.git
cd palimpsest-cn
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[all]"
```

## 3. Choose a translation engine

| Engine | VPN needed? | Cost | Use when |
|--------|------------|------|----------|
| `workbuddy` | No | Dad's token quota | **Dad's WorkBuddy tokens — recommended** |
| `baidu` | No | Free 50k chars/day | **China, no VPN** |
| `ollama` | No | Free (runs on your PC) | **Fully offline** |
| `translatepy` | No | Free | Quick test, no key needed (lower quality) |
| `google` | Yes (blocked in China) | Free | Outside China only |
| `gemini` | Yes | Free tier | Outside China only |
| `anthropic` | Yes | Paid | Highest quality |

## 4. WorkBuddy setup (recommended — uses Dad's tokens)

Dad's WorkBuddy quota is Tencent Cloud TokenHub/Token Plan credit,
spent through an OpenAI-compatible endpoint. You need three values
from the Tencent Cloud console:

1. **API Base** — TokenHub: `https://tokenhub-intl.tencentcloudmaas.com/v1`
   or Token Plan: `https://tokenhub-intl.tencentcloudmaas.com/plan/v3`
   (China/Guangzhou Token Plan: `https://tokenhub.tencentcloudmaas.com/plan/v3`)
2. **API Key** — created under API Key Management, with scope covering your model.
3. **Model** — the exact model ID, e.g. `deepseek-v4-pro`
   (Token Plan: use a model ID from your plan's model list).

Set them as environment variables:

**Windows (PowerShell, permanent):**

```powershell
setx WORKBUDDY_API_BASE "https://tokenhub-intl.tencentcloudmaas.com/v1"
setx WORKBUDDY_API_KEY "paste-key-here"
setx WORKBUDDY_MODEL "deepseek-v4-pro"
```

Then close and reopen the terminal, and re-activate `.venv`.

**macOS / Linux:**

```bash
export WORKBUDDY_API_BASE="https://tokenhub-intl.tencentcloudmaas.com/v1"
export WORKBUDDY_API_KEY="paste-key-here"
export WORKBUDDY_MODEL="deepseek-v4-pro"
```

Keep the key on Dad's machine only — never paste it into chat or commit it.

## 4. Baidu setup (recommended in China)

1. Go to https://fanyi-api.baidu.com/product/11 and register.
2. Create an app and copy your **APP_ID** and **SECRET_KEY**.
3. Set them as environment variables.

**Windows (PowerShell, permanent):**

```powershell
setx BAIDU_APP_ID "your_app_id"
setx BAIDU_SECRET_KEY "your_secret_key"
```

Then close and reopen the terminal, and re-activate `.venv`.

**macOS / Linux:**

```bash
export BAIDU_APP_ID="your_app_id"
export BAIDU_SECRET_KEY="your_secret_key"
```

## 5. Ollama setup (fully offline alternative)

1. Install Ollama from https://ollama.ai
2. Pull a model:

```bash
ollama pull qwen2.5
```

3. (Optional) pick the model:

```bash
# macOS / Linux
export OLLAMA_MODEL="qwen2.5"
```

```powershell
# Windows
setx OLLAMA_MODEL "qwen2.5"
```

## 6. Translate (easiest way — wrapper script)

Activate the environment first (every new terminal):

```powershell
# Windows
.venv\Scripts\activate
```

```bash
# macOS / Linux
source .venv/bin/activate
```

Then translate:

```bash
# Chinese → Korean (default, Dad's tokens)
python skills/translate-doc/translate.py "document.pdf" --backend workbuddy

# Chinese → English
python skills/translate-doc/translate.py "document.pdf" --target en --backend workbuddy

# PowerPoint
python skills/translate-doc/translate.py "slides.pptx" --backend workbuddy

# Word
python skills/translate-doc/translate.py "report.docx" --target en --backend baidu

# Bilingual output (original + translation side by side)
python skills/translate-doc/translate.py "paper.pdf" --backend baidu --dual

# Fully offline
python skills/translate-doc/translate.py "document.pdf" --backend ollama
```

Output goes to a `translated/` folder next to your file,
e.g. `translated/document.ko.pdf`.

## 7. Translate (direct CLI)

The wrapper above is recommended because it writes the config for you.
If you use `palimpsest` directly, create a `palimpsest.toml`
in the same folder as your document:

```toml
[language]
source = "zh"
target = "ko"        # or "en" for English

[backend]
name = "baidu"       # or "ollama", "translatepy", "google"
fallback = "translatepy"

[paths]
source_dir = "."
output_dir = "./translated"
```

Then run:

```bash
palimpsest translate "document.pdf" --backend baidu -o "translated/document.ko.pdf"
palimpsest translate "slides.pptx" --backend baidu --dual -o "translated/slides.ko.pptx"
```

## 8. Good to know

- **Layout is preserved.** Fonts, positions, tables, and images stay where they were.
- **Code, numbers, and names are protected.** Technical terms (e.g. CNN, AlphaFold, HumanEval) and amounts stay verbatim.
- **Failed paragraphs stay in Chinese** instead of disappearing — nothing is silently dropped.
- **Scanned PDFs** are handled with OCR automatically (needs `ocrmypdf`, included in `[all]`).
- **Google Translate does not work in China.** Use `baidu`, `ollama`, or `translatepy`.

## 9. Troubleshooting

| Problem | Fix |
|---------|-----|
| `BAIDU_APP_ID and BAIDU_SECRET_KEY required` | Set the env vars (step 4) and reopen the terminal |
| `unknown backend` | Use one of: `google baidu ollama translatepy gemini anthropic` |
| `File not found` | Put the full path in quotes, e.g. `"C:\Users\name\file.pdf"` |
| Google errors / rate limits | Switch to `--backend baidu` or `--backend translatepy` |
| Python too old | Install Python 3.11+ from https://www.python.org/downloads/ |
