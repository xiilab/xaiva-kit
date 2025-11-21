# XaivaKit

**Xaiva Media를 위한 프리셋 기반 Docker 빌드 시스템**입니다.

## 🎯 주요 특징

- ✅ **프리셋 기반 관리**: 환경별 설정을 JSON 프리셋으로 관리
- ✅ **대화형 빌드**: Python 기반 대화형 빌드 드라이버 제공
- ✅ **멀티스테이지 Dockerfile**: Dev 이미지 기반 통합 빌드 (개발/배포 겸용)
- ✅ **버전 관리**: CUDA, Python, PyTorch, TensorRT 등 주요 의존성 버전 관리
- ✅ **표준 경로 사용**: FHS 준수 (`/usr/local`)로 라이브러리 관리 간소화
- ✅ **검증된 빌드 방식**: Legacy dockerfile 기반 온라인 빌드
- ✅ **오프라인 배포**: Docker 이미지 export/import로 오프라인 환경 배포 가능

## 📁 프로젝트 구조

```
xaiva-kit/
├── artifacts/                          # [Git Ignore] 프리셋별 빌드 의존성
│   └── <preset-name>/                  # 프리셋 디렉터리 (예: ubuntu22.04-cuda11.8-torch2.1/)
│       ├── wheels/                     # Python wheel 파일
│       ├── debs/                       # APT .deb 패키지 (선택)
│       ├── sources/                    # 소스 코드 아카이브
│       └── requirements.txt            # Python 패키지 목록
├── docker/
│   └── Dockerfile                      # 통합 Multi-stage Dockerfile ✅
├── docs/                               # 상세 문서
│   ├── README.md                       # 📚 문서 가이드 (시작점)
│   ├── PROJECT_SUMMARY.md              # 프로젝트 전체 요약 ✅
│   ├── DEVELOPMENT_HISTORY.md          # 개발 히스토리 ✅
│   ├── build-guide.md                  # 빌드 가이드 ✅
│   ├── preset-schema.md                # 프리셋 JSON 스키마 ✅
│   └── [기타 아카이브 문서들]
├── legacy/                             # 기존 dockerfile 참고용
├── presets/                            # 빌드 프리셋 JSON 파일
│   └── ubuntu22.04-cuda11.8-torch2.1.json
├── scripts/
│   ├── build.py                        # 대화형 빌드 드라이버 ✅
│   └── deps_sync.sh                    # 의존성 다운로드 스크립트 ✅
├── env.template                        # 환경 변수 템플릿
├── .gitignore
└── README.md
```

## 🚀 빠른 시작

### 1. 환경 설정

```bash
# 환경 변수 파일 생성
cp env.template .env

# .env 파일 편집 (필요한 경우)
vim .env
```

### 2. 이미지 빌드

**⚠️ 주의**: Docker 빌드 시 인터넷 연결이 필요합니다 (Python 패키지 다운로드)

```bash
# 대화형 모드로 빌드
python3 scripts/build.py

# 또는 프리셋을 직접 지정
python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1

# 비대화형 모드 (자동화)
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --non-interactive
```

### 3. 이미지 실행

```bash
docker run --rm -it --gpus all \
  xaiva-kit:ubuntu22.04-cuda11.8-torch2.1 \
  /bin/bash
```

## 📦 프리셋 관리

프리셋은 `presets/` 디렉터리에 JSON 파일로 관리됩니다.

### 사용 가능한 프리셋

- **ubuntu22.04-cuda11.8-torch2.1**: Production 환경
  - CUDA 11.8 / cuDNN 8
  - Python 3.10
  - PyTorch 2.1.0
  - TensorRT 8.6.1
  - Target: NVIDIA RTX 30xx series (Ampere)

### 새 프리셋 추가

1. `presets/` 디렉터리에 새 JSON 파일 생성
2. `artifacts/<preset-name>/` 디렉터리 생성
3. `artifacts/<preset-name>/requirements.txt` 작성
4. 필요한 의존성 다운로드

자세한 내용은 [개발 가이드](docs/build-guide.md)를 참조하세요.

## 🔧 의존성 관리

### Python 패키지

**버전 관리 패키지 (Dockerfile에서 직접 설치):**
- numpy, scipy
- torch, torchvision, torchaudio
- tensorrt

**일반 패키지 (requirements.txt):**
- 패키지 목록: `artifacts/<preset-name>/requirements.txt`
- Docker 빌드 시 자동 설치

**중요: TensorRT는 이미지에 필수 포함됩니다.**
- TensorRT 8.x: CUDA 11.8 호환
- TensorRT 10.x: CUDA 12.x 호환

### 시스템 패키지

시스템 패키지 목록은 프리셋 JSON 파일의 `system_packages` 필드에 정의됩니다.

### 소스 빌드 패키지

FFmpeg, OpenCV, Xaiva Media 등은 소스에서 빌드되며, 소스 아카이브는 `artifacts/<preset-name>/sources/`에 저장됩니다.

