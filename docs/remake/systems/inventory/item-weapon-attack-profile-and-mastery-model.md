# 24. 무기·아이템·공격 프로필과 Weapon Mastery 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](../../../../architecture/rules-content-grant-capability-model.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](../../../rules/active-feature-and-action-container-execution-model.md)
  - [`21. 패시브 특성 모델`](../../../../architecture/passive-modifier-and-rule-override-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`23. 상태·지속 효과·집중 수명주기 모델`](../../../rules/condition-ongoing-effect-duration-and-concentration-model.md)
  - [`ADR-0030`](../../../../decisions/ADR-0030-item-instances-attack-profiles-and-weapon-mastery.md)

## 1. 문서 목적

이 문서는 무기, 방패, 탄약, 소모품, 마법 아이템과 기타 장비가 캐릭터에게 공격과 행동을 제공하는 공통 구조를 정의한다.

대상은 다음을 포함한다.

- 근접 무기와 원거리 무기
- 한 손, 두 손과 다용도 사용
- 투척 무기
- 탄약과 장전
- 방패와 손 점유
- 마법 무기의 명중·피해 보너스
- 아이템 충전과 수량
- Weapon Mastery
- 아이템이 제공하는 특수 공격과 행동
- 몬스터가 장비를 통해 사용하는 공격

핵심 원칙:

```text
아이템 정의
≠ 개별 소유 아이템
≠ 현재 장착 상태
≠ 이번 공격의 계산 스냅샷
```

네 책임을 분리한다.

---

## 2. 전체 구조

```text
ItemDefinition / WeaponDefinition
→ ItemInstance
→ InventoryState
→ EquipmentState
→ Capability Compiler
→ AttackProfileCompiler
→ AttackProfileSnapshot
→ ActionUnitExecution
→ EffectRecipe
```

### 정의

콘텐츠 카탈로그가 소유하는 규칙 데이터다.

### 인스턴스

특정 캐릭터나 장면에 존재하는 실제 아이템이다.

### 장착 상태

현재 누가 무엇을 들고 착용하고 있는지 나타낸다.

### 공격 프로필

현재 공격 하나를 실행하기 위해 서버가 계산한 일회성 스냅샷이다.

---

## 3. ItemDefinition 계층

```text
ItemDefinition
├─ WeaponDefinition
├─ ArmorDefinition
├─ ShieldDefinition
├─ AmmunitionDefinition
├─ ConsumableDefinition
├─ ToolDefinition
├─ SpellcastingFocusDefinition
├─ WondrousItemDefinition
└─ CustomItemDefinition
```

공통 필드:

```text
itemId
schemaVersion
rulesetId
sourcePackId
localizationKeys
itemKind
tags[]
weight
stackingProfile
inventoryProfile
equipmentProfile?
attunementProfile?
grantedCapabilities[]
itemActions[]
presentationProfileId
```

아이템 종류마다 허용 필드를 검증한다. 무기가 아닌 아이템에 무기 피해 필드를 임의로 넣지 않는다.

---

## 4. WeaponDefinition

```text
WeaponDefinition
├─ weaponCategory
├─ proficiencyTags[]
├─ weaponProperties[]
├─ attackModes[]
├─ baseDamageProfiles[]
├─ rangeProfiles[]
├─ ammunitionProfileId?
├─ throwProfileId?
├─ masteryPropertyId?
├─ equipProfile
└─ presentationProfileId
```

### weaponCategory

규칙 세트가 정의하는 무기 분류를 참조한다.

예시:

```text
simple_melee
simple_ranged
martial_melee
martial_ranged
natural_weapon
improvised_weapon
custom_registered
```

분류는 숙련과 콘텐츠 필터링에 사용하고 공격 구현을 직접 분기하는 키로 사용하지 않는다.

### weaponProperties

타입 있는 속성 ID를 사용한다.

예시:

```text
finesse
light
heavy
reach
thrown
versatile
two_handed
ammunition
loading
special
```

