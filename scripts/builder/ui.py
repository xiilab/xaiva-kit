"""
대화형 UI 모듈

사용자와의 대화형 인터페이스를 제공합니다.
"""

import sys
from typing import Dict, Any

from .utils import print_section, print_error
from .docker import generate_image_tag


# 빌드 타입 정의
BUILD_TYPES = ["runtime", "dev"]
DEFAULT_BUILD_TYPE = "runtime"


def select_preset(presets: Dict[str, Dict[str, Any]]) -> str:
    """
    사용자가 프리셋을 선택하도록 합니다.
    
    Args:
        presets: 프리셋 딕셔너리
    
    Returns:
        선택된 프리셋 이름
    """
    print_section("Available Presets")
    
    preset_list = list(presets.keys())
    
    for idx, preset_name in enumerate(preset_list, 1):
        preset = presets[preset_name]
        desc = preset.get("metadata", {}).get("description", "No description")
        print(f"  {idx}. {preset_name}")
        print(f"     {desc}")
    
    while True:
        try:
            choice = input(f"\nSelect preset (1-{len(preset_list)}): ").strip()
            idx = int(choice) - 1
            
            if 0 <= idx < len(preset_list):
                return preset_list[idx]
            else:
                print_error(f"Please enter a number between 1 and {len(preset_list)}")
        
        except ValueError:
            print_error("Please enter a valid number")
        except KeyboardInterrupt:
            print("\n\nBuild cancelled by user")
            sys.exit(0)


def select_build_type() -> str:
    """
    사용자가 빌드 타입을 선택하도록 합니다.
    
    Returns:
        선택된 빌드 타입
    """
    print_section("Build Type")
    print("  1. runtime - Production image (minimal size)")
    print("  2. dev     - Development image (includes build tools)")
    
    while True:
        try:
            choice = input(f"\nSelect build type (1-2) [default: 1]: ").strip()
            
            if not choice:
                return DEFAULT_BUILD_TYPE
            
            idx = int(choice) - 1
            
            if 0 <= idx < len(BUILD_TYPES):
                return BUILD_TYPES[idx]
            else:
                print_error("Please enter 1 or 2")
        
        except ValueError:
            print_error("Please enter a valid number")
        except KeyboardInterrupt:
            print("\n\nBuild cancelled by user")
            sys.exit(0)


def confirm_build(preset_name: str, build_type: str, image_tag: str) -> bool:
    """
    빌드 실행 확인
    
    Args:
        preset_name: 프리셋 이름
        build_type: 빌드 타입
        image_tag: Docker 이미지 태그
    
    Returns:
        True if confirmed, False otherwise
    """
    print_section("Build Summary")
    print(f"  Preset:     {preset_name}")
    print(f"  Build Type: {build_type}")
    print(f"  Image Tag:  {image_tag}")
    
    while True:
        try:
            choice = input("\nProceed with build? (y/n) [y]: ").strip().lower()
            
            if not choice or choice == 'y':
                return True
            elif choice == 'n':
                return False
            else:
                print_error("Please enter 'y' or 'n'")
        
        except KeyboardInterrupt:
            print("\n\nBuild cancelled by user")
            sys.exit(0)