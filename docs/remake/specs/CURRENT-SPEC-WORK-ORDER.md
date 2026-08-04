# RVTT Implementation Specs 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Implementation Spec Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Spec Hub: [`README.md`](README.md)
- 작성 Template: [`../templates/implementation-spec-template.md`](../templates/implementation-spec-template.md)
- 선행 완료 감사: [`구현 명세 전 최종 문서 연결 감사`](../audits/pre-implementation-document-linkage-audit.md)

이 문서는 Implementation Specs 단계의 **단일 세부 작업 순서 기준**이다.

## 1. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 항목을 먼저 완료한다.
2. 하나의 Spec은 구현·검증·복구 가능한 사용자 결과 또는 그 결과에 꼭 필요한 최소 Foundation만 다룬다.
3. Foundation Spec은 첫 수직 Slice에 필요한 계약까지만 정의하며 미래 전체 Runtime을 미리 구현하도록 요구하지 않는다.
4. Quick Flow와 User Guide는 Acceptance Flow를 제공하고, Product·Architecture·System·UI·ADR은 구현 계약의 직접 근거가 된다.
5. 실제 코드·Schema·Test 구조를 조사하지 못한 Spec은 `준비 완료`로 올리지 않는다.
6. 새 Product 동작이나 Architecture 결정이 필요하면 Spec 작성을 중단하고 권위 문서를 먼저 갱신한다.
7. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 충돌 Draft를 근거로 사용하지 않는다.
8. 각 Spec은 문서 검증 성공과 변경 영향 확인 후에만 `DONE` 처리한다.
9. Production Code는 현재 수직 Slice의 관련 Spec이 모두 준비 완료된 뒤 별도 사용자 요청으로 시작한다.

상태 값:

```text
IN_PROGRESS
QUEUED
BLOCKED
DONE
DEFERRED
```

## 2. 첫 수직 Slice

### 이름

```text
First Session Walking Skeleton
```

### Player Acceptance Flow

```text
세션 참가
→ 허용된 Character 선택
→ Ready
→ DM 시작 승인 대기
→ Scene Entry Essential 동기화
→ 자신의 Token 선택
→ 목적지를 클릭해 이동
→ 권위 위치 확인
→ 연결 종료
→ 다시 참가
→ 현재 Character·Scene·Token 위치로 복귀
```

### DM Acceptance Flow

```text
Campaign과 시작 Scene 확인
→ Player Membership·Role·Owner·Control 확인
→ Player Ready와 Client Ready 구분 확인
→ 세션 시작
→ Player의 Scene 입장과 Token 이동 확인
→ 연결 종료 상태 확인
→ 재접속 후 같은 권위 상태로 복귀한 것을 확인
```

### 완료 결과

- Player와 DM이 Quick Flow의 세션 시작·첫 탐험·재접속 구간을 실제로 검증할 수 있다.
- Character Owner, Runtime Controller, Session Role과 공개 범위가 분리된다.
- Scene Entry Essential과 Controlled Actor Essential 준비 전 Gameplay Command가 거부된다.
- Client가 목적지 Intent를 제출하고 Server가 경로·점유·Revision을 검증해 위치를 Commit한다.
- Commit된 위치는 Projection, 저장, 재접속과 Full Resync에서 동일하게 복원된다.
- Hidden Authority와 DM-only 정보가 Player Projection·오류·진단에 포함되지 않는다.

### 명시적 비범위

- WASD Token 이동
- Interaction·Fog·Search·Spell·Attack
- Encounter·Initiative·Turn
- Full Scene Editor와 일반 DM Authoring UI
- Rules Recipe Runtime과 Standard Step 구현
- 최종 성능 수치 확정

## 3. 현재 작업 순서

