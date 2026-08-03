# 22. EffectRecipe와 효과 해결·확정 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`11. 공통 실행 계약`](../rules-content-execution-and-spell-contract.md)
  - [`17. 주문 대상 지정·영역·공간 질의 모델`](../../systems/rules/spell-targeting-area-and-spatial-query-model.md)
  - [`18. RuleRecipe 사례`](../../systems/rules/rule-recipe-examples-magic-missile-and-witch-bolt.md)
  - [`19. 트리거와 다른 턴 실행 모델`](../../systems/rules/feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](../../systems/rules/active-feature-and-action-container-execution-model.md)
  - [`21. 패시브 특성 모델`](../passive-modifier-and-rule-override-model.md)
  - [`ADR-0028`](../../decisions/ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)

## 1. 문서 목적

이 문서는 주문, 무기 공격, 재주, 직업 특성, 종 특성, 아이템과 몬스터 능력이 실제 게임 상태를 변경하는 공통 절차를 정의한다.

대상 지정, 행동 비용과 자원 결제는 앞선 문서에서 다룬다.

이 문서가 다루는 범위는 다음과 같다.

- 공격 굴림, 내성 굴림과 능력 판정
- 성공, 실패, 치명타와 기타 결과 분기
- 피해, 회복과 임시 HP
- 다중 피해 유형과 추가 피해
- 여러 대상, 여러 투사체와 동시 해결
- 상태 적용, 제거, 중첩과 반복 내성
- 강제 이동, 순간이동과 영역 진입·퇴장
- 지속 효과와 장면 오브젝트 생성
- 반응, 패시브와 규칙 오버라이드의 개입
- 집중, HP 0과 결과 후속 사건
- 서버 권위 확정, 취소, 실패와 재접속

핵심 원칙은 다음과 같다.

```text
효과 정의
→ 즉시 영구 상태 변경 X

효과 정의
→ 굴림과 결과 계산
→ PendingEffect 생성
→ 반응과 규칙 수정
→ CommitGroup 확정
→ 영구 상태 변경 O
```

---

## 2. 전체 구조

```text
RuleExecution
├─ RuleExecutionContext
├─ ResolvedTargetingPlan
├─ reservedCosts
├─ EffectRecipe
├─ RollRecord[]
├─ ResolutionOutcome[]
├─ PendingEffect[]
├─ CommitGroup[]
└─ CommitResult
```

실행 흐름:

```text
1. 레시피, 콘텐츠와 규칙 세트 버전 고정
2. 입력 바인딩과 대상 재검증
3. 레시피 그래프 실행
4. 굴림 기록과 결과 생성
5. PendingEffect 생성
6. 패시브·추가 효과·규칙 오버라이드 결합
7. 적용 직전 TimingWindow 해결
8. CommitGroup 단위로 최종 재검증
9. 권위 상태 확정
10. 사후 RuleEvent와 표현 생성
```

효과의 시각 연출은 확정 결과를 표현한다. VFX가 피해 판정과 상태 변경의 권위 원본이 되지 않는다.

---

## 3. EffectRecipe 정의

```text
EffectRecipe
├─ recipeId
├─ schemaVersion
├─ rulesetId
├─ inputBindings[]
├─ nodes[]
├─ outputBindings[]
├─ commitPolicy
├─ handlerId?
└─ diagnosticsProfile
```

### inputBindings

대상 지정, 시전 수준, 선택한 모드, 공격 무기와 사용 자원을 참조한다.

예시:

```text
caster
primaryTarget
affectedTargets
selectedPoint
selectedDirection
castLevel
selectedDamageType
weaponInstance
featureRank
allocatedEffectUnits
```

### nodes

타입 있는 실행 노드다. 노드 ID와 입력·출력 바인딩을 가진다.

### outputBindings

후속 노드, 고급 연산, 로그와 지속 효과가 참조할 결과를 공개한다.

### handlerId

공통 노드로 표현할 수 없는 제한된 규칙만 처리한다. 전용 처리기도 PendingEffect와 CommitGroup을 우회하지 않는다.

---

## 4. 레시피 그래프 규칙

EffectRecipe는 검증 가능한 유한 그래프다.

허용하는 제어 노드:

```text
Sequence
Branch
ForEach
BoundedRepeat
SelectFirstValid
SimultaneousGroup
ReferenceSubRecipe
```

### Sequence

순서대로 노드를 실행한다.

### Branch

타입 있는 조건과 `ResolutionOutcome`을 기준으로 경로를 선택한다.

### ForEach

검증된 대상 집합이나 효과 단위를 순회한다.

### BoundedRepeat

명시된 최대 횟수 안에서만 반복한다.

### SimultaneousGroup

여러 효과를 같은 동시 해결 그룹에 넣는다.

### ReferenceSubRecipe

등록된 공통 하위 레시피를 참조한다.

금지 사항:

- 임의 Luau 코드 문자열 실행
- 제한 없는 반복
- 런타임에 임의 노드 타입 생성
- 콘텐츠 설명 텍스트 파싱
- 클라이언트가 지정한 분기 결과 신뢰

콘텐츠 로딩 시 다음을 검사한다.

- 모든 노드 타입이 등록되어 있는가
- 입력과 출력 타입이 일치하는가
- 참조 바인딩이 존재하는가
- 모든 반복에 안전 상한이 있는가
- 도달 불가능한 노드와 순환이 없는가
- 생성 가능한 효과 수가 제한 안에 있는가
- handler가 허용된 확장점만 사용하는가

