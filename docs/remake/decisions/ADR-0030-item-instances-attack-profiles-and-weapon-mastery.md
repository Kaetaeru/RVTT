# ADR-0030: 무기와 아이템 공격은 인스턴스 기반 AttackProfile로 컴파일한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0014`](ADR-0014-character-data-and-scene-actor-separation.md)
  - [`ADR-0017`](ADR-0017-derived-fixed-grants-and-stored-selections.md)
  - [`ADR-0026`](ADR-0026-active-capabilities-action-containers-and-unit-replacements.md)
  - [`ADR-0027`](ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`24. 무기·아이템·공격 프로필 모델`](../24-item-weapon-attack-profile-and-mastery-model.md)

## 배경

무기와 아이템은 단순한 공격 버튼 목록이 아니다.

- 같은 무기 정의라도 개별 인스턴스마다 마법 보너스, 충전, 손상, 귀속과 사용자 지정 이름이 다를 수 있다.
- 장검처럼 한 손과 양손 사용 모드가 달라질 수 있다.
- 활은 탄약과 두 손 점유가 필요하고, 투척 무기는 공격 후 현재 손에서 사라질 수 있다.
- 특정 특성은 공격 능력치, 사거리, 피해 유형, 추가 효과와 숙련 판정을 바꾼다.
- Weapon Mastery는 무기 정의에 고정된 자동 효과가 아니라 사용자의 선택·숙련과 공격 결과에 따라 활성화되는 규칙 기능이다.
- 추가 공격, 기회 공격, 보너스 행동 공격과 몬스터 다중공격이 모두 같은 공격 해결 엔진을 사용해야 한다.

무기마다 완성된 공격 수치를 저장하면 능력치, 숙련, 상태, 장비와 특성 변화에 따라 데이터가 쉽게 낡는다.

반대로 공격 시점마다 모든 아이템·특성·효과를 임의 순회하면 성능과 설명 가능성이 나빠지고, 탄약·손 점유·투척 소모를 일관되게 확정하기 어렵다.

## 결정

아이템 콘텐츠 정의, 소유 인스턴스, 장착 상태와 현재 공격 실행을 분리한다.

```text
ItemDefinition / WeaponDefinition
+ ItemInstance
+ EquipmentState
+ Character Capability Set
+ 현재 RuleContext
→ AttackProfileCompiler
→ AttackProfileSnapshot
→ ActionUnitExecution
→ EffectRecipe
```

`AttackProfileSnapshot`은 공격 실행 한 번을 위해 서버가 생성한 파생 스냅샷이다. 캐릭터 저장 데이터의 권위 원본이 아니다.

## 정의와 인스턴스

```text
ItemDefinition
├─ itemId
├─ itemKind
├─ tags
├─ equipProfile
├─ grantedCapabilities
├─ itemActions
└─ presentation

WeaponDefinition
├─ weaponCategory
├─ weaponProperties
├─ attackModes
├─ baseDamageProfiles
├─ rangeProfiles
├─ ammunitionProfile?
├─ throwProfile?
├─ masteryPropertyId?
└─ proficiencyTags
```

```text
ItemInstance
├─ itemInstanceId
├─ definitionId와 version
├─ ownerScope
├─ quantity
├─ conditionState
├─ charges
├─ attunementState
├─ customName?
├─ instanceModifiers[]
└─ revision
```

정의의 규칙 데이터를 인스턴스에 복사하지 않는다. 인스턴스는 개별 상태와 정의 참조만 저장한다.

## EquipmentState

현재 장착과 손 점유는 Actor 상태다.

```text
EquipmentState
├─ equippedItemBindings[]
├─ handOccupancy
├─ armorBindings[]
├─ activeLoadoutId?
├─ stowedItems[]
└─ revision
```

손은 단순 `mainHand`와 `offHand` 문자열이 아니라 점유 요구를 검증할 수 있는 리소스다.

- 한 손 무기
- 두 손 무기
- 다용도 무기의 현재 사용 모드
- 방패
- 주문시전 도구
- 탄약 장전과 물체 상호작용

공격 선언 시 서버가 현재 손 점유와 장비 상태를 다시 검증한다.

## AttackModeDefinition

하나의 무기는 여러 공격 모드를 가질 수 있다.

```text
AttackModeDefinition
├─ modeId
├─ attackKind
├─ handRequirement
├─ abilitySelectionPolicy
├─ proficiencyRequirement
├─ rangeProfile
├─ targetProfile
├─ damageProfile
├─ consumptionProfile?
├─ effectRecipeId
└─ tags[]
```

예시:

- 장검 한 손 공격
- 장검 양손 공격
- 단검 근접 공격
- 단검 투척 공격
- 활 원거리 공격
- 아이템이 제공하는 특수 공격

모드 차이를 별도 아이템 복사본으로 만들지 않는다.

## AttackProfileSnapshot

```text
AttackProfileSnapshot
├─ attackProfileId
├─ sourceItemInstanceId?
├─ sourceCapabilityId
├─ modeId
├─ attackKind
├─ selectedAbilityId
├─ proficiencyState
├─ attackModifierBreakdown
├─ rangeState
├─ damageComponents[]
├─ handRequirement
├─ consumptionPlan
├─ masteryBindings[]
├─ effectRecipeId
├─ presentationProfileId
├─ ruleSnapshot
└─ revisionSet
```

