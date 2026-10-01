# install.ps1 -- One-liner installer for Dad's translator (palimpsest-cn)
# 一键安装 / Run this ONE line in PowerShell (Win+X -> Terminal):
#   powershell -c "irm https://raw.githubusercontent.com/0124212/palimpsest-cn/main/windows/install.ps1 | iex"
# NOTE 若提示禁止运行脚本 / if scripts are blocked: relaunch PowerShell with -ExecutionPolicy Bypass -Scope Process (current window only, no system change).
# What it does: download cn/main zip -> %USERPROFILE%\palimpsest-cn -> run setup-dad.bat.
$ErrorActionPreference = 'Stop'
$dest = Join-Path $HOME 'palimpsest-cn'
$zip = Join-Path $env:TEMP 'palimpsest-cn.zip'
$tmpDir = Join-Path $env:TEMP 'palimpsest-cn-main'
Write-Host '正在下载 / Downloading palimpsest-cn...'
Invoke-RestMethod -Uri 'https://codeload.github.com/0124212/palimpsest-cn/zip/refs/heads/main' -OutFile $zip
Write-Host '正在解压 / Extracting...'
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
Expand-Archive -Path $zip -DestinationPath $env:TEMP -Force
Move-Item $tmpDir $dest
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Write-Host '正在安装 / Installing (setup-dad.bat)...'
& "$dest\windows\setup-dad.bat"
