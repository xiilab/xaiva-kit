#!/bin/bash
# build-codecs.sh - 비디오 코덱 라이브러리 빌드 스크립트
# 
# 이 스크립트는 FFmpeg에서 사용할 다양한 코덱 라이브러리를 빌드합니다.
# 빌드되는 라이브러리:
#   - x264: H.264/AVC 인코더 (가장 널리 사용되는 비디오 코덱)
#   - x265: H.265/HEVC 인코더 (차세대 비디오 코덱, 더 나은 압축률)
#   - libvpx: VP8/VP9 코덱 (Google의 오픈소스 비디오 코덱)
#   - opus: 오디오 코덱 (낮은 지연시간, 높은 품질)
#   - fdk-aac: AAC 오디오 코덱 (고품질 오디오 인코딩)
#
# 모든 라이브러리는 정적 라이브러리로 빌드되어 FFmpeg에 링크됩니다.
# 빌드 결과물은 ${THIRD_PARTY_PATH}/ffmpeg_build 에 설치됩니다.

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

# 빌드 디렉터리 생성
log_info "Creating build directory: ${THIRD_PARTY_PATH}/ffmpeg_build"
mkdir -p ${THIRD_PARTY_PATH}/ffmpeg_build

# -----------------------------------------------------------------------------
# x264 빌드
# -----------------------------------------------------------------------------
log_info "Building x264..."
cd /root
git clone --depth 1 https://code.videolan.org/videolan/x264.git
cd x264

PATH="${THIRD_PARTY_PATH}/libx264:$PATH" PKG_CONFIG_PATH="${THIRD_PARTY_PATH}/pkgconfig" \
./configure --prefix="${THIRD_PARTY_PATH}/ffmpeg_build" \
            --bindir="${THIRD_PARTY_PATH}/libx264" \
            --enable-static \
            --enable-pic

PATH="${THIRD_PARTY_PATH}/libx264:$PATH" make -j$(nproc)
make install

# 정리
cd /root && rm -rf x264
log_info "x264 build completed"

# -----------------------------------------------------------------------------
# x265 빌드
# -----------------------------------------------------------------------------
log_info "Building x265..."
cd /root
wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2
tar xjvf x265.tar.bz2
cd multicoreware*/build/linux

PATH="${THIRD_PARTY_PATH}/libx265:$PATH" \
cmake -G "Unix Makefiles" \
      -DCMAKE_INSTALL_PREFIX="${THIRD_PARTY_PATH}/ffmpeg_build" \
      -DENABLE_SHARED:bool=off \
      ../../source

PATH="${THIRD_PARTY_PATH}/libx265:$PATH" make -j$(nproc)
make install

# pkg-config 파일 수정 (누락된 의존성 추가)
sed -i '/^Libs.private/c\Libs.private: -lstdc++ -lm -lgcc -lrt -ldl -lnuma' \
    ${THIRD_PARTY_PATH}/ffmpeg_build/lib/pkgconfig/x265.pc

# 정리
cd /root
rm -f x265.tar.bz2
rm -rf multicoreware*
log_info "x265 build completed"

# -----------------------------------------------------------------------------
# libvpx 빌드
# -----------------------------------------------------------------------------
log_info "Building libvpx..."
cd /root
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx

PATH="${THIRD_PARTY_PATH}/libvpx:$PATH" \
./configure --prefix="${THIRD_PARTY_PATH}/ffmpeg_build" \
            --enable-pic \
            --enable-static \
            --disable-examples \
            --disable-unit-tests \
            --enable-vp9-highbitdepth \
            --as=yasm

PATH="${THIRD_PARTY_PATH}/libvpx:$PATH" make -j$(nproc)
make install

# 정리
cd /root && rm -rf libvpx
log_info "libvpx build completed"

# -----------------------------------------------------------------------------
# opus 빌드
# -----------------------------------------------------------------------------
log_info "Building opus..."
cd /root
git clone --depth 1 https://github.com/xiph/opus.git
cd opus

./autogen.sh
./configure --prefix="${THIRD_PARTY_PATH}/ffmpeg_build" \
            --with-pic \
            --disable-shared

make -j$(nproc)
make install

# 정리
cd /root && rm -rf opus
log_info "opus build completed"

# -----------------------------------------------------------------------------
# fdk-aac 빌드
# -----------------------------------------------------------------------------
log_info "Building fdk-aac..."
cd /root
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac

autoreconf -fiv
./configure --prefix="${THIRD_PARTY_PATH}/ffmpeg_build" \
            --with-pic \
            --disable-shared

make -j$(nproc)
make install

# 정리
cd /root && rm -rf fdk-aac
log_info "fdk-aac build completed"

# -----------------------------------------------------------------------------
# NVIDIA 코덱 헤더 설치
# -----------------------------------------------------------------------------
log_info "Installing NVIDIA codec headers..."
cd /usr/include/linux
ln -s -f ../libv4l1-videodev.h videodev.h

cd /root
git clone --single-branch https://github.com/FFmpeg/nv-codec-headers.git
cd nv-codec-headers
make && make install

# 정리
cd /root && rm -rf nv-codec-headers
log_info "NVIDIA codec headers installed"

log_info "All codec libraries built successfully!"
log_info "Build artifacts installed in: ${THIRD_PARTY_PATH}/ffmpeg_build"