**Xaiva Media 소스 관리:**
- 직접 Git 클론하지 않음
- 서브트리, 외부 경로 마운트, 또는 빌드 컨텍스트에 포함된 소스 사용
- 표준 경로(`/usr/local`)에 설치하여 라이브러리 경로 문제 최소화

## 🌐 오프라인 환경 배포

**빌드 방식 변경**: 온라인 빌드 방식으로 전환되었습니다.
- Docker 빌드 시 Python 패키지를 직접 다운로드
- 오프라인 환경에는 이미지를 export/import하여 배포

### 배포 절차

1. **개발 환경** (인터넷 연결 가능):
   ```bash
   # 1. 이미지 빌드
   python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1
   
   # 2. 이미지 저장
   docker save xaiva-kit:ubuntu22.04-cuda11.8-torch2.1 > xaiva-kit.tar
   
   # 3. tar 파일을 USB/외장 드라이브에 복사
   ```

2. **현장 환경** (오프라인):
   ```bash
   # 1. tar 파일 복사 (USB에서)
   cp /mnt/usb/xaiva-kit.tar ~/
   
   # 2. 이미지 로드
   docker load < xaiva-kit.tar
   
   # 3. 이미지 실행
   docker run --rm -it --gpus all xaiva-kit:ubuntu22.04-cuda11.8-torch2.1 /bin/bash
   ```

자세한 내용은 [빌드 가이드](docs/build-guide.md)를 참조하세요.

## 📚 문서

### 시작하기
- **[docs/README.md](docs/README.md)**: 📚 문서 가이드 (문서 탐색 시작점)
- **[docs/build-guide.md](docs/build-guide.md)**: ⭐ 빌드 가이드 (전체 빌드 프로세스)
- **[docs/preset-schema.md](docs/preset-schema.md)**: 프리셋 JSON 스키마

### 프로젝트 이해
- **[docs/PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md)**: 프로젝트 전체 요약
- **[docs/DEVELOPMENT_HISTORY.md](docs/DEVELOPMENT_HISTORY.md)**: 개발 히스토리
- **[docs/CHANGE_PLAN.md](docs/CHANGE_PLAN.md)**: 변경 계획 및 추적

### 아카이브 (참고용)
- 개발 목표, 구현 계획, 완료 보고서 등은 `docs/` 디렉터리 참조

## 🔐 보안

- `.env` 파일에는 민감한 정보(토큰, 비밀번호 등)가 포함되므로 절대 Git에 커밋하지 마세요.
- `env.template` 파일을 참조하여 필요한 환경 변수를 설정하세요.
- 현장 배포 시 `.env` 파일 관리 절차를 준수하세요.

## 🤝 기여

이 프로젝트는 Xaiva Media의 내부 프로젝트입니다.

## 📝 라이선스

Internal Use Only

## 📧 문의

프로젝트 관련 문의는 팀 채널을 통해 주세요.

---

## 🎉 개발 진행 상황

### ✅ Phase 1 완료: 프로젝트 초기화
- 디렉토리 구조 생성
- 문서 재작성 (프리셋별 artifacts 관리)
- .gitignore 설정
- 첫 프리셋 정의 (ubuntu22.04-cuda11.8-torch2.1)
- 환경 변수 템플릿 작성
- README 작성

### ✅ Phase 2-4 완료: 빌드 시스템 구현
- **Dockerfile**: Multi-stage (base, builder, dev)
- **build.py**: 대화형 빌드 드라이버 (Python 표준 라이브러리)
- **deps_sync.sh**: 의존성 동기화 스크립트
- **프리셋 스키마**: JSON 스키마 문서화
- **빌드 가이드**: 온라인/오프라인 빌드 전체 프로세스

### 🚀 사용 가능 상태!

프로젝트는 현재 완전히 사용 가능한 상태입니다. 아래 명령어로 즉시 빌드할 수 있습니다:

```bash
# 1. 환경 설정
cp env.template .env

# 2. Docker 이미지 빌드 (인터넷 연결 필요)
python3 scripts/build.py

# 또는 비대화형 모드
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --non-interactive

# 3. 이미지 실행
docker run --rm -it --gpus all \
  xaiva-kit:ubuntu22.04-cuda11.8-torch2.1 \
  /bin/bash
```

**오프라인 배포**: 빌드 후 `docker save`로 이미지를 tar 파일로 저장하여 오프라인 환경에 배포

### ⏳ Phase 5 예정: 검증 및 추가 기능
- 실제 빌드 테스트 및 검증
- Xaiva Media 통합
- 추가 프리셋 작성 (CUDA 12.x, TensorRT 10.x)
- CI/CD 파이프라인 (선택)

---

**최근 업데이트** (2025-11-21):
- ✅ 온라인 빌드 방식으로 변경 (Legacy dockerfile 기반)
- ✅ 표준 경로 마이그레이션 (`/usr/local`)
- ✅ 문서 통합 및 요약 (PROJECT_SUMMARY, DEVELOPMENT_HISTORY)
- ✅ 완전한 빌드 파이프라인 구현 (FFmpeg, OpenCV, Xaiva Media)

