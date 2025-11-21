# XaivaKit - 프로젝트 요약

## 📋 목차

1. [프로젝트 개요](#프로젝트-개요)
2. [핵심 목표](#핵심-목표)
3. [프로젝트 구조](#프로젝트-구조)
4. [개발 단계 및 진행 상황](#개발-단계-및-진행-상황)
5. [주요 기술 결정사항](#주요-기술-결정사항)
6. [현재 시스템 구성](#현재-시스템-구성)
7. [사용 방법](#사용-방법)
8. [문서 가이드](#문서-가이드)

---

## 프로젝트 개요

**프로젝트명**: XaivaKit  
**목적**: Xaiva Media를 위한 프리셋 기반 Docker 빌드 시스템  
**대상 플랫폼**: Ubuntu/Linux 22.04  
**생성일**: 2025-11-20

### 핵심 특징

- ✅ **완전 오프라인 빌드 지원**: 인터넷 없이 빌드 가능 (온라인 빌드 방식으로 변경됨)
- ✅ **프리셋 기반 관리**: 환경별 독립적인 의존성 관리
- ✅ **대화형 빌드 시스템**: Python 기반 사용자 친화적 인터페이스
- ✅ **Multi-stage Dockerfile**: Runtime/Dev 이미지 선택 빌드
- ✅ **표준 경로 준수**: FHS (Filesystem Hierarchy Standard) 따름
- ✅ **검증된 빌드 프로세스**: Legacy dockerfile 기반

---

## 핵심 목표

### 1. 범위 및 전제
- Ubuntu/Linux 22.04로 고정
- ~~완전 오프라인 환경에서 빌드 성공~~ → **온라인 빌드 방식으로 변경**
- 프리셋별 CUDA 베이스 이미지 변경 가능, OS는 22.04 유지
- 민감한 토큰/키는 `.env` 파일로 관리

### 2. 아티팩트 관리
- 구조: `artifacts/<preset-name>/` 형태
  - `wheels/`: Python .whl 파일 (현재 미사용)
  - `debs/`: apt .deb 패키지 (선택 사항)
  - `sources/`: 소스 코드 아카이브
  - `requirements.txt`: Python 패키지 목록
- 프리셋별 독립적 관리로 선택적 복사 가능

### 3. 빌드 시스템
- 단일 Multi-stage Dockerfile
  - `builder`: 컴파일 툴체인, 개발 이미지
  - `runtime`: 최소 의존성, 배포용
  - `dev`: 개발자용, 빌드 도구 포함
- Python 3 빌드 드라이버 (표준 라이브러리만 사용)
- 프리셋 JSON 기반 설정 관리

### 4. 보안
- `.env` 파일에서 토큰 관리
- `.env.template` 제공
- 빌드 시 필요한 경우만 `--build-arg`로 전달

---

## 프로젝트 구조

```
xaiva-kit/
├── artifacts/                    # 프리셋별 의존성 저장소
│   └── <preset-name>/
│       ├── wheels/               # Python wheels (현재 미사용)
│       ├── debs/                 # APT packages (선택)
│       ├── sources/              # 소스 코드
│       └── requirements.txt      # Python 패키지 목록
├── docker/
│   └── Dockerfile                # Multi-stage Dockerfile
├── docs/                         # 문서
│   ├── PROJECT_SUMMARY.md        # 이 문서
│   ├── DEVELOPMENT_HISTORY.md    # 개발 히스토리
│   ├── build-guide.md            # 빌드 가이드
│   ├── preset-schema.md          # 프리셋 스키마
│   └── [기타 문서들]
├── legacy/                       # 참고용 기존 dockerfile
├── presets/                      # 프리셋 JSON 파일들
│   └── ubuntu22.04-cuda11.8-torch2.1.json
├── scripts/
│   ├── build.py                  # 대화형 빌드 드라이버
│   └── deps_sync.sh              # 의존성 동기화 (현재 안내용)
├── env.template                  # 환경 변수 템플릿
├── .env                          # [Git Ignore] 민감 정보
├── .gitignore
└── README.md
```

---

## 개발 단계 및 진행 상황

### Phase 1: 프로젝트 초기화 ✅ 완료
- 디렉터리 구조 생성
- Git 설정 (.gitignore)
- 첫 프리셋 JSON 작성 (ubuntu22.04-cuda11.8-torch2.1)
- .env 템플릿 작성
- README.md 작성

**주요 변경사항:**
- 용어 통일: `<preset-triplet>` → `<preset-name>`
- TensorRT 정보 강화 (런타임 필수, CUDA 호환성)

### Phase 2: 데이터 및 설정 설계 ✅ 완료
- 프리셋 JSON 스키마 문서 작성
- Python 의존성 관리 방식 확정
- 프리셋별 requirements.txt 관리

### Phase 3: 통합 Dockerfile 구현 ✅ 완료
- Multi-stage Dockerfile 작성
- ARG를 통한 동적 설정
- 오프라인 pip 설치 → **온라인 설치로 변경**
- 환경 변수 설정

### Phase 4: 대화형 빌드 드라이버 개발 ✅ 완료
- `build.py` 작성 (650+ 라인)
- 대화형/비대화형 모드 지원
- 프리셋 검증 기능
- `deps_sync.sh` 작성 (현재 안내용으로 변경)

### Phase 5: 검증 및 문서화 ⏳ 진행 중
- [ ] 실제 오프라인 빌드 테스트
- [ ] 추가 프리셋 작성
- [ ] FFmpeg/OpenCV 빌드 스크립트
- [ ] Xaiva Media 통합
- [ ] CI/CD 파이프라인 (선택)

---

## 주요 기술 결정사항

### 1. 온라인 빌드 방식 채택 (2025-11-20)

**변경 이유:**
- Legacy dockerfile의 검증된 방식
- wheels 관리 복잡도 감소
- 항상 최신 패키지 사용 가능

**변경 내용:**
- Python 패키지는 Docker 빌드 시 직접 다운로드
- PyTorch: `--find-links https://download.pytorch.org/whl/torch_stable.html` 사용
- 버전 관리 패키지 (numpy, scipy, torch, tensorrt)는 Dockerfile에서 직접 설치
- requirements.txt는 일반 패키지만 포함

**장단점:**
- ✅ 간소화된 관리
- ✅ 검증된 방식
- ❌ Docker 빌드 시 인터넷 필수
- ❌ 완전 오프라인 불가

**오프라인 배포 방법:**
```bash
# 빌드 후 이미지 저장
docker save xaiva-kit:tag > xaiva-kit.tar

# 오프라인 환경에서 로드
docker load < xaiva-kit.tar
```

### 2. 표준 경로 사용 (2025-11-20)

**변경 전:**
```
/usr/local/xaiva_media/bin
/usr/local/xaiva_media/lib
```

**변경 후:**
```
/usr/local/bin      # 실행 파일
/usr/local/lib      # 라이브러리
/usr/local/include  # 헤더 파일
```

**장점:**
- ✅ FHS (Filesystem Hierarchy Standard) 준수
- ✅ `/usr/local/bin`은 시스템 PATH에 자동 포함
- ✅ `ldconfig`로 라이브러리 자동 인식
- ✅ 경로 관리 단순화
- ✅ 라이브러리 충돌 최소화

### 3. Python 빌드 드라이버 선택

**선정 이유:**
- Ubuntu 22.04에 기본 내장
- JSON 처리 및 대화형 UI 구현 용이
- Shell Script 대비 복잡한 로직 처리 우수
- 유지보수성 향상

**구현 기능:**
- CLI 플래그 지원 (`--preset`, `--build-type`, `--non-interactive`)
- 프리셋 검증 (JSON 구조, TensorRT-CUDA 호환성)
- Artifacts 존재 확인
- 색상 출력 및 진행 상황 표시

### 4. 소스 빌드 (FFmpeg, OpenCV, Xaiva Media)

**Dockerfile에 완전한 빌드 파이프라인 구현:**

#### 코덱 라이브러리
- x264, x265, libvpx, opus, fdk-aac
- NVIDIA 코덱 헤더 (NVENC/NVDEC)

#### FFmpeg
- 버전: ARG로 제어 (기본 4.2)
- 소스: 공개 저장소
- GPU 가속 (CUDA, CUVID) 활성화

#### OpenCV
- 버전: ARG로 제어 (기본 4.9.0)
- CUDA/cuDNN 지원
- Python 바인딩 생성

#### Xaiva Media
- 소스: 외부 경로 또는 빌드 컨텍스트
- 표준 경로 설치 (`CMAKE_INSTALL_PREFIX=/usr/local`)

---

## 현재 시스템 구성

### 프리셋 관리

**프리셋 JSON 스키마:**
```json
{
  "metadata": { "name", "description", "created", "target_gpu" },
  "base_image": "nvidia/cuda:...",
  "python": { "version", "version_without_dot" },
  "pytorch": { "version", "torch_version", "torchvision_version", ... },
  "tensorrt": { "enabled", "version", "required_in_runtime", ... },
  "cuda": { "version", "arch", "arch_name" },
  "build_options": { "ffmpeg_version", "opencv_version", ... },
  "system_packages": [...],
  "environment": { "TZ", "LC_ALL", "LD_LIBRARY_PATH", ... }
}
```

**현재 프리셋:**
- `ubuntu22.04-cuda11.8-torch2.1`: Production 환경
  - CUDA 11.8.0, cuDNN 8
  - Python 3.10
  - PyTorch 2.1.0+cu118
  - TensorRT 8.6.1
  - CUDA Arch 86 (RTX 30xx)

### 빌드 스테이지

```
[base] - 공통 베이스 설정
   ↓
[builder] - 빌드 및 개발 도구
   ↓         ├─ 코덱 라이브러리 빌드
   ↓         ├─ FFmpeg 빌드
   ↓         ├─ OpenCV 빌드
   ↓         └─ Xaiva Media 빌드
   ↓
   ├─→ [runtime] - 최소 런타임 (배포용)
   └─→ [dev] - 개발 이미지 (빌드 도구 포함)
```

### 환경 변수

```bash
# PATH (시스템 기본값 사용)
PATH="/usr/local/bin:/usr/bin:/bin"

# 라이브러리 경로
LD_LIBRARY_PATH="/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"

# NVIDIA 설정
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=video,compute,utility
```

---

## 사용 방법

### 빠른 시작

```bash
# 1. 대화형 빌드
python3 scripts/build.py

# 2. 비대화형 빌드
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --build-type runtime \
  --non-interactive

# 3. 이미지 실행
docker run --rm -it --gpus all \
  xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime \
  /bin/bash
```

### 프리셋 목록 확인

```bash
python3 scripts/build.py --list-presets
```

### Dry-run 모드

```bash
python3 scripts/build.py --preset <name> --dry-run
```

### Dev 이미지 빌드

```bash
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --build-type dev
```

---

## 문서 가이드

### 사용자용 문서

| 문서 | 내용 | 대상 |
|------|------|------|
| `README.md` | 프로젝트 소개 및 빠른 시작 | 모든 사용자 |
| `build-guide.md` | 상세 빌드 가이드 | 빌드 담당자 |
| `preset-schema.md` | 프리셋 JSON 스키마 | 프리셋 작성자 |

### 개발자용 문서

| 문서 | 내용 | 대상 |
|------|------|------|
| `PROJECT_SUMMARY.md` | 프로젝트 요약 (이 문서) | 개발자 |
| `DEVELOPMENT_HISTORY.md` | 개발 히스토리 | 개발자 |
| `development-goals.md` | 개발 목표 | 개발자 |
| `implementation-plan.md` | 구현 계획 | 개발자 |

### 기술 변경 문서

| 문서 | 내용 | 날짜 |
|------|------|------|
| `dockerfile-update-summary.md` | Dockerfile 업데이트 요약 | 2025-11-20 |
| `online-build-migration.md` | 온라인 빌드 마이그레이션 | 2025-11-20 |
| `standard-paths-migration.md` | 표준 경로 마이그레이션 | 2025-11-20 |

### 완료 보고서

| 문서 | 내용 | 날짜 |
|------|------|------|
| `phase1-update.md` | Phase 1 업데이트 | 2025-11-20 |
| `phase1-completion.md` | Phase 1 완료 보고서 | 2025-11-20 |
| `phase2-4-completion.md` | Phase 2-4 완료 보고서 | 2025-11-20 |

### 문서 읽기 순서 추천

#### 처음 사용하는 경우
1. `README.md` - 프로젝트 개요
2. `build-guide.md` - 빌드 방법
3. `preset-schema.md` - 프리셋 이해

#### 개발에 참여하는 경우
1. `PROJECT_SUMMARY.md` (이 문서) - 전체 이해
2. `DEVELOPMENT_HISTORY.md` - 개발 과정
3. `development-goals.md` - 목표 이해
4. `implementation-plan.md` - 구조 이해

#### 특정 변경사항 이해하는 경우
- 온라인 빌드: `online-build-migration.md`
- 표준 경로: `standard-paths-migration.md`
- Dockerfile: `dockerfile-update-summary.md`

---

## 주요 변경 이력

| 날짜 | 변경 내용 | 관련 문서 |
|------|----------|----------|
| 2025-11-20 | Phase 1 완료: 프로젝트 초기화 | phase1-completion.md |
| 2025-11-20 | Phase 1 업데이트: 용어 통일, TensorRT 강화 | phase1-update.md |
| 2025-11-20 | Phase 2-4 완료: Dockerfile, 빌드 스크립트 | phase2-4-completion.md |
| 2025-11-20 | 온라인 빌드 방식으로 변경 | online-build-migration.md |
| 2025-11-20 | 표준 경로 마이그레이션 | standard-paths-migration.md |
| 2025-11-20 | Dockerfile 완전한 빌드 파이프라인 구현 | dockerfile-update-summary.md |

---

## 진행 중인 변경 사항

> 💡 **빠른 참조**: [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)  
> 📋 **상세 계획**: [CHANGE_PLAN.md](CHANGE_PLAN.md)

### 확정된 변경 (4개)

| ID | 변경 내용 | 우선순위 | 상태 |
|----|----------|----------|------|
| CP-001 | Dev 이미지만 사용 | 높음 | 📋 계획 |
| CP-002 | 빌드 의존성 아카이브 | 높음 | 📋 계획 |
| CP-003 | Xaiva Media 브랜치 선택 | 중간 | 📋 계획 |
| CP-004 | 대화형 의존성 관리 | 낮음 | 📋 계획 |

### 주요 변경 요약

**CP-001: Dev 이미지만 사용**
- Runtime/Dev 분리 → Dev로 통합
- 빌드 프로세스 단순화
- 이미지 크기 약간 증가

**CP-002: 빌드 의존성 아카이브**
- 온라인 빌드 → 하이브리드 빌드 (온라인/오프라인)
- 완전 오프라인 빌드 지원
- deps_sync.sh 기능 복원

**CP-003: Xaiva Media 브랜치 선택**
- 고정 브랜치 → 브랜치 선택 가능
- Git 서브모듈 사용
- CLI로 브랜치 오버라이드

**CP-004: 대화형 의존성 관리**
- 별도 스크립트 → build.py 통합
- 자동 의존성 확인 및 다운로드
- 사용자 경험 개선

---

## 다음 단계

### Phase 5: 검증 및 문서화 (기존 계획)
1. **실제 빌드 테스트**
   - 온라인 환경에서 빌드
   - 이미지 export/import 테스트
   - GPU 동작 확인

2. **문서 정리**
   - 최신 정보 반영
   - 변경 사항 반영

### Phase 6: 변경 구현 (신규)
1. **CP-001, CP-002** (Week 1)
   - Dev 이미지 통합
   - 하이브리드 빌드 방식

2. **CP-003, CP-004** (Week 2)
   - 브랜치 선택 기능
   - 대화형 의존성 관리

3. **최종 검증 및 문서화**
   - 모든 변경 사항 테스트
   - 문서 업데이트

---

## 기술 스택

| 컴포넌트 | 기술 | 버전 |
|----------|------|------|
| 베이스 이미지 | NVIDIA CUDA | 11.8.0 (cuDNN 8) |
| OS | Ubuntu | 22.04 |
| Python | CPython | 3.10 |
| PyTorch | PyTorch | 2.1.0+cu118 |
| TensorRT | TensorRT | 8.6.1 |
| Dockerfile | Multi-stage | - |
| 빌드 드라이버 | Python 3 | 표준 라이브러리만 |
| 의존성 관리 | Bash | - |
| 프리셋 | JSON | - |

---

## 연락처 및 지원

**프로젝트 관리자**: h.kim  
**생성일**: 2025-11-20  
**마지막 업데이트**: 2025-11-21

**문의**:
- 기술 문의: 팀 채널
- 버그 리포트: 이슈 트래커
- 개선 제안: Pull Request

---

**이 문서는 지속적으로 업데이트됩니다.**

