# install.ps1 -- One-liner installer for Dad's translator (palimpsest-cn)
# Run this ONE line in PowerShell (Win+X -> Terminal): / 아래 한 줄을 PowerShell에 붙여넣기 (Win+X → 터미널):
#   powershell -c "irm https://raw.githubusercontent.com/0124212/palimpsest-cn/main/windows/install.ps1 | iex"
# Bare run = zero prompts: language from OS locale, free backend, Ollama only if
# installed + model present. Params: -Lang ko|en -Backend free|ollama|workbuddy -Yes -Interactive.
param(
  [string]$Lang = '',
  [string]$Backend = '',
  [switch]$Yes,
  [switch]$Interactive
)
# What it does: resolve picks -> download cn/main zip -> $HOME\palimpsest-cn -> run setup-dad.bat.
# Self-relaunch with Bypass for this process only (user-local, no system change):
if ((Get-ExecutionPolicy -Scope Process) -notin @('Bypass', 'Unrestricted')) {
  Write-Host 'Policy blocked, relaunching with -ExecutionPolicy Bypass -Scope Process... / 정책 차단, Bypass로 다시 실행 중...' -ForegroundColor Yellow
  Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-Command',"irm https://raw.githubusercontent.com/0124212/palimpsest-cn/main/windows/install.ps1 | iex" -Wait
  return
}
$ErrorActionPreference = 'Stop'

# Boxed header (cyan) - progress display, no decisions here.
Write-Host '+--------------------------------------------------+' -ForegroundColor Cyan
Write-Host '|  Dad Translator Setup / 아빠 번역기 설치' -ForegroundColor Cyan
Write-Host '|  Zero prompts by default / 기본값은 질문 없음' -ForegroundColor Cyan
Write-Host '+--------------------------------------------------+' -ForegroundColor Cyan
Write-Host ''

# Language: param / env wins; else OS locale (Korean Windows -> KO first); menu ONLY if -Interactive.
if ([string]::IsNullOrWhiteSpace($Lang)) { $Lang = $env:PALIMPSEST_LANG }
$Lang = "$Lang".ToLower()
if ($Lang -in @('ko', 'korean')) { $lang = 'KO' }
elseif ($Lang -in @('en', 'english')) { $lang = 'EN' }
else {
  $loc = (Get-Culture).Name
  $lang = if ($loc -like 'ko*') { 'KO' } else { 'EN' }
  Write-Host "Language auto: $lang ($loc). / 언어 자동: $lang." -ForegroundColor Yellow
  if ($Interactive) {
    $lp = Read-Host 'Pick language / 언어 선택: 1) English (default)  2) 한국어'
    $lang = if ($lp -eq '2') { 'KO' } else { 'EN' }
  }
}

# GPU silent detect: one info line, no menu.
$hasGpu = $null -ne (Get-Command nvidia-smi -ErrorAction SilentlyContinue)
if ($hasGpu) {
  $card = (nvidia-smi -L 2>$null | Select-Object -First 1)
  Write-Host "[...] GPU: $card / GPU 감지" -ForegroundColor Yellow
}

