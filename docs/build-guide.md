# XaivaKit - 빌드 가이드

## 📋 목차

1. [개요](#개요)
2. [사전 준비](#사전-준비)
3. [온라인 환경: 의존성 다운로드](#온라인-환경-의존성-다운로드)
4. [오프라인 환경: 이미지 빌드](#오프라인-환경-이미지-빌드)
5. [고급 사용법](#고급-사용법)
6. [문제 해결](#문제-해결)

---

## 개요

이 가이드는 XaivaKit 이미지를 빌드하는 전체 과정을 안내합니다. 이 시스템은 **완전 오프라인 환경**에서도 빌드할 수 있도록 설계되었습니다.

### 빌드 프로세스 개요

```
[온라인 환경]                          [오프라인 환경]
    │                                      │
    ├─ 1. 프리셋 선택                     │
    ├─ 2. 의존성 다운로드                 │
    │    (deps_sync.sh)                   │
    │                                      │
    └─ 3. 프로젝트 복사 ─────USB/외장─────>
                                           │
                                           ├─ 4. 이미지 빌드
                                           │    (build.py)
                                           │
                                           └─ 5. 이미지 실행
```

---

## 사전 준비

### 필수 소프트웨어

#### 온라인 환경
- Python 3.9 이상
- pip (Python 패키지 관리자)
- Git
- 인터넷 연결

#### 오프라인 환경
- Docker 20.10 이상
- NVIDIA Container Toolkit (GPU 사용 시)
- Python 3.9 이상 (빌드 스크립트 실행용)

### 시스템 요구사항

- **저장 공간**: 프리셋당 최소 20GB (artifacts + 이미지)
- **메모리**: 최소 8GB RAM (빌드 시)
- **GPU**: NVIDIA GPU (CUDA 지원)

---

## 온라인 환경: 의존성 다운로드

### 1단계: 프로젝트 클론

```bash
git clone <repository-url> xaiva-kit
cd xaiva-kit
```

### 2단계: 환경 변수 설정 (선택 사항)

```bash
# 환경 변수 파일 생성
cp env.template .env

# 필요한 경우 토큰 설정
vim .env
```

### 3단계: 프리셋 확인

사용 가능한 프리셋 목록 확인:

```bash
ls presets/
```

출력 예:
```
ubuntu22.04-cuda11.8-torch2.1.json
ubuntu22.04-cuda12.1-torch2.3.json
```

프리셋 상세 정보 확인:

```bash
python3 scripts/build.py --list-presets
```

### 4단계: 의존성 준비 (선택 사항)

**주의: Python 패키지는 Docker 빌드 시 자동으로 다운로드됩니다.**

소스 빌드가 필요한 경우에만 실행:

```bash
./scripts/deps_sync.sh ubuntu22.04-cuda11.8-torch2.1
```

이 스크립트는 다음을 안내합니다:
- ℹ️  Python 패키지는 Dockerfile에서 직접 설치됨을 안내
- ℹ️  FFmpeg/OpenCV 소스 다운로드 안내 (선택 사항)

**변경 사항**: Python wheels 다운로드는 더 이상 필요하지 않습니다.
버전 관리 패키지(numpy, pytorch, tensorrt)는 Dockerfile에서 직접 설치됩니다.

### 5단계: 소스 파일 추가 (선택 사항)

FFmpeg/OpenCV를 소스에서 빌드하려는 경우:

```bash
# FFmpeg 다운로드
cd artifacts/ubuntu22.04-cuda11.8-torch2.1/sources/
wget https://ffmpeg.org/releases/ffmpeg-4.2.tar.gz

# OpenCV 다운로드
wget https://github.com/opencv/opencv/archive/refs/tags/4.9.0.tar.gz \
     -O opencv-4.9.0.tar.gz
```

### 6단계: Xaiva Media 소스 준비

Xaiva Media 소스 코드를 준비합니다 (방법은 팀 정책에 따름):

**옵션 A: Git 서브트리**
```bash
git subtree add --prefix=xaiva-media <xaiva-repo-url> master
```

**옵션 B: 별도 디렉터리**
```bash
# 프로젝트 외부에 클론 후 빌드 시 경로 지정
git clone <xaiva-repo-url> ../xaiva-media-source
```

### 7단계: 프로젝트 패키징

오프라인 환경으로 이동하기 위해 프로젝트를 패키징합니다:

```bash
cd ..
tar czf xaiva-kit.tar.gz xaiva-kit/
```

**참고**: `artifacts/` 디렉터리가 크므로 압축에 시간이 걸립니다.

---

## 오프라인 환경: 이미지 빌드

### 1단계: 프로젝트 압축 해제

USB 또는 외장 드라이브에서 프로젝트를 복사합니다:

```bash
# USB 마운트 (Linux 예시)
sudo mount /dev/sdb1 /mnt/usb

# 프로젝트 복사 및 압축 해제
cp /mnt/usb/xaiva-kit.tar.gz ~/
cd ~/
tar xzf xaiva-kit.tar.gz
cd xaiva-kit/
```

### 2단계: 프리셋 확인

다운로드된 artifacts가 있는지 확인:

```bash
ls -lh artifacts/ubuntu22.04-cuda11.8-torch2.1/
```

출력 예:
```
drwxr-xr-x  wheels/           # Python wheel 파일들
drwxr-xr-x  debs/             # (선택) .deb 패키지
drwxr-xr-x  sources/          # (선택) 소스 파일
-rw-r--r--  requirements.txt  # Python 패키지 목록
```

### 3단계: 대화형 빌드

```bash
python3 scripts/build.py
```

스크립트가 다음을 안내합니다:
1. 프리셋 선택
2. 빌드 타입 선택 (runtime/dev)
3. 빌드 확인

**예시 출력:**
```
================================================================================
  XaivaKit - Build Driver
================================================================================

✅ Loaded 1 preset(s)

--- Available Presets ---
  1. ubuntu22.04-cuda11.8-torch2.1
     Production Environment - CUDA 11.8, PyTorch 2.1.0, TensorRT 8.6.1

Select preset (1-1): 1

--- Build Type ---
  1. runtime - Production image (minimal size)
  2. dev     - Development image (includes build tools)

Select build type (1-2) [default: 1]: 1

--- Build Summary ---
  Preset:     ubuntu22.04-cuda11.8-torch2.1
  Build Type: runtime
  Image Tag:  xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime

Proceed with build? (y/n) [y]: y
```

**진행 시간**: 하드웨어에 따라 30-60분 소요

### 4단계: 비대화형 빌드 (자동화)

CLI 플래그로 완전 자동 빌드:

```bash
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --build-type runtime \
  --non-interactive
```

### 5단계: 빌드 확인

빌드가 완료되면 이미지를 확인합니다:

```bash
docker images | grep xaiva-media
```

출력 예:
```
xaiva-media   ubuntu22.04-cuda11.8-torch2.1-runtime   abc123   2 minutes ago   15.2GB
```

### 6단계: 이미지 실행

빌드된 이미지를 실행합니다:

```bash
# GPU를 사용하여 컨테이너 실행
docker run --rm -it --gpus all \
  xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime \
  /bin/bash
```

컨테이너 내에서 확인:

```bash
# CUDA 확인
nvidia-smi

# Python 확인
python --version

# PyTorch 확인
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"

# TensorRT 확인
python -c "import tensorrt; print(f'TensorRT: {tensorrt.__version__}')"
```

---

## 고급 사용법

### 여러 프리셋 빌드

```bash
#!/bin/bash
# build-all.sh

PRESETS=(
  "ubuntu22.04-cuda11.8-torch2.1"
  "ubuntu22.04-cuda12.1-torch2.3"
)

for preset in "${PRESETS[@]}"; do
  echo "Building preset: $preset"
  
  python3 scripts/build.py \
    --preset "$preset" \
    --build-type runtime \
    --non-interactive
done
```

### 빌드 로그 저장

```bash
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --build-type runtime \
  --non-interactive \
  2>&1 | tee build-$(date +%Y%m%d-%H%M%S).log
```

### Dry-run 모드

Docker 명령어만 확인하고 실행하지 않음:

```bash
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --dry-run
```

### Dev 이미지 빌드

개발용 이미지는 빌드 도구가 포함됩니다:

```bash
python3 scripts/build.py \
  --preset ubuntu22.04-cuda11.8-torch2.1 \
  --build-type dev
```

Dev 이미지 사용 예:

```bash
# 소스 코드를 마운트하여 개발
docker run --rm -it --gpus all \
  -v $(pwd)/xaiva-media:/workspace/xaiva-media \
  xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-dev \
  /bin/bash
```

### 네트워크 차단 빌드 테스트

완전 오프라인 빌드 테스트:

```bash
docker build \
  -f docker/Dockerfile \
  --network=none \
  --target runtime \
  --build-arg PRESET_NAME=ubuntu22.04-cuda11.8-torch2.1 \
  --build-arg BASE_IMAGE=nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 \
  --build-arg PYTHON_VERSION=3.10 \
  --build-arg PYTHON_VERSION_WITHOUT_DOT=310 \
  --build-arg CUDA_ARCH=86 \
  -t xaiva-kit:test-offline \
  .
```

---

## 문제 해결

### 일반적인 문제

#### 1. Wheel 파일이 없음

**증상:**
```
ERROR: Could not find a version that satisfies the requirement ...
```

**해결:**
```bash
# 온라인 환경에서 다시 다운로드
./scripts/deps_sync.sh ubuntu22.04-cuda11.8-torch2.1

# 또는 수동으로 다운로드
cd artifacts/ubuntu22.04-cuda11.8-torch2.1/wheels/
pip3 download <package-name>==<version>
```

#### 2. TensorRT-CUDA 호환성 오류

**증상:**
```
❌ ERROR: TensorRT 8.6.1 requires CUDA 11.8, but preset uses CUDA 12.1
```

**해결:**
프리셋 JSON 파일을 수정하여 호환되는 TensorRT 버전 사용:
```json
{
  "tensorrt": {
    "version": "10.0.0",
    "cuda_compatibility": {
      "10.0.0": "12.1"
    }
  }
}
```

#### 3. Docker 빌드 메모리 부족

**증상:**
```
ERROR: failed to solve: ...
```

**해결:**
Docker에 더 많은 메모리 할당:
```bash
# Docker Desktop 설정에서 메모리 증가
# 또는 빌드 시 병렬 작업 제한
docker build --cpus=2 --memory=8g ...
```

#### 4. GPU 인식 안 됨

**증상:**
컨테이너에서 `nvidia-smi` 실패

**해결:**
```bash
# NVIDIA Container Toolkit 설치 확인
nvidia-container-toolkit --version

# Docker 재시작
sudo systemctl restart docker

# GPU 테스트
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### 로그 및 디버깅

#### 빌드 스크립트 디버그 모드

```bash
# 상세 출력
python3 scripts/build.py --preset <name> -v

# Python 디버거
python3 -m pdb scripts/build.py --preset <name>
```

#### Docker 빌드 로그

```bash
# 빌드 중간 스테이지 유지
docker build --rm=false ...

# 실패한 스테이지에서 컨테이너 실행
docker run --rm -it <intermediate-container-id> /bin/bash
```

### 지원

문제가 계속되면:
1. 로그 파일 저장
2. 프리셋 JSON 파일 확인
3. 팀 채널에 문의

---

## 체크리스트

### 온라인 환경 (의존성 다운로드)

- [ ] 프로젝트 클론 완료
- [ ] 프리셋 선택 완료
- [ ] `deps_sync.sh` 실행 완료
- [ ] `artifacts/<preset-name>/wheels/` 에 파일 존재
- [ ] (선택) FFmpeg/OpenCV 소스 다운로드
- [ ] Xaiva Media 소스 준비
- [ ] 프로젝트 압축 완료
- [ ] USB/외장 드라이브에 복사 완료

### 오프라인 환경 (이미지 빌드)

- [ ] 프로젝트 압축 해제 완료
- [ ] artifacts 파일 확인 완료
- [ ] Docker 및 NVIDIA Toolkit 설치 확인
- [ ] `build.py` 실행 완료
- [ ] 이미지 빌드 성공
- [ ] 이미지 실행 테스트 완료
- [ ] GPU 인식 확인 완료
- [ ] PyTorch/TensorRT 동작 확인 완료

---

## 참고 자료

- [프리셋 JSON 스키마](preset-schema.md)
- [패키지 버전 관리](package-versions.md)
- [개발 목표](development-goals.md)
- [구현 계획](implementation-plan.md)

---

**마지막 업데이트**: 2025-11-20

