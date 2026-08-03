# 21. 패시브 특성, 수치 수정과 규칙 오버라이드 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](../../rules-content-grant-capability-model.md)
  - [`11. 공통 실행 계약`](../../rules-content-execution-and-spell-contract.md)
  - [`19. 트리거와 다른 턴 실행 모델`](../../../systems/rules/feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](../../../systems/rules/active-feature-and-action-container-execution-model.md)
  - [`ADR-0027`](../../../decisions/ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md)

## 1. 문서 목적

이 문서는 행동이나 반응을 직접 생성하지 않으면서 현재 캐릭터와 규칙 계산을 바꾸는 패시브 특성의 공통 계약을 정의한다.

적용 출처는 다음을 포함한다.

- 재주
- 직업 및 하위직업 특성
- 종 특성
- 장비와 조율 아이템
- 형태와 자세
- 상태 효과
- 주문과 장면의 지속 효과
- DM이 부여한 예외 효과

패시브라는 이유로 하나의 타입에 모두 넣지 않는다.

```text
수치 자체를 바꾸는가
현재 굴림·공격·피해 문맥만 바꾸는가
기본 규칙의 허용 여부나 계산 방식을 바꾸는가
특정 조건에서 다른 Capability들을 켜는가
```

이 질문에 따라 다음 네 구조로 나눈다.

```text
DerivedValueModifierCapability
ContextModifierCapability
RuleOverrideCapability
ConditionalCapabilityGroup
```

---

## 2. 패시브와 실행형 기능의 경계

### 패시브

규칙 엔진이 값을 질의하거나 문맥을 만들 때 현재 활성 Capability를 읽는다.

```text
현재 이동 속도 질의
→ 이동 속도 Modifier 수집
→ 최종 이동 속도 계산
```

패시브를 확인할 때마다 별도 `RuleExecution`을 만들지 않는다.

### 트리거

특정 사건에 새로운 선택, 비용 또는 후속 결과가 생기면 `TriggerCapability`다.

```text
공격 명중
→ 추가 피해 사용 여부 제안
```

### 능동 기능

플레이어가 직접 선언하여 실행을 시작하면 `ActionCapability` 또는 행동 내부 Capability다.

### 구분 예시

| 규칙 의미 | 구조 |
|---|---|
| 이동 속도 +10피트 | `DerivedValueModifierCapability` |
| 특정 내성 굴림에 이점 | `ContextModifierCapability` |
| 어려운 지형으로 추가 이동 비용을 받지 않음 | `RuleOverrideCapability` |
| 방어구를 입지 않았을 때만 위 효과 활성 | `ConditionalCapabilityGroup` |
| 피해를 받은 뒤 반격할지 선택 | `TriggerCapability` |
| 보너스 행동으로 태세 활성화 | `ActionCapability` |

---

## 3. 획득 출처와 패시브 결과

재주와 Feature는 실행 타입이 아니라 Capability를 부여하는 출처다.

```text
FeatDefinition / FeatureDefinition / SpeciesFeature
→ GrantInstruction
→ ResolvedGrant
→ Capability Compiler
→ Passive Capability Set
```

캐릭터 저장 데이터에는 패시브의 현재 계산 결과를 권위 원본으로 저장하지 않는다.

저장하는 것:

- 획득 출처
- 선택 기록
- DM 예외 부여
- 현재 장비와 상태
- 지속 효과 인스턴스

파생하는 것:

- 현재 활성 패시브 Capability
- 최종 이동 속도와 방어도
- 현재 굴림 문맥 보정
- 적용 가능한 규칙 오버라이드

---

## 4. 중앙 카탈로그

패시브가 임의 문자열이나 코드 함수 이름을 수정 대상으로 삼지 않도록 두 중앙 카탈로그를 둔다.

### 4.1 DerivedValueCatalog

시스템이 질의 가능한 파생 값을 등록한다.

초기 범주 예시:

