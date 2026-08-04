# Spell Casting Route와 2024 Spell Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 주문 후보 목록의 기본 정렬·검색 Cache 상한
  - 장시간 시전의 탐험 시간 갱신 주기
  - 대규모 AoE Preview 후보 수와 경고 기준
  - 동일 주문의 다중 Cast Route 선택 UI 기본값
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0018`](../decisions/ADR-0018-source-scoped-spellcasting-profiles.md)
  - [`ADR-0020`](../decisions/ADR-0020-typed-spell-resource-pools-and-explicit-cast-payments.md)
  - [`ADR-0021`](../decisions/ADR-0021-typed-spell-components-and-inventory-backed-materials.md)
  - [`ADR-0028`](../decisions/ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0029`](../decisions/ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0065`](../decisions/ADR-0065-compiled-effect-builds-and-authoritative-effect-instances.md)
  - [`ADR-0068`](../decisions/ADR-0068-2024-spell-casts-as-route-bound-pending-rule-executions.md)
- 상위 문서:
  - [`Character Runtime 계약`](character-runtime-and-compiled-character-build-contract.md)
  - [`Character Action Runtime 계약`](character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - [`Rule Runtime Orchestrator 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Effect Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)
  - [`Inventory와 Item Runtime 계약`](inventory-item-instance-and-world-presence-runtime-contract.md)
- 관련 시스템:
  - [`주문 획득·준비·시전 권한 모델`](../systems/character/spell-acquisition-preparation-and-cast-access-model.md)
  - [`주문 자원 풀과 시전 결제 모델`](../systems/rules/spell-resource-pools-and-cast-payment-model.md)
  - [`주문 구성요소와 재료 인벤토리 계약`](../systems/rules/spell-components-and-material-inventory-contract.md)
  - [`주문 대상 지정·영역·공간 질의 모델`](../systems/rules/spell-targeting-area-and-spatial-query-model.md)

## 1. 목적

이 문서는 D&D 2024 규칙의 주문 시전을 Character Capability, Action Economy, Resource, Component, Targeting, RuleExecution, Effect와 Transaction에 연결하는 상위 Runtime 계약을 정의한다.

주문은 하나의 전역 Spell 버튼이나 주문 이름별 Server 분기로 실행하지 않는다.

```text
Spell Definition
+ Character SpellCastRoute
+ 현재 Character·Item·Effect State
→ Cast Option
→ SpellCastExecution
→ PendingEffect·Roll·Save·Reaction
→ Atomic Commit
→ EffectInstance·Damage·Healing·Runtime Object
```

## 2. 사용자 결과

- 같은 주문을 직업 슬롯, 무료 시전, 아이템 충전 등 허용된 경로로 선택할 수 있다.
- 업캐스팅, 의식 시전, 반응 주문과 준비 주문이 2024 규칙에 맞게 동작한다.
- 음성·동작·물질 구성요소와 손 점유가 실제 장비·상태를 반영한다.
- 주문 슬롯과 소비 재료는 실패 시점과 규칙에 맞게 예약·소비·해제된다.
- 대상·범위·영역 Preview는 Client가 보여주지만 서버가 최종 확정한다.
- 집중, 지속 영역, 소환체와 변신은 Effect Runtime과 Runtime Object 계약을 따른다.
- 재접속·서버 복구·턴 롤백 후에도 진행 중인 시전과 예약이 복원된다.

## 3. Definition, Build, Route와 Execution

### 3.1 SpellDefinitionSource

콘텐츠 원본은 다음을 정의한다.

```text
spellId
spellLevel
school
castingTime
range
targetingProfile
components
duration
concentration
ritualTag
effectRecipeRef
higherLevelPlan
presentationProfile
```

현재 준비 상태, 슬롯, 시전자 능력치와 ItemInstance는 포함하지 않는다.

### 3.2 CompiledSpellBuild

Compiler는 정규화된 불변 Build를 생성한다.

```text
CompiledSpellBuild
├─ compiledSpellBuildId
├─ sourceRef와 buildHash
├─ castingTimePlan
├─ rangeAndTargetPlan
├─ componentRequirementPlan
├─ durationAndConcentrationPlan
├─ effectRecipeRef
├─ higherLevelScalingPlan
├─ reactionTriggerPlan?
├─ ritualEligibility
└─ dependencyRefs[]
```

### 3.3 SpellCastRoute

같은 주문이라도 캐릭터가 접근하는 출처와 규칙이 다를 수 있다.

