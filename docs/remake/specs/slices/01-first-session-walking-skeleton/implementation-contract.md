# Implementation Spec — Slice 01 First Session Walking Skeleton

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: Production Source Tree, 기존 Schema와 Test Runner를 확인하지 못해 최종 Package 경로와 Migration 대상을 확정할 수 없다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 관련 Quick Flow: [`한눈에 보는 세션 흐름`](../../../user-guides/QUICK-FLOW.md)
- 관련 User Guide: [`Player Guide`](../../../user-guides/player/README.md), [`DM Guide`](../../../user-guides/dm/README.md)
- 관련 Main Guide: [`Runtime`](../../../guides/runtime/README.md), [`Session`](../../../guides/session/README.md), [`Scene`](../../../guides/scene/README.md), [`Exploration`](../../../guides/exploration/README.md), [`UI`](../../../guides/ui/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)
- 기존 세부 Spec: [`Core Authority Identity·Version·Result`](../../runtime/001-core-authority-identity-version-and-result.md)

> 이 Spec은 세션 참가부터 클릭 이동과 재접속까지의 첫 생산 경로를 하나의 계약으로 묶는다. 후속 Slice의 Rules·Interaction·Encounter 기능을 미리 구현하지 않는다.

## 1. 목표와 Acceptance Flow

### Player

```text
Campaign 참가 요청
→ Membership Projection 수신
→ 허용 Character 선택
→ User Ready 제출
→ DM 시작 승인 대기
→ Scene Essential Snapshot 적용
→ Controlled Actor Essential 확인
→ Token 선택
→ Destination Intent 제출
→ Receipt·Terminal Result 수신
→ Position Projection 적용
→ Disconnect
→ 새 Connection Epoch로 Reconnect
→ Character·Scene·Actor·Position 복원
```

### DM

```text
Campaign·Start Scene 확인
→ Player Membership·Role·Owner·Controller 확인
→ User Ready와 Client Ready 확인
→ Start Session Command
→ Scene Entry·Actor Bootstrap 확인
→ Movement Commit 확인
→ Disconnect 상태 확인
→ Reconnect·Resync와 동일 Authority State 확인
```

성공은 화면 전환만으로 판정하지 않는다. Server Authority State, Commit Journal과 사용자별 Projection이 같은 Epoch·Revision 의미를 가져야 한다.

## 2. 직접 권위 문서

