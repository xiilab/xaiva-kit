# =============================================================================
# XaivaKit - Multi-stage Dockerfile
# =============================================================================
# 
# 이 Dockerfile은 완전 오프라인 환경에서 빌드 가능하도록 설계되었습니다.
# 모든 의존성은 artifacts/<preset-name>/ 에서 로드됩니다.
#
# 표준 경로 사용:
#   - 실행 파일: /usr/local/bin/
#   - 라이브러리: /usr/local/lib/
#   - 헤더 파일: /usr/local/include/
#
# =============================================================================

# -----------------------------------------------------------------------------
# Build Arguments
# -----------------------------------------------------------------------------
ARG BASE_IMAGE=nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
ARG PRESET_NAME=ubuntu22.04-cuda11.8-torch2.1
ARG PYTHON_VERSION=3.10
ARG PYTHON_VERSION_WITHOUT_DOT=310
ARG CUDA_ARCH=86
ARG FFMPEG_VERSION=4.2
ARG OPENCV_VERSION=4.11.0
ARG XAIVA_SOURCE_PATH=xaiva-media
ARG BUILD_MODE=online

# -----------------------------------------------------------------------------
# Stage 0: Base Setup
# -----------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG PRESET_NAME
ARG PYTHON_VERSION
ARG CUDA_ARCH
ARG FFMPEG_VERSION
ARG OPENCV_VERSION

# 환경 변수 설정
ENV TZ=Asia/Seoul
ENV LC_ALL=C.UTF-8
ENV CUDA_ARCH=${CUDA_ARCH}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES="video,compute,utility"
ENV THIRD_PARTY_PATH="/tmp/third_party"

# 기본 디렉터리 권한 설정
RUN chmod 777 /tmp

# -----------------------------------------------------------------------------
# Stage 1: Builder (개발 및 빌드용)
# -----------------------------------------------------------------------------
FROM base AS builder

ARG PRESET_NAME
ARG PYTHON_VERSION
ARG PYTHON_VERSION_WITHOUT_DOT
ARG FFMPEG_VERSION
ARG OPENCV_VERSION

# 빌드 정보 출력
RUN echo "Building with PRESET: ${PRESET_NAME}" && \
    echo "Python version: ${PYTHON_VERSION}" && \
    echo "CUDA_ARCH: ${CUDA_ARCH}" && \
    echo "FFmpeg version: ${FFMPEG_VERSION}" && \
    echo "OpenCV version: ${OPENCV_VERSION}"

# -----------------------------------------------------------------------------
# 시스템 패키지 설치 - 빌드 도구
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    cmake \
    git-core \
    git-lfs \
    libtool \
    meson \
    ninja-build \
    nasm \
    yasm \
    pkg-config \
    texinfo \
    wget \
    curl \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 시스템 패키지 설치 - FFmpeg 의존성
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    libass-dev \
    libfreetype6-dev \
    libgnutls28-dev \
    libmp3lame-dev \
    libsdl2-dev \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    zlib1g-dev \
    libssl-dev \
    openssl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 시스템 패키지 설치 - OpenCV 의존성
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    libtbb-dev \
    libatlas-base-dev \
    gfortran \
    libeigen3-dev \
    libv4l-dev \
    v4l-utils \
    libjpeg-dev \
    libtiff5-dev \
    libpng-dev \
    libwebp-dev \
    libopenjp2-7-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Python 및 개발 도구 설치
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python3-pip \
    vim \
    gdb \
    lftp \
    libnuma-dev \
    jq \
    tzdata \
    ntp \
    redis-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Python 심볼릭 링크 설정
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 2 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 2

# 임시 디렉터리 생성
RUN mkdir -p /root/util && \
    mkdir -p ${THIRD_PARTY_PATH}/ffmpeg_build

# -----------------------------------------------------------------------------
# Python 기본 패키지 설치
# -----------------------------------------------------------------------------
RUN pip3 install --upgrade pip setuptools wheel