| 순서 | 상태 | 작업 | 산출물 | 완료 조건 |
|---:|---|---|---|---|
| 1 | `DONE` | Spec 단계 Work Order 수립 | 이 문서 | 첫 Slice, 의존 순서, Gate와 후속 Slice가 연결됨 |
| 2 | `DONE` | 기존 Shared Spec 001·002 재검토 | [`Shared Spec 001·002 재검토 감사`](../audits/shared-spec-001-002-revalidation-audit.md) | `CURRENT·UPDATE_REQUIRED·SUPERSEDED` 판정과 후속 위치 확정 |
| 3 | `IN_PROGRESS` | First Slice 구현 기준선·공통 계약 조사 | `runtime/001` 작성 준비 기록 | 실제 저장소 구현 경로 또는 Greenfield 상태, 재사용·대체 범위가 확인됨 |
| 4 | `QUEUED` | Core Authority Identity·Version·Result Spec | `runtime/001-core-authority-identity-version-and-result.md` | 첫 Slice에 필요한 ID·Epoch·Revision·Result·Error 계약만 준비 완료 |
| 5 | `QUEUED` | Command·Projection Protocol Spec | `networking/001-command-projection-and-resync-protocol.md` | Command Receipt·Result, Projection Snapshot·Event·Gap·Resync 계약 준비 완료 |
| 6 | `QUEUED` | Campaign Join·Character Selection·Ready Spec | `session/001-campaign-join-character-selection-and-ready.md` | Membership·Role·Owner·Control·User Ready·Client Ready 흐름 준비 완료 |
| 7 | `QUEUED` | Scene Entry Essential·Controlled Actor Bootstrap Spec | `scene/001-scene-entry-essential-and-controlled-actor-bootstrap.md` | Published Build Ref, Runtime Presence, Essential Activation과 Gameplay Gate 준비 완료 |
| 8 | `QUEUED` | Click Movement·Position Projection Spec | `exploration/001-click-movement-plan-execution-and-reconciliation.md` | 목적지 Intent부터 Plan·Execution·Commit·Projection까지 준비 완료 |
| 9 | `QUEUED` | Snapshot·Journal·Reconnect Resume Spec | `persistence/001-first-slice-snapshot-journal-and-reconnect.md` | 위치·Control·Scene·Projection Cursor의 저장·복구·Full Resync 준비 완료 |
| 10 | `QUEUED` | Walking Skeleton Deterministic·Roblox Integration Spec | `testing/001-join-move-disconnect-reconnect.md` | 정상·권한·Gap·중복·Disconnect·Restart·Disclosure Scenario 준비 완료 |
| 11 | `QUEUED` | First Slice Spec 통합 감사 | `audits/first-session-walking-skeleton-spec-audit.md` | 모든 Spec 추적성·상태·Migration·Diagnostics·Test·문서 검증 통과 |

## 4. First Slice 의존 관계

```text
Core Identity·Version·Result
→ Command·Projection Protocol
→ Membership·Role·Owner·Control·Ready
→ Scene Entry Essential·Controlled Actor Bootstrap
→ Click Movement·Position Commit·Projection
→ Snapshot·Journal·Reconnect
→ Deterministic·Roblox Integration Scenario
→ First Slice Spec Audit
```

수직 흐름을 오래 지연시키는 전면 Foundation 구현을 피한다.

```text
각 Foundation의 첫 구현 범위
= First Session Walking Skeleton이 실제로 요구하는 필드·상태·오류·검증
```

후속 Slice가 새 요구를 추가하면 Versioned Contract와 Migration으로 확장한다.

## 5. Spec별 직접 Guide·Authority 묶음

### Runtime·Protocol Foundation

