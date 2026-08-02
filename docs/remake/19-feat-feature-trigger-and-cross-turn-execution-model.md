# 19. 재주·특성의 트리거와 다른 턴 실행 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](10-rules-content-grant-capability-model.md)
  - [`11. 공통 실행 계약`](11-rules-content-execution-and-spell-contract.md)
  - [`17. 주문 대상 지정·영역·공간 질의 모델`](17-spell-targeting-area-and-spatial-query-model.md)
  - [`18. RuleRecipe 사례`](18-rule-recipe-examples-magic-missile-and-witch-bolt.md)
  - [`ADR-0024`](decisions/ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md)
  - [`ADR-0025`](decisions/ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)

## 1. 문서 목적

재주, 직업 특성, 하위직업 특성, 종 특성, 아이템 능력과 주문은 자신의 차례에 행동 버튼을 누르는 것만으로 실행되지 않는다.

RVTT는 다음 패턴을 같은 규약으로 처리해야 한다.

- 적이 사정거리에서 벗어날 때 기회 공격
- 아군이 공격받거나 피해를 받을 때 보호 반응
- 다른 생물이 주문을 시전할 때 방해 주문
- 공격이 명중한 뒤 추가 피해 사용 여부 선택
- 굴림 결과를 본 뒤 재굴림하거나 값을 수정
- 피해 적용 직전에 감소 또는 저항 적용
- 다른 생물의 턴에 명중한 공격에도 한 턴에 한 번인 특성 사용
- 주도권 결정 직후 순서 교환
- 턴 시작·종료와 휴식 완료 시 자동 회복 또는 상태 처리
- 준비 행동으로 저장한 실행을 조건 충족 시 반응으로 발동

이 문서의 목표는 모든 특성을 `Reaction`으로 만드는 것이 아니다.

```text
언제 후보가 되는가
+ 사용 여부를 누가 결정하는가
+ 어떤 비용을 소비하는가
+ 얼마나 자주 사용할 수 있는가
+ 부모 실행의 어느 지점에 개입하는가
```

이 다섯 축을 분리하여 표현한다.

---

## 2. 핵심 분류

### 2.1 명시적 행동 Capability

자신의 차례에 사용자가 직접 시작한다.

- 행동
- 보너스 행동
- 활용 행동
- 이동 중 선언하는 능력
- 행동의 일부를 대체하는 특성

```text
ActionCapability
→ 사용자가 직접 선언
→ RuleExecution 시작
```

### 2.2 반응 비용을 쓰는 트리거

특정 사건이 발생할 때만 사용할 수 있고, 사용하면 반응을 소비한다.

```text
TriggerCapability
├─ eventType
├─ offerPolicy: prompt
└─ actionCost: reaction
```

예시 유형:

- 기회 공격
- 공격을 막거나 방어도를 올리는 능력
- 아군의 피해를 줄이는 능력
- 주문 시전을 방해하는 주문
- 특정 이동이나 공격에 대응하는 재주

### 2.3 행동 비용 없는 선택형 트리거

사건이 발생할 때 사용할지 선택하지만 반응 행동은 소비하지 않는다.

```text
TriggerCapability
├─ eventType
├─ offerPolicy: prompt
├─ actionCost: none
└─ usageGate: once_per_turn 등
```

예시 유형:

- 명중한 공격에 한 턴에 한 번 추가 피해
- 판정 실패 후 직업 자원을 사용해 값을 보정
- 치명타 또는 특정 피해 유형에 추가 효과 선택
- 공격 하나에 제한 자원을 얹는 특성

다른 생물의 턴에 사용 가능하더라도 그 자체가 반응인 것은 아니다.

### 2.4 의무적 자동 트리거

사용자가 선택하지 않고 규칙상 자동 적용된다.

```text
TriggerCapability
├─ offerPolicy: mandatory
└─ actionCost: none
```

예시 유형:

