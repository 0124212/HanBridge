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
$tmp=Join-Path $env:TEMP 'hb-portable-build2'
@($pyDir,$binDir,$tessDir,$fontDir,$appDir,$tmp)|%{ if(!(Test-Path $_)){New-Item -ItemType Directory -Path $_ -Force|Out-Null} }

function Fetch($url,$dest){ Invoke-WebRequest -Uri $url -OutFile $dest; (Get-FileHash $dest -Algorithm SHA256).Hash }

Write-Host '[build] python...' -ForegroundColor Cyan
$pyZip=Join-Path $tmp 'python-embed.zip'
Fetch $PY_URL $pyZip
Expand-Archive $pyZip $pyDir -Force
Invoke-WebRequest $PIP_URL -OutFile (Join-Path $tmp 'get-pip.py')
& "$pyDir\python.exe" (Join-Path $tmp 'get-pip.py')
$pth=Join-Path $pyDir "python$($PY_VER.Split('.')[0,1]-join'')._pth"
(Get-Content $pth) -replace '^#import site$','import site' | Set-Content $pth
Add-Content $pth 'Lib\site-packages'
Add-Content $pth '..\app'

Write-Host '[build] tesseract...' -ForegroundColor Cyan
$tessExe=Join-Path $tmp 'tess-setup.exe'
Fetch $TESS_URL $tessExe
$stage=Join-Path $tmp 'tess-stage'
Start-Process $tessExe -ArgumentList '/S',"/D=$stage" -Wait
Copy-Item "$stage\tesseract.exe" $binDir -Force
Copy-Item "$stage\*.dll" $binDir -Force

Write-Host '[build] tessdata/fonts...' -ForegroundColor Cyan
foreach($f in $TESSDATA_FILES){ Fetch "$TESSDATA_BASE/$f" (Join-Path $tessDir $f) }
foreach($f in $FONT_FILES){ Fetch "$FONTS_BASE/$f" (Join-Path $fontDir ([IO.Path]::GetFileName($f))) }

Write-Host '[build] app+pip...' -ForegroundColor Cyan
$repoRoot=$PWD.Path
Copy-Item "$repoRoot\skills" (Join-Path $appDir 'skills') -Recurse -Force
Copy-Item "$repoRoot\windows\DadTranslate.py" (Join-Path $appDir 'windows') -Force
Copy-Item "$repoRoot\examples\palimpsest.zh-ko.toml" (Join-Path $appDir) -Force
Copy-Item "$repoRoot\windows\portable\Translate-CN.bat" $OutDir -Force
Copy-Item "$repoRoot\windows\portable\README-DAD.*.md" $OutDir -Force
& "$pyDir\python.exe" -m pip install --target "$pyDir\Lib\site-packages" "$repoRoot[all]"

$manifest=@("HanBridge portable manifest -- built $(Get-Date -Format 'yyyy-MM-dd HH:mm')",'')
foreach($f in $TESSDATA_FILES){ $p=(Join-Path $tessDir $f); $manifest+="tessdata/$f $TESSDATA_BASE/$f $((Get-FileHash $p -Algorithm SHA256).Hash)" }
foreach($f in $FONT_FILES){ $n=[IO.Path]::GetFileName($f); $p=(Join-Path $fontDir $n); $manifest+="fonts/$n $FONTS_BASE/$f $((Get-FileHash $p -Algorithm SHA256).Hash)" }
$manifest | Set-Content (Join-Path $OutDir 'MANIFEST.txt')
Copy-Item (Join-Path $OutDir 'MANIFEST.txt') $appDir -Force
Write-Host '[OK]' -ForegroundColor Green
