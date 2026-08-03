# ADR-0036: 시야·감각·은신·탐지는 관찰자 상대적 PerceptionState와 확장 가능한 규칙 지점으로 처리한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0023`](ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0027`](ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0035`](ADR-0035-manual-fog-masks-and-optional-region-assist.md)
  - [`30. 시야·감각·은신·탐지 모델`](../systems/perception/visibility-senses-stealth-and-detection-model.md)

## 배경

RVTT의 시야 규칙은 단순히 두 토큰 사이에 Raycast 하나를 쏘는 기능이 아니다.

- 일반 시야, 암시야, 맹시, 진동감지, 진시야와 사용자 정의 감각이 서로 다른 대상을 다른 정밀도로 감지한다.
- 밝은 빛, 약한 빛, 어둠, 마법적 어둠과 시야를 가리는 연기·안개가 감각마다 다르게 작동한다.
- 고저차, 난간, 문, 창문, 큰 장애물과 복층 구조 때문에 단일 시야선은 쉽게 잘못된 결과를 낸다.
- 은신과 투명은 전역 `hidden = true`가 아니라 관찰자마다 결과가 달라질 수 있다.
- 공격, 주문과 특성은 `볼 수 있는 대상`, `위치를 아는 대상`, `감지한 대상`, `시야가 필요 없는 지점`처럼 서로 다른 인식 조건을 요구한다.
- Feature, Feat, 종족 특성, 직업 특성, 주문, 장비와 상태 효과가 감각 범위, 어둠 처리, 은신 조건, 지각 판정, 보이지 않는 대상 공격과 엄폐 처리를 수정할 수 있어야 한다.
- Fog of War는 DM이 지형을 공개하는 수동 시스템이며, 자동 시야 판정이 Fog 마스크를 임의로 변경해서는 안 된다.

모든 특수 사례를 `if featId == ...` 또는 주문 이름 분기로 구현하면 공식 콘텐츠와 사용자 콘텐츠를 확장하기 어렵다.

반대로 실제 메시와 Roblox 렌더링 결과를 규칙 원본으로 사용하면 장식물, 프레임률, 스트리밍과 모델 변경에 따라 규칙 결과가 달라진다.

## 결정

시야와 탐지는 서버 권위 `PerceptionEngine`이 처리하며, 결과는 관찰자와 대상의 관계마다 별도 `PerceptionRelation`으로 관리한다.

```text
Observer Sense Capability Set
+ Target Percealment Profile
+ Lighting·Obscurement Snapshot
+ Semantic Vision Blockers
+ Stealth·Detection Contest State
→ PerceptionQuery
→ PerceptionRelation
```

Fog of War, 시야, 효과선과 엄폐는 분리한다.

```text
Fog of War
→ 플레이어에게 지형을 공개할지 결정

Perception
→ 관찰자가 Actor·오브젝트를 어느 수준으로 인식하는지 결정

Line of Sight
→ 특정 규칙이 요구하는 시각적 경로가 존재하는지 결정

Line of Effect
→ 공격·주문 효과가 물리적으로 도달할 수 있는지 결정

Cover
→ 공격 경로가 어느 정도 가려지는지 결정
```

시야 판정은 Fog 마스크를 자동 편집하지 않는다.

## PerceivableEntity

탐지 대상은 Actor에 한정하지 않는다.

```text
PerceivableEntity
├─ CharacterActor
├─ RuleSceneObject
├─ SceneEffect
├─ Trap or SecretFeature
└─ CustomRegisteredEntity
```

각 대상은 규칙용 단순 형상과 감지 특성을 가진다.

```text
PercealmentProfile
├─ ruleVolume
├─ visualSignature
├─ soundSignature
├─ vibrationSignature
├─ magicalSignature
├─ concealmentTags[]
├─ visibilityOverrides[]
└─ revision
```

실제 MeshPart 외형을 직접 시야 판정 형상으로 사용하지 않는다.

## SenseCapability

감각은 ActorDefinition의 고정 필드가 아니라 Capability Set에 투영되는 타입 있는 기능이다.

```text
SenseCapability
├─ senseId
├─ senseKind
├─ rangeExpression
├─ originProfileId
├─ targetFilters[]
├─ blockerProfileId
├─ lightingInteractionProfileId
├─ obscurementInteractionProfileId
├─ precisionLevel
├─ activationPredicate
├─ stackingPolicy
└─ informationPolicy
```

초기 감각 종류:

```text
normal_vision
darkvision
blindsight
tremorsense
truesight
hearing
scent
magic_detection
custom_registered
```

`precisionLevel`은 감각이 제공하는 정보 수준을 나타낸다.

```text
presence_only
approximate_location
exact_location
visual_perception
full_revelation
```

감각 하나가 모든 정보를 자동 제공하지 않는다. 예를 들어 진동감지는 정확한 위치를 제공할 수 있지만 외형이나 색상을 보여주는 시각 감각은 아닐 수 있다.

## 관찰자 상대적 PerceptionRelation

