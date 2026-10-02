@echo off
REM setup-dad.bat -- *** THE ONLY SETUP *** -- One-click setup for Dad's translator
REM RUN ME FIRST / 먼저 실행. All other bats are optional extras / 나머지 bat은 선택 사항.
REM Double-click to run / 더블클릭으로 실행. Creates .venv, installs, makes desktop shortcut.
REM Mini-TUI: boxed header, [n/6] steps, colors, menus. Plain batch only, no new dependencies.

chcp 65001 >nul
cd /d "%~dp0.."

REM --- Flags: --lang ko|en --backend free|ollama|workbuddy --yes --interactive.
REM Bare double-click (no flags) = zero prompts: everything auto-decided.
set "FLAG_LANG="
set "FLAG_BACKEND="
set "FLAG_YES="
set "FLAG_INTERACTIVE="
:parseargs
if "%~1"=="" goto :argsdone
if /i "%~1"=="--lang" (set "FLAG_LANG=%~2" & shift & shift & goto :parseargs)
if /i "%~1"=="--backend" (set "FLAG_BACKEND=%~2" & shift & shift & goto :parseargs)
if /i "%~1"=="--yes" (set "FLAG_YES=1" & shift & goto :parseargs)
if /i "%~1"=="-y" (set "FLAG_YES=1" & shift & goto :parseargs)
if /i "%~1"=="--interactive" (set "FLAG_INTERACTIVE=1" & shift & goto :parseargs)
shift
goto :parseargs
:argsdone

REM --- Mini-TUI colors: green OK / yellow working / red error, ANSI with fallback.
REM Off when NO_COLOR is set or Windows major version is below 10 (no ANSI support).
set "LANG="
set "BACKEND="
set "HASGPU="
set "OSLOCALE="
set "GPUCARD="
set "USECOLOR=1"
if defined NO_COLOR set "USECOLOR="
set "WINMAJOR=10"
for /f "tokens=4 delims=. " %%v in ('ver') do set "WINMAJOR=%%v"
if %WINMAJOR% LSS 10 set "USECOLOR="
set "C_OK="
set "C_WRK="
set "C_ERR="
set "C_RST="
set "C_BLD="
if defined USECOLOR for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
if defined USECOLOR (
  set "C_OK=%ESC%[92m"
  set "C_WRK=%ESC%[93m"
  set "C_ERR=%ESC%[91m"
  set "C_RST=%ESC%[0m"
  set "C_BLD=%ESC%[1m"
)

REM 0. MAX_PATH preflight: deep extract paths break pip/venv past ~100 chars.
powershell -NoProfile -Command "if ((Get-Location).Path.Length -gt 100) { exit 1 } else { exit 0 }" >nul 2>&1
if not errorlevel 1 goto :pathok
goto :longpath

:pathok
REM Boxed title header (ASCII box: renders on every Windows console).
echo %C_BLD%+--------------------------------------------------+%C_RST%
echo %C_BLD%^|%C_RST%  Dad's Translator Setup / 아빠 번역기 설치
echo %C_BLD%^|%C_RST%  6 steps, zero prompts. Add --interactive for menus.
echo %C_BLD%^|%C_RST%  6단계, 질문 없음. 메뉴는 --interactive.
echo %C_BLD%+--------------------------------------------------+%C_RST%
echo.

