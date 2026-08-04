# RVTT 문서 구조와 작성 가이드

- 상태: 확정
- 문서 종류: Documentation Guide
- 즉시 구현 명세 가능성: READY
- 최종 갱신일: 2026-08-05

이 문서는 `docs/remake/` 아래의 문서를 어디에 두고, 어떤 책임으로 작성하며, 어떤 순서로 연결하는지 정의한다.

## 1. 문서 계층

```text
user-guides/
→ 코딩 용어 없는 Quick Flow와 Player·DM 목표 사용자 경험

product/
→ 제품 목표, 지원 범위, 비목표와 사용자 경험의 권위 결정

architecture/
→ 여러 기능이 공유하는 권위, Source·Build·State, Runtime, 저장과 통합 계약

systems/
→ 기능 영역별 사용자 흐름과 시스템 동작

ui/
→ 화면 구조, 입력 문맥, Panel 상태와 사용자 피드백

decisions/
→ 되돌리기 어렵거나 여러 시스템에 영향을 주는 ADR

guides/
→ 완료된 권위 문서의 관계, 전체 흐름, 경계와 읽기 순서

specs/
→ 실제 코드를 시작하기 위한 Module·Type·Command·Persistence·Test 계약

audits/
→ 기획 완성도, 충돌, 누락, 연결과 단계 준비도 검사

templates/
→ 새 문서 작성 시 필수 항목 누락을 막는 표준 형식

archive/
→ 현재 판단에 사용하지 않는 역사 문서와 수명주기 기록
```

## 2. 문서 종류 선택

- 전체 세션을 사용자 언어로 설명한다면 `user-guides/`
- 제품 전체 범위나 비목표를 정한다면 `product/`
- 여러 기능이 공유하는 공통 계약이라면 `architecture/`
- 하나의 기능 영역 동작을 정한다면 `systems/<영역>/`
- 화면·입력·표시 구조를 정한다면 `ui/<영역>/`
- 중요한 대안을 비교하고 하나를 확정한다면 `decisions/`
- 완료된 문서 관계와 구현 진입 순서를 설명한다면 `guides/`
- 구현자가 추가 제품 결정을 하지 않고 코드를 시작할 계약이라면 `specs/<영역>/`
- 기존 문서의 충돌·완성도·연결을 검사한다면 `audits/`

한 문서가 여러 역할을 동시에 갖지 않게 한다.

```text
사용자 목표 경험
→ User Guide

제품과 시스템 의미
→ Product·Architecture·System·UI·ADR

권위 문서 탐색
→ Main System Guide

실제 구현 계약
→ Implementation Spec
```

User Guide와 Main System Guide는 비권위 탐색 문서다. 새로운 Product·Architecture·API·Schema 결정을 만들지 않는다.

## 3. 공통 메타데이터

### 권위 기획 문서

```markdown
- 상태: 초안 | 확정 | 대체됨
- 문서 종류: Product | Architecture | System | UI | Documentation Policy
- 즉시 구현 명세 가능성: READY | READY_WITH_DEFAULTS | BLOCKED
- 관련 ADR:
- 상위 문서:
- 관련 시스템:
- 대체하는 문서:
- 대체된 문서:
```

### User Guide

```markdown
- 사용자 가이드 상태: TARGET_EXPERIENCE | UPDATE_REQUIRED | CURRENT_FOR_BUILD | RELEASE_VERIFIED
- 대상: Player | DM | Observer
- 최종 갱신일:
- Quick Flow:
- User Guide Hub:
```

### Main System Guide

```markdown
- Guide Status: NOT_READY | READY_TO_WRITE | CURRENT | UPDATE_REQUIRED
- 적용 시스템 상태:
- Completion Audit:
- 마지막 권위 문서 검토일:
```

### Implementation Spec

구현 명세 상태와 필수 절은 [`AGENTS.md`](AGENTS.md)와 [`Implementation Spec Template`](templates/implementation-spec-template.md)을 따른다.

## 4. 권위와 우선순위

