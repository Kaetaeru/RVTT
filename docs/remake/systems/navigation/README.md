# Navigation 시스템

연속 무격자 이동의 Scene 제작, Compiled Traversal Domain, 경로 계획, 이동 실행과 동적 점유를 다룬다.

## 권위 문서

### Scene Compiler 공통 계약

- [`../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - Scene Source와 Semantic Contribution 정규화
  - Layer Builder와 Compiled Runtime Scene Build
  - Navigation Artifact, State Binding, Dependency Graph와 Chunk
  - 부분 컴파일과 원자적 Build 게시

### Scene 제작

- [`navigation-authoring-pipeline.md`](navigation-authoring-pipeline.md)
  - Asset Semantic Profile과 Scene Override
  - Traversal Domain·Transition 자동 컴파일
  - 대표 SpatialBodyProfile 자동 검사
  - 검토함, 부분 갱신과 게시 상태
  - DM에게 내부 Polygon·Portal 폭·Clearance 수동 편집을 요구하지 않는 제작 흐름

### Runtime

- [`../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
  - Hybrid Traversal Domain과 연속 Path Corridor
  - Navigation Planner, Movement Coordinator와 Movement Executor
  - Progress Checkpoint, Swept Body와 이동 중 사건
  - Movement Budget Ledger, Dynamic Replan과 Occupancy Reservation
  - 탐험 클릭·WASD, 전투 클릭 이동, 강제 이동과 순간이동의 경계

### 공통 공간 계약

- [`../../architecture/spatial-query-engine-and-provider-contract.md`](../../architecture/spatial-query-engine-and-provider-contract.md)
  - Snapshot 고정형 Occupancy·Segment·Boundary Query
  - SpatialBodyProfile과 구성 공간 계산
  - Path Planner가 사용하는 읽기 전용 공간 증거

## 고정 제품 전제

- 권위 위치와 경로는 연속 무격자 공간을 사용한다.
- 월드 비율은 `5 ft = 4 studs`다.
- 탐험은 클릭 이동과 WASD 이동을 지원한다.
- 전투는 클릭 경로 이동만 지원한다.
- 토큰 이동은 Humanoid와 Roblox 물리 충돌을 사용하지 않는다.
- 크기별 고정 NavMesh와 Legacy `Walkable` Attribute를 권위 모델로 사용하지 않는다.
- Navigation Layer는 Scene Compiler Build의 일부이며 다른 Layer와 혼합 Revision으로 게시하지 않는다.

월드 비율과 입력 범위는 [`../../product/platform-movement-and-input-scope.md`](../../product/platform-movement-and-input-scope.md)를 따른다.
