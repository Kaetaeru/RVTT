# 14. 주문 자원 풀과 시전 결제 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`11. 공통 실행 계약과 마법 처리 모델`](../../architecture/rules-content-execution-and-spell-contract.md)
  - [`12. 주문 획득·준비·시전 권한 모델`](../character/spell-acquisition-preparation-and-cast-access-model.md)
  - [`13. 주문책 저장소와 복사 모델`](../character/spellbook-repository-and-copying-model.md)
  - [`ADR-0011`](../../decisions/ADR-0011-persistent-character-current-state.md)
  - [`ADR-0018`](../../decisions/ADR-0018-source-scoped-spellcasting-profiles.md)
  - [`ADR-0020`](../../decisions/ADR-0020-typed-spell-resource-pools-and-explicit-cast-payments.md)

## 1. 문서 목적

RVTT의 주문은 하나의 공통 `mana` 수치로 실행되지 않는다.

캐릭터는 동시에 다음 자원을 가질 수 있다.

- 레벨별 일반 주문 슬롯
- 다중직업 진행으로 계산되는 공유 주문 슬롯
- 별도의 개수와 회복 규칙을 가진 워락형 슬롯
- 종, 재주와 특성이 주는 제한된 무료 시전
- 주문을 사용할 수 있는 직업 자원이나 포인트
- 지팡이, 완드와 기타 아이템의 충전
- 일시 효과가 제공하는 임시 시전권
- 슬롯 없이 추가 시간을 지불하는 의식 시전

같은 주문도 여러 `SpellcastingProfile`에서 제공될 수 있고, 하나의 프로필이 여러 자원 풀을 사용할 수도 있다.

이 문서는 다음을 정형화한다.

```text
SpellCastRoute
→ 가능한 CastPaymentOption 생성
→ 플레이어가 하나의 결제 계획 선택
→ 서버가 행동·자원·소모품 예약
→ 규칙상 확정 시점에서 원자적 소비
→ 확정된 castLevel로 주문 해결
```

목표는 모든 자원을 같은 데이터 모양으로 만드는 것이 아니다. 서로 다른 자원이 같은 선택, 검증, 예약, 확정, 로그와 오류 처리 절차를 사용하게 하는 것이다.

---

## 2. 책임 경계

다음 네 요소를 혼합하지 않는다.

### SpellDefinition

주문 자체의 규칙을 소유한다.

- 기본 주문 레벨
- 시전 시간
- 대상과 사거리
- 구성요소
- 집중과 지속시간
- 기본 효과
- 상위 레벨 시전 변화

### SpellCastRoute

이 캐릭터가 이 주문을 어떤 출처와 시전 규칙으로 사용할 수 있는지 나타낸다.

- 연결된 `SpellcastingProfile`
- 시전 능력치와 주문 DC 계산
- 습득·준비·항상 준비 상태
- 의식 시전 가능 여부
- 구성요소와 도구 변경
- 사용할 수 있는 자원 풀 선택 규칙

### ResourcePool

실제로 소비하고 회복되는 자원을 소유한다.

- 최대량 또는 최대량 계산
- 현재 소모 상태
- 슬롯 등급 또는 포인트 구조
- 회복 정책
- 소유 범위
- 사용할 수 있는 콘텐츠 제한

### CastCostPlan

이번 한 번의 시전에 무엇을 지불할지 확정한 계획이다.

- 선택된 시전 경로
- 선택된 주 결제 옵션
- 확정된 시전 레벨
- 행동 경제 비용
- 물질 구성요소와 소모품
- 특성이나 메타마법이 추가한 보조 비용
- 예약과 확정 상태

---

## 3. 전체 구조

```text
Character Capability Set
├─ SpellCastRoute
│  ├─ spellId
│  ├─ spellcastingProfileId
│  ├─ casting ability and DC rule
│  ├─ access and readiness state
│  └─ payment eligibility rules
│
└─ Accessible ResourcePool Set
   ├─ character-owned pools
   ├─ profile or feature pools
   ├─ accessible item pools
   └─ temporary effect pools

Spell Payment Resolver
├─ route validation
├─ eligible pool lookup
├─ cast level calculation
├─ material and action checks
└─ CastPaymentOption[]
```

실행 시:

```text
주문 카드 선택
→ SpellCastRoute 선택 또는 자동 단일 선택
→ CastPaymentOption 선택
→ 대상·모드·시전 레벨 입력
→ CastCostPlan 생성
→ 서버 검증과 예약
→ 실행 트랜잭션 확정
```

---

## 4. 자원 풀 공통 식별

모든 자원 풀은 최소한 다음 식별 정보를 가진다.

```text
poolInstanceId
poolDefinitionId
poolKind
ownerScope
ownerId
sourceChain
rulesetId
contentVersion
stateRevision
status
```

- `poolInstanceId`: 실제 캐릭터, 아이템 또는 효과에 존재하는 자원 풀 인스턴스
- `poolDefinitionId`: 최대량과 회복 규칙을 제공하는 콘텐츠 정의
- `poolKind`: 등급별 슬롯, 고정 등급 슬롯, 제한 사용권, 포인트, 아이템 충전 등
- `ownerScope`: character, feature, profile, item, effect 등
- `ownerId`: 실제 소유자 ID
- `sourceChain`: 어떤 직업, 재주, 아이템 또는 효과로 생성되었는지 추적
- `stateRevision`: 동시 소비와 중복 요청을 방지하기 위한 상태 버전
- `status`: active, unavailable, exhausted, expired, migration_required 등

표시 이름이나 번역 문자열을 풀 식별자로 사용하지 않는다.

---

## 5. 자원 풀 종류

### 5.1 RankedSpellSlotPool

일반적인 레벨별 주문 슬롯이다.

```text
RankedSpellSlotPool
├─ maximumByRank formula
├─ minimumRank
├─ maximumRank
├─ spentByRank
├─ recoveryPolicy
└─ usageEligibility
```

최대 슬롯 수는 직업 진행과 다중직업 규칙에서 파생한다.

현재 상태는 기본적으로 등급별 `spentByRank`를 저장한다.

```text
maximumByRank: {1: 4, 2: 3, 3: 2}
spentByRank:   {1: 1, 2: 3, 3: 0}
remaining:     {1: 3, 2: 0, 3: 2}
```

최대량을 저장 원본으로 중복하지 않는다. 레벨업이나 진행 변경으로 최대량이 바뀌면 현재 소모 기록과 새 최대량을 규칙에 따라 조정한다.

### 5.2 SharedMulticlassSlotPool

공유 다중직업 슬롯은 `RankedSpellSlotPool`의 소유와 계산 정책이다.

```text
character spellcasting progression
→ shared slot progression calculator
→ one character-scoped RankedSpellSlotPool
```

직업별 준비 목록과 시전 능력치는 각각의 `SpellcastingProfile`에 남지만, 규칙상 허용된 여러 프로필이 같은 슬롯 풀을 사용할 수 있다.

```text
Wizard profile ─┐
Cleric profile ─┼→ shared-multiclass-slot-pool
Druid profile ──┘
```

공유 슬롯 풀을 각 직업 프로필에 복사하지 않는다.

### 5.3 FixedRankSpellSlotPool

워락형 슬롯처럼 모든 현재 슬롯이 하나의 유효 등급을 공유하는 별도 풀이다.

```text
FixedRankSpellSlotPool
├─ maximumSlots formula
├─ effectiveRank formula
├─ spentSlots
├─ recoveryPolicy
└─ usageEligibility
```

예시:

```text
maximumSlots: 2
effectiveRank: 3
spentSlots: 1
remaining: 1
```

이 풀은 일반 슬롯 풀과 합산하지 않는다.

주문을 이 풀로 시전하면 선택 가능한 임의의 낮은 슬롯 등급을 만드는 것이 아니라 현재 `effectiveRank`로 시전한다.

### 5.4 LimitedCastAllowance

특정 주문 또는 제한된 주문 후보군에만 사용할 수 있는 무료 시전권이다.

```text
LimitedCastAllowance
├─ allowedSpellIds or spell predicate
├─ castRank rule
├─ maximumUses formula
├─ spentUses
├─ recoveryPolicy
├─ componentOverrides
└─ slotCastingAfterAllowancePolicy
```

이 자원은 일반 슬롯이 아니다.

```text
재주가 부여한 특정 주문 무료 시전 1회
≠ 모든 1레벨 주문에 사용할 수 있는 1레벨 슬롯 1개
```

