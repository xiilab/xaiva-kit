# 개발 히스토리

## 📅 타임라인

이 문서는 XaivaKit 프로젝트의 개발 과정을 시간순으로 정리합니다.

---

## 2025-11-20: 프로젝트 시작

### Phase 1 시작: 프로젝트 초기화

#### 목표 설정
- 완전 오프라인 대응 빌드 시스템 구축
- 프리셋 기반 관리
- 자립형 빌드 환경

#### 디렉터리 구조 설계

**초기 구조 (구조 A):**
```
artifacts/
├── wheels/
├── debs/
└── sources/
```

**최종 구조 (구조 B) 채택:**
```
artifacts/<preset-name>/
├── wheels/
├── debs/
├── sources/
└── requirements.txt
```

**변경 이유:**
- 프리셋별 독립적 관리
- 현장 배포 시 선택적 복사
- 스토리지 효율성

#### 첫 프리셋 작성

**기반**: legacy/dockerfile 분석  
**프리셋**: ubuntu22.04-cuda11.8-torch2.1

**사양:**
- Base Image: nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
- Python 3.10
- PyTorch 2.1.0+cu118
- TensorRT 8.6.1
- CUDA Arch 86 (Ampere/RTX 30xx)
- 시스템 패키지: 60+ 개

#### 문서 작성

**작성된 문서:**
- `development-goals.md`: 개발 목표 정의
- `implementation-plan.md`: Phase 1-5 계획
- `README.md`: 프로젝트 소개
- `env.template`: 환경 변수 템플릿

#### Git 설정

**`.gitignore` 작성:**
- `.env` (환경 변수)
- `artifacts/` (대용량 바이너리)
- Python 캐시
- IDE 설정

#### 결과

✅ **Phase 1 완료**

**생성된 파일:**
- .gitignore
- README.md
- env.template
- presets/ubuntu22.04-cuda11.8-torch2.1.json
- artifacts/ubuntu22.04-cuda11.8-torch2.1/requirements.txt
- docs/development-goals.md
- docs/implementation-plan.md
- docs/phase1-completion.md

**참조**: `docs/phase1-completion.md`

---

## 2025-11-20: Phase 1 업데이트

### 용어 통일

**변경 내용:**
- `<preset-triplet>` → `<preset-name>`

**이유:**
- "triplet"은 기술적 용어로 일반인 이해 어려움
- "preset-name"이 더 직관적
- 프리셋 이름이 3개 요소 조합에 한정되지 않음

**영향받은 파일:**
- development-goals.md
- implementation-plan.md
- README.md
- phase1-completion.md

### TensorRT 정보 강화

**변경 전:**
```json
"tensorrt": {
  "enabled": true,
  "version": "8.6.1"
}
```

**변경 후:**
```json
"tensorrt": {
  "enabled": true,
  "version": "8.6.1",
  "required_in_runtime": true,
  "supported_versions": ["8.6.1", "10.x"],
  "cuda_compatibility": {
    "8.6.1": "11.8",
    "10.x": "12.x"
  },
  "description": "TensorRT is required..."
}
```

**이유:**
- 런타임 필수성 명시
- CUDA 호환성 정보 제공
- 실수 방지

**참조**: `docs/phase1-update.md`

---

## 2025-11-20: Phase 2-4 완료

### Phase 2: 데이터 및 설정 설계

#### 프리셋 JSON 스키마 문서

**파일**: `docs/preset-schema.md`

**내용:**
- 9개 섹션 상세 설명
  1. metadata
  2. base_image
  3. python
  4. pytorch
  5. tensorrt (강화됨)
  6. cuda
  7. build_options
  8. system_packages
  9. environment
- 프리셋 생성 가이드
- 검증 체크리스트
- 완전한 예제

#### Python 의존성 관리

**초기 방식**: requirements.txt에 모든 패키지

**확정 방식**:
- requirements.txt: 일반 패키지만
- 버전 관리 패키지: Dockerfile에서 직접 설치
  - numpy, scipy
  - torch, torchvision, torchaudio
  - tensorrt

### Phase 3: 통합 Dockerfile 구현

**파일**: `docker/Dockerfile`

#### Multi-stage 구조

```
[base] - 공통 베이스
  ↓
[builder] - 빌드 및 개발 도구
  ↓
[runtime] - 최소 런타임 (배포용)
[dev] - 개발 이미지 (builder 기반)
```