# -----------------------------------------------------------------------------
# Wheels 복사 (오프라인 모드용) - 실패해도 계속 진행
# 오프라인 모드 현재 사용 안함 (2025-11-21) -----------------------------------------------------------------------------
# COPY artifacts/${PRESET_NAME}/wheels/ /tmp/wheels/ 2>/dev/null || true

# -----------------------------------------------------------------------------
# Python 패키지 설치 - PyTorch (하이브리드 빌드 지원)
# -----------------------------------------------------------------------------
ARG PYTORCH_VERSION
ARG PYTORCH_INDEX_URL
ARG BUILD_MODE
RUN if [ -n "${PYTORCH_VERSION}" ]; then \
        if [ "$BUILD_MODE" = "offline" ] && [ -d "/tmp/wheels" ] && [ "$(ls -A /tmp/wheels 2>/dev/null)" ]; then \
            echo "=== Offline mode: Installing PyTorch from local wheels ==="; \
            pip3 install --no-index --find-links=/tmp/wheels torch==${PYTORCH_VERSION} torchvision torchaudio; \
        else \
            echo "=== Online mode: Downloading PyTorch packages ==="; \
            pip3 install --find-links ${PYTORCH_INDEX_URL} \
            torch==${PYTORCH_VERSION} torchvision torchaudio ;\
        fi; \
    fi

# -----------------------------------------------------------------------------
# Python 패키지 설치 - TensorRT (하이브리드 빌드 지원)
# -----------------------------------------------------------------------------
ARG TENSORRT_VERSION
RUN if [ -n "${TENSORRT_VERSION}" ]; then \
        if [ "$BUILD_MODE" = "offline" ] && [ -d "/tmp/wheels" ] && [ "$(ls -A /tmp/wheels 2>/dev/null)" ]; then \
            echo "=== Offline mode: Installing TensorRT from local wheels ==="; \
            pip3 install --no-index --find-links=/tmp/wheels tensorrt==${TENSORRT_VERSION}; \
        else \
            echo "=== Online mode: Downloading TensorRT ==="; \
            pip3 install tensorrt==${TENSORRT_VERSION}; \
        fi; \
    fi

# -----------------------------------------------------------------------------
# Python 패키지 설치 - 일반 패키지 (하이브리드 빌드 지원)
# -----------------------------------------------------------------------------
COPY artifacts/${PRESET_NAME}/requirements-base.txt /tmp/requirements-base.txt
RUN if [ "$BUILD_MODE" = "offline" ] && [ -d "/tmp/wheels" ] && [ "$(ls -A /tmp/wheels 2>/dev/null)" ]; then \
        echo "=== Offline mode: Installing base packages from local wheels ==="; \
        # PyTorch, numpy, scipy 등은 이미 설치되었으므로 제외
        grep -v -E "^torch|^torchvision|^torchaudio|^numpy==|^scipy==" /tmp/requirements-base.txt > /tmp/filtered-base.txt; \
        pip3 install --no-index --find-links=/tmp/wheels -r /tmp/filtered-base.txt; \
        rm /tmp/filtered-base.txt; \
    else \
        echo "=== Online mode: Installing base packages ==="; \
        pip3 install -r /tmp/requirements-base.txt; \
    fi && \
    rm /tmp/requirements-base.txt

# PKG_CONFIG_PATH 설정
ENV PKG_CONFIG_PATH="${THIRD_PARTY_PATH}/ffmpeg_build/lib/pkgconfig:${PKG_CONFIG_PATH}"

# -----------------------------------------------------------------------------
# 코덱 라이브러리 빌드
# -----------------------------------------------------------------------------
# 빌드 스크립트 복사 및 실행
COPY docker/build-scripts/build-codecs.sh /tmp/
RUN chmod +x /tmp/build-codecs.sh && \
    /tmp/build-codecs.sh && \
    rm /tmp/build-codecs.sh

# -----------------------------------------------------------------------------
# FFmpeg 빌드
# -----------------------------------------------------------------------------
# 빌드 스크립트 복사 및 실행
COPY docker/build-scripts/build-ffmpeg.sh /tmp/
RUN chmod +x /tmp/build-ffmpeg.sh && \
    /tmp/build-ffmpeg.sh && \
    rm /tmp/build-ffmpeg.sh

