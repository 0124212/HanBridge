"""DadTranslate.py -- 爸爸窗口版翻译器 (tkinter only, no new deps).

Single window: big [选择文件] button, fixed 中文->韩文 label,
drag-drop hint, progress label, done = green 完成 + [打开文件夹] button.
Calls skills/translate-doc/translate.py via subprocess with --target ko --dual.
"""
import os
import subprocess
import sys
import tkinter as tk
from tkinter import filedialog
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # repo root
TRANSLATE_PY = ROOT / "skills" / "translate-doc" / "translate.py"
OUT_DIR = ROOT / "translated"


def run_translate(path: str, status: tk.Label, open_btn: tk.Button, root: tk.Tk):
    status.config(text="翻译中... / Translating...", fg="black")
    open_btn.pack_forget()
    root.update()
    cmd = [sys.executable, str(TRANSLATE_PY), path, "--target", "ko", "--dual"]
    try:
        subprocess.run(cmd, cwd=str(ROOT), check=True)
    except subprocess.CalledProcessError:
        status.config(text="失败 / Failed，请重试。", fg="red")
        return
    status.config(text="完成 / Done!", fg="green")
    open_btn.pack(pady=6)


def pick_file(status, open_btn, root):
    path = filedialog.askopenfilename(title="选择要翻译的文件 / Choose file")
    if path:
        run_translate(path, status, open_btn, root)


def open_outdir():
    OUT_DIR.mkdir(exist_ok=True)
    os.startfile(str(OUT_DIR))  # type: ignore[attr-defined] -- Windows only, ponytail: no cross-platform opener needed (dad is Windows-only)


def main():
    root = tk.Tk()
    root.title("翻译爸爸 / Dad Translate")
    tk.Label(root, text="中文 -> 韩文", font=("", 16)).pack(pady=10)
    status = tk.Label(root, text="请选择文件", font=("", 12))
    open_btn = tk.Button(root, text="打开文件夹 / Open folder", command=open_outdir)
    tk.Button(root, text="选择文件 / Choose file", font=("", 14),
              width=20, height=2,
              command=lambda: pick_file(status, open_btn, root)).pack(pady=10)
    tk.Label(root, text="也可以把文件拖到桌面图标上翻译\n(Drag a file onto the desktop icon)",
             fg="gray").pack(pady=4)
    status.pack(pady=8)
    root.mainloop()


if __name__ == "__main__":
    main()