- 턴 시작 시 지속 피해
- 휴식 완료 시 자원 회복
- HP가 0이 될 때 발생하는 정해진 상태 변화
- 영역 진입 시 반드시 적용되는 효과

### 2.5 패시브 규칙 변경

사건에 반응하여 실행을 만드는 것이 아니라 계산 규칙 자체를 바꾼다.

```text
PassiveModifierCapability
RuleOverrideCapability
```

예시 유형:

- 추가 공격 횟수
- 방어도 계산 방식
- 피해 저항
- 이동 속도 증가
- 특정 무기를 주문시전 도구로 사용

매 공격마다 “저항을 사용할까요?” 같은 트리거를 만들지 않는다.

---

## 3. RuleEvent

규칙 엔진은 의미 있는 상태 변화마다 타입 있는 이벤트를 만든다.

```text
RuleEvent
├─ eventOccurrenceId
├─ eventType
├─ parentExecutionId?
├─ sourceActorId?
├─ primaryTargetIds[]
├─ relatedEntityIds[]
├─ activeTurnActorId?
├─ turnId?
├─ roundId?
├─ phase
├─ publicSnapshot
├─ privateServerSnapshot
├─ revisionSet
└─ tags[]
```

### eventOccurrenceId

동일한 사건을 네트워크 재전송이나 재평가로 두 번 처리하지 않기 위한 고정 ID다.

### publicSnapshot

해당 응답자가 규칙상 알 수 있는 정보만 포함한다.

### privateServerSnapshot

서버 검증에 필요한 전체 정보다. 클라이언트에 그대로 보내지 않는다.

### phase

한 실행 안의 정확한 개입 지점을 나타낸다.

예시:

```text
declared
targets_locked
before_roll
roll_produced
outcome_determined
before_effect_commit
after_effect_commit
execution_finished
```

모든 이벤트가 모든 phase를 가지는 것은 아니다.

---

## 4. 중앙 RuleEventCatalog

콘텐츠는 임의 문자열 이벤트를 만들지 않는다.

초기 중앙 이벤트 범주:

### 턴과 라운드

- `RoundStarted`
- `RoundEnded`
- `TurnStarted`
- `TurnEnded`
- `InitiativeRolled`
- `InitiativeFinalized`

### 이동

- `MovementDeclared`
- `MovementAboutToLeaveReach`
- `MovementEnteredReach`
- `MovementEnteredArea`
- `MovementExitedArea`
- `MovementCompleted`
- `TeleportDeclared`
- `TeleportCompleted`

### 공격

- `AttackDeclared`
- `AttackTargetsLocked`
- `AttackRollAboutToOccur`
- `AttackRollProduced`
- `AttackOutcomeDetermined`
- `AttackHitConfirmed`
- `AttackMissConfirmed`
- `CriticalHitConfirmed`

### 판정과 내성

- `AbilityCheckAboutToOccur`
- `AbilityCheckProduced`
- `AbilityCheckFailed`
- `SavingThrowAboutToOccur`
- `SavingThrowProduced`
- `SavingThrowFailed`
- `SavingThrowSucceeded`

### 피해와 회복

- `DamageCalculated`
- `DamageAboutToApply`
- `DamageApplied`
- `HealingAboutToApply`
- `HealingApplied`
- `HitPointsReachedZero`

### 주문과 실행

- `SpellCastDeclared`
- `SpellTargetsLocked`
- `SpellEffectAboutToCommit`
- `SpellEffectCommitted`
- `ConcentrationAboutToBreak`
- `ConcentrationEnded`
- `RuleExecutionAboutToCommit`
- `RuleExecutionCommitted`
- `RuleExecutionCancelled`

### 상태와 효과

- `ConditionAboutToApply`
- `ConditionApplied`
- `ConditionRemoved`
- `OngoingEffectStarted`
- `OngoingEffectEnded`
- `ResourceSpent`
- `RestCompleted`