속성 설명 문자열을 파싱하지 않는다.

---

## 5. ItemInstance

```text
ItemInstance
├─ itemInstanceId
├─ definitionReference
├─ ownerScope
├─ containerBinding?
├─ quantity
├─ charges?
├─ maximumChargesSnapshot?
├─ conditionState
├─ attunementState
├─ customName?
├─ identifiedState
├─ instanceModifiers[]
├─ provenance
└─ revision
```

### ownerScope

```text
character_inventory
actor_inventory
scene_object
container_item
party_storage
unowned_scene_item
```

### quantity

쌓을 수 있는 탄약·소모품에 사용한다.

고유 마법 무기처럼 개별 상태가 필요한 아이템은 일반적으로 quantity 1의 독립 인스턴스로 저장한다.

### instanceModifiers

마법 강화, 제작 품질, 저주, 손상과 DM 보정을 표현한다.

기본 정의를 직접 수정하지 않는다.

---

## 6. InventoryState와 EquipmentState

```text
InventoryState
├─ itemBindings[]
├─ containerRelations[]
├─ carriedWeightState
├─ capacityState
└─ revision
```

```text
EquipmentState
├─ handSlots[]
├─ wornSlots[]
├─ readiedItemBindings[]
├─ stowedItemBindings[]
├─ activeLoadoutId?
└─ revision
```

### HandSlot

```text
HandSlot
├─ handId
├─ occupancyState
├─ occupiedByItemInstanceId?
├─ occupancyUnits
├─ reservationId?
└─ revision
```

손 점유 요구는 단순히 아이템 하나당 손 하나로 고정하지 않는다.

```text
HandRequirement
├─ requiredHands
├─ allowedHands
├─ mustRemainOccupiedThrough
├─ temporaryReleasePolicy
└─ interactionRequirement?
```

예시:

- 한 손 무기: 공격 해결 동안 한 손
- 양손 무기: 공격 실행 시 두 손
- 다용도 무기: 선택 모드에 따라 한 손 또는 두 손
- 활: 공격 실행 시 두 손
- 방패: 장착 상태 동안 한 손 지속 점유

---

## 7. 장착과 꺼내기

아이템을 장착하거나 손에 드는 것은 인벤토리 이동과 다르다.

```text
EquipCommand
├─ actorId
├─ itemInstanceId
├─ targetSlots[]
├─ interactionCost
├─ expectedRevisions
└─ requestedMode?
```

서버 검증:

- 아이템을 실제로 소유하거나 접근 가능한가
- 필요한 손·착용 슬롯이 비어 있는가
- 방어구와 방패 제한을 만족하는가
- 조율 또는 숙련 조건이 필요한가
- 현재 상태가 아이템 조작을 허용하는가
- 전투 중 상호작용 비용이 남아 있는가

장착 변경은 Capability Set과 AttackProfile 캐시를 무효화한다.

---

## 8. AttackModeDefinition

```text
AttackModeDefinition
├─ modeId
├─ attackKind
├─ activationContext
├─ handRequirement
├─ abilitySelectionPolicy
├─ proficiencyPolicy
├─ targetProfile
├─ rangeProfileId
├─ damageProfileId
├─ consumptionProfileId?
├─ effectRecipeId
├─ masteryEligibilityTags[]
└─ presentationProfileId
```

### attackKind

```text
melee_weapon
ranged_weapon
thrown_weapon
unarmed
natural_weapon
item_spell_attack
special_attack
```

### activationContext

```text
attack_unit
reaction_attack
bonus_action_attack
item_action
monster_multiattack_unit
special_container_unit
```

하나의 공격 모드가 허용되는 행동 문맥을 명시한다.

---

## 9. 대표 무기 모드

### 9.1 장검

```text
WeaponDefinition: longsword
├─ mode: one_handed_melee
│  ├─ requiredHands: 1
│  └─ damageProfile: one-handed damage
└─ mode: two_handed_melee
   ├─ requiredHands: 2
   └─ damageProfile: versatile damage
```

