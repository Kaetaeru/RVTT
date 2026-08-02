# 15. 주문 구성요소와 재료 인벤토리 계약

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`11. 공통 실행 계약과 마법 처리 모델`](11-rules-content-execution-and-spell-contract.md)
  - [`12. 주문 획득·준비·시전 권한 모델`](12-spell-acquisition-preparation-and-cast-access-model.md)
  - [`14. 주문 자원 풀과 시전 결제 모델`](14-spell-resource-pools-and-cast-payment-model.md)
  - [`ADR-0020`](decisions/ADR-0020-typed-spell-resource-pools-and-explicit-cast-payments.md)
  - [`ADR-0021`](decisions/ADR-0021-typed-spell-components-and-inventory-backed-materials.md)

## 1. 문서 목적

주문 정의에 적힌 음성, 동작과 물질 구성요소는 실제 시전 가능 여부와 비용에 영향을 준다.

RVTT는 다음 상황을 처리해야 한다.

- 침묵이나 변신 상태 때문에 음성 구성요소를 사용할 수 없다.
- 양손에 장비를 들고 있어 동작이나 주문시전 도구를 사용할 손이 없다.
- 구성요소 주머니가 일반적인 작은 재료를 대신한다.
- 성표가 방패에 부착되어 있거나 무기 자체가 주문시전 도구다.
- 가격이 있는 진주, 다이아몬드와 특수 용기를 실제로 소유해야 한다.
- 주문이 재료를 소비하거나 소비하지 않는다.
- 아이템 시전은 원래 주문의 일부 구성요소를 요구하지 않는다.
- 특성이나 메타마법이 음성 또는 동작 구성요소를 제거한다.
- DM이 서사 상황에 따라 대체 재료를 승인한다.

이 문서는 구성요소를 설명 문자열이 아니라 타입 있는 요구 조건과 충족 계획으로 다룬다.

```text
SpellComponentRequirements
+ SpellCastRoute component policy
+ active ComponentOverrideCapability
+ actor speech, manipulation and inventory state
→ ComponentSatisfactionPlan
→ CastCostPlan
```

---

## 2. 전체 구조

```text
SpellDefinition
└─ SpellComponentRequirements
   ├─ verbal
   ├─ somatic
   └─ materials[]

SpellcastingProfile / Item route
└─ ComponentPolicy

Character Capability Set
├─ SpeechCapability
├─ ManipulationCapability
├─ ComponentSupplyCapability
└─ ComponentOverrideCapability

Inventory and equipment
├─ spellcasting focuses
├─ component pouches
├─ material stacks
└─ unique material items
```

실행 시:

```text
원본 구성요소 요구 조회
→ 경로와 특성의 변경 적용
→ 음성·동작 가능 여부 검사
→ 도구·주머니·실제 재료 후보 검색
→ 손 사용과 아이템 접근 계획 생성
→ 소비 재료 예약
→ CastCostPlan에 포함
```

---

## 3. SpellComponentRequirements

개념 데이터 구조:

```text
SpellComponentRequirements
├─ verbal: VerbalRequirement?
├─ somatic: SomaticRequirement?
└─ materials: MaterialRequirement[]
```

### VerbalRequirement

```text
VerbalRequirement
├─ required
├─ speechMode
├─ audibilityPolicy
└─ specialRestrictions
```

정확한 주문 문구를 플레이어가 음성으로 말하는지를 감지하지 않는다.

규칙 엔진은 시전자가 규칙상 음성 구성요소를 낼 수 있는지만 판정한다.

### SomaticRequirement

```text
SomaticRequirement
├─ required
├─ manipulationMode
├─ requiredSlots
└─ sharedWithMaterialPolicy
```

기본 인간형 캐릭터는 손을 조작 슬롯으로 사용하지만, 시스템 데이터는 무조건 왼손과 오른손 두 개로 하드코딩하지 않는다.

