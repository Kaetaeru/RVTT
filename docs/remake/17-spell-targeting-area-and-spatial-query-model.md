# 17. 주문 대상 지정·영역·공간 질의 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`11. 공통 실행 계약과 마법 처리 모델`](11-rules-content-execution-and-spell-contract.md)
  - [`14. 주문 자원 풀과 시전 결제 모델`](14-spell-resource-pools-and-cast-payment-model.md)
  - [`16. 캠페인 물질 구성요소 정책`](16-campaign-material-component-policy.md)
  - [`ADR-0023`](decisions/ADR-0023-composable-targeting-and-spatial-query-model.md)

## 1. 문서 목적

D&D 주문의 대상 지정은 매우 다양하지만, 대부분은 다음 요소의 조합으로 환원할 수 있다.

```text
무엇을 선택하는가
+ 어디까지 선택할 수 있는가
+ 어떤 공간 형상을 만드는가
+ 누가 그 공간에 포함되는가
+ 언제 다시 포함 여부를 계산하는가
+ 어떤 효과를 누구에게 적용하는가
```

이 문서는 주문마다 별도 대상 지정 시스템을 만들지 않고, 조합 가능한 공통 계약으로 대부분의 주문을 표현하기 위한 구조를 정의한다.

적용 대상은 주문만이 아니다.

- 직업 특성
- 재주
- 무기 마스터리
- 아이템 행동
- 몬스터 능력
- 함정과 장면 상호작용

모두 같은 `TargetingPlan`과 `SpatialQuery`를 사용할 수 있다.

---

## 2. 전체 구조

```text
RuleContentDefinition
└─ TargetingPlanDefinition
   ├─ steps[]
   ├─ finalValidationPolicy
   ├─ affectedSetDefinitions[]
   └─ sceneEffectCreation?

TargetingSession
├─ executionId
├─ actorId
├─ completedSteps
├─ currentStepIndex
├─ previewState
├─ ruleSnapshot
└─ revision

TargetSelectionDraft
├─ selectedEntities
├─ selectedObjects
├─ selectedPoints
├─ selectedDirections
├─ selectedPaths
├─ selectedAreas
└─ selectedOptions

SpatialQuery
→ AffectedSet[]

RuleExecution
→ rolls, saves, damage, conditions, movement and scene effects
```

`TargetSelectionDraft`는 아직 권위 결과가 아니다. 서버가 최종 검증하고 공간 질의를 수행한 뒤 실행 트랜잭션에 고정한다.

---

## 3. TargetingStep 공통 계약

```text
TargetingStep
├─ stepId
├─ kind
├─ promptKey
├─ selectionCount
├─ selectionOrderPolicy
├─ candidateSource
├─ targetFilter
├─ validationPolicy
├─ dependencyBindings
├─ duplicatePolicy
├─ selfSelectionPolicy
├─ autoResolvePolicy
├─ dmAdjudicationPolicy
└─ revalidationPolicy
```

### selectionCount

다음을 표현할 수 있다.

- 정확히 1개
- 최소 1개, 최대 N개
- 0개 이상 선택 가능
- 시전 레벨에 따라 증가
- 능력 수정치나 숙련 보너스에 따라 증가
- 이전 단계 결과 수에 따라 결정

### dependencyBindings

이전 단계 결과를 다음 단계의 원점, 후보군 또는 크기 계산에 사용한다.

```text
step-1: 첫 생물 선택
step-2: origin = step-1.selectedEntity
        range = 30 ft
        exclude = previous selections
```

### revalidationPolicy

- `selection_only`: 선택 순간만 검사
- `before_commit`: 비용 확정 직전에 다시 검사
- `before_resolution`: 효과 해결 직전에 다시 검사
- `continuous`: 지속 효과가 활성인 동안 반복 검사
- `event_driven`: 진입, 턴 시작, 이동 종료 등 특정 사건에서 검사

---

## 4. 선택 단계 종류

### 4.1 EntitySelectionStep