```text
SpellCastRoute
├─ routeId
├─ characterId
├─ spellBuildRef
├─ sourceSpellcastingProfileId?
├─ sourceFeatureId?
├─ sourceItemInstanceId?
├─ castingAbilityPlan
├─ accessState
├─ preparationState
├─ paymentEligibility
├─ componentPolicy
├─ ritualPolicy
├─ castLevelPolicy
├─ capabilityRestrictions[]
└─ routeRevision
```

Route는 실제 Resource State를 복사하지 않는다.

### 3.4 SpellCastExecution

주문 한 번의 권위 실행은 RuleExecution의 전문화된 Context다.

```text
SpellCastExecutionContext
├─ executionId
├─ casterActorId
├─ characterId?
├─ routeId
├─ spellBuildRef
├─ selectedCastLevel
├─ castingTimeMode
├─ actionOpportunityRef?
├─ paymentPlan
├─ componentSatisfactionPlan
├─ targetAndAreaBindings
├─ ruleSnapshot
├─ reservationRefs[]
└─ authorityEpoch
```

별도 독립 상태기계를 만들지 않고 Rule Runtime Orchestrator의 상태기계를 따른다.

## 4. 시전 가능성 해석

```text
Character Capability View
+ SpellCastRoute
+ Action·Bonus Action·Reaction Opportunity
+ Character·Actor·Encounter State
+ Equipment·Inventory·Effect State
→ SpellCastOption[]
```

검증 항목:

- 주문 접근·준비·습득 상태
- 현재 Route의 시전 능력치와 규칙 출처
- 시전 시간에 맞는 행동 기회
- 2024 턴당 주문 슬롯 사용 제한
- 필요한 Resource와 무료 시전권
- 음성·동작·물질 구성요소
- Armor Training, 상태와 Magic Action 제한
- 대상·사거리·효과선과 Scene Context
- 장시간 시전과 집중 가능 여부

UI의 활성 버튼은 권위가 아니다. 서버가 선언 시 최신 Snapshot에서 재검증한다.

## 5. Casting Time

지원 종류:

```text
action
bonus_action
reaction
minutes_or_hours
ritual_variant
special_registered
```

### Action과 Bonus Action

해당 Opportunity를 예약한 뒤 실행한다.

### Reaction

주문 정의가 선언한 Trigger와 TimingWindow에서만 Offer를 생성한다. 플레이어가 아무 때나 반응 주문 버튼을 누를 수 없다.

### 장시간 시전

1분 이상의 시전은 저장 가능한 `LongCastExecution`으로 유지한다.

```text
시전 시작
→ 각 턴 Magic Action 유지
→ Concentration Channel 점유
→ 진행도 갱신
→ 완료 시 자원·재료 확정과 효과 해결
```

집중이 끊기면 시전은 실패하고 다시 시작해야 한다. 2024 기본 규칙에서 장시간 시전이 완료되기 전에 실패하면 슬롯을 소비하지 않는 경로를 지원한다.

## 6. 턴당 주문 슬롯 사용 제한

2024 기본 규칙의 턴 제한을 타입 있는 Usage Gate로 둔다.

```text
SpellSlotCastPerTurnGate
├─ turnId
├─ consumedByExecutionId?
└─ overrideContributions[]
```

한 턴에 주문 슬롯을 소비하여 시전할 수 있는 주문은 기본적으로 하나다. Cantrip, Ritual, 무료 시전과 Item Cast는 각 Route의 Payment와 규칙 정의에 따라 Gate 적용 여부를 판단한다.

문자열 주문 이름이나 Action/Bonus Action 조합으로 하드코딩하지 않는다.

## 7. Cast Level과 업캐스팅

```text
기본 주문 레벨
+ 선택한 Payment Option의 슬롯 등급
+ Route 제한
→ selectedCastLevel
→ HigherLevelScalingPlan
```

- 슬롯은 주문 레벨 이상이어야 한다.
- 높은 슬롯으로 시전하면 이번 주문의 시전 레벨이 높아진다.
- 실제 강화 효과는 주문의 HigherLevelScalingPlan이 선언한다.
- Ritual은 슬롯을 소비하지 않으며 기본적으로 업캐스팅할 수 없다.
- 고정 등급 슬롯과 무료 시전권은 각 Payment Option이 시전 레벨을 결정한다.

## 8. Ritual Casting

Ritual Route가 허용되고 주문이 준비되어 있으며 Ritual 태그가 있을 때 후보를 만든다.

```text
normal cast
또는
ritual cast
```

Ritual:

- 일반 시전 시간보다 10분 길다.
- 주문 슬롯을 소비하지 않는다.
- 업캐스팅하지 않는다.
- 장시간 시전과 동일하게 Magic Action 반복과 Concentration 유지 계약을 사용한다.
- 중단되면 진행도는 사라지고 다시 시작한다.

