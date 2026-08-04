# RVTT Implementation Specs 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Implementation Spec Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 전체 Slice Roadmap: [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)
- Roadmap 완전성 감사: [`Implementation Slice Roadmap 완전성 감사`](../audits/implementation-slice-roadmap-completeness-audit.md)
- Spec Hub: [`README.md`](README.md)
- 작성 Template: [`../templates/implementation-spec-template.md`](../templates/implementation-spec-template.md)

이 문서는 현재 Implementation Slice 내부의 **단일 세부 작업 순서 기준**이다. 전체 Slice의 범위와 장기 순서는 `SLICE-ROADMAP.md`가 소유한다.

## 1. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 항목을 먼저 완료한다.
2. 현재 Slice 밖의 Production Code나 전면 Foundation을 미리 시작하지 않는다.
3. 하나의 Spec은 사용자 결과 또는 그 결과에 필요한 최소 Foundation만 다룬다.
4. Quick Flow와 User Guide는 Acceptance Flow, Product·Architecture·System·UI·ADR은 직접 구현 근거다.
5. 실제 Code·Schema·Test 구조를 조사하지 못한 Spec은 `준비 완료`로 올리지 않는다.
6. 새 제품 동작이나 Architecture 결정이 필요하면 Spec을 중단하고 권위 문서를 먼저 갱신한다.
7. 각 Spec은 Migration·Recovery·Diagnostics·Security·Deterministic Test를 포함한다.
8. 문서 검증과 Slice Completion Audit 전에는 다음 Slice로 전환하지 않는다.
9. Production Code는 현재 Slice Spec이 모두 준비 완료되고 사용자가 명시적으로 요청한 뒤 시작한다.

상태 값:

```text
IN_PROGRESS
QUEUED
BLOCKED
DONE
DEFERRED
```

## 2. 전체 Slice 정의 상태

```text
16개 Implementation Slice 정의
→ DONE

12개 Main Guide·Quick Flow 범위 배정
→ COMPLETE

현재 Slice
→ 01 First Session Walking Skeleton

다음 Slice
→ 02 Core Rules Kernel
```

- 전체 정의: [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)
- 완전성 근거: [`implementation-slice-roadmap-completeness-audit.md`](../audits/implementation-slice-roadmap-completeness-audit.md)

## 3. 현재 Slice — First Session Walking Skeleton

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
→ Membership·Role·Owner·Control 확인
→ User Ready와 Client Ready 구분
→ 세션 시작
→ Player Scene 입장·Token 이동 확인
→ Disconnect 확인
→ Reconnect 후 같은 권위 상태 복귀 확인
```

### 완료 결과

- Character Owner, Runtime Controller, Session Role과 공개 범위가 분리된다.
- Scene Entry Essential과 Controlled Actor Essential 준비 전 Gameplay Command가 거부된다.
- Client는 목적지 Intent만 제출하고 Server가 Path·Occupancy·Revision을 검증한다.
- 위치 Commit은 Projection·Snapshot·Journal·Reconnect에서 같은 의미를 가진다.
- DM-only·Hidden Authority가 Player Projection·Error·Diagnostic에 포함되지 않는다.

### 비범위

- WASD Token 이동
- Interaction·Fog·Search
- Rules Recipe·Attack·Spell
- Encounter·Turn·Reaction
- Character 생성·성장
- 일반 Scene Editor

## 4. 현재 작업 순서

| 순서 | 상태 | 작업 | 산출물 | 완료 조건 |
|---:|---|---|---|---|
| 1 | `DONE` | 전체 Slice Roadmap 정의 | [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md) | 16개 Slice와 공통 레일 확정 |
| 2 | `DONE` | Slice Roadmap 완전성 감사 | [`완전성 감사`](../audits/implementation-slice-roadmap-completeness-audit.md) | Quick Flow·12개 Guide·최종 Content 범위 배정 |
| 3 | `DONE` | Shared Spec 001·002 재검토 | [`재검토 감사`](../audits/shared-spec-001-002-revalidation-audit.md) | 둘 다 `UPDATE_REQUIRED`, Slice 02로 배치 |
| 4 | `DONE` | First Slice 구현 기준선 조사 | `runtime/001` §4 | GitHub Branch에서 Production Source Tree 미확인과 제안 경로 정책 기록 |
| 5 | `IN_PROGRESS` | Core Authority Identity·Version·Result Spec | [`runtime/001`](runtime/001-core-authority-identity-version-and-result.md) | ID·Epoch·Revision·Result·Error 계약 완성; Source Tree 확인 전 `초안·BLOCKED` 유지 |
| 6 | `QUEUED` | Command·Projection Protocol Spec | `networking/001-command-projection-and-resync-protocol.md` | Receipt·Result·Snapshot·Event·Gap·Resync 계약 |
| 7 | `QUEUED` | Campaign Join·Character Selection·Ready Spec | `session/001-campaign-join-character-selection-and-ready.md` | Membership·Role·Owner·Control·Ready 계약 |
| 8 | `QUEUED` | Scene Entry Essential·Controlled Actor Bootstrap Spec | `scene/001-scene-entry-essential-and-controlled-actor-bootstrap.md` | Published Build·Runtime Presence·Essential Activation 계약 |
| 9 | `QUEUED` | Click Movement·Position Projection Spec | `exploration/001-click-movement-plan-execution-and-reconciliation.md` | Intent→Plan→Execution→Commit→Projection 계약 |
| 10 | `QUEUED` | Snapshot·Journal·Reconnect Resume Spec | `persistence/001-first-slice-snapshot-journal-and-reconnect.md` | 위치·Control·Scene·Cursor 저장·복구 계약 |
| 11 | `QUEUED` | Deterministic·Roblox Integration Spec | `testing/001-join-move-disconnect-reconnect.md` | 정상·권한·Gap·중복·Restart·Disclosure Scenario |
| 12 | `QUEUED` | Slice 01 Spec 통합 감사 | `audits/first-session-walking-skeleton-spec-audit.md` | 추적성·Migration·Diagnostics·Test·문서 검증 통과 |

## 5. Slice 01 의존 관계

```text
Core Identity·Version·Result
→ Command·Projection Protocol
→ Membership·Role·Owner·Control·Ready
→ Scene Entry Essential·Controlled Actor Bootstrap
→ Click Movement·Position Commit·Projection
→ Snapshot·Journal·Reconnect
→ Deterministic·Roblox Integration
→ Slice Completion Audit
```

각 Foundation의 범위는 First Session Walking Skeleton이 실제로 요구하는 계약까지다. 후속 요구는 Versioned Contract와 Migration으로 확장한다.

## 6. 직접 Guide·Authority 묶음

### Runtime·Protocol

- [`Runtime Foundation Guide`](../guides/runtime/README.md)
- [`Session Guide`](../guides/session/README.md)
- [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
- [`Networking Command, Event와 Client Synchronization`](../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Domain Event와 Projection Runtime`](../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)

