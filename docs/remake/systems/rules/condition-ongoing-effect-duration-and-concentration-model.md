# 23. 상태·지속 효과·집중 수명주기 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](../../architecture/rules-content-grant-capability-model.md)
  - [`19. 트리거와 다른 턴 실행 모델`](feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`21. 패시브 특성 모델`](../../architecture/passive-modifier-and-rule-override-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`ADR-0029`](../../decisions/ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)

## 1. 문서 목적

이 문서는 실행이 끝난 뒤에도 남아 있는 규칙 효과의 공통 수명주기를 정의한다.

대상은 다음을 포함한다.

- 공식 상태
- 버프와 디버프
- 지속 피해와 반복 회복
- 집중 주문
- 반복 내성
- 변신과 형태 교체
- 시전자와 대상 사이의 지속 연결
- 소환체와 생성된 장면 오브젝트
- 지속 영역과 오라
- 안티매직에 의한 일시 억제
- 해제, 디스펠과 수동 DM 종료

핵심 원칙은 다음과 같다.

```text
상태 이름을 대상에게 직접 추가
X

EffectRecipe가 지속 효과 생성 요청
→ EffectInstance 생성
→ Capability·Trigger·소유 오브젝트 활성화
→ 지속시간과 종료 조건 추적
→ 종료 트랜잭션
→ 정리와 기록
O
```

---

## 2. 정의와 런타임 인스턴스를 분리한다

### 2.1 ConditionDefinition

규칙 카탈로그에 존재하는 공식 상태 정의다.

```text
ConditionDefinition
├─ conditionId
├─ schemaVersion
├─ rulesetId
├─ localizationKeys
├─ tags[]
├─ grantedCapabilities[]
├─ applicationRules
├─ defaultStackingProfileId
├─ displayProfileId
└─ diagnosticsProfile
```

상태 정의는 다음을 소유할 수 있다.

- 행동과 이동 제한
- 공격, 판정과 내성 굴림 수정
- 대상에게 가해지는 공격의 수정
- 이동 방식과 속도 변경
- 특정 피해와 상태에 대한 면역
- 턴 시작·종료 트리거
- 상태 아이콘과 설명

상태 정의 자체는 일반적으로 특정 지속시간을 소유하지 않는다.

```text
중독됨
→ 어떤 규칙 효과를 주는가

이번 중독 인스턴스
→ 언제 끝나는가
```

두 책임을 분리한다.

### 2.2 OngoingEffectDefinition

공식 상태가 아닌 지속 규칙의 정의다.

```text
OngoingEffectDefinition
├─ effectDefinitionId
├─ effectKind
├─ schemaVersion
├─ grantedCapabilities[]
├─ triggers[]
├─ objectCreationProfiles[]
├─ defaultDurationProfile?
├─ defaultEndConditions[]
├─ stackingProfileId
├─ suppressionProfileId
├─ cleanupProfileId
└─ presentationProfileId
```

예시:

- 일시적 방어도 증가
- 축복형 굴림 보너스
- 마녀의 번개 연결
- 투명화
- 폴리모프 형태
- 지속 마법 영역
- 소환 유지 효과

### 2.3 EffectInstance

정의가 실제 게임 세계에 적용된 런타임 상태다.

```text
EffectInstance
├─ effectInstanceId
├─ effectKind
├─ definitionReference
├─ rulesetSnapshot
├─ sourceExecutionId
├─ sourceContentId
├─ sourceActorId?
├─ ownerActorId?
├─ controllerBinding?
├─ targetBindings[]
├─ anchorBinding?
├─ frozenParameters
├─ liveBindings[]
├─ grantedCapabilityBindings[]
├─ triggerBindings[]
├─ ownedObjectBindings[]
├─ durationState
├─ endConditionStates[]
├─ stackingIdentity
├─ concentrationLink?
├─ suppressionSources[]
├─ parentEffectId?
├─ childEffectIds[]
├─ cleanupPlan
├─ visibilityPolicy
├─ lifecycleState
├─ endRecord?
└─ revision
```

캐릭터와 Actor에 효과 정의 전체를 복사하지 않는다.

---

## 3. effectKind

초기 공통 종류:

```text
condition
buff
debuff
stance
form
link
aura
persistent_area
summon_controller
stored_execution
suppression_zone
scene_rule
custom_registered
```

`effectKind`는 표시 분류와 기본 정책 선택을 돕는다. 실행 엔진이 특정 주문 이름을 분기하는 키로 사용하지 않는다.

