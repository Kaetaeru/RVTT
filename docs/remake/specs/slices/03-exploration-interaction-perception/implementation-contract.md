# Implementation Spec — Slice 03 Exploration Interaction·Perception

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Input, Interaction, Visibility, Fog와 Navigation Source Tree를 확인하지 못했다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 계약: [`Slice 01`](../01-first-session-walking-skeleton/implementation-contract.md), [`Slice 02`](../02-core-rules-kernel/implementation-contract.md)
- 관련 Guide: [`Exploration`](../../../guides/exploration/README.md), [`Scene`](../../../guides/scene/README.md), [`Rules`](../../../guides/rules/README.md), [`UI`](../../../guides/ui/README.md), [`Session`](../../../guides/session/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> 이 Spec은 탐험에서 사용자가 대상을 보고 선택하고 상호작용하며, 판정과 공개 결과를 안전하게 받는 전체 경로를 정의한다. Encounter 순서와 Action Economy는 Slice 04가 소유한다.

## 1. Acceptance Flow

### Player

```text
Scene 탐험
→ Mouse Hover·Focus
→ E 또는 Context Action
→ Selection·Preview
→ 필요 시 Check·Save·선택
→ Interaction Commit
→ 문·상자·Item·Knowledge·Fog 결과 확인
→ 이동 계속
```

### DM

```text
Scene Object·Secret·Fog·Knowledge 상태 확인
→ 자동화 가능한 Interaction 허용
→ 필요 시 DC·Outcome·Adjudication 제공
→ Player별 공개 결과 Preview
→ Commit·Trace·Object State 확인
```

## 2. 직접 권위 문서

- [`Selection, Targeting, Preview와 Frozen Binding`](../../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Visibility, Knowledge, Detection과 Hover Information`](../../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- [`Exploration 실시간 이동, 행동과 Encounter 전환`](../../../architecture/exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Scene Streaming과 Ready Activation`](../../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Spatial Query Engine과 Provider`](../../../architecture/spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation과 Movement Execution`](../../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery`](../../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Rule Runtime Orchestrator`](../../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Dice Roll과 Resolution`](../../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`Diagnostics와 Observability`](../../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)

## 3. 범위

포함:

- Input Context Stack과 Semantic Intent
- Hover, Focus, Selection, Candidate, Preview와 Frozen Binding
- Door, Container, Lever, Button과 Ground Item Interaction
- Search, Study, Lock, Trap, Secret Object와 DM Adjudication
- Visibility, Knowledge, Detection, Hover Disclosure와 Manual Fog
- 탐험 Token WASD 이동
- Interaction·Fog·Item Concurrency
- Scene Transition·Reconnect·Rollback 복구

제외:

- Initiative·Turn·Reaction·Opportunity
- Inventory 전체 UI와 Equipment
- Scene Source Editor
- AI 행동과 NPC 대화

## 4. 상태와 Type

```lua
export type InputContext = {
    contextId: string,
    kind: "gameplay" | "selection" | "prompt" | "panel" | "text_input" | "camera" | "scene_transition",
    priority: number,
    consumes: {[string]: boolean},
    revision: number,
}

export type SelectionSession = {
    selectionId: string,
    sourceIntentId: string,
    ownerUserId: number,
    state: "open" | "confirmed" | "cancelled" | "expired",
    candidatePolicyId: string,
    expectedRevision: number,
}

export type FrozenBinding = {
    bindingId: string,
    sourceExecutionRef: string,
    targetRefs: {string},
    sceneSnapshotRef: string,
    dependencyRevisions: {[string]: number},
}

export type InteractionState = {
    objectId: string,
    objectIncarnation: string,
    interactionProfileId: string,
    lifecycleState: string,
    stateRevision: number,
}

export type ObserverKnowledgeState = {
    observerScopeId: string,
    subjectRef: string,
    knowledgeLevel: string,
    sourceRefs: {string},
    revision: number,
}

export type ManualFogState = {
    sceneId: string,
    fogLayerRevision: number,
    audienceScopeId: string,
    revealedRegions: {string},
    hiddenRegions: {string},
}
```

Hover는 Local Candidate를 만들 수 있지만 Authority Selection이나 Knowledge를 생성하지 않는다. Frozen Binding은 Commit 성공을 보장하지 않으며 실행 직전 최신 Revision과 Eligibility를 재검증한다.

## 5. Input와 WASD

물리 입력은 Semantic Intent로 변환한다.

```text
Mouse Hover → InspectCandidate
Left Click → Select 또는 MoveDestination
E → Confirm·Interact
Q → Cancel·Close
WASD → 현재 Context에 따른 Camera 또는 Exploration Actor Movement
```

Text Input, Authority Prompt, Selection, Scene Transition이 활성화되면 더 낮은 Context가 같은 키를 받지 않는다.

탐험 WASD는 별도 위치 권위가 아니다.

```text
WASD Sample
→ Local Direction Intent
→ Rate·Connection·Control 검증
→ Navigation Snapshot Query
→ 짧은 Movement Plan·Checkpoint
→ Position Commit
→ Projection
```

클릭 이동과 WASD는 같은 Traversal, Collision, Occupancy, Position Revision과 Transaction 경로를 사용한다. Client Frame Rate와 Physics 위치를 저장하지 않는다.

## 6. Selection·Preview·Interaction

```text
Hover Candidate
→ 공개 가능한 Summary Projection
→ Interaction Intent
→ Selection Session 또는 즉시 Target
→ Range·Line·Knowledge·Capability 검증
→ Frozen Binding
→ Core Rules Check·Save 또는 Direct Operation
→ Object·Item·Knowledge Pending Outcome
→ Transaction
```

대표 Command:

| Command | 검증 | Commit |
|---|---|---|
| `BeginInteraction` | Control, Object Incarnation, 공개·거리·Capability | Selection 또는 RuleExecution 생성 |
| `ConfirmSelection` | Selection Revision, Candidate, Scene Snapshot | Frozen Binding |
| `CancelSelection` | Owner, 취소 가능 상태 | Selection 종료 |
| `OperateSceneObject` | Object State, Eligibility, expected Revision | Door·Lever·Container State |
| `SearchArea` | Capability, Search Scope, Policy | Roll·Knowledge 후보 |
| `AdjudicateInteraction` | DM Role, 허용 Decision, Audit | Versioned Outcome |
| `ModifyManualFog` | DM Role, Scene·Audience, Region Validation | Fog Layer Revision |
| `PickupGroundItem` | Item·Presence·Actor·Range Revision | Item Location Transaction |

Client가 `성공`, `발견함`, `문 열림`, `함정 해제됨`을 제출하지 않는다.

## 7. Perception·Knowledge·Fog

다음을 분리한다.

```text
Visibility
→ 현재 관찰 가능한가

Detection
→ 숨김·은신·Secret을 판정했는가

Knowledge
→ 과거에 무엇을 알게 되었는가

Manual Fog
→ DM이 사용자에게 지형 공개 영역을 어떻게 제한하는가
```

Detection 성공은 Knowledge Event를 만들 수 있지만 Manual Fog 전체를 자동 제거하지 않는다. Fog Reveal은 숨은 Actor·Secret Object의 Identity를 자동 공개하지 않는다.

Player Projection Builder는 Raw Scene State를 받은 뒤 숨기지 않고, Viewer Context에서 처음부터 안전한 Candidate·Hover·Object·Knowledge View를 만든다.

## 8. 동시성·Transaction

Ordering Key 예시:

```text
sceneId / objectId
sceneId / itemInstanceId
sceneId / fogAudienceScope
observerScope / knowledgeSubject
actorId / position
```

- 두 Player가 같은 Door를 열면 Revision에 따라 하나의 State Transition만 Commit한다.
- 같은 Ground Item Pickup 경쟁은 Item Location Binding Transaction으로 해결한다.
- Fog Edit와 Detection 결과는 서로의 Store를 직접 수정하지 않고 Cross-Domain Plan으로 합성한다.
- Interaction 중 Scene Transition이 시작되면 신규 Scene-bound Command Gate를 닫고 미Commit Execution을 안전 취소하거나 저장한다.

## 9. Persistence·Recovery

저장:

- Object·Container·Door·Trap State와 Revision
- Item World Presence와 Location Binding
- Observer Knowledge Records
- Manual Fog Layer와 Audience Binding
- 열린 Authority Selection·RuleExecution이 복구 대상이면 해당 Record
- Actor Position과 Exploration Movement Checkpoint

파생·비저장:

- Hover Highlight
- Client Candidate Cache
- Path Preview·Tooltip·Camera Focus
- Fog Render Texture 자체

Reconnect는 현재 공개 가능한 Projection을 재생성한다. 권한이 줄었으면 이전 Hover·Search·Knowledge Cache를 제거한다. Rollback 후 이전 Incarnation·Selection·Fog Command는 새 AuthorityEpoch에서 거부한다.

## 10. UI와 실패 상태

표시 상태:

```text
상호작용 가능
너무 멂·경로 없음
대상이 변경됨
선택 중·취소 가능
판정 중·DM 대기
다른 사용자가 처리 중
숨은 정보가 없음이 아니라 공개 불가
Fog 갱신 중
Scene 전환으로 취소됨
Reconnect 후 최신 상태 복구 중
```

Preview는 예상 결과와 의존 Revision을 표시할 수 있지만 성공을 확정하지 않는다.

## 11. Diagnostics·Security

Trace:

```text
input.route
selection.open
selection.confirm
interaction.validate
spatial.query
perception.resolve
knowledge.commit
fog.commit
item.pickup
exploration.move
```

Security:

- Client가 Secret Object ID, Hidden Actor, DM Fog Source와 Detection DC를 열거하지 못한다.
- Search 결과 Count·Facet·Error가 비공개 대상 존재를 암시하지 않는다.
- Hover·Camera Target·VFX Anchor는 공개 Projection만 사용한다.
- DM Adjudication과 Fog Command는 Mandatory Audit Scope를 가진다.
- Input Spam은 Rate·Payload·Per-object Concurrency Budget으로 제한한다.

## 12. Test 계획

1. Door 정상 Open·Close와 동시 Open 경쟁.
2. Locked Door Check 성공·실패와 stale Object Revision.
3. Search 실패 시 Secret Canary 미노출.
4. Search 성공 후 Knowledge 유지, Fog는 Policy대로 별도 처리.
5. Trap Save와 Effect Commit이 Core Rules Kernel 사용.
6. Ground Item 동시 Pickup에서 단일 Owner.
7. WASD·Camera·Text Input Context 단일 소비.
8. Client Preview 변조 후 Server 재검증.
9. Hidden Actor가 Hover·Camera·Error·Diagnostic에 없음.
10. Scene Transition 중 열린 Selection 안전 종료.
11. Reconnect 후 Object·Fog·Knowledge·Position 복원.
12. Rollback 이후 이전 Selection·Fog Command 거부.
13. Network Drop·Duplicate·Reorder에서 Projection Gap 복구.
14. 대형 Scene Spatial Query와 Hover Payload Budget 측정.

## 13. 구현 순서와 완료 기준

```text
Input Context·Semantic Intent
→ Selection·Preview·Frozen Binding
→ Interaction Object State·Command
→ Core Rules Check·Adjudication
→ Visibility·Detection·Knowledge·Fog
→ Exploration WASD
→ Persistence·Disclosure·Integration Test
```

완료 기준:

- 모든 Interaction이 Command·RuleExecution·Transaction 경로를 사용한다.
- Input·Preview·Camera가 Authority를 만들지 않는다.
- Fog·Visibility·Knowledge·Detection이 분리된다.
- Player에게 비밀 정보가 전송되지 않는다.
- Click과 WASD Movement가 같은 Position Authority를 사용한다.

Production 구현 전에는 실제 Input·Object·Fog·Navigation Package와 Legacy 데이터 Mapping을 확인해야 한다.