---

## 5. 초기 노드 카탈로그

### 5.1 굴림 노드

```text
RollAttack
RollSavingThrow
RollAbilityCheck
RollDamage
RollHealing
RollTable
```

### 5.2 흐름과 결과 노드

```text
EvaluatePredicate
MapOutcome
Branch
ForEach
SimultaneousGroup
SelectValue
CalculateExpression
```

### 5.3 효과 생성 노드

```text
CreateDamage
CreateHealing
CreateTemporaryHitPoints
ApplyCondition
RemoveCondition
CreateForcedMovement
CreateTeleport
CreateResourceChange
CreateOngoingEffect
EndOngoingEffect
CreateRuleSceneObject
DestroyRuleSceneObject
```

### 5.4 실행 수정과 판정 노드

```text
OpenTimingWindow
RequestDMAdjudication
InvokeAdvancedOperation
ReferenceSubRecipe
```

노드 이름은 특정 주문 이름이 아니라 규칙 의미를 나타낸다.

---

## 6. 타입 있는 값과 표현식

레시피의 수치는 등록된 표현식으로 계산한다.

```text
ValueExpression
├─ Constant
├─ BoundValue
├─ DiceExpression
├─ AbilityModifier
├─ ProficiencyBonus
├─ CharacterLevel
├─ ClassLevel
├─ FeatureRank
├─ CastLevel
├─ TargetCount
├─ ResourceValue
├─ Add
├─ Subtract
├─ Multiply
├─ DivideRounded
├─ Minimum
├─ Maximum
└─ Clamp
```

예시:

```text
2d6 + ability_modifier(charisma)

baseDice + dicePerCastLevel × max(0, castLevel - baseLevel)

max(1, proficiencyBonus)
```

표현식의 입력은 서버가 제공한 바인딩만 참조한다.

표현식은 타입과 허용 범위를 가진다.

- 거리 값
- 정수
- 피해량
- 굴림 수정치
- 대상 수
- 지속시간
- 자원량

거리와 일반 정수를 같은 무형 숫자로 취급하지 않는다.

---

## 7. 굴림 기록

모든 주사위 결과는 `RollRecord`로 남긴다.

```text
RollRecord
├─ rollRecordId
├─ rollKind
├─ sourceExecutionId
├─ rollerActorId
├─ targetId?
├─ diceExpression
├─ rawDice[]
├─ selectedDice[]
├─ modifiers[]
├─ rollMode
├─ total
├─ visibilityPolicy
├─ rulesetSnapshot
└─ createdAt
```

### rollKind

```text
attack
saving_throw
ability_check
damage
healing
table
custom_registered
```

### rollMode

이점, 불리점과 기타 굴림 방식은 `ContextModifierCapability`와 `RuleOverrideCapability`를 수집하여 결정한다.

클라이언트는 최종 total이나 성공 여부를 제출하지 않는다.

### 가시성

플레이어 공개, DM 전용, 당사자 전용과 결과만 공개 같은 정책을 지원한다.

반응 창은 해당 시점에 공개할 수 있는 RollRecord 필드만 보여준다.

---

## 8. RollScope

굴림은 레시피 노드마다 공유 범위를 명시한다.

```text
RollScope
├─ per_execution
├─ per_affected_set
├─ per_target
├─ per_effect_unit
└─ per_component
```

### per_execution

실행 전체가 하나의 굴림을 공유한다.

### per_affected_set

특정 대상 집합이 하나의 굴림을 공유한다.

### per_target

대상마다 별도 굴림을 만든다.

### per_effect_unit

투사체, 광선 또는 개별 공격 단위마다 굴린다.

### per_component

여러 피해 구성요소가 각각 별도 굴림을 가진다.

콘텐츠는 수치 규칙에 따라 정확한 scope를 선언한다. 엔진이 주문 이름으로 추측하지 않는다.

---

## 9. ResolutionOutcome

굴림 결과를 단순 불리언으로만 저장하지 않는다.

```text
ResolutionOutcome
├─ outcomeId
├─ outcomeKind
├─ sourceNodeId
├─ rollRecordIds[]
├─ actorId
├─ targetId?
├─ successLevel
├─ criticalState
├─ margin?
├─ tags[]
└─ ruleSnapshot
```

### outcomeKind

```text
attack
saving_throw
ability_check
contest
automatic
adjudicated
```

### successLevel

규칙 세트에 따라 다음과 같은 값을 사용할 수 있다.

```text
critical_failure
failure
partial_success
success
critical_success
```

기본 D&D 공격과 내성에서 사용하지 않는 단계는 생성하지 않는다.

### criticalState

치명타 여부는 별도 타입으로 유지한다.

치명타가 어떤 피해 주사위에 적용되는지는 `DamageComponent.criticalPolicy`가 결정한다.

---

## 10. OutcomeMap

공격·내성 결과에 따라 효과를 연결한다.

```text
OutcomeMap
├─ onHit[]
├─ onMiss[]
├─ onCriticalHit[]
├─ onSaveSuccess[]
├─ onSaveFailure[]
├─ onPartialSuccess[]
└─ always[]
```

예시: 내성 성공 시 절반 피해

