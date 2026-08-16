# RVTT DM Guide

- 상태: `CURRENT · TARGET_EXPERIENCE · ADR-0092`
- 최종 갱신일: 2026-08-06
- User Guide Hub: [`../README.md`](../README.md)
- HTML 순서: [`UI-EXAMPLES.md`](UI-EXAMPLES.md)
- Survival·Token Guide: [`CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md`](CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md)
- 상위 결정:
  - [`ADR-0092`](../../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
  - [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)

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
→ Scenes · Scene Editor · Quick Edit · Fog · Time · Encounter · Journal · Players · Campaign Rules · Rollback

왼쪽
→ Selection Inspector

중앙
→ Live Scene

선택 대상 근처
→ Quick Action Popover
```

상단은 Tool Window 실행기다. Inspector와 각 도구는 이동·크기 변경·Dock·Tab·Close 가능한 독립 Module이다.

## 3. 상단 도구

### Scenes

현재 Scene과 Draft·Published 상태, Scene 전환과 Scene Editor 진입을 관리한다.

### Quick Edit

Live Session을 유지하면서 제한된 위치·회전·문·조명·Visibility 상태를 수정한다.

### Fog

공개·숨김 Brush와 Region을 사용한다. Player에게 비공개 Mask·Actor를 미리 보내지 않는다.

### Time

Campaign Time, Lighting Time, Travel·Rest·Downtime과 Supply Settlement를 조정한다.

### Encounter

참가자를 확인하고 전투를 시작·진행·종료한다.

### Journal

DM 문서, Handout, Core Rules와 선택 Actor·Object 연결 문서를 연다.

### Players

Observer, Owner, Controller와 연결 상태를 관리한다.

### Campaign Rules

- Narrative·Standard·Survival·Custom Preset
- Food·Water·Mount Feed·Exposure·Ammunition·Rest Quality Module
- Settlement Mode와 Supply Source 우선순위
- Candidate Policy Snapshot과 적용 경계
- Retroactive Reconcile Preview

### Rollback

Checkpoint와 Character·Scene·Inventory·Encounter·Supply Ledger Diff를 확인하고 명시적 복구를 실행한다.

## 4. 왼쪽 Inspector와 Quick Action

Inspector는 Identity·Transform·State·Interaction·Visibility·Control·Journal·Lighting·Navigation·Permission을 표시한다. 기본 위치는 왼쪽이다.

Quick Action은 큰 창이 아니라 선택 대상 옆의 작은 세로 Popover다.

```text
공개
HP 변경 ›
전투 참가
제어권 배정
문서 열기
Inspector
```

추가 값은 작은 Inline Step으로 받고, 위험한 명령만 변경 요약 확인을 연다.

## 5. Downtime·Travel·Supply

DM이 Activity 또는 Travel Plan을 만든다.

```text
참가자 선택
→ Activity·Travel 배정
→ 시간·비용·시설 확인
→ Supply Settlement Preview
→ 필요한 Player 선택 요청
→ Campaign Time Checkpoint 진행
→ 중간 사건 처리
→ Completion Confirm
```

Player에게 임의 Activity Launcher를 제공하지 않는다.

수일 진행에서 시간만 먼저 확정하지 않는다.

```text
Time Advance
+ Food·Water·Feed Requirement
+ Item Reservation
+ Shortage Consequence
→ Atomic Commit
```

Campaign Rules를 끄거나 켜도 과거 Item과 Effect를 자동 재작성하지 않는다.

## 6. Actor Model Registry와 Actor & Token Builder

DM은 Campaign에 Actor Model과 Stat Block을 추가할 수 있다.

```text
Actor Model 등록·선택
→ Strict Stat Block JSON
→ Schema·Asset·Rules·Rights 검사
→ Token·Stat Card Preview
→ Campaign Draft
→ Publish
→ SceneNpc 배치
```

Actor Model과 Stat Block은 별도 Definition이다. 같은 Model을 여러 Actor Template에서 재사용할 수 있다.

AI Prompt Builder는 외부 AI를 직접 권위 서비스로 호출하지 않는다. Strict JSON Schema와 현재 보이는 Actor Model Catalog 전체가 포함된 복사용 Prompt를 만든다.

AI 출력은 자동 Publish되지 않으며 Script·Luau·Remote·미등록 Recipe와 존재하지 않는 Model ID를 허용하지 않는다.

상세 흐름은 [`CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md`](CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md)를 따른다.

## 7. Scene Editor

```text
Top Toolbar
→ Scene, Save, Publish, Select, Move, Rotate, Scale, Measure, Undo, Redo

Left Inspector
→ Hierarchy, Transform, Appearance, Interaction, Lighting, Navigation

Center
→ Build Viewport

Bottom Catalog
→ Tiles, Props, Actor Tokens, Prefabs, Blueprints, Recent, Favorites, Search
```

Asset을 선택하면 Placement Mode가 유지되어 연속 배치할 수 있다. TaleSpire형 전장 중심 Build workflow를 참고하지만 고유 자산과 브랜드 외형은 복제하지 않는다.

## 8. Player View Preview와 Recovery

DM은 특정 Player·Observer의 Projection에서 권한 밖 Actor·Action·Document의 부재, Dice Result Audience, Journal 공개 범위, Character Console, Supply Summary와 Campaign-local Actor Metadata를 확인한다.

Preview가 실제 권한을 변경하지 않는다.

Rollback 전에는 기준 Checkpoint, 변경 Diff, 취소되는 Pending·Prompt·Settlement, 접속 중 사용자 영향과 복구 뒤 Projection 재동기화를 확인한다.
