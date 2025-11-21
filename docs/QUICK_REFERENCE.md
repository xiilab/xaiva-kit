# 빠른 참조 가이드

## 🚀 한눈에 보는 명령어

### 빌드

```bash
# 대화형 빌드
python3 scripts/build.py

# 자동 빌드
python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1 --non-interactive

# Dry-run (명령어만 확인)
python3 scripts/build.py --preset ubuntu22.04-cuda11.8-torch2.1 --dry-run

# 프리셋 목록
python3 scripts/build.py --list-presets
```

### 실행

```bash
# 이미지 실행
docker run --rm -it --gpus all xaiva-kit:ubuntu22.04-cuda11.8-torch2.1 /bin/bash

# 소스 마운트와 함께 실행
docker run --rm -it --gpus all -v $(pwd)/xaiva-kit:/workspace/xaiva-media \
  xaiva-kit:ubuntu22.04-cuda11.8-torch2.1 /bin/bash

# 데몬 모드로 실행
docker run -d --gpus all --name xaiva-container xaiva-kit:ubuntu22.04-cuda11.8-torch2.1
```

### 오프라인 배포

```bash
# 이미지 저장
docker save xaiva-kit:ubuntu22.04-cuda11.8-torch2.1 > xaiva-kit.tar

# 이미지 로드
docker load < xaiva-kit.tar

# 이미지 압축 (더 작은 파일)
docker save xaiva-kit:ubuntu22.04-cuda11.8-torch2.1 | gzip > xaiva-kit.tar.gz
docker load < xaiva-kit.tar.gz
```

### 이미지 관리

```bash
# 이미지 목록
docker images | grep xaiva-media

# 이미지 삭제
docker rmi xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime

# 사용하지 않는 이미지 정리
docker image prune -a

# 이미지 정보 확인
docker inspect xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime
```

---

## 📋 체크리스트

### 빌드 전 체크리스트

- [ ] Docker 설치 확인: `docker --version`
- [ ] NVIDIA Container Toolkit 확인: `nvidia-container-toolkit --version`
- [ ] GPU 인식 확인: `nvidia-smi`
- [ ] 디스크 공간 확인: `df -h` (최소 20GB)
- [ ] 인터넷 연결 확인 (Python 패키지 다운로드용)

### 빌드 후 체크리스트

- [ ] 이미지 생성 확인: `docker images | grep xaiva-media`
- [ ] 이미지 크기 확인 (Runtime: ~10-15GB)
- [ ] 컨테이너 실행 테스트
- [ ] GPU 접근 확인: `nvidia-smi` (컨테이너 내)
- [ ] Python 버전 확인: `python --version`
- [ ] PyTorch 확인: `python -c "import torch; print(torch.__version__)"`
- [ ] CUDA 사용 가능 확인: `python -c "import torch; print(torch.cuda.is_available())"`
- [ ] TensorRT 확인: `python -c "import tensorrt; print(tensorrt.__version__)"`

---

## 🔧 문제 해결

### 빌드 실패

```bash
# 1. 로그 확인
docker logs <container-id>

# 2. 중간 스테이지 확인
docker ps -a

# 3. 캐시 무시하고 다시 빌드
docker build --no-cache ...

# 4. 메모리 부족 시
docker build --memory=8g --cpus=4 ...
```

### GPU 인식 안 됨

```bash
# 1. NVIDIA 드라이버 확인
nvidia-smi

# 2. Docker GPU 지원 확인
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# 3. Docker 재시작
sudo systemctl restart docker

# 4. 컨테이너 GPU 플래그 확인
docker run --gpus all ...  # 'all' 또는 'device=0,1'
```

### Python 패키지 설치 실패

```bash
# 1. 인터넷 연결 확인
ping pypi.org

# 2. PyTorch 인덱스 확인
curl https://download.pytorch.org/whl/torch_stable.html

# 3. 프록시 설정 (필요시)
docker build --build-arg HTTP_PROXY=http://proxy:port ...

# 4. pip 캐시 정리
docker build --no-cache ...
```

---

## 📊 빠른 통계

### 빌드 시간

| 항목 | 시간 (예상) |
|------|-------------|
| 코덱 라이브러리 | 15-30분 |
| FFmpeg | 10-20분 |
| OpenCV (CUDA) | 30-60분 |
| Xaiva Media | 10-20분 |
| Python 패키지 | 10-20분 |
| **전체** | **1-2시간** |

### 디스크 사용량

