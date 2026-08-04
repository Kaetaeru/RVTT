# Downtime Activity, Time Coordination과 Atomic Completion Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - DowntimeSession당 동시 Activity와 Participant 상한
  - 참가자 선택 응답 Timeout과 DM Fallback 기본값
  - 장시간 Activity Progress Checkpoint 기본 간격
  - 취소 시 재료·비용·진행도 반환 기본 정책
  - Downtime Window에서 미응답 참가자의 기본 Activity
  - Travel Resolution의 중간 사건 제안 빈도와 최대 연쇄 깊이
  - 완료된 Activity·Reservation·Progress Tombstone 보존 기간
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0031`](../decisions/ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0064`](../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0078`](../decisions/ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md)
  - [`ADR-0080`](../decisions/ADR-0080-downtime-as-time-coordinated-activity-sessions-with-domain-owned-completion.md)
- 상위 문서:
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Game Time, Calendar, Duration과 Scheduler Runtime 계약`](game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event, Outbox, Subscription과 Projection Runtime 계약`](domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)
- 관련 Runtime:
  - [`Character Runtime과 Compiled Character Build 계약`](character-runtime-and-compiled-character-build-contract.md)
  - [`Inventory, ItemInstance와 World Presence Runtime 계약`](inventory-item-instance-and-world-presence-runtime-contract.md)
  - [`Effect, Condition과 Ongoing Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
- 관련 시스템:
  - [`HP 0·죽음 내성·휴식·자원 회복 모델`](../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
  - [`주문 획득·준비·시전 권한 모델`](../systems/character/spell-acquisition-preparation-and-cast-access-model.md)
  - [`주문책 저장소와 복사 모델`](../systems/character/spellbook-repository-and-copying-model.md)

## 1. 목적

이 문서는 실시간 Scene 플레이보다 Campaign Time 진행, 여러 참가자의 장기 활동, Character Source·State 변경과 복수 Domain Transaction이 중심인 `Downtime Runtime`을 정의한다.

초기 지원 종류:

```text
short_rest
long_rest
level_up
spell_preparation
spellbook_work
crafting
training
travel_resolution
custom_registered
```

Downtime은 개별 기능을 다시 구현하는 거대한 규칙 엔진이 아니다.

```text
DowntimeSession
→ 참가자와 활동을 같은 Campaign Time Window에 배치
→ 선택·비용·진행도와 중간 사건을 조정
→ Game Time을 안전한 Checkpoint까지 진행
→ 각 Domain이 만든 Completion Plan을 원자적으로 Commit
```

핵심 원칙:

```text
Downtime은 시간과 활동을 조정한다.
휴식·레벨업·주문·아이템 규칙의 결과는 해당 Domain이 소유한다.
```

## 2. 사용자 결과

이 계약은 다음 경험을 보장한다.

- 한 캐릭터가 8시간 제작한다고 그 캐릭터에게만 별도의 8시간이 흐르지 않는다.
- 같은 시간 동안 다른 캐릭터는 휴식, 경계, 훈련, 주문책 작업이나 대기를 선택할 수 있다.
- 휴식·여행 중 사건이 발생하면 남은 시간을 건너뛰지 않고 사건 지점에서 멈춘다.
- 레벨업이 실패해도 기존 Character Build와 현재 상태가 손상되지 않는다.
- 주문 준비 변경, 제작 재료 소비와 완성품 생성이 부분 성공으로 남지 않는다.
- 연결이 끊겨도 진행 중 활동, 선택, 예약과 경과 시간이 복구된다.
- 플레이어는 자신의 활동과 선택을 제출하고, DM은 숨은 사건·예외·강제 진행을 통제한다.
- 플레이테스트 후 활동 종류, 필요 시간, 중단·환불 정책을 Core 수정 없이 교체할 수 있다.

## 3. 책임 분리

### 3.1 Downtime Runtime이 소유한다

- `DowntimeSession` Identity와 상태기계
- 참가자별 Activity 배정과 동시 활동 Window
- 활동 간 선행조건·의존성·지원 관계
- 필수 선택, DM 승인과 응답 대기
- 장시간 Domain Reservation의 수명주기 조정
- Time Consumption을 `TimeAdvancePlan`으로 결합
- Scheduler·중간 사건·Encounter에 따른 Checkpoint 정지
- Activity Progress Ledger
- Domain Completion Plan 수집과 Atomic Completion 조정
- 저장·복구·Rollback용 Downtime Snapshot
- 역할별 Downtime Projection과 감사 Trace

### 3.2 소유하지 않는다

- 휴식 적격성, 회복량과 Hit Dice 규칙
- Character Progression Source, Build Compile와 State Migration 규칙
- 주문 습득·준비·주문책 규칙
- 제작 Recipe의 입력·산출물 규칙
- 훈련으로 실제 획득하는 Feature 규칙
- 여행 경로의 지형·이동 계산
- Encounter Initiative와 Turn
- Campaign Game Time의 권위 값
- ItemInstance, Resource와 Effect Store의 직접 Mutation

### 3.3 Domain별 책임

```text
Rest Domain
→ RestSession, Activity Ledger 분류, RecoveryPlan

Character Domain
→ Progression Change Proposal, Candidate Build, State Migration

Spell Access Domain
→ Preparation Change, Spell Choice와 Cast Route 재계산

Spellbook Domain
→ Repository Entry, Copy Requirement와 결과

Inventory Domain
→ 재료 Reservation, Item Transfer와 Output ItemInstance

Game Time Runtime
→ Campaign Time Advance와 Scheduler Checkpoint

Encounter Runtime
→ 중간 Encounter가 발생했을 때 Turn 기반 진행
```

Downtime Runtime은 이 결과를 조정하지만 각 규칙을 복제하지 않는다.

## 4. Downtime과 Long Exploration Action의 경계

모든 긴 행동이 Downtime Mode는 아니다.

```text
LongExplorationAction
→ 현재 Scene 안에서 즉시 진행
→ 이동·위험·상호작용과 밀접
→ 다른 참가자가 실시간 탐험을 계속할 수 있음

DowntimeActivity
→ Campaign Time을 의미 있게 진행
→ 여러 참가자의 활동 배정이 필요
→ 장기 Resource·Build·Inventory 변경 가능
→ 중간 사건과 Atomic Completion이 필요
```

예시:

```text
문 하나를 10분 조사
→ Scene 위험과 다른 Actor 행동에 따라 LongExplorationAction 또는 Downtime 전환 후보

긴 휴식·하루 제작·레벨업
→ DowntimeActivity
```

`DowntimeEntryPolicy`가 상황, 시간 규모와 Campaign 설정을 바탕으로 제안하며 DM이 최종 전환을 승인할 수 있다.

## 5. Campaign Time은 참가자별로 갈라지지 않는다

초기 제품의 세계 시간 권위 원본은 하나의 Campaign Game Time이다.

```text
Character A: 8시간 제작
Character B: 8시간 훈련
Character C: 8시간 경계·휴식 조합

동시에 진행
→ Campaign Time 8시간
```

다음을 금지한다.

```text
A만 +8시간
B는 기존 시각 유지
```

따라서 시간 진행 전 현재 Downtime Window에 속한 모든 관련 참가자에게 활동 또는 기본 Passage Policy를 배정한다.

```text
active_activity
supporting_activity
resting
watching
traveling
idle
absent_character_policy
custom_registered
```

오프라인 플레이어의 캐릭터도 DM 또는 Campaign Policy가 승인한 기본 활동 없이 자동으로 성장·회복하지 않는다.

## 6. DowntimeSession

```text
DowntimeSessionState
├─ downtimeSessionId
├─ campaignId
├─ authorityEpoch
├─ scope
├─ downtimeKindSummary[]
├─ participantBindings[]
├─ activityInstances[]
├─ activityDependencyGraph
├─ currentWindow
├─ timeAdvancePlanRef?
├─ activeReservationRefs[]
├─ pendingChoiceRefs[]
├─ pendingApprovalRefs[]
├─ checkpointState?
├─ completionPlanRefs[]
├─ sourceModeSnapshot
├─ lifecycleState
├─ revision
└─ terminalRecord?
```

`scope`:

```text
session_wide
participant_group
scene_group
campaign_admin
```

Scope가 일부 참가자만 포함하더라도 실제 Campaign Time이 진행되면 영향을 받는 다른 Character·Scene·Schedule을 Game Time Runtime이 함께 처리한다.

## 7. Session 상태기계

```text
proposed
→ collecting_participants
→ collecting_activities
→ validating
→ ready_to_advance
→ advancing_time
→ resolving_checkpoint
→ awaiting_choices | awaiting_approval
→ preparing_completion
→ committing_completion
→ completed
```

보조·실패 상태:

```text
suspended
cancelled
invalidated
failed_safe
recovery_required
```

### suspended와 Pause Overlay

`suspended`는 Encounter, 중간 사건 또는 필수 조건 손실로 활동 진행이 중단된 Domain 상태다.

`Pause Overlay`는 현재 입력과 진행을 일시 차단하는 Session Overlay다. 둘을 같은 상태로 취급하지 않는다.

## 8. Activity Definition, Build와 Instance

### 8.1 Definition Source

```text
DowntimeActivityDefinitionSource
├─ activityDefinitionId
├─ activityKind
├─ schemaVersion
├─ rulesetRef
├─ eligibilityPolicy
├─ participantPolicy
├─ timeRequirementDefinition
├─ concurrencyPolicy
├─ inputRequirementDefinitions[]
├─ reservationPolicy
├─ progressPolicy
├─ interruptionPolicy
├─ completionProviderId
├─ cancellationPolicy
├─ disclosurePolicy
└─ presentationProfileRef
```

Definition은 현재 참가자, 실제 재료, 경과 시간과 선택값을 포함하지 않는다.

### 8.2 Compiled Activity Build

```text
CompiledDowntimeActivityBuild
├─ activityBuildId
├─ sourceRef와 hash
├─ normalizedEligibilityPlan
├─ compiledTimePlan
├─ compiledInputPlan
├─ compiledProgressPlan
├─ compiledInterruptionPlan
├─ completionProviderBinding
├─ dependencyRefs[]
├─ diagnostics
└─ buildHash
```

### 8.3 Activity Instance

```text
DowntimeActivityInstance
├─ activityInstanceId
├─ downtimeSessionId
├─ activityBuildRef
├─ ownerCharacterRef?
├─ actorRef?
├─ participantRefs[]
├─ supportParticipantRefs[]
├─ frozenChoices
├─ liveBindingRefs[]
├─ inputReservationRefs[]
├─ progressState
├─ timeRequirementState
├─ interruptionRecords[]
├─ completionCandidateRef?
├─ lifecycleState
├─ revision
└─ terminalRecord?
```

Activity Instance가 Character, Item과 Effect 상태의 복사본을 권위 원본으로 저장하지 않는다.

## 9. Activity Lifecycle

```text
proposed
→ validating
→ awaiting_inputs | awaiting_choices
→ ready
→ active
↔ suspended
→ completion_candidate
→ awaiting_completion_choices
→ completed
```

실패·종료:

```text
cancelled
invalidated
failed_safe
superseded
```

Activity 완료 여부는 UI Progress Bar가 아니라 Domain Completion Provider의 최신 검증 결과로 확정한다.

## 10. 참가자와 동시 활동 Window

```text
DowntimeWindow
├─ windowId
├─ startGameTime
├─ participantAssignments[]
├─ dependencyEdges[]
├─ nextCheckpointCandidates[]
├─ fallbackAssignments[]
└─ revision
```

기본 규칙:

- 같은 Character는 같은 시간 구간에 기본적으로 하나의 `primary_activity`만 수행한다.
- `secondary_activity`는 Definition이 명시적으로 허용할 때만 가능하다.
- 도움·경계·교대 수면은 별도 Support Assignment로 모델링한다.
- 두 Activity가 동일 Item, Tool, Actor 또는 Location을 독점하면 Reservation 충돌을 해결한다.
- 순차 의존 활동은 Dependency Edge로 표현한다.
- 서로 독립적인 활동 시간은 합산하지 않고 병렬로 진행한다.

예시:

```text
A: 주문책 복사 2시간
B: 짧은 휴식 1시간 → 이후 경계 1시간

첫 Checkpoint
→ 1시간
→ B 휴식 완료 후보 해결

두 번째 Checkpoint
→ 추가 1시간
→ A 주문책 복사 완료 후보
```

## 11. 선택과 승인

```text
DowntimeChoiceRequest
├─ choiceRequestId
├─ activityInstanceId
├─ participantOrController
├─ choiceKind
├─ optionsProjection[]
├─ validationSnapshot
├─ deadlinePolicy
├─ fallbackPolicy
└─ state
```

플레이어는 자신의 활동·준비 주문·Hit Dice·레벨업 선택·제작 대상 등을 선택한다.

DM은 다음을 승인하거나 수정할 수 있다.

- 규칙 밖 활동 허용
- 숨은 비용·사건·훈련 자격
- 시간 진행 범위
- 미응답 참가자의 Fallback
- 강제 취소·재개·완료

입력 계약:

```text
E
→ 현재 최상위 Downtime 선택·승인 확정

Q
→ 현재 선택 한 단계 취소·이전 단계 복귀·요청 거절
```

DM 승인 Prompt가 최상위 Context이면 E/Q는 기존 다른 창보다 승인·거절에 우선한다.

## 12. Input과 장기 Reservation

Downtime은 장시간 진행되므로 Ordering Lock을 유지하지 않는다.

```text
Ordering Reservation
→ Completion Commit 직전에 짧게 획득

Domain Reservation
→ 재료, 비용, 선택권과 사용 자격을 장시간 보존
```

지원 Reservation 예시:

```text
item_instance_reservation
currency_or_resource_reservation
tool_or_facility_reservation
progression_choice_reservation
spell_repository_slot_reservation
character_activity_slot_reservation
```

Reservation은 실제 소비가 아니다.

```text
available
→ reserved(activityInstanceId)
→ committed_consumed | released | partially_settled
```

취소·중단 시 반환량과 진행도 보존은 Activity Definition의 Cancellation·Interruption Policy가 결정한다.

## 13. TimeAdvancePlan

Downtime Runtime은 활동별 필요 시간을 직접 더하지 않는다.

```text
Activity Time Requirements
+ 참가자 동시 활동 Window
+ Scheduler Due Times
+ Rest·Travel Checkpoints
+ DM Stop Point
→ TimeAdvancePlan
```

```text
TimeAdvancePlan
├─ planId
├─ downtimeSessionId
├─ startInstant
├─ requestedEndInstant
├─ nextSafeCheckpoint
├─ participantCoverage
├─ activeActivityRefs[]
├─ schedulerBoundaryRefs[]
├─ expectedProgressDeltas[]
├─ interruptionPolicies[]
├─ validationSnapshot
└─ revision
```

Game Time Runtime이 실제 시간을 진행한다.

```text
현재 시각
→ 가장 가까운 Activity·Scheduler·사건 Checkpoint까지 Advance
→ Domain Event 발행
→ 모든 Activity 재검증
→ 다음 Advance 여부 결정
```

## 14. 중간 사건과 Encounter

휴식·여행·제작 중 다음 사건이 발생할 수 있다.

```text
Scheduled Event
Hazard
Enemy Encounter
환경 변화
시설·도구 상실
참가자 상태 변경
```

흐름:

```text
Time Advance
→ 중간 Checkpoint 도달
→ 사건 RuleExecution 또는 EncounterProposal
→ DowntimeSession suspended
→ 사건 해결
→ Activity Eligibility·Reservation·남은 시간 재검증
→ 재개·변환·취소
```

남은 시간을 자동으로 계속 진행하지 않는다.

Encounter가 시작됐다고 Activity Progress를 무조건 초기화하지 않는다. 각 Activity의 Interruption Policy가 진행도 유지·부분 유지·초기화·실패를 결정한다.

## 15. Atomic Completion

Activity가 필요 시간을 충족해도 즉시 결과를 적용하지 않는다.

```text
시간·진행도 충족
→ Completion Candidate
→ Domain Provider 최신 검증
→ 필수 선택 완료
→ Completion Plan 조립
→ Ordering Key 획득
→ Authority Transaction
→ Domain Event Outbox
→ Activity completed
```

```text
DowntimeCompletionPlan
├─ completionPlanId
├─ activityInstanceId
├─ providerId와 version
├─ readSet[]
├─ writeSet[]
├─ preconditions[]
├─ mutationProposals[]
├─ reservationSettlementPlan
├─ progressSettlementPlan
├─ migrationPlanRef?
├─ outputProjectionSummary
├─ validationSnapshot
└─ state
```

Downtime Runtime은 `mutationProposals`를 임의로 작성하지 않는다. 각 Domain Provider가 자신의 규칙과 Store에 대한 Proposal을 제공한다.

## 16. 휴식

Short Rest와 Long Rest는 `RestSession`과 `RecoveryPlan`을 사용한다.

```text
DowntimeActivity
→ RestSession 생성·연결
→ Game Time Advance
→ Activity Ledger와 Interruption 평가
→ Recovery Completion Candidate
→ RecoveryPlan 선택·검증
→ RecoveryCommitGroup
```

Downtime Runtime이 HP, Hit Dice, 주문 슬롯과 상태를 직접 회복하지 않는다.

파티가 함께 쉬어도 참가자별 합류 시점, 허용 활동, 중단과 완료 결과를 별도로 유지한다.

## 17. 레벨업과 Character 변경

레벨업은 Live Build를 제자리 수정하지 않는다.

```text
Level Up Activity
→ Progression Change Proposal
→ 필수 Class·Subclass·Feat·Spell 선택
→ 새 CharacterProgressionSource Revision 후보
→ Candidate Character Build Compile
→ Old State + New Build Migration Plan
→ Player·DM 검토
→ Atomic Source·Build Ref·State 교체
```

기본 정책에서 레벨업 자체의 Campaign Time 비용은 `none`일 수 있다. Campaign 설정이 훈련·휴식·장소를 요구하면 Activity Definition이 시간과 자격을 추가한다.

다음을 금지한다.

- 현재 Build Table 직접 수정
- Compile 실패 후 Source 일부만 저장
- 새 최대 Resource 적용 후 현재 State를 나중에 보정
- 사라진 Pending Capability를 검토 없이 유지

## 18. 주문 준비 변경

주문 준비는 주문 획득과 구분한다.

```text
Spell Preparation Activity
→ 적격 SpellcastingProfile과 후보 조회
→ 새 Preparation Set 선택
→ Readiness·Route 검증
→ Persistent spellPreparationState 변경 Proposal
→ Capability·Projection Cache 무효화
→ Atomic Commit
```

준비 변경만으로 Character Progression Source를 수정하지 않는다.

규칙이 긴 휴식 종료 등 특정 Boundary에서만 준비 변경을 허용하면 해당 Rest Completion Candidate에 결합한다.

## 19. 주문책 작업

```text
Spellbook Work Activity
→ Source Spell·Repository·도구·비용 검증
→ 시간·재료 Reservation
→ 진행도 Checkpoint
→ 중단·재개 정책
→ Repository Entry Completion Plan
→ 비용 소비와 Entry 생성 Atomic Commit
```

주문 Definition 전체를 주문책에 복사하지 않는다. Spell ID, 출처, 획득 기록과 필요한 Repository State만 저장한다.

## 20. 제작

```text
Crafting Activity
├─ Craft Recipe Build
├─ 제작자·지원자
├─ 도구·시설
├─ 입력 Item·Resource Reservation
├─ 필요 시간과 Progress
├─ Checkpoint·Quality Choice
├─ Interruption Policy
└─ Output Provider
```

완료 흐름:

```text
입력 예약
→ 시간·진행도 축적
→ Completion 검증
→ 입력 소비
→ Output ItemInstance 생성
→ Container 또는 Ground Presence 배치
→ 한 Transaction으로 Commit
```

완성품 생성 전에 입력만 사라지는 부분 성공을 허용하지 않는다.

부분 제작물이나 진행도 보존이 필요한 Recipe는 명시적 `work_in_progress` Item 또는 Progress Record를 사용한다.

## 21. 훈련

훈련은 Capability를 즉시 직접 주입하지 않는다.

```text
Training Activity
→ 자격·교관·시설·비용 검증
→ 시간·Milestone Progress
→ 완료 조건과 DM 승인
→ Progression Change 또는 Exceptional Grant Proposal
→ Character Compiler·Migration
→ Atomic Activation
```

캠페인 규칙이 훈련으로 단순 Progress Marker만 제공한다면 Character Source를 변경하지 않고 Training Domain Record만 갱신할 수 있다.

## 22. 여행 정산

Travel Resolution은 Scene Navigation Path를 장시간 자동 재생하는 시스템이 아니다.

```text
Travel Plan
├─ 출발·목적지
├─ Route Definition
├─ 참가자·운송 수단
├─ 예상 시간
├─ 소모품·피로 Policy
├─ Watch·Activity Assignment
├─ 중간 사건 Checkpoint
└─ Arrival Plan
```

흐름:

```text
Travel Activity 시작
→ 참가자 활동 배정
→ 다음 사건·구간까지 Time Advance
→ 소모품·상태·환경 결과 해결
→ Encounter 또는 선택 발생 시 중단
→ 최종 도착 검증
→ 필요 시 Scene Transition
```

Travel Runtime이 Runtime Navigation의 세부 경로와 Actor Transform을 프레임별로 조작하지 않는다.

## 23. 취소·중단·실패

Cancellation·Interruption Policy는 다음을 정의한다.

```text
progress_retained
progress_partially_retained
progress_reset
inputs_released
inputs_partially_consumed
inputs_forfeited
output_partial_record
requires_dm_resolution
```

공통 원칙:

- Commit되지 않은 최종 Output을 생성하지 않는다.
- 이미 확정된 중간 Domain Event를 조용히 되돌리지 않는다.
- 취소 시 장기 Reservation을 결정적으로 정리한다.
- 실패 사유와 반환·소비 근거를 Player와 DM Projection에 제공한다.

## 24. 역할과 권한

### PLAYER_ONLY

- 자신이 제어하는 Character의 Activity 제안
- 자신의 선택, 비용 승인과 취소 요청
- 준비 주문·Hit Dice·레벨업 선택·제작 항목 선택
- 공개된 진행도와 예상 결과 확인

### DM_ONLY

- DowntimeSession 시작·종료와 Scope 확정
- 숨은 사건·비용·자격과 중단 판정
- 미응답 참가자 Fallback
- 강제 시간 진행·중단·재개
- Activity Override·Migration 승인·실패 복구
- 비공개 Training·Travel·Crafting 정보 확인

### OBSERVER

- 공개 정책이 허용하는 시간 진행과 참가자 상태만 확인
- 선택·비용·비밀 Activity 세부 정보 수정 불가

### SYSTEM_ONLY

- Activity Registry·Eligibility 평가
- 동시 활동 Window와 Checkpoint 계산
- Reservation·Progress·TimeAdvance 조정
- Completion Plan 수집과 Transaction 제출
- Snapshot·Projection·Domain Event 생성

DM이 Character를 일반 Controller로 조작할 때는 Player Command 경로를 사용하고, 규칙을 무시하는 경우에만 감사되는 Override Command를 사용한다.

## 25. Event 계약

예시 Domain Event:

```text
downtime.session_started
downtime.activity_started
downtime.activity_suspended
downtime.progress_advanced
downtime.checkpoint_reached
downtime.activity_completed
downtime.activity_cancelled
rest.completion_candidate_created
character.build_migration_completed
spell.preparation_changed
spellbook.entry_added
item.crafting_completed
travel.segment_completed
travel.arrived
```

Domain Event는 Commit된 사실이다. Subscriber가 Store를 직접 수정하지 않고 새 Command 또는 RuleExecution을 제출한다.

## 26. Projection과 UI 경계

```text
DowntimeSession Snapshot
+ Role·Ownership·Disclosure
→ DowntimeProjection
→ Activity Planner·Progress View·Choice UI
```

Player Projection:

- 자신의 활동·시간·진행도·예약 요약
- 공개된 파티 활동 상태
- 허용된 선택과 예상 결과
- 중단·실패 이유

DM Projection:

- 전체 Activity Graph와 숨은 Checkpoint
- Eligibility·Reservation·Migration 진단
- Override·Fallback·강제 진행 도구
- 비공개 비용·사건·결과

UI가 Progress, Resource, Character Build와 Item State를 직접 수정하지 않는다.

## 27. 저장·복구·Rollback

Snapshot 저장 대상:

```text
DowntimeSession과 Activity Instance
Participant Assignment
Activity Dependency Graph
Current Downtime Window
Progress Ledger
TimeAdvancePlan과 Checkpoint Cursor
Domain Reservation
Pending Choice·Approval
Completion Candidate·Plan Reference
Candidate Build·Migration Reference
Travel·Rest·Crafting 하위 Session Reference
```

복구:

```text
Snapshot 복원
→ AuthorityEpoch 검증
→ Reservation 재연결
→ 현재 Campaign Time과 Scheduler 재검증
→ Activity Eligibility 재평가
→ Pending Choice 재Projection
→ 안전 상태에서 재개
```

Rollback은 선택 Branch의 Campaign Time, Downtime State, Character·Inventory·Effect·Reservation과 Completion Commit을 함께 복원한다. 이전 AuthorityEpoch의 응답과 Scheduler Due 신호를 새 Branch에 적용하지 않는다.

## 28. 확장 등록점

새 Activity는 Core 분기문에 추가하지 않는다.

```text
DowntimeActivityRegistry
├─ activityKind
├─ definitionSchema
├─ compilerId와 version
├─ eligibilityProviderId
├─ progressProviderId
├─ interruptionProviderId
├─ completionProviderId
├─ migrationAdapter?
└─ diagnosticsProfile
```

등록된 Definition과 검증된 Provider만 사용할 수 있다. 저장된 임의 Luau Callback 실행은 금지한다.

## 29. 실패 정책

- Activity Build Compile 실패: Activity 시작 금지, 기존 Session 유지
- Eligibility 변경: 안전 Checkpoint에서 suspend·invalidate·DM review
- Reservation 유실: Completion 차단, 복구 또는 명시적 취소
- Time Advance 실패: Campaign Time과 Progress 모두 이전 Commit 유지
- Domain Completion 검증 실패: Output 미생성, Reservation 유지 또는 Policy에 따라 해제
- Character Migration 실패: 기존 Source·Build·State 유지
- Projection 실패: 권위 Downtime 진행 유지, Client 재동기화
- Subscriber 실패: Gameplay Completion 유지, Retry·Dead Letter로 격리

## 30. 금지 사항

- 현실 시간 경과로 Downtime 자동 완료
- 참가자별 독립 Campaign Clock 생성
- 휴식 버튼 클릭 즉시 전체 자원 회복
- 레벨업 중 Live Character Build 제자리 수정
- 제작 입력을 먼저 삭제하고 Output을 나중에 생성
- 장시간 Ordering Lock 유지
- Downtime UI가 직접 Character·Item·Resource Store 수정
- Encounter 중 적대 상황을 무시하고 일반 Downtime 강제 시작
- 중간 Scheduler Event를 건너뛰는 대규모 시간 점프
- Activity Handler가 다른 Domain Store를 직접 수정

## 31. 완료 기준

- Short·Long Rest가 RestSession과 RecoveryPlan을 통해 완료된다.
- 레벨업이 Candidate Build와 State Migration으로 원자 적용된다.
- 주문 준비·주문책 작업이 Spell Domain 권위를 따른다.
- 제작 입력 소비와 Output 생성이 하나의 Transaction이다.
- 훈련 결과가 Progression Proposal 또는 타입 있는 Progress Record가 된다.
- 여행 시간 진행이 중간 사건에서 멈추고 재개될 수 있다.
- 여러 참가자의 활동이 하나의 Campaign Time Window에 병렬 배치된다.
- 재접속·서버 복구·Rollback 후 활동·선택·예약이 결정적으로 복원된다.

## 32. Guide 상태

```text
Guide Status: NOT_READY
```

Downtime Main System Guide는 Rest·Spellbook·Crafting·Travel 세부 계약과 구현 Specs 및 Completion Audit가 완료된 뒤 작성한다.
