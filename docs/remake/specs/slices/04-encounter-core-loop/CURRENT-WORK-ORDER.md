# Slice 04 Work Order — Encounter Core Loop

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Slice 02`](../02-core-rules-kernel/implementation-contract.md), [`Slice 03`](../03-exploration-interaction-perception/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 04 Spec Checkpoint Audit`](../../../audits/slices/04-encounter-core-loop-spec-checkpoint-audit.md)

## 1. 사용자 완료 결과

```text
Exploration의 적대 행동·Hazard·DM Start
→ Encounter Proposal
→ Participant·Faction·Awareness 확정
→ Initiative·Timeline 활성화
→ Turn·Opportunity·Movement·Action·Reaction
→ Damage·HP 0·Objective·Round Time
→ Encounter 종료
→ Exploration 복귀
→ 필요 시 Turn Checkpoint Rollback
```

## 2. 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Encounter Proposal·Lifecycle | preparing→active→ending→ended와 Session Transition 정의 |
| 2 | DONE | Participant·Faction·Control | Ownership·Controller·Participation·Visibility 분리 |
| 3 | DONE | Initiative·Timeline·Cursor | Entry·Occurrence·Revision·Cursor와 공개 Gate 정의 |
| 4 | DONE | Turn·Opportunity·Movement Budget | Action·Bonus Action·Reaction·Movement 상태와 Reservation 정의 |
| 5 | DONE | Reaction·Ready·RuleExecution Bridge | 별도 Reaction Stack 없이 TimingWindow·Child Execution 사용 |
| 6 | DONE | Damage·HP 0·Death·Objective | Immediate Closure와 Deferred Consequence 분리 |
| 7 | DONE | Round Time·Scheduler Boundary | Round·Campaign Time·Due Staging 원자 경계 정의 |
| 8 | DONE | End·Checkpoint·Rollback·Recovery | Exploration 복귀, Snapshot·Branch·Full Resync 정의 |
| 9 | DONE | HUD·Projection·Diagnostics·Test | Player·DM·Observer Projection과 Race·Restart Scenario 정의 |
| 10 | BLOCKED | Production Source Mapping | 실제 Encounter·Time·Combat HUD·Snapshot 구조 조사 필요 |

## 3. 구현 시 추출할 세부 명세

```text
encounter/lifecycle-participant-control
encounter/initiative-timeline-cursor
encounter/turn-opportunity-movement
rules/reaction-ready-timing-window
combat/damage-vital-objective
encounter/round-time-scheduler-boundary
encounter/end-checkpoint-rollback
ui/encounter-projection-hud
testing/encounter-race-recovery
```

## 4. 핵심 Gate

- Encounter는 Actor 위치·HP·Item·Effect의 복사본을 만들지 않는다.
- Initiative UI 배열을 권위 Timeline으로 사용하지 않는다.
- Action·Spell·Interaction 규칙을 Encounter가 재구현하지 않는다.
- 전투 Token WASD는 금지하고 클릭 Movement Runtime만 사용한다.
- Reaction은 RuleExecution TimingWindow와 Opportunity Reservation을 사용한다.
- Damage Roll이 HP Store와 Cursor를 직접 수정하지 않는다.
- Round Time은 개별 Turn마다 누적하지 않는다.
- Rollback은 역연산이 아니라 새 Branch·AuthorityEpoch 복원이다.

## 5. 차단 사항

- 기존 Encounter·Initiative·Turn·Control Schema
- Combat HUD·Prompt·Reaction UI 구현
- Character HP·Vital·DeathSave 저장 구조
- Campaign Time·Scheduler 실제 Provider
- Turn Snapshot·Rollback Legacy 데이터와 Migration 대상