| 항목 | 크기 (예상) |
|------|-------------|
| Builder 이미지 | ~20GB |
| Runtime 이미지 | ~10-15GB |
| Dev 이미지 | ~20GB |
| artifacts/ | ~5-10GB |

---

## 🎯 주요 경로

### 컨테이너 내부 경로

```
/usr/local/bin/              # 실행 파일 (FFmpeg, xaiva-app 등)
/usr/local/lib/              # 라이브러리 (.so 파일)
/usr/local/include/          # 헤더 파일
/usr/local/cuda/             # CUDA 설치 경로
```

### 호스트 프로젝트 경로

```
artifacts/<preset-name>/     # 프리셋별 아티팩트
  ├── wheels/                # Python wheels (현재 미사용)
  ├── sources/               # 소스 아카이브
  └── requirements.txt       # Python 패키지 목록

presets/<preset-name>.json   # 프리셋 정의
docker/Dockerfile            # Multi-stage Dockerfile
scripts/build.py             # 빌드 드라이버
```

---

## 🔑 주요 환경 변수

### 빌드 시

```bash
# Dockerfile ARG
BASE_IMAGE=nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
PRESET_NAME=ubuntu22.04-cuda11.8-torch2.1
PYTHON_VERSION=3.10
CUDA_ARCH=86
FFMPEG_VERSION=4.2
OPENCV_VERSION=4.9.0
```

### 런타임

```bash
# 컨테이너 내부 환경 변수
PATH=/usr/local/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=video,compute,utility
TZ=Asia/Seoul
LC_ALL=C.UTF-8
```

---

## 📦 프리셋 필드 요약

```json
{
  "metadata": { "name", "description", "created", "target_gpu" },
  "base_image": "nvidia/cuda:...",
  "python": { "version": "3.10", "version_without_dot": "310" },
  "pytorch": { "torch_version": "2.1.0+cu118", ... },
  "tensorrt": { "version": "8.6.1", "required_in_runtime": true, ... },
  "cuda": { "version": "11.8", "arch": "86" },
  "build_options": { "ffmpeg_version", "opencv_version", ... },
  "system_packages": [...],
  "environment": { "LD_LIBRARY_PATH", ... }
}
```

---

## 🐛 디버깅 팁

### 컨테이너 내부 확인

```bash
# 라이브러리 의존성 확인
ldd /usr/local/bin/xaiva-app

# 라이브러리 검색 경로 확인
ldconfig -p | grep libxaiva

# Python 패키지 확인
pip list | grep torch

# CUDA 확인
nvcc --version
nvidia-smi

# 환경 변수 확인
echo $LD_LIBRARY_PATH
echo $PATH
```

### 로그 확인

```bash
# Docker 빌드 로그 저장
python3 scripts/build.py ... 2>&1 | tee build.log

# 컨테이너 로그
docker logs <container-id>

# 빌드 히스토리 확인
docker history xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime
```

---

## 📞 도움말 및 문서

### CLI 도움말

```bash
# build.py 도움말
python3 scripts/build.py --help

# Docker 도움말
docker build --help
docker run --help
```

### 문서 링크

| 문서 | 경로 |
|------|------|
| 빌드 가이드 | `docs/build-guide.md` |
| 프리셋 스키마 | `docs/preset-schema.md` |
| 프로젝트 요약 | `docs/PROJECT_SUMMARY.md` |
| 개발 히스토리 | `docs/DEVELOPMENT_HISTORY.md` |
| 문서 가이드 | `docs/README.md` |

---

## 💡 유용한 팁

### 빌드 최적화

```bash
# BuildKit 사용 (더 빠른 빌드)
DOCKER_BUILDKIT=1 docker build ...

# 병렬 빌드 제한 (메모리 부족 시)
export MAKEFLAGS="-j4"  # 4코어만 사용

# 빌드 캐시 활용
docker build --cache-from=xaiva-kit:latest ...
```

### 이미지 크기 최적화

```bash
# 불필요한 레이어 확인
docker history xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime

# 이미지 압축
docker-squash xaiva-kit:ubuntu22.04-cuda11.8-torch2.1-runtime

# 다단계 빌드 사용 (이미 적용됨)
# builder, runtime 분리
```

### 여러 프리셋 빌드

```bash
# 스크립트 작성
for preset in ubuntu22.04-cuda11.8-torch2.1 ubuntu22.04-cuda12.1-torch2.3; do
  python3 scripts/build.py --preset $preset --build-type runtime --non-interactive
done
```

---

**마지막 업데이트**: 2025-11-21  
**버전**: 1.0