```text
actor.max_hit_points
actor.armor_class
actor.initiative_modifier
actor.walk_speed
actor.fly_speed
actor.swim_speed
actor.climb_speed
actor.jump_distance
actor.carry_capacity
actor.passive_perception
actor.spell_save_dc.<profile>
actor.spell_attack_modifier.<profile>
action.attack_unit_capacity.<container_profile>
resource.maximum.<resource_id>
```

각 값 정의는 다음을 가진다.

```text
DerivedValueDefinition
├─ valueId
├─ valueType
├─ baseFormula
├─ calculationPipelineId
├─ allowedOperations[]
├─ cachePolicy
└─ diagnosticsProfile
```

모든 값에 모든 연산을 허용하지 않는다. 예를 들어 정수형 공격 횟수에 임의 소수 배율을 적용하지 못하게 한다.

### 4.2 RulePointCatalog

규칙의 의미 있는 결정 지점을 등록한다.

초기 범주 예시:

```text
movement.difficult_terrain_cost
movement.provokes_opportunity_response
movement.can_enter_occupied_space
attack.long_range_disadvantage
attack.cover_tier_applied
attack.ability_selection
attack.unit_capacity
roll.advantage_disadvantage_resolution
spell.component_requirement
spell.concentration_requirement
item.attunement_requirement
action.allowed_while_conditioned
condition.grants_immunity
```

각 지점은 허용되는 오버라이드 종류와 파라미터 스키마를 정의한다.

```text
RulePointDefinition
├─ rulePointId
├─ inputContextSchema
├─ outputDecisionSchema
├─ allowedOverrideKinds[]
├─ precedencePipelineId
└─ conflictPolicy
```

콘텐츠는 엔진 내부 ModuleScript나 함수 이름을 참조하지 않는다.

---

## 5. DerivedValueModifierCapability

```text
DerivedValueModifierCapability
├─ capabilityId
├─ sourceContentId
├─ sourceOccurrenceId
├─ targetValueId
├─ operation
├─ valueExpression
├─ activationPredicate?
├─ calculationPhase
├─ priority
├─ stackingKey
├─ stackingPolicy
├─ tags[]
└─ diagnosticsKey
```

### 5.1 operation

초기 지원 연산:

```text
add
multiply
set
set_if_higher
set_if_lower
minimum
maximum
replace_formula
```

#### add

기본값 또는 앞 단계 결과에 값을 더한다.

#### multiply

규칙 세트가 허용한 단계에서 배율을 적용한다.

#### set

값을 직접 설정한다. 일반 가산 보너스보다 우선순위와 충돌 규칙이 중요하다.

#### set_if_higher / set_if_lower

현재 값보다 유리하거나 불리한 경우에만 대체한다.

#### minimum / maximum

최종 값의 하한 또는 상한을 제공한다.

#### replace_formula

기본 산식을 다른 등록된 공식으로 교체한다. 임의 코드나 자유 수식을 실행하지 않는다.

### 5.2 valueExpression

타입 있는 식만 허용한다.

```text
constant
ability_modifier
proficiency_bonus
class_level
character_level
feature_rank
resource_maximum
sum_of_registered_values
bounded_expression
```

예시:

```text
constant(10)
proficiency_bonus
max(1, ability_modifier(charisma))
```

문자열을 런타임에 `loadstring`처럼 평가하지 않는다.

---

## 6. 파생 수치 계산 단계

파생 값마다 규칙 세트가 계산 파이프라인을 정의한다.

일반적인 개념 단계:

```text
1. base_formula
2. formula_replacement
3. additive_contributions
4. multiplicative_contributions
5. set_or_compare_replacements
6. lower_and_upper_bounds
7. final_rule_overrides
8. normalization
```

정확한 단계는 값 종류마다 다를 수 있다.

콘텐츠 배열 순서, 파일 로드 순서와 Feature 획득 순서로 결과를 결정하지 않는다.

### 계산 요청

```text
DerivedValueQuery
├─ valueId
├─ subjectActorId
├─ ruleContext?
├─ rulesetSnapshot
└─ revisionSet
```

### 계산 결과

