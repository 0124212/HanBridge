"""setup-dad-tui.py -- Dad-proof step-by-step installer TUI (tkinter only, stdlib).

Same 6 steps as windows/setup-dad.bat (THE ONLY SETUP), one Next click per
step: [1/6] Python check -> [2/6] ready -> [3/6] installing (minutes) ->
[4/6] default settings -> [5/6] shortcuts -> [6/6] demo. Fail = red status +
keep-original note, Retry reruns the same step. No new deps.

Launch (from repo root):  python windows\\setup-dad-tui.py
Dry run (lists steps, changes nothing):  python windows\\setup-dad-tui.py --dry-run
Help:  python windows\\setup-dad-tui.py --help

Line endings: .py stays LF per .gitattributes (only *.bat/*.cmd get CRLF).
"""
import argparse
import os
import shutil
import subprocess
import sys
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # repo root
VENV_PY = ROOT / ".venv" / "Scripts" / "python.exe"
VENV_PYW = ROOT / ".venv" / "Scripts" / "pythonw.exe"
LANG_FILE = Path(__file__).resolve().parent / "lang.json"

STEPS = [
    ("Python check", "파이썬 확인"),
    ("Ready", "기본 준비"),
    ("Installing (a few minutes)", "설치 중 (몇 분)"),
    ("Default settings", "기본 설정"),
    ("Desktop shortcuts", "바탕화면 바로가기"),
    ("Final check", "마무리 확인"),
]

GUIDE = [
    "가만히 계세요, 컴퓨터를 확인하고 있어요",
    "가만히 계세요, 준비하고 있어요",
    "가만히 계세요, 자동으로 설치 중이에요 (몇 분 걸려요)",
    "가만히 계세요, 기본 설정을 만들고 있어요",
    "가만히 계세요, 바탕화면 아이콘을 만들고 있어요",
    "가만히 계세요, 마지막으로 확인하고 있어요",
]

STRINGS = {
    "ko": {"title": "HanBridge 설치 (6단계)", "next": "다음", "retry": "다시 시도",
           "toggle": "English", "ok": "완료!", "fail": "실패 — 원본은 그대로, 다시 시도하세요.",
           "idle": "대기 중", "working": "진행 중...", "done": "성공", "failed": "실패",
           "free_note": "무료 방식 사용 중", "gpu_note": "그래픽카드 발견",
           "ollama_note": "로컬 모델 발견 — 오프라인 사용",
           "fails": ["파이썬 3.11+ 필요 (python.org)",
                      "준비 실패 — 다시 시도하세요",
                      "설치 실패 — 네트워크 확인 후 다시 시도하세요",
                      "기본 설정 실패 — 다시 시도하세요",
                      "바로가기 실패 — 다시 시도하세요",
                      "데모 실패 — 다시 시도하세요"]},
    "en": {"title": "HanBridge Setup (6 steps)", "next": "Next", "retry": "Retry",
           "toggle": "한국어", "ok": "Done!", "fail": "Failed — original kept, please retry.",
           "idle": "idle", "working": "working...", "done": "ok", "failed": "failed",
           "free_note": "Free mode", "gpu_note": "GPU found",
           "ollama_note": "Local model found — offline",
           "fails": ["need Python 3.11+ (python.org)",
                      "ready failed — please retry",
                      "install failed — check network and retry",
                      "settings failed — please retry",
                      "shortcut failed — please retry",
                      "demo failed — please retry"]},
}

FG = {"idle": "black", "working": "black", "done": "green", "failed": "red"}


def load_lang():
    try:
        import json
        lang = json.loads(LANG_FILE.read_text(encoding="utf-8")).get("lang", "ko")
    except (OSError, ValueError, AttributeError):
        lang = "ko"
    return lang if lang in STRINGS else "ko"


