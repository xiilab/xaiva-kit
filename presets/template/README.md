# Xaiva-Kit 프리셋 템플릿

새로운 프리셋을 생성하기 위한 템플릿 파일들입니다.

## 📁 파일 구성

- `preset-template.json` - 프리셋 설정 템플릿
- `requirements-base-template.txt` - 기본 Python 패키지 템플릿
- `requirements-template.txt` - 런타임 Python 패키지 템플릿
- `requirements-extra-template.txt` - 추가 패키지 템플릿 (선택적)
- `README.md` - 이 파일 (사용 가이드)

## 🚀 새 프리셋 생성 방법

### Step 1: 프리셋 이름 결정

프리셋 이름 형식: `<os>-<cuda>-<pytorch>`

**예시**:
- `ubuntu22.04-cuda11.8-torch2.1`
- `ubuntu20.04-cuda12.1-torch2.2`
- `ubuntu22.04-cuda12.4-torch2.3`

### Step 2: 프리셋 JSON 생성

```bash
# 1. 템플릿 복사
cp presets/template/preset-template.json presets/<preset-name>.json

# 예시:
cp presets/template/preset-template.json presets/ubuntu22.04-cuda12.1-torch2.2.json
```

**2. 파일 편집**:

```json
{
  "metadata": {
    "name": "ubuntu22.04-cuda12.1-torch2.2",  // 프리셋 이름 (파일명과 일치)
    "description": "CUDA 12.1, PyTorch 2.2.0, TensorRT 10.0.0"
  },
  "base_image": "nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04",  // CUDA 버전 맞춤
  "python": {
    "version": "3.10",           // Python 버전
    "version_without_dot": "310"
  },
  "pytorch": {
    "torch_version": "2.2.0+cu121",  // CUDA 버전과 일치해야 함
    "index_url": "https://download.pytorch.org/whl/torch_stable.html"
  },
  "tensorrt": {
    "version": "10.0.0"          // CUDA 12.x와 호환되는 TensorRT
  },
  "cuda": {
    "arch": "89"                 // GPU 아키텍처 (아래 표 참조)
  },
  "build_options": {
    "ffmpeg_version": "4.2",     // 필요 시 변경
    "opencv_version": "4.11.0",  // 필요 시 변경
    "xaiva_media_source": {
      "path": "xaiva-media",
      "branch": "main"           // 사용할 브랜치
    }
  }
}
```

### Step 3: Artifacts 디렉터리 생성

```bash
# 1. 디렉터리 구조 생성
mkdir -p artifacts/<preset-name>/{wheels,debs,sources}

# 예시:
mkdir -p artifacts/ubuntu22.04-cuda12.1-torch2.2/{wheels,debs,sources}
```

### Step 4: Requirements 파일 생성

```bash
# 1. requirements-base.txt 생성
cp presets/template/requirements-base-template.txt \
   artifacts/<preset-name>/requirements-base.txt

# 2. requirements.txt 생성
cp presets/template/requirements-template.txt \
   artifacts/<preset-name>/requirements.txt

# 3. requirements-extra.txt 생성 (선택적)
# 추가 패키지가 필요한 경우에만 생성
cp presets/template/requirements-extra-template.txt \
   artifacts/<preset-name>/requirements-extra.txt

# 예시:
cp presets/template/requirements-base-template.txt \
   artifacts/ubuntu22.04-cuda12.1-torch2.2/requirements-base.txt
cp presets/template/requirements-template.txt \
   artifacts/ubuntu22.04-cuda12.1-torch2.2/requirements.txt
cp presets/template/requirements-extra-template.txt \
   artifacts/ubuntu22.04-cuda12.1-torch2.2/requirements-extra.txt
```

#### Requirements 파일 역할 구분

- **requirements-base.txt**: 핵심 의존성 패키지
  - 빌드 초기에 설치
  - NumPy, SciPy, Matplotlib, scikit-learn 등
  
- **requirements.txt**: 런타임 필수 패키지
  - 빌드 중간에 설치
  - PyTorch, TorchVision, 애플리케이션 의존성 등
  
- **requirements-extra.txt**: 추가 선택적 패키지 (선택적)
  - 빌드 마지막에 설치
  - ONNX, TensorRT 유틸리티, 디버깅 도구, 프로파일링 도구 등
  - 파일이 존재하면 자동으로 설치 시도
  - 설치 실패해도 빌드는 계속 진행

