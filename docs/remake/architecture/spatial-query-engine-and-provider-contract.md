# Spatial Query Engine과 Provider 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 권위 Query별 기본 연산 예산
  - Snapshot Query Cache의 메모리 상한
  - 부동소수점 경계 비교 epsilon
  - 첫 구현에서 지원할 CompositeShape 깊이
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0023`](../decisions/ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0055`](../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md)
- 관련 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`주문 대상 지정·영역·공간 질의 모델`](../systems/rules/spell-targeting-area-and-spatial-query-model.md)
  - [`시야·감각·은신·탐지 모델`](../systems/perception/visibility-senses-stealth-and-detection-model.md)
  - [`이동 의미 레이어 자동 제작 파이프라인`](../systems/navigation/navigation-authoring-pipeline.md)
  - [`공통 기반 계약 공백 감사`](../audits/cross-system-foundation-contract-gap-audit.md)

## 1. 목적

Spatial Query Engine은 RVTT의 권위 월드 상태에 공간 질문을 제출하는 유일한 공통 창구다.

다음 시스템은 거리, 포함, 차단, 엄폐, 점유와 공간 후보를 독자적으로 계산하지 않는다.

- Rules와 Recipe
- Targeting과 영역 효과
- Runtime Navigation
- Perception과 Fog Assist
- Interaction
- Hazard와 Trigger
- AI
- DM Quick Action
- 배치·소환·순간이동 검증

Spatial Query의 목적은 하나의 거대한 범용 함수를 만드는 것이 아니다. 서로 다른 질문이 같은 Snapshot, 좌표계, 형상, 경계 정책, 정렬 규칙과 실패 정책을 공유하도록 만드는 것이다.

## 2. 사용자 결과

내부 구조는 다음 결과를 보장하기 위해 존재한다.

- 주문 미리보기와 실제 적용 대상이 가능한 한 일치한다.
- 같은 벽과 문이 이동, 시야, 효과선과 엄폐에서 모순된 결과를 내지 않는다.
- DM은 거리 계산 방식이나 내부 공간 Index를 설정하지 않아도 된다.
- Scene Editor에서 Navigation Polygon, Query Volume과 Clearance를 일상적으로 수동 작성하지 않는다.
- 플레이어 입력은 내부 Query 복잡성 때문에 눈에 띄게 지연되지 않는다.
- 규칙 결과가 이상할 때 Query Trace로 원인을 확인할 수 있다.
- 롤백과 리플레이가 동일한 Snapshot에서 동일한 공간 결과를 얻는다.

## 3. 책임 경계

### 3.1 Spatial Query가 소유하는 책임

- Snapshot에 바인딩된 읽기 전용 공간 조회
- 좌표, Anchor와 Shape 정규화
- Runtime Scene Index를 사용한 후보 수집
- 정확한 형상 교차와 경계 포함 판정
- 거리와 가장 가까운 점 계산
- Line of Sight, Line of Effect와 Cover의 공간 증거 계산
- 점유·배치·단일 이동 구간 통과 가능성 검사
- Rule Volume, Interaction 후보와 공간 사건 후보 조회
- 결과의 결정적 정렬
- Query Budget, Cache와 Trace
- 권한에 맞는 결과 공개 범위 적용

### 3.2 Spatial Query가 소유하지 않는 책임

- Actor, 문, 오브젝트와 효과의 상태 변경
- 전체 경로 탐색과 이동 실행
- 감각 Capability, 은신 판정과 지각 대항 판정
- 공격 보너스, 내성 보너스와 피해 계산
- 상호작용 가능 여부의 비공간 권한·상태 판정
- 클라이언트 UI와 Presentation
- Scene Source 편집
- Runtime Scene 컴파일과 영구 저장

다음 구분을 유지한다.

```text
Spatial Query
→ 공간 증거와 후보를 계산

Rules / Perception / Interaction
→ 그 증거를 규칙 의미로 해석

Command / CommitGroup
→ 권위 상태를 변경
```

## 4. 권위 Snapshot 계약

