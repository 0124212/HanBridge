@echo off
REM remove-right-click.bat -- 删除右键菜单“翻译成韩文”
chcp 65001 >nul
reg delete "HKCU\Software\Classes\*\shell\翻译成韩文" /f >nul
echo [完成 DONE] 右键菜单已删除 / Right-click entry removed.
pause
