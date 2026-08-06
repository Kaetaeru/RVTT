# Semantic Scene 기반 Navigation Authoring Pipeline

- 상태: 확정
- 문서 종류: System Planning
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 자동 분석 신뢰도 임계값
  - 작은 Geometry 결함의 자동 보정 허용치
  - 기준 Scene별 검사 Body Profile 묶음
  - 게시 차단 오류와 경고의 최종 목록
  - 대형 Scene 검사 작업의 사용자 표시 방식
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0005`](../../decisions/ADR-0005-performance-reliability-clean-code.md)
  - [`ADR-0006`](../../decisions/ADR-0006-rigless-3d-token-continuous-movement.md)
  - [`ADR-0048`](../../decisions/ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md)
  - [`ADR-0054`](../../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0055`](../../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md)
  - [`ADR-0056`](../../decisions/ADR-0056-hybrid-traversal-domain-and-checkpointed-movement-execution.md)
- 관련 문서:
  - [`Scenes and World`](../scene/scenes-and-world.md)
  - [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
  - [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md)
  - [`Runtime Navigation 계약`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)

## 1. 목표

Scene 제작자는 집, 벽, 문, 계단, 물, 절벽과 장식을 배치한다. 내부 Navigation Polygon, Portal 폭, Clearance 숫자와 크기별 NavMesh를 직접 관리하지 않는다.

```text
Scene Source
+ Asset Semantic Profile
+ Scene Override
→ Scene Compiler
→ Compiled Traversal Domain과 Transition
→ 자동 검사
→ 검토가 필요한 예외만 DM에게 표시
```

일반적인 Scene은 `Scene Runtime 만들기 / 갱신` 한 번으로 플레이 가능한 상태가 되어야 한다.

## 2. 이전 관례의 폐기

리메이크 Navigation의 권위 원본으로 다음을 사용하지 않는다.

- Model 내부 `Walkable`, `Deniable`, `DifficultTerrain` Attribute 또는 Value
- Model 이름, 색상과 투명도에 의존한 규칙 판정
- Small·Medium·Large별 고정 Navigation Mesh
- DM이 직접 그리는 Polygon과 Portal이 기본 제작 방식인 Editor
- Roblox Part 충돌과 물리 마찰을 그대로 규칙 이동에 사용

기존 에셋에 이런 값이 남아 있어도 리메이크 Compiler는 권위 입력으로 신뢰하지 않는다.

## 3. Scene Authoring Source

Navigation 제작에 필요한 저장 원본은 다음과 같다.

```text
SceneNavigationAuthoringSource
├─ placedAssetRefs[]
├─ transforms[]
├─ semanticProfileRefs[]
├─ instanceOverrides[]
├─ explicitSemanticRegions[]
├─ explicitTransitionLinks[]
├─ criticalRouteDefinitions[]
└─ authoringRevision
```

원본 Model은 시각 리소스다. Semantic Profile은 Asset Library, Content Pack 또는 배치된 Scene 인스턴스의 외부 메타데이터에 저장한다.

## 4. Semantic Profile

Semantic Profile은 최종 경로 자료구조가 아니라 **오브젝트가 세계에서 어떤 의미를 제공하는지** 설명한다.

```text
NavigationSemanticProfile
├─ supportContributions[]
├─ obstacleContributions[]
├─ traversalTransitions[]
├─ movementCostFieldContributions[]
├─ ruleBoundaryContributions[]
├─ dynamicStateBindings[]
├─ compilerExclusions[]
└─ diagnosticsMetadata
```

예시:

| 오브젝트 | Semantic 기여 |
|---|---|
| 바닥 | Ground Support Surface 후보 |
| 벽 | 정적 Obstacle Volume |
| 일반 문 | 상태 연동 Obstacle + Linked Interaction Transition |
| 계단 | 두 Ground Domain을 잇는 Surface Transition |
| 사다리 | Ground와 Climb Domain Transition |
| 경사로 | 연속 Ground Surface |
| 얕은 물 | Ground Support + Rule Movement Cost Field |
| 깊은 물 | Swim Volume 또는 Ground→Swim Transition |
| 절벽 | Ground 경계 + Drop Transition 후보 |
| 큰 가구 | Obstacle Volume |
| 작은 장식 | Compiler 제외 또는 시각 전용 |
| 연기 VFX | Navigation 제외, 필요하면 Perception Semantic만 제공 |

`walkable=true`처럼 최종 결과를 저장하지 않는다. Compiler가 현재 Geometry, Semantic Profile과 Scene 상태로 Traversal Domain을 만든다.

## 5. 기본 제작 흐름

```text
1. DM이 Asset을 Scene에 배치
2. Asset Library가 Semantic Profile을 연결
3. DM이 필요한 인스턴스 예외만 수정
4. Scene Compiler가 Runtime Layer와 Index 생성
5. 대표 SpatialBodyProfile로 자동 경로 검사
6. 안전한 Geometry 결함만 자동 보정
7. 애매한 의미만 검토함에 표시
8. 핵심 경로와 시작 지점 검사
9. 준비 상태 표시 후 게시
```

DM이 Navigation 전용 편집 화면을 열지 않아도 정상 Scene을 게시할 수 있어야 한다.

## 6. 자동 Compiler 출력

```text
CompiledNavigationLayer
├─ traversalDomains[]
├─ transitionGraph
├─ staticObstacleField
├─ dynamicObstacleBindings
├─ supportingSurfaceIndex
├─ movementCostFields[]
├─ portalGeometry
├─ verticalFreeSpanData
├─ configurationSpaceCaches[]
├─ invalidationDependencies
└─ revision
```

Compiler는 Navigation 외에도 Visibility, Interaction과 Rule Layer를 같은 Scene Source에서 만들 수 있다. 한 오브젝트의 상태 변경은 각 Layer의 연결된 파생 데이터에 일관되게 반영한다.

## 7. 자동 분석 우선순위

```text
1. Scene 인스턴스의 명시적 Semantic Override
2. Asset Library의 Semantic Profile
3. Scene Editor가 만든 명시적 Region과 Transition
4. 제한된 Geometry 분석
5. Unknown 진단
```

Geometry 분석은 보조 수단이다.

다음을 모델 모양만 보고 임의로 추측하지 않는다.

- 문이 잠겼는지
- 얕은 물과 깊은 물의 규칙 차이
- 절벽에서 안전하게 내려갈 수 있는지
- 가구가 통과 가능한 장식인지 장애물인지
- 비밀 통로의 존재와 공개 조건

확신할 수 없는 의미는 잘못된 자동 결과보다 `검토 필요`로 남긴다.

## 8. Scene별 Override

특수 Scene에서는 Asset 기본 의미를 배치 인스턴스 단위로 바꿀 수 있다.

예시:

- 평소 장애물인 책상을 이번 Scene에서는 통과 가능한 환영으로 설정
- 일반 물을 독성 늪 Cost Field로 변경
- 무너진 벽을 Obstacle이 아니라 Squeeze Transition으로 지정
- 절벽 두 지점을 명시적인 Jump Transition으로 연결
- 시각적으로 존재하지만 모든 규칙 Layer에서 제외

Override는 원본 Asset과 다른 Scene 인스턴스를 변경하지 않는다.

## 9. DM 수동 도구의 경계

수동 도구는 내부 Polygon을 그리는 도구가 아니라 **의미를 명확하게 하는 예외 도구**다.

허용되는 도구:

- Support Surface Region 지정
- Obstacle Volume 지정
- Movement Cost 또는 Rule Field Region 지정
- 두 Anchor 사이 Transition 연결
- One-way, Drop, Ladder, Jump와 Portal 의미 선택
- 특정 오브젝트를 Navigation Compiler에서 제외
- Scene 인스턴스 Semantic Profile 교체
- 테스트 목적지와 핵심 경로 지정

기본 UI에서 노출하지 않는 내부 데이터:

- Convex Cell과 Polygon ID
- A* Node와 Edge
- Portal 폭 수치
- Configuration-space Offset
- Distance Field
- Actor별 Clearance 숫자

개발 진단 모드에서만 내부 자료구조를 시각화한다.

## 10. 대표 Body Profile 자동 검사

자동 검사는 크기 등급별 고정 NavMesh의 존재를 확인하는 것이 아니다.

실제 `SpatialBodyProfile`과 Movement Configuration을 가진 검사 Fixture를 사용한다.

기본 검사 예시:

- 일반적인 Medium humanoid standing
- Small humanoid standing
- Large creature의 대표 Body Shape
- Medium humanoid squeezing
- Ground→Climb Transition 사용 가능 Profile
- Scene이 수영·비행을 지원할 때 해당 Movement Configuration

Scene의 콘텐츠에 필요하지 않은 이동 모드를 무조건 검사하지 않는다.

### 검사 시작점

- 플레이어 진입 지점
- 전투 배치 지점
- 핵심 방과 구역
- 문 양쪽
- 계단·사다리·경사로의 양 끝
- 상호작용 오브젝트 접근 지점
- Scene 전환 지점
- DM이 지정한 Critical Route Anchor

### 찾는 문제

- Support Surface 사이의 작은 Geometry 단절
- 시작 지점이 Traversal Domain에 투영되지 않음
- 열린 문 Transition이 연결되지 않음
- 닫힌 문 Obstacle을 우회해 새는 경로
- 계단·경사로·사다리 연결 실패
- Body Profile이 통로를 통과할 수 없는 이유가 불명확함
- Squeeze 가능 구간이 일반 경로로 잘못 분류됨
- 장식 Mesh가 Obstacle로 잘못 포함됨
- 공중에 떠 있는 고립 Domain 조각
- Rule Movement Cost Field가 Traversal Domain과 어긋남
- 핵심 상호작용 지점에 유효한 접근 Anchor가 없음
- Critical Route가 끊김
- 여러 Layer의 Door 상태 Binding이 불일치함

## 11. 안전 자동 보정

자동 보정은 의미를 새로 발명하지 않고, 확실한 수치·Geometry 결함만 수정한다.

가능한 예:

- 설정된 허용치 이하의 Support Surface 틈 연결
- 동일 Source에서 중복 생성된 Obstacle 병합
- 문 Profile과 상태 Binding 재연결
- 명확한 계단 끝 Anchor 정렬
- VFX, 선택 원과 Editor Gizmo 제외
- 극소 고립 Domain 조각 제거
- 경계의 부동소수점 오차 정리

자동으로 하지 않는 것:

- 벽을 뚫어 새 통로 생성
- 절벽을 경사로로 변환
- 잠긴 문을 통과 가능한 Transition으로 변경
- 어느 층에 연결할지 불명확한 계단을 임의 연결
- 깊은 물에 Ground Support를 임의 생성
- 비밀문과 함정의 의미 공개
- Actor가 Squeeze할 의도가 있다고 추측

모든 자동 보정은 하나의 Authoring Transaction으로 기록하고 실행 취소할 수 있어야 한다.

## 12. 검토함

| 상태 | 의미 | 사용자 처리 |
|---|---|---|
| 확정 | 명시 Profile과 Override로 컴파일됨 | 기본적으로 숨김 |
| 보정됨 | 안전한 수치 결함 자동 수정 | 결과 요약에 표시 |
| 검토 권장 | 둘 이상의 의미 해석 가능 | 게시 가능, 위치 안내 |
| 오류 | 플레이를 막는 명확한 문제 | 게시 전 해결 필요 |

검토 항목을 선택하면 다음을 보여준다.

- 문제 위치와 카메라 이동
- 관련 Asset과 Semantic Profile
- 예상 Runtime 의미
- Compiler가 확정하지 못한 이유
- 2~4개의 의미 있는 수정 선택지

DM에게 Polygon, Node와 내부 Cache를 직접 수정하게 하지 않는다.

## 13. Critical Route

DM은 다음처럼 플레이에 중요한 Anchor 사이의 경로를 지정할 수 있다.

- 입구 → 보스방
- 플레이어 시작 → Scene 출구
- 감옥 → 탈출 지점
- 입구 → 2층 계단
- 주요 NPC → 안전 지역

Compiler 갱신 후 각 Route를 대표 Body Profile과 정책으로 재검사한다.

Critical Route가 끊기면 게시 차단 오류로 설정할 수 있다.

## 14. 부분 갱신

오브젝트 하나가 바뀔 때 Scene 전체를 다시 컴파일하지 않는다.

```text
Authoring Source 변경
→ 영향 영역과 Semantic Dependency 계산
→ 관련 Traversal Domain·Transition·Field 재생성
→ 인접 연결 검증
→ 영향을 받는 검사 Route만 재실행
→ 검토함 갱신
```

전체 재생성 조건:

- 최초 Runtime Scene 생성
- 대규모 Terrain 변경
- Scene 좌표계와 월드 Scale 변경
- Asset Semantic Profile의 호환 불가능한 버전 변경
- DM의 명시적 전체 재생성

컴파일 실패 시 마지막 정상 Runtime Scene을 보존하고 새 결과를 게시하지 않는다.

## 15. 게시 상태

### 준비 완료

- 치명적 Compiler 오류 없음
- 시작 지점과 Critical Route 정상
- 필수 Transition 정상
- 게시 차단 검토 항목 없음

### 검토 권장

- 기본 플레이 가능
- 의미가 불명확한 비차단 항목 존재
- 문제 위치와 영향 범위가 요약됨

### 게시 불가

- 시작 지점이 유효 Domain에 없음
- Critical Route 끊김
- 필수 Door·Stair·Portal Transition 컴파일 실패
- Runtime Layer revision 불일치
- 새 컴파일 실패 후 정상 Snapshot 없음

## 16. 사용자 경험 예시

```text
1. DM이 집, 문, 계단과 가구를 배치한다.
2. Asset Library가 각 오브젝트의 Semantic Profile을 자동 연결한다.
3. DM이 `Scene Runtime 갱신`을 누른다.
4. Compiler가 Navigation·Visibility·Interaction·Rule Layer를 생성한다.
5. 대표 Body Profile이 핵심 구역을 자동 검사한다.
6. 작은 Geometry 결함은 자동 보정된다.
7. 애매한 계단 연결 하나만 검토함에 표시된다.
8. DM이 추천된 위층 Anchor를 선택한다.
9. 해당 영역만 다시 컴파일되고 `준비 완료`가 된다.
10. DM이 Scene을 게시한다.
```

## 17. 성능 원칙

- 무거운 Compiler와 자동 주행 검사는 편집·게시 단계에서 수행한다.
- 실행 중에는 Compiled Runtime Layer와 증분 Index를 사용한다.
- 검사 Fixture는 시각 Model과 물리 Actor를 생성하지 않는다.
- 반복 Asset의 정적 Compiler 결과를 재사용할 수 있다.
- 변경 영역과 의존 Route만 다시 계산한다.
- 검사와 Compiler 작업은 취소 가능하고 Scene 종료 시 정리한다.
- 실제 수치 목표는 기준 Scene을 정한 뒤 프로파일링으로 확정한다.

## 18. 확정된 방향

1. Scene Editor는 Semantic Object, Region과 예외만 편집한다.
2. 원본 Model 내부 기술용 Attribute와 Value를 요구하지 않는다.
3. Compiler가 연속 Traversal Domain, Transition과 파생 Index를 생성한다.
4. Clearance는 SpatialBodyProfile과 구성 공간 계산으로 처리한다.
5. 크기별 고정 NavMesh는 권위 모델이 아니다.
6. 일반적인 Scene은 내부 Navigation 자료를 수동 편집하지 않고 게시할 수 있어야 한다.
7. 자동 분석은 Profile보다 낮은 우선순위의 보조 수단이다.
8. 확실한 수치 결함만 자동 보정한다.
9. 애매한 의미는 검토함과 추천 선택지로 해결한다.
10. 부분 컴파일과 마지막 정상 Snapshot 보존을 지원한다.
