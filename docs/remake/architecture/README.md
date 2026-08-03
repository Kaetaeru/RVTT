# Architecture 문서

여러 기능이 공유하는 권위, 데이터와 실행 계약을 정의한다.

## 최상위 권위 문서

- [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - 사용자 경험을 상위 제약으로 둔다.
  - Scene Source, Compiled Runtime, Dynamic State와 Presentation을 분리한다.
  - Runtime 계층, Query와 Command 경계를 고정한다.
  - Legacy `Walkable` Attribute 관례를 리메이크 권위 데이터에서 제외한다.
  - 모든 하위 Architecture·System·Spec 문서가 따라야 하는 공통 원칙이다.
- [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
  - Canonical Scene Source와 정규화 Semantic Contribution
  - Layer Builder, Runtime Object Blueprint와 State Binding
  - 불변 Build Package, Chunk, Spatial Index와 Dependency Graph
  - 부분 컴파일과 전체 Build 동일성
  - 원자적 게시, Last Known Good Build와 Live Patch 경계
  - 서버 Raw Build와 권한별 Client Disclosure Segment 분리
- [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)
  - Runtime Scene Snapshot에 고정된 공간 질의 계약
  - 타입 있는 Spatial Reference, Shape, Request와 Immutable Result
  - Geometry, Occupancy, Visibility Evidence, Rule Field와 Interaction Query
  - Provider Registry, Budget, Cache, Trace와 비밀 정보 공개 정책
  - Perception, Navigation Planner와 Movement Executor의 책임 경계
- [`Runtime Navigation, Path Planning과 Movement Execution 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)
  - Hybrid Traversal Domain과 연속 Path Corridor
  - SpatialBodyProfile과 구성 공간 Clearance
  - Navigation Planner, Movement Coordinator와 Movement Executor
  - Progress Checkpoint, Swept Body, 이동력 소비와 Timing Window
  - 탐험 클릭·WASD, 전투 이동, Dynamic Replan과 Occupancy

## 포함 범위

- 서버·클라이언트 책임
- Command, revision, transaction과 Result
- Registry와 고정 ID
- Scene Source, Compiler Build, Runtime Scene Snapshot과 Spatial Query
- Runtime Layer, State Binding, Chunk와 Dependency Graph
- Traversal Domain, 경로 계획과 Movement Execution
- Capability, Recipe와 Effect
- 저장·복구와 마이그레이션
- PresentationRecipe와 확장 계약

기능별 사용자 흐름은 `../systems/`, 화면 구조는 `../ui/`, 실제 파일 계약은 `../specs/`에 둔다.

## 작성 원칙

새 Architecture 문서는 먼저 [`Runtime Architecture Principles`](runtime-architecture-principles.md)를 따른다.

Scene Source, Semantic Profile, Runtime Layer, Index, Chunk, Build와 게시를 다루는 문서는 [`Scene Compiler 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)을 따른다.

공간, 거리, 점유, 시야 증거, 영역 포함이나 이동 가능성을 사용하는 문서는 [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)을 추가로 따른다.

경로 계획, 이동 비용, 중단, 점유와 위치 변경을 사용하는 문서는 [`Runtime Navigation 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)을 따른다.

동일한 결정을 여러 문서에 반복하지 않는다. 전체 계층과 권위 원칙은 이 문서에 연결하고, 각 하위 문서는 자신의 데이터·상태·실패·성능 계약만 추가한다.
