@echo off
REM Translate-CN.bat -- portable dad-proof launcher, zero install.
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
"%ROOT%python\pythonw.exe" "%ROOT%app\windows\DadTranslate.py"
goto :done

:cli
REM File dropped on the icon: translate it directly.
REM Backend: Dad's WorkBuddy tokens if present, else free translatepy.
set "BACKEND=translatepy"
if defined WORKBUDDY_API_KEY set "BACKEND=workbuddy"
"%ROOT%python\python.exe" "%ROOT%app\skills\translate-doc\translate.py" "%~1" --target ko --backend %BACKEND% --dual
if errorlevel 1 goto :failed
echo.
echo Done! Output is in the translated folder next to your file.
echo Press any key to close.
pause >nul
goto :done

:failed
echo.
echo Translation failed -- check the message above and try again.
echo Needs internet (translatepy). Press any key to close.
pause >nul
goto :done

:longpath
echo Folder path too long, Windows limit 260 chars.
echo Move this folder somewhere short like C:\hanbridge and run again.
echo Current path: "%ROOT%"
pause
goto :done

:done
