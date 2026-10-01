@echo off
REM setup-dad.bat -- *** THE ONLY SETUP / 唯一入口 *** -- One-click setup for Dad's translator
REM 先运行我 / RUN ME FIRST. 其他 bat 都是可选 / all other bats are optional extras.
REM 双击运行 / Double-click to run. Creates .venv, installs, makes desktop 翻译爸爸 shortcut.

chcp 65001 >nul
cd /d "%~dp0.."
echo ============================================
echo  爸爸翻译安装 / Dad's Translator Setup
echo  共 6 步，全自动，每步都会告诉你进度 / 6 steps, automatic, progress shown each step.
echo ============================================
echo.

REM 1. Check python >= 3.11 (field: plain `python` may be broken uv-trampoline; fall back to py -3.12)
set "PYTHON=python"
%PYTHON% --version >nul 2>&1
if errorlevel 1 (
  py -3.12 --version >nul 2>&1
  if errorlevel 1 goto :nopython
  set "PYTHON=py -3.12"
  echo [OK] plain python broken, using py -3.12 / plain python 不可用，改用 py -3.12
)
%PYTHON% -c "import sys; sys.exit(0 if sys.version_info>=(3,11) else 1)" >nul 2>&1
if errorlevel 1 goto :oldpython
echo [OK] Python 版本正常 / Python version OK (%PYTHON%)

REM 1b. GPU auto-detect (any 12GB+ NVIDIA card runs local 7b models; skip silently if none)
where nvidia-smi >nul 2>&1
if not errorlevel 1 (
  echo [GPU] 检测到 NVIDIA 显卡 / NVIDIA GPU detected:
  nvidia-smi -L
  echo 提示 Note: 任何 12GB+ N 卡都可本地跑 7b 模型 (如本机 RTX 3060 12GB) / Any 12GB+ NVIDIA card works for local 7b models (e.g. this PC's RTX 3060 12GB).
)
goto :venv

:nopython
echo [错误 ERROR] 没有找到 Python / Python not found.
echo 正在自动安装 Python 3.12，请稍候 / Auto-installing Python 3.12, please wait...
echo (如弹出确认窗口请点“是” / If a prompt pops up, click Yes.)
where winget >nul 2>&1
if errorlevel 1 goto :manualpython
winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
if errorlevel 1 goto :manualpython
REM winget 不刷新当前窗口的 PATH，手动加上默认安装路径 / PATH is stale in this shell, add default location.
set "PATH=%LocalAppData%\Programs\Python\Python312\;%LocalAppData%\Programs\Python\Python312\Scripts\;%PATH%"
python --version >nul 2>&1
if errorlevel 1 goto :manualpython
echo [OK] Python 自动安装成功 / Python auto-installed.
goto :venv

:manualpython
echo 请手动安装 Python 3.11 或更高版本 / Please install Python 3.11+ manually:
echo https://www.python.org/downloads/
echo 注意：安装时请勾选 "Add python.exe to PATH"
echo Note: tick "Add python.exe to PATH" during install.
echo 装完后重新双击本脚本 / Then double-click this script again.
pause
exit /b 1

:oldpython
echo [错误 ERROR] Python 版本太旧 / Python version too old (need ^>= 3.11).
echo 正在自动升级到 Python 3.12，请稍候 / Auto-upgrading to Python 3.12, please wait...
echo (如弹出确认窗口请点“是” / If a prompt pops up, click Yes.)
where winget >nul 2>&1
if errorlevel 1 goto :manualoldpython
winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
if errorlevel 1 goto :manualoldpython
set "PATH=%LocalAppData%\Programs\Python\Python312\;%LocalAppData%\Programs\Python\Python312\Scripts\;%PATH%"
python -c "import sys; sys.exit(0 if sys.version_info>=(3,11) else 1)" >nul 2>&1
if errorlevel 1 goto :manualoldpython
echo [OK] Python 升级成功 / Python upgraded.
goto :venv

:manualoldpython
echo 自动升级失败，请手动升级 / Auto-upgrade failed, please upgrade manually:
echo https://www.python.org/downloads/
echo 注意：安装时请勾选 "Add python.exe to PATH"
echo Note: tick "Add python.exe to PATH" during install.
echo 装完后重新双击本脚本 / Then double-click this script again.
pause
exit /b 1

:venv
REM 2. Create .venv if absent
if not exist ".venv" (
  echo 正在创建虚拟环境 / Creating virtual environment...
  %PYTHON% -m venv .venv
) else (
  echo [OK] 虚拟环境已存在 / Virtual env already exists.
)

REM 3. Install (keyless default: translatepy via [all])
echo 正在安装 / Installing palimpsest [all] (may take a few minutes)...
.venv\Scripts\python -m pip install -e .[all]
if errorlevel 1 (
  echo [错误 ERROR] 安装失败 / Install failed. 请检查网络后重试 / Check network and retry.
  pause
  exit /b 1
)
echo [OK] 安装完成 / Install done.

REM 4. Copy default config if absent
if not exist "palimpsest.toml" (
  copy "examples\palimpsest.zh-ko.toml" "palimpsest.toml" >nul
  echo [OK] 已创建默认配置 palimpsest.toml (中文-^>韩文) / Default config created (zh-^>ko).
) else (
  echo [OK] 配置已存在，跳过 / Config already exists, skipped.
)

REM 5. Desktop shortcut 翻译爸爸 -> windows\dad-run.vbs (hidden CMD + popups)
echo 正在创建桌面快捷方式 / Creating desktop shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'翻译爸爸.lnk')); $s.TargetPath='wscript.exe'; $s.Arguments='\"'+[IO.Path]::Combine((Get-Location).Path,'windows\dad-run.vbs')+'\"'; $s.WorkingDirectory=(Get-Location).Path; $s.Save()"
echo [OK] 桌面已有“翻译爸爸” / Desktop shortcut ready.

REM 5b. Desktop shortcut 翻译爸爸窗口版 -> windows\DadTranslate.py
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'翻译爸爸窗口版.lnk')); $s.TargetPath=[IO.Path]::Combine((Get-Location).Path,'.venv\Scripts\pythonw.exe'); $s.Arguments='\"'+[IO.Path]::Combine((Get-Location).Path,'windows\DadTranslate.py')+'\"'; $s.WorkingDirectory=(Get-Location).Path; $s.Save()"
echo [OK] 桌面已有“翻译爸爸窗口版” / Desktop windowed shortcut ready.

REM 6. Offer right-click menu (HKCU, no admin needed)
echo.
set /p ADDRIGHT=是否添加右键菜单“翻译成韩文”? (Y/N) / Add right-click menu? (Y/N):
if /i "%ADDRIGHT%"=="Y" call "windows\add-right-click.bat"

echo.
echo ============================================
echo  完成 / Done! 把文件拖到“翻译爸爸”上即可翻译。
echo  Done! Drag a file onto 翻译爸爸 to translate.
echo ============================================
pause