:stats
REM Preflight system-stats box: CPU, RAM, disk free on this drive, GPU.
REM Unnumbered preflight (like MAX_PATH above) so the [1/6]-[6/6] steps stay consistent.
set "STATFILE=%TEMP%\palimpsest-stats.txt"
set "CPUINFO=Unknown CPU"
set "RAMTOTALGB=?"
set "RAMFREEGB=?"
set "DISKFREEGB=?"
set "DISKDRIVE=%CD:~0,1%"
set "DISKSTATUS=OK"
powershell -NoProfile -Command "$c=Get-CimInstance Win32_Processor | Select-Object -First 1; $o=Get-CimInstance Win32_OperatingSystem; $d=Get-PSDrive $PWD.Drive.Name; Write-Output $c.Name; Write-Output ([math]::Round($o.TotalVisibleMemorySize/1MB,1)); Write-Output ([math]::Round($o.FreePhysicalMemory/1MB,1)); Write-Output ([math]::Round($d.Free/1GB,1)); Write-Output $d.Free; Write-Output $PWD.Drive.Name; if ($d.Free -lt 3GB) { Write-Output 'LOW' } else { Write-Output 'OK' }" > "%STATFILE%" 2>nul
if exist "%STATFILE%" (
  < "%STATFILE%" (
    set /p CPUINFO=
    set /p RAMTOTALGB=
    set /p RAMFREEGB=
    set /p DISKFREEGB=
    set /p DISKFREEBYTES=
    set /p DISKDRIVE=
    set /p DISKSTATUS=
  )
)
del "%STATFILE%" >nul 2>&1
where nvidia-smi >nul 2>&1
if not errorlevel 1 (
  set "HASGPU=1"
  for /f "delims=" %%G in ('nvidia-smi -L 2^>nul') do if not defined GPUCARD set "GPUCARD=%%G"
)
echo %C_BLD%+--- System / 시스템 ---%C_RST%
echo %C_WRK%CPU: %CPUINFO%%C_RST%
echo %C_WRK%RAM: %RAMTOTALGB% GB total, %RAMFREEGB% GB free / RAM: 전체 %RAMTOTALGB% GB, 여유 %RAMFREEGB% GB%C_RST%
echo %C_WRK%Disk %DISKDRIVE%: %DISKFREEGB% GB free / 디스크 %DISKDRIVE%: %DISKFREEGB% GB 여유%C_RST%
if not defined HASGPU (
  echo %C_WRK%GPU: none, free backend will be used / GPU: 없음, 무료 백엔드 사용%C_RST%
) else (
  call :work "GPU: %GPUCARD%" "GPU: %GPUCARD%"
)
if "%DISKSTATUS%"=="LOW" goto :lowdisk

REM 0b. Language: --lang / PALIMPSEST_LANG wins; else OS locale auto-detect
REM (Korean Windows -> KO first); menu ONLY with --interactive.
if defined PALIMPSEST_LANG set "FLAG_LANG=%PALIMPSEST_LANG%"
set "LANG="
if /i "%FLAG_LANG%"=="ko" set "LANG=KO"
if /i "%FLAG_LANG%"=="korean" set "LANG=KO"
if /i "%FLAG_LANG%"=="en" set "LANG=EN"
if /i "%FLAG_LANG%"=="english" set "LANG=EN"
if defined LANG goto :langdone
for /f %%L in ('powershell -NoProfile -Command "(Get-Culture).Name" 2^>nul') do set "OSLOCALE=%%L"
set "LANG=EN"
if /i "%OSLOCALE:~0,2%"=="ko" set "LANG=KO"
if "%LANG%"=="KO" (
  call :work "Korean Windows detected - 한국어 먼저" "Korean Windows detected - KO first"
) else (
  call :work "English first - 한국어 둘째" "English first - KO second"
)
if not defined FLAG_INTERACTIVE goto :langdone
echo %C_BLD%[menu] Pick language / 언어 선택:%C_RST%
echo   1) English (default)
echo   2) 한국어
set "LANGPICK="
set /p LANGPICK=Choose 1 or 2, Enter=1 / 선택 1 또는 2, Enter=1:
if "%LANGPICK%"=="2" (set "LANG=KO") else (set "LANG=EN")
:langdone

call :step 1 "Checking Python 3.11+" "Python 3.11+ 확인 중"
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
  call :work "Ignoring Windows Store python shim - using py launcher" "Store 가짜 python 무시 - py 런처 사용"
  goto :nopython
)
python --version >nul 2>&1
if errorlevel 1 goto :nopython
set "PYTHON=python"
:havepy
%PYTHON% -c "import sys; sys.exit(0 if sys.version_info>=(3,11) else 1)" >nul 2>&1
if errorlevel 1 goto :oldpython
call :ok "Python version OK (%PYTHON%)" "Python 버전 정상 (%PYTHON%)"

REM 1b. GPU was detected in the :stats preflight above; backend menu gates on HASGPU.
goto :backendmenu

:nopython
call :err "Python not found." "Python을 찾을 수 없음."
call :work "Auto-installing Python 3.12, please wait..." "Python 3.12 자동 설치 중, 잠시만 기다리세요..."
call :work "If a prompt pops up, click Yes." "확인 창이 뜨면 예를 클릭하세요."
call :installpy312
if errorlevel 1 goto :manualpython
call :ok "Python auto-installed." "Python 자동 설치 완료."
goto :backendmenu