```text
DerivedValueResult
├─ valueId
├─ finalValue
├─ baseValue
├─ acceptedContributions[]
├─ suppressedContributions[]
├─ appliedOverrides[]
├─ dependencyRevisions
└─ diagnostics[]
```

시트는 `finalValue`만 표시할 수 있지만 상세 보기에서는 계산 근거를 제공한다.

---

## 7. 중첩 정책

패시브는 출처가 다르다는 이유만으로 무조건 합산하지 않는다.

```text
StackingPolicy
├─ stack
├─ highest_only
├─ lowest_only
├─ replace_by_priority
├─ independent_occurrences
├─ shared_effect
└─ prohibited
```

### stackingKey

같은 규칙 효과인지 판단하는 안정적인 키다.

예시:

```text
movement.walk_speed.untyped_bonus
armor_class.unarmored_formula
roll.concentration.advantage
attack.long_range_disadvantage.ignore
```

표시 이름이나 번역 문구를 키로 사용하지 않는다.

### 독립 출처

같은 Feat를 반복 습득할 수 있거나 아이템 두 개가 각각 독립 효과를 갖는 경우 `sourceOccurrenceId`로 구분한다.

독립 인스턴스라고 반드시 효과가 중첩되는 것은 아니다. 최종 허용 여부는 `stackingPolicy`가 결정한다.

### 억제된 기여

낮은 값만 무시된 경우에도 기여를 삭제하지 않는다.

```text
acceptedContributions
→ 실제 적용된 높은 값

suppressedContributions
→ 중첩 규칙 때문에 현재 적용되지 않은 낮은 값
```

높은 효과가 사라지면 낮은 효과가 자동으로 다시 활성화될 수 있다.

---

## 8. ContextModifierCapability

영구 파생 수치가 아니라 현재 실행 문맥에만 적용되는 패시브다.

```text
ContextModifierCapability
├─ capabilityId
├─ sourceContentId
├─ contextKind
├─ predicate
├─ contribution
├─ calculationPhase
├─ priority
├─ stackingKey
├─ stackingPolicy
├─ sourceBinding
└─ informationPolicy?
```

### contextKind 초기 후보

```text
attack_roll
ability_check
saving_throw
damage_roll
damage_received
healing_received
initiative_roll
concentration_check
movement_cost
target_eligibility
```

### predicate

현재 실행에 포함된 구조화된 데이터를 검사한다.

```text
allOf
├─ actor is capability owner
├─ attack uses eligible weapon tag
├─ target has required relation or condition
├─ distance is in allowed band
└─ owner satisfies equipment predicate
```

설명 텍스트를 파싱하지 않는다.

### contribution 초기 후보

```text
NumericBonusContribution
DiceBonusContribution
RollModeContribution
RerollPermissionContribution
DamageTypeContribution
DamageResponseContribution
TargetRuleContribution
```

`RerollPermissionContribution`처럼 실제 사용 여부와 자원 소비가 필요하면 패시브가 아니라 TriggerCapability를 생성하거나 연결해야 한다. 무제한 자동 재굴림 권한처럼 선택과 비용이 없는 경우에만 순수 문맥 기여가 될 수 있다.

---

## 9. 이점과 불리점

이점과 불리점을 `+5`, `-5` 같은 숫자로 변환하지 않는다.

```text
RollModeContribution
├─ mode: advantage | disadvantage
├─ sourceBinding
├─ predicateResult
├─ stackingKey
└─ suppressionTags[]
```

굴림 엔진은 모든 RollModeContribution과 RuleOverride를 모아 규칙 세트의 이점·불리점 결합 규칙을 적용한다.

```text
굴림 기본 모드
+ 이점 기여들
+ 불리점 기여들
+ 취소·무시 오버라이드
→ 최종 굴림 모드
```

같은 이점 출처가 여러 개 있다고 주사위를 추가로 더 굴리지 않는다. 정확한 결합 방식은 규칙 세트가 소유한다.

---

## 10. 피해 관련 패시브의 경계

종 특성, 장비와 상태는 피해 면역, 저항, 취약성 또는 감소를 제공할 수 있다.