#### 주요 기능

- ✅ ARG를 통한 동적 설정
- ✅ 프리셋별 artifacts 로딩
- ✅ 오프라인 pip 설치 (초기)
- ✅ Python 버전 동적 설치
- ✅ 환경 변수 설정
- ✅ 캐시 최적화

#### 주석 처리된 기능 (향후 확장)

- FFmpeg 소스 빌드
- OpenCV 소스 빌드
- Xaiva Media 빌드

### Phase 4: 대화형 빌드 드라이버 개발

#### build.py 작성

**라인 수**: ~650  
**언어**: Python 3 (표준 라이브러리만)

**핵심 기능:**
- 프리셋 JSON 로딩 및 검증
- 대화형 프리셋 선택
- 대화형 빌드 타입 선택
- TensorRT-CUDA 호환성 검증
- Artifacts 존재 여부 확인
- Docker build 명령어 생성
- 빌드 실행 및 진행 상황 표시

**CLI 플래그:**
```bash
--preset <name>
--build-type <type>
--non-interactive
--list-presets
--dry-run
--help
```

#### deps_sync.sh 작성

**라인 수**: ~270  
**언어**: Bash

**기능:**
- 프리셋 존재 확인
- artifacts 디렉터리 생성
- Python wheels 다운로드 (초기)
- 소스 파일 다운로드 안내

### Phase 2-4 완료

✅ **Phase 2, 3, 4 완료**

**생성된 파일:**
- docker/Dockerfile (~250 라인)
- scripts/build.py (~650 라인)
- scripts/deps_sync.sh (~270 라인)
- docs/preset-schema.md (~450 라인)
- docs/build-guide.md (~550 라인)
- docs/phase2-4-completion.md

**총 라인 수**: ~2,170 라인

**참조**: `docs/phase2-4-completion.md`

---

## 2025-11-20: 온라인 빌드 방식으로 마이그레이션

### 배경

**기존 방식**: 오프라인 (wheels 사전 다운로드)

**문제점:**
- ❌ wheels 관리 복잡도
- ❌ 큰 파일 크기 (PyTorch ~800MB)
- ❌ 사전 다운로드 단계 필요

### 결정

**새 방식**: 온라인 (Docker 빌드 시 직접 다운로드)

**이유:**
- ✅ Legacy dockerfile의 검증된 방식
- ✅ 관리 간소화
- ✅ 항상 최신 버전 사용

### 변경 내용

#### 1. PyTorch 설치 방식

**Before:**
```dockerfile
COPY artifacts/${PRESET_NAME}/wheels/ /tmp/wheels/
RUN pip3 install --no-index --find-links=/tmp/wheels torch==2.1.0+cu118
```

**After:**
```dockerfile
RUN pip3 install --find-links https://download.pytorch.org/whl/torch_stable.html torch==2.1.0+cu118
```

#### 2. requirements.txt 분리

**Before**: 모든 패키지 포함

**After**: 일반 패키지만 포함
```txt
# Data processing and utilities
packaging
webcolors
matplotlib
...

# Note: 버전 관리 패키지는 Dockerfile에서 직접 설치
```

#### 3. Dockerfile 설치 순서

```dockerfile
RUN pip3 install --upgrade pip setuptools wheel && \
    pip3 install numpy==1.23.1 && \
    pip3 install scipy==1.11.4 && \
    pip3 install --find-links https://download.pytorch.org/whl/torch_stable.html torch==2.1.0+cu118 && \
    pip3 install tensorrt==8.6.1 && \
    pip3 install -r /tmp/requirements.txt
```

#### 4. deps_sync.sh 수정

- Python wheels 다운로드 제거
- 안내 메시지로 변경
- 소스 파일 다운로드 안내 유지

### 장단점

**장점:**
- ✅ 간소화된 관리
- ✅ 검증된 방식
- ✅ 최신 패키지 사용

**단점:**
- ❌ Docker 빌드 시 인터넷 필수
- ❌ 완전 오프라인 불가

### 오프라인 배포 해결책

```bash
# 빌드 후 이미지 저장
docker save xaiva-kit:tag > xaiva-media.tar

# 오프라인 환경에서 로드
docker load < xaiva-media.tar
```

### 영향받은 파일

