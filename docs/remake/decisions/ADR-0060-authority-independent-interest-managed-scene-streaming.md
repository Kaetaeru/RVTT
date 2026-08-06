# ADR-0060. 권위와 분리된 Interest 기반 Scene Streaming

- 상태: 확정
- 작성일: 2026-08-03
- 결정 범위: Scene Chunk, Client Interest, Presentation Materialization, Client Ready, Scene Transition과 Streaming 실패 복구
- 관련 문서:
  - [`Scene Streaming, Client Interest와 Ready Activation 계약`](../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`Semantic Scene, World와 Runtime Build 모델`](../systems/scene/scenes-and-world.md)
  - [`캠페인 로비·중도 참여·소유권·제어권`](../systems/session/campaign-lobby-hot-join-ownership-and-control.md)

## 배경

RVTT는 큰 Scene, 자유 카메라, 중도 참여, 재접속, 여러 Actor와 Scene 전환을 지원해야 한다.

Client Camera와 Roblox Instance Streaming을 권위 상태와 직접 연결하면 다음 문제가 생긴다.

- 화면 밖 Chunk의 Actor, 함정과 Trigger가 삭제되거나 비활성화됨
- 아직 로드되지 않은 벽과 바닥이 빈 공간 또는 통과 가능한 길로 보임
- Presentation Model 실패가 Runtime Object 파괴로 이어짐
- 중도 참여 Client가 필수 구조를 받기 전에 이동·공격을 시작함
- 전체 Dungeon Geometry와 비밀문·함정 Definition이 Player Client에 미리 전달됨
- Scene 전환 중 Source Actor가 사라졌지만 Target Actor 생성은 실패하는 부분 상태 발생
- 서로 다른 Build의 구조, Interaction과 Presentation Chunk가 혼합됨
- Event가 Model보다 먼저 도착했을 때 상태를 잃거나 오래된 Animation을 다시 실행함
- Roblox StreamingEnabled의 Instance 존재 여부가 규칙 결과와 Ready 상태를 결정함

반대로 모든 Scene 자료와 장식을 모든 Client에 항상 전송하면 로딩, 메모리와 중도 참여 비용이 커지고 비밀 정보 보호가 어려워진다.

## 결정

### 1. 서버 권위 Runtime과 Client Streaming을 분리한다

Client Chunk의 `ready`, `evicted`, `failed`는 Runtime Object의 `active`, `suspended`, `archived`, `destroyed`와 다른 상태다.

Client Camera, Chunk 축출과 Presentation 실패가 서버 Object Lifecycle, Trigger, Navigation과 Rule 상태를 변경하지 않는다.

초기 구현에서는 활성 Scene의 권위 Layer와 필수 Index를 서버에 유지한다.

### 2. Build Chunk, Projection과 Presentation 자료를 구분한다

- `Server Artifact Chunk`: 서버 전용 Compiled Layer와 Index
- `Client Build Chunk`: 공개 가능한 불변 Scene Definition과 Presentation 자료
- `Projection Snapshot Segment`: 사용자별 Dynamic Authority View
- `Presentation Asset Bundle`: Mesh, Texture와 표시 의존성

이 네 종류를 하나의 Scene Blob 또는 `loaded` Boolean으로 합치지 않는다.

### 3. Projection Interest와 Presentation Interest를 분리한다

Projection Interest는 Client가 권한상 알아야 하는 상태 범위다.

Presentation Interest는 Camera, Controlled Actor, 이동 Corridor, Encounter, 선택 대상과 Scene Transition에 따라 지금 표시할 자료 범위다.

Camera 밖의 Encounter State는 Projection에 남을 수 있고, Presentation Interest에서 빠진 Object Model은 축출할 수 있다.

### 4. Interest는 Server가 계산한다

Client Camera는 제한된 Hint다.

Server는 Role, Control, Scene Bounds, Fog, Perception, Discovery, 요청 빈도와 Budget을 적용한다.

Camera가 비공개 공간을 향했다는 이유로 비밀 Chunk를 전송하지 않는다.

### 5. Client-safe Manifest와 Disclosure Grant를 사용한다

Server Raw Chunk Manifest를 Player에게 보내지 않는다.

Client Chunk는 SceneId, BuildId, Content Hash, Dependency, Activation Group, Disclosure Grant와 Projection Policy Version을 가진다.

발견하지 않은 비밀방, 함정, 비밀문의 실제 Geometry, Transition, Blueprint와 RuntimeObjectId를 추측성 Prefetch로 보내지 않는다.

### 6. 함께 필요한 자료는 Activation Set으로 준비한다

Scene Entry, Controlled Actor, Encounter, Movement Corridor, Interaction과 Scene Transition 자료는 `StreamingActivationSet`으로 묶는다.

필수 Chunk, Projection Segment, Runtime Object View와 Asset Bundle이 검증되기 전에는 해당 Gameplay Readiness Scope를 열지 않는다.

Optional Decoration 실패는 권위 Gameplay를 중단하지 않는다.

### 7. Streaming Ready는 Networking Ready를 구체화한다

- `authority_ready`: Projection Snapshot과 Event Catch-up 완료
- `presentation_ready`: Scene Entry와 Controlled Actor Essential Set 준비
- `gameplay_ready`: Command별 필요한 Activation Set 준비

Client의 Ready 주장만 신뢰하지 않고 Server가 Hash, Segment Ack, Projection Cursor, Role과 Activation Set을 확인한다.

### 8. 미준비 구역을 빈 공간으로 표시하지 않는다

Camera가 Streaming보다 빠르면 Streaming Veil, 불투명 경계 또는 Low-detail Proxy를 사용한다.

필수 구조가 없는 구역의 선택과 Interaction을 비활성화한다.

