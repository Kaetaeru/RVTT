# Effect, Condition과 Ongoing Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 작성일: 2026-08-04
- 남은 기본값:
  - 활성 EffectInstance 수와 대상별 Index의 경고 기준
  - Duration Scheduler의 처리 Budget과 한 Tick 최대 만료 수
  - 종료 Tombstone과 Effect Journal 보존 기간
  - Projection에서 동일 상태를 집계하는 기본 표시 순서
  - Form Overlay 파생 결과 Cache의 메모리 상한
- 관련 ADR:
  - [`ADR-0027`](../decisions/ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md)
  - [`ADR-0028`](../decisions/ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0029`](../decisions/ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0064`](../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
  - [`ADR-0065`](../decisions/ADR-0065-compiled-effect-builds-and-authoritative-effect-instances.md)
- Parent:
  - [`Compiled Build와 Authoritative State 분리 패턴`](compiled-build-and-authoritative-state-pattern.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
- References:
  - [`Character Runtime과 Compiled Character Build 계약`](character-runtime-and-compiled-character-build-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Persistence, Snapshot, Journal과 Recovery 계약`](persistence-and-session-recovery-model.md)
  - [`Passive Modifier와 Rule Override 모델`](passive-modifier-and-rule-override-model.md)
  - [`EffectRecipe 해결·확정 모델`](effect-recipe-resolution-and-commit-model.md)

## 1. 목적

이 문서는 실행이 끝난 뒤에도 남는 모든 규칙 효과의 공통 권위 구조를 정의한다.

포함 범위:

- 공식 Condition
- 버프·디버프와 Stance
- 지속 피해·반복 회복·반복 내성
- 집중
- Aura와 지속 영역
- 시전자와 대상 사이의 Link
- 변신과 Form Overlay
- 소환체와 생성된 Runtime Object
- 안티매직과 기타 Suppression
- Dispel, 해제, 만료와 DM 종료

특정 주문·특성 이름별 코드를 이 문서에서 정의하지 않는다. 콘텐츠는 Effect Definition과 Recipe로 선언하고, Runtime은 공통 Build·Instance·Transaction 계약을 실행한다.

## 2. 최상위 구조

```text
ConditionDefinition / OngoingEffectDefinition
+ Rules Content Pack Version
→ Effect Compiler
→ Immutable CompiledEffectBuild

RuleExecution / DM Command / Environment Trigger
→ PendingEffectCreation
→ Transaction 검증
→ Authoritative EffectInstance
→ Modifier·Capability·Trigger·Runtime Object 기여
→ Runtime Snapshot과 Projection
```

다음을 분리한다.

```text
CompiledEffectBuild
→ 효과가 무엇을 제공하고 어떤 정책을 사용하는가

EffectInstance
→ 누가, 누구에게, 어떤 값과 수명으로 적용되었는가

Derived Contribution View
→ 현재 Snapshot에서 실제로 활성인 Modifier·Capability·Trigger
```

## 3. 권위 소유권

### 3.1 Effect Definition

`RulesContentCatalog`가 소유하는 Authoring Source다.

```text
EffectDefinitionSource
├─ effectDefinitionId
├─ definitionKind
├─ schemaVersion
├─ rulesetId
├─ contentPackId와 version
├─ tags
├─ grants
├─ triggerDefinitions
├─ modifierDefinitions
├─ durationPolicyDefinition
├─ endConditionDefinitions
├─ stackingPolicyDefinition
├─ suppressionPolicyDefinition
├─ ownershipPolicyDefinition
├─ formOverlayDefinition?
├─ disclosurePolicyDefinition
└─ presentationProfileReference
```

`ConditionDefinition`은 공식 상태를 위한 전문 Definition이지만 별도 Runtime 수명주기를 만들지 않는다.

### 3.2 CompiledEffectBuild

Compiler가 Definition을 검증·정규화한 불변 Build다.

```text
CompiledEffectBuild
├─ effectBuildId
├─ effectDefinitionId
├─ sourceContentHash
├─ compilerVersion
├─ rulesetSnapshotRef
├─ normalizedTags
├─ compiledModifierContributions
├─ compiledCapabilityContributions
├─ compiledTriggerBindings
├─ compiledDurationPlan
├─ compiledEndConditionPlan
├─ compiledStackingPlan
├─ compiledSuppressionPlan
├─ compiledCleanupPlan
├─ compiledOwnershipPlan
├─ compiledFormOverlayPlan?
├─ dependencyGraph
├─ disclosurePlan
└─ buildContentHash
```

Build에는 현재 대상, 남은 지속시간, Suppression Source와 현재 Stack 수를 넣지 않는다.

### 3.3 EffectInstance

별도 `EffectRegistry`가 권위 상태를 소유한다.

```text
EffectInstanceState
├─ effectInstanceId
├─ effectBuildRef와 hash
├─ authorityEpoch
├─ incarnation
├─ lifecycleState
├─ sourceExecutionId?
├─ sourceContentId
├─ sourceCharacterRef?
├─ sourceActorRef?
├─ ownerBinding?
├─ controllerBinding?
├─ targetBindings
├─ anchorBinding?
├─ encounterBinding?
├─ frozenParameters
├─ liveBindingReferences
├─ durationState
├─ endConditionState
├─ stackingIdentity
├─ concentrationBinding?
├─ suppressionSources
├─ parentEffectRef?
├─ childEffectRefs
├─ ownedRuntimeObjectRefs
├─ revision
└─ endRecord?
```

Character, Actor와 Encounter는 EffectInstance 전체를 복사하지 않는다. 필요한 경우 타입 있는 Effect Reference와 파생 View만 가진다.

## 4. Binding과 수명주기 경계

EffectInstance는 하나의 도메인에 무조건 종속되지 않는다.

지원 Binding:

```text
character_binding
→ Scene이 바뀌어도 Character에 유지되는 효과

actor_binding
→ 특정 Scene Presence에만 적용되는 효과

encounter_binding
→ 현재 Encounter가 끝나면 정리되는 효과

scene_anchor_binding
→ 위치·영역·오브젝트에 묶인 효과

runtime_object_binding
→ 문, 장벽, 소환체 등 특정 Runtime Object에 묶인 효과

campaign_binding
→ 캠페인 시간과 사건에 따라 유지되는 장기 효과
```

Binding은 Target과 Ownership을 구분한다.

- Target: 규칙 기여를 받는 대상
- Owner: 종료·정리 책임을 연결하는 상위 수명주기
- Source: 효과를 발생시킨 Character, Actor, Item, Hazard 또는 RuleExecution
- Controller: 선택이나 재사용 행동을 제출할 권한

## 5. 수명주기

외부 권위 상태:

```text
pending_activation
→ active
↔ suppressed
→ ending
→ ended
```

실패 상태:

```text
rejected
invalidated_before_activation
failed_safe
```

`pending_activation`은 RuleExecution 내부의 임시 객체가 아니라 Transaction Plan에 포함된 생성 후보다. Commit 전까지 다른 Query와 Projection에는 나타나지 않는다.

`ending`은 정리 Transaction이 진행 중인 상태다. Capability 제거, Trigger 해제와 소유 Object 정리가 일부만 반영된 상태를 외부에 공개하지 않는다.

`ended`는 활성 Index에서 제거되지만 Tombstone, EndRecord와 Journal 참조를 보존할 수 있다.

## 6. 생성과 활성화 Transaction

```text
PendingEffectCreation
→ Build와 Schema 검증
→ Source·Target·Anchor·Incarnation 검증
→ 면역·적격성 검증
→ Stacking Plan 평가
→ Concentration Reservation
→ Runtime Object 생성 가능성 검증
→ EffectInstanceId 예약
→ Contribution과 Cleanup Plan 구성
→ Commit Graph 검증
→ 원자적 Commit
→ EffectActivated Event와 Projection
```

다음을 하나의 CommitGroup에서 처리할 수 있어야 한다.

- 기존 Stack 교체 또는 갱신
- 기존 집중 효과 종료
- 새 EffectInstance 생성
- Character Resource 소비
- Capability·Modifier·Trigger Index 갱신
- 지속 영역·소환체 Runtime Object Spawn
- AuthorityRevision과 Journal 발행

중간 실패 시 기존 효과만 종료되고 새 효과가 생성되지 않는 상태를 남기지 않는다.

## 7. 기여 모델

EffectInstance가 Character 수치나 행동 목록을 직접 덮어쓰지 않는다.

```text
Active EffectInstance
→ Compiled Contribution 활성화
→ Character·Actor·Scene Context Resolver
→ Derived Character View / Capability View / Rule Event View
```

기여 종류:

```text
ModifierContribution
RuleOverrideContribution
CapabilityContribution
TriggerContribution
MovementProfileContribution
SenseContribution
SpatialBodyOverlay
DisclosureContribution
```

Contribution은 `effectInstanceId`와 출처를 유지해 설명·로그·충돌 진단이 가능해야 한다.

Suppressed 상태에서는 Suppression Plan에 따라 기여별 활성 여부를 계산한다.

## 8. Duration과 논리 시간

Duration은 프레임별 타이머를 만들지 않는다.

```text
instantaneous
until_turn_boundary
fixed_turns
fixed_rounds
game_time_deadline
until_short_rest
until_long_rest
concentration_bound
until_successful_save
until_event
until_condition
until_dispelled
permanent
manual
```

전투 Duration은 다음을 참조한다.

```text
encounterId
turnCycleId
boundaryActorRef
boundaryKind: turn_start | turn_end | round_start | round_end
remainingCount
```

탐험·캠페인 Duration은 서버 권위 Game Time을 사용한다.

Duration Scheduler는 만료 후보만 생성한다. 실제 종료는 최신 Snapshot에서 End Condition을 재검증하는 `EndEffectTransaction`으로 확정한다.

## 9. End Condition

지원 조건 예시:

```text
duration_expired
concentration_ended
successful_save
source_invalid
target_invalid
owner_destroyed
owner_incapacitated
out_of_range
line_of_effect_lost
left_required_region
triggering_action_occurred
resource_exhausted
dispelled
explicit_recipe
dm_ended
```

조건은 `any`, `all`과 검증된 Boolean Plan으로 결합한다.

거리·효과선·영역 이탈 조건은 Spatial Query의 같은 Snapshot 증거를 사용한다. Effect Runtime이 Workspace를 직접 검사하지 않는다.

## 10. Concentration Channel

집중은 Character의 단일 Boolean이 아니다.

```text
ConcentrationChannelState
├─ channelOwnerCharacterId
├─ activeActorRef?
├─ channelId
├─ rootEffectInstanceId
├─ linkedEffectInstanceIds
├─ reservedByExecutionId?
├─ startedByExecutionId
├─ rulesetPolicyRef
└─ revision
```

기본 2024 규칙은 일반적으로 하나의 채널을 제공하지만, Channel 수와 사용 조건은 Character Build와 Rule Override가 결정한다.

새 집중 시작:

```text
새 Channel Reservation
→ 기존 Root 종료 Plan
→ 새 Root·Child 효과 생성 Plan
→ 한 Transaction으로 Commit
```

피해에 따른 집중 검사는 `DamageApplied` 이후 Child RuleExecution으로 생성한다. 실패 결과가 Commit되면 연결된 Effect Graph를 결정적 순서로 종료한다.

Actor가 Scene을 이동해도 Character Binding의 집중 채널은 유지할 수 있다. 단, 대상·거리·Scene 요구 조건은 새 Snapshot에서 재검증한다.

## 11. Stacking

Stack 판단은 이름이나 아이콘을 사용하지 않는다.

```text
StackingIdentity
├─ stackingKey
├─ equivalenceScope
├─ sourceIdentity?
├─ targetIdentity
├─ occurrenceId?
└─ potencyKey?
```

정책:

```text
independent
replace_existing
refresh_duration
extend_duration
highest_potency_only
lowest_penalty_only
merge_sources
unique_by_source
unique_by_target
prohibited
custom_registered
```

`highest_potency_only`는 약한 Instance를 삭제한다는 의미가 아니다. 정책에 따라 약한 Instance를 유지하되 Contribution만 비활성화할 수 있다.

UI의 상태 아이콘 집계는 Projection이며 권위 Instance 수를 대체하지 않는다.

## 12. Suppression

Suppression은 종료가 아니다.

```text
SuppressionSource
├─ sourceType
├─ sourceRef
├─ scope
├─ policyOverride?
├─ startedRevision
└─ validityEvidenceRef?
```

여러 Suppression Source를 Set으로 유지한다. 하나가 제거되어도 다른 원인이 남으면 재활성화하지 않는다.

정책별로 다음을 결정한다.

- Modifier Contribution 활성 여부
- Capability 사용 가능 여부
- Trigger 후보 생성 여부
- Duration 진행 여부
- Concentration 유지 여부
- Owned Runtime Object의 Active·Suspended 상태
- Presentation 표시 방식

Suppression Source 추가·제거도 Transaction을 사용한다.

## 13. Parent·Child와 Runtime Object Ownership

Effect Graph는 명시적 소유 관계를 가진다.

```text
Concentration Root Effect
├─ Target Buff Effect
├─ Persistent Area Effect
├─ Summon Controller Effect
└─ Owned Runtime Objects
```

Parent 종료 정책:

```text
end_with_parent
suppress_with_parent
detach_on_parent_end
transfer_to_owner
resolve_by_cleanup_recipe
```

Scene Presence가 필요한 결과는 Runtime Object System을 사용한다.

```text
EffectInstance
→ Runtime Ownership Edge
→ Runtime Object
```

Effect Runtime은 Workspace Model을 직접 생성·삭제하지 않는다. Spawn·Archive·Destroy Command와 공통 Lifecycle을 사용한다.

## 14. Form Overlay와 변신

변신은 Character Build를 제자리 수정하지 않는다.

```text
Base CompiledCharacterBuild
+ CompiledFormOverlayPlan
+ Persistent Character State
+ Form EffectInstance State
→ Effective Character Runtime View
```

Form Overlay는 항목별 정책을 선언한다.

```text
replace
preserve
augment
suppress
inherit_with_limit
```

적용 대상 예시:

- Ability Score와 Skill
- HP Pool 정책
- AC와 Movement
- Sense와 SpatialBodyProfile
- Capability와 Spell Access
- Equipment 사용 가능성
- 이름·Token Presentation

현재 HP를 별도 Character로 복사하거나 Base Character Build를 수정하지 않는다. Form 종료 시 Cleanup Plan과 State Migration Policy로 원상 복구한다.

Wild Shape, Polymorph와 Shapechange는 같은 Overlay 기반을 사용하되 서로 다른 콘텐츠 정책을 선언할 수 있다.

## 15. 저장·복구·롤백

Snapshot 저장 대상:

```text
EffectInstanceId와 Incarnation
EffectBuildRef와 Content Hash
Lifecycle State
Source·Owner·Controller·Target Binding
Frozen Parameters
Duration State
End Condition State
Stacking Identity
Concentration Link
Suppression Sources
Parent·Child·Owned Object Reference
Revision
필요한 Tombstone과 EndRecord
```

저장하지 않는 파생 데이터:

- 최종 Modifier 합계
- 활성 Capability 복사본
- Trigger 후보 Cache
- UI 상태 아이콘 집계
- VFX·Tween·Camera 상태

복구 시 Build Hash를 검증하고 EffectRegistry를 복원한 뒤 Contribution Index와 Scheduler를 재구성한다.

Rollback은 과거 Effect Snapshot을 새 Authority Branch에서 복원한다. 폐기된 Branch의 Prompt, Timer Callback과 종료 후보는 새 Epoch에 적용할 수 없다.

## 16. Projection과 공개 범위

서버 Raw EffectInstance를 모든 Client에 보내지 않는다.

```text
Raw Effect State
→ Disclosure·Perception·Control Policy
→ Client-safe Effect Projection
```

Projection 예시:

- 소유 플레이어: 상세 Duration, 출처, 재사용 Action
- 대상 플레이어: 자신에게 적용된 공개 효과와 필요한 규칙 설명
- 다른 플레이어: 공개된 아이콘·연출만
- DM: 전체 Binding, Suppression과 내부 진단

숨겨진 저주, 미발견 함정 효과와 비밀 Scene Rule의 실제 DefinitionId·Target을 권한 없는 Client에 보내지 않는다.

## 17. 실패 정책

다음 경우 조용히 효과를 누락하거나 부분 활성화하지 않는다.

```text
EFFECT_BUILD_MISSING
EFFECT_BUILD_HASH_MISMATCH
INVALID_TARGET_BINDING
STALE_TARGET_INCARCERATION
STACKING_PLAN_FAILED
CONCENTRATION_CONFLICT
DURATION_PLAN_INVALID
OWNED_OBJECT_SPAWN_FAILED
CLEANUP_PLAN_FAILED
MIGRATION_REQUIRED
COMPUTE_BUDGET_EXCEEDED
```

활성화 전 실패는 전체 생성 Transaction을 거부한다.

종료 정리 중 실패는 `failed_safe` 진단을 남기고, 규칙 기여를 다시 활성화하지 않은 안전 상태에서 DM 복구 작업을 요구한다. Tombstone과 Journal은 보존한다.

## 18. 성능 원칙

- Effect마다 Heartbeat Loop를 만들지 않는다.
- Target, Source, Owner, Duration Boundary와 Stacking Key별 Index를 사용한다.
- Character Derived View는 Effect revision 의존성으로 증분 무효화한다.
- 범위·거리 기반 효과는 Spatial Query와 Region Index를 사용한다.
- 전체 Effect Registry 순회를 일반 판정 경로로 사용하지 않는다.
- 대규모 종료는 제한된 Batch와 Commit Graph로 처리하되 권위 결과의 원자성을 유지한다.

## 19. 구현 경계

초기 Service 경계:

```text
EffectDefinitionCompiler
EffectBuildRegistry
EffectRegistry
EffectApplicationService
EffectLifecycleService
DurationScheduler
EndConditionEvaluator
StackingResolver
SuppressionService
ConcentrationService
EffectContributionResolver
FormOverlayResolver
EffectProjectionBuilder
EffectPersistenceAdapter
EffectTraceService
```

정확한 Luau Module 경로와 Type 이름은 `specs/`에서 정한다.

## 20. 비목표

- 모든 효과를 단순 Modifier로 축약하지 않는다.
- 주문 이름별 Runtime 분기를 만들지 않는다.
- Condition을 Character의 문자열 Set으로 저장하지 않는다.
- 집중을 주문별 Boolean으로 저장하지 않는다.
- 억제와 종료를 같은 상태로 처리하지 않는다.
- Effect 종료를 Model 삭제 하나로 처리하지 않는다.
- UI 아이콘 목록을 권위 Effect 목록으로 사용하지 않는다.

## 21. 구현 명세 선행 순서

```text
Effect Build Schema와 Compiler
→ EffectRegistry와 Identity
→ Application·Stacking Transaction
→ Contribution Resolver
→ Duration·End Condition Scheduler
→ Concentration Channel
→ Suppression
→ Parent·Child와 Runtime Object Ownership
→ Form Overlay
→ Persistence·Projection·Diagnostics
```