:manualpython
call :err "Please install Python 3.11+ manually:" "Python 3.11+ 수동 설치 필요:"
echo https://www.python.org/downloads/
call :work "Tick Add python.exe to PATH during install." "설치 시 Add python.exe to PATH 체크."
call :work "Then double-click this script again." "설치 후 이 스크립트를 다시 더블클릭하세요."
pause
exit /b 1

:oldpython
call :err "Python version too old (need >= 3.11)." "Python 버전이 너무 오래됨 (3.11+ 필요)."
call :work "Auto-upgrading to Python 3.12, please wait..." "Python 3.12로 자동 업그레이드 중, 잠시만 기다리세요..."
call :work "If a prompt pops up, click Yes." "확인 창이 뜨면 예를 클릭하세요."
call :installpy312
if errorlevel 1 goto :manualoldpython
call :ok "Python upgraded." "Python 업그레이드 완료."
goto :backendmenu

REM Shared Python 3.12 installer: winget first (Win11/new Win10), else
REM direct python.org download run silently, user-local (no admin).
:installpy312
where winget >nul 2>&1
if errorlevel 1 goto :dlpython
winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
if not errorlevel 1 goto :fixpath
call :work "winget install failed, trying direct download..." "winget 실패, 직접 다운로드 시도..."
:dlpython
call :work "Downloading Python 3.12 installer..." "Python 3.12 설치 파일 다운로드 중..."
set "PYSETUP=%TEMP%\python-3.12.7-amd64.exe"
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe' -OutFile $env:TEMP+'\python-3.12.7-amd64.exe' } catch { exit 1 }" >nul 2>&1
if errorlevel 1 curl.exe -L -o "%PYSETUP%" "https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe" >nul 2>&1
if not exist "%PYSETUP%" exit /b 1
call :work "Running Python installer silently (current user only, no admin)..." "Python 설치 중 (현재 사용자만, 관리자 불필요)..."
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
call :err "Auto-upgrade failed, please upgrade manually:" "자동 업그레이드 실패, 수동 업그레이드 필요:"
echo https://www.python.org/downloads/
call :work "Tick Add python.exe to PATH during install." "설치 시 Add python.exe to PATH 체크."
call :work "Then double-click this script again." "설치 후 이 스크립트를 다시 더블클릭하세요."
pause
exit /b 1

:longpath
call :err "Folder path too long, Windows limit 260 chars." "폴더 경로가 너무 깁니다 (Windows 260자 제한)."
call :work "Move this folder to C:\palimpsest-cn and run again." "이 폴더를 C:\palimpsest-cn 으로 옮긴 뒤 다시 실행하세요."
echo Current path / 현재 경로: "%CD%"
pause
exit /b 1

:lowdisk
call :err "Drive %DISKDRIVE%: only %DISKFREEGB% GB free, need 3 GB for install." "드라이브 %DISKDRIVE%: 여유 %DISKFREEGB% GB, 설치에 3 GB 필요."
call :work "Free some space and run again." "공간을 확보한 뒤 다시 실행하세요."
pause
exit /b 1

