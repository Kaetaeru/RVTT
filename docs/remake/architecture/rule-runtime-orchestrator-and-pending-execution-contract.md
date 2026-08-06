# Rule Runtime Orchestrator와 Pending Execution 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 한 RuleExecution에서 허용할 최대 Child Execution 깊이
  - 동시에 열린 TimingWindow·Prompt·Reaction 수
  - 자동 선택 Deadline과 DM 검토 대기 시간
  - Pending Execution Snapshot 주기와 보존 기간
  - 동일 Event에서 후보 Capability를 평가할 최대 수
  - 실행 Trace의 기본 상세 수준과 장기 보존 범위
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0025`](../decisions/ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0028`](../decisions/ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0033`](../decisions/ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0053`](../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
- 관련 문서:
  - [`Rules Content Grant와 Capability 모델`](rules-content-grant-capability-model.md)
  - [`Rules Content 실행과 주문 계약`](rules-content-execution-and-spell-contract.md)
  - [`EffectRecipe와 효과 해결·확정 모델`](effect-recipe-resolution-and-commit-model.md)
  - [`Recipe Step Runtime Foundation`](../specs/shared/001-recipe-step-runtime-foundation.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`저장·세션 복구 모델`](persistence-and-session-recovery-model.md)

## 1. 목적

이 문서는 사용자가 행동을 선언한 시점부터 규칙 결과가 Commit되고 후속 사건이 모두 정리될 때까지 전체 실행을 조정하는 서버 권위 `Rule Runtime Orchestrator`의 책임을 정의한다.

RVTT에는 이미 다음 하위 계약이 존재한다.

- Capability는 무엇을 사용할 수 있는지 설명한다.
- Recipe는 실행할 규칙 절차를 설명한다.
- Step Runtime은 Recipe의 개별 Step을 실행한다.
- Spatial Query는 공간 증거를 계산한다.
- Roll Service는 서버 권위 굴림을 만든다.
- PendingEffect와 CommitGroup은 영구 상태 변경을 준비하고 확정한다.
- TimingWindow는 반응, 선택형 트리거와 규칙 수정의 개입 지점을 제공한다.

하지만 이 요소들을 기능별 코드가 직접 연결하면 공격, 주문, 아이템, 함정과 특성마다 실행 순서와 복구 방식이 달라진다.

따라서 모든 규칙 실행은 다음 하나의 상위 흐름을 사용한다.

```text
Validated Intent
→ RuleExecution 생성
→ Capability와 비용 예약
→ Recipe 실행
→ RuleEvent와 TimingWindow 해결
→ PendingEffect와 CommitGroup 준비
→ 권위 Commit
→ 후속 Event 처리
→ Execution 종료
```

## 2. 사용자 결과

이 계약은 다음을 보장한다.

- 공격, 주문, 특성, 아이템과 함정이 같은 실행·반응·확정 규약을 사용한다.
- 반응 선택 중 연결이 끊겨도 실행이 사라지거나 비용이 두 번 소비되지 않는다.
- `Shield`, 기회 공격, 피해 감소와 명중 후 추가 피해가 정확한 개입 시점에 처리된다.
- VFX나 주사위 Animation이 실패해도 권위 실행은 복구할 수 있다.
- 한 반응이 다시 새로운 반응을 만들더라도 무한 중첩되지 않는다.
- DM은 현재 무엇을 기다리는지, 어떤 비용이 예약됐는지, 왜 실행이 멈췄는지 확인할 수 있다.
- Rollback 이후 이전 Timeline의 Prompt 응답과 비동기 작업이 새 실행에 적용되지 않는다.
- 한 실행의 일부 효과만 확정되고 나머지가 유실되는 상태를 허용하지 않는다.

## 3. 책임 경계

### 3.1 Rule Runtime Orchestrator가 소유한다

- RuleExecution Identity와 상태기계
- 부모·자식 실행 관계
- Capability 사용 검증 절차의 조정
- 비용 예약과 Commit·Release 요청
- Recipe Runtime 시작·중단·재개
- RuleEvent 발행 순서
- TimingWindow Stack과 후보 정렬
- Prompt·Reaction·DM Adjudication 대기
- PendingEffect 수집과 CommitGroup 경계
- 안전 경계, 저장·복구와 종료 정책
- 실행 Trace, 진단과 사용자별 Projection

### 3.2 소유하지 않는다

- Character의 영구 Feature·Spell·Item 데이터
- 구체적인 공격, 주문과 상태 효과 규칙
- Spatial Query의 기하 계산
- Dice 난수 생성
- Runtime Object Lifecycle Mutation
- Network Transport와 Remote 구조
- VFX, Camera와 Token Motion 구현
- DataStore 직렬화 Worker

Orchestrator는 하위 서비스의 공개 계약을 조정하며, 해당 도메인의 규칙을 다시 구현하지 않는다.

## 4. RuleExecution Identity

```text
RuleExecutionRecord
├─ executionId
├─ executionKind
├─ authorityEpoch
├─ executionIncarnation
├─ parentExecutionId?
├─ rootExecutionId
├─ sourceCommandId?
├─ sourceEventOccurrenceId?
├─ sourceActorRef?
├─ capabilityRef
├─ compiledRecipeRef
├─ rulesetVersionSet
├─ sceneSnapshotRef
├─ encounterContextRef?
├─ createdRevision
├─ currentState
├─ currentPhase
├─ bindingStoreRef
├─ reservationSetRef
├─ pendingEffectSetRef
├─ timingWindowStackRef
├─ pendingInputRefs[]
├─ childExecutionRefs[]
├─ executionBudgetState
├─ terminalSummary?
└─ traceRef
```

### 4.1 executionId

한 권위 Timeline에서 하나의 규칙 실행을 식별한다. Client가 생성하지 않는다.

### 4.2 executionIncarnation

저장 복구나 내부 Migration으로 같은 논리 실행을 재구성할 때 오래된 비동기 응답을 차단한다.

### 4.3 rootExecutionId와 parentExecutionId

반응과 후속 실행은 부모 실행과 연결한다.

예:

```text
장검 공격 Root Execution
└─ Shield Reaction Child Execution
   └─ Shield 효과 Recipe
```

모든 Child가 부모와 같은 CommitGroup에 포함되는 것은 아니다. `joinPolicy`가 Commit 경계를 결정한다.

## 5. 실행 종류

초기 `executionKind`:

```text
active_capability
triggered_capability
mandatory_rule_trigger
prepared_action_release
environmental_trigger
system_maintenance
advanced_operation
```

실행 종류는 UI 분류와 기본 정책을 제공하지만, 규칙 의미는 Capability와 Recipe가 소유한다.

## 6. 상태기계

외부 진단과 복구에 사용하는 기본 상태:

```text
created
→ validating
→ reserving
→ running
→ waiting_input | waiting_timing_window | waiting_child | waiting_presentation_gate
→ preparing_commit
→ committing
→ resolving_aftermath
→ completed
```

터미널 실패 상태:

```text
cancelled
rejected
failed_safe
expired
superseded
```

### 6.1 created

Command 또는 RuleEvent에서 실행 후보가 생성되었지만 아직 권위 검증을 마치지 않았다.

### 6.2 validating

다음을 검증한다.

- Capability Grant와 현재 사용 가능성
- 요청자 제어권·권한
- Action Economy와 Timing
- 대상·선택·Scene Context
- Ruleset·Recipe Version
- Usage Gate와 중복 Event 처리
- 필요한 Runtime Object Incarnation과 Revision

### 6.3 reserving

다른 실행과 중복 사용을 막기 위해 비용과 독점 자원을 예약한다.

예:

- 행동, 보너스 행동, 반응
- 주문 슬롯
- Feature 사용 횟수
- 아이템 Charge
- 선택한 탄약 또는 소모품

예약은 소비 확정이 아니다.

### 6.4 running

Compiled Recipe와 Step Runtime을 실행한다. Step은 Continue, Branch, Suspend 또는 Fail을 반환한다.

### 6.5 waiting_input

Guided 선택, DM Adjudication 또는 구조화된 Prompt 응답을 기다린다.

### 6.6 waiting_timing_window

현재 RuleEvent에 반응 가능한 Capability 후보를 평가하고 응답을 기다린다.

### 6.7 waiting_child

부모 실행이 Child Execution의 종료를 기다린다.

### 6.8 waiting_presentation_gate

주사위 공개처럼 제품상 연출 완료 또는 Deadline을 기다리는 제한된 Gate다. 권위 결과 자체를 Client Animation이 결정하지 않는다.

### 6.9 preparing_commit

PendingEffect, 비용, Runtime Object Command와 후속 상태 변경을 CommitGroup으로 조립하고 최신 권위 상태에서 재검증한다.

### 6.10 committing

Transaction이 권위 상태를 원자적으로 변경한다. 이 구간에서는 새 사용자 입력으로 실행 구조를 변경하지 않는다.

### 6.11 resolving_aftermath

Commit 이후 발생한 RuleEvent, HP 0, 집중 검사, 지속 효과 종료와 Trigger를 처리한다.

### 6.12 completed

모든 필수 후속 처리와 비용 정산이 끝난 터미널 성공 상태다.

## 7. Phase와 RuleEvent

상태와 규칙 개입 지점을 구분한다.

초기 `executionPhase`:

```text
declared
costs_reserved
targets_locked
before_roll
roll_produced
outcome_determined
before_effect_commit
effect_committed
after_effect_commit
execution_finished
```

모든 실행이 모든 Phase를 사용하지는 않는다.

Phase 전환은 의미 있는 `RuleEvent`를 생성할 수 있다.

```text
AttackRollProduced
DamageAboutToApply
SpellEffectAboutToCommit
MovementAboutToLeaveReach
```

Event는 발생 사실을 기록하며, Event Handler가 원래 실행을 직접 수정하지 않는다. 개입은 TimingWindow와 등록된 Modifier·Override 계약을 사용한다.

## 8. TimingWindow Stack

### 8.1 TimingWindow

```text
TimingWindowRecord
├─ timingWindowId
├─ rootExecutionId
├─ parentExecutionId
├─ sourceEventOccurrenceId
├─ timingPointId
├─ authorityEpoch
├─ openedRevision
├─ responderSet
├─ candidateOfferRefs[]
├─ orderingPolicy
├─ visibilityPolicy
├─ responsePolicy
├─ deadlinePolicy
├─ currentRound
├─ maxRounds
├─ status
└─ resolutionSummary?
```

### 8.2 후보 평가

```text
RuleEvent
→ Trigger Index 후보 조회
→ Grant·Usage·권한·공개 정보 필터
→ 결정적 정렬
→ 필수 자동 후보와 선택형 후보 분리
→ Offer 생성
```

모든 Feature를 매 Event마다 전체 순회하지 않는다.

### 8.3 중첩 창

반응이 새로운 Event를 만들면 새 TimingWindow가 Stack 위에 열릴 수 있다.

```text
공격 굴림
→ Shield 제안
→ Shield 주문 실행
→ Shield 실행 중 Counterspell 제안 가능
```

중첩은 다음 제한을 가진다.

- 최대 Child Execution 깊이
- 최대 TimingWindow Stack 깊이
- 같은 EventOccurrence에 같은 Trigger의 중복 사용 금지
- Cycle Key 반복 감지
- Root Execution Budget

### 8.4 우선순위

하나의 거대한 숫자 Priority만 사용하지 않는다.

```text
1. 규칙상 필수 자동 처리
2. 현재 사건의 직접 대상 또는 행위자에게 부여된 명시적 선택권
3. 동시에 선언 가능한 다른 응답자
4. DM Override 또는 Adjudication
5. 안정적인 Capability·Actor ID Tie-break
```

구체적인 D&D 동시 처리 정책은 Ruleset Provider가 등록할 수 있다.

### 8.5 Pass와 Deadline

응답자는 `use`, `pass`, `delegate_to_dm` 또는 등록된 선택을 제출한다.

Deadline 종료 시 정책:

```text
pass
use_preference
ask_dm
mandatory_auto_resolve
cancel_parent_if_required
```

사용자 설정이 자원 소비를 자동 승인하도록 허용하려면 명시적 사전 정책이 필요하다.

## 9. Capability Offer

```text
CapabilityOffer
├─ offerId
├─ timingWindowId
├─ capabilityRef
├─ responderRef
├─ publicEventView
├─ availableVariants[]
├─ projectedCosts
├─ usageGateSummary
├─ informationPolicy
├─ expiresAt
├─ defaultResolution
└─ expectedOfferRevision
```

Client에는 응답자가 규칙상 알 수 있는 정보만 제공한다.

Offer 응답은 별도 Command다.

```text
RespondToCapabilityOfferCommand
├─ offerId
├─ selectedVariantId?
├─ responseKind
├─ expectedOfferRevision
└─ idempotencyKey
```

서버는 응답 시 Capability, 비용, 사건과 권한을 다시 검증한다.

## 10. 비용 예약과 정산

```text
available
→ reserved(executionId)
→ committed_spent
```

취소 가능한 단계에서 실행이 종료되면 예약을 반환한다.

다음은 예약만으로 처리하지 않고 규칙 시점에 맞춰 Commit한다.

- 명중 후에만 소비하는 자원
- Trigger를 실제 채택했을 때만 소비하는 반응
- 주문이 무효화되어도 소비되는 슬롯
- 재료가 시전 완료 시 파괴되는 주문

`CostCommitPolicy`가 다음 시점을 명시한다.

```text
on_declaration
on_execution_started
on_roll_revealed
on_effect_commit
on_execution_completed
custom_registered
```

비용 정산은 해당 상태 변경과 같은 CommitGroup 또는 명시적으로 앞선 독립 CommitGroup에 포함한다.

## 11. Recipe Runtime 연결

Orchestrator는 Recipe의 내부 Step 의미를 알 필요가 없다.

```text
RuleExecution
→ CompiledRecipe 시작
→ BindingStore와 Execution Context 제공
→ Step Runtime 결과 수신
```

`BindingStore`는 해당 Execution 범위의 Blackboard다.

Child Execution은 기본적으로 별도 BindingStore를 가지며, 허용된 Typed Import·Export Binding만 부모와 공유한다.

다음은 금지한다.

- Child가 부모 BindingStore 전체를 임의 수정
- Step Handler가 Orchestrator 상태를 직접 전환
- Recipe가 TimingWindow Stack을 직접 조작
- Step이 HP, 자원과 Runtime Object를 직접 변경

## 12. PendingEffect와 CommitGroup

Recipe와 Child Execution은 PendingEffect를 생성할 수 있다.

```text
PendingEffectSet
├─ damage
├─ healing
├─ condition
├─ resource_change
├─ movement
├─ runtime_object_lifecycle
├─ ongoing_effect
└─ custom_registered
```

Orchestrator는 Commit 전에 다음을 수행한다.

1. Effect 간 의존 관계 확인
2. 동시 해결 그룹 구성
3. Passive Modifier와 Rule Override 적용
4. `before_effect_commit` TimingWindow 해결
5. 최신 Snapshot에서 대상·Revision 재검증
6. CommitGroup 구성
7. 비용 정산과 Journal 정책 결합

CommitGroup은 일부만 성공하지 않는다.

여러 CommitGroup을 가진 실행은 각 경계가 제품 규칙상 독립 확정 지점이어야 하며, RecoveryRecord에 이미 Commit된 Group을 기록한다.

## 13. Child Execution과 Join Policy

```text
ChildExecutionLink
├─ childExecutionId
├─ parentExecutionId
├─ spawnReason
├─ joinPolicy
├─ resultBindingMap
├─ failurePropagationPolicy
└─ cancellationPropagationPolicy
```

초기 `joinPolicy`:

```text
inline_blocking
→ Child가 끝날 때까지 부모 중지

parallel_collect
→ 여러 Child를 실행하고 모두 종료 후 결과 수집

independent_after_commit
→ 부모 Commit 이후 독립 실행

replace_parent_path
→ Child 결과가 부모의 현재 분기를 대체
```

반응은 일반적으로 `inline_blocking`, 사후 Trigger는 `independent_after_commit` 또는 `parallel_collect`를 사용한다.

## 14. 취소와 실패

### 14.1 사용자 취소

대상 확정과 비용 확정 전처럼 규칙상 취소 가능한 단계에서만 허용한다.

취소 시:

- 열린 Prompt·Offer 닫기
- Child Execution 취소 전파 정책 적용
- 예약 자원 반환
- 비권위 Presentation 정리
- `cancelled` Terminal Summary 기록

### 14.2 규칙상 거부

Capability 사용 조건, 대상과 비용 검증에 실패하면 `rejected`다. 이미 존재하는 다른 권위 상태를 변경하지 않는다.

### 14.3 안전 실패

Handler 오류, Budget 초과와 Provider 실패가 권위 결과를 확정할 수 없게 만들면 `failed_safe`로 종료한다.

- 아직 Commit되지 않은 PendingEffect 폐기
- 예약 자원 정책에 따라 반환 또는 DM 검토
- 이미 Commit된 Group은 되돌려 적용하지 않음
- RecoveryRecord와 Trace 보존
- 사용자에게 구조화된 오류 표시

Presentation 실패는 기본적으로 규칙 실행 실패가 아니다.

## 15. 저장, 재접속과 서버 복구

입력이나 TimingWindow를 기다리는 실행은 저장 가능한 권위 상태다.

```text
PendingRuleExecutionSnapshot
├─ executionRecord
├─ compiledRecipeHash
├─ bindingStore
├─ reservationSet
├─ rollRecords
├─ pendingEffects
├─ committedGroupIds
├─ timingWindowStack
├─ pendingInputs
├─ childExecutionDirectory
├─ executionBudgetState
├─ authorityEpoch
└─ integrityHash
```

복구 시:

1. Ruleset·Recipe·Provider Version 확인
2. 이미 Commit된 Group 확인
3. Idempotency와 Prompt 응답 상태 확인
4. 새 Execution Incarnation 필요 여부 결정
5. 사용자별 Projection 재생성
6. 원래 대기 지점 또는 안전 경계에서 재개

Client의 로컬 Prompt 선택이나 Animation 진행률을 권위 복구 원본으로 사용하지 않는다.

## 16. Rollback

DM Rollback은 현재 실행을 과거 상태로 역실행하지 않는다.

```text
과거 Encounter Snapshot 선택
→ 새 Authority Epoch·Branch 활성화
→ 해당 시점의 Pending Execution Directory 복원
→ 현재 Timeline의 Prompt·Offer·Command 무효화
```

Rollback 이후 이전 Authority Epoch의 응답은 거부한다.

## 17. Networking과 Projection

권위 실행 입력은 Versioned Command를 사용한다.

예:

```text
StartCapabilityExecutionCommand
RespondToCapabilityOfferCommand
SubmitGuidedSelectionCommand
SubmitDMAdjudicationCommand
CancelRuleExecutionCommand
```

Client에 전달되는 것은 사용자별 Projection이다.

```text
RuleExecutionStarted
RuleExecutionPhaseChanged
CapabilityOfferOpened
CapabilityOfferResolved
RuleExecutionWaiting
RuleExecutionCommitted
RuleExecutionFailed
```

비공개 Trigger 후보, 숨겨진 함정의 실행 원본과 DM 전용 판정 정보는 권한 없는 Client에 보내지 않는다.

## 18. Presentation Gate

Presentation은 원칙적으로 규칙 실행과 분리한다.

다만 주사위가 화면 중앙으로 날아온 뒤 결과를 공개하는 제품 흐름처럼 제한된 Gate를 허용한다.

```text
권위 Roll 생성·봉인
→ Presentation Signal
→ Ack 또는 Deadline
→ Result Reveal Commit
```

Gate가 기다릴 수 있는 것은 공개 시점이며, Dice 값이나 규칙 결과가 아니다.

Client 이탈·Animation 실패·Deadline 초과 시 서버 정책에 따라 결과를 공개하고 진행한다.

## 19. 동시성과 Ordering

Orchestrator는 필요한 Ordering Key를 선언한다.

```text
execution:{executionId}
actor:{actorId}
encounter:{encounterId}
object:{runtimeObjectId}
resource_pool:{poolId}
```

긴 실행 동안 모든 Key를 계속 잠그지 않는다.

- 입력 대기 전에는 예약과 Revision Token을 남기고 Lock을 해제한다.
- 재개 시 최신 상태를 재검증한다.
- Commit 직전에 필요한 Key를 안정적 순서로 다시 확보한다.

다른 변화 때문에 실행의 전제가 무효화되면 재계산, 다시 선택 요청, 안전 취소 또는 DM 검토 중 명시된 정책을 사용한다.

## 20. 실행 Budget과 Cycle 방지

```text
RuleExecutionBudget
├─ maxRecipeSteps
├─ maxChildExecutions
├─ maxExecutionDepth
├─ maxTimingWindows
├─ maxOffers
├─ maxPendingEffects
├─ maxCommitGroups
├─ maxRollRecords
├─ maxDMAdjudications
└─ maxElapsedWaitPolicy
```

Cycle Key 예:

```text
rootExecutionId
+ sourceEventOccurrenceId
+ capabilityDefinitionId
+ responderActorId
+ triggerVariantId
```

동일 Cycle Key가 정책상 허용된 횟수를 넘으면 새 Trigger를 열지 않고 구조화된 진단을 남긴다.

## 21. 진단과 DM 도구

DM은 최소한 다음을 확인할 수 있어야 한다.

- 실행 이름, 시전자·대상과 현재 Phase
- 현재 기다리는 사용자·DM 입력
- 열린 TimingWindow와 후보 응답
- 예약·소비된 비용
- RollRecord와 공개 여부
- 생성된 PendingEffect
- Commit된 Group과 남은 Group
- 부모·자식 실행 트리
- 실패 이유와 Recovery 선택지

일반 사용자에게 내부 ID와 숨겨진 후보를 그대로 노출하지 않는다.

## 22. 서비스 경계

```text
RuleRuntimeOrchestrator
├─ RuleExecutionRegistry
├─ CapabilityResolver
├─ ExecutionContextFactory
├─ CostReservationCoordinator
├─ RecipeExecutionAdapter
├─ RuleEventDispatcher
├─ TimingWindowCoordinator
├─ CapabilityOfferService
├─ ChildExecutionCoordinator
├─ CommitPreparationService
├─ ExecutionRecoveryService
├─ ExecutionProjectionBuilder
├─ RuleExecutionTraceService
└─ ExecutionBudgetService
```

Orchestrator 하나가 모든 규칙 계산을 가진 거대한 Manager가 되어서는 안 된다.

## 23. 오류 코드

초기 오류 예:

```text
RULE_EXECUTION_NOT_FOUND
RULE_EXECUTION_STALE_INCARCATION
RULE_EXECUTION_WRONG_EPOCH
CAPABILITY_NOT_GRANTED
CAPABILITY_NOT_AVAILABLE
EXECUTION_CONTEXT_STALE
COST_RESERVATION_FAILED
TIMING_WINDOW_CLOSED
CAPABILITY_OFFER_STALE
OFFER_RESPONSE_NOT_AUTHORIZED
EXECUTION_BUDGET_EXCEEDED
EXECUTION_CYCLE_DETECTED
CHILD_EXECUTION_FAILED
COMMIT_PRECONDITION_FAILED
COMMIT_GROUP_FAILED
RECIPE_VERSION_MISMATCH
EXECUTION_RECOVERY_REQUIRES_DM
```

구현 명세에서는 `STALE_INCARCATION`을 `STALE_INCARNATION`으로 정규화한다.

## 24. 성능 원칙

- Event마다 모든 Actor와 Feature를 전체 순회하지 않는다.
- Trigger Index와 Grant Cache를 사용한다.
- Waiting Execution마다 Heartbeat Loop를 만들지 않는다.
- Deadline은 중앙 Scheduler에서 관리한다.
- BindingStore와 PendingEffect는 실행 종료 후 정리한다.
- Trace 상세 수준은 개발·DM 진단·일반 운영 정책으로 나눈다.
- Presentation 대기로 서버 권위 Lock을 유지하지 않는다.

## 25. 완료 기준

후속 구현 명세는 최소한 다음 흐름을 검증해야 한다.

1. 일반 무기 공격이 선언부터 피해 Commit까지 완료된다.
2. 명중 굴림 후 `Shield`가 제안되고 결과를 바꿀 수 있다.
3. 기회 공격이 이동 Checkpoint에서 Child Execution으로 실행된다.
4. 명중 후 한 턴에 한 번인 추가 피해가 반응 비용 없이 제안된다.
5. 피해 적용 전 피해 감소가 PendingEffect를 수정한다.
6. 사용자 연결 종료 후 TimingWindow가 복구된다.
7. 같은 Offer 응답 재전송이 두 번 자원을 소비하지 않는다.
8. Presentation 실패 후에도 Roll 공개와 Commit이 완료된다.
9. Child Execution Cycle이 Budget에 의해 차단된다.
10. Commit 중 실패가 부분 상태를 남기지 않는다.
11. 서버 복구 후 이미 Commit된 Group이 재적용되지 않는다.
12. Rollback 이후 이전 Prompt 응답이 거부된다.

## 26. 비목표

- 개별 주문과 Feature의 세부 규칙을 이 문서에서 정의하지 않는다.
- 정확한 Luau 파일 경로와 타입 선언을 이 문서에서 확정하지 않는다.
- D&D의 모든 동시 처리 예외를 하나의 고정 Priority 숫자로 환원하지 않는다.
- Client Animation이 권위 결과를 결정하게 하지 않는다.
- 자유 텍스트 DM 판정을 자동으로 규칙 상태에 적용하지 않는다.
