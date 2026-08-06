# Semantic Scene, World와 Runtime Build 모델

- 상태: 확정
- 문서 종류: System Planning
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 새 Scene 생성 시 제공할 기본 Entry Anchor 수
  - Build 완료 알림과 자동 저장 표시 시간
  - Runtime Quick Edit의 기본 유지 범위
  - 구조적 Live Patch 시 기본 일시정지 정책
  - Scene 목록의 기본 정렬과 미리보기 이미지 갱신 시점
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0005`](../../decisions/ADR-0005-performance-reliability-clean-code.md)
  - [`ADR-0006`](../../decisions/ADR-0006-rigless-3d-token-continuous-movement.md)
  - [`ADR-0054`](../../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0057`](../../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)
- 관련 문서:
  - [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`Semantic Scene 기반 Navigation Authoring Pipeline`](../navigation/navigation-authoring-pipeline.md)
  - [`인게임 Scene Editor와 맵 제작 도구`](ingame-scene-editor-tools.md)

## 1. 목적

Scene은 단순한 Roblox Model 묶음이 아니다.

RVTT의 Scene은 다음 세 상태를 분리해 관리한다.

```text
DM이 편집하는 Scene Source
→ Compiler가 만든 Compiled Runtime Scene Build
→ 세션 중 변하는 Authoritative Runtime State
```

이 문서는 DM이 Scene을 만들고, Runtime을 생성하고, 검토하고, 게시하고, 실제 세션에서 사용하는 전체 흐름을 정의한다.

Navigation의 내부 경로 자료구조, Spatial Query의 API와 Compiler Artifact Schema는 관련 Architecture 문서가 소유한다.

## 2. 사용자 목표

DM은 다음 흐름으로 Scene을 사용할 수 있어야 한다.

```text
Scene 만들기
→ 벽·바닥·문·계단·소품 배치
→ 의미 있는 예외와 연결 설정
→ Scene Runtime 만들기
→ 오류 또는 검토 항목 확인
→ 게시
→ 플레이 시작
```

일반적인 Scene에서는 다음이 필요하지 않아야 한다.

- 내부 Polygon과 Graph 편집
- Model 안에 기술용 Attribute 삽입
- 문 상태를 Navigation, 시야와 상호작용에서 각각 설정
- Scene 파일을 Roblox Studio에서 별도 가공
- 플레이 시작 전 Workspace 구조 수동 검사

## 3. World와 Scene의 관계

### 3.1 Campaign World

Campaign World는 여러 Scene의 논리적 집합이다.

```text
CampaignWorld
├─ campaignId
├─ sceneRecords[]
├─ defaultSceneId?
├─ worldMetadata
├─ sceneLinkDefinitions[]
└─ revision
```

RVTT는 모든 장소를 하나의 거대한 Seamless World로 합칠 것을 요구하지 않는다.

마을, 던전, 건물 내부와 전투 전용 장소는 별도 Scene이 될 수 있다.

### 3.2 Scene은 권위 경계다

각 Scene은 다음을 독립적으로 가진다.

- Scene Source Revision
- Published Build
- Runtime Dynamic State
- 권한별 공개 정보
- Entry와 Exit Anchor
- 저장·복구 기록

다른 Scene으로 이동하는 연결은 `sceneId + entryAnchorId`를 사용한다.

```text
현재 Scene Exit Anchor
→ Scene Transition 요청
→ 대상 Scene Build 준비 확인
→ 대상 Entry Anchor 배치 검증
→ 전환 확정
```

정확한 Streaming과 Client Ready 순서는 후속 계약에서 정의한다.

## 4. Scene Record

```text
SceneRecord
├─ sceneId
├─ campaignId
├─ displayName
├─ description?
├─ thumbnailRef?
├─ authoringStatus
├─ currentSourceRevision
├─ publishedBuildId?
├─ lastKnownGoodBuildId?
├─ activeSessionBindings[]
├─ entryAnchorIds[]
├─ sourcePackDependencies[]
├─ createdBy
├─ updatedAt
└─ revision
```

Scene 이름을 바꾸어도 `sceneId`는 바뀌지 않는다.

Scene 복제는 새로운 `sceneId`와 Source Object ID 집합을 만든다.

## 5. 세 가지 Scene 상태

### 5.1 Scene Source

DM이 편집하고 저장하는 원본이다.

포함:

- 배치된 Asset과 Transform
- 벽, 방, 계단 같은 Parametric Object 원본
- 외부 Semantic Profile 참조
- Scene Instance Override
- Rule Region과 Trigger
- 오브젝트와 Anchor 사이의 명시적 Link
- Entry·Exit Anchor
- 조명과 Scene 표시 설정
- DM Metadata

포함하지 않음:

- Runtime Polygon과 Path Node
- Spatial Index
- Roblox Instance 참조
- 플레이 중 Actor 위치
- 현재 문 열림 상태
- Compiler Cache

### 5.2 Compiled Runtime Scene Build

Scene Source를 검증해 만든 불변 Runtime Package다.

포함:

- Navigation Layer
- Visibility Layer
- Interaction Layer
- Rule Layer
- Permission-aware Metadata
- Runtime Object Blueprint
- State Binding
- Spatial Index와 Chunk Manifest
- Dependency Graph와 Diagnostic Summary

Build는 고유 `buildId`를 가진다.

### 5.3 Authoritative Runtime State

세션 중 서버가 변경하는 상태다.

포함:

- Actor 위치와 상태
- 문, 함정, 상자와 파괴 오브젝트의 현재 상태
- 활성 Scene Effect와 Rule Volume
- Fog 공개 상태
- Encounter와 Turn 상태
- Runtime Quick Edit Overlay

Runtime State는 Scene Source를 자동 수정하지 않는다.

## 6. Scene 제작 흐름

### 6.1 새 Scene 만들기

```text
새 Scene
→ Scene 이름과 기본 설정
→ Scene Source와 기본 Entry Anchor 생성
→ 편집 모드 진입
```

빈 Scene도 안정적인 `sceneId`, Source Schema Version과 Authoring Revision을 가진다.

### 6.2 Asset과 구조 배치

DM은 다음을 배치한다.

- 벽과 방
- 바닥과 지형
- 문과 창문
- 계단, 사다리와 연결 지점
- 프리팹과 소품
- Rule Region과 Trigger
- 조명과 장면 표시 요소

Editor Tool은 최종 Runtime Layer를 직접 만들지 않는다.

```text
Editor 입력
→ Scene Source 변경
→ Authoring Revision 증가
→ Runtime Build 갱신 필요 표시
```

### 6.3 의미와 예외 편집

대부분의 Asset은 Asset Library의 Semantic Profile을 자동 사용한다.

DM은 자동 의미가 맞지 않는 경우에만 다음을 수정한다.

- 이 Scene에서만 다른 Semantic Profile 사용
- 특정 오브젝트를 규칙 Layer에서 제외
- 명시적 Obstacle, Support, Rule Field Region
- 문·레버·함정 사이 Link
- 계단, 사다리, Jump와 Drop 연결
- 비밀 정보와 공개 정책

DM은 `Walkable`, `Deniable`, Polygon ID와 Portal 폭을 편집하지 않는다.

## 7. Scene Runtime 만들기

DM이 `Scene Runtime 만들기 / 갱신`을 실행하면:

```text
Source 저장 확인
→ Asset과 Profile 참조 확인
→ Semantic Contribution 생성
→ Runtime Layer와 Index Build
→ Cross-layer 상태 연결 검사
→ Entry Anchor와 Critical Route 검사
→ Client Disclosure Package 검사
→ Candidate Build 완성
```

Compiler가 자동으로 만든 작은 수치 보정은 결과 요약에서 확인할 수 있다.

의미가 불명확한 문제는 DM에게 내부 자료구조가 아니라 선택 가능한 해석으로 제시한다.

예:

```text
이 계단의 위쪽 연결을 확정할 수 없습니다.

1. 위층 복도 Anchor에 연결
2. 발코니 Anchor에 연결
3. 이동 연결 없이 장식으로 처리
```

## 8. Scene 상태 표시

DM UI는 다음 상태를 사용한다.

```text
draft
runtime_outdated
building
review_recommended
ready_to_publish
published
build_failed
```

### draft

새 Scene이거나 아직 정상 Runtime Build가 없다.

### runtime_outdated

Published Build 이후 Scene Source가 변경되었다.

현재 Build는 계속 사용할 수 있지만 새 변경은 반영되지 않았다.

### building

Candidate Build를 생성 중이다.

현재 Published Build와 활성 세션은 영향을 받지 않는다.

### review_recommended

