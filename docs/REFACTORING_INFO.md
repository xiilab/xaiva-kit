# 리팩토링 정보 수집 체크리스트

> 📋 **목적**: CP-000 리팩토링 작업 시작 전 필요한 정보 수집  
> 🔗 **참조**: [CHANGE_PLAN.md - CP-000](CHANGE_PLAN.md#cp-000-코드베이스-리팩토링-최우선)

**생성일**: 2025-11-21  
**상태**: 🔍 정보 수집 중

---

## 📊 진행 상황

```
총 질문: 10개
답변 완료: 0개 (0%)
남은 질문: 10개 (100%)

즉시 결정 필요: 8개 (Q1-Q8)
나중 결정 가능: 2개 (Q9-Q10)

마지막 업데이트: 2025-11-21 (실제 코드 검토 반영)
```

---

## 🔴 즉시 결정 필요 (8개)

### Q1: Dockerfile 빌드 코드 구조 개선

**배경**:
- 현재 Dockerfile에 모든 빌드 코드가 활성화되어 있음
- FFmpeg 빌드 코드: 150-263 라인 (코덱 라이브러리 포함)
- OpenCV 빌드 코드: 275-342 라인
- Xaiva Media 빌드 코드: 347-390 라인
- 총 ~390 라인의 빌드 코드가 인라인으로 포함됨

**옵션**:

#### 옵션 A: 별도 스크립트로 분리 (권장)
**장점**:
- ✅ Dockerfile 가독성 대폭 향상
- ✅ 빌드 로직 재사용 용이
- ✅ 개별 컴포넌트 테스트 가능
- ✅ 버전 업그레이드 시 유지보수 용이

**단점**:
- ⚠️ 파일 수 증가
- ⚠️ COPY 명령어 추가 필요

**구조 예시**:
```
docker/
├── Dockerfile                    # 메인 (간결)
└── build-scripts/               # 빌드 스크립트
    ├── build-codecs.sh          # x264, x265, libvpx, opus, fdk-aac
    ├── build-ffmpeg.sh
    ├── build-opencv.sh
    └── build-xaiva-media.sh
```

#### 옵션 B: 현재 상태 유지
**장점**:
- ✅ 변경 없음
- ✅ 단일 파일로 모든 빌드 과정 확인 가능

**단점**:
- ❌ Dockerfile 513 라인으로 매우 김
- ❌ 가독성 저하
- ❌ 유지보수 어려움

#### 옵션 C: 멀티스테이지 빌드로 더 세분화
**장점**:
- ✅ 각 컴포넌트별 캐싱 최적화
- ✅ 병렬 빌드 가능

**단점**:
- ❌ 스테이지 수 증가로 복잡도 상승
- ❌ 레이어 관리 어려움

---

**결정**:
- [x] 옵션 A - 별도 스크립트로 분리 (권장)
- [ ] 옵션 B - 현재 상태 유지
- [ ] 옵션 C - 멀티스테이지 세분화

**세부 결정** (옵션 A 선택 시):
- [x] 분리할 코드:
  - [x] 코덱 빌드 (150-218 라인) → `docker/build-scripts/build-codecs.sh`
  - [x] FFmpeg 빌드 (220-269 라인) → `docker/build-scripts/build-ffmpeg.sh`
  - [x] OpenCV 빌드 (275-342 라인) → `docker/build-scripts/build-opencv.sh`
  - [x] Xaiva Media 빌드 (357-390 라인) → `docker/build-scripts/build-xaiva-media.sh`

**추가 확인 사항**
- sh 파일 변경 시 캐싱 사용되는지 확인
- 각 빌드 셸 스크립트에 충분한 주석을 사용할 수 있는지 확인

---

### Q2: Dockerfile 구조 개선 기준

**배경**:
- 현재 시스템 패키지 설치 RUN 명령어가 67 라인 (line 67-134)
- 이미 논리적으로 그룹화되어 있음 (빌드 도구, FFmpeg 의존성, OpenCV 의존성, Python, 유틸리티)
- 가독성과 빌드 캐시 최적화 사이 균형 필요

**옵션**:

#### 옵션 A: 논리적 단위별 분할
**예시**:
```dockerfile
# 시스템 패키지 설치
RUN apt-get update && \
    apt-get install -y pkg1 pkg2 ...

# Python 설치
RUN apt-get install -y python${PYTHON_VERSION} ...

# Python 패키지 설치
RUN pip3 install package1 && \
    pip3 install package2 ...

# 정리
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

**장점**:
- ✅ 가독성 중간
- ✅ 캐시 활용 좋음

**단점**:
- ⚠️ 레이어 수 증가

#### 옵션 B: 레이어 최적화 우선
**예시**:
```dockerfile
# 모든 설치를 하나의 RUN으로
RUN apt-get update && \
    apt-get install -y pkg1 pkg2 ... python${PYTHON_VERSION} && \
    pip3 install package1 package2 ... && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

**장점**:
- ✅ 레이어 수 최소
- ✅ 이미지 크기 최소

**단점**:
- ❌ 가독성 저하
- ❌ 캐시 활용 어려움

#### 옵션 C: 가독성 우선 (권장)
**예시**:
```dockerfile
# 시스템 패키지
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Python 설치
RUN apt-get update && apt-get install -y \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    && apt-get clean

# Python 패키지 (버전 관리)
RUN pip3 install --upgrade pip setuptools wheel && \
    pip3 install numpy==1.23.1 && \
    pip3 install scipy==1.11.4

# Python 패키지 (일반)
COPY artifacts/${PRESET_NAME}/requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt
```

**장점**:
- ✅ 가독성 우수
- ✅ 유지보수 용이
- ✅ 적절한 캐시 활용

**단점**:
- ⚠️ 레이어 수 증가 (관리 가능 수준)

---

**결정**:
- [ ] 옵션 A - 논리적 단위별
- [ ] 옵션 B - 레이어 최적화 우선
- [x] 옵션 C - 가독성 우선 (권장)

---

### Q3: Runtime/Dev 스테이지 처리 순서

**배경**:
- CP-001에서 Dev 이미지만 사용 예정
- 리팩토링 시 Runtime/Dev 중복 제거 가능

**옵션**:

#### 옵션 A: 리팩토링 먼저 (권장)
**순서**:
1. CP-000: 리팩토링 (Runtime/Dev 중복 제거)
2. CP-001: Dev 이미지로 통합 (간단)

**장점**:
- ✅ 중복 제거 후 통합이 쉬움
- ✅ 코드 정리 효과 극대화

**단점**:
- ⚠️ 리팩토링 시간 추가

#### 옵션 B: CP-001 먼저
**순서**:
1. CP-001: Dev 이미지로 통합 (Runtime 제거)
2. CP-000: 리팩토링 (단순화된 코드)

**장점**:
- ✅ 빠른 통합

**단점**:
- ❌ 중복 코드 상태에서 통합 (복잡)
- ❌ 리팩토링 효과 감소

---

**결정**:
- [x] 옵션 A - 리팩토링 먼저 (권장)
- [ ] 옵션 B - CP-001 먼저

---

### Q4: Python 패키지 버전 관리 방식

**배경**:
- 현재: Dockerfile에 하드코딩 (`numpy==1.23.1`)
- 문제: 프리셋별 버전 변경 시 Dockerfile 수정 필요

**옵션**:

#### 옵션 A: 프리셋 JSON에서 버전 읽어오기
**방식**:
```json
// 프리셋 JSON
"packages": {
  "numpy": "1.23.1",
  "scipy": "1.11.4",
  "torch": "2.1.0+cu118"
}
```

```dockerfile
# Dockerfile (동적 ARG 사용)
ARG NUMPY_VERSION
ARG SCIPY_VERSION
RUN pip3 install numpy==${NUMPY_VERSION}
```

```python
# build.py
build_args = {
    "NUMPY_VERSION": preset["packages"]["numpy"],
    ...
}
```

**장점**:
- ✅ 프리셋별 버전 관리
- ✅ 중앙 집중식 관리

**단점**:
- ❌ 복잡도 증가
- ❌ ARG 수 증가
- ❌ Dockerfile 가독성 저하

#### 옵션 B: 하드코딩 유지, 주석으로 명시 (권장)
**방식**:
```dockerfile
# 버전 관리 패키지 (프리셋: ubuntu22.04-cuda11.8-torch2.1)
# 출처: presets/ubuntu22.04-cuda11.8-torch2.1.json
RUN pip3 install numpy==1.23.1 && \
    pip3 install scipy==1.11.4 && \
    pip3 install --find-links https://download.pytorch.org/whl/torch_stable.html torch==2.1.0+cu118
```

**장점**:
- ✅ 단순
- ✅ 가독성 우수
- ✅ 빠른 빌드

**단점**:
- ⚠️ 프리셋 추가 시 Dockerfile 수정 필요

#### 옵션 C: requirements.txt에 통합
**방식**:
모든 패키지를 requirements.txt로 관리

**장점**:
- ✅ 단일 파일 관리

**단점**:
- ❌ 설치 순서 제어 어려움
- ❌ PyTorch 커스텀 인덱스 처리 복잡

---

**결정**:
- [ ] 옵션 A - JSON에서 읽기
- [x] 옵션 B - 하드코딩 + 주석 (권장)
- [ ] 옵션 C - requirements.txt 통합

**추가 확인 사항**
pytorch tensorRT 는 별도 도커 명령어로 분리하고 프리셋에서 버전 로드(프리셋에서 버전 관리 항목은 별도 설치 필요)

---

### Q5: build.py 모듈 분할 방식

**배경**:
- 현재: 단일 파일 594 라인
- 문제: 모든 기능이 한 파일에 집중
- 구조는 이미 함수별로 잘 분리되어 있음

**옵션**:

#### 옵션 A: 기능별 디렉터리 구조 (권장)
**구조**:
```
scripts/
├── build.py                    # 메인 엔트리포인트 (100 라인)
├── builder/                    # 빌드 로직 모듈
│   ├── __init__.py
│   ├── preset.py               # 프리셋 로딩/검증 (150 라인)
│   ├── validator.py            # 검증 로직 (100 라인)
│   ├── docker.py               # Docker 빌드 (150 라인)
│   └── ui.py                   # 대화형 UI (150 라인)
└── deps_sync.sh
```

**장점**:
- ✅ 명확한 책임 분리
- ✅ 유지보수 용이
- ✅ 확장 가능

**단점**:
- ⚠️ 파일 수 증가
- ⚠️ import 관리 필요

#### 옵션 B: 단일 파일 유지, 함수만 분리
**방식**:
현재 파일 내에서 함수만 정리

**장점**:
- ✅ 구조 단순
- ✅ 단일 파일 실행

**단점**:
- ❌ 여전히 긴 파일
- ❌ 확장 어려움

#### 옵션 C: 클래스 기반 재설계
**구조**:
```python
class PresetManager:
    def load(self, name)
    def validate(self, preset)

class DockerBuilder:
    def build(self, preset, args)

class InteractiveUI:
    def select_preset(self)
    def select_build_type(self)
```

**장점**:
- ✅ OOP 설계
- ✅ 상태 관리 용이

**단점**:
- ⚠️ 복잡도 증가
- ⚠️ 과도한 설계

---

**결정**:
- [x] 옵션 A - 기능별 디렉터리 (권장)
- [ ] 옵션 B - 단일 파일 유지
- [ ] 옵션 C - 클래스 기반

**세부 결정** (옵션 A 선택 시):
- [x] 모듈 분할:
  - [x] `builder/preset.py` - 프리셋 로딩/검증
  - [x] `builder/validator.py` - TensorRT, artifacts 검증
  - [x] `builder/docker.py` - Docker 빌드 로직
  - [x] `builder/ui.py` - 대화형 UI

---

### Q6: 표준 라이브러리 제한 유지 여부

**배경**:
- 현재: Python 표준 라이브러리만 사용
- 장점: 별도 설치 불필요
- 문제: 일부 기능 구현 복잡

**옵션**:

#### 옵션 A: 표준 라이브러리만 유지 (권장)
**유지 이유**:
- Ubuntu 22.04에 Python 3.10 기본 포함
- 별도 설치 불필요
- 현재 기능 충분

**단점**:
- CLI 파싱: argparse (기본 제공, 충분함)
- JSON 검증: 수동 구현 필요

#### 옵션 B: 유용한 외부 라이브러리 허용
**추천 라이브러리**:
- `click`: CLI 프레임워크 (argparse 대체)
- `pydantic`: JSON 검증
- `rich`: 색상 출력, 진행 바

**장점**:
- ✅ 구현 간편
- ✅ 기능 풍부

**단점**:
- ❌ 별도 설치 필요
- ❌ 의존성 증가

---

**결정**:
- [x] 옵션 A - 표준 라이브러리만 (권장)
- [ ] 옵션 B - 외부 라이브러리 허용

---

### Q7: 에러 처리 일관성

**배경**:
- 현재: sys.exit(1), print_error() 혼재
- 문제: 에러 처리 방식 불일치

**옵션**:

#### 옵션 A: 커스텀 Exception 클래스
**방식**:
```python
class BuildError(Exception):
    pass

class PresetNotFoundError(BuildError):
    pass

class ValidationError(BuildError):
    pass

# 사용
try:
    if not preset_exists:
        raise PresetNotFoundError(f"Preset {name} not found")
except BuildError as e:
    print_error(str(e))
    sys.exit(1)
```

**장점**:
- ✅ 에러 타입 명확
- ✅ 에러 처리 일관성

**단점**:
- ⚠️ 복잡도 증가
- ⚠️ 표준 라이브러리 외 패턴

#### 옵션 B: 현재 방식 유지, 일관성만 확보 (권장)
**방식**:
```python
# 일관된 패턴
if error_condition:
    print_error("Error message")
    sys.exit(1)

# 경고만 필요한 경우
if warning_condition:
    print_warning("Warning message")
    # 계속 진행
```

**장점**:
- ✅ 단순
- ✅ 현재 코드 스타일 유지

**단점**:
- ⚠️ Exception 미활용

---

**결정**:
- [ ] 옵션 A - 커스텀 Exception
- [x] 옵션 B - 현재 방식 + 일관성 (권장)

---

### Q8: 테스트 코드 추가 여부

**배경**:
- 현재: 테스트 코드 없음
- 검증: 수동 빌드 테스트

**옵션**:

#### 옵션 A: pytest 도입
**방식**:
```
scripts/
├── build.py
├── builder/
│   ├── preset.py
│   └── ...
└── tests/
    ├── test_preset.py
    ├── test_validator.py
    └── test_docker.py
```

**테스트 예시**:
```python
def test_load_preset():
    preset = load_preset("ubuntu22.04-cuda11.8-torch2.1")
    assert preset["metadata"]["name"] == "ubuntu22.04-cuda11.8-torch2.1"

def test_validate_tensorrt_compatibility():
    preset = {...}
    assert validate_tensorrt_compatibility(preset) == True
```

**장점**:
- ✅ 자동 검증
- ✅ 리팩토링 안전성

**단점**:
- ❌ pytest 설치 필요
- ❌ 테스트 작성 시간

#### 옵션 B: 수동 검증 (권장)
**방식**:
- 리팩토링 후 수동 빌드 테스트
- 기능 동작 확인

**장점**:
- ✅ 빠른 진행
- ✅ 추가 의존성 없음

**단점**:
- ⚠️ 자동화 없음

---

**결정**:
- [ ] 옵션 A - pytest 도입
- [x] 옵션 B - 수동 검증 (권장)

---

## 🟡 나중에 결정 가능 (2개)

### Q9: xaiva-media 소스 관리 방식

**배경**:
- 현재: `xaiva-media/` 디렉터리가 프로젝트 루트에 존재 (일반 디렉터리로 포함됨)
- 문제: 프로젝트 구조 혼재
- xaiva-media는 자체적인 CMakeLists.txt와 소스 구조를 가진 독립적인 프로젝트

**옵션**:

#### 옵션 A: Git 서브모듈 전환 (권장)
**방식**:
```bash
# xaiva-media 디렉터리 제거
rm -rf xaiva-media/

# 서브모듈로 추가
git submodule add <xaiva-repo-url> xaiva-media

# .gitmodules 생성됨
```

**장점**:
- ✅ 버전 관리 명확
- ✅ 브랜치 전환 용이
- ✅ CP-003과 연계

**단점**:
- ⚠️ 서브모듈 관리 필요
- ⚠️ 초기 클론 시 `--recursive` 필요

#### 옵션 B: 외부 경로 사용
**방식**:
```bash
# xaiva-media를 프로젝트 외부에
/DATA/h.kim/xaiva-media/

# 빌드 시 경로 지정
python3 scripts/build.py --xaiva-source /DATA/h.kim/xaiva-media
```

**장점**:
- ✅ 독립적 관리

**단점**:
- ❌ 경로 설정 필요
- ❌ 이식성 저하

#### 옵션 C: 현재 상태 유지
**장점**:
- ✅ 변경 없음

**단점**:
- ❌ 구조 혼재

---

**결정**:
- [ ] 옵션 A - Git 서브모듈 (권장, CP-003 연계)
- [ ] 옵션 B - 외부 경로
- [x] 옵션 C - 현재 상태 유지

**추가확인사항**
- 추후 옵션 B로 변경(리팩토링에서는 변경하지 않음)

---

### Q10: .gitignore 설정

**배경**:
- xaiva-media 처리 방식에 따라 결정

**옵션**:

#### 옵션 A: 서브모듈이면 자동 제외
**방식**:
서브모듈은 자동으로 .gitignore 불필요

#### 옵션 B: .gitignore에 명시
**방식**:
```gitignore
# Xaiva Media source
xaiva-media/
```

#### 옵션 C: Git에 포함
현재 상태

---

**결정**:
- [ ] 옵션 A - 서브모듈 (자동)
- [x] 옵션 B - .gitignore 추가
- [ ] 옵션 C - Git 포함

---

## 📝 결정 요약표

| 질문 | 선택 | 비고 |
|------|------|------|
| **Q1**: 주석 코드 처리 | ⬜ A / ⬜ B / ⬜ C | 즉시 |
| **Q2**: Dockerfile 구조 | ⬜ A / ⬜ B / ⬜ C | 즉시 |
| **Q3**: Runtime/Dev 순서 | ⬜ A / ⬜ B | 즉시 |
| **Q4**: 패키지 버전 관리 | ⬜ A / ⬜ B / ⬜ C | 즉시 |
| **Q5**: build.py 모듈화 | ⬜ A / ⬜ B / ⬜ C | 즉시 |
| **Q6**: 표준 라이브러리 | ⬜ A / ⬜ B | 즉시 |
| **Q7**: 에러 처리 | ⬜ A / ⬜ B | 즉시 |
| **Q8**: 테스트 코드 | ⬜ A / ⬜ B | 즉시 |
| **Q9**: xaiva-media 관리 | ⬜ A / ⬜ B / ⬜ C | 나중 |
| **Q10**: .gitignore | ⬜ A / ⬜ B / ⬜ C | 나중 |

---

## 🎯 권장 선택 (빠른 진행)

즉시 결정하고 빠르게 진행하려면:

```
Q1: B (별도 파일 분리)
Q2: C (가독성 우선)
Q3: A (리팩토링 먼저)
Q4: B (하드코딩 + 주석)
Q5: A (기능별 디렉터리)
Q6: A (표준 라이브러리만)
Q7: B (현재 방식 + 일관성)
Q8: B (수동 검증)
Q9: A (Git 서브모듈) - CP-003과 함께
Q10: A (자동)
```

이 선택으로 진행 시:
- 예상 시간: 6-8시간
- 라인 감소: ~30%
- 기능 변경: 없음

---

## 📅 다음 단계

### 결정 후
1. [ ] 이 문서의 체크박스 체크
2. [ ] 결정 요약표 작성
3. [ ] CHANGE_PLAN.md에 결정 사항 기록
4. [ ] 리팩토링 작업 시작

### 작업 중
1. [ ] 단계별 커밋
2. [ ] 각 단계마다 테스트
3. [ ] 진행 상황 CHANGE_PLAN.md 업데이트

---

**문서 버전**: 1.1  
**마지막 업데이트**: 2025-11-21  
**작성자**: AI Assistant

## 📝 업데이트 내역

### v1.1 (2025-11-21)
- 실제 코드 검토 후 문서 업데이트
- Q1: 주석 처리된 코드 → 활성화된 빌드 코드로 수정
- Q2: RUN 명령어 30+ 라인 → 67 라인으로 수정
- Q5: build.py 650+ 라인 → 594 라인으로 수정
- Q9: xaiva-media 현재 상태 명확히 기술

