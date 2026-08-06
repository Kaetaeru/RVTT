# 구현 명세 전 최종 문서 연결 감사

- 상태: COMPLETE
- 문서 종류: Completion Audit
- 감사일: 2026-08-05
- 현재 작업 순서: [`CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 선행 감사:
  - [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](runtime-architecture-completion-and-main-guide-readiness-audit.md)
  - [`Main System Guide 일관성과 문서 허브 완료 감사`](main-system-guide-consistency-and-document-hub-completion-audit.md)
  - [`Player·DM User Guide 완료 감사`](player-and-dm-user-guide-completion-audit.md)
  - [`User Guide Quick Flow와 Flowchart 보완 감사`](user-guide-quick-flow-and-flowchart-audit.md)

## 1. 감사 목적

Implementation Specs를 시작하기 전에 RVTT Remake 문서가 다음 경로로 끊김 없이 연결되는지 검사했다.

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

검사 범위:

- 사용자와 개발자의 시작점
- 문서 역할과 권위 방향
- Hub의 현재 단계 표시
- Quick Flow·User Guide·Main Guide·Spec 추적성
- 12개 Main Guide의 상태와 Completion Audit 연결
- Product·Architecture·System·UI·ADR Index 연결
- Implementation Spec Template과 Shared Spec 진입 경로
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`, 충돌 Draft 제외
- 상대 링크와 GitHub Actions 문서 검증

이 Audit은 제품 동작이나 Architecture 결정을 새로 만들지 않았다.

## 2. 발견하고 수정한 문제

### 2.1 User Guide 계층 누락

`DOCUMENT-GUIDE.md`에 `user-guides/` 계층, 상태 체계와 역할이 없었다.

수정:

- Quick Flow와 Player·DM Guide의 역할 추가
- `TARGET_EXPERIENCE → UPDATE_REQUIRED → CURRENT_FOR_BUILD → RELEASE_VERIFIED` 상태 추가
- User Guide와 Main Guide가 비권위 Reference라는 방향 확정
- 사용자·기획·Spec·구현의 표준 탐색 경로 추가

### 2.2 오래된 Product Draft의 활성 권위 잔류

`product/core-session-loop.md`는 다음 최신 확정 범위와 충돌했다.

- Encounter에서 Token WASD 금지
- 음악·환경음·효과음 비목표

수정:

- 활성 파일을 `DISCONTINUED` 안내문으로 교체
- 보관 기록 생성: [`archive/discontinued/product/core-session-loop.md`](../archive/discontinued/product/core-session-loop.md)
- 현재 사용자 흐름을 [`Quick Flow`](../user-guides/QUICK-FLOW.md)와 상세 User Guide로 이전
- 현재 Product Authority를 이동·입력 범위와 콘텐츠·제외 범위로 한정

### 2.3 Implementation Spec Template 부재

필수 명세 구조가 `AGENTS.md`에만 있었고 실제 Template 파일이 없었다.

수정:

- [`Implementation Spec Template`](../templates/implementation-spec-template.md) 생성
- Quick Flow·Player·DM Acceptance Flow와 직접 Authority 추적성 추가
- Type·Command·Persistence·Migration·Transaction·Projection·Diagnostics·Test Gate 통합
- Template Index에서 실제 제공 Template만 안내

### 2.4 Shared Spec Index 불완전

Shared Index가 Spec 001만 안내했고 002와 재검토 Gate를 누락했다.

수정:

- 001·002 모두 연결
- Index 상태를 `REVIEW_REQUIRED`로 변경
- RuleExecution·Transaction·Recovery·Diagnostics·Simulation·Extension과 사용자 Prompt 흐름의 재검토 항목 추가
- 재검토 전 Production Code 근거로 사용하지 않도록 차단

### 2.5 Hub와 Index의 역방향 탐색 부족

수정한 문서:

- [`Product Index`](../product/README.md)
- [`User Guide Hub`](../user-guides/README.md)
- [`Main System Guide Hub`](../guides/README.md)
- [`ADR Index`](../decisions/README.md)
- [`Shared Spec Index`](../specs/shared/README.md)
- [`Implementation Spec Hub`](../specs/README.md)
- [`Template Index`](../templates/README.md)
- [`Audit Index`](README.md)

Root·Work Order·Quick Flow·Guide·Authority·Spec·Lifecycle로 왕복할 수 있도록 연결했다.

### 2.6 Guide Template과 실제 경로 불일치

수정:

- 실제 Guide 경로인 `guides/<domain>/README.md` 사용
- Quick Flow·User Guide Reference 필드 추가
- User Guide를 Parent Authority로 기록하지 않는 규칙 추가
- 폐기 문서 제외와 Spec 전달 체크리스트 추가
- Work Order 상대 링크 교정

## 3. 12개 Main System Guide 재확인

| Guide | Guide Status | 시스템 상태 | Completion Audit |
|---|---|---|---|
| Runtime | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Session | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Scene | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Exploration | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Rules | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Combat | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Character | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| UI | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Journal | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Scene Editor | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Diagnostics | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |
| Extension | `CURRENT` | `GUIDE_CURRENT` | 연결됨 |

선행 Guide Completion Audit에서 검사한 Parent·Children·References와 Authority Documents 구조도 그대로 유지됐다.

## 4. 최종 연결 모델

### 사용자 경로

```text
Root README
→ Quick Flow
→ Player 또는 DM Guide
→ 필요한 상세 Hub
```

### 기획·Architecture 경로

```text
CURRENT-WORK-ORDER
→ Quick Flow의 사용자 목표
→ 관련 User Guide
→ Runtime Foundation Guide
→ Domain Main System Guide
→ 직접 Product·Architecture·System·UI·ADR
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

## 5. 권위 방향 검사

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

검사 결과:

- User Guide가 Product Authority로 승격되지 않음
- Main System Guide가 Authority Parent로 사용되지 않음
- Spec이 Quick Flow를 Type·Schema 근거로 사용하지 않음
- Discontinued Draft가 현재 Authority 목록에서 제거됨
- Archive가 현재 구현 근거로 연결되지 않음

판정: `PASS`

## 6. 자동 검증

GitHub Actions:

```text
Workflow: Validate remake documentation
Run: #805
Job: validate
Conclusion: success
```

확인된 항목:

- 상대 링크 대상 존재
- Archive·Discontinued 안내 경로
- 새 Implementation Spec Template 링크
- Root·Hub·Work Order 경로
- Markdown 내부 링크 정합성

판정: `PASS`

## 7. 최종 판정

```text
Root-to-User Flow Navigation
→ PASS

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
→ PASS

Pre-Implementation Document Linkage Audit
→ COMPLETE

Implementation Specs
→ READY TO START

Production Implementation
→ NOT STARTED
```

구현 명세 전 문서 연결 감사는 완료됐다. 다음 단계는 `specs/CURRENT-SPEC-WORK-ORDER.md`를 만들고 Shared Spec 001·002를 재검토한 뒤 Quick Flow의 첫 수직 Slice를 확정하는 것이다.