모든 권위 Query는 하나의 `RuntimeSceneSnapshotLease`에 고정된다.

```text
RuntimeSceneSnapshotLease
├─ sceneId
├─ snapshotId
├─ worldRevision
├─ layerRevisions
│  ├─ navigationRevision
│  ├─ visibilityRevision
│  ├─ interactionRevision
│  ├─ ruleRevision
│  ├─ entityRevision
│  └─ disclosureRevision
├─ rulesetVersion
├─ acquiredAtServerSequence
└─ leasePolicy
```

규칙:

- 하나의 Query는 실행 도중 다른 Snapshot으로 넘어가지 않는다.
- 여러 Provider가 참여해도 같은 Lease를 사용한다.
- Query Result에는 `snapshotId`와 `worldRevision`을 포함한다.
- 서로 다른 Snapshot에서 얻은 결과를 하나의 권위 판정으로 조용히 합치지 않는다.
- 실행 중 Snapshot이 오래되어도 Query 자체는 해당 Snapshot에서 일관되게 끝난다.
- Commit 직전 최신 상태 검사가 필요한 콘텐츠는 별도 재검증 정책으로 새 Snapshot Query를 수행한다.
- 롤백과 리플레이는 역사적 Snapshot Lease를 사용할 수 있다.
- 클라이언트 예측 Snapshot은 권위 Snapshot과 다른 타입 또는 authority marker를 가진다.

## 5. Spatial Reference와 Anchor

Query는 불투명한 주문 Context만 받지 않는다. 실제 공간 입력은 타입 있는 `SpatialReference`로 명시한다.

```text
SpatialReference
├─ PointReference
├─ EntityAnchorReference
├─ ObjectAnchorReference
├─ VolumeAnchorReference
├─ PathReference
└─ BoundReference
```

### 5.1 PointReference

- `sceneId`
- Scene 좌표계의 3차원 위치
- 좌표 단위
- 선택 표면 또는 자유 공간 여부
- 생성한 입력의 출처

직접 좌표 사용은 허용한다. 단, Scene 좌표계와 단위가 명시되어야 하며 서버가 Snapshot에 투영·검증한다.

### 5.2 EntityAnchorReference

Entity의 시각 Mesh 중심을 직접 사용하지 않는다.

```text
EntityAnchorReference
├─ entityId
├─ expectedEntityRevision?
├─ anchorProfileId
└─ anchorSelector
```

`anchorSelector` 예시:

- occupancy_center
- occupancy_boundary_nearest
- vision_origin
- effect_origin
- interaction_origin
- upper_body_sample
- ground_contact
- custom_registered

### 5.3 BoundReference

Recipe BindingStore나 다른 실행 결과에 저장된 SpatialReference를 참조한다.

BoundReference를 해석한 뒤에도 결과는 같은 Snapshot의 타입 있는 Reference로 정규화한다.

## 6. 공통 Shape 계약

Runtime Scene과 Query는 시각 Mesh 대신 제한된 규칙용 형상을 사용한다.

초기 기본 형상:

```text
Point
Segment
Ray
Sphere
Capsule
Cylinder
OrientedBox
ConvexPolygonPrism
PolylineVolume
FootprintExtrusion
CompositeShape
```

### 6.1 CompositeShape

다음 연산만 지원한다.

- union
- intersection
- subtraction

CompositeShape는 컴파일 또는 Query 정규화 과정에서 깊이와 총 Primitive 수 제한을 검사한다.

### 6.2 형상 권위

- 원본 Mesh의 삼각형 전체를 일반 규칙 Query 입력으로 사용하지 않는다.
- Scene Compiler가 Mesh와 Semantic Profile을 Runtime Primitive, blocker와 field로 변환한다.
- 특수 형상이 필요하면 등록된 Shape Provider를 사용한다.
- 형상 Provider도 Query Budget과 결정성 규약을 우회하지 않는다.

## 7. Query Context

모든 Query는 명시적인 Context를 가진다.