### Step 5: Requirements 파일 커스터마이징

#### requirements-base.txt 수정

```bash
vim artifacts/<preset-name>/requirements-base.txt
```

**주요 수정 사항**:

```txt
# 1. NumPy 버전 조정 (PyTorch 호환성 확인)
numpy==1.26.0  # PyTorch 2.2.x와 호환

# 2. SciPy 버전 조정
scipy==1.12.0

# 3. 프로젝트 특화 패키지 추가
albumentations  # 필요한 경우
tensorboard     # 필요한 경우
```

#### requirements.txt 수정

```bash
vim artifacts/<preset-name>/requirements.txt
```

**주요 수정 사항**:

```txt
# NumPy/SciPy 버전 수정 (PyTorch 호환성 확인)
numpy==1.26.0
scipy==1.12.0

# 주의: PyTorch는 Dockerfile에서 설치됨 (프리셋 JSON에서 버전 관리)
# torch, torchvision, torchaudio는 여기에 포함하지 않음

# 런타임 전용 패키지 추가 (필요 시)
# fastapi
# uvicorn
```

**중요**: PyTorch 버전은 프리셋 JSON 파일의 `pytorch` 섹션에서 관리합니다.

#### requirements-extra.txt 수정 (선택적)

```bash
vim artifacts/<preset-name>/requirements-extra.txt
```

**사용 예시**:

```txt
# ONNX 지원 (모델 변환 등)
onnx==1.18.0
onnxruntime==1.22.0
protobuf==6.31.1
flatbuffers==25.2.10

# 시스템 모니터링 및 디버깅
psutil==7.0.0
coloredlogs==15.0.1
humanfriendly==10.0

# 모델 프로파일링
thop==0.1.1.post2209072238

# TensorBoard 확장
# tensorboard-plugin-profile

# 기타 디버깅 도구
# py-spy
# memory-profiler
```

**참고**: 이 파일의 패키지들은 설치 실패 시에도 빌드가 계속 진행됩니다.

### Step 6: 의존성 다운로드 (선택사항, 오프라인 빌드용)

```bash
# 오프라인 빌드를 위한 의존성 다운로드
./scripts/deps_sync.sh <preset-name>

# 예시:
./scripts/deps_sync.sh ubuntu22.04-cuda12.1-torch2.2
```

**참고**: 온라인 빌드만 수행하는 경우 이 단계는 생략 가능합니다.

### Step 7: 빌드 테스트

```bash
# 1. Dry-run으로 설정 검증
python3 scripts/build.py --preset <preset-name> --dry-run

# 2. 실제 빌드
python3 scripts/build.py --preset <preset-name>

# 예시:
python3 scripts/build.py --preset ubuntu22.04-cuda12.1-torch2.2 --dry-run
python3 scripts/build.py --preset ubuntu22.04-cuda12.1-torch2.2
```

---

## 📋 CUDA/PyTorch 버전별 설정 가이드

### CUDA 11.8 + PyTorch 2.1 (RTX 30 시리즈)

**프리셋 JSON**:
```json
{
  "base_image": "nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04",
  "pytorch": {
    "torch_version": "2.1.0",
    "torchvision_version": "0.16.0",
    "torchaudio_version": "2.1.0",
    "index_url": "https://download.pytorch.org/whl/cu118"
  },
  "tensorrt": {
    "version": "8.6.1"
  },
  "cuda": {
    "arch": "86"
  }
}
```

**requirements.txt**:
```txt
numpy==1.23.1
scipy==1.11.4

# PyTorch는 Dockerfile에서 설치됨 (프리셋 JSON 참조)
# 버전에서 +cu118 접미사는 제거 (index_url에서 CUDA 버전 관리)
```

### CUDA 12.1 + PyTorch 2.2 (RTX 40 시리즈)

**프리셋 JSON**:
```json
{
  "base_image": "nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04",
  "pytorch": {
    "torch_version": "2.2.0",
    "torchvision_version": "0.17.0",
    "torchaudio_version": "2.2.0",
    "index_url": "https://download.pytorch.org/whl/cu121"
  },
  "tensorrt": {
    "version": "10.0.0"
  },
  "cuda": {
    "arch": "89"
  }
}
```