```text
RollSavingThrow
→ MapOutcome
   ├─ failure: damageMultiplier = 1
   └─ success: damageMultiplier = 0.5 with ruleset rounding
→ CreateDamage
```

예시: 명중 시 피해와 상태

```text
RollAttack
→ Branch on_hit
   ├─ CreateDamage
   └─ ApplyCondition
```

공격이 빗나갔을 때도 발생하는 효과가 있다면 `always` 또는 `onMiss`에 명시한다.

---

## 11. PendingEffect 공통 계약

```text
PendingEffect
├─ pendingEffectId
├─ effectKind
├─ sourceExecutionId
├─ sourceNodeId
├─ sourceContentId
├─ sourceActorId
├─ targetBinding
├─ payload
├─ tags[]
├─ resolutionState
├─ commitGroupId
├─ revisionSnapshot
└─ diagnostics[]
```

### resolutionState

```text
created
collecting_modifiers
awaiting_response
ready_to_commit
suppressed
invalidated
committed
failed
```

PendingEffect는 권위 상태 변화가 아니다.

HP, 위치, 상태, 자원과 장면 객체는 `committed`가 되기 전까지 바뀌지 않는다.

---

## 12. 피해 모델

```text
PendingDamage
├─ applicationId
├─ targetId
├─ components[]
├─ rollRecordIds[]
├─ attackOutcomeId?
├─ saveOutcomeId?
├─ simultaneousGroupId?
├─ damagePipelineId
├─ applicationTags[]
└─ responseWindowPolicy
```

### DamageComponent

```text
DamageComponent
├─ componentId
├─ damageType
├─ baseAmount
├─ amountRollRecordIds[]
├─ sourceBinding
├─ sourceTags[]
├─ criticalPolicy
├─ saveAdjustmentPolicy
├─ responsePolicy
└─ diagnosticsKey
```

### applicationId

하나의 피해 적용 사건을 식별한다.

같은 명중에서 발생하는 검격 피해와 화염 피해는 하나의 `applicationId` 안에 서로 다른 구성요소로 존재할 수 있다.

### 별도 피해 적용

독립된 투사체, 별도 공격과 지속 피해 틱은 다른 `applicationId`를 가진다.

동시에 발생하더라도 각 적용 사건의 정체성을 잃지 않는다.

---

## 13. 다중 피해 유형

예시: 무기 피해와 추가 화염 피해

```text
PendingDamage
└─ components
   ├─ slashing: weapon damage
   └─ fire: additional damage
```

대상은 각 구성요소에 서로 다른 면역, 저항, 취약성과 감소 정책을 가질 수 있다.

엔진은 먼저 전체 피해를 하나의 숫자로 합친 뒤 피해 유형을 잃지 않는다.

```text
잘못된 처리
8 검격 + 4 화염
→ 12 피해
→ 저항 계산

올바른 처리
8 검격
→ 검격 대응 계산

4 화염
→ 화염 대응 계산

→ 최종 적용량 합산
```

다만 어떤 감소가 구성요소별인지, 적용 사건 전체인지, 공격 전체인지 규칙에 따라 다를 수 있으므로 `responsePolicy`와 규칙 파이프라인이 범위를 명시한다.

---

## 14. DamageResolutionPipeline

피해 계산 순서는 규칙 세트가 소유한다.

개념 단계:

```text
1. base_component_amounts
2. critical_adjustments
3. source_side_additions_and_replacements
4. save_or_outcome_adjustments
5. damage_type_substitution
6. target_immunity_resistance_vulnerability
7. flat_or_dice_reductions
8. minimum_and_prevention_rules
9. before_apply_timing_window
10. temporary_hit_points
11. current_hit_points
12. overflow_and_zero_hp_rules
13. after_apply_events
```

정확한 순서와 반올림은 `dnd5e-2024` 규칙 팩이 정의한다.

콘텐츠는 파이프라인의 허용된 지점에 기여한다.

### source-side 기여

- 추가 피해
- 피해 주사위 교체
- 피해 유형 변경
- 치명타 확장

### target-side 기여

- 면역
- 저항
- 취약성
- 피해 감소
- 피해 방지

### TimingWindow

피해 적용 직전 사용하는 반응은 HP가 바뀌기 전에 PendingDamage를 수정한다.

피해를 먼저 적용하고 회복을 추가하는 방식으로 피해 감소를 흉내 내지 않는다.

---

## 15. 추가 피해와 증강

암습형 추가 피해, 강타형 자원 소비와 무기 특수 효과는 원래 공격의 PendingDamage에 새 구성요소를 추가할 수 있다.

```text
AttackHitConfirmed
→ 적격 TriggerCapability 또는 ActionAugmentCapability
→ 사용 여부와 비용 결정
→ AddDamageComponent
→ 같은 applicationId에 결합
→ 피해 해결 계속
```

별도 피해 적용이어야 하는 규칙은 새 `applicationId`를 생성한다.

콘텐츠 정의가 결합 정책을 선언한다.

```text
DamageMergePolicy
├─ same_application
├─ separate_application
├─ same_simultaneous_group
└─ sequential_after
```

이 구분은 저항, 집중, HP 0과 후속 트리거에 영향을 줄 수 있으므로 로그 표현만의 문제가 아니다.

---

## 16. 치명타

치명타는 피해 총량을 무조건 두 배로 곱하지 않는다.

