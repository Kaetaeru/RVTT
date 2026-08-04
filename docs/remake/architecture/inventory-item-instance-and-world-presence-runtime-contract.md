# Inventory, ItemInstance와 World Presence Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 바닥 아이템 자동 정리·보존 기본 기간
  - 한 Scene Chunk의 Item Presence 목표 수
  - 자동 Stack 병합 거리와 최대 묶음 수
  - 드롭 배치 탐색 반경과 재시도 횟수
  - 전투 중 줍기·드롭 기본 Interaction Cost 표시
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0030`](../decisions/ADR-0030-item-instances-attack-profiles-and-weapon-mastery.md)
  - [`ADR-0051`](../decisions/ADR-0051-inventory-loot-transfer-and-identification.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0064`](../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
  - [`ADR-0066`](../decisions/ADR-0066-single-item-instance-with-transactional-world-presence.md)
- 상위 문서:
  - [`Compiled Build와 Authoritative State 분리 패턴`](compiled-build-and-authoritative-state-pattern.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Command Ordering과 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
- 관련 시스템:
  - [`Inventory 전리품·이전 모델`](../systems/inventory/inventory-loot-and-item-transfer-model.md)
  - [`무기·아이템·공격 프로필 모델`](../systems/inventory/item-weapon-attack-profile-and-mastery-model.md)
  - [`무설정 상호작용 Prefab 모델`](../systems/interaction/zero-metadata-interaction-prefab-and-state-transition-model.md)
- 문서 작성 규칙:
  - [`역할별 기능 접근 구분 작성 규칙`](../DOCUMENT-ROLE-ACCESS-AUTHORING-RULE.md)

## 1. 목적

이 문서는 아이템 정의, 실제 ItemInstance, Inventory·Equipment 상태, Container와 Scene 바닥에 존재하는 World Presence를 하나의 권위 흐름으로 연결한다.

플레이어는 다음을 자연스럽게 수행할 수 있어야 한다.

- 자신이 제어하는 캐릭터의 아이템을 인벤토리에서 바닥에 떨어뜨린다.
- 투척되거나 무장 해제된 무기를 Scene에서 직접 확인한다.
- 공개된 바닥 아이템을 선택하고 정보와 현재 가능한 플레이 행동을 본다.
- 가까이 이동해 줍거나, 전투 규칙에 맞는 상호작용 비용으로 획득한다.
- 허용된 상자와 시체에서 아이템을 꺼내거나 다시 넣는다.
- 규칙과 권한이 허용하면 다른 플레이어의 캐릭터에게 아이템을 넘긴다.

DM은 별도 DM Surface에서 다음을 수행할 수 있다.

- 아이템을 생성·배치·회수·강제 이전한다.
- 바닥 아이템을 저널의 Actor·Object·Dungeon Room 링크 대상으로 사용한다.
- 숨김 정보, 식별 상태, 수량, 충전과 위치를 관리한다.

재접속·서버 복구·롤백 후에도 같은 아이템과 위치가 복원되어야 한다.

## 2. 핵심 원칙

### 2.1 ItemInstance는 하나만 존재한다

바닥에 떨어뜨릴 때 Inventory Item을 복제해 별도 Scene Item을 만들지 않는다.

```text
ItemInstance
├─ definitionReference
├─ instanceState
└─ locationBinding
```

`locationBinding`이 바뀔 뿐 동일한 `itemInstanceId`를 유지한다.

```text
character_inventory
→ scene_ground
→ character_inventory
```

각 이동은 원자적 Transfer Transaction이다.

### 2.2 ItemInstance와 Scene Presence를 분리한다

ItemInstance는 아이템의 영구 권위 원본이다.

바닥에서 선택·공간 질의·상호작용·표시가 필요할 때만 Item Presence Runtime Object를 만든다.

```text
ItemInstance
+ locationBinding: scene_ground
↔ ItemPresence Runtime Object
```

Runtime Object가 스트림 아웃되거나 Presentation Model이 사라져도 ItemInstance는 삭제되지 않는다.

### 2.3 위치는 배타적이다

하나의 ItemInstance는 같은 Authority Revision에서 하나의 권위 위치만 가진다.

```text
character_inventory
actor_equipment
container_inventory
scene_ground
campaign_storage
consumed_or_destroyed
```

두 Inventory나 Inventory와 바닥에 동시에 존재할 수 없다.

### 2.4 역할별 기능을 분리한다

플레이어 정상 행동, DM 저작·관리 행동과 System 자동 처리는 같은 행동 목록에 섞지 않는다.

DM이 플레이어 행동을 테스트하거나 대신 실행할 수 있어도, DM Override와 플레이어 정상 Command는 별도 Surface·권한·Audit 의미를 가진다.

## 3. Definition, Build와 Instance

```text
ItemDefinitionSource
→ Item Compiler
→ Immutable CompiledItemBuild
→ ItemInstance State
```

### CompiledItemBuild

다음을 포함할 수 있다.

- Item kind와 태그
- Stack·수량 정책
- 무게와 용량 기여
- Equipment·Hand 요구
- Attack Mode와 Weapon Mastery 연결
- Item Action과 Capability
- Charge·소비·회복 정책
- Attunement와 Identification 정책
- World Presence Profile
- Interaction Profile
- Presentation Profile

현재 소유자, 수량, 충전, 식별 상태와 바닥 위치는 포함하지 않는다.

### ItemInstance State

```text
ItemInstanceState
├─ itemInstanceId
├─ compiledItemBuildRef
├─ quantity
├─ chargeState?
├─ conditionState?
├─ attunementState?
├─ identificationState
├─ customName?
├─ instanceModifierRefs[]
├─ provenance
├─ locationBinding
├─ worldPresenceBinding?
└─ revision
```

## 4. Item Location Binding

```text
ItemLocationBinding
├─ locationKind
├─ characterId?
├─ actorId?
├─ containerId?
├─ sceneId?
├─ groundPlacement?
├─ campaignStorageId?
└─ locationRevision
```

`locationKind = scene_ground`이면 `sceneId`와 `groundPlacement`가 필수다.

```text
GroundPlacement
├─ spatialReference
├─ orientation
├─ placementSurfaceRef
├─ placementMode
├─ dropSourceActorId?
├─ scatterSeed?
└─ placementRevision
```

클라이언트가 보낸 최종 위치를 신뢰하지 않는다. 서버가 Spatial Query와 Placement Provider로 유효한 표면을 결정한다.

## 5. Item Presence Runtime Object

바닥 Item은 다음 Component를 가진 Runtime Object로 Scene에 존재한다.

```text
ItemPresenceComponent
├─ itemInstanceId
├─ expectedItemRevision
├─ interactionProfileId
├─ pickupPolicy
├─ visibilityPolicy
└─ presenceState
```

필요에 따라 다음에 기여한다.

- Transform과 Spatial Index
- Selection·Hover
- Interaction 후보
- Perception·Fog 공개
- 작은 Occupancy 또는 Navigation 장애물
- Player Ping
- DM Journal·Object Link Target
- World Presentation

`Player Ping`과 `DM Journal Link`는 같은 기능이 아니다. 플레이어는 공개된 위치를 핑할 수 있지만, 저널의 Actor·Object·Dungeon Room 링크 작성은 DM 전용 저작 기능이다.

작은 동전이나 화살 하나를 실제 Navigation 장애물로 만들 필요는 없다. `WorldPresenceProfile`이 공간 기여 수준을 선언한다.

## 6. 바닥에 떨어뜨리기

```text
DropItemCommand
→ 권한·소유·수량 검증
→ Stack 분할 필요 여부 계산
→ 목표 지점과 배치 표면 검증
→ ItemInstance·Inventory·Equipment Reservation
→ 필요한 Item Presence Runtime Object 준비
→ Atomic Transfer Commit
→ Projection과 Presentation 생성
```

Commit 결과:

```text
Inventory Binding 제거 또는 수량 감소
+ 새 ItemInstance 생성(부분 Stack 분할 시)
+ scene_ground Location Binding
+ Item Presence Runtime Object Spawn
+ Equipment·Capability·무게 파생값 갱신
```

부분 Stack을 떨어뜨리는 경우에만 새 ItemInstance ID를 발급한다. 원본과 새 인스턴스의 수량 합은 Commit 전후 동일해야 한다.

### 안전한 배치

목표 지점이 벽 안, 통과 불가능한 공간, Scene 밖 또는 접근 불가능한 표면이면 서버가 다음 순서로 처리한다.

1. 가까운 유효 표면 탐색
2. 허용 반경 안의 안정 배치점 선택
3. 찾지 못하면 Command 거부 또는 출처 Actor 발밑 안전점 사용

정확한 기본 정책은 Command 종류별로 선언한다. 아이템을 조용히 삭제하지 않는다.

## 7. 투척과 무장 해제

투척 공격은 ItemInstance의 소유 위치를 공격 선언 즉시 바꾸지 않는다.

```text
Attack Execution
→ Item Transfer 예약
→ Roll·Reaction·결과 해결
→ Commit 정책에 따라 scene_ground 또는 회수 상태 확정
```

명중·빗나감·귀환 무기·파괴되는 탄약 등은 `ConsumptionOrTransferPlan`이 결정한다.

무장 해제도 피해나 판정과 Item Transfer를 같은 CommitGraph에서 처리한다.

## 8. 바닥 아이템 상호작용 역할표

바닥 아이템의 행동은 역할별 Surface에서 분리한다.

| 기능 | Player | DM | System | 분류와 조건 |
|---|---:|---:|---:|---|
| 공개 정보 살펴보기 | O | O | - | `SHARED`, 각 역할의 Projection 범위만 표시 |
| 제어 캐릭터로 줍기 | O | O | - | 플레이어 정상 행동. DM은 Player View 테스트 또는 제어권을 통해 사용 |
| 자신의 아이템 떨어뜨리기 | O | O | - | 플레이어 정상 행동. 소유·제어·비용 검증 |
| 위치 핑 | O | O | - | `SHARED`, 공개 가능한 위치만 전송 |
| 제자리에서 사용 | O | O | - | Capability와 규칙이 허용할 때만 표시 |
| 컨테이너 열기 | O | O | - | 공개·거리·잠금·권한 조건 적용 |
| 일반 이동·끌기 | 조건부 | O | - | Player는 규칙 Capability가 있을 때만, DM은 별도 배치 도구 사용 |
| 저널에 Actor·Object·Room 링크 작성 | - | O | - | `DM_ONLY`, DM Journal 저작 Surface |
| 숨김 정보와 실제 Definition 확인 | - | O | - | `DM_ONLY` |
| 강제 이동·회수·삭제·복원 | - | O | - | `DM_ONLY` Override, Audit 필수 |
| Stream Out Presence 복구 | - | - | O | `SYSTEM_ONLY` |
| 자동 Stack·Bundle Projection | - | - | O | `SYSTEM_ONLY` |

플레이어 Context Menu에는 DM 전용 행동을 넣지 않는다. DM 전용 기능은 DM Context Menu, DM Workspace 또는 Journal Editor에 둔다.

UI에서 숨기는 것만으로 권한을 보장하지 않는다. 서버는 Command별 Role Requirement를 검증한다.

### 줍기

```text
PickUpItemCommand
→ RuntimeObjectRef와 ItemInstanceRef 해결
→ 현재 위치·Incarnation·Revision 검증
→ Actor 제어권과 행동 가능성 검증
→ 거리·접근·필요 시 Line of Effect 검증
→ Inventory 용량·Stack 병합 검증
→ Item·Presence·Inventory Reservation
→ Atomic Transfer Commit
```

성공 시:

```text
scene_ground Binding 제거
→ Inventory Binding 추가 또는 기존 Stack 병합
→ Item Presence Runtime Object Archive/Destroy
→ Projection 갱신
```

동시에 두 플레이어가 줍는 경우 먼저 유효하게 Commit한 요청만 성공한다. 다른 요청은 `STALE_ITEM_LOCATION` 또는 최신 상태와 함께 거부된다.

## 9. Container와 바닥 아이템

상자, 시체, 가방과 Campaign Storage는 Container Inventory를 가진다.

Container 자체가 Scene에 존재하면 Runtime Object와 Container Domain State가 연결된다.

```text
Container Runtime Object
↔ ContainerId
↔ ItemInstance Location Bindings
```

Container가 파괴될 때 내용물 처리 정책은 명시적이다.

```text
spill_to_ground
transfer_to_parent
remain_in_destroyed_container
consume_contents
custom_registered
```

`spill_to_ground`는 내용물을 Batch Transfer하고 유효한 배치점에 Item Presence를 생성한다.

## 10. Stack과 World Bundle

같은 Definition이라고 무조건 같은 ItemInstance로 합치지 않는다.

Stack 병합은 다음이 모두 호환될 때만 가능하다.

- Stack Profile
- Identification 상태
- Instance Modifier
- Charge·Condition 상태
- Provenance 병합 정책
- 소유·Container 정책

바닥에서 여러 개가 시각적으로 하나의 묶음으로 보일 수 있지만, 권위적으로는 하나 이상의 ItemInstance를 참조하는 `WorldItemBundlePresentation`일 수 있다. Presentation Bundle은 ItemInstance 원본을 대체하지 않는다.

## 11. 권한과 비밀 정보

미확인 아이템의 실제 Definition ID, 저주, 숨겨진 Charge와 DM Metadata를 권한 없는 Client에 보내지 않는다.

```text
Authority ItemInstance
→ Identification·Perception·Permission 적용
→ Item Projection
```

바닥 Model이나 이름으로 비밀 정보를 누출하지 않도록 공개 Presentation Profile을 별도로 선택한다.

플레이어와 DM Projection은 명시적으로 분리한다.

```text
Player Item Projection
→ 공개 이름, 공개 설명, 공개 가능한 행동과 위치

DM Item Projection
→ 실제 Definition, 숨김 속성, 저주, 내부 상태와 관리 행동
```

## 12. Persistence, Recovery와 Rollback

Snapshot은 다음을 저장한다.

- ItemInstance State
- CompiledItemBuild Reference와 Hash
- Location Binding
- Container Relation
- Equipment·Attunement State
- scene_ground Placement
- Item Presence Runtime Object Binding
- Revision과 Transaction Commit Marker

저장하지 않는 것:

- Workspace Model
- Highlight·Hover 상태
- Tween·낙하 애니메이션
- Client Streaming Cache
- 임시 World Bundle Presentation

복구 시 ItemInstance를 먼저 복원하고 `scene_ground` Binding에 따라 Item Presence Runtime Object를 재구성한다.

Rollback은 과거 Branch의 Inventory, Item 위치, 바닥 공개 상태와 Presence를 함께 복원한다.

## 13. Streaming과 Presentation

Item Presence의 Materialization은 Client Streaming과 독립된 권위 상태다.

미로드 구역의 바닥 아이템은 서버에 계속 존재한다. 권한과 Interest 범위가 허용될 때 Client-safe Projection과 Presentation Asset을 보낸다.

필수 상호작용 대상의 Model 로드가 실패하면 보이지 않는 상태에서 줍게 하지 않고 해당 Interaction Scope를 일시 차단한다.

## 14. DM 전용 명령

다음은 Player Context Menu에 노출하지 않는 DM 전용 관리 기능이다.

- Spawn Item
- Drop/Place Item Override
- Force Transfer Item
- Split/Merge Stack Override
- Set Quantity·Charge·Condition
- Identify/Conceal Item
- Link Item Presence to Journal·Actor·Object·Dungeon Room
- Recall to Campaign Storage
- Destroy/Restore Item

DM Override는 게임 규칙상의 거리·비용을 우회할 수 있지만 ID, Location 배타성, Revision, Journal과 Atomic Commit은 우회할 수 없다.

DM이 제어권을 가진 Actor로 일반 줍기·사용·드롭을 수행할 때는 Player Command 경로를 그대로 사용한다. 별도 Override를 사용한 경우에는 감사 로그에서 구분한다.

## 15. 실패 코드 예시

```text
ITEM_NOT_FOUND
STALE_ITEM_REVISION
STALE_ITEM_LOCATION
ITEM_ALREADY_RESERVED
ROLE_NOT_ALLOWED
CONTROL_AUTHORITY_REQUIRED
INVALID_DROP_SURFACE
NO_VALID_GROUND_PLACEMENT
PICKUP_OUT_OF_RANGE
PICKUP_PATH_BLOCKED
INVENTORY_CAPACITY_EXCEEDED
STACK_INCOMPATIBLE
ITEM_PRESENCE_NOT_READY
ITEM_LOCATION_CONFLICT
```

## 16. 성능 원칙

- Item마다 Heartbeat Loop를 만들지 않는다.
- 바닥 Item은 Spatial·Interaction Index에 등록한다.
- 멀리 있는 Presentation은 Stream Out 가능하다.
- 작은 동일 아이템은 World Presentation Bundle로 묶을 수 있다.
- 권위 ItemInstance와 위치는 묶음 표시와 관계없이 개별적으로 보존한다.
- 대량 Spill·Loot는 Batch Transaction과 Chunked Projection을 사용한다.

## 17. 비목표

- Roblox Physics 결과를 최종 Item 위치 권위로 사용하지 않는다.
- Workspace Model을 ItemInstance 원본으로 사용하지 않는다.
- 바닥에 놓였다는 이유로 ItemDefinition을 복제하지 않는다.
- 모든 작은 Item을 Navigation 장애물로 만들지 않는다.
- Pickup Animation 완료를 권위 Transfer 조건으로 사용하지 않는다.
- DM 전용 저널·관리 기능을 Player Context Menu에 섞지 않는다.