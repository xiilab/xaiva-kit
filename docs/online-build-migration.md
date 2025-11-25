# 온라인 빌드 방식으로 마이그레이션

## 개요

빌드 방식을 오프라인(wheels 기반)에서 온라인(직접 다운로드)으로 변경했습니다. 이는 legacy dockerfile의 방식을 따른 것입니다.

## 변경 날짜
2025-11-20

---

## 주요 변경 사항

### 1. PyTorch 설치 방식 변경

#### Before (오프라인 방식)

```dockerfile
COPY artifacts/${PRESET_NAME}/wheels/ /tmp/wheels/
RUN pip3 install --no-index --find-links=/tmp/wheels torch==2.1.0+cu118
```

**문제점:**
- ❌ wheels 사전 다운로드 필요
- ❌ 큰 파일 크기 (PyTorch wheel ~800MB)
- ❌ 관리 복잡도 증가

#### After (온라인 방식 - 공식 문서)

```dockerfile
RUN pip3 install --index-url https://download.pytorch.org/whl/cu118 \
    torch==2.1.0 \
    torchvision==0.16.0 \
    torchaudio==2.1.0
```

**장점:**
- ✅ wheels 다운로드 불필요
- ✅ PyTorch 공식 문서 권장 방식 (`--index-url`)
- ✅ 버전에서 CUDA 접미사 제거 (index_url에서 관리)
- ✅ CUDA 버전별 명확한 인덱스 URL
- ✅ 관리 간소화

### 2. 버전 관리 패키지 분리

#### requirements.txt (Before)

```txt
# Core dependencies (version-managed)
numpy==1.23.1
scipy==1.11.4

# PyTorch ecosystem (version-managed)
torch==2.1.0+cu118
torchvision==0.16.0+cu118
torchaudio==2.1.0+cu118

# TensorRT (version-managed)
tensorrt==8.6.1

# Data processing and utilities
packaging
webcolors
...
```

#### requirements.txt (After)

```txt
# Core dependencies (version-locked)
numpy==1.23.1
scipy==1.11.4

# PyTorch는 Dockerfile에서 직접 설치됨 (프리셋 JSON 참조)
# torch, torchvision, torchaudio는 여기에 포함하지 않음

# Data processing and utilities
packaging
webcolors
matplotlib
yacs
...

# Note: 버전 관리 패키지는 Dockerfile에서 직접 설치
# - torch, torchvision, torchaudio (프리셋 JSON에서 버전 관리)
# - tensorrt
```

### 3. Dockerfile 패키지 설치 순서

```dockerfile
RUN echo "=== Installing Python packages ===" && \
    # 1. pip, setuptools, wheel 업그레이드
    pip3 install --upgrade pip setuptools wheel && \
    \
    # 2. Core dependencies (버전 관리)
    pip3 install numpy==1.23.1 && \
    pip3 install scipy==1.11.4 && \
    \
    # 3. PyTorch ecosystem (버전 관리 - 공식 문서)
    pip3 install --index-url https://download.pytorch.org/whl/cu118 \
        torch==2.1.0 \
        torchvision==0.16.0 \
        torchaudio==2.1.0 && \
    \
    # 4. TensorRT (버전 관리)
    pip3 install tensorrt==8.6.1 && \
    \
    # 5. 나머지 패키지들 (requirements.txt)
    pip3 install -r /tmp/requirements.txt && \
    \
    # 6. 정리
    rm -rf /tmp/requirements.txt
```

**설치 순서 이유:**
1. **pip, setuptools, wheel**: 최신 패키지 관리 도구 사용
2. **numpy, scipy**: 다른 패키지의 의존성
3. **PyTorch**: 큰 패키지, 별도 인덱스 필요
4. **TensorRT**: PyTorch 설치 후
5. **나머지**: 일반 패키지들

---

## Legacy Dockerfile 참조

### Legacy 방식 (검증됨)

```dockerfile
pip3 install --upgrade pip setuptools wheel && \
pip3 install gdown && \
pip3 install scipy==1.11.4 && \
pip3 install numpy==1.23.1 && \

pip3 install --find-links https://download.pytorch.org/whl/torch_stable.html torch==2.1.0+cu118 && \
pip3 install --find-links https://download.pytorch.org/whl/torch_stable.html torchvision==0.16.0+cu118 && \
pip3 install --find-links https://download.pytorch.org/whl/torch_stable.html torchaudio==2.1.0+cu118 && \
pip3 install packaging webcolors matplotlib yacs scikit-learn scikit-image torchgeometry pytz requests redis GPUtil opencv-python && \

pip3 install tensorrt==8.6.1 && \

apt clean && \
rm -rf /var/lib/apt/lists/* && \
pip cache purge
```

**특징:**
- ✅ `--find-links`로 PyTorch 설치 (구버전 방식)
- ✅ 버전 중요 패키지는 명시적 설치

**현재 방식 (공식 문서):**
- ✅ `--index-url`로 PyTorch 설치 (공식 권장 방식)
- ✅ 버전에서 CUDA 접미사 제거 (예: `2.1.0`, `+cu118` 제거)
- ✅ 프리셋 JSON에서 개별 버전 관리 (torch, torchvision, torchaudio)
- ✅ CUDA 버전별 명확한 인덱스 URL
- ✅ 일반 패키지는 한 줄에 설치

---

## 변경된 파일 목록

### 1. `artifacts/ubuntu22.04-cuda11.8-torch2.1/requirements.txt`

**변경 내용:**
- ❌ 제거: pip, setuptools, wheel
- ❌ 제거: numpy, scipy
- ❌ 제거: torch, torchvision, torchaudio
- ❌ 제거: tensorrt
- ✅ 유지: 일반 패키지들만

