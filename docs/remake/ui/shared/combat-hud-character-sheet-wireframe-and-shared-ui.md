# 35. 전투 HUD·캐릭터 시트 와이어프레임과 공통 UI 규격

- 상태: `CURRENT · SUPERSEDED IN PART BY FULL UI SPEC`
- 작성일: 2026-08-03
- 최종 개정일: 2026-08-06
- 최신 구현 직전 명세: [`Full UI·UX Specification`](implementation-ready-ui-ux-and-settings-spec.md)
- 관련 문서:
  - [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
  - [`공통 입력 교과서`](../common-input/common-input-grammar.md)
  - [`Baldur's Gate형 전투 HUD`](../combat-hud/baldurs-gate-style-combat-hud.md)
  - [`공식 2024형 캐릭터 시트`](../character-sheet/official-2024-character-sheet-and-live-player-ui.md)
  - [`ADR-0041`](../../decisions/ADR-0041-shared-combat-hud-character-sheet-layout-and-ui-layering.md)

## 1. 문서 목적

이 문서는 전투 HUD와 캐릭터 시트의 16:9 PC 기준 와이어프레임, 중앙 전장 안전 영역, 반응형 동작, 공통 Component와 레이어를 정의한다.

탐험 HUD, Inventory·Loot, Journal·Map, Settings, Entry·Rest·Death·Recovery, 사용자 설정 기본값과 전체 Acceptance는 최신 `implementation-ready-ui-ux-and-settings-spec.md`를 따른다.

핵심 원칙:

```text
중앙 전장을 먼저 확보한다.
→ 필요한 HUD를 가장자리에 배치한다.
→ 상세 정보는 요청된 순간에만 확장한다.
```

## 2. 기준 화면과 좌표 체계

```text
ReferenceViewport = 1920 × 1080
DesignSafeInset = Left 32 / Right 32 / Top 24 / Bottom 24
BaseUiScale = 1.0
UserUiScale = 0.80 ~ 1.40
```

실제 위치는 Roblox Anchor·Constraint와 상대 좌표를 사용한다. px 값은 기준 화면 목표이며 고정값이 아니다. CoreGui Inset과 안전 영역을 반영한다.

## 3. 중앙 전장 안전 영역

1920×1080 기준:

```text
Left   = 260 px
Right  = 360 px
Top    = 108 px
Bottom = 210 px

Safe X = 260 ~ 1560
Safe Y = 108 ~ 870
```

- 지속 Panel은 안전 영역을 침범하지 않는다.
- World Feedback은 Cursor·대상 근처에 표시하되 Token·경로·범위 중심을 덮지 않는다.
- 화면 밖이나 HUD와 겹치면 반대 방향으로 Flip한다.
- 여러 피드백이 겹치면 현재 결정에 필요한 정보만 유지한다.

## 4. 기본 전투 HUD

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                         InitiativeRibbon                                 │
│                                                                          │
│ PartyRail                3D Battlefield                     Minimap      │
│                         WorldFeedback                                    │
│                                                             CombatLog   │
│                                                                          │
│ ActiveActorPanel       ResourceRail / ActionHotbar          EndTurn      │
└──────────────────────────────────────────────────────────────────────────┘
```

### 4.1 InitiativeRibbon

```text
Anchor = TopCenter
Width  = 720 ~ 1120 px
Height = 72 px
PortraitCell = 56 × 56 px
Gap = 6 px
```

- 현재 Actor는 위치·Stroke·Label로 강조한다.
- 완료·행동 불가·의식 없음은 서로 다른 Badge를 가진다.
- 같은 제어 Group은 연결 표시를 사용한다.
- 현재 턴과 다음 2–3개 Entry를 우선 유지한다.
- 조작 가능한 Entry Left Click은 Actor 선택 전환을 우선한다.
- 턴 전환만으로 Camera를 강제 이동하지 않는다.

### 4.2 PartyRail

```text
Expanded Width = 220 px
Compact Width = 76 px
Portrait = 56 ~ 64 px
EntryHeight = 78 px
```

- Portrait·이름·HP·임시 HP·핵심 상태·제어권을 표시한다.
- Summon은 Owner 아래 Group으로 표시한다.
- 인원 증가 시 Virtualized Scroll을 사용한다.
- 기본 설정은 `partyRailMode = auto`다.

### 4.3 ActiveActorPanel

```text
Anchor = BottomLeft
Width = 300 px
Height = 168 px
Portrait = 104 × 104 px
```

- Portrait·이름·분류
- HP·임시 HP·AC·이동력·집중
- Action·Bonus Action·Reaction 요약
- Character Sheet·Inventory 진입
- 현재 Controller·Role

### 4.4 ResourceRail

```text
Height = 32 ~ 44 px
ResourcePip = 18 ~ 24 px
```

우선순위:

```text
Action
→ Bonus Action
→ Reaction
→ Movement
→ 현재 Action 관련 Resource
→ Spell Slot
→ 기타 Resource Drawer
```

### 4.5 ActionHotbar

```text
Anchor = BottomCenter
Width = 760 ~ 980 px
Height = 116 ~ 228 px
ActionSlot = 52 × 52 px
Gap = 4 px
Rows = 기본 2, 사용자 1 ~ 4
```

구성:

```text
CategoryTabs
PinnedActions
ContextActions
Overflow·Search
```

상태:

- available
- disabled + Hover·Focus Reason
- pending
- selected
- targeting
- toggle active
- stale·denied

권한에 없는 Action은 빈 Slot이나 Disabled 자리로 남기지 않는다. 최근 사용만으로 Slot 또는 Default Action을 자동 변경하지 않는다.

### 4.6 EndTurnControl

```text
Anchor = BottomRight
Size = 92 × 92 px
```

상태:

```text
End Turn
Waiting
Skip Reaction
End Group Turn
Disabled with Reason
```

남은 Action·Movement가 있어도 Turn End를 막지 않는다. 미해결 필수 Targeting·AuthorityPrompt가 있을 때만 Disabled하고 Hover·Focus Reason을 제공한다.

### 4.7 Minimap

```text
Anchor = TopRight
Size = 220 × 220 px
CollapsedSize = 44 × 44 px
Default = medium · camera_up
```

공개된 지형, Fog, Party와 DM 공개 정보만 표시한다. North Marker를 별도 표시하며 사용자는 `north_up`으로 전환할 수 있다.

### 4.8 CombatLog

```text
Anchor = RightCenter
ExpandedWidth = 340 px
MinWidth = 280 px
MaxWidth = 520 px
Height = 420 ~ 720 px
Default = recent
```

기본은 최근 결과 요약 상태다. 펼치면 Roll·Modifier·EffectResolution 근거를 확인한다.

## 5. 문맥별 HUD 변화

### Exploration

- InitiativeRibbon·EndTurn·Turn ResourceRail을 숨긴다.
- PartyRail·ActiveActorPanel·ActionHotbar·Minimap·Objective를 유지한다.
- World Action Label과 Movement Preview를 우선한다.

### Action Selection·Targeting

- 선택 Action과 비용을 Compact Bar로 남긴다.
- 유효 Target·Range·Cover·위험을 World에 표시한다.
- Q는 현재 Targeting Step만 취소한다.
- E는 표시된 Preview가 완성된 경우에만 Confirm한다.

### Dice Presentation

- HUD를 완전히 제거하지 않고 현재 Action·대상·Q/E 상태를 유지한다.
- 접근성 Skip은 연출만 줄이고 Authority 순서를 바꾸지 않는다.

### Reaction·DM Approval

- 중앙 하단 AuthorityPrompt를 사용한다.
- 전장과 관련 Actor를 볼 수 있어야 한다.
- Q 거절, E Confirm, 1–5 공개 선택지를 사용한다.

### Paused

상단 상태 Bar로 표시하고 Character Sheet·Log·Tooltip 읽기를 허용한다.

## 6. Character Sheet Layout

지원 Mode:

```text
single_page — 초기 기본
combat_side_sheet — 전투 중 권장
responsive_sections — 좁은 화면
double_spread — 충분히 넓은 화면
```

- Character Sheet는 Authority 원본이 아니라 Projection이다.
- 전체 Sheet가 열린 동안 World 기본 Action을 차단한다.
- Side Sheet는 Panel 밖 Camera 입력을 허용한다.
- AuthorityPrompt는 Sheet보다 우선한다.
- Targeting 중 Sheet를 열면 Targeting을 일시중지하고 닫을 때 최신 Revision으로 재검증한다.

## 7. 반응형 축약 순서

화면이 좁거나 UI Scale이 클 때:

```text
1. CombatLog 접기
2. Minimap 축소
3. PartyRail Compact
4. Hotbar Slot·Gap 축소
5. Hotbar 한 행 + Scroll
6. ActiveActor 부가 정보 접기
7. Character Sheet single_page
8. 보조 Panel Tab 전환
```

현재 Turn, HP, 주요 Resource, Q/E, Prompt와 위험 정보는 마지막까지 유지한다.

## 8. UI 레이어와 입력 소유권

```text
WorldScene
< WorldFeedback
< PersistentHud
< DockedPanel
< FloatingPanel·ContextActionTable
< Tooltip
< AuthorityPrompt
< DicePresentation
< CriticalModal
< RecoverySurface
```

- 상위 Layer가 입력을 소비하면 하위로 전달하지 않는다.
- Q는 최상위 Context 하나만 닫는다.
- ESC에는 Gameplay 의미가 없다.
- Right Pointer는 Context Action Table, Middle Pointer Drag는 Camera Orbit이다.
- 오류·연결 Recovery는 모든 Authority-bound Gameplay 입력보다 우선한다.

## 9. 공통 Component 계약

```text
PanelFrame
PortraitCell
ActionSlot
ResourcePip
StatField
StatusBadge
TooltipCard
ReasonTooltip
ContextActionTable
ModeRoleBadge
RecoverySurface
```

Component는 Domain Store나 Workspace Instance를 직접 읽지 않고 UI Projection DTO만 받는다.

## 10. 사용자 설정

최신 기본값과 저장 범위는 구현 직전 명세를 따른다.

```text
uiScale = 1.00
textScale = 1.00
hotbarRows = 2
partyRailMode = auto
combatLogDefaultState = recent
minimapSize = medium
minimapOrientation = camera_up
tooltipDelay = 0.25s
```

## 11. 성능과 테스트

- Hotbar는 Capability Revision 변화에서 재계산한다.
- HP·Resource는 Field Delta로 갱신한다.
- 긴 목록은 VirtualizedList를 사용한다.
- 닫힌 Page·Panel의 Animation과 Layout 계산을 중단한다.
- 같은 속성 Tween을 병합한다.

검수 Viewport:

```text
1280×720
1366×768
1600×900
1920×1080
2560×1440
3440×1440
```

검수 상태:

- Party 1·4·8
- Initiative 5·20·50
- Hotbar 5·40·120
- Inventory 10·100·500
- Sheet·Targeting·Reaction·Reconnect·Role Change 동시 전환

최종 완료 기준은 구현 직전 명세와 UI·UX Review Checklist를 따른다.