:backendmenu
REM Backend: --backend / PALIMPSEST_BACKEND wins; else free translatepy silently,
REM auto-using Ollama only if installed + a model is present. Menu ONLY with --interactive.
if defined PALIMPSEST_BACKEND set "FLAG_BACKEND=%PALIMPSEST_BACKEND%"
set "BACKEND="
if /i "%FLAG_BACKEND%"=="1" set "BACKEND=1"
if /i "%FLAG_BACKEND%"=="free" set "BACKEND=1"
if /i "%FLAG_BACKEND%"=="translatepy" set "BACKEND=1"
if /i "%FLAG_BACKEND%"=="2" set "BACKEND=2"
if /i "%FLAG_BACKEND%"=="ollama" set "BACKEND=2"
if /i "%FLAG_BACKEND%"=="3" set "BACKEND=3"
if /i "%FLAG_BACKEND%"=="workbuddy" set "BACKEND=3"
if defined BACKEND goto :backendflagcheck
if not defined FLAG_INTERACTIVE goto :backendauto
echo.
echo %C_BLD%[menu] Pick translation backend / 번역 방식 선택:%C_RST%
echo   1) Free - no key needed, translatepy (default) / 무료 - 키 불필요
if defined HASGPU echo   2) Local GPU offline, Ollama 7b private / 로컬 GPU 오프라인
echo   3) WorkBuddy tokens, needs 3 values / WorkBuddy 토큰, 3개 값 필요
set "BACKENDPICK="
set /p BACKENDPICK=Choose 1-3, Enter=1 / 선택 1-3, Enter=1:
set "BACKEND=1"
if "%BACKENDPICK%"=="2" set "BACKEND=2"
if "%BACKENDPICK%"=="3" set "BACKEND=3"
:backendcheck
if "%BACKEND%"=="2" if not defined HASGPU (
  call :work "No NVIDIA GPU found - using free default instead." "NVIDIA GPU 없음 - 무료 기본값 사용."
  set "BACKEND=1"
)
goto :backenddone
:backendauto
REM Silent default: free. Switch to Ollama only if installed AND a model exists.
set "BACKEND=1"
where ollama >nul 2>&1
if errorlevel 1 goto :backenddone
ollama list 2>nul | findstr /i "qwen2.5" >nul 2>&1
if errorlevel 1 goto :backenddone
set "BACKEND=2"
call :work "Ollama + model found - using local backend, no prompt." "Ollama + 모델 발견 - 로컬 백엔드 자동 사용."
goto :backenddone
:backendflagcheck
REM Explicit --backend: validate it can actually work, else fall back to free.
if "%BACKEND%"=="2" (
  where ollama >nul 2>&1
  if errorlevel 1 (
    call :work "Ollama picked but not installed - using free default." "Ollama 선택됐지만 미설치 - 무료 기본값 사용."
    set "BACKEND=1"
    goto :backenddone
  )
  ollama list 2>nul | findstr /i "qwen2.5" >nul 2>&1
  if errorlevel 1 (
    call :work "Ollama picked but no model found - using free default." "Ollama 선택됐지만 모델 없음 - 무료 기본값 사용."
    set "BACKEND=1"
    goto :backenddone
  )
)
if "%BACKEND%"=="3" (
  if defined WORKBUDDY_API_KEY goto :backenddone
  if defined FLAG_YES (
    call :work "WorkBuddy picked but no key and --yes given - using free default." "WorkBuddy 선택됐지만 키 없고 --yes - 무료 기본값 사용."
    set "BACKEND=1"
    goto :backenddone
  )
)
:backenddone
set "BACKENDNAME=Free translatepy, no key"
set "BACKENDNAME_KO=무료 translatepy, 키 불필요"
if "%BACKEND%"=="2" set "BACKENDNAME=Local GPU offline, Ollama 7b"
if "%BACKEND%"=="2" set "BACKENDNAME_KO=로컬 GPU 오프라인, Ollama 7b"
if "%BACKEND%"=="3" set "BACKENDNAME=WorkBuddy tokens"
if "%BACKEND%"=="3" set "BACKENDNAME_KO=WorkBuddy 토큰"
if "%BACKEND%"=="2" goto :backendollama
if "%BACKEND%"=="3" goto :backendworkbuddy
goto :venv

:backendollama
if not "%OLLAMA_MODEL%"=="" (
  call :ok "Keeping existing OLLAMA_MODEL (%OLLAMA_MODEL%)." "기존 OLLAMA_MODEL 유지 (%OLLAMA_MODEL%)."
  goto :venv
)
set "OLLAMA_MODEL=qwen2.5:7b"
setx OLLAMA_MODEL "qwen2.5:7b" >nul 2>&1
call :ok "Ollama model set to qwen2.5:7b. Translate with --backend ollama." "Ollama 모델 qwen2.5:7b 설정. 번역 시 --backend ollama 사용."
goto :venv

