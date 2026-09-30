@echo off
REM dad-run.bat -- Dad's one-click translate (drag-drop). 双击或拖文件到上面运行。
chcp 65001 >nul
cd /d "%~dp0.."

set INPUT=%~1
if "%INPUT%"=="" (
  echo 把要翻译的文件拖到这个图标上 / Drag a file onto this icon,
  echo 或者在下面输入文件路径 / or type the file path below:
  set /p INPUT=文件路径 File path:
)
set INPUT=%INPUT:"=%
if "%INPUT%"=="" (
  echo [错误 ERROR] 没有文件 / No file given.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo [错误 ERROR] 翻译环境还没装好。
  echo 请先运行setup-dad: 双击 windows\setup-dad.bat 先安装。
  echo Please run setup-dad first: double-click windows\setup-dad.bat.
  pause
  exit /b 1
)

if not exist "%INPUT%" (
  echo [错误 ERROR] 文件找不到 / File not found:
  echo %INPUT%
  echo 请检查文件路径是否正确。
  pause
  exit /b 1
)

if not exist "translated" mkdir "translated" >nul 2>&1

echo 正在翻译...请稍候 / Translating, please wait:
echo %INPUT%
echo ..........
.venv\Scripts\python skills/translate-doc/translate.py "%INPUT%" --target ko
if not errorlevel 1 goto :success

echo.
echo 第一次没成功，5秒后自动再试一次 / First try failed, retrying once in 5s...
timeout /t 5 /nobreak >nul 2>&1
echo 正在翻译...请稍候 / Retrying, please wait:
echo ..........
.venv\Scripts\python skills/translate-doc/translate.py "%INPUT%" --target ko
if not errorlevel 1 goto :success

echo.
echo [失败 FAILED] 两次都失败了 / Still failed.
for %%F in ("%INPUT%") do if exist "%%~dpF~$*" (
  echo 文件可能被WPS占用，请关闭WPS后重试。
  echo File may be locked by WPS, please close WPS and retry.
  goto :keeporiginal
)
ping -n 1 -w 2000 114.114.114.114 >nul 2>&1
if errorlevel 1 (
  echo [错误 ERROR] 没网 - 请检查网络，联网后按任意键重试。
  echo No network - check connection, then press any key to retry.
  pause
  echo 正在翻译...请稍候 / Retrying, please wait:
  echo ..........
  .venv\Scripts\python skills/translate-doc/translate.py "%INPUT%" --target ko
  if not errorlevel 1 goto :success
  echo.
  echo [失败 FAILED] 还是不行 / Still failed.
)

:keeporiginal
call :keepcopy "%INPUT%"
echo 网络连不上翻译服务，已保留原文，请稍后再试。
pause
exit /b 1

:success
echo.
echo [完成 DONE] 翻译完成，结果在 translated 文件夹 / Done, see translated folder.
start "" explorer "translated"
pause
exit /b 0

:keepcopy
copy "%~1" "translated\%~n1-原文保留%~x1" >nul 2>&1
echo 原文已保留为 translated\%~n1-原文保留%~x1
echo Original kept as translated\%~n1-原文保留%~x1
goto :eof
