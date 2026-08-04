# Main System Guide: Scene, Streaming, Runtime Object, Spatial Query와 Navigation

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 DM이 Scene Source를 제작해 검증된 Runtime Build로 게시하고, 서버가 그 Build 위에 Runtime Object와 Dynamic State를 유지하며, Client가 필요한 공개 자료만 준비한 뒤, Spatial Query·Path Planning·Movement Execution으로 월드 안의 이동과 공간 판정을 수행하는 전체 흐름을 설명한다.

사용자에게 보장하는 결과:

- DM은 벽, 바닥, 문, 계단, 물, 함정과 소품을 의미 있는 Scene 요소로 배치하고 내부 Polygon·Portal·Spatial Index를 직접 편집하지 않는다.
- Scene Source, 불변 Compiled Build와 플레이 중 Dynamic State를 서로 다른 권위 계층으로 유지한다.
- Candidate Build가 실패해도 Last Known Good Published Build와 활성 세션은 손상되지 않는다.
- 정적 바닥과 벽의 모든 조각을 Runtime Object로 만들지 않고, 독립 Identity·Lifecycle·상호작용이 필요한 Scene Presence만 Runtime Object로 관리한다.
- 문 하나의 상태 변화가 Navigation, Visibility, Interaction과 Presentation에 서로 다른 Revision으로 반영되지 않는다.
- Client Camera와 Roblox Streaming 상태가 서버의 Runtime Object 존재, Trigger 활성 여부와 이동 가능성을 결정하지 않는다.
- Scene Entry Essential과 조작에 필요한 자료가 준비되기 전에 Gameplay Command를 열지 않는다.
- 미준비 구역을 빈 공간이나 통과 가능한 길처럼 표시하지 않고 Streaming Veil, Proxy 또는 입력 Gate로 안전하게 처리한다.
- 주문, Perception, Interaction, Navigation과 배치 검증이 같은 Snapshot·좌표·Shape·경계 정책을 사용한다.
- 클릭 이동, 탐험 WASD, AI 이동과 전투 이동은 같은 Traversal Domain, SpatialBodyProfile, Planner와 Executor 계약을 공유한다.
- 전투 이동 중 문, 함정, 반응, 동적 장애물과 Rule Field가 바뀌면 안전한 Progress Checkpoint에서 중단·재검증·재계획한다.
- Presentation Model이나 Chunk가 Evicted·Failed 상태여도 서버 권위 Object와 Dynamic State는 유지된다.
- Scene 전환은 Target을 준비한 뒤 새 Presence 생성과 Source Presence 정리를 의미적으로 원자 처리한다.

적용 범위:

- Campaign World와 Scene Record
- Scene Source, Semantic Profile, Scene Override와 Compiler
- Compiled Runtime Scene Build와 Layer·Index·Chunk
- Runtime Object Blueprint, Registry, Component와 Lifecycle
- Runtime Scene Snapshot과 Spatial Query Provider
- Client-safe Chunk, Projection Interest, Presentation Interest와 Ready Activation
- Traversal Domain, SpatialBodyProfile, Navigation Plan과 Movement Execution
- 탐험 클릭·WASD, 전투 클릭 이동, 강제 이동, 순간이동과 낙하의 공간 경계
- Scene Transition, Live Patch, Build Rebind와 Runtime Quick Edit
- 관련 실패, 복구, Rollback, Disclosure와 진단 경계

명시적 비범위:

- 주문별 대상 적격성, 감각·은신 판정과 최종 Perception 결과
- 문 잠금 해제, 공격, 피해, Trigger와 Reaction의 비공간 규칙 해결
- Scene Editor의 구체적 버튼 배치와 Tool 조작법
- Roblox Module, Remote, DataStore Key와 실제 파일 구조
- Polygon 생성, 공간 분할, Path Search와 Local Avoidance의 구체 알고리즘
- Chunk 크기, Query Budget, Prefetch 거리와 보정 임계값의 측정형 기본값
- 모든 Campaign Scene을 하나의 Seamless Open World로 합치는 기능

## 2. 전체 구조

### Authoring과 게시

```text
Scene Source
+ Asset Semantic Profile
+ Scene Override·Explicit Link·Region
→ Source Validation·Semantic Normalization
→ Navigation·Visibility·Interaction·Rule·Metadata Layer Build
→ Runtime Object Blueprint·State Binding·Spatial Index·Chunk
→ Cross-layer Validation
→ Immutable Compiled Runtime Scene Build
→ Atomic Publish
```

### 서버 권위 Runtime

```text
Published Build
+ Runtime Object Directory
+ Authoritative Dynamic State Revision
+ Runtime Semantic Overlay
→ Runtime Scene Snapshot
→ Spatial Query·Navigation·Perception·Rules가 읽는 권위 View
```

### Client 공개와 표시

```text
Server Raw Build·Runtime State
+ Role·Permission·Fog·Perception·Discovery
→ Permission-aware Projection
+ Client-safe Chunk Manifest
→ Streaming Activation Set
→ Client State Store·Presentation Materialization
→ Command별 Gameplay Ready Scope
```

### 이동

```text
Movement Intent
→ Navigation Request
→ Snapshot-bound Navigation Plan
→ 사용자 확인 또는 자동 승인
→ Movement Execution
→ Swept Body·Boundary Evidence·Progress Checkpoint
→ Dynamic State Commit
→ Projection·Presentation
```

