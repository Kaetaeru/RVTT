# ADR-0025: 다른 턴의 특성은 타입 있는 규칙 이벤트와 시간 창으로 실행한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0017`](ADR-0017-derived-fixed-grants-and-stored-selections.md)
  - [`ADR-0024`](ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md)
  - [`10. Grant Graph와 Capability 모델`](../architecture/rules-content-grant-capability-model.md)
  - [`11. 공통 실행 계약`](../architecture/rules-content-execution-and-spell-contract.md)
  - [`19. 재주·특성의 트리거와 다른 턴 실행 모델`](../systems/rules/feat-feature-trigger-and-cross-turn-execution-model.md)

## 배경

재주, 직업 특성, 종 특성, 주문과 아이템 능력은 자신의 차례에 행동 버튼으로 사용하는 것만이 아니다.

- 다른 생물이 이동하거나 공격할 때 반응한다.
- 공격이나 내성 굴림 결과를 본 뒤 수정한다.
- 피해가 적용되기 직전에 감소시킨다.
- 다른 주문의 시전을 방해한다.
- 다른 생물의 턴에 명중한 공격에 추가 피해를 붙인다.
- 주도권 결정 직후 순서를 교환한다.
- 턴 시작, 턴 종료와 휴식 완료 시 자동으로 발동한다.

이 기능을 주문·재주별 콜백이나 자유 문자열 이벤트로 구현하면 발동 시점과 우선순위가 일관되지 않고, 중복 발동과 숨겨진 정보 누출을 막기 어렵다.

반대로 모든 다른 턴 능력을 `Reaction` 하나로 취급하면 반응 행동을 소비하지 않는 암습형 추가 효과, 의무적으로 적용되는 패시브와 실행 후 결과 효과를 구분할 수 없다.

## 결정

RVTT는 규칙 엔진이 생성하는 타입 있는 `RuleEvent`와 명시적인 `TimingWindow`를 사용한다.

```text
RuleExecution 또는 전투 상태 변화
→ RuleEvent 생성
→ 관련 TriggerCapability 인덱스 조회
→ 조건과 사용 제한 검증
→ TimingWindow 생성
→ 자동 적용 또는 사용자 제안
→ 자식 RuleExecution 해결
→ 부모 실행 재검증 후 계속
```

`RuleEvent`는 이벤트 유형, 발생 ID, 부모 실행, 관련 액터와 대상, 현재 턴 관계, 공개 가능한 규칙 스냅샷과 revision을 포함한다.

주요 이벤트 유형은 중앙 등록소에서 관리한다.

예시:

- `TurnStarted`, `TurnEnded`
- `InitiativeFinalized`
- `MovementAboutToLeaveReach`, `MovementCompleted`
- `AttackDeclared`, `AttackRollProduced`, `AttackHitConfirmed`
- `SavingThrowProduced`, `SavingThrowFailed`
- `DamageAboutToApply`, `DamageApplied`
- `SpellCastDeclared`, `SpellEffectAboutToCommit`
- `ConditionAboutToApply`, `ConditionApplied`
- `RestCompleted`

콘텐츠는 자유 문자열 콜백을 등록하지 않고 알려진 이벤트와 시간 창을 참조한다.

## TriggerCapability

재주나 특성의 실제 발동 조항은 `TriggerCapability`로 컴파일한다.

```text
TriggerCapability
├─ eventType
├─ timingWindow
├─ eventPredicate
├─ turnRelationPolicy
├─ offerPolicy
├─ actionCost
├─ usageGates[]
├─ responseRecipe
├─ informationPolicy
└─ priorityTier
```

- `eventPredicate`: 거리, 시야, 장비, 대상 관계, 공격 종류와 결과 조건
- `turnRelationPolicy`: 자신의 턴, 다른 생물의 턴, 아무 턴, 활성 턴 없음과 같은 관계
- `offerPolicy`: 자동, 선택 제안, 의무 적용, DM 판정
- `actionCost`: 반응, 자원, 행동 없음, 다른 행동 대체 등
- `usageGates`: 한 턴에 한 번, 한 라운드에 한 번, 사건당 한 번, 제한 자원 등
- `responseRecipe`: 굴림 수정, 피해 추가, 피해 감소, 공격 생성, 실행 중단과 같은 자식 레시피

## 반응 비용과 트리거를 분리한다

트리거가 발생했다고 반드시 반응 행동을 소비하는 것은 아니다.