1. 사용자의 최신 명시적 결정
2. 확정 ADR
3. 확정 Product·Architecture·System·UI 문서
4. 준비 완료 Implementation Spec
5. Audit
6. User Guide와 Main System Guide
7. 초안, `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서

- Audit은 문제를 보고하지만 제품 결정을 직접 대체하지 않는다.
- User Guide는 사용자 결과를 설명하지만 Product Authority가 아니다.
- Main System Guide는 권위 문서를 연결하지만 Authority Tree의 Parent가 아니다.
- 충돌하면 더 높은 권위 문서를 따른다.

## 5. 표준 탐색 경로

### 처음 제품을 이해할 때

```text
Root README
→ Remake Documentation Hub
→ Quick Flow
→ Player 또는 DM Guide
```

### 구현 명세를 작성할 때

```text
CURRENT-WORK-ORDER
→ Quick Flow의 대상 사용자 구간
→ 관련 Player 또는 DM Guide
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 직접 인접 Guide
→ Guide가 연결한 Product·Architecture·System·UI·ADR
→ 기존 관련 Spec
→ Implementation Spec Template
→ 새 Spec
```

### 실제 구현을 시작할 때

```text
승인된 Implementation Spec
→ 관련 User Guide Acceptance Flow
→ 관련 Authority Documents
→ 현재 코드와 Test 조사
→ Production Implementation
```

## 6. 폴더별 README

각 주요 폴더의 `README.md`는 다음을 안내한다.

- 폴더가 다루는 범위와 문서 종류
- 현재 작업 순서로 돌아가는 링크
- 현재 권위 문서 또는 비권위 탐색 문서
- 추천 읽기 순서
- 관련 Main System Guide와 Implementation Spec
- `BLOCKED`, `UPDATE_REQUIRED`, `DISCONTINUED` 항목

상세 규칙을 README에 중복해 새 권위처럼 만들지 않는다.

## 7. Authority Tree

권위 문서 관계는 세 종류로 구분한다.

```text
Parent
→ 직접 상위 권위 문서

Children
→ 이 문서를 구체화하는 하위 권위 문서

