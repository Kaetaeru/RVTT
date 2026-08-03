# 30. 시야·감각·은신·탐지 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`17. 주문 대상·범위·공간 질의 모델`](../rules/spell-targeting-area-and-spatial-query-model.md)
  - [`19. 트리거와 다른 턴 실행 모델`](../rules/feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`21. 패시브 특성 모델`](../../architecture/passive-modifier-and-rule-override-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`28. 인카운터·주도권·턴과 제어권 모델`](../combat/encounter-initiative-turn-and-control-authority-model.md)
  - [`29. 수동 Fog of War와 선택형 Assist 모델`](manual-fog-of-war-and-optional-assist-model.md)
  - [`ADR-0036`](../../decisions/ADR-0036-observer-relative-perception-senses-stealth-and-rule-points.md)

## 1. 문서 목적

이 문서는 D&D 규칙상의 시야, 감각, 은신, 투명, 수동 지각, 능동 수색과 대상 인식을 하나의 확장 가능한 서버 권위 구조로 처리하는 방법을 정의한다.

대상:

- 일반 시야
- 밝은 빛, 약한 빛과 어둠
- 마법적 어둠
- 암시야, 맹시, 진동감지와 진시야
- 사용자 정의 감각
- 고저차와 복층 시야
- 시야 차단체와 가림 영역
- 수동 지각과 능동 수색
- 은신 행동과 관찰자별 탐지
- 투명한 대상과 보이지 않는 대상
- 공격, 주문과 특성의 대상 지정 조건
- Feature·Feat·장비·상태 효과와의 호환
- DM 판정, 비밀 정보와 클라이언트 복제
- 성능, 저장과 재접속

핵심 원칙:

```text
Fog of War
≠ 시야 판정
≠ Actor 탐지
≠ 효과선
≠ 엄폐
```

```text
숨겨짐
≠ 모든 관찰자에게 동일한 전역 상태
```

```text
Feature와 Feat
→ PerceptionEngine의 이름별 분기
아님

Feature와 Feat
→ Capability·RulePoint·Trigger·Recipe 조합
```

---

## 2. 시스템 책임 분리

### 2.1 Fog of War

DM이 지형을 플레이어에게 공개하거나 기억 상태로 유지하는 수동 마스크다.

시야 판정은 Fog 마스크를 자동으로 열거나 닫지 않는다.

### 2.2 Perception

특정 관찰자가 특정 Actor, 함정, 비밀문, 장면 효과나 오브젝트를 어느 수준으로 인식하는지를 결정한다.

### 2.3 Line of Sight

특정 규칙이 요구하는 시각적 경로가 존재하는지를 판단한다.

### 2.4 Line of Effect

공격, 주문 또는 효과가 대상까지 물리적으로 도달할 수 있는지를 판단한다.

투명한 유리창은 시야를 허용하면서 효과선을 막을 수 있다.

### 2.5 Cover

공격 경로가 장애물에 의해 얼마나 보호되는지를 판단한다.

일부 표본 시야선이 통과했다고 곧바로 엄폐 없음으로 확정하지 않는다.

---

## 3. 전체 런타임 구조

```text
PerceptionEngine
├─ SenseProjectionService
├─ LightingQueryService
├─ ObscurementQueryService
├─ VisionBlockerQueryService
├─ LineOfSightService
├─ ConcealmentService
├─ DetectionContestService
├─ PerceptionRelationStore
├─ PerceptionReplicationService
└─ PerceptionInvalidationIndex
```

처리 흐름:

```text
관찰자와 대상 후보 수집
→ 활성 감각 수집
→ 감각별 거리·대상 적격성 검사
→ 조명·가림·차단체 검사
→ 은신·투명·감지 예외 검사
→ 관찰자별 인식 수준 계산
→ PerceptionRelation 갱신
→ 허용된 정보만 클라이언트에 복제
```

---

## 4. PerceivableEntity

Actor뿐 아니라 탐지 가능한 모든 장면 요소를 공통 인터페이스로 다룬다.

```text
PerceivableEntity
├─ entityId
├─ entityKind
├─ sceneBinding
├─ ruleVolumeProfileId
├─ percealmentProfileId
├─ informationProfileId
├─ currentTransform
├─ lifecycleState
└─ revision
```

`entityKind` 예시:

```text
actor
scene_object
trap
secret_feature
scene_effect
illusion
sound_source
custom_registered
```

### 4.1 PercealmentProfile

```text
PercealmentProfile
├─ visualSignature
├─ soundSignature
├─ vibrationSignature
├─ scentSignature
├─ magicalSignature
├─ concealmentTags[]
├─ defaultInformationLevel
├─ activeVisibilityOverrides[]
└─ revision
```

대상이 완전히 정지했는지, 소리를 냈는지, 지면에 접촉했는지와 같은 현재 상태는 Profile 원본을 수정하지 않고 Context와 EffectInstance에서 결합한다.

---

## 5. SenseCapability

감각은 Actor의 고정 문자열 목록이 아니라 Capability다.