def fail_msg(n, lang="ko"):
    """Localized per-step fail message via STRINGS (1-based n)."""
    fails = STRINGS.get(lang, STRINGS["ko"])["fails"]
    if 1 <= n <= len(fails):
        return fails[n - 1]
    return STRINGS.get(lang, STRINGS["ko"])["fail"]


def sanitize_gpu(s):
    """Same sanitize as setup-dad.bat L94-97/L99-102: strip parens that break blocks."""
    return s.replace("(", "").replace(")", "").strip()


def detect_gpu():
    """Pre-step nvidia-smi -L detect. Returns sanitized first line or None."""
    if shutil.which("nvidia-smi") is None:
        return None
    try:
        r = subprocess.run(["nvidia-smi", "-L"], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return None
    if r.returncode != 0:
        return None
    for line in (r.stdout or "").splitlines():
        line = line.strip()
        if line:
            return sanitize_gpu(line)
    return None


def has_ollama_model(keyword="qwen2.5"):
    """Ollama only if `ollama list` has a model (silent default free otherwise)."""
    if shutil.which("ollama") is None:
        return False
    try:
        r = subprocess.run(["ollama", "list"], capture_output=True, text=True, timeout=15)
    except (OSError, subprocess.SubprocessError):
        return False
    if r.returncode != 0:
        return False
    return keyword.lower() in (r.stdout or "").lower()


def pick_backend():
    """Silent default free; ollama only when a model is present."""
    return "ollama" if has_ollama_model() else "free"


def find_python():
    """Step 1: py launcher first (bypasses Store shim), plain python second."""
    for cmd in (["py", "-3.12"], ["py", "-3.11"], ["python"]):
        if shutil.which(cmd[0]) is None:
            continue
        try:
            subprocess.run(cmd + ["--version"], capture_output=True, check=True)
        except subprocess.CalledProcessError:
            continue
        r = subprocess.run(cmd + ["-c", "import sys;sys.exit(0 if sys.version_info>=(3,11) else 1)"])
        if r.returncode == 0:
            return cmd
    return None


def run_step(n, dry=False, lang="ko"):
    """Run step n (1-based). Returns (ok, message). Dry run only describes."""
    if n == 1:
        if dry:
            return True, "check python >= 3.11"
        py = find_python()
        return (True, "Python OK: " + " ".join(py)) if py else (False, fail_msg(1, lang))
    if n == 2:
        if dry:
            return True, "python -m venv .venv"
        if (ROOT / ".venv").exists():
            return True, "venv already exists"
        py = find_python() or [sys.executable]
        r = subprocess.run(py + ["-m", "venv", str(ROOT / ".venv")])
        return (r.returncode == 0, "venv created" if r.returncode == 0 else fail_msg(2, lang))
    if n == 3:
        if dry:
            return True, "pip install -e .[all] (a few minutes)"
        pippy = str(VENV_PY if VENV_PY.exists() else sys.executable)
        r = subprocess.run([pippy, "-m", "pip", "install", "-e", ".[all]"], cwd=str(ROOT))
        return (r.returncode == 0, "install done" if r.returncode == 0 else fail_msg(3, lang))
    if n == 4:
        if dry:
            return True, "copy examples/palimpsest.zh-ko.toml -> palimpsest.toml"
        if (ROOT / "palimpsest.toml").exists():
            return True, "config exists, skipped"
        src = ROOT / "examples" / "palimpsest.zh-ko.toml"
        try:
            shutil.copy(src, ROOT / "palimpsest.toml")
            return True, "config created (zh-ko)"
        except OSError:
            return False, fail_msg(4, lang)
    if n == 5:
        if dry:
            return True, "create 2 desktop shortcuts (HanBridge + HanBridge Windowed)"
        d = Path(os.environ.get("USERPROFILE", str(Path.home()))) / "Desktop"
        for _old in ("Chinese Translator.lnk", "Chinese Translator App.lnk",
                      "Dad Translate.lnk", "Dad Translate Window.lnk"):
            try:
                (d / _old).unlink()
            except OSError:
                pass
        vbs = str(ROOT / "windows" / "dad-run.vbs")
        ps1 = ("$s=(New-Object -ComObject WScript.Shell).CreateShortcut("
               "[IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'HanBridge.lnk')); "
               f"$s.TargetPath='wscript.exe'; $s.Arguments='\"{vbs}\"'; "
               f"$s.WorkingDirectory='{ROOT}'; $s.Description='중국어 PDF를 여기에 드래그하면 한국어로 번역됩니다'; $s.Save()")
        r1 = subprocess.run(["powershell", "-NoProfile", "-Command", ps1], capture_output=True)
        app_py = str(ROOT / "windows" / "HanBridge.py")
        pyw = str(VENV_PYW if VENV_PYW.exists() else sys.executable)
        ps2 = ("$s=(New-Object -ComObject WScript.Shell).CreateShortcut("
               "[IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'HanBridge Windowed.lnk')); "
               f"$s.TargetPath='{pyw}'; $s.Arguments='\"{app_py}\"'; "
               f"$s.WorkingDirectory='{ROOT}'; $s.Description='더블클릭하면 번역할 파일을 고릅니다'; $s.Save()")
        r2 = subprocess.run(["powershell", "-NoProfile", "-Command", ps2], capture_output=True)
        ok = r1.returncode == 0 and r2.returncode == 0
        return (ok, "shortcuts ready (2)" if ok else fail_msg(5, lang))
    if n == 6:
        if dry:
            return True, "translate.py --help"
        tpy = ROOT / "skills" / "translate-doc" / "translate.py"
        pippy = str(VENV_PY if VENV_PY.exists() else sys.executable)
        if not tpy.exists():
            return False, fail_msg(6, lang)
        r = subprocess.run([pippy, str(tpy), "--help"], capture_output=True, cwd=str(ROOT))
        return (r.returncode == 0, "demo OK" if r.returncode == 0 else fail_msg(6, lang))
    return False, "bad step"


def main(argv=None):
    ap = argparse.ArgumentParser(description="Dad-proof 6-step installer TUI (tkinter, stdlib only).")
    ap.add_argument("--dry-run", action="store_true", help="list steps, change nothing")
    ap.add_argument("--step", type=int, default=0, help="run single step N (1-6) in console, no GUI")
    ap.add_argument("--lang", choices=["ko", "en"], default=None, help="message language")
    args = ap.parse_args(argv)
    lang_cli = args.lang or load_lang()

    # GPU parity minimal: pre-step detect, silent default free, note only.
    gpu = None if (args.dry_run or args.step) else None  # GUI path detects below
    if args.dry_run:
        g = detect_gpu()
        b = pick_backend()
        note = STRINGS[lang_cli]["free_note"]
        if g:
            print(f"GPU: {g} ({STRINGS[lang_cli]['gpu_note']})")
        print(f"backend: {b} ({note})")
        for i, (en, ko) in enumerate(STEPS, 1):
            ok, desc = run_step(i, dry=True)
            print(f"[{i}/6] {ko} / {en} -> {desc}")
        return 0

    if args.step:
        ok, msg = run_step(args.step, lang=lang_cli)
        print(f"[{args.step}/6] {'OK' if ok else 'FAIL'}: {msg}")
        return 0 if ok else 1

    import tkinter as tk  # lazy: --help/--dry-run work headless
    lang = [load_lang()]
    idx = [0]  # next step to run (0-based)
    gpu_info = [detect_gpu()]
    backend = [pick_backend()]

    def t(k):
        return STRINGS[lang[0]][k]

    root = tk.Tk()
    hdr = tk.Label(root, font=("", 16))
    hdr.pack(pady=10)
    rows, labels = [], []
    pulse = {"on": False, "n": 0, "msg": ""}

    def apply():
        # Guard: after final success idx == len(STEPS); never index past end.
        root.title(t("title"))
        if idx[0] >= len(STEPS):
            hdr.config(text=t("ok"), fg="green")
        else:
            en, ko = STEPS[idx[0]]
            hdr.config(text=f"[{idx[0] + 1}/6] {ko} / {en}", fg="black")
        toggle_btn.config(text=t("toggle"))
        if idx[0] >= len(STEPS):
            next_btn.config(text=t("ok"), state="disabled")
        else:
            next_btn.config(text=t("next") if labels[idx[0]][1] != "failed" else t("retry"))
        for i, (en, ko) in enumerate(STEPS):
            state = labels[i][1]
            txt = f"[{'✓' if state == 'done' else '✗' if state == 'failed' else f'{i + 1}/6'}] "
            txt += ko if lang[0] == "ko" else en
            txt += f" — {t(state)}"
            rows[i].config(text=txt, fg=FG[state])

    def tick():
        if not pulse["on"]:
            return
        pulse["n"] = (pulse["n"] + 1) % 4
        dots = "." * pulse["n"]
        status.config(text=f"{pulse['msg']}{dots}", fg="black")
        root.after(500, tick)

    busy = [False]

    def advance():
        if idx[0] >= len(STEPS) or busy[0]:
            return
        busy[0] = True
        i = idx[0]
        labels[i][1] = "working"
        next_btn.config(state="disabled")  # disable Next while working
        pulse["on"] = True
        pulse["n"] = 0
        pulse["msg"] = GUIDE[i]
        status.config(text=GUIDE[i], fg="black")
        tick()  # liveness dots / 진행 중 pulse (matters for pip step)
        apply()
        cur_lang = lang[0]

        def worker():
            ok, msg = run_step(i + 1, lang=cur_lang)

            def finish():
                pulse["on"] = False
                busy[0] = False
                labels[i][0], labels[i][1] = msg, ("done" if ok else "failed")
                if ok:
                    idx[0] += 1
                if idx[0] >= len(STEPS):
                    done_msg = ("완료! 바탕화면 HanBridge 아이콘을 쓰세요"
                                if cur_lang == "ko" else STRINGS["en"]["ok"])
                    status.config(text=done_msg, fg="green")
                elif not ok:
                    print(f"[fail] step {i + 1}: {msg}")
                    status.config(text=t("fail"), fg="red")
                else:
                    status.config(text=t("ok"), fg="green")
                    next_btn.config(state="disabled")
                    root.after(900, advance)  # auto-advance, dad clicks once total
                    apply()
                    return
                next_btn.config(state="normal" if idx[0] < len(STEPS) else "disabled")
                apply()
            root.after(0, finish)  # push result via root.after()

        threading.Thread(target=worker, daemon=True).start()

    def toggle():
        lang[0] = "en" if lang[0] == "ko" else "ko"
        try:
            LANG_FILE.write_text(f'{{"lang": "{lang[0]}"}}', encoding="utf-8")
        except OSError:
            pass
        apply()
        backend_label.config(text=backend_text())

    def backend_text():
        note = t("free_note")
        if backend[0] == "ollama":
            return f"{t('ollama_note')} ({note})"
        if gpu_info[0]:
            return f"{t('gpu_note')}: {gpu_info[0]} ({note})"
        return f"({note})"

    toggle_btn = tk.Button(root, command=toggle)
    toggle_btn.pack(pady=4, anchor="e", padx=8)
    backend_label = tk.Label(root, font=("", 10))
    backend_label.pack(pady=2)
    for _ in STEPS:
        labels.append(["", "idle"])
        lbl = tk.Label(root, font=("", 12), anchor="w")
        lbl.pack(pady=2, padx=12, anchor="w")
        rows.append(lbl)
    status = tk.Label(root, font=("", 12))
    status.pack(pady=8)
    next_btn = tk.Button(root, font=("", 18), width=24, height=2, command=advance)
    next_btn.pack(pady=10)
    backend_label.config(text=backend_text())
    apply()
    root.mainloop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