각 DamageComponent가 치명타 정책을 가진다.

```text
CriticalPolicy
├─ unaffected
├─ duplicate_eligible_dice
├─ maximize_eligible_dice
├─ add_registered_dice
└─ custom_ruleset_policy
```

주사위와 고정 보너스, 추가 피해 중 무엇이 치명타 영향을 받는지는 콘텐츠와 규칙 세트가 결정한다.

`RollDamage`는 원래 주사위 기록과 치명타로 추가된 주사위 기록을 구분한다.

---

## 17. 동시 피해와 순차 피해

### 17.1 SimultaneousGroup

```text
SimultaneousResolutionGroup
├─ simultaneousGroupId
├─ memberEffectIds[]
├─ visibilityPolicy
├─ reactionGroupingPolicy
├─ commitGroupId
└─ postCommitEventPolicy
```

같은 그룹은 중간 HP 상태를 외부 실행에 노출하지 않고 함께 확정한다.

### 17.2 매직 미사일형 투사체

```text
projectile 1 → PendingDamage A
projectile 2 → PendingDamage B
projectile 3 → PendingDamage C

A, B, C
→ 같은 simultaneousGroupId
→ 각 applicationId는 유지
```

대상 배분, 반응과 투사체별 로그를 유지하면서 동시 명중을 표현한다.

### 17.3 순차 공격

공격 행동의 첫 공격과 두 번째 공격은 서로 다른 CommitGroup이다.

첫 공격이 확정된 뒤 두 번째 공격이 취소되거나 무효화되어도 첫 공격을 롤백하지 않는다.

### 17.4 광역 효과

여러 대상의 결과는 같은 실행에서 생성되지만 대상별 내성, 면역과 피해 반응을 가진다.

콘텐츠와 규칙 세트가 다음 중 하나를 선택한다.

```text
대상별 CommitGroup
전체 AffectedSet CommitGroup
명시적 SimultaneousGroup
```

기본값을 주문 이름으로 하드코딩하지 않는다.

---

## 18. CommitGroup

```text
CommitGroup
├─ commitGroupId
├─ sourceExecutionId
├─ atomicScope
├─ pendingEffectIds[]
├─ orderingPolicy
├─ revalidationPolicy
├─ failurePolicy
├─ idempotencyKey
├─ state
└─ commitResult?
```

### atomicScope

```text
single_effect
effect_unit
target_resolution
simultaneous_group
execution_resolution
```

### orderingPolicy

그룹 안의 상태 적용 순서가 의미 있을 때 타입 있는 정책을 사용한다.

예시:

```text
damage_then_condition
movement_then_area_entry
resource_then_ongoing_effect
all_state_visible_after_commit
```

### revalidationPolicy

확정 직전 무엇을 다시 검사할지 정의한다.

- 대상 존재
- 대상 revision
- 위치와 사거리
- HP와 상태
- 자원 예약
- 장면 객체 상태
- 부모 실행 유효성

### failurePolicy

```text
rollback_group
suppress_invalid_member
fail_execution
request_dm_adjudication
```

그룹의 일부 실패를 조용히 무시하지 않는다.

### 멱등성

같은 `idempotencyKey`의 그룹은 한 번만 확정된다.

네트워크 재시도, 재접속과 서버 중복 요청으로 피해가 두 번 적용되지 않게 한다.

---

## 19. 회복

```text
PendingHealing
├─ applicationId
├─ targetId
├─ baseAmount
├─ rollRecordIds[]
├─ healingType?
├─ sourceTags[]
├─ healingPipelineId
└─ responseWindowPolicy
```

회복 파이프라인은 다음을 처리한다.

- 회복 가능 대상인지
- 회복 금지 또는 감소 효과
- 회복량 증감
- 최대 HP 제한
- HP 0 상태와 특수 규칙
- 실제 회복량과 초과량 기록

```text
HealingCommitResult
├─ requestedAmount
├─ modifiedAmount
├─ appliedAmount
├─ overflowAmount
├─ previousHitPoints
└─ finalHitPoints
```

회복량 10을 굴렸더라도 최대 HP 제한으로 실제 4만 회복했다면 두 값을 모두 기록한다.

---

## 20. 임시 HP

임시 HP는 회복과 다른 효과다.

```text
PendingTemporaryHitPoints
├─ targetId
├─ amount
├─ sourceBinding
├─ durationPolicy?
├─ replacementPolicy
└─ choicePolicy
```

초기 정책 후보:

```text
replace_if_higher
replace_always
keep_existing
prompt_if_choice_required
ruleset_default
```

임시 HP끼리 일반 덧셈을 하지 않는다. 정확한 교체 규칙은 규칙 세트가 정의한다.

피해 적용 시 임시 HP와 현재 HP에 적용된 양을 별도로 기록한다.

---

## 21. 상태 적용과 제거

```text
PendingConditionChange
├─ applicationId
├─ targetId
├─ conditionDefinitionId
├─ operation
├─ sourceBinding
├─ durationPolicy
├─ endConditions[]
├─ repeatSavePolicy?
├─ stackingPolicy
├─ immunityCheckPolicy
└─ parameters
```

### operation

```text
apply
remove
suppress
resume
refresh_duration
modify_stack
```

### 상태 정의

`ConditionDefinition`은 다음을 가진다.