공식 상태와 일반 지속 효과는 같은 수명주기를 사용하지만, `ConditionDefinition`과 상태 집계 UI 같은 전문 계약을 추가로 가진다.

---

## 4. EffectInstance 수명주기

```text
PendingCreation
→ Validating
→ Active
↔ Suppressed
→ Ending
→ Ended
```

실패 상태:

```text
Rejected
InvalidatedBeforeActivation
FailedActivation
FailedCleanup
```

### PendingCreation

`EffectRecipe`가 `PendingOngoingEffectCreation` 또는 `PendingConditionChange`를 생성한 상태다.

### Validating

서버가 다음을 검사한다.

- 대상이 존재하고 적격한가
- 상태·효과 면역이 적용되는가
- 중첩 정책상 새 인스턴스를 만들 수 있는가
- 집중 채널을 확보할 수 있는가
- 필수 앵커와 장면 오브젝트를 만들 수 있는가
- 정의와 규칙 버전이 유효한가

### Active

Capability, Trigger와 소유 오브젝트가 현재 규칙에 기여한다.

### Suppressed

인스턴스는 남아 있지만 하나 이상의 억제 출처 때문에 일부 또는 전체 기능이 비활성화된 상태다.

### Ending

종료 조건이 발생하여 정리 계획을 실행 중이다.

### Ended

규칙 기여와 소유 관계가 모두 정리되었고 종료 사유가 기록된 상태다.

종료된 인스턴스는 권위 활성 목록에서 제외하지만 감사·로그·멱등성 기록은 보존한다.

---

## 5. 적용 검증과 면역

효과 생성 전에 `EffectApplicationContext`를 만든다.

```text
EffectApplicationContext
├─ sourceActorId?
├─ targetId
├─ definitionId
├─ effectTags[]
├─ applicationMethod
├─ sourceExecutionId
├─ potencyBindings
├─ durationProposal
├─ rulesetSnapshot
└─ revisionSet
```

면역은 문자열 상태 이름 비교가 아니라 태그와 타입 있는 규칙으로 평가한다.

```text
ConditionImmunityCapability
EffectTagImmunityCapability
RuleOverrideCapability
```

면역 정책:

```text
on_application_only
continuous_suppress
continuous_end
```

### on_application_only

적용 순간만 검사한다. 이후 새 면역을 얻어도 기존 효과가 자동으로 끝나지 않는다.

### continuous_suppress

면역 조건이 유지되는 동안 기존 효과를 억제하고 조건이 사라지면 재활성화할 수 있다.

### continuous_end

면역 조건을 얻는 즉시 기존 효과를 종료한다.

정확한 정책은 상태·효과 정의와 규칙 세트가 소유한다.

---

## 6. Capability와 Trigger 바인딩

효과 인스턴스가 활성화되면 정의가 제공하는 Capability와 Trigger를 인스턴스 출처로 컴파일한다.

```text
EffectInstance
→ Capability Compiler
→ sourceEffectInstanceId가 있는 CapabilityBinding[]
```

지원 가능 항목:

- `DerivedValueModifierCapability`
- `ContextModifierCapability`
- `RuleOverrideCapability`
- `ConditionalCapabilityGroup`
- `ActionCapability`
- `TriggerCapability`
- `ResourceCapability`
- `UnitReplacementCapability`

효과가 끝나면 원본 정의를 찾아 역추론하지 않고 저장된 CapabilityBinding을 정리한다.

### 바인딩 값의 고정과 실시간 참조

모든 수치를 시전 시점에 고정하거나 모두 실시간으로 참조하지 않는다.

```text
ParameterBindingPolicy
├─ freeze_at_creation
├─ resolve_on_trigger
├─ resolve_on_use
├─ resolve_on_turn_boundary
└─ custom_registered
```

예시:

- 시전 당시 주문 DC를 고정
- 현재 대상 수에 따라 오라 효과를 실시간 질의
- 매 턴 현재 능력 수정치로 반복 피해 계산

각 정의가 바인딩 정책을 명시한다.

---

## 7. DurationPolicy

```text
DurationPolicy
├─ durationKind
├─ startAnchor
├─ expirationAnchor?
├─ amount?
├─ timeUnit?
├─ boundaryActorBinding?
├─ boundaryKind?
├─ clockId?
├─ pausePolicy
├─ suppressionTimePolicy
└─ expirationEffectRecipeId?
```