양손 모드는 별도 장검 아이템이 아니다.

### 9.2 단검

```text
WeaponDefinition: dagger
├─ mode: melee
│  ├─ attackKind: melee_weapon
│  └─ range: reach
└─ mode: thrown
   ├─ attackKind: thrown_weapon
   ├─ range: normal / long
   └─ consumption: transfer weapon from hand
```

### 9.3 장궁

```text
WeaponDefinition: longbow
└─ mode: ranged
   ├─ requiredHands: 2
   ├─ ammunition required
   ├─ normal / long range
   └─ attack EffectRecipe
```

활 아이템과 화살 아이템을 별도 인스턴스로 추적한다.

---

## 10. AbilitySelectionPolicy

공격에 사용할 능력치는 무기 정의가 최종 확정하지 않는다.

```text
AbilitySelectionPolicy
├─ baseCandidates[]
├─ propertyCandidates[]
├─ overrideRulePointId
├─ choicePolicy
└─ tiePolicy
```

처리 흐름:

```text
공격 모드 기본 후보
+ 무기 속성 후보
+ Feature·마법·형태 RuleOverride
→ 적격 능력치 후보
→ 자동 선택 또는 사용자 선택
```

예시:

- 일반 근접 무기: Strength
- finesse 무기: Strength 또는 Dexterity
- 특정 특성: 다른 등록 능력치 후보 추가

서버가 최종 후보와 선택을 검증한다.

---

## 11. 숙련

```text
ProficiencyEvaluation
├─ requiredTags[]
├─ actorProficiencyCapabilities[]
├─ specialOverrides[]
├─ proficiencyState
└─ diagnostics[]
```

`proficiencyState` 예시:

```text
proficient
not_proficient
expertise_like_registered
custom_registered
```

무기 공격 프로필은 숙련 결과를 사용해 공격 수정치를 계산한다.

아이템 정의에 캐릭터별 숙련 여부를 저장하지 않는다.

---

## 12. RangeProfile

```text
RangeProfile
├─ rangeKind
├─ reachDistance?
├─ normalDistance?
├─ longDistance?
├─ minimumDistance?
├─ lineOfEffectPolicy
├─ visibilityPolicy
├─ coverPolicy
└─ rangeBandRules[]
```

거리 단위는 피트다.

```text
RuleDistanceFeet
→ scene scale adapter
→ studs for preview and spatial query
```

### 근접 도달거리

현재 크기, 무기 속성, 형태와 Feature에 따라 `ContextModifierCapability` 또는 `RuleOverrideCapability`가 수정할 수 있다.

### 정상·장거리

장거리 불리점과 공격 가능 여부는 `RulePointCatalog`의 공격 사거리 지점에서 결정한다.

### 인접 적과 원거리 공격

이와 같은 문맥 규칙도 공격 정의에 하드코딩하지 않고 현재 `RuleContext`와 패시브 오버라이드에서 해결한다.

---

## 13. DamageProfile

```text
DamageProfile
├─ baseComponents[]
├─ abilityContributionPolicy
├─ criticalPolicies[]
├─ versatileVariant?
├─ scalingBindings[]
└─ tags[]
```

```text
BaseDamageComponent
├─ componentId
├─ diceExpression
├─ damageType
├─ abilityModifierPolicy
├─ criticalPolicy
└─ tags[]
```

마법 무기의 추가 피해는 기본 WeaponDefinition을 복사하지 않고 인스턴스 Modifier 또는 장착 Capability가 `DamageComponent`를 추가한다.

```text
기본 무기 피해
+ ItemInstance modifier
+ Feature augment
+ EffectInstance contribution
→ PendingDamage components
```

---

## 14. AttackProfileCompiler

입력:

```text
AttackProfileCompileRequest
├─ actorId
├─ sourceItemInstanceId?
├─ attackModeId
├─ parentContainerExecutionId?
├─ actionUnitSlotId?
├─ intendedTargetId?
├─ ruleContext
└─ expectedRevisions
```