Class·Feature가 별도 Ritual 접근 규칙을 제공하면 Route Policy로 확장한다.

## 9. Components와 손 점유

```text
Compiled Component Requirement
+ Route Component Policy
+ Effect·Feature Override
+ Speech·Manipulation Capability
+ Inventory·Equipment
→ ComponentSatisfactionPlan
```

### Verbal

정상 목소리를 낼 수 없거나 Silence 등으로 제한되면 실패한다. 실제 마이크 입력이나 발음은 검사하지 않는다.

### Somatic

현재 형태에서 동작 가능한 Manipulation Slot이 최소 하나 필요하다.

### Material

- 비소모·무가격 재료는 허용된 Focus 또는 Component Pouch로 대체 가능
- 가격 있는 재료는 실제 적격 ItemInstance 필요
- 소비 재료는 예약 후 규칙상 확정 시 소비
- Focus·Pouch 접근과 손 점유를 검사

시전을 가능하게 하려고 무기나 방패를 조용히 자동 해제하지 않는다.

## 10. Resource, Payment와 Commit 시점

```text
SpellCastRoute
→ CastPaymentOption[]
→ CastCostPlan
→ Resource·Material Reservation
→ Spell Resolution
→ Commit 또는 Release
```

지원 경로:

- Cantrip
- Ranked Spell Slot
- Fixed Rank Slot
- Limited Free Cast
- Feature Point Payment
- Item Charge
- Temporary Effect Cast
- Ritual

자원 소비 시점은 Route·Casting Time·Spell 계약이 선언한다. 공통 원칙:

- 선언 직후 실제 소비하지 않고 먼저 예약
- 다른 시전이 같은 자원을 중복 사용하지 못함
- Commit 조건을 충족하면 원자적으로 소비
- 선언 취소·검증 실패 시 예약 해제
- 이미 규칙상 시전이 확정된 뒤 대상이 무효가 되거나 효과가 실패한 경우 자동 환불하지 않음
- DM Override도 Reservation·Journal·Atomic Commit을 우회하지 않음

## 11. Targeting, Range와 Area

```text
Targeting Plan
→ Client Preview Request
→ Spatial Query Snapshot
→ Candidate·Range·LoS·LoE Preview
→ Player Confirm
→ Server Revalidation
→ Frozen Target Bindings
```

지원 형태:

- Self
- Touch
- 거리 대상
- Point·Object·Actor Target
- Sphere·Cone·Cube·Cylinder·Line
- Emanation
- 다중 대상과 순차 대상
- 이동 가능한 지속 영역

Client Preview는 설명용이며 최종 Affected Set은 서버가 Commit 직전에 다시 계산하거나 규칙이 요구한 시점에 고정한다.

## 12. Attack Roll, Saving Throw와 자동 효과

Spell Build의 Recipe가 다음 중 하나 이상을 선언한다.

```text
spell_attack
saving_throw
automatic_effect
ability_check_contest
mixed_or_repeated_resolution
```

주문 Runtime은 자체 Dice Engine을 만들지 않는다. 표준 Roll Request와 PendingEffect를 사용한다.

## 13. Concentration과 Duration

집중 주문이 활성화되면 Effect Runtime의 Concentration Channel에 연결한다.

```text
SpellCast Commit
→ Root EffectInstance
→ Concentration Channel
→ Child Effect·Area·Summon
```

새 집중 주문 시작은 기존 집중 종료와 새 효과 활성화를 같은 Transaction으로 처리한다.

시전자가 원할 때 집중을 끝내는 것은 `no_action_required` Capability로 제공한다.

## 14. Ready Spell

Ready는 주문을 Trigger 시점에 새로 시전하는 것이 아니다.

```text
Ready Action
→ Action 시전 주문 선택
→ 정상 시전·자원 소비
→ Held Spell EffectInstance
→ Concentration 유지
→ Trigger 발생
→ Reaction Offer
→ Release 또는 Ignore
```

규칙:

- 시전 시간이 Action인 주문만 준비 가능
- 시전 자원과 소비 재료는 준비 시점에 처리
- 유지에는 Concentration 필요
- 다음 자기 턴 시작 전까지만 유지
- 집중이 깨지거나 기한이 끝나면 효과 없이 소멸
- Trigger가 발생해도 Reaction을 사용하지 않으면 방출하지 않음

## 15. Counterspell과 반응 주문

반응 주문은 Spell Build의 `reactionTriggerPlan`으로 TimingWindow Offer를 생성한다.

Counterspell처럼 다른 주문 시전을 방해하는 주문은 부모 SpellCastExecution을 직접 수정하지 않는다.

