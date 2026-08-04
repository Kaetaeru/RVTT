# 구현 명세

- 상태: QUEUED
- 문서 종류: Implementation Spec Index
- 현재 단계: `WAITING_FOR_DOCUMENT_LINKAGE_AUDIT`
- 선행 단계:
  - Main System Guides `COMPLETE`
  - Player·DM User Guides와 Quick Flow `COMPLETE`
  - 구현 명세 전 최종 문서 연결 감사 `IN_PROGRESS`

확정된 기획과 목표 사용자 경험을 실제 Module, Type, Command, Network, Persistence, Migration, Diagnostics와 Test 계약으로 변환한다.

현재 최종 문서 연결 감사가 끝날 때까지 새 Spec Work Order와 새 Implementation Spec을 시작하지 않는다.

## 현재 작업 기준

- 단일 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 한눈에 보는 세션 흐름: [`../user-guides/QUICK-FLOW.md`](../user-guides/QUICK-FLOW.md)
- Player·DM User Guide: [`../user-guides/README.md`](../user-guides/README.md)
- Main System Guide 허브: [`../guides/README.md`](../guides/README.md)
- Implementation Spec Template: [`../templates/implementation-spec-template.md`](../templates/implementation-spec-template.md)
- 문서 구조와 작성 가이드: [`../DOCUMENT-GUIDE.md`](../DOCUMENT-GUIDE.md)
- 문서 수명주기: [`../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)

## Spec 작성 전 읽기 순서

```text
CURRENT-WORK-ORDER
→ Quick Flow의 대상 사용자 구간
→ 관련 Player 또는 DM 상세 Guide
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 직접 인접 Guide
→ Guide가 연결한 Product·Architecture·System·UI·ADR
→ 기존 관련 Spec
→ Implementation Spec Template
→ 새 Implementation Spec
```

역할 구분:

```text
Quick Flow·User Guide
→ Acceptance Flow와 사용자가 보는 결과

Main System Guide
→ 직접 권위 문서를 찾는 탐색 경로

Product·Architecture·System·UI·ADR
→ 구현 계약의 직접 근거

Implementation Spec
→ 실제 코드·저장·Network·Test 계약
```

User Guide와 Main System Guide를 Type·Schema·Command의 권위 원본으로 사용하지 않는다.

## 사용자 흐름 전달 기준

모든 수직 Slice는 Quick Flow의 한 구간을 하나 이상의 Acceptance Scenario로 연결한다.

### 첫 Player 흐름 후보

```text
세션 참가
→ 캐릭터 선택과 준비 완료
→ 장면 입장
→ 토큰 선택
→ 탐험 이동
→ 연결이 끊기면 다시 참가
→ 현재 진행 상황으로 복귀
```

### 첫 DM 흐름 후보

```text
캠페인과 시작 장면 준비
→ 플레이어 준비 상태 확인
→ 세션 시작
→ 탐험 진행
→ 필요한 대상과 정보 조정
→ 현재 상태 확인과 저장
```

첫 수직 Slice는 별도 `CURRENT-SPEC-WORK-ORDER.md`에서 권위 의존성 검토 후 확정한다.

## 작성 조건

Spec은 다음 조건을 모두 만족할 때만 작성한다.

- 관련 기획의 준비도가 `READY` 또는 감사에서 허용한 `READY_WITH_DEFAULTS`
- Quick Flow·User Guide Acceptance Flow가 연결됨
- Runtime Foundation과 Domain Guide를 통해 직접 Authority Documents가 확인됨
- 새 Product·Architecture 결정이 필요하지 않음
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 충돌하는 오래된 Draft가 근거에서 제외됨

새 결정이 필요하면 Spec을 멈추고 관련 Product·Architecture·ADR을 먼저 수정한다.

## Spec 필수 계약

- Package·Module·Service 책임
- Luau Type와 Versioned Schema
- Registry·Compiler·Provider Interface
- Command·Read Request·Result·Stable Error Code
- Network Envelope·Projection Segment·Resync
- Persistence·Journal·Migration·Rollback
- Ordering Key·Reservation·Transaction·Outbox·Projection Barrier
- Trace Span·Budget·Health Probe
- Player·DM 화면의 성공·대기·거부·재시도·복구 상태
- Deterministic Fixture·Scenario·Acceptance Test
- 실제 Roblox Integration Boundary와 Failure Isolation

세부 절은 [`Implementation Spec Template`](../templates/implementation-spec-template.md)을 따른다.

## 파일 규칙

```text
specs/<영역>/<3자리 번호>-<기능명>.md
```

예:

```text
session/001-session-join-and-ready.md
scene/001-scene-entry-bootstrap.md
exploration/001-click-movement.md
```

하나의 Spec은 독립적으로 구현·검증·Rollback 가능한 수직 사용자 결과 하나를 다룬다.

## 현재 명세

### Shared — `REVIEW_REQUIRED`

- [`Shared Spec Index`](shared/README.md)
- [`001. Recipe Step Runtime Foundation`](shared/001-recipe-step-runtime-foundation.md)
- [`002. Standard Recipe Step Handler Contracts`](shared/002-standard-step-handler-contracts.md)

두 문서는 Main System Guide와 User Guide 완료 전에 작성됐다. 다음 Spec Work Order에서 최신 RuleExecution·Transaction·Recovery·Diagnostics·Simulation·Extension 계약과 다시 대조한다.

재검토 판정:

```text
CURRENT
UPDATE_REQUIRED
SUPERSEDED
```

재검토 전에는 두 문서를 Production Code의 승인된 근거로 사용하지 않는다.

## Spec 완료 조건

- 직접 Authority Documents와 충돌하지 않음
- Quick Flow와 Player·DM Acceptance Flow가 연결됨
- 책임·입출력·권한·실패·복구 경계가 명확함
- Source·Build·State·Projection·Presentation이 분리됨
- Client Intent와 Server Authority 검증이 분리됨
- Version·Migration·Deprecation·Recovery·Rollback이 정의됨
- Transaction·Outbox·Projection Barrier가 필요한 범위에서 정의됨
- Diagnostics·Budget·Error·Health가 정의됨
- Deterministic Scenario와 Roblox Integration Test가 정의됨
- 관련 User Guide·Main Guide의 변경 영향이 확인됨
- 문서 검증 Workflow가 성공함

## 현재 비목표

- 최종 문서 연결 감사 완료 전 새 Spec 착수
- 승인된 Spec 없이 Production Code 작성
- 조사하지 않은 최종 Module 경로와 API 확정
- 측정 없이 Budget·Timeout·Cache 수치 확정
- Test-only Authorization 우회 계약
- User Guide·Main Guide를 Authority로 승격
- Quick Flow에 없는 새 사용자 동작을 Spec에서 몰래 추가

감사 완료 후 첫 작업은 `CURRENT-SPEC-WORK-ORDER.md` 작성, Shared Spec 001·002 재검토와 첫 수직 Slice 확정이다.