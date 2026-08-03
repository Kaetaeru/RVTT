# ADR-0055. Snapshot 고정형 Typed Spatial Query와 Navigation 경계

- 상태: 확정
- 작성일: 2026-08-03
- 결정 범위: 공간 질의, 시야 증거, 점유, 배치, 이동 계획과 권위 결과
- 관련 문서:
  - [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
  - [`Spatial Query Engine과 Provider 계약`](../architecture/spatial-query-engine-and-provider-contract.md)
  - [`ADR-0023`](ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0054`](ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)

## 배경

기존 기획은 주문 대상 지정, 영역 형상, 시야, 효과선, 엄폐와 점유 개념을 정의했지만 다음 엔진 계약은 비어 있었다.

- 여러 Provider가 같은 월드 상태를 보는 방법
- Query 실행 중 문이나 Actor가 변경될 때의 일관성
- Query 결과 정렬과 재현성
- 경로 탐색과 즉시 공간 질의의 책임 경계
- 시야선과 실제 탐지 결과의 책임 경계
- 예산 초과와 Provider 실패를 대상 없음으로 오인하지 않는 정책
- Clearance를 DM이 직접 입력하지 않고 계산하는 방법
- 비밀 정보를 포함한 Raw Result의 클라이언트 공개 정책

기능별 코드가 Workspace, Raycast와 자체 거리 계산을 직접 사용하면 이동, 공격, 시야, 영역 효과와 롤백이 서로 다른 결과를 낼 수 있다.

## 결정

### 1. 모든 권위 공간 질의는 하나의 Runtime Scene Snapshot에 고정한다

Query는 `sceneId`, `snapshotId`, `worldRevision`과 Layer revision을 가진 Snapshot Lease를 사용한다.

한 Query 실행 중에는 Snapshot을 바꾸지 않는다. Commit 직전 최신 상태가 필요한 경우 기존 Query를 이어서 수정하지 않고 새 Snapshot에서 재검증한다.

### 2. Spatial Query는 타입 있는 읽기 전용 공통 창구다

Rules, Recipe, Perception, Interaction, AI와 Navigation은 Workspace 또는 Roblox 공간 API를 직접 사용해 권위 결과를 계산하지 않는다.

공개 Query는 고유 `QueryTypeId`, Request·Result schema, 정렬 규칙, 예산 모델과 공개 정책을 가진다.

좌표를 금지하지 않는다. 직접 좌표, Entity Anchor, Object Anchor, Shape와 Binding은 타입 있는 `SpatialReference`로 명시한다.

### 3. Query는 공간 증거를 반환하고 상위 시스템이 규칙 의미를 판정한다

Spatial Query는 거리, 교차, 차단체, 조명 Field, 가림 Field, 엄폐 표본과 후보 목록을 계산한다.

다음은 상위 시스템의 책임이다.

- Perception: 감각, 은신, 투명과 관찰자별 인식 수준
- Rules: 공격·내성 보정, 면역과 최종 대상 적격성
- Interaction: 잠금, 권한, 사용 상태와 행동 가능성
- Command: 실제 상태 변경

`LineOfSight == true`만으로 대상이 탐지되거나 선택 가능하다고 확정하지 않는다.

### 4. Provider는 공개 진입점이 아니다

Rules와 Recipe는 개별 Provider를 직접 호출하지 않는다.

```text
Caller
→ SpatialQueryService
→ QueryPlanner
→ ProviderRegistry
→ Layer Provider
```

SpatialQueryService가 Snapshot, schema, budget, cache, 결과 결합, 결정적 정렬, disclosure와 trace를 소유한다.

Provider는 등록된 Capability만 수행하며 상태 변경, Remote 호출, UI 호출과 Roblox Instance 반환을 하지 않는다.

### 5. 전체 경로 탐색은 Navigation Planner로 분리한다

Spatial Query가 담당:

- CanOccupy
- CanTraverseSegment
- ProjectToTraversalDomain
- SampleTraversalCost
- FindLocalAvoidanceBlockers

Navigation Planner가 담당:

- FindPath
- TravelDistance
- 이동 비용 누적
- Portal graph 탐색
- 대안 경로와 Replan

Movement Executor가 실제 위치 변경, 중단, 반응과 재개를 담당한다.

세 시스템은 같은 Snapshot, SpatialBodyProfile과 Traversal Domain 계약을 사용한다.

### 6. Clearance는 수동 속성이 아니라 구성 공간 Query다

Scene Object에 `ClearanceWidth`와 `ClearanceHeight`를 일상적으로 입력하지 않는다.

Actor는 실제 점유 형상, 수직 범위, 자세, Squeeze와 이동 모드를 포함한 `SpatialBodyProfile`을 사용한다.

Scene Compiler와 Runtime은 obstacle distance field, vertical free-span, traversal portal geometry와 configuration-space cache 같은 파생 데이터를 만들 수 있다.

Small, Medium, Large별 고정 NavMesh만을 권위 모델로 삼지 않는다.

### 7. 권위 Query는 완전성과 실패를 명시한다

피해 대상, 시야, 효과선, 점유와 Commit 검증은 완전한 결과가 필요하다.

예산 초과, Provider 실패와 Snapshot 오류를 빈 목록 또는 false로 변환하지 않는다. 구조화된 실패를 반환하며 권위 상태는 변경하지 않는다.

잘린 결과와 best-effort 결과는 명시적으로 허용된 검색·미리보기 Query에서만 사용할 수 있다.

### 8. 결정적 작업량 Budget과 안정적 정렬을 사용한다

서버 부하에 따라 결과가 달라지지 않도록 후보 수, 형상 검사 수, blocker 검사 수와 Provider 호출 수 같은 결정적 Budget을 우선한다.

같은 Snapshot과 Request는 동일한 결과 순서를 가진다. Workspace 순서, Lua table 순서와 비결정적 Raycast 순서를 최종 정렬 기준으로 사용하지 않는다.

### 9. Raw Result와 Client View Result를 분리한다

서버의 Raw Result에는 숨겨진 Actor, 함정, 비밀문과 DM 전용 Field가 포함될 수 있다.

클라이언트에는 Disclosure와 Perception 정책을 통과한 View Result만 보낸다. Query Trace에도 같은 정보 공개 정책을 적용한다.

### 10. Query Result는 불변이며 Snapshot 출처를 가진다

Result에는 `queryId`, `queryTypeId`, `snapshotId`, `worldRevision`, `queryHash`, cost와 evidence를 포함한다.

Recipe BindingStore는 Result를 재사용할 수 있지만 Scene 전역 Cache로 사용하지 않는다. 최신 재검증이 필요한 경우 오래된 Result를 권위 결과로 사용하지 않는다.

## 결과

### 장점

- 이동, 시야, 사거리, 엄폐와 영역 효과가 같은 공간 원본을 사용한다.
- 롤백과 리플레이에서 Query 결과를 재현할 수 있다.
- Provider와 Plugin을 추가해도 Rules API를 바꾸지 않는다.
- DM이 기술용 Clearance와 Navigation 형상을 직접 관리하지 않는다.
- Query 실패가 조용한 대상 누락이나 규칙 오판으로 이어지지 않는다.
- 비밀 정보가 Raw Query Result를 통해 클라이언트에 노출되는 것을 막을 수 있다.

### 비용

- Runtime Scene Snapshot, Index와 Provider Registry가 필요하다.
- Query schema와 Evidence 타입을 초기부터 엄격하게 관리해야 한다.
- Preview와 권위 Query가 분리되어 UI 재검증 흐름이 필요하다.
- Snapshot Cache와 Trace에 메모리·진단 예산이 필요하다.

## 대안 검토

### Workspace 직접 Raycast와 Overlap 사용

초기 구현은 빠르지만 Snapshot 재현성, 비밀 복제, Layer 의미와 통합하기 어렵기 때문에 채택하지 않는다.

### 하나의 범용 `Execute(table)` Query

확장은 쉽지만 지원 Policy, Result 완전성과 예산을 정적으로 검증하기 어렵기 때문에 타입 있는 Query 등록 방식을 채택한다.

### Spatial Query 안에서 전체 Pathfinding 수행

즉시 조회와 무거운 탐색의 성능·취소·재계획 요구가 다르므로 Navigation Planner로 분리한다.

### 크기 등급별 NavMesh만 생성

일반 사례는 빠르지만 자세, 변신, 특수 점유 형상과 Squeeze를 정확히 표현하기 어려우므로 SpatialBodyProfile과 구성 공간 파생 Cache를 채택한다.

## 후속 작업

1. Runtime Navigation과 Movement Execution 기획
2. Scene Compiler와 Runtime Layer Index 기획
3. Runtime Object와 Entity Lifecycle 기획
4. Command Ordering과 Network Envelope 기획
5. Spatial Query 구현 명세와 benchmark 기본값 확정
