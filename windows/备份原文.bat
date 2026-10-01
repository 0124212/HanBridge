@echo off
REM 备份原文.bat -- Backup the source file before/after translate. 备份原文。
chcp 65001 >nul
cd /d "%~dp0.."

set SRC=%~1
if "%SRC%"=="" (
  echo 把要备份的文件拖到这个图标上 / Drag a file onto this icon,
  echo 或者在下面输入文件路径 / or type the file path below:
  set /p SRC=文件路径 File path:
)
set SRC=%SRC:"=%
if "%SRC%"=="" (
  echo [错误 ERROR] 没有文件 / No file given.
  pause
  exit /b 1
)

if not exist "%SRC%" (
  echo [错误 ERROR] 文件找不到 / File not found:
  echo %SRC%
  pause
  exit /b 1
)

if not exist "translated\原文备份" mkdir "translated\原文备份" >nul 2>&1
copy "%SRC%" "translated\原文备份\" >nul
if errorlevel 1 (
  echo [错误 ERROR] 备份失败 / Backup failed.
  pause
  exit /b 1
)

echo [完成 DONE] 已备份到 translated\原文备份\ / Backed up to translated\原文备份\
pause
