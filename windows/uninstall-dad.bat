@echo off
REM uninstall-dad.bat -- Undo dad setup. 卸载爸爸翻译。
chcp 65001 >nul
cd /d "%~dp0.."

echo 正在删除右键菜单 / Removing right-click entry...
call "windows\remove-right-click.bat"

echo 正在删除桌面快捷方式 / Removing desktop shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=[Environment]::GetFolderPath('Desktop'); del (Join-Path $d 'HanBridge.lnk') -Force -ErrorAction SilentlyContinue; del (Join-Path $d 'HanBridge Windowed.lnk') -Force -ErrorAction SilentlyContinue; del (Join-Path $d 'Chinese Translator.lnk') -Force -ErrorAction SilentlyContinue; del (Join-Path $d 'Chinese Translator App.lnk') -Force -ErrorAction SilentlyContinue"
REM Legacy names from earlier installs (USERPROFILE path kept: best-effort cleanup only):
del "%USERPROFILE%\Desktop\翻译爸爸.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\翻译爸爸窗口版.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\Dad Translate.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\Dad Translate Window.lnk" >nul 2>&1
echo [OK] Shortcuts removed (HanBridge, HanBridge Windowed). / 바로가기 제거됨.

echo.
set /p DELTRANS=是否删除 translated 文件夹? (Y/N, 默认 N) / Delete translated folder? (Y/N, default N):
if /i "%DELTRANS%"=="Y" (
  rmdir /s /q "translated" >nul 2>&1
  echo [OK] translated 已删除 / translated deleted.
) else (
  echo [OK] 保留 translated / Keeping translated.
)

echo.
set /p DELVENV=是否删除 .venv 环境? (Y/N, 默认 N) / Remove .venv? (Y/N, default N):
if /i "%DELVENV%"=="Y" (
  rmdir /s /q ".venv" >nul 2>&1
  echo [OK] .venv 已删除 / .venv deleted.
) else (
  echo [OK] 保留 .venv / Keeping .venv.
)

echo.
echo [完成 DONE] 卸载完成 / Uninstall done.
pause