- [`Runtime Architecture Principles`](../../../architecture/runtime-architecture-principles.md)
- [`Networking Command, Event와 Client Synchronization`](../../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Scene Streaming, Client Interest와 Ready Activation`](../../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Spatial Query Engine과 Provider`](../../../architecture/spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation, Path Planning과 Movement Execution`](../../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Persistence, Snapshot, Journal과 Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`UI Projection, ViewModel, Input Context와 Recovery`](../../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Diagnostics와 Observability`](../../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation과 Test Harness`](../../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- [`플랫폼·이동·입력 범위`](../../../product/platform-movement-and-input-scope.md)
- [`Campaign Lobby·Hot Join·Ownership·Control`](../../../systems/session/campaign-lobby-hot-join-ownership-and-control.md)

## 3. 범위와 종료 경계

포함:

- Campaign Membership, Session Role, Character Owner와 Runtime Controller
- User Ready, Client Essential Ready, Session Start Gate
- Published Scene Build Reference와 Scene Runtime Presence
- Controlled Actor Bootstrap과 사용자별 공개 Projection
- 탐험 목적지 클릭 이동
- Command Receipt, Terminal Result, Projection Snapshot·Delta·Gap·Full Resync
- Snapshot·Commit Journal·Reconnect Resume
- Trace·Stable Error·Negative Disclosure와 결정적 Test

제외:

- 탐험 WASD Token 이동
- Door·Container·Search·Fog·Interaction
- D20 Test, Attack, Spell과 EffectRecipe
- Encounter·Initiative·Turn·Reaction
- Character 생성·Level Up·Inventory
- Scene Source 편집과 Live Patch

종료 상태는 Player가 재접속 후 같은 Campaign Character와 현재 Scene의 Controlled Actor를 보고, 마지막 Commit Position에서 새 이동 Intent를 제출할 수 있는 시점이다.

## 4. Authority State와 Type 계약

최종 경로는 신규 제안이며 실제 Source Tree 조사 후 고정한다.

```lua
export type SessionConnectionRef = {
    connectionSessionId: string,
    connectionEpoch: number,
}

export type AuthorityVersion = {
    authorityEpoch: string,
    authorityRevision: number,
}

export type MembershipState = {
    membershipId: string,
    campaignId: string,
    userId: number,
    role: "player" | "dm" | "observer",
    revision: number,
}

export type CharacterControlBinding = {
    characterId: string,
    ownerUserId: number?,
    controllerUserId: number?,
    controlRevision: number,
}

export type SessionReadiness = {
    userReady: boolean,
    clientEssentialReady: boolean,
    sceneEssentialReady: boolean,
    actorEssentialReady: boolean,
    readinessRevision: number,
}

export type SceneEntryBinding = {
    sceneId: string,
    publishedBuildId: string,
    publishedBuildVersion: number,
    runtimeSceneIncarnation: string,
    entryAnchorId: string,
}

export type ActorPositionState = {
    actorId: string,
    actorIncarnation: string,
    positionRevision: number,
    worldPosition: {x: number, y: number, z: number},
    facingRadians: number,
}
```

불변식:

- `CharacterId`와 `ActorId`를 같은 ID로 사용하지 않는다.
- Character Owner 변경과 Runtime Controller 변경은 별도 Command다.
- Scene Source, Published Build와 Runtime Scene Incarnation은 분리한다.
- Client가 제출한 Instance Path, CFrame과 Local Token 위치는 Authority Ref가 아니다.
- `connectionEpoch`, `authorityEpoch`, `authorityRevision`, Domain Revision과 Projection Cursor를 혼용하지 않는다.

## 5. Command와 Network 계약

| Command | 요청자 | 주요 검증 | 성공 Commit | 대표 실패 코드 |
|---|---|---|---|---|
| `JoinCampaign` | 인증 사용자 | Campaign 접근, Membership 상태, Protocol Version | Membership 또는 기존 Membership 재Projection | `CAMPAIGN_ACCESS_DENIED`, `PROTOCOL_UNSUPPORTED` |
| `SelectSessionCharacter` | Player·DM | Membership, Character Owner·허용 목록, expected Revision | Character Session Binding | `CHARACTER_NOT_ALLOWED`, `CONTROL_REVISION_STALE` |
| `SetUserReady` | Player | Membership·Character Binding | User Ready Revision | `SESSION_MEMBERSHIP_STALE` |
| `StartSession` | DM | DM Role, Start Scene, 필수 Player Ready Policy | Session Transition | `SESSION_START_NOT_READY` |
| `AcknowledgeSceneEssential` | Client | Build·Segment Digest, Connection Epoch | Client Ready State | `SCENE_BUILD_MISMATCH` |
| `RequestActorControl` | 허용 Player·DM | Role, Ownership, Actor Incarnation | Control Assignment | `CONTROL_NOT_ELIGIBLE` |
| `MoveActorToDestination` | Controller | Connection·Authority Epoch, Scene·Actor Ready, Path·Occupancy·Revision | Position·Movement State Commit | `MOVEMENT_PATH_INVALID`, `POSITION_REVISION_STALE` |

모든 변경 Command는 즉시 Receipt를 반환하고, 검증·Commit 후 Terminal Result를 반환한다. 성공 Result만으로 Client Position을 확정하지 않으며 해당 Authority Revision을 포함한 Projection이 적용돼야 `reconciled`가 된다.

Projection lane:

```text
Membership Snapshot
→ Session State Delta
→ Scene Essential Snapshot Segments
→ Controlled Actor Essential
→ Position Delta Batch
→ Gap Detection
→ Catch-up 또는 Full Resync
```

Projection Batch는 부분 적용하지 않는다. Sequence Gap, Epoch 불일치나 Integrity 실패 시 Last Known Good Replica를 유지하고 Authority-bound 입력 Gate를 닫는다.

## 6. 상태 전이와 Readiness

```text
not_joined
→ joining
→ lobby_joined
→ character_selected
→ user_ready
→ session_starting
→ scene_loading
→ scene_essential_ready
→ actor_essential_ready
→ gameplay_ready
```

Disconnect는 Membership과 Character Owner를 삭제하지 않는다.

```text
gameplay_ready
→ connection_lost
→ reconnecting
→ resyncing
→ gameplay_ready
```

새 Connection Epoch가 발급되면 이전 연결의 Pending Command·Prompt·Preview는 현재 연결에 자동 승계하지 않는다. Idempotency Status 조회로 Commit 여부를 확인할 수 있으나 Client Local State를 Server 복구 원본으로 사용하지 않는다.

## 7. 이동 실행과 Transaction

```text
Destination Intent
→ Controller·Readiness·Revision 검증
→ Snapshot-bound Traversal Query
→ Path Plan
→ Occupancy·Collision·Deniable·Movement Policy 검증
→ Movement Execution
→ Checkpoint
→ 최신 Position Revision 재검증
→ Authority Transaction
→ Journal + movement.committed Event
→ Position Projection Barrier
```

Client Path는 Preview일 뿐이다. Server가 다른 경로를 선택하거나 목적지를 거부할 수 있다. Slice 01에서는 Interaction Trigger와 Encounter Reaction을 실행하지 않지만, Movement Checkpoint와 중단 사유를 Versioned Result로 남겨 후속 Slice가 확장할 수 있게 한다.

Ordering Key의 최소 범위:

```text
campaignId / runtimeSceneId / actorId
```

같은 Actor의 병렬 이동 Commit은 직렬화하고, 서로 독립적인 Actor는 전역 Lock 없이 진행할 수 있다.

## 8. Persistence·Recovery·Rollback

저장 원본:

- Campaign Membership과 Role
- Character Owner·Controller Binding
- Session Mode와 Start Scene Ref
- Published Build Ref와 Runtime Scene Identity
- Actor Runtime Presence와 Position Revision
- Authority Epoch·Revision
- Projection Resume에 필요한 Commit Journal Cursor

저장하지 않는 값:

- Hover, Selection Highlight와 제출 전 Path Preview
- Camera Transform과 UI Panel 상태
- Client Workspace Instance 경로
- Tween·VFX·Loading Animation 진행률

Snapshot과 Commit Journal이 불일치하면 자동으로 최신 값들을 섞지 않는다. Last Known Good Snapshot과 Commit Marker를 사용하거나 DM Recovery Review를 요구한다. Rollback은 새 Branch·AuthorityEpoch를 발급하고 이전 연결과 Command를 무효화한다.

## 9. UI·오류·정보 공개

필수 사용자 상태:

```text
참가 중
Character 선택 필요
다른 사용자가 제어 중
DM 시작 대기
Scene 필수 데이터 로딩 중
동기화 복구 중
이동 요청 처리 중
목적지 거부
재접속 중
Full Resync 필요
```

Player Projection에는 자신에게 공개 가능한 Membership, Character, Scene와 Actor 정보만 포함한다. DM-only Notes, 숨은 Actor, Secret Object, 전체 Membership Diagnostic과 Raw Error Context를 보내지 않는다.

Internal Stack과 Payload는 Stable Error Code, 안전한 `userMessageKey`, `supportReference`로 변환한다.

## 10. Module 책임 제안

실제 경로 확인 전 논리 Package만 정의한다.

| 논리 Package | 책임 | 금지 |
|---|---|---|
| Core Authority | ID·Epoch·Revision·Result·Error | Domain Store 소유 |
| Protocol Gateway | Envelope·Receipt·Result·Projection Cursor | Gameplay 판정 |
| Campaign Session | Membership·Role·Ready·Transition | Character 영구 데이터 수정 |
| Control Resolver | Owner·Controller·Capability 검증 | 비밀 정보 Projection |
| Scene Bootstrap | Published Build·Presence·Essential Gate | Source 편집 |
| Navigation Execution | Path·Checkpoint·Position Proposal | Client Path 신뢰 |
| Persistence Coordinator | Snapshot·Journal·Recovery | UI Local State 저장 |
| Projection Builder | Viewer별 공개 View | Raw Store 전송 |

## 11. Diagnostics와 Test

필수 Trace:

```text
campaign.join
character.select
session.ready_change
session.start
scene.bootstrap
actor.control_assign
movement.plan
movement.commit
projection.apply
connection.reconnect
recovery.resync
```

필수 Scenario:

1. 정상 Join→Move→Reconnect.
2. Owner가 아닌 Character 선택 거부.
3. User Ready지만 Client Essential 미준비 상태에서 시작 Gate.
4. 오래된 Connection Epoch 이동 거부.
5. 같은 Idempotency Key 중복 이동이 한 번만 Commit.
6. Position Revision 경합에서 하나만 성공.
7. Projection Batch Drop·Duplicate·Reorder 후 Catch-up.
8. Commit 직후 Server Restart에서 Position 복원.
9. Scene Build 불일치 시 Gameplay Gate 유지.
10. Player Projection에 DM-only Character·Hidden Actor Canary가 없음.
11. Client가 Instance Path와 임의 CFrame을 제출해도 거부.
12. Rollback 후 이전 Epoch Command가 거부되고 Full Resync.

실제 Roblox Integration은 Remote ingress, Player reconnect, Streaming Essential과 Workspace materialization 실패를 포함해야 한다.

## 12. 구현 순서와 완료 기준

```text
Core Authority Type·Validator
→ Protocol·Projection Replica
→ Campaign Membership·Ready
→ Scene Bootstrap·Actor Control
→ Movement Plan·Execution·Commit
→ Snapshot·Journal·Reconnect
→ Deterministic·Roblox Integration
```

Spec 완료 기준:

- 모든 사용자 흐름과 권위 계약이 직접 문서에 추적된다.
- State·Command·Projection·Persistence 의미가 중복되지 않는다.
- 실패·중복·Reconnect·Restart·Rollback·Disclosure Test가 존재한다.
- 실제 Source Tree Mapping 외에 중요한 제품 동작 추측이 남지 않는다.

Production 구현 시작 전 남은 Gate:

- 실제 Repository Source·Schema·Test Tree 조사
- 제안 Package를 실제 경로에 Mapping
- 기존 데이터가 있으면 Migration Plan 작성
- 측정형 Payload·Queue·Timeout·Budget 기본값 확정 절차 연결