```text
ConditionDefinition
├─ conditionId
├─ tags[]
├─ grantedCapabilities[]
├─ prohibitedCapabilities[]
├─ stackingPolicy
├─ defaultDurationPolicy
├─ immunityTags[]
└─ presentationProfileId
```

상태는 단순한 이름 목록이 아니라 Capability와 규칙 제한을 제공하는 지속 효과다.

### 면역

상태 면역은 적용 직전에 검사한다.

면역 때문에 적용되지 않은 상태도 진단과 로그에는 남길 수 있다.

### 중첩

```text
ignore_duplicate
refresh_duration
replace_if_stronger
independent_instances
increase_stack_count
prohibited
```

정확한 정책은 상태 정의가 소유한다.

---

## 22. 지속시간과 반복 내성

```text
DurationPolicy
├─ durationKind
├─ amount?
├─ anchorTurnBinding?
├─ expiresAtPhase?
├─ concentrationBinding?
└─ worldTimePolicy?
```

### durationKind

```text
instantaneous
until_start_of_turn
until_end_of_turn
rounds
minutes
hours
until_rest
until_condition
permanent_until_removed
concentration
```

### 반복 내성

```text
RepeatSavePolicy
├─ timing
├─ saveDefinition
├─ successEffect
├─ failureEffect
├─ maximumAttempts?
└─ ownerBinding
```

`timing` 예시:

```text
start_of_target_turn
end_of_target_turn
when_damaged
when_action_spent
manual_dm_prompt
```

반복 내성은 지속 효과가 `TriggerCapability`를 제공하는 방식으로 실행한다.

상태 시스템이 별도 턴 폴링 루프를 만들지 않는다.

---

## 23. 강제 이동

```text
PendingMovement
├─ applicationId
├─ movementKind
├─ targetId
├─ sourceBinding
├─ directionBinding?
├─ destinationBinding?
├─ requestedDistance?
├─ distancePolicy
├─ collisionPolicy
├─ terrainPolicy
├─ occupancyPolicy
├─ triggerPolicy
├─ fallPolicy
└─ pathResult
```

### movementKind

```text
push
pull
slide
commanded_movement
reposition
teleport
swap_positions
```

### 일반 이동과 분리

강제 이동은 대상의 일반 이동 예산을 자동 소비하지 않는다.

어려운 지형, 기회 공격과 이동 제한이 적용되는지는 `movementKind`, 규칙 세트와 오버라이드가 결정한다.

### 경로 계산

밀기와 끌기는 시작점과 방향에서 규칙용 경로를 계산한다.

- 의미 충돌체
- 점유 공간
- 높이 차이
- 벽과 문
- 낭떠러지
- 금지 영역

시각 MeshPart의 장식 표면만으로 경로를 결정하지 않는다.

### 부분 이동

요청 거리 전체를 이동할 수 없을 때 정책을 명시한다.

```text
stop_at_first_blocker
fail_entire_movement
move_to_last_valid_point
apply_collision_consequence
request_dm_adjudication
```

### 이동 사건

확정된 이동 경로로 다음 사건을 생성할 수 있다.

- 영역 진입
- 영역 퇴장
- 도달거리 변화
- 추락 시작
- 이동 완료

보류 경로만으로 사건을 미리 확정하지 않는다.

---

## 24. 순간이동

순간이동은 일반 강제 이동과 같은 `PendingMovement` 계열을 사용하지만 경로 통과 판정이 다르다.

```text
movementKind: teleport
├─ destination validation
├─ occupancy validation
├─ line or sight requirements if any
├─ origin exit event policy
├─ destination entry event policy
└─ failure destination policy
```

순간이동 중간 경로의 영역과 장애물은 일반적으로 통과하지 않지만, 출발과 도착 사건은 규칙 정책에 따라 생성할 수 있다.

다른 장면으로 이동하는 경우 `TransitionEntities` 고급 연산을 사용한다.

---

## 25. 자원 변화

효과가 대상의 자원, 충전, 히트 다이스나 기타 풀을 바꿀 수 있다.

```text
PendingResourceChange
├─ resourcePoolInstanceId
├─ operation
├─ amount
├─ boundsPolicy
├─ sourceBinding
└─ commitPolicy
```

### operation

```text
spend
restore
set
increase_maximum_temporarily
decrease_maximum_temporarily
transfer
```

시전 비용처럼 실행 전에 예약된 비용과 효과 결과로 발생하는 자원 변화는 구분한다.

자원 이동과 효과 적용을 반드시 함께 확정해야 한다면 같은 CommitGroup에 넣는다.

---

## 26. 지속 효과 생성

```text
PendingOngoingEffectCreation
├─ effectDefinitionId
├─ ownerScope
├─ sourceBinding
├─ targetsOrAnchor
├─ durationPolicy
├─ grantedCapabilities[]
├─ triggerRules[]
├─ suppressionPolicy
├─ cleanupPolicy
└─ presentationProfileId
```

예시:

- 집중 주문
- 마녀의 번개 연결
- 지속 영역
- 버프와 디버프
- 반복 내성을 제공하는 상태
- 다음 공격에 적용되는 표식

OngoingEffect는 정의를 캐릭터에 영구 복사하지 않고 인스턴스로 생성한다.

---

## 27. 장면 오브젝트 변화

