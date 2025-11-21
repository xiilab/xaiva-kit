# Changelog

## [2025-11-21] - 프로젝트 이름 변경

### 변경됨 (Changed)
- **프로젝트명 변경**: "Xaiva Media Docker Unified" → "XaivaKit"
  - 더 간결하고 명확한 이름으로 변경
  - 디렉터리명: `xaiva-media-docker-unified` → `xaiva-kit`
  - Docker 이미지명: `xaiva-media:` → `xaiva-kit:`
  - 모든 문서 및 스크립트 업데이트

### 업데이트된 파일
- README.md, CLAUDE.md
- docs/ 디렉터리의 모든 주요 문서
- scripts/build.py, scripts/deps_sync.sh
- docker/Dockerfile, env.template

---

## [2025-11-20] - Dockerfile 완전 빌드 시스템 구현

### 추가됨 (Added)
- **FFmpeg 빌드 파이프라인**: 공개 저장소에서 소스 다운로드 및 빌드
  - x264, x265, libvpx, opus, fdk-aac 코덱 라이브러리
  - NVIDIA NVENC/NVDEC 지원
  - 버전 제어 가능 (ARG FFMPEG_VERSION)
  
- **OpenCV 빌드 파이프라인**: 공개 저장소에서 소스 다운로드 및 빌드
  - CUDA 및 cuDNN 지원
  - Python 바인딩 생성
  - opencv_contrib 모듈 포함
  - 버전 제어 가능 (ARG OPENCV_VERSION)
  
- **Xaiva Media 빌드 파이프라인**: 지정된 경로에서 소스 빌드
  - lib_compile.sh 및 release_packaging.sh 실행
  - 표준 경로(/usr/local)에 설치
  - 소스 경로 제어 가능 (ARG XAIVA_SOURCE_PATH)

- **Build Arguments**: 
  - FFMPEG_VERSION (기본값: 4.2)
  - OPENCV_VERSION (기본값: 4.9.0)
  - XAIVA_SOURCE_PATH (기본값: xaiva-media)

- **문서 추가**:
  - docs/dockerfile-update-summary.md: 상세한 업데이트 내용

### 변경됨 (Changed)
- **표준 경로 적용**: `/usr/local/xaiva_media` → `/usr/local`
  - 실행 파일: /usr/local/bin/
  - 라이브러리: /usr/local/lib/
  - 헤더 파일: /usr/local/include/

- **Builder 스테이지**: 완전한 빌드 환경 구현
  - 모든 코덱 라이브러리 빌드
  - FFmpeg 정적 빌드 (GPU 가속 지원)
  - OpenCV CUDA 빌드
  - Xaiva Media 빌드

- **Runtime 스테이지**: Builder 산출물 복사
  - /usr/local/lib/, /usr/local/bin/, /usr/local/include/ 복사
  - OpenCV Python 바인딩 복사
  - ldconfig 실행

- **Dev 스테이지**: 개발 도구 강화
  - GDB Dashboard 추가
  - 디버깅 도구 추가 (gdb, valgrind, strace)
  - 시스템 모니터링 도구 추가 (htop, tmux)

- **환경 변수 단순화**:
  - LD_LIBRARY_PATH에서 불필요한 경로 제거
  - PATH는 시스템 기본값 사용

### 수정됨 (Fixed)
- **프리셋 JSON**: build_options 필드 업데이트
  - build_ffmpeg_from_source: true
  - build_opencv_from_source: true
  - opencv_cuda_enabled: true
  - xaiva_media_source.path 설명 추가

- **build.py**: build_options에서 버전 정보 추출
  - FFMPEG_VERSION을 build args로 전달
  - OPENCV_VERSION을 build args로 전달
  - XAIVA_SOURCE_PATH를 build args로 전달

- **requirements.txt**: 버전 고정 패키지 추가
  - numpy==1.23.1
  - scipy==1.11.4
  - torch==2.1.0+cu118
  - torchvision==0.16.0+cu118
  - torchaudio==2.1.0+cu118
  - opencv-python 제외 (소스 빌드로 대체)

### 참고 (Notes)
- FFmpeg와 OpenCV는 공개 저장소에서 자동 다운로드 및 빌드
- Xaiva Media는 빌드 컨텍스트의 지정된 경로에서 빌드
- 완전 오프라인 빌드를 위해 소스를 artifacts/sources/에 미리 다운로드 가능
- 빌드 시간: 약 1-2시간 (하드웨어 의존적)

### 마이그레이션 가이드

#### 기존 사용자
1. Xaiva Media 소스를 프로젝트 루트에 배치:
   ```bash
   ln -s /path/to/xaiva-media ./xaiva-media
   # 또는
   cp -r /path/to/xaiva-media ./xaiva-media
   ```

2. 빌드 실행:
   ```bash
   python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1
   ```

#### 새 프리셋 작성 시
- build_options에 ffmpeg_version, opencv_version 추가
- xaiva_media_source.path 지정

---

## [이전 버전]

### Phase 2-4 완료 (2025-11-15)
- Multi-stage Dockerfile 기본 구조
- 대화형 빌드 드라이버 (build.py)
- 의존성 동기화 스크립트 (deps_sync.sh)
- 프리셋 JSON 스키마
- 빌드 가이드 문서

### Phase 1 완료 (2025-11-10)
- 프로젝트 초기화
- 디렉토리 구조 생성
- 첫 프리셋 정의
- 기본 문서 작성

