# ADR-0027: 패시브 특성은 수치 기여, 문맥 수정, 규칙 오버라이드와 조건부 활성화로 분리한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0017`](ADR-0017-derived-fixed-grants-and-stored-selections.md)
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0026`](ADR-0026-active-capabilities-action-containers-and-unit-replacements.md)
  - [`10. Grant Graph와 Capability 모델`](../architecture/rules-content-grant-capability-model.md)
  - [`11. 공통 실행 계약`](../architecture/rules-content-execution-and-spell-contract.md)
  - [`21. 패시브 특성, 수치 수정과 규칙 오버라이드 모델`](../architecture/passive-modifier-and-rule-override-model.md)

## 배경

재주, 직업 특성, 종 특성, 아이템과 지속 효과는 행동이나 반응을 만들지 않고 현재 규칙 계산을 바꾸기도 한다.

- 이동 속도, 최대 HP, 우선권과 방어도에 수치 보너스를 준다.
- 특정 무기나 상황의 공격·피해·판정에만 보너스를 준다.
- 이점 또는 불리점을 부여하거나 제거한다.
- 어려운 지형, 장거리 불리점, 엄폐와 같은 기본 규칙을 무시한다.
- 다른 능력치를 공격이나 주문 계산에 사용하도록 바꾼다.
- 방어구, 장비, 자세, HP, 주변 생물이나 환경 조건에 따라 켜지고 꺼진다.

이 효과를 모두 자유로운 수식이나 이벤트 콜백으로 구현하면 중첩 순서, 조건 변화와 캐시 무효화가 불명확해진다.

반대로 모든 패시브를 하나의 `+값` 구조로 만들면 이점, 규칙 무시, 대체 계산과 사용 가능 여부 변경을 표현할 수 없다.

## 결정

패시브 기능을 다음 네 역할로 분리한다.

```text
DerivedValueModifierCapability
→ 이동 속도, 최대 HP와 같은 파생 수치에 정량적 기여

ContextModifierCapability
→ 특정 굴림, 공격, 피해, 내성과 같은 현재 계산 문맥 수정

RuleOverrideCapability
→ 규칙의 허용 여부, 대체 계산, 예외와 우선 규칙 변경

