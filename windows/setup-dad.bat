@echo off
REM setup-dad.bat -- *** THE ONLY SETUP *** -- One-click setup for Dad's translator
REM RUN ME FIRST / 먼저 실행. All other bats are optional extras / 나머지 bat은 선택 사항.
REM Double-click to run / 더블클릭으로 실행. Creates .venv, installs, makes desktop shortcut.

chcp 65001 >nul
cd /d "%~dp0.."

REM 0. MAX_PATH preflight: deep extract paths break pip/venv past ~100 chars.
powershell -NoProfile -Command "if ((Get-Location).Path.Length -gt 100) { exit 1 } else { exit 0 }" >nul 2>&1
if not errorlevel 1 goto :pathok
goto :longpath

:pathok
echo ============================================
echo  Dad's Translator Setup / 아빠 번역기 설치
echo  6 steps, automatic, progress shown each step. / 6단계, 전자동, 매 단계 진행 표시.
echo ============================================
echo.

REM 1. Check python >= 3.11. Prefer py launcher first (bypasses broken
REM    Windows Store python3.exe shim); plain `python` second (field: plain
REM    `python` may be broken uv-trampoline or a 0KB Store alias).
set "PYTHON="
py -3.12 --version >nul 2>&1
if not errorlevel 1 set "PYTHON=py -3.12"
if defined PYTHON goto :havepy
REM Ignore Store shim: a `python` living under WindowsApps opens the Store, it is not real Python.
where python 2>nul | findstr /i "WindowsApps" >nul 2>&1
if not errorlevel 1 (
  echo [INFO] Ignoring Windows Store python shim, using py launcher. / Store 가짜 python 무시, py 런처 사용.
  goto :nopython
)
python --version >nul 2>&1
if errorlevel 1 goto :nopython
set "PYTHON=python"
:havepy
%PYTHON% -c "import sys; sys.exit(0 if sys.version_info>=(3,11) else 1)" >nul 2>&1
if errorlevel 1 goto :oldpython
echo [OK] Python version OK / Python 버전 정상 (%PYTHON%)

