# palimpsest-cn

Layout-preserving document translation for Chinese → Korean / English.

Fork of [ianperaltahirujo/palimpsest](https://github.com/ianperaltahirujo/palimpsest) with added backends for China use (no VPN required).

## What it does

Translates Chinese PDFs, Word docs, and PowerPoint files to Korean or English **while preserving the original layout** — same fonts, same positions, same tables, same images. Only the words change language.

## Supported formats

| Format | How it works | Layout quality |
|--------|-------------|---------------|
| `.pdf` | Text cleared + redrawn at original coordinates with real embedded fonts | Excellent |
| `.docx` | OOXML zip edited in-place | Excellent |
| `.pptx` | OOXML zip edited in-place | Excellent |
| `.xlsx` | OOXML zip edited in-place | Excellent |

## Quick start

```bash
git clone https://github.com/0124212/palimpsest-cn.git
cd palimpsest-cn
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[all]"
```

## Usage

### Command line

```bash
# Chinese → Korean (default)
palimpsest translate document.pdf --backend baidu

# Chinese → English
palimpsest translate report.docx --backend baidu --target en

# Bilingual output (original + translation side by side)
palimpsest translate slides.pptx --backend baidu --dual
```

### Wrapper script (simpler)

```bash
cd skills/translate-doc

python translate.py document.pdf                           # Chinese → Korean
python translate.py document.pdf --target en               # Chinese → English
python translate.py document.pptx --backend baidu          # China, no VPN
python translate.py paper.docx --dual                      # Bilingual output
```

## Backend selection

| Backend | VPN needed? | Cost | Best for |
|---------|------------|------|----------|
| `google` | ⚠️ Yes (blocked in China) | Free | Outside China |
| `translatepy` | No | Free | Free fallback (lower quality) |
| `baidu` | No | Free 50k chars/day | **China, no VPN** |
| `ollama` | No | Free (local) | **China, fully offline** |
| `gemini` | Yes | Free tier | Outside China |
| `anthropic` | Yes | Paid | Highest quality |

### Baidu setup (recommended for China)

1. Register at https://fanyi-api.baidu.com/product/11
2. Get your APP_ID and SECRET_KEY
3. Set env vars:

```bash
export BAIDU_APP_ID="your_app_id"
export BAIDU_SECRET_KEY="your_secret_key"
```

### Ollama setup (fully offline)

1. Install Ollama: https://ollama.ai
2. Pull a model: `ollama pull qwen2.5`
3. Set env var:

```bash
export OLLAMA_MODEL="qwen2.5"
```

### Config file

Create `palimpsest.toml` next to your documents:

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

## What's new in this fork

- **Baidu Translate backend** — native China, no VPN, free tier
- **Ollama backend** — fully offline with local LLM models
- **translatepy backend** — free fallback via MyMemory/LibreTranslate
- **WorkBuddy skill** — `skills/translate-doc/` for agent integration
- **`translate.py` wrapper** — simpler CLI for non-WorkBuddy use

## Tested on

3-page Chinese coding research paper (60+ paragraphs, code blocks, tables, mixed Chinese/English content):
- Korean: 57/57 paragraphs translated, layout preserved
- English: 57/57 paragraphs translated, layout preserved

## License

Apache-2.0 (same as upstream palimpsest)
