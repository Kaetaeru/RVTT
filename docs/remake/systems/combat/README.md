# Combat 시스템

주사위 결과 확정, Encounter·Initiative Timeline·Turn·제어권, Damage·Death Integration과 전투 Rollback Timeline을 다룬다.

## 상위 권위 문서

- [`Session Play Mode, Context, Overlay와 Transition 계약`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - Encounter는 Exploration 위에 겹치는 단순 UI가 아니라 Base Play Mode다.
  - Encounter 종류는 Combat, Chase, Hazard, Escape와 Timed Objective를 포함한다.
  - Pause와 Rollback Review는 Encounter Mode가 아니라 Overlay다.
  - Join·Reconnect·Recovery와 Rollback Commit은 Transitional State다.
- [`Encounter Timeline, Turn, Opportunity와 Objective Runtime 계약`](../../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)
  - Combat를 포함한 모든 Turn 기반 Encounter의 현재 권위 계약
  - Policy 기반 Initiative·Timeline·Turn·Opportunity·Objective
  - Timeline Entry·Occurrence·Cursor와 중도 합류·재정렬
  - Reaction은 RuleExecution Graph, Pause는 Overlay로 분리
  - D&D 2024 기본 1 Round = 6초와 개별 Turn 시간 추가 금지
- [`Encounter–Game Time Temporal Boundary와 Scheduler 통합 계약`](../../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md)
  - Round Boundary와 Campaign Time Advance의 원자적 Commit
  - `TemporalBoundaryCandidate`, `RoundTimeLedger`와 멱등 Boundary Sequence
  - Scheduler Due Occurrence와 Event→Command Encounter Bridge
  - Blocking Due Boundary Gate와 같은 Chronology의 중복 시간 진행 방지
- [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime 계약`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
  - Damage·Temporary HP·Current HP·VitalState·DeathSave의 Atomic Closure
  - Death·Effect·Opportunity·Reservation과 Encounter Eligibility 통합
  - Concentration·Objective·Turn Advance의 Deferred Consequence
  - Encounter End Transaction, Projection Barrier와 Epoch-safe Follow-up
- [`Game Time, Calendar, Duration과 Scheduler Runtime 계약`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - Round End의 Campaign Time 반영
  - Turn·Round Boundary Duration과 초·분 단위 Duration 분리
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime 계약`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
  - 서버 권위 RollPlan·SealedRollResult·RollRecord
  - 공격·판정·내성·이니셔티브·죽음 내성과 피해·회복 Resolution
  - Advantage·Disadvantage, Modifier, Bonus Die와 Reroll
  - 3D 주사위 Presentation Gate와 비밀 굴림 Projection
- [`Character Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - 전투 Action Economy와 2024 기본 행동
  - Encounter는 행동을 제공하지 않고 Opportunity만 제공
- [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - Roll 전후 TimingWindow, Reaction, Parent·Child RuleExecution Graph와 CommitGroup
- [`Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - 피해·상태·자원·Encounter 결과의 원자적 Commit
- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
  - Combat Integration BLOCKER 해소와 Main Guide 단계 준비 완료 판정

## 시스템 문서

1. [`encounter-initiative-turn-and-control-authority-model.md`](encounter-initiative-turn-and-control-authority-model.md)
   - `SUPERSEDED`; 초기 상세 모델로 보존한다.
   - 현재 권위는 Encounter Timeline Runtime 계약, ADR-0034와 ADR-0079다.
2. [`dice-roll-presentation-and-resolution-gating-model.md`](dice-roll-presentation-and-resolution-gating-model.md)
   - `SUPERSEDED`; 현재 권위는 Dice와 Resolution Runtime Architecture 및 ADR-0069다.
3. [`encounter-turn-snapshot-and-dm-rollback-model.md`](encounter-turn-snapshot-and-dm-rollback-model.md)
   - Encounter Snapshot·Rollback 상세 모델로 유지한다.
   - 상위 Timeline Identity, AuthorityEpoch와 Overlay 경계는 최신 Architecture를 따른다.

## 고정 경계

- Encounter는 Scene, Actor, HP, Item과 Effect 상태를 복제하지 않는다.
- Encounter는 Attack·Spell·Interaction·Inventory 행동을 직접 제공하지 않는다.
- 내부 순서는 단순 Initiative List나 FIFO Queue가 아니라 Timeline Entry·Occurrence·Revision으로 관리한다.
- 전투 중 토큰 WASD 이동은 금지하고 Path Preview와 Movement Budget Command만 사용한다.
- 문, Item Pickup과 Scene Interaction은 Encounter 중에도 가능하지만 Action Opportunity와 규칙 비용을 적용한다.
- Pause 시 Pending RuleExecution과 Reservation을 임의 취소하지 않는다.
- Reaction과 Interrupt는 Encounter 전용 Stack이 아니라 RuleExecution Graph를 사용한다.
- D&D 2024에서 1 Round는 6 game seconds이며 개별 Turn마다 6초를 더하지 않는다.
- Round 종료와 해당 Campaign Time Advance는 하나의 Authority Transaction에서 Commit한다.
- Encounter가 Game Time Store를 직접 수정하지 않고 Scheduler Subscriber가 Encounter Store를 직접 수정하지 않는다.
- Blocking Due가 남아 있으면 Boundary Gate가 다음 Round 시작을 막는다.
- 같은 Campaign Chronology에서 여러 Encounter가 조정 없이 각각 시간을 진행하지 않는다.
- Ready는 지원하고 Delay는 D&D 2024 기본 Policy에서 제공하지 않는다.
- Rollback Review는 현재 Branch를 바꾸지 않으며 Commit 후 새 AuthorityEpoch로 Full Resync한다.
- 패배·의식불명·사망 상태와 Encounter 참가 기록을 동일시하지 않는다.
- Damage Provider가 Encounter Cursor를 직접 이동하거나 Encounter를 종료하지 않는다.
- HP 0·VitalState·DeathSave와 확정적 Opportunity Closure는 하나의 Cross-Domain Transaction에서 처리한다.
- 집중 내성, Objective 평가와 Turn Advance는 Commit 이후 타입 있는 Follow-up 실행을 사용한다.
- Objective 달성 후보가 생겨도 기본적으로 DM 또는 End Policy 확인 전 자동 종료하지 않는다.
- Encounter 종료가 Actor 위치·HP·시체·바닥 Item·지속 Knowledge를 초기화하지 않는다.
- 같은 Transaction의 HP·Vital·Effect·Encounter Projection은 Barrier Batch로 적용한다.

## 역할 경계

- 플레이어는 자신이 제어하는 Actor의 Action, Movement, Ready, Reaction과 Turn End 요청을 제출한다.
- DM은 Encounter 시작·종료·참가자·진영·Timeline·Objective, 위임, Override와 오류 복구를 담당한다.
- Observer는 공개 정책에 맞는 Encounter Projection만 확인한다.
- 시스템은 Initiative Roll, Timeline Commit, Boundary 진행, Opportunity Ledger, Objective Evaluation, Cross-Domain Gate와 Recovery를 담당한다.
- Client Physics와 주사위 Animation은 권위 결과를 결정하지 않는다.

화면 배치는 `../../ui/combat-hud/`를 참고한다.

## Guide Status

```text
READY_FOR_MAIN_GUIDE_PHASE
```

Combat Architecture와 Integration BLOCKER는 완료됐다. Main System Guide는 권위 문서 읽기 순서, Player·DM 흐름, Cross-Domain Outcome, 복구와 구현 Spec 진입점을 통합한다.
