# Runtime Architecture Principles

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY`
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
- 관련 문서:
  - [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
  - [`이동 의미 레이어 자동 제작 파이프라인`](../systems/navigation/navigation-authoring-pipeline.md)
  - [`EffectRecipe 해결·확정 모델`](effect-recipe-resolution-and-commit-model.md)
  - [`Recipe Step Runtime Foundation`](../specs/shared/001-recipe-step-runtime-foundation.md)
  - [`공통 기반 계약 공백 감사`](../audits/cross-system-foundation-contract-gap-audit.md)

## 1. 목적

이 문서는 RVTT 리메이크의 공통 런타임 아키텍처 원칙을 정의한다.

앞으로 작성되는 Scene Compiler, Spatial Query, Navigation, Runtime Object, Entity Lifecycle, Networking, Streaming, Rules와 Presentation 문서는 이 원칙을 따라야 한다.

이 문서는 특정 알고리즘이나 폴더 구조를 고정하지 않는다. 대신 시스템이 어떤 데이터를 권위 원본으로 삼고, 어떤 계층을 통해 읽고 변경하며, 사용성·성능·롤백을 어떻게 보존해야 하는지를 고정한다.

## 2. 최상위 제품 제약

### 2.1 복잡성은 엔진이 소유한다

내부 계산이 복잡한 것은 허용한다. 단, 복잡성이 다음 사용자에게 전가되어서는 안 된다.

- Scene을 제작하는 DM
- 세션을 진행하는 DM
- 캐릭터를 조작하는 플레이어
- 일반 에셋을 등록하는 콘텐츠 제작자

다음은 금지한다.

- 일반 Model을 사용하기 위해 내부에 `Walkable`, `Deniable`, `DifficultTerrain` 같은 Attribute나 Value를 직접 넣도록 요구
- DM이 내비게이션 Polygon, Portal 폭, 토큰 반지름과 머리 공간을 일상적으로 수동 편집
- Compiler와 Query의 내부 구조를 알아야 문, 계단, 상자와 함정을 배치할 수 있는 UI
- 내부 정합성을 이유로 플레이 중 눈에 띄는 입력 지연, 잦은 로딩과 불안정한 토큰 보정 허용

### 2.2 내부 일관성은 사용성을 보호하기 위한 수단이다

아키텍처의 목적은 추상화 자체가 아니다.

다음 효과가 없는 추상화는 추가하지 않는다.

- 기능 간 규칙 결과 일치
- Scene 제작 작업 감소
- 오류와 부분 실패 격리
- 저장·재접속·롤백 재현성
- 성능 측정과 최적화 가능성
- 콘텐츠 추가 시 중복 코드 감소

내부 구조의 순수성과 실제 플레이 감각이 충돌하면 플레이 감각을 우선한다. 다만 단기 편의를 위해 권위 원본과 계층 경계를 우회하지 않는다.

## 3. 권위 데이터 계층

RVTT의 월드 데이터는 네 종류로 구분한다.

### 3.1 Authoring Source

DM이 편집하고 저장하는 원본이다.

```text
Scene Source
├─ 배치된 AssetId와 Transform
├─ 외부 Semantic Profile 참조
├─ Scene 인스턴스 Override
├─ 명시적 영역, 링크와 예외
├─ Lighting 설정
└─ DM 전용 Metadata
```

원본 Model은 시각 리소스다. Semantic Profile을 Model 내부 Attribute와 Value로 강제하지 않는다.

Semantic Profile은 다음 중 하나에 저장한다.

- Asset Library의 Prefab Definition
- Content Pack Definition
- Scene 인스턴스 Metadata
- DM이 만든 명시적 Override

### 3.2 Compiled Definition

Compiler가 Authoring Source를 검증해 만든 불변 파생 데이터다.

예:

- Compiled Recipe
- Compiled Runtime Scene
- 타입 있는 Binding layout
- Navigation topology
- Visibility occluder data
- Interaction link graph
- Rule volume index

Compiled Definition은 저장 원본이 아니다. 원본과 Compiler 버전으로 다시 만들 수 있어야 한다.

### 3.3 Authoritative Dynamic State

플레이 중 변경되는 서버 권위 상태다.

예:

- Actor 위치와 상태
- 문 열림·잠금·파괴 상태
- 상자 전리품 상태
- 활성 함정과 Trigger 상태
- 현재 Rule Volume과 지속 효과
- Fog 공개 상태
- Encounter와 턴 상태

이 상태는 Command, transaction과 CommitGroup으로만 변경한다.

### 3.4 Presentation Projection

Workspace Instance, UI, VFX, 카메라와 선택 표시는 권위 상태를 보여 주는 투영이다.

Presentation은 권위 상태의 원본이 아니며, Presentation 오류가 Rules 결과를 변경하지 않는다.

## 4. Compile Before Runtime

### 4.1 기본 원칙

가능한 데이터는 콘텐츠 로딩 또는 Scene 게시 시점에 검증·컴파일한다.

```text
Source Definition
→ Schema Validation
→ Reference Resolution
→ Static Diagnostics
→ Compiled Definition
→ Runtime 사용
```

런타임은 문자열 설명, Model 이름과 임의 Attribute를 반복 해석하지 않는다.

### 4.2 컴파일하지 않는 것

모든 값을 정적으로 고정한다는 의미는 아니다.

다음은 동적 상태로 남는다.

- Actor의 현재 위치와 HP
- 문과 상호작용 오브젝트 상태
- 전투 중 생성된 효과와 소환체
- DM Override
- 임시 Rule Volume

동적 상태는 revision이 있는 권위 상태에 기록하고, Compiled Definition과 결합해 Runtime Scene Snapshot을 만든다.

### 4.3 증분 컴파일

문 하나가 열리거나 오브젝트 하나가 이동할 때 Scene 전체를 재컴파일하지 않는다.

```text
권위 변경
→ 영향 대상과 공간 범위 계산
→ 관련 파생 데이터 무효화
→ 필요한 Index와 Cache만 증분 갱신
→ 새 Runtime revision 공개
```

전체 재컴파일은 다음 경우에만 기본값이다.

- Scene 최초 게시
- Compiler schema 또는 주요 Builder 버전 변경
- 대규모 지형 교체
- 복구할 수 없는 파생 데이터 손상
- DM의 명시적 전체 재빌드

## 5. Semantic Scene Compilation

### 5.1 Scene Editor가 다루는 것

Scene Editor는 다음만 직접 편집한다.

- 시각 Asset과 Transform
- Semantic Object 유형 또는 Profile
- 문, 레버, 상자 같은 의미 있는 연결
- Rule Area와 Trigger
- 자동 판단이 불가능한 예외 Override

Scene Editor는 Runtime Polygon과 내부 Index를 직접 편집하는 도구가 아니다.

### 5.2 Runtime Layer

Scene Compiler는 Authoring Source에서 다음 레이어를 생성한다.

```text
Runtime Scene
├─ Navigation Layer
├─ Visibility Layer
├─ Interaction Layer
├─ Rule Layer
├─ Permission-aware Metadata Layer
└─ Spatial Indexes
```

Visual Instance와 Roblox Collision은 Runtime Layer의 권위 원본이 아니다.

### 5.3 Object별 기여 데이터

Semantic Object는 하나 이상의 Builder에 기여한다.

예시:

```text
잠긴 나무문
├─ Navigation Contributor: 상태 연동 통과 경계
├─ Visibility Contributor: 상태 연동 시야 차단
├─ Interaction Contributor: 열기, 닫기, 잠금, 해제
├─ Rule Contributor: 파괴 가능, HP와 재질
└─ Metadata Contributor: DM 링크와 공개 정책
```

문 자체에 `Walkable=false`를 저장하지 않는다. 통과 가능성은 현재 문 상태, 이동 Profile과 Navigation Provider가 계산한다.

### 5.4 Clearance는 저작 데이터가 아니다

DM은 일반적으로 폭·높이 Clearance 값을 직접 입력하지 않는다.

Actor는 타입 있는 Movement Profile을 가진다.

```text
Movement Profile
├─ footprint 또는 configuration shape
├─ standing height
├─ movement modes
├─ squeeze policy
└─ 규칙상 크기와 예외
```

Navigation Compiler와 Planner는 Semantic Geometry와 Movement Profile로부터 통과 가능 공간을 계산한다.

정확한 구성 공간 알고리즘, Profile 캐시 전략과 머리 공간 판정은 Runtime Navigation 문서에서 확정한다. 어떤 알고리즘을 선택하더라도 수동 Clearance 편집을 정상 제작 흐름으로 요구하지 않는다.

## 6. Runtime Dependency Direction

### 6.1 저작 경로

```text
Scene Editor
→ Scene Source
→ Scene Compiler
→ Compiled Runtime Scene
```

Scene Compiler는 Scene Editor UI를 참조하지 않는다.

### 6.2 런타임 읽기 경로

```text
Presentation
→ Rules
→ Recipe Runtime
→ Spatial Query와 Runtime Services
→ Runtime Scene Snapshot과 Index
```

상위 계층은 하위 계층의 공개 계약만 사용한다.

### 6.3 상태 변경 경로

```text
Player·DM·Rule Intent
→ Authoritative Command
→ Validation
→ Transaction 또는 CommitGroup
→ Dynamic State Revision
→ Derived Index Invalidation
→ Event
→ Presentation
```

Query와 Presentation은 상태 변경 경로를 소유하지 않는다.

## 7. One Source of Truth

동일한 개념에는 하나의 권위 소유자만 둔다.

| 개념 | 권위 소유자 |
|---|---|
| 월드 스케일 | 공통 Unit 계약 (`5 ft = 4 studs`) |
| Actor 권위 위치 | Authoritative Dynamic State |
| 이동 가능성과 경로 | Runtime Navigation Provider |
| 직선 거리와 공간 포함 | Spatial Query Provider |
| 시야와 엄폐 | Visibility Provider |
| 문 상태 | Interaction Object 권위 상태 |
| 피해와 상태 적용 | PendingEffect와 CommitGroup |
| Recipe 중간 결과 | 실행별 BindingStore |
| 화면 Instance 위치 | 권위 상태의 Presentation Projection |

기능 문서는 같은 규칙을 다시 정의하지 않고 권위 문서를 참조한다.

## 8. Roblox Boundary

### 8.1 Workspace는 권위 데이터베이스가 아니다

Rules, Recipe Step과 UI Controller는 다음을 직접 호출해 권위 판정을 만들지 않는다.

```lua
workspace:GetChildren()
workspace:GetDescendants()
workspace:GetPartBoundsInBox()
workspace:Raycast()
```

Roblox 공간 API가 필요한 경우 다음 경계 안에서만 사용한다.

- Scene Compiler의 Geometry Adapter
- 등록된 Spatial Provider
- Presentation 전용 비권위 효과
- 검증·진단 도구

### 8.2 Roblox Physics의 역할

Roblox Physics는 시각적 이동, VFX와 충돌 보조에 사용할 수 있다.

규칙상 이동 가능성, 점유, 사거리와 시야의 최종 판단은 Runtime 계약이 소유한다.

Physics 결과를 권위 상태로 반영하려면 서버 Command와 검증을 거쳐야 한다.

## 9. Spatial Query Principles

### 9.1 Snapshot-bound Query

모든 권위 Query는 다음을 포함하는 `QueryContext`에 바인딩된다.

```text
sceneId
runtimeRevision
snapshotId 또는 authorityRevision
requestingActorId?
executionId?
permissionView
rulesetId
budget
tracePolicy
```

좌표는 unversioned `Vector3`만 전달하지 않고 타입 있는 `SpatialReference`로 표현한다.

예:

- Actor Anchor
- Scene Object Anchor
- Snapshot-bound Point
- Region Reference
- Recipe Binding Reference

### 9.2 Read-only와 Deterministic

Query는 Runtime 상태를 수정하지 않는다.

같은 Snapshot, Query Definition과 Permission View는 같은 결과와 같은 안정 정렬 순서를 반환해야 한다.

동률 결과는 고정 ID와 명시된 tie-breaker로 정렬한다. Lua table 순서와 Instance 생성 순서에 의존하지 않는다.

### 9.3 Immutable Result

Query Result는 불변이다.

후속 필터링은 새 Result View 또는 Binding을 만든다. 호출자가 원본 결과 배열을 수정해 다른 Step 결과를 바꾸지 못한다.

### 9.4 Runtime Index 우선

Provider는 매 Query마다 Workspace 전체를 순회하지 않는다.

Scene Compiler와 Runtime Object Lifecycle이 관리하는 다음 Index를 사용한다.

- Actor와 Runtime Object 공간 Index
- Navigation topology와 Portal Index
- Visibility blocker Index
- Interaction Index
- Rule Volume Index
- 권한·공개 정책 Index

### 9.5 Query Budget

Query는 다음 비용을 측정하고 제한한다.

- 검사한 후보 수
- 공간 노드 방문 수
- Provider 호출 수
- ray 또는 segment test 수
- 생성한 결과 수
- Query 체인 깊이

예산 초과 시 잘못된 부분 결과를 정상 결과처럼 반환하지 않는다. 구조화된 실패 또는 명시적 제한 결과를 반환한다.

사용자 입력 경로에서 예산 초과가 반복되면 Query 정확도를 조용히 낮추는 대신 Index와 알고리즘을 개선한다.

### 9.6 Query Trace

개발·DM 진단 모드에서는 다음을 추적할 수 있다.

```text
Query 입력
→ 사용 Snapshot과 Provider
→ 후보 수
→ 제외 이유
→ 정렬과 tie-break
→ Budget 소비
→ 최종 결과
```

Trace는 기본 플레이 UI를 방해하지 않으며, 비밀 정보는 요청자의 Permission View에 맞게 보호한다.

### 9.7 Provider Chain

Spatial Query는 레이어별 Provider 계약을 사용한다.

Provider 교체 가능성은 호출자가 구현을 알 필요가 없다는 뜻이다. 런타임 중 임의 플러그인이 권위 Provider를 교체한다는 뜻이 아니다.

Provider 등록은 다음을 요구한다.

- 고정 Provider ID와 버전
- 지원 Query Type
- 입력·출력 Schema
- 결정성 선언
- Budget 모델
- Cache dependency
- Permission 처리
- Trace 지원
- 오류 격리

## 10. Navigation Planner Boundary

Spatial Query의 짧고 제한된 조회와 무거운 경로 계획을 구분한다.

```text
Spatial Query
→ CanOccupy, overlap, distance, visibility, region membership 같은 제한 조회

