# Slice 07 Work Order — Rest·Time·Downtime·Progression

- 상태: `CHECKPOINT_COMPLETE_WITH_ADR_0092_DELTA`
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 최종 갱신일: 2026-08-06
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Character`](../05-character-foundation-creation/implementation-contract.md), [`Inventory`](../06-inventory-equipment-world-items/implementation-contract.md), [`Encounter`](../04-encounter-core-loop/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- ADR-0092 Delta: [`Campaign Policy·Supply Settlement·Ledger`](ADR-0092-DELTA.md)
- Slice 06 Delta: [`Supply Metadata·Allocation·Reservation`](../06-inventory-equipment-world-items/ADR-0092-DELTA.md)
- 검수 감사: [`Slice 07 Spec Checkpoint Audit`](../../../audits/slices/07-rest-time-downtime-progression-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
Rest·Level Up·Preparation·Crafting·Training·Travel 시작
→ Eligibility·Resource Reservation
→ Campaign Time·Checkpoint
→ Choice·DM 승인·중간 사건
→ Domain Completion Proposal
→ Atomic Commit
→ Progression·Item·Recovery 결과
→ Reconnect·Resume
```

ADR-0092 추가 결과:

```text
Narrative·Standard·Survival·Custom Profile
→ Logistics Boundary와 Consumer Requirement
→ Slice 06 Supply Allocation·Reservation
→ Time Advance Supply Preview
→ DM Confirm 또는 Policy Approval
→ Time·Inventory·Shortage Atomic Settlement
→ Ledger·Reconnect·Rollback
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Campaign Time·Calendar·Scheduler | 현실 시간과 분리된 권위 시간·Due Lifecycle 정의 |
| 2 | DONE | Downtime Session·Activity | Participant Window, Eligibility, Progress와 상태 전이 정의 |
| 3 | DONE | Reservation·Checkpoint·Interruption | Resource·Item·Provider 예약과 Encounter 중단 경계 정의 |
| 4 | DONE | Short·Long Rest | HP·Resource Recovery Plan과 참가자별 적격성 정의 |
| 5 | DONE | Level Up·Build Migration | Source·Build·State Candidate와 원자 활성화 정의 |
| 6 | DONE | Spell Preparation·Spellbook | Access·Repository·Copy·비용·Item Binding 정의 |
| 7 | DONE | Crafting·Training·Travel | Domain-owned Completion과 Time Advance Checkpoint 정의 |
| 8 | DONE | Cancel·Recovery·Rollback·Test | Progress Settlement, Restart, Due·Choice Epoch 검증 정의 |
| 9 | DONE | ADR-0092 Policy·Settlement Delta | Preset·Boundary·Requirement·Atomic Settlement·Ledger 정의 |
| 10 | DONE | Mid-campaign Policy Change | Candidate Snapshot·Impact Preview·Safe Boundary·비소급 정의 |
| 11 | BLOCKED | Production Source Mapping | 실제 Time·Policy·Inventory·Effect·Ledger 구조 조사 필요 |

## 구현 시 추출할 세부 명세

```text
time/campaign-clock-calendar-scheduler
time/survival-policy-profile-binding
time/logistics-boundary-accumulator
time/supply-requirement-settlement-ledger
time/survival-policy-change-reconcile
downtime/session-activity-participant-window
downtime/reservation-progress-interruption
character/rest-resource-recovery
character/level-up-build-migration
character/spell-preparation-spellbook
downtime/crafting-training-travel
persistence/downtime-supply-recovery-rollback
```

## ADR-0092 구현 착수 Gate

다음이 준비되기 전에는 Settlement Runtime을 Production Queue에 넣지 않는다.

- Campaign Time·Scheduler·Frozen Policy Snapshot 실제 Mapping
- Slice 06 Supply Query·Reservation API
- Rule Profile Consumption Requirement·Shortage Recipe
- Effect·RuleExecution Integration
- Supply Ledger·Projection·Persistence Schema
- Slice 11 DM Preview API 경계

## 차단 사항

- 기존 Campaign Time·Scheduler 데이터
- Rest·Resource·DeathSave Legacy State
- Level Up·Spell Preparation UI와 Character Migration
- Crafting·Training·Travel Provider·Recipe 데이터
- 장기 Activity Snapshot·Journal·Reservation 저장 구조
- Campaign Survival Profile·Boundary Accumulator 저장 구조
- Requirement·Allocation·Shortage Plan Version 경계
- Supply Ledger·Idempotency·Retroactive Reconcile 구조