References
→ 인접 시스템과 보조 근거
```

Guide는 Authority Tree의 Parent가 될 수 없다. Guide 링크는 탐색 Reference다.

User Guide도 Authority Tree의 Parent가 아니다. Implementation Spec은 User Guide를 Acceptance Flow로 참조하고 실제 계약 근거는 Product·Architecture·System·UI·ADR에서 찾는다.

## 8. Main System Guide 작성과 갱신

Main System Guide는 다음 조건을 통과한 뒤 작성한다.

1. 시스템 범위와 사용자 결과가 확정됨
2. 핵심 Architecture와 System·UI가 준비됨
3. 되돌리기 어려운 결정이 ADR로 기록됨
4. 중대한 `BLOCKED` 항목이 없음
5. Parent·Children·References가 정리됨
6. 구현 명세 관계 또는 작성 순서를 설명할 수 있음
7. Completion Audit이 작성 가능으로 판정함

Guide에서 금지하는 것:

- 새로운 제품 동작과 Architecture 원칙
- 새로운 API, Type, Schema와 Command
- 권위 문서에 없는 예외 처리
- 미정 사항의 임의 기본값

권위 의미가 바뀌면 관련 Guide를 `UPDATE_REQUIRED`로 되돌린다. 오탈자와 링크만 교정하고 의미가 같으면 `CURRENT`를 유지할 수 있다.

## 9. User Guide 작성과 갱신

User Guide는 확정된 사용자 결과를 쉬운 언어로 설명한다.

- Quick Flow는 전체 세션과 역할 흐름만 보여 준다.
- Player Guide는 Player·Observer에게 공개되는 조작과 상태만 설명한다.
- DM Guide는 준비, 진행, 비밀 정보, 편집, 복구와 Rollback을 설명한다.
- 내부 Type·Command·Transaction 이름을 사용자에게 필요한 경우가 아니면 사용하지 않는다.
- 미확정 키, 수치, 화면 위치와 자동화 수준을 발명하지 않는다.

권위 문서나 실제 Build가 사용자 경험을 바꾸면 관련 User Guide를 `UPDATE_REQUIRED`로 되돌린다.

## 10. Implementation Spec 작성과 갱신

Spec은 수직 사용자 결과 하나를 구현 가능한 계약으로 변환한다.

필수 연결:

```text
Quick Flow 구간
→ Player·DM Acceptance Flow
→ Authority Requirement
→ Module·Type·Command·Persistence 계약
→ Failure·Recovery·Migration
→ Test와 완료 기준
```

새 제품 또는 Architecture 결정이 필요하면 Spec 작성을 멈추고 권위 문서와 ADR을 먼저 수정한다.

## 11. 단계와 상태

현재 리메이크의 문서·구현 단계는 다음 순서를 사용한다.

```text
PLANNING
→ ARCHITECTURE_READY
→ SYSTEM_READY
→ GUIDE_CURRENT
→ USER_GUIDE_TARGET
→ DOCUMENT_LINKAGE_AUDITED
→ SPEC_READY
→ IMPLEMENTATION_READY
→ IMPLEMENTED
→ RELEASE_VERIFIED
```

- `GUIDE_CURRENT`: 권위 문서 관계와 경계를 탐색할 수 있음
- `USER_GUIDE_TARGET`: Player·DM 목표 경험과 Quick Flow가 준비됨
- `DOCUMENT_LINKAGE_AUDITED`: 활성 탐색 경로와 수명주기가 검증됨
- `SPEC_READY`: 현재 수직 Slice의 구현 계약이 승인됨
- `IMPLEMENTATION_READY`: Production 작업을 시작할 Gate를 통과함
- `RELEASE_VERIFIED`: 실제 Build와 사용성 테스트에서 User Guide가 검증됨

Guide가 기획을 완료시키거나 Spec이 Product 결정을 대신하지 않는다.

## 12. 파일 이름

기획 문서는 의미 있는 kebab-case 이름을 사용한다.

```text
systems/combat/encounter-initiative-and-turns.md
```

ADR은 전역 번호를 유지한다.

```text
decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md
```

Implementation Spec은 영역 안에서 3자리 번호를 사용한다.

```text
specs/combat/001-encounter-bootstrap.md
```

Main System Guide는 현재 구조처럼 영역별 README를 사용한다.

```text
guides/runtime/README.md
guides/combat/README.md
```

User Guide는 공통 Quick Flow와 역할별 README를 사용한다.

```text
user-guides/QUICK-FLOW.md
user-guides/player/README.md
user-guides/dm/README.md
```

## 13. 링크와 추적성 규칙

- 저장소 내부 문서는 상대 링크를 사용한다.
- Root와 Remake Hub는 Quick Flow, User Guide, Guide, Spec과 Work Order로 연결한다.
- Quick Flow는 Player·DM Guide로 연결한다.
- User Guide Hub는 Quick Flow와 두 역할 Guide를 모두 연결한다.
- Main System Guide Hub는 12개 Guide와 사용자 흐름 대응표를 제공한다.
- 각 Guide의 핵심 설명은 Authority Documents 절에서 근거를 찾을 수 있어야 한다.
- Spec은 Quick Flow·User Guide Acceptance Flow와 직접 Authority Documents를 모두 연결한다.
- 대체 문서는 새 문서와 보관 기록을 명확히 연결한다.
- 파일 이동은 원문 보존 여부 결정, 링크 갱신, 대상 존재 확인, 활성 경로 처리 순서로 진행한다.
- 같은 권위 본문을 활성 경로와 Archive에 장기간 중복 유지하지 않는다.

## 14. 수명주기와 제외

문서 폐기·대체·보관은 [`DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md`](DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)를 따른다.

다음 문서는 현재 권위와 추천 읽기 순서에서 제외한다.

- `SUPERSEDED`
- `DISCONTINUED`
- `ARCHIVED`
- 최신 확정 범위와 충돌하는 오래된 Draft

구현 명세 단계로 내려가기 직전에 활성 경로에서 이러한 문서가 권위 근거로 남아 있지 않은지 감사한다.

## 15. 문서 검증

문서 단계 완료 전 다음을 확인한다.

- 상대 링크 대상 존재
- 현재 Work Order와 Hub의 단계 표시 일치
- User Guide·Guide·Spec의 책임 방향 일치
- `DISCONTINUED` 문서가 Authority 목록에서 제외됨
- 완료 Audit과 Archive 기록 연결
- GitHub Actions `Validate remake documentation` 성공

자동 검증 성공은 의미적 연결과 권위 방향 검사를 대신하지 않는다.