```text
PendingSceneObjectChange
├─ operation
├─ sceneObjectDefinitionId
├─ transformOrPath
├─ ruleGeometry
├─ blockingPolicies
├─ durationPolicy
├─ ownership
└─ cleanupPolicy
```

지원 작업:

```text
create
modify
destroy
suppress
resume
```

벽 주문, 위험 영역, 소환 표식과 규칙용 장면 객체가 사용한다.

시각 프리팹 생성과 규칙 오브젝트 확정은 같은 결과를 표현하지만, 규칙 상태가 권위 원본이다.

---

## 28. 반응과 부모 실행 수정

`TimingWindow`는 지정된 보류 단계에서 열린다.

주요 개입점:

```text
before_roll
roll_produced
outcome_determined
pending_effect_created
before_damage_responses
before_effect_commit
after_effect_commit
```

### 방어도 증가 반응

```text
AttackOutcomeDetermined: hit
→ TimingWindow modify
→ AC 문맥 변경
→ 공격 결과 재평가
→ miss가 되면 명중 전용 PendingEffect 제거
```

### 피해 감소 반응

```text
PendingDamage ready
→ DamageAboutToApply
→ ReducePendingDamage
→ 최종 피해량 계산
→ Commit
```

### 추가 피해

```text
AttackHitConfirmed
→ AddDamageComponent
→ 원래 PendingDamage와 결합
→ 피해 반응 단계 진행
```

### 반격 피해

원래 피해가 확정된 뒤 발생하는 효과라면 `Consequence`로 새 자식 실행을 만든다.

원래 PendingDamage에 섞지 않는다.

---

## 29. 패시브와 규칙 오버라이드 연결

### DerivedValueModifierCapability

공격 수정치, DC, 최대 HP와 같은 파생 값을 굴림과 효과 계산에서 조회한다.

### ContextModifierCapability

현재 공격, 내성, 피해, 회복과 이동 문맥에 기여한다.

### RuleOverrideCapability

등록된 규칙 지점에서 기본 결정을 변경한다.

예시:

```text
피해 유형 저항 무시
최소 피해량 변경
강제 이동 제한 면제
상태 면역
회복 금지 무시
치명타 범위 변경
```

오버라이드가 PendingEffect 전체를 임의 코드로 수정하지 않고 허용된 규칙 지점과 파라미터만 변경한다.

---

## 30. HP 0과 후속 상태

HP가 0에 도달하는지는 피해 Commit 이후에 판정한다.

```text
Damage Commit
→ finalHitPoints 계산
→ HitPointsReachedZero 여부
→ 규칙 세트의 zero-HP 처리
→ 후속 RuleEvent
```

0 HP 처리 예시 범주:

- 의식불명 상태
- 사망 판정 상태
- 즉시 사망 조건
- 형태 종료
- 특수 몬스터 제거
- DM 관리 서사 상태

정확한 규칙은 Actor 종류와 규칙 세트가 결정한다.

Damage 노드가 직접 토큰을 삭제하거나 전투에서 제거하지 않는다.

---

## 31. 집중 연결

집중 효과는 `OngoingEffectInstance`와 시전자 `ConcentrationState`에 연결된다.

```text
ConcentrationState
├─ ownerActorId
├─ sourceExecutionId
├─ ongoingEffectIds[]
├─ startedAt
└─ revision
```

피해가 확정되면 규칙 세트가 집중 검사 후보를 생성한다.

```text
DamageApplied
→ concentration policy 평가
→ 필요한 검사 단위 생성
→ SavingThrow RuleExecution
→ 실패 시 ConcentrationEnded
→ 연결된 지속 효과 정리
```

피해가 보류 상태일 때 집중 검사를 먼저 실행하지 않는다.

여러 피해 적용 사건이 동시에 발생한 경우 검사 단위와 순서는 규칙 세트 정책이 결정한다. `applicationId`와 `simultaneousGroupId`를 보존하므로 필요한 판정이 가능하다.

---

## 32. 대표 사례

### 32.1 일반 무기 공격

```text
RollAttack
→ outcome hit/miss
→ hit
   → RollDamage
   → CreateDamage
   → Damage pipeline
   → CommitGroup: attack unit
→ after-commit events
```

### 32.2 무기 피해와 추가 원소 피해

```text
공격 명중
→ PendingDamage 생성
   ├─ piercing component
   └─ lightning component
→ 대상의 각 피해 대응 계산
→ 하나의 target resolution commit
```

### 32.3 드래곤본 숨결 무기

```text
AttackUnitSlot을 숨결 무기로 교체
→ Area SpatialQuery
→ 대상별 SavingThrow
→ 공유 또는 개별 DamageRoll 정책
→ 성공·실패 OutcomeMap
→ 대상별 PendingDamage
→ CommitGroup 정책에 따라 확정
→ 공격 슬롯과 사용 자원 확정
```

숨결 무기는 EffectRecipe 관점에서 일반 광역 내성 효과와 같은 구조다.

### 32.4 화염구형 광역 주문

```text
PointSelection 완료
→ Sphere SpatialQuery
→ 피해 굴림 RollScope 결정
→ 대상별 내성
→ 성공: 조정된 피해
→ 실패: 전체 피해
→ 대상별 저항·면역과 반응
→ 동시 또는 대상별 commit
```

### 32.5 매직 미사일

