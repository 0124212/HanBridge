@echo off
REM dad-run.bat -- Dad's one-click translate (drag-drop). Drag a file onto it or double-click. / 파일을 드래그하거나 더블클릭으로 실행.
chcp 65001 >nul
cd /d "%~dp0.."

set INPUT=%~1
if "%INPUT%"=="" (
  echo Drag the file to translate onto this icon, / 번역할 파일을 이 아이콘에 드래그하세요,
  echo or type the file path below: / 또는 아래에 파일 경로를 입력하세요:
  set /p INPUT=File path / 파일 경로:
)
set INPUT=%INPUT:"=%
if "%INPUT%"=="" (
  echo [ERROR] No file given. / 파일이 없습니다.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo [ERROR] Translator env not installed yet. / 번역 환경이 아직 설치되지 않았습니다.
  echo Please run setup-dad first: double-click windows\setup-dad.bat. / 먼저 setup-dad를 실행하세요: windows\setup-dad.bat 더블클릭.
  pause
  exit /b 1
)

if not exist "%INPUT%" (
  echo [ERROR] File not found: / 파일을 찾을 수 없음:
  echo %INPUT%
  echo Please check the file path. / 파일 경로가 맞는지 확인하세요.
  pause
  exit /b 1
)

if not exist "translated" mkdir "translated" >nul 2>&1

echo %DATE% %TIME% 开始 START "%INPUT%" >> "translated\翻译日志.txt" 2>nul || ver>nul
for %%S in ("%INPUT%") do if %%~zS GTR 20971520 echo Large file, may take 10+ minutes, please do not close. / 파일이 커서 10분 이상 걸릴 수 있습니다. 닫지 마세요.
if not "%INPUT:&=X%"=="%INPUT%" goto :namewarn
if not "%INPUT:#=X%"=="%INPUT%" goto :namewarn
if not "%INPUT:!=X%"=="%INPUT%" goto :namewarn
echo "%INPUT%" | findstr "%%" >nul 2>&1 && goto :namewarn
goto :nameskip
:namewarn
echo Special chars in filename, still trying (rename recommended)... / 파일명에 특수문자가 있지만 계속 시도합니다 (이름 변경 권장)...
:nameskip

echo Translating, please wait: / 번역 중, 잠시만 기다리세요:
echo %INPUT%
echo ..........
".venv\Scripts\python" "skills\translate-doc\translate.py" "%INPUT%" --target ko
if not errorlevel 1 goto :success

echo.
echo First try failed, retrying once in 5s... / 첫 시도 실패, 5초 후 한 번 더 시도합니다...
timeout /t 5 /nobreak >nul 2>&1
echo Retrying, please wait: / 재시도 중, 잠시만 기다리세요:
echo ..........
".venv\Scripts\python" "skills\translate-doc\translate.py" "%INPUT%" --target ko
if not errorlevel 1 goto :success

echo.
echo [FAILED] Still failed after 2 tries. / [실패] 두 번 다 실패했습니다.
for %%F in ("%INPUT%") do if exist "%%~dpF~$*" (
  echo File may be locked by WPS, please close WPS and retry. / 파일이 WPS에 열려 있을 수 있습니다. WPS를 닫고 재시도하세요.
  goto :keeporiginal
)
ping -n 1 -w 2000 114.114.114.114 >nul 2>&1
if errorlevel 1 (
  echo [ERROR] No network - check connection, then press any key to retry. / [오류] 네트워크 없음 - 연결 확인 후 아무 키나 눌러 재시도하세요.
  pause
  echo Retrying, please wait: / 재시도 중, 잠시만 기다리세요:
  echo ..........
  ".venv\Scripts\python" "skills\translate-doc\translate.py" "%INPUT%" --target ko
  if not errorlevel 1 goto :success
  echo.
  echo [FAILED] Still failed. / [실패] 여전히 실패했습니다.
)

:keeporiginal
call :keepcopy "%INPUT%"
echo %DATE% %TIME% 失败 FAILED code=1 "%INPUT%" >> "translated\翻译日志.txt" 2>nul || ver>nul
echo Could not reach translation service, original kept, please try again later. / 번역 서비스에 연결하지 못했습니다. 원본은 보관했으니 나중에 다시 시도하세요.
pause
exit /b 1

:success
echo.
echo [DONE] Translation complete, results in translated folder. / [완료] 번역 완료, translated 폴더에서 확인하세요.
echo %DATE% %TIME% 成功 SUCCESS code=0 "%INPUT%" >> "translated\翻译日志.txt" 2>nul || ver>nul
start "" explorer "translated"
pause
exit /b 0

:keepcopy
copy "%~1" "translated\%~n1-原文保留%~x1" >nul 2>&1
echo Original kept as translated\%~n1-原文保留%~x1
echo 원본 보관됨: translated\%~n1-原文保留%~x1
goto :eof