처리:

```text
1. 아이템 정의와 인스턴스 해석
2. 현재 소유·장착·손 점유 확인
3. 공격 모드 적격성 확인
4. 능력치 후보 계산
5. 숙련 계산
6. 공격 수정치 기여 수집
7. 사거리와 대상 정책 계산
8. 피해 구성요소 계산
9. 탄약·투척·충전 소비 계획 생성
10. MasteryBinding과 특수 Capability 결합
11. EffectRecipe와 표현 프로필 연결
```

출력:

```text
AttackProfileSnapshot
├─ attackProfileId
├─ actorId
├─ sourceItemInstanceId?
├─ modeId
├─ attackKind
├─ selectedAbilityId
├─ proficiencyState
├─ attackModifierBreakdown[]
├─ rangeProfileSnapshot
├─ damageProfileSnapshot
├─ handRequirementSnapshot
├─ consumptionPlan
├─ masteryBindings[]
├─ effectRecipeId
├─ ruleSnapshot
├─ dependencyRevisions
└─ diagnostics[]
```

스냅샷은 해당 실행에만 사용한다. 장비나 상태가 바뀐 뒤 새 공격에는 다시 컴파일한다.

---

## 15. 공격 실행 흐름

```text
AttackUnitSlot 활성
→ AttackProfile 후보 요청
→ 무기와 모드 선택
→ 대상 선택
→ 사거리·시야·엄폐 미리보기
→ 서버 최종 검증
→ 손·탄약·아이템 상태 예약
→ RollAttack
→ TimingWindow
→ 명중 결과
→ EffectRecipe
→ PendingDamage와 기타 효과
→ CommitGroup
→ 공격 슬롯·탄약·아이템 상태 확정
```

### 취소

```text
대상 선택 중 Q
→ 공격 실행 취소
→ 손·탄약 예약 해제
→ AttackUnitSlot 유지
```

첫 굴림이 공개된 뒤의 취소와 환불은 콘텐츠와 규칙 정책에 따른다.

---

## 16. 탄약

```text
AmmunitionProfile
├─ acceptedAmmunitionTags[]
├─ amountPerAttack
├─ reservationPolicy
├─ consumeOn
├─ recoveryPolicy
└─ placementPolicy
```

공격 준비 단계에서 적격 탄약 인스턴스를 선택하거나 자동 선택한다.

```text
AmmoReservation
├─ ammunitionItemInstanceId
├─ amount
├─ expectedRevision
├─ reservedByExecutionId
└─ expiresOn
```

동시에 두 공격이 마지막 화살 하나를 사용하지 못하도록 서버 예약을 사용한다.

### 회수

탄약 회수는 공격 엔진의 기본 자동 환불이 아니다.

규칙 세트와 캠페인 정책이 허용하면 전투 종료 후 회수 판정 또는 장면 아이템 생성을 별도 절차로 처리한다.

---

## 17. 투척 무기

투척 공격은 무기 인스턴스 자체의 위치·소유 상태를 바꿀 수 있다.

```text
ThrownItemTransition
├─ itemInstanceId
├─ sourceHandId
├─ destinationPolicy
├─ targetBinding?
├─ scenePositionBinding?
├─ recoveryState
└─ commitPolicy
```

확정 결과 예시:

- 대상 위치에 장면 아이템 생성
- 공격 대상 인벤토리에 박힌 상태로 연결
- 회수 불가능 상태
- 규칙이 허용하는 자동 복귀

무기 이동과 피해는 같은 공격 실행에 속하지만 실패 정책과 확정 순서를 명시적으로 관리한다.

---

## 18. Loading과 발사 제한

`loading`과 같은 속성은 단순 공격 버튼 숨김이 아니다.

```text
RuleOverride / ActionRestriction
→ 현재 행동 문맥에서 해당 무기로 허용되는 공격 단위 수 계산
```

특성이 제한을 제거하면 `RuleOverrideCapability`가 해당 규칙 지점을 변경한다.