Navigation Planner
→ topology 탐색, 경로 비용, movement profile, portal과 동적 장애물 고려
```

둘은 같은 Runtime Scene Snapshot, ID, Unit와 Permission 계약을 사용한다.

Planner가 오래 걸릴 수 있더라도 플레이어의 경로 미리보기와 서버 확정은 서로 다른 revision을 사용하지 않는다. 확정 직전에 최신 revision으로 재검증한다.

## 11. BindingStore as Execution Blackboard

Recipe의 `BindingStore`는 하나의 `executionId` 안에서 다음을 재사용하는 Blackboard다.

- Query Result Reference
- 선택된 대상과 위치
- RollRecord
- 계산된 수정치
- PendingEffect Reference
- DM과 플레이어의 구조화된 결정

BindingStore는 다음을 소유하지 않는다.

- Scene 전역 공간 Index
- 다른 Recipe 실행의 캐시
- Actor와 문 권위 상태
- 장기 저장되는 Campaign 상태

BindingStore의 Snapshot은 실행 중단·재접속·복구에 필요한 값만 직렬화한다.

## 12. Immutability, Revision과 Cache

### 12.1 불변 대상

다음은 생성 후 수정하지 않는다.

- Compiled Definition
- Runtime Scene Snapshot의 공개 View
- Query Definition
- Query Result
- 완료된 RollRecord
- 확정된 Command와 Journal Entry

### 12.2 변경 가능한 대상

권위 Dynamic State는 Command를 통해 변경할 수 있다.

변경은 다음을 만든다.

- 증가한 authority revision
- 변경된 Entity revision
- 영향받은 Cache dependency token
- 재현 가능한 Command Journal Entry

### 12.3 Cache Key

Cache는 최소한 다음을 키에 포함한다.

```text
sceneId
runtimeRevision
permissionView
queryType 또는 planner profile
normalized input hash
dependency token
```

revision과 Permission View가 다른 결과를 같은 Cache Entry로 공유하지 않는다.

## 13. No Hidden Special Cases

특정 주문·Feature·Monster 이름을 검사해 엔진 분기를 만드는 방식은 기본적으로 금지한다.

나쁜 예:

```text
if spellId == "fireball" then ...
if featureId == "rage" then ...
```

좋은 구조:

```text
Content Definition
→ Standard Recipe Steps
→ Standard Query
→ PendingEffect
→ Presentation Augment
```

전용 구현이 필요한 경우 등록된 `AdvancedOperation`을 사용하고 다음 계약을 그대로 따른다.

- 서버 권위
- 타입 있는 입력과 출력
- Query와 Runtime Scene 사용
- Budget
- 저장과 복구
- Rollback
- Diagnostics
- 버전과 마이그레이션

## 14. Extension Principles

확장 가능한 기반은 다음 Registry를 통해 추가한다.

- Semantic Builder Registry
- Spatial Provider Registry
- Step Handler Registry
- Presentation Module Registry
- Content Importer Registry
- DM Workspace Panel Registry

초기 범위에서 Registry는 신뢰된 개발 모듈만 받는다.

콘텐츠 데이터가 다음을 제공하는 것은 금지한다.

- 임의 Luau 소스
- 무제한 반복
- 등록되지 않은 Provider·Handler ID
- 권위 Command 우회
- 전체 Workspace 접근 권한

## 15. Performance and Playability Gate

아키텍처가 일관돼도 플레이를 방해하면 완료가 아니다.

모든 공통 기반 명세는 다음을 포함한다.

- 기준 Scene과 Actor 수
- Scene 게시 Compiler 시간
- 증분 갱신 시간
- 일반 Query 지연 분포
- 경로 미리보기 응답 시간
- 서버 확정과 클라이언트 보정 횟수
- Cache hit rate와 무효화 빈도
- 메모리와 Instance 수
- 중도 참여 동기화 시간

정확한 기준값은 프로토타입 측정으로 확정할 수 있다. 다만 측정 없이 `최적화됨` 또는 `플레이에 지장 없음`으로 표시하지 않는다.

### 사용자 경험 실패 조건

다음 중 하나가 반복되면 설계를 재검토한다.

- 기본 Scene 제작에 수동 Semantic 보정이 과도하게 필요
- 문·계단·통로 배치 후 결과를 예측하기 어려움
- 클릭 이동 미리보기와 실제 경로가 자주 다름
- 플레이어 입력이 내부 컴파일 때문에 장시간 차단됨
- Query 실패가 조용히 잘못된 규칙 결과로 변환됨
- DM이 엔진 내부 ID나 그래프를 직접 고쳐야 세션을 진행할 수 있음

## 16. Failure and Degradation

공통 기반 실패는 안전하게 격리한다.

### Compiler 실패

- 마지막 정상 게시본을 유지
- 손상된 Draft를 자동 게시하지 않음
- 문제 위치와 Builder를 Diagnostics로 표시

### Query Provider 실패

- 구조화된 실패 반환
- 권위 상태 변경 금지
- 비권위 Presentation Query만 허용된 fallback 사용 가능

### Index 손상

- 관련 Chunk 또는 Layer를 재빌드
- 재빌드 전 해당 Query와 이동 확정을 제한
- Workspace 직접 탐색으로 조용히 우회하지 않음

### Presentation 실패

- 규칙 결과 유지
- 해당 연출만 생략 또는 fallback

## 17. 문서의 권위와 책임

각 결정은 하나의 권위 문서에 둔다.

예:

| 결정 | 권위 문서 |
|---|---|
| 전체 계층과 원칙 | 이 문서와 ADR-0054 |
| Scene Source와 Compiler 단계 | 후속 Scene Compiler 문서 |
| Spatial Query 타입과 Provider 계약 | 후속 Spatial Query 문서 |
| 경로 탐색과 Movement Profile | 후속 Runtime Navigation 문서 |
| Runtime Object ID와 Lifecycle | 후속 Runtime Object 문서 |
| Command 순서와 revision | 후속 Command/Logical Time 문서 |
| Remote Envelope와 rate limit | 후속 Network Contract 문서 |

다른 문서는 같은 규칙을 다시 만들지 않고 링크한다.

## 18. 하위 문서 작성 체크리스트

새 공통 기반 또는 기능 문서는 다음을 명시한다.

1. 저장 원본과 파생 Runtime 데이터는 무엇인가
2. 어느 Layer와 Provider가 소유하는가
3. 어떤 Snapshot과 revision을 읽는가
4. Query와 Command 중 어느 경로를 사용하는가
5. Cache와 Index가 무엇에 의해 무효화되는가
6. 롤백과 재접속 시 어떻게 복원되는가
7. 권한별로 어떤 정보가 보이는가
8. Roblox Instance와 Physics를 어디까지 사용하는가
9. 사용자나 DM에게 추가되는 조작 부담이 있는가
10. 기준 Scene에서 무엇을 측정하는가

하나라도 중요한 답이 없으면 `READY`로 표시하지 않는다.

## 19. 비목표

이 문서는 다음을 확정하지 않는다.

- 구체적인 NavMesh 생성 알고리즘
- Pathfinding heuristic과 waypoint smoothing
- Actor별 정확한 footprint와 squeeze 수치
- Query API의 최종 Luau 이름
- Chunk 크기와 Cache 용량
- 사용자 작성 Luau Plugin
- 모든 Runtime 데이터를 하나의 범용 Graph로 통합

이 항목은 원칙을 준수하는 하위 기획과 구현 명세에서 결정한다.

## 20. 구현 준비도

이 문서의 원칙은 `READY`다.

그러나 이 문서만으로 Spatial Query, Navigation과 Scene Compiler 구현을 시작하지 않는다. 각 시스템의 제품 동작, 데이터 계약, 실패 정책과 성능 측정 방법을 별도 문서로 확정해야 한다.
