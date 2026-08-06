# Encounter Timeline, Turn, Opportunity와 Objective Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Initiative Timeline의 단일 Encounter Entry 상한
  - 플레이어 턴 Reminder·Timeout과 DM 강제 진행 기본 시간
  - 동률 선택 Prompt의 기본 Timeout과 Fallback
  - 한 Boundary에서 처리할 환경·Objective Entry 수와 연쇄 깊이
  - 부분 라운드 종료 시 Campaign Game Time 반영 기본 정책
  - 비참가자의 동일 Scene 활동 허용 기본값
  - 종료 후보 자동 제안과 DM 확인 기본 정책
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0025`](../decisions/ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0026`](../decisions/ADR-0026-active-capabilities-action-containers-and-unit-replacements.md)
  - [`ADR-0034`](../decisions/ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0048`](../decisions/ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0069`](../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0076`](../decisions/ADR-0076-real-time-exploration-with-actor-scoped-execution-and-atomic-encounter-transition.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0078`](../decisions/ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md)
  - [`ADR-0079`](../decisions/ADR-0079-policy-driven-encounter-timelines-and-opportunity-gated-turns.md)
- 상위 문서:
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Exploration Runtime 계약`](exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md)
  - [`Character Action Runtime 계약`](character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - [`Rule Runtime Orchestrator 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Game Time Runtime 계약`](game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - [`Domain Event Runtime 계약`](domain-event-outbox-subscription-and-projection-runtime-contract.md)
- 관련 시스템:
  - [`Combat 시스템`](../systems/combat/README.md)
  - [`초기 Encounter·Initiative·Turn 모델`](../systems/combat/encounter-initiative-turn-and-control-authority-model.md)
  - [`Encounter Turn Snapshot과 DM Rollback 모델`](../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md)

## 1. 목적

이 문서는 턴과 순서가 필요한 장면을 공통으로 관리하는 서버 권위 `Encounter Runtime`을 정의한다.

Encounter는 Combat와 동의어가 아니다.

```text
Encounter
├─ combat
├─ chase
├─ hazard
├─ escape
├─ timed_objective
├─ negotiation_sequence
├─ puzzle_sequence
└─ custom_registered
```

Encounter는 공격, 주문, 이동, 아이템과 상호작용을 새로 구현하지 않는다. 기존 Runtime 위에 다음 규칙 문맥만 추가한다.

```text
Participant와 Faction
+ Initiative Timeline
+ Round·Turn Boundary
+ Action Opportunity와 Movement Budget
+ Objective와 종료 정책
+ Join·Leave·Control Policy
```

핵심 원칙:

```text
Encounter는 행동을 제공하지 않는다.
Encounter는 현재 행동을 사용할 기회와 순서를 제공한다.
```

## 2. 사용자 결과

이 계약은 다음 플레이 경험을 보장하기 위해 존재한다.

- 탐험 중인 Scene과 Actor 상태를 복제하지 않고 Encounter를 시작한다.
- 이니셔티브 주사위 결과가 공개되기 전에는 임시 순서를 권위 상태로 사용하지 않는다.
- 전투, 추격, 붕괴 탈출과 제한 시간 목표가 같은 Turn·Objective 기반을 사용할 수 있다.
- 공격, 주문, 문 열기와 아이템 줍기는 기존 Capability를 그대로 사용하되 현재 Opportunity와 비용만 적용한다.
- 반응과 준비 행동은 가짜 Turn을 만들지 않고 원래 RuleExecution에 연결된다.
- 소환체, 환경 사건, Lair Action과 중도 합류를 현재 순서에 안전하게 삽입할 수 있다.
- 플레이어 연결 종료나 DM 개입이 Actor Ownership과 Information Visibility를 바꾸지 않는다.
- Encounter 종료 시 HP, 위치, 바닥 아이템과 지속 효과를 전투 전 상태로 되돌리지 않는다.
- 플레이테스트에서 Initiative·Turn·Objective 방식을 바꿔도 Encounter Core를 다시 작성하지 않는다.

## 3. 책임 경계

### 3.1 Encounter Runtime이 소유한다

- EncounterSession Identity와 수명주기
- Participant·Faction·Objective Binding
- Initiative Policy 실행과 Timeline 확정
- Round·Turn·Entry Boundary 진행
- 현재 Entry와 Turn Cursor
- Encounter 범위 Opportunity와 Movement Budget Binding
- Join·Leave·Reorder·Control Assignment 조정
- End Candidate와 Encounter 종료 Transaction 조정
- Encounter Snapshot, Projection, 복구와 Rollback 연결
- Campaign Game Time에 반영할 Round Advance Proposal

### 3.2 Encounter Runtime이 소유하지 않는다

- 공격·주문·아이템·상호작용의 구체 규칙
- Character Capability와 Action Definition
- Reaction·Interrupt의 내부 해결 Graph
- Actor 위치, HP, Inventory와 Effect 권위 상태
- Navigation Path 계산과 이동 실행
- Dice 난수와 Roll Resolution
- Camera, VFX와 UI Animation
- Campaign Calendar와 현실 Timeout 시계

### 3.3 하위 Runtime과의 관계

```text
Encounter
→ 지금 누가 어떤 Opportunity를 사용할 수 있는지 확정

