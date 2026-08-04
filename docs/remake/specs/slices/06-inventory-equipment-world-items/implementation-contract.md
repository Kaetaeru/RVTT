# Implementation Spec — Slice 06 Inventory·Equipment·World Items

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Item·Container·Equipment·World Presence Schema와 Legacy 데이터가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 계약: [`Character`](../05-character-foundation-creation/implementation-contract.md), [`Exploration`](../03-exploration-interaction-perception/implementation-contract.md), [`Core Rules`](../02-core-rules-kernel/implementation-contract.md)
- 관련 Guide: [`Character`](../../../guides/character/README.md), [`Exploration`](../../../guides/exploration/README.md), [`Scene`](../../../guides/scene/README.md), [`Rules`](../../../guides/rules/README.md), [`UI`](../../../guides/ui/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> Item은 Inventory Table과 Ground Model에 각각 복제되는 데이터가 아니다. 하나의 ItemInstance가 정확히 하나의 Location Binding을 가지며, World Presence는 그 Binding의 Runtime 표현이다.

## 1. Acceptance Flow

```text
Loot 확인
→ Pickup 요청
→ ItemInstance Location 이전
→ Inventory에서 확인
→ Equip·Unequip
→ Capability·Attack Profile 갱신
→ Drop
→ Ground Presence 생성
→ Reconnect 후 동일 위치 복구
```

DM은 Item의 Definition·Instance·Location·Identification·Owner와 World Presence를 구분해 확인하고, 강제 이전도 Command·Audit 경계를 사용한다.

## 2. 직접 권위 문서

- [`Inventory, ItemInstance와 World Presence Runtime`](../../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
- [`Character Runtime과 Compiled Character Build`](../../../architecture/character-runtime-and-compiled-character-build-contract.md)
- [`Rules Content Grant와 Capability`](../../../architecture/rules-content-grant-capability-model.md)
- [`Runtime Object System과 Entity Lifecycle`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Spatial Query Engine`](../../../architecture/spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation과 Movement Execution`](../../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Cross-Domain Outcome Cascade`](../../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`무기·아이템·공격 Profile과 Mastery`](../../../systems/inventory/item-weapon-attack-profile-and-mastery-model.md)
- [`Inventory·Loot·Item Transfer`](../../../systems/inventory/inventory-loot-and-item-transfer-model.md)

## 3. 범위

포함:

- Item Definition·Compiled Item Build·ItemInstance
- Location Binding: Inventory, Container, Equipment, Ground, Transit
- Stack, Quantity, Currency와 Identification
- Equipment Slot, Hand, Attunement와 Conflict
- Weapon Attack Profile와 Mastery Capability
- Loot, Pickup, Drop, Transfer와 동시성
- Ground Presence·Streaming·Materialization
- Inventory Projection·Persistence·Migration·Rollback

제외:

- 전체 공식 Equipment Catalog
- Crafting과 Shop·Economy
- 현실 Physics 기반 Item Ownership

## 4. Type와 불변식

```lua
export type ItemInstance = {
    itemInstanceId: string,
    itemDefinitionRef: string,
    itemBuildVersion: string,
    instanceRevision: number,
    quantity: number,
    identificationState: string,
    customState: {[string]: unknown},
}

export type ItemLocationBinding = {
    itemInstanceId: string,
    locationKind: "inventory" | "container" | "equipment" | "ground" | "transit",
    ownerRef: string,
    slotRef: string?,
    sceneRuntimeRef: string?,
    worldPosition: {x: number, y: number, z: number}?,
    bindingRevision: number,
}

export type EquipmentBinding = {
    characterId: string,
    itemInstanceId: string,
    equipmentSlotId: string,
    handState: string?,
    attunementState: string?,
    revision: number,
}

export type ItemWorldPresence = {
    presenceId: string,
    itemInstanceId: string,
    sceneRuntimeRef: string,
    runtimeObjectRef: string,
    presenceIncarnation: string,
    revision: number,
}
```

불변식:

- ItemInstance는 동시에 두 Location에 존재하지 않는다.
- Ground Presence가 Stream Out돼도 ItemInstance는 사라지지 않는다.
- Workspace Model은 Item 권위 원본이 아니다.
- Stack Split·Merge 전후 전체 수량은 보존된다.
- Equipment는 Character Source를 제자리 수정하지 않고 Capability Contribution을 제공한다.

## 5. Definition·Build·Instance

```text
Item Definition Source
→ Item Compiler
→ Immutable Item Build
→ ItemInstance 생성
→ Location Binding
```

Definition은 Stable Content ID·Version, Tag, Slot·Stack·Use·Attack Profile·Capability Contribution을 가진다. Instance는 내구도·수량·식별·개별 이름 같은 상태만 저장한다. Localization은 ID와 Authority Digest를 대체하지 않는다.

## 6. Pickup·Transfer·Drop

```text
Pickup Intent
→ Actor Control·Range·Path·Visibility 검증
→ Item Presence·Binding Revision 검증
→ Destination Container Capacity 검증
→ Ordering Reservation
→ Ground Binding 제거 + Inventory Binding 생성
→ Atomic Commit
→ Presence Despawn Event·Inventory Projection
```

Drop:

```text
Item·Owner·Quantity 검증
→ Valid Placement Query
→ Stack Split 필요 시 새 ItemInstance Plan
→ Inventory·Equipment Binding 제거
→ Ground Binding + Runtime Presence Plan
→ Atomic Commit
```

Transfer는 Source와 Destination Container, ItemInstance, Character Equipment Revision을 결정적 Ordering Key로 사용한다. Client Drag 위치와 Physics Landing은 권위 결과가 아니다.

대표 실패 코드:

```text
ITEM_NOT_FOUND
ITEM_LOCATION_STALE
ITEM_ALREADY_CLAIMED
CONTAINER_CAPACITY_EXCEEDED
EQUIPMENT_REQUIREMENT_FAILED
EQUIPMENT_SLOT_CONFLICT
DROP_PLACEMENT_INVALID
ITEM_VERSION_UNSUPPORTED
```

## 7. Equipment·Capability·Attack Profile

Equip 실행:

```text
Item·Character·Slot 선택
→ Requirement·Hand·Attunement·Conflict 검증
→ Equipment Binding Proposal
→ Character Capability·Derived View Invalidation
→ Atomic Commit
→ Sheet·Inventory·Action Projection Barrier
```

Attack Profile은 Item Definition, Character Build·State, Equipment Binding, Mastery·Effect Contribution과 Frozen Rules Policy에서 파생한다. UI가 계산한 Hit Bonus·Damage·Range를 저장하거나 Command에 결과로 제출하지 않는다.

Unequip이 현재 RuleExecution·Reservation과 충돌하면 안전 Boundary 또는 명시적 실패를 사용한다.

## 8. Identification·Disclosure

Item 공개 정보는 Viewer Context를 따른다.

```text
unseen
→ appearance_known
→ partially_identified
→ fully_identified
```

비식별 Player에게 실제 Definition ID, Secret Property, Curse, 정확한 Value와 DM Note를 보내지 않는다. Search·Tooltip·Error·Diagnostic도 같은 Disclosure Policy를 사용한다.

## 9. World Presence·Streaming

Ground Location Binding이 권위 원본이다. Runtime Presence는 Scene Interest와 Streaming에 따라 Materialize한다.

```text
Ground Binding
→ Scene Interest
→ Prefab·Runtime Object 생성
→ ItemWorldPresence Incarnation
```

Materialization 실패 시 Item을 삭제하지 않는다. Safe Placeholder, Retry 또는 DM Diagnostic을 제공하며 Ground Binding을 유지한다. 같은 Binding에서 중복 Presence가 생기면 한 Incarnation만 활성화하고 Incident를 기록한다.

## 10. Persistence·Migration·Rollback

저장:

- ItemInstance·Definition Version
- Location Binding·Equipment Binding
- Stack·Identification·Custom State
- Ground Scene·좌표·Presence Mapping Ref
- Transfer·Split·Merge Journal

저장하지 않음:

- Drag Ghost·Hover·Tooltip
- Physics Velocity·Network Ownership
- Streamed Model Instance 경로

Pack 제거·Definition Migration은 사용 중 Item Reference를 검사한다. Missing Definition을 이름이 비슷한 Item으로 자동 대체하지 않는다. Read-only Placeholder와 Migration Review를 제공한다. Rollback은 Item·Location·Equipment·Presence Snapshot을 새 AuthorityEpoch에서 복원한다.

## 11. UI·Diagnostics·Test

필수 UI 상태:

```text
Pickup 처리 중
다른 사용자가 먼저 획득
Container 가득 참
장착 조건 불충족
Slot Conflict
Ground 배치 실패
Item 정보 일부 비공개
동기화·Recovery 중
```

Trace:

```text
item.create
item.transfer
item.pickup
item.drop
item.stack_split
item.stack_merge
item.equip
item.unequip
item.presence_materialize
item.migrate
```

Test:

1. 정상 Pickup→Equip→Drop→Reconnect.
2. 같은 Item 동시 Pickup 단일 승자.
3. Stack Split·Merge 수량 보존.
4. Equipment Slot·Hand·Attunement Conflict.
5. Equip 후 Capability·Attack Profile 갱신.
6. Stream Out·Materialization 실패 후 Item 보존.
7. Invalid Client CFrame·Model Ref 거부.
8. 비식별 Item Negative Disclosure.
9. Transfer Commit 직후 Restart 복구.
10. Rollback 이전 Transfer Command 차단.
11. Missing Definition Version에서 Read-only Recovery.
12. 대량 Container·Ground Item Projection Budget 측정.

## 12. 구현 순서와 완료 기준

```text
Definition·Build·Instance
→ Location·Container·Stack
→ Equipment·Attack Profile
→ Pickup·Drop·Transfer
→ World Presence·Streaming
→ Projection·Migration·Recovery·Test
```

완료 기준:

- 단일 ItemInstance와 단일 Location 불변식 유지
- Equipment와 World Presence가 Character·Scene 권위 Store를 복제하지 않음
- 동시 Pickup·Transfer가 Transaction으로 해결됨
- 정보 공개·Migration·Restart·Rollback이 정의됨

Production 구현 전 실제 Item·Inventory·Presence·UI Schema Mapping이 필요하다.