무기 정의에 특정 클래스 이름을 하드코딩하지 않는다.

---

## 19. Light와 보조 공격

가벼운 무기, 쌍수와 보너스 행동 공격은 공격 엔진이 아니라 **공격 기회 생성 규칙**에서 처리한다.

```text
적격 공격 수행
→ RuleEvent
→ 추가 공격 기회 조건 충족
→ 제한된 ActionOpportunity 생성
→ 해당 기회가 허용하는 AttackProfile만 표시
```

추가 공격은 일반 공격 행동의 남은 슬롯과 혼동하지 않는다.

어떤 피해 수정치를 적용하는지는 생성된 공격 문맥과 규칙 오버라이드가 결정한다.

---

## 20. Weapon Mastery 정의

```text
WeaponMasteryPropertyDefinition
├─ masteryPropertyId
├─ schemaVersion
├─ eligibilityTags[]
├─ activationEvent
├─ predicates[]
├─ actionCost
├─ usageGates[]
├─ responseRecipeId?
├─ grantedCapabilities[]
├─ stackingPolicy
└─ presentationProfileId
```

무기는 `masteryPropertyId`를 참조할 수 있지만, 소유자가 실제로 사용할 수 있다는 뜻은 아니다.

### 접근 권한

```text
WeaponMasteryAccessCapability
├─ selectedWeaponDefinitionIds[] 또는 selectionTags[]
├─ sourceOccurrenceId
├─ activeRestrictions[]
└─ rulesetBinding
```

```text
현재 무기
+ 무기의 mastery property
+ 캐릭터의 mastery access
→ MasteryBinding 활성화 여부
```

### 구현 형태

마스터리 규칙에 따라 기존 공통 구조를 사용한다.

```text
명중 전에 적용
→ ContextModifierCapability

명중 시 자동 또는 선택 효과
→ TriggerCapability

공격 행동의 선택지 확장
→ ActionAugmentCapability

이동·대상·공격 규칙 변경
→ RuleOverrideCapability

피해·상태·강제 이동 생성
→ EffectRecipe 또는 SubRecipe
```

### 사용 제한

`한 턴에 한 번`, `대상당 한 번`, `공격마다` 같은 제한은 `UsageGate`를 사용한다.

무기 인스턴스에 `masteryUsedThisTurn` 같은 임의 불리언을 추가하지 않는다.

---

## 21. 마법 무기

마법 무기는 다음을 조합할 수 있다.

```text
ItemInstance modifier
+ ConditionalCapabilityGroup
+ ItemActionDefinition
+ EffectDefinition
```

예시:

```text
장착 중 공격 +1
→ ContextModifierCapability: attack_roll

피해 +1
→ ContextModifierCapability: damage_roll 또는 damage component

명중 시 추가 화염 피해
→ TriggerCapability / ActionAugmentCapability

하루 1회 주문 사용
→ ItemActionDefinition + ResourceCapability
```

하나의 거대한 `MagicWeaponHandler`를 만들지 않는다.

---

## 22. 방패와 방어구

방패와 방어구는 공격 프로필이 아니라 장착 기반 패시브를 주로 제공한다.

```text
ShieldDefinition
→ hand occupancy
→ equipped ConditionalCapabilityGroup
→ armor class contribution
```

```text
ArmorDefinition
→ worn slot occupancy
→ armor calculation RuleOverride
→ movement or ability restrictions
```

방패 밀치기나 특수 공격이 존재하면 별도 `ItemActionDefinition` 또는 `AttackModeDefinition`을 추가할 수 있다.

---

## 23. 아이템 행동

```text
ItemActionDefinition
├─ itemActionId
├─ activationContext
├─ actionEconomyCost
├─ equipmentPredicate
├─ targetingPlanId?
├─ resourceOrQuantityCosts[]
├─ attackModeReference?
├─ effectRecipeId
├─ usageGates[]
└─ presentationProfileId
```

예시:

- 물약 마시기
- 물약을 다른 대상에게 사용
- 지팡이 충전으로 주문 시전
- 폭탄 투척
- 마법 아이템의 명령어 행동
- 도구를 이용한 장면 상호작용

폭탄처럼 공격 굴림이나 영역 효과가 있으면 기존 TargetingPlan과 EffectRecipe를 사용한다.

---

## 24. 아이템 소비와 CommitGroup

아이템 수량, 탄약, 충전과 투척 상태는 효과와 연결된 확정 정책을 가진다.

```text
ItemConsumptionPlan
├─ reservations[]
├─ commitTrigger
├─ linkedCommitGroupId
├─ failurePolicy
└─ refundPolicy
```

예시:

### 물약

```text
사용 선언
→ 물약 1개 예약
→ 대상과 효과 검증
→ 회복 효과와 수량 감소를 함께 확정
```

### 마법 지팡이

```text
충전 예약
→ 주문 실행
→ 규칙상 시전이 확정되는 시점에 충전 소비
```

### 화살

```text
공격 실행 확정
→ 화살 수량 감소
→ 명중 여부와 무관하게 기본적으로 소비
```

정확한 시점은 규칙 콘텐츠가 소유한다.

---

## 25. 캐시와 무효화

AttackProfile은 다음 의존성을 가진다.

```text
equipment.changed
inventory.changed
item_instance.changed
attunement.changed
ability_score.changed
proficiency.changed
condition.changed
ongoing_effect.changed
feature.changed
resource.changed
```

고정 부분은 캐시할 수 있지만 대상 거리, 엄폐, 현재 반응 창과 같은 일회성 문맥은 공격 실행 시 계산한다.

장면의 모든 Actor 공격 프로필을 매 프레임 재계산하지 않는다.

---

## 26. UI

공격 선택 UI는 현재 사용할 수 있는 프로필만 보여준다.

```text
[장검 — 한 손]
명중: +6
피해: 1d8+4
도달거리: 5피트
마스터리: 활성

[장검 — 양손]
사용 불가: 다른 손에 방패 장착
```

상세 설명에서는 계산 근거를 보여준다.

```text
명중 +6
├─ 힘 수정치 +4
├─ 숙련 보너스 +2
└─ 상태 보정 없음
```

탄약·충전·아이템 수량과 사용 불가 이유를 함께 표시한다.

클라이언트 표시는 서버 권위 계산 결과의 스냅샷이며 최종 판정이 아니다.

---

## 27. 대표 실행 사례

### 27.1 추가 공격이 있는 장검 사용자

```text
AttackActionContainer: capacity 2

슬롯 1
→ 장검 한 손 AttackProfile
→ 공격 확정

이동

슬롯 2
→ 장검 한 손 AttackProfile 재검증
→ 공격 확정
```

### 27.2 방패를 내려놓고 양손 공격

```text
방패 해제 명령
→ 손 점유와 AC Capability 갱신
→ 장검 양손 모드 활성화
→ AttackProfile 재컴파일
```

### 27.3 단검 투척

```text
단검 투척 모드 선택
→ 대상과 사거리 검증
→ 단검 인스턴스 예약
→ 공격 실행
→ 단검이 손에서 장면 위치로 전환
→ 피해 확정
```

### 27.4 마지막 화살

```text
화살 quantity = 1
→ 공격 A가 화살 예약
→ 공격 B는 탄약 부족으로 거부
→ 공격 A 확정 시 quantity 0
```

### 27.5 마스터리 효과

```text
적격 무기 공격 명중
→ AttackHitConfirmed
→ MasteryBinding의 TriggerCapability 조회
→ UsageGate 검증
→ 자동 또는 선택 EffectRecipe
→ 상태·이동·추가 공격 효과 해결
```

### 27.6 마법 검

```text
기본 장검 AttackProfile
+ 아이템 인스턴스 명중 보너스
+ 장착 중 추가 피해 Capability
+ 명중 후 제한 사용 Trigger
→ 최종 공격 프로필과 EffectRecipe
```

---