이들은 피해를 받을 때 현재 `DamageContext`에 다음 기여를 제공한다.

```text
DamageResponseContribution
├─ damageTypePredicate
├─ responseKind
├─ valueExpression?
├─ stackingKey
├─ stackingPolicy
└─ sourceBinding
```

`responseKind` 예시:

```text
immunity
resistance
vulnerability
flat_reduction
minimum_damage
ignore_reduction
```

패시브 모델은 어떤 기여가 존재하는지를 제공한다.

실제 적용 순서, 반올림, 다중 피해 구성요소와 동시 피해 처리는 이후 `EffectRecipe`의 피해 해결 규약이 소유한다.

---

## 11. RuleOverrideCapability

```text
RuleOverrideCapability
├─ capabilityId
├─ sourceContentId
├─ sourceOccurrenceId
├─ rulePointId
├─ predicate
├─ overrideKind
├─ parameters
├─ precedenceTier
├─ priority
├─ stackingKey
├─ conflictPolicy
├─ activationPredicate?
└─ diagnosticsKey
```

### 11.1 overrideKind 초기 후보

```text
allow
deny
ignore
replace
substitute
expand
restrict
set_policy
alter_capacity
```

#### allow / deny

원래 금지되거나 허용된 행동·대상·상태를 변경한다.

#### ignore

특정 규칙 효과를 적용하지 않는다.

예시: 특정 이동에서 어려운 지형 추가 비용 무시.

#### replace

원래 규칙 계산이나 결과를 등록된 다른 정책으로 교체한다.

#### substitute

사용 능력치, 자원 또는 대상 기준을 다른 적격 값으로 대체한다.

#### expand / restrict

기존 후보군, 사거리, 발동 조건 또는 사용 가능한 문맥을 확장하거나 제한한다.

#### alter_capacity

공격 횟수, 준비 수, 대상 수와 같은 용량 계산을 변경한다.

### 11.2 규칙 지점의 입력과 출력

예시: 공격 능력치 선택

```text
RulePoint: attack.ability_selection
Input
├─ actor
├─ attack source
├─ weapon or ability tags
├─ candidate abilities
└─ current form and equipment

Output
├─ allowed abilities
├─ selected default
└─ selection required
```

`substitute` 오버라이드는 새로운 후보 능력치를 추가하거나 기본값을 바꿀 수 있다.

예시: 어려운 지형

```text
RulePoint: movement.difficult_terrain_cost
Input
├─ mover
├─ movement mode
├─ terrain tags
└─ segment

Output
└─ cost multiplier or ignore decision
```

---

## 12. 오버라이드 우선순위와 충돌

단순한 숫자 `priority`만으로 모든 규칙을 해결하지 않는다.

```text
precedenceTier
├─ core_rule
├─ general_modifier
├─ specific_feature
├─ explicit_exception
├─ temporary_specific_exception
└─ dm_adjudication
```

규칙 세트가 각 `RulePoint`의 우선 단계 의미를 정의한다.

### conflictPolicy

```text
combine
highest_priority
most_specific
owner_choice
dm_choice
error
```

서로 양립할 수 없는 동일 우선순위 오버라이드가 발생하면 로딩 순서로 하나를 선택하지 않는다.

- 사용자 선택이 규칙상 허용되면 `owner_choice`
- DM 판정이 필요하면 `dm_choice`
- 콘텐츠 정의 오류라면 `error`

### 설명 가능한 결정

```text
RuleDecisionResult
├─ rulePointId
├─ baseDecision
├─ candidateOverrides[]
├─ appliedOverrides[]
├─ suppressedOverrides[]
├─ finalDecision
└─ diagnostics[]
```

---

## 13. ConditionalCapabilityGroup

```text
ConditionalCapabilityGroup
├─ groupId
├─ sourceContentId
├─ sourceOccurrenceId
├─ activationPredicate
├─ dependencyKeys[]
├─ grantedCapabilities[]
├─ activationState
├─ deactivationPolicy
└─ diagnosticsKey
```

