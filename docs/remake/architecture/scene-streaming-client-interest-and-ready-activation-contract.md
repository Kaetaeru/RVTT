# Scene Streaming, Client Interest와 Ready Activation 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Player·DM Camera Interest의 기본 반경과 Hysteresis 거리
  - Chunk 목표 크기, 동시 전송 수와 Client 메모리 Cache 상한
  - 이동 경로 선행 Prefetch 거리와 안전 Checkpoint 대기 한도
  - Scene Transition Ready 대기 시간과 DM 강제 진행 경고 시간
  - Optional Presentation 실패 시 Placeholder 품질 단계
  - Streaming Veil과 Low-detail Proxy의 표시 전환 시간
  - Client Chunk Ack와 Cache Lease 만료 시간
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0057`](../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0060`](../decisions/ADR-0060-authority-independent-interest-managed-scene-streaming.md)
- 관련 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Runtime Navigation 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)
  - [`Semantic Scene, World와 Runtime Build 모델`](../systems/scene/scenes-and-world.md)
  - [`캠페인 로비·중도 참여·소유권·제어권`](../systems/session/campaign-lobby-hot-join-ownership-and-control.md)

## 1. 목적

이 문서는 큰 Scene, 중도 참여, 재접속, 자유 카메라와 Scene 전환에서 필요한 자료만 Client에 준비하면서도 권위 규칙과 사용자 경험을 손상시키지 않는 Streaming 계약을 정의한다.

대상:

- Compiled Scene Chunk와 Client-safe Build Package
- 사용자별 State Interest와 Presentation Interest
- Chunk Prefetch, 검증, Materialization, 활성화와 축출
- Projection Snapshot과 Streaming Plan의 결합
- Client Ready와 Gameplay Command Gate
- Scene 안 이동과 카메라 이동의 선행 로딩
- Scene 간 전환의 준비·Commit·복구
- 비밀문, 함정, 미공개 공간과 Fog 정보 보호
- Cache, Version, Build 교체, Rollback과 재접속
- Roblox StreamingEnabled와 권위 Runtime의 경계

Streaming의 목적은 서버 월드를 Client의 카메라에 맞춰 생성·삭제하는 것이 아니다.

```text
서버 권위 Scene과 Runtime Object
→ 항상 권위 계약에 따라 존재

Client가 알아야 하는 상태
→ Projection Interest

Client가 지금 표시해야 하는 자료
→ Presentation Interest와 Streaming
```

## 2. 사용자 결과

내부 계약은 다음 결과를 보장하기 위해 존재한다.

- 플레이어가 Scene에 들어갈 때 필수 벽, 바닥, 문, 토큰과 UI가 준비되기 전에 조작이 열리지 않는다.
- 카메라가 빠르게 이동해도 로드되지 않은 공간을 빈 공간이나 통과 가능한 길로 보여 주지 않는다.
- 이동 중 다음 구역이 늦게 준비되면 토큰이 보이지 않는 공간으로 계속 달리지 않고 안전한 위치에서 잠시 대기한다.
- 장식 하나가 로드되지 않았다고 전투, 이동, 문 상태와 규칙이 중단되지 않는다.
- Chunk가 Client에서 축출되어도 서버의 Actor, 함정, Trigger와 지속 효과는 유지된다.
- Scene 전환에 실패하면 원래 Scene 또는 안전한 전환 상태를 유지하고 Actor를 두 Scene에 중복 생성하지 않는다.
- 중도 참여와 재접속은 이미 가진 불변 Chunk를 재사용하고 바뀐 Projection만 Catch-up할 수 있다.
- 발견하지 않은 비밀방, 함정과 비밀문 자료를 미리 Client에 보내지 않는다.
- DM은 Chunk 경계, Interest 반경과 내부 Activation Set을 일상적으로 관리하지 않는다.
- 로딩 문제가 생기면 `Chunk 84 실패`가 아니라 어느 구역과 기능이 준비되지 않았는지 보여 준다.

## 3. 서로 다른 네 개념

다음 개념을 하나의 `loaded` Boolean으로 합치지 않는다.

### 3.1 Compiled Build Chunk

Scene Compiler가 만든 불변 Build Artifact의 분할 단위다.

- 특정 `sceneId + buildId`에 고정된다.
- Content Hash와 Schema Version을 가진다.
- 정적 Layer, Client-safe Definition 또는 Presentation 자료를 담을 수 있다.
- 권위 저장 원본이 아니다.
- Chunk 경계는 규칙 경계가 아니다.

### 3.2 Authority Runtime Residency

서버가 현재 Scene의 권위 Layer, Index, Runtime Object State와 Trigger를 계산할 수 있는 상태다.

- Client Camera와 무관하다.
- Client Chunk 축출과 무관하다.
- 권위 Object Lifecycle과 별개다.
- 로드되지 않은 서버 Artifact를 빈 공간으로 해석하지 않는다.

