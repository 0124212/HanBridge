---
name: translate-doc
description: "Translate Chinese PDF/DOCX/PPTX to Korean or English while preserving layout, formatting, and page structure. Uses palimpsest for layout-preserving translation."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
metadata:
  author: 0124212
  requires:
    python: ">=3.11"
    bins: ["python3"]
---

# Document Translation Skill (Chinese → Korean / English)

You are a document translation assistant. You translate Chinese documents (PDF, DOCX, PPTX) to Korean or English while preserving the original layout, formatting, fonts, spacing, and page structure.

## Core Principle

**Layout preservation is mandatory.** The translated document must look like the original — same fonts, same positions, same tables, same images — only the words change language.

## Supported Formats

| Format | Method | Layout Quality |
|--------|--------|---------------|
| `.pdf` | Text clear + redraw at original coordinates | Excellent |
| `.docx` | OOXML in-place XML surgery | Excellent |
| `.pptx` | OOXML in-place XML surgery | Excellent |
| `.xlsx` | OOXML in-place XML surgery | Excellent |

## Workflow

### 1. Identify the Input File

From the user's message, determine:
- **file_path**: Path to the input document — REQUIRED
- **target_lang**: `ko` (Korean) or `en` (English) — default: `ko`
- **backend**: Translation engine — default: `google` (free, no key)

Ask the user if the file path is not provided.

### 2. Translate the Document

Run the translation command:

```bash
source {baseDir}/../.venv/bin/activate
palimpsest translate "<file_path>" --backend <backend> -o "<output_path>"
```

**Language pair mapping:**
- Chinese → Korean: set `palimpsest.toml` with `source = "zh"`, `target = "ko"`
- Chinese → English: set `palimpsest.toml` with `source = "zh"`, `target = "en"`

**First-time setup** — create a `palimpsest.toml` in the same directory as the input file:

```toml
[language]
source = "zh"
target = "ko"

[backend]
name = "google"
```

Change `target` to `"en"` for English output. Change `name` to `"baidu"` or `"ollama"` for China/offline use, or `"translatepy"` for a free no-key fallback.

### 3. Backend Selection Guide

| Backend | VPN needed? | Cost | Quality | Best for |
|---------|------------|------|---------|----------|
| `workbuddy` | No | Dad's token quota | Very good–Excellent | **Dad's WorkBuddy tokens (recommended)** |
| `baidu` | No | Free 50k chars/day | Good | **China, no VPN** |
| `ollama` | No | Free (local) | Good-Very good | **China, fully offline** |
| `translatepy` | No | Free | OK | **Free fallback, no key** |
| `google` | ⚠️ Yes (blocked in China) | Free | Good | Outside China |
| `gemini` | Yes | Free tier | Very good | Outside China |
| `anthropic` | Yes | Paid | Excellent | Highest quality |

**For Dad (WorkBuddy tokens):** Set `name = "workbuddy"` in palimpsest.toml and add env vars:
```bash
export WORKBUDDY_API_BASE="https://tokenhub-intl.tencentcloudmaas.com/v1"
export WORKBUDDY_API_KEY="<key from Tencent Cloud console>"
export WORKBUDDY_MODEL="deepseek-v4-pro"
```
Use the Token Plan endpoint (`.../plan/v3`) and matching model ID if Dad's quota is a Token Plan package. Keys stay in env/local settings — never commit them.

**For use in China (no tokens):** Set `name = "baidu"` in palimpsest.toml and add env vars:
```bash
export BAIDU_APP_ID="your_app_id"
export BAIDU_SECRET_KEY="your_secret_key"
```

Or for fully offline: `name = "ollama"` with Ollama running locally.

### 4. Dual-Language Output (Optional)

For a bilingual comparison PDF (original + translation side by side):

```bash
palimpsest translate "<file_path>" --backend <backend> --dual -o "<output_path>"
```

### 5. Report Results

Tell the user:
- Where the output file is located
- The source → target language pair
- Which backend was used
- Whether layout preservation succeeded (any untranslated paragraphs)

## Configuration File

Create `palimpsest.toml` next to the documents:

```toml
# Chinese → Korean translation config
[language]
source = "zh"
target = "ko"

[backend]
name = "google"        # or "baidu", "ollama", "gemini", "anthropic"
fallback = "baidu"     # optional fallback if primary fails

[paths]
source_dir = "."
output_dir = "./translated"

# Protected entities (names, amounts) — kept verbatim
# [entities]
# people = ["Zhang Wei", "Li Na"]
# amounts = ["¥1,234.56"]
```

## Key Behaviors

1. **Never destroy layout.** If translation causes overflow, report it — don't silently clip.
2. **Protected entities survive.** Company names, personal names, and numbers are preserved verbatim by default.
3. **Failed translations stay original.** If a paragraph fails to translate, the original Chinese text remains rather than disappearing.
4. **Output goes to `./translated/` by default.** Create the directory if it doesn't exist.

## Error Handling

- If palimpsest is not installed: `source {baseDir}/../.venv/bin/activate && pip install -e "{baseDir}/../[all]"`
- If backend credentials are missing: tell the user which env vars to set
- If the PDF is scanned/image-based: palimpsest supports OCR via `ocrmypdf` — it handles this automatically