변신, 추가 팔, 의수와 몬스터 형태를 지원할 수 있도록 `ManipulationSlot` 집합을 사용한다.

### MaterialRequirement

```text
MaterialRequirement
├─ requirementId
├─ itemDefinitionId?
├─ materialTags[]
├─ quantity
├─ minimumValue?
├─ valueCurrency?
├─ consumed
├─ mustUseSingleItem
├─ conditionPredicate?
├─ substitutionPolicy
└─ displayDescriptionKey
```

실행은 번역된 `displayDescription`을 파싱하지 않는다.

---

## 4. 음성 구성요소

음성 가능 여부는 `SpeechCapability`에서 계산한다.

```text
SpeechCapability
├─ canSpeak
├─ canProduceSpellVerbalComponent
├─ restrictions[]
└─ sourceReasons[]
```

영향을 줄 수 있는 출처:

- 침묵 영역과 마법 효과
- 의식 불명과 행동 불능
- 현재 형태의 발화 능력
- 입을 막는 물리적 상태
- 특성 또는 규칙상 음성 생략
- 환경과 장면의 특수 규칙

규칙 이벤트나 상태 효과가 `conditionName == "Silenced"` 같은 문자열 비교로 시전을 차단하지 않는다.

타입 있는 제한 Capability를 제공한다.

```text
ActionRestrictionCapability
└─ prevents: spell_component.verbal
```

음성 요구가 제거되면 원본 주문을 변경하지 않고 이번 `ComponentSatisfactionPlan`에서 요구를 제거한다.

---

## 5. 동작 구성요소와 조작 슬롯

캐릭터는 현재 형태와 장비에서 사용할 수 있는 `ManipulationSlot`을 가진다.

```text
ManipulationSlot
├─ slotId
├─ anatomyRole
├─ occupiedByItemInstanceId?
├─ canPerformSomatic
├─ canHoldFocus
├─ canAccessPouch
└─ restrictions[]
```

기본 검사 흐름:

```text
현재 형태의 조작 슬롯 조회
→ 장비 점유 상태 적용
→ 상태 효과와 제한 적용
→ 물질·도구와 공유 가능한 슬롯 계산
→ SomaticRequirement 충족 여부 판정
```

규칙 세트가 물질 구성요소나 주문시전 도구를 든 손으로 같은 주문의 동작도 수행할 수 있게 한다면 하나의 슬롯을 공유 배정한다.

```text
right hand
├─ holds spellcasting focus
├─ satisfies material requirement
└─ performs somatic component
```

동작만 필요하고 물질이 필요하지 않은 주문의 손 규칙은 별도의 규칙 정책을 따른다.

### 장비 자동 변경 금지

시전을 가능하게 만들기 위해 시스템이 다음을 조용히 수행하지 않는다.

- 무기를 자동으로 떨어뜨림
- 방패를 자동으로 해제
- 아이템을 자동으로 집어넣음
- 주문시전 도구를 자동으로 꺼냄

필요하다면 다음 중 하나로 처리한다.

- 플레이어에게 사용할 손과 도구 선택 요청
- 별도의 장비 조작 행동 생성
- 규칙상 무료로 가능한 장비 상태 전환 제안
- 현재 상태에서는 시전 불가 이유 표시

정확한 장비 조작 행동 경제는 인벤토리·장비 명세에서 확정한다.

---

## 6. 물질 구성요소 분류

### 6.1 일반 비소모 재료

조건:

```text
minimumValue 없음
consumed = false
```

규칙상 허용되는 `ComponentSupplyCapability`로 대체할 수 있다.

개별 박쥐 구아노, 모래 한 줌과 작은 털 조각을 모두 인벤토리 항목으로 만들지 않는다.

### 6.2 가격 있는 비소모 재료

조건:

```text
minimumValue 존재
consumed = false
```

실제 아이템이나 재료 묶음이 요구 가치를 충족해야 한다.

시전 후에도 아이템은 남는다.

### 6.3 소비되는 재료

