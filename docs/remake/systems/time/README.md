# Time 시스템

Campaign Game Time, Calendar, Encounter Round Duration, Duration Handle, Time Consumption과 Scheduler를 다룬다.

## 관련 Main System Guide

- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
  - Encounter Round Boundary, D&D 2024 기본 6초, RoundTimeLedger와 Campaign Time 원자 Commit
  - Scheduler Due Staging, Event→Command Bridge와 Blocking Boundary Gate

## 권위 문서

- [`Game Time, Calendar, Duration과 Scheduler Runtime 계약`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - Campaign Game Time과 현실 시간의 분리
  - D&D 2024 기본 `1 Round = 약 6초`
  - 개별 Turn은 Campaign Time 6초를 추가하지 않음
  - Turn·Round Boundary Duration과 고정 시간 Duration 분리
  - 휴식·여행·Downtime의 Time Advance Plan
  - 미래 사건 Scheduler와 대규모 시간 진행 Checkpoint
  - 저장·복구·Rollback과 Duration Migration
- [`Encounter–Game Time Temporal Boundary와 Scheduler 통합 계약`](../../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md)
  - Encounter Round State와 Campaign Time의 원자적 Commit
  - Snapshot-bound `EncounterTimeAdvanceContribution`
  - Due Schedule의 Staging과 실제 Gameplay 실행 분리
  - Event→Command Encounter Bridge, Blocking Boundary Gate와 Chronology Guard

## 관련 시스템

- [`Exploration`](../exploration/README.md)
  - 실시간 탐험 중 자동 또는 명시적 Time Advance
- [`Combat`](../combat/README.md)
  - Turn·Round Boundary와 Encounter Timeline
- [`Character`](../character/README.md)
  - 휴식, 죽음, 자원 회복과 장기 상태
- [`Rules`](../rules/README.md)
  - 주문 지속시간, 장시간 시전과 Effect
- [`Events`](../events/README.md)
  - `game_time.advanced`, `schedule.became_due`와 후속 실행
- [`Session`](../session/README.md)
  - Pause, Downtime, Scene Transition과 Recovery

## 고정 경계

- Wall Clock, Authority Monotonic Time, Campaign Game Time과 Presentation Time을 합치지 않는다.
- 한 라운드의 모든 Turn은 세계관상 같은 약 6초 안에 일어난다.
- `다음 자기 Turn 시작까지`를 임의의 6초 Timer로 바꾸지 않는다.
- Encounter Round 종료와 6초 Time Advance를 별도 비원자 작업으로 나누지 않는다.
- Scheduler는 Due 후보와 Due Occurrence만 만들고 Effect·Character·Scene·Encounter 상태를 직접 수정하지 않는다.
- Encounter로 연결되는 Due 작업은 Subscriber가 새 Command 또는 RuleExecution을 제출한다.
- Blocking Due가 해결되기 전에는 다음 Encounter Boundary를 열지 않는다.
- 동일 Chronology의 다중 Encounter가 각각 독립적으로 시간을 진행하지 않는다.
- 휴식·여행의 긴 Time Advance는 중간 사건을 건너뛰지 않는다.
- Client local clock은 Gameplay Duration의 권위가 아니다.

## 다음 구현 명세

- `specs/time/001-game-time-state-and-advance-transaction.md`
- `specs/time/002-duration-handle-and-boundary-migration.md`
- `specs/time/003-scheduler-due-index-and-checkpoint-processing.md`
- `specs/time/004-calendar-definition-and-time-projection.md`
- `specs/time/005-encounter-temporal-boundary-contribution.md`
- `specs/time/006-scheduler-encounter-command-bridge.md`