```text
TriggerCapability
→ 언제 제안되는가

ActionCost
→ 사용하면 무엇을 소비하는가

UsageGate
→ 얼마나 자주 사용할 수 있는가
```

예를 들어:

- 기회 공격: 이동 이벤트 + 반응 비용
- 암습형 추가 피해: 명중 이벤트 + 행동 비용 없음 + 한 턴에 한 번
- 피해 저항 패시브: 피해 계산 이벤트 + 자동 적용 + 사용 제한 없음
- 주도권 교환: 주도권 확정 이벤트 + 행동 비용 없음 + 해당 주도권 절차당 한 번

## UsageGate

사용 제한은 기능별 불리언으로 구현하지 않는다.

```text
UsageGate
├─ gateKey
├─ scope
├─ limitExpression
├─ resetPolicy
├─ consumptionPoint
└─ sourceBinding
```

지원 범위 예시:

- `once_per_event`
- `once_per_turn`
- `once_on_each_of_your_turns`
- `once_per_round`
- `once_per_initiative_sequence`
- `limited_resource`
- `once_until_rest`

같은 기능이 여러 출처에서 생길 때는 `sourceBinding`과 stacking policy로 독립 사용인지 공유 제한인지 결정한다.

## 시간 창과 실행 개입

트리거 응답은 다음 종류 중 하나다.

- `Interrupt`: 부모 실행이 계속되기 전에 해결
- `Modify`: 부모 실행의 보류된 값이나 규칙 컨텍스트를 수정
- `Replace`: 원래 선택지나 실행을 다른 레시피로 교체
- `Prevent`: 실행, 효과 또는 상태 적용을 취소하거나 억제
- `Consequence`: 부모 결과가 확정된 뒤 후속 실행 생성
- `Deferred`: 다음 합법적인 처리 지점에 예약

반응 창은 어떤 결과를 플레이어가 볼 수 있는지 정확히 고정한다. 굴림 전 능력은 굴림 값을 공개하기 전에, 결과 확인 후 능력은 허용된 결과를 공개한 뒤 제안한다.

## 여러 응답과 중첩

같은 이벤트에 여러 능력이 반응할 수 있다.

- 의무적 자동 규칙을 먼저 적용한다.
- 같은 컨트롤러의 선택형 응답은 사용자가 순서를 선택할 수 있다.
- 서로 다른 액터의 동시 응답은 규칙 세트의 결정적 순서 정책을 따른다.
- 각 응답 뒤 남은 후보를 현재 상태로 다시 검증한다.
- 자식 실행이 새로운 이벤트를 만들 수 있지만 부모·자식 실행 ID와 최대 중첩 깊이로 순환을 막는다.
- 같은 `eventOccurrenceId`에 사건당 한 번인 기능이 중복 실행되지 않게 한다.

## 재주는 실행 체계가 아니다

`FeatDefinition`은 하나 이상의 Feature와 Capability를 부여하는 획득 패키지다.

재주 자체가 별도 반응 엔진을 가지지 않는다.

```text
FeatDefinition
→ GrantInstruction
→ TriggerCapability / ActionCapability / PassiveModifierCapability / RuleOverrideCapability
→ 공통 규칙 이벤트와 실행 엔진
```

직업 특성, 재주, 종 특성, 아이템과 주문은 출처만 다르고 동일한 트리거 계약을 사용한다.

## 서버 권한과 UI

- 서버가 이벤트 후보, 조건, 사용 제한, 반응 보유 여부와 비용을 계산한다.
- 클라이언트는 임의 이벤트 유형이나 성공 결과를 제출하지 않는다.
- 제안 UI는 발동 원인, 예상 비용, 남은 사용 횟수와 응답 가능 시점을 보여준다.
- 숨겨진 주문, 투명한 대상과 비공개 판정은 `informationPolicy`가 허용한 정보만 공개한다.
- 반응 창이 닫힌 뒤 늦게 도착한 요청은 실행 ID와 revision 불일치로 거부한다.

## 결과

- 재주와 직업 특성을 주문과 동일한 실행 기반에서 처리할 수 있다.
- 반응 행동, 행동 비용 없는 트리거와 패시브를 명확히 구분할 수 있다.
- 다른 생물의 턴에 사용하는 능력과 한 턴에 한 번인 능력을 정확히 지원할 수 있다.
- 굴림 전후와 피해 적용 전후의 정보 경계를 보존할 수 있다.
- 복잡한 중첩 반응을 허용하면서 중복 실행과 무한 재귀를 차단할 수 있다.