조건:

```text
consumed = true
```

가격이 없어도 실제 수량을 추적한다.

시전 비용 확정 시 예약된 수량을 차감하거나 아이템 인스턴스를 소비 상태로 전환한다.

### 6.4 가격 있고 소비되는 재료

실제 소유, 최소 가치와 소비를 모두 검사한다.

강력한 부활이나 장기 의식 재료와 같은 중요한 비용을 금화 수치만 차감하여 우회하지 않는다.

### 6.5 고유 물체와 상태 조건

일부 주문은 특정 형태, 제작 상태, 내용물 또는 관계를 가진 물체를 요구할 수 있다.

```text
MaterialRequirement
├─ itemTags: ["container", "silvered"]
├─ condition: contains_holy_water
└─ consumed: false
```

공통 태그와 조건으로 표현하기 어려운 경우 제한된 `materialRequirementHandlerId`를 사용한다.

---

## 7. 주문시전 도구와 구성요소 주머니

도구와 주머니는 일반 아이템이면서 `ComponentSupplyCapability`를 제공한다.

```text
ComponentSupplyCapability
├─ supplyKind
├─ itemInstanceId
├─ applicableProfilePredicate
├─ satisfiesUnpricedNonConsumedMaterials
├─ materialTagCoverage
├─ accessMode
├─ requiredManipulationSlots
├─ attunementRequirement
└─ specialOverrides
```

`supplyKind` 후보:

- `component_pouch`
- `arcane_focus`
- `divine_focus`
- `druidic_focus`
- `instrument_focus`
- `weapon_focus`
- `integrated_focus`
- 확장 출처 팩의 기타 도구

### 프로필 연결

마법사의 비전 도구를 모든 주문 경로에서 자동 사용할 수 있게 하지 않는다.

```text
focus capability
+ selected SpellcastingProfile
+ spell route component policy
→ valid or invalid supply
```

다중직업 캐릭터는 프로필마다 사용할 수 있는 도구가 다를 수 있다.

### 접근 방식

`accessMode` 후보:

- 손에 들고 있어야 함
- 착용하고 있어야 함
- 방패나 방어구에 부착
- 무기와 통합
- 인벤토리에서 접근 가능
- 특정 자세나 상태 필요

성표가 방패에 부착된 경우처럼 아이템 자체의 장착 상태가 손 배정과 재료 충족에 함께 참여한다.

---

## 8. 인벤토리 재료 표현 계약

이 문서는 전체 인벤토리 스키마를 결정하지 않지만 주문 엔진이 요구하는 인터페이스를 정의한다.

```text
ComponentInventoryResolver
├─ findCandidates(actor, materialRequirement)
├─ evaluateValue(candidate, currencyContext)
├─ verifyAccess(candidate)
├─ reserve(candidate, quantity, executionId)
├─ commitReservation(reservationId)
└─ releaseReservation(reservationId)
```

재료 후보는 다음 중 하나일 수 있다.

- 수량을 가진 일반 아이템 스택
- 고유 `ItemInstance`
- 보석과 귀금속 재료 묶음
- 내용물이나 상태를 가진 용기
- 다른 시스템이 제공하는 규칙 자산

주문 엔진은 인벤토리 저장 구조를 직접 수정하지 않는다.

---

## 9. 가치 조건

`minimumValue`는 실제 재료 적격 조건이다.

```text
required minimum value
≤ candidate appraised rules value
```

원칙:

- 표시용 상점 가격 문자열을 파싱하지 않는다.
- 기준 통화와 가치 단위를 규칙 세트가 제공한다.
- 여러 통화를 쓰는 캠페인은 명시적 가치 변환기를 사용한다.
- 단순히 캐릭터의 금화를 차감하여 재료가 생긴 것으로 처리하지 않는다.
- 실제 구매는 상점 또는 DM 거래 작업으로 먼저 처리한다.
- 가치 평가가 불명확한 홈브루 아이템은 DM 판정을 요청한다.

