param([string]$OutDir='')
$ErrorActionPreference='Stop'
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = $env:OUTDIR }
$PY_VER='3.12.7'
$PY_URL="https://www.python.org/ftp/python/$PY_VER/python-$PY_VER-embed-amd64.zip"
$PIP_URL='https://bootstrap.pypa.io/get-pip.py'
$TESS_URL='https://github.com/UB-Mannheim/tesseract/releases/download/v5.4.0.20240606/tesseract-ocr-w64-setup-5.4.0.20240606.exe'
$TESSDATA_BASE='https://github.com/tesseract-ocr/tessdata_fast/raw/main'
$TESSDATA_FILES=@('chi_sim.traineddata','chi_tra.traineddata','eng.traineddata','osd.traineddata')
$FONTS_BASE='https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF'
$FONT_FILES=@('Korean/NotoSansCJKkr-Regular.otf','SimplifiedChinese/NotoSansCJKsc-Regular.otf')

$pyDir=Join-Path $OutDir 'python'
$binDir=Join-Path $OutDir 'bin'
$tessDir=Join-Path $OutDir 'tessdata'
$fontDir=Join-Path $OutDir 'fonts'
$appDir=Join-Path $OutDir 'app'
$tmp=[IO.Path]::Combine([IO.Path]::GetTempPath(),"hb-portable-build3")
@($pyDir,$binDir,$tessDir,$fontDir,$appDir,$tmp)|%{ if(!(Test-Path $_)){New-Item -ItemType Directory -Path $_ -Force|Out-Null} }

function Fetch($url,$dest){ if(Test-Path $dest){ Remove-Item $dest -Force }; Invoke-WebRequest -Uri $url -OutFile $dest; (Get-FileHash $dest -Algorithm SHA256).Hash }

Write-Host '[build] python' -ForegroundColor Cyan
$pyZip=Join-Path $tmp 'py.zip'
Fetch $PY_URL $pyZip
Expand-Archive $pyZip $pyDir -Force
Invoke-WebRequest $PIP_URL -OutFile (Join-Path $tmp 'get-pip.py')
& "$pyDir\python.exe" (Join-Path $tmp 'get-pip.py')
$pth=Join-Path $pyDir "python312._pth"
(Get-Content $pth) -replace '^#import site$','import site' | Set-Content $pth
Add-Content $pth 'Lib\site-packages'
Add-Content $pth '..\app'
