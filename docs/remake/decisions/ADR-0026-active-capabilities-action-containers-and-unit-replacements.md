# ADR-0026: 능동형 특성은 행동 컨테이너와 실행 단위 교체로 처리한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0017`](ADR-0017-derived-fixed-grants-and-stored-selections.md)
  - [`ADR-0023`](ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0024`](ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md)
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`10. Grant Graph와 Capability 모델`](../10-rules-content-grant-capability-model.md)
  - [`11. 공통 실행 계약`](../11-rules-content-execution-and-spell-contract.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](../20-active-feature-and-action-container-execution-model.md)

## 배경

재주, 직업 특성, 종 특성, 아이템과 주문이 제공하는 능동 기능은 모두 독립 행동 버튼으로 표현되지 않는다.

- 행동이나 보너스 행동으로 직접 사용한다.
- 행동 비용 없이 자신의 턴에 사용한다.
- 공격 행동 안의 공격 하나를 다른 능력으로 대체한다.
- 공격 하나에 모드나 추가 비용을 결합한다.
- 이동 중 특정 이동 단위를 다른 방식으로 바꾼다.
- 하나의 행동 안에서 여러 공격이나 하위 실행을 순서대로 해결한다.
- 제한 자원을 원하는 양만큼 소비한다.
- 추가 행동이나 제한된 특수 행동 기회를 생성한다.

이 기능들을 모두 독립 `ActionCapability`로 만들면 숨결 무기처럼 공격 하나를 대체하는 능력이 행동을 별도로 소비하거나, 추가 공격과 결합할 수 없는 문제가 생긴다.

반대로 공격 행동 전체를 하나의 원자적 실행으로 처리하면 첫 공격이 이미 명중한 뒤 두 번째 공격을 취소할 때 이전 결과까지 되돌려야 하는 잘못된 구조가 된다.

## 결정

RVTT는 자신의 턴에 시작하는 실행을 다음 세 층으로 구분한다.

```text
ActionCapability
→ 행동 경제에서 어떤 진입점을 사용할 수 있는가

ActionContainerExecution
→ 하나의 행동·보너스 행동·특수 행동 문맥

ActionUnitExecution
→ 컨테이너 안에서 순차적으로 확정되는 공격·이동·능력 단위
```

### 독립 능동 기능

행동, 보너스 행동 또는 비용 없는 능동 기능은 `ActionCapability`가 직접 `RuleExecution`을 시작한다.

### 복합 행동

공격 행동처럼 여러 실행 단위를 포함하는 행동은 `ActionContainerExecution`을 만든다.

```text
AttackActionContainer
└─ AttackUnitSlot[]
```

각 슬롯은 별도 `ActionUnitExecution`으로 해결하고 확정한다. 앞선 슬롯이 확정된 뒤에는 이후 슬롯 취소가 이전 결과를 되돌리지 않는다.

### 실행 단위 교체

숨결 무기처럼 공격 하나를 대체하는 기능은 `UnitReplacementCapability`로 컴파일한다.

```text
UnitReplacementCapability
├─ parentContainerKinds
├─ replaceableUnitKinds
├─ eligibilityPredicate
├─ replacementRecipe
├─ actionCost: consume_parent_unit
├─ additionalCosts[]
├─ usageGates[]
└─ recursionPolicy
```

교체 실행은 부모 행동 비용을 다시 소비하지 않고, 적격한 하위 슬롯 하나만 소비한다.

## 행동 경제와 기능 비용을 분리한다

```text
ActionEconomyCost
→ 행동, 보너스 행동, 반응, 이동 또는 특수 기회

ResourceCost
→ 특성 사용 횟수, 주문 슬롯, 아이템 충전과 기타 자원

UnitConsumption
→ 부모 행동 안의 공격·이동·상호작용 슬롯 소비
```

숨결 무기는 공격 슬롯 하나와 숨결 사용 자원을 소비하지만 행동을 다시 소비하지 않는다.

## 컨테이너의 확정 정책

- 컨테이너를 열고 첫 실행 단위가 확정되기 전에는 취소 시 행동 비용 예약을 해제할 수 있다.
- 첫 실행 단위가 확정되면 부모 행동 비용도 확정된다.
- 이후 남은 슬롯을 포기할 수 있지만 이미 확정된 실행 단위는 되돌리지 않는다.
- 각 실행 단위 사이에 이동, 대상 변경과 합법적인 반응이 발생할 수 있다.
- 각 실행 단위는 최신 장면, 상태, 자원과 대상 조건으로 다시 검증한다.

## Extra Attack과 행동 수

추가 공격은 공격 버튼을 여러 개 부여하지 않는다.

`RuleOverrideCapability`가 공격 행동 컨테이너의 `unitCapacity`를 계산한다.

```text
AttackAction base capacity
+ active attack-count overrides
→ AttackUnitSlot count
```

추가 행동을 주는 특성도 단순히 기본 행동 수를 영구 증가시키지 않는다. 현재 턴의 `ActionEconomyState`에 출처와 제한이 있는 행동 기회를 추가한다.

제한된 추가 행동은 별도의 `ActionContainerProfile`을 사용할 수 있다. 예를 들어 특정 추가 행동이 공격 하나만 허용한다면 일반 공격 행동과 같은 컨테이너로 가장하지 않는다.

## 모드와 가변 소비

하나의 능동 기능이 여러 형태를 가지면 별도 콘텐츠 복사본을 만들지 않는다.

```text
ModeSelectionStep
→ 선택한 모드에 따른 대상·비용·RuleRecipe 바인딩
```

원하는 양의 자원을 소비하는 기능은 `AmountSelectionStep`과 파생 비용을 사용한다.

```text
선택한 amount
→ 허용 범위 검증
→ 비용과 효과량 계산
→ 자원 예약
→ 실행 확정
```

## 드래곤본 숨결 무기

숨결 무기는 다음 조합으로 표현한다.

```text
SpeciesDefinition
→ FeatureDefinition
→ UnitReplacementCapability
   ├─ parent: AttackActionContainer
   ├─ replaces: one AttackUnitSlot
   ├─ recipe: breath weapon RuleRecipe
   ├─ resource cost: breath use
   └─ usage gate: content rule
```

교체 RuleRecipe는 공통 대상 지정, 영역 형상, 공간 질의, 내성 굴림과 피해 효과를 사용한다.

```text
공격 슬롯 하나 선택
→ 숨결 모드와 형상 결정
→ 방향 또는 영역 배치
→ SpatialQuery
→ 대상별 내성 굴림
→ 피해 적용
→ 슬롯과 사용 자원 확정
```

숨결 무기를 위해 종족 전용 행동 엔진을 만들지 않는다.

## Feat와 Feature의 관계

`FeatDefinition`, `FeatureDefinition`, 종 특성과 아이템은 실행 체계가 아니라 Capability 부여 출처다.

```text
획득 콘텐츠
→ ActionCapability / UnitReplacementCapability / ActionAugmentCapability
→ 공통 ActionExecution과 RuleRecipe
```

같은 실행 형태를 여러 출처가 재사용한다.

## 서버 권한과 안전

- 서버가 현재 행동 경제, 부모 컨테이너, 남은 슬롯과 교체 적격성을 계산한다.
- 클라이언트는 임의의 남은 공격 수나 교체 가능 여부를 제출하지 않는다.
- 교체가 다시 자신을 교체하는 무한 재귀를 막는다.
- 부모 슬롯과 추가 자원은 같은 하위 실행 트랜잭션에서 예약하고 확정한다.
- 이미 확정된 실행 단위를 이후 취소로 롤백하지 않는다.
- 행동 컨테이너와 하위 실행은 각각 고유 ID와 revision을 가진다.

## 결과

- 일반 행동, 보너스 행동과 비용 없는 능동 특성을 같은 실행 체계에서 처리할 수 있다.
- 추가 공격과 공격 대체 능력이 자연스럽게 결합한다.
- 숨결 무기 같은 종 특성을 별도 전용 엔진 없이 구현할 수 있다.
- 하나의 행동 안에서 이미 해결된 공격과 남은 공격을 명확히 분리한다.
- 자원 비용, 행동 비용과 하위 슬롯 소비가 섞이지 않는다.
- 특수한 추가 행동과 제한 행동을 일반 행동 수치에 억지로 합치지 않는다.