이벤트 수를 무제한으로 늘리지 않는다. 새 이벤트는 기존 이벤트와 predicate로 표현할 수 없는 규칙 의미가 반복될 때만 중앙 등록소에 추가한다.

---

## 5. TriggerCapability 계약

```text
TriggerCapability
├─ capabilityId
├─ sourceContentId
├─ sourceOccurrenceId
├─ eventType
├─ acceptedPhases[]
├─ eventPredicate
├─ turnRelationPolicy
├─ actorRelationPolicy
├─ rangeAndVisibilityPolicy?
├─ offerPolicy
├─ actionCost
├─ usageGates[]
├─ responseRecipeId
├─ informationPolicy
├─ priorityTier
├─ stackingKey?
└─ conflictPolicy
```

### eventPredicate

구조화된 조건 조합이다.

```text
allOf
├─ event.attack.weaponAttack = true
├─ event.outcome.hit = true
├─ sourceActor has valid weapon
├─ target is hostile
└─ additional damage conditions satisfied
```

표시 설명 문자열을 파싱하지 않는다.

### turnRelationPolicy

```text
own_turn
other_creature_turn
ally_turn
enemy_turn
any_turn
no_active_turn
initiative_boundary
```

`any_turn`은 사용 제한이 없다는 뜻이 아니다. 별도의 `UsageGate`가 빈도를 결정한다.

### actorRelationPolicy

- 사건을 일으킨 액터 자신
- 사건의 대상
- 대상의 아군
- 시전자
- 현재 조종 중인 Actor
- 특정 거리의 관찰자

### offerPolicy

```text
automatic
mandatory
prompt_controller
prompt_dm
auto_decline_by_preference
dm_adjudicated
```

규칙상 선택인 능력을 기본적으로 자동 사용하지 않는다.

---

## 6. TimingWindow

```text
TimingWindow
├─ windowId
├─ eventOccurrenceId
├─ parentExecutionId?
├─ timingKind
├─ eligibleResponseIds[]
├─ visibleEventData
├─ resolutionPolicy
├─ state
├─ openedRevision
└─ closeReason?
```

### timingKind

```text
interrupt
modify
replace
prevent
consequence
deferred
```

### interrupt

부모 실행이 계속되기 전에 자식 실행을 끝낸다.

예시: 주문 시전을 방해하는 반응.

### modify

부모 실행의 보류된 수치나 컨텍스트를 변경한다.

예시: 방어도 증가, 굴림 보정, 피해 감소.

### replace

원래 가능한 응답이나 행동을 다른 실행으로 교체한다.

예시: 기회 공격 대신 주문 사용.

### prevent

효과 적용이나 실행 완료를 취소 또는 억제한다.

### consequence

부모 결과가 확정된 뒤 후속 실행을 생성한다.

예시: 피해를 받은 뒤 공격자에게 반격 피해.

### deferred

즉시 해결하지 않고 다음 합법적인 규칙 지점에 예약한다.

---

## 7. ActionCost

트리거와 비용은 별도다.

```text
ActionCost
├─ kind
├─ amount
├─ resourcePoolId?
├─ replacementTarget?
├─ reservationPolicy
└─ refundPolicy
```

`kind` 예시:

- `reaction`
- `none`
- `resource`
- `reaction_and_resource`
- `replace_opportunity_attack`
- `replace_attack_in_action`
- `consume_movement`
- `custom`

### 반응 상태

```text
ReactionEconomyState
├─ available
├─ spentByExecutionId?
├─ resetPolicy
└─ revision
```

정확한 회복 시점은 규칙 세트가 정의한다. 콘텐츠가 각각 별도 반응 불리언을 만들지 않는다.

---

## 8. UsageGate

```text
UsageGate
├─ gateKey
├─ scope
├─ subjectBinding
├─ limitExpression
├─ currentUsageLookup
├─ resetPolicy
├─ consumptionPoint
├─ rollbackPolicy
└─ stackingPolicy
```

