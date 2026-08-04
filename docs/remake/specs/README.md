# 구현 명세

- 상태: ACTIVE
- 문서 종류: Implementation Spec Index
- 현재 단계: `IN_PROGRESS`
- 현재 수직 Slice: `FIRST SESSION WALKING SKELETON`
- 선행 단계:
  - Runtime Architecture `COMPLETE`
  - Main System Guides `COMPLETE`
  - Player·DM User Guides와 Quick Flow `COMPLETE`
  - 구현 명세 전 최종 문서 연결 감사 `COMPLETE`

확정된 기획과 목표 사용자 경험을 실제 Module, Type, Command, Network, Persistence, Migration, Diagnostics와 Test 계약으로 변환한다.

## 현재 작업

```text
First Slice 구현 기준선·공통 계약 조사
→ runtime/001 Core Authority Identity·Version·Result Spec
```

- 세부 Spec 작업 순서: [`CURRENT-SPEC-WORK-ORDER.md`](CURRENT-SPEC-WORK-ORDER.md)
- 현재 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 최종 문서 연결 감사: [`../audits/pre-implementation-document-linkage-audit.md`](../audits/pre-implementation-document-linkage-audit.md)
- Shared Spec 재검토: [`../audits/shared-spec-001-002-revalidation-audit.md`](../audits/shared-spec-001-002-revalidation-audit.md)
- Implementation Spec Template: [`../templates/implementation-spec-template.md`](../templates/implementation-spec-template.md)

## 첫 수직 Slice

### First Session Walking Skeleton

Player:

```text
세션 참가
→ Character 선택
→ Ready
→ Scene Entry Essential 동기화
→ Token 선택
→ 클릭 이동
→ 연결 종료
→ 재접속
→ 같은 권위 상태로 복귀
```

DM:

```text
Campaign·Scene·Player 상태 확인
→ User Ready와 Client Ready 확인
→ 세션 시작
→ Scene 입장과 이동 확인
→ Disconnect 상태 확인
→ 재접속·현재 상태 복귀 확인
```

이 Slice의 명세 순서:

```text
Core Authority Identity·Version·Result
→ Command·Projection Protocol
→ Campaign Join·Character Selection·Ready
→ Scene Entry Essential·Controlled Actor Bootstrap
→ Click Movement·Position Projection
→ Snapshot·Journal·Reconnect
→ Deterministic·Roblox Integration Scenario
→ Slice 통합 감사
```

세부 파일명과 Gate는 [`CURRENT-SPEC-WORK-ORDER.md`](CURRENT-SPEC-WORK-ORDER.md)를 따른다.

## Spec 작성 전 읽기 순서

```text
CURRENT-SPEC-WORK-ORDER
→ Quick Flow의 대상 사용자 구간
→ 관련 Player 또는 DM 상세 Guide
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 직접 인접 Guide
→ Guide가 연결한 Product·Architecture·System·UI·ADR
→ 기존 관련 Spec과 재검토 감사
→ 실제 Code·Schema·Test 조사
→ Implementation Spec Template
→ 새 수직 Implementation Spec
```

연결 문서:

- [`한눈에 보는 세션 흐름`](../user-guides/QUICK-FLOW.md)
- [`Player·DM User Guide Hub`](../user-guides/README.md)
- [`Main System Guide Hub`](../guides/README.md)
- [`Product Index`](../product/README.md)
- [`Architecture Index`](../architecture/README.md)
- [`Systems Index`](../systems/README.md)
- [`UI Index`](../ui/README.md)
- [`ADR Index`](../decisions/README.md)

## 문서 역할

```text
Quick Flow·User Guide
→ Acceptance Flow와 사용자가 보는 결과

Main System Guide
→ 직접 Authority Documents를 찾는 탐색 경로

Product·Architecture·System·UI·ADR
→ 구현 계약의 직접 근거

Implementation Spec
→ 실제 코드·저장·Network·Test 계약
```