### 핵심 구성 요소

- **Scene Source**: DM이 편집하고 저장하는 유일한 Scene 저작 원본이다.
- **Scene Compiler**: Source를 검증·정규화하고 여러 Runtime Layer를 하나의 불변 Build로 만든다.
- **Compiled Runtime Scene Build**: 특정 Source Revision과 Compiler Version Set에 고정된 파생 Package다.
- **Runtime Object Registry**: Scene 안에서 독립적으로 존재하는 권위 Presence의 Live Identity, Incarnation, Lifecycle과 Component Manifest를 소유한다.
- **Runtime Scene Snapshot**: Build, Dynamic State와 Runtime Overlay를 특정 Revision에서 결합한 읽기 전용 권위 View다.
- **Spatial Query Service**: Snapshot에 고정된 거리·포함·차단·점유·공간 후보와 Evidence를 제공한다.
- **Scene Streaming Coordinator**: Client별 공개 가능한 Chunk, Projection과 Presentation Interest를 계산하고 Readiness Scope를 관리한다.
- **Navigation Planner**: 목적지와 이동 정책을 Snapshot에 고정된 불변 NavigationPlan으로 변환한다.
- **Movement Coordinator**: Actor별 실행 충돌, Plan 승인, 동시 이동과 Reservation을 조정한다.
- **Movement Executor**: 승인된 Plan을 Checkpoint 단위로 실행하고 위치·비용·경계 사건을 권위 State에 반영한다.
- **Presentation Adapter**: Chunk와 Projection에서 Workspace Model, 경로 Preview, 보간과 오류 표시를 만들며 권위 결과를 확정하지 않는다.

## 3. 주요 데이터 흐름

### 3.1 Scene Source, Build와 Dynamic State

```text
Scene Source
├─ Asset·Transform·Parametric Source
├─ Semantic Profile·Instance Override
├─ Region·Link·Entry Anchor·Critical Route
└─ Authoring Revision

Compiled Build
├─ Layer Manifest
├─ Runtime Object Blueprint·State Binding
├─ Spatial Index·Dependency Graph
├─ Disclosure Segment·Chunk Manifest
└─ Build ID·Content Hash

Authoritative Dynamic State
├─ Actor Transform·State
├─ 문·함정·상자·파괴 Object 상태
├─ Runtime Object Lifecycle·Component State
├─ Runtime Effect·Rule Field·Fog
└─ Dynamic State Revision
```

다음 등식은 성립하지 않는다.

```text
Scene Source
≠ Compiled Build
≠ Authoritative Dynamic State
≠ Client Presentation
```

Source가 바뀌면 새 Candidate Build를 만든다. 문이 열리거나 Actor가 이동하는 Runtime 변경은 Source Compiler 전체를 다시 실행하지 않고 State Binding, Runtime Overlay와 관련 Index를 갱신한다.

### 3.2 Runtime Object Identity와 Presence

```text
SceneObjectId
→ Authoring Source Identity

RuntimeObjectBlueprintId
→ Compiled Build 안의 불변 Blueprint Identity

RuntimeObjectId
→ 활성 권위 Scene Presence의 Live Identity

RuntimeIncarnation
→ Archive에서 Restore된 같은 ID의 새 활성 세대

AuthorityEpoch
→ Recovery·Rollback 이후 오래된 Ref와 작업을 차단하는 권위 세대
```

Compiled Build는 Live `RuntimeObjectId`를 저장하지 않는다. Scene Compiler 계약의 초기 Blueprint 표기에 있던 `runtimeObjectId`는 Runtime Object 계약에 따라 Blueprint Identity Seed 또는 `RuntimeObjectBlueprintId`로 해석한다. Scene 활성화·Spawn 시 Registry가 Live ID를 바인딩한다.

정적 바닥과 벽은 Layer Artifact만 만들 수 있다. 문, 함정, 파괴 벽, Actor, 소환체와 Runtime Effect처럼 독립 State·Lifecycle·선택·상호작용이 필요한 Presence만 Runtime Object가 된다.

Runtime Object의 기본 Lifecycle:

```text
active
↔ suspended
→ archived
→ active 또는 suspended

active | suspended | archived
→ destroyed
```

Streaming, 화면 밖 상태와 Client Model 미생성은 `suspended`가 아니다. `destroyed`는 현재 Authority Branch에서 터미널이며 ID를 재사용하지 않는다.

### 3.3 Runtime Scene Snapshot과 Spatial Index

```text
Compiled Layer Artifact
+ Runtime Object Component State
+ Dynamic State Binding
+ Runtime-created Semantic Overlay
→ Runtime Scene Snapshot
→ Snapshot-bound Spatial Index View
```

모든 권위 Spatial Query는 하나의 `RuntimeSceneSnapshotLease`를 사용한다. Query 실행 도중 다른 Snapshot으로 넘어가거나 서로 다른 Revision의 Provider 결과를 조용히 합치지 않는다.

Query Result는 Runtime ID, Snapshot ID, World Revision과 공간 Evidence를 반환하고 Roblox Instance를 반환하지 않는다.

### 3.4 Server Runtime과 Client Streaming