- `artifacts/ubuntu22.04-cuda11.8-torch2.1/requirements.txt`
- `docker/Dockerfile`
- `scripts/deps_sync.sh`
- `docs/build-guide.md`
- `README.md`

**참조**: `docs/online-build-migration.md`

---

## 2025-11-20: 표준 경로 마이그레이션

### 배경

**기존 방식**: Xaiva Media 전용 경로 사용
```
/usr/local/xaiva_media/bin
/usr/local/xaiva_media/lib
/usr/local/xaiva_media/include
```

**문제점:**
- ❌ 전용 경로 관리 복잡
- ❌ PATH 설정 필수
- ❌ LD_LIBRARY_PATH 설정 복잡

### 결정

**새 방식**: 리눅스 표준 경로 사용
```
/usr/local/bin       # 실행 파일
/usr/local/lib       # 라이브러리
/usr/local/include   # 헤더 파일
```

### 변경 내용

#### 1. Dockerfile 환경 변수

**Before:**
```dockerfile
ENV PATH="/usr/local/xaiva_media/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/xaiva_media/lib:/usr/local/cuda/lib64:..."
```

**After:**
```dockerfile
# PATH는 시스템 기본값 사용 (변경 불필요)
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
```

#### 2. Dockerfile 산출물 복사

**Before:**
```dockerfile
COPY --from=builder /usr/local/xaiva_media/ /usr/local/xaiva_media/
```

**After:**
```dockerfile
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/include/ /usr/local/include/
RUN ldconfig
```

#### 3. Xaiva Media 빌드 설정

```dockerfile
RUN cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
```

#### 4. 프리셋 JSON 수정

**Before:**
```json
"environment": {
  "LD_LIBRARY_PATH": "/usr/local/xaiva_media/lib:/usr/include:..."
}
```

**After:**
```json
"environment": {
  "LD_LIBRARY_PATH": "/usr/local/lib:/usr/local/cuda/lib64:..."
}
```

### 장점

- ✅ **단순성**: 경로 관리 최소화
- ✅ **호환성**: FHS 표준 준수
- ✅ **자동 인식**: PATH, ldconfig
- ✅ **유지보수성**: 표준을 따라 문제 해결 용이
- ✅ **안정성**: 라이브러리 충돌 최소화

### 영향받은 파일

- `docker/Dockerfile`
- `presets/ubuntu22.04-cuda11.8-torch2.1.json`

**참조**: `docs/standard-paths-migration.md`

---

## 2025-11-20: Dockerfile 완전한 빌드 파이프라인 구현

### 배경

초기 Dockerfile은 FFmpeg, OpenCV, Xaiva Media 빌드 로직이 주석 처리되어 있었음.

### 구현 내용

#### 1. 코덱 라이브러리 빌드

Builder 스테이지에 추가:
- x264 (H.264 인코딩)
- x265 (H.265/HEVC 인코딩)
- libvpx (VP8/VP9 코덱)
- opus (오디오 코덱)
- fdk-aac (AAC 오디오 인코더)
- NVIDIA 코덱 헤더 (NVENC/NVDEC)

#### 2. FFmpeg 빌드

**버전**: ARG로 제어 (기본 4.2)  
**소스**: https://ffmpeg.org/releases/

**빌드 옵션:**
- 정적 빌드 (--disable-shared --enable-static)
- GPU 가속 (--enable-cuda --enable-cuvid)
- 모든 코덱 라이브러리 활성화

**설치 위치**: `/usr/local/`

#### 3. OpenCV 빌드

**버전**: ARG로 제어 (기본 4.9.0)  
**소스**: GitHub opencv/opencv, opencv_contrib

**빌드 옵션:**
- CUDA 지원 활성화
- cuDNN 지원 활성화
- DNN 모듈 (CUDA 가속)
- Python 바인딩 생성
- 정적 라이브러리 빌드

**설치 위치**: `/usr/local/`  
**CUDA 아키텍처**: `${CUDA_ARCH}` 변수로 제어

#### 4. Xaiva Media 빌드

**소스**: 지정된 경로 (ARG XAIVA_SOURCE_PATH)

**빌드 방법:**
```bash
./lib_compile.sh
./release_packaging.sh
```

**설치 위치**: `/usr/local/`

### Build Arguments 추가

```dockerfile
ARG FFMPEG_VERSION=4.2
ARG OPENCV_VERSION=4.9.0
ARG XAIVA_SOURCE_PATH=xaiva-media
```