REM 1b. GPU auto-detect (any 12GB+ NVIDIA card runs local 7b models; skip silently if none)
where nvidia-smi >nul 2>&1
if not errorlevel 1 (
  echo [GPU] NVIDIA GPU detected / NVIDIA 그래픽카드 감지:
  nvidia-smi -L
  echo Note: Any 12GB+ NVIDIA card works for local 7b models (e.g. this PC's RTX 3060 12GB). / 참고: 12GB+ N 카드면 로컬 7b 모델 가능 (예: 본 PC RTX 3060 12GB).
)
goto :venv

:nopython
echo [ERROR] Python not found / Python을 찾을 수 없음.
echo Auto-installing Python 3.12, please wait... / Python 3.12 자동 설치 중, 잠시만 기다리세요...
echo (If a prompt pops up, click Yes. / 확인 창이 뜨면 "예"를 클릭하세요.)
call :installpy312
if errorlevel 1 goto :manualpython
echo [OK] Python auto-installed. / Python 자동 설치 완료.
goto :venv

:manualpython
echo Please install Python 3.11+ manually: / Python 3.11+ 수동 설치 필요:
echo https://www.python.org/downloads/
echo Note: tick "Add python.exe to PATH" during install. / 참고: 설치 시 "Add python.exe to PATH" 체크.
echo Then double-click this script again. / 설치 후 이 스크립트를 다시 더블클릭하세요.
pause
exit /b 1

:oldpython
echo [ERROR] Python version too old (need ^>= 3.11). / Python 버전이 너무 오래됨 (3.11+ 필요).
echo Auto-upgrading to Python 3.12, please wait... / Python 3.12로 자동 업그레이드 중, 잠시만 기다리세요...
echo (If a prompt pops up, click Yes. / 확인 창이 뜨면 "예"를 클릭하세요.)
call :installpy312
if errorlevel 1 goto :manualoldpython
echo [OK] Python upgraded. / Python 업그레이드 완료.
goto :venv

REM Shared Python 3.12 installer: winget first (Win11/new Win10), else
REM direct python.org download run silently, user-local (no admin).
:installpy312
where winget >nul 2>&1
if errorlevel 1 goto :dlpython
winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
if not errorlevel 1 goto :fixpath
echo [INFO] winget install failed, trying direct download... / winget 실패, 직접 다운로드 시도...
:dlpython
echo Downloading Python 3.12 installer... / Python 3.12 설치 파일 다운로드 중...
set "PYSETUP=%TEMP%\python-3.12.7-amd64.exe"
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe' -OutFile $env:TEMP+'\python-3.12.7-amd64.exe' } catch { exit 1 }" >nul 2>&1
if errorlevel 1 curl.exe -L -o "%PYSETUP%" "https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe" >nul 2>&1
if not exist "%PYSETUP%" exit /b 1
echo Running Python installer silently (current user only, no admin)... / Python 설치 중 (현재 사용자만, 관리자 불필요)...
"%PYSETUP%" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
if errorlevel 1 exit /b 1
del "%PYSETUP%" >nul 2>&1
:fixpath
REM Installers leave PATH stale in this shell, prepend default user-local location.
set "PATH=%LocalAppData%\Programs\Python\Python312\;%LocalAppData%\Programs\Python\Python312\Scripts\;%PATH%"
set "PYTHON="
py -3.12 --version >nul 2>&1
if not errorlevel 1 set "PYTHON=py -3.12"
if defined PYTHON goto :checkver
python --version >nul 2>&1
if errorlevel 1 exit /b 1
set "PYTHON=python"
:checkver
%PYTHON% -c "import sys; sys.exit(0 if sys.version_info>=(3,11) else 1)" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:manualoldpython
echo Auto-upgrade failed, please upgrade manually: / 자동 업그레이드 실패, 수동 업그레이드 필요:
echo https://www.python.org/downloads/
echo Note: tick "Add python.exe to PATH" during install. / 참고: 설치 시 "Add python.exe to PATH" 체크.
echo Then double-click this script again. / 설치 후 이 스크립트를 다시 더블클릭하세요.
pause
exit /b 1

:longpath
echo [ERROR] Folder path too long, Windows limit 260 chars. / 폴더 경로가 너무 깁니다 (Windows 260자 제한).
echo Please move this folder to C:\palimpsest-cn and run again. / 이 폴더를 C:\palimpsest-cn 으로 옮긴 뒤 다시 실행하세요.
echo Current path / 현재 경로: %CD%
pause
exit /b 1

:venv
REM 2. Create .venv if absent
if not exist ".venv" (
  echo Creating virtual environment... / 가상환경 생성 중...
  %PYTHON% -m venv .venv
) else (
  echo [OK] Virtual env already exists. / 가상환경이 이미 있습니다.
)

REM 3. Install (keyless default: translatepy via [all])
echo Installing palimpsest [all] (may take a few minutes)... / palimpsest [all] 설치 중 (수 분 소요)...
.venv\Scripts\python -m pip install -e .[all]
if errorlevel 1 (
  echo [ERROR] Install failed. Check network and retry. / 설치 실패. 네트워크 확인 후 재시도.
  pause
  exit /b 1
)
echo [OK] Install done. / 설치 완료.

REM 4. Copy default config if absent
if not exist "palimpsest.toml" (
  copy "examples\palimpsest.zh-ko.toml" "palimpsest.toml" >nul
  echo [OK] Default config created (zh-^>ko). / 기본 설정 palimpsest.toml 생성됨 (zh-^>ko).
) else (
  echo [OK] Config already exists, skipped. / 설정이 이미 있어 건너뜀.
)

REM 5. Desktop shortcuts (English names) -> windows\dad-run.vbs (hidden CMD + popups)
echo Creating desktop shortcuts... / 바탕화면 바로가기 생성 중...
REM 5a. Legacy cleanup: remove old shortcut names from earlier installs
del "%USERPROFILE%\Desktop\翻译爸爸.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\翻译爸爸窗口版.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\Dad Translate.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\Dad Translate Window.lnk" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'Chinese Translator.lnk')); $s.TargetPath='wscript.exe'; $s.Arguments='\"'+[IO.Path]::Combine((Get-Location).Path,'windows\dad-run.vbs')+'\"'; $s.WorkingDirectory=(Get-Location).Path; $s.Save()"
echo [OK] Desktop shortcut ready "Chinese Translator". / 바탕화면 "Chinese Translator" 준비됨.

REM 5b. Desktop shortcut (windowed) -> windows\DadTranslate.py
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'Chinese Translator App.lnk')); $s.TargetPath=[IO.Path]::Combine((Get-Location).Path,'.venv\Scripts\pythonw.exe'); $s.Arguments='\"'+[IO.Path]::Combine((Get-Location).Path,'windows\DadTranslate.py')+'\"'; $s.WorkingDirectory=(Get-Location).Path; $s.Save()"
echo [OK] Desktop windowed shortcut ready "Chinese Translator App". / 창 모드 바로가기 "Chinese Translator App" 준비됨.

REM 6. Offer right-click menu (HKCU, no admin needed)
echo.
set /p ADDRIGHT=Add right-click menu "Translate to Korean"? (Y/N) / 우클릭 메뉴를 추가할까요? (Y/N):
if /i "%ADDRIGHT%"=="Y" call "windows\add-right-click.bat"

echo.
echo ============================================
echo  Done! Drag a file onto Chinese Translator to translate. / 완료! 파일을 "Chinese Translator"에 드래그하면 번역됩니다.
echo ============================================
pause
