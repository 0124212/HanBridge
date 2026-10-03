# Build-Portable.ps1 -- assemble the portable folder Build-Portable runs in.
# Run ONCE on any Windows PC with internet (yours or Dad's, admin NOT needed):
#   powershell -ExecutionPolicy Bypass -File Build-Portable.ps1 [-DryRun] [-OutDir .\HanBridge-Portable]
# -DryRun (default ON when -OutDir is omitted): print URLs + layout, download nothing.
# Real run: .\Build-Portable.ps1 -OutDir C:\hb-portable   (DryRun auto-off with -OutDir)
# Result is xcopy-able: zip the OutDir, Dad unzips, double-clicks Translate-CN.bat.
param(
  [string]$OutDir = '',
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

# Layout assembled under $OutDir:
#   Translate-CN.bat  (copied from this repo's windows/portable/)
#   python/           (embeddable python 3.12 + pip + .[all] via --target)
#   bin/              (tesseract.exe + leptonica DLLs; QPDF NOT needed -- pikepdf wheel bundles libqpdf)
#   tessdata/         (chi_sim + chi_tra + eng + osd, tessdata_fast)
#   fonts/            (Noto Sans CJK KR + SC -- Malgun/SimSun can't redistribute)
#   app/              (repo copy: skills/, windows/DadTranslate.py, examples/*.zh-ko.toml)
if ([string]::IsNullOrWhiteSpace($OutDir)) { $DryRun = $true }

$PY_VER  = '3.12.7'
$PY_URL  = "https://www.python.org/ftp/python/$PY_VER/python-$PY_VER-embed-amd64.zip"
$PIP_URL = 'https://bootstrap.pypa.io/get-pip.py'
# UB-Mannheim installer, silent-extracted (/S /D=) -- no admin, files copied out, rest deleted.
$TESS_VER = '5.4.0.20240606'
$TESS_URL = "https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-$TESS_VER.exe"
$TESSDATA_BASE = 'https://github.com/tesseract-ocr/tessdata_fast/raw/main'
$TESSDATA_FILES = @('chi_sim.traineddata', 'chi_tra.traineddata', 'eng.traineddata', 'osd.traineddata')
$FONTS_BASE = 'https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF'
$FONT_FILES = @('Korean/NotoSansCJKkr-Regular.otf', 'SimplifiedChinese/NotoSansCJKsc-Regular.otf')

function Step($msg) { Write-Host "[build] $msg" -ForegroundColor Cyan }

if ($DryRun) {
  Step 'DRY RUN -- nothing downloaded. Real run: .\Build-Portable.ps1 -OutDir <dir>'
  Write-Host "  python embeddable : $PY_URL"
  Write-Host "  get-pip           : $PIP_URL"
  Write-Host "  tesseract         : $TESS_URL  (silent /S /D=staging, keep tesseract.exe + leptonica DLLs -> bin/)"
  Write-Host "  tessdata          : $($TESSDATA_FILES -join ', ')  ($TESSDATA_BASE/...)"
  Write-Host "  fonts             : $($FONT_FILES -join ', ')  ($FONTS_BASE/...)"
  Write-Host '  pip target        : python\Lib\site-packages  (repo .[all] from OutDir\app source)'
  Write-Host '  app copy          : skills/ windows/DadTranslate.py examples/palimpsest.zh-ko.toml README* + MANIFEST.txt'
  return
}

Step "OutDir: $OutDir"
$pyDir = Join-Path $OutDir 'python'
$binDir = Join-Path $OutDir 'bin'
$tessDir = Join-Path $OutDir 'tessdata'
$fontDir = Join-Path $OutDir 'fonts'
$appDir = Join-Path $OutDir 'app'
$tmp = Join-Path $env:TEMP 'hb-portable-build'
foreach ($d in @($pyDir, $binDir, $tessDir, $fontDir, $appDir, $tmp)) {
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}
$manifest = @()

function Fetch($url, $dest) {
  $sha = $null
  Invoke-WebRequest -Uri $url -OutFile $dest
  $sha = (Get-FileHash $dest -Algorithm SHA256).Hash
  return $sha
}

# 1. Embeddable python + pip.
Step 'python embeddable...'
$pyZip = Join-Path $tmp 'python-embed.zip'
$manifest += "python-embed $PY_URL $((Fetch $PY_URL $pyZip))"
Expand-Archive -Path $pyZip -DestinationPath $pyDir -Force
$getPip = Join-Path $tmp 'get-pip.py'
Invoke-WebRequest -Uri $PIP_URL -OutFile $getPip
& "$pyDir\python.exe" $getPip
# Embeddable ignores installed site-packages unless the ._pth enables site:
# uncomment `import site`, keep zip + dot, add Lib\site-packages so --target lands on sys.path.
$pth = Join-Path $pyDir 'python312._pth'
(Get-Content $pth) -replace '^#import site$', 'import site' | Set-Content $pth
Add-Content $pth 'Lib\site-packages'
Add-Content $pth '..\app'

# 2. Tesseract portable binaries (silent NSIS extract, keep exe + DLLs only).
Step 'tesseract...'
$tessExe = Join-Path $tmp 'tesseract-setup.exe'
$manifest += "tesseract $TESS_URL $((Fetch $TESS_URL $tessExe))"
$stage = Join-Path $tmp 'tess-stage'
Start-Process $tessExe -ArgumentList '/S', "/D=$stage" -Wait
Copy-Item "$stage\tesseract.exe" $binDir -Force
Copy-Item "$stage\*.dll" $binDir -Force
$manifest += "tesseract-exe $((Get-FileHash (Join-Path $binDir 'tesseract.exe') -Algorithm SHA256).Hash)"
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue

# 3. tessdata + fonts.
Step 'tessdata + fonts...'
foreach ($f in $TESSDATA_FILES) {
  $dest = Join-Path $tessDir $f
  $manifest += "tessdata/$f $TESSDATA_BASE/$f $((Fetch "$TESSDATA_BASE/$f" $dest))"
}
foreach ($f in $FONT_FILES) {
  $dest = Join-Path $fontDir ([IO.Path]::GetFileName($f))
  $manifest += "fonts/$([IO.Path]::GetFileName($f)) $FONTS_BASE/$f $((Fetch "$FONTS_BASE/$f" $dest))"
}

# 4. App copy + pip install .[all] into the portable tree.
Step 'app + pip install...'
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Copy-Item (Join-Path $repoRoot 'skills') (Join-Path $appDir 'skills') -Recurse -Force
Copy-Item (Join-Path $repoRoot 'windows\DadTranslate.py') (Join-Path $appDir 'windows\DadTranslate.py') -Force
Copy-Item (Join-Path $repoRoot 'examples\palimpsest.zh-ko.toml') (Join-Path $appDir 'palimpsest.zh-ko.toml') -Force
Copy-Item (Join-Path $PSScriptRoot 'Translate-CN.bat') $OutDir -Force
Copy-Item (Join-Path $PSScriptRoot 'README-DAD.*.md') $OutDir -Force -ErrorAction SilentlyContinue
& "$pyDir\python.exe" -m pip install --target "$pyDir\Lib\site-packages" "$repoRoot[all]"
$manifest += "palimpsest $((Get-FileHash (Join-Path $appDir 'windows\DadTranslate.py') -Algorithm SHA256).Hash) (repo snapshot)"

# 5. MANIFEST.txt: what + where + SHA256.
Step 'manifest...'
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
@("HanBridge portable manifest -- built $stamp", '') + $manifest | Set-Content (Join-Path $OutDir 'MANIFEST.txt')
Copy-Item (Join-Path $OutDir 'MANIFEST.txt') (Join-Path $appDir 'MANIFEST.txt') -Force

Write-Host '[OK] Portable build done. Zip the OutDir and hand it to Dad.' -ForegroundColor Green
