# Implementation Spec — Slice 08 Player UI·Camera·Presentation

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Client UI·Input·Camera·Presentation Module·Asset 구조가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 관련 Guide: [`UI`](../../../guides/ui/README.md), [`Session`](../../../guides/session/README.md), [`Rules`](../../../guides/rules/README.md), [`Combat`](../../../guides/combat/README.md), [`Character`](../../../guides/character/README.md), [`Scene`](../../../guides/scene/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> UI·Camera·Presentation은 Authority 결과를 보여주고 Intent를 전달한다. Client Panel, Camera Transform, Animation, VFX와 물리 주사위는 Gameplay State의 원본이 아니다.

## 1. Acceptance Flow

```text
서버 Projection 수신
→ Staging Replica 검증
→ Atomic Commit
→ ViewModel·HUD·Panel 갱신
→ Semantic Input
→ Pending Command·Receipt·Result
→ Projection Reconciliation
→ Camera·Presentation 실행
→ Disconnect·Role Change·Rollback 복구
```

Player는 탐험·전투·Character·Inventory·Downtime 기능을 같은 입력 문법과 오류·복구 표현으로 사용한다. DM은 별도 권위 Projection과 Workspace를 받으며 Player Cache에 DM Raw State를 남기지 않는다.

## 2. 직접 권위 문서

- [`UI Projection, ViewModel, Input Context와 Recovery`](../../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Camera Policy, Focus, Follow와 Presentation Runtime`](../../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md)
- [`Presentation Recipe, Playback Priority와 Extension Runtime`](../../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`Networking Command, Event와 Client Synchronization`](../../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Selection, Targeting, Preview와 Frozen Binding`](../../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Visibility, Knowledge와 Hover Projection`](../../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`Diagnostics와 Observability`](../../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation과 Test Harness`](../../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- [`공통 입력 교과서`](../../../ui/common-input/common-input-grammar.md)
- [`Combat HUD`](../../../ui/combat-hud/baldurs-gate-style-combat-hud.md)
- [`공식 2024 Character Sheet`](../../../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)
- [`공통 UI Wireframe`](../../../ui/shared/combat-hud-character-sheet-wireframe-and-shared-ui.md)

## 3. 범위

포함:

- Projection Replica·Snapshot·Batch·Integrity·Gap·Resync
- ViewModel·Panel·Component Registry와 Error Boundary
- Input Context Stack·Focus·Semantic Intent·Q/E·1–5
- Pending Command·Ghost·Receipt·Terminal Result·Projection Expectation
- Free·Follow·Focus Camera, ViewY, Bookmark, DM Observe
- Presentation Recipe·Module·Intent·Queue·Audience·Marker·Fallback
- Dice Reveal, Attack·Spell·Damage·Condition·Movement Presentation
- Accessibility·Quality·Reduced Motion·Flash·Shake Hard Limit
- Reconnect·Scene Transition·Role Change·Rollback Recovery

제외:

- 음악·환경음·공격·주문·UI SFX
- Camera·Presentation 기반 Gameplay 판정
- 모든 최종 Content Asset 완성

## 4. Client Replica와 Type

```lua
export type ProjectionEnvelope = {
    protocolVersion: number,
    authorityEpoch: string,
    projectionEpoch: string,
    sequenceStart: number,
    sequenceEnd: number,
    integrityDigest: string,
    segments: {unknown},
}

export type ClientReplicaState = {
    projectionEpoch: string,
    lastAppliedSequence: number,
    authorityRevision: number,
    segmentRevisions: {[string]: number},
    readiness: string,
}

export type UIInputContext = {
    contextId: string,
    kind: string,
    priority: number,
    allowedSemanticInputs: {[string]: boolean},
    focusToken: string?,
    revision: number,
}

export type PendingCommandView = {
    requestId: string,
    idempotencyKey: string,
    state: "created" | "submitted" | "receipt" | "terminal_result" | "awaiting_projection" | "reconciled" | "failed",
    expectedProjectionRefs: {string},
}

export type CameraRequest = {
    requestId: string,
    policy: string,
    targetProjectionRef: string?,
    priority: number,
    interruptPolicy: string,
    cancelPolicy: string,
    audienceUserIds: {number},
}

export type PresentationIntent = {
    intentId: string,
    sourceProjectionRef: string,
    semanticTags: {string},
    frozenParameters: {[string]: unknown},
    audiencePolicyRef: string,
    importance: string,
    recipeVersionRef: string,
}
```

Projection Batch를 부분 적용하지 않는다. 실패하면 Last Known Good Replica를 유지하고 관련 Input Scope를 닫는다.

## 5. ViewModel·Panel·Component

```text
Client Replica
→ Domain Projection Adapter
→ ViewModel
→ Panel·HUD·Tooltip·Prompt Component
→ Semantic UI Intent
```

Component는 RemoteEvent·Domain Service·Workspace Query를 직접 호출하지 않는다. ViewModel은 Authority State 복사본이 아니라 Viewer Projection의 표시·입력 Adapter다.

대표 Surface:

- Exploration HUD·Selection·Interaction Prompt
- Combat HUD·Initiative·Action·Reaction
- Character Sheet·Inventory·Downtime
- Loading·Reconnect·Recovery·Error Surface
- Journal·DM Workspace의 공통 Panel 기반

Panel 열림 상태를 Session Mode나 Authority Overlay로 사용하지 않는다.

## 6. Input Context와 Focus

입력 우선순위는 Context Stack으로 결정한다.

```text
Text Input
> Critical Authority Prompt
> Selection·Targeting
> Modal Panel
> Scene Transition·Recovery Gate
> Gameplay Interaction
> Camera·Exploration Movement
```

하나의 Q·E·숫자·Pointer 입력이 여러 Context에 동시에 전달되지 않는다. Q는 현재 Context의 Cancel 의미, E는 Confirm·Interact 의미를 가진다. 물리 키를 각 Component가 직접 감시하지 않는다.

Focus Token은 Keyboard·Pointer·Game Surface의 현재 소비자를 나타내며, Panel 오류나 제거 후 안전한 이전 Focus로 복원한다.

## 7. Command Reconciliation

```text
Local Intent
→ Pending UI·Ghost
→ Command 제출
→ Receipt
→ Terminal Result
→ Projection Expectation 대기
→ Projection Batch 적용
→ reconciled
```

거부되면 권위값을 역보정하지 않고 Local Ghost·Pending만 정리한다. Result와 Projection 도착 순서가 바뀌어도 동일 Request·Authority Revision으로 결합한다. 불명확하면 Idempotency Status 또는 Resync를 사용한다.

## 8. Camera Runtime

Policy 예시:

```text
free
follow_actor
selection_focus
presentation_focus
dm_observe
replay
scene_transition
restoring_previous
```

CameraRequest는 공개 가능한 Target Projection만 참조한다. Follow와 Focus를 분리하고, 사용자의 Free Override와 접근성 설정을 존중한다. 높은 Priority Request 종료 시 Restoration Stack으로 Transform·Follow·Focus·ViewY를 복원한다.

DM Observe는 Control Assignment와 비밀 정보 권한을 자동 변경하지 않는다. Stream Out·권한 축소·Rollback 후 대상이 무효하면 이름으로 자동 재연결하지 않고 안전한 Fallback을 사용한다.

## 9. Presentation Runtime

```text
Committed Event·Projection
→ PresentationIntent
→ Recipe Version·Parameter·Audience 검증
→ Queue Admission
→ Playback Plan
→ Module·Marker·CameraRequest·UI Feedback
```

Recipe는 Data-driven Timeline Graph, Parameter Schema, Module Binding, Audience, Quality, Accessibility와 Fallback을 가진다. 저장된 임의 Luau Callback·무제한 Loop를 허용하지 않는다.

중요도:

```text
required_reveal > important > standard > ambient
```

Budget 초과 시 Ambient, 중복 Impact, 먼 거리 Effect를 줄이지만 필수 Reveal과 Warning은 유지한다. Module 오류는 해당 Module만 중단하고 Fallback 또는 생략하며 Gameplay Commit을 Rollback하지 않는다.

Roll Reveal은 최소 결과 표시와 Marker 또는 Hard Fallback을 사용한다. Client Dice Physics가 Roll 값을 만들지 않는다.

## 10. Accessibility와 Quality

사용자 Hard Limit:

- Reduced Motion
- Camera Shake 제한·비활성
- Flash·Screen Overlay 제한
- Particle·Decal·Light Quality
- Text Scale·Contrast·Input 안내

DM Presentation 요청이나 Recipe가 Hard Limit을 우회하지 못한다. Low-end Profile은 Core HUD·Prompt·Reveal 판독성을 유지한다.

## 11. Recovery

Reconnect:

```text
입력 Gate 닫기
→ Pending UI Frozen
→ Delta Resume 또는 Full Snapshot
→ Staging Replica 검증·Atomic Commit
→ Prompt·Selection·Turn View 재생성
→ Local Layout·Preference 결합
→ Camera Target 재검증
→ 필수 Reveal 안전 재개
```

Role·Control 변경은 허용되지 않는 Panel·Action·Data·Cache·Focus를 제거한다. Rollback은 이전 Epoch Command·Prompt·Selection·Preview·Camera ACK·Playback을 폐기하고 새 Replica를 적용한다. 일반 Particle·Tween 진행률은 복구하지 않는다.

## 12. Diagnostics·Security·Test

Trace:

```text
projection.receive
projection.apply
viewmodel.build
input.route
command.reconcile
camera.request
presentation.admit
presentation.marker
ui.error_boundary
client.resync
```

Security:

- Raw Server State와 DM Projection을 Player Client에 보내지 않는다.
- UI·Camera·Presentation Error와 Support Bundle을 Redaction한다.
- Client가 Recipe ID·Module·Secret Target·Authority Parameter를 임의 실행하지 못한다.
- Hidden Entity를 Tooltip·Camera·VFX Anchor·Error에 포함하지 않는다.

Test:

1. Snapshot·Delta 원자 적용과 Integrity 실패.
2. Projection Gap·Duplicate·Reorder·Full Resync.
3. Result와 Projection 도착 순서 역전.
4. Prompt·Selection·Text Input·Panel의 Q/E 단일 소비.
5. Panel 오류가 다른 HUD·Gameplay Input에 전파되지 않음.
6. Role Change 후 DM Panel·Cache·Focus 제거.
7. Reconnect 중 Pending Command·Prompt 복구.
8. Rollback 이전 ACK·Camera·Preview 차단.
9. Free Camera·Follow·Focus·Restoration.
10. Target Stream Out·권한 축소 Fallback.
11. Recipe Hot Swap 중 진행 Playback Version 고정.
12. Module 오류·ACK 유실·Hard Reveal Fallback.
13. Reduced Motion·Flash·Shake Hard Limit.
14. Audience별 Hidden VFX Anchor Negative Disclosure.
15. Low-end Quality와 Projection·Memory Budget.

## 13. 구현 순서와 완료 기준

```text
Projection Replica
→ ViewModel·Panel Registry
→ Input Context·Focus
→ Command Reconciliation
→ Camera Runtime
→ Presentation Runtime
→ Accessibility·Recovery
→ Virtual Client·Roblox Test
```

완료 기준:

- UI가 Projection만 소비하고 Command Intent만 제출한다.
- Input가 Context Stack에서 한 번만 소비된다.
- Camera·Presentation이 권위 판정에 참여하지 않는다.
- Role·Reconnect·Rollback에서 Cache와 입력이 Epoch-safe하다.
- Accessibility와 Low-end Fallback이 필수 결과를 유지한다.

Production 구현 전 실제 ScreenGui·Controller·Camera·VFX·Asset·Virtual Client Test Mapping이 필요하다.