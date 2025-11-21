# 문서 가이드

이 디렉터리는 XaivaKit 프로젝트의 모든 문서를 포함합니다.

---

## 📚 문서 카테고리

### 1. 시작 가이드

| 문서 | 설명 | 대상 독자 |
|------|------|----------|
| **[build-guide.md](build-guide.md)** | 빌드 가이드 (온라인/오프라인) | 빌드 담당자 |
| **[preset-schema.md](preset-schema.md)** | 프리셋 JSON 스키마 | 프리셋 작성자 |

**추천 순서**: `build-guide.md` → `preset-schema.md`

---

### 2. 프로젝트 이해

| 문서 | 설명 | 대상 독자 |
|------|------|----------|
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | 프로젝트 전체 요약 | 모든 개발자 |
| **[DEVELOPMENT_HISTORY.md](DEVELOPMENT_HISTORY.md)** | 시간순 개발 히스토리 | 개발자 |
| **[CHANGE_PLAN.md](CHANGE_PLAN.md)** | 변경 계획 및 추적 (상세) | 개발자 |
| **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** | 변경 사항 요약 (빠른 참조) | 개발자 |
| **[REFACTORING_INFO.md](REFACTORING_INFO.md)** | 리팩토링 정보 수집 | 개발자 |

**추천 순서**: `PROJECT_SUMMARY.md` → `DEVELOPMENT_HISTORY.md` → `CHANGES_SUMMARY.md`

---

### 3. 설계 문서 (아카이브)

| 문서 | 설명 | 상태 |
|------|------|------|
| **[development-goals.md](development-goals.md)** | 초기 개발 목표 | 📦 아카이브 |
| **[implementation-plan.md](implementation-plan.md)** | Phase 1-5 계획 | 📦 아카이브 |

**참고**: 이 문서들은 초기 계획이며, 현재 상태는 `PROJECT_SUMMARY.md` 참고

---

### 4. 완료 보고서 (아카이브)

| 문서 | 설명 | 날짜 | 상태 |
|------|------|------|------|
| **[phase1-update.md](phase1-update.md)** | Phase 1 업데이트 | 2025-11-20 | 📦 아카이브 |
| **[phase1-completion.md](phase1-completion.md)** | Phase 1 완료 | 2025-11-20 | 📦 아카이브 |
| **[phase2-4-completion.md](phase2-4-completion.md)** | Phase 2-4 완료 | 2025-11-20 | 📦 아카이브 |

**참고**: 내용은 `DEVELOPMENT_HISTORY.md`에 통합되었음

---

### 5. 기술 변경 문서 (아카이브)

| 문서 | 설명 | 날짜 | 상태 |
|------|------|------|------|
| **[dockerfile-update-summary.md](dockerfile-update-summary.md)** | Dockerfile 업데이트 | 2025-11-20 | 📦 아카이브 |
| **[online-build-migration.md](online-build-migration.md)** | 온라인 빌드 마이그레이션 | 2025-11-20 | 📦 아카이브 |
| **[standard-paths-migration.md](standard-paths-migration.md)** | 표준 경로 마이그레이션 | 2025-11-20 | 📦 아카이브 |

**참고**: 핵심 내용은 `PROJECT_SUMMARY.md`와 `DEVELOPMENT_HISTORY.md`에 통합되었음

---

## 🚀 빠른 시작

### 처음 사용하는 경우

1. **[../README.md](../README.md)** - 프로젝트 소개
2. **[build-guide.md](build-guide.md)** - 빌드 방법
3. **[preset-schema.md](preset-schema.md)** - 프리셋 이해

### 개발에 참여하는 경우

1. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - 전체 이해
2. **[DEVELOPMENT_HISTORY.md](DEVELOPMENT_HISTORY.md)** - 개발 과정
3. **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - 진행 중인 변경 (빠른 참조)
4. **[CHANGE_PLAN.md](CHANGE_PLAN.md)** - 변경 계획 상세 (필요시)
5. **[build-guide.md](build-guide.md)** - 실제 빌드

### 리팩토링 작업하는 경우

