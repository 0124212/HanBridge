# palimpsest-cn — 사용 설명서 (한국어)

중국어 문서(PDF / Word / PowerPoint / Excel)를 **한국어 또는 영어**로 번역합니다.
**원본 레이아웃이 그대로 유지**됩니다 — 글꼴, 위치, 표, 이미지는 그대로 두고
단어만 번역합니다.

## 1. 준비물

- Windows 10/11, macOS 또는 Linux
- Python 3.11 이상
- 번역할 문서 파일 (`.pdf`, `.docx`, `.pptx`, `.xlsx`)
- 중국에서 VPN 없이 사용: WorkBuddy 토큰 **또는** Baidu 무료 키 **또는** Ollama(완전 오프라인)

## 2. 설치

**Windows (PowerShell):**

```powershell
git clone https://github.com/0124212/palimpsest-cn.git
cd palimpsest-cn
py -3.11 -m venv .venv
.venv\Scripts\activate
pip install -e ".[all]"
```

**macOS / Linux:**

```bash
git clone https://github.com/0124212/palimpsest-cn.git
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

결과물은 원본 파일 옆의 `translated/` 폴더에 저장됩니다.
예: `translated/document.ko.pdf`

## 8. 알아둘 점

- **레이아웃이 보존됩니다.** 글꼴, 위치, 표, 이미지가 원래 자리에 그대로 있습니다.
- **코드·숫자·이름이 보호됩니다.** 기술 용어(예: CNN, AlphaFold, HumanEval)와 금액은 번역되지 않고 그대로 유지됩니다.
- **실패한 문단은 중국어 원문이 남습니다** — 조용히 사라지지 않습니다.
- **스캔 PDF**는 OCR로 자동 처리됩니다.
- **Google 번역은 중국에서 동작하지 않습니다.** `workbuddy`, `baidu`, `ollama` 중 하나를 사용하세요.

## 9. 문제 해결

| 문제 | 해결 방법 |
|------|-----------|
| `WORKBUDDY_API_BASE ... required` | 환경 변수를 설정하고(4번) 터미널을 다시 여세요 |
| `BAIDU_APP_ID ... required` | 환경 변수를 설정하고(5번) 터미널을 다시 여세요 |
| `unknown backend` | 다음 중 하나 사용: `workbuddy baidu ollama translatepy google gemini anthropic` |
| `File not found` | 경로를 따옴표로 감싸세요. 예: `"C:\Users\name\file.pdf"` |
| Python 버전 문제 | https://www.python.org/downloads/ 에서 Python 3.11+ 설치 |