Build는 사용할 수 있지만 확인하면 좋은 경고가 있다.

### ready_to_publish

모든 필수 검증을 통과한 Candidate Build가 있다.

### published

Candidate Build가 Scene의 기본 Published Build가 되었다.

### build_failed

Candidate Build 생성에 실패했다.

Last Known Good Build가 있으면 기존 Scene은 계속 사용할 수 있다.

## 9. 게시

게시 전 최소 조건:

- 필수 Asset과 Semantic Profile 참조 정상
- 필수 Layer와 Index Build 성공
- Entry Anchor 유효
- 게시 차단 Critical Route 정상
- Cross-layer State Binding 일치
- Secret Disclosure 검사 통과
- Build Manifest와 Chunk 참조 정상

게시 흐름:

```text
Ready Candidate Build 선택
→ 게시 확인
→ Build Manifest 봉인
→ Published Build Pointer 원자적 교체
→ Scene 상태 published
```

Layer 일부만 새 Build로 교체할 수 없다.

## 10. 테스트 플레이

DM은 게시 전 Candidate Build에서 테스트 플레이를 실행할 수 있다.

테스트 항목:

- Entry Anchor에서 시작
- 대표 Actor로 클릭 이동
- 문 열기와 닫기
- 시야 차단과 상호작용
- Critical Route
- Trigger와 Rule Field 진입
- Scene Exit와 대상 Entry Anchor

테스트 플레이의 Runtime State는 기본적으로 실제 Campaign 진행 상태에 반영하지 않는다.

DM이 명시적으로 선택한 경우에만 테스트 결과 일부를 Authoring Source나 Campaign State에 반영한다.

## 11. 활성 세션

활성 세션은 다음 조합을 사용한다.

```text
sceneId
+ buildId
+ dynamicStateRevision
```

플레이어가 Scene에 입장할 때 서버는 정확한 Build와 권한별 Runtime View를 준비한다.

Scene Source가 편집 중이거나 새 Candidate Build가 존재한다는 이유만으로 현재 세션의 Build를 바꾸지 않는다.

## 12. Live Authoring과 Runtime Quick Edit

### 12.1 구조적 Authoring 변경

다음은 Scene Source를 변경하고 새 Candidate Build가 필요하다.

- 벽과 바닥 구조 변경
- 계단과 Portal 연결 변경
- 대형 오브젝트 배치·삭제
- Semantic Profile과 Rule Region 변경
- Scene Entry·Exit 구조 변경

활성 세션에 적용하려면 세션을 안전 지점에서 일시정지하거나 호환 가능한 Patch 절차를 사용한다.

### 12.2 Runtime Quick Edit

다음은 Runtime Command와 Semantic Overlay로 처리할 수 있다.

- 임시 차단 영역
- 즉석 위험 지역
- 임시 조명·가림 Field
- DM이 세션 중 만든 일회성 Trigger
- 현재 문 상태와 오브젝트 상태 조정

Quick Edit는 활성 Runtime에 즉시 적용할 수 있지만 기본적으로 Scene Source를 바꾸지 않는다.

### 12.3 Source로 승격

DM이 임시 변경을 영구 Scene 요소로 남기려면 `Source로 승격`을 실행한다.

```text
Runtime Overlay 선택
→ 저장 가능한 Authoring 데이터로 변환
→ Scene Source에 새 ID로 추가
→ Authoring Revision 증가
→ 새 Candidate Build 필요
```

Runtime State를 그대로 직렬화해 Scene Source에 복사하지 않는다.

## 13. Build 실패와 복구

Candidate Build가 실패하면:

- Published Build Pointer를 바꾸지 않는다.
- 활성 세션을 중단하지 않는다.
- 실패한 Layer 일부를 Runtime에 적용하지 않는다.
- 관련 Source Object와 위치를 표시한다.
- 수정 후 영향 범위만 다시 Build할 수 있다.

Last Known Good Build도 손상되었다면 Source에서 전체 Build를 다시 생성한다.

Compiled Artifact와 Cache는 재생성 가능한 데이터이므로 영구 Authoring 원본처럼 취급하지 않는다.

## 14. Scene 삭제와 보관

Scene 삭제는 즉시 영구 제거보다 보관 상태를 우선한다.

```text
active
→ archived
→ pending_deletion
→ deleted
```

다음 참조가 있으면 삭제 전 경고한다.

