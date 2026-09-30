@echo off
REM add-right-click.bat -- 右键菜单“翻译成韩文” (HKCU, 无需管理员)
REM Adds right-click "翻译成韩文" for all files -> wscript dad-run.vbs "%1"
chcp 65001 >nul
set KEY="HKCU\Software\Classes\*\shell\翻译成韩文\command"
reg add "HKCU\Software\Classes\*\shell\翻译成韩文" /ve /d "翻译成韩文" /f >nul
reg add %KEY% /ve /d "wscript.exe \"%~dp0dad-run.vbs\" \"%%1\"" /f >nul
if errorlevel 1 (
  echo [失败 FAILED] 右键菜单添加失败。
) else (
  echo [完成 DONE] 右键菜单已添加：在任意文件上点右键 -^> 翻译成韩文。
)
pause