초기 구현에서는 활성 Scene의 권위 Navigation, Visibility, Interaction, Rule Layer와 필수 Index를 서버 메모리에 유지한다. 서버 측 세부 Artifact Eviction은 측정 후 추가할 수 있지만 같은 계약을 유지해야 한다.

### 3.3 Projection Interest

특정 Client가 현재 알아야 하며 권한상 받을 수 있는 권위 View의 범위다.

예:

- 자신의 Controlled Actor 상태
- 현재 Encounter 참가자와 순서
- 발견한 문과 상호작용 상태
- 자신의 Fog·Perception View
- 현재 Prompt와 Reaction 대상

Projection Interest는 `Authority Projection Stream`이 소유한다. Presentation Model이 없어도 Client State Store에 유지될 수 있다.

### 3.4 Presentation Interest

특정 Client가 현재 화면에 생성하거나 가까운 미래를 위해 준비해야 하는 시각·입력 자료의 범위다.

예:

- Camera 주변 구조와 토큰
- Controlled Actor의 예정 이동 Corridor
- 선택·Hover 중인 Object
- 곧 전환할 대상 Scene의 공개 가능한 정적 자료
- 현재 Encounter의 필수 연출 대상

Presentation Interest에서 빠졌다고 권위 Object가 Suspended, Archived 또는 Destroyed되지 않는다.

## 4. Chunk 종류와 공개 경계

### 4.1 Server Artifact Chunk

서버 전용 Compiled Layer와 Index다.

예:

- Raw Navigation Domain과 Portal Geometry
- Visibility Occluder Index
- Rule Trigger Boundary
- 전체 Runtime Object Blueprint와 비밀 Metadata

Player Client에 직접 전송하지 않는다.

### 4.2 Client Build Chunk

Compiler Build에서 생성한 Client-safe 불변 자료다.

초기 종류:

```text
scene_structure
presentation_definition
public_navigation_preview
interaction_shell
lighting_definition
low_detail_proxy
optional_decoration
editor_diagnostic_dm_only
custom_registered
```

`public_navigation_preview`는 로컬 Path Preview를 돕는 공개 가능한 근사 자료일 수 있지만 권위 이동 가능성, 비밀 통로와 최종 비용을 확정하지 않는다.

### 4.3 Projection Snapshot Segment

현재 권위 상태의 사용자별 View다.

- Dynamic Actor와 Object State
- Encounter와 Control Assignment
- Fog·Perception·Disclosure
- 현재 Interaction과 Prompt

Client Build Chunk와 달리 다른 사용자에게 무조건 재사용하지 않는다.

### 4.4 Presentation Asset Bundle

Mesh, Texture, Material, UI Atlas와 Presentation Definition의 실제 표시 의존성이다.

Asset Bundle의 준비 여부는 권위 Object의 존재 여부가 아니다.

## 5. Client-safe Chunk Manifest

Server Raw Chunk Manifest를 Client에 그대로 보내지 않는다.

```text
ClientSceneChunkManifestEntry
├─ clientChunkId
├─ sceneId
├─ buildId
├─ chunkKind
├─ contentHash
├─ artifactSchemaVersion
├─ coordinateBounds?
├─ dependencyChunkIds[]
├─ assetDependencyRefs[]
├─ activationGroupId
├─ priorityClass
├─ cachePolicy
├─ disclosureGrantId
├─ projectionPolicyVersion
├─ integrityPolicy
└─ estimatedSizeClass
```

### 5.1 Stable ID와 Build 고정

`clientChunkId`는 배열 순서, Workspace 이름과 전송 순서에서 만들지 않는다.

같은 Client View 안에서 서로 다른 `buildId`의 Scene Chunk를 혼합 활성화하지 않는다.

같은 Content Hash의 물리 자료를 Cache에서 재사용할 수 있어도 논리적 활성화는 현재 Build Manifest와 Disclosure Grant를 다시 검증한다.

### 5.2 Cross-chunk Reference

Chunk 경계를 넘는 Object와 Geometry는 Stable ID와 명시적 Reference를 사용한다.

- 경계에 걸친 벽이 둘로 갈라져 통과 가능한 틈이 되지 않는다.
- 한 Chunk의 문이 다른 Chunk의 문틀과 상태를 잃지 않는다.
- Query와 Movement의 권위 결과가 Chunk 경계에 따라 달라지지 않는다.
- 필요한 경우 Compiler가 Boundary Halo, Proxy 또는 Cross-chunk Dependency를 생성한다.

## 6. Streaming Activation Set

서로 함께 준비되어야 하는 자료는 `StreamingActivationSet`으로 묶는다.

