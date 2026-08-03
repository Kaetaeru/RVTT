# 09. 확장 가능한 씬 편집 도구 모듈 구조

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`06-ingame-scene-editor-tools.md`](../../systems/scene/ingame-scene-editor-tools.md)
  - [`07-scene-editor-interaction-and-layout.md`](../../ui/scene-editor/scene-editor-interaction-and-layout.md)
  - [`08-common-input-grammar.md`](../../ui/common-input/common-input-grammar.md)
  - [`ADR-0005`](../../decisions/ADR-0005-performance-reliability-clean-code.md)
  - [`ADR-0008`](../../decisions/ADR-0008-surface-first-placement-and-ctrl-elevation.md)

## 1. 목표

씬 편집기는 초기의 벽, 바닥과 프리팹 도구만을 위해 만들어지면 안 된다.

이후 다음과 같은 도구를 추가할 때 기존 편집기 핵심 코드를 크게 수정하지 않아야 한다.

- 울타리와 난간
- 길과 도로
- 강과 수로
- 지형 스탬프
- 지붕
- 산포 브러시
- 함정과 이벤트 배치
- 새로운 게임 규칙용 영역
- 특수한 파라메트릭 구조물
- 개발 중 추가되는 캠페인 전용 제작 도구

핵심 목표:

> 새 도구는 공통 편집 서비스를 재구현하지 않고, 정해진 모듈 계약에 따라 자신의 고유 동작만 제공한다.

새로운 도구를 추가하기 위해 중앙의 거대한 `if tool == ...` 또는 `switch` 목록을 수정하는 구조를 사용하지 않는다.

---

## 2. 편집기 코어와 도구 모듈을 분리한다

### 2.1 편집기 코어

코어는 모든 도구가 공유하는 기능을 제공한다.

- 선택 모드와 배치 모드
- 상시 가상 격자 커서
- 표면 우선 배치
- 스냅과 Shift 임시 해제
- ViewY 포인터 필터
- 고스트 미리보기
- 선택, 기즈모와 3차원 선택 박스
- 인스펙터 호스트
- 플로팅·도킹 패널 호스트
- 명령 실행과 서버 검증
- 실행 취소와 다시 실행
- 씬 원본 데이터 저장
- 객체 ID와 참조 관리
- 성능 측정과 오류 격리

코어는 벽이나 도로가 구체적으로 어떻게 생성되는지 알 필요가 없다.

### 2.2 도구 모듈

도구 모듈은 자신의 고유 규칙만 제공한다.

예시:

- 벽 모듈: 시작점, 끝점, 높이, 두께와 벽 체인 생성
- 도로 모듈: 경로, 폭, 곡률과 재질 처리
- 산포 모듈: 영역, 밀도, 최소 간격과 난수 시드
- 이벤트 영역 모듈: 영역 형태와 실행할 이벤트 설정

모듈은 공통 선택, 스냅, 입력 라우팅, 실행 취소와 저장 시스템을 자체 구현하지 않는다.

---

## 3. 모듈 발견과 등록

개발자가 추가한 씬 편집 모듈은 정해진 폴더 아래의 ModuleScript 패키지로 제공한다.

개념적 구조:

```text
SceneEditor
├─ Core
│  ├─ ToolRegistry
│  ├─ EditorModeService
│  ├─ PlacementCursorService
│  ├─ PlacementService
│  ├─ SnapService
│  ├─ InspectorHost
│  ├─ PanelHost
│  ├─ SceneCommandBus
│  └─ EditHistoryService
└─ Modules
   ├─ WallTool
   ├─ FloorTool
   ├─ PrefabTool
   ├─ FenceTool
   └─ RoadTool
```

시작 시 `ToolModuleLoader`가 `Modules` 폴더의 패키지를 발견하고 `ToolRegistry`에 등록한다.

새 모듈을 추가할 때 필요한 기본 작업:

```text
새 ModuleScript 패키지 추가
→ 모듈 정의 반환
→ Registry 검증 통과
→ 도구 팔레트와 관련 호스트에 자동 등록
```

편집기 코어의 도구 목록을 직접 수정하지 않는다.

초기 범위의 모듈은 RVTT 개발자가 작성하고 빌드에 포함하는 코드 모듈이다. 사용자가 임의의 Luau 코드를 런타임에 업로드하거나 실행하는 플러그인 시스템은 보안상 지원하지 않는다.

---

## 4. 공통 모듈 계약

