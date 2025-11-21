# Dockerfile 업데이트 요약

## 업데이트 날짜
2025-11-20

## 개요
Legacy dockerfile.dev와 dockerfile.runtime을 참고하여 통합 Dockerfile을 완전한 빌드 시스템으로 업데이트했습니다. FFmpeg, OpenCV, Xaiva Media를 공개 저장소 및 지정된 경로에서 소스로 빌드하도록 구현했습니다.

---

## 주요 변경사항

### 1. Build Arguments 추가

```dockerfile
ARG FFMPEG_VERSION=4.2
ARG OPENCV_VERSION=4.9.0
ARG XAIVA_SOURCE_PATH=xaiva-media
```

- FFmpeg 버전 제어 가능
- OpenCV 버전 제어 가능
- Xaiva Media 소스 경로 지정 가능

### 2. Builder 스테이지: 완전한 빌드 파이프라인 구현

#### 2.1 코덱 라이브러리 빌드
- **x264**: H.264 인코딩
- **x265**: H.265/HEVC 인코딩
- **libvpx**: VP8/VP9 코덱
- **opus**: 오디오 코덱
- **fdk-aac**: AAC 오디오 인코더
- **NVIDIA 코덱 헤더**: NVENC/NVDEC 지원

#### 2.2 FFmpeg 빌드
- 버전: ARG로 제어 (기본값 4.2)
- 소스: 공개 저장소 (https://ffmpeg.org/releases/)
- 빌드 옵션:
  - 정적 빌드 (--disable-shared --enable-static)
  - GPU 가속 (--enable-cuda --enable-cuvid)
  - 모든 코덱 라이브러리 활성화
- 설치 위치: `/usr/local/` (표준 경로)

#### 2.3 OpenCV 빌드
- 버전: ARG로 제어 (기본값 4.9.0)
- 소스: 공개 저장소 (GitHub opencv/opencv, opencv_contrib)
- 빌드 옵션:
  - CUDA 지원 활성화
  - cuDNN 지원 활성화
  - DNN 모듈 (CUDA 가속)
  - Python 바인딩 생성
  - 정적 라이브러리 빌드
- 설치 위치: `/usr/local/` (표준 경로)
- CUDA 아키텍처: `${CUDA_ARCH}` 변수로 제어

#### 2.4 Xaiva Media 빌드
- 소스: 지정된 경로 (ARG XAIVA_SOURCE_PATH)
- 빌드 방법:
  ```bash
  ./lib_compile.sh
  ./release_packaging.sh
  ```
- 설치 위치: `/usr/local/` (표준 경로)

### 3. Runtime 스테이지: 최적화된 배포 이미지

#### 3.1 Builder 산출물 복사
```dockerfile
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/include/ /usr/local/include/
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION}/site-packages/cv2/ \
                    /usr/local/lib/python${PYTHON_VERSION}/site-packages/cv2/
RUN ldconfig
```

#### 3.2 런타임 패키지만 설치
- Python 런타임
- FFmpeg 런타임 라이브러리 (libass9, libfreetype6, libmp3lame0, 등)
- OpenCV 런타임 라이브러리 (libjpeg8, libtiff5, libpng16-16, 등)
- 기타 유틸리티 (redis-server, vim, wget, curl)

#### 3.3 빌드 도구 제외
- build-essential, cmake, git 등 빌드 도구는 포함하지 않음
- 이미지 크기 최소화

### 4. Dev 스테이지: 개발 환경 강화

#### 4.1 Builder 기반
- Builder 스테이지의 모든 빌드 도구 포함
- 소스 코드 접근 가능

#### 4.2 개발 도구 추가
- gdb, valgrind, strace (디버깅)
- htop, tmux (시스템 모니터링)
- GDB Dashboard (향상된 디버깅 UI)

---

## 표준 경로 사용

### 변경 사항
- **이전**: `/usr/local/xaiva_media/bin`, `/usr/local/xaiva_media/lib`
- **현재**: `/usr/local/bin`, `/usr/local/lib`, `/usr/local/include`

### 장점
- ✅ 리눅스 FHS (Filesystem Hierarchy Standard) 준수
- ✅ `/usr/local/bin`은 시스템 PATH에 자동 포함
- ✅ `ldconfig`로 라이브러리 자동 인식
- ✅ 라이브러리 경로 충돌 최소화
- ✅ CMake, Make 등 빌드 도구의 기본 경로

### 환경 변수 단순화
```bash
# 이전
PATH="/usr/local/xaiva_media/bin:${PATH}"
LD_LIBRARY_PATH="/usr/local/xaiva_media/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/include"

# 현재
# PATH는 시스템 기본값 사용 (변경 불필요)
LD_LIBRARY_PATH="/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
```

---

## 프리셋 JSON 업데이트

### build_options 필드 추가

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
    "branch": "master",
    "description": "Xaiva Media source path relative to build context or absolute path"
  }
}
```

---

## 빌드 스크립트 업데이트

### build.py 변경사항

```python
# Build arguments에 FFmpeg, OpenCV 버전 추가
build_args = {
    "BASE_IMAGE": preset["base_image"],
    "PRESET_NAME": preset_name,
    "PYTHON_VERSION": preset["python"]["version"],
    "PYTHON_VERSION_WITHOUT_DOT": preset["python"]["version_without_dot"],
    "CUDA_ARCH": preset["cuda"]["arch"],
    "FFMPEG_VERSION": build_options["ffmpeg_version"],
    "OPENCV_VERSION": build_options["opencv_version"],
    "XAIVA_SOURCE_PATH": xaiva_source["path"]
}
```

---

## requirements.txt 업데이트

### 버전 고정 패키지 추가

```
# Core dependencies (version-locked)
numpy==1.23.1
scipy==1.11.4