```text
SenseCapability
├─ capabilityId
├─ senseKind
├─ rangeExpression
├─ originProfileId
├─ targetFilters[]
├─ blockerProfileId
├─ lightingInteractionProfileId
├─ obscurementInteractionProfileId
├─ signatureRequirements[]
├─ precisionLevel
├─ activationPredicate
├─ stackingKey
├─ stackingPolicy
└─ informationPolicy
```

초기 `senseKind`:

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

### 5.1 precisionLevel

```text
presence_only
approximate_location
exact_location
visual_perception
full_revelation
```

감각은 자신이 제공할 수 있는 최대 정보 수준을 명시한다.

예시:

```text
hearing
→ presence_only 또는 approximate_location

tremorsense
→ exact_location
→ 외형과 색상은 제공하지 않음

normal_vision
→ visual_perception

truesight
→ 조건을 충족하면 full_revelation
```

### 5.2 감각 중첩

감각은 기본적으로 독립적으로 평가한 뒤 가장 높은 유효 인식 결과를 합성한다.

```text
normal vision: blocked
hearing: approximate_location
blindsight: exact_location

최종 관계
→ exact_location_known
```

범위 증가와 동일 감각 부여는 `stackingPolicy`에 따라 처리한다.

```text
highest_range_only
replace_by_priority
independent_channels
merge_filters
custom_ruleset_policy
```

---

## 6. 감각 원점과 규칙용 표본점

실제 토큰 메시의 눈 위치를 직접 사용하지 않는다.

```text
SenseOriginProfile
├─ originKind
├─ localOffsets[]
├─ stanceAdjustments
├─ sizeAdjustments
└─ fallbackPolicy
```

예시:

```text
vision_eye_points
hearing_body_center
vibration_contact_points
magic_aura_center
```

대상도 규칙용 표본점을 가진다.

```text
VisibilitySampleProfile
├─ center
├─ upper_body
├─ lower_body
├─ left_extent
├─ right_extent
└─ sizeSpecificSamples[]
```

토큰이 엎드리거나 크기가 변하면 Profile 선택 또는 크기·자세 Modifier를 통해 갱신한다.

---

## 7. 규칙 조명

Roblox Lighting과 실제 픽셀 밝기는 연출용이며 권위 규칙 값이 아니다.

```text
RuleLightingField
├─ fieldId
├─ volume
├─ lightLevel
├─ sourceEntityId?
├─ priority
├─ interactionTags[]
└─ revision
```

`lightLevel`:

```text
bright_light
dim_light
darkness
magical_darkness
custom_registered
```

### 7.1 조명 합성

같은 위치에 여러 광원이 겹치면 규칙 세트의 조명 합성 정책을 사용한다.

```text
base scene lighting
→ local light fields
→ darkness fields
→ magical overrides
→ final RuleLightState
```

마법적 어둠과 일반 빛의 우선순위는 콘텐츠 배열 순서가 아니라 규칙 세트의 명시적 우선순위가 결정한다.

### 7.2 Feature·Feat의 조명 해석 변경

감각 또는 RuleOverride가 다음을 바꿀 수 있다.

```text
어둠을 약한 빛처럼 해석
약한 빛의 시각 불이익 무시
마법적 어둠에서도 시각 사용
특정 태그의 어둠만 무시
```

이를 Actor별 렌더 밝기 조작만으로 구현하지 않는다. 규칙 판정 결과와 플레이어 표현을 모두 같은 해석 결과에서 파생한다.

---

## 8. ObscurementVolume

연기, 안개, 수풀과 모래폭풍처럼 공간을 가리는 효과를 조명과 분리한다.

```text
ObscurementVolume
├─ volumeId
├─ ruleVolume
├─ obscurementKind
├─ affectedSenseTags[]
├─ unaffectedSenseTags[]
├─ densityProfile
├─ sourceEffectInstanceId?
└─ revision
```

초기 종류:

```text
lightly_obscured
heavily_obscured
visual_only
sound_dampening
vibration_dampening
sense_filtered
custom_registered
```

감각의 `obscurementInteractionProfileId`가 각 가림을 어떻게 처리할지 결정한다.

---

## 9. 의미 기반 VisionBlocker

```text
VisionBlocker
├─ blockerId
├─ ruleVolume
├─ blockerKind
├─ heightRange
├─ senseFilter
├─ openState?
├─ portalBinding?
└─ revision
```

초기 종류:

```text
opaque
partial_visual_blocker
one_way
transparent_to_selected_senses
portal_link
custom_registered
```

다음은 기본적으로 시야 차단체에서 제외한다.

- VFX
- 선택 원과 기즈모
- 작은 장식 소품
- 통과 가능한 수풀의 개별 잎 메시
- 토큰의 시각 메시
- Fog 표시용 오브젝트

문은 자신의 열림 상태에 따라 차단체를 활성화하거나 비활성화한다.

창문은 시야 허용과 효과선 차단을 별도 프로필로 가질 수 있다.