User Guide와 Main System Guide를 Type·Schema·Command의 권위 원본으로 사용하지 않는다.

## 작성 조건

Spec은 다음 조건을 모두 만족할 때만 `준비 완료`로 전환한다.

- 관련 기획의 준비도가 `READY` 또는 감사에서 허용한 `READY_WITH_DEFAULTS`
- Quick Flow와 Player·DM Acceptance Flow가 연결됨
- Runtime Foundation과 Domain Guide를 통해 직접 Authority Documents가 확인됨
- 실제 Code·Schema·Test 조사 결과가 기록됨
- 새 Product·Architecture 결정이 필요하지 않음
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 충돌 Draft가 근거에서 제외됨
- 문서 검증 Workflow가 성공함

현재 GitHub 코드 검색에서 구현 파일이 확인되지 않았으므로 실제 저장소 구현 경로를 추측해 확정하지 않는다. 구현 트리 또는 Greenfield 상태가 확인되기 전에는 제안 경로를 `신규 제안`으로 표시하고 Spec을 `초안`으로 유지한다.

## Spec 필수 계약

- 사용자 목표와 Player·DM Acceptance Flow
- 직접 Authority Requirement 추적성
- Package·Module·Service 책임
- Luau Type와 Versioned Schema
- Registry·Compiler·Provider Interface
- Command·Read Request·Receipt·Terminal Result·Stable Error Code
- Network Envelope·Projection Segment·Gap·Resync
- Persistence·Journal·Migration·Recovery·Rollback
- Ordering Key·Reservation·Transaction·Outbox·Projection Barrier
- Trace Span·Budget·Health Probe·Support Reference
- 사용자 화면의 성공·대기·거부·재시도·복구 상태
- Deterministic Fixture·Scenario·Fault Injection·Negative Disclosure
- 실제 Roblox Client·Server Integration Boundary와 Failure Isolation

세부 구조는 [`Implementation Spec Template`](../templates/implementation-spec-template.md)을 따른다.

## 파일 규칙

```text
specs/<영역>/<3자리 번호>-<기능명>.md
```

First Slice 예정 파일:

```text
runtime/001-core-authority-identity-version-and-result.md
networking/001-command-projection-and-resync-protocol.md
session/001-campaign-join-character-selection-and-ready.md
scene/001-scene-entry-essential-and-controlled-actor-bootstrap.md
exploration/001-click-movement-plan-execution-and-reconciliation.md
persistence/001-first-slice-snapshot-journal-and-reconnect.md
testing/001-join-move-disconnect-reconnect.md
```

하나의 Spec은 독립적으로 구현·검증·Rollback 가능한 사용자 결과 또는 그 결과에 꼭 필요한 최소 Foundation을 다룬다.

## 현재 명세

### Shared — `UPDATE_REQUIRED`

- [`Shared Spec Index`](shared/README.md)
- [`001. Recipe Step Runtime Foundation`](shared/001-recipe-step-runtime-foundation.md)
- [`002. Standard Recipe Step Handler Contracts`](shared/002-standard-step-handler-contracts.md)
- [`최신 재검토 감사`](../audits/shared-spec-001-002-revalidation-audit.md)

최종 판정:

```text
001 → UPDATE_REQUIRED
002 → UPDATE_REQUIRED
```

두 문서는 폐기하지 않지만 First Session Walking Skeleton의 선행 조건으로 사용하지 않는다. Character Action·Rules Slice에서 최신 RuleExecution·Transaction·Outbox·Projection·Recovery·Diagnostics·Simulation 계약에 맞춰 전체 갱신한다.

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

- 승인된 Spec 없이 Production Code 작성
- 조사하지 않은 최종 Module 경로와 API 확정
- 첫 Slice와 무관한 전면 Foundation 설계
- 측정 없이 Budget·Timeout·Cache 수치 확정
- Test-only Authorization·Mutation 우회 계약
- User Guide·Main Guide를 Authority로 승격
- Quick Flow에 없는 새 사용자 동작을 Spec에서 몰래 추가