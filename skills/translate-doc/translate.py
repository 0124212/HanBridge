#!/usr/bin/env python3
"""
translate.py — Simple wrapper around palimpsest for Chinese → Korean/English translation.

Usage:
    python translate.py <input_file> [--target ko|en] [--backend google|baidu|ollama|translatepy|workbuddy] [--no-dual]

Examples:
    python translate.py report.pdf                          # Chinese → Korean (default)
    python translate.py report.pdf --target en              # Chinese → English
    python translate.py report.pdf --no-dual                # Skip bilingual 对照 PDF
    python translate.py report.pptx --backend baidu         # Use Baidu (China, no VPN)
    python translate.py report.pptx --backend workbuddy     # Use Dad's WorkBuddy tokens
    python translate.py paper.docx --no-dual                # Korean only, no bilingual PDF
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

# Field fix: Windows consoles (cp1252/cp949, SSH without UTF-8 codepage) die with
# UnicodeEncodeError on non-ASCII prints. Force UTF-8 w/ replacement so output never crashes.
for _s in (sys.stdout, sys.stderr):
    if hasattr(_s, "reconfigure"):
        try:
            _s.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined] -- guarded by hasattr above; TextIO stub lacks it
        except Exception:
            pass

_VENV_BIN = "Scripts" if sys.platform == "win32" else "bin"
VENV_ACTIVATE = Path(__file__).resolve().parent.parent.parent / ".venv" / _VENV_BIN / "activate"
PALIMPSEST_ROOT = Path(__file__).resolve().parent.parent.parent


def ensure_palimpsest():
    """Check palimpsest is importable, install if not."""
    try:
        import palimpsest  # noqa: F401
    except ImportError:
        print("Installing palimpsest...")
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "-e", str(PALIMPSEST_ROOT) + "[all]"],
            check=True,
        )


def write_config(target_lang: str, backend: str, work_dir: Path):
    """Write a palimpsest.toml if one doesn't exist."""
    config_path = work_dir / "palimpsest.toml"
    if config_path.exists():
        # Update language target
        content = config_path.read_text()
        lines = content.split("\n")
        new_lines = []
        in_language = False
        found_target = False
        for line in lines:
            if line.strip().startswith("[language]"):
                in_language = True
            elif in_language and line.strip().startswith("target"):
                new_lines.append(f'target = "{target_lang}"')
                found_target = True
                in_language = False
                continue
            elif in_language and line.strip().startswith("["):
                if not found_target:
                    new_lines.append(f'target = "{target_lang}"')
                in_language = False
            new_lines.append(line)
        config_path.write_text("\n".join(new_lines))
    else:
        config_path.write_text(f"""# Auto-generated translation config
[language]
source = "zh"
target = "{target_lang}"

[backend]
name = "{backend}"
fallback = "translatepy"

[paths]
source_dir = "."
output_dir = "./translated"
""")


def count_pages(input_path: Path) -> int | None:
    """Best-effort PDF page count for progress display. None = unknown (office files etc.)."""
    if input_path.suffix.lower() != ".pdf":
        return None
    try:
        import fitz  # PyMuPDF, already a palimpsest dependency
        with fitz.open(str(input_path)) as doc:
            return len(doc)
    except Exception:
        pass
    try:
        from pypdf import PdfReader
        return len(PdfReader(str(input_path)).pages)
    except Exception:
        return None


def translate(
    input_file: str,
    target_lang: str = "ko",
    backend: str = "translatepy",
    dual: bool = True,
    output: str | None = None,
):
    """Run palimpsest translate."""
    input_path = Path(input_file).resolve()
    if not input_path.exists():
        print(f"Error: File not found: {input_path}")
        sys.exit(1)

    work_dir = input_path.parent
    ensure_palimpsest()
    write_config(target_lang, backend, work_dir)

    # Output path (dad-friendly: report-韩文版.pdf)
    if output:
        out_path = Path(output).resolve()
    else:
        translated_dir = work_dir / "translated"
        translated_dir.mkdir(exist_ok=True)
        suffix = "-韩文版" if target_lang == "ko" else "-英文版"
        out_path = translated_dir / f"{input_path.stem}{suffix}{input_path.suffix}"

    # Build command
    cmd = [
        sys.executable, "-m", "palimpsest.cli",
        "translate",
        str(input_path),
        "--backend", backend,
        "-o", str(out_path),
    ]
    if dual:
        cmd.append("--dual")

    print(f"Translating: {input_path.name} 正在翻译")
    print(f"  Target:  {target_lang}")
    print(f"  Backend: {backend}")
    print(f"  Output:  {out_path}")
    print(f"  Dual对照:  {'yes 是' if dual else 'no 否'}")
    pages = count_pages(input_path)
    if pages:
        print(f"正在翻译第 1 / 共 {pages} 页，请稍候... (Translating pages 1/{pages}, please wait...)")
    else:
        print("正在翻译，请稍候... (Translating, please wait...)")
    print()

    result = subprocess.run(cmd, cwd=str(work_dir))

    if result.returncode == 0:
        print(f"\n✓ Translation complete 翻译完成: {out_path}")
        if dual:
            dual_path = out_path.with_stem(out_path.stem + ".dual")
            print(f"✓ Bilingual PDF 双语对照: {dual_path}")
    else:
        print(f"\n✗ Translation failed 翻译失败 (exit code {result.returncode})")

    return result.returncode


def main():
    parser = argparse.ArgumentParser(
        description="Translate Chinese documents (PDF/DOCX/PPTX) to Korean or English",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s report.pdf                          # Chinese → Korean + bilingual 对照 PDF
  %(prog)s report.pdf --target en              # Chinese → English
  %(prog)s report.pdf --no-dual                # Korean only, skip bilingual PDF
  %(prog)s report.pptx --backend baidu         # China, no VPN
  %(prog)s paper.docx --no-dual                # No bilingual output
  %(prog)s slides.pptx -o /tmp/slides_ko.pptx # Custom output path
        """,
    )
    parser.add_argument("input", help="Input file (PDF, DOCX, PPTX)")
    parser.add_argument("-t", "--target", default="ko", choices=["ko", "en"], help="Target language (default: ko)")
    parser.add_argument("-b", "--backend", default="translatepy", choices=["google", "baidu", "ollama", "translatepy", "workbuddy", "gemini", "anthropic"], help="Translation backend (default: translatepy — free, no key, works everywhere; use workbuddy for Dad's tokens, baidu for China)")
    parser.add_argument("--dual", dest="dual", action=argparse.BooleanOptionalAction, default=True, help="Also generate bilingual 对照 PDF (default: yes; --no-dual to skip)")
    parser.add_argument("-o", "--output", help="Output file path")

    args = parser.parse_args()
    sys.exit(translate(args.input, args.target, args.backend, args.dual, args.output))


if __name__ == "__main__":
    main()
