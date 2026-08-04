# ADR-0066: 단일 ItemInstance와 Transaction 기반 World Presence

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Inventory, ItemInstance와 World Presence Runtime 계약`](../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Command Ordering과 Transaction Coordinator 계약`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`ADR-0030`](ADR-0030-item-instances-attack-profiles-and-weapon-mastery.md)
  - [`ADR-0051`](ADR-0051-inventory-loot-transfer-and-identification.md)

## 배경

아이템은 Character Inventory, Equipment, Container, Campaign Storage와 Scene 바닥 사이를 이동한다. 바닥에 떨어진 아이템은 선택·줍기·투척·상호작용·저장·롤백과 Streaming 대상이 된다.

Inventory 아이템을 바닥에 놓을 때 별도 Scene Item을 복제하면 다음 문제가 생긴다.

- 원본과 바닥 복사본이 동시에 존재할 수 있다.
- 수량, 충전, 식별, 저주와 Instance Modifier가 어긋난다.
- 동시 Pickup에서 중복 획득이 발생할 수 있다.
- Rollback과 복구에서 어느 복사본이 권위인지 불명확하다.
- Workspace Model의 존재 여부가 Item 생명주기에 영향을 준다.

반대로 ItemInstance에 Scene Transform과 상호작용 데이터를 모두 직접 넣으면 Inventory Domain과 Scene Runtime Object 수명주기가 섞인다.

## 결정

하나의 실제 아이템은 항상 하나의 `ItemInstance`로 유지한다.

```text
ItemInstance
└─ 하나의 배타적 Location Binding
```

바닥에 존재할 때는 ItemInstance를 복제하지 않고 다음을 연결한다.

```text
ItemInstance
+ locationKind = scene_ground
↔ Item Presence Runtime Object
```

ItemInstance는 아이템의 영구 권위 상태를 소유한다. Item Presence Runtime Object는 Scene Transform, 선택, 공간 질의, 상호작용과 Presentation 연결만 소유한다.

## 배타적 위치

ItemInstance는 같은 Authority Revision에서 다음 중 하나에만 존재한다.

```text
character_inventory
actor_equipment
container_inventory
scene_ground
campaign_storage
consumed_or_destroyed
```

위치 이동은 모두 Transaction Coordinator가 처리하는 원자적 Transfer다.

## 바닥 드롭

드롭은 다음을 한 Transaction으로 확정한다.

- Inventory 또는 Equipment Binding 제거
- 필요 시 Stack 분할
- `scene_ground` Location Binding 생성
- 서버 검증 Ground Placement 기록
- Item Presence Runtime Object Spawn
- Character Capability·무게·Equipment 파생값 무효화
- Journal, Revision과 Projection 발행

일부만 적용되는 상태는 허용하지 않는다.

## 줍기

Pickup은 ItemInstance, Item Presence, Actor Inventory와 필요한 행동 자원을 함께 예약한다.

먼저 유효하게 Commit한 요청만 성공한다. 이후 요청은 오래된 위치 또는 Revision 오류로 거부되고 최신 Projection을 받는다.

성공 시 Scene Presence는 Archive 또는 Destroy되고 동일 ItemInstance가 Inventory에 연결된다.

## 투척과 무장 해제

투척·무장 해제는 일반 Presentation 동작이 아니라 RuleExecution의 Transfer Plan이다.

Roll, Reaction과 결과가 해결된 뒤 Commit 정책에 따라 ItemInstance 위치를 `scene_ground`, Inventory, 파괴 또는 귀환 상태로 확정한다.

## Runtime Object 경계

Item Presence Runtime Object가 Stream Out되거나 Presentation Model이 제거되어도 ItemInstance와 `scene_ground` 위치는 유지된다.

Workspace Model은 Item 존재의 권위 증거가 아니다.

## Stack

부분 Stack 드롭처럼 실제로 두 독립 위치에 수량을 나눌 때만 새 ItemInstance ID를 발급한다.

Stack 분할·병합은 수량 보존, Instance 상태 호환성과 Provenance 정책을 검증하는 Transaction이다.

여러 ItemInstance를 하나의 World Bundle Model로 표시할 수 있지만 Presentation Bundle은 권위 ItemInstance를 대체하지 않는다.

## 상호작용

바닥 아이템은 Runtime Object Interaction 후보가 된다.

기본 행동은 Inspect, Pick Up, Use in Place, Move, Ping과 Journal Link를 포함할 수 있다. 실제 노출은 권한, 거리, 제어권, Identification, Encounter 비용과 Capability를 검증한다.

## 저장과 복구

Snapshot은 ItemInstance, Build Reference, Location Binding, Ground Placement와 Item Presence Binding을 저장한다.

Workspace Model, Highlight, 낙하 Animation과 Client Streaming Cache는 저장하지 않는다.

복구 시 `scene_ground` Item을 기준으로 Item Presence Runtime Object를 재구성한다.

## 결과

- Inventory와 바닥에 같은 아이템이 중복되는 문제를 구조적으로 막는다.
- 바닥 아이템을 자연스럽게 선택하고 상호작용할 수 있다.
- 동시 Pickup, Stack 분할, 투척과 무장 해제를 원자적으로 처리할 수 있다.
- Streaming과 Presentation 실패가 Item 권위 상태를 삭제하지 않는다.
- 저장·재접속·롤백에서 아이템 위치와 상태를 정확히 복원할 수 있다.

## 비목표

- 모든 바닥 Item을 물리 시뮬레이션 대상으로 만들지 않는다.
- 모든 작은 Item을 Navigation 장애물로 만들지 않는다.
- 낙하 Animation 완료를 Transfer Commit 조건으로 사용하지 않는다.
- ItemInstance와 Runtime Object를 하나의 범용 Entity로 합치지 않는다.