```text
StreamingActivationSet
├─ activationSetId
├─ sceneId
├─ buildId
├─ projectionEpoch
├─ disclosureGrantId
├─ requiredChunkIds[]
├─ optionalChunkIds[]
├─ requiredProjectionSegments[]
├─ requiredRuntimeObjectViews[]
├─ requiredAssetBundles[]
├─ readinessScopeIds[]
├─ safeBoundaryPolicy
└─ expiresAt
```

초기 Activation Set 종류:

```text
scene_entry_essential
controlled_actor_essential
encounter_essential
camera_near
movement_corridor_prefetch
interaction_focus
scene_transition_preload
optional_decoration
```

### 6.1 원자적 의미

- 같은 Set의 필수 Chunk는 같은 Build와 Disclosure Policy에 속한다.
- 의존성이 검증되기 전에는 Interaction과 Gameplay Scope를 활성화하지 않는다.
- Presentation Model은 점진적으로 만들 수 있지만 필수 Set의 Ready는 전체 조건을 만족한 뒤 한 번에 전환한다.
- Optional Chunk 실패는 Set 전체를 실패시키지 않을 수 있다.

## 7. Interest 모델

Interest는 단순 Camera 거리 하나로 계산하지 않는다.

```text
ClientInterestContext
├─ sessionRole
├─ controlledRuntimeObjectRefs[]
├─ cameraHint
├─ activeSceneId
├─ activeEncounterId?
├─ selectedObjectRefs[]
├─ pendingPromptRefs[]
├─ movementPlanRefs[]
├─ transitionTicketRef?
├─ dmPinnedRegions[]
├─ disclosureContext
└─ clientBudgetClass
```

### 7.1 Projection Interest Source

다음은 Camera 밖이어도 State View가 필요할 수 있다.

- Controlled Actor
- 현재 Encounter 참가자와 Turn 상태
- 열린 Prompt·Reaction과 대상
- 선택한 Object의 공개 상태
- 소유 Inventory와 Character Sheet 데이터
- 알려진 장기 Interaction 상태
- Scene Transition과 Control Assignment에 필요한 상태

### 7.2 Presentation Interest Source

다음은 실제 표시·입력 자료를 우선 준비한다.

- Controlled Actor 주변
- Camera Frustum과 주변 Prefetch Ring
- 현재 이동 Corridor와 도착 지점
- 선택·Hover·Context Menu 대상
- 활성 Interaction과 Targeting Shape 주변
- Encounter 연출에 필요한 Actor
- Scene Entry·Exit와 전환 대상
- DM이 명시적으로 Pin한 구역

### 7.3 Camera는 Hint다

Client Camera Transform을 권위 Interest로 그대로 신뢰하지 않는다.

Server는 다음을 적용할 수 있다.

- Role별 최대 요청 범위
- Scene Bounds 검증
- 요청 빈도 제한
- Disclosure와 Fog 필터
- 빠른 Camera 이동의 Prefetch Budget
- DM과 Player의 서로 다른 범위 정책

Camera가 비공개 공간을 바라봤다는 이유로 비밀 Chunk를 전송하지 않는다.

## 8. Priority와 Pinning

초기 Priority Class:

```text
P0 protocol_and_session_shell
P1 scene_entry_and_controlled_actor
P2 encounter_and_near_interaction
P3 camera_near_and_movement_prefetch
P4 low_detail_and_far_known_objects
P5 optional_decoration
```

다음은 기본적으로 Pin되어 메모리 압박으로 축출하지 않는다.

- 현재 Scene Entry Essential Set
- Controlled Actor와 직접 점유하는 구조
- 활성 Encounter의 필수 View
- 열린 Prompt·Reaction 대상
- 현재 이동 Corridor의 다음 안전 Checkpoint까지 필요한 자료
- Scene Transition Commit에 필요한 Target Set
- DM이 명시적으로 Pin한 진단·편집 대상

Pin은 무기한 누적하지 않는다. Source가 사라지면 Reference Count와 Lease로 해제한다.

## 9. Disclosure와 비밀 정보

Streaming은 보안 경계다.

다음을 금지한다.

- 전체 Dungeon Geometry를 미리 보내고 Fog UI로만 가림
- 발견하지 않은 비밀문의 Transition과 RuntimeObjectId 전송
- 함정 Blueprint와 정확한 위치를 Optional Chunk에 포함
- Player가 Camera를 움직였다는 이유로 DM-only Chunk Grant 발급
- Role이 바뀐 뒤 이전 Manifest를 새 Projection에 그대로 재사용

### 9.1 공개 가능한 Chunk만 Grant

```text
Server Raw Build
→ Disclosure Compiler
→ Role·Fog·Perception·Discovery 적용
→ Client-safe Chunk Manifest와 Projection
```

공개 상태가 변하면 새로운 Grant와 Activation Set을 만든다.

이미 Client에 보낸 비밀을 완전히 회수할 수 없으므로, 추측성 Preload로 민감 자료를 미리 보내지 않는다.

