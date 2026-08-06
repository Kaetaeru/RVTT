# 씬 편집기 조작과 레이아웃 V2

- 상태: `CURRENT · ADR-0089 ALIGNED`
- 작성일: 2026-08-06
- 대체 대상: `scene-editor-interaction-and-layout.md`의 기본 창 배치
- 상위 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)

## 1. 목표

RVTT Scene Editor는 전장 자체를 중심에 두고 Tile·Prop·Prefab을 연속 배치하는 Build Mode다. TaleSpire형 작업 흐름을 참고하되 RVTT의 Surface-first Placement, ViewY, Semantic Object와 Atomic Publish 구조를 사용한다.

## 2. 기본 레이아웃

```text
┌──────────────────────────────────────────────────────────────┐
│ Scene | Save | Publish | Select Move Rotate Scale Measure   │
├──────────────┬───────────────────────────────────────────────┤
│ Left         │                                               │
│ Inspector    │                Build Viewport                 │
│ Hierarchy    │                                               │
│ Transform    │                                               │
│ Properties   │                                               │
├──────────────┴───────────────────────────────────────────────┤
│ Bottom Catalog: Tiles | Props | Prefabs | Blueprints | 🔎   │
└──────────────────────────────────────────────────────────────┘
```

- Inspector 기본 위치는 왼쪽이다.
- Catalog 기본 위치는 하단 Tray다.
- 중앙 Viewport는 가장 큰 영역을 가진다.
- 창 도킹은 허용하지만 `Reset Layout`은 이 배치로 돌아온다.

## 3. Top Toolbar

- Scene 선택과 상태
- Save Draft
- Validate Candidate
- Publish
- Selection Mode
- Move·Rotate·Scale Gizmo
- Measure
- ViewY
- Snap·Grid
- Undo·Redo
- Test Play

Scene 선택창은 편집기 진입점이며 현재 Scene의 Draft·Published·Dirty·Validation 상태를 표시한다.

## 4. Left Inspector

탭:

```text
Selection
Hierarchy
Transform
Appearance
Interaction
Lighting
Navigation
Permissions
```

다중 선택은 공통 값을 표시하고 다른 값은 `혼합` 상태로 표시한다. 수치 입력 하나는 Undo history의 한 작업이다.

## 5. Bottom Catalog

탭:

```text
Tiles
Props
Prefabs
Blueprints
Recent
Favorites
```

기능:

- Search
- Category·Tag Filter
- Thumbnail·List density
- Current Material/Variant
- Recent placement
- Favorite pin
- Slab/Blueprint publish·import entry

Catalog Item 선택 시 Placement Mode로 진입한다.

## 6. Selection과 Placement

```text
Selection Mode
→ 기존 Object 선택·다중 선택·Gizmo 편집

Placement Mode
→ Ghost를 Cursor에 표시
→ Click/Drag로 배치
→ 같은 Ghost 유지
→ Q 또는 Select Tool로 종료
```

한 번 배치했다고 Selection Mode로 자동 복귀하지 않는다.

## 7. 공통 조작

- Shift: 현재 Snap 임시 해제
- Ctrl+D: 선택 대상 복제 Ghost Placement
- Eyedropper: 대상 설정을 읽고 Placement Mode
- Q: 현재 Placement/Selection Context 한 단계 취소
- E: 명시적 Preview Confirm이 있을 때만 실행
- Middle Drag: Camera Orbit
- Wheel: Zoom

## 8. Live DM Quick Edit와 구분

Live DM Quick Edit:

- 선택 Object 이동·회전
- 문·조명·Fog·Visibility 상태
- Actor 위치·상태
- 빠른 Scene 설정

Full Scene Editor:

- Catalog
- 구조 배치
- Blueprint
- Navigation·Lighting authoring
- Candidate validation·Publish

Live Quick Edit가 Bottom Catalog 전체를 열지 않는다.

## 9. Publish

```text
Draft Edit
→ Candidate Compile
→ Diagnostic
→ Test Play
→ Publish Confirm
→ Atomic Activation
```

일부 실패 결과를 Published Scene에 섞지 않는다.

## 10. Acceptance

- Left Inspector가 기본 위치다.
- Bottom Catalog Tray가 기본 위치다.
- Asset 선택 후 반복 배치된다.
- Q가 Placement를 종료하고 ESC는 Gameplay/Edit 의미가 없다.
- Shift Snap 해제가 저장 설정을 바꾸지 않는다.
- Candidate 실패 시 Published Scene을 유지한다.
- 16:9·21:9·UI Scale 0.80–1.40에서 Viewport가 우선된다.
