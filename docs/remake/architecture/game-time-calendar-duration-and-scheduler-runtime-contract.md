# Game Time, Calendar, Duration과 Scheduler Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 권위 Game Time의 고정소수점 최소 단위
  - Exploration 자동 시간 진행의 Commit 간격과 AFK 판정
  - Scheduler 단일 처리 Batch와 연쇄 실행 최대 깊이
  - 대규모 Time Advance의 중간 Checkpoint 상한
  - D&D 2024 부분 라운드 종료 시 Campaign Time 반영 기본값
  - Calendar Formatter의 기본 세계관 달력
  - 완료된 Schedule·Duration Tombstone 보존 기간
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0029`](../decisions/ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)
  - [`ADR-0031`](../decisions/ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md)
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0078`](../decisions/ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event, Outbox, Subscription과 Projection Runtime 계약`](domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)
- 관련 Runtime:
  - [`Exploration Runtime 계약`](exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md)
  - [`Spell Runtime 계약`](spell-casting-route-and-2024-spell-runtime-contract.md)
  - [`Effect Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)
- 관련 시스템:
  - [`HP 0·죽음 내성·휴식·자원 회복 모델`](../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
  - [`Encounter 시스템`](../systems/combat/README.md)

## 1. 목적

이 문서는 RVTT 세계 안에서 경과한 시간, 턴·라운드 경계, 지속시간, 휴식·여행·제작의 시간 소비와 미래 사건 예약을 하나의 서버 권위 계약으로 연결한다.

핵심 원칙:

```text
Wall Clock
≠ Campaign Game Time
≠ Encounter Boundary
≠ Presentation Time
```

```text
시간은 Client Frame마다 자연 증가하는 전역 숫자가 아니다.

권위 있는 Time Advance
→ Scheduler Checkpoint
→ Authority Transaction
→ Domain Event
```

현실에서 30초가 지났다는 이유만으로 게임 세계에서 30초가 흐르지 않는다. 반대로 긴 휴식이나 여행은 현실에서 짧게 처리하더라도 게임 세계에서는 여러 시간 또는 날짜를 진행할 수 있다.

## 2. 책임 분리

### Game Time Runtime

소유:

- Campaign Game Time의 권위 상태
- Time Advance Proposal·Plan·Commit
- Calendar Definition과 시간 표시 변환
- Duration Handle의 진행 기준
- Scheduled Execution의 등록·취소·Due 후보 생성
- 시간 이동 중 중간 사건 Checkpoint
- 저장·복구·롤백용 Time State

소유하지 않음:

- Effect의 종료 규칙
- 휴식 적격성과 회복량
- Encounter Turn 순서
- 여행 중 발생할 사건의 실제 규칙
- Presentation 재생 속도
- 네트워크 Timeout과 Lock Lease

### Effect Runtime

Effect가 어떤 Duration 의미와 종료 조건을 사용하는지 정의한다. Game Time Runtime은 해당 Duration의 진행과 만료 후보만 계산한다.

### Encounter Runtime

Turn·Round·Timeline Boundary를 소유한다. Game Time Runtime은 Encounter Policy가 확정한 경과량만 Campaign Game Time에 반영한다.

### Downtime·Rest·Travel Runtime

행동의 필요 시간과 중단 규칙을 선언한다. 실제 Campaign Time 변경과 중간 Schedule 처리는 Game Time Runtime을 사용한다.

### Authority Monotonic Time Service

다음처럼 현실 서버 시간에 의존하는 기술적 제한을 담당한다.

- Command Timeout
- Reservation Lease
- Reaction 응답 제한
- 연결 Grace Period
- Rate Limit

이 시간은 게임 세계의 주문·독·휴식 지속시간을 진행시키지 않는다.

### Presentation Time

Animation, VFX, Camera와 UI 재생 속도만 다룬다. Slow Motion이나 연출 Skip은 Campaign Game Time을 변경하지 않는다.

## 3. 권위 시간 축

초기 제품의 세계 시간 권위 원본은 하나다.

```text
CampaignGameTimeState
├─ chronologyId
├─ currentInstant
├─ calendarDefinitionRef
├─ automaticAdvancePolicyRef
├─ schedulerCursor
├─ lastAdvanceTransactionId?
├─ revision
└─ authorityEpoch
```

### chronologyId

캠페인 세계의 시간 계보를 식별한다. Rollback 또는 Campaign Branch가 발생해도 이전 기록과 현재 권위 계보를 구분할 수 있어야 한다.

### currentInstant

부동소수점 누적값을 권위 원본으로 사용하지 않는다. 구현 명세에서 정한 고정소수점 또는 정수 기반 단위를 사용한다.

### Scene Time

일반 Scene마다 독립적으로 흐르는 두 번째 권위 시계를 기본 제공하지 않는다. 같은 Campaign 세계의 Scene은 Campaign Game Time을 공유한다.

특수한 시간 정지 영역, 다른 차원, 시간 가속 효과가 필요하면 다음 중 하나로 표현한다.

- Effect·Rule Override가 특정 Duration의 진행을 Suppress
- 등록된 Local Time Mapping Policy
- 별도 Campaign Chronology를 가진 독립 세계 Scope

임의의 Scene Local Clock을 남발하지 않는다.

## 4. 시간 종류

```text
campaign_game_time
encounter_boundary_time
authority_monotonic_time
presentation_time
```

### Campaign Game Time

세계관 내부에서 실제로 경과한 절대 시간이다.

사용 예:

- 10분 뒤 독 만료
- 8시간 긴 휴식
- 3시간 여행
- 다음 날 새벽 사건
- 사망 시각
- 제작 완료일

### Encounter Boundary Time

시간 숫자보다 의미 있는 순서를 표현한다.

```text
turn_start
turn_end
round_start
round_end
occurrence_count
```

사용 예:

- 다음 자기 턴 시작까지
- 현재 턴 종료까지
- 매 라운드 종료 시
- 3턴 동안
- 10라운드 동안

### Authority Monotonic Time

현실 서버의 단조 시간이다. 캠페인 저장·롤백 대상이 아니며 세계관 시간으로 표시하지 않는다.

### Presentation Time

사용자별 로컬 재생 시간이다. 배속·Skip·접근성 설정을 허용한다.

## 5. GameTimeInstant와 GameTimeDuration

```text
GameTimeInstant
├─ chronologyId
├─ fixedTimeValue
└─ precisionDefinitionRef
```

```text
GameTimeDuration
├─ fixedDurationValue
└─ precisionDefinitionRef
```

규칙:

- 음수 Duration은 일반 콘텐츠에서 금지한다.
- Calendar 표기 문자열을 권위 시간으로 저장하지 않는다.
- `3일째 오후` 같은 입력은 Calendar Compiler가 절대 Instant로 변환한다.
- 비교와 정렬은 동일 Chronology와 정규화된 고정 단위에서 수행한다.
- 현실 Unix Timestamp를 Campaign Game Time 원본으로 사용하지 않는다.

## 6. Calendar Definition

Calendar는 시간 권위 원본이 아니라 표시와 달력 계산 정책이다.

```text
CalendarDefinition
├─ calendarId
├─ version
├─ epochLabel
├─ dayLength
├─ weekDefinition
├─ monthDefinitions[]
├─ yearRule
├─ leapRule?
├─ namedTimePeriods[]
├─ formatterProfile
└─ parserProfile
```

지원 목적:

- 현실식 연·월·일
- 판타지 세계의 다른 월 길이
- 주간·달 이름
- 새벽·낮·황혼·밤 구간
- 특정 날짜와 시각에 예약된 사건

Calendar Definition을 교체해도 이미 저장된 `GameTimeInstant`의 순서는 변하지 않는다. Calendar Migration은 표시 변환과 미래 Schedule 재컴파일 여부를 명시해야 한다.

## 7. Time Advance

Campaign Game Time은 권위 있는 Advance를 통해서만 변경한다.

```text
TimeAdvanceProposal
→ 영향 Scope와 활동 검증
→ 다음 Due Schedule 계산
→ TimeAdvancePlan 분할
→ Authority Transaction
→ GameTimeAdvanced Domain Event
```

```text
TimeAdvanceProposal
├─ proposalId
├─ sourceKind
├─ requestedDuration
├─ participantBindings[]
├─ activityPlanRefs[]
├─ interruptPolicy
├─ approvalPolicy
├─ reasonCode
└─ authorityEpoch
```

`sourceKind` 예시:

```text
exploration_realtime
encounter_round
rest
downtime
travel
long_action
scheduled_rule
dm_advance
custom_registered
```

Client가 `currentInstant`를 직접 제출하거나 변경할 수 없다. 플레이어는 휴식·여행·행동을 제안하고, 서버가 해당 행동에서 Time Advance Plan을 파생한다.

## 8. Exploration 시간 진행

Exploration은 실시간 조작을 사용하지만 Client Frame마다 Campaign Time을 증가시키지 않는다.

```text
Authority Monotonic Elapsed
+ Exploration AutomaticAdvancePolicy
+ Session Pause·Activity State
→ Batched TimeAdvanceProposal
→ Commit
```

기본 원칙:

- 서버만 자동 진행량을 계산한다.
- 일정 간격으로 묶어 Commit할 수 있다.
- Pause Gate 중에는 자동 진행을 멈춘다.
- Loading, Reconnect, Recovery와 DM Authoring만으로는 시간이 흐르지 않는다.
- 모든 참가자가 AFK일 때 진행할지는 Campaign Policy로 둔다.
- 서버가 종료된 동안의 현실 시간을 자동 반영하지 않는다.
- 이동·대화·탐색 중 실시간 흐름을 사용할지, DM이 명시적으로만 진행할지는 캠페인 설정으로 교체 가능하다.

자동 진행도 내부적으로는 명시적인 Time Advance Transaction의 연속이다.

## 9. D&D 2024 Encounter 시간 정책

D&D 2024 기본 Policy는 다음 의미를 사용한다.

```text
1 Round
→ 약 6초의 세계 시간
```

엔진 계산에서는 이를 `6 game seconds`로 정규화한다.

중요:

```text
1 Turn
≠ 6초
```

한 라운드 안의 모든 참가자 Turn은 규칙 처리상 순차적이지만 세계관상 거의 동시에 진행된다. 참가자가 6명이라고 해서 한 라운드가 36초가 되지 않는다.

```text
Dnd2024RoundDurationPolicy
├─ roundDuration: 6 game seconds
├─ campaignAdvanceBoundary: round_end
├─ turnsAdvanceCampaignTime: false
├─ partialRoundPolicy
└─ durationConversionPolicy
```

기본 흐름:

```text
Round 시작
→ Actor A Turn
→ Actor B Turn
→ Actor C Turn
→ Round 종료 Commit
→ Campaign Game Time +6초
```

### 부분 라운드

Encounter가 라운드 도중 끝날 수 있으므로 `partialRoundPolicy`를 둔다.

지원 정책:

```text
count_started_round_on_encounter_end
count_completed_rounds_only
explicit_dm_resolution
custom_registered
```

D&D 2024 제품 기본값은 플레이테스트 후 확정하되, 어떤 정책도 개별 Turn마다 6초를 더하지 않는다.

### Encounter Clock과 Campaign Time

Encounter Timeline은 Turn·Round·Interrupt 순서를 위한 권위 구조다. Campaign Game Time을 복제하는 별도 절대 시계가 아니다.

```text
Encounter Boundary Commit
→ RoundDurationPolicy
→ TimeAdvanceProposal
→ Campaign Game Time Commit
```

## 10. Duration 의미 분리

다음 Duration을 하나의 초 단위 타이머로 강제하지 않는다.

```text
fixed_game_time
until_turn_boundary
fixed_turns
fixed_rounds
until_short_rest
until_long_rest
activity_progress
until_event
until_condition
concentration_bound
permanent
manual
```

예시:

```text
1분
→ fixed_game_time 또는 규칙 세트가 컴파일한 10-round duration

다음 자기 턴 시작까지
→ until_turn_boundary

10라운드
→ fixed_rounds

긴 휴식까지
→ until_long_rest
```

`다음 자기 턴 시작까지`를 임의로 6초 Deadline으로 변환하지 않는다. Turn Boundary가 실제 권위 종료 기준이다.

## 11. DurationHandle

Effect, Long Cast, Rest와 다른 Runtime은 자체 Frame Timer 대신 공통 Handle을 사용한다.

```text
DurationHandleState
├─ durationHandleId
├─ ownerBinding
├─ sourceDefinitionRef
├─ progressionKind
├─ campaignDeadline?
├─ encounterBinding?
├─ boundaryAnchor?
├─ remainingOccurrenceCount?
├─ activityProgressRef?
├─ pauseAndSuppressionPolicy
├─ crossModeMigrationPolicy
├─ dueState
├─ revision
└─ authorityEpoch
```

상태:

```text
active
→ due_candidate
→ resolved | cancelled | migrated
```

Duration Runtime은 만료 후보만 생성한다.

```text
Duration Due Candidate
→ Effect·Rest·Rule Runtime 최신 상태 재검증
→ 종료 또는 완료 Transaction
```

시간이 지났다는 이유만으로 Effect Store를 Scheduler가 직접 수정하지 않는다.

## 12. 고정 시간과 Encounter 경계 변환

고정 시간 Duration이 Encounter 안에서 사용될 때 규칙 세트는 변환 정책을 제공한다.

D&D 2024 예시:

```text
1분
→ 10 round cycles

10분
→ 100 round cycles
```

단, 단순히 Campaign Deadline만 Round End에서 검사하면 시전한 Turn 위치가 사라질 수 있다. 따라서 Encounter 안에서는 다음을 보존한다.

```text
시작 Encounter Occurrence
Boundary Actor 또는 Timeline Anchor
필요 Round Cycle 수
현재 완료 Cycle 수
```

예를 들어 자기 Turn에 시전한 1분 효과는 규칙 세트가 정한 동일한 Timeline Anchor에서 10 Cycle을 센다.

### Encounter 종료 시

Boundary 기반 Duration이 Encounter 밖으로 이동하면 `crossModeMigrationPolicy`가 남은 시간을 Campaign Duration으로 변환한다.

### Encounter 진입 시

Campaign Deadline 기반 Duration은 남은 시간을 보존한 상태로 유지하거나, 규칙 세트가 요구하면 Encounter Boundary Projection을 생성한다.

두 표현을 동시에 독립적으로 진행해 이중 만료시키지 않는다. 하나의 Handle이 현재 진행 권위 Domain을 소유한다.

## 13. Long Cast와 Activity Progress

1분 이상의 주문 시전처럼 단순 대기만으로 완료되지 않는 행동은 `ActivityProgressHandle`을 함께 사용한다.

```text
LongCastExecution
├─ requiredGameDuration
├─ elapsedEligibleGameDuration
├─ requiredBoundaryActions[]
├─ completedBoundaryActions[]
├─ concentrationBinding
├─ interruptionPolicy
└─ durationHandleRef
```

Encounter에서 1분 시전을 완료하려면 일반적으로 10라운드의 시간뿐 아니라 각 자기 Turn에 필요한 Magic Action을 수행해야 한다. 라운드가 지났다는 이유만으로 자동 완료하지 않는다.

Exploration에서는 Game Time Advance와 활동 상태가 모두 적격일 때만 진행한다.

## 14. Time Consumption

행동 Runtime은 Campaign Clock을 직접 더하지 않고 시간 비용을 선언한다.

```text
TimeCostDeclaration
├─ sourceCapabilityId
├─ durationExpression
├─ participationScope
├─ actorBusyPolicy
├─ concurrencyPolicy
├─ interruptionPolicy
├─ completionRequirement
└─ disclosurePolicy
```

예시:

```text
문 조사
→ 1분

복잡한 함정 해제
→ 10분

긴 휴식
→ 규칙 세트가 정의한 시간

여행
→ 경로와 속도에서 계산된 시간
```

### 병렬 활동

여러 참가자의 시간을 무조건 합산하지 않는다.

```text
A: 방 조사 10분
B: 아이템 식별 10분
동시에 수행
→ Campaign Time 10분 진행 가능
```

```text
A: 방 조사 10분
그 후 같은 A가 자물쇠 해제 10분
→ Campaign Time 20분
```

이를 위해 `ConcurrentActivityWindow`와 `TimeAdvancePlan`이 참가자별 Busy Interval을 결합한다.

### 공유 세계 시간

한 플레이어가 10분 행동을 선택했다고 즉시 파티 전체 Clock을 10분 점프하지 않는다.

```text
Time Cost 제안
→ 영향을 받는 참가자와 Scene 확인
→ 다른 참가자의 동시 활동 또는 대기 선택
→ DM·자동 정책 승인
→ 공통 TimeAdvancePlan Commit
```

## 15. Scheduler

Scheduler는 미래 시점과 경계에 연결된 실행 후보를 관리한다.

```text
ScheduledExecutionState
├─ scheduleId
├─ scheduleDefinitionRef
├─ ownerBinding
├─ dueSpecification
├─ recurrencePolicy?
├─ handlerBinding
├─ frozenPayload
├─ catchUpPolicy
├─ interruptionPolicy
├─ disclosurePolicy
├─ idempotencyKey
├─ state
├─ revision
└─ authorityEpoch
```

`dueSpecification`:

```text
game_time_deadline
calendar_instant
encounter_boundary
occurrence_count
activity_progress
after_domain_event
custom_registered
```

상태:

```text
scheduled
→ due_candidate
→ dispatched
→ completed

scheduled | due_candidate
→ cancelled | invalidated
```

Scheduler에 임의 Luau Callback을 저장하지 않는다. 등록된 Handler, RuleExecution Definition 또는 Command Definition만 참조한다.

## 16. Schedule Due 처리

```text
시간 또는 경계 진행
→ Due 후보 정렬
→ Schedule 상태 재검증
→ schedule.became_due Domain Event
→ 등록 Subscriber
→ 새 RuleExecution 또는 Command
→ 별도 Transaction
```

Scheduler Subscriber가 권위 Store를 직접 수정하지 않는다.

정렬 기본키:

```text
Due Instant 또는 Boundary Occurrence
→ Priority
→ Schedule Creation Revision
→ scheduleId
```

동일 Schedule은 `idempotencyKey`로 중복 실행을 막는다.

## 17. 대규모 Time Advance

8시간 휴식이나 수일 여행을 최종 시각까지 한 번에 Commit한 뒤 중간 사건을 소급 적용하지 않는다.

```text
+8시간 요청
→ 다음 Due 사건이 +2시간에 존재
→ 우선 +2시간 Advance Commit
→ Due 사건 해결
→ 남은 +6시간 Plan 재검증
→ 계속 또는 중단
```

중간 사건이 다음 진행을 막을 수 있다.

예시:

- 휴식 중 적대 Encounter
- 여행 중 위험
- 독 단계 변화
- 문 자동 폐쇄
- 제작 재료 부족
- 날짜 경계에서 발생하는 Campaign Event

비차단 Schedule은 Budget 범위에서 Batch로 처리할 수 있다. 차단 가능성이 있는 Schedule은 반드시 Time Advance Checkpoint를 만든다.

## 18. 반복 Schedule과 Catch-up

반복 Schedule은 누락된 횟수를 어떻게 처리할지 선언한다.

```text
run_each_occurrence
coalesce_to_latest
aggregate_count
skip_missed
pause_until_observed
custom_registered
```

예를 들어 1시간마다 피해를 받는 효과를 24시간 점프할 때, 24개의 개별 Roll이 필요한지 하나의 집계 Recipe를 사용할지는 콘텐츠·규칙 정책이 결정한다.

무제한 Catch-up Loop를 금지하고 최대 발생 수와 집계 Fallback을 둔다.

## 19. Pause와 Offline Progression

### Session Pause

Pause Gate 중:

- Exploration 자동 Game Time 진행 중지
- Encounter Timeline 진행 중지
- 새 Due 실행 Dispatch 중지
- 이미 Commit 중인 Transaction은 안전 경계까지 완료
- DM의 명시적 Time Advance는 권한·정책에 따라 허용 가능

### 서버 종료·오프라인

초기 제품 기본값:

```text
offline_world_progression = false
```

서버가 꺼져 있던 현실 시간만큼 Campaign Clock을 자동 진행하지 않는다. 향후 살아 있는 월드 기능을 추가하면 별도 Policy와 보안·Catch-up 계약이 필요하다.

## 20. Rest·Downtime·Travel 연결

### Rest

```text
RestSession
→ requiredDuration과 Activity Ledger
→ TimeAdvancePlan
→ 중간 Schedule·Interruption
→ completion_pending
→ Recovery Transaction
```

휴식 시간 충족은 회복 완료 후보일 뿐이다. Recovery Runtime이 최신 상태와 선택을 다시 검증한다.

### Downtime

제작·훈련·주문책 작업은 `TimeCostDeclaration`, Resource Reservation과 Completion Recipe를 사용한다.

### Travel

경로·속도·환경에서 계산한 Travel Duration을 TimeAdvancePlan으로 제출한다. Random Encounter 또는 Hazard는 중간 Checkpoint에서 진행을 중단할 수 있다.

## 21. Domain Event

기본 Domain Event:

```text
game_time.advanced
calendar.boundary_crossed
schedule.created
schedule.cancelled
schedule.became_due
duration.became_due
activity.progressed
time_advance.interrupted
```

Event는 Commit된 사실 또는 Due 후보를 설명한다. 실제 Effect 종료, 피해, 회복과 Scene 변경은 후속 RuleExecution·Command·Transaction이 담당한다.

모든 Domain Event에는 다음을 연결한다.

```text
chronologyId
authorityEpoch
authorityRevision
previousGameTime
currentGameTime
sourceAdvanceTransactionId
correlationId
```

## 22. 저장·복구·롤백

Snapshot 저장 대상:

```text
CampaignGameTimeState
Calendar Definition Ref와 Version
활성 DurationHandle
활성 ScheduledExecution
Scheduler Cursor
진행 중 TimeAdvancePlan
Concurrent Activity Window
Long Activity Progress
완료·취소 Tombstone Cursor
```

복구:

```text
Snapshot 복원
→ Journal 적용
→ Outbox Cursor 복원
→ Due Index 재구성
→ 현재 Instant 기준 Due 후보 재검증
→ 중복 Dispatch 방지
```

Rollback:

- Game Time과 Scheduler 상태도 함께 복원한다.
- 새 AuthorityEpoch를 생성한다.
- 이전 Epoch의 Schedule Dispatch와 Timeout 응답을 무효화한다.
- Replay 재생 속도는 Presentation Time이며 Campaign Game Time을 다시 진행시키지 않는다.

## 23. 역할과 권한

### PLAYER_ONLY

- 허용된 휴식·여행·시간 소모 행동 제안
- 자신의 장시간 활동 시작·취소
- 필요한 동시 활동 또는 대기 선택
- 공개된 Calendar와 남은 Duration 확인

### DM_ONLY

- Campaign Time 명시적 진행·정정
- 숨은 Scheduled Event 생성·취소
- Time Advance Plan 승인·중단
- 참가자 Busy State Override
- Calendar Policy 교체
- Rest·Travel·Downtime 시간 Override
- Due 사건 강제 실행·무효화

DM 변경도 Command·Transaction·Journal을 우회하지 않는다.

### SHARED

- 공개된 현재 날짜·시각 확인
- 공개된 휴식·여행 진행도 확인
- 공개 Duration과 예약된 공개 사건 확인

### SYSTEM_ONLY

- 자동 Exploration Time Advance Proposal
- Round Duration 변환
- Due Index와 Scheduler Cursor 관리
- Duration·Activity 진행 후보 생성
- Time Advance Checkpoint 분할
- 복구·멱등성·Epoch 검증

## 24. Projection과 UI 경계

Client는 전체 숨은 Schedule 목록을 받지 않는다.

```text
Authority Time State
+ Observer Context
+ Disclosure Policy
→ Time Projection
```

Player Projection 예시:

- 현재 공개 날짜·시간
- 자신의 공개 Duration
- 파티가 동의한 휴식·여행 진행도
- 알려진 마감 시각

DM Projection 예시:

- 전체 Schedule과 Due 상태
- 숨은 사건
- Advance Plan Checkpoint
- Duration Migration 상태
- Catch-up 진단

UI가 남은 시간을 계산해 표시할 수는 있지만 서버 Projection Revision보다 권위가 높지 않다.

## 25. 실패와 안전 규칙

- Time Advance 중 Due Handler 오류가 발생하면 해당 Checkpoint 이후 진행을 중단한다.
- Scheduler 오류로 Campaign Clock을 되돌리지 않는다. 후속 실행을 재시도하거나 DM 판정을 요청한다.
- 이미 Commit된 `game_time.advanced`를 Client 오류 때문에 취소하지 않는다.
- Calendar Parser 실패가 권위 Instant를 손상시키지 않는다.
- 잘못된 Schedule은 `failed_safe` 또는 `invalidated`로 격리한다.
- Presentation·UI Timer 실패는 Campaign Time에 영향을 주지 않는다.
- Client local clock과 timezone을 Gameplay 판정에 사용하지 않는다.

## 26. 성능과 확장성

- Due Instant 기준 Index와 Boundary 기준 Index를 분리한다.
- 모든 Schedule을 매 Frame Polling하지 않는다.
- Time Advance 시 변경 구간 안에 있는 Due Entry만 조회한다.
- 반복 Schedule은 필요에 따라 집계한다.
- Schedule Handler는 Registry와 Schema Version을 가진다.
- 새로운 Calendar·Round·Catch-up·Duration Migration Policy를 핵심 Runtime 수정 없이 등록할 수 있어야 한다.
- 플레이테스트 후 Round 길이, Exploration 시간 배율, 휴식 시간과 Catch-up 방식을 Policy 교체로 변경할 수 있어야 한다.

## 27. D&D 2024 기본값 요약

```text
Round
→ 약 6초

Turn
→ 개별 6초를 추가하지 않음

1분
→ Encounter에서 일반적으로 10 Round Cycle

다음 자기 Turn 시작까지
→ Turn Boundary Duration

Ritual
→ 기본 시전 시간 +10분

1분 이상 Casting Time
→ 시간 진행 + 각 Turn Magic Action + Concentration
```

정확한 휴식 시간, 활동 허용량, 주문별 Duration과 예외는 `dnd5e-2024` Ruleset Policy가 제공한다.

## 28. 완료 조건

다음이 가능해야 구현 준비가 완료된 것으로 본다.

- 한 라운드에 참가자가 몇 명이든 Campaign Time이 기본 6초만 진행된다.
- Turn Boundary Duration과 초·분 Duration이 서로 오염되지 않는다.
- 1분 Effect가 Encounter와 Exploration을 오가며 중복 만료되지 않는다.
- +8시간 Advance가 +2시간의 중간 사건을 건너뛰지 않는다.
- 두 참가자의 10분 병렬 행동이 20분으로 잘못 합산되지 않는다.
- Rest 중 Encounter 발생 시 남은 시간과 적격 진행도가 보존된다.
- Rollback 후 이전 Epoch Schedule이 재실행되지 않는다.
- Presentation Slow Motion이 Gameplay Duration을 늘리지 않는다.
- Client 시간 조작으로 주문·휴식·제작을 완료할 수 없다.