---

## 10. LineOfSightQuery

```text
LineOfSightQuery
├─ observerId
├─ targetEntityId 또는 targetVolume
├─ requiredSenseKind?
├─ observerSampleProfileId
├─ targetSampleProfileId
├─ blockerProfileId
├─ ruleContext
└─ revisionSnapshot
```

출력:

```text
LineOfSightResult
├─ state
├─ testedPathCount
├─ clearPathCount
├─ blockedPathCount
├─ indeterminatePathCount
├─ blockerReferences[]
├─ visibilityFractionBand
└─ diagnostics[]
```

`state`:

```text
clear
partially_visible
blocked
indeterminate
```

### 10.1 고저차

모든 시야선은 실제 3차원 좌표를 사용한다.

- 낮은 벽 너머의 대형 대상 상단이 보일 수 있다.
- 아래층 천장이 위층과 아래층의 시야를 막을 수 있다.
- 계단이나 발코니는 의미 차단체의 실제 높이 범위를 사용한다.
- ViewY는 로컬 카메라 표시 기능이므로 권위 시야 결과를 바꾸지 않는다.

### 10.2 관대한 표본 정책

단일 경로가 장식 경계에 닿았다는 이유로 전체 시야를 차단하지 않는다.

규칙 세트는 다음을 소유한다.

```text
필요 최소 통과 경로 수
크기별 표본 개수
부분 시야 임계치
접촉 오차 허용 범위
동일 평면 경계 처리
```

### 10.3 indeterminate

규칙 형상 누락, 겹친 포털 또는 비정상 장면 데이터 때문에 결과를 안정적으로 확정할 수 없으면 `indeterminate`를 반환한다.

이 경우 콘텐츠 정책에 따라:

```text
보수적으로 차단
관대하게 허용
DM 판정 요청
```

중 하나를 선택한다.

---

## 11. PerceptionRelation

```text
PerceptionRelation
├─ relationId
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
├─ updatedAtGameTime
└─ revision
```

`awarenessLevel`:

```text
unaware
presence_detected
approximate_location_known
exact_location_known
visually_perceived
fully_revealed
```

### 11.1 위치와 정체 분리

```text
currentLocationKnowledge
├─ none
├─ approximate
├─ exact
└─ stale_exact
```

```text
identityKnowledge
├─ unknown_entity
├─ known_category
├─ known_public_identity
└─ known_true_identity
```

투명한 뱀파이어의 정확한 위치를 맹시로 감지하더라도 진짜 정체까지 자동으로 알게 되는 것은 아니다.

### 11.2 마지막 위치

대상이 시야에서 사라지면 정책에 따라 마지막으로 확정된 위치를 유지할 수 있다.

```text
lastKnownPosition
├─ transformSnapshot
├─ observedAtGameTime
├─ certainty
└─ sourceSenseId
```

실제 최신 위치를 클라이언트에 보내고 단순히 토큰을 숨기는 방식은 사용하지 않는다.

---

## 12. PerceptionQuery

```text
PerceptionQuery
├─ observerActorId
├─ targetEntityId
├─ requestedInformationLevel
├─ purpose
├─ ruleContext
└─ revisionSnapshot
```

`purpose` 예시:

```text
passive_detection
active_search
attack_targeting
spell_targeting
reaction_eligibility
movement_awareness
information_display
dm_inspection
```

처리 순서:

```text
1. 대상과 관찰자의 현재 상태 확인
2. 활성 SenseCapability 수집
3. 감각별 거리와 필터 검사
4. 시야·조명·가림·서명 검사
5. 은신 시도와 탐지 판정 적용
6. RuleOverride와 DM 판정 적용
7. 감각 결과 합성
8. PerceptionRelation 생성 또는 갱신
```

콘텐츠 파일의 나열 순서는 결과 우선순위가 아니다.

---

## 13. 은신 행동

은신은 `ActionCapability`다.

```text
HideActionCapability
├─ activationContext
├─ actionEconomyCost
├─ eligibilityRulePointId
├─ stealthCheckProfileId
├─ concealmentProfileId
├─ breakConditionProfileId
└─ effectRecipeId
```

처리:

```text
Hide 선언
→ 현재 은신 적격성 검사
→ 비용 예약
→ Stealth Roll
→ 결과 공개
→ ConcealmentAttempt 생성
→ 관련 관찰자 Detection 평가
→ 관찰자별 PerceptionRelation 갱신
```

### 13.1 은신 적격성

중앙 RulePoint:

```text
perception.hide_eligibility
```

입력:

```text
시전자 위치
관찰자 후보
조명과 가림
현재 시야 관계
특성·Feat·상태
전투 또는 탐험 문맥
```

출력:

```text
allowed
denied
allowed_with_conditions
dm_adjudication
```

Feature는 특정 조건에서 은신 가능 범위를 확장할 수 있지만, Hide 시스템 내부 코드를 교체하지 않는다.

### 13.2 ConcealmentAttempt