```text
SpatialQueryContext
├─ snapshotLease
├─ queryId
├─ sourceExecutionId?
├─ requesterRef?
├─ rulesetId
├─ authorityMode
├─ disclosureScope
├─ budgetProfile
├─ tracePolicy
└─ cancellationToken
```

### authorityMode

```text
authoritative
preview
historical
simulation
```

- `authoritative`: 서버 규칙 판정과 Commit 준비에 사용
- `preview`: 클라이언트 또는 서버 미리보기에 사용하며 권위 결과가 아님
- `historical`: 롤백·리플레이·감사에 사용
- `simulation`: AI, Scene 검증과 자동 주행 검사에 사용

### disclosureScope

Query 계산 권한과 결과 공개 권한을 분리한다.

서버 내부 Query는 비밀 정보를 포함한 전체 결과를 계산할 수 있지만, 플레이어에게 반환되는 View Result는 공개 가능한 정보만 포함한다.

## 8. Query 종류

공개 Query는 타입 있는 종류로 등록한다. 하나의 자유형 문자열 Query가 모든 동작을 표현하지 않는다.

### 8.1 Geometry Query

- `MeasureDistance`
- `MeasureHeightDifference`
- `FindClosestPoints`
- `Intersects`
- `Contains`
- `ProjectToSurface`
- `SampleAlongSegment`

`MeasureDistance`는 측정 정책을 명시한다.

```text
center_to_center
boundary_to_boundary
anchor_to_anchor
horizontal_only
three_dimensional
```

전체 이동 경로의 길이는 Geometry Query가 아니라 Navigation Planner가 계산한다.

### 8.2 Candidate Query

- `FindEntitiesInShape`
- `FindObjectsInShape`
- `FindVolumesInShape`
- `FindPortalsInShape`
- `FindNearestCandidates`

Candidate Query는 넓은 후보를 반환할 수 있지만, Rules가 최종 대상 목록으로 사용하려면 필요한 Filter와 공간 정책을 같은 Query Plan에 포함해야 한다.

### 8.3 Occupancy와 Placement Query

- `CanOccupy`
- `FindOccupancyBlockers`
- `FindNearestValidPlacement`
- `CanTraverseSegment`
- `FindContactManifold`
- `FindSupportingSurface`

이 Query는 소환, 순간이동, 토큰 배치, 밀기 결과와 이동 실행의 짧은 구간 검증에 사용한다.

### 8.4 Visibility Evidence Query

- `EvaluateLineOfSight`
- `EvaluateLineOfEffect`
- `EvaluateCover`
- `SampleRuleLighting`
- `SampleObscurement`
- `FindVisibilityBlockers`

Spatial Query는 공간 증거를 반환한다.

```text
LineOfSightEvidence
├─ clearSamples
├─ blockedSamples
├─ blockerRefs
├─ transmissionTags
└─ geometryOutcome
```

최종적으로 관찰자가 대상을 인식하는지는 Perception Engine이 감각, 은신, 투명, 지각 판정과 함께 결정한다.

### 8.5 Rule Field Query

- `FindRuleFieldsAtPoint`
- `FindRuleFieldsInShape`
- `EvaluatePathFieldCrossings`
- `FindEnteredAndExitedVolumes`
- `SampleTerrainCost`
- `FindHazardCandidates`

Aura, 어려운 지형, 위험 지역, 조명, 가림과 Trigger Volume이 이 계열을 사용한다.

### 8.6 Interaction Spatial Query

- `FindInteractableCandidates`
- `MeasureInteractionReach`
- `FindInteractionBlockers`
- `FindFacingCandidates`

공간상 가까운 후보라는 사실만 반환한다. 잠금 상태, 소유권, 사용 횟수와 권한은 Interaction 시스템이 판정한다.

### 8.7 Navigation Support Query

- `ProjectToTraversalDomain`
- `CanEnterTraversalPortal`
- `SampleTraversalCost`
- `ValidatePathSegment`
- `FindLocalAvoidanceBlockers`

이 Query는 Runtime Navigation이 사용한다. 전체 `FindPath`와 `TravelDistance`는 Navigation Planner의 책임이다.