- [`Runtime Foundation Guide`](../guides/runtime/README.md)
- [`Session Guide`](../guides/session/README.md)
- [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
- [`Networking Command, Event와 Client Synchronization`](../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Domain Event, Outbox, Subscription과 Projection`](../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery`](../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

### Session Join·Ready·Reconnect

- [`Player Guide`](../user-guides/player/README.md) — 빠른 시작, Character·Control, 재접속
- [`DM Guide`](../user-guides/dm/README.md) — 세션 준비, Lobby와 시작
- [`Session Guide`](../guides/session/README.md)
- [`캠페인 로비·중도 참여·소유권·제어권`](../systems/session/campaign-lobby-hot-join-ownership-and-control.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Persistence와 Session Recovery`](../architecture/persistence-and-session-recovery-model.md)
- ADR-0042, ADR-0049, ADR-0059, ADR-0063, ADR-0070, ADR-0083

### Scene Entry·Movement

- [`Scene Guide`](../guides/scene/README.md)
- [`Exploration Guide`](../guides/exploration/README.md)
- [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
- [`Scene Streaming, Client Interest와 Ready Activation`](../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Spatial Query Engine과 Provider`](../architecture/spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation, Path Planning과 Movement Execution`](../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Exploration 실시간 이동, 행동과 Encounter 전환`](../architecture/exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md)
- ADR-0048, ADR-0055, ADR-0056, ADR-0058, ADR-0060, ADR-0076

### Diagnostics·Test

- [`Diagnostics Guide`](../guides/diagnostics/README.md)
- [`Diagnostics, Observability, Correlated Trace와 Incident`](../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation, Scenario와 Test Harness`](../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- ADR-0084, ADR-0085

## 6. First Slice 공통 Gate

모든 Spec은 다음을 포함한다.

- Quick Flow와 Player·DM Acceptance Flow
- 직접 Authority Requirement 표
- 실제 기존 코드·Schema·Test 조사 결과
- Source·Build·State·Projection·Presentation 분리
- Client Intent와 Server Authority 검증
- AuthorityEpoch·ConnectionEpoch·Revision·Incarnation 처리
- Command Receipt와 Terminal Result의 분리
- Ordering Key·Reservation·Transaction·Outbox·Projection Barrier
- Version·Migration·Deprecation·Last Known Good
- Snapshot·Journal·Reconnect·Recovery·Rollback 영향
- Correlated Trace·Stable Error·Support Reference·Health
- 사용자 Loading·Waiting·Denied·Retrying·Resync 상태
- Deterministic Scenario·Fault Injection·Negative Disclosure
- 실제 Roblox Client·Server 통합 경계
- 측정 전 수치 기본값을 확정하지 않는 원칙

## 7. Shared Spec 001·002 배치

재검토 결과 두 문서는 모두 `UPDATE_REQUIRED`다.

```text
Shared 001·002
→ First Session Walking Skeleton의 선행 조건 아님
→ Rules·Action Slice에서 최신 RuleExecution·Transaction·Event·Projection 계약에 맞춰 갱신
```

갱신 순서:

```text
Core Authority·Protocol·Persistence 기반 완료
→ Ruleset Policy·RuleExecution Adapter Spec
→ Shared 001 Recipe Definition·Registry·Compiler 갱신
→ Shared 002 Step Handler Provider·Invoker 갱신
→ Roll·PendingEffect·Guided·Presentation Step Specs
→ Rules Slice 통합 감사
```

기존 파일명은 우선 유지하고, 실제 책임 분할 결과가 명확해질 때만 대체 Spec과 Migration 관계를 만든다.

## 8. 후속 Slice 순서

First Session Walking Skeleton 완료 뒤 다음 순서로 진행한다.

### Slice 2 — Exploration Interaction

```text
Selection·Focus·Input Context
→ Door·Container·Item Interaction
→ DM Adjudication
→ Fog·Knowledge·Disclosure
→ Reconnect·Concurrency·Security
```

### Slice 3 — Character Action·Rules

```text
Ruleset Policy·Character Capability
→ RuleExecution Orchestrator Adapter
→ Shared Recipe Runtime 001·002 갱신
→ Roll·Effect·Guided Input
→ Action·Spell·Item 사용
```

### Slice 4 — Encounter

```text
Encounter Proposal
→ Initiative·Timeline·Turn·Opportunity
→ Movement·Action·Reaction
→ Damage·Death·Objective·Time
→ Rollback
```

### Slice 5 — Character·Inventory·Downtime

```text
Character Build·Persistent State
→ Inventory·Equipment·World Presence
→ Rest·Level Up·Spell Preparation·Downtime
```

### Slice 6 — DM Authoring·Journal·Extension

```text
Scene Authoring·Compile·Publish
→ Quick Edit·Live Patch
→ Journal·Anchor·Search
→ Content Pack·Trusted Extension·Presentation
```

각 Slice는 별도 세부 Work Order 또는 이 문서의 갱신으로 확정한다.

## 9. 완료 판정

Implementation Specs 단계 전체 완료 조건:

- 계획된 수직 Slice의 Spec 상태가 모두 `준비 완료` 또는 명시적으로 `DEFERRED`
- 기존 Shared Spec 001·002의 `UPDATE_REQUIRED` 해소
- 각 Slice별 통합 감사와 문서 검증 성공
- Production Implementation 순서와 Migration 경계 확정
- User Guide·Main System Guide 변경 영향 재검토
- 사용자의 명시적 Production Implementation 시작 요청

## 10. 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | First Session Walking Skeleton을 첫 수직 Slice로 확정하고 Runtime·Protocol·Session·Scene·Movement·Persistence·Testing Spec 순서를 수립했다. |
| 2026-08-05 | Shared Spec 001·002를 `UPDATE_REQUIRED`로 판정하고 Rules Slice로 이동했다. |