### 주요 scope

#### once_per_event

같은 사건 발생 ID에 한 번만 사용한다.

#### once_per_turn

누구의 턴인지와 무관하게 현재 `turnId` 동안 한 번 사용한다.

이 제한은 다른 생물의 턴에 사용하고 자신의 턴에 다시 사용하는 상황을 구분할 수 있다.

```text
적 A의 턴
→ 특성 1회 사용

내 턴
→ 새로운 turnId이므로 다시 사용 가능
```

#### once_on_each_of_your_turns

소유자의 턴에서만 한 번 사용할 수 있다.

#### once_per_round

라운드 ID 전체에서 한 번이다.

#### once_per_initiative_sequence

현재 주도권 결정 절차에서 한 번이다.

#### limited_resource

명시적 ResourcePool을 소비한다.

#### once_until_rest

휴식 이벤트에서 초기화한다.

### consumptionPoint

사용 선언, 비용 확정, 굴림 수행, 효과 적용 중 어느 순간 사용 횟수를 소비하는지 정의한다.

취소와 무효화 시 반환 여부도 명시한다.

---

## 9. 부모 실행 수정 연산

트리거 응답은 공통 고급 연산으로 부모 실행에 개입한다.

```text
ModifyPendingRoll
ReplaceRollResult
AddRollModifier
GrantAdvantageOrDisadvantage
ModifyArmorClassContext
AddDamageComponent
ReducePendingDamage
ChangeDamageType
RedirectTarget
PreventEffect
CancelExecution
CreateReactionAttack
ReplaceResponseExecution
ScheduleConsequence
```

이 연산은 이미 확정된 영구 상태를 임의로 되돌리지 않는다. 지정된 시간 창에서 아직 commit되지 않은 값만 수정한다.

확정 후 되돌려야 하는 규칙은 명시적인 보상 트랜잭션을 사용한다.

---

## 10. 여러 트리거의 순서

한 사건에 여러 능력이 반응할 수 있다.

### 10.1 우선 단계

```text
1. 규칙상 의무적인 억제·교체·면역
2. 사건을 발생시킨 실행의 직접 응답
3. 사건 대상의 방어 응답
4. 다른 액터의 관찰자·보호 응답
5. 결과 확정 후 consequence
```

정확한 tier는 이벤트 종류와 규칙 세트가 정의한다.

### 10.2 같은 컨트롤러의 여러 선택

사용자는 가능한 응답을 보고 하나를 선택하거나, 규칙상 허용되면 순서대로 여러 개 사용할 수 있다.

반응을 이미 소비하면 남은 반응 비용 응답은 즉시 비활성화한다.

### 10.3 서로 다른 액터

동시 응답 순서는 다음 중 규칙 세트가 정한 결정적 정책을 사용한다.

- 주도권 순서
- 현재 턴 액터부터 시계 방향 순서
- 방어자 우선
- DM 선택이 필요한 동률

서버마다 다른 순서가 나오지 않게 한다.

### 10.4 재검증

한 응답이 끝날 때마다 다음을 다시 검사한다.

- 원래 사건이 아직 유효한가
- 대상이 여전히 존재하고 적격한가
- 반응과 자원이 남아 있는가
- 이미 다른 응답으로 결과가 확정되었는가
- 동일한 사건당 사용 제한을 소비했는가

---

## 11. 중첩 반응과 순환 방지

반응 실행도 새로운 사건을 만들 수 있다.

```text
부모 실행
→ TimingWindow A
→ 반응 실행 B
→ B에 대한 TimingWindow C
→ C 해결
→ B 해결
→ A로 복귀
→ 부모 실행 계속
```

필수 필드:

```text
parentExecutionId
rootExecutionId
reactionDepth
visitedCapabilityOccurrences
```

안전 규칙:

- 동일 Capability가 동일 사건 사슬에서 무한 재진입하지 않게 한다.
- 최대 반응 중첩 깊이를 둔다.
- 같은 `eventOccurrenceId`의 사건당 한 번 제한을 서버가 보장한다.
- 순환이 감지되면 임의 순서로 진행하지 않고 진단 가능한 실패 상태로 전환한다.

---

## 12. 정보 공개 정책

반응 선택은 정보 시점에 민감하다.

```text
InformationPolicy
├─ revealEventType
├─ revealActorIdentity
├─ revealTargetIdentity
├─ revealRollTotal
├─ revealNaturalDie
├─ revealOutcome
├─ revealSpellIdentity
├─ revealDamageTotal
└─ revealHiddenModifiers
```

예시:

- 굴림 전에 선언해야 하는 능력은 주사위 결과를 보여주지 않는다.
- 굴림 결과를 본 뒤 쓰는 능력은 허용된 합계만 보여준다.
- 주문 정체를 알 수 없는 반응은 주문 이름을 자동 공개하지 않는다.
- DM의 비공개 굴림에 반응할 수 있는 능력은 규칙상 허용되는 성공·실패 정보만 보여준다.

UI 편의를 위해 규칙보다 더 많은 정보를 공개하지 않는다.

---

## 13. 반응 제안 UI

선택형 TimingWindow는 실행을 일시 정지하고 다음을 표시한다.

```text
발동 원인
사용 가능한 능력
비용
남은 사용 횟수
예상 대상과 효과
선택 가능 정보
승인 / 거절
```

예시:

```text
오우거의 공격이 당신에게 명중했습니다.

[방어 반응]
비용: 반응 1회
효과: 이번 공격에 대한 방어도 증가

[E] 사용   [Q] 거절
```

### 제안 피로 감소

플레이어는 Capability별로 다음 로컬 선호를 가질 수 있다.

- 항상 묻기
- 이번 턴 동안 자동 거절
- 이번 전투 동안 자동 거절

규칙상 선택인 능력을 영구 자동 사용으로 설정하는 것은 초기 핵심 범위에서 제외한다.

### 여러 후보

여러 능력이 가능하면 한 창에서 후보를 묶어 보여준다. 각각 별도 팝업을 연속으로 띄우지 않는다.

---

## 14. 대표 사례

### 14.1 기회 공격

```text
MovementAboutToLeaveReach
→ 관찰자의 OpportunityResponseCapability 조회
→ 시야·도달거리·반응 상태 검증
→ TimingWindow: interrupt
→ 반응 소비
→ CreateReactionAttack
→ 공격 해결
→ 대상 생존·이동 가능 여부 재검증
→ 원래 이동 계속 또는 중단
```

기회 공격은 특정 재주의 전용 시스템이 아니라 공통 이동 사건 응답이다.

### 14.2 기회 공격을 주문으로 교체하는 재주

```text
OpportunityResponseOffered
→ ReplaceResponseExecution
   ├─ original: reaction melee attack
   └─ replacement: eligible spell RuleRecipe
→ 반응 비용은 교체된 실행이 공유
```

원래 기회 공격과 교체 주문이 반응을 두 번 소비하지 않는다.

### 14.3 한 턴에 한 번인 추가 피해

```text
AttackHitConfirmed
→ 조건을 만족하는 AddDamage TriggerCapability 조회
→ actionCost: none
→ usageGate: once_per_turn
→ 사용자에게 사용 여부 제안
→ AddDamageComponent
→ 현재 공격의 피해 commit에 포함
```

다른 생물의 턴에 반응 공격이 명중했더라도 현재 `turnId`에서 아직 사용하지 않았다면 사용할 수 있다.

### 14.4 아군 피해 감소

```text
DamageAboutToApply
→ 일정 거리의 보호 Capability 조회
→ reaction + 시야·장비 조건 검사
→ ReducePendingDamage
→ 감소 후 피해량 확정
```

피해가 이미 HP에 적용된 뒤 다시 회복시키는 방식으로 흉내 내지 않는다.