## 9. Query Request 구조

각 Query 종류는 자신의 타입 있는 Request를 가지지만 공통 요소는 동일하다.

```text
SpatialQueryRequest
├─ queryTypeId
├─ schemaVersion
├─ origins[]
├─ shapes[]
├─ filters[]
├─ policies
├─ exclusions[]
├─ requestedEvidence
└─ resultLimit
```

### 9.1 Filter

Filter는 공간 후보 수집 후 규칙 적격성을 제한한다.

- entityKind
- relationship
- creatureType
- lifecycleState
- tags
- size category
- source ownership
- effect immunity candidate
- custom registered predicate

Filter는 번역 문자열과 Model 이름을 비교하지 않는다.

### 9.2 Policy

공통 Policy:

- boundary inclusion
- distance measurement
- line of sight
- line of effect
- cover sampling
- occupancy overlap
- vertical handling
- scene boundary
- hidden information disclosure

Query Type이 지원하지 않는 Policy를 받으면 무시하지 않고 구조화된 오류를 반환한다.

## 10. Provider 구조

Rules와 Recipe는 개별 Provider를 직접 호출하지 않는다.

```text
Rules / Recipe / Perception / Navigation
→ SpatialQueryService
→ QueryPlanner
→ ProviderRegistry
→ Runtime Scene Layer Providers
```

### 10.1 SpatialQueryService

소유 책임:

- Request schema 검증
- Snapshot Lease 검증
- Query Plan 생성
- 예산 부여
- Cache 조회
- Provider 호출 순서 관리
- 결과 결합과 결정적 정렬
- disclosure 적용
- Trace와 진단

### 10.2 QueryPlanner

Query 종류와 정책을 고정된 실행 계획으로 변환한다.

예시:

```text
FindEntitiesInSphere
→ EntitySpatialIndex broad phase
→ exact sphere/occupancy intersection
→ TargetFilter
→ optional line-of-effect evidence
→ stable ordering
```

QueryPlanner는 Scene 상태를 변경하지 않는다.

### 10.3 Provider

초기 Provider 범주:

```text
EntitySpatialProvider
GeometryProvider
NavigationDomainProvider
VisibilityProvider
RuleFieldProvider
InteractionSpatialProvider
DisclosureProvider
```

Provider 계약:

- 하나 이상의 명시적 Query Capability를 등록한다.
- 하나의 Snapshot Lease만 읽는다.
- Roblox Instance를 결과로 반환하지 않는다.
- 상태를 변경하지 않는다.
- Remote와 UI를 호출하지 않는다.
- 자체적으로 무제한 재귀 Query를 실행하지 않는다.
- 소모한 결정적 작업량을 Budget Tracker에 보고한다.
- 실패를 nil이나 빈 목록으로 숨기지 않는다.

### 10.4 Provider 등록

- 신뢰된 서버 코드만 등록한다.
- 부팅 중 등록하고 콘텐츠 로드 전에 Registry를 동결한다.
- 같은 Query Capability를 조용히 덮어쓰지 않는다.
- 대체 Provider는 명시적 우선순위와 호환 버전을 가져야 한다.
- Plugin Provider는 Core Query의 권위 의미를 변경하려면 별도 ADR과 ruleset opt-in이 필요하다.

## 11. 실행 파이프라인

```text
1. Context와 Request schema 검증
2. Snapshot Lease와 참조 revision 검증
3. 좌표, Anchor, 단위와 Shape 정규화
4. Query Plan 선택
5. Broad phase 후보 수집
6. Exact geometry와 boundary 판정
7. Visibility·effect·cover·field 증거 계산
8. Filter와 exclusion 적용
9. 공개 범위 정제
10. 결정적 정렬과 제한 검사
11. Immutable Result 생성
12. Cache와 선택적 Trace 기록
```

Query 도중 상태가 바뀌어도 2단계에서 고정한 Snapshot을 사용한다.

## 12. 좌표와 단위

### 12.1 Runtime 좌표

Runtime Geometry는 Roblox Scene 좌표와 호환되는 stud 단위를 사용한다.

