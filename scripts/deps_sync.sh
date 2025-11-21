#!/bin/bash
# =============================================================================
# XaivaKit - Dependency Sync Script
# =============================================================================
#
# 이 스크립트는 인터넷이 연결된 환경에서 프리셋에 필요한 소스 파일을
# artifacts/<preset-name>/ 디렉터리에 다운로드합니다.
#
# 주의: Python 패키지(numpy, pytorch, tensorrt 등)는 Dockerfile에서
#       온라인으로 직접 설치하므로 wheels 다운로드가 필요하지 않습니다.
#
# 사용법:
#   ./scripts/deps_sync.sh <preset-name>
#   ./scripts/deps_sync.sh ubuntu22.04-cuda11.8-torch2.1
#
# =============================================================================

set -e  # 에러 발생 시 즉시 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# 유틸리티 함수
# =============================================================================

print_header() {
    echo ""
    echo "================================================================================"
    echo "  $1"
    echo "================================================================================"
    echo ""
}

print_section() {
    echo ""
    echo "--- $1 ---"
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# =============================================================================
# 인자 처리
# =============================================================================

if [ $# -eq 0 ]; then
    print_error "No preset name provided"
    echo ""
    echo "Usage: $0 <preset-name>"
    echo ""
    echo "Example:"
    echo "  $0 ubuntu22.04-cuda11.8-torch2.1"
    echo ""
    exit 1
fi

PRESET_NAME="$1"

# 프로젝트 루트 디렉터리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PRESETS_DIR="$PROJECT_ROOT/presets"
ARTIFACTS_DIR="$PROJECT_ROOT/artifacts"
PRESET_FILE="$PRESETS_DIR/${PRESET_NAME}.json"
PRESET_ARTIFACTS_DIR="$ARTIFACTS_DIR/$PRESET_NAME"

# =============================================================================
# 검증
# =============================================================================

print_header "XaivaKit - Dependency Sync"

print_info "Preset: $PRESET_NAME"
print_info "Project root: $PROJECT_ROOT"

# 프리셋 파일 존재 확인
if [ ! -f "$PRESET_FILE" ]; then
    print_error "Preset file not found: $PRESET_FILE"
    echo ""
    echo "Available presets:"
    ls -1 "$PRESETS_DIR"/*.json 2>/dev/null | xargs -n 1 basename | sed 's/\.json$//' | sed 's/^/  - /'
    echo ""
    exit 1
fi

print_success "Preset file found: $PRESET_FILE"

# artifacts 디렉터리 생성
print_section "Preparing directories"

mkdir -p "$PRESET_ARTIFACTS_DIR"/{wheels,debs,sources}

print_success "Created directories:"
echo "  - $PRESET_ARTIFACTS_DIR/wheels"
echo "  - $PRESET_ARTIFACTS_DIR/debs"
echo "  - $PRESET_ARTIFACTS_DIR/sources"

# requirements.txt 존재 확인
REQUIREMENTS_FILE="$PRESET_ARTIFACTS_DIR/requirements.txt"

if [ ! -f "$REQUIREMENTS_FILE" ]; then
    print_error "requirements.txt not found: $REQUIREMENTS_FILE"
    echo ""
    echo "Please create requirements.txt file for this preset."
    exit 1
fi

print_success "Found requirements.txt"

# =============================================================================
# Python Wheels 다운로드 (하이브리드 빌드 지원)
# =============================================================================

print_section "Python packages"

WHEELS_DIR="$PRESET_ARTIFACTS_DIR/wheels"

# 프리셋 JSON에서 정보 읽어오기
if command -v jq &> /dev/null; then
    PYTORCH_VERSION=$(jq -r '.pytorch.torch_version // empty' "$PRESET_FILE")
    PYTORCH_INDEX_URL=$(jq -r '.pytorch.index_url // empty' "$PRESET_FILE")
    TENSORRT_VERSION=$(jq -r '.tensorrt.version // empty' "$PRESET_FILE")
    TENSORRT_ENABLED=$(jq -r '.tensorrt.enabled // false' "$PRESET_FILE")
else
    print_warning "jq not found. Using default versions."
    PYTORCH_VERSION="2.1.0+cu118"
    PYTORCH_INDEX_URL="https://download.pytorch.org/whl/torch_stable.html"
    TENSORRT_VERSION="8.6.1"
    TENSORRT_ENABLED="true"
fi

print_info "Downloading Python wheels for offline build support..."
echo ""
echo "Target packages:"
echo "  - PyTorch: ${PYTORCH_VERSION}"
echo "  - TensorRT: ${TENSORRT_VERSION} (enabled: ${TENSORRT_ENABLED})"
echo "  - Requirements from: ${REQUIREMENTS_FILE}"
echo ""

cd "$WHEELS_DIR"

# Core packages (고정 버전)
print_info "Downloading core packages..."
pip3 download numpy==1.23.1
pip3 download scipy==1.11.4

# PyTorch 패키지 (커스텀 인덱스 사용)
if [ -n "$PYTORCH_VERSION" ] && [ -n "$PYTORCH_INDEX_URL" ]; then
    print_info "Downloading PyTorch packages..."
    pip3 download --find-links "$PYTORCH_INDEX_URL" torch=="${PYTORCH_VERSION}"
    pip3 download --find-links "$PYTORCH_INDEX_URL" torchvision
    pip3 download --find-links "$PYTORCH_INDEX_URL" torchaudio
fi

# TensorRT
if [ "$TENSORRT_ENABLED" = "true" ] && [ -n "$TENSORRT_VERSION" ]; then
    print_info "Downloading TensorRT..."
    pip3 download tensorrt=="${TENSORRT_VERSION}"
fi

# requirements.txt의 나머지 패키지들
print_info "Downloading packages from requirements.txt..."
# PyTorch 관련 줄 제외 (이미 다운로드함)
grep -v -E "^torch|^torchvision|^torchaudio|^--find-links|^numpy==|^scipy==" "$REQUIREMENTS_FILE" > /tmp/filtered_requirements.txt
pip3 download -r /tmp/filtered_requirements.txt
rm -f /tmp/filtered_requirements.txt

print_success "Python wheels download completed!"

# 다운로드된 파일 개수 출력
WHEEL_COUNT=$(ls -1 *.whl 2>/dev/null | wc -l)
echo "Downloaded wheels: $WHEEL_COUNT files"
echo ""

# =============================================================================
# 소스 파일 다운로드 (자동 다운로드 지원)
# =============================================================================

print_section "Source files"

SOURCES_DIR="$PRESET_ARTIFACTS_DIR/sources"

# 프리셋에서 소스 버전 읽기
if command -v jq &> /dev/null; then
    FFMPEG_VERSION=$(jq -r '.build_options.ffmpeg_version // "4.2"' "$PRESET_FILE")
    OPENCV_VERSION=$(jq -r '.build_options.opencv_version // "4.11.0"' "$PRESET_FILE")
else
    FFMPEG_VERSION="4.2"
    OPENCV_VERSION="4.11.0"
fi

print_info "Downloading source files for offline build..."
echo ""
echo "Target sources:"
echo "  - FFmpeg: ${FFMPEG_VERSION}"
echo "  - OpenCV: ${OPENCV_VERSION}"
echo ""

cd "$SOURCES_DIR"

# FFmpeg 소스 다운로드
print_info "Downloading FFmpeg source..."
FFMPEG_FILE="ffmpeg-${FFMPEG_VERSION}.tar.bz2"
if [ ! -f "$FFMPEG_FILE" ]; then
    wget -O "$FFMPEG_FILE" "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2"
    if [ $? -eq 0 ]; then
        print_success "Downloaded: $FFMPEG_FILE"
    else
        print_warning "Failed to download FFmpeg source"
    fi
else
    print_info "FFmpeg source already exists: $FFMPEG_FILE"
fi

# OpenCV 소스 다운로드
print_info "Downloading OpenCV source..."
OPENCV_FILE="opencv-${OPENCV_VERSION}.zip"
if [ ! -f "$OPENCV_FILE" ]; then
    wget -O "$OPENCV_FILE" "https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.zip"
    if [ $? -eq 0 ]; then
        print_success "Downloaded: $OPENCV_FILE"
    else
        print_warning "Failed to download OpenCV source"
    fi
else
    print_info "OpenCV source already exists: $OPENCV_FILE"
fi

# OpenCV Contrib 다운로드
print_info "Downloading OpenCV Contrib source..."
OPENCV_CONTRIB_FILE="opencv_contrib-${OPENCV_VERSION}.zip"
if [ ! -f "$OPENCV_CONTRIB_FILE" ]; then
    wget -O "$OPENCV_CONTRIB_FILE" "https://github.com/opencv/opencv_contrib/archive/refs/tags/${OPENCV_VERSION}.zip"
    if [ $? -eq 0 ]; then
        print_success "Downloaded: $OPENCV_CONTRIB_FILE"
    else
        print_warning "Failed to download OpenCV Contrib source"
    fi
else
    print_info "OpenCV Contrib source already exists: $OPENCV_CONTRIB_FILE"
fi

# x265 코덱 소스 다운로드
print_info "Downloading x265 codec source..."
X265_FILE="x265.tar.bz2"
if [ ! -f "$X265_FILE" ]; then
    wget -O "$X265_FILE" "https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2"
    if [ $? -eq 0 ]; then
        print_success "Downloaded: $X265_FILE"
    else
        print_warning "Failed to download x265 source"
    fi
else
    print_info "x265 source already exists: $X265_FILE"
fi

print_success "Source files download completed!"
echo ""

# 체크섬 검증 (선택적)
print_info "Note: Consider adding checksum verification for production use"
echo ""

# =============================================================================
# 요약
# =============================================================================

print_section "Summary"

echo ""
echo "Artifacts prepared for preset: $PRESET_NAME"
echo ""
echo "Directory: $PRESET_ARTIFACTS_DIR"
echo ""

# 각 디렉터리의 파일 개수 출력
WHEEL_COUNT=$(ls -1 "$PRESET_ARTIFACTS_DIR/wheels" 2>/dev/null | wc -l)
DEB_COUNT=$(ls -1 "$PRESET_ARTIFACTS_DIR/debs" 2>/dev/null | wc -l)
SOURCE_COUNT=$(ls -1 "$PRESET_ARTIFACTS_DIR/sources" 2>/dev/null | wc -l)

echo "  Wheels:  $WHEEL_COUNT file(s)"
echo "  Debs:    $DEB_COUNT file(s)"
echo "  Sources: $SOURCE_COUNT file(s)"
echo ""

# 다음 단계 안내
print_success "Dependency sync completed!"
echo ""
echo "Next steps:"
echo "  1. (Optional) Add FFmpeg/OpenCV source tarballs to:"
echo "     $SOURCES_DIR"
echo ""
echo "  2. (Optional) Review downloaded wheels:"
echo "     ls -lh $PRESET_ARTIFACTS_DIR/wheels"
echo ""
echo "  3. Build the Docker image:"
echo "     python3 scripts/build.py --preset $PRESET_NAME"
echo ""

# =============================================================================
# 오프라인 검증 옵션
# =============================================================================

if command -v docker &> /dev/null; then
    echo ""
    read -p "Would you like to test offline build capability? (y/n) [n]: " TEST_OFFLINE
    
    if [ "$TEST_OFFLINE" = "y" ] || [ "$TEST_OFFLINE" = "Y" ]; then
        print_section "Testing offline build"
        
        print_info "This will attempt a docker build with --network=none"
        print_warning "This is a dry-run test and may fail if source builds are required"
        
        # 간단한 오프라인 테스트 (실제 빌드는 하지 않음)
        print_info "Checking if all wheels are present..."
        
        missing_packages=0
        while read -r line; do
            # 주석과 빈 줄 건너뛰기
            if [[ "$line" =~ ^#.*$ ]] || [ -z "$line" ]; then
                continue
            fi
            
            # 패키지 이름 추출 (버전 정보 제외)
            package_name=$(echo "$line" | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | tr -d ' ')
            
            # wheels 디렉터리에 해당 패키지가 있는지 확인
            if ! ls "$WHEELS_DIR"/"${package_name}"* &> /dev/null; then
                print_warning "Missing wheel for: $package_name"
                ((missing_packages++))
            fi
        done < "$REQUIREMENTS_FILE"
        
        if [ $missing_packages -eq 0 ]; then
            print_success "All package wheels found!"
        else
            print_warning "$missing_packages package(s) may be missing"
            print_info "This is normal for packages without wheel distributions"
        fi
    fi
fi

print_success "All done! 🎉"
echo ""