### 9.2 발견 변화

비밀문이나 함정이 발견되면:

```text
Discovery Commit
→ Projection Event
→ 새 Client Chunk Grant 필요 여부 계산
→ 필요한 Definition·Presentation Chunk 전송
→ Materialization
```

발견 Event와 Chunk 준비 순서가 어긋나면 Client는 공개 상태를 저장하되 안전한 Placeholder를 사용하고 Interaction Scope를 Chunk Ready 후 활성화한다.

## 10. Client Chunk 상태 기계

```text
absent
→ requested
→ receiving
→ verified
→ staged
→ materializing
→ ready
→ evictable
→ evicted
```

실패 상태:

```text
failed_transfer
failed_integrity
failed_schema
failed_dependency
failed_materialization
revoked
expired
```

### 10.1 Verified

다음을 확인한다.

- Content Hash
- Schema Version
- SceneId와 BuildId
- Disclosure Grant
- Dependency Manifest
- Projection Policy Version

### 10.2 Staged

자료는 준비됐지만 현재 Scene View와 Object Store에 아직 활성화되지 않았다.

Scene Transition Preload는 주로 이 상태를 사용한다.

### 10.3 Ready

필수 의존성과 Materialization을 충족하고 해당 Readiness Scope에서 사용할 수 있다.

Chunk 하나의 Ready와 Activation Set 전체 Ready를 구분한다.

### 10.4 Evicted

Client 표시 자료만 제거한다.

- 서버 Object Lifecycle은 바뀌지 않는다.
- Projection State는 정책에 따라 유지할 수 있다.
- 다시 Interest에 들어오면 Cache 또는 재전송으로 복구한다.

## 11. Streaming Plan과 Network 흐름

Networking 계약의 Snapshot·Sync Control Lane을 사용한다.

```text
SceneStreamingPlan
├─ streamingPlanId
├─ sceneId
├─ buildId
├─ projectionId
├─ projectionEpoch
├─ baseViewSequence
├─ activationSets[]
├─ chunkManifestRefs[]
├─ cacheValidationRequests[]
├─ readinessScopes[]
├─ transitionTicketId?
└─ expiresAt
```

기본 흐름:

```text
1. Server가 Interest와 Disclosure 계산
2. Streaming Plan과 Client-safe Manifest 전송
3. Client가 보유 Cache Hash 보고
4. Server가 필요한 Chunk와 Snapshot Segment 전송
5. Client가 Hash·Schema·Grant 검증
6. Projection Snapshot 또는 Event Catch-up 적용
7. Chunk Stage와 Presentation Materialization
8. Activation Set Ready Ack
9. Server가 Cursor·Ack·Role을 검증
10. 해당 Gameplay Readiness Scope 활성화
```

Client Ack만으로 권위 State가 바뀌지 않는다.

## 12. Client Ready와 Streaming Ready

Networking 계약의 Ready 상태를 유지한다.

```text
connected
→ protocol_ready
→ projection_syncing
→ projection_catching_up
→ authority_ready
→ presentation_ready
→ gameplay_ready
```

Streaming은 다음 조건을 구체화한다.

### authority_ready

- 필수 Projection State가 원자 적용됨
- Event Gap 없음
- Authority·Projection Epoch 일치

### presentation_ready

- 현재 Scene의 `scene_entry_essential`
- Controlled Actor Essential Set
- 조작에 필요한 구조·Object·UI
- 안전한 Streaming Veil 경계

가 Ready다.

모든 장식과 먼 구역이 준비될 필요는 없다.

### gameplay_ready

Command별 Scope를 충족한다.

예:

```text
Camera 이동
→ authority_ready + camera shell

Actor 이동 시작
→ authority_ready + controlled actor + 현재 위치 Essential

먼 목적지 이동 Commit
→ 위 조건 + Movement Corridor의 선행 Set

문 상호작용
→ Object View + Interaction Shell + 접근 구역 Essential

전투 Targeting
→ Encounter Essential + 대상 주변 필수 Presentation
```

Ready Scope가 사라지면 관련 Command만 일시 중지한다. 전체 Client를 무조건 로비로 돌려보내지 않는다.

## 13. 최초 Scene 입장과 중도 참여

```text
Protocol Ready
→ Projection Snapshot Plan
→ Scene Entry Essential Chunk Plan
→ 필수 Projection Segment와 Chunk 검증
→ Snapshot 원자 적용
→ Entry 주변 Presentation Materialization
→ Event Catch-up
→ Authority Ready
→ Presentation Ready
→ 안전 경계에서 Control Assignment 활성화
→ Gameplay Ready
→ Optional Chunk 계속 Streaming
```

Client는 필수 구조가 없는 상태에서 Actor를 조작하지 않는다.

Entry Essential 실패 시:

- Loading 또는 복구 화면 유지
- Gameplay Command 차단
- 기존 Scene이 있으면 기존 화면 유지 가능
- Retry·대체 Build·세션 이탈 선택 제공
- 실패를 빈 Scene으로 처리하지 않음

## 14. Scene 안 Camera Streaming

Camera 이동은 Presentation Interest를 바꿀 수 있다.

```text
Camera Hint
→ Server 검증
→ Camera-near Activation Set
→ Low-detail Proxy 우선
→ 필수 구조·Object Detail 준비
→ 선택·Interaction 허용
```

Camera가 Streaming 속도보다 빠르면:

- 미준비 구역을 Streaming Veil, 낮은 상세 Proxy 또는 불투명 경계로 표시
- 그 구역의 Object 선택과 Interaction을 비활성화
- 미로드 Geometry를 투명한 빈 공간으로 표시하지 않음
- 이미 권위상 알고 있는 UI State는 유지 가능

DM은 더 넓은 Interest Budget을 받을 수 있지만 비밀 공개 정책을 우회하는 일반 Player 권한이 생기지는 않는다.

## 15. 이동 Corridor Prefetch

Navigation Preview와 Plan은 필요한 향후 Presentation 구역을 알려줄 수 있다.

```text
Navigation Plan
→ Corridor Bounds와 Checkpoint
→ Movement Prefetch Activation Set
→ 선행 Chunk 준비
→ Movement Command 또는 실행 계속
```

### 15.1 자발적 이동

플레이어가 직접 시작한 이동은 최소한 다음 안전 Checkpoint까지 필수 Presentation이 준비되어야 한다.

다음 구역 준비가 늦으면:

- Movement Executor는 현재 유효한 안전 Checkpoint에서 대기 가능
- 이동 비용은 실제 통과한 구간까지만 소비
- Client에 `다음 구역 준비 중` 상태 표시
- 준비 후 같은 권위 Movement Execution을 재개하거나 최신 Snapshot으로 재계획

Streaming 대기를 장애물이나 규칙상 이동 불가로 기록하지 않는다.

### 15.2 강제 이동과 순간이동

권위 Rules는 Client Presentation이 늦다는 이유로 필수 결과를 취소하지 않는다.

강제 이동·순간이동이 먼저 Commit되면:

- Actor의 권위 위치는 즉시 바뀔 수 있음
- 해당 Client의 이동·상호작용 Command를 준비 전까지 차단
- Streaming Veil과 안전한 위치 표시 사용
- 최신 Projection State를 Materialization 시 즉시 적용

## 16. Scene Transition의 2단계 계약

Scene 전환은 Seamless World 이동으로 가정하지 않는다.

### 16.1 Prepare 단계

```text
SceneTransitionIntent
→ 대상 Scene·Entry Anchor 권한 확인
→ 대상 Published Build 선택
→ 서버 Authority Runtime 준비
→ 대상 Entry Placement 후보와 Reservation 검사
→ SceneTransitionTicket 발급
→ 공개 가능한 정적 Target Chunk Preload
```

```text
SceneTransitionTicket
├─ transitionTicketId
├─ sourceSceneId
├─ sourceRuntimeObjectRefs[]
├─ targetSceneId
├─ targetBuildId
├─ targetEntryAnchorId
├─ participantBindings[]
├─ preloadActivationSetIds[]
├─ expectedPreconditions[]
├─ expiry
└─ transitionPolicy
```

Prepare 중에는:

- Target RuntimeObject Presence를 아직 권위 Spawn하지 않음
- Source Presence를 Archive하지 않음
- 비밀 Dynamic State를 미리 Client에 전송하지 않음
- Target의 공개 가능한 정적 Chunk만 Staged 가능

### 16.2 Commit 단계

```text
필수 Controller Client Preload 확인
→ 안전 규칙 경계 대기
→ Source·Target Precondition 재검증
→ Target Entry Occupancy 재검증
→ Target Presence Batch Spawn
→ Persistent Binding 연결
→ Source Presence Archive 또는 종료
→ Scene Transition Transaction Commit
→ 새 Projection Context와 Target Dynamic State 전송
→ Staged Chunk 활성화와 Materialization
→ Event Catch-up
→ Target Gameplay Ready
```

Target Spawn과 Source Archive는 같은 전환 Transaction의 의미적 원자성을 가진다.

실패하면 Actor를 두 Scene에 동시에 활성화하지 않는다.

### 16.3 화면 전환

권위 Commit 전에는 Source Scene을 유지할 수 있다.

Commit 후 Target Essential Presentation이 준비되는 짧은 구간에는:

- 전환 Curtain 또는 Loading Veil
- 입력 잠금
- Target Scene 상태 진행 표시
- Source Camera Freeze 또는 전환 연출

을 사용한다.

Presentation 연출이 끝나지 않아도 권위 Transaction을 다시 실행하지 않는다.

## 17. 그룹 Scene Transition

