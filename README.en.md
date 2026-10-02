# palimpsest-cn — Quick Guide (English)

Translate Chinese documents (PDF / Word / PowerPoint / Excel) into **Korean or English**
with the **original layout preserved** — same fonts, positions, tables, and images.
Only the words change language.

> SmartScreen blocked the zip? Right-click it → Properties → check Unblock (or `Unblock-File -Recurse .` in PowerShell). No admin needed — user-local only (HKCU + %LOCALAPPDATA%, never HKLM). / SmartScreen 경고 시 zip 우클릭 → 속성 → 차단 해제 (또는 PowerShell `Unblock-File -Recurse .`). 관리자 불필요 — 현재 사용자 영역만 사용 (HKCU + %LOCALAPPDATA%, HKLM 기록 없음).

## 1. Requirements

- Windows 10/11, macOS, or Linux
- Python 3.11 or newer
- Your document file (`.pdf`, `.docx`, `.pptx`, `.xlsx`)
- For use in China (no VPN): Dad's WorkBuddy tokens (recommended) **or** a free Baidu Translate key **or** Ollama for fully offline use

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

### Check the endpoint first (10 seconds, costs almost nothing)

Run this **before** translating real documents. It translates one word and
proves the base URL, the key, and the model ID are all correct:

**Windows (PowerShell):**

```powershell
$base = $env:WORKBUDDY_API_BASE.TrimEnd('/')
if (-not $base.EndsWith('/chat/completions')) { $base += '/chat/completions' }
$body = @{ model = $env:WORKBUDDY_MODEL
  messages = @(@{ role = 'user'; content = 'Translate to Korean: 你好' })
  max_tokens = 20; temperature = 0.1 } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri $base -Method Post `
  -Headers @{ Authorization = "Bearer $($env:WORKBUDDY_API_KEY)" } `
  -ContentType 'application/json' -Body $body
```

**macOS / Linux:**

```bash
base="${WORKBUDDY_API_BASE%/}"
[[ "$base" == */chat/completions ]] || base="$base/chat/completions"
curl -s "$base" -H "Authorization: Bearer $WORKBUDDY_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"$WORKBUDDY_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Translate to Korean: 你好\"}],\"max_tokens\":20,\"temperature\":0.1}"
```

| Response | Meaning | Next step |
|----------|---------|-----------|
| `안녕하세요` in the reply | Base URL ✓ key ✓ model ✓ — go translate | Nothing, it works |
| `401` / `403` | Key wrong, scope missing, or different auth | Check the key scope in the Tencent console |
| `404` | Base URL or model ID wrong | Copy both character-by-character from the console |
| Timeout / can't connect | Network from this machine | Try the other endpoint host (intl vs China) |

## 5. Baidu setup (China, no tokens)

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

## 6. Ollama setup (fully offline alternative)

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

## 7. Translate (easiest way — wrapper script)

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

No keys at all? Drop `--backend` — the wrapper defaults to `translatepy`
(free, no key, verified Chinese→Korean above). Lower quality than Baidu or
WorkBuddy, but it works out of the box:

```bash
python skills/translate-doc/translate.py "document.pdf"
```

Output goes to a `translated/` folder next to your file,
e.g. `translated/document.ko.pdf`.

## 8. Translate (direct CLI)

The wrapper above is recommended because it writes the config for you.
If you use `palimpsest` directly, create a `palimpsest.toml`
in the same folder as your document:

```toml
[language]
source = "zh"
target = "ko"        # or "en" for English

[backend]
name = "workbuddy"   # or "baidu", "ollama", "translatepy", "google"
fallback = "translatepy"

[paths]
source_dir = "."
output_dir = "./translated"
```

Then run:

```bash
palimpsest translate "document.pdf" --backend workbuddy -o "translated/document.ko.pdf"
palimpsest translate "slides.pptx" --backend workbuddy --dual -o "translated/slides.ko.pptx"
```

## 9. Good to know

- **Layout is preserved.** Fonts, positions, tables, and images stay where they were.
- **Code, numbers, and names are protected.** Technical terms (e.g. CNN, AlphaFold, HumanEval) and amounts stay verbatim.
- **Failed paragraphs stay in Chinese** instead of disappearing — nothing is silently dropped.
- **Scanned PDFs** are handled with OCR automatically (needs `ocrmypdf`, included in `[all]`).
- **Google Translate does not work in China.** Use `workbuddy`, `baidu`, `ollama`, or `translatepy`.

## 10. What stays untouched (diagrams, tables, fonts)

Only the words change. Everything else survives because of how the tool works:

- **Word / PowerPoint / Excel** — the file is unzipped and *only text runs*
  are rewritten. Images, diagrams, shapes, charts, vectors, positions,
  fonts, and styles are copied through byte-identical (compression and
  timestamps preserved). Tables keep their grid — only the cell text is
  translated.
- **PDF** — text is cleared *without touching images or line art*, and the
  translation is redrawn at the original coordinates with real embedded
  fonts. Multi-column pages and tables keep their geometry.
- **Numbers, names, code** stay verbatim (e.g. CNN, AlphaFold, amounts).
- **Nothing is silently dropped.** A paragraph that fails to translate stays
  in Chinese and is reported (`failures=0` means a clean run).
- **Pure-Chinese paragraphs are translated**, not skipped — including titles
  and headings with no English in them.

Verified 2026-09-21: a Chinese Word file (3 paragraphs incl. pure-Chinese
titles + a 2×2 table) → Korean, 7/7 text nodes, table intact, 0 lost — with
both the free `translatepy` backend and Gemini.

One honest limit: PDF output needs a Korean-capable font on the machine. If
Korean renders as boxes, install one (e.g. Noto Sans CJK KR) and re-run.

## 11. Troubleshooting

| Problem | Fix |
|---------|-----|
| `BAIDU_APP_ID and BAIDU_SECRET_KEY required` | Set the env vars (step 5) and reopen the terminal |
| `WORKBUDDY_API_BASE ... required` | Set the env vars (step 4) and reopen the terminal |
| `unknown backend` | Use one of: `workbuddy baidu ollama translatepy google gemini anthropic` |
| `File not found` | Put the full path in quotes, e.g. `"C:\Users\name\file.pdf"` |
| Google errors / rate limits | Switch to `--backend baidu` or `--backend translatepy` |
| Python too old | Install Python 3.11+ from https://www.python.org/downloads/ |
