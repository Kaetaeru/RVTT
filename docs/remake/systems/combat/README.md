# Combat 시스템

주사위 결과 확정, Encounter·Initiative Timeline·Turn·제어권과 전투 Rollback Timeline을 다룬다.

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
- Ready는 지원하고 Delay는 D&D 2024 기본 Policy에서 제공하지 않는다.
- Rollback Review는 현재 Branch를 바꾸지 않으며 Commit 후 새 AuthorityEpoch로 Full Resync한다.
- 패배·의식불명·사망 상태와 Encounter 참가 기록을 동일시하지 않는다.
- Objective 달성 후보가 생겨도 기본적으로 DM 또는 End Policy 확인 전 자동 종료하지 않는다.

## 역할 경계

- 플레이어는 자신이 제어하는 Actor의 Action, Movement, Ready, Reaction과 Turn End 요청을 제출한다.
- DM은 Encounter 시작·종료·참가자·진영·Timeline·Objective, 위임, Override와 오류 복구를 담당한다.
- Observer는 공개 정책에 맞는 Encounter Projection만 확인한다.
- 시스템은 Initiative Roll, Timeline Commit, Boundary 진행, Opportunity Ledger, Objective Evaluation과 Recovery를 담당한다.
- Client Physics와 주사위 Animation은 권위 결과를 결정하지 않는다.

화면 배치는 `../../ui/combat-hud/`를 참고한다.

## Guide Status

`NOT_READY`

Encounter 상위 계약은 완료됐다. Damage·Death·Combat Integration 계약과 Completion Audit가 끝난 뒤 Main System Guide를 작성한다.