모든 도구 모듈은 하나의 정의 객체를 반환한다.

개념 예시:

```lua
export type SceneEditorToolDefinition = {
    id: string,
    version: number,
    displayNameKey: string,
    category: string,
    iconId: string?,
    order: number?,
    permissions: {string}?,
    dependencies: {string}?,
    capabilities: {string},

    createClientController: (context: ToolClientContext) -> ToolClientController,
    commandDefinitions: {ToolCommandDefinition},
    objectTypeDefinitions: {SceneObjectTypeDefinition}?,
    inspectorSections: {InspectorSectionDefinition}?,
    panelDefinitions: {PanelDefinition}?,
    recommendationProviders: {RecommendationProviderDefinition}?,
    snapProviders: {SnapProviderDefinition}?,
}
```

정확한 Luau 타입은 구현 단계에서 조정하지만, 다음 항목은 필수다.

- 전역적으로 고유한 모듈 ID
- 모듈 버전
- 표시 이름과 카테고리
- 클라이언트 도구 컨트롤러 생성 함수
- 서버가 검증할 명령 정의
- 사용하는 공통 기능 목록

모듈 ID 예시:

```text
rvtt.build.wall
rvtt.build.floor
rvtt.build.fence
rvtt.terrain.road
rvtt.gameplay.trigger-zone
```

파일명이나 UI 표시 이름을 저장 ID로 사용하지 않는다.

---

## 5. 도구 생명주기

모든 도구는 같은 생명주기를 따른다.

```text
등록
→ 활성화
→ 작업 시작
→ 미리보기 갱신
→ 확정 또는 취소
→ 다음 작업 대기
→ 비활성화
```

개념적 인터페이스:

```lua
export type ToolClientController = {
    activate: (self: ToolClientController, session: ToolSession) -> (),
    deactivate: (self: ToolClientController) -> (),
    beginOperation: (self: ToolClientController, input: ToolInput) -> (),
    updateOperation: (self: ToolClientController, input: ToolInput) -> (),
    confirmOperation: (self: ToolClientController) -> ToolCommand?,
    cancelOperation: (self: ToolClientController) -> (),
    destroy: (self: ToolClientController) -> (),
}
```

모든 이벤트 연결, 임시 인스턴스와 입력 문맥은 `deactivate` 또는 `destroy`에서 반드시 정리한다.

도구 전환 후 이전 도구의 고스트, 입력 연결이나 RenderStep이 남아서는 안 된다.

---

## 6. 모듈이 받는 공통 컨텍스트

모듈은 전역 서비스를 직접 찾아다니지 않고 제한된 `ToolClientContext`를 주입받는다.

제공 후보:

- `placementCursor`
- `placement`
- `pointerQuery`
- `snap`
- `preview`
- `selection`
- `inspector`
- `panels`
- `commands`
- `history`
- `sceneObjects`
- `viewY`
- `inputContext`
- `localization`
- `telemetry`

개념 예시:

```lua
local result = context.placement:resolve({
    pointerRay = pointerRay,
    surfaceProfile = "HorizontalOrVirtualPlane",
    snapProfile = "BuildDefault",
})
```

벽 도구와 울타리 도구가 각각 표면 판정과 가상 격자 계산을 다시 구현하지 않는다.

컨텍스트에 없는 내부 서비스에 접근하는 것을 기본적으로 금지한다. 이를 통해 결합도를 낮추고 테스트 대역을 제공할 수 있다.

---

## 7. 기능은 Capability로 요청한다

각 모듈은 필요한 공통 능력을 선언한다.

예시:

```text
PlacementCursor
SurfacePlacement
ContinuousPlacement
Inspector
UndoableCommands
Selection
TransformGizmo
CustomPanel
CustomSnapProvider
SceneObjectType
```

Registry는 등록 시 다음을 검사한다.

- 필수 capability가 코어에서 지원되는가
- 선언하지 않은 위험한 확장점을 사용하지 않는가
- 의존 모듈이 존재하고 버전이 맞는가
- 동일한 명령 또는 오브젝트 타입 ID가 중복되지 않는가

도구가 자신의 요구사항을 숨겨서 런타임 중간에 실패하지 않게 한다.

---

## 8. 입력 통합

씬 편집 모듈은 `UserInputService`에서 물리 키를 직접 감시하지 않는다.

공통 입력 라우터에서 의미 동작을 받는다.

씬 편집의 기본 의미 동작 후보:

```text
Cancel
Confirm
PrimaryPointer
CameraPointer
TemporarySnapBypass
VerticalPlacementAdjust
DuplicatePlacement
```

규칙:

- Q는 `Cancel`을 통해 현재 작업 또는 배치 모드를 취소한다.
- E는 해당 도구가 명시적인 최종 확정 단계를 제공할 때만 `Confirm`으로 사용한다.
- Shift는 공통 스냅 서비스의 임시 해제로 처리한다.
- Ctrl 수직 이동은 공통 배치 높이 조절로 처리한다.
- 도구 모듈은 `1–5` 숫자 슬롯을 점유하지 않는다.
- 도구별 특수 기능은 인스펙터, 툴바 버튼, 컨텍스트 메뉴 또는 모듈 패널로 제공한다.

모듈이 정말 새로운 입력 의미를 필요로 하면 물리 키가 아니라 의미 동작을 제안하고, 코어 입력 교과서와 충돌 검토를 거쳐 추가한다.

---

## 9. 도구 팔레트와 UI 등록

도구 팔레트는 Registry의 메타데이터로 자동 구성한다.

모듈이 제공하는 기본 UI 정보:

- 카테고리
- 표시 이름 번역 키
- 아이콘
- 정렬 우선순위
- 사용 권한
- 실험 기능 여부
- 간단한 도움말

예시:

```lua
category = "Build"
displayNameKey = "editor.tool.fence"
iconId = "fence"
order = 40
```

새 도구가 추가됐다고 도구 팔레트 UI 코드를 수정하지 않는다.

도구가 별도 패널을 필요로 하면 `PanelHost`에 패널 정의를 등록한다.

패널은 기존 도킹 시스템을 그대로 사용한다.

- 플로팅
- 가장자리 도킹
- 탭 묶기
- 크기 변경
- 사용자 레이아웃 저장

모듈이 화면에 고정 위치의 독자적인 창을 직접 생성하지 않는다.

---

## 10. 인스펙터 확장

도구와 씬 오브젝트는 인스펙터 필드를 선언형 스키마로 제공한다.

개념 예시:

```lua
inspectorSections = {
    {
        id = "fence.geometry",
        titleKey = "editor.fence.geometry",
        fields = {
            { id = "height", type = "number", unit = "stud" },
            { id = "postSpacing", type = "number", unit = "stud" },
            { id = "followSlope", type = "boolean" },
        },
    },
}
```

공통 필드 타입 후보:

- number
- vector3
- angle
- boolean
- enum
- color
- material
- asset reference
- object reference
- list
- custom read-only status

인스펙터 호스트가 다음을 처리한다.

- 필드 UI 생성
- 수치 검증
- 단위 표시와 변환
- 혼합값 표시
- 실행 취소 트랜잭션
- 권한과 읽기 전용 상태
- 번역

모듈이 자신의 인스펙터 창 전체를 새로 만들 필요가 없다. 특수한 편집기가 필요한 경우에만 제한된 커스텀 필드 렌더러를 등록한다.

---

## 11. 씬 오브젝트 타입 등록

파라메트릭 도구는 생성 결과를 단순 Part 묶음으로 저장하지 않는다.

모듈은 자신이 소유하는 씬 오브젝트 타입을 등록할 수 있다.

예시:

```text
rvtt.object.wall-chain
rvtt.object.floor-polygon
rvtt.object.fence-path
rvtt.object.road-spline
rvtt.object.scatter-group
```

오브젝트 타입 정의가 제공해야 할 책임:

- 저장 스키마
- 스키마 버전
- 월드 결과 생성기
- 선택 단위와 선택 AABB
- 인스펙터 스키마
- 이동·시야 의미 데이터 생성
- 복제 규칙
- 삭제와 참조 정리
- 마이그레이션

선택 시스템은 구체적인 도구 타입을 하드코딩하지 않고 오브젝트 타입 정의에서 선택 경계와 선택 단위를 요청한다.

---

## 12. 미리보기와 명령 확정을 분리한다

도구 컨트롤러는 클라이언트에서 즉시 고스트와 가이드를 표시한다.

실제 씬 변경은 명령으로 서버에 요청한다.

```text
로컬 입력
→ ToolClientController
→ 공통 서비스로 미리보기 계산
→ ToolCommand 생성
→ 서버 ToolCommandHandler 검증
→ 씬 원본 변경
→ 생성 결과와 의미 데이터 부분 갱신
→ 실행 이력과 참가자 동기화
```

각 명령 정의는 최소한 다음을 제공한다.