## 28. 서버 검증

서버는 다음을 확인한다.

- 아이템 인스턴스가 실제로 존재하는가
- 실행 Actor가 해당 아이템에 접근 가능한가
- 아이템 정의와 버전이 유효한가
- 공격 모드가 현재 장착과 손 점유에서 가능한가
- 숙련과 능력치 선택이 규칙에 맞는가
- 대상이 사거리·시야·효과선 조건을 만족하는가
- 탄약, 수량과 충전이 남아 있고 예약 가능한가
- 마스터리 접근 권한과 UsageGate가 유효한가
- 공격 슬롯과 행동 기회가 남아 있는가
- 아이템·장비·Actor revision이 변하지 않았는가

클라이언트는 다음을 결정하지 않는다.

- 명중 수정치
- 피해 구성요소
- 숙련 적용 여부
- 손 점유 가능 여부
- 탄약 소비 성공
- 마스터리 발동 적격성

---

## 29. 테스트 기준

필수 테스트:

1. 한 손 장검과 양손 장검이 같은 아이템 정의에서 다른 피해 프로필을 만든다.
2. 방패 장착 중 양손 모드가 비활성화된다.
3. 방패 해제 후 AC와 공격 모드 캐시가 갱신된다.
4. finesse 공격에서 적격 능력치 선택이 서버 검증된다.
5. 숙련이 없는 무기에 숙련 보너스가 적용되지 않는다.
6. 장거리 공격에 적절한 굴림 문맥이 적용된다.
7. 대상 선택 취소 시 탄약 예약이 반환된다.
8. 공격 굴림 실행 후 빗나가도 탄약이 정책대로 소비된다.
9. 마지막 탄약을 동시에 두 실행이 소비하지 못한다.
10. 투척 무기가 손에서 장면 상태로 정확히 전환된다.
11. 추가 공격의 각 슬롯이 최신 장비 상태로 재검증된다.
12. 마스터리 선택이 없는 캐릭터에게 무기의 마스터리 효과가 활성화되지 않는다.
13. 한 턴 1회 마스터리가 UsageGate를 공유한다.
14. 마법 무기 명중 보너스와 추가 피해의 출처가 로그에 분리된다.
15. 아이템 충전과 효과가 같은 확정 정책으로 처리된다.
16. 장비 변경 후 오래된 AttackProfileSnapshot이 revision 오류로 거부된다.
17. 재접속 후 아이템 인스턴스, 손 점유와 충전 상태가 복원된다.
18. 몬스터 장비 공격도 동일한 AttackProfileCompiler를 사용할 수 있다.

---

## 30. 명시적 비목표

- 캐릭터 저장 데이터에 완성된 공격 수정치와 피해를 권위 값으로 저장하지 않는다.
- 무기마다 별도 공격 처리기를 만들지 않는다.
- 한 손·양손·투척 모드를 별도 아이템 복사본으로 만들지 않는다.
- 탄약과 충전을 클라이언트가 직접 차감하지 않는다.
- Weapon Mastery를 무기 ID 분기문으로 구현하지 않는다.
- 장비 변경 시 모든 캐릭터와 모든 공격을 전체 재계산하지 않는다.
- 아이템 설명 문자열을 파싱하여 공격 속성을 추론하지 않는다.

---

## 31. 다음 단계

다음은 HP 0, 죽음 내성, 짧은 휴식·긴 휴식과 자원 회복을 하나의 캐릭터 생존·회복 규약으로 정리한다.

주요 범위:

1. HP 0과 의식불명 전환
2. 죽음 내성 성공·실패 기록
3. 안정화와 피해 시 실패 누적
4. 즉사와 사망 처리
5. 짧은 휴식의 히트 다이스 사용
6. 긴 휴식의 HP·히트 다이스·자원 회복
7. 휴식을 중단하는 사건
8. EffectInstance와 UsageGate의 휴식 종료
9. 주문 슬롯과 특성 자원 회복
10. 재접속과 서버 복구 중 휴식 상태