:backendworkbuddy
if defined WORKBUDDY_API_KEY (
  call :ok "WorkBuddy key already set, keeping it." "WorkBuddy 키가 이미 있어 유지."
  goto :venv
)
echo.
call :work "WorkBuddy needs 3 values from Tencent Cloud console." "Tencent Cloud 콘솔에서 3개 값 확인."
set "WB_BASE="
set /p WB_BASE=API Base, Enter=default / API Base, Enter=기본값:
if "%WB_BASE%"=="" set "WB_BASE=https://tokenhub-intl.tencentcloudmaas.com/v1"
set "WB_MODEL="
set /p WB_MODEL=Model, Enter=default deepseek-v4-pro / 모델, Enter=기본값:
if "%WB_MODEL%"=="" set "WB_MODEL=deepseek-v4-pro"
set "WB_KEY="
set /p WB_KEY=API Key, paste yours / API Key 붙여넣기:
if "%WB_KEY%"=="" (
  call :err "No key pasted - falling back to free default." "키 없음 - 무료 기본값으로 진행."
  set "BACKEND=1"
  set "BACKENDNAME=Free translatepy, no key"
  set "BACKENDNAME_KO=무료 translatepy, 키 불필요"
  goto :venv
)
setx WORKBUDDY_API_BASE "%WB_BASE%" >nul 2>&1
setx WORKBUDDY_API_KEY "%WB_KEY%" >nul 2>&1
setx WORKBUDDY_MODEL "%WB_MODEL%" >nul 2>&1
set "WORKBUDDY_API_BASE=%WB_BASE%"
set "WORKBUDDY_API_KEY=%WB_KEY%"
set "WORKBUDDY_MODEL=%WB_MODEL%"
call :ok "WorkBuddy keys saved for this user. Test one word first." "WorkBuddy 키 저장됨. 먼저 한 단어로 테스트."
goto :venv

:venv
call :step 2 "Virtual environment" "가상환경"
REM 2. Create .venv if absent
if not exist ".venv" (
  call :work "Creating virtual environment..." "가상환경 생성 중..."
  %PYTHON% -m venv .venv
) else (
  call :ok "Virtual env already exists." "가상환경이 이미 있습니다."
)

REM 3. Install (keyless default: translatepy via [all])
call :step 3 "Installing palimpsest [all], minutes, dots mean working" "palimpsest [all] 설치 중, 수 분 소요, 점이 찍히면 정상"
set "PIPFLAG=%TEMP%\palimpsest-pip.busy"
set "DOTLOOP=%TEMP%\palimpsest-dots.bat"
echo busy > "%PIPFLAG%"
(
  echo @echo off
  echo :dots
  echo if not exist "%PIPFLAG%" exit
  echo ^<nul set /p=.^>con
  echo ping -n 3 127.0.0.1 ^>nul
  echo goto :dots
) > "%DOTLOOP%"
start /b "" "%DOTLOOP%"
".venv\Scripts\python" -m pip install -e ".[all]"
set "PIPRC=%ERRORLEVEL%"
del "%PIPFLAG%" >nul 2>&1
ping -n 2 127.0.0.1 >nul 2>&1
del "%DOTLOOP%" >nul 2>&1
if not "%PIPRC%"=="0" (
  echo.
  call :err "Install failed. Check network and retry." "설치 실패. 네트워크 확인 후 재시도."
  pause
  exit /b 1
)
echo.
call :ok "Install done." "설치 완료."

REM 4. Copy default config if absent
call :step 4 "Default config" "기본 설정"
if not exist "palimpsest.toml" (
  copy "examples\palimpsest.zh-ko.toml" "palimpsest.toml" >nul
  call :ok "Default config created (zh-ko)." "기본 설정 palimpsest.toml 생성됨 (zh-ko)."
) else (
  call :ok "Config already exists, skipped." "설정이 이미 있어 건너뜀."
)

REM 5. Desktop shortcuts (English names) -> windows\dad-run.vbs (hidden CMD + popups)
call :step 5 "Desktop shortcuts" "바탕화면 바로가기"
REM 5a. Legacy cleanup: remove old shortcut names from earlier installs
del "%USERPROFILE%\Desktop\翻译爸爸.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\翻译爸爸窗口版.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\Dad Translate.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\Dad Translate Window.lnk" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'Chinese Translator.lnk')); $s.TargetPath='wscript.exe'; $s.Arguments='\"'+[IO.Path]::Combine((Get-Location).Path,'windows\dad-run.vbs')+'\"'; $s.WorkingDirectory=(Get-Location).Path; $s.Save()"
call :ok "Desktop shortcut ready Chinese Translator." "바탕화면 Chinese Translator 준비됨."

REM 5b. Desktop shortcut (windowed) -> windows\DadTranslate.py
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'Chinese Translator App.lnk')); $s.TargetPath=[IO.Path]::Combine((Get-Location).Path,'.venv\Scripts\pythonw.exe'); $s.Arguments='\"'+[IO.Path]::Combine((Get-Location).Path,'windows\DadTranslate.py')+'\"'; $s.WorkingDirectory=(Get-Location).Path; $s.Save()"
call :ok "Desktop windowed shortcut ready Chinese Translator App." "창 모드 바로가기 Chinese Translator App 준비됨."

