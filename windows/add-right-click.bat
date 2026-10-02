@echo off
REM add-right-click.bat -- right-click "翻译成韩文" menu (HKCU, no admin needed) / 우클릭 "翻译成韩文" 메뉴 (HKCU, 관리자 불필요)
REM Adds right-click "翻译成韩文" for all files -> wscript dad-run.vbs "%1"
chcp 65001 >nul
set KEY="HKCU\Software\Classes\*\shell\翻译成韩文\command"
reg add "HKCU\Software\Classes\*\shell\翻译成韩文" /ve /d "翻译成韩文" /f >nul
reg add %KEY% /ve /d "wscript.exe \"%~dp0dad-run.vbs\" \"%%1\"" /f >nul
if errorlevel 1 (
  echo [FAILED] Could not add right-click menu. / 우클릭 메뉴 추가 실패.
) else (
  echo [DONE] Right-click menu added: right-click any file -^> 翻译成韩文. / 우클릭 메뉴 추가됨: 아무 파일이나 우클릭 -^> 翻译成韩文.
)
pause