Character Action·Spell·Interaction·Inventory
→ 실제 사용할 수 있는 Capability 제공

Rule Runtime
→ 선언된 Capability의 Reaction·Roll·Effect 해결

Transaction Coordinator
→ 상태와 Encounter 결과 원자적 Commit
```

## 4. Policy 기반 구조

Encounter Core에 D&D 2024의 수치를 하드코딩하지 않는다.

```text
EncounterPolicySet
├─ initiativePolicyRef
├─ timelinePolicyRef
├─ turnPolicyRef
├─ opportunityPolicyRef
├─ movementPolicyRef
├─ objectivePolicyRef
├─ joinLeavePolicyRef
├─ timeoutPolicyRef
├─ controlPolicyRef
├─ nonParticipantPolicyRef
├─ timeAdvancePolicyRef
├─ endPolicyRef
└─ projectionPolicyRef
```

Policy는 검증된 Registry 항목이며 Version과 Migration 계약을 가진다.

진행 중 Encounter는 시작 당시의 `EncounterPolicySetVersion`을 고정한다. 새 Policy를 활성화해도 기존 Encounter에 조용히 섞지 않는다.

활성 Encounter의 Policy를 바꿔야 하면 다음 중 하나를 사용한다.

```text
Encounter 종료 후 새 Policy로 재시작
명시적 Migration Plan 적용
DM Override로 특정 값만 수정하고 감사 기록
```

## 5. D&D 2024 기본 Policy Pack

초기 기본값:

```text
ruleset: dnd5e-2024
initiative: d20 + Dexterity modifier
round duration: 6 game seconds
individual turn duration: Campaign Time 추가 없음
action economy: Action + 조건부 Bonus Action + Reaction + Movement
Delay: 지원하지 않음
Ready: Action과 Reaction 계약으로 지원
end confirmation: DM 확인 기본
```

`1 Round = 약 6초`는 D&D 2024 Policy의 기본값이다. 참가자 수만큼 6초를 더하지 않는다.

## 6. EncounterSession

```text
EncounterSessionState
├─ encounterId
├─ authorityEpoch
├─ encounterKind
├─ lifecycleState
├─ sceneScope
├─ policySetRef와 version
├─ rulesetSnapshotRef
├─ participantBindings[]
├─ factionBindings[]
├─ initiativeSetupState?
├─ timelineState?
├─ activeTurnState?
├─ objectiveState
├─ nonParticipantBindings[]
├─ controlAssignmentRefs[]
├─ openExecutionRefs[]
├─ endCandidate?
├─ roundTimeLedger
├─ snapshotCursor
├─ auditMetadata
└─ revision
```

EncounterSession은 Scene, Actor, Character, Item과 Effect 상태를 복사하지 않는다. Stable Reference와 Revision만 가진다.

## 7. Encounter 수명주기

```text
proposed
→ preparing
→ rolling_initiative | building_timeline
→ awaiting_reveal_or_choices
→ activating
→ active
→ ending
→ ended
```

실패 상태:

```text
cancelled
failed_to_start
recovery_required
```

`paused`는 Encounter lifecycleState가 아니다.

```text
Encounter active
+ Pause Overlay
```

구조를 사용한다. Pause가 열린 RuleExecution, Reaction Offer, Resource Reservation과 현재 Turn을 임의 취소하지 않는다.

### 7.1 proposed

DM 또는 규칙 Trigger가 참가자·진영·목표 후보를 제출한다.

### 7.2 preparing

참가자, 인식 상태, Control Assignment, Policy와 비참가자 정책을 확정한다.

### 7.3 rolling_initiative / building_timeline

Policy에 따라 Roll 또는 고정·그룹·Side Initiative Entry를 만든다.

### 7.4 awaiting_reveal_or_choices

주사위 공개, 동률 선택, 참가자 확인 등 필요한 입력을 기다린다.

### 7.5 activating

Timeline과 첫 Cursor를 Commit하고 Exploration에서 진행 중인 실행을 전환 정책에 따라 정리한다.

### 7.6 active

Turn·Round·Objective와 Entry를 진행한다.

### 7.7 ending

열린 RuleExecution, Reaction, Objective 결과와 시간 진행을 안전 경계에서 정리한다.

### 7.8 ended

Encounter 전용 Binding을 Archive하고 Session Base Mode를 Exploration 또는 명시된 다음 Mode로 전환한다.

## 8. Participant와 Faction

```text
EncounterParticipantBinding
├─ participantId
├─ actorRef
├─ factionRef
├─ participantState
├─ awarenessState
├─ initiativeParticipationPolicy
├─ turnParticipationPolicy
├─ controlAssignmentRef
├─ disclosurePolicyRef
├─ joinedAtTimelineRevision?
├─ leftAtTimelineRevision?
└─ revision
```

`participantState`:

```text
pending
active
incapacitated
defeated
withdrawn
escaped
surrendered
removed
hidden_reserve
```

HP 0, 의식불명, 사망과 Participant 제거를 동일시하지 않는다.

```text
FactionBinding
├─ factionId
├─ relationshipBindings[]
├─ sharedInitiativePolicy?
├─ sharedObjectivePolicy?
├─ sharedDisclosurePolicy?
└─ revision
```

관계는 단순 ally/enemy Boolean이 아니다.

```text
friendly
neutral
hostile
unknown
conditionally_hostile
```

## 9. Initiative는 Timeline 구축 정책이다

Initiative를 단순 숫자 목록이나 FIFO Queue로 정의하지 않는다.

```text
Initiative Inputs
→ InitiativePolicy
→ TimelineEntry Drafts
→ Reveal·Tie Resolution
→ Immutable Timeline Revision Commit
```

지원 정책 예시:

```text
individual_roll
shared_by_definition
shared_by_control_group
side_initiative
fixed_order
follow_owner_entry
simultaneous_band
custom_registered
```

Initiative Roll은 표준 Dice Runtime을 사용한다.

```text
Participant Snapshot
→ RollPlan
→ SealedRollResult
→ Presentation Reveal
→ RollRecord
→ Tie Policy
→ Timeline Revision Commit
```

필수 Roll이 공개되기 전에 임시 순서를 권위 Turn에 사용하지 않는다.

## 10. Initiative Timeline

```text
InitiativeTimelineState
├─ timelineId
├─ encounterId
├─ timelineRevision
├─ roundNumber
├─ entries[]
├─ activeCursor
├─ completedOccurrenceIds[]
├─ pendingInsertionRequests[]
├─ pendingReorderRequests[]
└─ revision
```

Timeline Entry 종류:

```text
actor_turn
actor_group_turn
environment_turn
lair_action
hazard_step
objective_checkpoint
scripted_event
custom_registered
```

```text
TimelineEntry
├─ entryId
├─ entryKind
├─ participantRefs[]
├─ orderKey
├─ initiativeEvidenceRefs[]
├─ turnPolicyRef
├─ opportunityProfileRef
├─ visibilityPolicyRef
├─ recurrencePolicy
├─ activationPredicate?
├─ controllerSummary
└─ revision
```

UI는 Initiative Bar처럼 목록으로 보여도 내부 계약은 Timeline이다.

지원 연산:

```text
insert
remove
archive
reorder
replace
attach_to_owner
activate_reserve
```

이미 완료된 Entry Occurrence의 역사 순서를 다시 쓰지 않는다. 변경은 새 `timelineRevision`부터 적용한다.

## 11. Timeline Cursor와 Occurrence

Entry Definition과 실제 실행 발생을 구분한다.

```text
TimelineEntry
→ 반복 가능한 정의

