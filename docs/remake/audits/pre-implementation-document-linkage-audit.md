# 구현 명세 전 최종 문서 연결 감사

- 상태: IN_PROGRESS
- 문서 종류: Completion Audit
- 감사일: 2026-08-05
- 현재 작업 순서: [`CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 선행 감사:
  - [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](runtime-architecture-completion-and-main-guide-readiness-audit.md)
  - [`Main System Guide 일관성과 문서 허브 완료 감사`](main-system-guide-consistency-and-document-hub-completion-audit.md)
  - [`Player·DM User Guide 완료 감사`](player-and-dm-user-guide-completion-audit.md)
  - [`User Guide Quick Flow와 Flowchart 보완 감사`](user-guide-quick-flow-and-flowchart-audit.md)

## 1. 감사 목적

Implementation Specs를 시작하기 전에 RVTT Remake 문서가 다음 경로로 끊김 없이 연결되는지 마지막으로 확인한다.

```text
Root README
→ Remake Documentation Hub
→ Quick Flow
→ Player·DM User Guide
→ Runtime·Domain Main System Guide
→ Product·Architecture·System·UI·ADR
→ Implementation Spec Hub·Template
→ Production Implementation Gate
```

감사 범위:

- 사용자와 개발자의 시작점
- 문서 역할과 권위 방향
- Hub의 현재 단계 표시
- Quick Flow·User Guide·Main Guide·Spec의 추적성
- 12개 Main Guide의 상태와 Completion Audit 연결
- Product·Architecture·System·UI·ADR Index 연결
- Implementation Spec Template과 기존 Shared Spec 진입 경로
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`, 충돌 Draft 제외
- 상대 링크와 GitHub Actions 문서 검증

이 Audit은 제품 동작이나 Architecture 결정을 새로 만들지 않는다.

## 2. 감사 전 발견 사항

### 2.1 단계 표시 Drift

다음 문서는 Work Order가 감사 단계로 바뀌기 전 상태인 `Implementation Specs IN_PROGRESS`를 계속 표시했다.

- Root `README.md`
- `docs/remake/README.md`
- `guides/README.md`
- `specs/README.md`

판정: `FIX_REQUIRED`

### 2.2 User Guide 계층 누락

`DOCUMENT-GUIDE.md`의 문서 계층과 문서 종류 선택에 `user-guides/`가 없었다.

추가 문제:

- User Guide 상태 체계가 없음
- 실제 Guide 경로가 아닌 오래된 파일명 예시 사용
- 현재 절차와 반대로 `IMPLEMENTED → GUIDE_CURRENT` 순서를 표시
- Quick Flow·User Guide·Authority·Spec 추적성 규칙이 없음

판정: `FIX_REQUIRED`

### 2.3 오래된 Product Draft가 활성 Index에 남음

`product/README.md`가 `core-session-loop.md`를 예정 권위 문서 1번으로 안내했다.

해당 Draft는 다음 최신 범위와 충돌했다.

- Encounter Token WASD 금지
- 음악·환경음·효과음 비목표

문서 수명주기 정책은 구현 명세 직전에 이러한 충돌 문서를 활성 권위 경로에서 정리하도록 요구한다.

판정: `DISCONTINUATION_REQUIRED`

### 2.4 Template 연결 누락

`templates/README.md`는 존재하지 않는 `implementation-spec-template.md`를 예정 문서로만 나열했고, 실제 존재하는 Main System Guide Template을 안내하지 않았다.

Implementation Spec의 필수 구조는 `AGENTS.md`에 있었지만 실제 작성 Template과 연결되지 않았다.

판정: `FIX_REQUIRED`

### 2.5 Shared Spec Index 불완전

`specs/shared/README.md`는 읽기 순서에서 001만 안내했고 002를 연결하지 않았다.

또한 두 초기 Shared Spec이 최신 Guide·User Guide 이전에 작성됐다는 `REVIEW_REQUIRED` 상태가 Index에 반영되지 않았다.

판정: `FIX_REQUIRED`

### 2.6 일부 Index의 역방향 탐색 부족

- User Guide Hub에서 Product·Guide·Spec·Lifecycle로 돌아가는 직접 링크가 부족함
- ADR Index에서 Work Order·Guide·Spec으로 이동하는 경로가 없음
- Guide Hub에서 Quick Flow 사용자 구간과 Domain Guide 대응을 한눈에 확인하기 어려움

판정: `FIX_REQUIRED`

## 3. 적용한 수정

### 3.1 수명주기 정리

`core-session-loop.md`를 `DISCONTINUED` 안내문으로 교체했다.

- 활성 안내: [`product/core-session-loop.md`](../product/core-session-loop.md)
- 보관 기록: [`archive/discontinued/product/core-session-loop.md`](../archive/discontinued/product/core-session-loop.md)
- 현재 사용자 흐름: [`Quick Flow`](../user-guides/QUICK-FLOW.md)
- 현재 이동 범위: [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
- 현재 제외 범위: [`콘텐츠 범위·자동화·Rollback·저장·제외 기능`](../product/content-automation-rollback-storage-and-exclusions.md)

원문 전체는 Git 기록으로 보존한다.

### 3.2 문서 구조 정책 갱신

[`DOCUMENT-GUIDE.md`](../DOCUMENT-GUIDE.md)에 다음을 반영했다.

- `user-guides/` 계층과 역할
- User Guide 메타데이터·상태
- 실제 Guide·User Guide 경로
- 현재 단계 순서
- 표준 사용자·개발자·구현 탐색 경로
- Quick Flow·User Guide·Guide·Authority·Spec 추적성
- 구현 명세 직전 수명주기 검사

### 3.3 Template 정리

- [`Implementation Spec Template`](../templates/implementation-spec-template.md) 생성
- [`Template Index`](../templates/README.md)에서 실제 제공 Template만 안내
- [`Main System Guide Template`](../templates/main-system-guide-template.md)에 User Flow Reference와 Spec 전달 규칙 추가

### 3.4 Hub·Index 연결 보강

- [`Product Index`](../product/README.md)
  - Quick Flow부터 현재 Product Authority까지 연결
  - Discontinued Draft 제외
- [`User Guide Hub`](../user-guides/README.md)
  - Product·Guide·Spec·Lifecycle 역방향 링크 추가
- [`Main System Guide Hub`](../guides/README.md)
  - Quick Flow·User Guide·Domain Guide 대응표 추가
- [`ADR Index`](../decisions/README.md)
  - Work Order·Guide·Authority·Spec 탐색 경로 추가
- [`Shared Spec Index`](../specs/shared/README.md)
  - 001·002 모두 연결
  - `REVIEW_REQUIRED`와 재검토 Gate 명시
- [`Implementation Spec Hub`](../specs/README.md)
  - 최종 감사 완료 전 `QUEUED`
  - Template·Acceptance·Authority 경로 명시

## 4. 12개 Main System Guide 재확인

다음 12개 Guide의 상단 상태와 Completion Audit 링크를 재확인했다.

| Guide | Guide Status | 시스템 상태 | Audit Link |
|---|---|---|---|
| Runtime | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Session | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Scene | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Exploration | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Rules | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Combat | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Character | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| UI | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Journal | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Scene Editor | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Diagnostics | `CURRENT` | `GUIDE_CURRENT` | 존재 |
| Extension | `CURRENT` | `GUIDE_CURRENT` | 존재 |

Guide 내부의 Parent·Children·References와 Authority Documents 구조는 선행 Guide Completion Audit에서 전체 검사됐다. 이번 감사에서는 파일이 유지되고 상태·Audit 연결이 변하지 않았음을 확인했다.

## 5. 최종 연결 모델

### 사용자 경로

```text
Root README
→ Quick Flow
→ Player 또는 DM Guide
→ 필요할 때 User Guide Hub
```

### 기획·Architecture 경로

```text
CURRENT-WORK-ORDER
→ Quick Flow의 사용자 목표
→ 관련 User Guide
→ Runtime Foundation Guide
→ Domain Main System Guide
→ 직접 Authority Documents·ADR
```

### Spec 경로

```text
사용자 Acceptance Flow
+ 직접 Authority Requirements
+ 기존 Code·Schema·Test 조사
→ Implementation Spec Template
→ 수직 Implementation Spec
→ Spec Ready Gate
```

### 구현 경로

```text
승인된 Spec
→ Test·Migration·Diagnostics 계약
→ Production Implementation
→ Build 검증
→ User Guide CURRENT_FOR_BUILD·RELEASE_VERIFIED 재검토
```

## 6. 권위 방향 검사

```text
사용자의 최신 명시적 결정
→ ADR
→ Product·Architecture·System·UI
→ 준비 완료 Spec

Audit
→ 완료·충돌·연결 판정

User Guide
→ 사용자 결과 Reference

Main System Guide
→ Authority 탐색 Reference
```

판정:

- User Guide가 Product Authority로 승격되지 않음
- Main System Guide가 Authority Parent로 사용되지 않음
- Spec이 Quick Flow를 Type·Schema 근거로 사용하지 않음
- Discontinued Draft가 현재 Authority 목록에서 제거됨
- Archive가 현재 구현 근거로 연결되지 않음

결과: `PASS`

## 7. 자동 검증

확인 대상:

- 상대 링크 존재
- Markdown 내부 경로
- Archive·Discontinued 안내 경로
- 새 Template 링크
- Root·Hub·Work Order 링크

최종 GitHub Actions 결과:

```text
PENDING
```

## 8. 최종 판정

```text
Root-to-User Flow Navigation
→ PENDING FINAL HUB UPDATE

User Flow-to-Guide Mapping
→ PASS

Guide-to-Authority Mapping
→ PASS

Authority-to-Spec Entry
→ PASS

Spec Template Availability
→ PASS

Document Lifecycle Exclusion
→ PASS

Shared Spec Review Gate
→ PASS

Automated Link Validation
→ PENDING

Pre-Implementation Document Linkage Audit
→ IN_PROGRESS

Implementation Specs
→ BLOCKED UNTIL FINAL VALIDATION
```

Root·Remake·Audit Hub와 Work Order를 최종 상태로 갱신하고 GitHub Actions가 성공하면 이 감사를 `COMPLETE`로 종료한다.