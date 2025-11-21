"""
프리셋 관리 모듈

프리셋 JSON 파일의 로딩, 검증, 아티팩트 확인 기능을 제공합니다.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Any

from .utils import print_error, print_warning


# 프로젝트 경로 설정
PROJECT_ROOT = Path(__file__).parent.parent.parent
PRESETS_DIR = PROJECT_ROOT / "presets"
ARTIFACTS_DIR = PROJECT_ROOT / "artifacts"


def load_presets() -> Dict[str, Dict[str, Any]]:
    """
    presets/ 디렉터리에서 모든 프리셋 JSON 파일을 로드합니다.
    
    Returns:
        프리셋 이름을 키로 하는 딕셔너리
    """
    if not PRESETS_DIR.exists():
        print_error(f"Presets directory not found: {PRESETS_DIR}")
        sys.exit(1)
    
    presets = {}
    
    for preset_file in PRESETS_DIR.glob("*.json"):
        try:
            with open(preset_file, 'r', encoding='utf-8') as f:
                preset_data = json.load(f)
                preset_name = preset_data.get("metadata", {}).get("name")
                
                if not preset_name:
                    print_warning(f"Preset {preset_file.name} has no metadata.name field, skipping")
                    continue
                
                presets[preset_name] = preset_data
                
        except json.JSONDecodeError as e:
            print_warning(f"Failed to parse {preset_file.name}: {e}")
        except Exception as e:
            print_warning(f"Failed to load {preset_file.name}: {e}")
    
    return presets


def validate_preset(preset: Dict[str, Any]) -> List[str]:
    """
    프리셋 데이터의 유효성을 검증합니다.
    
    Args:
        preset: 검증할 프리셋 데이터
    
    Returns:
        에러 메시지 리스트 (빈 리스트면 유효함)
    """
    errors = []
    
    # 필수 필드 체크
    required_fields = [
        ("metadata", dict),
        ("base_image", str),
        ("python", dict),
        ("pytorch", dict),
        ("tensorrt", dict),
        ("cuda", dict),
        ("build_options", dict),
        ("system_packages", list),
        ("environment", dict),
    ]
    
    for field, expected_type in required_fields:
        if field not in preset:
            errors.append(f"Missing required field: {field}")
        elif not isinstance(preset[field], expected_type):
            errors.append(f"Field {field} must be {expected_type.__name__}")
    
    # TensorRT-CUDA 호환성 체크
    if "tensorrt" in preset and "cuda" in preset:
        tensorrt = preset["tensorrt"]
        cuda_version = preset["cuda"].get("version", "")
        
        if tensorrt.get("enabled") and tensorrt.get("required_in_runtime"):
            compatibility = tensorrt.get("cuda_compatibility", {})
            tensorrt_version = tensorrt.get("version", "")
            
            if tensorrt_version in compatibility:
                expected_cuda = compatibility[tensorrt_version]
                if not cuda_version.startswith(expected_cuda):
                    errors.append(
                        f"TensorRT {tensorrt_version} requires CUDA {expected_cuda}, "
                        f"but preset uses CUDA {cuda_version}"
                    )
    
    return errors


def check_preset_artifacts(preset_name: str) -> List[str]:
    """
    프리셋에 필요한 artifacts가 있는지 확인합니다.
    
    Args:
        preset_name: 프리셋 이름
    
    Returns:
        경고 메시지 리스트
    """
    warnings = []
    preset_dir = ARTIFACTS_DIR / preset_name
    
    if not preset_dir.exists():
        warnings.append(f"Artifacts directory not found: {preset_dir}")
        return warnings
    
    # 필수 파일/디렉터리 체크
    required_items = [
        ("wheels", True),   # (이름, 디렉터리 여부)
        ("sources", True),
        ("requirements.txt", False),
    ]
    
    for item_name, is_dir in required_items:
        item_path = preset_dir / item_name
        
        if not item_path.exists():
            warnings.append(f"Missing: {item_path}")
        elif is_dir and not item_path.is_dir():
            warnings.append(f"Not a directory: {item_path}")
        elif not is_dir and not item_path.is_file():
            warnings.append(f"Not a file: {item_path}")
    
    return warnings