Grant가 허용하는 경우 무료 사용을 소진한 뒤 일반 슬롯으로 같은 주문을 시전할 수 있다. 이 경우 무료 결제와 슬롯 결제는 서로 다른 `CastPaymentOption`으로 생성한다.

### 5.5 FeaturePointPool

직업 자원이나 특수 포인트를 주문 시전 비용으로 사용할 때 사용한다.

```text
FeaturePointPool
├─ maximum formula
├─ current or spent value
├─ recoveryPolicy
├─ conversionPolicy
└─ usageEligibility
```

포인트를 주문 슬롯으로 바꾸는 특성이 있다면, 숨겨진 자동 결제로 처리하지 않는다.

```text
포인트를 슬롯으로 변환하는 별도 규칙 행동
→ 슬롯 풀 상태 변경
→ 이후 일반 슬롯 결제
```

규칙이 직접 포인트를 사용해 주문을 시전하도록 한다면 `PointPayment`를 사용한다.

### 5.6 ItemChargePool

아이템 충전은 `ItemInstance`에 연결된다.

```text
ItemChargePool
├─ itemInstanceId
├─ maximumCharges
├─ currentCharges
├─ rechargePolicy
├─ destructionOrFailurePolicy
└─ itemUseRequirements
```

아이템을 소유하지 않거나 접근할 수 없거나, 필요한 장착·조율 조건을 충족하지 않으면 풀은 캐릭터의 사용 가능 자원 집합에 들어오지 않는다.

아이템을 양도하면 현재 충전도 아이템과 함께 이동한다.

### 5.7 TemporaryCastPool

상태 효과, 장면 효과 또는 서사 보상이 일시적으로 제공하는 주문 자원이다.

```text
TemporaryCastPool
├─ sourceEffectInstanceId
├─ allowed spells
├─ remaining uses
├─ expirationCondition
└─ removalPolicy
```

출처 효과가 종료되면 해당 풀과 미사용 결제 선택지를 정리한다.

지속 효과의 종료가 캐릭터의 영구 성장 원본을 수정하지 않는다.

---

## 6. 자원 상태의 소유 위치

자원 상태는 실제 소유자와 함께 저장한다.

```text
Character current state
├─ shared and class spell slot states
├─ feature point states
└─ limited cast allowance states

ItemInstance state
└─ item charge states

EffectInstance state
└─ temporary cast pool states
```

아이템 충전을 캐릭터 상태에 복사하거나, 캐릭터의 슬롯 소모량을 `SpellcastingProfile` 정의에 기록하지 않는다.

최대값은 가능한 한 규칙 정의와 성장 원본에서 파생하고, 현재 소비·충전·회복 상태만 영구 상태로 저장한다.

---

## 7. 자원 풀과 SpellcastingProfile 연결

`SpellcastingProfile`은 현재 풀 인스턴스 ID를 콘텐츠 정의에 하드코딩하지 않는다.

대신 사용할 수 있는 풀의 조건을 제공한다.

```text
paymentEligibility
├─ allowedPoolKinds
├─ requiredPoolTags
├─ forbiddenPoolTags
├─ minimumCastRank
├─ maximumCastRank
├─ allowUpcasting
└─ source-specific restrictions
```

런타임의 `Spell Payment Resolver`가 캐릭터와 접근 가능한 아이템의 실제 풀을 조회하여 결제 선택지를 만든다.

이를 통해 다음이 가능하다.

- 서로 다른 직업 프로필이 하나의 공유 슬롯 풀 사용
- 하나의 직업 주문을 일반 슬롯 또는 워락형 슬롯으로 시전
- 같은 주문을 무료 시전 또는 일반 슬롯으로 선택
- 아이템에서 제공된 주문을 아이템 충전으로만 시전

풀 사용 허용 여부는 클래스 이름을 직접 검사하지 않고 프로필, Grant와 풀의 태그 및 명시적 규칙으로 판정한다.

---

## 8. SpellCastRoute와 결제 선택지

하나의 `SpellCastRoute`는 주문의 출처와 시전 능력치를 고정하지만, 여러 결제 방법을 가질 수 있다.

```text
SpellCastRoute
├─ routeId
├─ spellId
├─ spellcastingProfileId
├─ sourceChain
├─ castingAbilityRule
├─ accessState
├─ readinessState
├─ componentPolicy
├─ ritualPolicy
└─ paymentEligibility
```

결제 해석 결과:

```text
CastPaymentOption
├─ paymentOptionId
├─ routeId
├─ primaryPayment
├─ castLevel
├─ supplementalCosts
├─ requirementSnapshot
├─ availability
├─ unavailableReasons
└─ displaySummary
```

`CastPaymentOption`은 영구 저장 원본이 아니라 현재 상태에서 만든 파생 결과다.

---

## 9. 주 결제 유형

한 번의 일반 시전은 정확히 하나의 주 결제 유형을 선택한다.

```text
PrimaryCastPayment
├─ RankedSlotPayment
├─ FixedRankSlotPayment
├─ LimitedAllowancePayment
├─ FeaturePointPayment
├─ ItemChargePayment
└─ NoPrimaryResourcePayment
```

### RankedSlotPayment

```text
poolInstanceId
slotRank
amount: 1
```

선택한 슬롯 등급이 `castLevel`을 결정한다.

### FixedRankSlotPayment

```text
poolInstanceId
slotIndex or amount
castLevel: pool.effectiveRank
```

### LimitedAllowancePayment

```text
poolInstanceId
uses: 1
castLevel: allowance.castRank
```

### FeaturePointPayment

```text
poolInstanceId
points
castLevel rule
```

### ItemChargePayment

```text
itemInstanceId
poolInstanceId
charges
castLevel rule
```

### NoPrimaryResourcePayment

캔트립, 무제한 시전, 의식 시전 등 주 자원을 소비하지 않는 경로에 사용한다.

자원을 소비하지 않는다는 뜻이지 행동, 시간, 구성요소와 대상 검증을 생략한다는 뜻은 아니다.

---

## 10. 추가 비용과 요구 조건

주 결제 하나만으로 모든 주문 비용을 표현하지 않는다.

```text
CastCostPlan
├─ actionEconomyCost
├─ primaryPayment
├─ supplementalPayments[]
├─ materialRequirements[]
├─ consumedMaterials[]
├─ focusOrComponentRequirements[]
├─ timeCost
├─ specialCostHandlerId
└─ commitPolicy
```

### 행동 경제 비용

행동, 보너스 행동, 반응과 특수 시전 시간을 별도로 예약한다.

### 보조 자원 비용

메타마법이나 특성 수정처럼 주 슬롯 결제와 동시에 포인트를 소비할 수 있다.

```text
3레벨 주문 슬롯 1개
+ 소서리 포인트 2점
```

이 경우 슬롯은 주 결제이고 포인트는 보조 결제다. 둘은 하나의 트랜잭션에서 함께 예약하고 확정한다.

### 물질 구성요소

소모되지 않는 일반 구성요소, 금전 가치가 있는 구성요소와 실제로 소비되는 구성요소를 구분한다.

구성요소 검증과 인벤토리 차감은 후속 아이템·인벤토리 계약과 연결하지만, 결제 계획에는 필요한 항목과 예약 결과가 포함되어야 한다.

### 특별 비용

HP 감소, 히트 다이스, 피로, 특정 아이템 파괴처럼 일반 자원 풀로 표현하기 어려운 드문 비용은 등록된 `specialCostHandlerId`를 사용할 수 있다.

전용 처리기도 공통 예약, 검증, 확정과 로그를 우회하지 않는다.

---

## 11. 시전 레벨과 상위 레벨 시전

`castLevel`은 실제 선택된 결제에서 결정한다.

```text
SpellDefinition.baseLevel
+ selected CastPaymentOption
→ castLevel
→ upcast parameters
```

검증 규칙:

- `castLevel`은 주문의 기본 레벨보다 낮을 수 없다.
- 프로필이 상위 레벨 시전을 허용해야 한다.
- 선택한 자원 풀이 해당 레벨을 제공해야 한다.
- 무료 시전과 아이템 시전은 정의된 레벨 범위를 따라야 한다.
- 주문의 상위 레벨 효과는 확정된 `castLevel`을 사용한다.

주문 효과는 다음 문맥을 받는다.

```text
SpellExecutionContext
├─ spellId
├─ routeId
├─ castLevel
├─ casterLevel variables
├─ spellcastingAbility
├─ saveDC and attackBonus
├─ sourceChain
└─ paymentReceipt
```

효과 처리기는 `warlockSlot == true`처럼 자원 이름을 검사하지 않고, 규칙이 특별히 자원 출처를 요구하는 경우에만 결제 영수증의 타입 있는 정보를 사용한다.