### 14.5 방어도 증가 반응

```text
AttackOutcomeDetermined: hit
→ TimingWindow: modify
→ reaction 소비
→ ModifyArmorClassContext
→ 공격 결과 재평가
→ miss로 바뀌면 피해 단계 취소
```

공격이 이미 피해까지 적용된 후 롤백하지 않는다.

### 14.6 주문 방해

```text
SpellCastDeclared
→ 관찰 가능한 반응 후보 조회
→ OpenReactionWindow
→ 방해 주문 실행
→ InterruptExecution 또는 원래 실행 계속
→ 원래 주문 비용과 효과 정책 적용
```

### 14.7 주도권 교환

```text
InitiativeFinalized
→ eligible swap Capability 조회
→ timing: initiative_boundary
→ 비용 없음
→ 교환 상대 승인 필요 여부 처리
→ initiative order transaction 확정
```

일반 턴 반응 UI를 억지로 재사용하지 않고 같은 TimingWindow 계약의 주도권 전용 표현을 사용한다.

### 14.8 준비 행동

```text
자신의 턴
→ 실행할 행동 RuleRecipe 선택
→ 감지 가능한 트리거 조건 정의
→ StoreExecution

조건 후보 발생
→ TimingWindow
→ 반응 소비
→ 저장된 실행 재검증
→ 실행 또는 포기
```

준비 행동은 별도 하드코딩이 아니라 `StoreExecution + TriggerCapability + reaction cost` 조합이다.

---

## 15. 재주와 Feature 데이터 작성 원칙

`FeatDefinition`은 실행 코드를 직접 가지는 거대한 객체가 아니다.

```text
FeatDefinition
├─ prerequisites
├─ repeatability
├─ choices
└─ grants[]
```

`grants`는 필요에 따라 다음을 제공한다.

- `TriggerCapability`
- `ActionCapability`
- `PassiveModifierCapability`
- `RuleOverrideCapability`
- `ResourceCapability`
- 다른 FeatureDefinition

하나의 재주가 여러 조항을 가지면 조항별 Capability로 분리한다.

```text
feat.example
├─ passive clause
│  └─ PassiveModifierCapability
├─ reaction clause
│  └─ TriggerCapability
└─ limited use clause
   └─ ResourceCapability + TriggerCapability
```

한 조항의 구현 오류 때문에 재주 전체가 비활성화되지 않도록 지원 수준도 조항 단위로 표시할 수 있다.

---

## 16. 서버 검증

서버는 다음을 검증한다.

- 이벤트가 실제 권위 실행에서 생성되었는가
- TimingWindow가 아직 열려 있는가
- Capability가 현재 활성 상태인가
- 사건과 액터 관계가 predicate를 만족하는가
- 턴 관계와 정확한 phase가 일치하는가
- 반응, 자원과 UsageGate가 남아 있는가
- 공개되지 않은 정보를 클라이언트가 추측하여 제출하지 않았는가
- 응답 뒤 부모 실행이 여전히 유효한가
- 동일 이벤트에 중복 요청이 아닌가
- 실행 depth와 순환 제한을 위반하지 않는가

클라이언트는 다음을 결정하지 않는다.

- 자신이 반응 후보인지
- 공격이 실제로 명중했는지
- 피해 감소 후 최종 피해량
- 사용 제한이 초기화되었는지
- 부모 실행을 취소할 수 있는지

---

## 17. 성능

모든 이벤트에서 모든 캐릭터의 모든 특성을 검사하지 않는다.

```text
TriggerCapabilityIndex
├─ by eventType
├─ by acceptedPhase
├─ by sceneId
├─ by owningActorId
├─ by observerRangeBucket
└─ by relation requirements
```

처리 흐름:

```text
RuleEvent 생성
→ eventType 인덱스로 후보 축소
→ 공간 인덱스로 관찰 가능한 액터 축소
→ 저비용 predicate
→ 상세 서버 검증
→ 실제 TimingWindow 후보 생성
```