### 12.2 규칙 거리

규칙에 공개되는 기본 거리 단위는 feet다.

```text
4 studs = 5 feet
1 stud = 1.25 feet
```

단위 변환은 공통 Unit 계약을 사용한다. 시스템별 상수를 복사하지 않는다.

### 12.3 비교와 표시

- 권위 비교는 변환 전후의 정규화된 실수 값으로 수행한다.
- UI 반올림 값으로 사거리와 포함 여부를 판정하지 않는다.
- 경계 비교에는 공통 epsilon과 boundary policy를 사용한다.
- Query Result는 원본 측정값과 규칙 단위를 함께 추적할 수 있다.

## 13. 점유와 Clearance

`ClearanceWidth`, `ClearanceHeight`를 Scene Object의 수동 속성으로 저장하지 않는다.

Actor와 이동 가능 오브젝트는 `SpatialBodyProfile`을 가진다.

```text
SpatialBodyProfile
├─ occupancyShape
├─ verticalExtent
├─ contactProfile
├─ stanceVariants
├─ squeezePolicy
└─ movementConfigurationRefs
```

Runtime Scene은 다음 파생 데이터를 제공할 수 있다.

- obstacle distance field
- vertical free-span field
- supporting surface index
- traversal portal geometry
- common body profile용 configuration-space cache
- 동적 장애물 occupancy index

규칙:

- Small, Medium, Large 같은 크기 등급만으로 통과 가능성을 확정하지 않는다.
- 실제 Query는 현재 `SpatialBodyProfile`과 자세·변신·Squeeze 상태를 사용한다.
- 자주 쓰는 Body Profile은 캐시할 수 있지만 크기별 NavMesh를 권위 원본으로 고정하지 않는다.
- Scene Editor에서 DM은 Body Profile별 통로 폭과 머리 공간을 직접 입력하지 않는다.
- 자동 분석이 확정하지 못한 예외만 Semantic Override로 처리한다.

## 14. Query Result와 Evidence

모든 Result는 불변 값 객체다.

```text
SpatialQueryResult
├─ queryId
├─ queryTypeId
├─ snapshotId
├─ worldRevision
├─ queryHash
├─ status
├─ items[]
├─ evidence[]
├─ excluded[]?
├─ costReport
├─ traceId?
└─ truncationState
```

Result item은 Runtime ID와 revision을 사용하며 Roblox Instance를 포함하지 않는다.

### 14.1 Evidence

Query Result는 필요한 경우 단순 true/false 외의 근거를 반환한다.

예시:

- 가장 가까운 두 경계점
- 차단한 Object ID
- 통과한 Portal ID
- 포함된 Shape primitive
- 엄폐 표본별 차단 상태
- 영역 진입·이탈 지점
- 제외 이유 코드

Rules는 근거를 사용해 공격 보정, 면역, Trigger와 사용자 설명을 계산할 수 있다.

### 14.2 안정적인 정렬

정렬 기준은 Query 종류가 정의한다.

예시:

```text
거리 오름차순
→ 규칙 우선순위
→ RuntimeEntityId 오름차순
```

Lua table iteration, Workspace 자식 순서와 Raycast 반환 순서를 최종 정렬 기준으로 사용하지 않는다.

## 15. Cache와 BindingStore

### 15.1 Query Cache

Cache key에는 최소한 다음이 포함된다.

- snapshotId
- queryTypeId와 schemaVersion
- 정규화된 Request hash
- rulesetVersion
- disclosureScope
- Provider set version

Snapshot이 불변이므로 같은 Snapshot 안에서는 Tick을 넘어 Cache할 수 있다.

### 15.2 무효화

기존 Cache entry를 부분 수정하지 않는다.

새 worldRevision이 생성되면 새 Snapshot key를 사용한다. 오래된 Snapshot Cache는 Lease와 메모리 정책에 따라 제거한다.

### 15.3 BindingStore

Recipe는 Query Result 또는 필요한 축약 결과를 BindingStore에 저장할 수 있다.

저장된 값은 다음을 포함해야 한다.