### durationKind

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
until_dispelled
permanent
manual
```

`instantaneous` 효과는 일반적으로 EffectInstance를 만들지 않는다. 다른 지속 오브젝트의 생성과 즉시 정리를 묶어야 할 때만 제한적으로 사용할 수 있다.

---

## 8. 턴 경계 지속시간

`다음 턴 시작까지`와 `다음 턴 종료까지`를 단순 남은 라운드 수로 저장하지 않는다.

```text
TurnBoundaryExpiration
├─ boundaryActorId
├─ boundaryKind: turn_start | turn_end
├─ occurrencePolicy
├─ createdTurnId
├─ targetOccurrenceOrdinal
└─ resolvedOccurrenceId?
```

예시:

```text
시전자의 다음 턴 시작까지
→ boundaryActorId = caster
→ boundaryKind = turn_start
→ targetOccurrenceOrdinal = next
```

주도권 변경, 턴 건너뛰기와 추가 턴이 있어도 규칙 세트의 occurrence policy로 일관되게 처리한다.

효과마다 매초 카운터를 돌리지 않고 `TurnStarted` 또는 `TurnEnded` 이벤트 인덱스에서 만료 후보를 조회한다.

---

## 9. 고정 턴과 라운드

```text
CombatDurationState
├─ startTurnId
├─ startRoundId
├─ remainingOccurrences
├─ decrementEventType
├─ initiativeSequenceId
└─ expirationState
```

`1라운드`가 정확히 어느 경계에서 끝나는지는 규칙 세트와 적용 정의가 명시한다.

콘텐츠 작성자가 모호한 `remainingRounds--`만 선언하지 않게 한다.

전투가 종료되었을 때:

- 남은 지속시간을 캠페인 시간으로 변환
- 즉시 종료
- 탐험 지속 상태로 전환

중 어느 정책을 사용할지 `combatExitPolicy`가 결정한다.

---

## 10. 게임 시간 지속시간

분, 시간과 일 단위 효과는 캠페인 게임 시간축을 사용한다.

```text
GameTimeDurationState
├─ clockId
├─ startedAtGameTime
├─ expiresAtGameTime
├─ pausePolicy
└─ lastEvaluatedRevision
```

실제 서버 벽시계와 동일하게 취급하지 않는다.

세션이 오프라인일 때 시간이 흐르는지, 장면 일시정지에서 시간이 흐르는지는 캠페인 시간 정책이 결정한다.

만료 예약은 시간 인덱스 또는 우선순위 큐를 사용한다.

---

## 11. EndCondition

```text
EndCondition
├─ conditionId
├─ conditionKind
├─ eventType?
├─ predicate?
├─ evaluationPolicy
├─ combinationGroup
├─ onSatisfiedPolicy
└─ diagnosticsKey
```

초기 `conditionKind`:

```text
duration_expired
concentration_ended
successful_save
source_invalid
target_invalid
source_incapacitated
owner_incapacitated
target_out_of_range
line_of_effect_lost
left_scene
entered_scene
triggering_action_occurred
damage_received
attack_made
spell_cast
dispelled
parent_effect_ended
owned_object_destroyed
explicit_recipe
dm_ended
```

### evaluationPolicy

```text
event_driven
on_use
on_turn_boundary
on_scene_transition
continuous_indexed
manual
```

`continuous_indexed`는 매 프레임 전체 검사라는 뜻이 아니다. 거리·영역·시야 인덱스의 변경 사건으로 후보를 제한한다.

### 조건 결합

```text
EndConditionExpression
├─ anyOf[]
├─ allOf[]
└─ not?
```

무제한 논리식과 임의 스크립트를 허용하지 않고 검증 가능한 제한 구조만 사용한다.

---

## 12. 반복 내성

반복 내성은 상태 시스템 내부의 특별 루프가 아니라 EffectInstance가 제공하는 TriggerCapability와 EffectRecipe 조합이다.

```text
RepeatSaveBinding
├─ triggerEventType
├─ timingPhase
├─ saveRecipeId
├─ dcBinding
├─ actorBinding
├─ successPolicy
├─ failurePolicy
├─ usageGate
└─ visibilityPolicy
```

예시:

```text
TurnEnded(target)
→ 반복 내성 실행
→ 성공
   → EndEffectTransaction
→ 실패
   → 효과 유지
```

성공 시 상태 일부만 약화되거나 단계가 내려가는 효과는 종료 대신 `TransformEffectInstance` 또는 등록된 단계 전환 연산을 사용할 수 있다.

한 턴에 여러 번 반복 내성이 발생하지 않도록 사건 ID와 UsageGate를 사용한다.

---

## 13. ConcentrationState

집중은 EffectInstance 내부 불리언만으로 관리하지 않는다.

```text
ConcentrationState
├─ ownerActorId
├─ channels[]
├─ rulesetPolicyId
└─ revision

