# ADR-0082: Encounter Boundary와 Campaign Time을 원자 Commit하고 Scheduler는 Event→Command Bridge로 연결한다

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Encounter–Game Time Temporal Boundary와 Scheduler 통합 계약`](../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md)
  - [`Encounter Timeline Runtime 계약`](../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)
  - [`Game Time Runtime 계약`](../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - [`Ruleset Policy Runtime 계약`](../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - [`Domain Event Runtime 계약`](../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)

## 배경

D&D 2024 기본 규칙에서 한 Round는 약 6초다. Encounter Runtime은 Round·Turn·Timeline Boundary를 소유하고 Game Time Runtime은 Campaign Game Time과 Scheduler를 소유하므로, Round 종료 시 두 Runtime의 상태를 함께 변경해야 한다.

단순한 직접 호출 구조는 다음 문제를 만든다.

```text
Encounter Round Commit
→ Game Time +6초 호출
→ Scheduler Callback
→ Encounter Timeline 수정
```

- Round만 끝나고 시간이 반영되지 않는 부분 성공
- 시간이 진행됐지만 Encounter Cursor가 이전 상태인 불일치
- `EncounterService ↔ GameTimeService` 순환 의존
- Scheduler Callback의 권위 Store 직접 수정
- 재시도 시 같은 Round에 시간 중복 증가
- Rollback 이전 Due 작업의 재실행

## 결정

### 1. Boundary와 Time Advance는 하나의 Authority Transaction이다

완료된 Encounter Round와 해당 Round가 소비한 Campaign Time은 같은 Transaction에서 Commit한다.

Transaction에는 최소한 다음이 포함된다.

```text
Encounter Round·Timeline State
RoundTimeLedger
Campaign Game Time
Scheduler Cursor와 Due Occurrence Staging
Domain Event Outbox
```

Round Commit 후 별도 `AdvanceTime(6)` 호출을 사용하지 않는다.

### 2. Encounter는 TemporalBoundaryCandidate만 만든다

Encounter Runtime은 Campaign Time Store를 직접 수정하지 않는다.

```text
Encounter Boundary Candidate
+ Frozen Policy Snapshot
→ Snapshot-bound Temporal Contribution Provider
→ EncounterTimeAdvanceContribution
```

Provider는 읽기 전용이며 같은 Snapshot과 Candidate에 결정적인 결과를 반환한다.

### 3. D&D 2024 기본 Full Round는 6초다

```text
full round = 6 game seconds
individual turn adds time = false
extra timeline entry adds time = false
```

Reaction, Ready 발동, 추가 Turn, Lair Entry와 소환체 Turn은 별도의 Campaign Time을 추가하지 않는다.

부분 라운드 종료 처리는 Frozen `partialRoundPolicy`가 결정한다.

### 4. Scheduler는 Due Occurrence만 같은 Transaction에서 확정한다

시간 진행 구간에 들어온 Schedule은 `ScheduledDueOccurrence`로 Staging한다.

Due가 되었다는 사실과 실제 Gameplay 결과를 분리한다.

```text
Time Transaction
→ schedule.became_due
→ 후속 Command 또는 RuleExecution
→ 별도 Domain Transaction
```

Time Runtime은 피해, Effect, Encounter Entry와 Character State를 직접 변경하지 않는다.

### 5. Scheduler에서 Encounter로의 연결은 멱등 Event→Command Bridge다

`EncounterTemporalBridgeSubscriber`는 Due Domain Event를 받아 현재 AuthorityEpoch, Encounter Incarnation과 Frozen Policy를 검증한 뒤 새 Command를 제출한다.

Subscriber가 Encounter Store를 직접 수정하지 않는다.

```text
schedule.became_due
→ InsertTemporalTimelineEntryCommand
   또는 OpenScheduledRuleExecutionCommand
```

### 6. Blocking Due는 Boundary Gate를 사용한다

다음 Round 또는 다음 필수 Timeline Entry는 Blocking Due Command가 안전하게 연결되기 전에 시작하지 않는다.

Outbox Subscriber 지연은 이미 Commit된 Round와 Campaign Time을 되돌리지 않지만, Boundary Gate가 진행을 차단하고 멱등 재시도한다.

### 7. Frozen Policy Snapshot을 사용한다

Round Duration, 부분 라운드 처리, Due Mapping, Blocking 분류와 다음 Round Gate는 Encounter가 시작할 때 고정한 Policy Snapshot을 사용한다.

진행 중 Encounter가 최신 Campaign Policy를 조용히 다시 조회하지 않는다.

### 8. 같은 Chronology의 시간 중복 진행을 막는다

초기 안전 정책은 한 Campaign Chronology에 하나의 `time_driving` Encounter만 허용한다.

다른 Encounter는 `time_following`, 별도 Chronology 또는 명시적 Synchronized Temporal Group을 사용한다.

동일 Chronology의 Encounter들이 조정 없이 각각 Round마다 6초를 더하지 않는다.

### 9. Rollback은 음수 Time Advance가 아니다

Rollback은 Encounter, Campaign Time, Scheduler Cursor, Due Occurrence와 Boundary Gate가 포함된 Authority Snapshot을 복원하고 새 AuthorityEpoch를 생성한다.

이전 Epoch의 Boundary·Due Event와 비동기 Subscriber 작업은 무효화한다.

## 결과

### 장점

- Round와 Campaign Time이 부분 성공으로 갈라지지 않는다.
- Encounter와 Game Time의 모듈 순환을 피한다.
- Scheduler Due 작업이 Transaction과 Command 경계를 우회하지 않는다.
- 중복 Event 전달과 서버 복구에서도 시간 중복 진행을 막을 수 있다.
- D&D 2024의 1 Round = 6초 규칙을 정확히 적용하면서 다른 Ruleset Policy로 교체할 수 있다.
- Rollback, Replay와 Deterministic Simulation에서 전체 시간 흐름을 재현할 수 있다.

### 비용

- Transaction Coordinator가 Encounter와 Game Time의 다중 Store Commit을 지원해야 한다.
- Boundary Gate와 Due Subscriber 멱등 상태를 저장해야 한다.
- 부분 라운드, 동시 Encounter와 Due Mapping Policy를 구현해야 한다.
- Scheduler Due가 많을 때 Batch·Budget·Recovery 설계가 필요하다.

## 거부한 대안

### Round Commit 후 Game Time을 별도 호출

부분 성공과 재시도 중복 때문에 거부한다.

### Scheduler Callback이 Encounter를 직접 수정

권위 Command, Ordering과 감사 경계를 우회하므로 거부한다.

### 모든 Turn마다 6초 진행

D&D의 Round 의미와 충돌하므로 거부한다.

### Scheduler Due 효과를 Time Transaction 안에서 전부 실행

Time Runtime이 모든 Gameplay Domain을 소유하게 되고 장기 Transaction이 되므로 거부한다.

### Rollback에서 Campaign Time에 음수 값을 적용

Scheduler·Duration·Event 계보를 안전하게 복원할 수 없으므로 거부한다.