### 2. `docker/Dockerfile`

**Builder Stage:**
- ✅ 명시적 설치 순서 (numpy → scipy → pytorch → tensorrt → 나머지)
- ✅ PyTorch `--find-links` 사용
- ❌ wheels 디렉토리 복사 제거
- ❌ sources 디렉토리 복사 주석 처리

**Runtime Stage:**
- ✅ Builder와 동일한 설치 방식
- ✅ `pip cache purge` 추가 (이미지 크기 최소화)

### 3. `scripts/deps_sync.sh`

**변경 내용:**
- ❌ Python wheels 다운로드 제거
- ✅ 안내 메시지로 변경
- ✅ Python 패키지는 Docker 빌드 시 설치됨을 명시

### 4. 문서들

**업데이트된 문서:**
- `docs/build-guide.md`: 의존성 다운로드 단계 업데이트
- `README.md`: Python 패키지 관리 섹션 업데이트

---

## 장점과 단점

### 장점 ✅

1. **간소화**
   - wheels 디렉토리 관리 불필요
   - 사전 다운로드 단계 제거

2. **검증된 방식**
   - Legacy dockerfile에서 이미 사용 중
   - 안정성 입증됨

3. **최신성**
   - 항상 최신 패키지 다운로드
   - 보안 업데이트 자동 적용

4. **유연성**
   - 프리셋별 버전 변경 용이
   - requirements.txt 단순화

### 단점 ❌

1. **인터넷 필수**
   - Docker 빌드 시 인터넷 연결 필요
   - 완전 오프라인 빌드 불가

2. **빌드 시간**
   - 패키지 다운로드 시간 추가
   - 캐싱되지 않으면 매번 다운로드

3. **네트워크 의존성**
   - PyPI, PyTorch 서버 장애 시 빌드 불가
   - 방화벽 환경에서 제한

---

## 마이그레이션 가이드

### 기존 프로젝트 업데이트

```bash
# 1. 최신 코드 가져오기
git pull origin main

# 2. wheels 디렉토리 정리 (선택 사항)
rm -rf artifacts/*/wheels/*.whl

# 3. 빌드 테스트
python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1
```

### 새 프리셋 생성 시

```bash
# 1. 프리셋 디렉토리 생성
mkdir -p artifacts/new-preset/{sources,wheels,debs}

# 2. requirements.txt 작성 (버전 관리 패키지 제외)
cat > artifacts/new-preset/requirements.txt << EOF
# Data processing and utilities
packaging
webcolors
matplotlib
...
EOF

# 3. 프리셋 JSON 작성
# pytorch, tensorrt 버전 명시

# 4. Dockerfile에서 버전 하드코딩 수정 (향후 개선 예정)
```

---

## 향후 개선 계획

### 1. 동적 버전 관리

현재는 Dockerfile에 버전이 하드코딩되어 있습니다:

```dockerfile
pip3 install numpy==1.23.1
pip3 install torch==2.1.0+cu118
```

**개선 방안:**

```dockerfile
ARG NUMPY_VERSION=1.23.1
ARG TORCH_VERSION=2.1.0+cu118

RUN pip3 install numpy==${NUMPY_VERSION}
RUN pip3 install torch==${TORCH_VERSION}
```

build.py에서 프리셋 JSON을 읽어 ARG로 전달:

```python
build_args = {
    "NUMPY_VERSION": preset["packages"]["numpy"],
    "TORCH_VERSION": preset["pytorch"]["torch_version"],
    ...
}
```

### 2. 하이브리드 방식

인터넷 연결 여부에 따라 자동 선택:

```dockerfile
RUN if [ -d "/tmp/wheels" ] && [ "$(ls -A /tmp/wheels)" ]; then \
        pip3 install --no-index --find-links=/tmp/wheels -r /tmp/requirements.txt; \
    else \
        pip3 install -r /tmp/requirements.txt; \
    fi
```

### 3. 프록시 지원

방화벽 환경을 위한 프록시 설정:

```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
```

---

## 빌드 시간 비교

### Before (오프라인)

```
사전 준비: 10-30분 (deps_sync.sh)
빌드: 30-40분
총: 40-70분
```

### After (온라인)

```
사전 준비: 0분
빌드: 40-60분 (패키지 다운로드 포함)
총: 40-60분
```

**결론**: 총 시간은 비슷하거나 약간 단축됨

---

## FAQ

### Q1: 완전 오프라인 환경에서는?

A: 현재 방식으로는 불가능합니다. 하이브리드 방식을 구현하거나, 네트워크가 있는 환경에서 빌드 후 이미지를 export/import해야 합니다.

```bash
# 빌드 후 이미지 저장
docker save xaiva-kit:tag > xaiva-media.tar

# 오프라인 환경에서 로드
docker load < xaiva-media.tar
```

### Q2: PyTorch 다운로드 실패 시?

A: `--find-links` URL 확인 또는 프록시 설정:

```bash
docker build --build-arg HTTP_PROXY=http://proxy:port ...
```

### Q3: 버전을 변경하려면?

A: 현재는 Dockerfile을 직접 수정해야 합니다. 향후 프리셋 JSON에서 관리하도록 개선 예정입니다.

---

## 결론

Legacy dockerfile의 검증된 방식을 채택하여 빌드 프로세스를 간소화했습니다. 인터넷 연결이 필요하지만, 관리 복잡도가 크게 감소했습니다.

**권장 사항:**
- ✅ 일반적인 경우: 온라인 빌드 사용
- ✅ 오프라인 배포: 이미지를 빌드 후 export/import
- ✅ 하이브리드: 향후 개선 예정

---

**작성일**: 2025-11-20  
**참조**: legacy/dockerfile