---

## 12. 캔트립과 무제한 시전

캔트립은 0레벨 슬롯을 소비하지 않는다.

```text
NoPrimaryResourcePayment
+ normal action and component requirements
+ cantrip scaling rule
```

캔트립 성장 수치는 `castLevel`이 아니라 주문 정의가 지정한 캐릭터 레벨, 클래스 레벨 또는 기타 스케일 변수에서 계산한다.

종이나 아이템이 특정 주문을 무제한 제공하는 경우에도 별도의 슬롯을 만들지 않는다.

---

## 13. 의식 시전

의식 시전은 일반 슬롯 결제의 변형이 아니라 별도 시전 방법이다.

```text
Ritual CastPaymentOption
├─ primaryPayment: none
├─ additionalTime
├─ ritualEligibility
├─ spellAccess requirement
├─ repositoryAccess requirement when applicable
└─ normal or modified component requirements
```

주문책에서 직접 의식 시전하는 규칙이라면 현재 준비 목록이 아니라 접근 가능한 주문책과 프로필 정책을 검사할 수 있다.

전투 중 즉시 사용할 수 없는 긴 의식은 일반 행동 버튼과 같은 방식으로 즉시 완료하지 않고 진행 활동 또는 장기 시전 흐름으로 연결한다.

---

## 14. 결제 선택지 생성

`Spell Payment Resolver`는 다음 순서로 현재 결제 선택지를 만든다.

```text
1. SpellCastRoute가 현재 활성인지 검사
2. 주문 습득·준비·항상 준비 상태 검사
3. 접근 가능한 ResourcePool 집합 수집
4. route paymentEligibility로 후보 풀 필터링
5. 가능한 슬롯 등급과 고정 시전 등급 계산
6. 무료 시전과 아이템 결제 후보 추가
7. 의식 또는 무제한 경로 추가
8. 행동·구성요소·아이템 접근 요구 조건 검사
9. 사용 가능 여부와 비활성 이유 생성
```

결제 선택지는 현재 자원이 부족해도 UI 설명을 위해 비활성 상태로 노출할 수 있다.

```text
3레벨 일반 슬롯 — 사용 가능 2개
5레벨 워락형 슬롯 — 모두 소모됨
무료 시전 — 긴 휴식 후 회복
지팡이 충전 — 지팡이를 장착하지 않음
```

---

## 15. 플레이어 선택과 기본 추천

서버는 플레이어가 어떤 자원을 아끼고 싶은지 추측해 강제로 소비하지 않는다.

원칙:

- 유효한 결제 방법이 하나뿐이면 추가 선택 없이 사용할 수 있다.
- 여러 방법이 있으면 현재 선택을 명확히 표시한다.
- 클라이언트는 낭비가 적은 결제 방법을 추천할 수 있다.
- 추천은 서버 규칙이 아니라 사용자 편의 기능이다.
- 최근 선택이나 사용자 선호는 로컬 설정으로 기억할 수 있다.
- 실제 요청에는 `routeId`와 `paymentOptionId` 또는 동등한 검증 가능한 선택이 포함된다.
- 서버는 클라이언트가 보낸 비용 수치나 `castLevel`을 그대로 신뢰하지 않고 다시 계산한다.

빠른 시전에서도 소비할 자원과 시전 레벨을 실행 전에 확인할 수 있어야 한다.

---

## 16. 예약, 확정과 롤백

주문 시전은 여러 자원과 소모품을 동시에 사용할 수 있으므로 원자적 트랜잭션으로 처리한다.

```text
CastCostPlan 생성
→ 모든 관련 상태 revision 확인
→ 행동 경제 예약
→ 주 자원 예약
→ 보조 자원과 소모품 예약
→ 검증 완료
→ commit point
→ 모든 예약 원자적 확정
→ payment receipt 생성
```

### 확정 전 취소

다음 상황에서는 예약을 되돌린다.

- 플레이어가 대상 선택 중 취소
- 대상, 거리 또는 시야 검증 실패
- 자원 상태가 다른 요청으로 변경됨
- 필요한 아이템 접근권 상실
- DM 승인 단계에서 거절
- 실행 처리기 초기화 실패

### 확정 후 실패

