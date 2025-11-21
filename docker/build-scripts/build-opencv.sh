#!/bin/bash
# build-opencv.sh - OpenCV 빌드 스크립트
#
# 이 스크립트는 CUDA 지원이 포함된 OpenCV를 빌드합니다.
#
# 주요 기능:
#   - CUDA/cuDNN 가속 지원
#   - Python 바인딩 포함
#   - FFmpeg 통합 (비디오 처리)
#   - 정적 라이브러리 빌드
#   - C++11 ABI=0 (PyTorch 2.1.0 호환성)
#
# 전제 조건:
#   - CUDA/cuDNN이 설치되어 있어야 함
#   - Python이 설치되어 있어야 함
#   - 환경 변수 설정: OPENCV_VERSION, CUDA_ARCH

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
if [ -z "${OPENCV_VERSION}" ]; then
    log_error "OPENCV_VERSION is not set"
    exit 1
fi

if [ -z "${CUDA_ARCH}" ]; then
    log_error "CUDA_ARCH is not set"
    exit 1
fi

# -----------------------------------------------------------------------------
# Python 환경 정보 수집
# -----------------------------------------------------------------------------
log_info "Detecting Python environment..."

PYTHON_VERSION_FULL="$(python3 -c 'import sys; print(str(sys.version_info[0])+"."+str(sys.version_info[1]))')"
PYTHON_LIB_PATH="$(python3 -c 'from distutils.sysconfig import get_config_var;print("{}/{}".format(get_config_var("LIBDIR"), get_config_var("INSTSONAME")))')"
PYTHON_INCLUDE_PATH="$(python3 -c 'from sysconfig import get_paths as gp; print(gp()["include"])')"
PYTHON_PACKAGE_PATH="$(python3 -c 'import site; print(site.getsitepackages()[0])')"
CUDA_TOOLKIT_PATH=/usr/local/cuda

log_info "Python version: ${PYTHON_VERSION_FULL}"
log_info "Python library: ${PYTHON_LIB_PATH}"
log_info "Python include: ${PYTHON_INCLUDE_PATH}"
log_info "Python packages: ${PYTHON_PACKAGE_PATH}"
log_info "CUDA toolkit: ${CUDA_TOOLKIT_PATH}"
log_info "CUDA architecture: ${CUDA_ARCH}"

# -----------------------------------------------------------------------------
# OpenCV 다운로드
# -----------------------------------------------------------------------------
log_info "Downloading OpenCV ${OPENCV_VERSION}..."
cd /root

# OpenCV 메인 저장소
wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip
unzip opencv.zip

# OpenCV contrib 모듈 (추가 기능)
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip
unzip opencv_contrib.zip

# -----------------------------------------------------------------------------
# OpenCV 빌드 설정
# -----------------------------------------------------------------------------
log_info "Configuring OpenCV build..."
cd opencv-${OPENCV_VERSION}
mkdir build && cd build

# CMake 설정
# 주요 옵션 설명:
#   - CMAKE_BUILD_TYPE=RELEASE: 최적화된 릴리즈 빌드
#   - WITH_CUDA=ON: CUDA 가속 활성화
#   - WITH_CUDNN=ON: cuDNN 가속 활성화
#   - OPENCV_DNN_CUDA=ON: DNN 모듈에서 CUDA 사용
#   - BUILD_SHARED_LIBS=OFF: 정적 라이브러리 빌드
#   - CMAKE_CXX_FLAGS='-D_GLIBCXX_USE_CXX11_ABI=0': PyTorch 호환성

cmake -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr/local \
  -D WITH_MKL=ON \
  -D WITH_IPP=OFF \
  -D WITH_ITT=OFF \
  -D WITH_1394=OFF \
  -D WITH_TBB=ON \
  -D BUILD_WITH_DEBUG_INFO=OFF \
  -D BUILD_DOCS=OFF \
  -D INSTALL_C_EXAMPLES=OFF \
  -D INSTALL_PYTHON_EXAMPLES=OFF \
  -D WITH_JPEG=ON \
  -D WITH_WEBP=ON \
  -D WITH_TIFF=OFF \
  -D BUILD_PNG=ON \
  -D BUILD_EXAMPLES=OFF \
  -D BUILD_TESTS=OFF \
  -D BUILD_PERF_TESTS=OFF \
  -D WITH_QT=OFF \
  -D WITH_GTK=OFF \
  -D WITH_OPENGL=OFF \
  -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENCV_VERSION}/modules \
  -D WITH_V4L=OFF \
  -D WITH_FFMPEG=ON \
  -D WITH_XINE=ON \
  -D WITH_OPENEXR=OFF \
  -D BUILD_opencv_python3=ON \
  -D PYTHON3_LIBRARY=${PYTHON_LIB_PATH} \
  -D PYTHON3_INCLUDE_DIR=${PYTHON_INCLUDE_PATH} \
  -D PYTHON3_EXECUTABLE=$(which python3) \
  -D PYTHON3_PACKAGES_PATH=${PYTHON_PACKAGE_PATH} \
  -D BUILD_NEW_PYTHON_SUPPORT=ON \
  -D OPENCV_GENERATE_PKGCONFIG=ON \
  -D CMAKE_CXX_FLAGS='-D_GLIBCXX_USE_CXX11_ABI=0' \
  -D CUDA_TOOLKIT_ROOT_DIR=${CUDA_TOOLKIT_PATH} \
  -D ENABLE_FAST_MATH=1 \
  -D CUDA_FAST_MATH=1 \
  -D WITH_CUBLAS=ON \
  -D WITH_CUDA=ON \
  -D WITH_CUDNN=ON \
  -D CUDA_CUDART_LIBRARY=${CUDA_TOOLKIT_PATH}/lib64/libcudart.so \
  -D CUDA_USE_STATIC_CUDA_RUNTIME=OFF \
  -D OPENCV_DNN_CUDA=ON \
  -D WITH_NVCUVID=ON \
  -D CUDA_ARCH_BIN=${CUDA_ARCH} \
  -D CUDA_ARCH_PTX=${CUDA_ARCH} \
  -D BUILD_SHARED_LIBS=OFF ../

# -----------------------------------------------------------------------------
# OpenCV 빌드
# -----------------------------------------------------------------------------
log_info "Building OpenCV (this may take a while)..."
make -j$(nproc)

# -----------------------------------------------------------------------------
# OpenCV 설치
# -----------------------------------------------------------------------------
log_info "Installing OpenCV..."
make install
ldconfig

# -----------------------------------------------------------------------------
# 정리
# -----------------------------------------------------------------------------
log_info "Cleaning up..."
cd /root
rm -f opencv.zip
rm -f opencv_contrib.zip
rm -rf opencv_contrib-${OPENCV_VERSION}
rm -rf opencv-${OPENCV_VERSION}

# -----------------------------------------------------------------------------
# 설치 확인
# -----------------------------------------------------------------------------
log_info "OpenCV installation completed!"
log_info "Installation paths:"
log_info "  - Libraries: /usr/local/lib/"
log_info "  - Headers: /usr/local/include/opencv4/"
log_info "  - Python module: ${PYTHON_PACKAGE_PATH}/cv2/"

# Python에서 OpenCV 확인
log_info "Verifying OpenCV Python binding..."
python3 -c "import cv2; print('OpenCV version:', cv2.__version__); print('CUDA enabled:', cv2.cuda.getCudaEnabledDeviceCount() > 0)" || log_warn "Failed to verify OpenCV Python binding"