**requirements.txt**:
```txt
numpy==1.26.0
scipy==1.12.0

# PyTorch는 Dockerfile에서 설치됨 (프리셋 JSON 참조)
# 버전에서 +cu121 접미사는 제거 (index_url에서 CUDA 버전 관리)
```

### CUDA 12.4 + PyTorch 2.3 (최신)

**프리셋 JSON**:
```json
{
  "base_image": "nvidia/cuda:12.4.0-cudnn8-devel-ubuntu22.04",
  "pytorch": {
    "torch_version": "2.3.0",
    "torchvision_version": "0.18.0",
    "torchaudio_version": "2.3.0",
    "index_url": "https://download.pytorch.org/whl/cu124"
  },
  "tensorrt": {
    "version": "10.0.0"
  },
  "cuda": {
    "arch": "89"
  }
}
```

**requirements.txt**:
```txt
numpy==1.26.0
scipy==1.12.0

# PyTorch는 Dockerfile에서 설치됨 (프리셋 JSON 참조)
# 버전에서 +cu124 접미사는 제거 (index_url에서 CUDA 버전 관리)
```

---

## 🎯 GPU 아키텍처 코드 (cuda.arch)

| GPU 시리즈 | 아키텍처 | cuda.arch | 예시 |
|-----------|---------|-----------|------|
| GTX 10 시리즈 | Pascal | 61 | GTX 1080 Ti |
| RTX 20 시리즈 | Turing | 75 | RTX 2080 Ti |
| RTX 30 시리즈 | Ampere | 86 | RTX 3090 |
| RTX 40 시리즈 | Ada Lovelace | 89 | RTX 4090 |
| A100 | Ampere | 80 | A100 80GB |
| H100 | Hopper | 90 | H100 80GB |
| L4/L40 | Ada Lovelace | 89 | L4, L40S |

