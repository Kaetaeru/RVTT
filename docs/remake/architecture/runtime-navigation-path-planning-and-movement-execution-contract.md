# Runtime Navigation, Path Planning과 Movement Execution 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Path Planning 작업량 Budget과 요청 대기열 상한
  - 탐험 WASD Intent 전송 주기와 예측 허용 거리
  - 서버 보정 시 부드러운 보간과 즉시 스냅을 나누는 거리
  - Short-horizon Occupancy Reservation의 시간·거리 범위
  - 전투 자동 Replan을 허용하는 경로 차이 허용치
  - Movement Progress Checkpoint의 최대 간격
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0006`](../decisions/ADR-0006-rigless-3d-token-continuous-movement.md)
  - [`ADR-0048`](../decisions/ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md)
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0055`](../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md)
  - [`ADR-0056`](../decisions/ADR-0056-hybrid-traversal-domain-and-checkpointed-movement-execution.md)
- 관련 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)
  - [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
  - [`Navigation Authoring Pipeline`](../systems/navigation/navigation-authoring-pipeline.md)
  - [`인카운터·주도권·턴과 제어권 모델`](../systems/combat/encounter-initiative-turn-and-control-authority-model.md)

## 1. 목적

Runtime Navigation은 토큰을 화면에서 움직이는 Tween 시스템이 아니다.

다음 전체 흐름을 하나의 서버 권위 계약으로 관리한다.

```text
이동 의도
→ 경로 계획
→ 사용자 확인 또는 자동 승인
→ 이동 실행
→ 경계 사건과 중단
→ 재검증·재계획
→ 완료·취소·실패
```

클릭 이동, 탐험 WASD, AI 이동, Follow, Patrol과 규칙에 의한 이동은 같은 Path Planner와 Movement Executor를 사용한다. 강제 이동, 순간이동과 낙하는 이동 의미가 다르므로 같은 공개 진입점 아래에서 별도 실행 정책을 사용한다.

## 2. 사용자 결과

내부 구조는 다음 플레이 경험을 보장하기 위해 존재한다.

- DM은 Navigation Polygon, Portal 폭과 Clearance 수치를 직접 만들지 않는다.
- 플레이어가 클릭한 목적지까지 자연스럽고 예측 가능한 경로가 표시된다.
- 전투 경로 미리보기의 거리·험지 비용·중단 지점이 실제 실행과 가능한 한 일치한다.
- 문, 함정, 반응과 다른 Actor 때문에 경로가 바뀌면 토큰이 벽을 통과하지 않고 안전한 지점에서 멈춘다.
- 탐험 WASD는 반응성이 있지만 클라이언트가 최종 위치를 결정하지 않는다.
- 서버 보정이 필요해도 잦은 순간이동과 흔들림을 만들지 않는다.
- 이동 실패 시 `갈 수 없음`만 표시하지 않고 차단 이유와 가장 가까운 유효 지점을 제공할 수 있다.
- 메시 크기, 장식과 Roblox 물리 상태가 규칙상 이동 결과를 임의로 바꾸지 않는다.

## 3. 책임 분리

### 3.1 Scene Compiler

다음을 Compiled Runtime Scene에 생성한다.

- Traversal Domain
- Transition Graph
- 정적 Obstacle Field
- Supporting Surface Index
- Rule Movement Cost Field
- Vertical Free-span과 Portal Geometry
- 구성 공간 계산을 위한 파생 데이터
- 부분 갱신 의존성

Scene Compiler는 Actor의 현재 이동 명령을 실행하지 않는다.

### 3.2 Spatial Query

다음을 제공한다.

- `CanOccupy`
- `CanTraverseSegment`
- `ProjectToTraversalDomain`
- `SampleTraversalCost`
- `FindLocalAvoidanceBlockers`
- Swept body와 영역 경계 교차 증거

Spatial Query는 전체 목적지 경로를 탐색하거나 Actor 위치를 변경하지 않는다.

### 3.3 Navigation Planner

목적지와 이동 정책을 Snapshot에 바인딩된 불변 `NavigationPlan`으로 변환한다.

Planner는 위치를 변경하거나 반응을 해결하지 않는다.

### 3.4 Movement Coordinator

- 이동 권한과 현재 실행 충돌 확인
- Planning Job 수명주기
- Plan 승인과 실행 시작
- 동시 이동 순서와 Occupancy Reservation
- 현재 Actor별 이동 실행 하나만 허용
- 취소·교체·강제 중단 요청 조정

### 3.5 Movement Executor

- 승인된 Plan을 따라 권위 위치 진행
- Swept body를 이용한 국소 재검증
- Movement Budget Ledger 갱신
- 경계 사건과 Timing Window에서 정지
- 문 상태 변화와 동적 차단에 따른 Replan
- 완료·취소·차단·실패 결과 생성

### 3.6 Presentation

- 경로 미리보기
- 토큰 모델의 부드러운 보간
- 이동 비용, 남은 이동력과 중단 사유 표시
- 서버 보정 표현

Presentation은 권위 위치, 경로 비용과 사건 발생 여부를 확정하지 않는다.

## 4. 권위 Traversal Domain

RVTT는 5피트 셀, 단일 Waypoint Graph 또는 크기별 고정 NavMesh를 권위 이동 모델로 사용하지 않는다.

권위 모델은 **연속 공간을 나타내는 Compiled Traversal Domain과 의미 있는 Transition Graph의 혼합 구조**다.

```text
CompiledNavigationLayer
├─ traversalDomains[]
├─ transitionGraph
├─ staticObstacleField
├─ dynamicObstacleBindings
├─ movementCostFields[]
├─ supportingSurfaceIndex
├─ configurationSpaceCaches[]
└─ revision
```

### 4.1 Traversal Domain 종류

초기 계약은 다음 Domain을 지원할 수 있어야 한다.

```text
ground_surface
climb_surface
swim_volume
fly_volume
burrow_volume
custom_registered
```

모든 Domain을 같은 자료구조로 강제하지 않는다.

- Ground와 Climb은 연속 표면과 Portal 연결이 적합하다.
- Swim과 Fly는 통과 가능한 3차원 Volume과 연결이 필요하다.
- Ladder, Jump, Drop과 Door는 Domain 사이를 잇는 Transition으로 표현한다.

공개 Planner 계약은 내부가 Polygon Mesh, Convex Cell, Portal Graph 또는 다른 가속 구조인지 알 필요가 없다.

### 4.2 연속 경로와 Portal Graph

Planner는 넓은 범위에서 Domain Cell과 Transition Graph를 탐색하고, 선택된 경로 내부에서는 연속 Corridor를 만든다.

```text
Broad phase
→ Domain과 Transition 경로 탐색

Narrow phase
→ 연속 Corridor 생성
→ 코너 단순화와 Funnel 계열 정리
→ Swept body 검증
```

최종 경로가 Cell 중심이나 임의 Waypoint를 그대로 연결한 지그재그가 되어서는 안 된다.

## 5. SpatialBodyProfile과 Clearance

Clearance는 Scene Object의 수동 숫자가 아니다.

```text
SpatialBodyProfile
├─ bodyProfileId
├─ occupancyShape
├─ verticalExtent
├─ supportContactProfile
├─ stanceVariants[]
├─ squeezePolicy
├─ movementConfigurations[]
├─ rotationPolicy
└─ revision
```

### 5.1 구성 공간 판정

Planner와 Spatial Query는 Actor의 현재 Body Configuration을 장애물에 대해 구성 공간으로 해석한다.

Runtime은 성능을 위해 다음 파생 데이터를 사용할 수 있다.

- Obstacle Distance Field
- Vertical Free-span Field
- Portal Geometry
- Supporting Surface Index
- 자주 사용되는 Body Configuration Cache

하지만 `Small NavMesh`, `Medium NavMesh`, `Large NavMesh` 세 개만으로 모든 Actor를 분류하지 않는다.

### 5.2 자세와 Squeeze

Actor의 자세와 변신은 Body Configuration을 바꾼다.

```text
standing
crouched_or_low_profile
prone
squeezing
transformed
custom_registered
```

Squeeze가 가능한 통로는 일반 경로와 구분된 `SqueezeSegment`로 계획한다.

- 요청 정책이 허용할 때만 사용한다.
- 경로 미리보기에 명확히 표시한다.
- 실제 이동 비용과 규칙상 불이익은 Rules가 제공한다.
- 자동으로 자세를 바꾸어 플레이어 의도를 숨기지 않는다.

## 6. NavigationRequest

모든 자발적 경로 계획은 공통 요청을 사용한다.

```text
NavigationRequest
├─ requestId
├─ executionReason
├─ actorId
├─ startReference
├─ destinationReference
├─ snapshotLease
├─ spatialBodyProfileRef
├─ movementConfiguration
├─ movementBudget?
├─ routeHints[]
├─ transitionPolicy
├─ occupancyPolicy
├─ terrainCostPolicy
├─ preferencePolicy
├─ replanPolicy
└─ tracePolicy
```

클라이언트는 `actorId`, 목적지, 선택한 경유점과 사용자 의도를 제출할 수 있다. 시작 위치, Body Profile, 이동력, Door 상태와 최종 경로는 서버가 권위 상태에서 가져온다.

## 7. NavigationPlan

Plan은 특정 Snapshot과 의존성 Revision에 고정된 불변 결과다.

```text
NavigationPlan
├─ planId
├─ requestId
├─ actorId
├─ snapshotLease
├─ dependencyRevisionSet
├─ startAnchor
├─ requestedDestination
├─ resolvedDestination
├─ pathCorridor
├─ segments[]
├─ transitions[]
├─ movementCostBreakdown
├─ preferenceBreakdown
├─ checkpoints[]
├─ predictedBoundaryEvents[]
├─ requiredTransitionActions[]
├─ completionKind
├─ assumptions[]
├─ stablePathKey
└─ planHash
```

`completionKind`:

```text
complete
partial_reachable
requires_choice
unreachable
invalid_request
budget_exceeded
```

권위 실행에서 예산 초과와 Planner 실패를 `unreachable`로 위장하지 않는다.

## 8. Path Segment 종류

```text
surface_traverse
volume_traverse
transition
squeeze
jump
controlled_drop
linked_interaction
custom_registered
```

각 Segment는 다음을 가진다.

```text
segmentId
startAnchor
endAnchor
geometricLengthFeet
movementCostFeet
traversalDomainId
bodyConfiguration
boundaryRefs[]
dependencyRefs[]
```

Segment의 화면상 곡선과 권위 비용 계산 경로를 서로 다른 자료로 만들지 않는다. Presentation은 권위 Corridor를 시각적으로 보간한다.

## 9. 경로 선택 기준

기본 플레이어 경로는 다음 우선순위를 사용한다.

```text
1. 유효한 경로
2. 규칙상 총 이동 비용이 가장 낮음
3. 사용자 Route Hint와 명시적 회피 정책 준수
4. 불필요한 Transition과 자세 변경 최소화
5. 기하학적 거리 최소화
6. 안정적인 Topology·Entity ID 순서
```

위험 지역의 예상 피해와 AI 전술 선호는 `movementCostFeet`에 몰래 합치지 않는다.

```text
Rule Movement Cost
→ 실제 이동력 소비

Preference Penalty
→ AI 또는 사용자가 요청한 경로 선호

Hazard Evidence
→ 경로 미리보기와 Rules 판단
```

플레이어 경로가 자동으로 안전한 우회로를 선택해야 하는지는 UI 정책이며, 위험 비용을 D&D 이동 비용으로 위장하지 않는다.

## 10. Transition과 문

문, 계단, 사다리, 점프, Drop과 Portal은 의미 있는 Transition이다.

```text
TraversalTransition
├─ transitionId
├─ fromDomain
├─ toDomain
├─ transitionKind
├─ entryAnchor
├─ exitAnchor
├─ spatialRequirements
├─ capabilityRequirements
├─ ruleCostBinding
├─ stateDependency
├─ linkedInteraction?
└─ revision
```

### 10.1 일반 문 자동 처리

현재 닫혀 있지만 다음 조건을 모두 만족하는 일반 문은 Plan에 `linked_interaction`으로 포함할 수 있다.

- Actor가 문을 인식하고 상호작용할 수 있음
- 잠금·비밀·권한 조건을 통과함
- 요청의 `transitionPolicy`가 자동 상호작용을 허용함
- 탐험 또는 전투의 행동 경제가 허용함

실행 시 문을 직접 열지 않는다.

```text
Movement Executor 정지
→ Interaction Command 실행
→ Door revision 갱신
→ 새 Snapshot에서 남은 경로 재검증
→ 이동 재개
```

잠긴 문, 발견하지 못한 비밀문과 DM 전용 통로를 Planner가 우회 정보로 노출해서는 안 된다.

## 11. Movement Execution 상태 기계

```text
requested
→ planning
→ awaiting_confirmation
→ approved
→ executing
→ completed
```

실행 중 보조 상태:

```text
paused_for_timing_window
paused_for_transition
paused_for_replan
cancel_pending
```

종료 상태:

```text
completed
cancelled
blocked
invalidated
failed
recovery_required
```

### 11.1 시작 검증

실행 직전 서버는 다음을 다시 확인한다.

- 현재 Controller와 Command 권한
- Actor 생명주기와 제어 가능 상태
- 시작 위치와 Plan 시작 Anchor 일치
- 이동 Configuration 사용 가능
- 전투 중 남은 이동력
- Plan의 Dependency Revision
- 같은 Actor에 실행 중인 다른 이동 없음
- Scene과 Encounter 상태

## 12. Movement Progress와 Checkpoint

화면상 위치는 부드럽게 이동하지만 규칙 처리는 임의의 매 프레임 이벤트에 의존하지 않는다.

Movement Executor는 경로를 **안전한 Progress Checkpoint**로 나눈다.

Checkpoint 후보:

- 이동 시작과 종료
- Traversal Domain 또는 Body Configuration 변경
- Door·Ladder·Jump 같은 Transition 전후
- Rule Field 진입·이탈 경계
- Trap·Hazard·Aura의 Swept Volume 교차점
- 위협 범위 진입·이탈로 Timing Window가 생길 수 있는 지점
- 동적 장애물 재검증 지점
- Movement Budget 임계점
- 사용자가 취소를 요청한 뒤의 가장 가까운 안전 지점

Checkpoint는 고정 5피트 간격이 아니다. 공간 사건과 수치 안정성을 기준으로 생성한다.

```text
MovementProgressRecord
├─ movementExecutionId
├─ checkpointId
├─ authoritativeTransform
├─ traversedDistanceFeet
├─ spentMovementCostFeet
├─ crossedBoundaryRefs[]
├─ snapshotRevision
└─ commandSequence
```

## 13. Swept Body와 사건 누락 방지

함정, 오라와 위험 영역은 Waypoint에 Actor 중심점이 들어왔는지만 검사하지 않는다.

```text
이전 Body Transform
+ 다음 Body Transform
+ SpatialBodyProfile
→ Swept Volume
→ 교차한 Boundary와 최초 교차 지점
```

이를 통해 빠른 이동, 큰 Actor와 좁은 영역에서도 사건이 건너뛰어지지 않게 한다.

Spatial Query는 교차 증거를 반환하고, Rules와 Timing Window가 실제 발동 여부를 결정한다.

## 14. Movement Budget Ledger

전투 이동력은 계획한 전체 경로를 시작 순간 모두 소비하지 않는다.

```text
MovementBudgetLedger
├─ actorId
├─ turnId
├─ availableFeet
├─ reservedFeet
├─ committedSpentFeet
├─ currentExecutionId?
└─ revision
```

기본 원칙:

- Plan 승인 시 필요한 최대 비용을 예약할 수 있다.
- Checkpoint를 확정할 때 실제 통과한 비용만 소비한다.
- 중단·취소·차단 시 아직 이동하지 않은 예약량은 반환한다.
- 이미 지나간 길을 되돌아가면 다시 이동력을 소비한다.
- 단순 Client 취소로 이미 이동한 비용을 환불하지 않는다.
- 강제 이동과 순간이동은 자발적 이동력 Ledger를 사용하지 않는 것이 기본이다.
- Rules가 명시한 특수 이동만 별도 자원을 사용한다.

험지와 비용 영역은 경로 선분과 Rule Field의 교차 길이로 결정적으로 적분한다. 시각 Mesh 재질이나 Roblox 물리 마찰을 비용으로 사용하지 않는다.

## 15. 중단과 Timing Window

Movement Executor가 경계 사건을 발견했다고 직접 기회 공격, 함정 피해와 상태 효과를 적용하지 않는다.

```text
MovementBoundaryEvidence
→ Rule Event
→ Timing Window 또는 Trigger 평가
→ 필요한 경우 Executor 일시정지
→ 독립 ActionExecution·EffectRecipe 해결
→ Actor 상태와 경로 재검증
→ Resume, Replan 또는 종료
```

반응을 선택하지 않거나 Trigger가 무효라면 같은 실행을 재개한다.

Actor가 반응 결과로 쓰러지거나 다른 위치로 이동하면 원래 Plan을 계속 사용하지 않는다.

## 16. Dynamic Change와 Replan

Plan 생성 이후 다음이 바뀔 수 있다.

- 문 열림·닫힘·파괴
- 다른 Actor의 위치
- 장벽과 Scene Effect 생성·제거
- 이동 모드·크기·자세 변화
- 이동 비용과 위험 영역 변화
- Scene Chunk 활성 상태

Plan은 전체 `worldRevision`이 달라졌다는 이유만으로 무조건 폐기하지 않는다. `dependencyRevisionSet`에 포함된 관련 요소를 우선 검사한다.

### 16.1 자동 Replan

#### 탐험

목적지가 여전히 유효하면 현재 위치에서 자동으로 다시 계획할 수 있다.

- 사용자 목적지를 유지한다.
- 비밀 정보와 금지 Transition을 새로 사용하지 않는다.
- 과도한 우회가 발생하면 정지하고 사용자에게 알린다.

#### 전투

플레이어가 확인한 경로와 실질적으로 같은 국소 보정만 자동 적용한다.

다음 중 하나라도 바뀌면 안전한 Checkpoint에서 멈추고 다시 확인받는다.

- 이동 비용이 증가함
- 새 위험 영역 또는 반응 가능 경계를 통과함
- 다른 문·Transition을 사용함
- 사용자가 지정한 Route Hint를 벗어남
- 목적지 또는 최종 Facing이 의미 있게 달라짐

강제 이동은 장애물을 피해 우회 Replan하지 않는다.

## 17. Dynamic Occupancy와 동시 이동

토큰끼리 Roblox 물리 충돌로 밀어내지 않는다.

### 17.1 전투

전투의 자발적 이동은 서버 Command Sequence와 현재 Turn 권한으로 직렬화한다.

반응과 강제 이동이 끼어들면 Opportunity Stack 순서에 따라 원래 이동을 일시정지한다.

### 17.2 탐험

여러 Actor가 동시에 이동할 수 있다.

Movement Coordinator는 다음을 사용한다.

- 현재 점유 Body Index
- 목적지 점유 검증
- 가까운 미래 구간의 Short-horizon Reservation
- 서버가 부여한 안정적인 우선순위
- 장시간 대기 방지를 위한 공정성 승격

낮은 우선순위 Actor는 물리적으로 밀려나지 않고 잠시 감속·정지하거나 국소 Replan한다.

경로 전체를 장시간 독점 예약하지 않는다.

### 17.3 Actor 통과와 종료 위치

다른 Actor를 통과할 수 있는지와 같은 공간에서 종료할 수 있는지는 별도 정책이다.

```text
OccupancyPolicy
├─ mayPassThrough
├─ mayEndOverlapping
├─ relationshipRules
├─ sizeRules
├─ incapacitatedRules
├─ squeezeInteraction
└─ customRegistered
```

Rules가 정책을 제공하고 Spatial Query와 Planner가 공간 결과를 계산한다.

## 18. 클릭 이동

### 18.1 탐험 클릭

- 클라이언트는 즉시 로컬 Preview를 표시할 수 있다.
- 서버는 목적지로 권위 Plan을 생성한다.
- 일반적인 단순 클릭은 추가 확인 없이 실행할 수 있다.
- Door 상호작용, Squeeze, Jump, 위험 영역과 큰 우회가 포함되면 Preview와 확인을 요구할 수 있다.

### 18.2 전투 클릭

- 서버 권위 Plan Preview에 거리, 이동 비용, 남은 이동력과 예상 경계 사건을 표시한다.
- 플레이어가 목적지 또는 경유점을 확정한 뒤 실행한다.
- 클라이언트가 제출한 Waypoint와 예상 비용을 신뢰하지 않고 서버가 다시 계획한다.
- 같은 `planHash`와 Dependency Revision이 유효하면 기존 Plan을 재사용할 수 있다.

## 19. 탐험 WASD

탐험 WASD는 Final Position을 보내는 방식이 아니다.

```text
DirectionalMoveIntent
├─ actorId
├─ inputSequence
├─ direction
├─ requestedDuration
├─ stanceIntent?
├─ clientKnownRevision
└─ issuedAtClientTime
```

서버는 짧은 Horizon에 대해 다음을 수행한다.

```text
방향 Intent
→ 현재 Traversal Domain에 투영
→ 직접 Segment 검사
→ 필요한 경우 국소 Steering·Replan
→ 짧은 Movement Execution
```

클라이언트는 공개된 Navigation Preview 데이터 안에서 짧은 시각 예측을 할 수 있다. 권위 경로와 차이가 나면 서버 Transform으로 보정한다.

금지:

- 매 Render Frame마다 Remote 전송
- 클라이언트 최종 CFrame 제출
- Roblox Humanoid 이동과 Network Ownership에 권위 위임
- 클릭 이동과 다른 충돌·비용 규칙 사용

전투 중 WASD는 토큰 이동 Intent를 생성하지 않는다.

## 20. 강제 이동, 순간이동과 낙하

### 20.1 강제 이동

강제 이동은 규칙이 지정한 방향과 최대 거리를 따른다.

- 일반 경로처럼 장애물을 피해 우회하지 않는다.
- Swept Body 검사에서 최초 차단 지점에 멈춘다.
- 험지 비용을 자발적 이동력에서 소비하지 않는 것이 기본이다.
- 경계 교차 증거는 생성하지만 기회 공격·Trigger 여부는 Rules가 결정한다.

### 20.2 순간이동

순간이동은 경로 이동이 아니다.

```text
목적지 선택
→ Spatial Query 배치 검증
→ Teleport Command
→ 시작·종료 상태 변경
```

중간 영역을 통과하지 않으며 이동 경로 사건을 생성하지 않는다. 출발·도착 Trigger는 Rules가 별도로 판정한다.

### 20.3 낙하와 비탄도 환경 이동

낙하, 미끄러짐과 붕괴에 의한 이동은 일반 자발적 Planner가 안전 경로를 찾지 않는다.

환경 Motion Policy와 Swept Body 검사를 사용하고, 충돌·착지·피해 계산은 Rules와 EffectRecipe가 담당한다.

## 21. 취소와 교체

- 플레이어는 자신의 자발적 이동을 취소할 수 있다.
- 취소 요청은 즉시 과거 위치로 되돌리지 않고 가장 가까운 안전한 Checkpoint에서 멈춘다.
- 새 자발적 이동 요청은 기존 실행의 취소가 확정된 뒤 시작한다.
- 강제 이동과 Rule Resolution 중 이동은 Controller가 임의 취소할 수 없다.
- DM 강제 중단은 감사 로그와 이유를 남긴다.
- Actor가 삭제·비활성화되면 실행을 종료하고 Reservation을 해제한다.

## 22. 저장, 재접속과 롤백

영구 저장에는 Scene Source와 Actor의 확정 위치를 저장한다. Path Cache와 화면 보간 상태는 저장하지 않는다.

중단 가능한 실행은 다음 최소 상태를 세션 복구 데이터에 포함한다.

```text
movementExecutionId
actorId
planId 또는 재계획에 필요한 Intent
lastCommittedCheckpoint
MovementBudgetLedger revision
pending Timing Window 또는 Transition
commandSequence
```

재접속 시 클라이언트가 보던 보간 위치가 아니라 서버의 마지막 권위 Progress를 사용한다.

Encounter Rollback은 Command Journal과 MovementProgressRecord를 이용해 Actor 위치와 소비 이동력을 함께 복원한다.

## 23. 오류와 실패 정책

초기 구조화된 오류 범주:

```text
NAV_REQUEST_INVALID
NAV_ACTOR_NOT_CONTROLLABLE
NAV_START_POSITION_STALE
NAV_DESTINATION_INVALID
NAV_NO_TRAVERSAL_DOMAIN
NAV_NO_PATH
NAV_PLAN_BUDGET_EXCEEDED
NAV_PLAN_DEPENDENCY_STALE
NAV_BODY_CONFIGURATION_INVALID
NAV_TRANSITION_UNAVAILABLE
NAV_OCCUPANCY_CONFLICT
NAV_MOVEMENT_BUDGET_INSUFFICIENT
NAV_EXECUTION_REPLACED
NAV_EXECUTION_BLOCKED
NAV_REPLAN_REQUIRES_CONFIRMATION
NAV_PROVIDER_FAILURE
NAV_RECOVERY_REQUIRED
```

권위 실패를 가장 가까운 유효 위치로 자동 성공 처리하지 않는다. `partial_reachable`을 허용하는 요청만 명시적으로 부분 경로를 받을 수 있다.

## 24. 성능과 생명주기

- 정지 Actor에는 개별 Heartbeat 이동 루프를 두지 않는다.
- 현재 Planning Job과 실행 중 Movement만 갱신한다.
- Planner는 Snapshot·Body Configuration·목적 함수 기준 Cache를 사용할 수 있다.
- Dynamic Actor 때문에 정적 Traversal Domain 전체를 다시 컴파일하지 않는다.
- 문과 파괴 오브젝트 변화는 관련 Transition과 국소 파생 Index만 무효화한다.
- 경로 계산은 취소 가능한 작업이며 Scene·Actor 수명 종료 시 즉시 폐기한다.
- 대형 Scene은 Chunk 경계를 넘는 계층형 탐색을 사용할 수 있다.
- 성능 수치는 기준 Scene과 Actor 수를 정한 뒤 프로파일링으로 확정한다.

## 25. 진단

선택적 Navigation Trace는 다음을 기록할 수 있다.

```text
requestId
planId
snapshotId
dependency revisions
선택된 Domain·Transition
탈락한 주요 후보와 이유
비용 Breakdown
Squeeze·Door·Jump 판단
예상·실제 경계 사건
Replan 원인
종료 상태와 오류 코드
```

DM의 일반 화면에는 내부 Polygon과 Graph를 노출하지 않는다. 개발 진단 모드에서만 Corridor, Portal, Body Sweep와 Reservation을 시각화한다.

## 26. 비목표

- Roblox PathfindingService 결과를 권위 경로로 그대로 사용
- Humanoid와 물리 충돌을 통한 토큰 이동
- 크기 등급별 고정 NavMesh만으로 Clearance 해결
- 매 프레임 모든 Actor의 경로와 Trigger 재계산
- 이동 중 발생한 규칙 효과를 Movement Executor가 직접 적용
- 전투 경로를 동적 장애물 때문에 조용히 전혀 다른 길로 변경
- DM에게 내부 경로 데이터 수동 편집을 기본 작업으로 요구

## 27. 후속 구현 명세 순서

1. Compiled Traversal Domain과 Transition schema
2. SpatialBodyProfile·구성 공간 Query 구현 계약
3. Navigation Planner와 NavigationPlan
4. Movement Coordinator·Execution 상태 기계
5. Progress Checkpoint·Boundary Event·Timing Window 연결
6. Movement Budget Ledger
7. 탐험 클릭 이동
8. 탐험 WASD Intent와 예측·보정
9. 전투 경로 Preview·확정·중단
10. 강제 이동·순간이동·낙하
11. Dynamic Occupancy와 동시 이동
12. Navigation 진단·성능 기준 Scene

## 28. 준비도 결론

권위 구조, 이동 종류, Path와 Executor 경계, Budget 소비, 중단·재계획, 점유와 입력 방식은 확정되었다.

남은 항목은 측정과 프로토타입으로 정할 수 있는 수치 기본값이다. 따라서 구현 명세 작성 준비도는 `READY_WITH_DEFAULTS`다.