생물, 캐릭터, NPC, 소환체와 기타 규칙 행위자를 선택한다.

```text
EntitySelectionStep
├─ entityKinds
├─ relationshipFilter
├─ creatureTypeFilter
├─ lifeStateFilter
├─ sizeFilter
├─ conditionFilter
├─ requiredTags
├─ excludedTags
└─ consentPolicy
```

예시:

- 자신
- 자신 이외의 아군 하나
- 볼 수 있는 적 최대 세 명
- 죽은 생물의 시체 하나
- 의지가 있는 생물 하나
- 특정 크기 이하의 야수

`ally`, `enemy`는 표시용 팀 색상이 아니라 캠페인과 전투 관계 판정에서 계산한다.

### 4.2 ObjectSelectionStep

문, 상자, 무기, 휴대 물체, 고정 구조물과 장면 오브젝트를 선택한다.

```text
ObjectSelectionStep
├─ objectKinds
├─ portabilityPolicy
├─ ownershipPolicy
├─ materialTags
├─ sizeOrVolumeLimit
├─ magicalStatePolicy
└─ interactionStateFilter
```

생물과 물체를 모두 허용하는 주문은 후보 종류를 합성하거나 선택 모드 분기를 제공한다.

### 4.3 PointSelectionStep

장면의 3차원 지점을 선택한다.

```text
PointSelectionStep
├─ surfacePolicy
├─ freeAirPolicy
├─ validVolumePolicy
├─ snapPolicy
├─ originPolicy
└─ placementClearance
```

- 바닥 표면만 가능
- 공중 지점 가능
- 보이는 지점만 가능
- 효과선만 있으면 가능
- 점유되지 않은 공간이어야 함
- 특정 높이 또는 표면 유형 필요

클라이언트 레이캐스트 결과를 그대로 신뢰하지 않고 서버 장면 데이터로 재검증한다.

### 4.4 DirectionSelectionStep

시전자 또는 선택한 원점에서 방향을 고른다.

원뿔, 선, 밀치기 방향과 부채꼴 공격에 사용한다.

```text
DirectionSelectionStep
├─ originBinding
├─ horizontalOnly
├─ verticalAngleLimits
├─ facingSnapPolicy
└─ allowedDirectionVolume
```

### 4.5 PathSelectionStep

하나 이상의 점으로 경로나 벽을 그린다.

```text
PathSelectionStep
├─ minimumPoints
├─ maximumPoints
├─ maximumTotalLength
├─ segmentPolicy
├─ selfIntersectionPolicy
├─ surfaceConformPolicy
├─ verticalPolicy
└─ obstructionPolicy
```

사용 예시:

- 직선 벽
- 꺾이는 벽
- 이동 경로를 따라 생성되는 위험 지대
- 두 지점을 잇는 광선
- 자유곡선에 가까운 환영 윤곽

정확한 자유곡선은 내부적으로 제한된 선분 집합이나 샘플링된 경로로 정규화한다.

### 4.6 AreaPlacementStep

형상과 배치를 함께 선택한다.

```text
AreaPlacementStep
├─ shapeDefinition
├─ originBinding
├─ orientationPolicy
├─ sizeFormula
├─ placementPolicy
└─ clippingPolicy
```

### 4.7 OptionSelectionStep

주문 모드, 피해 유형, 생성 형태와 같은 비공간 선택을 받는다.

예시:

- 피해 유형 선택
- 벽의 불타는 면 선택
- 소환할 생물 유형 선택
- 밀기 또는 넘어뜨리기 선택

### 4.8 DependentSelectionStep

이전 결과에 따라 종류 자체가 바뀌는 선택이다.

```text
선택한 주문 모드가 beam이면 DirectionSelectionStep
선택한 주문 모드가 burst이면 PointSelectionStep
```

분기 결과도 서버가 정의된 후보 안에서 검증한다.

---

## 5. 대상 필터

필터는 UI 후보 표시와 서버 검증에서 같은 의미를 사용한다.

