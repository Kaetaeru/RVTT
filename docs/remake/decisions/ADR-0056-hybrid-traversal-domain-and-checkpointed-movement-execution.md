# ADR-0056. Hybrid Traversal Domain과 Checkpoint 기반 Movement Execution

- 상태: 확정
- 작성일: 2026-08-03
- 결정 범위: 토큰 경로 계획, 이동 실행, 동적 장애물, 이동력 소비와 이동 중 사건
- 관련 문서:
  - [`Runtime Navigation, Path Planning과 Movement Execution 계약`](../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
  - [`Spatial Query Engine과 Provider 계약`](../architecture/spatial-query-engine-and-provider-contract.md)
  - [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
  - [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
  - [`Navigation Authoring Pipeline`](../systems/navigation/navigation-authoring-pipeline.md)
  - [`ADR-0006`](ADR-0006-rigless-3d-token-continuous-movement.md)
  - [`ADR-0048`](ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md)
  - [`ADR-0055`](ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md)

## 배경

RVTT는 연속 무격자 좌표, 리그 없는 3D 토큰, 탐험 클릭·WASD, 전투 클릭 경로 이동을 지원한다.

그러나 다음이 아직 확정되지 않았다.

- 권위 경로 데이터가 NavMesh, Waypoint Graph 또는 다른 구조 중 무엇인지
- Actor 크기·자세·Squeeze와 통로 Clearance를 계산하는 방법
- 문과 동적 장애물이 경로 생성 이후 바뀌었을 때의 처리
- 이동 중 함정, 위험 영역과 기회 공격을 누락 없이 판정하는 방법
- 전투 이동력이 어느 시점에 소비되는지
- 탐험 WASD와 클릭 이동이 같은 규칙을 사용하는 방법
- 강제 이동, 순간이동과 낙하를 일반 경로 이동과 구분하는 방법
- 여러 Actor가 탐험에서 동시에 움직일 때 점유 충돌을 처리하는 방법

순수 Roblox PathfindingService는 D&D 이동 비용, 의미 있는 Transition, Snapshot 재현성과 세밀한 중단 정책을 충분히 제공하지 않는다.

크기 등급별 고정 NavMesh는 자세, 변신, Squeeze와 비정형 점유 모양을 일반적으로 처리하기 어렵다.

## 결정

### 1. 권위 Navigation은 Hybrid Traversal Domain을 사용한다

권위 경로 모델은 다음의 조합이다.

```text
연속 Traversal Domain
+ 의미 있는 Transition Graph
+ Spatial Query의 국소 Occupancy·Swept Body 검증
```

Ground·Climb은 연속 표면, Swim·Fly는 3차원 Volume을 사용할 수 있다. Door, Ladder, Jump, Drop과 Portal은 Domain 사이의 Transition이다.

5피트 셀, 단일 Waypoint Graph와 Roblox PathfindingService 결과를 권위 경로로 사용하지 않는다.

### 2. Planner와 Executor를 분리한다

```text
Navigation Planner
→ Snapshot에 고정된 불변 NavigationPlan 생성

Movement Executor
→ 승인된 Plan을 따라 권위 위치 진행
→ 경계 사건에서 중단
→ 실제 이동 비용 확정
```

Planner는 Actor 위치와 게임 상태를 변경하지 않는다. Executor는 새로운 목적지를 임의로 선택하지 않는다.

### 3. 경로는 연속 Corridor로 정리한다

넓은 범위에서는 Domain과 Transition Graph를 탐색하고, 선택된 경로 내부에서는 연속 Corridor를 생성한다.

최종 이동이 Cell 중심이나 임의 Waypoint를 그대로 연결한 지그재그가 되지 않게 한다.

### 4. Clearance는 SpatialBodyProfile과 구성 공간으로 계산한다

DM이 Portal 폭, `ClearanceWidth`, `ClearanceHeight`를 일상적으로 입력하지 않는다.

Actor의 실제 규칙용 Body Configuration, 수직 범위, 자세, Squeeze와 이동 모드를 사용해 통과 가능성을 계산한다.

성능을 위해 Distance Field, Vertical Free-span, Portal Geometry와 구성 공간 Cache를 사용할 수 있지만, Small·Medium·Large별 고정 NavMesh만을 권위 모델로 삼지 않는다.

### 5. Plan은 Snapshot과 Dependency Revision에 고정한다

Plan은 생성 당시의 Runtime Scene Snapshot과 관련 문·장벽·Actor 점유·Rule Field Revision을 기록한다.

실행 중 관련 의존성이 바뀌면 현재 위치에서 재검증한다. 무관한 `worldRevision` 변경만으로 모든 Plan을 폐기하지 않는다.

### 6. 이동은 Progress Checkpoint에서 규칙적으로 확정한다

화면은 연속 보간하지만 이동력 소비, 경계 사건과 복구 상태는 안전한 Checkpoint 단위로 확정한다.

Checkpoint는 다음에 생성될 수 있다.

- Domain과 Transition 경계
- Door·Ladder·Jump 전후
- Rule Field·Hazard·Aura 진입과 이탈
- 반응 가능 경계
- 이동력 임계점
- 동적 장애물 재검증 지점
- 취소 후 안전하게 멈출 수 있는 지점

고정 5피트 간격을 사용하지 않는다.

### 7. 이동 중 공간 사건은 Swept Body로 탐지한다

Waypoint의 중심점만 검사하지 않는다.

이전 Body Transform에서 다음 Transform까지의 Swept Volume과 영역 경계를 비교해 최초 교차 지점과 증거를 계산한다.

Movement Executor는 증거를 Rule Event로 전달하며 함정 피해, 반응과 상태 효과를 직접 적용하지 않는다.

### 8. 이동력은 실제 통과한 비용만 소비한다

Plan 승인 시 이동력을 예약할 수 있지만, 실제 소비는 Progress Checkpoint에서 통과한 거리와 Rule Movement Cost만큼 확정한다.

중단·취소·차단 시 이동하지 않은 예약량은 반환한다. 이미 지나간 거리는 환불하지 않고, 되돌아가면 다시 소비한다.

### 9. Dynamic Change는 모드에 따라 재계획한다

탐험에서는 목적지를 유지한 자동 Replan을 허용한다.

전투에서는 비용, 위험 경계, Transition, Route Hint와 목적지가 실질적으로 동일한 국소 보정만 자동 허용한다. 확인한 경로와 의미 있게 달라지면 안전한 Checkpoint에서 멈추고 다시 확인받는다.

강제 이동은 장애물을 피해 우회하지 않는다.

### 10. 일반 문은 명시적 Linked Interaction으로 처리한다

인식 가능하고 잠기지 않았으며 규칙상 사용할 수 있는 일반 문은 요청 정책에 따라 경로의 `linked_interaction` Transition이 될 수 있다.

Executor는 문을 직접 열지 않는다. Interaction Command를 실행하고 새 Snapshot에서 남은 경로를 재검증한 뒤 계속한다.

잠긴 문과 발견하지 못한 비밀문을 경로 정보로 노출하지 않는다.

### 11. 탐험 WASD는 Short-horizon Intent다

클라이언트는 최종 위치를 보내지 않는다.

방향과 짧은 요청 시간을 보내면 서버가 같은 Traversal Domain, SpatialBodyProfile, 비용과 Executor를 사용해 짧은 실행을 만든다.

클라이언트는 제한된 시각 예측을 사용할 수 있지만 서버 위치로 보정한다. 전투에서는 WASD 토큰 이동 Intent를 만들지 않는다.

### 12. 동적 점유는 규칙과 Reservation으로 처리한다

토큰을 Roblox 물리 충돌로 밀어내지 않는다.

전투 자발적 이동은 Command Sequence로 직렬화한다. 탐험 동시 이동은 현재 점유, 목적지 검사와 가까운 미래 구간의 Short-horizon Reservation을 사용한다.

경로 전체를 장시간 예약하지 않는다. 낮은 우선순위 Actor는 잠시 정지하거나 국소 Replan한다.

### 13. 강제 이동, 순간이동과 낙하는 별도 정책이다

- 강제 이동은 지정 방향으로 Swept Body를 검사하고 최초 차단 지점에 멈춘다.
- 순간이동은 경로 없이 목적지 배치 검증과 Teleport Command를 사용한다.
- 낙하와 환경 이동은 안전 경로 Planner가 아니라 환경 Motion Policy를 사용한다.

세 경우 모두 실제 피해와 규칙 효과는 Rules와 EffectRecipe가 처리한다.

## 결과

- 클릭, WASD, AI와 자동 이동이 같은 공간 계약을 사용한다.
- 전투 경로 Preview와 실제 비용을 추적할 수 있다.
- 문, 함정, 반응과 동적 장애물에서 안전하게 멈추고 재개할 수 있다.
- Actor 크기뿐 아니라 자세, 변신과 Squeeze를 같은 Clearance 모델로 처리한다.
- 이동 중 빠른 영역 통과에서도 Trigger를 누락하지 않는다.
- 토큰 물리 충돌과 Humanoid 없이 다수의 정적·이동 토큰을 관리할 수 있다.
- DM은 내부 Navigation 자료구조를 직접 편집하지 않는다.

## 비목표

- 구체적인 Polygon 생성 라이브러리와 A* 구현을 이 ADR에서 고정하지 않는다.
- 모든 이동 종류의 D&D 규칙 비용을 Navigation 내부에 하드코딩하지 않는다.
- Player Presentation의 정확한 보간 시간과 UI 픽셀 규격을 고정하지 않는다.
- Roblox Physics 결과를 권위 충돌·이동 판정으로 사용하지 않는다.