# Backend: param / env wins; else free silently, Ollama only if installed + model present.
if ([string]::IsNullOrWhiteSpace($Backend)) { $Backend = $env:PALIMPSEST_BACKEND }
$Backend = "$Backend".ToLower()
$backend = ''
if ($Backend -in @('1', 'free', 'translatepy')) { $backend = '1' }
elseif ($Backend -in @('2', 'ollama')) { $backend = '2' }
elseif ($Backend -in @('3', 'workbuddy')) { $backend = '3' }
if ($backend -eq '') {
  if ($Interactive) {
    Write-Host '[menu] Pick translation backend / 번역 방식 선택:' -ForegroundColor Cyan
    Write-Host '  1) Free - no key needed, translatepy (default) / 무료 - 키 불필요'
    if ($hasGpu) { Write-Host '  2) Local GPU offline, Ollama 7b private / 로컬 GPU 오프라인' }
    Write-Host '  3) WorkBuddy tokens, needs 3 values / WorkBuddy 토큰, 3개 값 필요'
    $bp = Read-Host 'Choose 1-3 (Enter=1) / 선택 1-3 (Enter=1)'
    $backend = '1'
    if ($bp -eq '2') { $backend = '2' }
    if ($bp -eq '3') { $backend = '3' }
    if (($backend -eq '2') -and (-not $hasGpu)) {
      Write-Host 'No NVIDIA GPU found - using free default. / GPU 없음 - 무료 기본값.' -ForegroundColor Yellow
      $backend = '1'
    }
  } else {
    $backend = '1'
    if ($null -ne (Get-Command ollama -ErrorAction SilentlyContinue)) {
      $models = (ollama list 2>$null)
      if ($models -match 'qwen2.5') {
        $backend = '2'
        Write-Host '[...] Ollama + model found - using local backend. / Ollama + 모델 발견.' -ForegroundColor Yellow
      }
    }
  }
}
# Validate explicit pick; fall back to free when it cannot work.
if ($backend -eq '2') {
  $oll = (Get-Command ollama -ErrorAction SilentlyContinue)
  $models = if ($oll) { (ollama list 2>$null) } else { '' }
  if (($null -eq $oll) -or (-not ($models -match 'qwen2.5'))) {
    Write-Host 'Ollama picked but missing - using free default. / Ollama 미비 - 무료 기본값.' -ForegroundColor Yellow
    $backend = '1'
  }
}
if ($backend -eq '2') {
  if ([string]::IsNullOrWhiteSpace($env:OLLAMA_MODEL)) {
    $env:OLLAMA_MODEL = 'qwen2.5:7b'
    setx.exe OLLAMA_MODEL 'qwen2.5:7b' | Out-Null
    Write-Host '[OK] Ollama model set to qwen2.5:7b. / Ollama 모델 설정됨.' -ForegroundColor Green
  } else {
    Write-Host "[OK] Keeping existing OLLAMA_MODEL ($env:OLLAMA_MODEL). / 기존 모델 유지." -ForegroundColor Green
  }
}
if ($backend -eq '3') {
  if ([string]::IsNullOrWhiteSpace($env:WORKBUDDY_API_KEY)) {
    if ($Yes) {
      Write-Host '[ERROR] WorkBuddy picked but no key and -Yes given - free default. / 키 없고 -Yes - 무료 기본값.' -ForegroundColor Red
      $backend = '1'
    } else {
      Write-Host 'WorkBuddy needs 3 values from Tencent Cloud console. / 콘솔에서 3개 값 확인.' -ForegroundColor Yellow
      $wbBase = Read-Host 'API Base (Enter=default)'
      if ([string]::IsNullOrWhiteSpace($wbBase)) { $wbBase = 'https://tokenhub-intl.tencentcloudmaas.com/v1' }
      $wbModel = Read-Host 'Model (Enter=default deepseek-v4-pro)'
      if ([string]::IsNullOrWhiteSpace($wbModel)) { $wbModel = 'deepseek-v4-pro' }
      $wbKey = Read-Host 'API Key (paste yours)'
      if ([string]::IsNullOrWhiteSpace($wbKey)) {
        Write-Host '[ERROR] No key pasted - falling back to free default. / 키 없음 - 무료 기본값으로 진행.' -ForegroundColor Red
        $backend = '1'
      } else {
        $env:WORKBUDDY_API_BASE = $wbBase
        $env:WORKBUDDY_API_KEY = $wbKey
        $env:WORKBUDDY_MODEL = $wbModel
        setx.exe WORKBUDDY_API_BASE $wbBase | Out-Null
        setx.exe WORKBUDDY_API_KEY $wbKey | Out-Null
        setx.exe WORKBUDDY_MODEL $wbModel | Out-Null
        Write-Host '[OK] WorkBuddy keys saved for this user. / WorkBuddy 키 저장됨.' -ForegroundColor Green
      }
    }
  }
}

# Resolve words for setup-dad.bat flags (single source of truth downstream).
$backendWord = 'free'
if ($backend -eq '2') { $backendWord = 'ollama' }
if ($backend -eq '3') { $backendWord = 'workbuddy' }
$langWord = if ($lang -eq 'KO') { 'ko' } else { 'en' }

$dest = Join-Path $HOME 'palimpsest-cn'
$zip = Join-Path $env:TEMP 'palimpsest-cn.zip'
$tmpDir = Join-Path $env:TEMP 'palimpsest-cn-main'
Write-Host 'Downloading palimpsest-cn... / palimpsest-cn 다운로드 중...' -ForegroundColor Yellow
Invoke-RestMethod -Uri 'https://codeload.github.com/0124212/palimpsest-cn/zip/refs/heads/main' -OutFile $zip
Write-Host 'Extracting... / 압축 해제 중...' -ForegroundColor Yellow
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
Expand-Archive -Path $zip -DestinationPath $env:TEMP -Force
Move-Item $tmpDir $dest
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Write-Host 'Installing (setup-dad.bat)... / 설치 중 (setup-dad.bat)...' -ForegroundColor Yellow
$batArgs = @('--lang', $langWord, '--backend', $backendWord)
if ($Yes) { $batArgs += '--yes' }
if ($Interactive) { $batArgs += '--interactive' }
& "$dest\windows\setup-dad.bat" @batArgs