`mustUseSingleItem = true`인 요구는 여러 작은 재료의 가치를 합산하여 만족할 수 없다.

---

## 10. 재료 후보 선택

같은 요구를 여러 아이템이 만족할 수 있다.

예시:

```text
최소 가치 100gp 진주 1개 필요
├─ 진주 A: 100gp
├─ 진주 B: 250gp
└─ 장식된 진주 C: 500gp
```

시스템은 낭비가 적은 후보를 추천할 수 있지만, 실제 소비 또는 사용 대상을 명확히 보여준다.

원칙:

- 유효한 후보가 하나면 자동 선택 가능
- 여러 소비 후보가 있으면 추천 결과와 선택 변경 제공
- 고유하거나 서사적으로 중요한 아이템은 자동 소비 금지 플래그 지원 가능
- 사용자 선택은 `ComponentSatisfactionPlan`에 구체적인 아이템 ID로 기록
- 서버가 선택 시점과 확정 시점에 소유, 수량과 상태를 다시 검증

---

## 11. ComponentSatisfactionPlan

한 번의 시전에서 구성요소를 어떻게 만족하는지 구조화한다.

```text
ComponentSatisfactionPlan
├─ executionId
├─ effectiveRequirements
├─ verbalSatisfaction
├─ somaticSlotAssignments[]
├─ materialSatisfiers[]
├─ focusOrPouchReference?
├─ inventoryReservations[]
├─ appliedOverrides[]
├─ dmOverride?
└─ validationRevisionSet
```

### MaterialSatisfier

```text
MaterialSatisfier
├─ requirementId
├─ satisfactionKind
├─ itemInstanceId or stackId?
├─ supplyCapabilityId?
├─ reservedQuantity
├─ consumed
└─ valueSnapshot?
```

`satisfactionKind` 후보:

- focus
- component pouch
- actual item
- material stack
- route waiver
- feature override
- DM override

이 계획은 현재 시전 트랜잭션의 일부이며 영구 주문 데이터가 아니다.

---

## 12. 구성요소 변경 Capability

특성, 메타마법, 아이템과 주문 경로가 원본 구성요소 요구를 변경할 수 있다.

```text
ComponentOverrideCapability
├─ appliesToPredicate
├─ removeVerbal
├─ removeSomatic
├─ removeMaterialKinds[]
├─ provideMaterialSupply
├─ changeAccessMode
├─ waiveConsumedMaterial
├─ priority
└─ handlerId?
```

기본적으로 다음은 매우 강한 예외이므로 명시적 규칙이 없으면 허용하지 않는다.

- 가격 있는 재료 면제
- 소비 재료 면제
- 고유 물체 대체
- 손 사용 조건 완전 제거

여러 Override가 적용될 때는 우선순위와 배타 관계를 결정적으로 해결한다.

원본 `SpellDefinition`을 런타임에서 수정하지 않는다.

---

## 13. 아이템을 통한 주문 시전

아이템 주문 경로는 원본 주문과 다른 구성요소 정책을 가질 수 있다.

```text
ItemSpellComponentPolicy
├─ inheritAll
├─ waiveAll
├─ waiveTypes[]
├─ replaceWithItemUse
└─ additionalRequirements[]
```

예시:

```text
완드 사용
→ 음성·동작·물질 요구를 아이템 사용으로 대체
→ 완드를 손에 들고 접근 가능해야 함
→ 아이템 충전 소비
```

아이템 시전이 구성요소를 요구하지 않는다는 이유로 아이템 접근, 손 점유와 충전 비용까지 사라지게 하지 않는다.

---

## 14. 변신과 특수 형태

현재 형태가 바뀌면 다음 Capability가 달라질 수 있다.

- 발화 가능 여부
- 조작 슬롯 수와 기능
- 장착 아이템 접근
- 주문시전 도구 사용
- 구성요소 주머니 접근
- 특성상 구성요소 생략