ConcentrationChannel
├─ channelId
├─ capacitySlotId
├─ rootEffectInstanceId
├─ linkedEffectInstanceIds[]
├─ startedByExecutionId
├─ startedAt
├─ status
└─ revision
```

기본 D&D 규칙에서는 일반적으로 하나의 집중 채널만 활성화되지만, 시스템 구조는 규칙 오버라이드와 홈브루 확장을 막지 않는다.

### 집중 시작

```text
새 집중 효과 확정 준비
→ 사용 가능한 집중 채널 계산
→ 기존 효과 교체가 필요한지 판정
→ 기존 집중 종료 계획 생성
→ 새 루트 EffectInstance 생성
→ 자식 효과와 채널 연결
→ 하나의 CommitGroup으로 확정
```

기존 집중 종료와 새 집중 시작 사이에 중간 상태를 외부에 노출하지 않는다.

### 집중을 자발적으로 끝내기

규칙상 허용되는 경우 소유자는 명시적인 `EndConcentrationRequest`를 보낸다.

서버가 소유권, 현재 상태와 시간 정책을 검증한 뒤 종료한다.

클라이언트가 연결된 효과 목록을 직접 삭제하지 않는다.

---

## 14. 피해와 집중 검사

집중 검사는 `PendingDamage` 단계가 아니라 실제 `DamageApplied` 이후에 생성한다.

```text
DamageApplied
→ 대상이 집중 중인지 조회
→ ruleset concentration check grouping policy
→ ConcentrationCheckRequest 생성
→ 내성 굴림 EffectRecipe
→ 실패 시 EndConcentrationTransaction
```

### 검사 묶음 정책

```text
ConcentrationCheckGroupingPolicy
├─ per_damage_application
├─ per_simultaneous_group
├─ per_effect_unit
└─ custom_ruleset_policy
```

여러 투사체와 동시 피해를 어떻게 셀지는 주문 이름이 아니라 피해 적용 구조와 규칙 세트가 결정한다.

### DC

DC는 타입 있는 표현식으로 계산한다.

```text
ConcentrationDCExpression
→ damage amount, minimum DC와 ruleset parameters 참조
```

정확한 공식은 규칙 콘텐츠 또는 규칙 세트 팩이 소유한다.

### 다른 집중 종료 원인

- 무력화 또는 사망
- 집중 불가능 상태
- 새 집중 시작
- 자발적 종료
- 특정 환경 사건
- 효과 자체 종료

각 원인은 공통 종료 트랜잭션으로 연결된다.

---

## 15. 부모·자식 Effect Graph

한 실행이 여러 지속 인스턴스와 오브젝트를 만들 수 있다.

```text
EffectOwnershipGraph
├─ rootEffectInstanceId
├─ ownedEffectIds[]
├─ ownedActorIds[]
├─ ownedSceneObjectIds[]
└─ ownershipPolicies[]
```

### 예시: 다중 대상 집중 버프

```text
Concentration Root Effect
├─ Target A Buff Effect
├─ Target B Buff Effect
└─ Target C Buff Effect
```

대상 B의 효과가 개별적으로 해제되어도 A와 C는 유지될 수 있다.

집중 루트가 끝나면 남은 모든 자식 효과를 정리한다.

### 예시: 소환 주문

```text
Concentration Root Effect
├─ Summoned Actor ownership
├─ Summon Controller Effect
└─ Presentation bindings
```

집중 종료 시 소환 Actor 제거 또는 독립화 여부는 cleanup policy가 정한다.

### 예시: 지속 영역

```text
Root Effect
├─ SceneEffectInstance
├─ RuleSceneObject
└─ area trigger bindings
```

소유 오브젝트 파괴가 루트 효과를 끝내는지, 루트 종료가 오브젝트를 파괴하는지 방향을 명시한다.

---

## 16. StackingIdentity와 중첩

```text
StackingIdentity
├─ stackingKey
├─ equivalenceScope
├─ definitionId?
├─ sourceActorId?
├─ sourceOccurrenceId?
├─ targetBinding
└─ selectedModeKey?
```

### equivalenceScope

```text
same_definition
same_source_content
same_source_actor
same_source_occurrence
same_selected_mode
same_ruleset_tag
custom_registered
```

### StackingPolicy

```text
independent
replace_existing
refresh_duration
extend_duration
highest_potency_only
lowest_potency_only
merge_sources
unique_by_source
unique_by_target
prohibited
```

### independent

각 인스턴스가 독립적으로 기능하고 종료된다.

### replace_existing

새 효과가 기존 효과를 종료하고 자리를 차지한다.

### refresh_duration

기존 인스턴스를 유지하면서 지속시간만 새 기준으로 갱신한다.

### extend_duration

허용된 상한 안에서 남은 지속시간을 늘린다.

### highest_potency_only

모든 인스턴스를 보존하지만 가장 강한 인스턴스만 Capability를 제공한다.

강한 효과가 끝나면 다음 효과가 활성화된다.

### merge_sources

하나의 집계 효과가 여러 출처를 추적한다. 출처가 하나 사라져도 다른 출처가 남으면 효과를 유지한다.

중첩 결과는 파일 로드 순서나 적용 순서에 의존하지 않는다.

---

## 17. 상태 집계 표시

같은 공식 상태의 여러 EffectInstance가 존재할 수 있다.

권위 상태:

```text
Condition Effect A: 독 원천
Condition Effect B: 마법 원천
```

표시 상태:

```text
중독됨 아이콘 1개
출처 2개
가장 긴 또는 관련 지속시간 표시
```

```text
ConditionAggregateView
├─ conditionId
├─ targetId
├─ activeInstanceIds[]
├─ suppressedInstanceIds[]
├─ displayDuration
├─ visibleSources[]
└─ effectiveCapabilitiesSummary
```

표시 집계가 실제 인스턴스, 종료와 디스펠 대상을 대체하지 않는다.

DM은 필요할 때 출처별 인스턴스를 확인하고 개별 종료할 수 있다.

---

## 18. Suppression

```text
SuppressionSourceBinding
├─ suppressionSourceId
├─ sourceEffectInstanceId?
├─ sourceSceneObjectId?
├─ suppressionTags[]
├─ appliedAt
├─ policyId
└─ revision
```

EffectInstance는 여러 억제 출처를 동시에 가질 수 있다.

```text
suppressionSources.count > 0
→ effective state = suppressed
```

하나가 사라져도 다른 억제 출처가 남으면 재활성화하지 않는다.

### SuppressionPolicy

```text
SuppressionPolicy
├─ capabilityBehavior
├─ triggerBehavior
├─ durationBehavior
├─ concentrationBehavior
├─ ownedActorBehavior
├─ ownedObjectBehavior
├─ presentationBehavior
└─ reactivationPolicy
```

가능한 동작 예시:

```text
capabilityBehavior
├─ disable_all
├─ disable_tagged
└─ remain_active