```text
ConcealmentAttempt
├─ concealmentAttemptId
├─ actorId
├─ rollRecordId
├─ stealthOutcome
├─ startedByExecutionId
├─ eligibleObserverScope
├─ concealmentSources[]
├─ breakConditions[]
├─ durationPolicy
├─ state
└─ revision
```

상태:

```text
active
partially_compromised
ended
superseded
```

관찰자 한 명에게 들켜도 다른 관찰자에게 자동으로 종료되지 않는다.

---

## 14. DetectionContest

```text
DetectionContest
├─ contestId
├─ concealmentAttemptId
├─ observerActorId
├─ detectionSource
├─ observerScoreBinding
├─ targetScoreBinding
├─ comparisonPolicy
├─ outcome
└─ revision
```

`detectionSource`:

```text
passive_perception
active_search
special_sense
automatic_reveal
shared_information
dm_adjudication
```

동률 처리와 성공 기준은 규칙 세트가 소유한다.

수동 지각은 저장된 고정 숫자가 아니라 현재 Capability를 반영한 파생 값으로 계산한다.

---

## 15. 수동 지각

```text
actor.passive_perception
```

은 `DerivedValueCatalog` 항목이다.

기본 계산과 Feature 기여를 출처별로 유지한다.

```text
기본 공식
+ 숙련 기여
+ Feature 보너스
+ 장비 보너스
+ 상태 불이익
→ 최종 수동 지각
```

수동 탐지는 매 프레임 모든 대상을 확인하지 않는다.

다음 사건이 발생할 때 관련 후보만 재평가한다.

```text
관찰자 또는 대상의 의미 있는 이동
감각 범위 진입·이탈
문 열림·닫힘
빛 또는 가림 변화
은신 시도 시작
소리나 진동 발생
공격 공개
관찰자 감각 활성화·비활성화
대상의 투명·변신 상태 변화
```

---

## 16. 능동 수색

수색은 `ActionCapability + TargetingPlan + EffectRecipe`로 실행한다.

```text
SearchAction
├─ searchMode
├─ areaOrTargetPlan
├─ checkProfileId
├─ informationRequestLevel
├─ cost
└─ resultRecipeId
```

`searchMode` 예시:

```text
visual_search
listen
inspect_object
search_area
sense_magic
custom_registered
```

수색 성공은 대상의 Hidden 플래그를 직접 제거하지 않고 해당 관찰자의 PerceptionRelation을 갱신한다.

특정 특성은:

- 수색 범위를 확장
- 행동 비용을 변경
- 지각 판정에 보너스 부여
- 특정 종류의 비밀 요소만 추가 탐지
- 실패 시 재굴림 허용

할 수 있다.

---

## 17. PerceptionStimulus

은신 대상이 행동하거나 환경이 바뀔 때 사건 기반으로 탐지를 재평가한다.

```text
PerceptionStimulus
├─ stimulusId
├─ sourceEntityId
├─ stimulusKind
├─ origin
├─ intensityProfile
├─ affectedSenseTags[]
├─ observerCandidatePolicy
├─ informationLevelCap
└─ emittedAtRevision
```

종류:

```text
movement
sound_emitted
vibration_emitted
attack_declared
attack_revealed
spell_component_used
damage_received
light_created
cover_left
door_opened
object_interacted
custom_registered
```

Stimulus가 항상 자동 발견을 뜻하지는 않는다.

```text
Stimulus
→ 자동 위치 공개
또는
→ DetectionContest 재평가
또는
→ presence_detected만 제공
```

정책은 규칙 세트와 발생 효과가 결정한다.

---

## 18. 은신 해제와 공개 시점

```text
ConcealmentBreakCondition
├─ eventKind
├─ timingWindow
├─ observerScope
├─ outcomePolicy
├─ suppressionPredicate?
└─ priority
```

예시:

```text
공격 결과 공개 시
주문 시전 구성요소 공개 시
밝은 영역에 진입 시
가림을 벗어났을 때
큰 소리를 냈을 때
특정 피해를 받았을 때
DM이 종료했을 때
```

공격 버튼을 누른 즉시 모든 관찰자에게 공개하지 않는다. 정확한 TimingWindow에서 공개한다.

Feature 또는 Feat는 다음을 수정할 수 있다.

```text
빗나간 공격에서는 은신 유지
특정 종류의 공격 후에도 일부 관찰자에게 유지
공개 시점을 피해 적용 후로 연기
특정 Stimulus 강도를 낮춤
```

이러한 변경은 `RuleOverrideCapability` 또는 `TriggerCapability`로 제공한다.

---

## 19. 투명과 보이지 않는 대상

투명은 다음 기능을 조합한 `EffectInstance`다.

```text
시각 감각에 대한 PercealmentOverride
+ 공격·대상 지정 ContextModifier
+ 공개 또는 종료 Trigger
+ 지속시간·집중 정책
```

투명 상태가 제공할 수 있는 규칙 기여:

```text
normal_vision의 visual_perception 차단
특정 TargetingPlan의 visually_perceived 요구 충족 실패
공격자·방어자 문맥 RollMode 기여
특정 감각에 의한 Override 허용
```

다른 감각으로 정확한 위치를 알아도 `보았다`고 간주되는지는 해당 감각의 `precisionLevel`과 TargetingPlan 요구 조건이 결정한다.

```text
blindsight
→ exact_location 또는 visual-equivalent로 등록 가능

hearing
→ approximate_location
→ `볼 수 있는 대상` 요구는 충족하지 않음
```

규칙 세트는 특정 감각을 `visual-equivalent`로 취급할지 명시한다.

---

## 20. TargetingPlan과 인식 요구

```text
PerceptionRequirement
├─ minimumAwarenessLevel
├─ acceptedSenseTags[]?
├─ requireCurrentLocation
├─ allowLastKnownLocation
├─ unseenTargetPolicy
└─ failurePresentationPolicy
```

예시:

### 볼 수 있는 생물

```text
minimumAwarenessLevel: visually_perceived
requireCurrentLocation: true
```

### 보이지 않는 대상에 대한 무기 공격

```text
minimumAwarenessLevel: exact_location_known
unseenTargetPolicy: apply_registered_attack_modifier
```

### 위치를 추정한 공격

```text
minimumAwarenessLevel: approximate_location_known
unseenTargetPolicy: target_location_with_miss_risk
```

### 범위 지점 지정

```text
minimumAwarenessLevel: none
단, 지점 자체의 선택 가능성과 효과선은 별도 검사
```

### 감지 주문

```text
결과: presence_detected
정확한 위치나 정체는 제공하지 않을 수 있음
```

---

## 21. 공격 문맥과 보이지 않음

공격 시 다음을 별도로 평가한다.

```text
공격자가 대상을 어느 수준으로 인식하는가
대상이 공격자를 어느 수준으로 인식하는가
현재 공격이 시각을 요구하는가
정확한 위치를 알고 있는가
특성으로 보이지 않음 불이익을 무시하는가
엄폐가 존재하는가
```

결과는 `AttackRollContext`에 기여한다.

```text
ContextModifierCapability
→ RollModeContribution
→ NumericBonus
→ TargetRuleContribution
```

보이지 않는 대상이라는 이유만으로 공격 엔진 내부에서 고정 불리점을 하드코딩하지 않는다. 규칙 세트의 RulePoint와 활성 Capability가 최종 기여를 만든다.

---

## 22. Feature·Feat 호환 구조

Feature와 Feat는 아래 계약 중 하나 이상을 부여한다.

```text
SenseCapability
DerivedValueModifierCapability
ContextModifierCapability
RuleOverrideCapability
TriggerCapability
ActionCapability
ConditionalCapabilityGroup
```

### 22.1 감각을 부여하는 특성

```text
FeatureDefinition
→ GrantInstruction
→ SenseCapability
```

예시:

```text
10피트 맹시
60피트 암시야
기존 암시야 범위 +30피트
지면 접촉 중 30피트 진동감지
집중 중 120피트 진시야
```

### 22.2 감각 범위 수정

범위는 `sense.<senseKind>.range` 계열 DerivedValue로 노출할 수 있다.

```text
DerivedValueModifierCapability
├─ targetValueId: sense.darkvision.range
├─ operation: add
└─ value: 30 ft
```

감각 자체가 없을 때 범위 증가가 감각을 새로 생성하는지는 `requiresExistingSense` 정책으로 구분한다.

### 22.3 지각과 은신 판정

```text
ContextModifierCapability
├─ contextKind: perception_check
├─ predicate
└─ contribution
```

적용 문맥:

```text
passive_perception
visual_search
listen_search
stealth_check
concealment_contest
specific_creature_type_detection
```

### 22.4 조명과 가림 예외

```text
RuleOverrideCapability
├─ rulePointId: perception.darkness_interpretation
├─ overrideKind: replace 또는 ignore
└─ params
```

가능한 예외:

```text
약한 빛으로 인한 불이익 무시
일반 어둠을 약한 빛처럼 처리
마법적 어둠에서도 특정 감각 사용
연기 가림을 시각 감각에서 무시
수풀의 가벼운 가림을 은신 적격성으로 인정
```

### 22.5 은신 유지와 공개

```text
RuleOverrideCapability
→ perception.attack_reveal_timing
→ perception.missed_attack_reveal
```

또는:

```text
TriggerCapability
→ AttackResolved
→ 조건 검사
→ ConcealmentAttempt 유지 또는 종료 Recipe
```

### 22.6 능동 감지 특성

```text
ActionCapability
→ 감각 활성화 EffectInstance 생성
→ 일정 시간 SenseCapability 부여
```

### 22.7 엄폐와 시야의 구분

엄폐 무시는 `perception.cover_interaction` 또는 Cover 전용 RulePoint를 수정한다.

이는 시야가 확보되었다는 뜻이 아니다.

```text
엄폐 무시
≠ 벽 너머를 볼 수 있음
≠ 효과선 무시
```