다음 네 상태를 하나의 `loaded` Boolean으로 합치지 않는다.

```text
Authority Runtime Residency
Projection Interest
Presentation Interest
Streaming Activation Set Ready
```

- Authority Runtime Residency는 서버가 Scene Layer, Index와 Runtime Object State를 계산할 수 있는 상태다.
- Projection Interest는 Client가 현재 알아야 하고 권한상 받을 수 있는 권위 View다.
- Presentation Interest는 Camera, 이동 Corridor, 선택과 전환을 위해 지금 표시하거나 준비할 자료다.
- Activation Set Ready는 특정 Command Scope에 필요한 Chunk·Projection·Object View·Asset이 준비된 상태다.

Camera Transform은 Presentation Interest의 Hint일 뿐 권위 Object Lifecycle과 Disclosure를 결정하지 않는다.

```text
Raw Server Build
→ Disclosure Compiler
→ Role·Fog·Perception·Discovery 적용
→ Client-safe Chunk Manifest
+ Permission-aware Projection
→ Verified·Staged·Materialized
→ Activation Set Ready
```

Client Chunk가 Evicted되어도 서버 Object, Trigger, Ownership과 Dynamic State는 유지된다.

### 3.5 Navigation Data와 Movement State

권위 월드 비율과 이동 모델:

```text
5 ft = 4 studs
권위 위치 = 연속 좌표
권위 거리·이동 비용 = feet
권위 경로 = Compiled Traversal Domain + Transition Graph + 연속 Corridor
규칙 격자 = 없음
```

Compiled Navigation Layer는 Ground·Climb·Swim·Fly 등 Traversal Domain, Transition Graph, Obstacle, Support, Movement Cost와 관련 파생 자료를 제공한다.

Actor의 통과 가능성은 크기 등급별 고정 NavMesh가 아니라 현재 `SpatialBodyProfile`, Body Configuration, Portal Geometry, Supporting Surface와 구성 공간 판정으로 계산한다.

```text
NavigationPlan
├─ Snapshot Lease·Dependency Revision
├─ Resolved Destination·Path Corridor
├─ Segment·Transition
├─ Movement Cost·Preference Breakdown
├─ Progress Checkpoint
└─ Predicted Boundary Event
```

```text
MovementExecution
├─ 현재 Plan·Actor
├─ Last Committed Checkpoint
├─ Traversed Distance·Spent Cost
├─ Pending Timing Window·Transition
├─ Reservation
└─ Execution State
```

영구 저장에는 확정 Actor 위치를 저장한다. Path Cache, Client 보간 위치와 Preview는 저장 원본이 아니다.

## 4. 주요 실행 흐름

### 4.1 Scene 제작, Build와 게시

```text
Scene 생성
→ Stable Scene ID·기본 Entry Anchor와 Source 생성
→ Asset·구조·Region·Link 배치
→ Authoring Revision 증가
→ Scene Runtime 만들기
→ Source·Reference·Semantic Validation
→ Layer·Blueprint·Index·Chunk Build
→ Cross-layer·Critical Route·Disclosure 검사
→ Candidate Build Ready
→ Build Manifest 봉인
→ Published Build Pointer 원자 교체
```

Candidate Build가 실패하면 Published Build를 유지하고 관련 Source Object, 위치, 원인과 수정 선택지를 표시한다. 실패한 Layer 일부를 활성 Runtime에 적용하지 않는다.

### 4.2 최초 Scene 입장과 Gameplay Ready

```text
Protocol·Projection Sync
→ 대상 Published Build 선택
→ Server Authority Runtime 준비
→ Client-safe Scene Entry Essential Plan
→ 필수 Projection Segment와 Chunk 검증
→ Snapshot 원자 적용
→ Entry 주변 Presentation Materialization
→ Event Catch-up
→ Authority Ready
→ Presentation Ready
→ Control Assignment 활성화
→ Gameplay Ready
```

바닥, 벽, 문, Controlled Actor와 입력에 필요한 Essential Set이 준비되기 전에 이동·상호작용을 열지 않는다. Optional Decoration 실패는 권위 Gameplay를 막지 않을 수 있다.

### 4.3 문과 Runtime Object 상태 변경

```text
Interaction 또는 Rule Intent
→ Authoritative Command
→ Object Ref·Incarnation·Revision·권한 검증
→ State Transaction
→ Dynamic State Revision 증가
→ Compiled State Binding 적용
→ Navigation·Visibility·Interaction Index 무효화·증분 갱신
→ 새 Runtime Scene Snapshot
→ Projection Event
→ Presentation State 갱신
```

문 열림을 Source 수정이나 Scene 전체 재컴파일로 처리하지 않는다. Presentation Animation 실패가 문 상태 Commit을 되돌리지 않는다.

### 4.4 Runtime Object Spawn·Suspend·Archive·Restore·Destroy

```text
Lifecycle Command
→ Blueprint·Authority·Placement·Ownership·Link 검증
→ Component State와 ID 예약
→ Registry·Domain State·Index 변경 준비
→ CommitGroup 원자 적용
→ Lifecycle Event
→ Presentation Materialization 또는 제거 요청
```

Spawn 실패 시 부분 Component, Index Entry와 Workspace Model을 권위 Object처럼 남기지 않는다.