공격 수정치와 피해는 최종 숫자만 저장하지 않고 기여 출처를 유지한다.

## 공격 실행

```text
AttackUnitSlot 선택
→ 사용 가능한 AttackProfile 후보 생성
→ 공격 모드와 대상 선택
→ 손·장비·사거리·탄약·숙련 검증
→ 비용과 소비 예약
→ RollAttack
→ 명중 결과에 따라 EffectRecipe
→ 아이템·탄약·투척 상태와 효과를 CommitGroup으로 확정
```

기회 공격과 보너스 행동 공격도 새로운 공격 엔진을 만들지 않고, 허용된 `AttackProfileSnapshot`을 선택하여 같은 실행 절차를 사용한다.

## 탄약과 투척

탄약과 투척 무기 상태는 공격 선언 즉시 영구 변경하지 않는다.

```text
ConsumptionPlan
├─ reservations[]
├─ consumeOn
├─ recoveryPolicy?
├─ dropOrPlacementPolicy?
└─ rollbackPolicy
```

`consumeOn`은 규칙 세트와 콘텐츠가 결정한다.

- 공격 확정 시
- 발사 또는 투척 실행 시
- 명중 시
- 효과 적용 시

대상 선택 중 취소나 서버 검증 실패에서는 예약을 해제한다. 실제 공격이 실행된 뒤 빗나갔다고 기본적으로 탄약을 반환하지 않는다.

투척 무기는 확정 시 손 점유에서 빠지고, 장면 오브젝트·대상 인벤토리·회수 가능 기록 중 정의된 위치로 전환된다.

## 사거리

거리 값은 피트 단위 규칙 값으로 저장하며 장면 어댑터가 스터드로 변환한다.

```text
RangeProfile
├─ reach?
├─ normalRange?
├─ longRange?
├─ minimumRange?
├─ lineOfEffectPolicy
└─ rangeBandRules
```

정상 사거리, 장거리, 도달거리와 불리점은 공격 정의와 현재 `RuleContext`를 통해 계산한다. UI 미리보기는 권위 판정이 아니다.

## Weapon Mastery

마스터리 속성은 무기 정의가 참조하는 규칙 콘텐츠지만, 실제 사용 권한은 캐릭터의 선택과 Capability에서 온다.

```text
WeaponDefinition
→ masteryPropertyId

Character progression choice
→ WeaponMasteryAccessCapability

공격 프로필 컴파일
→ 무기와 선택이 일치하면 MasteryBinding 활성화
```

마스터리는 다음 형태로 컴파일될 수 있다.

- `ContextModifierCapability`
- `TriggerCapability`
- `ActionAugmentCapability`
- `RuleOverrideCapability`
- 공격 EffectRecipe의 추가 노드 또는 하위 레시피

명중 전, 명중 후, 피해 적용 후와 턴당 사용 제한을 기존 TimingWindow와 UsageGate로 표현한다.

무기 ID를 기준으로 중앙 공격 코드에서 분기하지 않는다.

## 아이템 행동

소모품, 마법 아이템과 도구의 능동 기능은 `ItemActionDefinition`으로 제공한다.

```text
ItemActionDefinition
├─ activationContext
├─ actionEconomyCost
├─ equipmentPredicate
├─ chargeOrQuantityCost
├─ targetingPlan
├─ effectRecipeId
└─ usageGates[]
```

아이템 행동은 공격일 수도 있고, 회복·소환·상태 적용·장면 상호작용일 수도 있다. 공격인 경우 같은 `AttackProfile`과 `EffectRecipe` 계약을 사용한다.

## 장비가 부여하는 패시브

장착, 들기, 조율과 소유 조건에 따라 아이템 Capability가 활성화된다.

```text
ItemInstance
+ EquipmentState
+ AttunementState
→ ConditionalCapabilityGroup
→ 패시브·행동·트리거 Capability 활성화
```

아이템을 해제해도 획득 기록과 인스턴스를 삭제하지 않고 현재 Capability만 비활성화한다.

## 서버 권한

- 서버가 현재 인벤토리, 장착, 손 점유, 탄약, 충전과 아이템 revision을 검증한다.
- 클라이언트는 공격 수정치, 숙련 적용 여부, 남은 탄약과 마스터리 발동 가능 여부를 확정하지 않는다.
- 공격 스냅샷은 실행 시점의 정의와 규칙 버전에 고정된다.
- 공격 확정과 아이템 소비는 같은 CommitGroup 또는 명시적 연결 그룹으로 처리한다.
- 같은 아이템 수량과 충전을 동시에 소비하는 요청은 revision과 예약으로 충돌을 방지한다.

## 결과

- 무기 정의와 개별 아이템 상태를 분리할 수 있다.
- 한 무기의 근접·투척·한손·양손 모드를 같은 정의에서 표현할 수 있다.
- 추가 공격, 반응 공격, 몬스터 공격과 아이템 특수 공격이 같은 공격 엔진을 사용한다.
- 탄약, 투척 무기, 충전과 수량 소비를 취소·재전송에 안전하게 처리할 수 있다.
- Weapon Mastery를 무기별 하드코딩 없이 기존 Capability와 TimingWindow로 구현할 수 있다.
- 공격 수치의 계산 근거를 시트와 로그에서 설명할 수 있다.