@echo off
REM HanBridge.bat -- portable dad-proof launcher, zero install.
REM Unzip anywhere, double-click (opens the window app) or drag a PDF onto
REM this file (translates it straight to Korean + bilingual PDF).
REM No admin, no setx, no winget, no network setup -- everything resolves
REM inside this folder. translatepy backend needs internet; nothing else does.

chcp 65001 >nul
set "ROOT=%~dp0"

REM MAX_PATH preflight: deep extract paths break embedded python past ~100 chars.
powershell -NoProfile -Command "if ($env:ROOT.Length -gt 100) { exit 1 } else { exit 0 }" >nul 2>&1
if not errorlevel 1 goto :pathok
goto :longpath

:pathok
REM Portable environment, session-local only -- nothing leaks to the system.
set "TESSDATA_PREFIX=%ROOT%tessdata"
set "PYTHONPATH=%ROOT%app"
set "PATH=%ROOT%python;%ROOT%bin;%PATH%"

if "%~1"=="" goto :gui
goto :cli

:gui
REM No file given: open the windowed app (tkinter, Korean default).
"%ROOT%python\pythonw.exe" "%ROOT%app\windows\HanBridge.py"
goto :done

:cli
REM File dropped on the icon: translate it directly.
REM Backend: Dad's WorkBuddy tokens if present, else free translatepy.
set "BACKEND=translatepy"
if defined WORKBUDDY_API_KEY set "BACKEND=workbuddy"
"%ROOT%python\python.exe" "%ROOT%app\skills\translate-doc\translate.py" "%~1" --target ko --backend %BACKEND% --dual
if errorlevel 1 goto :failed
echo.
echo 완료! 원본 옆 translated 폴더를 보세요.
for %%F in ("%~1") do start "" explorer "%%~dpFtranslated"
echo 계속하려면 아무 키나 누르세요...
pause >nul
goto :done

:failed
echo.
echo 실패했습니다. 원본은 그대로 있습니다. 인터넷을 확인하고 다시 시도하세요.
echo 계속하려면 아무 키나 누르세요...
pause >nul
goto :done

:longpath
echo 폴더 경로가 너무 깁니다 (Windows 260자 제한).
echo C:\hanbridge 같은 짧은 곳으로 옮긴 뒤 다시 실행하세요.
echo 현재 경로: "%ROOT%"
pause
goto :done

:done