상쇄, 면역, 내성 성공이나 대상 부재로 주문 효과가 없더라도 자동으로 비용을 환불하지 않는다.

비용 환불 여부는 주문과 반응 규칙의 정확한 commit point 및 예외 정책이 결정한다.

### 동시성

각 예약은 다음을 포함한다.

```text
reservationId
executionId
poolInstanceId
expectedRevision
reservedAmount
expiresAtServerTick
status
```

같은 슬롯이나 충전이 중복 요청으로 두 번 소비되지 않게 한다.

`executionId`를 사용해 재전송된 동일 요청은 중복 결제가 아니라 같은 실행으로 처리한다.

---

## 17. 결제 영수증

확정된 시전은 구조화된 `PaymentReceipt`를 남긴다.

```text
PaymentReceipt
├─ executionId
├─ routeId
├─ spellId
├─ castLevel
├─ primaryPaymentReceipt
├─ supplementalPaymentReceipts
├─ consumedItemReferences
├─ committedAt
└─ resultingStateRevisions
```

용도:

- 전투 로그
- 오류 진단
- 재접속 복구
- 중복 요청 방지
- 규칙 트리거의 출처 확인
- DM 감사 기록
- 제한된 실행 취소와 보상 처리

결제 영수증이 캐릭터 성장 원본이나 장기 주문 목록을 대체하지 않는다.

---

## 18. 회복과 재충전

자원 회복은 타입 있는 규칙 이벤트에서 실행한다.

후보 이벤트:

```text
ShortRestCompleted
LongRestCompleted
DawnReachedInGameTime
TurnStarted
EncounterEnded
ItemRechargeResolved
FeatureRecoveryResolved
DMResourceAdjustment
```

현실 시간 경과만으로 자원을 회복하지 않는다.

`RecoveryPolicy`는 다음을 표현할 수 있다.

```text
RecoveryPolicy
├─ triggerEvent
├─ restoreMode
├─ amountFormula
├─ rankSelectionPolicy
├─ rechargeRoll
├─ prerequisites
└─ handlerId
```

회복 방식 예시:

- 전부 회복
- 정해진 수만큼 회복
- 선택한 슬롯 등급 조합을 회복
- 주사위로 아이템 충전 회복
- 일부만 회복하고 최대치 제한
- 전용 규칙 처리기로 회복

회복도 서버 트랜잭션과 로그를 사용한다.

---

## 19. 예시

### 19.1 일반 마법사 주문

```text
SpellCastRoute: wizard / Intelligence
Available payments:
├─ 1레벨 일반 슬롯
├─ 2레벨 일반 슬롯
└─ 3레벨 일반 슬롯
```

선택한 슬롯이 주문의 `castLevel`을 결정한다.

### 19.2 다중직업 주문 시전

```text
Wizard profile: Intelligence, wizard preparation
Cleric profile: Wisdom, cleric preparation
Shared slot pool: character-scoped ranked slots
```

같은 공유 슬롯을 사용하더라도 주문 DC와 준비 규칙은 선택한 프로필 경로를 따른다.

### 19.3 일반 슬롯과 워락형 슬롯

```text
Spell route: wizard spell / Intelligence
Payment options:
├─ shared 3rd-level slot
└─ fixed-rank pact slot at 5th level
```

규칙상 허용된다면 마법사 경로의 주문을 워락형 슬롯으로 시전해도 시전 능력치는 지능으로 유지되고, 효과의 `castLevel`만 5가 된다.

### 19.4 재주 무료 시전

```text
Spell route: feat source / Wisdom
Payment options:
├─ feat free cast, fixed at 1st level
└─ compatible normal spell slot, when grant allows
```

무료 사용을 소진해도 슬롯 시전 경로가 허용되어 있다면 주문 자체가 사라지지 않는다.

### 19.5 아이템 주문

```text
Spell route: wand item
Payment:
└─ item-instance-51 charge pool, 3 charges
```

완드를 다른 캐릭터에게 넘기면 남은 충전과 주문 경로도 아이템 접근 조건에 따라 이동한다.

### 19.6 의식 시전

```text
Spell route: wizard ritual from accessible spellbook
Payment:
├─ no spell slot
├─ additional casting time
└─ required components
```

주문책에 접근할 수 없으면 준비 여부와 별개로 이 의식 경로가 비활성화될 수 있다.

### 19.7 메타마법

