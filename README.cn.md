# palimpsest-cn

Layout-preserving document translation for Chinese → Korean / English.

Fork of [ianperaltahirujo/palimpsest](https://github.com/ianperaltahirujo/palimpsest) with added backends for China use (no VPN required).

## 爸爸 3 步 / Dad's 3 steps (Windows)

1. 下载 zip 并解压 / Download zip and unzip (Code → Download ZIP)
2. 双击 `windows\setup-dad.bat` — 自动装好环境 + 桌面出现"翻译爸爸"
3. 把文件拖到"翻译爸爸"上 → `translated` 文件夹拿译文

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
| `workbuddy` | No | Dad's WorkBuddy token quota | **Recommended — Dad's tokens** |
| `baidu` | No | Free 50k chars/day | **China, no VPN** |
| `ollama` | No | Free (local) | **China, fully offline** |
| `translatepy` | No | Free | Free fallback (lower quality) |
| `google` | ⚠️ Yes (blocked in China) | Free | Outside China |
| `gemini` | Yes | Free tier | Outside China |
| `anthropic` | Yes | Paid | Highest quality |

### WorkBuddy setup (recommended — uses Dad's tokens)

Dad's WorkBuddy quota is Tencent Cloud TokenHub/Token Plan credit,
spent through an OpenAI-compatible endpoint. Three values from the
Tencent Cloud console:

1. **API Base** — TokenHub: `https://tokenhub-intl.tencentcloudmaas.com/v1`
   or Token Plan: `https://tokenhub-intl.tencentcloudmaas.com/plan/v3`
   (China/Guangzhou Token Plan: `https://tokenhub.tencentcloudmaas.com/plan/v3`)
2. **API Key** — created under API Key Management, with scope covering your model.
3. **Model** — the exact model ID, e.g. `deepseek-v4-pro`.

```bash
export WORKBUDDY_API_BASE="https://tokenhub-intl.tencentcloudmaas.com/v1"
export WORKBUDDY_API_KEY="paste-key-here"
export WORKBUDDY_MODEL="deepseek-v4-pro"
```

Keep the key on Dad's machine only — never paste it into chat or commit it.

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
name = "workbuddy"   # or "baidu", "ollama", "translatepy", "google"
fallback = "translatepy"

[paths]
source_dir = "."
output_dir = "./translated"
```

## What's new in this fork

- **CJK paragraph fix (2026-09-21)** — pure-Chinese paragraphs (no Latin
  letters at all, e.g. titles like 实验报告总结) used to be silently
  skipped in PDF/DOCX/PPTX because the translatability filter only
  recognized Latin letters. Both filters now accept any Unicode letters.
- **WorkBuddy backend** — spends Dad's Tencent TokenHub/Token Plan quota, no VPN needed
- **Baidu Translate backend** — native China, no VPN, free tier
- **Ollama backend** — fully offline with local LLM models
- **translatepy backend** — free fallback via MyMemory/LibreTranslate
- **WorkBuddy skill** — `skills/translate-doc/` for agent integration
- **`translate.py` wrapper** — simpler CLI for non-WorkBuddy use

## Tested on

3-page Chinese coding research paper (60+ paragraphs, code blocks, tables, mixed Chinese/English content):
- Korean: 57/57 paragraphs translated, layout preserved
- English: 57/57 paragraphs translated, layout preserved

Chinese DOCX → Korean (2026-09-21, after the CJK fix):
- 3 paragraphs incl. pure-Chinese titles + one 2×2 table → 7/7 text nodes,
  table intact, 0 lost — verified with both `translatepy` (free, no key)
  and Gemini backends.

## License

Apache-2.0 (same as upstream palimpsest)

## 爸爸三步用 / Dad 3 steps

1. 双击安装 / Setup: 双击 `windows\setup-dad.bat` 安装一次。

   ![setup double-click](docs/assets/dad-1.png)

2. 拖文件翻译 / Translate: 把文件拖到桌面“翻译爸爸”上（或双击“翻译爸爸窗口版”选文件）。

   ![drag file](docs/assets/dad-2.png)

3. 打开看结果 / Open result: 翻译完自动打开 `translated` 文件夹，日志在 `translated/翻译日志.txt`。

   ![open translated](docs/assets/dad-3.png)