```text
SpellCastExecution
→ Spell Cast Observed Event
→ Reaction TimingWindow
→ Counterspell Child Execution
→ 결과 기여
→ 부모 실행 재개·실패 판정
```

정확한 Counterspell 판정은 해당 주문 Recipe가 정의한다.

## 16. Magic Item과 Spell Cast의 차이

마법 아이템이 주문을 발동할 수 있어도 일반 Character Spellcasting Route와 동일하다고 가정하지 않는다.

Item Route는 다음을 별도로 선언할 수 있다.

- Item Charge 또는 사용 횟수
- 주문 슬롯 사용 여부
- 구성요소 면제·변경
- 고정 시전 능력치·DC
- 장착·조율·소유 조건
- 파괴·오작동 정책

그래도 RuleExecution, Targeting, Effect, Transaction과 Projection은 같은 Runtime을 사용한다.

## 17. 역할 구분

### PLAYER_ONLY

- 제어 중인 캐릭터의 공개된 SpellCastOption 선택
- Route·Cast Level·Payment Option 선택
- 대상·영역·모드 선택
- Ready Trigger 입력
- Reaction Spell Offer 수락·거절

### DM_ONLY

- 숨겨진 주문·효과 정보 확인
- 비밀 대상·DC·면역 정보 관리
- 주문 접근권·준비 상태·Resource 강제 수정
- 강제 시전·취소·성공·실패와 대상 Override
- Homebrew Spell 등록·비활성화

DM Override는 Audit Log를 남기며 권위 Transaction을 우회하지 않는다.

### SHARED

- 공개 주문 설명 확인
- 공개 가능한 시전 결과와 Roll 확인
- 공개 가능한 Area Preview와 Effect 상태 확인

### SYSTEM_ONLY

- Route Resolver와 Cast Option 생성
- Resource·Material Reservation
- Usage Gate와 Component 검증
- Target Revalidation
- RuleExecution 중단·재개
- Commit·Journal·Recovery·Rollback

## 18. Persistence와 Recovery

저장 대상:

- SpellCastRoute의 영구 선택·접근 상태
- Resource와 준비 상태
- 진행 중 LongCastExecution
- Ready Spell의 Held Effect와 Trigger
- 예약된 Resource·Material
- RuleExecution·TimingWindow·Target Binding
- Build Reference·Hash와 Revision

재생성 대상:

- Spell 후보 UI 목록
- 설명 Tooltip
- Area Preview Mesh
- 최종 Modifier 합계
- Animation·VFX·Camera

복구 후 이전 AuthorityEpoch의 Prompt·Offer를 재사용하지 않고 새 Projection으로 재발급한다.

## 19. 실패 코드 예시

```text
SPELL_ROUTE_NOT_FOUND
SPELL_NOT_PREPARED
SPELL_ACCESS_REVOKED
INVALID_CASTING_TIME
ACTION_OPPORTUNITY_UNAVAILABLE
SPELL_SLOT_TURN_GATE_EXCEEDED
NO_VALID_PAYMENT_OPTION
RESOURCE_RESERVATION_FAILED
VERBAL_COMPONENT_BLOCKED
SOMATIC_COMPONENT_BLOCKED
MATERIAL_COMPONENT_MISSING
MATERIAL_COMPONENT_RESERVED
INVALID_CAST_LEVEL
RITUAL_NOT_ALLOWED
TARGET_OUT_OF_RANGE
TARGET_NOT_VISIBLE
LINE_OF_EFFECT_BLOCKED
REACTION_TRIGGER_EXPIRED
CONCENTRATION_UNAVAILABLE
STALE_SPELL_ROUTE
STALE_TARGET_SNAPSHOT
```

## 20. 성능 원칙

- 주문마다 Heartbeat Loop를 만들지 않는다.
- Cast Option은 Character·Route·Resource·Equipment·Effect Revision으로 Cache한다.
- Target Preview는 Spatial Query Budget과 Candidate Cap을 따른다.
- 장시간 시전은 Scheduler와 논리 시간으로 갱신한다.
- 대량 AoE는 Batch Roll·PendingEffect와 Chunked Projection을 사용한다.
- 비공개 주문 정보와 숨은 대상은 Client에 보내지 않는다.

## 21. 비목표

- 주문 이름별 거대한 조건문을 만들지 않는다.
- Client가 슬롯 소비·대상 적격·최종 피해를 확정하지 않는다.
- 모든 공식 주문을 완전 자동화할 수 있다고 가정하지 않는다.
- 마이크로 실제 음성 구성요소를 검사하지 않는다.
- 시전 가능성을 위해 장비를 자동 변경하지 않는다.
- VFX 완료를 주문 결과 Commit 조건으로 사용하지 않는다.
