# RVTT DM Guide

- 상태: `CURRENT · TARGET_EXPERIENCE`
- 최종 갱신일: 2026-08-06
- User Guide Hub: [`../README.md`](../README.md)
- HTML 순서: [`UI-EXAMPLES.md`](UI-EXAMPLES.md)
- 상위 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)

## 1. 세션 참가자와 Character 배정

DM이 아닌 참가자는 Observer로 들어온다. DM은 `Players` 도구에서 Character를 배정한다.

```text
Observer 확인
→ Character 선택
→ Owner 배정 또는 이전
→ Controller 배정
→ 적용 시점 확인
→ Player Projection 활성화
```

배정이 성공한 순간 참가자는 해당 Character의 캠페인 Owner가 된다. 이후 Controller는 연결 종료·위임·안전 경계에서 별도로 바꿀 수 있다.

진행 중 판정이나 Transaction 중간에는 Controller를 변경하지 않는다.

## 2. Live DM 기본 화면

```text
상단
→ Scenes · Scene Editor · Quick Edit · Fog · Time · Encounter · Journal · Players · Rollback

왼쪽
→ Selection Inspector

중앙
→ Live Scene

선택 대상 근처
→ Quick Action Popover
```

필요한 상세 Panel은 도킹할 수 있지만 기본 배치는 위 구조다.

## 3. 상단 도구

### Scenes

- 현재 Scene과 Draft·Published 상태
- Scene 전환
- Scene Editor 진입

### Quick Edit

Live Session을 유지하면서 제한된 위치·회전·문·조명·Visibility 상태를 수정한다.

### Fog

공개·숨김 Brush와 Region을 사용한다. Player에게 비공개 Mask·Actor를 미리 보내지 않는다.

### Time

Campaign Time, Lighting Time과 Downtime Activity를 조정한다.

### Encounter

참가자를 확인하고 전투를 시작·진행·종료한다.

### Journal

DM 문서, Handout과 선택 Actor·Object 연결 문서를 연다.

### Players

Observer, Owner, Controller와 연결 상태를 관리한다.

### Rollback

Checkpoint와 변경 Diff를 확인하고 명시적 복구를 실행한다.

## 4. 왼쪽 Inspector

현재 Selection에 따라 다음을 표시한다.

- Identity·Type
- Transform
- State·Interaction
- Visibility·Fog
- Control·Ownership
- Linked Journal
- Lighting·Navigation
- Permission

Inspector가 기본적으로 오른쪽에 있지 않는다.

## 5. Quick Action

Quick Action은 큰 창이 아니다. 선택한 Actor·Door·Object·Player 근처의 작은 세로 Popover다.

예:

```text
공개
HP 변경 ›
전투 참가
제어권 배정
문서 열기
Inspector
```

추가 값은 작은 Inline Step으로 받고, 위험한 명령만 변경 요약 확인을 연다.

## 6. Downtime

DM이 Activity를 만든다.

```text
참가자 선택
→ Activity 배정
→ 시간·비용·시설 확인
→ 필요한 Player 선택 요청
→ Campaign Time Checkpoint 진행
→ 중간 사건 처리
→ Completion Confirm
```

Player에게 임의 Activity Launcher를 제공하지 않는다.

## 7. Scene Editor

Full Scene Editor 기본 배치:

```text
Top Toolbar
→ Scene, Save, Publish, Select, Move, Rotate, Scale, Measure, Undo, Redo

Left Inspector
→ Hierarchy, Transform, Appearance, Interaction, Lighting, Navigation

Center
→ Build Viewport

Bottom Catalog
→ Tiles, Props, Prefabs, Blueprints, Recent, Favorites, Search
```

Asset을 선택하면 Placement Mode가 유지되어 연속 배치할 수 있다. TaleSpire형 전장 중심 Build workflow를 참고하지만 고유 자산과 브랜드 외형은 복제하지 않는다.

## 8. Player View Preview

DM은 특정 Player·Observer의 Projection을 확인한다.

- 권한 밖 Actor·Action·Document의 부재
- Dice Result Audience
- Journal 공개 범위
- Observer에 Character Console이 없는지
- Player 기본 Owned Actor와 Console

Preview가 실제 권한을 변경하지 않는다.

## 9. Recovery

Rollback 전에는 다음을 확인한다.

- 기준 Checkpoint
- Character·Scene·Inventory·Encounter 변경 Diff
- 취소되는 Pending·Prompt
- 접속 중 사용자 영향
- 복구 뒤 Projection 재동기화

복구는 큰 Quick Action이 아니라 Timeline·Rollback 도구의 명시적 안전 흐름이다.