ConditionalCapabilityGroup
→ 조건을 만족할 때 하위 Capability들을 활성화
```

`FeatDefinition`, `FeatureDefinition`, 종 특성, 아이템과 지속 효과는 이 Capability들을 부여하는 출처다.

패시브는 별도 실행을 매번 만들지 않는다. 규칙 엔진이 해당 값을 질의하거나 실행 문맥을 구성할 때 활성 Capability를 읽는다.

## 파생 수치 수정

```text
DerivedValueQuery
+ 활성 DerivedValueModifierCapability
+ 규칙 세트의 계산 단계와 중첩 정책
→ DerivedValueResult
```

주요 필드:

```text
DerivedValueModifierCapability
├─ targetValueId
├─ operation
├─ valueExpression
├─ activationPredicate?
├─ stackingKey
├─ stackingPolicy
├─ calculationPhase
├─ priority
└─ sourceBinding
```

지원 연산 예시:

- `add`
- `multiply`
- `set_if_higher`
- `set_if_lower`
- `minimum`
- `maximum`
- `replace_formula`

연산 순서는 콘텐츠 배열 순서가 아니라 규칙 세트가 소유하는 계산 단계로 결정한다.

## 실행 문맥 수정

특정 사건이나 대상과의 관계에 따라 적용되는 수정은 캐릭터의 영구 파생 수치로 합치지 않는다.

```text
ContextModifierCapability
├─ contextKind
├─ predicate
├─ contribution
├─ stackingKey
├─ stackingPolicy
├─ calculationPhase
└─ sourceBinding
```

문맥 예시:

- 특정 종류의 공격 굴림
- 특정 능력 판정
- 특정 대상에 대한 피해 굴림
- 특정 피해 유형을 받는 계산
- 집중 내성
- 주도권 굴림
- 이동 비용 계산

이점·불리점은 숫자 보너스가 아니라 타입 있는 `RollModeContribution`으로 제공한다.

## 규칙 오버라이드

단순 수치 수정으로 표현할 수 없는 패시브는 `RuleOverrideCapability`를 사용한다.

```text
RuleOverrideCapability
├─ rulePointId
├─ predicate
├─ overrideKind
├─ parameters
├─ precedenceTier
├─ stackingKey
├─ conflictPolicy
└─ sourceBinding
```

`rulePointId`는 중앙 `RulePointCatalog`의 타입 있는 규칙 지점을 참조한다.

예시:

- 어려운 지형이 이동 비용을 증가시키는가
- 장거리 공격에 불리점이 적용되는가
- 특정 엄폐 단계를 무시하는가
- 특정 무기에 사용할 능력치가 무엇인가
- 공격 행동의 공격 횟수가 어떻게 계산되는가
- 기회 공격 후보를 생성하는가
- 특정 상태가 행동을 금지하는가

콘텐츠는 임의 엔진 함수 이름이나 코드 경로를 참조하지 않는다.

## 조건부 활성화

조건부 패시브는 획득과 활성화를 분리한다.

```text
ConditionalCapabilityGroup
├─ activationPredicate
├─ capabilities[]
├─ dependencyKeys[]
├─ deactivationPolicy
└─ sourceBinding
```

조건이 거짓이 되어도 Feat나 Feature 획득 기록을 삭제하지 않는다. 현재 Capability Set에서만 비활성화한다.

조건 예시:

- 특정 장비를 착용하거나 들고 있음
- 방어구를 착용하지 않음
- 특정 상태 또는 자세
- HP 비율
- 인접한 아군 존재
- 빛, 어둠, 지형과 영역
- 집중 중인 효과

## 중첩과 충돌

모든 패시브는 `stackingKey`와 `stackingPolicy`를 명시한다.

지원 정책 예시:

- `stack`
- `highest_only`
- `lowest_only`
- `replace_by_priority`
- `independent_occurrences`
- `prohibited`

규칙 오버라이드 충돌은 선언 순서나 로딩 순서로 해결하지 않는다. `precedenceTier`와 `conflictPolicy`가 결정적인 결과를 만든다.

같은 우선순위에서 서로 양립할 수 없는 오버라이드는 콘텐츠 검증 오류 또는 DM 판정 대상으로 처리하고 임의로 하나를 선택하지 않는다.

## 계산 결과와 설명

파생 결과는 최종 숫자만 반환하지 않는다.

```text
DerivedValueResult
├─ finalValue
├─ baseValue
├─ acceptedContributions[]
├─ suppressedContributions[]
├─ appliedOverrides[]
└─ diagnostics[]
```

시트와 전투 로그는 이 결과를 사용해 현재 값이 왜 그렇게 계산되었는지 설명할 수 있다.

## 캐시와 무효화

패시브 계산을 매 프레임 전체 재계산하지 않는다.

Capability와 predicate는 의존 키를 등록한다.

예시:

- `equipment.changed`
- `condition.changed`
- `hit_points.changed`
- `position.changed`
- `nearby_allies.changed`
- `lighting.changed`
- `ongoing_effect.changed`

관련 의존 상태가 바뀔 때만 Capability 활성 상태와 파생 값 캐시를 무효화한다.

공격 대상이나 굴림처럼 일회성 문맥은 캐시된 영구 수치에 넣지 않고 현재 `RuleContext`에서 평가한다.

## Feat와 Feature의 관계

하나의 재주나 특성은 여러 패시브 조항을 부여할 수 있다.

```text
FeatDefinition
└─ grants[]
   ├─ DerivedValueModifierCapability
   ├─ ContextModifierCapability
   ├─ RuleOverrideCapability
   └─ ConditionalCapabilityGroup
```

능력치 증가, 숙련, 언어와 주문 습득은 패시브 Modifier가 아니라 Grant Graph의 영구 선택 및 부여로 처리한다.

## 결과

- 단순 수치 보너스와 규칙 예외를 분리할 수 있다.
- 상황별 굴림 보너스를 캐릭터의 영구 수치에 잘못 합치지 않는다.
- 이점·불리점, 엄폐 무시와 대체 능력치 같은 효과를 타입 있게 표현할 수 있다.
- 조건부 패시브를 획득 기록 손상 없이 켜고 끌 수 있다.
- 중첩과 충돌 결과가 로딩 순서에 의존하지 않는다.
- 시트와 로그에서 계산 근거를 설명할 수 있다.
- 의존성 기반 캐시로 매 프레임 전체 Capability 순회를 피할 수 있다.