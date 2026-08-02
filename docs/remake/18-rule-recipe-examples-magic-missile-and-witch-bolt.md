# 18. RuleRecipe 사례: 매직 미사일과 마녀의 번개

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`11. 공통 실행 계약과 마법 처리 모델`](11-rules-content-execution-and-spell-contract.md)
  - [`14. 주문 자원 풀과 시전 결제 모델`](14-spell-resource-pools-and-cast-payment-model.md)
  - [`17. 주문 대상 지정·영역·공간 질의 모델`](17-spell-targeting-area-and-spatial-query-model.md)
  - [`ADR-0023`](decisions/ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0024`](decisions/ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md)

## 1. 문서 목적

이 문서는 공통 `RuleRecipe` 구조가 서로 성격이 다른 주문을 어떻게 표현하는지 구체적인 사례로 검증한다.

- 매직 미사일은 여러 개의 동일한 효과 단위를 여러 대상에게 자유롭게 배분한 뒤 동시에 해결한다.
- 마녀의 번개는 최초 공격과 별개로 시전자와 대상 사이의 지속 연결을 만들고, 그 연결이 유지되는 동안 후속 행동을 제공한다.

두 주문 모두 주문 전용 실행 엔진을 만들지 않는다.

```text
공통 대상 지정
+ 공통 시전 비용
+ 공통 굴림과 피해
+ 재사용 고급 연산
+ 주문별 파라미터
```

정확한 수치와 문구는 `dnd5e-2024` 규칙 콘텐츠 정의가 소유한다. 이 문서는 실행 의미와 데이터 계약을 정의한다.

---

## 2. 추가하는 재사용 고급 연산

### 2.1 AssignEffectUnits

동일한 효과 단위를 정해진 개수만큼 생성하고, 플레이어가 하나 이상의 적격 대상에게 배분하도록 한다.

```text
AssignEffectUnits
├─ operationId
├─ unitDefinitionId
├─ countExpression
├─ targetStepId
├─ duplicateTargetPolicy
├─ allocationMinimumPerTarget
├─ allocationMaximumPerTarget?
├─ resolutionGroupingPolicy
├─ reactionGroupingPolicy
└─ outputBinding
```

주요 용도:

- 매직 미사일 투사체
- 여러 광선을 대상에게 나누는 주문
- 여러 치유 단위를 대상에게 배분하는 능력
- 여러 표식이나 폭발 지점을 배분하는 효과

이 연산은 피해를 직접 적용하지 않는다. 몇 개의 효과 단위가 어떤 대상에게 연결되었는지를 구조화하여 후속 노드에 전달한다.

### 2.2 CreateSustainedLink

두 규칙 개체 사이에 지속되는 연결 효과를 생성하고, 연결이 활성화된 동안 후속 Capability나 트리거를 제공한다.

```text
CreateSustainedLink
├─ operationId
├─ sourceBinding
├─ targetBinding
├─ durationPolicy
├─ concentrationBinding?
├─ validationPolicies
├─ terminationConditions
├─ grantedCapabilities[]
├─ triggerRules[]
├─ visualPresentationId?
└─ outputBinding
```

주요 용도:

- 마녀의 번개
- 특정 대상에게 유지되는 흡수 광선
- 시전자와 소환체의 연결
- 거리가 벌어지면 끝나는 정신 연결
- 두 대상 사이의 보호 또는 피해 사슬

연결은 대상이나 캐릭터 정의를 수정하지 않는 독립 `EffectInstance`다.

---

# 3. 매직 미사일

## 3.1 구현 관점

매직 미사일은 단순한 복수 대상 선택이 아니다.

플레이어는 주문이 생성한 여러 투사체를 한 대상에게 몰아주거나 여러 대상에게 나눈다. 따라서 저장해야 하는 결과는 고유 대상 목록이 아니라 **투사체 단위의 배분 결과**다.

```text
잘못된 표현
selectedTargets = [target-a, target-b]

올바른 표현
allocations
├─ target-a: 2 units
└─ target-b: 1 unit
```

같은 대상이 여러 투사체를 받을 수 있으므로 일반적인 `duplicateTargets = false` 복수 대상 선택으로 표현하지 않는다.

## 3.2 투사체 수 계산

```text
projectileCount
= baseProjectileCount
+ max(0, castLevel - baseSpellLevel) × projectilesPerUpcastLevel
```

기본 규칙 콘텐츠는 다음 파라미터를 제공한다.

```text
baseProjectileCount: 3
projectilesPerUpcastLevel: 1
```

최종 투사체 수는 시전 레벨에서 파생하며 캐릭터 상태에 저장하지 않는다.

## 3.3 대상 지정

```text
TargetingPlan
└─ EntitySelectionStep: eligibleRecipients
   ├─ candidateType: creature
   ├─ visibilityPolicy: required
   ├─ rangePolicy: spellRange
   ├─ minimumDistinctTargets: 1
   └─ maximumDistinctTargets: projectileCount
```

후속 `AssignEffectUnits`가 선택된 적격 대상에게 투사체를 배분한다.

```text
AssignEffectUnits
├─ unitDefinitionId: effect-unit.magic-missile-dart
├─ countExpression: projectileCount
├─ duplicateTargetPolicy: allowed
├─ resolutionGroupingPolicy: simultaneous
└─ reactionGroupingPolicy: once-per-recipient
```

UI는 각 대상 옆에 투사체 수를 조절하는 방식으로 제공할 수 있다.

```text
매직 미사일 4발

대상 A: 2
대상 B: 1
대상 C: 1
남은 투사체: 0
```

서버는 다음을 검증한다.

- 전체 배분량이 정확히 `projectileCount`와 같은가
- 모든 대상이 해당 시전의 적격 조건을 만족하는가
- 클라이언트가 허용되지 않은 대상 ID를 추가하지 않았는가
- 투사체별 대상 참조가 최종 재검증 시점에도 유효한가

## 3.4 RuleRecipe

```text
RuleRecipe: spell.magic-missile
├─ ResolveCastLevel
├─ CalculateValue: projectileCount
├─ ExecuteTargetingPlan
├─ AssignEffectUnits
├─ GroupUnitsByRecipient
├─ OpenReactionWindow
│  ├─ trigger: targeted-by-magic-missile
│  └─ grouping: once-per-recipient
├─ ForEachEffectUnit
│  └─ CreateDamagePacket
│     ├─ type: force
│     └─ formula: spell-defined
├─ ResolveSimultaneousEffectGroup
└─ CommitExecution
```

## 3.5 동시 해결

각 투사체는 개별 효과 단위로 유지하지만 같은 `simultaneousGroupId`를 가진다.

```text
EffectUnit 1 → target-a
EffectUnit 2 → target-a
EffectUnit 3 → target-b
└─ simultaneousGroupId: execution-42:impact-1
```

이 구조는 다음을 모두 만족한다.

- 여러 대상에게 자유롭게 배분
- 투사체별 피해와 연출
- 대상별 총 피해 표시
- 모든 투사체가 동시에 명중한다는 규칙
- 특정 대상이 모든 투사체 피해를 막는 반응

피해는 필요하다면 대상별로 집계하여 한 번에 HP에 반영할 수 있지만, 로그와 규칙 판정을 위해 원본 투사체 단위는 유지한다.

## 3.6 방패 반응과의 연결

대상별 배분이 확정된 뒤, 해당 대상을 겨냥한 투사체가 해결되기 전에 반응 창을 연다.

```text
대상별 투사체 그룹 생성
→ 해당 대상의 ReactionCapability 검색
→ 방패 사용 여부 결정
→ 대상별 방어 결과 고정
→ 모든 투사체 동시 해결
```

방패가 매직 미사일을 막는 상태라면 해당 대상에게 배분된 투사체의 피해 패킷을 모두 무효화한다.

```text
RecipientResolutionModifier
├─ recipientId
├─ sourceCapabilityId: spell.shield
└─ suppressEffectTags: [magic-missile-dart-damage]
```

투사체마다 같은 반응을 반복해서 요청하지 않는다.

## 3.7 저장과 로그

영구 캐릭터 데이터에는 매직 미사일 배분을 저장하지 않는다.

현재 실행 기록에는 다음을 남긴다.

```text
executionId
spellId
castRouteId
castLevel
projectileCount
allocationsByRecipient
reactionWindowResults
individualEffectUnits
simultaneousGroupId
damagePackets
commitResult
```

---

# 4. 마녀의 번개(Witch Bolt)

## 4.1 구현 관점

마녀의 번개는 다음 두 부분으로 분리한다.

```text
최초 시전
→ 원거리 주문 공격과 초기 피해

지속 연결
→ 집중 중 대상과 연결
→ 후속 턴에 자동 피해 행동 제공
```

최초 공격의 명중 여부와 지속 연결 생성 여부를 같은 조건으로 묶지 않는다.

2024 규칙 프로필에서는 최초 공격이 빗나가도 주문의 연결은 생성되며, 후속 턴의 보너스 행동을 사용할 수 있다. 정확한 판본 차이는 규칙 콘텐츠의 정책으로 관리한다.

## 4.2 최초 대상 지정

```text
TargetingPlan
└─ EntitySelectionStep: linkedTarget
   ├─ candidateType: creature
   ├─ count: exactly-one
   ├─ visibilityPolicy: required-at-cast
   └─ rangePolicy: spellRange
```

시전 경로와 구성요소 검증이 끝나면 대상 참조를 실행에 고정한다.

## 4.3 최초 RuleRecipe

```text
RuleRecipe: spell.witch-bolt.initial
├─ ExecuteTargetingPlan
├─ ReserveCastCost
├─ RollSpellAttack
├─ Branch: attackHit
│  ├─ true
│  │  └─ ApplyDamage
│  │     ├─ type: lightning
│  │     └─ formula: initialDamageFormula
│  └─ false
│     └─ RecordNoInitialDamage
├─ CreateSustainedLink
│  ├─ source: caster
│  ├─ target: linkedTarget
│  ├─ concentration: currentCastConcentration
│  ├─ grantedCapability: witch-bolt-repeat
│  └─ terminationPolicy: witch-bolt-link-policy
└─ CommitExecution
```

`CreateSustainedLink`는 공격 분기의 바깥에 있으므로 명중과 관계없이 실행된다.

## 4.4 지속 연결 인스턴스

```text
SustainedLinkEffect
├─ effectInstanceId
├─ sourceActorId
├─ targetActorId
├─ sourceSpellId
├─ castLevel
├─ concentrationStateId
├─ remainingDuration
├─ validationPolicies
├─ terminationConditions
├─ grantedCapabilityInstanceIds
├─ triggerSubscriptions
├─ presentationState
└─ status
```

연결이 소유하는 것은 대상 참조와 연결 상태다. 대상의 캐릭터 데이터에 `witchBoltLinked = true` 같은 플래그를 직접 추가하지 않는다.

## 4.5 후속 보너스 행동

연결이 활성화되어 있으면 시전자에게 임시 Capability를 부여한다.

```text
GrantedActionCapability: witch-bolt-repeat
├─ actionEconomy: bonus-action
├─ sourceEffectInstanceId
├─ targetBinding: sustainedLink.targetActorId
├─ targetingMode: bound-target
├─ requiresAttackRoll: false
├─ validationPolicy: sustained-link-currently-valid
└─ effectRecipe
   └─ ApplyDamage
      ├─ type: lightning
      └─ formula: recurringDamageFormula
```

플레이어는 대상을 다시 선택하지 않는다. 연결된 대상이 자동으로 사용 대상이 된다.

```text
보너스 행동 선택
→ 연결 인스턴스 조회
→ 연결 유효성 재검증
→ 보너스 행동 예약
→ 자동 피해 적용
→ 실행 확정
```

## 4.6 연결 종료 조건

종료 정책은 주문 데이터에서 선언한다.

```text
SustainedLinkTerminationPolicy
├─ concentrationEnded
├─ durationExpired
├─ sourceInvalid
├─ targetInvalid
├─ targetOutsideMaximumRange
├─ targetHasTotalCover
├─ sceneRelationshipInvalid
└─ explicitEffectRemoval
```

정확한 시야 요구와 총엄폐 판정은 규칙 판본의 정책을 따른다. 일반적인 `CreateSustainedLink`는 종료 조건을 하드코딩하지 않는다.

## 4.7 이벤트 기반 재검증

모든 연결을 매 프레임 검사하지 않는다.

다음 사건이 발생할 때 영향받은 연결만 재검증한다.

```text
source actor movement committed
target actor movement committed
teleport committed
scene transition committed
door or blocker state changed
line-of-effect region changed
concentration ended
source or target removed
repeat action requested
```

```text
RelevantRuleEvent
→ SustainedLinkIndex에서 관련 연결 조회
→ 종료 조건 재검증
→ 실패 시 EndEffect
```

## 4.8 종료 처리

```text
EndSustainedLink
├─ status를 ended로 변경
├─ granted action Capability 제거
├─ 트리거 구독 해제
├─ 연결 VFX 제거
├─ 집중 연결에서 effectInstanceId 제거
└─ 종료 사유 로그
```

연결 종료가 항상 집중 상태 전체를 종료하는지는 주문 정책이 결정한다. 하나의 집중 상태가 여러 효과 인스턴스를 소유할 수 있으므로 공통 엔진이 임의로 모든 집중 효과를 삭제하지 않는다.

## 4.9 저장과 로그

지속 연결은 세션을 넘어 보존될 수 있는 현재 상태이므로 캐릭터의 영구 성장 데이터가 아니라 지속 효과 저장 영역에 기록한다.

```text
sourceActorId / sourceCharacterId
targetActorId / targetReference
sourceSpellId
castRouteId
castLevel
concentrationStateId
remainingDuration
terminationPolicyId
grantedCapability references
status
revision
```

장면 전환이 연결 종료 조건이라면 전환 트랜잭션 중 종료한다. 장면을 넘어 유지되는 홈브루 연결이라면 대상 참조를 Actor ID가 아닌 지속 Entity 참조로 승격해야 한다.

---

# 5. 공통 엔진에서의 차이

```text
매직 미사일
├─ 여러 EffectUnit 배분
├─ 대상별 반응 창
├─ 동시 해결
└─ 지속 상태 없음
```

```text
마녀의 번개
├─ 단일 대상과 최초 공격
├─ 명중 시 초기 피해
├─ 지속 연결 생성
├─ 후속 행동 Capability 부여
└─ 집중·거리·엄폐로 종료
```

두 주문 모두 다음 공통 시스템을 그대로 사용한다.

- `SpellCastRoute`
- `CastCostPlan`
- `TargetingPlan`
- 공격 및 피해 굴림
- 반응 창
- 실행 트랜잭션
- 지속 효과 저장
- Capability 부여와 제거
- 구조화된 로그

추가되는 재사용 연산은 두 개뿐이다.

```text
AssignEffectUnits
CreateSustainedLink
```

---

# 6. 구현 검증 시나리오

## 6.1 매직 미사일

- 모든 투사체를 한 대상에게 배분한다.
- 투사체를 여러 대상에게 나눈다.
- 상위 레벨 시전으로 투사체 수가 증가한다.
- 대상 하나가 반응으로 자신에게 온 모든 투사체를 막는다.
- 다른 대상에게 간 투사체는 정상 피해를 준다.
- 반응 해결 후 모든 남은 투사체가 같은 동시 그룹에서 해결된다.
- 배분 확정 직전에 대상 하나가 무효화되면 전체 시전을 재검증하거나 선택 단계로 되돌린다.
- 클라이언트가 허용량보다 많은 투사체를 배분하면 서버가 거부한다.

## 6.2 마녀의 번개

- 최초 공격이 명중하면 초기 피해와 연결이 모두 생성된다.
- 최초 공격이 빗나가도 2024 정책에서는 연결이 생성된다.
- 후속 보너스 행동은 공격 굴림 없이 연결된 대상에게 피해를 준다.
- 집중이 끝나면 연결과 후속 행동이 제거된다.
- 대상이 최대 거리 밖으로 이동하면 연결이 종료된다.
- 대상이 총엄폐를 얻으면 연결이 종료된다.
- 대상이 다시 가까워져도 종료된 연결은 자동 복구되지 않는다.
- 연결이 종료된 뒤 클라이언트가 후속 행동을 요청하면 서버가 거부한다.
- 문이나 차단 오브젝트 변화가 연결 유효성에 영향을 주는 경우 관련 연결만 재검증한다.

---

# 7. 비목표

- 매직 미사일을 일반 복수 대상 피해 하나로 축약하지 않는다.
- 투사체를 하나의 합산 피해 패킷만으로 저장하지 않는다.
- 마녀의 번개 연결 상태를 대상 캐릭터 정의에 직접 기록하지 않는다.
- 최초 공격 실패를 이유로 판본 정책과 무관하게 지속 연결을 강제 종료하지 않는다.
- 지속 연결을 매 프레임 전체 장면에서 검색하지 않는다.
- 두 주문의 이름을 검사하는 중앙 `if spellId == ...` 분기문을 만들지 않는다.

---

# 8. 후속 단계

다음 문서는 이 사례가 사용하는 공통 효과 해결 구조를 정형화해야 한다.

- `EffectUnit`
- `DamagePacket`
- `SimultaneousEffectGroup`
- 공격·내성·조건 분기
- 저항·면역·취약과 피해 수정
- 효과 적용 순서
- 지속 효과와 Capability 생성
- 실행 중단, 취소와 롤백