여러 Actor를 함께 이동할 수 있다.

```text
GroupTransitionPolicy
├─ atomic_participant_batch
├─ requiredControllerSet
├─ optionalObserverSet
├─ unreadyClientPolicy
└─ rollbackPolicy
```

기본 원칙:

- 같은 파티 전환은 Participant Batch로 원자 처리한다.
- Actor 일부만 Spawn되고 나머지는 Source에 남는 부분 성공을 기본으로 허용하지 않는다.
- Observer Client Ready는 권위 전환을 차단하지 않을 수 있다.
- Controller Client가 준비되지 않으면 일정 시간 대기 후 DM에게 `기다리기 / 해당 사용자 제어권을 DM으로 이전 / 전환 취소`를 제시한다.
- DM이 강제 진행하면 Actor는 권위상 Target으로 이동하고 미준비 Client는 Gameplay Ready까지 입력할 수 없다.

## 18. Projection Event와 미생성 Presentation

권위 Event는 Model이 없는 동안에도 Client State Store에 적용할 수 있다.

예:

```text
문 상태가 closed → open으로 변경
→ Door Presentation Chunk가 아직 없음
→ Client Object View에는 open 저장
→ Model Materialization 시 최신 open 상태로 즉시 생성
```

과거 Tween과 Presentation Signal을 모두 재생할 필요는 없다.

- Authority State는 최신 값을 적용
- 놓친 Presentation Signal은 만료 가능
- 규칙상 중요한 공개 기록은 Event·로그 UI로 복구

Object View에 필요한 Definition Chunk가 없으면 Interaction Command Scope를 열지 않는다.

## 19. Cache와 Version

### 19.1 Content-addressed Cache

다음은 Content Hash로 재사용할 수 있다.

- 동일 Build의 Client-safe 정적 Chunk
- 동일한 Presentation Definition과 Asset Bundle
- Low-detail Proxy

다음은 사용자 간 무조건 공유하지 않는다.

- Dynamic Projection Snapshot
- Fog·Perception View
- Role·Control 전용 Metadata
- 비밀 발견 상태가 포함된 Chunk

### 19.2 Cache 검증

재접속 시 Client는 보유 Hash를 제안할 수 있다.

Server는 다음을 다시 확인한다.

- BuildId 또는 호환 가능한 Content Hash
- Schema·Provider Version
- Disclosure Grant와 Projection Policy
- Asset Availability
- Integrity Record

### 19.3 Build 혼합 금지

같은 Scene View에서 구조는 Build A, Interaction Definition은 Build B인 상태를 활성화하지 않는다.

새 Build로 전환할 때:

- 새 Activation Set Stage
- Runtime Object Rebind와 Projection 준비
- 안전 경계에서 Build Pointer 전환
- 관련 Client Set 원자 활성화 또는 Full Scene Resync

을 사용한다.

## 20. Eviction

Eviction은 메모리·표시 자료를 정리하는 작업이다.

```text
Interest에서 이탈
→ Hysteresis와 Lease 대기
→ Pin·Dependency 확인
→ Presentation Model 제거
→ Chunk Cache 유지 또는 제거
→ Client Chunk State evicted
```

다음을 축출하지 않는다.

- 현재 Gameplay Ready에 필요한 Essential Set
- Controlled Actor와 현재 위치 구조
- 활성 Prompt·Reaction·Interaction 대상
- 다음 Movement Checkpoint 자료
- Scene Transition Staged Set
- 아직 다른 Ready Set이 의존하는 Chunk

Eviction 후에도:

- 서버 Runtime Object 유지
- 권위 Trigger와 Rule 유지
- Ownership·Link 유지
- Client Projection State는 정책에 따라 요약 유지 가능

## 21. 실패와 Fallback

### 21.1 필수 Authority Projection 실패

- Authority Ready 해제
- Gameplay Command 차단
- Event Catch-up 또는 Full Projection Resync
- 빈 State로 계속 진행하지 않음

### 21.2 필수 Scene Chunk 실패

- 해당 Readiness Scope 활성화 금지
- Retry와 Cache 무효화
- Streaming Veil 또는 안전 화면 유지
- 현재 Scene 전환 중이면 Source 또는 전환 대기 상태 유지

### 21.3 Optional Presentation 실패

- 권위 Gameplay는 계속 가능
- 안전한 Placeholder, Low-detail Proxy 또는 연출 생략
- 선택·상호작용에 필요한 Object라면 Optional이 아니라 Essential로 승격

### 21.4 Materialization 실패

Presentation Model 생성 실패가 Runtime Object를 Destroy하지 않는다.

공개 Object의 필수 시각 표현이 없으면:

- 명확한 Placeholder 사용
- 충돌·이동은 서버 권위 결과 유지
- 플레이어가 보이지 않는 필수 장애물로 피해를 입지 않도록 해당 구역 Gameplay Scope 제한
- 진단과 재시도 Queue 등록