Player가 보이지 않는 필수 장애물로 인해 불합리한 피해를 받지 않도록 해당 Gameplay Scope를 제한한다.

### 9. 자발적 이동은 Corridor를 선행 준비한다

Navigation Plan은 향후 이동 Corridor의 Presentation Interest를 생성할 수 있다.

다음 구역이 늦게 준비되면 자발적 이동은 안전 Checkpoint에서 대기할 수 있으며 실제 통과한 비용만 소비한다.

Streaming 대기를 규칙상 장애물이나 이동 실패로 기록하지 않는다.

강제 이동과 순간이동은 Client Presentation이 늦다는 이유로 권위 결과를 취소하지 않으며, Client 입력만 준비 전까지 제한한다.

### 10. Scene Transition은 Prepare와 Commit으로 나눈다

Prepare 단계에서 Target Scene Build, Entry Anchor, 서버 Authority Runtime과 Placement를 검증하고 공개 가능한 정적 Chunk를 Stage한다.

Target Runtime Presence는 아직 만들지 않고 Source Presence도 유지한다.

안전 경계에서 Commit할 때 Target Presence Batch Spawn, Persistent Binding, Source Presence Archive와 Scene Context 변경을 원자적으로 처리한다.

부분 성공으로 Actor가 두 Scene에 동시에 존재하거나 어느 Scene에도 없는 상태를 허용하지 않는다.

### 11. 그룹 전환은 Participant Batch로 처리한다

같은 파티 전환은 기본적으로 원자적 Participant Batch다.

준비되지 않은 Controller가 있으면 기다리기, 제어권을 DM으로 이전, 전환 취소를 DM에게 제시한다.

DM이 강제 진행하면 Actor는 Target으로 이동하고 미준비 Client는 Gameplay Ready까지 입력할 수 없다.

### 12. Event와 Model 생성 순서를 분리한다

Authority Projection Event는 Presentation Model이 없어도 Client State Store에 적용한다.

Model이 나중에 생성되면 최신 State를 즉시 적용한다.

놓친 Tween, VFX와 Camera Cue는 재생하지 않아도 되지만 권위 상태와 규칙 로그는 보존한다.

### 13. Chunk는 Content Hash로 Cache하되 Build와 공개 범위를 다시 검증한다

정적 Client-safe Chunk와 Asset Bundle은 재사용할 수 있다.

Dynamic Projection, Fog, Perception과 비밀 발견 상태는 사용자 간 무조건 공유하지 않는다.

같은 Scene View에서 서로 다른 Build의 구조와 Interaction Chunk를 혼합 활성화하지 않는다.

### 14. Eviction은 Presentation 정리다

Interest 이탈 후 Hysteresis, Lease, Pin과 Dependency를 검사해 Model과 Cache를 정리한다.

Eviction은 서버 Runtime Object, Trigger, Ownership, Link와 Dynamic State를 변경하지 않는다.

### 15. Roblox StreamingEnabled는 Adapter다

Roblox Instance의 Stream In·Out은 저수준 표시 최적화다.

Instance 존재 여부로 Authority Object 존재, Navigation, Interaction, Disclosure와 Client Ready를 판정하지 않는다.

RVTT Ready는 Manifest, Hash, Projection Cursor, Activation Set과 Materialization 상태로 결정한다.

### 16. 필수 실패와 선택적 실패를 분리한다

필수 Projection 또는 Essential Chunk 실패 시 관련 Gameplay Scope를 열지 않고 Catch-up, Retry 또는 Full Resync를 수행한다.

Optional Presentation 실패는 Placeholder 또는 연출 생략으로 격리한다.

로드 실패를 빈 State와 빈 공간으로 변환하지 않는다.

## 결과

- Client Streaming이 서버 Rules와 Runtime Object Lifecycle을 변경하지 않는다.
- 필요한 구역만 준비하면서도 필수 구조가 없는 상태의 조작을 막을 수 있다.
- 중도 참여와 재접속에서 정적 Cache와 Dynamic Projection을 분리해 재사용할 수 있다.
- 비밀 Geometry와 Runtime Object 정보를 최소 공개할 수 있다.
- 이동과 Scene Transition이 로딩 실패 때문에 부분 적용되지 않는다.
- Presentation Model이 늦거나 실패해도 권위 상태를 보존한다.
- Scene Build, Projection Epoch와 Chunk Version을 일관되게 관리할 수 있다.
- Roblox StreamingEnabled를 사용하더라도 자체 Ready·Disclosure 계약을 유지한다.

## 비용과 주의점

- Client-safe Chunk Compiler, Disclosure Chunk Planner와 Activation Set Coordinator가 필요하다.
- 사용자별 Interest와 Projection을 계산하고 Cache·전송 Budget을 관리해야 한다.
- Scene Transition의 Preload, Placement Reservation과 원자적 Presence Transfer가 필요하다.
- Client는 Chunk Integrity, Dependency, Materialization과 Eviction 상태를 추적해야 한다.
- 숨겨진 Geometry를 최소 공개하려면 Chunk와 Disclosure Segment 경계를 신중히 생성해야 한다.
- Camera와 Movement Prefetch의 실제 반경은 측정으로 조정해야 한다.

## 비목표

- 모든 Scene을 Seamless Open World로 전환하지 않는다.
- Chunk 경계를 DM이 수동 편집하게 하지 않는다.
- 초기 구현에서 활성 Scene 서버 권위 Layer를 공격적으로 Evict하지 않는다.
- Streaming을 Runtime Object Lifecycle, Navigation, Perception, Persistence와 Networking의 대체물로 만들지 않는다.
- 모든 장식이 준비될 때까지 Gameplay Ready를 막지 않는다.
