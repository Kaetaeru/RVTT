# Encounter–Game Time Temporal Boundary와 Scheduler 통합 계약

- 상태: 확정
- 문서 종류: Architecture Integration Contract
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Encounter가 부분 라운드에서 종료될 때 Campaign Time을 반영하는 D&D 2024 기본 정책
  - 한 Temporal Boundary에서 Staging할 Scheduler Due 항목 수와 연쇄 깊이 상한
  - Blocking Due 항목을 처리하지 못했을 때 DM 복구 전환 시간
  - 같은 Boundary에 여러 Due 항목이 있을 때 기본 Timeline 삽입 우선순위
  - 완료된 Boundary·Due Occurrence와 멱등성 Tombstone 보존 기간
  - 다중 Encounter Temporal Group을 초기 공개 범위에서 허용할지 여부
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0078`](../decisions/ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md)
  - [`ADR-0079`](../decisions/ADR-0079-policy-driven-encounter-timelines-and-opportunity-gated-turns.md)
  - [`ADR-0081`](../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
  - [`ADR-0082`](../decisions/ADR-0082-atomic-encounter-boundary-time-advance-and-event-driven-scheduler-bridge.md)
- 상위 권위 문서:
  - [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime 계약`](ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - [`Encounter Timeline, Turn, Opportunity와 Objective Runtime 계약`](encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)
  - [`Game Time, Calendar, Duration과 Scheduler Runtime 계약`](game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event, Outbox, Subscription과 Projection Runtime 계약`](domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)

## 1. 목적

Encounter Runtime은 Turn·Round·Timeline Boundary를 소유하고, Game Time Runtime은 Campaign Game Time과 Scheduler를 소유한다.

D&D 2024 기본 정책에서는 한 Round가 약 6초이므로 두 Runtime은 연결되어야 한다. 그러나 양쪽 Service가 서로 직접 호출하면 다음 문제가 발생한다.

- `EncounterService → GameTimeService → EncounterService` 순환 의존
- Round는 끝났지만 Campaign Time 반영이 실패하는 부분 성공
- Campaign Time은 진행됐지만 Encounter Cursor가 이전 Round에 남는 불일치
- Scheduler Due Callback이 Encounter Store를 직접 수정하는 권위 우회
- 재시도·복구 중 같은 Round에 6초가 두 번 더해지는 중복 진행
- Rollback 이전 Timeline의 Due 작업이 새 AuthorityEpoch에 삽입되는 오류

따라서 이 문서는 다음 통합 흐름을 고정한다.

```text
Encounter Boundary Candidate
+ Frozen Policy Snapshot
→ 순수 Temporal Contribution 계산
→ Encounter Boundary + Campaign Time + Scheduler Due Staging 원자 Commit
→ Domain Event Outbox
→ 멱등 Scheduler Bridge Subscriber
→ 새 Encounter Command 또는 RuleExecution
```

핵심 원칙:

```text
Encounter는 Campaign Time Store를 직접 수정하지 않는다.
Game Time Scheduler는 Encounter Store를 직접 수정하지 않는다.
```

```text
완료된 Round와 그 Round가 소비한 Campaign Time은 하나의 권위 Transaction에서 함께 확정한다.
```

## 2. 고정 불변식

1. D&D 2024 기본 Policy에서 완전히 완료된 1 Round는 6 game seconds를 소비한다.
2. 개별 Turn, Reaction, Ready 발동, Lair Entry와 추가 Timeline Entry는 별도의 6초를 추가하지 않는다.
3. Encounter Boundary와 Campaign Time Advance는 서로 다른 후속 Transaction으로 분리하지 않는다.
4. Scheduler는 시간 진행 Transaction 안에서 Due 여부와 Due Occurrence만 확정한다. 실제 Gameplay 결과는 후속 Command 또는 RuleExecution이 처리한다.
5. 다음 Round 또는 다음 Blocking Timeline Entry는 필수 Temporal Due 처리가 정리되기 전에 시작하지 않는다.
6. 모든 계산은 Encounter가 고정한 Frozen Policy Snapshot을 사용한다.
7. 동일 Boundary의 재시도는 멱등적이어야 하며 Campaign Time을 중복 증가시키지 않는다.
8. Rollback 이후 이전 AuthorityEpoch의 Boundary·Due Occurrence를 재사용하지 않는다.
9. Presentation Animation, Client Frame과 현실 경과 시간은 이 계약의 Campaign Time 계산에 참여하지 않는다.
10. 같은 Campaign Chronology에는 기본적으로 하나의 Time-driving Encounter만 허용한다.

## 3. 책임 경계

### 3.1 Encounter Runtime

소유:

- Round·Turn·Timeline Boundary Candidate
- Boundary Sequence와 Encounter Timeline Revision
- Full Round 또는 Partial Round 분류
- RoundTimeLedger의 Encounter 측 기록
- 다음 Timeline Entry를 열 수 있는지 판단하는 Boundary Gate
- Scheduler Due 결과를 Encounter Entry 또는 RuleExecution으로 연결하는 Command 처리

소유하지 않음:

- Campaign Game Time 값
- Calendar 계산
- Scheduler Due Index
- Campaign Time Advance Transaction의 단독 Commit
- Scheduler Callback 실행

### 3.2 Game Time Runtime

소유:

- Campaign Game Time의 현재 Instant
- Encounter Boundary에 대응하는 경과 Duration 계산
- Time Advance Checkpoint와 Scheduler Due 탐색
- Scheduler Cursor와 Due Occurrence Staging
- Campaign Time State의 Commit Contribution

소유하지 않음:

- Encounter Cursor·Round Number·Timeline Entry
- 다음 Turn 시작 여부
- Due 효과의 실제 공격·피해·상태·오브젝트 변경
- Encounter Timeline 직접 삽입

### 3.3 Policy Runtime

소유:

- `encounter_temporal_advance` Policy Family
- Round Duration, Advance Boundary와 Partial Round 정책
- Scheduler Due를 Encounter Boundary에 매핑하는 정책
- Blocking·Non-blocking 분류
- Frozen Policy Snapshot과 Composition Trace

### 3.4 Transaction Coordinator

소유:

- Encounter State와 Game Time State의 Ordering Key 획득
- Read Set·Write Set 검증
- Boundary·Time·Scheduler Due Staging의 원자 Commit
- Domain Event Outbox 동시 기록

### 3.5 Domain Event Runtime

소유:

- Commit된 Boundary·Time Advance·Due Occurrence 전달
- Subscriber 멱등 재시도와 Dead Letter
- Event에서 후속 Command를 제출하는 안전한 연결

## 4. 직접 상호 호출 금지

다음 구조를 금지한다.

```text
EncounterService:CompleteRound()
→ GameTimeService:Advance(6)
→ Scheduler:RunCallbacks()
→ EncounterService:InsertEntry()
```

이 구조는 부분 실패, 순환 의존과 저장 복구 불일치를 만든다.

허용 구조:

```text
Encounter Runtime
→ TemporalBoundaryCandidate 생성

Temporal Contribution Provider
→ Snapshot-bound 읽기 전용 계산

Transaction Coordinator
→ Encounter + Game Time + Due Staging 원자 Commit

Outbox Subscriber
→ 후속 Encounter Command 제출
```

`Temporal Contribution Provider`는 Game Time Runtime의 내부 Store를 수정하지 않는 순수 Provider다. Snapshot과 Candidate가 같으면 같은 결과를 반환해야 한다.

## 5. 통합 데이터 계약

### 5.1 TemporalBoundaryCandidate

Commit 전 Transaction 입력이다.

```text
TemporalBoundaryCandidate
├─ candidateId
├─ encounterId
├─ encounterIncarnation
├─ authorityEpoch
├─ chronologyId
├─ temporalCoordinationScopeId
├─ boundarySequence
├─ boundaryKind
├─ roundNumber
├─ timelineRevision
├─ completedEntryOccurrenceIds[]
├─ roundCompletionClass
├─ currentCampaignInstant
├─ frozenPolicySnapshotRef
├─ expectedEncounterRevision
├─ expectedGameTimeRevision
├─ sourceCommandId
└─ idempotencyKey
```

`boundaryKind` 초기 값:

```text
round_start
turn_start
turn_end
round_end
encounter_end
custom_registered
```

모든 Boundary가 Campaign Time을 진행하지 않는다. 기본 D&D 2024 Policy에서는 `round_end`가 Full Round Advance 후보다.

`roundCompletionClass`:

```text
full_round
partial_round
administrative_boundary
rollback_restoration
```

`rollback_restoration`은 음수 Time Advance를 만들지 않는다. Rollback은 Snapshot 복원과 새 AuthorityEpoch로 처리한다.

### 5.2 EncounterTimeAdvanceContribution

읽기 전용 Provider가 계산해 Transaction Proposal에 기여한다.

```text
EncounterTimeAdvanceContribution
├─ contributionId
├─ candidateId
├─ chronologyId
├─ fromInstant
├─ requestedDuration
├─ approvedDuration
├─ toInstant
├─ policySnapshotRef
├─ roundDurationPolicyRef
├─ partialRoundPolicyRef
├─ checkpointResults[]
├─ dueScheduleCandidates[]
├─ blockingDueCandidateIds[]
├─ schedulerCursorPrecondition
├─ diagnostics[]
└─ contributionHash
```

`approvedDuration`은 Policy와 Checkpoint 검증 결과다. Full Round 기본값은 6 game seconds다.

Contribution은 상태를 변경하지 않으며 Transaction이 Commit될 때만 효력이 생긴다.

### 5.3 TemporalBoundaryOccurrence

원자 Commit 이후 생성되는 Domain Event용 확정 기록이다.

```text
TemporalBoundaryOccurrence
├─ occurrenceId
├─ encounterId
├─ encounterIncarnation
├─ authorityEpoch
├─ chronologyId
├─ boundarySequence
├─ boundaryKind
├─ roundNumber
├─ timelineRevisionBefore
├─ timelineRevisionAfter
├─ elapsedGameDuration
├─ campaignInstantBefore
├─ campaignInstantAfter
├─ policySnapshotRef
├─ transactionId
├─ dueOccurrenceIds[]
└─ occurrenceHash
```

이 기록은 이미 Commit된 과거 사실이다. Subscriber가 Duration이나 Boundary 결과를 수정하지 않는다.

### 5.4 ScheduledDueOccurrence

```text
ScheduledDueOccurrence
├─ dueOccurrenceId
├─ scheduledExecutionId
├─ authorityEpoch
├─ chronologyId
├─ dueInstant
├─ observedAtBoundaryOccurrenceId
├─ encounterBinding?
├─ dueMappingMode
├─ blockingMode
├─ targetDomain
├─ sourceScheduleVersion
├─ lifecycleState
├─ transactionId
└─ idempotencyKey
```

`lifecycleState`:

```text
staged
→ command_submitted
→ accepted
→ resolved

실패·종료:
rejected_stale
failed_safe
dead_lettered
superseded
```

## 6. Policy Family

통합 계약은 `encounter_temporal_advance` Policy Family를 사용한다.

```text
EncounterTemporalAdvancePolicy
├─ roundDuration
├─ campaignAdvanceBoundary
├─ individualTurnAddsTime
├─ extraTimelineEntryAddsTime
├─ partialRoundPolicy
├─ schedulerDueMappingPolicy
├─ boundaryGatePolicy
├─ simultaneousEncounterPolicy
└─ failureRecoveryPolicy
```

D&D 2024 기본값:

```text
roundDuration = 6 game seconds
campaignAdvanceBoundary = round_end
individualTurnAddsTime = false
extraTimelineEntryAddsTime = false
```

다음은 Frozen Snapshot에 고정한다.

- Round Duration
- Partial Round 처리
- 같은 Instant의 Due 정렬 방식
- Blocking Due 기준
- 다음 Round Gate 방식
- 다중 Encounter 조정 방식

진행 중 Encounter가 최신 Campaign Policy를 다시 조회하지 않는다.

## 7. 정상 Round 종료 흐름

```text
마지막 Timeline Entry 종료 후보
→ 열린 RuleExecution·Reaction·Reservation 정리 확인
→ TemporalBoundaryCandidate 생성
→ Frozen Policy Snapshot 검증
→ EncounterTimeAdvanceContribution 계산
→ Ordering Key 획득
→ 최신 Encounter·Game Time·Scheduler Revision 재검증
→ 원자 Commit
→ Domain Event Outbox 기록
→ 다음 Boundary Gate 평가
```

원자 Commit의 Write Set에는 최소한 다음이 포함된다.

```text
Encounter Timeline Cursor·Round State
Encounter RoundTimeLedger
CampaignGameTimeState.currentInstant
Scheduler Cursor와 Due Occurrence Staging
TemporalBoundaryOccurrence
Domain Event Outbox
```

다음 상태는 허용하지 않는다.

```text
Round 3 종료 Commit
Campaign Time은 Round 2 시각
```

또는:

```text
Campaign Time +6초 Commit
Encounter는 Round 3 마지막 Turn 진행 중
```

## 8. D&D 2024 시간 의미

### 8.1 한 Round는 6초

```text
Round 1
├─ Actor A Turn
├─ Actor B Turn
├─ Actor C Turn
├─ Reaction과 Ready 발동
└─ 환경 Entry

Campaign Time Advance
→ 총 6초
```

참가자가 다섯 명이라고 30초를 더하지 않는다.

### 8.2 시간 추가가 없는 항목

기본 D&D 2024 Policy에서 다음은 별도 Campaign Time을 추가하지 않는다.

- 개별 Turn 시작·종료
- Reaction
- Ready Action 발동
- Opportunity Attack
- Legendary·Lair·Hazard Entry
- 소환체의 별도 Turn
- 추가 Turn 또는 Timeline 삽입
- Initiative 재정렬
- 동률 해결 Prompt
- 주사위 Animation과 VFX

이 항목은 같은 Round의 약 6초 안에서 일어난다.

### 8.3 Turn 수와 Round Duration 분리

Actor가 기절해 Turn을 건너뛰어도 Full Round Duration은 기본적으로 6초다. 추가 Actor가 합류해도 Round Duration이 늘어나지 않는다.

### 8.4 부분 라운드 종료

Encounter가 Round 중간에 끝날 때의 추가 Campaign Time은 `partialRoundPolicy`가 결정한다.

허용 정책 예:

```text
completed_rounds_only
count_started_round_as_full
proportional_by_boundary_occurrence
explicit_dm_adjudication
```

이 결정은 Core에 하드코딩하지 않으며, 적용 결과와 근거를 RoundTimeLedger에 기록한다.

## 9. Scheduler Due Staging

Time Advance Contribution은 `(fromInstant, toInstant]` 범위의 Schedule을 조회한다.

```text
Campaign Time 10:00:00
→ Round End +6초
→ 10:00:06
```

이 구간 안의 Schedule은 같은 Transaction에서 `ScheduledDueOccurrence`로 Staging한다.

중요:

```text
Due Staging
≠ 실제 효과 적용
```

예를 들어 독 피해 Schedule이 Due가 되어도 Time Transaction이 HP를 직접 변경하지 않는다.

```text
schedule.became_due
→ RuleExecution Command
→ 피해 Resolution
→ 별도 Authority Transaction
```

## 10. Scheduler에서 Encounter로의 역방향 연결

Commit 후 `schedule.became_due` Domain Event를 멱등 Subscriber가 처리한다.

```text
ScheduledDueOccurrence
→ EncounterTemporalBridgeSubscriber
→ 현재 AuthorityEpoch·Encounter Incarnation 검증
→ Frozen Policy와 Due Mapping 확인
→ 새 Command 제출
```

가능한 Command:

```text
InsertTemporalTimelineEntryCommand
OpenScheduledRuleExecutionCommand
AttachDueOccurrenceToBoundaryGateCommand
ResolveExternalScheduledOperationCommand
```

Subscriber는 Encounter Store를 직접 수정하지 않는다.

### 10.1 Due Mapping Mode

```text
before_next_timeline_entry
before_next_round_start
at_current_boundary_aftermath
non_encounter_domain
manual_dm_adjudication
custom_registered
```

예:

- Round 종료 시 만료되는 지속 피해: `at_current_boundary_aftermath`
- 다음 Round 시작 전에 발생하는 환경 붕괴: `before_next_round_start`
- Encounter와 무관한 제작 완료: `non_encounter_domain`

### 10.2 Blocking Mode

```text
blocking
non_blocking
```

`blocking` Due는 필요한 Command가 Accept되고 안전 경계에 연결되기 전까지 다음 Encounter 진행을 막는다.

`non_blocking` Due는 다음 Turn을 막지 않지만 Ordering과 규칙상 결과가 현재 Encounter에 영향을 주기 전에 최신 상태를 재검증한다.

## 11. Boundary Gate

```text
Boundary Gate
├─ Boundary Transaction Commit 완료
├─ 필수 Outbox Event 생성 확인
├─ Blocking Due Command 상태
├─ 열린 RuleExecution·Reaction 상태
├─ Encounter End Candidate 상태
└─ Recovery Flag
```

다음 Round를 열기 위한 기본 조건:

```text
Boundary Commit 완료
+ 모든 Blocking Due가 accepted 또는 안전하게 adjudicated
+ 이전 Round의 필수 실행 종료
→ 다음 Round Start 가능
```

Presentation 완료는 기본 Gate가 아니다. 주사위 공개처럼 별도 Presentation Gate가 명시된 경우만 기다린다.

## 12. 다중 Encounter와 하나의 Campaign Time

같은 `chronologyId`에 속한 Encounter가 각각 Round 종료마다 6초를 더하면 세계 시간이 중복 진행된다.

초기 안전 정책:

```text
한 Chronology
→ 하나의 time_driving Encounter
```

다른 활성 Encounter는 다음 중 하나여야 한다.

```text
time_following
paused_by_policy
separate_chronology
synchronized_temporal_group
```

`time_following` Encounter는 자신의 Round 종료로 Campaign Time을 직접 진행하지 않고 Time-driving Encounter의 Boundary Occurrence를 참조한다.

`synchronized_temporal_group`은 여러 Encounter가 동일 Temporal Window를 공유하는 확장 기능이다. 초기 구현에 포함한다면 모든 Blocking Encounter가 호환 Boundary에 도달했을 때 한 번만 Campaign Time을 진행해야 한다.

임의로 두 Encounter가 각각 독립 6초를 Commit하는 것은 금지한다.

## 13. 멱등성과 순서

Boundary의 멱등성 Key 예:

```text
AuthorityEpoch
+ EncounterId
+ EncounterIncarnation
+ BoundarySequence
+ FrozenPolicySnapshotHash
```

같은 Key의 재시도는 다음 중 하나를 반환한다.

```text
기존 Commit Result
진행 중 Transaction 상태
명시적 stale·conflict 오류
```

새 Time Advance를 만들지 않는다.

Due Subscriber의 멱등성 Key:

```text
DueOccurrenceId
+ SubscriberId
+ HandlerVersion
```

Event 전달은 at-least-once일 수 있으므로 중복 Command 제출 방지 기록을 유지한다.

동일 Campaign Instant에 여러 Due가 있으면 Frozen Policy가 정의한 안정적 Priority와 Stable ID Tie-breaker로 정렬한다.

## 14. 저장·복구·재접속

저장 대상:

- Encounter RoundTimeLedger
- Boundary Sequence와 마지막 Commit Transaction
- Campaign Game Time Revision
- Scheduler Cursor
- ScheduledDueOccurrence와 Lifecycle
- Boundary Gate 상태
- Frozen Policy Snapshot Reference
- Subscriber 멱등 처리 기록

서버 복구 시:

```text
마지막 Authority Snapshot 로드
→ Commit Journal 재생
→ Boundary·Time State 일치 검증
→ Outbox Cursor 복구
→ 미처리 Due Subscriber 재시도
→ Blocking Gate 재구성
```

Client 재접속은 Boundary 계산에 참여하지 않는다. 현재 Encounter Projection과 Campaign Time Projection을 새 Connection Epoch로 다시 받는다.

## 15. Rollback

Rollback은 Campaign Time에 음수 Duration을 적용하는 Command가 아니다.

```text
선택한 Authority Snapshot 복원
→ 새 AuthorityEpoch 생성
→ Encounter·Game Time·Scheduler 상태 함께 복원
→ 이전 Epoch의 Boundary·Due·Subscriber 작업 무효화
→ Full Projection Resync
```

이전 Epoch의 `schedule.became_due` Event가 늦게 도착하면 `rejected_stale`로 종료한다.

Rollback 대상에는 Encounter State만이 아니라 다음이 함께 포함되어야 한다.

- Campaign Game Time
- Scheduler Cursor와 Due Occurrence
- RoundTimeLedger
- Boundary Gate
- Frozen Policy Snapshot Reference

## 16. 실패 정책

### Contribution 계산 실패

- Boundary Transaction을 시작하지 않는다.
- Encounter는 현재 안전한 Boundary 이전 상태를 유지한다.
- Campaign Time을 변경하지 않는다.
- 진단과 DM 복구 옵션을 제공한다.

### 원자 Commit 충돌

- 최신 Revision에서 Candidate와 Contribution을 다시 계산한다.
- 같은 멱등성 Key를 사용한다.
- 일부 Store만 Commit하지 않는다.

### Outbox 또는 Subscriber 지연

- Boundary·Time Commit은 유지한다.
- Blocking Gate가 다음 Round를 차단한다.
- Subscriber를 멱등 재시도한다.

### Due Command 거절

- Stale Encounter면 `rejected_stale`로 종료한다.
- 필수 효과면 DM Adjudication 또는 Recovery State로 전환한다.
- 조용히 Due Occurrence를 삭제하지 않는다.

### Policy Snapshot 누락

- 최신 Policy를 임의 적용하지 않는다.
- 참조된 Snapshot 복구 또는 명시적 Migration이 필요하다.
- 실패하면 Last Known Good 상태를 유지하고 진행을 차단한다.

## 17. Domain Event

초기 Event 종류:

```text
encounter.temporal_boundary_committed
game_time.advanced
schedule.became_due
encounter.temporal_due_command_submitted
encounter.temporal_due_attached
encounter.boundary_gate_opened
encounter.boundary_gate_blocked
```

`encounter.temporal_boundary_committed`, `game_time.advanced`, `schedule.became_due`는 같은 Transaction의 Outbox에 기록될 수 있다.

Client에는 Raw Domain Event를 그대로 보내지 않는다. 시간·Round·Due 정보는 Observer별 Projection으로 변환한다.

## 18. Projection과 사용자 경험

플레이어에게 필요한 정보:

- 현재 Round와 Turn
- 세계 시간이 진행됐는지 여부
- 공개 가능한 지속 효과 만료·환경 사건
- 다음 Round 진행이 기다리는 이유

DM에게 추가 제공:

- Boundary Sequence와 Transaction ID
- 적용된 Frozen Policy Snapshot
- 6초 또는 부분 라운드 계산 근거
- Due Schedule 목록과 Blocking 상태
- Subscriber·Command 실패와 복구 조작

숨은 Schedule의 이름·대상·정확한 시각은 Disclosure Policy에 따라 Player Projection에서 제거한다.

## 19. 진단 요구

통합 Trace는 최소한 다음 Correlation을 보존한다.

```text
Turn End Command
→ Round Boundary Candidate
→ Temporal Contribution
→ Authority Transaction
→ Boundary Occurrence
→ Game Time Advanced
→ Schedule Due Occurrence
→ Subscriber
→ Encounter Command 또는 RuleExecution
```

필수 진단:

- 같은 Boundary의 중복 Time Advance 탐지
- Encounter와 Campaign Time Revision 불일치
- Scheduler Cursor 역행
- Blocking Due가 남은 상태에서 다음 Round 시작
- 이전 AuthorityEpoch Due 재사용
- 두 Time-driving Encounter의 동시 Advance 시도

## 20. 금지 사항

- Encounter가 `CampaignGameTimeState.currentInstant`를 직접 수정
- Scheduler Callback에서 Encounter Timeline Table 직접 변경
- Round Commit 후 별도 비원자 `AdvanceTime(6)` 호출
- 개별 Turn마다 6초 추가
- 추가 Timeline Entry 수만큼 Round Duration 증가
- Event Subscriber가 기존 Boundary Transaction을 수정
- Due Schedule을 임의 Luau Callback으로 저장
- Client Clock이나 Animation 완료를 Campaign Time 권위로 사용
- Rollback을 음수 Time Advance로 구현
- Policy Snapshot이 없을 때 최신 Policy 자동 적용
- 동일 Chronology의 여러 Encounter가 조정 없이 각각 시간 진행

## 21. 구현 명세 분해

후속 구현 명세 권장 순서:

```text
001 Temporal Boundary Candidate와 Contribution Provider
002 Atomic Encounter–Game Time Boundary Transaction
003 Scheduler Due Occurrence와 Outbox
004 Encounter Temporal Bridge Subscriber와 Commands
005 Boundary Gate와 Recovery
006 Multi-Encounter Chronology Guard
007 Persistence·Rollback·Deterministic Tests
```

## 22. Guide 상태

```text
Guide Status: NOT_READY
```

UI Runtime, Diagnostics, Simulation 기반과 Cross-System Completion Audit가 완료된 뒤 Main System Guide에 통합한다.
