# Slice 06 Work Order — Inventory·Equipment·World Items

- 상태: `CHECKPOINT_COMPLETE_WITH_ADR_0092_DELTA`
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 최종 갱신일: 2026-08-06
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Character Foundation`](../05-character-foundation-creation/implementation-contract.md), [`Exploration`](../03-exploration-interaction-perception/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- ADR-0092 Delta: [`Supply Metadata·Allocation·Reservation`](ADR-0092-DELTA.md)
- 검수 감사: [`Slice 06 Spec Checkpoint Audit`](../../../audits/slices/06-inventory-equipment-world-items-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
Loot·Pickup
→ ItemInstance Location 이전
→ Inventory·Container·Equipment 배치
→ Capability·Attack Profile 갱신
→ Drop·Ground Presence 생성
→ 저장·Reconnect
```

ADR-0092 추가 결과:

```text
명시적 Supply Metadata가 있는 Item
→ 접근 가능한 Supply Source 조회
→ 보호·예약·Quest Item 제외
→ 결정적 부분 Stack Allocation
→ Settlement Reservation
→ Slice 07의 Time·Shortage Plan과 Atomic Commit
```

Slice 06은 하루 요구량, Campaign Time과 결핍 결과를 계산하지 않는다.

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Item Definition·ItemInstance | Definition과 영구 Instance·Revision 분리 |
| 2 | DONE | Location Binding | Inventory·Container·Equipment·Ground·Transit 중 하나만 소유 |
| 3 | DONE | Stack·Currency·Identification | 수량 보존과 공개 단계 정의 |
| 4 | DONE | Equipment·Hand·Attunement | Slot, Requirement, Conflict와 Character Capability 연결 |
| 5 | DONE | Weapon Attack Profile·Mastery | Item Build와 Character Build·State 기여 경계 정의 |
| 6 | DONE | Pickup·Drop·Transfer | Range·Presence·Revision·Ordering과 Atomic Transaction 정의 |
| 7 | DONE | World Presence·Streaming | Item 보존과 Materialization 실패 격리 정의 |
| 8 | DONE | Inventory Projection·Recovery·Test | 동시 획득·정보 누출·Restart Scenario 정의 |
| 9 | DONE | ADR-0092 Supply Delta | Metadata·Protection·Source·Allocation·Reservation·Disclosure 정의 |
| 10 | BLOCKED | Production Source Mapping | 실제 Item·Container·Equipment·Presence·Supply Schema 조사 필요 |

## 구현 시 추출할 세부 명세

```text
inventory/item-definition-instance
inventory/location-container-stack
inventory/equipment-hand-attunement
inventory/weapon-attack-profile-mastery
inventory/pickup-drop-transfer
inventory/supply-metadata-protection-source
inventory/supply-allocation-reservation
scene/item-world-presence
ui/inventory-supply-projection
persistence/item-supply-migration-recovery
```

## ADR-0092 구현 착수 Gate

다음이 준비되기 전에는 Supply Runtime을 Production Queue에 넣지 않는다.

- 실제 Item Definition·Instance·Location Schema Mapping
- Container ACL·Projection API
- 공통 Reservation Coordinator
- Slice 07 Requirement·Settlement API
- Versioned Supply Metadata·Migration 경로

## 차단 사항

- 기존 Inventory·Item JSON과 Slot 구조
- World Item Model·Prefab·Streaming 구조
- Character Equipment·Attack Profile Legacy 데이터
- Currency·Stack·Identification 저장 방식
- Inventory UI와 Drag·Drop 입력 구현
- Supply Metadata·Protection·Source Priority 저장 구조
- Settlement Reservation과 Restart·Rollback Marker 구조
