# ADR-0078: 권위 Game Time, Boundary Duration과 Scheduled Execution

- 상태: Accepted
- 작성일: 2026-08-04

## Context

RVTT에는 서로 다른 시간 의미가 동시에 존재한다.

- 캠페인 세계에서 실제로 경과한 시간
- Encounter의 Turn·Round 순서
- `다음 자기 Turn 시작까지` 같은 경계 기반 Duration
- 1분·10분·8시간 같은 고정 Game Time Duration
- Reaction Timeout, Reservation Lease와 네트워크 Grace Period
- VFX·Animation·Camera 재생 시간
- 휴식·여행·제작 중 발생하는 미래 사건

이들을 하나의 현실 시간 타이머나 Client Frame 기반 숫자로 처리하면 다음 문제가 발생한다.

- 참가자 수만큼 라운드 시간이 잘못 누적된다.
- Turn Boundary 효과가 초 단위 Timer로 변환되어 잘못 종료된다.
- 긴 휴식이나 여행이 중간 사건을 건너뛴다.
- 서버가 꺼진 현실 시간만큼 Effect가 만료된다.
- Presentation Slow Motion이 Gameplay Duration에 영향을 준다.
- Client local clock 조작으로 완료 시점을 앞당길 수 있다.
- Effect, Rest, Spell과 Encounter가 각자 별도 Scheduler를 만든다.

D&D 2024 기본 규칙에서 한 라운드는 약 6초를 나타내지만, 한 Turn이 각각 6초를 소비하는 것은 아니다. 또한 `다음 Turn 시작까지` 같은 표현은 6초 Deadline과 동일하지 않다.

## Decision

### 1. Campaign Game Time을 세계 시간의 단일 권위 원본으로 둔다

세계 안에서 경과한 절대 시간은 서버 권위 `CampaignGameTimeState`가 소유한다.

- Client Frame이나 local clock은 권위 원본이 아니다.
- 현실 Unix Timestamp를 Campaign Time으로 사용하지 않는다.
- Scene마다 독립 Clock을 기본 생성하지 않는다.
- Calendar는 절대 Instant를 표시하는 교체 가능한 Policy다.

### 2. 시간 Domain을 분리한다

다음을 동일한 Clock으로 취급하지 않는다.

```text
Campaign Game Time
Encounter Boundary Time
Authority Monotonic Time
Presentation Time
```

- Campaign Game Time: 세계관 내부 경과 시간
- Encounter Boundary Time: Turn·Round·Occurrence 순서
- Authority Monotonic Time: Timeout·Lease·Rate Limit
- Presentation Time: Animation·VFX·Camera 재생

### 3. Campaign Time은 명시적 Advance Transaction으로만 변경한다

Exploration의 실시간 흐름도 서버가 계산한 Batched `TimeAdvanceProposal`을 통해 Commit한다.

```text
TimeAdvanceProposal
→ Due Checkpoint 분할
→ Authority Transaction
→ game_time.advanced Domain Event
```

휴식·여행·Downtime·DM 시간 진행도 같은 경로를 사용한다.

### 4. D&D 2024 Round Duration을 Policy로 둔다

기본 Policy:

```text
1 Round = 6 game seconds
Turns advance Campaign Time = false
Campaign Advance Boundary = round_end
```

한 라운드에 참가자가 몇 명이든 개별 Turn마다 6초를 더하지 않는다.

부분 라운드의 Campaign Time 반영 방식은 교체 가능한 `partialRoundPolicy`로 둔다.

### 5. Duration 의미를 보존한다

다음 Duration을 모두 초 단위 Timer로 강제하지 않는다.

```text
fixed_game_time
until_turn_boundary
fixed_turns
fixed_rounds
until_rest
activity_progress
until_event
until_condition
```

`다음 자기 Turn 시작까지`는 Turn Boundary를 권위 종료 기준으로 사용한다.

고정 Game Time Duration이 Encounter 안에서 Round Cycle로 변환될 때 Timeline Anchor와 남은 Cycle을 보존한다. Encounter 진입·종료 시 하나의 `DurationHandle`만 진행 권위를 소유하고 중복 만료를 허용하지 않는다.