```text
TargetFilter
├─ includeKinds
├─ excludeKinds
├─ relationshipPredicate
├─ creaturePredicate
├─ objectPredicate
├─ statePredicate
├─ tagPredicate
├─ sizePredicate
├─ immunityPredicate
└─ customPredicateId?
```

### 기본 필터 원칙

- 이름이나 번역 문자열로 생물 유형과 상태를 비교하지 않는다.
- 보이지 않는 대상을 후보에서 숨기는 것과 규칙상 선택 불가인 것을 구분한다.
- 면역은 대상 선택 자체를 막는 면역과 효과만 무효화하는 면역을 구분한다.
- 선택 당시 유효했지만 해결 전에 조건이 바뀔 수 있으므로 재검증 정책을 가진다.

---

## 6. 거리·시야·효과선·엄폐

이 네 개념을 하나로 합치지 않는다.

### RangePolicy

```text
RangePolicy
├─ originBinding
├─ distanceFormula
├─ measurementMode
├─ minimumRange?
├─ maximumRange
├─ touchingRequired
└─ unlimitedWithinScene
```

`measurementMode` 후보:

- 중심점 간 거리
- 점유 범위 사이 최단 거리
- 경로 거리
- 수평 거리만
- 3차원 유클리드 거리
- 규칙 세트의 격자 근사

RVTT 기본은 연속 3차원 공간이므로 실제 규칙용 점유 범위와 피트 단위 거리를 사용한다.

### VisibilityPolicy

- 시전자가 직접 볼 수 있어야 함
- 감각 중 하나로 감지하면 됨
- 정확한 위치를 알고 있으면 됨
- 시야 불필요
- 대상이 시전자를 볼 수 있어야 함

### LineOfEffectPolicy

효과가 원점에서 대상 또는 지점까지 물리적으로 전달될 수 있는지를 판정한다.

- 완전 차단 벽 통과 불가
- 창문, 틈과 투과 가능한 장벽 정책
- 특정 재질이나 마법 장벽 예외
- 원점에서 영역 중심까지만 검사
- 영역 안 각 대상까지 별도 검사

### CoverPolicy

엄폐는 선택 불가, 공격 보정, 내성 보정 또는 효과 면역으로 서로 다르게 작동할 수 있다.

```text
CoverPolicy
├─ blocksSelectionAt
├─ attackModifierPolicy
├─ saveModifierPolicy
└─ areaProtectionPolicy
```

---

## 7. 원점과 기준 좌표

주문의 사거리와 형상은 다양한 원점을 사용한다.

```text
OriginBinding
├─ caster
├─ casterFootprint
├─ selectedEntity
├─ selectedObject
├─ selectedPoint
├─ previousStepResult
├─ activeSceneEffect
└─ customOriginHandler
```

예시:

- 원뿔: 시전자 점유 범위의 가장자리
- 화염구: 선택한 지점
- 연쇄 번개 후속 대상: 첫 대상
- 오라: 지속 효과를 가진 행위자
- 포탑이나 소환체 공격: 해당 장면 오브젝트

원점은 콘텐츠 실행 중 임의로 바뀌지 않도록 선택 확정 시 스냅샷을 남긴다. 지속 오라는 현재 소유자의 위치를 따라가는 동적 바인딩을 사용할 수 있다.

---

## 8. 영역 형상

```text
AreaShapeDefinition
├─ shapeKind
├─ dimensions
├─ originAnchor
├─ orientation
├─ boundaryPolicy
├─ verticalPolicy
└─ customShapeHandlerId?
```

### Sphere

중심점과 반지름으로 정의한다.

구체 또는 규칙상 구형 폭발에 사용한다.

### Cylinder

중심, 반지름, 높이와 수직 방향으로 정의한다.

바닥에서 위로 솟는 영역, 기둥형 효과와 일부 날씨 효과에 사용한다.

### Cone

원점, 방향, 길이와 각도로 정의한다.

