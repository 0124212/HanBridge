@echo off
REM setup-opencode-dad.bat -- OPTIONAL step 2 / 可选第2步 (only if Dad wants his own OpenCode)
REM 先运行 setup-dad.bat! / Run setup-dad.bat FIRST. All messages bilingual CN/EN.

chcp 65001 >nul
cd /d "%~dp0.."
echo ============================================
echo  爸爸 OpenCode 安装 / Dad's OpenCode Setup
echo ============================================
echo.

REM 1. Check opencode already installed
opencode --version >nul 2>&1
if not errorlevel 1 (
  echo [OK] OpenCode 已安装 / OpenCode already installed.
  goto :config
)

echo 正在安装 OpenCode / Installing OpenCode...

REM 2a. Try npm first (needs node)
where npm >nul 2>&1
if not errorlevel 1 (
  echo 尝试 npm 安装 / Trying npm install...
  call npm install -g opencode-ai
  opencode --version >nul 2>&1
  if not errorlevel 1 (
    echo [OK] npm 安装成功 / Installed via npm.
    goto :config
  )
  echo [..] npm 安装失败，试下一种 / npm failed, trying next method...
)

REM 2b. Try scoop
where scoop >nul 2>&1
if not errorlevel 1 (
  echo 尝试 scoop 安装 / Trying scoop install...
  call scoop install opencode
  opencode --version >nul 2>&1
  if not errorlevel 1 (
    echo [OK] scoop 安装成功 / Installed via scoop.
    goto :config
  )
  echo [..] scoop 安装失败，试下一种 / scoop failed, trying next method...
)

REM 2c. Try choco
where choco >nul 2>&1
if not errorlevel 1 (
  echo 尝试 choco 安装 / Trying choco install...
  call choco install opencode -y
  opencode --version >nul 2>&1
  if not errorlevel 1 (
    echo [OK] choco 安装成功 / Installed via choco.
    goto :config
  )
)

REM 2d. All failed
echo [错误 ERROR] 自动安装失败 / Auto-install failed.
echo 请先安装 Node.js / Please install Node.js first:
echo https://nodejs.org/
echo 然后重新运行本脚本 / Then run this script again.
pause
exit /b 1

:config
REM 3. Write minimal config ONLY if absent (never overwrite)
if not exist "%USERPROFILE%\.config\opencode\opencode.json" (
  if not exist "%USERPROFILE%\.config\opencode" mkdir "%USERPROFILE%\.config\opencode"
  copy "windows\opencode-dad.json" "%USERPROFILE%\.config\opencode\opencode.json" >nul
  echo [OK] 已写入默认配置 / Default config written.
) else (
  echo [OK] 配置已存在，跳过 / Config already exists, skipped.
)

REM 4. Copy translate-doc skill if absent
if not exist "%USERPROFILE%\.config\opencode\skills\translate-doc" (
  mkdir "%USERPROFILE%\.config\opencode\skills\translate-doc" 2>nul
  copy "skills\translate-doc\SKILL.md" "%USERPROFILE%\.config\opencode\skills\translate-doc\" >nul
  copy "skills\translate-doc\translate.py" "%USERPROFILE%\.config\opencode\skills\translate-doc\" >nul
  echo [OK] 翻译技能已安装 / Translate skill installed.
) else (
  echo [OK] 翻译技能已存在，跳过 / Skill already exists, skipped.
)

echo.
echo ============================================
echo  最后一步 / Last step — 连接你自己的账号 / Connect your own account:
echo  1. 运行 opencode / Run: opencode
echo  2. 输入 /connect 选 OpenCode Zen / Type /connect, pick OpenCode Zen
echo  3. 从这里拿钥匙 / Get your key here: https://opencode.ai/auth
echo  4. 粘贴钥匙回车 / Paste the key and Enter
echo  5. 输入 /models 确认 muse-spark 免费版 / Type /models to confirm muse-spark free
echo ============================================
pause