1. **[REFACTORING_INFO.md](REFACTORING_INFO.md)** - 정보 수집 체크리스트
2. **[CHANGE_PLAN.md](CHANGE_PLAN.md#cp-000)** - CP-000 상세 계획
3. **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md#cp-000)** - CP-000 요약

### 특정 주제를 찾는 경우

- **빌드 방법**: `build-guide.md`
- **프리셋 작성**: `preset-schema.md`
- **온라인 빌드**: `PROJECT_SUMMARY.md` > 주요 기술 결정사항 > 온라인 빌드
- **표준 경로**: `PROJECT_SUMMARY.md` > 주요 기술 결정사항 > 표준 경로
- **개발 히스토리**: `DEVELOPMENT_HISTORY.md`

---

## 📖 문서 읽기 맵

```
처음 사용
    ├─ ../README.md (프로젝트 소개)
    └─ build-guide.md (빌드 가이드)
         └─ preset-schema.md (프리셋 스키마)

개발 참여
    ├─ PROJECT_SUMMARY.md (프로젝트 요약)
    │   ├─ 핵심 목표
    │   ├─ 주요 기술 결정사항
    │   └─ 현재 시스템 구성
    ├─ DEVELOPMENT_HISTORY.md (개발 히스토리)
    │   └─ 시간순 변경사항
    └─ CHANGE_PLAN.md (변경 계획)
         ├─ 진행 중인 변경
         ├─ 구현 계획
         └─ 작업 추적

참고 자료 (아카이브)
    ├─ development-goals.md (초기 목표)
    ├─ implementation-plan.md (초기 계획)
    ├─ phase*-completion.md (완료 보고서)
    └─ *-migration.md (변경 문서)
```

---

## 📝 문서 작성 가이드

### 새 문서 추가 시

1. 이 README에 문서 링크 추가
2. 적절한 카테고리 배치
3. 대상 독자 명시
4. 관련 문서 링크

### 문서 업데이트 시

1. 마지막 업데이트 날짜 기록
2. 주요 변경사항 명시
3. 관련 문서에 상호 링크

### 문서 아카이브 시

1. 상태를 "📦 아카이브"로 표시
2. 내용이 통합된 문서 링크
3. 원본은 유지 (삭제하지 않음)

---

## 🔍 검색 가이드

### 키워드별 문서

| 키워드 | 관련 문서 |
|--------|----------|
| 빌드 | build-guide.md, PROJECT_SUMMARY.md |
| 프리셋 | preset-schema.md, build-guide.md |
| Dockerfile | dockerfile-update-summary.md, PROJECT_SUMMARY.md |
| 온라인 빌드 | online-build-migration.md, PROJECT_SUMMARY.md |
| 표준 경로 | standard-paths-migration.md, PROJECT_SUMMARY.md |
| TensorRT | preset-schema.md, PROJECT_SUMMARY.md |
| PyTorch | preset-schema.md, online-build-migration.md |
| FFmpeg | dockerfile-update-summary.md, build-guide.md |
| OpenCV | dockerfile-update-summary.md, build-guide.md |
| 변경 계획 | CHANGE_PLAN.md |
| 의존성 | CHANGE_PLAN.md, build-guide.md |
| 브랜치 선택 | CHANGE_PLAN.md |

---

## ❓ FAQ

### Q: 어느 문서부터 읽어야 하나요?

**A**: 목적에 따라 다릅니다:
- **빌드만 하고 싶다**: `build-guide.md`
- **프로젝트를 이해하고 싶다**: `PROJECT_SUMMARY.md`
- **개발 과정이 궁금하다**: `DEVELOPMENT_HISTORY.md`

### Q: 오래된 문서는 어떻게 되나요?

**A**: 아카이브 상태로 유지됩니다. 
- 핵심 내용은 새 문서에 통합
- 원본은 참고용으로 보존
- "📦 아카이브" 표시로 구분

### Q: 문서가 최신인지 어떻게 확인하나요?

**A**: 각 문서 하단의 "마지막 업데이트" 날짜 확인
- **활성 문서**: 최근 업데이트
- **아카이브 문서**: 참고용

### Q: 새 프리셋을 만들려면?

**A**: `preset-schema.md` → `build-guide.md` 순서로 읽기

---

## 📮 문의

**문서 관련 문의**: 팀 채널  
**오타/오류 발견**: 이슈 트래커  
**개선 제안**: Pull Request

---

## 🔄 문서 버전 관리

| 날짜 | 변경 내용 |
|------|----------|
| 2025-11-21 | 변경 계획 문서(CHANGE_PLAN.md) 추가 |
| 2025-11-21 | 문서 통합 및 이 가이드 작성 |
| 2025-11-20 | Phase 2-4 완료 문서 추가 |
| 2025-11-20 | Phase 1 완료 문서 추가 |
| 2025-11-20 | 초기 문서 작성 |

---

**마지막 업데이트**: 2025-11-21  
**관리자**: h.kim