- 고유한 명령 타입 ID
- 입력 데이터 스키마
- 권한 검사
- 서버 유효성 검사
- 원본 데이터 변경
- 실행 취소를 위한 역연산 또는 이전 상태
- 영향 영역 계산

모듈이 RemoteEvent를 직접 만들거나 씬 Workspace를 직접 변경하지 않는다.

---

## 13. 실행 취소와 트랜잭션

모든 모듈 작업은 공통 `SceneCommandBus`와 `EditHistoryService`를 통과한다.

예시:

```text
울타리 경로 하나 생성
→ 내부 기둥 14개와 난간 13개 생성
→ 사용자 이력에는 "울타리 생성" 한 줄
```

모듈은 여러 내부 변경을 하나의 트랜잭션으로 묶는다.

지원해야 할 항목:

- 실행
- 취소
- 다시 실행
- 작업 이름
- 영향받은 원본 오브젝트 ID
- 영향 영역
- 저장 상태와의 관계

공통 이력 구조를 우회하는 도구는 등록하지 않는다.

---

## 14. 저장 스키마와 마이그레이션

모듈이 생성한 씬 데이터는 모듈 ID와 오브젝트 타입 버전을 함께 저장한다.

개념 예시:

```text
typeId: rvtt.object.fence-path
schemaVersion: 2
ownerModule: rvtt.build.fence
```

모듈의 저장 스키마가 변경되면 해당 모듈이 마이그레이션을 제공한다.

```lua
migrations = {
    [1] = migrateV1ToV2,
    [2] = migrateV2ToV3,
}
```

마이그레이션이 없는 미지원 버전은 조용히 깨진 상태로 로드하지 않는다.

- 안전한 읽기 전용 대체 표시
- 누락 모듈 경고
- 원본 데이터 보존
- 게시 차단 또는 명시적 복구 선택지

모듈을 제거해도 해당 데이터를 즉시 삭제하지 않는다.

---

## 15. 스마트 추천과 스냅 확장

모듈은 제한된 provider 인터페이스로 편집기 기능을 확장할 수 있다.

### 추천 Provider

예시:

- 폐쇄된 울타리 안에 영역 생성 추천
- 도로 끝을 기존 도로에 연결 추천
- 계단 상단에 난간 추가 추천

추천은 자동 실행하지 않고 사용자가 승인하는 명령을 반환한다.

### 스냅 Provider

기본 스냅으로 해결되지 않는 경우에만 커스텀 스냅 후보를 제공한다.

예시:

- 도로 중심선
- 울타리 포스트 간격
- 곡선 접선

커스텀 Provider도 공통 `SnapService`를 통해 우선순위, Shift 임시 해제와 시각 표시를 공유한다.

---

## 16. 권한과 서버 검증

클라이언트 모듈은 편집 권한을 부여하지 않는다.

서버가 검증할 항목:

- 사용자가 현재 씬을 편집할 수 있는가
- 해당 도구 또는 모듈 사용 권한이 있는가
- 명령 데이터가 스키마와 범위를 만족하는가
- 참조한 에셋과 오브젝트가 존재하는가
- ViewY 같은 로컬 보기 상태를 권한 근거로 사용하지 않았는가
- 오브젝트 수와 크기가 허용 한도를 넘지 않는가
- 다른 명령과 충돌하지 않는가

모듈별 서버 처리기도 공통 명령 버스 안에서만 실행한다.

---

## 17. 성능과 오류 격리

도구 모듈 하나가 전체 편집기를 느리게 만들지 않도록 한다.

규칙:

- 비활성 도구는 매 프레임 업데이트하지 않는다.
- 활성 도구도 필요할 때만 포인터와 미리보기를 갱신한다.
- 전체 Workspace를 반복 순회하지 않는다.
- 공통 공간 인덱스와 객체 Registry를 사용한다.
- 미리보기는 로컬 전용이며 확정 전 서버에 복제하지 않는다.
- 대량 결과는 개별 Script가 아니라 원본 데이터와 생성기로 관리한다.
- 모듈별 CPU 시간, 미리보기 인스턴스 수와 명령 비용을 측정할 수 있어야 한다.

모듈 활성화나 갱신 중 오류가 발생하면:

- 현재 모듈 작업만 중단
- 임시 고스트와 입력 문맥 정리
- 선택 모드로 안전 복귀
- 오류 로그에 모듈 ID와 버전 기록
- 다른 편집 도구는 계속 사용 가능