durationBehavior
├─ duration_continues
├─ duration_pauses
└─ ruleset_specific

ownedObjectBehavior
├─ remain
├─ become_inert
├─ hide_presentation
└─ temporarily_remove
```

안티매직이 모든 마법 효과에 같은 방식으로 작동한다고 하드코딩하지 않는다. 각 효과 정의와 억제 규칙이 결합하여 결과를 결정한다.

---

## 19. 디스펠과 강제 종료

디스펠은 단순히 대상의 모든 마법 효과를 지우지 않는다.

```text
EffectQuery
├─ target or area
├─ effect tags
├─ source type
├─ dispellable policy
├─ visibility policy
└─ sorting policy
```

```text
DispelExecution
→ 적격 EffectInstance 조회
→ 자동 성공 또는 판정
→ 선택된 인스턴스에 EndEffectTransaction
→ cleanup
```

효과 정의는 다음을 명시할 수 있다.

```text
DispelPolicy
├─ dispellable
├─ requiredCheck
├─ minimumTier
├─ protectedTags[]
└─ onDispelRecipe?
```

DM 강제 종료는 규칙 판정과 구분되는 감사 로그를 남긴다.

```text
endReason: dm_override
reasonText
actorId
createdAt
```

---

## 20. EndEffectTransaction

효과 종료는 공통 트랜잭션으로 처리한다.

```text
EndEffectTransaction
├─ transactionId
├─ rootRequest
├─ targetEffectIds[]
├─ endReason
├─ revalidationSnapshot
├─ orderedCleanupSteps[]
├─ childTerminationPlan
├─ commitGroupId
└─ result
```

### 기본 순서

```text
1. 종료 요청과 조건 재검증
2. 인스턴스를 Ending으로 잠금
3. 신규 사용과 트리거 후보에서 제외
4. 자식 효과 종료 계획 확정
5. Capability 해제
6. Trigger 등록 해제
7. 형태·조종권·자원 오버라이드 복구
8. 소유 Actor와 SceneObject 정리
9. 집중·부모·자식 링크 제거
10. Ended 상태와 종료 기록 확정
11. OngoingEffectEnded 사건 생성
12. 표현 정리
```

정확한 순서는 효과 종류별 cleanup profile이 세부 조정할 수 있지만 핵심 안전 단계는 우회할 수 없다.

### 멱등성

같은 효과에 종료 요청이 여러 번 도착하면 첫 번째 확정 결과를 반환한다.

이미 종료된 효과에 cleanup을 다시 실행하지 않는다.

### 정리 실패

한 정리 단계가 실패했다고 인스턴스를 무조건 Active로 되돌리지 않는다.

```text
FailedCleanup
→ 규칙 기여 차단 유지
→ 복구 작업 큐
→ DM 진단 표시
```

부분 활성 상태를 숨기지 않는다.

---

## 21. CleanupPlan

```text
CleanupPlan
├─ revokeCapabilities[]
├─ unregisterTriggers[]
├─ endChildEffectsPolicy
├─ ownedActorCleanup[]
├─ ownedSceneObjectCleanup[]
├─ formReversion?
├─ controllerRestoration?
├─ resourceCleanup[]
├─ reservationCleanup[]
├─ presentationCleanup[]
└─ finalEventRecipe?
```

### 변신

```text
Effect 종료
→ ActiveFormLayer 제거
→ 원래 Capability 재구성
→ 초과 피해·위치·상태 정책 적용
```

원본 캐릭터 데이터를 백업본으로 덮어쓰지 않는다.

### 조종권 전환

```text
Effect 종료
→ ControllerBinding 검증
→ 원래 조종권 복원
→ 대상 Body 상태 처리
```

### 소환

```text
Effect 종료
→ 소환 Actor 행동 잠금
→ 진행 중 실행 안전 종료
→ 장면 제거 또는 독립화
→ 소유 링크 제거
```

### 지속 영역

```text
Effect 종료
→ 신규 진입 트리거 차단
→ 보류 중인 합법적 해결 처리
→ SceneEffect와 RuleSceneObject 제거
```

---

## 22. 대표 사례

### 22.1 턴 시작까지 AC 증가

```text
EffectInstance: temporary_ac_bonus
├─ target: caster
├─ granted capability: AC modifier
└─ duration
   ├─ kind: until_turn_boundary
   ├─ actor: caster
   └─ boundary: next turn start