---

## 23. 대표 Feature·Feat 매핑 예시

아래는 특정 공식 문구를 고정하는 것이 아니라 구현 형태를 보여주는 예시다.

### 23.1 Blind Fighting 계열

```text
SenseCapability
├─ senseKind: blindsight
├─ range: 10 ft
├─ precisionLevel: visual_perception 또는 ruleset 지정 수준
└─ activationPredicate: actor is not incapacitated
```

### 23.2 Observant 계열

```text
DerivedValueModifierCapability
→ actor.passive_perception 증가

ContextModifierCapability
→ 특정 Search 문맥 보너스
```

### 23.3 Skulker 계열

가능한 조합:

```text
RuleOverrideCapability
→ 약한 빛의 시각 불이익 변경

RuleOverrideCapability
→ 빗나간 원거리 공격의 은신 공개 정책 변경

ContextModifierCapability
→ 은신 또는 수색 문맥 수정
```

### 23.4 투명체 감지 주문·아이템

```text
EffectInstance
→ 조건부 SenseCapability 또는 PerceptionOverride
→ invisible 태그를 visual_perception에서 무시
```

### 23.5 마법적 어둠을 보는 특성

```text
SenseCapability 또는 RuleOverrideCapability
→ magical_darkness_interpretation 변경
```

### 23.6 보이지 않는 공격자 불이익 무시

```text
ContextModifierCapability
├─ contextKind: attack_roll
├─ predicate: attacker perception below visual threshold
└─ contribution: suppress specified RollMode source
```

다른 출처의 불리점까지 모두 지우지 않고, 정확히 해당 출처 기여만 억제한다.

---

## 24. 감각과 형태 변환

변신, 빙의와 형태 레이어는 감각 Capability를 추가·억제·교체할 수 있다.

```text
Base Character Sense Set
+ Active FormLayer grants
+ Suppressed original senses
+ Equipment and Effect grants
→ Projected Sense Capability Set
```

형태가 끝나면 원본 감각이 다시 활성화된다.

감각 데이터를 ActorInstance에 영구 복사하지 않는다.

---

## 25. 감각 억제

실명, 귀먹음, 안티매직과 환경 효과는 감각을 삭제하지 않는다.

```text
SuppressionSource
→ SenseCapability 비활성화
```

예시:

```text
blind condition
→ visual 태그 감각 억제

silence field
→ 소리 Stimulus와 hearing 채널 제한

anti-magic
→ 마법 기반 감각만 억제
```

억제 출처가 제거되면 다른 억제 출처가 없는 감각이 다시 활성화된다.

---

## 26. 파티 정보 공유와 플레이어 표시

Actor별 PerceptionRelation과 사용자 화면 표시를 분리한다.

```text
ObserverPerceptionState
→ 실제 규칙상 누가 감지했는가

ClientAwarenessAggregation
→ 한 사용자가 조작·공유받은 Actor들의 정보를 어떻게 표시할지
```

캠페인 정책:

```text
strict_individual
party_shared_visible_information
controlled_actor_union
dm_configured
```

정보 공유가 켜져도 숨겨진 진짜 정체나 DM 전용 정보는 자동 공유하지 않는다.

Feature가 텔레파시나 특별한 감각 공유를 제공한다면 `InformationShareCapability` 또는 Trigger 기반 공유 사건으로 처리한다.

---

## 27. Fog of War와의 결합

표현 조건:

```text
지형 표시
→ DiscoveryMask / CurrentRevealMask

Actor·오브젝트 표시
→ PerceptionRelation + 정보 권한
```

예시:

```text
CurrentRevealMask 있음
+ 적 Actor unaware
→ 방은 보이지만 적은 보이지 않음

CurrentRevealMask 없음
+ 특수 감각으로 적 exact_location_known
→ 캠페인 표현 정책에 따라 안개 위 감지 마커만 표시 가능

DiscoveryMask만 있음
+ 마지막 위치 기억
→ 기억된 지형 위에 마지막 위치 마커 표시 가능
```

Perception 결과는 Fog Assist 제안의 참고 정보가 될 수 있지만 마스크를 자동 확정하지 않는다.

---

## 28. 클라이언트 복제와 보안

서버는 사용자별 `PerceptionViewSnapshot`을 만든다.

```text
PerceptionViewSnapshot
├─ visibleEntitySnapshots[]
├─ detectedPresenceMarkers[]
├─ lastKnownMarkers[]
├─ publicIdentityData[]
├─ allowedDiagnostics[]
└─ revision
```

금지:

- 모든 적 Actor를 클라이언트에 보내고 투명도만 변경
- 실제 최신 위치를 보내고 UI만 숨김
- 비밀 특성이나 실제 생물 유형을 미리 복제
- 클라이언트가 자신의 감지 성공을 확정
- 클라이언트 Raycast 결과로 서버 인식 상태 변경

DM 클라이언트는 원본 장면과 플레이어별 인식 결과를 선택적으로 겹쳐 볼 수 있다.