### activationPredicate

타입 있는 조건 조합을 사용한다.

```text
allOf
anyOf
noneOf
```

원자 조건 예시:

```text
equipment.has_tag
item.is_equipped
item.is_attuned
armor.category_is
armor.none_equipped
actor.has_condition
actor.lacks_condition
actor.hit_point_ratio_below
actor.is_concentrating
actor.form_has_tag
scene.light_level
scene.terrain_has_tag
nearby.actor_matching
ongoing_effect.active
```

### 조건 변화

```text
획득 상태
→ 유지

activationPredicate = true
→ 하위 Capability 활성

activationPredicate = false
→ 하위 Capability 비활성
```

Feature를 획득 목록에서 삭제하거나 다시 부여하지 않는다.

### deactivationPolicy

대부분의 수치 패시브는 즉시 비활성화된다.

이미 시작된 실행이나 생성된 지속 효과에 영향을 주는 특수 패시브는 다음 중 하나를 명시한다.

```text
immediate
next_rule_query
preserve_existing_execution_snapshot
end_linked_effects
custom_policy
```

---

## 14. 위치·주변 생물·환경 조건

위치 기반 조건은 단순 캐릭터 시트 캐시에 영구 저장하지 않는다.

예시:

- 아군과 인접한 동안 보너스
- 특정 오라 안에서 이점
- 밝은 빛에서 비활성
- 특정 지형에서 이동 보너스

### 처리 방식

```text
공간 또는 장면 사건
→ 관련 dependencyKey 갱신
→ 영향받는 ConditionalCapabilityGroup만 재평가
→ 관련 파생 값 캐시 무효화
```

모든 캐릭터가 매 프레임 주변 생물을 전체 검색하지 않는다.

오라와 주변 조건은 공간 인덱스와 영역 진입·퇴장 이벤트를 사용한다.

---

## 15. Capability 억제

마법 억제, 형태 변환, 장비 비활성화와 상태 효과는 Capability 정의를 삭제하지 않는다.

```text
CapabilityInstance
├─ definition reference
├─ sourceBinding
├─ activationState
├─ suppressionSources[]
└─ diagnostics[]
```

활성 상태:

```text
active
inactive_by_condition
suppressed
invalid_source
conflicted
```

억제 원인이 사라지면 다른 조건과 충돌을 다시 평가하여 활성화할 수 있다.

---

## 16. 의존성 기반 캐시

### dependencyKeys 예시

```text
progression.changed
equipment.changed
attunement.changed
condition.changed
hit_points.changed
form.changed
position.changed
nearby_allies.changed
lighting.changed
terrain.changed
ongoing_effect.changed
resource.maximum.changed
```

각 파생 값과 ConditionalCapabilityGroup은 자신이 의존하는 키를 등록한다.

```text
상태 변경
→ 변경된 dependencyKey 발행
→ 관련 Capability 활성 캐시 무효화
→ 관련 DerivedValue 캐시 무효화
→ 필요한 소비자에게 델타 동기화
```

공격 대상, 거리와 현재 피해 유형처럼 실행마다 달라지는 문맥은 장기 캐시에 포함하지 않는다.

### revision

```text
PassiveCapabilityRevision
DerivedValueRevision.<valueId>
RuleContextRevision
```

서버는 실행 검증 시 관련 revision을 스냅샷하고 commit 전에 필요한 항목만 재검증한다.

---

## 17. UI와 진단

### 캐릭터 시트

최종 값 옆에 출처를 펼쳐볼 수 있다.

```text
이동 속도: 40피트

기본값                 30
민첩한 발걸음 재주     +10
중갑 감속               적용 안 됨: 규칙 오버라이드
```

### 조건부 패시브

비활성 효과도 획득한 Feature 상세 화면에서는 보여준다.

```text
활성: 방어구를 착용하지 않음
비활성 이유: 중형 방어구 착용 중
```

### 충돌

콘텐츠 오류 또는 DM 판정이 필요한 충돌은 조용히 숨기지 않는다.