### 6. 장시간 행동은 시간과 활동 조건을 함께 요구한다

1분 이상 주문 시전, 휴식, 제작과 조사처럼 단순 대기만으로 완료되지 않는 행동은 `ActivityProgressHandle`과 `TimeCostDeclaration`을 사용한다.

Encounter에서 장시간 주문은 경과 Round뿐 아니라 필요한 각 Turn의 행동과 Concentration을 충족해야 한다.

### 7. Scheduler는 Due 후보만 생성한다

Scheduler는 미래 실행을 예약하지만 권위 Store를 직접 수정하지 않는다.

```text
Schedule Due
→ Domain Event
→ 등록 Subscriber
→ 새 Command 또는 RuleExecution
→ 별도 Transaction
```

임의 Luau Callback을 Schedule에 저장하지 않는다.

### 8. 대규모 Time Advance는 중간 Due 사건에서 분할한다

8시간 휴식 또는 수일 여행은 최종 시각을 먼저 Commit하지 않는다.

```text
요청된 Advance
→ 다음 Due Instant까지 Commit
→ 사건 해결
→ 남은 Advance 재검증
```

중간 사건이 휴식·여행·제작을 중단할 수 있다.

### 9. 병렬 활동을 시간 합산하지 않는다

여러 참가자가 동시에 수행한 활동은 `ConcurrentActivityWindow`에서 결합한다.

- 두 명이 각각 10분 활동을 동시에 수행하면 기본 10분 진행
- 같은 Actor가 10분 활동 두 개를 순차 수행하면 20분 진행

한 플레이어의 Time Cost만으로 파티 전체 Clock을 즉시 점프하지 않는다.

### 10. Offline World Progression은 초기 기본값에서 비활성화한다

서버 종료 중 현실 경과 시간을 Campaign Time에 자동 반영하지 않는다.

## Alternatives Considered

### 현실 시간과 Game Time을 동일하게 사용

거부한다. 휴식·여행·Pause·Replay·서버 종료와 호환되지 않고 Client 시간 조작에 취약하다.

### 모든 Duration을 초 단위 Deadline으로 변환

거부한다. Turn Boundary, Round Boundary, Concentration과 Event 기반 종료 의미를 잃는다.

### Effect·Rest·Encounter별 별도 Scheduler

거부한다. 시간 진행과 복구 순서가 중복되고 중간 사건 처리와 Rollback이 불일치한다.

### Time Advance 후 중간 사건을 소급 처리

거부한다. 중간 사건이 이후 시간 진행을 막을 수 있어 권위 인과관계를 깨뜨린다.

### Scene별 독립 Clock을 기본 제공

거부한다. 동일 세계의 Scene 간 시간 불일치와 Schedule 중복을 만든다. 특수 시간 영역은 명시적 Mapping Policy나 별도 Chronology로 확장한다.

## Consequences

### Positive

- Round 참가자 수와 무관하게 D&D 시간 계산이 일관된다.
- Encounter·Exploration·Downtime 사이 Duration Migration이 가능하다.
- 휴식·여행 중 사건을 건너뛰지 않는다.
- 저장·복구·Rollback에서 Schedule과 Duration을 재현할 수 있다.
- Calendar, Round 길이, Exploration 배율과 Catch-up 정책을 플레이테스트 후 교체할 수 있다.
- Presentation과 기술 Timeout이 Gameplay Time을 오염시키지 않는다.

### Negative

- DurationHandle과 Cross-mode Migration 구현이 필요하다.
- 대규모 Time Advance는 중간 Checkpoint 때문에 단일 숫자 변경보다 복잡하다.
- 병렬 활동 조정과 참가자 Busy Interval이 필요하다.
- Encounter 부분 라운드의 Campaign Time 반영 기본값을 플레이테스트로 확정해야 한다.

## Follow-up

- Game Time Runtime 구현 Spec 작성
- Encounter Runtime의 Round Boundary Event와 TimeAdvance 연결
- Effect Runtime의 Duration Scheduler를 Game Time Runtime에 연결
- Rest·Downtime Runtime에서 TimeCostDeclaration 사용
- Calendar Definition과 기본 Campaign Calendar 결정
- Scheduler·DurationHandle 복구·Rollback 테스트 작성
