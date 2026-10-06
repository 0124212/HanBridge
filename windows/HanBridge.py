"""HanBridge.py -- Dad's windowed translator (tkinter only, no new deps).

Single window: big file-picker button, Chinese->Korean label,
drag-drop hint, progress label, done = green status + open-folder button.
Calls skills/translate-doc/translate.py via subprocess with --target ko --dual.
UI language: Korean (default) / English toggle button, persisted in lang.json.
"""
import json
import os
import subprocess
import sys
import tkinter as tk
from tkinter import filedialog, messagebox
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # repo root
TRANSLATE_PY = ROOT / "skills" / "translate-doc" / "translate.py"
OUT_DIR = ROOT / "translated"
LOG_FILE = OUT_DIR / "translation-log.txt"
LANG_FILE = Path(__file__).resolve().parent / "lang.json"

STRINGS = {
    "ko": {
        "title": "HanBridge (중국어 번역기)",
        "direction": "중국어 → 한국어",
        "pick": "파일 선택",
        "open_folder": "폴더 열기",
        "hint": "바탕화면 아이콘에 파일을 드래그해도 됩니다",
        "toggle": "English",
        "idle": "파일을 선택하세요",
        "working": "번역 중...",
        "working_big": "큰 파일입니다. 잠시만 기다리세요...",
        "done": "완료!",
        "failed": "실패, 다시 시도하세요.",
        "done_popup": "완료! 바탕화면 translated 폴더를 보세요.",
        "fail_popup": "실패했습니다. 원본은 그대로 있습니다. 다시 시도하세요.",
        "dialog_title": "번역할 파일 선택",
        "log_start": "Translating: ",
        "log_fail": "[FAILED] ",
        "log_done": "[DONE] ",
    },
    "en": {
        "title": "HanBridge",
        "direction": "Chinese → Korean",
        "pick": "Choose file",
        "open_folder": "Open folder",
        "hint": "You can also drag a file onto the desktop icon",
        "toggle": "한국어",
        "idle": "Choose a file",
        "working": "Translating...",
        "working_big": "Big file, please wait...",
        "done": "Done!",
        "failed": "Failed, please retry.",
        "done_popup": "Done! Check the translated folder on your Desktop.",
        "fail_popup": "Failed. Your original file is untouched. Please try again.",
        "dialog_title": "Choose file to translate",
        "log_start": "Translating: ",
        "log_fail": "[FAILED] ",
        "log_done": "[DONE] ",
    },
}

STATE_FG = {"idle": "black", "working": "black", "working_big": "black",
            "done": "green", "failed": "red"}


def load_lang():
    try:
        lang = json.loads(LANG_FILE.read_text(encoding="utf-8")).get("lang", "ko")
    except (OSError, ValueError, AttributeError):
        lang = "ko"
    return lang if lang in STRINGS else "ko"


def save_lang(lang):
    try:
        LANG_FILE.write_text(json.dumps({"lang": lang}), encoding="utf-8")
    except OSError:
        pass  # persistence must never break flow


def append_log(msg: str):
    try:
        OUT_DIR.mkdir(exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(msg + "\n")
    except OSError:
        pass  # log must never break flow


def main():
    root = tk.Tk()
    lang = [load_lang()]
    state = ["idle"]

    def t(key):
        return STRINGS[lang[0]][key]

    toggle_btn = tk.Button(root, font=("", 10))
    direction_lbl = tk.Label(root, font=("", 16))
    status = tk.Label(root, font=("", 12))
    open_btn = tk.Button(root, command=lambda: (OUT_DIR.mkdir(exist_ok=True),
                                                os.startfile(str(OUT_DIR))))  # type: ignore[attr-defined] -- Windows only, ponytail: no cross-platform opener needed (dad is Windows-only)
    pick_btn = tk.Button(root, font=("", 14), width=20, height=2)
    hint_lbl = tk.Label(root, fg="gray")

    def apply():
        root.title(t("title"))
        toggle_btn.config(text=t("toggle"))
        direction_lbl.config(text=t("direction"))
        pick_btn.config(text=t("pick"))
        open_btn.config(text=t("open_folder"))
        hint_lbl.config(text=t("hint"))
        status.config(text=t(state[0]), fg=STATE_FG[state[0]])

    def set_state(key):
        state[0] = key
        status.config(text=t(key), fg=STATE_FG[key])
        root.update()

    def run_translate(path):
        try:
            big = Path(path).stat().st_size > 20 * 1024 * 1024
        except OSError:
            big = False
        set_state("working_big" if big else "working")
        open_btn.pack_forget()
        append_log(t("log_start") + path)
        cmd = [sys.executable, str(TRANSLATE_PY), path, "--target", "ko", "--dual"]
        try:
            subprocess.run(cmd, cwd=str(ROOT), check=True)
        except subprocess.CalledProcessError:
            set_state("failed")
            append_log(t("log_fail") + path)
            messagebox.showerror(t("title"), t("fail_popup"))
            return
        set_state("done")
        append_log(t("log_done") + path)
        try:
            os.startfile(str(OUT_DIR))
        except OSError:
            pass
        messagebox.showinfo(t("title"), t("done_popup"))
        open_btn.pack(pady=6)

    def pick_file():
        path = filedialog.askopenfilename(
            title=t("dialog_title"),
            filetypes=[("문서 Documents", "*.pdf *.docx *.pptx *.xlsx"),
                       ("모든 파일 All files", "*.*")])
        if path:
            run_translate(path)

    def toggle():
        lang[0] = "en" if lang[0] == "ko" else "ko"
        save_lang(lang[0])
        apply()

    toggle_btn.config(command=toggle)
    pick_btn.config(command=pick_file)
    toggle_btn.pack(pady=4, anchor="e", padx=8)
    direction_lbl.pack(pady=10)
    pick_btn.pack(pady=10)
    hint_lbl.pack(pady=4)
    status.pack(pady=8)
    apply()
    root.mainloop()


if __name__ == "__main__":
    main()