```text
두 효과가 공격 능력치를 서로 다른 값으로 강제합니다.
→ 선택 필요 / DM 판정 필요 / 콘텐츠 오류
```

플레이어에게 공개하면 안 되는 숨겨진 효과의 출처는 정보 정책에 따라 일반화된 설명만 표시한다.

---

## 18. 대표 사례

### 18.1 이동 속도 증가

```text
DerivedValueModifierCapability
├─ targetValueId: actor.walk_speed
├─ operation: add
├─ valueExpression: constant(10 feet)
└─ stackingPolicy: content_rule
```

이 효과는 이동할 때마다 실행되지 않는다. 현재 이동 속도 질의 결과를 바꾼다.

### 18.2 비장갑 방어도 공식

```text
ConditionalCapabilityGroup
├─ activationPredicate: armor.none_equipped
└─ RuleOverrideCapability
   ├─ rulePointId: actor.armor_class_formula
   └─ overrideKind: replace
```

방어구를 착용하면 획득 특성은 유지되지만 해당 공식 오버라이드는 비활성화된다.

### 18.3 특정 내성에 이점

```text
ContextModifierCapability
├─ contextKind: saving_throw
├─ predicate: save matches required condition
└─ contribution: advantage
```

캐릭터 시트의 모든 내성 수치에 고정 보너스를 더하지 않는다.

### 18.4 어려운 지형 무시

```text
RuleOverrideCapability
├─ rulePointId: movement.difficult_terrain_cost
├─ predicate: movement mode and terrain eligible
└─ overrideKind: ignore
```

기본 이동 속도를 올리는 방식으로 흉내 내지 않는다.

### 18.5 특정 공격 능력치 대체

```text
RuleOverrideCapability
├─ rulePointId: attack.ability_selection
├─ predicate: attack source has eligible tags
├─ overrideKind: substitute
└─ parameters: add eligible ability
```

공격 정의 자체의 능력치를 영구 수정하지 않는다.

### 18.6 종 특성의 피해 저항

```text
ContextModifierCapability
├─ contextKind: damage_received
├─ predicate: damage type matches ancestry choice
└─ contribution: resistance
```

선택한 계통이나 피해 유형은 성장 `ChoiceRecord`에서 파생한다.

### 18.7 인접 아군 조건

```text
ConditionalCapabilityGroup
├─ activationPredicate: nearby ally within configured distance
├─ dependencyKeys: [position.changed, nearby_allies.changed]
└─ ContextModifierCapability
   └─ contribution: eligible combat bonus
```

공간 인덱스 이벤트로 활성 상태를 갱신한다.

### 18.8 여러 조항을 가진 재주

```text
FeatDefinition
├─ AbilityScoreChoice
├─ ConditionalCapabilityGroup
│  └─ PassiveModifierCapability
├─ TriggerCapability
└─ ResourceCapability
```

각 조항은 자기 역할의 Capability로 분리되고 재주 이름을 기준으로 하나의 거대한 처리기를 만들지 않는다.

---

## 19. 패시브로 처리하지 않는 것

### 능력치 증가

영구 능력치 선택과 증가는 성장 선택 및 Grant Graph의 원본 데이터다.

`현재 힘 +1 패시브`로만 저장하지 않는다.

### 숙련, 언어와 도구

`ProficiencyGrant`, `LanguageGrant`와 선택 기록으로 처리한다.

### 제한 자원

`ResourceCapability`가 소유한다.

### 사용 여부를 묻는 보너스

사건에 선택적으로 개입한다면 `TriggerCapability`다.

### 버튼으로 사용하는 능력

`ActionCapability` 또는 행동 내부 Capability다.

---

## 20. 서버 권한과 검증

서버가 다음을 결정한다.

- 획득 출처가 유효한가
- Capability가 현재 활성·억제 상태인가
- predicate가 현재 권위 상태를 만족하는가
- 어떤 기여가 중첩 규칙을 통과하는가
- 오버라이드 충돌이 어떻게 해결되는가
- 최종 파생 수치와 규칙 결정이 무엇인가