TimelineOccurrence
→ 특정 Round에서 실제로 시작된 발생
```

```text
TimelineOccurrence
├─ occurrenceId
├─ entryId
├─ roundNumber
├─ timelineRevision
├─ startedAtAuthorityRevision
├─ completedAtAuthorityRevision?
├─ outcome
└─ revision
```

`activeCursor`는 Entry Index가 아니라 현재 Occurrence Reference를 가리킨다. 삽입·재정렬 후에도 안정적인 Identity를 유지한다.

## 12. Round 경계

Round는 모든 활성 Entry가 한 번씩 완료됐는지만 세는 UI 숫자가 아니다.

```text
Round Start Boundary
→ Entry Occurrence 진행
→ Round End Candidate
→ 종료 전 RuleEvent와 Objective 평가
→ Round End Commit
→ Campaign Time Advance Proposal
→ 다음 Round Start
```

D&D 2024 기본 Policy:

```text
Round End Commit
→ Campaign Game Time +6 seconds
```

개별 Turn 종료는 Campaign Time에 6초를 추가하지 않는다.

Turn·Round Boundary를 고정 시간 Deadline으로 변환하지 않는다.

```text
다음 자기 Turn 시작까지
→ 해당 Actor의 다음 turn_start occurrence

1분
→ Campaign Deadline 또는 10 Round 정책
```

## 13. Turn State Machine

```text
preparing
→ starting
→ awaiting_controller
→ acting
↔ waiting_execution
→ ending
→ completed
```

```text
ActiveTurnState
├─ turnId
├─ occurrenceId
├─ entryId
├─ roundNumber
├─ actingParticipantRefs[]
├─ phase
├─ opportunityLedgerRefs[]
├─ movementBudgetRefs[]
├─ turnScopedUsageRefs[]
├─ openExecutionRefs[]
├─ controllerDeadline?
├─ endRequest?
└─ revision
```

### starting

Turn Start RuleEvent, Effect Boundary, Recharge, Death Save와 Turn-scoped Reset을 Rule Runtime을 통해 처리한다.

### awaiting_controller

Control Assignment에 따라 플레이어·DM·위임 Controller 또는 자동화의 입력을 기다린다.

### acting

현재 Opportunity로 Capability Command를 제출할 수 있다.

### waiting_execution

열린 RuleExecution, Selection, DM Adjudication 또는 Reaction 해결을 기다린다. Encounter가 내부 Recipe를 직접 실행하지 않는다.

### ending

미해결 실행과 Turn End TimingWindow를 재검증한다.

### completed

Occurrence를 완료하고 Timeline Cursor를 다음 적격 Entry로 이동한다.

## 14. Encounter는 행동을 제공하지 않는다

사용 가능한 행동은 다음 Runtime이 제공한다.

```text
Character Action Runtime
Spell Runtime
Interaction Runtime
Inventory Runtime
Effect·Feature Capability
```

Encounter는 다음 문맥만 제공한다.

```text
현재 Turn인가
어떤 Opportunity가 남았는가
Movement Budget이 얼마인가
Reaction을 사용할 수 있는가
Turn·Round Usage Gate를 통과했는가
Objective Policy가 추가 제한을 제공하는가
```

UI의 Action 버튼은 Capability Projection이며 Encounter의 고정 버튼 목록이 아니다.

## 15. Opportunity Ledger

```text
EncounterOpportunityLedger
├─ ledgerId
├─ actorRef
├─ turnId?
├─ encounterId
├─ opportunities[]
├─ sharedResourceBindings[]
└─ revision
```

기본 Opportunity 종류:

```text
action
bonus_action
reaction
special_action
no_action_required
movement_budget
object_interaction
custom_registered
```

```text
OpportunityState
├─ opportunityId
├─ kind
├─ sourceRef
├─ eligibilityPredicateRef
├─ lifecycleState
├─ reservedByExecutionId?
├─ consumedByExecutionId?
├─ releasePolicy
└─ revision
```

상태:

```text
available
→ reserved
→ consumed | released | expired
```

Encounter는 Opportunity를 생성·만료하지만 실제 Capability가 어떤 Opportunity를 요구하는지는 Action Runtime이 선언한다.

## 16. Movement Budget

전투 중 토큰 WASD 직접 이동은 금지한다.

```text
Movement Intent
→ Path Preview
→ Movement Budget 검증
→ MovementExecution
→ Trigger Boundary에서 정지
→ Reaction·RuleExecution 해결
→ 재개 또는 종료
```

Movement Budget은 Opportunity Ledger의 전문 자원이며 Runtime Navigation이 실제 경로와 비용을 계산한다.

Dash, Difficult Terrain, Speed 변화와 특수 이동은 Character·Effect·Navigation Contribution으로 계산한다.

## 17. Reaction과 Interrupt

Encounter는 별도 Reaction Stack이나 Interrupt Stack을 구현하지 않는다.

```text
현재 Turn
→ RuleExecution
→ RuleEvent
→ TimingWindow
→ Child RuleExecution Graph
→ 원래 실행 재개
```

Encounter는 다음만 추적한다.

- 어느 Turn·Occurrence에서 실행이 열렸는가
- 어떤 Reaction Opportunity가 예약·소비됐는가
- Turn 종료가 가능한가
- 열린 Root·Child Execution Reference가 무엇인가

Counterspell에 대한 Counterspell처럼 중첩된 실행은 Rule Runtime의 Parent·Child Graph와 실행 Budget을 따른다.

## 18. Ready와 Delay

D&D 2024 기본 Policy에서는 `Delay`를 제공하지 않는다.

Ready는 표준 Action Capability다.

```text
Action Opportunity 소비
→ Trigger와 준비 행동 저장
→ 적격 RuleEvent 발생
→ Reaction Offer
→ prepared_action_release Child Execution
```

준비한 주문, 이동 또는 행동의 세부 비용·집중·만료는 Character Action·Spell·Effect Runtime이 소유한다.

## 19. Objective

```text
EncounterObjectiveState
├─ objectiveSetId
├─ objectiveDefinitions[]
├─ progressStates[]
├─ successCandidate?
├─ failureCandidate?
├─ neutralEndCandidate?
└─ revision
```

Objective 종류는 고정 Enum 하나로 제한하지 않는다.

초기 Profile 예시:

```text
defeat_or_disable
escape_region
reach_destination
protect_target
escort_target
survive_rounds
hold_region
complete_interaction
prevent_event
negotiation_sequence
custom_registered
```

Objective는 Domain Event와 최신 Snapshot에서 진행도를 계산한다. Subscriber가 상태를 직접 수정하지 않고 새 Objective Evaluation Command 또는 RuleExecution을 생성한다.

Objective 달성 후보가 생겨도 기본적으로 Encounter를 즉시 종료하지 않는다.

```text
Objective Candidate
→ End Policy 평가
→ DM 확인 또는 자동 확정
→ Encounter ending
```

## 20. 비참가자와 동일 Scene

Encounter에 참여하지 않은 Actor와 플레이어를 전부 자동 정지하지 않는다.

```text
NonParticipantPolicy
├─ observe_only
├─ continue_limited_exploration
├─ join_candidate
├─ region_blocked
├─ dm_controlled
└─ custom_registered
```

비참가자가 Encounter 참가자의 결과에 영향을 주는 Command를 제출하면 Join Policy 또는 명시적 외부 개입 정책을 통과해야 한다.

## 21. 중도 합류와 Timeline 삽입

```text
JoinEncounterProposal
→ Actor·인지·진영·Control 검증
→ Initiative Policy 적용
→ Timeline Insertion Plan
→ Transaction Commit
→ Participant 활성화
```

삽입 정책:

```text
roll_and_insert
fixed_after_current
fixed_before_next_round
join_existing_group
follow_owner_entry
reserve_until_trigger
custom_registered
```

현재 RuleExecution 중간에 Timeline을 재정렬하지 않는다. Commit 가능한 안전 Boundary에서 새 `timelineRevision`을 활성화한다.

## 22. 이탈과 제거

이탈은 Actor 삭제가 아니다.

```text
withdrawn
escaped
surrendered
defeated
removed_by_dm
scene_transitioned
```

현재 Entry가 이탈 Actor만 포함한다면 Turn End Policy가 남은 실행을 정리하고 다음 Entry로 진행한다.

소환체나 생성 Object의 삭제는 Runtime Object Lifecycle이 담당한다.

## 23. Control Assignment

```text
ActorOwnership
≠ ControlAssignment
≠ InformationVisibility
```

```text
EncounterControlAssignment
├─ assignmentId
├─ actorRef
├─ controllerKind
├─ controllerUserId?
├─ controllerGroupId?
├─ scope
├─ allowedCommandKinds[]
├─ activationBoundary
├─ expirationBoundary
├─ fallbackController
└─ revision
```

`controllerKind`:

```text
player
DM
delegated_player
server_automation
shared_prompt
uncontrolled
```

DM이 NPC를 플레이어에게 위임해도 Ownership과 비밀 정보 접근 권한은 자동 이전되지 않는다.

자동화도 일반 Intent→Command→RuleExecution 흐름을 사용한다.

## 24. 연결 종료와 Timeout

현실 응답 시간은 Campaign Game Time이 아니라 Authority Monotonic Time을 사용한다.

```text
Controller Disconnect
→ Reconnect Grace
→ Reminder
→ Timeout Policy
→ DM Takeover | Auto Policy | Skip Candidate | Continue Waiting
```

Turn Timeout이 발생해도 자동으로 Campaign Game Time을 추가하지 않는다.

플레이어 Turn을 무조건 Auto Pass하는 기본값을 엔진에 하드코딩하지 않는다.

## 25. Pause와 DM Override

Pause는 Session Overlay이며 Encounter 상태가 아니다.

DM 전용 Command:

```text
pause_or_resume
skip_entry
force_end_turn
insert_participant
remove_participant
reorder_timeline
change_faction
delegate_control
force_opportunity_state
propose_end
commit_end
rollback
recover
```

Override는 일반 Store Mutation을 직접 수행하지 않고 Command·Transaction·Domain Event·Audit 경계를 통과한다.

## 26. 종료

종료 후보:

```text
Objective 성공·실패
적대 세력 무력화
도주·항복
시간 제한 종료
Scene 전환
DM 수동 종료
규칙 정의 종료 사건
```

```text
End Candidate
→ 신규 관련 Command Gate
→ 열린 RuleExecution·Reaction 정리
→ Turn·Round Boundary 정책 평가
→ Campaign Time Advance 확정
→ Encounter 전용 Effect·Opportunity 정리
→ EncounterEndTransaction
→ Domain Event와 Snapshot
→ Exploration 또는 지정 Mode 전환
```

Encounter 종료는 다음을 초기화하지 않는다.

- Actor 위치와 HP
- 시체와 바닥 Item
- Encounter 종료 후에도 유지되는 Effect
- 문·상자·함정의 변경 상태
- 이미 발견된 Knowledge

## 27. Event 계약

대표 Domain Event:

```text
encounter.proposed
encounter.started
encounter.timeline_committed
encounter.round_started
encounter.turn_started
encounter.turn_ended
encounter.participant_joined
encounter.participant_left
encounter.objective_updated
encounter.end_candidate_created
encounter.ended
```

`turn_start`, `turn_end`와 같은 규칙 개입 지점은 Rule Event다. Commit 이후 외부 전달용 Domain Event와 혼합하지 않는다.

## 28. Transaction과 동시성

대표 Ordering Key:

```text
encounter:{encounterId}
actor:{actorId}
rule_execution:{executionId}
control_assignment:{actorId}
```

Timeline 변경, Turn 이동, Participant 합류와 Opportunity 소비는 최신 Encounter Revision을 재검증한다.

늦게 도착한 Command는 다음 구조화 오류를 반환할 수 있다.

```text
STALE_ENCOUNTER_REVISION
STALE_TIMELINE_REVISION
STALE_TURN_ID
NOT_ACTIVE_CONTROLLER
OPPORTUNITY_NOT_AVAILABLE
ENCOUNTER_TRANSITION_IN_PROGRESS
```

## 29. Projection과 역할

### PLAYER_ONLY

- 자신이 제어하는 Actor의 Turn Command 제출
- 공개된 Timeline, Objective와 Opportunity 확인
- Reaction·Ready·Action 선택
- 허용된 Turn End 요청

### DM_ONLY

- Encounter 생성·취소·종료
- Participant·Faction·Timeline 수정
- 비밀 Entry와 Hidden Reserve 관리
- Control 위임과 강제 회수
- Timeout·Override·Rollback·Recovery
- 비공개 Objective와 Trigger 확인

### OBSERVER

- 할당된 Disclosure Policy에 맞는 Encounter Projection 열람
- Selection과 Inspection은 가능하지만 Command 제출은 불가

### SYSTEM_ONLY

- Initiative Roll과 Timeline Commit
- Round·Turn Boundary 진행
- Opportunity Ledger와 Movement Budget 생성
- Objective Evaluation과 End Candidate
- Snapshot·Projection·Domain Event·Recovery

## 30. 저장·복구·롤백

Snapshot 대상:

```text
EncounterSession State
Policy Set Version
Participant·Faction Binding
Timeline와 active Cursor
Round·Turn State
Opportunity Ledger
Movement Budget
Objective State
Control Assignment
Open RuleExecution References
Round Time Ledger
End Candidate
```

재접속 Client는 Raw Encounter State가 아니라 관찰자별 Projection Snapshot을 받는다.

Rollback Commit은 새 `AuthorityEpoch`를 생성한다. 이전 Epoch의 Timeline Command, Reaction 응답과 Timeout은 무효다.

## 31. 진단과 확장성

Trace에 다음 근거를 남긴다.

- Initiative Policy와 RollRecord
- Timeline 삽입·재정렬 사유
- Turn 시작·종료 Gate
- Opportunity 생성·예약·소비 근거
- Objective 진행도 근거
- Timeout과 DM Override
- End Candidate와 종료 확정 근거

새 Encounter Kind는 Core를 수정하지 않고 다음을 Registry에 등록한다.

```text
Encounter Policy Set
Timeline Entry Type
Objective Profile
Projection Adapter
Migration Adapter
Diagnostics Formatter
```

사용자 임의 Luau 실행은 허용하지 않는다.

## 32. 완료 기준

구현 명세로 내려가기 전에 다음을 만족해야 한다.

- Encounter와 Combat를 동일시하지 않는다.
- Encounter가 Action·Spell·Interaction을 재구현하지 않는다.
- Initiative 결과 공개 전 Turn을 시작하지 않는다.
- Timeline Entry 삽입·재정렬이 안정적 Identity와 Revision을 유지한다.
- Pause가 Encounter lifecycleState로 구현되지 않는다.
- Reaction 중첩은 RuleExecution Graph를 사용한다.
- 1 Round가 기본 6초이고 개별 Turn은 시간을 추가하지 않는다.
- Ready는 지원하고 Delay는 D&D 2024 기본 Policy에서 제외한다.
- DM·Player·Observer·System 권한이 분리된다.
- Join·Leave·Reconnect·Rollback 후에도 Timeline과 Opportunity가 복구된다.
- Policy와 Objective를 교체해도 Encounter Core를 수정하지 않는다.
