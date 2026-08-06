# Event 시스템

Commit 이후 Domain Event, Transactional Outbox, Subscriber, 관찰자별 Projection Event와 Presentation Signal 연결을 다룬다.

## 관련 Main System Guide

- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
  - Encounter·Round·Turn·Objective·End Domain Event와 Rule Event의 분리
  - Temporal Boundary Commit 이후 `schedule.became_due` Event→Command Bridge와 Deferred Consequence
- [`Diagnostics, Simulation과 Operations Guide`](../../guides/diagnostics/README.md)
  - Event Fan-out·Subscriber·Retry·Dead Letter의 Causation Trace와 Health·Incident 연결
  - Duplicate·Drop·Reorder·Retry Fault Scenario와 이전 AuthorityEpoch Follow-up 차단
  - Event Gap·Projection Gap·Quiescence·Resource Leak의 구조화된 검증

## 권위 문서

- [`../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - Rule Event와 Commit 이후 Domain Event 분리
  - Authority State와 Event Outbox의 원자적 Commit
  - Subscriber 멱등성, Retry, Dead Letter와 Cycle Guard
  - Observer별 Projection Event
  - Presentation·Journal·Diagnostics 확장 경계
- [`../../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md`](../../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md)
  - Encounter Boundary·Campaign Time·Due Occurrence의 원자적 Commit
  - `encounter.temporal_boundary_committed`, `game_time.advanced`, `schedule.became_due`
  - Scheduler Due의 멱등 Event→Command Encounter Bridge
  - Subscriber 실패와 Blocking Boundary Gate의 분리

## 관련 문서

- [`../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`../../architecture/networking-command-event-and-client-synchronization-contract.md`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`../../architecture/persistence-and-session-recovery-model.md`](../../architecture/persistence-and-session-recovery-model.md)

## 고정 경계

- Event Handler는 Domain Store를 직접 수정하지 않는다.
- 상태 변경이 필요하면 새 Command 또는 RuleExecution을 제출한다.
- `schedule.became_due` Subscriber가 Encounter Timeline을 직접 수정하지 않는다.
- 동일 Due Occurrence의 중복 전달은 Subscriber 멱등 기록으로 차단한다.
- Client에는 Raw Domain Event를 보내지 않는다.
- Presentation Subscriber 실패는 Gameplay Commit을 되돌리지 않는다.
- Rollback 이전 Authority Epoch의 Event를 새 Branch에 다시 적용하지 않는다.
- Diagnostics Trace와 Incident가 Domain Event Outbox의 권위 원본이 되지 않는다.
- Test Harness는 실제 Outbox·Subscriber 경로를 사용하고 Event Store를 직접 수정하지 않는다.