규칙 원문이 폭을 길이와 동일하게 취급하는 경우 규칙 세트가 각도 또는 단면 계산을 제공한다.

### Line

원점, 방향, 길이와 폭으로 정의한다.

단순한 무한히 얇은 선이 아니라 규칙상 폭을 가진 직육면체 또는 캡슐형 질의로 구현할 수 있다.

### Cube / Box

중심 또는 한 면의 원점, 폭·높이·깊이와 방향을 가진다.

### Wall

경로, 높이, 두께와 세그먼트별 제한을 가진다.

```text
WallShape
├─ pathSegments
├─ height
├─ thickness
├─ maximumLength
├─ segmentLengthPolicy
└─ sideSelection?
```

### Ring

내부 반지름과 외부 반지름 사이의 영역이다.

### Aura

행위자나 오브젝트에 붙어서 이동하는 동적 형상이다.

### Footprint

토큰이나 오브젝트의 규칙용 점유 모양을 확장하거나 그대로 사용한다.

### PathVolume

이동 경로나 그려진 선을 따라 일정 폭과 높이를 가진 영역을 만든다.

### CompositeShape

여러 기본 형상의 합집합, 교집합 또는 차집합이다.

```text
CompositeShape
├─ union
├─ intersection
└─ subtraction
```

복잡한 고리, 가운데가 빈 벽, 여러 폭발 지점과 선택적 안전지대를 표현할 수 있다.

공통 부울 조합으로 명확하지 않은 형상만 전용 처리기를 사용한다.

---

## 9. 경계 포함과 토큰 점유 범위

토큰은 중심점 하나가 아니라 규칙용 점유 범위를 가진다.

```text
SpatialOccupant
├─ actorId or objectId
├─ occupancyShape
├─ transform
├─ sizeCategory
└─ verticalExtent
```

영역 포함 정책 후보:

- 점유 범위가 조금이라도 교차하면 포함
- 중심점이 영역 안에 있어야 포함
- 점유 범위의 일정 비율 이상 포함
- 규칙용 기준점이 포함되어야 함
- 콘텐츠별 특수 정책

기본 정책은 규칙 세트가 정하고 주문이 명시적으로 변경할 수 있다.

클라이언트 렌더 메시의 크기나 투명 파츠를 포함 판정에 사용하지 않는다.

---

## 10. SpatialQuery

```text
SpatialQueryRequest
├─ sceneId
├─ queryOrigin
├─ shapeSnapshot
├─ occupantKinds
├─ targetFilter
├─ lineOfEffectPolicy
├─ coverPolicy
├─ inclusionPolicy
├─ exclusionReferences
└─ ruleRevision
```

결과:

```text
AffectedSet
├─ affectedSetId
├─ members[]
├─ excludedMembers[]
├─ inclusionReasons
├─ coverResults
├─ lineOfEffectResults
└─ queryRevision
```

### 서버 권한

클라이언트는 미리보기 대상 목록을 계산할 수 있지만 실행 요청에는 선택 입력과 형상 파라미터만 제출한다.

서버가 최신 장면 상태로 `AffectedSet`을 다시 계산한다.

### 성능

모든 장면 오브젝트를 선형 순회하지 않는다.

- 공간 인덱스에서 형상의 넓은 후보군 조회
- 단순 경계 상자로 1차 거르기
- 정확한 형상 교차 검사
- 필요한 대상에만 효과선과 엄폐 검사
- 정적 장면 차단 구조 캐시 사용

지속 영역은 매 프레임 전체 질의를 수행하지 않는다.

- 공간 셀 진입과 이탈 이벤트
- 토큰 이동 완료
- 턴 시작·종료
- 장면 오브젝트 변경
- 효과 크기나 위치 변경

등 필요한 사건에서만 갱신한다.

---

## 11. 다중 AffectedSet

한 주문은 여러 효과 대상 집합을 가질 수 있다.

```text
AffectedSetDefinition[]
├─ primaryTargets
├─ secondaryTargets
├─ alliesInArea
├─ enemiesInArea
├─ objectsInArea
├─ terrainCells
└─ excludedSafeTargets
```