### Session·Reconnect

- [`Player Guide`](../user-guides/player/README.md)
- [`DM Guide`](../user-guides/dm/README.md)
- [`캠페인 로비·중도 참여·소유권·제어권`](../systems/session/campaign-lobby-hot-join-ownership-and-control.md)
- [`Session Play Mode·Context·Transition`](../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Persistence와 Session Recovery`](../architecture/persistence-and-session-recovery-model.md)

### Scene·Movement

- [`Scene Guide`](../guides/scene/README.md)
- [`Exploration Guide`](../guides/exploration/README.md)
- [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
- [`Scene Streaming·Ready Activation`](../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Runtime Object Lifecycle`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Spatial Query`](../architecture/spatial-query-engine-and-provider-contract.md)
- [`Navigation·Movement Execution`](../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)

### Diagnostics·Test

- [`Diagnostics Guide`](../guides/diagnostics/README.md)
- [`Diagnostics·Observability Runtime`](../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation·Test Harness`](../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

## 7. 공통 Spec Gate

모든 Slice 01 Spec은 다음을 포함한다.

- Player·DM Acceptance Flow
- 직접 Authority Requirement 추적표
- 기존 Code·Schema·Test 조사 결과
- Source·Build·State·Projection·Presentation 분리
- Client Intent와 Server 재검증
- AuthorityEpoch·ConnectionEpoch·Revision·Incarnation
- Receipt와 Terminal Result 분리
- Ordering·Reservation·Transaction·Outbox·Projection Barrier
- Version·Migration·Last Known Good·Rollback
- Snapshot·Journal·Reconnect·Restart
- Trace·Stable Error·Health·Support Reference
- Loading·Waiting·Denied·Retrying·Resync 상태
- Deterministic·Fault·Negative Disclosure·Roblox Integration
- 측정 전 수치 기본값을 확정하지 않는 원칙

## 8. Shared Spec 001·002

재검토 결과:

```text
001 Recipe Step Runtime Foundation
→ UPDATE_REQUIRED

002 Standard Step Handler Contracts
→ UPDATE_REQUIRED
```

두 문서는 Slice 01의 선행 조건이 아니다. Roadmap의 Slice 02 `Core Rules Kernel`에서 다음 순서로 갱신한다.

```text
Core Authority·Protocol·Persistence 기반
→ Ruleset Policy·RuleExecution Adapter
→ Shared 001 Recipe Definition·Registry·Compiler
→ Shared 002 Step Handler Provider·Invoker
→ D20 Test·Roll·PendingEffect·Guided Input
→ 대표 Check·Attack·Save·Damage 수직 검증
```

## 9. Slice 전환 Gate

Slice 02로 넘어가기 전에:

- Slice 01 관련 Spec이 모두 `준비 완료` 또는 명시적으로 `DEFERRED`
- Slice 01 Spec Completion Audit 완료
- 문서 검증 성공
- 관련 Guide와 User Guide 영향 확인
- Production 구현 여부와 관계없이 Slice 01 계약이 닫힘

전체 다음 순서는 [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)를 따른다.

## 10. 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | 16개 전체 Slice Roadmap과 완전성 감사를 완료하고 현재 Work Order를 Slice 01 전용으로 정리했다. |
| 2026-08-05 | Core Rules Kernel을 Slice 02로 앞당겼다. |
| 2026-08-05 | First Session Walking Skeleton을 Slice 01로 확정했다. |
| 2026-08-05 | Shared Spec 001·002를 `UPDATE_REQUIRED`로 판정했다. |