- snapshotId
- queryHash
- result type
- source step

Commit 전 재검증 정책이 있는 경우 오래된 BindingStore Result를 최신 결과로 간주하지 않는다.

BindingStore는 Scene 전역 Cache가 아니다.

## 16. Query Budget과 성능

권위 Query는 서버 부하 시간에 따라 임의로 결과가 달라지지 않도록 결정적 작업량 Budget을 우선 사용한다.

Budget 단위 예시:

- broad-phase candidates
- exact shape tests
- blocker segment tests
- cover samples
- Provider calls
- composite shape nodes
- returned result items

별도 wall-clock watchdog은 서버 보호를 위해 Query를 중단할 수 있지만, 일부 결과를 정상 결과처럼 반환하지 않는다.

### 16.1 완전성 정책

```text
complete_required
truncation_allowed
best_effort_preview
```

- 피해 대상, 시야 판정과 Commit 검증은 `complete_required`
- DM 검색과 UI 후보 표시는 명시적으로 `truncation_allowed` 가능
- 클라이언트 미리보기만 `best_effort_preview` 가능

권위 Query가 예산을 초과하면 빈 결과나 잘린 결과를 성공으로 반환하지 않는다.

### 16.2 지속 영역

지속 영역은 매 프레임 전체 Scene Query를 반복하지 않는다.

- Entity occupancy 변경
- 영역 이동·크기 변경
- 문·벽·차단 상태 변경
- 턴 시작·종료
- 명시적 Rule Event

에서 관련 Index와 후보만 다시 평가한다.

## 17. 실패 정책

공통 오류 코드:

```text
SPATIAL_QUERY_INVALID_REQUEST
SPATIAL_QUERY_TYPE_NOT_REGISTERED
SPATIAL_QUERY_SCHEMA_UNSUPPORTED
SPATIAL_QUERY_SNAPSHOT_NOT_FOUND
SPATIAL_QUERY_SNAPSHOT_EXPIRED
SPATIAL_QUERY_SCENE_NOT_ACTIVE
SPATIAL_QUERY_REFERENCE_NOT_FOUND
SPATIAL_QUERY_REFERENCE_STALE
SPATIAL_QUERY_POLICY_UNSUPPORTED
SPATIAL_QUERY_PROVIDER_UNAVAILABLE
SPATIAL_QUERY_PROVIDER_FAILED
SPATIAL_QUERY_BUDGET_EXCEEDED
SPATIAL_QUERY_RESULT_LIMIT_EXCEEDED
SPATIAL_QUERY_CROSS_SCENE_UNSUPPORTED
SPATIAL_QUERY_CANCELLED
SPATIAL_QUERY_DISCLOSURE_DENIED
```

### 17.1 권위 Rules와 Commit

- 실패 시 상태를 변경하지 않는다.
- 예약된 비용은 상위 실행 계약에 따라 해제하거나 안전하게 대기한다.
- 실패를 `대상 없음`으로 해석하지 않는다.
- DM 수동 판정이 필요하면 구조화된 Assisted 흐름으로 전환한다.

### 17.2 Preview

- 이전 Preview를 권위 결과로 유지하지 않는다.
- 재계산 중 또는 확인 불가 상태를 표시한다.
- 권위 검증이 불가능한 동안 확정 입력을 막을 수 있다.
- 낮은 정밀도의 로컬 Preview는 명확히 비권위로 취급한다.

### 17.3 Presentation

Presentation용 보조 Query가 실패하면 연출만 생략하거나 단순화한다. 규칙 결과를 되돌리지 않는다.

## 18. 비밀 정보와 복제

Spatial Query의 Raw Result는 기본적으로 서버 내부 데이터다.

플레이어 클라이언트에 다음을 그대로 보내지 않는다.

- 발견하지 못한 적과 함정의 ID
- 비밀문과 DM 전용 Trigger의 실제 위치
- 미확인 오브젝트의 내부 Definition ID
- 보이지 않는 blocker와 hidden field의 상세 목록
- 다른 플레이어의 비공개 정보