예시:

- 적에게 피해를 주고 아군에게 임시 HP 제공
- 생물에게 피해를 주고 가연성 물체에 불을 붙임
- 첫 대상은 전체 피해, 주변 대상은 절반 피해
- 선택한 일부 대상을 영역 효과에서 제외

각 집합은 별도 필터, 공간 정책과 효과 레시피를 가진다.

---

## 12. 선택 대상과 자동 영향 대상

### 직접 선택

플레이어가 특정 대상을 명시적으로 선택한다.

### 공간 자동 선택

배치한 영역과 서버 공간 질의로 대상이 결정된다.

### 규칙 자동 선택

가장 가까운 대상, 무작위 대상, HP가 가장 낮은 대상처럼 규칙이 선택한다.

```text
SelectionResolver
├─ nearest
├─ farthest
├─ random
├─ lowestCurrentHp
├─ highestAttribute
├─ orderedByCaster
└─ customResolver
```

자동 선택의 후보군과 결과는 서버 로그에 남긴다.

### DM 판정 선택

서술 조건을 시스템이 객관적으로 판정할 수 없으면 후보와 이유를 DM에게 보여주고 확정받는다.

---

## 13. 선택 순서와 동시 선택

주문에 따라 대상 선택 순서가 중요할 수 있다.

- 순서 없음
- 첫 대상만 특별함
- 이전 대상으로부터 다음 대상을 선택
- 같은 대상을 다시 선택 가능
- 각 대상에 다른 모드 배정
- 선택 완료 뒤 전체를 동시에 해결
- 선택 순서대로 하나씩 해결

```text
SelectionOrderPolicy
├─ unordered
├─ ordered
├─ first_is_primary
├─ chained
└─ per_target_configuration
```

효과 해결 순서는 대상 선택 순서와 별개 필드로 둔다.

---

## 14. 연쇄 주문

연쇄 주문은 다음 공통 구조로 표현한다.

```text
step-1 EntitySelection
├─ count: 1
└─ range origin: caster

step-2 EntitySelection
├─ count: formula
├─ range origin: step-1 entity
├─ exclude previous selections
└─ optional ordered selection
```

후속 대상이 첫 대상이 사라진 뒤에도 유지되는지는 주문의 재검증 정책으로 결정한다.

자동으로 튀는 주문은 두 번째 단계를 `SelectionResolver.nearest` 등으로 처리한다.

---

## 15. 상위 레벨 시전과 스케일링

대상 수, 범위와 형상 크기는 수식으로 확장할 수 있다.

```text
ScalingBindings
├─ selectedTargetMaximum
├─ shapeRadius
├─ shapeLength
├─ wallSegmentCount
├─ summonCount
└─ effectIntensity
```

수식 입력:

- 기본 주문 레벨
- 실제 시전 레벨
- 슬롯 초과 레벨
- 시전자 레벨
- 특정 직업 레벨
- 시전 능력 수정치
- 숙련 보너스

최종 계산값을 주문 정의에 중복 저장하지 않고 실행 시 파생한다.

---

## 16. 지속 영역

지속 영역은 `SceneEffectInstance`를 만든다.

```text
SceneEffectInstance
├─ sceneEffectId
├─ sourceExecutionId
├─ sourceContentId
├─ ownerActorId?
├─ shapeDefinitionSnapshot
├─ transformBinding
├─ durationState
├─ concentrationLink?
├─ visibilityState
├─ triggerDefinitions[]
├─ currentOccupants
└─ revision
```

### transformBinding

- 고정된 장면 위치
- 시전자에게 부착
- 대상에게 부착
- 이동 가능한 장면 오브젝트에 부착
- 매 턴 재배치 가능

### triggerDefinitions

- 영역이 처음 생성될 때
- 처음 들어올 때
- 턴 중 처음 들어올 때
- 턴을 시작할 때
- 턴을 끝낼 때
- 영역을 통과할 때
- 영역 안에서 행동할 때
- 영역이 사라질 때