## 22. Roblox StreamingEnabled와의 경계

Roblox StreamingEnabled, Instance Replication과 ContentProvider는 저수준 전송·표시 Adapter로 사용할 수 있다.

다음은 금지한다.

- `IsDescendantOf(workspace)`로 권위 Object 존재 판정
- Roblox가 Model을 Stream Out했다는 이유로 Object Suspend·Archive
- Client에 Part가 보인다는 이유만으로 Ready 처리
- Roblox 물리 충돌 존재 여부를 권위 Navigation과 Interaction 상태로 사용
- StreamingEnabled의 자동 반경만으로 비밀 정보 공개 결정

RVTT Ready는 Manifest, Hash, Projection Cursor, Activation Set과 Presentation Materialization 상태로 판정한다.

## 23. 서버 Authority Artifact Residency

초기 구현의 안전한 기본값:

- 활성 Scene의 권위 Layer와 필수 Index는 서버에 Resident
- 비활성 Scene은 Published Build Manifest와 저장 상태만 유지 가능
- Scene Transition Prepare에서 Target Authority Runtime을 먼저 준비
- Client Interest가 서버 권위 Trigger 활성 여부를 바꾸지 않음

향후 서버 메모리 측정 결과로 Authority Artifact Partition Eviction을 추가하려면 다음을 지킨다.

- Stable Object Directory와 Cross-partition Ref 유지
- Unloaded Partition Query를 빈 결과로 반환하지 않음
- Command 전 필요한 Partition Ready 확인
- Active Trigger·Effect와 Scheduled Work의 Wake-up 계약
- 실패 시 구조화된 `SERVER_SCENE_PARTITION_UNAVAILABLE`
- 규칙 의미가 전체 Resident 방식과 동일함을 검증

## 24. Rollback, 서버 복구와 Role 변경

### Rollback·서버 복구

AuthorityEpoch가 바뀌면:

- 기존 Projection과 Streaming Plan 만료
- Staged Activation Set 폐기 또는 재검증
- 새 Projection Snapshot과 Build Binding 확인
- Content Hash가 같아도 Runtime Object View와 Disclosure 재검증

### Role·Control·Perception 변경

공개 범위가 크게 바뀌면 Projection Epoch와 Streaming Grant를 갱신한다.

Role Downgrade 시 Client Cache에서 자료를 제거하도록 요청할 수 있지만 이미 전달한 비밀을 완전히 회수할 수는 없다. 따라서 최초 전송 단계에서 최소 공개를 지킨다.

## 25. Service 책임

```text
SceneStreamingCoordinator
├─ ClientInterestService
├─ DisclosureChunkPlanner
├─ StreamingPlanRegistry
├─ ActivationSetCoordinator
├─ ChunkTransferService
├─ ClientCacheLeaseService
├─ PresentationMaterializationTracker
├─ SceneTransitionCoordinator
├─ StreamingReadinessService
├─ StreamingBackpressureService
├─ StreamingTraceService
└─ StreamingMetrics
```

### SceneStreamingCoordinator가 하지 않는 것

- Runtime Object Lifecycle 직접 변경
- Navigation과 Perception 규칙 계산
- Character Owner와 Control Assignment 변경
- Scene Build 컴파일
- 비밀 공개를 임의 결정
- Workspace Model 존재를 Authority State로 승격

각 책임은 Runtime Object, Spatial Query, Networking, Scene Compiler와 Session Service의 공개 계약을 사용한다.

## 26. 구조화된 오류

초기 Error Code:

```text
STREAMING_PLAN_EXPIRED
STREAMING_BUILD_MISMATCH
STREAMING_DISCLOSURE_GRANT_REVOKED
STREAMING_CHUNK_NOT_FOUND
STREAMING_CHUNK_HASH_MISMATCH
STREAMING_SCHEMA_INCOMPATIBLE
STREAMING_DEPENDENCY_MISSING
STREAMING_ACTIVATION_SET_INCOMPLETE
STREAMING_MATERIALIZATION_FAILED
STREAMING_ESSENTIAL_SCOPE_NOT_READY
STREAMING_CACHE_INVALID
STREAMING_BACKPRESSURE
SCENE_TRANSITION_TARGET_NOT_READY
SCENE_TRANSITION_ENTRY_INVALID
SCENE_TRANSITION_PARTICIPANT_NOT_READY
SCENE_TRANSITION_PRECONDITION_CHANGED
SCENE_TRANSITION_COMMIT_FAILED
SERVER_SCENE_PARTITION_UNAVAILABLE
```

Error는 다음을 포함한다.

```text
errorCode
retryable
resyncRequired
readinessScopeId?
sceneId?
activationSetId?
userMessageKey
retryAfter?
traceId
```