```

`TurnStarted(caster)`에서 만료 후보가 되고 종료 트랜잭션으로 AC 기여를 제거한다.

### 22.2 반복 내성이 있는 상태

```text
Condition EffectInstance
├─ condition: restrained-like condition
├─ duration: until_successful_save
└─ trigger
   └─ TurnEnded(target)
      → repeat save recipe
```

성공 시 해당 출처 인스턴스만 종료한다.

### 22.3 다중 대상 집중 버프

```text
Concentration Root
├─ Target A Buff
├─ Target B Buff
└─ Target C Buff
```

한 대상의 효과가 개별 디스펠되어도 루트 집중은 유지될 수 있다.

집중 실패 시 남은 모든 자식 버프를 종료한다.

### 22.4 마녀의 번개 연결

```text
SustainedLink EffectInstance
├─ source: caster
├─ target: enemy
├─ concentrationLink
├─ granted bonus action
└─ endConditions
   ├─ concentration ended
   ├─ target out of range
   ├─ total cover policy
   └─ target invalid
```

거리와 엄폐는 관련 이동·장면 변경 사건에서 재검증한다.

### 22.5 투명화

```text
Invisibility EffectInstance
├─ granted visibility and targeting overrides
└─ endConditions
   ├─ duration expired
   ├─ concentration ended
   ├─ attack made
   └─ spell cast
```

공격 선언 또는 주문 시전 사건에 연결된 종료 조건으로 처리한다.

### 22.6 폴리모프

```text
Form EffectInstance
├─ form layer ownership
├─ concentrationLink
├─ form HP bindings
└─ cleanupPlan: revert form
```

형태 HP 0, 집중 종료와 명시적 종료가 모두 같은 종료 트랜잭션으로 형태 복구를 수행한다.

### 22.7 소환 주문

```text
Concentration Root
├─ Summon Controller Effect
└─ owned Actor
```

집중 종료 시 소환 Actor를 즉시 무효화하고 정해진 제거 연출을 시작한다.

### 22.8 지속 영역

```text
Persistent Area Effect
├─ anchor and shape
├─ RuleSceneObject
├─ entered / turn-start triggers
├─ duration
└─ concentrationLink?
```

효과 종료 시 공간 인덱스, 트리거와 장면 표시를 함께 정리한다.

### 22.9 안티매직 억제

```text
마법 EffectInstance
→ 안티매직 영역 진입
→ suppressionSource 추가
→ capability와 trigger 비활성
→ duration policy에 따라 시간 유지 또는 정지

