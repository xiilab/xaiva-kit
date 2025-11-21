# 구현 계획 (Implementation Plan)

## 개요
이 문서는 기존 프로젝트를 아카이브하고, **완전 오프라인 대응 및 자립형 빌드 시스템**을 갖춘 신규 프로젝트(`xaiva-media-standalone`)를 구축하기 위한 단계별 실행 계획입니다.

---

## Phase 1: 프로젝트 초기화 (Project Initialization)

### 1.1. 디렉토리 구조 생성
새로운 저장소의 기본 골격을 생성합니다.

```text
xaiva-media-docker-unified/
├── artifacts/              # [Git Ignore] 프리셋별 로컬 빌드용 패키지 저장소
│   └── <preset-name>/      # 예: ubuntu22.04-cuda11.8-torch2.1/
│       ├── wheels/         # Python .whl 파일
│       ├── debs/           # apt .deb 패키지 (선택)
│       ├── sources/        # 소스 코드 (tar.gz, git bundle)
│       └── requirements.txt # 해당 프리셋의 Python 패키지 목록
├── docker/
│   └── Dockerfile          # 통합 Multi-stage Dockerfile
├── docs/                   # 가이드 문서
├── legacy/                 # 기존 dockerfile 참고용 보관
│   └── dockerfile
├── presets/                # 빌드 프리셋 JSON 파일들
├── scripts/
│   ├── build.py            # 대화형 빌드 드라이버
│   └── deps_sync.sh        # 의존성 다운로드/동기화 스크립트
├── env.template            # 환경 변수 템플릿
├── .env                    # [Git Ignore] 민감 정보(GitHub Token 등)
├── .gitignore              # artifacts, .env 등 제외 설정
└── README.md
```

**주요 변경사항:**
- `artifacts/` 하위를 프리셋별로 구조화하여 현장 복제 시 필요한 프리셋만 선택적으로 복사 가능
- 각 프리셋 폴더에 `requirements.txt`를 포함하여 Python 패키지를 프리셋별로 독립 관리
- Xaiva Media 소스는 서브트리 또는 외부 경로를 통해 관리 (직접 클론하지 않음)

### 1.2. Git 설정
- `.gitignore`에 `artifacts/`, `.env`, `__pycache__/` 등을 등록하여 대용량 파일과 민감 정보가 커밋되지 않도록 방지합니다.

---

## Phase 2: 데이터 및 설정 설계 (Data & Configuration)

### 2.1. 프리셋 JSON 스키마 확정
`presets/` 폴더에 저장될 JSON 파일 형식을 정의합니다.

**예시: `presets/ubuntu22.04-cuda11.8.json`**
```json
{
  "metadata": {
    "description": "Standard Prod Environment"
  },
  "base_image": "nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04",
  "python_version": "3.10",
  "pytorch": {
    "version": "2.1.0+cu118",
    "components": ["torch", "torchvision", "torchaudio"]
  },
  "tensorrt": {
    "enabled": true,
    "version": "8.6.1"
  },
  "build_options": {
    "ffmpeg_version": "4.2",
    "opencv_version": "4.9.0",
    "xaiva_media_branch": "master"
  }
}
```

### 2.2. Python 의존성 관리
- 각 프리셋 폴더(`artifacts/<preset-name>/requirements.txt`)에 해당 프리셋에 필요한 Python 패키지 목록을 관리합니다.
- 특정 버전이 중요한 경우(예: `numpy`, `scipy`) 버전을 고정합니다.
- PyTorch, TensorRT 등 주요 라이브러리는 프리셋 JSON에서 별도로 버전을 명시하고, requirements.txt에도 포함합니다.
- **TensorRT는 런타임 이미지에 필수 포함**되며, CUDA 버전과 호환성을 확인해야 합니다 (v8.x → CUDA 11.8, v10.x → CUDA 12.x).
- 오프라인 설치를 위해 모든 wheel 파일을 `artifacts/<preset-name>/wheels/` 에 사전 다운로드합니다.

---

## Phase 3: 통합 Dockerfile 구현 (Dockerization)

### 3.1. Multi-stage 구조 설계
`docker/Dockerfile` 하나로 모든 빌드를 처리합니다.

1.  **Builder Stage (`FROM base AS builder`)**
    - 필수 컴파일 도구 설치 (`build-essential`, `cmake`, `git`).
    - `COPY artifacts/sources /tmp/sources`: 소스 코드 반입.
    - FFmpeg, OpenCV, Xaiva Media 소스 컴파일 수행.
    - 결과물을 `/artifacts_out` 같은 임시 경로에 모음.

2.  **Runtime Stage (`FROM base AS runtime`)**
    - 최소 실행 의존성 설치.
    - `COPY --from=builder /artifacts_out /usr/local`: 빌드 결과물 복사.
    - `COPY artifacts/wheels /tmp/wheels`: Python 패키지 반입 및 설치.
    - 불필요한 파일 정리 후 최종 이미지 생성.

### 3.2. Build Arguments (ARG)
- `ARG PYTHON_VERSION`, `ARG TORCH_VERSION`, `ARG PRESET_NAME` 등을 통해 Dockerfile 내부 로직을 동적으로 제어합니다.
- `ARG PRESET_NAME`을 통해 `artifacts/<preset-name>/` 경로를 자동 선택하여 해당 프리셋의 의존성만 복사합니다.
- **Xaiva Media 소스**: `ARG XAIVA_SOURCE_PATH`를 통해 외부 소스 경로를 받거나, 빌드 컨텍스트에 포함된 경로를 사용합니다.

---

## Phase 4: 대화형 빌드 드라이버 개발 (Automation)

### 4.1. `scripts/build.py` 개발
Python 표준 라이브러리만 사용하여 다음 기능을 구현합니다.

1.  **프리셋 로더**: `presets/*.json` 목록을 읽어와 선택지 제공.
2.  **대화형 입력 루프 (Interactive Loop)**:
    - 프리셋 선택 vs 수동 입력.
    - Base Image, Python, PyTorch, TensorRT, Build Type(Runtime/Dev) 순차 입력.
3.  **Docker 커맨드 생성기**:
    - 사용자 입력 + `.env` 토큰 조합.
    - `docker build -t <tag> --build-arg ...` 명령어 조합 및 실행.

### 4.2. `scripts/deps_sync.sh` 개발 (선택 사항)
- 인터넷이 연결된 개발 환경에서 실행 시, 프리셋에 정의된 파일들을 다운로드하여 `artifacts/<preset-name>/` 폴더를 채워주는 쉘 스크립트입니다.
- 사용 예: `./scripts/deps_sync.sh ubuntu22.04-cuda11.8-torch2.1`
- Python wheel 파일은 `pip download -r requirements.txt -d wheels/` 형태로 자동 수집합니다.

---

## Phase 5: 검증 및 문서화 (Verification & Docs)

### 5.1. 오프라인 빌드 테스트
1.  인터넷 연결을 차단(또는 `docker build --network none`)한 상태에서 빌드가 성공하는지 테스트합니다.
2.  `artifacts/` 폴더만 있으면 어디서든 빌드 가능한지 검증합니다.

### 5.2. 가이드 문서 작성
- `docs/build-guide.md`: USB를 들고 현장에 갔을 때의 절차(Artifacts 복사 -> 스크립트 실행)를 상세히 기술합니다.