형태 정의가 캐릭터의 주문 데이터를 복사하거나 삭제하지 않는다.

```text
Character SpellCastRoute
+ current form capabilities
→ current component availability
```

형태가 끝나면 원래 Capability 집합으로 돌아간다.

---

## 15. DM 구성요소 예외

창의적인 대체 재료나 서사적 면제가 필요할 수 있다.

```text
DMComponentOverride
├─ executionId
├─ waivedRequirementIds[]
├─ replacementItemReferences[]
├─ reason
├─ approvedByUserId
├─ scope
└─ createdAt
```

`scope` 기본값은 해당 실행 한 번이다.

영구적인 홈브루 규칙이라면 매 시전 DM 승인을 반복하지 않고 콘텐츠 팩이나 명시적 Capability로 만들어야 한다.

클라이언트가 DM 승인 없이 `ignoreComponents = true`를 전송할 수 없게 한다.

---

## 16. 예약과 소비

소비되는 재료는 주문 슬롯과 같은 실행 트랜잭션 안에서 처리한다.

```text
재료 후보 확정
→ inventory revision 확인
→ 수량 또는 item instance 예약
→ 다른 비용 예약
→ commit point
→ 자원과 재료 원자적 소비
```

예약 중인 재료는 다른 거래, 시전이나 아이템 이동에서 사용할 수 없다.

확정 전 취소 시 예약을 해제한다.

확정 후 주문 효과가 없었다는 이유만으로 재료를 자동 복구하지 않는다. 해당 주문이나 반응 규칙이 환불을 명시한 경우에만 보상 트랜잭션을 사용한다.

비소모 재료도 확정 순간까지 접근 가능 상태를 유지해야 하지만 수량을 차감하지 않는다.

---

## 17. UI 표현

주문 카드에 기본 구성요소 아이콘을 표시한다.

```text
[V] [S] [M]
```

세부 정보에는 다음을 보여준다.

- 음성, 동작과 물질 요구
- 가격과 소비 여부
- 현재 사용 중인 주문시전 도구 또는 주머니
- 예약될 실제 재료
- 사용할 손 또는 장비 요구
- 구성요소를 제거한 특성과 출처
- 시전 불가 이유

비활성 예시:

```text
시전 불가
- 침묵 영역으로 음성 구성요소를 사용할 수 없음
- 사용 가능한 손이 없음
- 300gp 가치의 다이아몬드가 없음
```

소비되는 중요 재료는 최종 시전 확인에서 명시적으로 보여준다.

```text
이 시전은 다이아몬드 1개를 소비합니다.
선택 재료: item-diamond-42, 가치 500gp
```

---

## 18. 서버 검증

서버는 최소한 다음을 검증한다.

- 적용된 구성요소 요구가 현재 주문, 경로와 Override에서 정확히 파생되었는가
- 시전자가 음성 구성요소를 낼 수 있는가
- 동작에 사용할 조작 슬롯이 실제로 존재하고 사용 가능한가
- 같은 슬롯의 공유 사용이 규칙상 허용되는가
- 선택한 도구 또는 주머니가 해당 프로필에서 유효한가
- 가격 또는 소비 재료를 대체하려는 잘못된 도구 사용이 없는가
- 재료 아이템이 현재 소유·접근 가능한가
- 수량, 가치, 태그와 상태 조건을 충족하는가
- 소비 재료가 다른 실행에 이미 예약되지 않았는가
- 아이템과 인벤토리 revision이 일치하는가
- DM Override가 실제 승인 기록과 일치하는가

클라이언트가 제출한 `componentsSatisfied = true` 값을 신뢰하지 않는다.

---

## 19. 캐시와 성능

모든 인벤토리를 매 프레임 모든 주문 요구와 대조하지 않는다.

캐시와 인덱스 후보:

```text
ComponentSupplyIndex
├─ active focus capabilities by profile
├─ accessible component pouches
├─ inventory items by material tags
├─ valued material candidates
└─ consumed material stacks
```