# PyTorch ecosystem (CUDA 11.8)
--find-links https://download.pytorch.org/whl/torch_stable.html
torch==2.1.0+cu118
torchvision==0.16.0+cu118
torchaudio==2.1.0+cu118
```

### opencv-python 제외
- OpenCV를 소스에서 CUDA 지원으로 빌드하므로 opencv-python 패키지는 불필요

---

## 빌드 방법

### 1. Xaiva Media 소스 준비

프로젝트 루트에 Xaiva Media 소스 배치:

```bash
# 옵션 1: 심볼릭 링크
ln -s /DATA/h.kim/xaiva-media ./xaiva-media

# 옵션 2: 복사
cp -r /DATA/h.kim/xaiva-media ./xaiva-media

# 옵션 3: 프리셋 JSON에서 경로 지정
# "path": "/DATA/h.kim/xaiva-media"
```

### 2. 빌드 실행

```bash
# 대화형 모드
python3 scripts/build.py

# 비대화형 모드 (runtime)
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --build-type runtime \
  --non-interactive

# 비대화형 모드 (dev)
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --build-type dev \
  --non-interactive
```

### 3. 생성된 이미지

- **Runtime**: `xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime`
  - 최소 크기, 배포용
- **Dev**: `xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-dev`
  - 빌드 도구 포함, 개발용

---

## 빌드 시간

### 예상 소요 시간 (하드웨어 의존적)

- **코덱 라이브러리**: 15-30분
- **FFmpeg**: 10-20분
- **OpenCV**: 30-60분 (CUDA 빌드 포함)
- **Xaiva Media**: 10-20분
- **전체**: 약 1-2시간

### 병렬 빌드
- `make -j$(nproc)` 사용으로 멀티코어 활용
- CPU 코어 수에 따라 빌드 시간 단축

---

## 확인 사항

### 빌드 완료 후 확인

```bash
# 이미지 확인
docker images | grep xaiva-media

# 컨테이너 실행
docker run --rm -it --gpus all \
  xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime \
  /bin/bash

# 컨테이너 내에서
which ffmpeg           # /usr/local/bin/ffmpeg
ffmpeg -version
python -c "import cv2; print(cv2.__version__)"
python -c "import torch; print(torch.cuda.is_available())"
```

---

## 문제 해결

### 문제 1: Xaiva Media 소스를 찾을 수 없음

**증상:**
```
COPY failed: file not found in build context
```

**해결:**
- 프리셋 JSON의 `xaiva_media_source.path` 확인
- 빌드 컨텍스트(프로젝트 루트)에 소스가 있는지 확인
- 심볼릭 링크 또는 복사로 소스 배치

### 문제 2: 빌드 중 메모리 부족

**증상:**
```
c++: fatal error: Killed signal terminated program
```

**해결:**
```bash
# Docker에 더 많은 메모리 할당
# 또는 병렬 빌드 제한
export MAKEFLAGS="-j4"  # 4개 코어만 사용
```

### 문제 3: GitHub 저장소 접근 실패

**증상:**
```
fatal: unable to access 'https://github.com/...'
```

**해결:**
- 인터넷 연결 확인
- 방화벽/프록시 설정 확인
- 대안: 소스를 `artifacts/<preset>/sources/`에 미리 다운로드

---

## 참고 문서

- [표준 경로 마이그레이션](standard-paths-migration.md)
- [빌드 가이드](build-guide.md)
- [프리셋 스키마](preset-schema.md)
- [개발 목표](development-goals.md)

---

## 다음 단계

### 완료된 작업
- ✅ Dockerfile에 완전한 빌드 파이프라인 구현
- ✅ 표준 경로 적용
- ✅ 프리셋 JSON 업데이트
- ✅ 빌드 스크립트 업데이트
- ✅ requirements.txt 업데이트

### 추가 작업 권장사항
1. **오프라인 빌드 테스트**
   - 네트워크 차단 상태에서 빌드 테스트
   - `docker build --network=none` 사용

2. **artifacts/sources/ 준비**
   - FFmpeg, OpenCV 소스 tar.gz 다운로드
   - 완전 오프라인 빌드 지원

3. **추가 프리셋 작성**
   - CUDA 12.x + PyTorch 2.3 + TensorRT 10.x
   - 다양한 GPU 아키텍처 지원

4. **CI/CD 파이프라인**
   - 자동 빌드 및 테스트
   - 이미지 레지스트리 푸시

---

**작성자**: AI Assistant  
**검토자**: h.kim  
**마지막 업데이트**: 2025-11-20