### Runtime 스테이지 최적화

**빌드 산출물 복사:**
```dockerfile
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/include/ /usr/local/include/
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION}/site-packages/cv2/ ...
RUN ldconfig
```

**런타임 패키지만 설치:**
- Python 런타임
- FFmpeg 런타임 라이브러리
- OpenCV 런타임 라이브러리
- 기타 유틸리티

**빌드 도구 제외:**
- 이미지 크기 최소화

### Dev 스테이지 강화

**Builder 기반:**
- 모든 빌드 도구 포함
- 소스 코드 접근 가능

**개발 도구 추가:**
- gdb, valgrind, strace (디버깅)
- htop, tmux (시스템 모니터링)
- GDB Dashboard

### 프리셋 JSON 업데이트

**build_options 필드 추가:**
```json
"build_options": {
  "ffmpeg_version": "4.2",
  "opencv_version": "4.9.0",
  "build_ffmpeg_from_source": true,
  "build_opencv_from_source": true,
  "opencv_cuda_enabled": true,
  "xaiva_media_source": {
    "type": "external",
    "path": "xaiva-media",
    "branch": "master"
  }
}
```

### requirements.txt 업데이트

**opencv-python 제외:**
- OpenCV를 소스에서 CUDA 지원으로 빌드하므로 불필요

### 빌드 시간

**예상 소요 시간** (하드웨어 의존적):
- 코덱 라이브러리: 15-30분
- FFmpeg: 10-20분
- OpenCV: 30-60분 (CUDA 빌드 포함)
- Xaiva Media: 10-20분
- **전체**: 약 1-2시간

### 영향받은 파일

- `docker/Dockerfile`
- `presets/ubuntu22.04-cuda11.8-torch2.1.json`
- `artifacts/ubuntu22.04-cuda11.8-torch2.1/requirements.txt`
- `scripts/build.py`

**참조**: `docs/dockerfile-update-summary.md`

---

## 2025-11-21: 문서 통합 및 요약

### 배경

개발 과정에서 생성된 10개의 문서를 정리하고 통합하여 관리 효율성 향상.

### 생성된 문서

#### 1. PROJECT_SUMMARY.md

**내용:**
- 프로젝트 개요
- 핵심 목표
- 프로젝트 구조
- 개발 단계 및 진행 상황
- 주요 기술 결정사항
- 현재 시스템 구성
- 사용 방법
- 문서 가이드

**대상**: 모든 개발자 및 사용자

#### 2. DEVELOPMENT_HISTORY.md (이 문서)

**내용:**
- 시간순 개발 히스토리
- 주요 변경사항
- 결정 배경 및 이유

**대상**: 개발자

### 기존 문서 정리

**유지할 문서:**
- `build-guide.md`: 사용자 매뉴얼
- `preset-schema.md`: 기술 레퍼런스
- `development-goals.md`: 초기 목표 (아카이브)
- `implementation-plan.md`: 초기 계획 (아카이브)

**아카이브 고려 문서:**
- `phase1-update.md`: 히스토리로 통합됨
- `phase1-completion.md`: 히스토리로 통합됨
- `phase2-4-completion.md`: 히스토리로 통합됨
- `dockerfile-update-summary.md`: 히스토리로 통합됨
- `online-build-migration.md`: 서머리에 통합됨
- `standard-paths-migration.md`: 서머리에 통합됨

---

## 향후 계획

### Phase 5: 검증 및 문서화

**필수 작업:**
1. 실제 빌드 테스트
2. Xaiva Media 통합
3. 문서 최신화

**추가 작업:**
1. 추가 프리셋 작성
2. 하이브리드 빌드 방식
3. CI/CD 파이프라인

---

## 주요 교훈

### 1. 프리셋 기반 관리의 중요성
- 환경별 독립적 관리
- 선택적 배포 가능
- 버전 충돌 방지

### 2. 표준 준수
- FHS 표준 경로 사용
- 시스템 기본 기능 활용
- 관리 복잡도 감소

### 3. 검증된 방식 채택
- Legacy dockerfile 참조
- 온라인 빌드 방식
- 안정성 입증

### 4. 문서화의 중요성
- 단계별 기록
- 결정 배경 명시
- 팀 협업 지원

---

**마지막 업데이트**: 2025-11-21  
**작성자**: AI Assistant  
**검토자**: h.kim