같은 대상에게 한 턴에 여러 번 적용되는 것을 막기 위한 `applicationLedger`를 효과 인스턴스가 가질 수 있다.

---

## 17. 벽과 장면 오브젝트

벽 주문은 단순한 AOE가 아니라 규칙용 장면 오브젝트를 생성한다.

```text
RuleSceneObject
├─ objectId
├─ geometry
├─ visualPrefabId
├─ navigationImpact
├─ lineOfSightImpact
├─ lineOfEffectImpact
├─ collisionPolicy
├─ damageAndConditionTriggers
├─ destructibility
└─ durationState
```

주문마다 다음을 선택적으로 사용한다.

- 이동 차단
- 시야 차단
- 효과선 차단
- 통과 시 피해
- 근처에서 피해
- 파괴 가능
- 세그먼트별 HP
- 특정 생물만 통과 가능

시각 VFX만 배치하고 규칙 판정을 별도 수동 처리하지 않도록 의미 데이터를 함께 생성한다.

---

## 18. 소환과 생성

소환 주문의 대상 지정은 보통 다음 조합이다.

```text
OptionSelectionStep: 소환 유형
PointSelectionStep: 등장 지점
Area or clearance validation
CreationDefinition: 생성할 Actor 또는 RuleSceneObject
```

생성 시 검증:

- 지점이 사거리 안인가
- 허용된 표면이나 공간인가
- 소환체 점유 범위가 들어가는가
- 다른 점유 범위와 불법 중첩하지 않는가
- 시야 또는 효과선 요구를 충족하는가
- 캠페인과 장면의 소환 제한을 충족하는가

여러 소환체는 개별 지점 선택, 자동 분산 또는 형상 안 자동 배치를 지원할 수 있다.

---

## 19. 환영과 자유 형상

환영은 완전 자동 판정이 어려워도 공통 구조를 최대한 사용한다.

```text
OptionSelectionStep: 환영 종류 또는 프리셋
Point / Path / AreaPlacementStep: 위치와 크기
IntentPayload: 플레이어가 표현하려는 내용
SceneEffectInstance: 시각·청각·표시 범위
DMAdjudicationPolicy: 상호작용과 믿음 판정
```

`IntentPayload`는 규칙 실행 코드가 자유 문장을 파싱하여 자동 효과를 만들기 위한 것이 아니다.

DM과 플레이어에게 의도를 전달하고 로그에 남기며, 크기·사거리·지속시간 같은 객관적 제한은 시스템이 자동 검사한다.

---

## 20. 순간이동과 장면 전환

같은 장면 안의 순간이동은 `PointSelectionStep`과 배치 유효성 검사로 처리한다.

다른 장면, 세계 지도 또는 서술적 목적지는 전용 목적지 선택 계약을 사용한다.

```text
DestinationSelection
├─ currentScenePoint
├─ knownLocation
├─ linkedSceneAnchor
├─ namedCampaignLocation
├─ describedDestination
└─ randomOrMishapDestination
```

다른 장면으로 이동하는 효과는 일반 공간 질의 뒤에 씬 전환 트랜잭션을 사용한다.

자유롭게 설명한 목적지의 유효성, 오차와 사고 결과는 DM 판정 또는 전용 처리기가 담당한다.

---

## 21. 대상 이동·사망·소실 시 재검증

선택 이후 상태가 바뀔 수 있다.

```text
선택 완료
→ 반응 발생
→ 대상 이동 또는 사망
→ 비용 확정
→ 효과 해결
```

콘텐츠는 다음 정책 중 하나를 명시한다.

- 대상이 불법이 되면 전체 시전 취소
- 해당 대상만 제외하고 나머지 해결
- 마지막 유효 위치를 사용
- 선택 당시 대상을 계속 추적
- 새 대상을 다시 선택
- DM 판정 요청

