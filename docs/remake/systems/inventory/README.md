# Inventory 시스템

아이템 정의와 인스턴스, 장비, 무기 공격 프로필, Weapon Mastery, 전리품, 소유권 이전과 바닥 World Presence를 다룬다.

## 상위 권위 문서

- [`Inventory, ItemInstance와 World Presence Runtime 계약`](../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
  - 불변 CompiledItemBuild와 권위 ItemInstance State
  - 배타적인 Item Location Binding
  - Inventory·Equipment·Container·Scene Ground 간 원자적 Transfer
  - 바닥 아이템의 Item Presence Runtime Object
  - 드롭·투척·무장 해제·줍기·Stack 분할과 동시 획득
  - 저장·재접속·롤백·Streaming 경계
- [`Runtime Object System과 Entity Lifecycle 계약`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - Scene에 놓인 Item Presence의 ID, Lifecycle, Spatial·Interaction Binding
- [`Command Ordering과 Transaction Coordinator 계약`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - Item, Inventory, Presence와 행동 자원의 원자적 Commit

## 시스템 문서

- [`item-weapon-attack-profile-and-mastery-model.md`](item-weapon-attack-profile-and-mastery-model.md)
  - 무기·장비·Attack Profile·Weapon Mastery와 Item Capability
- [`inventory-loot-and-item-transfer-model.md`](inventory-loot-and-item-transfer-model.md)
  - 전리품 획득, 플레이어 간 전달, 화폐, 미확인 아이템과 DM 도구

## 고정 경계

- 하나의 실제 아이템은 하나의 `ItemInstance`만 가진다.
- ItemInstance는 같은 Revision에서 하나의 권위 위치에만 존재한다.
- 바닥 아이템은 ItemInstance의 복사본이 아니라 Item Presence Runtime Object와 연결된 동일 ItemInstance다.
- Workspace Model과 Client Streaming 상태는 Item 존재의 권위가 아니다.
- 드롭, Pickup, 투척, Stack 분할·병합과 Container Spill은 모두 Transaction을 사용한다.
- Equipment와 Item Capability는 Character Build를 직접 수정하지 않고 현재 Item State에서 파생된다.

## 추천 읽기 순서

1. `../../architecture/compiled-build-and-authoritative-state-pattern.md`
2. `../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md`
3. `item-weapon-attack-profile-and-mastery-model.md`
4. `inventory-loot-and-item-transfer-model.md`
5. `../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md`
6. `../../architecture/persistence-and-session-recovery-model.md`

## Guide Status

`NOT_READY`

Item 구현 명세, Character·Effect 연결과 Inventory Completion Audit가 끝난 뒤 Main System Guide를 작성한다.
