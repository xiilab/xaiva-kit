# 프리셋 JSON 스키마

## 개요

프리셋 JSON 파일은 Docker 이미지 빌드에 필요한 모든 설정을 정의합니다. 이 문서는 프리셋 JSON의 스키마와 각 필드의 의미를 설명합니다.

## 파일 위치 및 명명 규칙

- **위치**: `presets/<preset-name>.json`
- **명명 규칙**: `<os-version>-<cuda-version>-<framework-version>.json`
  - 예: `ubuntu22.04-cuda11.8-torch2.1.json`
  - 예: `ubuntu22.04-cuda12.1-torch2.3.json`

## 스키마 구조

### 전체 구조

```json
{
  "metadata": { ... },
  "base_image": "...",
  "python": { ... },
  "pytorch": { ... },
  "tensorrt": { ... },
  "cuda": { ... },
  "build_options": { ... },
  "system_packages": [ ... ],
  "environment": { ... }
}
```

---

## 필드 상세 설명

### 1. metadata (필수)

프리셋의 메타데이터 정보

```json
{
  "metadata": {
    "name": "ubuntu22.04-cuda11.8-torch2.1",
    "description": "Production Environment - CUDA 11.8, PyTorch 2.1.0, TensorRT 8.6.1",
    "created": "2025-11-20",
    "target_gpu": "NVIDIA RTX 30xx series (Ampere, Arch 86)"
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `name` | string | ✅ | 프리셋 이름 (파일명과 일치해야 함) |
| `description` | string | ✅ | 프리셋 설명 |
| `created` | string | ✅ | 생성 날짜 (YYYY-MM-DD) |
| `target_gpu` | string | ⚠️ | 타겟 GPU 정보 (선택) |

---

### 2. base_image (필수)

Docker 베이스 이미지

```json
{
  "base_image": "nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `base_image` | string | ✅ | NVIDIA CUDA 공식 이미지 태그 |

**권장 이미지:**
- `nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04`
- `nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04`

---

### 3. python (필수)

Python 버전 설정

```json
{
  "python": {
    "version": "3.10",
    "version_without_dot": "310"
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `version` | string | ✅ | Python 버전 (예: "3.10", "3.11") |
| `version_without_dot` | string | ✅ | 점 제거 버전 (예: "310", "311") |

**지원 버전:** Python 3.9, 3.10, 3.11

---

### 4. pytorch (필수)

PyTorch 및 관련 라이브러리 설정

```json
{
  "pytorch": {
    "version": "2.1.0+cu118",
    "torch_version": "2.1.0+cu118",
    "torchvision_version": "0.16.0+cu118",
    "torchaudio_version": "2.1.0+cu118",
    "index_url": "https://download.pytorch.org/whl/torch_stable.html"
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `version` | string | ✅ | PyTorch 메인 버전 |
| `torch_version` | string | ✅ | torch 패키지 버전 |
| `torchvision_version` | string | ✅ | torchvision 패키지 버전 |
| `torchaudio_version` | string | ✅ | torchaudio 패키지 버전 |
| `index_url` | string | ✅ | PyTorch wheel 인덱스 URL |

**버전 명명 규칙:**
- `+cu118`: CUDA 11.8용
- `+cu121`: CUDA 12.1용

---

### 5. tensorrt (필수)

TensorRT 설정

```json
{
  "tensorrt": {
    "enabled": true,
    "version": "8.6.1",
    "required_in_runtime": true,
    "supported_versions": ["8.6.1", "10.x"],
    "cuda_compatibility": {
      "8.6.1": "11.8",
      "10.x": "12.x"
    },
    "description": "TensorRT is required in runtime for inference acceleration. Version 8.x supports CUDA 11.8, Version 10.x supports CUDA 12.x"
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `enabled` | boolean | ✅ | TensorRT 사용 여부 |
| `version` | string | ✅ | 사용할 TensorRT 버전 |
| `required_in_runtime` | boolean | ✅ | 런타임 이미지에 포함 여부 |
| `supported_versions` | array | ✅ | 지원하는 버전 목록 |
| `cuda_compatibility` | object | ✅ | CUDA 버전별 호환성 매핑 |
| `description` | string | ⚠️ | 상세 설명 (선택) |

**⚠️ 중요:**
- TensorRT는 런타임 이미지에 필수 포함
- CUDA 버전과 TensorRT 버전이 호환되어야 함

**호환성:**
- TensorRT 8.x → CUDA 11.8
- TensorRT 10.x → CUDA 12.x

---

### 6. cuda (필수)

CUDA 상세 정보

```json
{
  "cuda": {
    "version": "11.8",
    "arch": "86",
    "arch_name": "ampere"
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `version` | string | ✅ | CUDA 버전 |
| `arch` | string | ✅ | CUDA Compute Capability (예: "86", "89") |
| `arch_name` | string | ⚠️ | 아키텍처 이름 (예: "ampere", "ada") |

**CUDA Compute Capability 참고:**
- `86`: RTX 30xx (Ampere)
- `89`: RTX 40xx (Ada Lovelace)
- `75`: RTX 20xx (Turing)

---

### 7. build_options (필수)

빌드 옵션 설정

```json
{
  "build_options": {
    "ffmpeg_version": "4.2",
    "opencv_version": "4.9.0",
    "build_opencv_from_source": false,
    "opencv_cuda_enabled": false,
    "xaiva_media_source": {
      "type": "external",
      "path": "/path/to/xaiva-media",
      "branch": "master"
    }
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `ffmpeg_version` | string | ✅ | FFmpeg 버전 (예: "4.2", "5.1") |
| `opencv_version` | string | ✅ | OpenCV 버전 (예: "4.9.0") |
| `build_opencv_from_source` | boolean | ✅ | OpenCV 소스 빌드 여부 |
| `opencv_cuda_enabled` | boolean | ✅ | OpenCV CUDA 모듈 활성화 여부 |
| `xaiva_media_source` | object | ✅ | Xaiva Media 소스 설정 |

#### xaiva_media_source 하위 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `type` | string | ✅ | 소스 타입 ("external", "subtree", "context") |
| `path` | string | ✅ | 소스 경로 |
| `branch` | string | ⚠️ | Git 브랜치 (선택) |

---

### 8. system_packages (필수)

APT 시스템 패키지 목록

```json
{
  "system_packages": [
    "build-essential",
    "cmake",
    "git",
    "python3-pip",
    "..."
  ]
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `system_packages` | array | ✅ | 설치할 APT 패키지 목록 |

**필수 패키지 카테고리:**
- 빌드 도구: `build-essential`, `cmake`, `git`
- 멀티미디어: FFmpeg 빌드용 라이브러리
- Python: `python3-pip`, `python3-dev`
- 기타: `wget`, `curl`, `vim` 등

---

### 9. environment (필수)

환경 변수 설정

```json
{
  "environment": {
    "TZ": "Asia/Seoul",
    "LC_ALL": "C.UTF-8",
    "LD_LIBRARY_PATH": "/usr/local/xaiva_media/lib:/usr/include:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/include",
    "NVIDIA_VISIBLE_DEVICES": "all",
    "NVIDIA_DRIVER_CAPABILITIES": "video,compute,utility"
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `TZ` | string | ✅ | 시간대 |
| `LC_ALL` | string | ✅ | 로케일 설정 |
| `LD_LIBRARY_PATH` | string | ✅ | 라이브러리 경로 |
| `NVIDIA_VISIBLE_DEVICES` | string | ✅ | NVIDIA GPU 가시성 |
| `NVIDIA_DRIVER_CAPABILITIES` | string | ✅ | NVIDIA 드라이버 기능 |

**LD_LIBRARY_PATH 필수 경로:**
- `/usr/local/lib`: 표준 사용자 설치 라이브러리
- `/usr/local/cuda/lib64`: CUDA 라이브러리
- `/usr/local/cuda/extras/CUPTI/lib64`: CUDA Profiling Tools
- TensorRT 라이브러리 경로 (버전별 상이)

---

## 프리셋 생성 가이드

### 1. 새 프리셋 생성 절차

1. **기존 프리셋 복사**
   ```bash
   cp presets/ubuntu22.04-cuda11.8-torch2.1.json \
      presets/ubuntu22.04-cuda12.1-torch2.3.json
   ```

2. **필수 필드 수정**
   - `metadata.name`: 파일명과 일치시키기
   - `base_image`: CUDA 버전에 맞는 이미지
   - `pytorch`: PyTorch 버전 및 CUDA 접미사 변경
   - `tensorrt`: CUDA 호환 버전 선택
   - `cuda.version`: CUDA 버전 업데이트

3. **artifacts 디렉터리 생성**
   ```bash
   mkdir -p artifacts/ubuntu22.04-cuda12.1-torch2.3/{wheels,debs,sources}
   ```

4. **requirements.txt 작성**
   ```bash
   cp artifacts/ubuntu22.04-cuda11.8-torch2.1/requirements.txt \
      artifacts/ubuntu22.04-cuda12.1-torch2.3/requirements.txt
   # 버전 정보 수정
   ```

### 2. 검증 체크리스트

- [ ] JSON 문법 오류 없음
- [ ] `metadata.name`이 파일명과 일치
- [ ] CUDA 버전과 TensorRT 버전 호환
- [ ] PyTorch CUDA 접미사가 CUDA 버전과 일치
- [ ] artifacts 디렉터리 존재
- [ ] requirements.txt 파일 존재

---

## 예제

### 완전한 프리셋 예제

```json
{
  "metadata": {
    "name": "ubuntu22.04-cuda11.8-torch2.1",
    "description": "Production Environment - CUDA 11.8, PyTorch 2.1.0",
    "created": "2025-11-20",
    "target_gpu": "NVIDIA RTX 30xx series (Ampere)"
  },
  "base_image": "nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04",
  "python": {
    "version": "3.10",
    "version_without_dot": "310"
  },
  "pytorch": {
    "version": "2.1.0+cu118",
    "torch_version": "2.1.0+cu118",
    "torchvision_version": "0.16.0+cu118",
    "torchaudio_version": "2.1.0+cu118",
    "index_url": "https://download.pytorch.org/whl/torch_stable.html"
  },
  "tensorrt": {
    "enabled": true,
    "version": "8.6.1",
    "required_in_runtime": true,
    "supported_versions": ["8.6.1"],
    "cuda_compatibility": {
      "8.6.1": "11.8"
    },
    "description": "TensorRT for inference acceleration"
  },
  "cuda": {
    "version": "11.8",
    "arch": "86",
    "arch_name": "ampere"
  },
  "build_options": {
    "ffmpeg_version": "4.2",
    "opencv_version": "4.9.0",
    "build_opencv_from_source": false,
    "opencv_cuda_enabled": false,
    "xaiva_media_source": {
      "type": "external",
      "path": "/path/to/xaiva-media",
      "branch": "master"
    }
  },
  "system_packages": [
    "build-essential",
    "cmake",
    "git"
  ],
  "environment": {
    "TZ": "Asia/Seoul",
    "LC_ALL": "C.UTF-8",
    "LD_LIBRARY_PATH": "/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64",
    "NVIDIA_VISIBLE_DEVICES": "all",
    "NVIDIA_DRIVER_CAPABILITIES": "video,compute,utility"
  }
}
```

---

## 참고 자료

- [PyTorch 버전 호환성](https://pytorch.org/get-started/previous-versions/)
- [TensorRT 릴리스 노트](https://docs.nvidia.com/deeplearning/tensorrt/release-notes/)
- [CUDA Compute Capability](https://developer.nvidia.com/cuda-gpus)

