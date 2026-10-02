# install.ps1 -- One-liner installer for Dad's translator (palimpsest-cn)
# Run this ONE line in PowerShell (Win+X -> Terminal): / 아래 한 줄을 PowerShell에 붙여넣기 (Win+X → 터미널):
#   powershell -c "irm https://raw.githubusercontent.com/0124212/palimpsest-cn/main/windows/install.ps1 | iex"
# What it does: download cn/main zip -> $HOME\palimpsest-cn -> run setup-dad.bat.
# Self-relaunch with Bypass for this process only (user-local, no system change):
if ((Get-ExecutionPolicy -Scope Process) -notin @('Bypass', 'Unrestricted')) {
  Write-Host 'Policy blocked, relaunching with -ExecutionPolicy Bypass -Scope Process... / 정책 차단, Bypass로 다시 실행 중...'
  Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-Command',"irm https://raw.githubusercontent.com/0124212/palimpsest-cn/main/windows/install.ps1 | iex" -Wait
  return
}
$ErrorActionPreference = 'Stop'
$dest = Join-Path $HOME 'palimpsest-cn'
$zip = Join-Path $env:TEMP 'palimpsest-cn.zip'
$tmpDir = Join-Path $env:TEMP 'palimpsest-cn-main'
Write-Host 'Downloading palimpsest-cn... / palimpsest-cn 다운로드 중...'
Invoke-RestMethod -Uri 'https://codeload.github.com/0124212/palimpsest-cn/zip/refs/heads/main' -OutFile $zip
Write-Host 'Extracting... / 압축 해제 중...'
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
Expand-Archive -Path $zip -DestinationPath $env:TEMP -Force
Move-Item $tmpDir $dest
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Write-Host 'Installing (setup-dad.bat)... / 설치 중 (setup-dad.bat)...'
& "$dest\windows\setup-dad.bat"