Client에 Raw Chunk 경로, 비밀 Object ID와 서버 파일 구조를 공개하지 않는다.

## 27. 진단과 측정

측정 항목:

- Scene Entry Essential Ready까지 걸린 시간
- Projection Snapshot과 Chunk 전송 Byte
- Cache Hit·Miss와 Hash 재사용률
- Activation Set별 Ready 지연
- Camera와 Movement Prefetch 적중률
- Streaming 때문에 Movement가 대기한 횟수와 시간
- Optional Placeholder 발생률
- Chunk Eviction·Reload 반복률
- Scene Transition Prepare·Commit·Gameplay Ready 시간
- Client별 메모리와 Materialization 실패율
- Disclosure Grant 재생성 횟수

Trace는 다음을 연결한다.

```text
streamingPlanId
activationSetId
projectionId
sceneId + buildId
transitionTicketId
runtimeObjectRef
commandId
clientConnectionSession
```

성능 측정 없이 Interest 반경과 Chunk 크기가 최적이라고 주장하지 않는다.

## 28. 구현 검증 시나리오

1. 새 Client가 Entry Essential을 받은 뒤에만 Actor 이동을 시작할 수 있다.
2. Optional Decoration이 실패해도 권위 전투와 이동이 계속된다.
3. Camera가 빠르게 이동할 때 미준비 구역이 빈 공간으로 표시되지 않는다.
4. Player Camera가 비밀방을 향해도 비밀 Chunk Manifest가 전달되지 않는다.
5. Runtime Object Presentation이 Evicted되어도 서버 Object와 Trigger가 유지된다.
6. Event가 Model보다 먼저 도착하면 Materialization 시 최신 State가 적용된다.
7. Chunk Hash 불일치 시 Ready가 열리지 않고 재전송 또는 Resync가 실행된다.
8. 이동 Corridor Prefetch가 늦으면 안전 Checkpoint에서 대기하고 이동 비용을 중복 소비하지 않는다.
9. 강제 이동은 권위상 Commit되며 Client는 준비될 때까지 안전 화면과 입력 차단을 사용한다.
10. Scene Transition Prepare 실패 시 Source Presence가 유지된다.
11. Transition Commit 중 Target Spawn과 Source Archive가 부분 성공하지 않는다.
12. Group Transition에서 준비되지 않은 Controller 처리 선택이 DM에게 제공된다.
13. 재접속 Client가 유효한 정적 Chunk Cache를 재사용하고 Projection만 Catch-up한다.
14. Rollback 후 이전 Streaming Plan과 Object View가 Epoch 불일치로 무효화된다.
15. Build 교체 중 서로 다른 Build의 구조와 Interaction Chunk가 혼합 활성화되지 않는다.
16. Client Model 실패가 Runtime Object Destroy로 이어지지 않는다.
17. Roblox StreamingEnabled의 Stream Out이 권위 Lifecycle을 바꾸지 않는다.

## 29. 완료 기준

Streaming 구현 명세는 최소한 다음을 명시해야 한다.

1. Server Artifact, Client Build Chunk, Projection Segment와 Asset Bundle의 Schema
2. Chunk ID, Build ID, Content Hash와 Disclosure Grant 정책
3. Interest Source, Priority, Pinning과 Hysteresis
4. Activation Set과 Command별 Readiness Scope
5. Snapshot·Event Catch-up과 Chunk Stage 순서
6. Client Chunk 상태 기계와 Integrity Ack
7. Movement Prefetch, Camera Veil과 Essential Boundary 동작
8. Scene Transition Prepare·Commit·실패·그룹 정책
9. Cache 재사용, Eviction과 Build 혼합 방지
10. 비밀 Geometry와 Runtime Object의 최소 공개 정책
11. Roblox Adapter 경계와 Presentation 실패 Fallback
12. Rollback·재접속·Role 변경 후 Plan 무효화
13. Rate, Byte, 메모리, 동시 전송과 Backpressure Budget
14. 사용자 오류 문구와 DM 복구 선택지
15. 성능·보안·통합 테스트

중요한 항목이 빠지면 `READY`로 표시하지 않는다.

## 30. 비목표

- 모든 Campaign Scene을 하나의 Seamless Open World로 합치지 않는다.
- Chunk 경계와 Interest 반경을 일반 DM 편집 항목으로 노출하지 않는다.
- Client Camera를 서버 권위 Object Lifecycle의 원본으로 사용하지 않는다.
- Client에 전체 Raw Scene Build를 보내고 UI에서만 비밀을 숨기지 않는다.
- Streaming을 Navigation, Perception, Runtime Object Lifecycle 또는 저장 시스템의 대체물로 사용하지 않는다.
- 초기 구현에서 활성 Scene의 서버 권위 Layer까지 공격적으로 Evict하지 않는다.
- 모든 장식이 준비될 때까지 Gameplay Ready를 막지 않는다.
