#!/usr/bin/env python3
"""
XaivaKit - Interactive Build Driver

이 스크립트는 프리셋 기반 Docker 이미지 빌드를 대화형으로 수행합니다.
Python 표준 라이브러리만 사용하여 구현되었습니다.

사용법:
    python3 scripts/build.py                           # 대화형 모드
    python3 scripts/build.py --preset <name>           # 프리셋 지정
    python3 scripts/build.py --non-interactive         # 비대화형 모드
    python3 scripts/build.py --help                    # 도움말
"""

import argparse
import os
import sys
from pathlib import Path

# builder 모듈 임포트
from builder import (
    # preset
    load_presets,
    validate_preset,
    check_preset_artifacts,
    # docker
    build_docker_image,
    generate_image_tag,
    # ui
    select_preset,
    select_build_type,
    confirm_build,
    # utils
    print_header,
    print_section,
    print_error,
    print_warning,
    print_success,
)


# 프로젝트 경로 설정
PROJECT_ROOT = Path(__file__).parent.parent
ENV_FILE = PROJECT_ROOT / ".env"
ENV_TEMPLATE = PROJECT_ROOT / "env.template"

# 빌드 타입 정의
BUILD_TYPES = ["runtime", "dev"]
DEFAULT_BUILD_TYPE = "runtime"


def load_env_file() -> dict:
    """
    .env 파일을 로드합니다.
    
    Returns:
        환경 변수 딕셔너리
    """
    env_vars = {}
    
    if not ENV_FILE.exists():
        print_warning(f".env file not found. Using template: {ENV_TEMPLATE}")
        if ENV_TEMPLATE.exists():
            print(f"Run: cp {ENV_TEMPLATE} {ENV_FILE}")
        return env_vars
    
    try:
        with open(ENV_FILE, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                
                # 주석과 빈 줄 무시
                if not line or line.startswith('#'):
                    continue
                
                # KEY=VALUE 형식 파싱
                if '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
    
    except Exception as e:
        print_warning(f"Failed to load .env file: {e}")
    
    return env_vars


def main():
    """메인 함수"""
    
    # 인자 파서 설정
    parser = argparse.ArgumentParser(
        description="XaivaKit - Interactive Build Driver",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 scripts/build.py
      Interactive mode - prompts for preset and build type
  
  python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1
      Build with specified preset (prompts for build type)
  
  python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1 --build-type runtime
      Fully non-interactive build
  
  python3 scripts/build.py --list-presets
      List available presets and exit
        """
    )
    
    parser.add_argument(
        "--preset",
        type=str,
        help="Preset name to use (skips preset selection)"
    )
    
    parser.add_argument(
        "--build-type",
        type=str,
        choices=BUILD_TYPES,
        help=f"Build type: {', '.join(BUILD_TYPES)}"
    )
    
    parser.add_argument(
        "--non-interactive",
        action="store_true",
        help="Non-interactive mode (uses defaults)"
    )
    
    parser.add_argument(
        "--list-presets",
        action="store_true",
        help="List available presets and exit"
    )
    
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show docker build command without executing"
    )
    
    args = parser.parse_args()
    
    # 헤더 출력
    print_header("XaivaKit - Build Driver")
    
    # 프리셋 로드
    presets = load_presets()
    
    if not presets:
        print_error("No presets found!")
        print(f"Please add preset JSON files to: {PROJECT_ROOT / 'presets'}")
        sys.exit(1)
    
    print_success(f"Loaded {len(presets)} preset(s)")
    
    # --list-presets 처리
    if args.list_presets:
        print_section("Available Presets")
        for name, preset in presets.items():
            desc = preset.get("metadata", {}).get("description", "")
            print(f"  • {name}")
            if desc:
                print(f"    {desc}")
        sys.exit(0)
    
    # 프리셋 선택
    if args.preset:
        if args.preset not in presets:
            print_error(f"Preset not found: {args.preset}")
            print(f"Available presets: {', '.join(presets.keys())}")
            sys.exit(1)
        preset_name = args.preset
    else:
        if args.non_interactive:
            # 비대화형 모드에서는 첫 번째 프리셋 사용
            preset_name = list(presets.keys())[0]
            print(f"Using default preset: {preset_name}")
        else:
            preset_name = select_preset(presets)
    
    preset = presets[preset_name]
    
    # 프리셋 검증
    print_section(f"Validating preset: {preset_name}")
    
    errors = validate_preset(preset)
    if errors:
        print_error("Preset validation failed:")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)
    
    print_success("Preset is valid")
    
    # Artifacts 체크
    warnings = check_preset_artifacts(preset_name)
    if warnings:
        print_warning("Artifacts check:")
        for warning in warnings:
            print(f"  - {warning}")
        
        if not args.non_interactive:
            choice = input("\nContinue anyway? (y/n) [n]: ").strip().lower()
            if choice != 'y':
                print("Build cancelled")
                sys.exit(0)
    
    # 빌드 타입 선택
    if args.build_type:
        build_type = args.build_type
    else:
        if args.non_interactive:
            build_type = DEFAULT_BUILD_TYPE
            print(f"Using default build type: {build_type}")
        else:
            build_type = select_build_type()
    
    # 환경 변수 로드
    env_vars = load_env_file()
    
    # 빌드 확인
    image_tag = generate_image_tag(preset_name, build_type)
    
    if not args.non_interactive and not args.dry_run:
        if not confirm_build(preset_name, build_type, image_tag):
            print("Build cancelled")
            sys.exit(0)
    
    # 빌드 실행
    exit_code = build_docker_image(
        preset=preset,
        preset_name=preset_name,
        build_type=build_type,
        env_vars=env_vars,
        dry_run=args.dry_run
    )
    
    if exit_code == 0:
        print_success(f"Build completed successfully!")
        print(f"\nImage tag: {image_tag}")
        print(f"\nRun with:")
        print(f"  docker run --rm -it --gpus all {image_tag}")
    else:
        print_error(f"Build failed with exit code {exit_code}")
    
    sys.exit(exit_code)


if __name__ == "__main__":
    main()