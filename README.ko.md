# HanBridge — 사용 설명서 (한국어)

중국어 문서(PDF / Word / PowerPoint / Excel)를 **한국어 또는 영어**로 번역합니다.
**원본 레이아웃이 그대로 유지**됩니다 — 글꼴, 위치, 표, 이미지는 그대로 두고
단어만 번역합니다.

> SmartScreen blocked the zip? Right-click it → Properties → check Unblock (or `Unblock-File -Recurse .` in PowerShell). No admin needed — user-local only (HKCU + %LOCALAPPDATA%, never HKLM). / SmartScreen 경고 시 zip 우클릭 → 속성 → 차단 해제 (또는 PowerShell `Unblock-File -Recurse .`). 관리자 불필요 — 현재 사용자 영역만 사용 (HKCU + %LOCALAPPDATA%, HKLM 기록 없음).

## 아빠 3단계 / 3 steps (Windows 11)

1. Win+X로 터미널 열고 아래 한 줄 붙여넣기 + Enter:
   `powershell -c "irm https://raw.githubusercontent.com/0124212/HanBridge/main/windows/install.ps1 | iex"`
2. 설치가 끝날 때까지 대기 (바탕화면에 "Chinese Translator" 생성)
3. 중국어 PDF / PPT를 바탕화면 "Chinese Translator"에 드래그 → `translated` 폴더에서 번역문 확인

수동 방법 / Manual fallback: zip 다운로드·압축 풀기 → `windows\setup-dad.bat` 더블클릭 → 위 3단계로.

> GPU 안내 (선택 OPTIONAL): 설치 시 nvidia-smi로 자동 감지 — VRAM 12GB+ NVIDIA 카드(이 PC의 RTX 3060 12GB 등)면 Ollama 7b 로컬 모델로 빠르고 비공개적인 오프라인 번역이 가능합니다. 안 해도 됩니다.
>
> ```bat
> ollama pull qwen2.5:7b
> setx OLLAMA_MODEL "qwen2.5:7b"
> REM 번역할 때 --backend ollama 를 붙이면 오프라인 번역
> ```

> API 키 1분 (WorkBuddy 번역에만 필요; 무료 translatepy는 불필요):
> Tencent Cloud 콘솔 → API Key 관리에서 3개 값을 확인하고, 아래 3줄을 복사·붙여넣기 (2번째 줄만 네 키로 교체):
>
> ```bat
> setx WORKBUDDY_API_BASE "https://tokenhub-intl.tencentcloudmaas.com/v1"
> setx WORKBUDDY_API_KEY "여기에-키-붙여넣기"
> setx WORKBUDDY_MODEL "deepseek-v4-pro"
> ```
>
> 주의: 키는 환경 변수에만 넣고, palimpsest.toml에는 절대 쓰지 마세요.

## 1. 준비물

- Windows 10/11, macOS 또는 Linux
- Python 3.11 이상
- 번역할 문서 파일 (`.pdf`, `.docx`, `.pptx`, `.xlsx`)
- 중국에서 VPN 없이 사용: WorkBuddy 토큰 **또는** Baidu 무료 키 **또는** Ollama(완전 오프라인)

## 2. 설치

**Windows (PowerShell):**

```powershell
git clone https://github.com/0124212/HanBridge.git
cd palimpsest-cn
py -3.11 -m venv .venv
.venv\Scripts\activate
pip install -e ".[all]"
```

**macOS / Linux:**

```bash
git clone https://github.com/0124212/HanBridge.git
cd palimpsest-cn
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[all]"
```

## 3. 번역 엔진 선택

| 엔진 | VPN 필요? | 비용 | 용도 |
|------|-----------|------|------|
| `workbuddy` | 아니오 | WorkBuddy 토큰 사용 | **WorkBuddy 토큰 사용 — 권장** |
| `baidu` | 아니오 | 무료 (하루 5만자) | **중국, VPN 불필요** |
| `ollama` | 아니오 | 무료 (내 PC에서 실행) | **완전 오프라인** |
| `translatepy` | 아니오 | 무료 | 빠른 테스트, 키 불필요 (품질 낮음) |
| `google` | 예 (중국에서 차단) | 무료 | 중국 외 지역에서만 |
| `gemini` | 예 | 무료 tier | 중국 외 지역에서만 |
| `anthropic` | 예 | 유료 | 최고 품질 |

## 4. WorkBuddy 설정 (권장 — 기존 토큰 사용)

WorkBuddy 토큰은 Tencent Cloud TokenHub/Token Plan 크레딧이며,
OpenAI 호환 엔드포인트로 사용합니다. Tencent Cloud 콘솔에서
세 가지 값을 확인하세요:

1. **API Base** — TokenHub: `https://tokenhub-intl.tencentcloudmaas.com/v1`
   또는 Token Plan: `https://tokenhub-intl.tencentcloudmaas.com/plan/v3`
   (중국/광저우 Token Plan: `https://tokenhub.tencentcloudmaas.com/plan/v3`)
2. **API Key** — API 키 관리에서 생성, 사용 모델 범위가 포함되어야 합니다.
3. **Model** — 정확한 모델 ID, 예: `deepseek-v4-pro`
   (Token Plan은 가입 플랜의 모델 목록에서 선택).

환경 변수로 설정하세요:

**Windows (PowerShell, 영구 저장):**

```powershell
setx WORKBUDDY_API_BASE "https://tokenhub-intl.tencentcloudmaas.com/v1"
setx WORKBUDDY_API_KEY "여기에-키-붙여넣기"
setx WORKBUDDY_MODEL "deepseek-v4-pro"
```

터미널을 닫았다가 다시 열고 `.venv`를 활성화하세요.

**macOS / Linux:**

```bash
export WORKBUDDY_API_BASE="https://tokenhub-intl.tencentcloudmaas.com/v1"
export WORKBUDDY_API_KEY="여기에-키-붙여넣기"
export WORKBUDDY_MODEL="deepseek-v4-pro"
```

키는 본인 PC에만 보관하세요 — 채팅에 붙여넣거나 커밋하지 마세요.

### 먼저 엔드포인트 확인 (10초, 비용 거의 없음)

실제 문서를 번역하기 **전에** 실행하세요. 한 단어를 번역하면서
Base URL·키·모델 ID가 모두 맞는지 증명합니다:

**Windows (PowerShell):**

```powershell
$base = $env:WORKBUDDY_API_BASE.TrimEnd('/')
if (-not $base.EndsWith('/chat/completions')) { $base += '/chat/completions' }
$body = @{ model = $env:WORKBUDDY_MODEL
  messages = @(@{ role = 'user'; content = 'Translate to Korean: 你好' })
  max_tokens = 20; temperature = 0.1 } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri $base -Method Post `
  -Headers @{ Authorization = "Bearer $($env:WORKBUDDY_API_KEY)" } `
  -ContentType 'application/json' -Body $body
```

**macOS / Linux:**

```bash
base="${WORKBUDDY_API_BASE%/}"
[[ "$base" == */chat/completions ]] || base="$base/chat/completions"
curl -s "$base" -H "Authorization: Bearer $WORKBUDDY_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"$WORKBUDDY_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Translate to Korean: 你好\"}],\"max_tokens\":20,\"temperature\":0.1}"
```

| 응답 | 의미 | 다음 단계 |
|------|------|-----------|
| 답에 `안녕하세요` | Base URL ✓ 키 ✓ 모델 ✓ — 번역 시작 | 없음, 동작합니다 |
| `401` / `403` | 키 오류, 권한 범위 누락, 인증 방식 상이 | Tencent 콘솔에서 키 범위 확인 |
| `404` | Base URL 또는 모델 ID 오류 | 콘솔에서 한 글자씩 대조 |
| 시간 초과 / 연결 불가 | 이 PC의 네트워크 문제 | 다른 엔드포인트 호스트 시도 (intl vs 중국) |

## 5. Baidu 설정 (중국, 토큰이 없을 때)

1. https://fanyi-api.baidu.com/product/11 에서 가입합니다.
2. 앱을 만들고 **APP_ID**와 **SECRET_KEY**를 복사합니다.
3. 환경 변수로 설정합니다:

```powershell
# Windows
setx BAIDU_APP_ID "your_app_id"
setx BAIDU_SECRET_KEY "your_secret_key"
```

```bash
# macOS / Linux
export BAIDU_APP_ID="your_app_id"
export BAIDU_SECRET_KEY="your_secret_key"
```

## 6. Ollama 설정 (완전 오프라인)

1. https://ollama.ai 에서 Ollama를 설치합니다.
2. 모델을 받습니다:

```bash
ollama pull qwen2.5
```

3. (선택) 모델 지정:

```bash
# macOS / Linux
export OLLAMA_MODEL="qwen2.5"
```

```powershell
# Windows
setx OLLAMA_MODEL "qwen2.5"
```

## 7. 번역하기 (가장 쉬운 방법)

새 터미널마다 먼저 가상환경을 활성화하세요:

```powershell
# Windows
.venv\Scripts\activate
```

```bash
# macOS / Linux
source .venv/bin/activate
```

번역 명령:

```bash
# 중국어 → 한국어 (기본값, WorkBuddy 토큰 사용)
python skills/translate-doc/translate.py "document.pdf" --backend workbuddy

# 중국어 → 영어
python skills/translate-doc/translate.py "document.pdf" --target en --backend workbuddy

# 파워포인트
python skills/translate-doc/translate.py "slides.pptx" --backend workbuddy

# 워드
python skills/translate-doc/translate.py "report.docx" --target en --backend workbuddy

# 이중언어 출력 (원문 + 번역 나란히)
python skills/translate-doc/translate.py "paper.pdf" --backend workbuddy --dual

# 완전 오프라인
python skills/translate-doc/translate.py "document.pdf" --backend ollama
```

키가 하나도 없나요? `--backend`를 빼세요 — 래퍼 기본값이 `translatepy`
(무료, 키 불필요, 중국어→한국어 검증됨)입니다. Baidu나 WorkBuddy보다
품질은 낮지만 바로 동작합니다:

```bash
python skills/translate-doc/translate.py "document.pdf"
```

결과물은 원본 파일 옆의 `translated/` 폴더에 저장됩니다.
예: `translated/document.ko.pdf`

## 8. 번역하기 (직접 CLI)

위 래퍼 스크립트를 권장합니다 — 설정을 자동으로 만들어주기 때문입니다.
`palimpsest`를 직접 쓰려면 문서와 같은 폴더에 `palimpsest.toml`을 만드세요:

```toml
[language]
source = "zh"
target = "ko"        # 영어 출력은 "en"

[backend]
name = "workbuddy"   # 또는 "baidu", "ollama", "translatepy", "google"
fallback = "translatepy"

[paths]
source_dir = "."
output_dir = "./translated"
```

실행:

```bash
palimpsest translate "document.pdf" --backend workbuddy -o "translated/document.ko.pdf"
palimpsest translate "slides.pptx" --backend workbuddy --dual -o "translated/slides.ko.pptx"
```

## 9. 알아둘 점

- **레이아웃이 보존됩니다.** 글꼴, 위치, 표, 이미지가 원래 자리에 그대로 있습니다.
- **코드·숫자·이름이 보호됩니다.** 기술 용어(예: CNN, AlphaFold, HumanEval)와 금액은 번역되지 않고 그대로 유지됩니다.
- **실패한 문단은 중국어 원문이 남습니다** — 조용히 사라지지 않습니다.
- **스캔 PDF**는 OCR로 자동 처리됩니다.
- **Google 번역은 중국에서 동작하지 않습니다.** `workbuddy`, `baidu`, `ollama` 중 하나를 사용하세요.

## 10. 손대지 않는 것 (그림, 표, 글꼴)

단어만 바뀝니다. 나머지가 유지되는 이유:

- **Word / PowerPoint / Excel** — 파일 압축을 풀고 *텍스트만* 바꿉니다.
  이미지, 다이어그램, 도형, 차트, 벡터, 위치, 글꼴, 스타일은
  바이트 그대로 복사됩니다(압축·타임스탬프 유지). 표는 격자 그대로,
  셀 텍스트만 번역됩니다.
- **PDF** — 이미지·선아트는 건드리지 않고 텍스트만 지운 뒤, 원본 좌표에
  실제 내장 글꼴로 번역을 다시 그립니다. 다단·표 구조가 유지됩니다.
- **숫자·이름·코드**는 그대로 유지됩니다(예: CNN, AlphaFold, 금액).
- **조용히 버려지는 문단이 없습니다.** 번역 실패 문단은 중국어 원문이
  남고 보고됩니다(`failures=0`이면 깨끗한 실행).
- **순수 중국어 문단도 번역됩니다** — 영어 없는 제목·표제도 포함.

2026-09-21 검증: 중국어 Word 파일(순수 중국어 포함 3문단 + 2×2 표) →
한국어, 7/7 텍스트 노드, 표 구조 유지, 손실 0 — 무료 `translatepy`와
Gemini 모두에서 확인.

정직한 한계 하나: PDF 출력에는 한국어 지원 글꼴이 PC에 필요합니다.
한국어가 네모(□)로 나오면 글꼴을 설치하고(예: Noto Sans CJK KR)
다시 실행하세요.

## 11. 문제 해결

| 문제 | 해결 방법 |
|------|-----------|
| `WORKBUDDY_API_BASE ... required` | 환경 변수를 설정하고(4번) 터미널을 다시 여세요 |
| `BAIDU_APP_ID ... required` | 환경 변수를 설정하고(5번) 터미널을 다시 여세요 |
| `unknown backend` | 다음 중 하나 사용: `workbuddy baidu ollama translatepy google gemini anthropic` |
| `File not found` | 경로를 따옴표로 감싸세요. 예: `"C:\Users\name\file.pdf"` |
| Python 버전 문제 | https://www.python.org/downloads/ 에서 Python 3.11+ 설치 |