클라이언트는 최종 이동 속도, 이점 여부와 엄폐 무시 여부를 권위 값으로 보내지 않는다.

실행 중 클라이언트가 사용한 미리보기와 서버 최종 결과가 달라지면 서버 결과를 적용하고 변경 원인을 진단 가능한 형태로 돌려준다.

---

## 21. 성능 원칙

- 활성 Capability를 값 질의마다 전체 순회하지 않는다.
- `targetValueId`, `contextKind`와 `rulePointId`별 인덱스를 사용한다.
- 장비·상태·위치 변화에 관련된 캐시만 무효화한다.
- 정적 성장 패시브와 동적 장면 패시브를 별도 revision으로 관리한다.
- 위치 기반 조건은 공간 인덱스와 영역 사건을 사용한다.
- UI를 위해 매 프레임 상세 계산 추적을 재생성하지 않는다.
- 진단 추적은 계산 결과 캐시 또는 요청 시 생성한다.

---

## 22. 테스트 기준

필수 테스트:

1. 두 가산 이동 보너스가 stacking policy에 따라 합산 또는 억제된다.
2. 높은 값만 적용되는 효과가 사라지면 낮은 값이 다시 적용된다.
3. 파일 로딩 순서를 바꿔도 최종 수치가 동일하다.
4. 방어구 장착 시 비장갑 조건부 공식이 비활성화된다.
5. 방어구 해제 시 획득 기록 변경 없이 다시 활성화된다.
6. 특정 대상에 대한 굴림 보너스가 영구 시트 수치에 포함되지 않는다.
7. 이점과 불리점이 숫자 보너스가 아닌 규칙 세트 정책으로 결합된다.
8. 어려운 지형 무시가 이동 속도 자체를 변경하지 않는다.
9. 대체 공격 능력치가 적격 공격에만 후보로 등장한다.
10. 피해 저항 기여가 피해 유형 predicate를 정확히 검사한다.
11. 억제된 Capability가 억제 원인 제거 후 재활성화된다.
12. 같은 우선순위의 상충 오버라이드가 임의 선택되지 않는다.
13. 위치 기반 조건이 영역 진입·퇴장 사건에서만 필요한 캐시를 갱신한다.
14. 숨겨진 적 효과의 출처가 플레이어 진단 UI로 누출되지 않는다.
15. 클라이언트의 조작된 최종 수치가 서버 검증에서 무시된다.
16. 순환 파생 값 의존성이 콘텐츠 검증에서 탐지된다.
17. replace_formula가 등록되지 않은 임의 식을 실행하지 못한다.
18. 동일 Feature의 여러 occurrence가 sourceBinding과 stacking policy에 따라 처리된다.

---

## 23. 명시적 비목표

- 모든 패시브를 숫자 보너스로 환원하지 않는다.
- 패시브마다 Heartbeat 또는 개별 이벤트 연결을 만들지 않는다.
- Feature 설명 문구를 파싱해 적용 대상을 추론하지 않는다.
- 영구 능력치·숙련 선택을 임시 패시브로만 저장하지 않는다.
- 파일 순서로 중첩과 오버라이드 충돌을 해결하지 않는다.
- 조건이 꺼질 때 획득 Feature를 삭제하지 않는다.
- 이점과 불리점을 임의 숫자로 변환하지 않는다.
- 피해 저항의 실제 적용 순서를 이 문서에서 중복 정의하지 않는다.

---

## 24. Feat 구조에서 남은 단계

패시브 구조 이후에도 Feat 전체 조립을 위해 다음을 별도로 정리해야 한다.

1. 능력치, 숙련, 언어, 도구와 주문 선택 부여
2. Feat 전용 및 공유 ResourceCapability
3. 반복 습득, 선택 occurrence와 교체 규칙
4. 복수 조항의 지원 수준과 부분 비활성화
5. FeatDefinition 전체 검증과 UI 조립

이 단계들을 완료한 뒤 피해·회복·상태와 강제 이동의 `EffectRecipe` 해결 규약으로 넘어간다.