공개 흐름:

```text
Raw SpatialQueryResult
→ DisclosureProvider
→ Perception / Permission Policy
→ ClientViewResult
```

Query Trace도 같은 공개 정책을 따른다.

## 19. Perception과의 경계

Spatial Query가 계산:

- 감각 원점과 대상 표본 사이의 공간 경로
- 조명과 가림 Field
- 차단체와 투과 태그
- 거리와 형상 관계

Perception Engine이 계산:

- 어떤 SenseCapability가 활성인지
- 은신과 지각 판정
- 투명·진시야·맹시 예외
- 관찰자별 정보 수준
- 플레이어에게 복제할 최종 인식 상태

따라서 `HasLineOfSight == true`가 곧 `대상을 인식함`을 의미하지 않는다.

## 20. Navigation Planner와의 경계

Spatial Query는 즉시 끝나는 제한된 공간 질문을 처리한다.

Navigation Planner는 다음을 소유한다.

- 출발지부터 목적지까지의 전체 경로 탐색
- 계층형 탐색과 Portal graph 탐색
- 이동 비용 누적
- Movement Profile과 이동 모드 전환
- 경로 대안, 재계획과 부분 경로
- TravelDistance

Planner도 같은 Snapshot Lease, SpatialBodyProfile, Traversal Domain과 Provider 계약을 사용한다.

```text
Spatial Query
→ CanOccupy, CanTraverseSegment, SampleTraversalCost

Navigation Planner
→ FindPath, EstimateTravelCost, Replan

Movement Executor
→ 경로 실행, 중단, 반응과 실제 위치 변경
```

## 21. 확장 계약

새 Query Type은 다음을 등록해야 한다.

- 고유 QueryTypeId
- schemaVersion
- Request와 Result schema
- 필요한 Provider Capability
- deterministic ordering
- budget cost model
- disclosure policy
- failure completeness policy
- conformance tests

`custom-handler`라는 이유만으로 Workspace 직접 검색, 무제한 연산과 Raw Result 복제를 허용하지 않는다.

## 22. 진단과 Query Trace

Trace는 기본 게임 로그가 아니라 선택적 진단 데이터다.

```text
SpatialQueryTrace
├─ queryId
├─ snapshotId
├─ normalized request summary
├─ provider steps
├─ candidate counts
├─ exclusion reason counts
├─ budget consumption
├─ final ordering summary
└─ error or completion
```

규칙:

- 기본적으로 비활성 또는 샘플링한다.
- DM과 개발자 진단 권한을 구분한다.
- 비밀 정보는 권한에 따라 마스킹한다.
- 전체 Geometry와 대규모 후보 목록을 영구 로그에 저장하지 않는다.
- 사용자가 보는 설명은 번역 가능한 reason code에서 생성한다.

## 23. 문서 권위와 후속 순서

이 문서가 소유하는 결정:

- Spatial Query의 Snapshot, Context, Request와 Result 공통 계약
- Query 종류와 Provider 경계
- Perception과 Navigation의 책임 분리
- Cache, Budget, 실패와 공개 정책
- 점유와 Clearance의 상위 계약

다른 문서가 소유하는 결정:

- 구체적인 Targeting UX와 주문별 선택: Rules Targeting 문서
- 감각, 은신, 탐지와 정보 수준: Perception 문서
- Traversal Domain, Path Planner와 Movement Executor: Runtime Navigation 문서
- Layer와 Index 생성: Scene Compiler 문서
- Runtime Entity ID와 생명주기: Runtime Object와 Entity Lifecycle 문서
- Command 순서와 revision 생성: Command·Logical Time 문서

후속 문서 순서:

```text
1. Runtime Navigation과 Movement Execution
2. Scene Compiler와 Runtime Layer Index
3. Runtime Object와 Entity Lifecycle
4. Command Ordering과 Network Envelope
5. Spatial Query 구현 명세
```

이 문서는 알고리즘별 수치와 성능 상한만 측정 기본값으로 남아 있으므로 `READY_WITH_DEFAULTS`다.
