# 20. 능동형 특성과 행동 내부 실행 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](../../../../architecture/rules-content-grant-capability-model.md)
  - [`11. 공통 실행 계약`](../../../../architecture/rules-content-execution-and-spell-contract.md)
  - [`17. 주문 대상 지정·영역·공간 질의 모델`](../../../../spell-targeting-area-and-spatial-query-model.md)
  - [`19. 재주·특성의 트리거와 다른 턴 실행 모델`](../../../../feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`ADR-0024`](../../../../decisions/ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md)
  - [`ADR-0025`](../../../../decisions/ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0026`](../../../../decisions/ADR-0026-active-capabilities-action-containers-and-unit-replacements.md)

## 1. 문서 목적

이 문서는 플레이어가 자신의 턴에 직접 사용하는 재주, 직업 특성, 종 특성, 아이템 능력과 주문 외 행동이 어떻게 실행되는지 정의한다.

대상은 다음을 포함한다.

- 행동으로 사용하는 능력
- 보너스 행동으로 사용하는 능력
- 행동 비용 없이 자신의 턴에 선언하는 능력
- 공격 행동 안의 공격 하나를 대체하는 능력
- 공격 또는 행동 하나에 추가 모드와 비용을 결합하는 능력
- 하나의 행동 안에서 여러 공격이나 하위 실행을 순서대로 해결하는 능력
- 자원을 원하는 양만큼 소비하는 능력
- 추가 행동 또는 제한된 특수 행동 기회를 부여하는 능력
- 이동 도중 사용하는 능력과 이동 단위 교체

이 문서는 `FeatDefinition` 자체만을 위한 문서가 아니다.

```text
FeatDefinition
Class Feature
Species Feature
Item Capability
Monster Ability
```

이들은 획득 출처가 다를 뿐, 실제 능동 실행은 같은 `ActionCapability`, `ActionContainerExecution`, `ActionUnitExecution` 계약을 사용한다.

---

## 2. 전체 구조

```text
획득 출처
→ Grant Graph
→ Capability Compiler
→ Active Capability Set

Active Capability Set
├─ StandaloneActionCapability
├─ ActionContainerCapability
├─ UnitReplacementCapability
├─ ActionAugmentCapability
├─ ActionEconomyGrantCapability
└─ MovementActivationCapability

플레이어 선언
→ ActionExecution 또는 ActionContainerExecution
→ 하위 RuleExecution
→ 확정된 게임 상태
```

### 독립 실행

```text
StandaloneActionCapability
→ RuleExecution
```

예시:

- 보너스 행동으로 회복
- 행동으로 변신
- 행동으로 물체 사용
- 비용 없이 태세 활성화

### 컨테이너 실행

```text
ActionContainerCapability
→ ActionContainerExecution
   └─ ActionUnitSlot[]
      └─ ActionUnitExecution
```

예시:

- 공격 행동
- 몬스터의 다중공격
- 여러 하위 선택을 순차 실행하는 특수 행동
- 제한된 추가 행동

### 행동 내부 교체

```text
UnitReplacementCapability
→ 적격 ActionUnitSlot 하나를 replacement RuleRecipe로 충족
```

예시:

- 공격 하나를 숨결 무기로 대체
- 기회 공격을 주문으로 대체
- 이동 단위 하나를 특수 이동으로 대체
- 공격 하나를 특별한 비공격 기술로 대체

---

## 3. ActionEconomyState

행동 경제를 단순한 불리언 집합으로 저장하지 않는다.

```text
ActionEconomyState
├─ turnId
├─ actionOpportunities[]
├─ bonusActionOpportunities[]
├─ reactionOpportunities[]
├─ movementBudget
├─ specialOpportunities[]
├─ activeRestrictions[]
└─ revision
```

### ActionOpportunity

```text
ActionOpportunity
├─ opportunityId
├─ kind
├─ sourceId
├─ containerProfileId?
├─ allowedContentPredicates[]
├─ restrictions[]
├─ state
├─ reservedByExecutionId?
└─ consumedByExecutionId?
```

`kind` 예시:

- `action`
- `bonus_action`
- `reaction`
- `special_action`
- `no_action_required`

기본 행동과 보너스 행동도 동일한 기회 구조로 표현한다.

추가 행동을 얻으면 `actionAvailable = 2`처럼 숫자만 올리지 않고 새로운 `ActionOpportunity`를 추가한다.

이렇게 해야 특정 추가 행동에 다음 제한을 붙일 수 있다.

- 공격 행동만 가능
- 공격 하나만 가능
- 주문 시전 불가
- 특정 기능만 가능
- 이번 턴에만 유효
- 특정 출처가 생성한 행동으로 표시

---

## 4. StandaloneActionCapability

독립 능동 기능은 행동 컨테이너 없이 하나의 실행으로 완료된다.

```text
StandaloneActionCapability
├─ capabilityId
├─ sourceContentId
├─ activationContext
├─ actionEconomyCost
├─ resourceCosts[]
├─ prerequisites
├─ inputPlan
├─ targetingPlan
├─ ruleRecipeId
├─ usageGates[]
└─ presentationProfileId
```

### activationContext

```text
own_turn
combat_only
exploration_only
own_turn_or_exploration
special_phase
no_active_turn
```

자신의 턴에만 사용할 수 있는지, 탐험에서도 사용할 수 있는지를 별도로 명시한다.

### actionEconomyCost

```text
action
bonus_action
special_action
none
```

반응은 `19번 문서`의 TriggerCapability 흐름을 사용한다.

### 예시: 보너스 행동 회복 특성

```text
StandaloneActionCapability
├─ cost: bonus_action
├─ resource: feature use 1
├─ targeting: self
└─ recipe
   ├─ RollHealing
   └─ ApplyHealing
```

이 능력은 보너스 행동 버튼으로 표시되며 공격 행동 컨테이너와 무관하다.

---

## 5. ActionContainerCapability

하나의 행동 안에 여러 하위 실행이 있는 경우 컨테이너를 만든다.

```text
ActionContainerCapability
├─ containerKind
├─ actionEconomyCost
├─ unitCapacityFormula
├─ unitSlotProfile
├─ orderingPolicy
├─ interleavePolicy
├─ completionPolicy
├─ cancellationPolicy
└─ restrictions[]
```

### containerKind

초기 후보:

- `attack_action`
- `restricted_attack_action`
- `monster_multiattack`
- `multi_step_feature`
- `movement_sequence`
- `custom_bounded_container`

주문마다 새 컨테이너 종류를 만들지 않는다.

### ActionContainerExecution

```text
ActionContainerExecution
├─ containerExecutionId
├─ actorId
├─ capabilityId
├─ actionOpportunityId
├─ state
├─ unitCapacitySnapshot
├─ unitSlots[]
├─ committedUnitIds[]
├─ activeUnitExecutionId?
├─ interleavedExecutionIds[]
├─ ruleSnapshot
└─ revision
```

### 상태

```text
Declared
→ OpportunityReserved
→ ReadyForUnit
→ ResolvingUnit
→ ReadyForUnit
→ Completed
```

종료 상태:

```text
CancelledBeforeCommit
EndedWithUnusedUnits
Invalidated
Failed
```

---

## 6. ActionUnitSlot

컨테이너 안의 실행 가능 횟수를 슬롯으로 표현한다.

```text
ActionUnitSlot
├─ slotId
├─ ordinal
├─ unitKind
├─ allowedFulfillmentKinds[]
├─ allowedReplacementTags[]
├─ status
├─ fulfilledByExecutionId?
├─ consumedReplacementId?
└─ revision
```

`unitKind` 초기 후보:

- `attack`
- `movement_segment`
- `object_interaction`
- `feature_step`
- `choice_step`

### 공격 행동 슬롯

```text
AttackActionContainer
├─ AttackUnitSlot 1
├─ AttackUnitSlot 2
└─ ...
```

각 슬롯은 다음 중 하나로 충족될 수 있다.

- 무기 공격
- 비무장 공격
- 규칙상 허용되는 특별 공격
- 적격한 UnitReplacementCapability

슬롯은 UI 버튼 자체가 아니라 서버가 관리하는 실행 용량이다.

---

## 7. 공격 횟수와 Extra Attack

추가 공격은 캐릭터에 `attackButtons = 2`를 저장하지 않는다.

```text
AttackAction base capacity
+ RuleOverrideCapability modifiers
+ 현재 형태와 상태
+ 해당 ActionOpportunity의 제한
→ unitCapacitySnapshot
```

### RuleOverrideCapability 예시

```text
AttackUnitCapacityOverride
├─ appliesTo: normal_attack_action
├─ capacityFormula
├─ stackingKey
├─ stackingPolicy
└─ sourceOccurrenceId
```

여러 출처가 공격 횟수에 영향을 줄 때 단순 합산하지 않고 규칙의 stacking policy를 적용한다.

### 제한된 추가 행동

특정 효과가 추가 행동을 주되 공격 하나만 허용한다면:

```text
ActionOpportunity
├─ kind: action
└─ containerProfileId: restricted_single_attack
```

일반 공격 행동의 Extra Attack 보정을 그대로 받지 않는다.

---

## 8. 순차 확정과 취소

공격 행동 전체를 하나의 원자적 트랜잭션으로 처리하지 않는다.

### 첫 실행 단위 전

```text
공격 행동 선택
→ ActionOpportunity 예약
→ 아직 실행 단위 미확정
```

이때 Q로 전체 행동을 취소하면 예약을 해제할 수 있다.

### 첫 실행 단위 확정

```text
첫 공격 명중·피해 확정
→ 해당 ActionUnitSlot 소비
→ 부모 ActionOpportunity 소비 확정
```

이 시점부터 공격 행동은 사용된 것으로 본다.

### 이후 실행 단위

- 남은 공격을 계속 사용할 수 있다.
- 남은 공격을 포기하고 컨테이너를 종료할 수 있다.
- 앞선 공격 결과는 되돌리지 않는다.
- 각 공격 사이에 규칙상 가능한 이동과 보너스 행동을 사용할 수 있다.
- 각 공격은 최신 대상, 거리, 장비와 상태로 다시 검증한다.

### Q 동작

```text
하위 공격의 대상 선택 중 Q
→ 현재 하위 실행만 취소
→ 같은 공격 슬롯은 남음

컨테이너 대기 상태에서 Q
→ 남은 슬롯 포기
→ 컨테이너 종료
→ 이미 확정된 단위는 유지
```

---

## 9. UnitReplacementCapability

```text
UnitReplacementCapability
├─ capabilityId
├─ sourceContentId
├─ parentContainerKinds[]
├─ replaceableUnitKinds[]
├─ parentPredicate
├─ unitPredicate
├─ replacementRecipeId
├─ additionalInputPlan?
├─ additionalCosts[]
├─ usageGates[]
├─ perContainerLimit?
├─ recursionPolicy
└─ presentationProfileId
```

### 교체 흐름

```text
남은 ActionUnitSlot 선택
→ 해당 슬롯의 교체 후보 계산
→ 교체 능력 선택
→ 대상·모드·비용 입력 수집
→ 슬롯과 추가 비용 예약
→ replacement RuleRecipe 실행
→ 확정 시 슬롯과 비용 소비
```

### 부모 행동 비용

교체 능력은 부모 행동 비용을 다시 소비하지 않는다.

```text
부모 Attack Action
→ action opportunity 1회

숨결 무기 교체
→ attack unit 1개
→ breath resource
→ 추가 action 비용 없음
```

### 실패와 취소

- 대상 선택 중 취소하면 슬롯과 자원 예약을 해제한다.
- 서버 검증 실패 시 슬롯을 소비하지 않는다.
- 교체 실행이 규칙상 확정되었으나 효과가 없었다면 일반적으로 슬롯과 자원은 소비된다.
- 환불 여부는 콘텐츠의 명시적 정책을 따른다.

### 교체 재귀

기본 정책:

```text
replacement execution
→ 같은 슬롯을 다시 replacement 대상으로 삼을 수 없음
```

교체 결과 내부에 새 컨테이너나 새 슬롯이 생기는 특수 규칙은 제한된 정책 처리기와 최대 깊이를 요구한다.

---

## 10. ActionAugmentCapability

행동이나 실행 단위를 교체하지 않고 추가 모드나 효과를 결합하는 기능이다.

```text
ActionAugmentCapability
├─ appliesToContainerKinds[]
├─ appliesToUnitKinds[]
├─ declarationPhase
├─ augmentPredicate
├─ additionalCosts[]
├─ augmentRecipe
├─ usageGates[]
├─ stackingKey
└─ conflictPolicy
```

### declarationPhase

- 컨테이너 시작 전
- 공격 대상 선택 전
- 굴림 전
- 명중 결과 후
- 효과 commit 전

명중 후 선택하는 추가 피해처럼 사건 기반인 능력은 `19번 문서`의 TriggerCapability가 더 적합하다.

ActionAugmentCapability는 사용자가 자신의 실행을 구성하면서 미리 선택하거나 특정 하위 실행에 결합하는 경우에 사용한다.

### 예시

- 다음 공격의 사거리 또는 피해 유형 변경
- 공격 하나에 제한 자원을 미리 투자
- 공격 행동 전체에 태세 효과 적용
- 선택한 행동 모드에 추가 이동 결합

---

## 11. ModeSelectionStep

같은 Feature가 여러 실행 모드를 가진다고 콘텐츠를 여러 개 복제하지 않는다.

```text
ModeSelectionStep
├─ modePoolId
├─ selectionCount
├─ modePrerequisites
├─ modeTargetingOverrides
├─ modeCostOverrides
├─ modeRecipeBindings
└─ displayPolicy
```

선택한 모드는 현재 `RuleExecution`에만 기록한다.

### 예시: 여러 행동 선택을 제공하는 보너스 행동 특성

```text
보너스 행동 특성
├─ 질주 모드
├─ 이탈 모드
└─ 숨기 모드
```

구현 선택지는 두 가지다.

1. UI에서 세 개의 파생 버튼으로 보여주되 같은 원본 Capability와 보너스 행동 기회를 공유한다.
2. 하나의 버튼을 누른 뒤 모드 선택 UI를 연다.

서버 데이터에서는 같은 Capability의 모드로 유지한다.

---

## 12. AmountSelectionStep

자원을 원하는 양만큼 사용하는 기능을 처리한다.

```text
AmountSelectionStep
├─ amountBinding
├─ minimumExpression
├─ maximumExpression
├─ stepSize
├─ defaultValuePolicy
├─ costExpression
├─ effectExpression
└─ confirmationPolicy
```

### 예시: 회복 자원 분배

```text
대상 선택
→ 사용할 회복량 선택
→ 현재 자원 이하인지 검증
→ 선택량만큼 자원 예약
→ 같은 양의 회복 적용
→ 확정
```

```text
selectedAmount = 7
resourceCost = 7
healingAmount = 7
```

최대값과 현재 자원을 클라이언트가 결정하지 않는다. 서버가 현재 상태에서 계산한다.

중요한 자원을 많이 소비하는 경우 최종 확인을 표시할 수 있다.

---

## 13. ActionEconomyGrantCapability

현재 턴에 추가 행동 기회를 제공한다.

```text
ActionEconomyGrantCapability
├─ opportunityKind
├─ containerProfileId?
├─ allowedContentPredicates[]
├─ restrictions[]
├─ durationPolicy
├─ sourceResourceCost?
└─ stackingPolicy
```

### 실행 흐름

```text
특성 사용
→ 자원 소비
→ ActionOpportunity 생성
→ 현재 턴 ActionEconomyState에 추가
→ 허용된 행동 사용
→ 턴 종료 시 미사용 기회 정리
```

특성이 행동 기회를 주는 것과 그 행동을 즉시 실행하는 것을 구분한다.

### 제한 행동

```text
추가 ActionOpportunity
├─ attack action 가능
├─ unitCapacity: 1
├─ spell action 불가
└─ source: temporary feature
```

이런 제한은 새 기회 자체가 소유한다.

---

## 14. 이동 중 능동 기능

이동은 연속 경로와 이동 예산을 사용하지만, 규칙상 의미 있는 구간에서는 `MovementExecution`을 가진다.

```text
MovementExecution
├─ path
├─ committedSegments[]
├─ remainingBudget
├─ currentSegment
└─ revision
```

### 이동 방식 변경

비행, 수영과 등반 속도처럼 항상 적용되는 방식은 PassiveModifierCapability 또는 RuleOverrideCapability다.

### 이동 중 선언 기능

이동 도중 특정 위치에서 사용하는 기능은 `MovementActivationCapability`를 사용한다.

```text
MovementActivationCapability
├─ activationBoundary
├─ movementCost
├─ resourceCosts[]
├─ targetingPlan
└─ ruleRecipeId
```

### 이동 단위 교체

규칙상 이동 일부를 순간이동이나 특별 도약으로 대체한다면 `UnitReplacementCapability`가 `movement_segment`에 적용될 수 있다.

일반적인 보너스 행동 순간이동은 이동 교체가 아니라 독립 StandaloneActionCapability다.

---

## 15. 드래곤본 숨결 무기 사례

숨결 무기는 종족 전용 실행 엔진을 만들지 않는다.

### 획득

```text
SpeciesDefinition: dragonborn
→ FixedGrant
→ FeatureDefinition: breath_weapon
→ UnitReplacementCapability
```

### Capability

```text
UnitReplacementCapability
├─ parentContainerKinds: [attack_action]
├─ replaceableUnitKinds: [attack]
├─ replacementRecipeId: recipe.breath_weapon
├─ additionalCosts: breath_resource_use
├─ usageGates: content-defined
└─ perContainerLimit: content-defined
```

정확한 사용 횟수, 피해, 내성 DC, 피해 유형과 형상은 규칙 콘텐츠 정의가 소유한다.

### 실행 흐름

```text
AttackActionContainer 시작
→ 공격 슬롯 수 계산
→ 첫 번째 슬롯을 무기 공격으로 해결 가능
→ 남은 공격 슬롯 선택
→ 숨결 무기 교체 선택
→ 사용 가능한 숨결 모드 조회
→ 방향 또는 영역 배치
→ 사거리와 형상 검증
→ SpatialQuery로 대상 집합 계산
→ 대상별 내성 굴림
→ 성공·실패 피해 분기
→ 숨결 자원과 공격 슬롯 확정
→ 남은 공격 슬롯이 있으면 계속
```

### 예시

```text
공격 행동: 공격 슬롯 2개

슬롯 1
→ 장검 공격
→ 확정

슬롯 2
→ 숨결 무기로 교체
→ 원뿔 방향 선택
→ 대상 3명 내성 굴림
→ 피해 확정

공격 행동 종료
```

### 취소

숨결 방향 선택 중 Q를 누르면:

- 숨결 자원을 소비하지 않는다.
- 해당 공격 슬롯은 남는다.
- 플레이어는 일반 공격이나 다른 교체 능력을 선택할 수 있다.

숨결 실행이 확정된 후에는 공격 슬롯과 자원을 되돌리지 않는다.

### 추가 공격과 결합

추가 공격은 숨결 무기 정의에 들어가지 않는다.

```text
Extra Attack RuleOverride
→ AttackActionContainer의 슬롯 수 증가

Breath Weapon UnitReplacement
→ 그중 적격 슬롯 하나 소비
```

두 시스템은 독립적으로 결합한다.

---

## 16. 다른 대표 사례

### 16.1 보너스 행동 회복

```text
StandaloneActionCapability
├─ actionEconomyCost: bonus_action
├─ target: self
├─ resourceCost: 1 use
└─ ApplyHealing
```

### 16.2 여러 모드의 보너스 행동

```text
StandaloneActionCapability
├─ actionEconomyCost: bonus_action
└─ ModeSelectionStep
   ├─ dash
   ├─ disengage
   └─ hide
```

각 모드가 보너스 행동을 별도로 생성하지 않는다.

### 16.3 행동으로 변신

```text
StandaloneActionCapability
├─ actionEconomyCost: action
├─ FormSelectionStep
├─ resourceCost
└─ ApplyFormLayer
```

### 16.4 원하는 양의 회복 자원

```text
대상 선택
→ AmountSelectionStep
→ 자원 예약
→ ApplyHealing(selectedAmount)
```

### 16.5 추가 행동 획득

```text
특성 사용
→ resource commit
→ ActionEconomyGrantCapability
→ 새 ActionOpportunity 추가
```

### 16.6 몬스터 다중공격

몬스터 다중공격은 플레이어의 Extra Attack과 동일한 것으로 취급하지 않는다.

```text
MonsterMultiattackContainer
├─ 정해진 공격 조합
├─ 선택 가능한 조합
├─ 순서 정책
└─ 각 공격의 별도 ActionUnitExecution
```

설명 문자열을 파싱하지 않고 구조화된 컨테이너 프로필을 사용한다.

---

## 17. UI

### 행동 표시

행동 패널을 행동 경제별로 그룹화한다.

```text
행동
보너스 행동
특수 행동
비용 없음
```

공격 대체 능력은 기본적으로 독립 행동 버튼 영역에 중복 표시하지 않는다.

공격 행동을 시작한 뒤 남은 슬롯과 함께 보여준다.

```text
공격 행동
남은 공격: 1 / 2

[무기 공격]
[비무장 공격]
[숨결 무기]
```

### 비활성 이유

```text
숨결 무기 사용 불가
- 남은 공격 슬롯이 없음
```

또는:

```text
숨결 무기 사용 불가
- 사용 횟수를 모두 소모함
```

### 현재 컨테이너

UI는 다음을 보여준다.

- 소비한 행동 종류
- 남은 실행 단위
- 이미 해결된 단위
- 현재 선택 중인 하위 실행
- 사용할 추가 자원
- Q와 E의 현재 의미

### 가변 자원

슬라이더나 숫자 선택기로 사용량을 고르되 서버가 최대값을 제공하고 최종 확인에서 실제 비용과 효과를 다시 보여준다.

---

## 18. 입력 문법

기존 공통 입력 규약을 따른다.

```text
E
→ 현재 하위 선택 또는 실행 확정

Q
→ 현재 미완성 하위 실행 취소
→ 컨테이너 대기 상태에서는 남은 단위 포기 후 종료
```

첫 실행 단위가 확정되기 전 컨테이너 전체 취소와, 이후 남은 단위 포기를 UI 문구로 구분한다.

```text
공격 행동 취소
```

```text
남은 공격 포기
```

---

## 19. 서버 검증

서버는 최소한 다음을 검증한다.

- 현재 턴과 ActionEconomyState가 해당 행동을 허용하는가
- ActionOpportunity가 다른 실행에 예약 또는 소비되지 않았는가
- ActionContainerExecution이 현재 액터의 열린 컨테이너인가
- 남은 ActionUnitSlot이 실제 존재하는가
- 선택한 기본 실행이나 교체 능력이 해당 슬롯에 적격한가
- Extra Attack과 제한 행동 프로필이 올바르게 적용되었는가
- 교체 능력의 자원, 사용 제한과 per-container 제한이 남아 있는가
- 클라이언트가 임의로 공격 슬롯 수를 늘리지 않았는가
- 교체 재귀와 중첩 깊이를 위반하지 않는가
- 대상, 장비, 사거리와 상태가 하위 실행 확정 시점에도 유효한가
- 부모 행동과 하위 실행 revision이 일치하는가
- 이미 확정된 하위 실행을 클라이언트 취소로 롤백하려 하지 않는가

---

## 20. 저장과 재접속

### 영구 저장

- 특성 자원 현재값
- 장기 효과와 형태
- Feature 획득과 선택 원본

### 전투 런타임

- ActionEconomyState
- 열린 ActionContainerExecution
- 남은 ActionUnitSlot
- 현재 예약된 하위 실행과 비용
- 해당 턴의 UsageGate 상태

일반적인 짧은 행동 선택은 캐릭터 영구 데이터에 넣지 않는다.

전투 저장과 재접속을 지원할 경우 열린 컨테이너를 복원하거나 마지막 안전한 단위 경계로 되돌린다.

이미 확정된 하위 실행은 유지하고, 확정되지 않은 대상 선택과 미리보기는 안전하게 취소할 수 있다.

---

## 21. 성능

- 현재 액터의 활성 Capability와 현재 행동 문맥만 조회한다.
- 모든 재주와 특성을 매 프레임 검사하지 않는다.
- 공격 컨테이너를 열 때 교체 후보를 unitKind와 parentContainerKind로 인덱싱한다.
- 자원, 장비, 형태와 상태 revision이 바뀔 때만 후보 캐시를 무효화한다.
- 영역 미리보기는 클라이언트가 계산할 수 있지만 최종 대상 집합은 서버가 계산한다.
- 열린 컨테이너가 없을 때 관련 모듈은 프레임 루프 비용을 만들지 않는다.

---

## 22. 테스트 기준

필수 테스트:

1. 일반 공격 행동이 행동 기회를 한 번만 소비한다.
2. 첫 공격 전 취소하면 행동 기회가 반환된다.
3. 첫 공격 확정 후 남은 공격을 포기해도 행동과 첫 결과는 유지된다.
4. Extra Attack이 공격 슬롯 수만 늘리고 별도 행동 버튼을 만들지 않는다.
5. 제한된 추가 행동이 일반 Extra Attack 보정을 잘못 받지 않는다.
6. 숨결 무기가 공격 슬롯 하나와 자원만 소비한다.
7. 숨결 대상 선택 중 취소하면 공격 슬롯과 자원이 남는다.
8. 숨결 확정 후 남은 공격 슬롯이 정상적으로 이어진다.
9. 교체 능력이 같은 슬롯을 재귀적으로 다시 교체하지 못한다.
10. 여러 교체 후보가 같은 슬롯에서 올바르게 표시된다.
11. 공격 사이 이동 후 다음 공격의 사거리와 대상이 재검증된다.
12. 공격 사이 반응으로 액터 상태가 변하면 남은 슬롯의 후보가 갱신된다.
13. 가변 자원 사용량이 현재 자원을 초과할 수 없다.
14. 여러 모드가 하나의 행동 기회를 공유한다.
15. 추가 행동 특성이 출처와 제한이 있는 ActionOpportunity를 생성한다.
16. 몬스터 다중공격의 각 공격이 순차적으로 확정된다.
17. 재접속 시 확정된 단위는 유지되고 미완성 단위만 안전하게 취소된다.

---

## 23. 명시적 비목표

- 모든 능동형 특성을 독립 행동 버튼으로 만들지 않는다.
- 추가 공격을 캐릭터 저장 데이터의 고정 숫자로 저장하지 않는다.
- 공격 행동 전체를 하나의 원자적 피해 트랜잭션으로 묶지 않는다.
- 공격 하나를 대체하는 능력이 행동을 다시 소비하게 하지 않는다.
- 숨결 무기나 특정 재주를 위해 별도 행동 엔진을 만들지 않는다.
- 클라이언트가 남은 공격 수와 교체 적격성을 결정하게 하지 않는다.
- 설명 문자열에서 “공격 하나를 대체한다”는 문장을 파싱하지 않는다.
- 보너스 행동의 여러 모드를 독립 자원처럼 중복 생성하지 않는다.
- 확정된 첫 공격을 두 번째 공격 취소 때문에 롤백하지 않는다.

---

## 24. 다음 단계

다음으로는 모든 행동과 트리거가 실제로 적용하는 `EffectRecipe` 해결 순서를 정한다.

연결 대상:

1. 공격 굴림과 내성 굴림
2. 피해·회복·임시 HP
3. 다중 피해 구성요소
4. 저항·면역·취약성과 피해 감소
5. 상태 적용과 반복 내성
6. 강제 이동과 이동 이벤트
7. 동시 효과 그룹
8. 부모 실행을 수정하는 반응
9. 하위 실행과 최종 commit 순서

이 규약이 완성되면 주문, 능동형 특성, 반응형 특성, 몬스터 능력과 아이템이 같은 결과 적용 엔진을 공유할 수 있다.