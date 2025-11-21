#!/bin/bash
# build-xaiva-media.sh - Xaiva Media 라이브러리 빌드 스크립트
#
# 이 스크립트는 Xaiva Media 라이브러리를 빌드하고 설치합니다.
#
# Xaiva Media 구성 요소:
#   - XaivaDecoder: 하드웨어 가속 비디오 디코딩 (NVDEC, FFmpeg)
#   - XaivaEncoder: 하드웨어 가속 비디오 인코딩 (NVENC, FFmpeg)
#   - XaivaImageProcessor: CUDA 가속 이미지 처리
#   - XaivaMuxer: 컨테이너 포맷 처리
#
# 모든 컴포넌트는 Python 바인딩(pybind11)을 포함합니다.
#
# 전제 조건:
#   - CUDA가 설치되어 있어야 함
#   - FFmpeg가 빌드되어 있어야 함
#   - OpenCV가 빌드되어 있어야 함
#   - 환경 변수 설정: CUDA_ARCH, XAIVA_SOURCE_PATH

set -e  # 에러 발생시 즉시 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 환경 변수 확인
if [ -z "${CUDA_ARCH}" ]; then
    log_error "CUDA_ARCH is not set"
    exit 1
fi

if [ -z "${XAIVA_SOURCE_PATH}" ]; then
    log_warn "XAIVA_SOURCE_PATH is not set, using default: /tmp/xaiva-media"
    XAIVA_SOURCE_PATH="/tmp/xaiva-media"
fi

# CUDA 환경 변수 설정
export CUDA_HOME=/usr/local/cuda
export CUDA_PATH=/usr/local/cuda
export CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda

log_info "Building Xaiva Media Library..."
log_info "CUDA Architecture: ${CUDA_ARCH}"
log_info "Source path: ${XAIVA_SOURCE_PATH}"

# -----------------------------------------------------------------------------
# 소스 코드 확인
# -----------------------------------------------------------------------------
if [ ! -d "${XAIVA_SOURCE_PATH}" ]; then
    log_error "Xaiva Media source not found at: ${XAIVA_SOURCE_PATH}"
    exit 1
fi

cd "${XAIVA_SOURCE_PATH}"

# -----------------------------------------------------------------------------
# 빌드 디렉터리 생성 및 CMake 설정
# -----------------------------------------------------------------------------
log_info "Creating build directory and configuring CMake..."
mkdir -p build
cd build

# CMake 설정
# 주요 옵션:
#   - CMAKE_POSITION_INDEPENDENT_CODE: Python 바인딩을 위한 PIC
#   - CMAKE_BUILD_TYPE=Release: 최적화된 릴리즈 빌드
#   - CUDA_ARCH: 타겟 GPU 아키텍처
cmake -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DCUDA_ARCH=${CUDA_ARCH} ..

# -----------------------------------------------------------------------------
# 빌드 실행
# -----------------------------------------------------------------------------
log_info "Building Xaiva Media (this may take a while)..."
BUILD_LOG="build_log_$(date +%Y%m%d_%H%M%S).log"
make -j$(nproc) 2>&1 | tee "${BUILD_LOG}"

# -----------------------------------------------------------------------------
# 빌드 결과 확인
# -----------------------------------------------------------------------------
log_info "Checking build results..."
if [ ! -d "/tmp/xaiva-media/lib" ]; then
    log_error "Build failed: lib directory not found"
    log_error "Check build log: ${BUILD_LOG}"
    exit 1
fi

ls -la /tmp/xaiva-media/lib/

# -----------------------------------------------------------------------------
# Python site-packages 경로 가져오기
# -----------------------------------------------------------------------------
PYTHON_PACKAGES_PATH=$(python3 -c "import site; print(site.getsitepackages()[0])")
log_info "Python packages path: ${PYTHON_PACKAGES_PATH}"

# -----------------------------------------------------------------------------
# 라이브러리 설치
# -----------------------------------------------------------------------------
log_info "Installing Xaiva Media libraries..."

# Python 모듈 설치 (.so 파일들)
log_info "Installing Python modules to ${PYTHON_PACKAGES_PATH}..."
for module in XaivaDecoder.so XaivaImageProcessor.so XaivaEncoder.so XaivaMuxer.so; do
    if [ -f "/tmp/xaiva-media/lib/${module}" ]; then
        cp -v "/tmp/xaiva-media/lib/${module}" "${PYTHON_PACKAGES_PATH}/"
    else
        log_warn "Module not found: ${module}"
    fi
done

# 시스템 라이브러리 설치
log_info "Installing system libraries to /usr/local/lib..."
cp -v /tmp/xaiva-media/lib/*.so /usr/local/lib/

# -----------------------------------------------------------------------------
# 리소스 파일 설치
# -----------------------------------------------------------------------------
log_info "Installing resource files..."

# 폰트 파일
if [ -d "/tmp/xaiva-media/resources/fonts" ]; then
    mkdir -p /usr/local/xaiva_media/resources/fonts
    cp -r /tmp/xaiva-media/resources/fonts/* /usr/local/xaiva_media/resources/fonts/ 2>/dev/null || true
    log_info "Font resources installed"
fi

# 샘플 파일 (선택적)
if [ -d "/tmp/xaiva-media/samples" ]; then
    mkdir -p /usr/local/xaiva_media/samples
    cp -r /tmp/xaiva-media/samples/* /usr/local/xaiva_media/samples/ 2>/dev/null || true
    log_info "Sample files installed"
fi

# -----------------------------------------------------------------------------
# 라이브러리 캐시 업데이트
# -----------------------------------------------------------------------------
log_info "Updating library cache..."
ldconfig

# -----------------------------------------------------------------------------
# 설치 확인
# -----------------------------------------------------------------------------
log_info "Verifying installation..."

# Python 모듈 확인
log_info "Installed Python modules:"
ls -la ${PYTHON_PACKAGES_PATH}/Xaiva*.so || log_warn "No Python modules found"

# 시스템 라이브러리 확인
log_info "Installed system libraries:"
ls -la /usr/local/lib/Xaiva*.so || log_warn "No system libraries found"

# Python에서 모듈 import 테스트
log_info "Testing Python imports..."
python3 -c "import XaivaDecoder; print('XaivaDecoder imported successfully')" 2>/dev/null || log_warn "Failed to import XaivaDecoder"
python3 -c "import XaivaEncoder; print('XaivaEncoder imported successfully')" 2>/dev/null || log_warn "Failed to import XaivaEncoder"
python3 -c "import XaivaImageProcessor; print('XaivaImageProcessor imported successfully')" 2>/dev/null || log_warn "Failed to import XaivaImageProcessor"
python3 -c "import XaivaMuxer; print('XaivaMuxer imported successfully')" 2>/dev/null || log_warn "Failed to import XaivaMuxer"

log_info "Xaiva Media build and installation completed!"
log_info "Build log saved to: ${XAIVA_SOURCE_PATH}/build/${BUILD_LOG}"