REM 6. Offer right-click menu (HKCU, no admin needed)
call :step 6 "Right-click menu, optional" "우클릭 메뉴, 선택 사항"
if not defined FLAG_INTERACTIVE (
  call :work "Right-click menu skipped, default off. Rerun with --interactive to add." "우클릭 메뉴 건너뜀, 기본값 끔. 추가하려면 --interactive로 재실행."
  goto :summary
)
echo.
call :work "Add right-click menu Translate to Korean?" "우클릭 메뉴를 추가할까요?"
set "ADDRIGHT="
if "%LANG%"=="KO" (
  set /p ADDRIGHT=Add Y or N, Y/N / 추가 Y 또는 N:
) else (
  set /p ADDRIGHT=Add right-click menu Translate to Korean? Y/N / 우클릭 메뉴를 추가할까요?:
)
if /i "%ADDRIGHT%"=="Y" call "windows\add-right-click.bat"

:summary
echo.
echo %C_BLD%+--------------------------------------------------+%C_RST%
echo %C_BLD%^| SUMMARY / 요약%C_RST%
echo %C_BLD%+--------------------------------------------------+%C_RST%
if "%LANG%"=="KO" echo %C_OK%[OK] 설치됨: .venv + palimpsest [all] / Installed: .venv + palimpsest [all]%C_RST% else echo %C_OK%[OK] Installed: .venv + palimpsest [all] / 설치됨: .venv + palimpsest [all]%C_RST%
if "%LANG%"=="KO" echo %C_OK%[OK] 백엔드: %BACKENDNAME_KO% / Backend: %BACKENDNAME%%C_RST% else echo %C_OK%[OK] Backend: %BACKENDNAME% / 백엔드: %BACKENDNAME_KO%%C_RST%
if "%LANG%"=="KO" echo %C_OK%[OK] 바탕화면 아이콘 2개: Chinese Translator + Chinese Translator App / Desktop icons: 2%C_RST% else echo %C_OK%[OK] Desktop icons: Chinese Translator + Chinese Translator App / 바탕화면 아이콘 2개%C_RST%
if "%LANG%"=="KO" echo %C_WRK%[...] 사용법: 파일을 아이콘에 드래그 / How to translate: drag a file onto the icon%C_RST% else echo %C_WRK%[...] How to translate: drag a file onto the icon / 사용법: 파일을 아이콘에 드래그%C_RST%
if "%LANG%"=="KO" echo %C_WRK%[...] 결과물: 원본 옆 translated 폴더 / Outputs: translated folder next to your file%C_RST% else echo %C_WRK%[...] Outputs: translated folder next to your file / 결과물: 원본 옆 translated 폴더%C_RST%
if "%LANG%"=="KO" echo %C_WRK%[...] 관리자 불필요: HKCU + LOCALAPPDATA만 사용 / No admin used: HKCU + LOCALAPPDATA only%C_RST% else echo %C_WRK%[...] No admin used: HKCU + LOCALAPPDATA only / 관리자 불필요: HKCU + LOCALAPPDATA만 사용%C_RST%
echo %C_BLD%+--------------------------------------------------+%C_RST%
echo %C_OK%DONE! / 완료!%C_RST%
pause
exit /b 0

REM --- Mini-TUI helpers (call subroutines, LANG picks which language prints first) ---
:ok
if "%LANG%"=="KO" (echo %C_OK%[OK] %~2 / %~1%C_RST%) else (echo %C_OK%[OK] %~1 / %~2%C_RST%)
exit /b 0

:work
if "%LANG%"=="KO" (echo %C_WRK%[...] %~2 / %~1%C_RST%) else (echo %C_WRK%[...] %~1 / %~2%C_RST%)
exit /b 0

:err
if "%LANG%"=="KO" (echo %C_ERR%[ERROR] %~2 / %~1%C_RST%) else (echo %C_ERR%[ERROR] %~1 / %~2%C_RST%)
exit /b 0

:step
echo.
if "%LANG%"=="KO" (echo %C_BLD%[%1/6]%C_RST% %C_WRK%%~3 / %~2%C_RST%) else (echo %C_BLD%[%1/6]%C_RST% %C_WRK%%~1 / %~2%C_RST%)
exit /b 0
