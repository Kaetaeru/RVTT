# Slice 07 Spec Checkpoint Audit — Rest·Time·Downtime·Progression

- 상태: COMPLETE_WITH_BLOCKER
- 문서 종류: Slice Specification Checkpoint Audit
- 즉시 구현 명세 가능성: BLOCKED
- 감사일: 2026-08-05
- Work Order: [`CURRENT-WORK-ORDER.md`](../../specs/slices/07-rest-time-downtime-progression/CURRENT-WORK-ORDER.md)
- 통합 계약: [`implementation-contract.md`](../../specs/slices/07-rest-time-downtime-progression/implementation-contract.md)

## 검사 결과

| 항목 | 결과 |
|---|---|
| Campaign Time·현실 시간 분리 | 충족 |
| Scheduler Due와 Gameplay Mutation 분리 | 충족 |
| Downtime Session·Activity·Participant Window | 충족 |
| Reservation·Checkpoint·Interruption | 충족 |
| Rest·Level Up·Preparation·Spellbook | 충족 |
| Crafting·Training·Travel Completion Provider | 충족 |
| Character·Inventory Domain 직접 수정 금지 | 충족 |
| Restart·중복 Completion·Rollback 방지 | 충족 |
| 실제 Time·Provider·Migration Mapping | 미충족 |

## 판정

```text
Slice 07 Specification Package
→ CHECKPOINT_COMPLETE

Time·Downtime·Progression Contract
→ COMPLETE

Production Implementation Readiness
→ BLOCKED
```

장기 Activity와 Campaign Time이 별도 Actor 위치 Simulation이나 현실 시간 보상으로 구현되지 않도록 경계가 확정됐다.

## 후속 Slice 영향

Slice 08은 Activity·Choice·Approval·Recovery를 Projection과 Panel로 표현해야 하며 Authority State를 Client Progress Bar에 저장하지 않는다. Slice 13·14 Content는 이 Activity·Migration·Repository 계약을 재사용한다.