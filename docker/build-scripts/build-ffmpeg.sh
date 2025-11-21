#!/bin/bash
# build-ffmpeg.sh - FFmpeg 빌드 스크립트
#
# 이 스크립트는 CUDA 지원이 포함된 FFmpeg를 빌드합니다.
# 
# 주요 기능:
#   - NVIDIA GPU 하드웨어 가속 (CUDA, CUVID)
#   - 다양한 코덱 지원 (x264, x265, VP9, AAC, Opus)
#   - 정적 라이브러리로 빌드 (배포 용이성)
#
# 전제 조건:
#   - 코덱 라이브러리가 이미 빌드되어 있어야 함 (build-codecs.sh)
#   - CUDA가 설치되어 있어야 함
#   - 환경 변수 설정: THIRD_PARTY_PATH, FFMPEG_VERSION

set -e  # 에러 발생시 즉시 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로깅 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 환경 변수 확인
if [ -z "${THIRD_PARTY_PATH}" ]; then
    log_error "THIRD_PARTY_PATH is not set"
    exit 1
fi

if [ -z "${FFMPEG_VERSION}" ]; then
    log_error "FFMPEG_VERSION is not set"
    exit 1
fi

# PKG_CONFIG_PATH 설정 확인
log_info "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"

# -----------------------------------------------------------------------------
# FFmpeg 다운로드 및 압축 해제
# -----------------------------------------------------------------------------
log_info "Downloading FFmpeg ${FFMPEG_VERSION}..."
cd /root
mkdir -p ~/ffmpeg_sources
cd ~/ffmpeg_sources

wget -O ffmpeg-${FFMPEG_VERSION}.tar.bz2 https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2
tar xjvf ffmpeg-${FFMPEG_VERSION}.tar.bz2
cd ffmpeg-${FFMPEG_VERSION}

# -----------------------------------------------------------------------------
# FFmpeg 빌드 설정
# -----------------------------------------------------------------------------
log_info "Configuring FFmpeg build..."
log_info "  - Static libraries only"
log_info "  - CUDA/CUVID hardware acceleration"
log_info "  - Codecs: x264, x265, VP9, AAC, Opus"

PATH="${THIRD_PARTY_PATH}/ffmpeg:$PATH" ./configure \
  --prefix="${THIRD_PARTY_PATH}/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="${THIRD_PARTY_PATH}/ffmpeg" \
  --disable-shared \
  --enable-static \
  --enable-gpl \
  --enable-libfdk-aac \
  --enable-libvpx \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libx264 \
  --enable-libx265 \
  --enable-cuda \
  --enable-cuvid \
  --extra-cflags='-I/usr/local/cuda/include -static' \
  --extra-ldflags='-L/usr/local/cuda/lib64 -static' \
  --enable-nonfree

# -----------------------------------------------------------------------------
# FFmpeg 빌드
# -----------------------------------------------------------------------------
log_info "Building FFmpeg (this may take a while)..."
PATH="${THIRD_PARTY_PATH}/ffmpeg:$PATH" make -j$(nproc)

# -----------------------------------------------------------------------------
# FFmpeg 설치
# -----------------------------------------------------------------------------
log_info "Installing FFmpeg..."
make install
hash -r

# -----------------------------------------------------------------------------
# 표준 경로로 복사
# -----------------------------------------------------------------------------
log_info "Copying FFmpeg to standard paths..."

# 라이브러리 복사
cp -r ${THIRD_PARTY_PATH}/ffmpeg_build/lib/* /usr/local/lib/

# 헤더 파일 복사
cp -r ${THIRD_PARTY_PATH}/ffmpeg_build/include/* /usr/local/include/

# 실행 파일 복사 (있는 경우)
if [ -d "${THIRD_PARTY_PATH}/ffmpeg" ]; then
    cp ${THIRD_PARTY_PATH}/ffmpeg/* /usr/local/bin/ 2>/dev/null || true
fi

# 라이브러리 캐시 업데이트
ldconfig

# -----------------------------------------------------------------------------
# 정리
# -----------------------------------------------------------------------------
log_info "Cleaning up..."
cd /root
rm -rf ~/ffmpeg_sources

# -----------------------------------------------------------------------------
# 설치 확인
# -----------------------------------------------------------------------------
log_info "FFmpeg installation completed!"
log_info "Installation paths:"
log_info "  - Libraries: /usr/local/lib/"
log_info "  - Headers: /usr/local/include/"
log_info "  - Binaries: /usr/local/bin/ (if built)"

# 버전 확인 (실행 파일이 있는 경우)
if command -v ffmpeg &> /dev/null; then
    log_info "FFmpeg version:"
    ffmpeg -version | head -n 1
fi