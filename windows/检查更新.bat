@echo off
REM 检查更新.bat -- Show version and open releases page. 查看版本并打开更新页面。
chcp 65001 >nul
cd /d "%~dp0.."

if exist ".venv\Scripts\python.exe" (
  echo 当前版本 / Current version:
  .venv\Scripts\python -m palimpsest --version
) else (
  echo [提示 NOTE] 还没安装 .venv，跳过版本检查 / .venv not found, skipping version check.
  echo 请先运行 windows\setup-dad.bat / Please run windows\setup-dad.bat first.
)

echo.
echo 正在打开更新页面 / Opening releases page:
echo https://github.com/0124212/HanBridge/releases
start "" "https://github.com/0124212/HanBridge/releases"
pause
