# Inventory 시스템

아이템 정의와 인스턴스, 장비, 무기 공격 프로필, Weapon Mastery, 전리품, 소유권 이전과 바닥 World Presence를 다룬다.

## 관련 Main System Guide

- `Character, Inventory와 Downtime Guide`
  - 현재 Main System Guide 작업 순서 7번에서 작성 중이다.
  - ItemDefinition·CompiledItemBuild·ItemInstance·Equipment·Location Binding·World Presence와 Crafting Completion을 통합한다.
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)
  - Item Capability·Attack Profile·소비 자원이 RuleExecution과 PendingEffect로 이어지는 경계
- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
  - 전투 중 Pickup·Drop·Equip·Throw가 Opportunity·Movement·Turn 경계를 사용하는 방식

## 상위 권위 문서

- [`Inventory, ItemInstance와 World Presence Runtime 계약`](../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
  - 불변 CompiledItemBuild와 권위 ItemInstance State
  - 배타적인 Item Location Binding
  - Inventory·Equipment·Container·Scene Ground 간 원자적 Transfer
  - 바닥 아이템의 Item Presence Runtime Object
  - 드롭·투척·무장 해제·줍기·Stack 분할과 동시 획득
  - Player·DM·System 역할별 상호작용 Surface
  - 저장·재접속·롤백·Streaming 경계
- [`Runtime Object System과 Entity Lifecycle 계약`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - Scene에 놓인 Item Presence의 ID, Lifecycle, Spatial·Interaction Binding
- [`Command Ordering과 Transaction Coordinator 계약`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - Item, Inventory, Presence와 행동 자원의 원자적 Commit
- [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime 계약`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
  - Crafting 입력 소비·Output ItemInstance·Container 또는 Ground Presence의 Atomic Closure
- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
  - ItemInstance Registry와 Crafting·Character Integration 완료 및 Guide 단계 준비 판정

## 시스템 문서

- [`item-weapon-attack-profile-and-mastery-model.md`](item-weapon-attack-profile-and-mastery-model.md)
  - 무기·장비·Attack Profile·Weapon Mastery와 Item Capability
- [`inventory-loot-and-item-transfer-model.md`](inventory-loot-and-item-transfer-model.md)
  - 전리품 획득, 플레이어 간 전달, 화폐, 미확인 아이템과 DM 도구

## 역할 구분

모든 Inventory 행동·버튼·Command는 [`역할별 기능 접근 구분 작성 규칙`](../../DOCUMENT-ROLE-ACCESS-AUTHORING-RULE.md)을 따른다.

### 플레이어 정상 행동

- 자신이 제어하는 캐릭터의 아이템 줍기·드롭·사용
- 허용된 Container 열기와 Loot 획득
- 규칙이 허용하는 다른 캐릭터로의 이전
- 공개 Item 정보 확인과 위치 핑

### DM 전용 행동

- Item 생성, 강제 배치·이전·회수·삭제·복원
- 숨김 Definition, 저주, 식별 상태, 수량과 Charge 관리
- Item Presence를 저널의 Actor·Object·Dungeon Room 링크 대상으로 작성
- 거리·행동 비용을 우회하는 Inventory Override

### 시스템 전용 처리

- Item Presence 복구와 Streaming Materialization
- 자동 Stack·World Bundle Projection
- Transaction Recovery와 Rollback Branch 복원

DM이 Actor 제어권을 통해 일반 줍기·사용·드롭을 수행할 때는 Player Command 경로를 사용한다. DM Override는 별도 Command와 Audit 기록을 사용한다.

## 고정 경계

- 하나의 실제 아이템은 하나의 `ItemInstance`만 가진다.
- ItemInstance는 같은 Revision에서 하나의 권위 위치에만 존재한다.
- 바닥 아이템은 ItemInstance의 복사본이 아니라 Item Presence Runtime Object와 연결된 동일 ItemInstance다.
- Workspace Model과 Client Streaming 상태는 Item 존재의 권위가 아니다.
- 드롭, Pickup, 투척, Stack 분할·병합과 Container Spill은 모두 Transaction을 사용한다.
- Equipment와 Item Capability는 Character Build를 직접 수정하지 않고 현재 Item State에서 파생된다.
- 플레이어 Context Menu에 DM 전용 저널·관리 기능을 섞지 않는다.

## 추천 읽기 순서

1. `../../architecture/compiled-build-and-authoritative-state-pattern.md`
2. `../../DOCUMENT-ROLE-ACCESS-AUTHORING-RULE.md`
3. `../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md`
4. `item-weapon-attack-profile-and-mastery-model.md`
5. `inventory-loot-and-item-transfer-model.md`
6. `../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md`
7. `../../architecture/persistence-and-session-recovery-model.md`

## Guide Status

```text
READY_TO_WRITE
```

최신 Completion Audit에서 Inventory Runtime과 Character·Downtime·Crafting Integration이 Main System Guide 작성 가능 상태로 판정됐다.