---

## 29. UI와 진단

### 플레이어

표시 단계:

```text
정확히 보임
위치만 감지
대략적인 방향 감지
마지막 위치
미인지
```

각 상태에 서로 다른 토큰·마커·윤곽 표현을 사용할 수 있다.

플레이어에게는 알 수 없는 실패 이유를 노출하지 않는다.

예:

```text
대상을 볼 수 없습니다.
```

실제 이유가 투명, 마법적 어둠, 환영 또는 DM 비밀 효과인지 구분해서 보여주지 않을 수 있다.

### DM

DM 진단 오버레이:

```text
관찰자 선택
→ 감각 범위
→ 사용된 감각
→ 차단 경로
→ 조명·가림 결과
→ 은신 대 수동 지각 비교
→ 활성 RuleOverride
→ 최종 PerceptionRelation
```

`왜 보이는가`와 `왜 안 보이는가`를 출처별로 확인할 수 있어야 한다.

---

## 30. DM 판정

```text
PerceptionAdjudication
├─ adjudicationId
├─ observerScope
├─ targetScope
├─ forcedAwarenessLevel
├─ reason
├─ durationPolicy
├─ createdByUserId
└─ revision
```

사용 예:

```text
이번 판정에만 볼 수 있음
이 장면 동안 위치를 알고 있음
이 차단체를 무시
은신 적격성 강제 승인
수색 결과 강제 성공
```

판정은 숨은 규칙 데이터 자체를 수정하지 않고 우선순위가 높은 명시적 Override로 기록한다.

---

## 31. 저장과 재접속

저장 대상:

```text
활성 ConcealmentAttempt
장기 PerceptionAdjudication
지속해야 하는 마지막 위치 정보
캠페인 정책상 유지되는 PerceptionRelation
감각을 부여하는 EffectInstance
```

일시적인 캐시와 다중 Ray 결과는 저장하지 않고 revision에서 재계산한다.

재접속 시:

```text
권위 Actor·Effect·장면 상태 복원
→ Sense Capability 재투영
→ 중요한 PerceptionRelation 복원 또는 재계산
→ 사용자별 ViewSnapshot 재생성
```

---

## 32. 성능

### Broad phase

공간 인덱스로 감각 최대 범위 안의 후보만 수집한다.

```text
observer sense bounds
→ spatial index query
→ candidate entities
```

### Narrow phase

후보에게만 다음을 수행한다.

```text
대상 필터
서명 필터
조명·가림 조회
다중 표본 시야선
은신 판정
```

### 무효화 키

```text
observer transform revision
target transform revision
sense capability revision
percealment revision
lighting field revision
obscurement revision
vision blocker revision
concealment attempt revision
DM adjudication revision
```

### 금지

- 모든 Actor 쌍을 매 프레임 검사
- 플레이어마다 전체 장면 Part Raycast
- 실제 메시 삼각형 단위 가시성 판정
- 변화가 없는데 PerceptionRelation 전체 재계산
- Fog 마스크와 Actor 탐지를 하나의 거대한 갱신 루프로 처리

---

## 33. 실패와 복구

### 규칙 형상 누락

```text
기본 단순 ruleVolume 사용
+ DM 경고
```

### 차단체 데이터 충돌

```text
indeterminate
→ 장면 정책에 따른 보수적·관대한 결과
→ DM 판정 가능
```

### 클라이언트 표시 실패

권위 PerceptionRelation은 유지한다. 클라이언트는 최신 ViewSnapshot을 다시 요청하고 표시만 복구한다.

### 대규모 장면 부하

낮은 우선순위의 탐험용 감각 갱신을 배치 처리할 수 있지만, 공격·주문·반응 TargetingQuery는 즉시 서버 재검증한다.

---

## 34. 대표 실행 사례

### 34.1 어둠 속 일반 인간

```text
normal vision
+ darkness
→ visual perception 실패

대상이 소리를 냄
→ hearing으로 presence_detected 가능
```

### 34.2 암시야 보유 Actor

```text
darkvision range 안
+ darkness
→ 감각 프로필에 따라 dim-light equivalent
→ visual perception 평가
```

### 34.3 맹시와 투명 대상

```text
normal vision
→ 투명으로 차단

blindsight
→ exact_location 또는 visual-equivalent 제공
→ TargetingPlan 요구에 따라 공격 허용
```

### 34.4 진동감지와 비행 대상

```text
tremorsense signatureRequirements
→ target touching same connected ground 필요

비행 대상
→ 조건 불충족
→ 해당 감각으로 탐지 불가
```

### 34.5 연기 속 공격

```text
visual sense
→ heavily obscured로 차단

공격자가 다른 감각으로 exact location 획득
→ 공격은 허용될 수 있음
→ 보이지 않음 관련 RollMode는 규칙 세트가 계산
```

### 34.6 은신 도적과 경비병 셋

```text
도적 ConcealmentAttempt: 17

경비병 A passive: 18
→ visually_perceived 또는 exact_location

경비병 B passive: 14
→ unaware

경비병 C blindsight 범위 안
→ 감각 기반 exact_location
```