재선택이 허용되더라도 비용 확정 시점과 입력 시간 제한을 공통 실행 계약에서 관리한다.

---

## 22. 자신·아군·적군 제외

영역 주문이 자동으로 아군을 피한다고 가정하지 않는다.

- 모든 적격 대상 포함
- 시전자가 선택한 N명 제외
- 시전자만 제외
- 아군 자동 제외
- 특정 태그나 효과를 가진 대상 제외

등을 명시적인 `AffectedSetDefinition`과 제외 선택 단계로 표현한다.

```text
AreaPlacementStep
→ Exclusion EntitySelectionStep
→ SpatialQuery
→ exclusionReferences 제거
```

---

## 23. 클라이언트 미리보기

클라이언트는 사용자 경험을 위해 다음을 즉시 표시한다.

- 유효·무효 후보 하이라이트
- 사거리 경계
- 원뿔, 선, 구체와 벽 고스트
- 예상 포함 대상
- 효과선과 완전 엄폐 경고
- 형상 크기와 시전 레벨 변화
- 선택한 대상 수와 남은 선택 수
- 현재 단계와 다음 단계

미리보기는 권위 결과가 아니다.

서버 결과와 차이가 생기면:

- 차이 원인을 표시
- 실행 전이면 미리보기 갱신
- 확정 과정이면 서버 결과를 기준으로 재확인
- 부정행위나 오래된 revision이면 요청 거부

---

## 24. 입력 문법

기존 공통 입력 교과서를 따른다.

- 마우스: 후보, 지점, 방향과 경로 지정
- `E`: 현재 단계 확정 또는 전체 실행 승인
- `Q`: 현재 단계 취소 또는 이전 단계로 이동
- 숫자 슬롯: 주문 모드나 제한된 선택지가 있을 때만 사용
- 우클릭 또는 지정 입력: 선택 제거와 경로 마지막 점 취소

복잡한 주문도 별도 키를 임의로 추가하기보다 화면의 현재 단계 문법을 따른다.

---

## 25. 서버 검증

서버는 최소한 다음을 검증한다.

- 제출한 단계와 순서가 정의와 일치하는가
- 선택 수와 중복 정책이 올바른가
- 모든 참조가 현재 장면과 실행에 존재하는가
- 선택 대상이 필터를 통과하는가
- 사거리 원점과 거리 계산이 올바른가
- 시야, 효과선과 엄폐 정책을 충족하는가
- 점, 경로와 영역 배치가 장면 안에서 유효한가
- 크기와 세그먼트 수가 수식 결과를 넘지 않는가
- 형상이 허용된 표면, 높이와 방향을 따르는가
- 실행 중 장면 revision이 바뀌었는가
- 비용 확정 전에 재검증이 필요한가
- 클라이언트가 제출한 예상 AffectedSet을 권위 데이터로 사용하지 않는가

---

## 26. 오류와 취소

대상 지정 세션은 명시적으로 취소 가능해야 한다.

- 사용자 취소
- 대상이나 장면 소실
- 사거리와 시야 변화
- 턴 종료
- 행동 불가 상태 발생
- DM 거절
- 서버 검증 실패
- 시간 제한 만료

비용 확정 전이면 예약을 해제하고 실행을 종료한다.

비용 확정 후 발생한 무효화는 주문 규칙에 따라 실패, 부분 해결 또는 환불 트랜잭션으로 처리한다.

---

## 27. 대표 주문 패턴

### 접촉 단일 대상

```text
EntitySelectionStep
├─ count: 1
├─ range: touch
└─ filter: creature
```

### 원거리 복수 대상

```text
EntitySelectionStep
├─ count: 1..N
├─ range: caster based
├─ visibility: required
└─ duplicates: forbidden
```

### 지점 중심 폭발

```text
PointSelectionStep
└─ range and line of effect

AffectedSetDefinition
└─ Sphere around selected point
```

### 시전자 원점 원뿔

```text
DirectionSelectionStep
└─ origin: caster footprint

AffectedSetDefinition
└─ Cone
```

