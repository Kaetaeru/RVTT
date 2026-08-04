# Combat 시스템

주사위 결과 확정, 인카운터·주도권·턴·제어권과 전투 롤백 타임라인을 다룬다.

## 상위 권위 문서

- [`Session Play Mode, Context, Overlay와 Transition 계약`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - Encounter는 Exploration 위에 겹치는 단순 UI가 아니라 Base Play Mode다.
  - Encounter 종류는 Combat, Chase, Hazard, Escape와 Timed Objective를 포함한다.
  - Pause와 Rollback Review는 Encounter Mode가 아니라 Overlay다.
  - Join·Reconnect·Recovery와 Rollback Commit은 Transitional State다.
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime 계약`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
  - 서버 권위 RollPlan·SealedRollResult·RollRecord
  - 공격·판정·내성·이니셔티브·죽음 내성과 피해·회복 Resolution
  - Advantage·Disadvantage, Modifier, Bonus Die와 Reroll
  - 3D 주사위 Presentation Gate와 비밀 굴림 Projection
- [`Character Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - 전투 Action Economy와 2024 기본 행동
- [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - Roll 전후 TimingWindow, Reaction, PendingEffect와 CommitGroup
- [`Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - 피해·상태·자원·Encounter 결과의 원자적 Commit

## 시스템 문서

1. [`encounter-initiative-turn-and-control-authority-model.md`](encounter-initiative-turn-and-control-authority-model.md)
2. [`dice-roll-presentation-and-resolution-gating-model.md`](dice-roll-presentation-and-resolution-gating-model.md)
   - `SUPERSEDED`; 현재 권위는 Dice와 Resolution Runtime Architecture 및 ADR-0069
3. [`encounter-turn-snapshot-and-dm-rollback-model.md`](encounter-turn-snapshot-and-dm-rollback-model.md)

## 고정 경계

- Encounter는 Scene, Actor, HP, Item과 Effect 상태를 복제하지 않는다.
- 전투 중 토큰 WASD 이동은 금지하고 Path Preview와 Movement Budget Command만 사용한다.
- 문, Item Pickup과 Scene Interaction은 Encounter 중에도 가능하지만 Action Opportunity와 규칙 비용을 적용한다.
- Pause 시 Pending RuleExecution과 Reservation을 임의 취소하지 않는다.
- Rollback Review는 현재 Branch를 바꾸지 않으며 Commit 후 새 AuthorityEpoch로 Full Resync한다.
- 패배·의식불명 상태와 Encounter 참가 기록을 동일시하지 않는다.

## 역할 경계

- 플레이어는 자신의 캐릭터 굴림 의도와 선택적 재굴림·추가 주사위 사용을 결정한다.
- DM은 Encounter 시작·종료·참가자·진영, 수동·비밀 굴림, Override와 오류 복구를 담당한다.
- 시스템은 RNG, 결과 봉인, 공개 Gate, Outcome Resolution과 Commit 조정을 담당한다.
- Client Physics와 주사위 Animation은 권위 결과를 결정하지 않는다.

화면 배치는 `../../ui/combat-hud/`를 참고한다.

## Guide Status

`NOT_READY`

Encounter·Damage·Death·Combat Integration 계약과 Completion Audit가 끝난 뒤 Main System Guide를 작성한다.