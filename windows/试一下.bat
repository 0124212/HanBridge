@echo off
REM 试一下.bat -- Demo: translate the Chinese sample to Korean. 演示：翻译中文样例。
chcp 65001 >nul
cd /d "%~dp0.."

if not exist ".venv\Scripts\python.exe" (
  echo [错误 ERROR] 翻译环境还没装好。
  echo 请先运行setup-dad: 双击 windows\setup-dad.bat 先安装。
  echo Please run setup-dad first: double-click windows\setup-dad.bat.
  pause
  exit /b 1
)

if not exist "examples\中文样例.txt" (
  echo [错误 ERROR] 找不到 examples\中文样例.txt / Sample file not found.
  pause
  exit /b 1
)

echo 正在翻译样例...请稍候 / Translating demo sample, please wait:
echo examples\中文样例.txt --^> ko
echo ..........
.venv\Scripts\python skills/translate-doc/translate.py examples/中文样例.txt --target ko

echo.
echo [完成 DONE] 演示结束，结果在 translated 文件夹 / Demo done, see translated folder.
pause