```text
PerceptionRelation
├─ observerActorId
├─ targetEntityId
├─ awarenessLevel
├─ contributingSenseIds[]
├─ currentLocationKnowledge
├─ lastKnownPosition?
├─ identityKnowledge
├─ concealmentContestId?
├─ activeOverrides[]
├─ evaluatedAtRevisionSet
└─ stateRevision
```

`awarenessLevel` 초기 값:

```text
unaware
presence_detected
approximate_location_known
exact_location_known
visually_perceived
fully_revealed
```

한 대상이 모든 관찰자에게 동시에 숨겨지거나 드러난다고 가정하지 않는다.

```text
경비병 A
→ 도적을 visually_perceived

경비병 B
→ 도적의 exact_location_known

경비병 C
→ unaware
```

## 의미 기반 시야 형상

시야 판정은 장면의 모든 Part를 Raycast하지 않는다.

```text
VisionBlocker
├─ ruleVolume
├─ blockerKind
├─ heightRange
├─ materialTags[]
├─ openState?
└─ revision
```

초기 blocker 종류:

```text
opaque
one_way
transparent_to_selected_senses
partial_visual_blocker
portal_link
custom_registered
```

벽, 닫힌 문과 큰 구조물만 의미 차단체로 참여한다. 난간 장식, VFX, 토큰 선택 원과 작은 소품은 기본적으로 제외한다.

## 고저차와 다중 샘플

단일 중심점 Raycast를 사용하지 않는다.

```text
ObserverSampleProfile
→ 눈높이와 크기에 따른 복수 관찰점

TargetSampleProfile
→ 중심·상단·좌우 등 규칙용 복수 표본점
```

`LineOfSightQuery`는 여러 표본 경로를 검사하여 다음 결과를 반환한다.

```text
clear
partially_visible
blocked
indeterminate
```

일부 경로만 통과했다고 즉시 완전 차단하지 않는다. 표본 수, 통과 임계치와 크기별 형상은 규칙 세트가 소유한다.

`partially_visible`은 엄폐 후보 계산에 전달할 수 있지만, 시야와 엄폐의 최종 결과는 서로 다른 파이프라인에서 결정한다.

## 조명과 가림

Roblox의 렌더 밝기만으로 규칙 조명을 판정하지 않는다.

```text
RuleLightingField
├─ bright_light
├─ dim_light
├─ darkness
├─ magical_darkness
└─ custom_registered
```

```text
ObscurementVolume
├─ lightly_obscured
├─ heavily_obscured
├─ visual_only
├─ sense_filtered
└─ custom_registered
```

빛과 가림은 SceneEffect와 RuleSceneObject가 생성할 수 있으며, 감각별 상호작용 프로필이 이를 해석한다.

## 은신

은신 행동은 전역 Hidden 플래그를 생성하지 않는다.

```text
Hide Action
→ 은신 적격성 RulePoint 평가
→ Stealth Roll
→ ConcealmentAttempt 생성
→ 관찰자별 Detection 평가
→ PerceptionRelation 갱신
```

```text
ConcealmentAttempt
├─ concealmentAttemptId
├─ actorId
├─ rollRecordId
├─ stealthOutcome
├─ eligibleObserverScope
├─ concealmentSources[]
├─ breakConditions[]
├─ durationPolicy
└─ revision
```

관찰자는 수동 지각, 능동 수색, 특수 감각과 사건 기반 재평가를 통해 해당 시도를 이길 수 있다.

## 투명과 보이지 않음

투명 상태는 대상을 존재하지 않는 것으로 만들지 않는다.

투명 효과는 시각 감각과 대상 지정 규칙에 Capability·RuleOverride를 제공한다.

- 일반 시야는 대상을 시각적으로 인식하지 못할 수 있다.
- 맹시, 진시야 또는 다른 감각은 위치나 외형을 인식할 수 있다.
- 소리, 흔적과 이미 알려진 위치 때문에 `exact_location_known` 상태가 유지될 수 있다.
- 공격과 주문은 요구하는 인식 수준에 따라 허용 여부와 불리점을 다르게 적용한다.

## 수동 지각과 능동 수색

수동 탐지는 매 프레임 모든 Actor 쌍을 재굴림하지 않는다.

```text
PerceptionStimulus
├─ movement
├─ entered_range
├─ left_cover
├─ sound_emitted
├─ attack_revealed
├─ light_changed
├─ blocker_changed
├─ concealment_started
└─ explicit_search
```

관련 사건이 발생할 때만 적격 관찰자를 찾아 재평가한다.

능동 수색은 `ActionCapability + EffectRecipe`이며, 성공 결과가 관찰자별 PerceptionRelation을 갱신한다.

## Targeting과의 연결

TargetingPlan은 필요한 인식 수준을 명시한다.

```text
PerceptionRequirement
├─ none
├─ presence_known
├─ approximate_location_known
├─ exact_location_known
├─ visually_perceived
└─ fully_revealed
```

예시:

- `볼 수 있는 생물`은 `visually_perceived`를 요구한다.
- 보이지 않는 대상에 대한 무기 공격은 `exact_location_known`이면 허용될 수 있으나 공격 문맥 수정이 붙을 수 있다.
- 범위 주문의 지점 선택은 대상 Actor 인식을 요구하지 않을 수 있다.
- 특정 감지 주문은 `presence_known`만 생성할 수 있다.

## Feature·Feat 호환 규칙 지점

시야 시스템은 콘텐츠 ID를 직접 분기하지 않는다. Feature와 Feat는 기존 Capability 구조를 통해 다음 규칙 지점을 수정한다.

### 감각 부여와 변경

```text
SenseCapability
DerivedValueModifierCapability
ConditionalCapabilityGroup
```

예시:

- 암시야 부여
- 기존 암시야 범위 증가
- 일정 거리의 맹시 부여
- 집중 중에만 진시야 부여
- 지면에 접촉한 동안만 진동감지 활성화

### 지각·은신 판정 수정

```text
ContextModifierCapability
```

대상 문맥:

```text
perception_check
passive_perception
stealth_check
concealment_contest
detection_recheck
```

### 규칙 예외

```text
RuleOverrideCapability
```

중앙 RulePoint 예시:

```text
perception.hide_eligibility
perception.visual_requirement
perception.darkness_interpretation
perception.magical_darkness_interpretation
perception.obscurement_interpretation
perception.invisible_target_location
perception.attack_reveal_timing
perception.missed_attack_reveal
perception.search_scope
perception.cover_interaction
perception.line_of_sight_sampling
```

### 사건 기반 특성

```text
TriggerCapability
UsageGate
EffectRecipe
```

예시:

- 공격이 빗나갔을 때 은신을 유지하는 특성
- 특정 범위에 투명한 대상이 들어오면 탐지 재평가
- 턴당 한 번 감지 실패를 재굴림
- 피해를 받으면 숨은 대상의 위치를 알아내는 효과

### 능동 특성

```text
ActionCapability
TargetingPlan
EffectRecipe
```

예시:

- 수색 행동 강화
- 제한 시간 동안 보이지 않는 존재 감지
- 대상의 은신 상태를 해제하는 특수 행동

따라서 새로운 Feat가 추가되어도 PerceptionEngine 내부에 Feat 이름별 분기를 추가하지 않는다.

## 공개와 보안

서버는 관찰자의 PerceptionRelation과 사용자 권한에 따라 복제 범위를 결정한다.

- `unaware` 대상의 실제 Actor와 위치는 권한 없는 클라이언트에 보내지 않는다.
- 마지막 위치만 아는 경우 실제 최신 위치 대신 허용된 기억 마커만 제공한다.
- 숨겨진 정체, 비밀 행동과 실제 생물 유형은 별도 정보 정책을 따른다.
- DM은 원본 상태와 플레이어별 인식 결과를 겹쳐 볼 수 있다.

투명도를 1로 설정한 실제 적 토큰을 모든 클라이언트에 보내는 방식은 사용하지 않는다.

## 성능

- 공간 인덱스로 감각 범위 안의 후보만 broad phase에서 수집한다.
- 이동, 조명, 차단체, 감각, 은신과 상태 revision이 바뀐 관계만 무효화한다.
- 모든 Observer와 Target 쌍을 매 프레임 검사하지 않는다.
- 다중 샘플 시야선은 broad phase와 조건 검사를 통과한 후보에만 수행한다.
- 동일 revision 조합의 PerceptionQuery 결과를 캐시한다.
- Fog 마스크 합성과 PerceptionQuery를 서로 다른 캐시와 갱신 주기로 운영한다.

## DM 판정

애매하거나 규칙 데이터가 부족한 경우 `RequestDMAdjudication`을 사용할 수 있다.

DM은 다음을 명시적으로 덮어쓸 수 있다.

- 특정 관찰자가 대상을 볼 수 있음 또는 볼 수 없음
- 위치를 알고 있음 또는 잃어버림
- 은신 적격성 승인 또는 거절
- 특정 차단체를 이번 판정에서 무시
- 수색 성공·실패 강제

판정은 범위, 이유와 지속시간을 포함해 로그에 기록한다.

## 결과

- 수동 Fog of War를 유지하면서 공격·은신 규칙에 필요한 실제 시야를 별도로 계산할 수 있다.
- 고저차와 복잡한 메시로 인한 단일 Raycast 오류를 줄일 수 있다.
- 은신과 투명을 관찰자별 관계로 표현할 수 있다.
- 암시야, 맹시, 진동감지와 진시야를 같은 감각 계약으로 처리할 수 있다.
- Feature와 Feat가 감각, 지각, 은신, 공개 시점과 대상 지정 규칙을 데이터로 확장할 수 있다.
- 숨겨진 Actor와 비밀 정보를 클라이언트 복제 단계에서 보호할 수 있다.
- 자동 시야가 Fog를 잘못 열어 비밀 지형을 노출하는 문제를 방지할 수 있다.
