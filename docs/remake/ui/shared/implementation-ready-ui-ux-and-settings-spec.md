# RVTT 구현 직전 UI·UX·Settings 명세

- 상태: `CURRENT · IMPLEMENTATION READY · ADR-0090 ALIGNED`
- 최종 갱신일: 2026-08-06
- Action Matrix·DM Window 결정: [`ADR-0090`](../../decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- 전체 UI 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 직접 입력: [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- Character Console 상세: [`character-console-action-matrix-and-resource-rail.md`](../combat-hud/character-console-action-matrix-and-resource-rail.md)
- DM Window 상세: [`modular-dm-tool-window-contract.md`](../dm-workspace/modular-dm-tool-window-contract.md)
- 고정밀 HTML: [`User Guide HTML`](../../user-guides/html/index.html)

이 문서는 구현자가 화면·상태·기본값을 추측하지 않도록 Player·Observer·DM UI를 구현 단위로 고정한다. 문서와 HTML 완료는 Roblox Runtime PASS가 아니다.

## 1. 전역 원칙

1. UI는 서버 권위 상태의 Permission-aware Projection이다.
2. 권한 밖 Action·Entity·Document는 Disabled 자리도 만들지 않는다.
3. Local Preview·Pending Animation·Hover 정보는 권위 결과가 아니다.
4. Q는 Focus된 최상위 Input Context 하나만 닫거나 취소한다.
5. E는 화면에 표시된 Confirm 하나만 제출한다.
6. ESC에는 Gameplay 의미가 없다.
7. Camera Focus, Hover, Keyboard Focus, Actor Selection과 Action Target을 분리한다.
8. Player의 Owned Actor는 명시적 다른 Actor 선택이 없으면 기본 의미 선택이다.
9. 외부 제품의 정보 구조와 흐름은 참고하되 고유 자산·브랜드 외형은 복제하지 않는다.
10. UI Window의 위치·크기·Dock 상태는 Local Preference이며 Tool Action은 서버 권위 Command다.

## 2. Session Entry·Role·Ownership

DM이 아닌 참가자는 Character 선택 화면이 아니라 Observer로 진입한다.

```text
connecting
→ observer_projection_loading
→ observer_ready
→ awaiting_dm_assignment
→ player_projection_loading?
→ player_ready?
```

Observer Entry 표시:

- Campaign·Session 이름
- Observer Role Badge
- 공개 Scene 준비 상태
- DM Character 배정 대기
- 연결·동기화·재시도
- System·Accessibility

표시하지 않음:

- Player가 선택하는 Character 목록
- 소유권 없는 Character의 이름·빈 Slot
- Objective·Map·Minimap

DM의 `AssignCharacterToParticipant`가 성공하면 같은 Revision 경계에서 다음을 갱신한다.

```text
Character Owner
Current Controller
Viewer Role = Player
Owned Character View
Controlled Actor View
Character Console Projection
Capability View
```

Client는 Observer Context를 폐기하고 Player Projection을 적용한 뒤 Owned Actor를 기본 의미 선택으로 설정한다. 실패하면 Observer Projection을 유지한다.

## 3. Effective Actor Selection

```text
명시적 조작 Actor 선택 있음
→ 해당 Actor

명시 선택 없음 + Owned Actor 사용 가능
→ Owned Actor

둘 다 없음
→ Actor-less Observer·Recovery Context
```

- Q가 하위 Context를 모두 닫으면 `none`이 아니라 Owned Actor로 복귀한다.
- 위임 NPC·소환체·공유 턴 Actor를 명시 선택할 수 있다.
- Camera Focus는 Actor Selection을 바꾸지 않는다.
- 권한 상실·Actor 제거·Scene 미배치 시 Default Selection도 제거한다.

## 4. Player Global Shell

```text
Top Center
→ InitiativeRibbon(Encounter에서만)
→ TopResultNotice(필요할 때만)

Left Edge
→ 축약 Party·Controlled Actor Portrait Rail

Bottom
→ Unified Character Console

Center World
→ World Action Label·Path·Target Preview

Right Edge
→ 접을 수 있는 Combat/Event Log
```

Player·Observer 상시 UI에서 제거한다.

- Objective Tracker
- Minimap
- Map Button·Map Screen
- 오른쪽 상시 Activity Column

## 5. Unified Character Console

하단 Console은 하나의 연속된 Baldur's Gate형 표면이며 `AnchorPoint(0.5, 1)`로 아래를 고정하고 위로 확장한다.

```text
Top Resource Rail
→ 행동 경제 · 이동 · 직업 자원 · 기억/준비 수 · 주문 슬롯 · Turn 상태

Body Left
→ Actor Switcher · Portrait · HP · 상태 · 집중

Body Center
→ Attack/Action Matrix + Spell Matrix

Body Right
→ Official Sheet · VTT Management · Inventory · End Turn
```

기존 `ActiveActorPanel`, `ActionHotbar`, `ResourceRail`, `EndTurnControl`은 ViewModel·Component 단위로는 유지하지만 하나의 연속 Console로 조합한다.

### 5.1 Action Matrix

공격·행동과 주문을 하나의 혼합 Grid로 만들지 않는다.

```text
Attack/Action Matrix
→ Weapon Attack · Class Action · Movement · Utility · Item Shortcut · Custom

Spell Matrix
→ Cantrip · Prepared/Memorized Spell · Known Spell Shortcut · Spellbook Entry
```

사용자 설정:

```text
consoleActionRows = 2
허용 범위 = 1–4
```

Icon은 위에서 아래로 행을 채운 뒤 오른쪽으로 이어진다. 두 Matrix는 같은 Row 설정을 사용하지만 Horizontal Scroll과 정렬 Preference는 독립적이다.

- Action Cell 기준 `48 × 48 px`, Gap `5 px`.
- 최근 사용만으로 Slot을 자동 교체하지 않는다.
- Row 수를 바꿔도 Action 의미와 순서는 유지한다.
- Console은 하단 Anchor를 유지하고 위로만 확장한다.

### 5.2 Action Cell 상태

```text
Idle
Hover
Keyboard Focus
Selected/Default
Disabled
Pending
Cooldown
Concentration
```

Cell은 다음을 포함한다.

- RVTT 자체 Icon
- Action 종류별 Frame·Surface
- Key Binding·Slot Marker
- Action·Bonus Action·Reaction·Spell Level Cost Badge
- Prepared·Concentration·Cooldown·Disabled Marker

긴 Text Label은 Matrix 안에 상시 표시하지 않는다.

### 5.3 ActionHoverPanel

Pointer Hover 또는 Keyboard Focus 시 Cursor·Cell 위에 상세 Panel을 표시한다.

```text
Action Name
Action Economy · Range · Target · Spell Level
짧은 규칙 설명
현재 실행 가능 여부
불가능하면 구체적인 이유
```

- Pointer Delay `0.12–0.18초`, Keyboard Focus는 즉시.
- Cursor·Cell을 가리지 않는다.
- Screen Edge에서 Flip·Clamp한다.
- Disabled Cell도 Hover·Focus를 허용하지만 실행은 차단한다.
- Panel은 Read-only Projection이며 권한을 만들지 않는다.

### 5.4 상단 Resource Rail

순서:

```text
Action
→ Bonus Action
→ Reaction
→ Movement
→ Class Resource
→ Memory/Prepared Capacity
→ Spell Slots by Level
→ Turn State
```

존재하지 않는 Resource는 빈 자리나 Disabled Placeholder를 만들지 않는다.

기억·준비 가능 주문 수와 실제 주문 슬롯은 별도 Projection이다.

```text
기억/준비     8 / 10
1레벨 Slot    ● ● ● ○
2레벨 Slot    ● ○
```

Character 규칙 모델에 따라 Label은 `기억`, `준비`, `알고 있는 주문` 등으로 바꿀 수 있다. Spell Slot과 합치지 않는다.

## 6. Pointer·Compact Context Action

### Left Click

- Actor가 없으면 조작 가능한 Actor 선택 또는 UI 조작.
- Actor가 있으면 클릭 전에 World Action Label로 보인 기본 행동 요청.
- 조작 가능한 다른 Actor는 공격보다 선택 전환 우선.

### Right Click

`CompactContextActionTable`을 Cursor·Target 옆에 연다.

```text
폭: 150–220 px 기준
열: 1
표시 행: 4–8
Label: 공격, 밀치기, 대화, 살펴보기, 문 열기처럼 짧게
```

- 상세 비용·설명은 Hover·Focus Tooltip에서 제공한다.
- 현재 불가능 Action은 비활성 색상과 이유를 가진다.
- 권한 밖 Action은 존재하지 않는다.
- 큰 중앙 Panel·2열 Table·상시 Side Sheet는 금지한다.

### Middle-button Drag

Camera Orbit. Right Click Camera는 사용하지 않는다.

## 7. World Preview·Encounter

Movement Preview:

- 예상 경로
- 거리·남은 이동력
- 어려운 지형·점프·문 통과
- 발견된 위험·기회 공격
- 도달 불가 이유
- Local·Pending·Confirmed 상태 구분

Target Preview:

- 유효 Target·범위·사거리
- 시야·엄폐·Advantage·Disadvantage
- 공개 가능한 명중 예상
- Resource·집중·아군 피해 경고

Encounter는 Exploration Console에 InitiativeRibbon, Turn 강조, End Turn, Reaction Prompt와 Log Filter만 추가한다.

## 8. Dice Presentation·Top Result Notice

```text
RollRequest
→ SealedRollResult
→ Physical/Reduced Dice Presentation
→ Presentation Complete
→ Top Result Notice Reveal
→ Resolution Projection
```

Top Result Notice는 화면 상단 중앙의 투명 프레임이다.

```text
[아리아 · 장검 공격]
[d20 16] + 7 = 23
명중
```

- 큰 Total과 보조 Raw Dice·Modifier를 표시한다.
- 성공·실패는 색상 외 Icon·Text를 함께 사용한다.
- 중앙 Modal·별도 결과 Window를 열지 않는다.
- Reduced Motion도 공개 순서를 유지한다.
- 비밀 Roll은 Audience Policy를 따른다.

## 9. Reaction·Authority Prompt

Character Console 위 중앙 하단의 짧은 Prompt다. 원인, Actor·Target, 반응, 비용, Q 거절, E Confirm을 표시한다. 전체 화면 Modal을 사용하지 않는다.

## 10. Character Sheet

같은 `CharacterSheetProjection`을 다음 보기로 제공한다.

### Official Sheet View

공식 D&D 2024 시트형 정보 계층과 읽기 순서를 RVTT 자체 시각체계로 재구성한다.

한눈에 보여야 하는 정보:

- Identity·Class·Level·Species·Background
- 6 Ability·Saving Throw·Skill
- Proficiency·Inspiration·AC·Initiative·Speed·Passive Perception
- HP·Temporary HP·Hit Dice·Death Save
- Weapons·Damage Cantrips
- Proficiencies·Traits·Class Features·Feats
- Spellcasting·Prepared Spell·Slot 1–9
- Equipment·Coins·Attunement·Languages
- Appearance·Personality·Backstory

### VTT Management View

```text
Left
→ Character Portrait · Abilities · Equipment Slots

Center
→ Inventory / Actions / Spells Tabs and Grid

Right
→ Item·Feature·Spell Detail · comparison · equip/use

Bottom
→ Weight · Currency · Attunement · Console pinning
```

Official과 VTT 보기는 같은 Revision을 사용한다.

## 11. Inventory·Loot

- Item Grid/List
- Equipment Slots
- Detail·Comparison
- Weight·Capacity·Currency
- Container와 Character Inventory 비교
- Take·Take All·Send·Split·Inspect

Drag and Drop은 빠른 경로이며 Click 기반 대체 경로가 필수다. 미식별 Item은 실제 정의·희귀도·비밀 효과를 암시하지 않는다.

## 12. Downtime

DM이 Downtime Session과 Activity를 생성·배정·시작·진행한다. Player는 임의 Activity Launcher를 받지 않는다.

Player 표시:

- 배정된 활동
- 참가자·예상 시간
- 현재 단계·중단 사유
- 필요한 선택·재료·승인
- 완료 결과

필요 선택은 중앙 Prompt 또는 Character Console Context로 표시한다.

## 13. HP 0·Death Save

```text
World
→ 계속 표시

Screen Edge
→ 낮은 강도의 Vignette·Pulse

Character Console
→ 응급 상태

Center Safe Area
→ 큰 Success 3·Failure 3 Track과 Death Save Prompt

Top
→ Dice 완료 후 Result Notice
```

색상만 쓰지 않고 Symbol·Text를 사용하며 Reduced Motion을 지원한다.

## 14. Journal

```text
Left Vertical Tabs
→ Folder · Scene Documents · Characters · Handouts · Recent · Search

Document Canvas
→ 현재 Markdown 문서

Optional Drawer
→ Heading Outline · Backlinks · World Link Detail
```

권한 없는 문서는 탭·검색·개수·Backlink로도 노출하지 않는다.

## 15. Settings·System

System 버튼 또는 재설정 가능한 Semantic Action으로 연다. ESC는 사용하지 않는다.

Categories:

- Interface
- Gameplay UX
- Camera
- Accessibility
- Key Bindings
- Graphics·Performance
- Session Information
- Leave Session

초기값:

| 설정 | 기본값 |
|---|---:|
| Accent | gold |
| UI Scale | 1.00 (0.80–1.40) |
| Text Scale | 1.00 (0.90–1.30) |
| Action Matrix Rows | 2 (1–4) |
| Console Locked | true |
| Actor Rail | auto |
| Combat Log | recent |
| World Action Label | true |
| General Tooltip | 0.25초 |
| Action Hover Panel | 0.15초 |
| Detailed Tooltip | 0.75초 |
| Disabled Reason | 0.15초 |
| Motion Profile | full |
| Turn Focus | soft_notification |

Camera 초기값:

| 설정 | 기본값 |
|---|---:|
| FOV | 50 |
| Orbit Sensitivity | 0.004 기준 |
| WASD Pan | 55 studs/s 기준 |
| Zoom Step | 5 |
| Smoothing | 14 기준 |
| Distance | 20–130 |
| Edge Pan | false |
| Occlusion Correction | true |
| Camera Shake | 35% |

## 16. Observer UI

Observer가 사용하는 표면:

- 공개 Scene과 Camera
- 공개 Initiative·Dice Notice·Log
- 공개 Journal
- System·Accessibility

Observer에게 없는 표면:

- Character Console
- Actor Action Matrix
- Inventory·Character Sheet
- Objective·Map·Minimap
- 권한 밖 Actor·Document·Action 자리

## 17. DM Workspace 기본 배치와 Modularity

기본 저장 Layout:

```text
Top Authoring Strip
→ Tool Module Launcher

Left Dock
→ Selection Inspector Module Instance

Center
→ Live Scene 또는 Build Viewport

Bottom Dock
→ Full Scene Edit의 Scene Catalog Module
```

이 배치는 초기값일 뿐 고정 단일 Panel 구조가 아니다. ADR-0045·0090에 따라 여러 Tool Window를 동시에 열 수 있다.

지원 Window 조작:

- Move
- Resize
- Minimize·Restore
- Close
- Dock Left·Right·Bottom
- Undock
- Tab Group
- Focus·Z-order
- Layout Save·Restore

Left Inspector는 Default Dock Instance이며 다른 위치로 이동하거나 허용된 경우 여러 Inspector Instance를 열 수 있다.

## 18. DmToolModule·DmWindowHost

```text
DmToolModule
├─ moduleId
├─ instanceId
├─ title·iconId
├─ instancePolicy
├─ projectionScope
├─ permissionQuery
├─ commandBindings
├─ windowConstraints
├─ localViewState
├─ serializeLayout()
└─ dispose()
```

`DmWindowHost` 담당:

- Window Instance Registry
- Z-order·Focus
- Move·Resize
- DockTree·TabGroup
- Input Context Stack
- Workspace Layout Preference
- Role·Scene·Permission 변경 시 Stale 처리

Tool Module 하나가 다른 Tool의 Local View State를 직접 수정하지 않는다. 공유 상태는 Projection·Domain Event·Command를 통해 전달한다.

Instance 정책:

```text
singleton
→ Players · Rollback · Session Settings

per_entity / per_document / multiple
→ Inspector · Journal · Scene Preview · Actor Sheet · Asset Detail

context_popover
→ Quick Action · Inline Stepper
```

Window Layout은 Local Preference다. Fog Reveal·HP 변경·Scene Publish 같은 Tool Action은 서버 권위 Command다.

## 19. DM Quick Action

```text
Selection/Hover
→ 작은 세로 Popover
→ 짧은 Action Label
→ 필요한 경우 작은 Inline Step
→ 위험 작업만 Confirmation
```

Quick Action은 자동으로 큰 Window를 열지 않는다. 사용자가 `상세 열기`를 명시적으로 선택한 경우에만 관련 Tool Window를 생성한다.

## 20. Full Scene Editor

기본 배치:

```text
Top Toolbar
→ Scene · Save · Publish · Select · Move · Rotate · Scale · Measure · Undo · Redo

Left Default Dock
→ Hierarchy · Inspector

Center Build Viewport
→ Grid · Ghost · Gizmo · Selection Volume

Bottom Default Dock
→ Tiles · Props · Prefabs · Blueprints · Recent · Favorites · Search
```

Material, Lighting, Navigation, Asset Detail, Diagnostics와 Publish Review는 독립 Tool Module이다. Catalog도 Default Dock Module이며 높이 변경·최소화·다른 Workspace 이동을 지원한다.

## 21. Recovery·Role Change

```text
Connection Detect
→ Session 확인
→ Role·Owner 확인
→ Snapshot 수신
→ Scene 준비
→ Player/Observer UI 재구성
→ Input 재개
```

Role·Ownership 변경 시 이전 Projection, Action Table, Targeting, Prompt와 Pending을 정리한다. DM Tool Window는 Instance별 Permission을 재검사하고, 권한을 잃은 Window의 민감 Projection을 즉시 폐기한다.

## 22. Shared Components

```text
ObserverEntryStatus
CharacterConsole
ActorSwitcher
ActorVitalCluster
ResourceRail
SpellCapacityView
ActionMatrix
ActionCell
ActionHoverPanel
CompactContextActionTable
WorldActionLabel
MovementPreview
TargetPreview
InitiativeRibbon
ReactionPrompt
DicePresentation
TopResultNotice
OfficialCharacterSheet
VttCharacterManagement
InventoryGrid
DeathSaveUrgencyOverlay
JournalVerticalTabs
DmTopAuthoringStrip
DmToolRegistry
DmToolModuleInstance
DmWindowHost
DockTree
TabGroup
QuickActionPopover
SceneCatalogModule
RecoverySurface
Tooltip
Toast
```

## 23. Acceptance Matrix

| 영역 | 최소 증거 |
|---|---|
| Entry | 미배정 참가자 Observer 진입, Character self-select 없음 |
| Assignment | DM 배정 후 Owner·Controller·Player Projection 원자 전환 |
| Selection | Owned Actor default selection, Q root 복귀 |
| Player HUD | Objective·Map·Minimap 없음, 하단 Character Console |
| Matrix | 공격·주문 분리, Rows 1·2·3·4, 순서 유지 |
| Hover | Cursor 위 설명, Focus 지원, Disabled Reason |
| Resource | Console 상단 Rail, 기억·준비 수와 Spell Slot 분리 |
| Context | 세로 1열, 작은 Cursor Popover |
| Dice | Physical dice 완료 뒤 투명 Top Result Notice |
| Sheet | Official Full Sheet + VTT Management 동일 Revision |
| Downtime | DM 배정, Player 임의 Activity 시작 불가 |
| Death | 긴급 UI, Success/Failure, Reduced Motion |
| Journal | 왼쪽 세로 문서 탭, 권한 미노출 |
| DM Window | 3개 이상 동시 Open, 독립 Move·Resize·Dock·Close |
| Window State | Layout Preference와 Domain State 분리 |
| Permission | 권한 상실 Window의 민감 Projection 즉시 폐기 |
| Quick Action | 작은 Popover, 자동 Full Window 금지 |
| Editor | Bottom Catalog Module, Material·Lighting 동시 실행 |
| Scale | 0.80·1.00·1.40, 한국어 긴 문구, Focus |

## 24. 구현 순서

```text
Projection·Role·Ownership
→ Theme Token·Action Cell·ActionHoverPanel
→ CharacterConsoleProjection·ResourceRail·SpellCapacity
→ Pointer·Compact Context
→ Dice Notice·Urgent Vital UI
→ Character Sheet Two Views·Inventory
→ DmToolRegistry·DmWindowHost·DockTree
→ DM Tool Modules·Scene Editor Integration
→ Settings·Recovery
→ Static·Rojo·Luau Gate
→ HTML/Roblox Screenshot 비교
→ Multi-client Human Evidence
```