Archive는 Runtime 참여에서 제거하되 ID와 복구 가능한 State를 보존한다. Restore는 같은 RuntimeObjectId와 증가한 Incarnation을 사용한다. Destroy는 Tombstone과 Cleanup을 남기고 현재 Branch에서 되돌리지 않는다.

### 4.5 Spatial Query

```text
Rules·Perception·Interaction·Navigation Request
→ Query Context·Snapshot Lease·Schema 검증
→ Anchor·Shape·단위 정규화
→ Query Plan
→ Broad Phase 후보
→ Exact Geometry·Boundary·Evidence
→ Filter·Disclosure
→ 결정적 정렬
→ Immutable Result
```

Spatial Query가 제공하는 것:

- 거리, 포함, 가장 가까운 점과 Surface 투영
- Entity·Object·Volume·Portal 후보
- 점유·배치·짧은 Segment 통과 가능성
- Line of Sight·Line of Effect·Cover의 공간 Evidence
- Rule Field, Interaction과 Navigation Support Query

Spatial Query가 제공하지 않는 것:

- 전체 목적지 Path
- 감각·은신·잠금·행동 경제의 최종 규칙 의미
- Actor 위치나 Object State 변경

실패와 Budget 초과를 `대상 없음`, `빈 공간` 또는 `경로 없음`으로 위장하지 않는다.

### 4.6 탐험 클릭 이동

```text
목적지 Intent
→ Client 비권위 Preview 가능
→ Server Navigation Request
→ Snapshot-bound Plan
→ Destination·Body·Transition·Occupancy 검증
→ 단순 경로 자동 승인 또는 의미 있는 Transition 확인
→ Movement Execution
→ Checkpoint별 위치·비용 Commit
→ Projection·보간
```

문 자동 상호작용, Squeeze, Jump, 위험 영역과 큰 우회는 Plan에 명시하고 필요하면 사용자 확인을 요구한다.

### 4.7 탐험 WASD

```text
Directional Move Intent
→ 현재 권위 위치와 Traversal Domain 확인
→ 짧은 Horizon Segment·Steering·Local Replan
→ 짧은 Movement Execution
→ Server Transform Commit
→ Client Prediction Reconciliation
```

Client는 최종 CFrame을 제출하지 않는다. Render Frame마다 Remote를 보내지 않고, Humanoid·Network Ownership과 Roblox Physics에 최종 권위를 위임하지 않는다.

### 4.8 전투 이동과 중단·재계획

```text
목적지·경유점 Intent
→ Server Plan Preview
→ 거리·Rule Movement Cost·남은 이동력·Transition·예상 경계 표시
→ Player Confirm
→ Movement Budget 예약
→ Execution
→ Swept Body Boundary Evidence
→ Timing Window·Trigger·Reaction에서 Checkpoint 정지
→ 독립 RuleExecution 해결
→ Actor·Plan Dependency 재검증
→ Resume·Replan·종료
```

전투 중 비용, 위험, Transition, Route Hint와 목적지가 의미 있게 달라지는 Replan은 자동 적용하지 않고 다시 확인받는다. 이미 통과한 거리와 비용은 취소해도 환불하지 않는다.

전투 중 WASD는 토큰 Movement Intent를 만들지 않는다.

### 4.9 강제 이동, 순간이동과 낙하

강제 이동:

```text
규칙 방향·거리
→ Swept Body Segment 검사
→ 최초 차단 지점
→ 권위 위치 Commit
→ Boundary Evidence를 Rules에 전달
```

일반 Path Planner가 장애물을 피해 우회하지 않는다.

순간이동:

```text
목적지 선택
→ CanOccupy·Placement 검증
→ Teleport Command
→ 시작·종료 State 변경
```

중간 경로를 통과하지 않는다. 출발·도착 Trigger의 규칙 의미는 Rules가 판정한다.

낙하·미끄러짐·붕괴는 자발적 안전 경로를 찾지 않고 Environment Motion Policy와 Swept Body를 사용한다.

### 4.10 Movement Corridor Prefetch와 Streaming 대기

```text
Navigation Plan
→ Corridor Bounds·다음 안전 Checkpoint
→ Movement Prefetch Activation Set
→ 필수 Chunk·Object View 준비
→ Execution 시작·계속
```

자발적 이동에서 다음 구역이 늦게 준비되면 현재 유효한 Checkpoint에서 대기한다. 실제 통과한 구간까지만 비용을 소비하고, 준비 후 같은 Execution을 재개하거나 최신 Snapshot에서 재계획한다.

강제 이동과 순간이동의 권위 결과는 Client Presentation 지연 때문에 취소하지 않는다. 권위 Commit 후 Client는 Target Essential이 준비될 때까지 Streaming Veil과 입력 Gate를 사용한다.

### 4.11 Scene Transition

Prepare:

```text
Scene Transition Intent
→ Target Scene·Entry 권한 확인
→ Published Build 선택
→ Target Authority Runtime 준비
→ Entry Placement·Reservation 검사
→ Transition Ticket
→ 공개 가능한 Target Chunk Stage
```

Commit:

```text
필수 Controller Preload 확인
→ 안전 규칙 경계
→ Source·Target Precondition 재검증
→ Target Presence Batch Spawn
→ Persistent Domain Binding 연결
→ Source Presence Archive·종료
→ Transition Transaction Commit
→ 새 Projection Context·Target Dynamic State
→ Staged Chunk 활성화
→ Target Gameplay Ready
```

Character 같은 Persistent Domain Identity는 유지될 수 있지만 새 Scene Presence는 새 RuntimeObjectId를 가진다. Source와 Target Scene에 같은 Presence를 동시에 활성화하지 않는다.

### 4.12 Live Authoring, Runtime Quick Edit와 Build 교체

구조적 Authoring 변경:

```text
Scene Source 변경
→ Candidate Build
→ Compatibility·State Rebase·Runtime Object Rebind 검사
→ 안전 Checkpoint 또는 Session Pause
→ Build Pointer·State Migration·Object Rebind 원자 교체
→ 새 Index·Projection
→ 실패 시 이전 Build·Snapshot 유지
```

Runtime Quick Edit:

```text
DM Runtime Command
→ Runtime Semantic Overlay
→ Dynamic State·Index·Snapshot 갱신
```

Quick Edit는 기본적으로 Source를 변경하지 않는다. 영구화하려면 별도 `Source로 승격` 흐름으로 새 Authoring Revision과 Candidate Build를 만든다.

### 4.13 실패, Recovery와 Rollback

- Build 실패: Last Known Good Build 유지, 실패 Layer 미적용, Source 위치 진단
- 필수 Chunk 실패: 해당 Readiness Scope 닫기, Retry·Resync·안전 화면
- Optional Presentation 실패: Placeholder 또는 연출 생략, 권위 결과 유지
- Query·Planner 실패: 상태 변경 없음, 구조화된 오류와 진단
- Movement 중 Dependency 변경: Checkpoint 정지 후 Resume·Replan·종료
- Server Recovery: Snapshot·Journal에서 Runtime Object Directory와 Dynamic State 복원, Index·Presentation 재구성
- Rollback: 과거 Snapshot을 새 Branch·AuthorityEpoch에서 복원하고 오래된 Ref·Plan·Streaming Grant·Client Replica를 무효화

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — Source·Compiled Definition·Dynamic State·Presentation 분리, Compile-before-runtime, 서버 권위와 Roblox 경계
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — 불변 Build, Versioned State, Runtime Snapshot과 원자적 Build·State 교체의 공통 패턴

### Child Authority

- [`Scene Compiler와 Compiled Runtime Scene 계약`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md) — Scene Source 정규화, Layer·Blueprint·Index·Chunk Build와 원자 게시
- [`Runtime Object System과 Entity Lifecycle 계약`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md) — Live Scene Presence Identity, Component, Lifecycle, Ownership, Build Rebind와 Presentation 분리
- [`Scene Streaming, Client Interest와 Ready Activation 계약`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md) — Client-safe Chunk, Interest, Activation Set, Ready Gate, Prefetch와 Scene Transition
- [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md) — Snapshot-bound 공간 조회, Provider, Evidence, Budget와 Disclosure
- [`Runtime Navigation, Path Planning과 Movement Execution 계약`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md) — Traversal Domain, Planner, Coordinator, Executor, Checkpoint와 이동 종류
- [`Semantic Scene, World와 Runtime Build 모델`](../../systems/scene/scenes-and-world.md) — DM의 Scene 생성·Build·게시·Live Authoring 사용자 흐름
- [`Semantic Scene 기반 Navigation Authoring Pipeline`](../../systems/navigation/navigation-authoring-pipeline.md) — Semantic Profile, Override, 자동 검사, Critical Route와 검토함

### References

