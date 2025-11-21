# Phase 1 업데이트 내역

## 📅 업데이트 날짜
2025-11-20

## 🎯 업데이트 목표

1. 용어 통일: `<preset-triplet>` → `<preset-name>` 변경
2. TensorRT 정보 강화: 런타임 필수성 및 CUDA 호환성 명시

---

## ✅ 완료된 변경사항

### 1. 용어 변경 (preset-triplet → preset-name)

**변경 이유:**
- "triplet"은 기술적 용어로 일반 사용자가 이해하기 어려움
- "preset-name"이 더 직관적이고 명확함
- 프리셋 이름이 단순히 3개 요소의 조합이 아닐 수 있음 (확장성)

**변경된 파일:**
- ✅ `docs/development-goals.md`
- ✅ `docs/implementation-plan.md`
- ✅ `README.md`
- ✅ `docs/phase1-completion.md`

**변경된 표현:**
- `artifacts/<preset-triplet>/` → `artifacts/<preset-name>/`
- `deps_sync.sh <preset-triplet>` → `deps_sync.sh <preset-name>`
- "환경 기준 트리플렛 형식" → "환경을 설명하는 프리셋 이름 형식"

### 2. 프리셋 JSON 수정 (TensorRT 섹션 강화)

**파일:** `presets/ubuntu22.04-cuda11.8-torch2.1.json`

**변경 전:**
```json
"tensorrt": {
  "enabled": true,
  "version": "8.6.1"
}
```

**변경 후:**
```json
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
```

**추가된 정보:**
- `required_in_runtime`: 런타임 이미지에 필수 포함 여부
- `supported_versions`: 지원하는 TensorRT 버전 목록
- `cuda_compatibility`: TensorRT 버전별 CUDA 호환성 매핑
- `description`: 상세 설명

### 3. 문서 내 TensorRT 설명 강화

**development-goals.md:**
```markdown
#### B. 핵심 AI 라이브러리
- **TensorRT**: `.deb` 또는 `.tar` 기반 설치. **런타임 이미지에 필수 포함** (추론 가속용).
  - 버전 8.x: CUDA 11.8 호환
  - 버전 10.x: CUDA 12.x 호환
```

**implementation-plan.md:**
- Python 의존성 관리 섹션에 TensorRT 런타임 필수성 명시
- CUDA 호환성 정보 추가

**README.md:**
```markdown
**중요: TensorRT는 런타임 이미지에 필수 포함됩니다.**
- TensorRT 8.x: CUDA 11.8 호환
- TensorRT 10.x: CUDA 12.x 호환
```

---

## 📊 영향 분석

### 디렉터리 구조 (변경 없음)
실제 디렉터리 이름은 변경되지 않았으며, 문서상 표기만 통일되었습니다.

```
artifacts/
└── ubuntu22.04-cuda11.8-torch2.1/    ← 실제 이름 유지
    ├── wheels/
    ├── debs/
    ├── sources/
    └── requirements.txt
```

### 코드 영향 (Phase 2에서 반영 필요)
다음 Phase에서 구현될 코드에 영향:
- `scripts/build.py`: 프리셋 이름 참조 시 일관된 용어 사용
- `scripts/deps_sync.sh`: 인자명 및 경로 참조
- `docker/Dockerfile`: ARG 변수명 및 경로 참조

### TensorRT 빌드 영향
- **Runtime 이미지**: TensorRT를 필수로 포함해야 함
- **Builder 이미지**: TensorRT 개발 헤더 필요 (선택적)
- **버전 선택**: CUDA 버전에 따라 자동으로 호환되는 TensorRT 버전 선택 필요

---

## 🔄 다음 단계 권장사항

### 1. 프리셋 확장 준비
- CUDA 12.x 기반 프리셋 추가 시 TensorRT 10.x 사용
- 프리셋 JSON 스키마 문서화

### 2. Dockerfile 구현 시 고려사항
- TensorRT를 Runtime 스테이지에 복사/설치
- CUDA 버전과 TensorRT 버전 호환성 체크 로직
- 환경 변수 `LD_LIBRARY_PATH`에 TensorRT 라이브러리 경로 포함

### 3. 빌드 스크립트 구현 시 고려사항
- 프리셋 JSON 검증 시 TensorRT 호환성 체크
- 사용자가 TensorRT를 비활성화하려 할 때 경고 표시
- TensorRT wheel 파일 자동 다운로드 (deps_sync.sh)

---

## 📝 요약

| 항목 | 변경 전 | 변경 후 |
|-----|---------|---------|
| 용어 | `<preset-triplet>` | `<preset-name>` |
| TensorRT 정보 | 버전만 명시 | 런타임 필수, CUDA 호환성, 지원 버전 명시 |
| 문서 일관성 | 부분적 | 전체 통일 |

---

## ✨ 개선 효과

1. **가독성 향상**: 직관적인 용어 사용으로 문서 이해도 증가
2. **명확성 강화**: TensorRT 런타임 필수성을 명시적으로 전달
3. **호환성 정보**: CUDA-TensorRT 버전 매핑으로 실수 방지
4. **확장성**: 새로운 프리셋 추가 시 명확한 가이드라인 제공

---

**업데이트 완료**: 모든 문서 및 프리셋 JSON이 새로운 명명 규칙과 TensorRT 정보를 반영하도록 업데이트되었습니다.