**참고**: `cuda.arch`는 CUDA의 Compute Capability를 나타냅니다. 자세한 정보는 [NVIDIA GPU Compute Capability](https://developer.nvidia.com/cuda-gpus)를 참조하세요.

---

## 🔄 버전 호환성 매트릭스

### PyTorch vs NumPy

| PyTorch | NumPy | 호환성 |
|---------|-------|--------|
| 2.1.x | 1.23.x | ✅ 권장 |
| 2.1.x | 1.24.x | ✅ 호환 |
| 2.2.x+ | 1.26.x | ✅ 권장 |

### CUDA vs TensorRT

| CUDA | TensorRT | 호환성 |
|------|----------|--------|
| 11.8 | 8.6.x | ✅ 권장 |
| 12.1 | 10.0.0+ | ✅ 권장 |
| 12.4 | 10.0.0+ | ✅ 권장 |

### Python vs PyTorch

| Python | PyTorch | 호환성 |
|--------|---------|--------|
| 3.8 | 2.1.x | ✅ 호환 |
| 3.10 | 2.1.x ~ 2.3.x | ✅ 권장 |
| 3.11 | 2.2.x+ | ✅ 권장 |

---

## ⚠️ 주의사항

### 1. 버전 호환성 확인

- ✅ **PyTorch와 CUDA 버전 일치 필수**
  - 예: `torch==2.1.0+cu118`는 CUDA 11.8용
  - 예: `torch==2.2.0+cu121`는 CUDA 12.1용

- ✅ **NumPy 버전은 PyTorch 호환성 확인**
  - PyTorch 2.1.x: NumPy 1.23.x 권장
  - PyTorch 2.2.x+: NumPy 1.26.x 권장

- ✅ **TensorRT와 CUDA 버전 호환성 확인**
  - CUDA 11.x: TensorRT 8.6.x
  - CUDA 12.x: TensorRT 10.0.0+

### 2. 중복 방지

- ❌ **requirements-base.txt, requirements.txt, requirements-extra.txt에 동일 패키지 중복 정의 금지**
- ✅ **PyTorch는 requirements.txt에만 정의**
- ✅ **기본 패키지는 requirements-base.txt에만 정의**
- ✅ **선택적/추가 패키지는 requirements-extra.txt에만 정의**

### 3. 오프라인 빌드

- `deps_sync.sh` 실행으로 wheels 사전 다운로드
- 베이스 이미지는 별도 처리 필요 (`docker save` 사용)
- 완전 오프라인 빌드는 추가 작업 필요 (CP-005 참조)

### 4. 프리셋 네이밍

- 파일명과 `metadata.name` 일치해야 함
- 형식: `<os>-<cuda>-<pytorch>`
- 소문자와 숫자, 하이픈(-), 점(.)만 사용

---

## ✅ 체크리스트

### 프리셋 생성 완료 체크리스트

- [ ] 프리셋 이름 결정 (`<os>-<cuda>-<pytorch>`)
- [ ] `presets/<preset-name>.json` 생성 및 편집
- [ ] `artifacts/<preset-name>/` 디렉터리 생성
- [ ] `requirements-base.txt` 생성 및 커스터마이징
- [ ] `requirements.txt` 생성 및 커스터마이징
- [ ] `requirements-extra.txt` 생성 및 커스터마이징 (필요 시)
- [ ] 세 파일 간 패키지 중복 없음 확인
- [ ] PyTorch 버전과 CUDA 버전 일치 확인
- [ ] NumPy 버전과 PyTorch 호환성 확인
- [ ] TensorRT 버전과 CUDA 호환성 확인
- [ ] GPU 아키텍처 코드 올바르게 설정
- [ ] Dry-run 테스트 성공 (`--dry-run`)
- [ ] 실제 빌드 테스트 성공

### 빌드 전 검증 체크리스트

- [ ] JSON 문법 오류 없음
- [ ] `metadata.name`이 파일명과 일치
- [ ] CUDA 버전과 TensorRT 버전 호환
- [ ] PyTorch CUDA 접미사가 CUDA 버전과 일치 (예: `+cu118`)
- [ ] artifacts 디렉터리 존재
- [ ] requirements.txt 파일 존재

---

## 🔗 참고 자료

### 공식 문서
- [PyTorch 버전 확인](https://pytorch.org/get-started/previous-versions/)
- [NVIDIA CUDA 이미지](https://hub.docker.com/r/nvidia/cuda)
- [TensorRT 다운로드](https://developer.nvidia.com/tensorrt)
- [NVIDIA GPU Compute Capability](https://developer.nvidia.com/cuda-gpus)

### 프로젝트 문서
- [프리셋 스키마](../../docs/preset-schema.md) - 프리셋 JSON 상세 스키마
- [빌드 가이드](../../docs/build-guide.md) - 빌드 프로세스 전체 가이드
- [변경 계획](../../docs/CHANGE_PLAN.md) - 프로젝트 변경 이력

### 도움말
- 문제 발생 시: [build-guide.md - 문제 해결](../../docs/build-guide.md#문제-해결) 섹션 참조
- 추가 질문: 팀 채널에 문의

---

## 💡 팁

### 빠른 프리셋 생성 스크립트

다음 스크립트를 사용하면 더 빠르게 프리셋을 생성할 수 있습니다:

```bash
#!/bin/bash
# create-preset.sh

PRESET_NAME=$1

if [ -z "$PRESET_NAME" ]; then
    echo "Usage: $0 <preset-name>"
    echo "Example: $0 ubuntu22.04-cuda12.1-torch2.2"
    exit 1
fi

echo "Creating preset: $PRESET_NAME"

# 1. 프리셋 JSON 복사
cp presets/template/preset-template.json presets/${PRESET_NAME}.json

# 2. Artifacts 디렉터리 생성
mkdir -p artifacts/${PRESET_NAME}/{wheels,debs,sources}

# 3. Requirements 파일 복사
cp presets/template/requirements-base-template.txt \
   artifacts/${PRESET_NAME}/requirements-base.txt
cp presets/template/requirements-template.txt \
   artifacts/${PRESET_NAME}/requirements.txt

echo "✅ Preset template created: $PRESET_NAME"
echo ""
echo "Next steps:"
echo "  1. Edit presets/${PRESET_NAME}.json"
echo "  2. Edit artifacts/${PRESET_NAME}/requirements-base.txt"
echo "  3. Edit artifacts/${PRESET_NAME}/requirements.txt"
echo "  4. (Optional) Create artifacts/${PRESET_NAME}/requirements-extra.txt for additional packages"
echo "  5. Run: python3 scripts/build.py --preset ${PRESET_NAME} --dry-run"
```

**사용 방법**:
```bash
chmod +x create-preset.sh
./create-preset.sh ubuntu22.04-cuda12.1-torch2.2
```

---

**작성일**: 2025-11-21  
**버전**: 1.0  
**관리**: xaiva-kit 프로젝트

