# 플랫폼·이동·입력 범위

- 상태: 확정
- 문서 종류: Product Scope
- 즉시 구현 명세 가능성: `READY`
- 관련 결정:
  - [`ADR-0048`](../decisions/ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md)
  - [`ADR-0056`](../decisions/ADR-0056-hybrid-traversal-domain-and-checkpointed-movement-execution.md)
- 관련 문서:
  - [`Runtime Navigation 계약`](../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
  - [`Navigation Authoring Pipeline`](../systems/navigation/navigation-authoring-pipeline.md)

## 이동 모델

```text
월드 비율: 5 ft = 4 studs
권위 위치: 연속 좌표
권위 거리와 이동 비용: 피트
권위 경로: Compiled Traversal Domain + Transition Graph + 연속 Corridor
규칙 격자: 없음
```

Scene Editor의 가상 격자는 벽·바닥·Asset을 정렬하는 제작 커서일 뿐, 토큰 이동과 D&D 거리 판정에 참여하지 않는다.

Actor의 통과 가능성은 크기별 고정 NavMesh나 수동 Clearance 숫자가 아니라 `SpatialBodyProfile`과 구성 공간 판정으로 계산한다.

## 탐험

- 클릭 이동과 WASD 직접 이동을 모두 허용한다.
- 두 입력은 같은 Traversal Domain, Body Profile, 이동 비용, 점유와 Movement Executor를 사용한다.
- 클릭 이동은 목적지에 대한 권위 Navigation Plan을 생성한다.
- WASD는 최종 위치가 아니라 짧은 방향 Intent를 반복 제출한다.
- 클라이언트는 제한된 시각 예측을 할 수 있지만 최종 위치는 서버가 확정한다.
- 동적 장애물로 경로가 바뀌면 목적지를 유지해 자동 Replan할 수 있다.

## 전투

- 토큰 WASD 이동을 허용하지 않는다.
- 이동은 목적지 또는 경유 경로를 미리 본 뒤 확정한다.
- 경로에는 거리, Rule Movement Cost, 남은 이동력, Squeeze·Door·Jump 같은 Transition과 예상 중단 지점을 표시한다.
- 이동 도중 반응, 함정, 위험 영역과 동적 차단이 발생하면 가장 가까운 안전한 Progress Checkpoint에서 멈춘다.
- 확인한 경로보다 비용·위험·Transition이 의미 있게 달라지는 Replan은 플레이어에게 다시 확인받는다.
- 이미 통과한 거리와 비용은 취소해도 환불하지 않는다.
- 전투 중 WASD는 자유 카메라 이동에 사용한다.

## 강제 이동과 순간이동

- 강제 이동은 일반 Path Planner가 장애물을 우회하지 않고 지정 방향으로 진행해 최초 차단 지점에 멈춘다.
- 순간이동은 이동 경로를 만들지 않고 목적지 배치 검증과 Teleport Command를 사용한다.
- 강제 이동, 순간이동과 낙하의 Trigger·피해 의미는 Navigation이 아니라 Rules가 판정한다.

## Scene 제작

- DM은 Navigation Polygon, Portal 폭, Clearance와 크기별 NavMesh를 직접 만들지 않는다.
- 원본 Model 내부에 `Walkable`, `Deniable`, `DifficultTerrain` Attribute와 Value를 요구하지 않는다.
- Asset Semantic Profile과 Scene Override에서 의미를 제공하고 Scene Compiler가 Runtime Navigation을 생성한다.
- 수동 도구는 내부 Graph 편집이 아니라 Support Surface, Obstacle, Rule Field와 Transition 같은 의미 예외를 지정한다.

## 지원 기기

초기 제품은 PC 키보드·마우스 전용이다. 모바일·게임패드·터치 대응을 이유로 입력 계약이나 UI를 복잡하게 만들지 않는다.

## 제거 대상

- 항상 생성되는 5피트 논리 셀
- 격자 중심 강제 스냅
- 전투 토큰 WASD 직접 이동
- 크기 등급별 고정 NavMesh만을 사용하는 Clearance
- Humanoid·Roblox Physics 기반 토큰 이동
- Legacy `Walkable` 계열 Model Attribute 관례
- 모바일·게임패드 초기 대응