---

## 18. 기능 플래그와 의존성

새 모듈은 개발 중 기능 플래그로 숨길 수 있다.

```text
stable
experimental
internal
campaign-restricted
```

모듈 의존성은 ID와 최소 버전으로 선언한다.

예시:

```text
rvtt.build.roof
→ rvtt.object.wall-chain >= 2
→ rvtt.object.floor-polygon >= 1
```

의존성이 충족되지 않으면 도구를 활성화하지 않고 원인을 도구 팔레트에 표시한다.

순환 의존성은 Registry 등록 단계에서 거부한다.

---

## 19. 테스트 가능한 구조

각 도구 모듈은 공통 서비스의 테스트 대역을 주입받아 독립적으로 검사할 수 있어야 한다.

필수 테스트 후보:

- 등록 정의 검증
- 활성화와 비활성화 시 리소스 정리
- Q 취소와 E 확정 상태 전환
- 배치 명령 생성
- 서버 입력 거부와 승인
- 실행 취소와 다시 실행
- 저장 후 다시 로드
- 이전 버전 데이터 마이그레이션
- ViewY와 선택 필터
- Shift 스냅 해제
- 성능 한도

새 모듈은 이 공통 계약 테스트를 통과해야 등록 가능 상태로 본다.

---

## 20. 울타리 모듈 추가 예시

새 울타리 도구를 추가한다고 가정한다.

울타리 모듈이 직접 구현할 것:

- 경로 지점 입력
- 기둥 간격 계산
- 울타리 시각 생성 파라미터
- 전용 인스펙터 필드
- 울타리 이동 차단 의미

공통 코어에서 받을 것:

- 가상 격자와 표면 우선 커서
- 클릭과 드래그 입력
- Q 취소
- Shift 스냅 해제
- 경로 고스트
- 서버 명령 전송
- 실행 취소
- 선택 AABB
- 복제와 스포이드
- 도킹 인스펙터
- 저장과 마이그레이션 호스트

추가 작업 흐름:

```text
FenceTool 패키지 추가
→ rvtt.build.fence 등록
→ 도구 팔레트 Build 카테고리에 자동 표시
→ 선택 시 공통 배치 모드 활성화
→ 확정 명령이 공통 이력과 서버 검증을 통과
```

기존 벽, 바닥, 프리팹 도구의 코드는 수정하지 않는다.

---

## 21. 확정하는 방향

1. 씬 편집기는 고정된 도구 목록이 아니라 Registry 기반 모듈 호스트로 만든다.
2. 새 도구는 정해진 ModuleScript 계약으로 등록한다.
3. 중앙 도구 분기문을 늘리는 방식으로 확장하지 않는다.
4. 선택, 배치, 스냅, ViewY, 고스트, 인스펙터, 명령과 이력은 코어가 제공한다.
5. 모듈은 자신의 고유한 도형, 파라미터와 규칙만 구현한다.
6. 모듈은 물리 키, RemoteEvent와 Workspace 변경을 직접 소유하지 않는다.
7. 씬 편집 모듈은 1–5 숫자 행동 슬롯을 점유하지 않는다.
8. 인스펙터와 패널은 선언형 스키마와 공통 호스트로 확장한다.
9. 파라메트릭 결과는 버전이 있는 씬 오브젝트 타입으로 등록한다.
10. 모든 변경은 서버 검증 가능한 명령과 공통 실행 이력을 통과한다.
11. 모듈은 저장 스키마 변경 시 마이그레이션을 제공한다.
12. 비활성 모듈은 편집 성능 비용을 만들지 않아야 한다.
13. 모듈 오류는 해당 도구에 격리하고 편집기 전체를 중단하지 않는다.
14. 초기에는 개발자가 빌드에 포함하는 신뢰된 코드 모듈만 지원한다.

---

## 22. 후속 논의 항목

1. 실제 Luau `SceneEditorToolDefinition` 타입
2. ToolRegistry 자동 발견 폴더와 로딩 순서
3. 도구 카테고리와 팔레트 정렬 규칙
4. 기본 Inspector 필드 타입 목록
5. 커스텀 필드와 커스텀 패널 허용 범위
6. SceneCommand 입력 스키마 형식
7. 모듈별 권한과 기능 플래그 저장 방식
8. 공통 계약 테스트 실행 방식
9. 누락 모듈 씬 데이터를 표시하는 대체 오브젝트
10. 캠페인 전용 데이터 모듈과 코드 모듈의 경계