영역 이탈
→ suppressionSource 제거
→ 다른 억제 출처 없음
→ 재활성화
```

효과 인스턴스를 삭제하거나 새로 생성하지 않는다.

### 22.10 여러 출처의 같은 상태

```text
독에 의한 중독 Effect A
주문에 의한 중독 Effect B
```

UI는 `중독됨` 하나로 표시할 수 있지만, 독 효과가 끝나도 주문 효과가 남으면 상태는 유지된다.

---

## 23. 가시성과 숨겨진 효과

```text
EffectVisibilityPolicy
├─ visibleToOwner
├─ visibleToTarget
├─ visibleToAllies
├─ visibleToEnemies
├─ visibleToDM
├─ revealDefinition
├─ revealSource
├─ revealDuration
└─ revealMechanicalDetails
```

저주, 비밀 표식과 DM 전용 장면 효과는 존재 자체나 상세 내용을 숨길 수 있다.

클라이언트에 숨겨진 EffectInstance 전체를 보내고 UI에서만 숨기지 않는다.

서버가 관찰자별 공개 뷰를 생성한다.

---

## 24. DM 조작

DM은 권위 상태를 직접 데이터 편집하지 않고 명시적 명령을 사용한다.

```text
EndEffectCommand
ExtendDurationCommand
ReplaceDurationCommand
SuppressEffectCommand
UnsuppressEffectCommand
TransferEffectSourceCommand
RepairEffectCommand
```

각 명령은 다음을 기록한다.

- 실행 DM
- 대상 인스턴스
- 이전 상태와 새 상태
- 이유
- 시간
- 관련 세션 로그

DM 조작도 Capability 재구성, 인덱스와 정리 규약을 우회하지 않는다.

---

## 25. 저장과 재접속

활성 EffectInstance에 저장하는 값:

- 정의 ID와 고정된 콘텐츠 버전
- 출처 실행과 Actor
- 대상과 앵커
- 고정 파라미터
- 지속 상태와 다음 평가 경계
- 집중 채널 링크
- 부모·자식·소유 오브젝트 링크
- 억제 출처
- 라이프사이클 상태와 revision

재구성 가능한 캐시는 저장 원본으로 삼지 않는다.

- 컴파일된 최종 Capability Set
- 이벤트 인덱스
- 표시용 상태 집계
- 다음 만료 큐의 내부 노드

재접속 흐름:

```text
EffectInstance 로드
→ 정의 버전 확인
→ 대상·소유 오브젝트 연결 복구
→ Capability와 Trigger 재컴파일
→ 집중 그래프 검증
→ 만료·이벤트 인덱스 재등록
→ 표시 뷰 재생성
```

정의 버전을 찾을 수 없거나 마이그레이션에 실패하면 효과를 조용히 삭제하지 않고 안전 억제 상태와 진단 항목으로 전환한다.

---

## 26. 성능

매 프레임 모든 효과의 지속시간과 조건을 검사하지 않는다.

초기 인덱스:

```text
EffectIndex
├─ byTargetId
├─ bySourceActorId
├─ byOwnerActorId
├─ byDefinitionId
├─ byStackingKey
├─ byConcentrationOwner
├─ byParentEffectId
├─ bySceneId
├─ byTriggerEventType
├─ byTurnBoundaryActor
└─ byGameTimeExpiration
```

처리 예시:

```text
TurnEnded 발생
→ 해당 Actor의 turn-boundary 및 repeat-save 인덱스 조회
→ 후보만 재검증
```

```text
Actor 이동
→ 공간 인덱스로 거리·영역 의존 효과 후보 조회
→ 관련 link와 aura만 재검증
```

```text
게임 시간 진행
→ 만료 우선순위 큐의 도달 항목만 처리
```

---

## 27. 서버 검증과 안전

서버는 다음을 검증한다.

- EffectInstance 생성 요청이 유효한 EffectRecipe에서 왔는가
- 대상, 면역과 중첩 정책이 유효한가
- 집중 채널과 소유 관계가 일치하는가
- 지속시간 경계와 게임 시간이 권위 상태와 일치하는가
- 반복 내성과 Trigger가 중복 실행되지 않았는가
- 종료 조건이 실제로 충족되었는가
- 억제 출처가 존재하고 아직 유효한가
- 부모·자식 그래프에 순환이 없는가
- cleanup이 허용된 오브젝트만 변경하는가
- 종료와 재활성화 요청이 revision에 맞는가

안전 상한:

- 한 루트 효과가 소유할 수 있는 자식 수
- 한 Actor에 적용 가능한 활성 인스턴스 수
- 한 종료 트랜잭션의 cascade 깊이
- 한 사건에서 실행 가능한 반복 Trigger 수
- 숨겨진 효과의 클라이언트 공개 범위

---

## 28. 테스트 기준

필수 테스트:

1. 같은 상태의 두 출처 중 하나가 끝나도 다른 출처가 남으면 상태가 유지된다.
2. `highest_potency_only`에서 강한 효과 종료 후 약한 효과가 다시 활성화된다.
3. 다음 턴 시작까지 효과가 정확한 Actor의 경계에서 종료된다.
4. 추가 턴과 턴 건너뛰기에서 duration occurrence policy가 일관되게 작동한다.
5. 게임 시간 효과가 서버 벽시계가 아니라 캠페인 시간으로 만료된다.
6. 반복 내성이 한 턴에 중복 실행되지 않는다.
7. 집중 시작 시 기존 집중 종료와 새 효과 연결이 원자적으로 처리된다.
8. 집중 실패 시 모든 연결 자식 효과가 정리된다.
9. 개별 자식 효과 디스펠이 불필요하게 집중 루트를 끝내지 않는다.
10. 안티매직 억제가 효과를 삭제하지 않고 영역 이탈 후 재활성화한다.
11. 여러 억제 출처 중 하나만 사라졌을 때 효과가 재활성화되지 않는다.
12. 종료 cleanup이 중복 요청에서도 한 번만 적용된다.
13. 변신 종료가 원본 캐릭터 데이터를 덮어쓰지 않고 형태 레이어만 제거한다.
14. 소환 종료 중 진행 중 행동이 안전하게 무효화된다.
15. 지속 영역 종료 시 공간 인덱스와 Trigger가 함께 제거된다.
16. 숨겨진 효과가 비인가 클라이언트에 노출되지 않는다.
17. 재접속 후 지속시간, 집중, 억제와 반복 내성 예약이 복구된다.
18. 정의 버전 누락 시 효과가 조용히 삭제되지 않고 진단 가능한 안전 상태가 된다.
19. 부모·자식 순환 데이터가 콘텐츠 검증에서 거부된다.
20. 강제 DM 종료가 감사 로그와 정상 cleanup을 남긴다.

---

## 29. 명시적 비목표

- 상태를 Actor의 문자열 배열로 저장하지 않는다.
- 모든 지속 효과를 공식 Condition으로 만들지 않는다.
- 지속시간을 실제 초 단위 프레임 카운터 하나로 처리하지 않는다.
- 효과마다 별도 Heartbeat 또는 턴 리스너를 만들지 않는다.
- 집중을 주문마다 독립 불리언으로 저장하지 않는다.
- 안티매직을 효과 삭제로 구현하지 않는다.
- UI 상태 아이콘 집계를 권위 상태로 사용하지 않는다.
- 효과 종료 시 Character 데이터 스냅샷 전체를 복원하지 않는다.
- 콘텐츠 갱신 때문에 활성 효과 의미를 세션 중 몰래 변경하지 않는다.
- 클라이언트가 효과 만료, 집중 실패와 cleanup 결과를 결정하지 않는다.

---

## 30. 다음 단계

상태와 지속 효과 수명주기가 완성되면 다음은 실제 공격의 원본 데이터를 정의한다.

```text
WeaponDefinition
AttackProfile
ItemDefinition
EquipmentState
WeaponMasteryProperty
```

다음 문서에서는 다음을 다룬다.

1. 무기의 피해 주사위, 피해 유형, 사거리와 속성
2. 근접·원거리·투척·탄약과 장전
3. 무기 장착과 손 점유
4. 공격 능력치와 숙련 선택
5. 양손·다용도·가벼운 무기 같은 속성
6. Weapon Mastery와 공격 후 효과
7. 아이템이 제공하는 ActionCapability와 주문 시전
8. 몬스터 자연 무기와 캐릭터 장비 공격의 공통 AttackProfile
9. 공격 애니메이션·VFX와 권위 규칙 데이터 분리
10. 무기 공격에서 EffectRecipe를 생성하는 절차