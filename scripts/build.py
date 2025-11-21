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
import subprocess
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
    confirm_build,
    # utils
    print_header,
    print_section,
    print_error,
    print_warning,
    print_success,
    print_info,
)


# 프로젝트 경로 설정
PROJECT_ROOT = Path(__file__).parent.parent
ENV_FILE = PROJECT_ROOT / ".env"
ENV_TEMPLATE = PROJECT_ROOT / "env.template"
ARTIFACTS_DIR = PROJECT_ROOT / "artifacts"

# 빌드 타입 제거 - Dev 이미지만 사용


def detect_build_mode(preset_name: str) -> str:
    """
    빌드 모드 반환 (현재는 온라인 모드만 지원)
    
    Args:
        preset_name: 프리셋 이름
    
    Returns:
        항상 'online' 반환
    
    Note:
        오프라인 빌드는 deps_sync.sh 작업 완료 후 지원 예정
    """
    return "online"


def print_build_mode_info(build_mode: str, preset_name: str):
    """
    빌드 모드 정보 출력
    
    Args:
        build_mode: 빌드 모드
        preset_name: 프리셋 이름
    """
    print_section("Build Mode")
    print("🌐 Online Mode")
    print("  Downloading packages directly from internet")
    print("  ⚠️  Internet connection required for build")
    print("  ℹ️  Offline mode will be available after deps_sync.sh implementation")
    print("")


def check_and_switch_xaiva_branch(preset: dict, preset_name: str, non_interactive: bool = False, override_branch: str = None) -> bool:
    """
    Xaiva Media 브랜치 확인 및 전환
    
    Args:
        preset: 프리셋 데이터
        preset_name: 프리셋 이름
        non_interactive: 비대화형 모드 여부
        override_branch: CLI로 지정된 브랜치 (프리셋 설정 오버라이드)
    
    Returns:
        성공 여부
    """
    # Xaiva Media 소스 설정 확인
    build_options = preset.get("build_options", {})
    xaiva_source = build_options.get("xaiva_media_source", {})
    
    if not xaiva_source:
        print_warning("No xaiva_media_source configuration found in preset")
        return True
    
    # 브랜치 결정 (CLI 오버라이드 > 프리셋 설정 > 기본값)
    if override_branch:
        target_branch = override_branch
        print_info(f"Using CLI override branch: {target_branch}")
    else:
        target_branch = xaiva_source.get("branch", "main")
    
    source_path = xaiva_source.get("path", "xaiva-media")
    
    # 절대 경로와 상대 경로 처리
    if source_path.startswith("/"):
        # 절대 경로
        xaiva_path = Path(source_path)
    else:
        # 상대 경로 (프로젝트 루트 기준)
        xaiva_path = PROJECT_ROOT / source_path
    
    print_section(f"Xaiva Media Branch Check")
    print(f"  Source path: {xaiva_path}")
    print(f"  Target branch: {target_branch}")
    
    # 디렉터리 존재 확인
    if not xaiva_path.exists():
        print_error(f"Xaiva Media source not found: {xaiva_path}")
        print("Please ensure the Xaiva Media source is available at the specified path")
        return False
    
    # Git 저장소 확인
    git_dir = xaiva_path / ".git"
    if not git_dir.exists():
        print_error(f"Not a git repository: {xaiva_path}")
        print("Xaiva Media source must be a git repository for branch management")
        return False
    
    try:
        # 현재 브랜치 확인
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=xaiva_path,
            capture_output=True,
            text=True,
            check=True
        )
        current_branch = result.stdout.strip()
        
        print(f"  Current branch: {current_branch}")
        
        if current_branch == target_branch:
            print_success("✅ Already on target branch")
            return True
        
        # 브랜치 불일치 처리
        print_warning(f"Branch mismatch detected!")
        print(f"  Expected: {target_branch}")
        print(f"  Current:  {current_branch}")
        
        if non_interactive:
            print_error("Cannot switch branches in non-interactive mode")
            return False
        
        # 사용자 확인
        print("\nOptions:")
        print("  1. Switch to target branch (recommended)")
        print("  2. Continue with current branch")
        print("  3. Cancel build")
        
        while True:
            choice = input("\nSelect option (1-3) [1]: ").strip() or "1"
            
            if choice == "1":
                # 타겟 브랜치로 전환
                print(f"\nSwitching to branch '{target_branch}'...")
                
                # 원격 브랜치 확인
                subprocess.run(
                    ["git", "fetch", "origin"],
                    cwd=xaiva_path,
                    check=True
                )
                
                # 브랜치 전환
                switch_result = subprocess.run(
                    ["git", "checkout", target_branch],
                    cwd=xaiva_path,
                    capture_output=True,
                    text=True
                )
                
                if switch_result.returncode != 0:
                    print_error(f"Failed to switch to branch '{target_branch}'")
                    print(f"Git error: {switch_result.stderr}")
                    return False
                
                print_success(f"✅ Switched to branch: {target_branch}")
                
                # 최신 상태로 업데이트
                pull_result = subprocess.run(
                    ["git", "pull", "origin", target_branch],
                    cwd=xaiva_path,
                    capture_output=True,
                    text=True
                )
                
                if pull_result.returncode == 0:
                    print_success("✅ Updated to latest commit")
                else:
                    print_warning("Failed to pull latest changes, continuing with current state")
                
                return True
                
            elif choice == "2":
                # 현재 브랜치로 계속
                print_warning("⚠️  Continuing with current branch")
                print("Note: This may cause build inconsistencies")
                return True
                
            elif choice == "3":
                # 빌드 취소
                print("Build cancelled by user")
                return False
                
            else:
                print("Invalid choice. Please select 1, 2, or 3.")
    
    except subprocess.CalledProcessError as e:
        print_error(f"Git command failed: {e}")
        return False
    except Exception as e:
        print_error(f"Unexpected error during branch check: {e}")
        return False


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
      Interactive mode - prompts for preset
  
  python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1
      Build with specified preset
  
  python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1 --non-interactive
      Fully non-interactive build
  
  python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1 --xaiva-branch develop
      Build with specific Xaiva Media branch
  
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
    
    parser.add_argument(
        "--build-mode",
        type=str,
        choices=["online", "offline", "auto"],
        default="online",
        help="Build mode (currently only 'online' is supported, offline mode coming soon)"
    )
    
    parser.add_argument(
        "--xaiva-branch",
        type=str,
        help="Override Xaiva Media branch (overrides preset setting)"
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
    
    # Xaiva Media 브랜치 체크 및 전환
    if not check_and_switch_xaiva_branch(preset, preset_name, args.non_interactive, args.xaiva_branch):
        print_error("Xaiva Media branch check failed")
        sys.exit(1)
    
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
    
    
    # 빌드 모드 결정
    # 현재는 온라인 모드만 지원
    build_mode = "online"
    if args.build_mode in ["offline", "auto"]:
        print_warning(f"Build mode '{args.build_mode}' is not yet supported, using 'online' mode")
    
    # 빌드 모드 정보 출력
    if not args.non_interactive:
        print_build_mode_info(build_mode, preset_name)
    
    # 환경 변수 로드
    env_vars = load_env_file()
    
    # 빌드 확인
    image_tag = generate_image_tag(preset_name)
    
    if not args.non_interactive and not args.dry_run:
        if not confirm_build(preset_name, image_tag):
            print("Build cancelled")
            sys.exit(0)
    
    # 빌드 실행
    exit_code = build_docker_image(
        preset=preset,
        preset_name=preset_name,
        build_mode=build_mode,
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