### 직선 광선

```text
DirectionSelectionStep
└─ origin: caster

AffectedSetDefinition
└─ Line with length and width
```

### 경로형 벽

```text
PathSelectionStep
└─ maximum total length

SceneEffectCreation
└─ Wall RuleSceneObject
```

### 연쇄 대상

```text
EntitySelectionStep: primary
EntitySelectionStep: secondary, origin primary, excludes selected
```

### 소환

```text
OptionSelectionStep
PointSelectionStep
CreationDefinition
```

### 오라

```text
SceneEffectInstance
└─ Aura bound to actor

EventDriven SpatialQuery
└─ enter, leave, turn start
```

### 제외 대상을 고르는 광역기

```text
AreaPlacementStep
EntitySelectionStep: exclusions from preview candidates
SpatialQuery minus exclusions
```

### 자유 환영

```text
Area or Path placement
IntentPayload
DM adjudication triggers
```

---

## 28. 전용 처리기가 필요한 기준

다음 조건을 만족할 때만 `targetingHandlerId`를 사용한다.

- 기본 선택 단계의 순서와 의존성으로 표현할 수 없음
- 기본 형상 또는 CompositeShape로 공간을 표현할 수 없음
- 후보 조건이 구조화된 필터로 판정 불가능
- 다른 장면이나 캠페인 지식이 필요함
- 서술적 의도에 대한 DM 판정이 핵심임

전용 처리기는 제한된 인터페이스만 사용한다.

```text
TargetingExtensionContext
├─ read validated prior selections
├─ request standard selection step
├─ request DM adjudication
├─ create custom preview descriptor
├─ submit normalized geometry
└─ return structured selection result
```

RemoteEvent, Workspace, 인벤토리와 캐릭터 저장 데이터를 직접 수정하지 않는다.

---

## 29. 테스트 매트릭스

최소한 다음 패턴을 수직 검증한다.

1. 접촉 단일 대상
2. 시야가 필요한 원거리 복수 대상
3. 지점 중심 구체
4. 시전자 원점 원뿔
5. 폭이 있는 직선
6. 회전 가능한 입방체
7. 꺾이는 벽과 세그먼트 제한
8. 첫 대상에서 이어지는 연쇄
9. 선택 제외가 있는 광역기
10. 이동하는 오라
11. 턴 시작에 작동하는 지속 영역
12. 소환체 배치와 점유 검사
13. 물체와 생물을 함께 다루는 주문
14. 대상 이동 후 재검증
15. 환영의 객관 제한과 DM 판정
16. 다른 장면 목적지의 순간이동

각 테스트는 클라이언트 미리보기, 서버 결과, 로그, 취소, 재접속과 장면 revision 충돌을 포함한다.

---

## 30. 명시적인 비목표

- 주문마다 개별 대상 지정 UI를 만들지 않는다.
- `single`, `aoe`, `self` 세 종류만으로 모든 주문을 표현하지 않는다.
- 클라이언트가 보낸 영향 대상 목록을 신뢰하지 않는다.
- 토큰 렌더 메시의 실제 파츠를 영역 판정에 사용하지 않는다.
- 지속 영역을 매 프레임 전체 장면 순회로 갱신하지 않는다.
- 환영과 예언의 서술 결과를 자유 문장 파싱으로 자동 판정하지 않는다.
- 벽과 소환체를 규칙 없는 VFX로만 생성하지 않는다.

---

## 31. 다음 단계

대상과 공간 규약 다음에는 **효과 해결 레시피**를 정해야 한다.

```text
AffectedSet
→ 공격 굴림 또는 내성 굴림
→ 피해·회복·상태·이동
→ 성공·실패별 분기
→ 반복 판정과 지속 효과
```

다음 문서에서는 피해, 회복, 내성 절반, 다중 피해 유형, 상태 적용, 강제 이동, 반복 내성과 면역·저항을 하나의 조합형 `EffectRecipe`로 정형화한다.