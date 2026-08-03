# 26. 몬스터·NPC 스탯블록과 인게임 JSON 가져오기 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](../../architecture/rules-content-grant-capability-model.md)
  - [`19. 트리거와 다른 턴 실행 모델`](../rules/feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](../rules/active-feature-and-action-container-execution-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`23. 상태·지속 효과·집중 수명주기 모델`](../rules/condition-ongoing-effect-duration-and-concentration-model.md)
  - [`24. 무기·아이템·공격 프로필 모델`](../inventory/item-weapon-attack-profile-and-mastery-model.md)
  - [`25. HP 0·죽음 내성·휴식·자원 회복 모델`](zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
  - [`ADR-0032`](../../decisions/ADR-0032-monster-npc-statblocks-and-safe-ingame-json-import.md)

## 1. 문서 목적

이 문서는 공식 몬스터, 캠페인 NPC, 즉석 전투원과 DM이 인게임에서 JSON으로 추가하는 사용자 NPC를 같은 규칙 엔진에서 실행하는 구조를 정의한다.

대상은 다음을 포함한다.

- 몬스터와 NPC의 재사용 가능한 스탯블록
- 장면에 생성된 개별 Actor 상태
- 일반 행동, 보너스 행동과 반응
- 다중공격
- 재충전 능력
- 전설적 행동과 은신처 행동
- 주문 시전 NPC
- 장비 기반 공격과 내장 공격
- DM 인게임 JSON 붙여넣기
- JSON 검증, 미리보기, 저장, 수정과 내보내기
- 캠페인 전용 콘텐츠 버전 관리
- 안전 상한과 사용자 콘텐츠 격리

핵심 원칙:

```text
공식 몬스터
캠페인 NPC
DM JSON NPC

→ 서로 다른 실행 엔진이 아니다
→ 모두 ActorDefinition과 공통 Capability·Recipe로 컴파일한다
```

---

## 2. 전체 구조

```text
Source Statblock
├─ developer content pack
├─ campaign authored definition
├─ imported JSON
└─ session temporary JSON

→ StatblockCompiler
→ ActorDefinition
→ ActorInstance
→ Capability Set
→ ActionPackage
→ TargetingPlan
→ EffectRecipe
```

### ActorDefinition

여러 Actor가 공유할 수 있는 콘텐츠 정의다.

### ActorInstance

현재 장면에 존재하는 실제 토큰 상태다.

```text
ActorDefinition
≠ ActorInstance
```

같은 `goblin` 정의에서 12개의 고블린 Actor를 만들어도 HP, 위치, 상태와 탄약은 각각 독립적이다.

---

## 3. ActorDefinition

```text
ActorDefinition
├─ actorDefinitionId
├─ schemaVersion
├─ rulesetId
├─ sourcePackId?
├─ trustLevel
├─ actorKind
├─ identityProfile
├─ statblock
├─ defaultInventory[]
├─ defaultEquipment[]
├─ innateAttackProfiles[]
├─ grantedCapabilities[]
├─ actionPackages[]
├─ spellcastingProfiles[]
├─ resourceDefinitions[]
├─ presentationProfile
├─ tokenProfile
├─ actorDeathPolicy
└─ diagnosticsProfile
```

### actorKind

```text
monster
npc
companion
summon
hazard
construct
vehicle_component
custom_registered
```

분류는 표시와 기본 정책을 선택하지만 특정 몬스터 이름에 따른 실행 분기에는 사용하지 않는다.

---

## 4. IdentityProfile

```text
IdentityProfile
├─ displayName
├─ singularName?
├─ pluralName?
├─ description?
├─ alignmentTag?
├─ creatureTypeTags[]
├─ factionTags[]
├─ roleTags[]
└─ visibilityPolicy
```

DM은 내부 이름과 플레이어 공개 이름을 다르게 설정할 수 있다.

```text
DM 표시: 변장한 뱀파이어 귀족
플레이어 표시: 알드릭 경
```

비밀 태그와 실제 유형은 권한이 없는 클라이언트에 전송하지 않는다.

---

## 5. StatblockDefinition

```text
StatblockDefinition
├─ size
├─ abilityScores
├─ proficiencyProfile
├─ armorClassProfile
├─ hitPointProfile
├─ movementModes[]
├─ savingThrows[]
├─ skills[]
├─ senses[]
├─ languages[]
├─ damageResponses[]
├─ conditionImmunities[]
├─ passiveTraits[]
├─ resources[]
├─ actions[]
├─ bonusActions[]
├─ reactions[]
├─ legendaryProfile?
├─ lairProfile?
├─ spellcastingProfiles[]
└─ encounterMetadata?
```

스탯블록은 실행 시 최종 수치를 모두 복사한 객체가 아니다. 규칙에 따라 계산되어야 하는 값은 정의와 Modifier에서 파생한다.

---

## 6. 능력치, HP와 AC

```text
AbilityScoreSet
├─ strength
├─ dexterity
├─ constitution
├─ intelligence
├─ wisdom
└─ charisma
```

```text
HitPointProfile
├─ maximumPolicy
├─ fixedMaximum?
├─ hitDiceExpression?
├─ constitutionContributionPolicy
└─ spawnPolicy
```

```text
ArmorClassProfile
├─ baseFormulaId
├─ fixedArmorClass?
├─ equipmentBindings[]
├─ naturalArmorContribution?
└─ modifierCapabilities[]
```

공식 스탯블록처럼 고정 HP와 AC를 사용할 수도 있고, 주사위·장비·자연 방어 공식으로 계산할 수도 있다.

Actor 생성 시 현재 최대 HP를 확정해 `ActorInstance`에 저장한다. 이후 정의가 바뀌어도 기존 Actor의 현재 HP를 임의로 재굴림하지 않는다.

---

## 7. 이동과 감각

```text
MovementModeDefinition
├─ mode: walk | fly | swim | climb | burrow | custom_registered
├─ speedFeet
├─ hover?
├─ surfaceRequirements?
└─ grantedMovementCapabilities[]
```

```text
SenseDefinition
├─ senseKind
├─ rangeFeet?
├─ precisionPolicy
└─ visibilityPolicy
```

이동은 장면의 의미 내비게이션과 연결하고, 감각은 시야·탐지 시스템의 등록된 SenseDefinition만 참조한다.

---

## 8. 피해 반응과 상태 면역

```text
DamageResponseDefinition
├─ predicate
├─ responseKind: resistance | immunity | vulnerability | reduction
├─ valueExpression?
└─ bypassPredicate?
```

```text
ConditionImmunityDefinition
├─ conditionId?
├─ effectTagPredicate?
└─ applicationPolicy
```

이들은 `ContextModifierCapability` 또는 `RuleOverrideCapability`로 컴파일되어 기존 피해·상태 파이프라인에 기여한다.

---

## 9. PassiveTraitDefinition

```text
PassiveTraitDefinition
├─ traitId
├─ localization
├─ grants[]
├─ visibilityPolicy
└─ diagnosticsKey
```

예시:

- 마법 저항
- 무리 전술
- 빛 민감성
- 재생
- 전설적 저항
- 특정 형태에서만 활성화되는 특성

구현 형태는 다음 중 하나 이상이다.

```text
DerivedValueModifierCapability
ContextModifierCapability
RuleOverrideCapability
ConditionalCapabilityGroup
TriggerCapability
ResourceCapability
```

설명 텍스트를 파싱하여 효과를 추론하지 않는다.

---

## 10. StatblockActionDefinition

```text
StatblockActionDefinition
├─ actionId
├─ displayProfile
├─ activationContext
├─ actionEconomyCost
├─ usageGates[]
├─ resourceCosts[]
├─ prerequisites[]
├─ targetingPlan
├─ effectRecipeId
├─ attackProfileReference?
├─ rechargePolicy?
├─ visibilityPolicy
└─ tags[]
```

### activationContext

```text
action
bonus_action
reaction
attack_unit
legendary_action
lair_action
free_special
out_of_combat
custom_registered
```

행동은 이름에 따라 전용 코드를 실행하지 않는다.

---

## 11. 장비 공격과 내장 공격

NPC 공격은 두 종류로 나눌 수 있다.

### 실제 아이템 기반

```text
고블린
→ ItemInstance: scimitar
→ EquipmentState
→ AttackProfileCompiler
```

무기를 떨어뜨리거나 빼앗을 수 있으며 인벤토리와 손 점유를 실제로 사용한다.

### 내장 공격 프로필

```text
늑대 물기
용 발톱
촉수
슬라임 의사족
```

이들은 `InnateAttackProfileDefinition`으로 제공한다.

```text
InnateAttackProfileDefinition
├─ attackMode
├─ abilitySelectionPolicy
├─ proficiencyPolicy
├─ rangeProfile
├─ damageProfile
├─ targetingPlan
└─ effectRecipeId
```

내장 공격도 일반 `AttackProfileSnapshot`으로 컴파일하여 같은 공격·피해 엔진을 사용한다.

---

## 12. 다중공격

다중공격은 하나의 거대한 피해 레시피가 아니다.

```text
MultiattackDefinition
├─ containerProfileId
├─ allowedSequences[]
├─ unitOptions[]
├─ selectionPolicy
├─ targetChangePolicy
├─ movementBetweenUnitsPolicy
├─ interruptionPolicy
└─ diagnosticsKey
```

예시:

```text
두 번 공격
→ AttackUnitSlot × 2

물기 1회 + 발톱 2회
→ 고정된 UnitSequence

창 2회 또는 장궁 2회
→ 대체 Sequence 선택
```

각 공격 단위는 별도 `ActionUnitExecution`과 `CommitGroup`을 사용한다. 첫 공격 결과는 두 번째 공격 취소 시 되돌리지 않는다.

---

## 13. RechargePolicy

```text
RechargePolicy
├─ rechargeKind
├─ triggerEvent
├─ rollExpression?
├─ successValues?
├─ restoreAmount
├─ initialAvailabilityPolicy
└─ visibilityPolicy
```

종류 예시:

```text
roll_at_turn_start
roll_at_round_start
restore_after_rest
restore_after_condition
manual_dm
custom_registered
```

실행 흐름:

```text
TurnStarted
→ 재충전 대상 Resource 조회
→ Recharge EffectRecipe
→ 성공 시 ResourceChange 확정
```

재충전 결과는 서버가 굴리고 전투 로그 가시성 정책에 따라 공개한다.

---

## 14. 전설적 저항

전설적 저항은 내성 굴림 값을 수동으로 조작하는 필드가 아니다.

```text
SavingThrowFailed
→ TriggerCapability
→ 전설적 저항 사용 제안
→ ResourceCost
→ ReplaceRollOutcome 또는 ReplaceResponseExecution
```

DM은 실패 결과와 남은 횟수를 확인하고 사용할 수 있다. 사용하지 않으면 원래 실패 결과가 진행된다.

---

## 15. 전설적 행동

```text
LegendaryActionProfile
├─ resourceDefinition
├─ refreshPolicy
├─ timingPolicy
├─ actionOptions[]
├─ eligibilityPredicate
└─ turnRelationPolicy
```

일반적인 흐름:

```text
다른 생물의 턴 종료
→ LegendaryActionOpportunity
→ DM에게 사용 가능한 행동 표시
→ 행동 선택
→ 비용 지불
→ 일반 ActionCapability 실행
```

전설적 행동은 독립적인 공격 엔진을 사용하지 않는다. 공격이면 AttackProfile, 효과면 EffectRecipe를 사용한다.

---

## 16. 은신처 행동과 지역 효과

```text
LairActionProfile
├─ initiativeTimingPolicy
├─ optionSelectionPolicy
├─ repeatRestriction?
├─ actionOptions[]
└─ sceneRequirementPredicate
```

은신처 행동은 Actor 또는 SceneRuleEffect가 제공하는 타이밍 기반 ActionOpportunity다.

지역 효과는 장기 규칙이라면 `EffectInstance`와 장면 Trigger를 사용한다.

---

## 17. 주문 시전 NPC

```text
NpcSpellcastingProfile
├─ spellcastingProfileId
├─ castingAbility
├─ saveDcPolicy
├─ attackModifierPolicy
├─ spellAccessEntries[]
├─ slotOrUseResources[]
├─ componentModeOverride?
├─ preparedSelectionPolicy?
└─ displayPolicy
```

지원 예시:

- 주문 슬롯을 사용하는 정규 시전자
- 하루 n회 주문
- 상시 사용 주문
- 재충전 주문
- 특정 행동으로만 사용하는 주문형 효과

실제 주문 실행은 기존 SpellDefinition, TargetingPlan과 EffectRecipe를 참조한다.

---

## 18. ActorInstance

```text
ActorInstance
├─ actorId
├─ definitionReference
├─ displayOverrides?
├─ sceneBinding
├─ controllerBindings[]
├─ hitPointState
├─ vitalState
├─ resourceStates[]
├─ inventoryState
├─ equipmentState
├─ effectInstanceIds[]
├─ initiativeState?
├─ actionState
├─ runtimeOverrides[]
└─ revision
```

정의에서 같은 NPC를 여러 번 생성해도 각 Actor는 독립 revision과 전투 상태를 가진다.

---

## 19. DM 인게임 NPC JSON 기능

DM UI에 `NPC JSON 가져오기` 창을 제공한다.

```text
NPC 라이브러리
→ 새 NPC
→ JSON 붙여넣기
→ 검증
→ 미리보기
→ 캠페인에 저장 또는 이번 세션만 사용
→ 장면에 배치
```

### 편집 영역

- JSON 코드 편집기
- 줄 번호와 구문 강조
- 오류 위치 표시
- 자동 포맷
- 스키마 버전 표시
- 예제 불러오기
- 정규화 결과 보기

### 미리보기

- 이름과 토큰
- HP, AC, 속도와 감각
- 능력치와 내성
- 피해 반응과 상태 면역
- 행동, 반응과 자원
- 계산된 공격 수정치와 피해
- 컴파일 경고

미리보기는 서버 컴파일 결과를 사용한다.

---

## 20. 외부 JSON 스키마

외부 스키마는 내부 런타임 구조보다 단순하고 안정적이어야 한다.

최상위 구조 예시:

```json
{
  "schemaVersion": 1,
  "kind": "npc",
  "id": "campaign.bandit-captain-variant",
  "name": "산적 대장",
  "size": "Medium",
  "creatureTypes": ["Humanoid"],
  "token": {
    "prefabId": "Thug"
  },
  "abilities": {
    "str": 16,
    "dex": 14,
    "con": 14,
    "int": 10,
    "wis": 11,
    "cha": 12
  },
  "armorClass": {
    "fixed": 15
  },
  "hitPoints": {
    "fixed": 65
  },
  "movement": {
    "walk": 30
  },
  "actions": [
    {
      "id": "scimitar",
      "name": "시미터",
      "type": "weaponAttack",
      "attack": {
        "kind": "melee",
        "ability": "str",
        "proficient": true,
        "reach": 5,
        "damage": [
          {
            "dice": "1d6",
            "abilityModifier": true,
            "type": "slashing"
          }
        ]
      }
    }
  ]
}
```

이 예시는 외부 저작 형식이다. 서버는 이를 내부 `ActorDefinition`, Capability와 EffectRecipe로 변환한다.

---

## 21. JSON에서 지원하는 행동 템플릿

초기 사용자 스키마는 완전 자유 그래프보다 안전한 고수준 템플릿을 우선 제공한다.

```text
weaponAttack
spellAttack
savingThrowEffect
automaticEffect
multiattack
healing
conditionApplication
forcedMovement
resourceAbility
rechargeAbility
spellcastingReference
```

예시: 내성 굴림 기반 숨결

```json
{
  "id": "fire-breath",
  "name": "화염 숨결",
  "type": "savingThrowEffect",
  "recharge": {
    "type": "rollAtTurnStart",
    "die": "1d6",
    "success": [5, 6]
  },
  "targeting": {
    "shape": "cone",
    "length": 30
  },
  "save": {
    "ability": "dex",
    "dc": 15
  },
  "damage": {
    "dice": "6d6",
    "type": "fire",
    "onSuccess": "half"
  }
}
```

서버는 이를 다음으로 컴파일한다.

```text
ResourceCapability
+ RechargePolicy
+ AreaPlacement TargetingPlan
+ RollSavingThrow
+ OutcomeMap
+ CreateDamage
```

---

## 22. 등록 참조

사용자 JSON은 등록된 콘텐츠를 참조할 수 있다.

```json
{
  "type": "spellcastingReference",
  "spellId": "dnd5e2024.fireball",
  "uses": {
    "perDay": 1
  }
}
```

참조 가능 대상:

- 주문
- ConditionDefinition
- 피해 유형
- 감각
- 아이템
- 토큰 프리팹
- 안전한 EffectRecipe 템플릿

캠페인에서 사용할 수 없는 출처 팩의 ID나 존재하지 않는 ID는 검증 오류다.

---

## 23. 고급 Recipe JSON

초기 일반 DM UI는 고수준 행동 템플릿을 권장한다.

고급 모드에서는 등록된 안전 노드만으로 제한된 Recipe를 작성할 수 있다.

```text
허용
→ 등록된 노드
→ 타입 있는 바인딩
→ 제한된 Branch·ForEach
→ 명시적 최대 반복

금지
→ handlerId
→ custom code
→ engine service path
→ arbitrary module
→ unbounded repeat
```

캠페인 설정에서 고급 JSON 저작을 끌 수 있다.

---

## 24. 검증 단계

### 24.1 구문 검증

- 유효한 UTF-8 JSON
- 중복 키 정책
- 최대 문서 크기
- 최대 중첩 깊이
- 문자열·배열 길이

### 24.2 구조 검증

- 필수 필드
- enum 값
- 타입 일치
- schemaVersion
- 알 수 없는 필드

### 24.3 의미 검증

- 능력치와 수치 범위
- 유효한 피해 유형과 상태 ID
- 사거리와 영역 값
- 공격과 피해 구성
- 다중공격 참조
- 자원 비용과 회복 정책
- Recipe 그래프 도달 가능성

### 24.4 권한 검증

- DM 권한
- 캠페인 편집 권한
- 허용된 출처 팩
- 사용 가능한 토큰 에셋
- 개발자 전용 노드 참조 금지

### 24.5 성능 검증

- 행동 개수 상한
- 다중공격 단위 수 상한
- 대상 수 상한
- 생성 Effect 수 상한
- Trigger 수 상한
- 반복·분기 깊이 상한

---

## 25. 오류 계약

```text
ImportDiagnostic
├─ severity
├─ code
├─ jsonPath
├─ messageKey
├─ parameters
├─ suggestedFix?
└─ documentationKey?
```

예시:

```text
ERROR NPC_ACTION_REFERENCE_NOT_FOUND
path: $.multiattack.options[1].actionId
message: "bite" 행동을 찾을 수 없습니다.
```

```text
WARNING FIXED_ATTACK_BONUS_IGNORES_ABILITY
path: $.actions[0].attack.bonus
message: 고정 명중 보너스를 사용하므로 능력치 변경이 반영되지 않습니다.
```

오류가 있으면 저장과 소환을 막고, 경고만 있으면 DM이 확인 후 진행할 수 있다.

---

## 26. 정규화와 컴파일 미리보기

가져오기 결과는 세 층으로 보관한다.

```text
Source JSON
→ Normalized External Definition
→ Compiled Internal Definition
```

### 정규화

- 기본값 채움
- ID 정규화
- enum 표준화
- shorthand 확장
- 참조 해석

### 컴파일

- Capability 생성
- TargetingPlan 생성
- EffectRecipe 생성 또는 참조
- Resource와 Recharge 생성
- ActionPackage 생성
- 성능 비용 계산

DM은 저장 전에 정규화된 결과와 예상 스탯블록을 확인할 수 있다.

---

## 27. 저장 범위

```text
SaveScope
├─ campaign_library
├─ session_temporary
└─ personal_draft
```

### campaign_library

캠페인의 모든 DM이 재사용할 수 있다.

### session_temporary

현재 서버 세션에서만 존재하며 재시작 후 제거된다.

### personal_draft

작성자만 볼 수 있는 미완성 초안이다. 검증 완료 전 장면에 배치할 수 없다.

---

## 28. CampaignContentEntry

```text
CampaignContentEntry
├─ contentId
├─ contentKind
├─ schemaVersion
├─ revision
├─ trustLevel
├─ sourceJson
├─ normalizedDefinition
├─ compiledArtifactReference
├─ compileDiagnostics[]
├─ createdBy
├─ updatedBy
├─ createdAt
├─ updatedAt
├─ publicationState
└─ revisionHistory[]
```

정의 수정은 기존 revision을 덮어쓰지 않고 새 revision을 만든다.

---

## 29. 기존 Actor에 정의 수정 적용

정의가 수정되어도 이미 장면에 있는 Actor를 자동 변경하지 않는다.

DM 선택:

```text
새 revision은 이후 소환부터 사용
현재 Actor의 정의만 갱신
현재 HP 비율 유지하며 갱신
현재 전투 상태 초기화 후 갱신
선택한 Actor만 갱신
```

업데이트 전 영향 미리보기를 제공한다.

- 최대 HP 변경
- AC 변경
- 삭제되는 행동
- 자원 ID 변경
- 지속 효과와 장비 충돌

안전하게 마이그레이션할 수 없으면 새 Actor 생성 또는 DM 판정을 권장한다.

---

## 30. JSON 내보내기

캠페인 NPC는 외부 JSON 스키마로 다시 내보낼 수 있다.

```text
CampaignContentEntry
→ Export Normalizer
→ portable NPC JSON
```

내보내기에는 현재 Actor의 HP나 장면 위치를 기본적으로 포함하지 않는다.

별도의 `ActorSnapshot Export` 기능에서만 런타임 상태를 포함한다.

---

## 31. 인게임 UX

### NPC 라이브러리

- 공식
- 캠페인 제작
- 세션 임시
- 초안
- 최근 사용
- 오류 있음

### 가져오기 결과

```text
검증 성공
→ 저장
→ 저장 후 소환
→ 이번 세션만 소환

검증 경고
→ 경고 검토
→ 승인 후 저장

검증 실패
→ 오류 위치로 이동
→ 수정 후 재검증
```

### 빠른 생성

DM은 JSON 저장 후 바로 다음을 선택할 수 있다.

- 커서 위치에 1개 배치
- 선택 영역에 여러 개 배치
- 비공개 상태로 배치
- 인카운터 그룹에 추가
- 라이브러리에만 저장

---

## 32. 토큰 프리팹과 외형

```text
TokenProfile
├─ prefabId?
├─ customAssetId?
├─ scaleProfile
├─ footprintProfile
├─ nameplateProfile
├─ portraitAssetId?
└─ fallbackProfile
```

사용자 JSON은 캠페인에서 허용된 프리팹·에셋 ID만 참조한다.

에셋이 없거나 권한이 없으면 규칙 정의는 유지하면서 안전한 기본 토큰으로 대체할 수 있다.

외형 메시가 점유 범위와 이동 판정의 권위 원본이 되지 않는다.

---

## 33. DM 런타임 오버라이드

DM은 ActorInstance에 일시적 오버라이드를 적용할 수 있다.

```text
RuntimeOverride
├─ overrideId
├─ targetPath
├─ operation
├─ value
├─ sourceDmUserId
├─ durationPolicy
└─ auditRecord
```

예시:

- 현재 HP 조정
- 이번 전투만 AC +2
- 특정 행동 비활성화
- 자원 즉시 충전
- 공개 이름 변경

정의 자체를 바꾸는 편집과 현재 Actor만 바꾸는 오버라이드를 UI에서 명확히 구분한다.

---

## 34. 서버 권한과 보안

- JSON 파싱, 검증, 컴파일과 저장은 서버가 수행한다.
- 클라이언트는 컴파일된 내부 객체나 신뢰 등급을 지정하지 않는다.
- 사용자는 등록된 외부 스키마만 제출한다.
- `handlerId`, ModuleScript, RemoteEvent와 DataStore 경로는 사용자 스키마에서 금지한다.
- URL, require asset ID와 동적 코드 로딩을 허용하지 않는다.
- 캠페인 JSON 콘텐츠는 개발자 서명 콘텐츠보다 낮은 신뢰 등급에서 실행된다.
- 가져오기 실패는 활성 정의, 라이브러리와 장면 상태를 변경하지 않는다.
- 저장, 수정, 삭제와 Actor 갱신은 감사 로그를 남긴다.

---

## 35. 성능

- 원본 JSON은 가져올 때 한 번 파싱하고 컴파일 결과를 캐시한다.
- Actor 생성 시 전체 JSON을 다시 해석하지 않는다.
- 동일 정의 revision은 컴파일 산출물을 공유한다.
- Trigger, Action과 Capability는 기존 이벤트 인덱스에 등록한다.
- 몬스터마다 매 프레임 루프를 만들지 않는다.
- JSON 입력의 최대 크기와 복잡도는 캠페인 정책으로 제한한다.

---

## 36. 재접속과 복구

서버 복구 시 저장된 `ActorInstance`는 정의 ID와 revision으로 컴파일 산출물을 다시 연결한다.

정의 revision이 없거나 손상된 경우:

```text
Actor 격리
→ DM에게 복구 진단 표시
→ 마지막 정상 revision 선택
→ JSON 재가져오기
→ 안전한 비활성 Actor로 유지
```

정의 오류 때문에 Actor를 임의로 삭제하지 않는다.

---

## 37. 대표 사례

### 공식 고블린

```text
Developer Content Pack
→ goblin ActorDefinition
→ 시미터·단궁 ItemInstance
→ Nimble Escape Capability
→ 여러 Actor 생성
```

### 캠페인 고유 기사

```text
기본 veteran 정의 참조
+ 이름·외형 Override
+ 캠페인 전용 반응
+ 고유 장비
→ 새 campaign ActorDefinition
```

### JSON으로 만든 화염 정령

```text
JSON 붙여넣기
→ 화염 면역·냉기 취약 검증
→ 접촉 화염 Trigger 컴파일
→ 내장 공격 프로필 컴파일
→ 미리보기
→ 캠페인 라이브러리 저장
→ 장면 소환
```

### JSON 다중공격

```text
multiattack
→ bite action 참조 1회
→ claw action 참조 2회
→ ActionContainerProfile 컴파일
```

### JSON 주문 시전자

```text
spellcastingReference
→ 등록 주문 ID 해석
→ 사용 횟수 Resource 생성
→ SpellAction Capability 생성
```

### 오류가 있는 JSON

```text
존재하지 않는 conditionId
→ jsonPath와 오류 표시
→ 저장·소환 차단
→ 유효한 Condition 선택 제안
```

---

## 38. 테스트 기준

최소 테스트:

1. 같은 정의로 생성한 여러 Actor의 HP와 자원이 독립적이다.
2. 장비 공격과 내장 공격이 같은 공격 해결 엔진을 사용한다.
3. 다중공격의 첫 공격 확정 후 두 번째 공격 취소가 첫 결과를 롤백하지 않는다.
4. 재충전 성공과 실패가 올바르게 자원 상태를 변경한다.
5. 전설적 행동 비용과 사용 시점이 검증된다.
6. 은신처 행동이 지정된 타이밍에만 제공된다.
7. 주문 시전 NPC가 등록된 주문을 공통 SpellExecution으로 사용한다.
8. 유효한 JSON이 정규화되고 저장 후 즉시 소환된다.
9. 잘못된 JSON이 정확한 경로 진단과 함께 거부된다.
10. JSON의 Luau, handlerId와 내부 서비스 참조가 거부된다.
11. 과도한 그래프 깊이와 반복 수가 거부된다.
12. 세션 임시 NPC가 영구 라이브러리에 저장되지 않는다.
13. 정의 revision 수정이 기존 Actor를 자동 변경하지 않는다.
14. 명시적 Actor 갱신이 영향 미리보기와 감사 로그를 남긴다.
15. 비밀 이름과 태그가 플레이어에게 노출되지 않는다.
16. 재접속 후 사용자 NPC의 행동과 자원이 복원된다.
17. 허용되지 않은 토큰 에셋은 안전한 fallback으로 대체된다.
18. 동일 JSON 재전송이 중복 콘텐츠를 만들지 않도록 idempotency 정책이 작동한다.

---

## 39. 비목표

이 문서에서 직접 정의하지 않는 것:

- 자연어 스탯블록을 자동으로 완전 변환하는 AI 파서
- 인터넷 URL에서 몬스터 데이터를 자동 수집하는 기능
- 사용자 Luau 플러그인 실행
- 공식 저작권 콘텐츠의 무단 배포
- 전투 AI의 목표 선택과 행동 계획
- 인카운터 난이도 자동 평가

이 기능들은 필요하면 별도 규약으로 정의한다.

---

## 40. 다음 단계

다음 문서는 몬스터와 NPC의 정의를 실제 전투에서 운용하는 **전투 AI, DM 직접 조종, 동료 제어권과 자동 행동 정책**을 다룰 수 있다.

그 전에 인카운터·주도권·전투 시작과 종료 구조가 충분한지 검토하여, 필요하면 전투 오케스트레이션 모델을 먼저 정의한다.