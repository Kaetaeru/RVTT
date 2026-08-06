# Implementation Spec — Slice 11 Live DM Workspace·Quick Actions·Recovery

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 DM Workspace, Runtime Command, Control, Live Patch와 Recovery UI 구조가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 관련 Guide: [`Session`](../../../guides/session/README.md), [`Scene Editor`](../../../guides/scene-editor/README.md), [`UI`](../../../guides/ui/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md), [`Exploration`](../../../guides/exploration/README.md), [`Combat`](../../../guides/combat/README.md)

> DM 권한은 Store 직접 수정 권한이 아니다. 일반 Player 행동과 같은 Route를 사용할 수 있는 경우 Player Command를 사용하고, Override가 필요한 경우 별도 Command·Scope·Mandatory Audit·Projection을 사용한다.

## 1. Acceptance Flow

```text
DM Workspace 열기
→ Player View·Session·Scene·Encounter 상태 확인
→ Context 대상 선택
→ Quick Action 또는 Override Command
→ Result·Projection 확인
→ Scene Transition·Quick Edit·Patch
→ Save·Checkpoint·Recovery Review
→ Resume
```

Player는 DM 변경으로 인해 자신의 Projection·Control·Scene·Fog가 갱신되는 것을 보며, DM Raw State나 다른 Player Secret을 받지 않는다.

## 2. 직접 권위 문서