```text
AssignEffectUnits
→ 투사체별 DamageRoll 또는 규칙이 정한 공유 굴림
→ 투사체별 PendingDamage
→ 대상별 방어 반응
→ 같은 simultaneousGroupId
→ 함께 확정
```

### 32.6 암습형 추가 피해

```text
AttackHitConfirmed
→ TriggerCapability 후보
→ 조건과 once_per_turn 검사
→ 사용 승인
→ AddDamageComponent
→ 같은 공격 applicationId
→ 원래 피해와 함께 해결
```

### 32.7 강타형 추가 자원 소비

```text
AttackHitConfirmed
→ ActionAugment 또는 TriggerCapability
→ 자원 결제 옵션 선택
→ 자원 예약
→ AddDamageComponent와 추가 상태 효과 생성
→ 같은 CommitGroup에 비용과 효과 포함
→ 확정 또는 함께 롤백
```

### 32.8 피해 감소 반응

```text
DamageAboutToApply
→ 보호자의 TriggerCapability
→ 반응과 자원 예약
→ ReducePendingDamage
→ 피해와 반응 비용을 확정
```

### 32.9 회복 특성

```text
대상 선택
→ RollHealing
→ PendingHealing
→ 회복 수정과 금지 규칙
→ 최대 HP 제한
→ 실제 적용량 commit
```

### 32.10 상태와 반복 내성

```text
내성 실패
→ PendingConditionChange
→ 면역과 중첩 검사
→ ConditionInstance 생성
→ TriggerCapability: target turn end
→ 반복 내성
→ 성공 시 RemoveCondition
```

### 32.11 밀치기

```text
공격 또는 내성 성공
→ CreateForcedMovement
→ 방향과 최대 거리 계산
→ 의미 충돌과 점유 검사
→ 마지막 유효 지점 산출
→ PendingMovement
→ commit
→ 영역 진입·퇴장과 추락 사건
```

### 32.12 지속 영역

```text
CreateOngoingEffect
→ 영역 형상과 TriggerRule 저장
→ 대상이 영역에 진입 또는 턴 시작
→ 새 자식 EffectRecipe
→ PendingDamage 또는 Condition
→ 별도 CommitGroup
```

지속 영역이 최초 시전의 CommitGroup을 계속 열어 두지 않는다.

---

## 33. UI와 로그

플레이어에게 다음을 구분하여 표시한다.

```text
굴림 결과
원래 효과량
적용된 추가 효과
면역·저항·취약성
피해 감소 또는 방지
임시 HP에 흡수된 양
실제 HP 변화
상태 적용 성공·실패
이동 요청 거리와 실제 이동 거리
```

예시 피해 로그:

```text
오우거가 14 피해를 받았습니다.
- 검격 8
- 화염 6 → 화염 저항으로 3
- 임시 HP 4 소모
- 실제 HP 7 감소
```

숨겨진 저항이나 비공개 수치는 `informationPolicy`에 따라 세부 표시를 제한할 수 있다.

로그는 최종 CommitResult에서 생성한다. 클라이언트 예상값을 공식 로그로 사용하지 않는다.

---

## 34. 클라이언트 미리보기

클라이언트는 다음을 예상 표시할 수 있다.

- 대상과 영역
- 예상 공격 또는 내성 종류
- 기본 피해 주사위
- 현재 알려진 공개 보정
- 적용될 수 있는 상태
- 강제 이동 예상 경로

미리보기는 권위 결과가 아니다.

숨겨진 패시브, 비공개 상태, DM 전용 수정치와 서버 최신 revision 때문에 결과가 달라질 수 있다.

서버 응답이 최종 결과를 결정한다.

---

## 35. 서버 권한과 네트워크

클라이언트 요청은 다음만 포함한다.

- 사용하려는 Capability
- 선택한 모드
- 대상·지점·방향 의도
- 선택한 자원 결제 옵션
- 선택형 반응 사용 여부

클라이언트가 보내지 않는 것:

- 명중 여부
- 내성 성공 여부
- 피해량
- 저항 적용 결과
- 최종 HP
- 상태 면역 판정
- 실제 이동 경로
- CommitGroup 성공 여부

서버는 실행 ID, 콘텐츠 버전, 장면·Actor revision과 멱등 키를 검증한다.

---

## 36. 성능

### 레시피 컴파일

검증된 EffectRecipe를 런타임 실행 계획으로 컴파일하고 캐시할 수 있다.

캐시 키:

```text
recipeId
schemaVersion
contentVersion
rulesetVersion
handlerVersion
```

### 후보 패시브 조회

피해와 굴림마다 모든 Capability를 순회하지 않는다.

- contextKind 인덱스
- rulePointId 인덱스
- 소유 Actor 인덱스
- 피해 유형 태그
- 상태 면역 태그

를 사용한다.

### 배치 처리

광역 효과는 대상별 실행 객체를 무조건 무거운 Actor 루프로 만들지 않는다.

공유 굴림, 공통 파이프라인 단계와 대상별 차이를 배치 처리하되, 각 대상의 결과·반응·로그 정체성은 유지한다.

### 지속 효과

매 프레임 전체 장면을 검색하지 않는다.

턴 사건, 이동 완료, 영역 진입·퇴장, 상태 변경과 의존성 이벤트에서만 자식 EffectRecipe를 생성한다.

---

## 37. 저장과 재접속

일반적인 즉시 효과는 CommitResult 이후 별도 실행 상태를 영구 저장할 필요가 없다.