### 34.7 빗나간 공격 후 은신 유지 Feat

```text
AttackResolved: miss
→ perception.missed_attack_reveal RulePoint
→ Feat Override 적용
→ ConcealmentAttempt 유지

다른 Stimulus가 발생하면 별도 재평가 가능
```

### 34.8 볼 수 있는 대상 주문

```text
TargetingPlan requires visually_perceived
→ hearing으로 위치만 아는 대상은 부적격
→ visual-equivalent 감각이 있으면 적격 가능
```

### 34.9 Fog가 가려진 방의 감지

```text
CurrentRevealMask 없음
+ 벽 너머 magic_detection으로 presence_detected
→ 방 지형은 계속 가림
→ 정책상 허용된 감지 마커만 표시
```

---

## 35. 필수 테스트

### 감각

1. 암시야가 없는 Actor는 어둠에서 시각 인식에 실패한다.
2. 암시야 범위 Modifier가 기존 감각 범위를 올바르게 증가시킨다.
3. 기존 암시야가 없는 Actor에게 범위 증가만 부여했을 때 정책대로 처리된다.
4. 맹시가 투명 대상의 위치를 감지한다.
5. 진동감지는 지면 비접촉 대상을 감지하지 않는다.
6. 진시야의 공개 수준이 정보 정책을 초과하지 않는다.

### 고저차·차단

7. 낮은 벽 너머 대형 대상의 일부 표본이 보여 `partially_visible`이 된다.
8. 천장이 다른 층의 시야를 차단한다.
9. 열린 문이 차단체에서 제거된다.
10. 창문은 시야를 허용하면서 효과선을 별도로 막는다.
11. 장식 소품은 시야를 차단하지 않는다.

### 은신

12. 같은 은신 대상이 관찰자마다 다른 PerceptionRelation을 가진다.
13. 능동 수색 성공은 수색한 관찰자의 관계만 갱신한다.
14. 공격 공개 TimingWindow 전에는 은신이 유지된다.
15. 빗나감 은신 유지 Override가 해당 공개 출처만 억제한다.
16. 다른 Stimulus는 별도로 은신을 깨거나 재평가한다.

### Targeting

17. `볼 수 있는 대상` 주문은 위치만 아는 대상을 거절한다.
18. 정확한 위치를 아는 보이지 않는 대상에 대한 공격은 정책상 허용된다.
19. 범위 지점 지정은 Actor 인식 없이도 가능하되 효과선을 검사한다.
20. 엄폐 무시 Feature가 시야 차단이나 효과선까지 무시하지 않는다.

### Feature·Feat

21. 감각 부여 Feature가 Capability projection을 통해 즉시 활성화된다.
22. 변신이 감각을 교체하고 종료 후 원본 감각이 복원된다.
23. 실명 억제가 시각 감각만 비활성화한다.
24. 마법적 어둠 해석 Override가 일반 어둠 규칙을 불필요하게 변경하지 않는다.
25. 공격 문맥 불리점 억제가 다른 출처의 불리점까지 제거하지 않는다.
26. 사용자 콘텐츠가 임의 엔진 함수나 ModuleScript 경로를 RulePoint로 등록하지 못한다.

### Fog·보안

27. Perception 결과가 DiscoveryMask나 CurrentRevealMask를 자동 변경하지 않는다.
28. unaware 대상의 실제 위치가 플레이어 클라이언트에 복제되지 않는다.
29. 마지막 위치 마커가 실제 최신 위치를 누설하지 않는다.
30. DM이 플레이어별 인식 결과를 진단할 수 있다.

### 성능·복구

31. 변화가 없는 관계는 캐시를 재사용한다.
32. 문 하나의 변경이 관련 공간 관계만 무효화한다.
33. 재접속 후 활성 감각과 은신 시도가 복원된다.
34. 클라이언트 표시 실패가 권위 인식 상태를 변경하지 않는다.
35. 공격 TargetingQuery는 지연된 탐험 캐시와 무관하게 즉시 재검증된다.

---

## 36. 완료 기준

이 모델의 구현은 다음을 만족해야 한다.

- Fog와 Perception이 데이터·갱신·권한 측면에서 분리되어 있다.
- 모든 감각은 `SenseCapability` 또는 등록된 확장 계약으로 표현된다.
- 은신은 관찰자별 결과를 가진다.
- 시야는 의미 차단체와 다중 규칙 표본을 사용한다.
- Feature와 Feat는 공개된 RulePoint와 Capability만으로 감각·은신 규칙을 확장할 수 있다.
- 공격, 주문과 반응이 필요한 인식 수준을 TargetingPlan에 명시한다.
- 숨겨진 Actor와 실제 위치가 권한 없는 클라이언트에 복제되지 않는다.
- 매 프레임 전체 Actor 쌍 검사가 없다.
- DM이 결과의 근거를 확인하고 명시적으로 판정할 수 있다.