- [`Session Play Mode, Context, Overlay와 Transition`](../../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery`](../../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Scene Compiler와 Compiled Runtime Scene`](../../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Scene Streaming과 Ready Activation`](../../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`Diagnostics와 Observability`](../../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`DM Workspace와 Scene Lighting`](../../../ui/dm-workspace/dm-workspace-and-scene-lighting.md)
- [`DM Quick Action과 Context Command`](../../../ui/dm-workspace/dm-quick-action-and-context-command.md)
- [`Campaign Lobby·Hot Join·Ownership·Control`](../../../systems/session/campaign-lobby-hot-join-ownership-and-control.md)

## 3. 범위

포함:

- Dockable DM Workspace·Session·Scene·Player·Encounter View
- Player View Preview와 Audience 확인
- Control Assignment·Observer·Takeover
- Context Quick Action, Player Route와 DM Override
- Fog·Actor·Object·Lighting Runtime Command
- Pause·Resume·Scene Transition
- Runtime Quick Edit와 Source Promotion
- Live Patch·Build Rebase·Client Ready
- Save·Checkpoint·Recovery Review·Rollback
- Normal Shutdown·Health·Incident Support

제외:

- Workspace Instance 직접 Mutation을 권위로 사용
- Runtime Quick Edit 자동 Source 영구화
- NPC Dialogue·AI
- 일반 사용자에게 DM Projection 전송

## 4. Workspace Projection

```lua
export type DmWorkspaceProjection = {
    sessionSummary: unknown,
    sceneSummary: unknown,
    participantViews: {unknown},
    encounterSummary: unknown?,
    recoverySummary: unknown?,
    availableQuickActions: {unknown},
    projectionRevision: number,
}

export type DmContextTarget = {
    targetKind: string,
    targetProjectionRef: string,
    sourceRevision: number,
    allowedActionRefs: {string},
}

export type DmOverrideRecord = {
    overrideId: string,
    dmUserId: number,
    scope: string,
    reasonCode: string,
    targetRefs: {string},
    beforeRevision: number,
    afterRevision: number?,
    auditRef: string,
}
```

Player View Preview는 실제 Player Projection Builder를 같은 Viewer Context로 실행한 결과다. DM 화면에서 필드를 숨기는 가짜 Preview를 사용하지 않는다.

## 5. Control·Observer·Takeover

```text
Character Owner
≠ Runtime Controller
≠ Session Role
≠ Encounter Participant
≠ Visibility Permission
```

Command:

- `AssignActorController`
- `ReleaseActorController`
- `GrantObserverAccess`
- `RevokeObserverAccess`
- `TakeOverDisconnectedActor`

Controller 변경은 Character Ownership과 DM Secret 접근을 바꾸지 않는다. Player가 NPC를 제어해도 공개 가능한 Capability와 Projection만 받는다. Disconnect Takeover는 Policy·Grace·Audit를 따른다.

## 6. Quick Action와 Override

Quick Action Registry는 현재 Context·Role·Mode·Target Projection을 입력으로 허용 Action을 제공한다.

```text
Context Target
→ Action Registry·Capability·Policy
→ Player Route 가능?
  → 일반 Command Route
  → 아니면 DM Override Command
→ Validation·Transaction·Audit
→ Projection
```

예:

- Actor 선택·Focus·Control
- HP·Resource 조정
- Condition 적용·제거
- Door·Object State 조정
- Fog Reveal·Hide
- Scene Transition
- Encounter Start·End·Participant 수정
- Time·Activity Adjudication

DM Override가 Domain Invariant, Version·Migration과 Projection Barrier를 우회하지 않는다.

## 7. Runtime Scene Command

Runtime Fog·Actor·Object·Lighting 변경은 Dynamic State 또는 Runtime Override Layer에 기록한다.

```text
DM Intent
→ Target Runtime Ref·Incarnation·Revision 검증
→ Domain Command
→ Transaction
→ Runtime Override Record·Event
→ Viewer Projection
```

Runtime Quick Edit는 Published Build·Scene Source를 자동 수정하지 않는다. Session 종료 후 보존할 필요가 있으면 Source Promotion을 명시적으로 실행한다.

## 8. Source Promotion

```text
Runtime Override 선택
→ Source Object Mapping·Compatibility 검증
→ 새 Source Change Proposal
→ Authoring Source Revision
→ Candidate Compile·Diagnostic
→ Test·Publish Review
```

Source Object가 없거나 Runtime-only State이면 자동 승격하지 않는다. Promotion 실패가 현재 Runtime State를 Rollback하지 않는다.

## 9. Live Patch·Build Rebase

```text
새 Published Build 선택
→ Active Session Compatibility Diff
→ Dynamic State Rebase Plan
→ Checkpoint·Pause Overlay
→ Client Essential 준비
→ Build·Runtime Mapping Atomic Swap
→ Projection·Streaming Resync
→ Resume
```

Rebase 실패 시 기존 Build·Dynamic State를 유지한다. 새 Published Build가 존재한다는 이유만으로 자동 Patch하지 않는다. Player별 Essential Ready와 Timeout은 Server Policy를 사용한다.

## 10. Pause·Transition·Recovery

Pause는 Session Overlay이며 Encounter·Downtime lifecycleState가 아니다. 신규 Gameplay Command Gate를 닫지만 Pending Execution·Reservation을 임의 삭제하지 않는다.

Scene Transition:

```text
Target Build·Entry·Audience 검증
→ Transition Proposal
→ Source Scene Command Gate
→ Target Essential Staging
→ Player별 Ready
→ Session Scene Binding Commit
→ Projection·Camera·UI 재구성
```

Recovery Review:

```text
Integrity 자동 판정 불가
→ Permission-aware 후보 Checkpoint
→ Damage·Knowledge·Time·Content Diff
→ DM 선택·확인
→ Recovery Command
→ 새 Branch·AuthorityEpoch
→ Full Resync
```

Diagnostics Panel이 Store를 직접 덮어쓰지 않는다.

## 11. Save·Shutdown

Save Command는 Snapshot·Journal 상태와 Writer Lease를 표시하고 실패를 구조화한다. 정상 종료:

```text
새 Command 접수 중지
→ 진행 Transaction 안전 경계
→ Pending Execution 저장 가능성 확인
→ Journal Flush·Snapshot
→ Manifest 검증·Session 종료 Commit
→ Writer Lease 해제
```

Snapshot Timeout이 있어도 Journal Flush로 복구 가능한지 확인한다. Client 종료 애니메이션은 저장 성공의 증거가 아니다.

## 12. UI·Diagnostics·Security

Workspace 상태:

```text
Player Ready·Connection·Control
Scene Build·Essential·Streaming
Encounter·Turn·Pending Prompt
Save·Snapshot·Journal Health
Override 결과·Audit
Recovery Candidate·Diff
Live Patch Compatibility
```

Trace:

```text
dm.workspace_open
dm.player_preview
dm.quick_action
dm.override
control.assign
scene.runtime_edit
scene.source_promote
scene.live_patch
session.pause
session.transition
recovery.review
session.shutdown
```

Security:

- DM Command도 expected Revision·Scope·Rate·Payload 검증을 거친다.
- Mandatory Audit 실패가 허용되지 않는 Override는 Commit하지 않는다.
- Player Client에 DM Workspace·Raw Diagnostic·Secret Metadata를 보내지 않는다.
- Support Bundle은 Credential·Raw Payload·비밀 Source를 Redact한다.

## 13. Test 계획

1. Player View Preview와 실제 Player Projection 동일.
2. Controller 변경 후 Owner·Visibility 불변.
3. 일반 Player Route와 DM Override 분리.
4. HP·Condition·Fog·Object Quick Action Transaction.
5. Override Revision 충돌·Audit 실패.
6. Pause 중 Pending RuleExecution·Reservation 유지.
7. Scene Transition Essential Ready·Timeout·Reconnect.
8. Runtime Quick Edit 후 Source 불변.
9. Source Promotion Compile 실패와 Runtime 유지.
10. Live Patch Rebase 성공·실패·Fallback.
11. Save 중 Restart와 Journal 복구.
12. Recovery Review가 승인 전 Store 불변.
13. Rollback 후 이전 Command·Prompt·Patch ACK 차단.
14. Player·Observer Negative Disclosure.
15. Normal Shutdown·Lease Release·다음 Boot Recovery.

## 14. 구현 순서와 완료 기준

```text
Workspace Projection·Player Preview
→ Control·Observer·Takeover
→ Quick Action·Override Registry
→ Runtime Scene Commands
→ Pause·Transition
→ Quick Edit·Source Promotion
→ Live Patch·Rebase
→ Save·Recovery·Shutdown
→ Security·Integration Test
```

완료 기준:

- DM 권한이 Store 직접 Mutation으로 구현되지 않는다.
- Player View Preview가 실제 Projection을 사용한다.
- Runtime Quick Edit·Source·Published Build가 분리된다.
- Patch 실패가 현재 Session을 손상하지 않는다.
- Recovery·Rollback이 새 Branch·Epoch를 사용한다.

Production 구현 전 실제 Workspace·Command·Patch·Persistence·Recovery UI Mapping이 필요하다.