```text
Primary payment: 3rd-level spell slot
Supplemental payment: 2 sorcery points
```

두 자원 중 하나라도 예약할 수 없으면 실행 전체를 확정하지 않는다.

---

## 20. 서버 검증

서버는 최소한 다음을 다시 검증한다.

- `routeId`가 현재 캐릭터의 Capability Set에 존재하는가
- 주문이 습득·준비·항상 준비 또는 의식 규칙을 충족하는가
- 선택한 자원 풀이 존재하고 활성 상태인가
- 캐릭터가 해당 풀을 소유하거나 접근할 수 있는가
- 프로필이 해당 풀 종류를 사용할 수 있는가
- 남은 슬롯, 사용 횟수, 포인트 또는 충전이 충분한가
- 선택한 슬롯 등급과 `castLevel`이 유효한가
- 아이템 장착·조율·접근 조건을 충족하는가
- 구성요소와 소모품이 존재하는가
- 행동 경제와 시전 시간 조건을 충족하는가
- 상태 revision이 요청 생성 이후 바뀌지 않았는가
- 동일 `executionId`가 이미 확정되지 않았는가

클라이언트가 제출한 최종 잔여 자원, 비용량, 시전 레벨과 주문 효과 수치를 신뢰하지 않는다.

---

## 21. 캐시와 성능

매 프레임 모든 주문과 자원 풀의 조합을 다시 만들지 않는다.

결제 선택지 캐시는 다음 revision에 의존할 수 있다.

```text
SpellPaymentCacheKey
├─ capabilityRevision
├─ spellPreparationRevision
├─ characterResourceRevision
├─ equipmentRevision
├─ itemChargeRevision
├─ effectRevision
└─ combatStateRevision
```

다음 변화가 있을 때 영향받는 주문만 갱신한다.

- 슬롯 또는 무료 시전 소비·회복
- 아이템 장착, 양도, 조율 또는 충전 변경
- 주문 준비 변경
- SpellcastingProfile 활성화 또는 제거
- 일시 자원 풀 생성 또는 만료
- 행동 경제 상태 변경

비활성 주문 카드의 세부 결제 선택지는 열 때 지연 계산할 수 있지만, 실제 시전 요청은 항상 서버에서 새 상태로 검증한다.

---

## 22. 오류 격리와 진단

결제 오류 로그 후보:

```text
executionId
characterId or actorId
spellId
routeId
paymentOptionId
poolInstanceIds
expected and actual revisions
castLevel
failureStage
rollbackResult
rulesetId
sourceChain
```

일부 자원 예약 뒤 다른 비용 예약이 실패하면 이미 예약된 항목을 모두 해제한다.

정의가 누락되거나 마이그레이션이 필요한 자원 풀은 임의의 기본 슬롯으로 변환하지 않고 읽기 전용 오류 상태로 표시한다.

---

## 23. 명시적인 비목표

- 모든 주문 자원을 하나의 `mana` 값으로 합치지 않는다.
- 워락형 슬롯을 일반 슬롯 배열에 억지로 넣지 않는다.
- 무료 시전을 가짜 주문 슬롯으로 만들지 않는다.
- 아이템 충전을 캐릭터의 영구 자원으로 복사하지 않는다.
- 의식 시전을 0레벨 슬롯 소비로 처리하지 않는다.
- 결제 방법을 숨겨진 우선순위로 자동 소비하지 않는다.
- 주문 카드가 현재 자원 상태의 권위 원본이 되게 하지 않는다.
- 클라이언트가 제출한 비용과 잔여 자원을 신뢰하지 않는다.
- 전용 주문 처리기가 자원 상태를 직접 수정하게 하지 않는다.

---

## 24. 후속 결정

다음 단계에서는 **주문 구성요소와 인벤토리 비용 계약**을 구체화한다.

특히 다음을 정해야 한다.

1. 음성, 동작과 물질 구성요소의 사용 가능 조건
2. 주문시전 도구와 구성요소 주머니가 무엇을 대체하는가
3. 금전 가치가 있는 재료와 실제 소모 재료의 인벤토리 표현
4. 손 점유, 침묵, 구속과 장비 상태가 주문 시전에 미치는 영향
5. 재료 예약, 소비와 시전 취소 시 롤백
6. DM이 수량을 엄격히 추적하지 않는 캠페인을 위한 편의 정책