# -----------------------------------------------------------------------------
# OpenCV 빌드
# -----------------------------------------------------------------------------
# 빌드 스크립트 복사 및 실행
COPY docker/build-scripts/build-opencv.sh /tmp/
RUN chmod +x /tmp/build-opencv.sh && \
    /tmp/build-opencv.sh && \
    rm /tmp/build-opencv.sh

# -----------------------------------------------------------------------------
# Xaiva Media 빌드
# -----------------------------------------------------------------------------
# 소스 코드 복사
ARG XAIVA_SOURCE_PATH
COPY ${XAIVA_SOURCE_PATH}/ /tmp/xaiva-media/

# CUDA 환경 변수 설정
ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda
ENV CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda
ENV XAIVA_SOURCE_PATH=/tmp/xaiva-media

# 빌드 스크립트 복사 및 실행
COPY docker/build-scripts/build-xaiva-media.sh /tmp/
RUN chmod +x /tmp/build-xaiva-media.sh && \
    /tmp/build-xaiva-media.sh && \
    rm /tmp/build-xaiva-media.sh

# 빌드 산출물 확인
RUN echo "Builder stage completed" && \
    echo "Installed libraries:" && \
    ls -la /usr/local/lib/ | head -20 || true && \
    echo "Installed binaries:" && \
    ls -la /usr/local/bin/ | head -20 || true

# -----------------------------------------------------------------------------
# Stage 2: Dev (개발/배포 통합 이미지)
# -----------------------------------------------------------------------------
FROM builder AS dev

# 런타임 라이브러리 및 개발 도구 추가 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    # FFmpeg 런타임 라이브러리 (runtime에서 이동)
    libass9 \
    libfreetype6 \
    libgnutls30 \
    libmp3lame0 \
    libva2 \
    libvdpau1 \
    libvorbis0a \
    libxcb1 \
    libxcb-shm0 \
    libxcb-xfixes0 \
    # OpenCV 런타임 라이브러리 (runtime에서 이동)
    libjpeg8 \
    libtiff5 \
    libpng16-16 \
    libwebp7 \
    libopenjp2-7 \
    libtbb2 \
    # 추가 런타임 패키지
    libnuma1 \
    # 개발 도구
    gdb \
    valgrind \
    strace \
    htop \
    tmux \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# GDB Dashboard 설치 (디버깅 편의성)
RUN wget -P ~ https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit && \
    pip3 install pygments

# 라이브러리 캐시 업데이트
RUN ldconfig

# Python 패키지 설치 (runtime에 필요한 추가 패키지, 하이브리드 빌드 지원)
COPY artifacts/${PRESET_NAME}/requirements.txt /tmp/requirements.txt
RUN if [ "$BUILD_MODE" = "offline" ] && [ -d "/tmp/wheels" ] && [ "$(ls -A /tmp/wheels 2>/dev/null)" ]; then \
        echo "=== Offline mode: Installing runtime packages from local wheels ==="; \
        # 이미 설치된 패키지들과 find-links 지시문 제외
        grep -v -E "^torch|^torchvision|^torchaudio|^numpy==|^scipy==|^--find-links" /tmp/requirements.txt > /tmp/filtered-runtime.txt; \
        pip3 install --no-index --find-links=/tmp/wheels -r /tmp/filtered-runtime.txt; \
        rm /tmp/filtered-runtime.txt; \
    else \
        echo "=== Online mode: Installing runtime packages ==="; \
        pip3 install -r /tmp/requirements.txt; \
    fi && \
    pip3 cache purge && \
    rm -rf /tmp/requirements.txt

# 환경 변수 설정 (개발/런타임 통합)
# /usr/local/bin 과 /usr/local/lib 는 시스템 기본 PATH에 포함됨
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"

# 작업 디렉터리 설정
WORKDIR /workspace

# Bash alias 설정
RUN echo "alias python=python3" >> /root/.bashrc

# 헬스체크 (선택적)
# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#   CMD python3 -c "import torch; print(torch.cuda.is_available())" || exit 1

# 기본 명령
CMD ["/bin/bash"]