다음 변화에서 영향 범위만 갱신한다.

- 장비 장착과 해제
- 아이템 이동과 수량 변경
- 현재 형태 변경
- 침묵과 행동 제한 효과 시작·종료
- 주문시전 도구 접근 또는 조율 변경
- SpellcastingProfile 변경

실제 시전 확정 전에는 항상 서버가 최신 인벤토리와 상태를 다시 검사한다.

---

## 20. 진단과 로그

구성요소 오류 로그 후보:

```text
executionId
characterId or actorId
spellId
routeId
requirementId
candidate item references
component override sources
manipulation slot assignments
inventory revisions
reservationIds
failureReason
rollbackResult
```

구성요소 정의가 손상되거나 번역과 구조 데이터가 불일치하면 설명 문자열로 임의 실행하지 않고 해당 주문 경로를 읽기 전용 오류 상태로 표시한다.

---

## 21. 예시

### 21.1 일반 재료와 비전 도구

```text
주문 요구: V, S, M
재료: 가격 없음, 비소모

충족:
- 발화 가능
- 오른손의 비전 도구
- 오른손이 물질과 동작을 함께 수행
```

개별 일반 재료는 인벤토리에서 차감하지 않는다.

### 21.2 가격 있는 비소모 재료

```text
주문 요구: 최소 100gp 진주, 비소모

인벤토리:
- 100gp 진주
- 250gp 진주

추천:
- 100gp 진주 사용
```

시전 후 진주는 남는다.

### 21.3 가격 있고 소비되는 재료

```text
주문 요구: 300gp 다이아몬드, 소비

결제 계획:
- 주문 슬롯 예약
- item-diamond-42 예약
- commit 시 슬롯과 다이아몬드 함께 소비
```

### 21.4 침묵 상태와 구성요소 제거 특성

```text
원본 주문: V, S
현재 상태: verbal component blocked
활성 특성: 이번 시전의 V 제거

결과:
- 유효 요구: S
- 사용 가능한 손이 있으면 시전 가능
```

### 21.5 아이템 시전

```text
원본 주문: V, S, M
완드 경로: 원본 구성요소를 완드 사용으로 대체

요구:
- 완드 접근 가능
- 완드를 사용할 손
- 충분한 충전
```

---

## 22. 명시적인 비목표

- 주문 설명의 `V, S, M` 문자열을 파싱하여 실행하지 않는다.
- 가격 없는 모든 일반 재료를 개별 인벤토리 아이템으로 만들지 않는다.
- 가격 있는 재료를 금화 자동 차감으로 대체하지 않는다.
- 구성요소 주머니가 고가 또는 소비 재료를 자동 제공하게 하지 않는다.
- 시전을 위해 장비를 조용히 버리거나 집어넣지 않는다.
- 아이템 시전이 원본 주문과 항상 같은 구성요소를 가진다고 가정하지 않는다.
- 특성이 원본 `SpellDefinition`을 직접 수정하게 하지 않는다.
- DM 예외를 검증되지 않은 클라이언트 플래그로 처리하지 않는다.

---

## 23. 다음 단계

이제 주문 데이터의 획득, 시전 경로, 자원 결제와 구성요소 계약이 연결되었다.

다음으로는 **주문의 대상 지정과 영역 템플릿 공통 규약**을 정하는 것이 적절하다.

다음 항목을 다룬다.

1. 자신, 단일 대상, 복수 대상, 지점, 물체와 영역 선택
2. 거리, 시야, 효과선과 엄폐 검증
3. 구체, 원뿔, 선, 원통, 벽과 사용자 지정 영역
4. 아군·적·생물 종류·의지 있는 대상 조건
5. 상위 레벨 시전으로 증가하는 대상 수
6. 대상 선택 뒤 이동하거나 사라진 경우의 재검증
7. 환영, 소환과 벽처럼 장면 오브젝트를 만드는 주문