비활성 Feature, 다른 장면의 Actor와 이미 사용 제한을 소모한 Capability는 초기 후보에서 제외한다.

---

## 18. 저장과 재접속

일반적인 짧은 반응 창은 영구 저장하지 않는다.

다만 서버 종료나 재접속에도 보존해야 하는 장기 상태는 저장한다.

- 준비 행동의 StoredExecution
- 지속 효과가 제공하는 TriggerCapability
- 현재 자원 소모 상태
- 라운드·턴 사용 제한 상태가 필요한 진행 중 전투
- 중단된 DM 판정 요청

전투 저장 시 열린 TimingWindow가 있다면 부모 실행, 이벤트 ID, 후보와 비용 예약을 함께 저장하거나 안전한 중단 지점으로 롤백한다. 저장 전략은 전투 영속성 명세와 맞춘다.

---

## 19. 테스트 기준

필수 테스트:

1. 반응을 소비한 뒤 같은 턴에 두 번째 반응 후보가 비활성화된다.
2. 행동 비용 없는 한 턴 1회 특성이 다른 생물의 턴에 정상 사용된다.
3. 다음 생물의 턴에서는 `turnId`가 바뀌어 한 턴 1회 제한이 초기화된다.
4. 굴림 전 능력에 주사위 결과가 공개되지 않는다.
5. 굴림 후 능력에는 규칙상 허용된 결과만 공개된다.
6. 피해 감소가 HP 적용 전에 실행된다.
7. 방어도 증가로 명중이 빗나감으로 변경되면 피해 실행이 생성되지 않는다.
8. 기회 공격 중 이동 중단 효과가 발생하면 원래 이동이 재검증된다.
9. 기회 공격 교체 주문이 반응을 한 번만 소비한다.
10. 여러 액터의 동시 응답이 결정적인 순서로 해결된다.
11. 자식 반응이 새 반응을 만들더라도 최대 깊이와 순환 검사가 작동한다.
12. 같은 eventOccurrenceId의 재전송이 중복 발동하지 않는다.
13. 준비 행동이 조건 충족 시 저장된 실행을 재검증한다.
14. 숨겨진 주문과 비공개 굴림 정보가 반응 UI로 누출되지 않는다.
15. 휴식과 턴 경계에서 UsageGate가 정확히 초기화된다.

---

## 20. 명시적 비목표

- 모든 다른 턴 능력을 반응 행동으로 취급하지 않는다.
- 재주마다 개별 이벤트 리스너와 RemoteEvent를 만들지 않는다.
- 콘텐츠 설명 문자열을 파싱하여 발동 시점을 추론하지 않는다.
- 피해가 적용된 뒤 회복으로 피해 감소를 흉내 내지 않는다.
- 모든 이벤트에서 모든 Capability를 전체 순회하지 않는다.
- 숨겨진 규칙 정보를 UI 편의를 위해 미리 공개하지 않는다.
- 선택형 능력을 플레이어 승인 없이 자동 소비하지 않는다.
- 주문과 재주별로 별도의 반응 스택을 만들지 않는다.

---

## 21. 다음 단계

다음으로는 `EffectRecipe`의 실제 해결 규약을 정한다.

특히 다음을 연결해야 한다.

1. 피해·회복·임시 HP
2. 공격 굴림·내성 굴림과 성공 분기
3. 피해 저항·면역·취약성과 피해 감소 순서
4. 다중 피해 구성요소와 동시 피해
5. 상태 적용·제거와 반복 내성
6. 강제 이동과 이동 중 트리거
7. 부모 실행을 수정하는 반응과 최종 commit 순서
8. 한 턴에 한 번인 추가 피해의 결합

이 단계가 끝나면 주문, 재주, 직업 특성과 몬스터 능력이 같은 실행 그래프 안에서 실제 결과를 공유할 수 있다.