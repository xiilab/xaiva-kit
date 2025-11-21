"""
Docker 빌드 모듈

Docker 이미지 빌드 관련 기능을 제공합니다.
"""

import subprocess
from pathlib import Path
from typing import Dict, Any

from .utils import print_section, print_error, print_success


# 프로젝트 경로 설정
PROJECT_ROOT = Path(__file__).parent.parent.parent
DOCKERFILE_PATH = PROJECT_ROOT / "docker" / "Dockerfile"


def generate_image_tag(preset_name: str) -> str:
    """
    Docker 이미지 태그를 생성합니다.
    
    Args:
        preset_name: 프리셋 이름
    
    Returns:
        이미지 태그
    """
    return f"xaiva-kit:{preset_name}"


def build_docker_image(
    preset: Dict[str, Any],
    preset_name: str,
    build_mode: str,
    env_vars: Dict[str, str],
    dry_run: bool = False
) -> int:
    """
    Docker 이미지를 빌드합니다.
    
    Args:
        preset: 프리셋 데이터
        preset_name: 프리셋 이름
        build_mode: 빌드 모드 (online/offline/auto)
        env_vars: 환경 변수
        dry_run: True일 경우 명령어만 출력하고 실행하지 않음
    
    Returns:
        Exit code (0 = success)
    """
    image_tag = generate_image_tag(preset_name)
    
    # Build arguments 준비
    build_args = {
        "BASE_IMAGE": preset["base_image"],
        "PRESET_NAME": preset_name,
        "BUILD_MODE": build_mode,
        "PYTHON_VERSION": preset["python"]["version"],
        "PYTHON_VERSION_WITHOUT_DOT": preset["python"]["version_without_dot"],
        "CUDA_ARCH": preset["cuda"]["arch"],
    }
    
    # PyTorch 버전 관리
    if "pytorch" in preset:
        pytorch = preset["pytorch"]
        if "torch_version" in pytorch:
            build_args["PYTORCH_VERSION"] = pytorch["torch_version"]
        if "index_url" in pytorch:
            build_args["PYTORCH_INDEX_URL"] = pytorch["index_url"]
    
    # TensorRT 버전 관리
    if "tensorrt" in preset and preset["tensorrt"].get("enabled"):
        tensorrt = preset["tensorrt"]
        if "version" in tensorrt:
            build_args["TENSORRT_VERSION"] = tensorrt["version"]
    
    # Build options에서 FFmpeg, OpenCV 버전 추가
    if "build_options" in preset:
        build_options = preset["build_options"]
        
        if "ffmpeg_version" in build_options:
            build_args["FFMPEG_VERSION"] = build_options["ffmpeg_version"]
        
        if "opencv_version" in build_options:
            build_args["OPENCV_VERSION"] = build_options["opencv_version"]
        
        # Xaiva Media 소스 경로
        if "xaiva_media_source" in build_options:
            xaiva_source = build_options["xaiva_media_source"]
            if "path" in xaiva_source:
                build_args["XAIVA_SOURCE_PATH"] = xaiva_source["path"]
    
    # .env에서 추가 build args (필요시 - 환경변수가 우선)
    if "XAIVA_MEDIA_SOURCE_PATH" in env_vars:
        build_args["XAIVA_SOURCE_PATH"] = env_vars["XAIVA_MEDIA_SOURCE_PATH"]
    
    # Docker build 명령어 생성 (항상 dev 타겟 사용)
    cmd = [
        "docker", "build",
        "-f", str(DOCKERFILE_PATH),
        "-t", image_tag,
        "--target", "dev",
    ]
    
    # Build arguments 추가
    for key, value in build_args.items():
        cmd.extend(["--build-arg", f"{key}={value}"])
    
    # Build context는 프로젝트 루트
    cmd.append(str(PROJECT_ROOT))
    
    # 명령어 출력
    print_section("Docker Build Command")
    print("  " + " ".join(cmd))
    
    if dry_run:
        print_success("Dry run mode - command not executed")
        return 0
    
    # 실행
    print_section("Building Docker Image")
    print(f"  This may take a while...")
    print()
    
    try:
        result = subprocess.run(cmd, cwd=PROJECT_ROOT)
        return result.returncode
    
    except KeyboardInterrupt:
        print("\n\nBuild cancelled by user")
        return 130
    
    except Exception as e:
        print_error(f"Failed to run docker build: {e}")
        return 1