- [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — 공통 Source·Build·State·Command·Transaction·Projection 용어
- [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Scene 입장·Ready·Transition·Recovery와 Client Sync 상위 흐름
- [`플랫폼·이동·입력 범위`](../../product/platform-movement-and-input-scope.md) — 월드 비율, 연속 무격자 이동, 탐험·전투 입력의 제품 범위
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Lifecycle·Movement·Build 교체의 원자 Commit과 Revision
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Projection Snapshot·Event Catch-up과 Client Ready
- [`Persistence, Snapshot, Journal과 Recovery`](../../architecture/persistence-and-session-recovery-model.md) — Runtime Object·Dynamic State·Checkpoint 복구와 Rollback
- [`Scene 시스템 인덱스`](../../systems/scene/README.md) — Scene 기능별 권위 문서 진입점
- [`Navigation 시스템 인덱스`](../../systems/navigation/README.md) — Navigation 기능별 권위 문서 진입점
- [`현재 Guide 작업 순서`](../CURRENT-GUIDE-WORK-ORDER.md) — Main System Guide 단계의 현재 진행 순서

## 6. 다른 시스템과의 경계

| 인접 시스템 | Scene·World Runtime이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Scene Editor·Authoring | Source Schema, Semantic 의미 입력, Build·Diagnostic 결과 | DM Tool Intent와 Source Transaction UX | Scene World, Compiler, Editor 기획 |
| Runtime Object | Live Presence Identity, Component Manifest, Lifecycle와 Scene·Build Binding | Character·Item·Effect 등 Persistent Domain 원본 | Runtime Object 계약 |
| Session·Networking | Scene Essential, Transition Ticket, Projection·Streaming Ready Scope | Connection·Role·Control·Projection Sync와 Command Gate | Streaming, Networking, Session Guide |
| Spatial Query | Snapshot-bound 거리·점유·차단·Boundary Evidence | 규칙 의미, 감각 Capability, 상호작용 상태와 최종 적격성 | Spatial Query 계약 |
| Navigation | Traversal Domain, Path, Checkpoint, 비용·점유와 Movement State | 이동 Capability, 행동 경제, Trigger·Reaction의 규칙 해결 | Navigation, Rules·Encounter 계약 |
| Interaction | 공간상 접근 후보, Runtime Object Ref와 State Binding | 잠금·권한·Action Set과 실제 Object State Command | Compiler, Runtime Object, Interaction 문서 |
| Perception | Visibility Layer와 Line-of-Sight 공간 Evidence | Sense, Stealth, Detection과 사용자별 인식 결과 | Spatial Query, Perception 문서 |
| Rules·Encounter | Boundary Evidence, Actor Position, Movement Ledger·Checkpoint | Trigger, Reaction, Damage, Turn·Opportunity와 Forced Movement Intent | Navigation, Rule Runtime, Encounter 문서 |
| Persistence | Stable ID, Build Ref, Dynamic State, Archive·Tombstone와 확정 위치 | Snapshot·Journal·Branch·Migration·Recovery Coordinator | Runtime Object, Persistence 계약 |
| UI·Presentation | Client-safe Projection, Chunk·Object View와 권위 Path Corridor | ViewModel, Input Context, Model·VFX·Camera와 보간 | Streaming, UI·Presentation Runtime |
| Diagnostics·Simulation | Build·Object·Query·Plan·Execution Trace Reference | Correlated Trace, Scenario, Fault Injection과 Support View | 각 Runtime 계약, Diagnostics·Simulation |

고정 경계:

- Scene Source와 Dynamic State를 같은 저장 원본으로 사용하지 않는다.
- Compiled Build를 Runtime 중 제자리 수정하지 않는다.
- Layer 일부만 다른 Build Revision으로 활성화하지 않는다.
- Compiler가 Live RuntimeObjectId를 발급하거나 Dynamic State를 직접 변경하지 않는다.
- Workspace Model과 Client Chunk 존재를 Runtime Object 생존 판정에 사용하지 않는다.
- Client Camera와 Streaming 반경이 서버 Trigger·Lifecycle·Disclosure를 결정하지 않는다.
- Spatial Query가 Path를 계획하거나 State를 변경하지 않는다.
- Navigation Planner가 Actor 위치를 변경하거나 Reaction을 해결하지 않는다.
- Movement Executor가 함정 피해, 기회 공격과 Door Interaction 결과를 직접 계산하지 않는다.
- Presentation이 권위 Transform·이동 비용·충돌 결과를 확정하지 않는다.
- `Walkable`, `Deniable`, `DifficultTerrain`, Model 이름과 Roblox Collision을 리메이크 권위 입력으로 사용하지 않는다.
- 전투 WASD로 토큰을 움직이지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — 공통 권위 계층, Command와 Transaction 용어
2. [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Scene 입장·Ready·Transition·Recovery의 상위 실행 문맥
3. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 월드 Runtime 전체의 최상위 불변식
4. [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — Source·Build·State·Snapshot의 공통 구조
5. [`플랫폼·이동·입력 범위`](../../product/platform-movement-and-input-scope.md) — 월드 비율과 탐험·전투 입력 범위
6. [`Semantic Scene, World와 Runtime Build 모델`](../../systems/scene/scenes-and-world.md) — DM 기준 Scene 제작·게시·사용 흐름
7. [`ADR-0057`](../../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md) — Canonical Source와 Build 원자 활성화
8. [`Scene Compiler와 Compiled Runtime Scene 계약`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md) — Layer·Blueprint·Index·Chunk 생성
9. [`ADR-0058`](../../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md) — Stable Runtime Object Identity와 Command Lifecycle
10. [`Runtime Object System과 Entity Lifecycle 계약`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md) — Live Presence와 Lifecycle
11. [`ADR-0060`](../../decisions/ADR-0060-authority-independent-interest-managed-scene-streaming.md) — Authority와 Client Streaming 분리
12. [`Scene Streaming, Client Interest와 Ready Activation 계약`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md) — Chunk·Interest·Ready·Transition
13. [`ADR-0055`](../../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md) — Snapshot-bound Query와 Navigation 경계
14. [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md) — 공통 공간 조회와 Evidence
15. [`Semantic Scene 기반 Navigation Authoring Pipeline`](../../systems/navigation/navigation-authoring-pipeline.md) — Navigation 의미 제작과 자동 검사
16. [`ADR-0056`](../../decisions/ADR-0056-hybrid-traversal-domain-and-checkpointed-movement-execution.md) — Hybrid Traversal Domain과 Checkpoint 실행
17. [`Runtime Navigation, Path Planning과 Movement Execution 계약`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md) — Plan부터 실행·중단·재계획까지
18. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md) — Architecture 공백 해소와 Guide 작성 가능 판정

## 8. 구현·검증 순서

다음은 권위 문서의 후속 구현 명세와 의존 관계를 하나의 월드 Runtime 수직 흐름으로 정리한 것이다.

```text
Scene Record·Source·Semantic Authoring Spec
→ Scene Compiler Core·Provider·Layer Artifact Spec
→ Build Manifest·Dependency·Chunk·Atomic Publish Spec
→ RuntimeObjectRegistry·Ref Resolution·Blueprint Instantiation Spec
→ Lifecycle·Ownership·Link·Build Rebind Spec
→ Runtime Scene Snapshot·Index Assembly Spec
→ Spatial Query Context·Planner·Provider·Evidence Spec
→ Compiled Traversal Domain·SpatialBodyProfile Spec
→ Navigation Planner·NavigationPlan Spec
→ Movement Coordinator·Executor·Checkpoint·Budget Spec
→ Client-safe Chunk·Interest·Activation Set·Ready Spec
→ Movement Prefetch·Camera Veil·Presentation Materialization Spec
→ Scene Transition·Live Patch·Recovery Integration Spec
→ Diagnostics·Simulation·Cross-system Validation
```

필수 검증 흐름:

- 같은 Source와 Version Set이 같은 Build Hash를 생성
- Candidate Build 실패 중 Published Build와 활성 세션 유지
- Layer 혼합 활성화와 서로 다른 Build Chunk 혼합 활성화 거부
- Source Object ID가 배열 순서 변경으로 바뀌지 않음
- Compiler Blueprint에서 Registry가 Stable Live RuntimeObjectId를 바인딩
- Spawn·Destroy Batch의 부분 Registry·Index·Presentation 잔여 없음
- Suspended·Archived·Destroyed와 Client Evicted·Failed 상태 분리
- 문 상태가 Navigation·Visibility·Interaction에 같은 Revision으로 반영
- Runtime Quick Edit가 Source를 자동 변경하지 않음
- Client Camera가 비밀방을 향해도 Secret Chunk·Object ID 미전송
- Entry Essential Ready 이전 Movement·Interaction Command 거부
- Event가 Model보다 먼저 도착해도 Materialization 시 최신 State 적용
- Query가 같은 Snapshot에서 결정적 결과와 정렬을 반환
- Query Budget 초과를 빈 결과로 처리하지 않음
- SpatialBodyProfile별 좁은 통로, Squeeze와 Vertical Clearance 검증
- 탐험 클릭과 WASD가 같은 Traversal·Cost·Occupancy 계약 사용
- 전투 이동 중 Boundary Event에서 Checkpoint 정지와 비용 보존
- 동적 장애물 변경 후 탐험 자동 Replan과 전투 재확인 분리
- Movement Prefetch 지연 시 안전 Checkpoint 대기와 비용 중복 방지
- 강제 이동이 장애물을 우회하지 않고 최초 차단 지점에 정지
- 순간이동이 중간 Path Event를 생성하지 않음
- Scene Transition Target Spawn과 Source Archive의 부분 성공 방지
- Build Rebind·Migration 실패 시 이전 Build·Object·Snapshot 복구
- Rollback 후 이전 Epoch의 Object Ref·Plan·Streaming Grant·Ack 거부

Guide는 실제 Module·Remote·Store·Index 자료구조와 알고리즘을 정하지 않는다. 이는 Implementation Specs 단계가 소유한다.

## 9. 변경 영향 지도

| 변경 유형 | 함께 확인할 권위 문서 | 영향받을 Specs | Guide 조치 |
|---|---|---|---|
| Scene Source·Semantic Profile Schema 변경 | Scene World, Compiler, Navigation Authoring | Source·Migration·Compiler Provider | `UPDATE_REQUIRED` |
| Build Manifest·Layer·Chunk 변경 | Compiler, Streaming, Compiled Build 패턴 | Artifact·Packaging·Activation | `UPDATE_REQUIRED` |
| Runtime Object Identity·Lifecycle 변경 | Runtime Object, Persistence, Scene Transition | Registry·Lifecycle·Recovery | `UPDATE_REQUIRED` |
| Component·State Binding 변경 | Runtime Object, Compiler, Spatial Query | Component Store·Index·Projection | `UPDATE_REQUIRED` |
| Snapshot·Spatial Query 계약 변경 | Spatial Query, Runtime Principles, Navigation | Query Context·Provider·Cache | `UPDATE_REQUIRED` |
| Traversal Domain·SpatialBodyProfile 변경 | Navigation Runtime, Authoring Pipeline, Product Scope | Nav Layer·Planner·Clearance | `UPDATE_REQUIRED` |
| Movement Plan·Checkpoint·Budget 변경 | Navigation Runtime, Encounter·Rules | Planner·Executor·Ledger | `UPDATE_REQUIRED` |
| 탐험·전투 입력 범위 변경 | Product Scope, Navigation Runtime, UI Runtime | Input Adapter·Preview·Command | `UPDATE_REQUIRED` |
| Streaming Interest·Ready Scope 변경 | Streaming, Networking, Session | Chunk Planner·Activation·Gate | `UPDATE_REQUIRED` |
| Disclosure·Secret Chunk 정책 변경 | Compiler, Streaming, Perception·Permission | Disclosure Compiler·Projection | `UPDATE_REQUIRED` |
| Scene Transition·Build Rebind 의미 변경 | Streaming, Runtime Object, Compiled Build 패턴 | Transition·Migration·Recovery | `UPDATE_REQUIRED` |
| Chunk 크기·Query Budget·Prefetch·보정 수치 변경 | 각 Architecture의 남은 기본값 | Configuration·Load Test | 필요 시 갱신 |

## 10. Authority Documents

### Product

- [`플랫폼·이동·입력 범위`](../../product/platform-movement-and-input-scope.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Scene Compiler와 Compiled Runtime Scene 계약`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Runtime Object System과 Entity Lifecycle 계약`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Scene Streaming, Client Interest와 Ready Activation 계약`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation, Path Planning과 Movement Execution 계약`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Persistence, Snapshot, Journal과 Recovery`](../../architecture/persistence-and-session-recovery-model.md)

### Systems·UI

- [`Semantic Scene, World와 Runtime Build 모델`](../../systems/scene/scenes-and-world.md)
- [`Scene 시스템 인덱스`](../../systems/scene/README.md)
- [`Semantic Scene 기반 Navigation Authoring Pipeline`](../../systems/navigation/navigation-authoring-pipeline.md)
- [`Navigation 시스템 인덱스`](../../systems/navigation/README.md)

### Specs

- 아직 없음. 이 Guide의 구현·검증 순서를 기준으로 `specs/` 단계에서 작성한다.

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

## 11. ADR References

- [`ADR-0006`](../../decisions/ADR-0006-rigless-3d-token-continuous-movement.md) — Rigless 3D Token과 연속 이동
- [`ADR-0048`](../../decisions/ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md) — PC 전용, 연속 무격자 이동과 전투 WASD 제외
- [`ADR-0054`](../../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md) — Compiled Semantic Runtime과 Query Authority 원칙
- [`ADR-0055`](../../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md) — Snapshot-bound Typed Spatial Query와 Navigation 경계
- [`ADR-0056`](../../decisions/ADR-0056-hybrid-traversal-domain-and-checkpointed-movement-execution.md) — Hybrid Traversal Domain과 Checkpointed Movement Execution
- [`ADR-0057`](../../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md) — Canonical Scene Source와 Atomic Build Activation
- [`ADR-0058`](../../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md) — Stable Runtime Object Identity와 Command-driven Lifecycle
- [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md) — Versioned Command Protocol과 Projection Stream Synchronization
- [`ADR-0060`](../../decisions/ADR-0060-authority-independent-interest-managed-scene-streaming.md) — Authority-independent Interest-managed Scene Streaming
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Ordered Reservation과 Atomic Authority Transaction
- [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md) — Manifest·Chunk Snapshot, Commit Journal과 Branch Recovery
- [`ADR-0064`](../../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md) — Immutable Compiled Build와 Versioned Authoritative State

## 12. 알려진 비목표와 측정형 기본값

### 비목표

- 모든 Scene을 하나의 Seamless Open World로 합치지 않는다.
- Scene Editor를 정밀 3D 모델링·NavMesh 편집 도구로 만들지 않는다.
- Runtime Polygon, Node, Portal 폭과 Clearance를 일반 DM 편집 항목으로 노출하지 않는다.
- 모든 정적 Geometry를 Runtime Object로 등록하지 않는다.
- Roblox Workspace, Instance Replication, Physics와 PathfindingService를 권위 월드 모델로 사용하지 않는다.
- Client에 전체 Raw Build와 비밀 Geometry를 보내고 UI에서만 숨기지 않는다.
- Client Chunk·Presentation 상태를 Object Lifecycle과 합치지 않는다.
- Spatial Query를 범용 상태 변경·Path Planning Service로 만들지 않는다.
- 크기별 고정 NavMesh만으로 통과 가능성을 결정하지 않는다.
- Movement Executor가 Trigger·Reaction·Damage를 직접 해결하지 않는다.
- 전투 경로를 비용·위험 변화 후 조용히 다른 길로 바꾸지 않는다.
- 모든 장식이 준비될 때까지 Gameplay Ready를 막지 않는다.

### 측정형 기본값

다음은 Architecture 의미를 바꾸지 않는 구현·프로파일링 기본값이며 각 권위 문서의 `READY_WITH_DEFAULTS` 항목이 소유한다.

- Compiler 작업 큐, Artifact Cache, Chunk 목표 크기와 Last Known Good 보존 수
- Runtime Object Registry 파티션, Lifecycle Batch, Tombstone 보존과 Cascade 깊이
- Camera Interest 반경, Hysteresis, Chunk 전송·Cache 상한과 Ready 대기 시간
- Movement Corridor Prefetch 거리, Streaming Veil 전환과 Placeholder 품질
- Spatial Query Budget, Cache 상한, epsilon과 Composite Shape 제한
- Path Planning Budget, WASD Intent 주기, Client Prediction·보정 임계값
- Occupancy Reservation 범위, 전투 Replan 허용치와 Checkpoint 최대 간격
- Navigation 자동 분석 신뢰도, Geometry 보정 허용치와 대표 Body Profile Fixture

이 값은 기준 Scene, Actor 수, Network·Memory 조건과 실패 Scenario를 측정한 뒤 Implementation Spec에서 확정한다.

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 존재한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR을 반영했고 Specs가 아직 없음을 명시했다.
- [x] 권위 문서와 충돌하는 요약이 없다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