- 다른 Scene의 Transition Link
- Campaign 기본 Scene
- 저장된 Character 위치
- Journal Link
- 활성 세션
- Snapshot과 Rollback 기록

보관된 Scene은 새 세션 진입 대상에서 제외하지만 복구할 수 있다.

## 15. 권한과 공개

### DM

- Scene Source 전체 편집
- Compiler Diagnostic 확인
- Secret Metadata 확인
- Build와 게시 관리
- Runtime Quick Edit
- Live Patch 승인

### Player

- 권한에 맞는 Published Runtime View만 수신
- 발견되지 않은 비밀문과 함정의 실제 Runtime Definition을 수신하지 않음
- Scene Source와 Compiler Diagnostic에 접근하지 않음

### Observer

- 별도 Information Visibility 정책에 따른 View 사용
- 관찰 권한이 Actor 제어권이나 DM Metadata 권한을 부여하지 않음

## 16. 저장과 Revision

Scene은 다음 Revision을 구분한다.

```text
Authoring Revision
→ Scene Source 변경

Build ID
→ 특정 Source와 Compiler Version으로 만든 불변 Runtime Build

Dynamic State Revision
→ 플레이 중 상태 변경

Snapshot ID
→ 특정 Build와 Dynamic State의 조회 시점
```

네 값을 하나의 `sceneRevision`으로 합치지 않는다.

자동 저장은 Scene Source Draft를 보존한다. 게시 여부와 Build 상태는 별도 기록한다.

## 17. 성능 원칙

- Scene Source 편집 중 매 입력마다 전체 Build를 만들지 않는다.
- 작은 변경은 Dependency Graph로 영향 범위를 계산한다.
- Build는 Editor 작업 큐에서 수행하고 현재 Published Runtime을 방해하지 않는다.
- 동일 Asset과 Semantic Profile 결과는 안전하게 Cache할 수 있다.
- 활성 세션은 문자열, Model 이름과 임의 Attribute를 반복 해석하지 않는다.
- Runtime Query는 Compiled Layer와 Index를 사용한다.
- Scene 전체 Build가 필요한 경우에도 진행 상태와 취소를 제공한다.

## 18. 실패 UX

나쁜 표시:

```text
Provider 3 failed at node 8421
Nav graph invalid
```

좋은 표시:

```text
북쪽 계단이 어느 위층 바닥과 연결되는지 확정할 수 없습니다.
계단을 선택해 연결 대상을 지정하세요.
```

오류 선택 시:

- 카메라가 문제 위치로 이동
- 관련 오브젝트 선택
- 현재 Source 의미 표시
- 추천 수정 선택지 제공
- 수정 후 해당 영역만 다시 검사

## 19. 완료 기준

Scene 시스템 구현 명세는 최소한 다음 사용자 흐름을 검증해야 한다.

1. 새 Scene을 만들고 Source를 저장할 수 있다.
2. Attribute 없는 일반 Asset을 Semantic Profile과 함께 배치할 수 있다.
3. Scene Runtime Build를 생성하고 게시할 수 있다.
4. Candidate Build 실패 중에도 기존 Published Scene을 플레이할 수 있다.
5. Source 변경 후 `runtime_outdated` 상태가 표시된다.
6. 문 상태가 Navigation, Visibility와 Interaction에서 일관되게 바뀐다.
7. Secret Object가 권한 없는 Client View에 포함되지 않는다.
8. Runtime Quick Edit가 Source를 자동 변경하지 않는다.
9. Overlay를 명시적으로 Source로 승격할 수 있다.
10. Scene Transition이 안정적 Scene ID와 Entry Anchor를 사용한다.
11. Build와 Dynamic State Revision을 혼합하지 않고 복구할 수 있다.
12. Scene 삭제 전 외부 참조와 활성 세션을 확인한다.

## 20. 비목표

- 모든 Campaign Scene을 하나의 Seamless World로 합치지 않는다.
- Scene Editor를 정밀 3D 모델링 프로그램으로 만들지 않는다.
- Runtime Polygon, Node와 Spatial Index를 일반 DM 편집 항목으로 노출하지 않는다.
- Roblox Workspace 구조를 Scene 저장 원본으로 사용하지 않는다.
- 새 Build를 활성 세션에 자동 강제 적용하지 않는다.
- Scene Streaming의 정확한 클라이언트 Ready Protocol을 이 문서에서 확정하지 않는다.