저장해야 할 수 있는 상태:

- 열린 DM 판정 요청
- 예약된 비용과 보류 효과가 있는 중단 가능한 실행
- 장기 지속 효과
- 반복 내성 스케줄
- 집중 상태
- 장면 오브젝트
- 저장된 실행

전투 저장 정책은 다음 중 하나를 선택한다.

```text
안전한 commit 지점까지만 저장
또는
열린 실행과 PendingEffect를 완전 저장
```

부분적으로만 저장하여 비용은 소비됐지만 효과는 사라지는 상태를 만들지 않는다.

---

## 38. 오류 처리

### 콘텐츠 오류

- 잘못된 노드 타입
- 바인딩 타입 불일치
- 무한 반복 가능성
- 존재하지 않는 피해 유형
- 허용되지 않은 규칙 지점
- 모순되는 CommitGroup

콘텐츠 로딩 시 비활성화하고 진단을 남긴다.

### 런타임 무효화

대상 사라짐, 장면 전환, 자원 변경과 revision 충돌이 발생하면 `revalidationPolicy`와 `failurePolicy`를 따른다.

### 처리기 오류

전용 handler가 실패해도 이미 확정된 이전 ActionUnitExecution을 되돌리지 않는다.

현재 CommitGroup만 실패 또는 롤백한다.

### DM 판정

규칙으로 결정할 수 없는 경우 임의 결과를 만들지 않고 `RequestDMAdjudication`으로 전환한다.

---

## 39. 필수 테스트

1. 공격이 빗나가면 명중 전용 PendingDamage가 생성되지 않는다.
2. 방어도 반응으로 명중이 빗나감으로 바뀌면 피해가 적용되지 않는다.
3. 다중 피해 유형이 유형별 면역·저항을 독립 적용한다.
4. 추가 피해가 설정된 merge policy에 따라 같은 적용 또는 별도 적용으로 처리된다.
5. 치명타가 적격한 주사위에만 적용된다.
6. 내성 성공 시 피해 조정과 반올림이 규칙 세트 정책을 따른다.
7. 여러 대상이 공유 굴림과 대상별 내성을 올바르게 참조한다.
8. 매직 미사일 투사체가 개별 applicationId와 공통 simultaneousGroupId를 가진다.
9. 동시 그룹 중간에 외부 HP 트리거가 끼어들지 않는다.
10. 첫 공격 확정 후 두 번째 공격 실패가 첫 공격을 롤백하지 않는다.
11. 피해 감소 반응이 HP 적용 전에 실행된다.
12. 임시 HP가 회복과 합산되지 않고 규칙 정책으로 교체된다.
13. 회복 실제 적용량과 초과량이 구분된다.
14. 상태 면역 대상에게 상태가 적용되지 않는다.
15. 중복 상태가 상태 정의의 stacking policy를 따른다.
16. 반복 내성이 정확한 턴 시점에 자식 실행을 생성한다.
17. 밀기 경로가 벽과 점유 공간에서 올바르게 멈춘다.
18. 강제 이동 후 영역 진입·퇴장 사건이 확정 경로 기준으로 발생한다.
19. 순간이동이 중간 경로 영역을 일반 이동처럼 통과하지 않는다.
20. 피해 확정 뒤 집중 검사 후보가 올바른 applicationId 기준으로 생성된다.
21. HP 0 후속 규칙이 피해 노드가 아닌 사후 정책에서 실행된다.
22. 같은 idempotencyKey의 CommitGroup이 두 번 적용되지 않는다.
23. 숨겨진 저항과 비공개 굴림이 UI에 누출되지 않는다.
24. 전용 handler 오류가 현재 CommitGroup 밖의 이미 확정된 결과를 손상하지 않는다.
25. 광역 대상 수가 많아도 전체 Capability 순회 없이 인덱스를 사용한다.

---

## 40. 명시적 비목표

- 주문과 특성마다 별도의 피해·상태 엔진을 만들지 않는다.
- 피해 감소를 사후 회복으로 구현하지 않는다.
- 모든 효과를 실행 전체 하나의 원자 트랜잭션으로 묶지 않는다.
- 모든 효과를 반대로 개별 commit하여 동시성을 잃지 않는다.
- 피해 유형을 합산 전에 버리지 않는다.
- 상태를 이름 문자열 배열로만 저장하지 않는다.
- 강제 이동을 클라이언트 좌표 덮어쓰기로 처리하지 않는다.
- VFX 충돌과 애니메이션 종료를 규칙 확정 신호로 사용하지 않는다.
- 패시브와 반응을 효과 적용 후 임의 롤백으로 처리하지 않는다.
- 콘텐츠 설명 문구에서 실행 순서를 추론하지 않는다.

---

## 41. 다음 단계

EffectRecipe 이후에는 다음 연결 규약을 정리한다.

1. 공격 정의와 무기·비무장 공격 데이터 모델
2. AC, 공격 수정치, 숙련과 무기 속성 계산
3. 상태 카탈로그와 상태별 Capability 정의
4. 피해 유형 카탈로그와 저항·면역 표시
5. 장비, 무기 교체와 손 점유
6. 전투 UI에서 행동·대상·굴림·결과 표현

이 문서의 EffectRecipe가 이 모든 콘텐츠가 공유하는 최종 해결 기반이 된다.