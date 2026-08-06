# RVTT 구현 직전 UI·UX·Settings 명세

- 상태: `CURRENT · IMPLEMENTATION READY · ADR-0089 ALIGNED`
- 최종 갱신일: 2026-08-06
- 상위 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 직접 입력: [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 충돌 감사: [`UI HTML Authority Conflict Audit`](../../audits/ui-html-authority-conflict-and-realignment-audit.md)
- HTML 예시: [`User Guide HTML`](../../user-guides/html/index.html)

이 문서는 구현자가 화면·상태·기본값을 추측하지 않도록 Player·Observer·DM UI를 구현 단위로 고정한다. 문서 완료는 Roblox Runtime PASS가 아니다.

## 1. 전역 원칙

1. UI는 서버 권위 상태의 Permission-aware Projection이다.
2. 권한 밖 Action·Entity·Document는 Disabled 자리도 만들지 않는다.
3. Local Preview·Pending Animation과 Hover 정보는 권위 결과가 아니다.
4. Q는 최상위 Input Context 하나만 닫거나 취소한다.
5. E는 화면에 표시된 Confirm 하나만 제출한다.
6. ESC에는 Gameplay 의미가 없다.
7. Camera Focus, Hover, Keyboard Focus, Actor Selection과 Action Target을 분리한다.
8. Player의 Owned Actor는 명시적 다른 Actor 선택이 없으면 기본 의미 선택이다.
9. 외부 제품의 정보 구조와 흐름은 참고하되 고유 자산·브랜드 외형은 복제하지 않는다.

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
- DM의 Character 배정 대기
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
Character Console View
Capability View
```

Client는 Observer Context를 폐기하고 Player Projection을 적용한 뒤 Owned Actor를 기본 의미 선택으로 설정한다. 실패하면 Observer Projection을 유지한다.

재접속 시 서버가 Owner를 다시 확인한다. Owner가 아니면 Observer로 남고, Owner이면 안전 경계에서 Player Projection과 Controller를 복구한다.

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

Fog·Scene 좌표·이동 경로·월드 링크의 권위 데이터는 유지한다.

## 5. Unified Character Console

하단 Console은 하나의 연속된 Baldur's Gate형 표면이다.

```text
Actor Switcher
→ Owned Character, delegated Actor, Summon

Identity/Vitals
→ Portrait, Name, HP, Temporary HP, Vital State, Concentration, Conditions

Action Deck
→ Common, Class, Spell, Item, Feature, Passive, Custom

Turn Resources
→ Action, Bonus Action, Reaction, Movement, class resources

Controls
→ End Turn, Official Sheet, VTT Management, Inventory, System
```

기본 Hotbar는 2행, 사용자 범위는 1–4행이다. 최근 사용만으로 Slot을 자동 교체하지 않는다. 명시 Actor 선택이 끝나면 Owned Actor Console로 돌아간다. 턴 전환은 Console을 강조하지만 Camera를 강제로 이동하지 않는다.

## 6. Pointer·Compact Context Action

### Left Click

- Actor가 없으면 조작 가능한 Actor 선택 또는 UI 조작
- Actor가 있으면 클릭 전에 World Action Label로 보인 기본 행동 요청
- 조작 가능한 다른 Actor는 공격보다 선택 전환 우선

### Right Click

`CompactContextActionTable`을 Cursor·Target 옆에 연다.

```text
폭: 150–220 px 기준
열: 1
표시 행: 4–8
Label: 공격, 밀치기, 대화, 살펴보기, 문 열기처럼 짧게
```

- 비용·사거리·상세 설명은 Hover·Focus Tooltip에서 제공한다.
- 현재 불가능 Action은 비활성 색상과 이유를 가진다.
- 권한 밖 Action은 존재하지 않는다.
- 많은 Action은 Scroll 또는 `더 보기` 하위 Context를 사용한다.
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

Encounter는 Exploration Console에 InitiativeRibbon, Turn Resource 강조, End Turn, Reaction Prompt와 Log Filter만 추가한다.

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
- 전장과 Character Console을 가리지 않는다.
- 중앙 Modal·별도 결과 Window를 열지 않는다.
- Reduced Motion도 공개 순서를 유지한다.
- 비밀 Roll은 Audience Policy를 따른다.

## 9. Reaction·Authority Prompt

Character Console 위 중앙 하단의 짧은 Prompt다. 원인, Actor·Target, 반응, 비용, Q 거절, E Confirm을 표시한다. 전장을 유지하며 전체 화면 Modal을 사용하지 않는다.

## 10. Character Sheet

같은 `CharacterSheetProjection`을 세 가지 보기로 제공한다.

### Official Sheet View

공식 D&D 2024 시트형 정보 계층과 읽기 순서를 RVTT 자체 시각체계로 재구성한다.

한눈에 보여야 하는 정보:

- Identity·Class·Level·Species·Background
- 6 Ability·Saving Throw·Skill
- Proficiency·Inspiration·AC·Initiative·Speed·Passive Perception
- HP·Temporary HP·Hit Dice·Death Save
- Weapons·Damage Cantrips
- Proficiencies·Species Traits·Class Features·Feats
- Spellcasting·Prepared Spell·Slot 1–9
- Equipment·Coins·Attunement·Languages
- Appearance·Personality·Backstory

보기:

```text
official_full_sheet
→ 16:9 한 화면에서 핵심 영역을 시트처럼 배치

official_double_spread
→ 넓은 화면의 2페이지 정보 구조

official_single_page
→ 한 페이지 확대
```

공식 로고·일러스트·고유 장식·서체는 복제하지 않는다.

### VTT Management View

```text
Left
→ Character Portrait, Abilities, Equipment Slots

Center
→ Inventory / Actions / Spells Tabs and Grid

Right
→ Item·Feature·Spell Detail, comparison, equip/use

Bottom
→ Weight, Currency, Attunement, Hotbar pinning
```

Official과 VTT 보기는 같은 Revision을 사용한다. 전투 중에는 선택 섹션만 보여주는 Combat Side Sheet를 제공할 수 있다.

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

필요 선택은 중앙 Prompt 또는 Character Console Context로 표시한다. DM은 상단 `Time` 도구에서 Activity와 Campaign Time을 관리한다.

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

`unconscious_at_zero`, `dying`, `stable_at_zero`, `dead`를 구분한다. 색상만 쓰지 않고 Symbol·Text를 사용하며 Reduced Motion을 지원한다. 전체 화면 Game Over Modal이나 일반 Card 디자인을 사용하지 않는다.

## 14. Journal

```text
Left Vertical Tabs
→ Folder, Scene Documents, Characters, Handouts, Recent, Search

Document Canvas
→ 현재 Markdown 문서

Optional Drawer
→ Heading Outline, Backlinks, World Link Detail
```

- 문서 탐색 기준은 왼쪽 탭이다.
- Player Map UI와 결합하지 않는다.
- World Link는 Camera Focus·Selection·Scene Proposal만 만든다.
- 권한 없는 문서는 탭·검색·개수·Backlink로도 노출하지 않는다.

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

제거된 설정:

- Minimap Size·Orientation
- Objective Tracker
- Map UI 관련 설정

초기값:

| 설정 | 기본값 |
|---|---:|
| Accent | gold |
| UI Scale | 1.00 (0.80–1.40) |
| Text Scale | 1.00 (0.90–1.30) |
| Hotbar Rows | 2 (1–4) |
| Hotbar Locked | true |
| Actor Rail | auto |
| Combat Log | recent |
| World Action Label | true |
| General Tooltip | 0.25초 |
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
- Actor Action·Hotbar
- Inventory·Character Sheet
- Objective·Map·Minimap
- 권한 밖 Actor·Document·Action 자리

## 17. DM Live Workspace

```text
Top Authoring Strip
→ Scenes | Scene Editor | Quick Edit | Fog | Time | Encounter | Journal | Players | Rollback | System

Left Inspector
→ Selection Identity, Transform, State, Visibility, Control, Linked Document

Center Viewport
→ Live Scene

Context Popover
→ Quick Action
```

상단 도구:

- Scenes: Scene 선택·전환·상태
- Scene Editor: Full Scene Edit
- Quick Edit: Live Transform·문·조명·상태 수정
- Fog: Reveal·Hide Brush와 Region
- Time: Campaign Time·Downtime·Lighting Time
- Encounter: 참가자·시작·진행·종료
- Journal: DM 문서·Handout
- Players: Observer·Owner·Controller 배정
- Rollback: Checkpoint·Diff·복구

Inspector 기본 위치는 왼쪽이다.

## 18. DM Quick Action

```text
Selection/Hover
→ 작은 세로 Popover
→ 짧은 Action Label
→ 필요한 경우 작은 Inline Step
→ 위험 작업만 Confirmation
```

금지:

- 별도 큰 Quick Action Window
- 화면 중앙 Category Dashboard
- Quick Action을 위해 Full Workspace 진입 요구

## 19. Full Scene Editor

TaleSpire형 전장 중심 Build Mode를 참고하는 RVTT 기본 배치:

```text
Top Toolbar
→ Scene, Save, Publish, Select, Move, Rotate, Scale, Measure, Undo, Redo, ViewY

Left Inspector
→ Hierarchy, Selection, Transform, Material, Interaction, Lighting, Navigation

Center Build Viewport
→ Grid/Surface Cursor, Ghost, Gizmo, Selection Volume

Bottom Catalog Tray
→ Tiles, Props, Prefabs, Blueprints, Recent, Favorites, Search
```

- Selection Mode와 Placement Mode를 분리한다.
- Asset 선택 시 Placement Mode에 들어가며 한 번 배치해도 유지한다.
- Q는 현재 Placement/Selection Context 한 단계 취소한다.
- Shift는 현재 Snap만 임시 해제한다.
- Ctrl+D는 복제 Ghost Placement다.
- Live Quick Edit는 Catalog 전체를 열지 않는다.
- Candidate Compile·Diagnostic·Test Play 후 Atomic Publish한다.

상세 레이아웃은 [`scene-editor-interaction-and-layout-v2.md`](../scene-editor/scene-editor-interaction-and-layout-v2.md)를 따른다.

## 20. Recovery·Role Change

```text
Connection Detect
→ Session 확인
→ Role·Owner 확인
→ Snapshot 수신
→ Scene 준비
→ Player/Observer UI 재구성
→ Input 재개
```

Role·Ownership 변경 시 이전 Projection, Action Table, Targeting, Prompt와 Pending을 정리한다. Accent·Scale·Accessibility·Camera Preference는 유지한다. Player가 되면 Owned Actor Selection과 Console을 만들고 Observer가 되면 제거한다.

## 21. Shared Components

```text
ObserverEntryStatus
CharacterConsole
ActorSwitcher
ActorVitalCluster
ActionHotbar
ResourceRail
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
LeftInspector
QuickActionPopover
SceneCatalogTray
RecoverySurface
Tooltip
Toast
```

## 22. Acceptance Matrix

| 영역 | 최소 증거 |
|---|---|
| Entry | 미배정 참가자 Observer 진입, Character self-select 없음 |
| Assignment | DM 배정 후 Owner·Controller·Player Projection 원자 전환 |
| Selection | Owned Actor default selection, Q root 복귀 |
| Player HUD | Objective·Map·Minimap 없음, 하단 Character Console |
| Context | 세로 1열, 작은 Cursor Popover, Disabled reason |
| Dice | Physical dice 완료 뒤 투명 Top Result Notice |
| Sheet | Official Full Sheet + VTT Management 동일 Revision |
| Downtime | DM 배정, Player 임의 Activity 시작 불가 |
| Death | 긴급 UI, Success/Failure, Reduced Motion |
| Journal | 왼쪽 세로 문서 탭, 권한 미노출 |
| DM | 왼쪽 Inspector, 상단 도구, 작은 Quick Action |
| Editor | Bottom Catalog, Placement 유지, Publish Gate |
| Role | Player↔Observer 전환 후 정보 잔존 없음 |
| Scale | 0.80·1.00·1.40, 한국어 긴 문구, Focus |

## 23. 구현 순서

```text
Projection·Role·Ownership
→ Shared Character Console
→ Pointer·Compact Context
→ Dice Notice·Urgent Vital UI
→ Character Sheet Two Views
→ Journal·Downtime
→ DM Top Strip·Left Inspector·Quick Action
→ Scene Editor Bottom Catalog
→ Settings·Recovery
→ HTML/Roblox Screenshot 비교
→ Multi-client Human Evidence
```
