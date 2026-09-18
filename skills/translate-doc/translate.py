#!/usr/bin/env python3
"""
translate.py — Simple wrapper around palimpsest for Chinese → Korean/English translation.

Usage:
    python translate.py <input_file> [--target ko|en] [--backend google|baidu|ollama|translatepy|workbuddy] [--dual]

Examples:
    python translate.py report.pdf                          # Chinese → Korean (default)
    python translate.py report.pdf --target en              # Chinese → English
    python translate.py report.pptx --backend baidu         # Use Baidu (China, no VPN)
    python translate.py report.pptx --backend workbuddy     # Use Dad's WorkBuddy tokens
    python translate.py paper.docx --dual                   # Generate bilingual PDF too
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

VENV_ACTIVATE = Path(__file__).resolve().parent.parent.parent / ".venv" / "bin" / "activate"
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

[paths]
source_dir = "."
output_dir = "./translated"
""")


def translate(
    input_file: str,
    target_lang: str = "ko",
    backend: str = "google",
    dual: bool = False,
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

    # Output path
    if output:
        out_path = Path(output).resolve()
    else:
        translated_dir = work_dir / "translated"
        translated_dir.mkdir(exist_ok=True)
        suffix = f".{target_lang}"
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

    print(f"Translating: {input_path.name}")
    print(f"  Target:  {target_lang}")
    print(f"  Backend: {backend}")
    print(f"  Output:  {out_path}")
    print()

    result = subprocess.run(cmd, cwd=str(work_dir))

    if result.returncode == 0:
        print(f"\n✓ Translation complete: {out_path}")
        if dual:
            dual_path = out_path.with_stem(out_path.stem + ".dual")
            print(f"✓ Bilingual PDF: {dual_path}")
    else:
        print(f"\n✗ Translation failed (exit code {result.returncode})")

    return result.returncode


def main():
    parser = argparse.ArgumentParser(
        description="Translate Chinese documents (PDF/DOCX/PPTX) to Korean or English",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s report.pdf                          # Chinese → Korean
  %(prog)s report.pdf --target en              # Chinese → English
  %(prog)s report.pptx --backend baidu         # China, no VPN
  %(prog)s paper.docx --dual                   # Bilingual output
  %(prog)s slides.pptx -o /tmp/slides_ko.pptx # Custom output path
        """,
    )
    parser.add_argument("input", help="Input file (PDF, DOCX, PPTX)")
    parser.add_argument("-t", "--target", default="ko", choices=["ko", "en"], help="Target language (default: ko)")
    parser.add_argument("-b", "--backend", default="google", choices=["google", "baidu", "ollama", "translatepy", "workbuddy", "gemini", "anthropic"], help="Translation backend (default: google; use workbuddy for Dad's tokens, baidu for China)")
    parser.add_argument("--dual", action="store_true", help="Also generate bilingual PDF")
    parser.add_argument("-o", "--output", help="Output file path")

    args = parser.parse_args()
    sys.exit(translate(args.input, args.target, args.backend, args.dual, args.output))


if __name__ == "__main__":
    main()
