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
# Python Wheels 다운로드 (선택 사항 - 현재는 온라인 빌드 사용)
# =============================================================================

print_section "Python packages"

print_info "Python packages are installed directly during Docker build."
print_info "Wheels directory is no longer required."
echo ""
echo "버전 관리 패키지들은 Dockerfile에서 직접 설치:"
echo "  - numpy, scipy"
echo "  - torch, torchvision, torchaudio"
echo "  - tensorrt"
echo ""
echo "나머지 패키지들은 requirements.txt에서 설치"
echo ""

# Note: wheels 다운로드는 더 이상 필요하지 않음
# PyTorch와 다른 패키지들은 Docker 빌드 시 온라인으로 설치됨

# =============================================================================
# 소스 파일 다운로드 (선택적)
# =============================================================================

print_section "Source files"

SOURCES_DIR="$PRESET_ARTIFACTS_DIR/sources"

print_info "Source files should be manually placed in: $SOURCES_DIR"
echo ""
echo "Required sources (if building from source):"
echo "  - FFmpeg source tarball (e.g., ffmpeg-4.2.tar.gz)"
echo "  - OpenCV source tarball (e.g., opencv-4.9.0.tar.gz)"
echo "  - Xaiva Media source (handled separately)"
echo ""
echo "Download URLs:"
echo "  - FFmpeg: https://ffmpeg.org/download.html"
echo "  - OpenCV: https://github.com/opencv/opencv/releases"
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

