# RVTT 구현 직전 UI·UX와 사용자 설정 명세

- 상태: `CURRENT · IMPLEMENTATION READY`
- 문서 종류: Screen Composition·UX Defaults·Settings·Acceptance Specification
- 작성일: 2026-08-06
- 제품 기준점: Baldur's Gate형 전술 RPG의 직접 조작·전장 중심 정보 위계
- 최상위 입력 결정: [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 전투 HUD: [`Baldur's Gate형 전투 HUD`](../combat-hud/baldurs-gate-style-combat-hud.md)
- 캐릭터 시트: [`공식 2024형 캐릭터 시트`](../character-sheet/official-2024-character-sheet-and-live-player-ui.md)
- 인벤토리 권위: [`ADR-0051`](../../decisions/ADR-0051-inventory-loot-transfer-and-identification.md)
- 공통 입력: [`공통 입력 교과서`](../common-input/common-input-grammar.md)
- 전역 정책: [`UI·UX Global Policies`](../policies/README.md)

## 1. 목적과 적용 우선순위

기존 문서는 시각 정책, 입력 원칙, 전투 HUD와 캐릭터 시트를 상세하게 정의한다. 그러나 Production UI 구현자가 다음 항목을 추측해야 하는 공백이 남아 있었다.

- 탐험·전투·휴식·Observer·DM Live Mode별 실제 화면 구성
- 인벤토리, 전리품, Journal, 지도, 설정과 시스템 화면
- Tooltip·Toast·Hotbar·카메라·접근성의 초기 기본값
- 선택 유지, 역할 변경, 사망, 재접속과 복구 중 화면 전환
- 사용자 설정의 저장 범위와 복구 원본
- 화면별 Acceptance Scenario

이 문서는 해당 공백을 채우는 구현 직전 명세다. 규칙 권위와 데이터 모델을 새로 만들지 않으며 기존 ADR·Architecture·Domain Projection을 화면과 상태 기계로 구체화한다.

우선순위:

```text
최신 사용자 결정
→ ADR-0088와 관련 Accepted ADR
→ Architecture·Domain Authority
→ UI·UX Global Policy
→ 이 구현 직전 명세
→ 화면별 상세 문서
→ Component·Script
```

충돌 시 상위 문서를 따른다. 이 문서의 수치 기본값은 Production 초기값이며 실제 Studio 측정에서 조정할 수 있다. 조정해도 입력 의미, 권한 공개와 Authority 경계는 바꾸지 않는다.

## 2. 전역 화면 셸

### 2.1 화면 레이어

```text
WorldScene
→ WorldFeedback
→ PersistentHud
→ DockedPanel
→ FloatingPanel·ContextActionTable
→ Tooltip·ReasonTooltip
→ AuthorityPrompt
→ Dice·Presentation
→ CriticalModal
→ Recovery·DisconnectSurface
```

상위 레이어가 입력을 소비하면 하위 레이어로 전달하지 않는다. 중첩 Modal은 금지한다. CriticalModal이 열린 상태에서 또 다른 Critical 결정이 오면 Queue 또는 기존 Modal 내부 Step으로 처리한다.

### 2.2 항상 존재하는 공통 영역

전장 모드의 기본 셸:

```text
Top Left
→ Mode·Role Badge, Session 상태

Top Center
→ 현재 Objective 또는 Encounter Initiative

Top Right
→ Minimap, Map, Journal, System 버튼

Left
→ PartyRail

Bottom Left
→ ActiveActorPanel

Bottom Center
→ ActionHotbar·ContextHint

Right
→ 접힌 Log·Objective·Context Side Sheet

Center
→ 전장 안전 영역과 World Feedback
```

`System` 버튼은 설정·세션 정보·나가기 Surface를 여는 명시적 진입점이다. ESC에는 Gameplay 또는 System Menu 의미를 부여하지 않는다.

### 2.3 공통 닫기와 탐색

- Q는 현재 최상위 Local Overlay·Targeting·Prompt·Panel Context 하나만 닫거나 취소한다.
- E는 화면에 표시된 현재 Confirm 하나만 실행한다.
- 문서·목록의 탐색 History는 화면 내 Back Button과 Breadcrumb를 사용한다.
- Q를 브라우저식 History와 혼합하지 않는다.
- 닫힌 Panel은 Gameplay Mode와 선택 Actor를 변경하지 않는다.

## 3. 모드별 기본 화면 구성

### 3.1 Exploration

```text
Mode Badge: 탐험
PartyRail
ActiveActorPanel
ActionHotbar 2행
Context Action·World Action Label
Minimap
접힌 Objective Tracker
접힌 Event·Roll Log
Map·Journal·System 버튼
```

Exploration에서는 InitiativeRibbon, EndTurnControl과 턴 ResourceRail을 숨긴다. 행동 Hotbar는 탐험에서 사용할 수 있는 Capability, Item, 주문과 사용자 고정 행동을 표시한다.

탐험 상시 정보:

- 선택 Actor HP·주요 자원·집중·핵심 상태
- 현재 조작권과 Party 연결 상태
- 현재 Scene·Objective·위험 Mode
- Hover 대상의 공개 가능한 이름과 기본 행동
- 이동 목적지·경로·거리·위험 Preview
- 발견된 상호작용, 공개된 Ping과 DM Prompt

탐험 중 조작 가능한 다른 아군 좌클릭은 선택 전환을 우선한다. 행동 후 선택 Actor를 유지한다.

### 3.2 Encounter

Exploration 셸에 다음을 추가·전환한다.

```text
Top Center
→ InitiativeRibbon

Bottom Center
→ Turn ResourceRail + ActionHotbar

Bottom Right
→ EndTurnControl

World Feedback
→ 이동 Budget·사거리·엄폐·시야·영향 대상
```

현재 턴이 바뀌어도 카메라를 강제로 이동하지 않는다. HUD·PartyRail·InitiativeRibbon에서 새 Actor를 강조하고, `F` 또는 `Space`로 Frame할 수 있음을 안내한다.

턴 시작 Soft Focus 알림은 한 번만 표시한다. 사용자가 카메라를 수동 조작하면 낮은 우선순위 연출 요청을 즉시 중단한다.

### 3.3 Downtime·Rest

Downtime은 별도 게임 맵이 아니라 현재 Scene 위에 DowntimeHeader와 Activity Side Sheet를 올린다.

```text
Top Center
→ Downtime 단계·남은 시간·참가 상태

Right Side Sheet
→ 가능한 Activity·비용·기간·참가자·결과 종류

Bottom Center
→ 현재 선택 Activity의 Confirm·Cancel
```

Short Rest·Long Rest는 다음 정보를 제출 전에 보여준다.

- 소요 게임 시간
- 회복되는 Resource와 자동 회복되지 않는 Resource
- 사용할 수 있는 Hit Dice·소모품
- 참가 Character
- 현재 Scene·Encounter 정책상 가능 여부
- DM 승인 또는 Party 합의가 필요한지 여부

Q는 현재 Rest Preview 또는 Activity Step 하나만 취소한다. E는 표시된 Rest·Activity Proposal을 제출한다.

### 3.4 Observer

Observer Projection은 조작 Hotbar를 제공하지 않는다.

```text
PartyRail 또는 공개 Actor 목록
공개 ActiveInfoPanel
Minimap·Map·Journal
Camera Bookmark·Focus
공개 Log
Role Badge: Observer
```

- 선택은 공개 정보 확인과 Camera Focus Proposal에만 사용한다.
- Actor 이동, 공격, Item 사용과 Interaction Action Table은 표시하지 않는다.
- 권한에 없는 행동 자리, 개수, 비활성 버튼도 만들지 않는다.

### 3.5 DM Live Mode

DM Live Mode는 Player 전장 셸을 유지하고 Dockable Workspace를 추가한다.

```text
Top
→ DM Role·Live/Paused·Save·Projection 상태
Left Dock
→ Scene·Actor·Asset
Right Dock
→ Inspector·Journal·Player Control·Request Queue
Bottom Dock
→ Encounter·Fog·Timeline·Roll
```

Player View Preview는 DM Source와 별도 Viewport·Projection으로 표시한다. Preview를 여는 행위는 제어권, Selection Authority나 Player Camera를 바꾸지 않는다.

DM 우클릭 행동표는 일반 Player Action과 DM Override를 섹션과 Label로 분리한다. Tier 3 Override는 일반 ContextActionTable에서 즉시 Commit하지 않고 영향 Preview와 별도 Confirm Surface로 이동한다.

## 4. 포인터·Focus·Component 상태

### 4.1 물리 입력

```text
왼쪽 클릭
→ PrimaryPointer
→ 선택 또는 클릭 전에 표시된 기본 행동

오른쪽 클릭
→ ContextActionPointer
→ Capability 기반 2열 행동표

마우스 휠 클릭 드래그
→ CameraOrbitPointer

Wheel
→ Zoom

Ctrl+Wheel
→ Camera Pivot Y

Q
→ 최상위 Context 한 단계 닫기·취소·거절

E
→ 현재 Preview·선택·승인·확정

ESC
→ Gameplay 의미 없음
```

### 4.2 상태 표현

모든 Button·Slot·Menu Entry는 필요한 범위에서 다음 상태를 가진다.

```text
idle
hover
focused
pressed
selected
pending
disabled
denied
stale
success
warning
error
```

구분:

- `disabled`: 사용자의 Capability에는 있으나 현재 조건을 만족하지 못함. 비활성 색상·클릭 불가·Hover/Focus 이유 제공.
- `denied`: 제출했으나 서버가 거부함. 관련 Control 또는 World 대상 근처에 이유 표시.
- `stale`: 표시된 Revision이 더 이상 유효하지 않음. 최신 상태 적용 후 재선택 경로 제공.
- `pending`: 제출됐으나 Authority Projection 확인 전. 중복 제출 차단.

권한에 없는 Action과 미인지 정보는 Disabled로 남기지 않고 Projection 자체에서 제거한다.

### 4.3 Disabled Reason 접근성

Pointer Hover 외에도 Keyboard Focus 후 `Details` 또는 동일 Tooltip Surface에서 이유를 확인할 수 있어야 한다. 색과 Hover만으로 의미를 전달하지 않는다.

## 5. Tooltip·Context Card·World Feedback

### 5.1 초기 Timing

| 종류 | 초기값 | 동작 |
|---|---:|---|
| World Hover Outline·기본 행동명 | 0초 | 즉시 표시 |
| Disabled Reason Tooltip | 0.15초 | 커서·Focus 근처 |
| 일반 Action Tooltip | 0.25초 | 이름·비용·대상·요약 |
| 상세 규칙 Tooltip | 0.75초 | 계산·출처·상세 조건 |
| Tooltip 종료 지연 | 0.08초 | 작은 Pointer 이동에서 깜박임 방지 |

Tooltip은 커서로부터 기본 16 px 떨어뜨리고, 클릭 대상·Token·경로·Persistent HUD와 겹치면 반대 방향으로 Flip한다.

### 5.2 World Action Label

선택 Actor가 있을 때 Pointer 위치의 기본 좌클릭 결과를 항상 예측 가능하게 표시한다.

예:

```text
장검 공격 · 명중 예상 65%
이동 · 18 ft
문 열기
캐릭터 선택
사용 불가 · 남은 이동 거리 부족
```

Action Label은 Pending이나 Authority Success를 의미하지 않는다.

### 5.3 Target Preview

공격·주문·상호작용 Preview는 필요한 범위에서 표시한다.

- 행동 이름과 Action Economy
- 사거리·유효 대상·영향 범위
- 엄폐·시야·Advantage·Disadvantage
- 예상 명중률 또는 판정 종류
- 사용하는 Resource
- 아군 피해·집중 종료·기회 공격 등 위험
- 실행 불가 이유

비밀 AC·저항·미인지 상태를 Client가 역산할 수 있는 정밀 정보는 표시하지 않는다.

### 5.4 Movement Preview

- 예상 경로
- 총 거리와 남은 이동력
- 어려운 지형·점프·등반·문 통과
- 기회 공격 또는 발견된 위험 구간
- 도달 가능한 최종 위치
- 도달 불가 원인

경로 Preview와 Destination Marker는 Local/Pending 상태를 명확히 표시한다. 서버 승인 후 Projection 위치와 일치할 때만 확정 표현으로 전환한다.

## 6. Exploration HUD 상세

### 6.1 PartyRail

- Player Character, 위임된 Companion, Summon을 표시한다.
- 기본 펼침 상태는 `auto`이며 4명 이하는 이름·HP·상태를 보이고, 화면·인원 압박 시 Portrait 중심으로 축약한다.
- Summon은 Owner 아래 접힌 그룹으로 표시한다.
- 연결 끊김·Observer 전환·제어권 위임은 별도 Badge와 Text를 사용한다.

### 6.2 ActiveActorPanel

탐험 기본 정보:

- Portrait·이름·레벨 또는 NPC 분류
- HP·임시 HP·AC
- 이동·집중·주요 상태
- 현재 조작자·제어권 상태
- Character Sheet·Inventory 진입

상세 상태 전체를 상시 표시하지 않고 `+N` 또는 Side Sheet로 확장한다.

### 6.3 Exploration Hotbar

기본 2행이며 다음 소스를 결합한다.

```text
고정된 사용자 행동
현재 Context 추천 행동
공통 행동
주문·특성
사용 가능한 Item
Overflow·검색
```

최근 사용만으로 기본 행동이나 Slot을 자동 교체하지 않는다. 사용자가 Pin·Reorder한 Layout을 우선한다.

### 6.4 Objective Tracker

기본은 접힌 한 줄 상태다.

- 활성 Objective 제목
- 다음 공개 단계
- 관련 Scene·Journal Link
- 완료·실패·갱신 상태

비공개 Objective, DM 메모와 숨은 단계의 개수도 Player에게 보내지 않는다.

## 7. Encounter HUD 보완

기존 전투 HUD 문서를 유지하며 다음 공백을 고정한다.

- Hotbar 기본 행 수는 2, 사용자 범위는 1–4다.
- EndTurn은 남은 Action·Bonus Action·Movement가 있어도 막지 않는다. 미해결 필수 Targeting·Authority Prompt가 있으면 Disabled하고 Hover 이유를 제공한다.
- 사용하지 않은 Resource가 있으면 Turn End Preview에서 요약하지만 Confirm을 강제하지 않는다.
- InitiativeRibbon Actor 클릭은 조작 가능한 Actor의 선택 전환을 우선한다.
- Reaction Prompt는 전장을 보존하는 중앙 하단 AuthorityPrompt다.
- Dice Presentation 중에도 Q/E 의미와 결과 상태를 잃지 않는다. Skip은 연출만 줄이고 Authority 순서를 바꾸지 않는다.
- Actor가 HP 0이 되면 ActiveActorPanel과 PartyRail은 `downed·unconscious·dead·stable`을 구분한다.

## 8. Inventory·Equipment·Loot·Transfer

### 8.1 Character Inventory 화면

기본 Side Sheet 또는 Full Panel 구성:

```text
Left
→ Character·Container Source, Category·Filter

Center
→ Item Grid 또는 List

Right
→ Equipment Slots, Item Detail·Comparison

Footer
→ Weight·Capacity·Currency·Context Actions
```

Item Card 최소 정보:

- 공개 이름·Icon·수량
- 장착·조율·식별 상태
- 무게·가격 또는 공개 가능한 가치
- 현재 위치와 Owner
- 사용할 수 있는 Action·비활성 상태

미식별 Item은 실제 정의, 희귀도, 비밀 효과를 암시하는 Icon·색·Tooltip을 사용하지 않는다.

### 8.2 Loot·Container 화면

```text
Left
→ Container·Ground Loot

Right
→ 선택 Character Inventory

상단
→ Source·Owner·잠금·거리·전투 비용

하단
→ 가져오기·모두 가져오기·보내기·나누기·검사
```

- `Take All`은 권한·소유권·Capacity·전투 비용 Preview를 먼저 보여준다.
- 줍기만으로 자동 장착하지 않는다.
- 동시 획득 충돌은 Pending 후 서버 Transaction 결과로 확정한다.
- 다른 Player에게 보내기는 대상·거리·행동 비용·수량을 보여주고 Tier 2 Confirm을 사용한다.
- 절도·소유권 분쟁 가능성이 있으면 공개 가능한 경고와 DM Adjudication 경로를 제공한다.

### 8.3 입력

- 좌클릭: Item 선택 또는 표시된 기본 행동.
- 우클릭: 사용·장착·해제·분할·이전·드롭·검사 Action Table.
- Q: Detail→Inventory Panel 순으로 한 단계 닫기.
- E: 현재 Transfer·Use·Equip Preview Confirm.
- Drag and Drop은 빠른 경로일 뿐이며 Click 기반 대체 경로를 반드시 제공한다.

### 8.4 비교와 정렬

장비 가능한 Item은 현재 장착 Item과 다음만 비교한다.

- 공개된 규칙 수치
- 요구 숙련·조율·조건
- 무게와 Action 제공
- 현재 사용 가능 여부

정렬·Filter 적용 상태는 Header에 항상 표시한다. `Filtered Empty`와 실제 Empty를 구분한다.

## 9. Journal·Map·Ping

### 9.1 Journal 화면

```text
Left
→ Folder·Recent·Search

Center
→ Document·Editor 또는 Read View

Right
→ Outline·Backlink·World Link Detail
```

- Journal의 History 탐색은 Back Button과 Breadcrumb를 사용한다.
- Q는 열린 Tooltip·Search Suggestion·Detail Side Sheet·Journal Panel을 한 단계씩 닫는다.
- Search Result Count, Recent와 Backlink는 권한 없는 문서 존재를 암시하지 않는다.
- Document Link는 Camera·Selection·SceneTransition Proposal만 만든다.

### 9.2 Map 화면

Map은 Journal과 별도 Tab이지만 같은 Stable Scene·Anchor Projection을 사용할 수 있다.

- 공개된 지형·Fog·Party·Ping·Journal Anchor만 표시한다.
- Camera 위치와 선택 Actor 위치를 분리해 표시한다.
- Map 클릭은 기본적으로 Camera Focus Proposal 또는 Ping Preview다.
- Character 이동은 별도의 명시적 Move Action과 경로 Preview를 통해서만 실행한다.
- 미인지 방·비밀 통로·숨은 Actor는 자리나 빈 마커도 보내지 않는다.

### 9.3 Ping

- 위치 Ping과 경로 Ping은 일시적 Presentation이다.
- Ping은 Movement·Targeting·Journal Anchor를 자동 생성하지 않는다.
- Audience와 Sender를 Label·Shape로 구분한다.
- 동일 Sender의 과도한 Ping은 Rate Limit 상태를 보여주되 Session Modal을 열지 않는다.

## 10. Character Sheet·Rest·Death UI

### 10.1 Character Sheet

기존 공식 2024형 구조를 유지한다. 구현 초기 기본은 `single_page`, 전투 중에는 `combat_side_sheet`를 우선 제안한다.

- Sheet에서 Roll·Attack·Spell을 선택하면 동일한 Action/Targeting Runtime으로 이동한다.
- 전체 Sheet가 열린 상태에서 Authority Prompt가 오면 Prompt가 우선한다.
- Sheet를 닫은 뒤 보존된 Targeting은 최신 Revision으로 재검증한다.

### 10.2 HP 0·Death Save

HP 0 상태는 전체 화면 Game Over Modal로 처리하지 않는다.

```text
ActiveActorPanel
→ 의식 없음·안정화·Death Save 상태

Hotbar
→ 현재 허용된 Death Save·Reaction·정보 행동만 표시

World
→ 선택과 Camera는 유지
```

Death Save 굴림이나 DM 판정이 필요한 경우 AuthorityPrompt로 표시한다. 이미 공개된 결과를 연출 때문에 숨기지 않는다.

### 10.3 휴식과 회복

Rest 완료 후 HP·Slot·Resource를 Client가 즉시 낙관적으로 변경하지 않는다. Pending→Server Result→Projection Reconciliation 순서를 따른다.

## 11. Session Entry·Role·Ready

Session 진입 흐름:

```text
연결
→ Campaign·Session 확인
→ Role 확인
→ Character 선택·배정
→ Projection 준비
→ Scene Ready
→ 입력 활성화
```

### 11.1 Entry Surface

표시:

- Campaign·Session 이름
- 현재 Role
- 선택 가능한 Character와 제어 상태
- 이미 사용 중·잠김·DM 승인 필요 상태
- Observer 진입
- 준비 상태와 연결 단계

준비되지 않은 Character를 선택해도 빈 화면으로 진입하지 않고 구체적 `Not Ready` 이유를 제공한다.

### 11.2 Role Change

Player↔Observer, Control Assignment와 DM Preview 변경 시:

- 이전 Role Projection을 폐기한다.
- 열린 Action Table·Targeting·Authority Prompt·Pending을 정리한다.
- Local UI Scale·Accent·Camera Preference는 유지한다.
- 새 Role Badge와 사용할 수 있는 Surface를 다시 구성한다.
- 권한이 사라진 정보는 Fade로 남기지 않고 즉시 Projection에서 제거한다.

## 12. Settings·System Menu

### 12.1 진입과 구조

Top-right `System` 버튼 또는 재설정 가능한 `OpenSystemMenu` Semantic Action으로 연다. ESC는 사용하지 않는다.

```text
System
├─ Interface
├─ Gameplay UX
├─ Camera
├─ Accessibility
├─ Key Bindings
├─ Graphics·Performance
├─ Session Information
└─ Leave Session
```

설정은 Local Preference와 Server-synced Preference를 구분해 표시한다. Gameplay Authority를 변경하는 Campaign Policy는 사용자 Settings에 두지 않는다.

### 12.2 초기 기본값

#### Interface

| 설정 | 기본값 | 범위·선택 |
|---|---:|---|
| Accent Color | `gold` | gold·azure·emerald·amethyst·teal·silver |
| UI Scale | `1.00` | 0.80–1.40, 0.05 Step |
| Text Scale | `1.00` | 0.90–1.30, 0.05 Step |
| Hotbar Rows | `2` | 1–4 |
| Hotbar Icon Scale | `1.00` | 0.85–1.20 |
| Hotbar Locked | `true` | On·Off |
| PartyRail Mode | `auto` | auto·expanded·compact |
| Combat Log | `recent` | collapsed·recent·expanded |
| Minimap Size | `medium` | hidden·small·medium·large |
| Minimap Orientation | `camera_up` | camera_up·north_up |
| Objective Tracker | `collapsed` | hidden·collapsed·expanded |
| World Action Label | `true` | On·Off |
| Floating Text | `standard` | off·minimal·standard |

#### Tooltip·Notification

| 설정 | 기본값 |
|---|---:|
| General Tooltip Delay | 0.25초 |
| Detailed Tooltip Delay | 0.75초 |
| Disabled Reason Delay | 0.15초 |
| 최대 동시 Toast | 3 |
| Success Toast | 2.5초 |
| Info Toast | 3초 |
| Warning Toast | 5초 |
| Ordinary Error Toast | 6초 또는 상태 변경 시까지 |
| 동일 Event 알림 병합 창 | 2초 |

#### Camera

| 설정 | 기본값 |
|---|---:|
| FOV | 50 |
| Orbit Sensitivity | 0.004 기준 |
| WASD Pan Speed | 55 studs/s 기준 |
| Zoom Step | 5 |
| Camera Smoothing | 14 기준 |
| Distance Range | 20–130 |
| Invert Y | false |
| Edge Pan | false |
| Turn Focus | `soft_notification` |
| Occlusion Correction | true |
| Camera Shake | 35% |

카메라 수치는 사용자 제공 CameraManager의 조작감을 기준으로 한 초기값이다.

#### Accessibility

| 설정 | 기본값 | 선택 |
|---|---:|---|
| Motion Profile | `full` | full·reduced·minimal |
| High Contrast | false | On·Off |
| Color Vision Profile | `none` | none + 검수된 Profile |
| Reduce Flash | false | On·Off |
| Reduce Translucency | false | On·Off |
| Cursor Scale | `1.00` | 0.80–1.50 |
| Icon Text Labels | `contextual` | off·contextual·always |
| Focus Ring | `automatic` | automatic·always |
| Hold to Confirm | false | 초기 구현은 단일 Confirm 우선 |
| Presentation Skip | true | On·Off |

### 12.3 설정 적용

- UI·Camera·Accessibility 설정은 즉시 Preview하고 되돌릴 수 있다.
- 변경 중 Selection·Pending·Modal·Input Context를 초기화하지 않는다.
- Key Binding 충돌은 새 Binding을 저장하기 전에 충돌 목록과 교체·취소를 표시한다.
- `기본값으로 복원`은 현재 Category만 복원하며 전체 설정 초기화는 별도 Tier 1 확인을 사용한다.
- Leave Session은 현재 미제출 Draft·Pending·저장 상태를 보여주고 안전하게 종료한다.

## 13. 저장 범위

### 13.1 사용자 Account Preference

가능하면 사용자별로 동기화한다.

- Accent·UI Scale·Text Scale
- Tooltip·Notification
- Accessibility·Motion
- Camera 감도·Invert·Shake
- Key Binding Profile

읽지 못하면 안전한 기본값을 사용하고 Gameplay를 막지 않는다.

### 13.2 Device Local

- Dock·Panel 크기와 위치
- 마지막 Window·Viewport별 축약 상태
- Graphics·Performance Preference

다른 화면 비율에서 그대로 적용하지 않고 Layout Constraint로 정규화한다.

### 13.3 Character·Campaign Preference

- Hotbar Layout·Pinned Action·Default Action 지정
- Character Sheet 마지막 Page·Mode
- Inventory 정렬·Filter의 안전한 사용자 선호

Capability가 사라지면 Slot을 다른 행동에 자동 재연결하지 않고 Missing Reference로 표시한다.

### 13.4 Ephemeral

저장하지 않는다.

- 현재 선택·Hover·Context Action Table
- Targeting Candidate·Preview
- Pending Command의 Client Animation
- 일시 Tooltip·Toast·Ping

Reconnect 후 Authority-bound 상태는 서버 Projection에서 다시 구성한다.

## 14. Reconnect·Resync·Recovery

Recovery Surface는 Spinner 하나로 끝내지 않는다.

```text
연결 감지
→ 재접속 시도
→ Session·Role 확인
→ Projection Snapshot 수신
→ Scene·Controlled Actor 준비
→ UI·Input 재구성
→ 입력 재개
```

현재 성공 단계, 실패 단계와 가능한 다음 행동을 표시한다.

- Local Layout·Accent·Accessibility·Camera Preference는 유지한다.
- 이전 ConnectionEpoch·AuthorityEpoch Prompt·Selection·ACK는 폐기한다.
- Last Known Good 전장은 읽을 수 있어도 Authority-bound 입력은 Gate한다.
- Panel 하나가 실패하면 Error Boundary로 격리하고 다른 HUD를 유지한다.
- 심각 오류는 안전한 Support Reference를 제공한다.

## 15. Onboarding·Context Hint

튜토리얼은 강제 전체 화면 연속 Modal이 아니라 현재 Context에 붙는 짧은 Hint다.

초기 Hint 후보:

- Actor 좌클릭 선택
- 선택 후 World Action Label과 기본 행동
- 우클릭 Action Table
- 중클릭 Camera Orbit
- Q 한 단계 취소
- E Preview 확정
- F·Space 선택 Actor Frame
- Hotbar·Inventory·Journal·Map 진입

규칙:

- 이미 성공한 Semantic Action은 해당 Hint를 완료한다.
- Hint는 Q로 현재 하나만 닫을 수 있다.
- 진행 중 Targeting·AuthorityPrompt보다 낮은 우선순위다.
- Settings에서 Reset·Off할 수 있다.
- Hint를 끄더라도 Input Hint·Accessible Label은 유지한다.

## 16. 공통 Component와 ViewModel

최소 Shared Component:

```text
ModeRoleBadge
PartyRail
ActorPortraitCell
ActiveActorPanel
ActionHotbar
ActionSlot
ResourceRail
ContextActionTable
WorldActionLabel
ReasonTooltip
TargetPreviewCard
MovementPreview
ObjectiveTracker
Minimap
LogPanel
InventoryPanel
LootTransferPanel
JournalPanel
MapPanel
SettingsPanel
AuthorityPrompt
RecoverySurface
ToastStack
```

공통 Action ViewModel:

```text
ActionEntryView
├─ actionId
├─ localizedName
├─ iconId
├─ category·stableOrder
├─ availabilityState
├─ disabledReasons[]
├─ costSummary
├─ targetSummary
├─ riskTier
├─ isDefault
├─ isPinned
├─ accessibleName
└─ projectionRevision
```

UI는 Domain Object와 Workspace Instance를 직접 읽지 않는다. Component는 UI Intent만 제출한다.

## 17. Acceptance Matrix

### 17.1 Global Shell

- Exploration·Encounter·Downtime·Observer·DM Live Mode가 명확히 구분된다.
- 중앙 전장 안전 영역이 유지된다.
- Q가 한 단계만 닫고 ESC가 Gameplay를 실행하지 않는다.
- UI Scale 0.80·1.00·1.40에서 핵심 Action이 남는다.

### 17.2 Direct Play

- 좌클릭 결과가 클릭 전에 표시된다.
- 조작 가능한 아군은 선택 전환이 우선이다.
- 우클릭 Action Table에 권한 밖 Action이 없다.
- 현재 불가능 Action은 비활성색이며 Hover·Focus 이유가 있다.
- 중클릭 Orbit이 우클릭 Action Table과 충돌하지 않는다.

### 17.3 Exploration·Encounter

- 이동 경로·거리·위험·Destination이 보인다.
- 공격·주문 대상·범위·비용이 보인다.
- 행동 후 선택 Actor가 유지된다.
- 턴 전환 시 Camera가 강제로 이동하지 않는다.
- EndTurn Disabled 이유와 남은 Resource Preview가 동작한다.

### 17.4 Inventory·Loot

- Item Definition·Instance·Location·Owner가 혼동되지 않는다.
- Loot 충돌·Capacity·Transfer Pending과 Projection 결과가 구분된다.
- Drag 없이도 전체 경로를 사용할 수 있다.
- 미식별 Item 정보가 누출되지 않는다.

### 17.5 Journal·Map

- 권한 없는 Document·Anchor·지형·Actor가 Search·Count·Map에 없다.
- Q와 화면 내 Back History가 충돌하지 않는다.
- World Link가 안전한 Proposal만 만든다.

### 17.6 Settings·Accessibility

- 모든 초기 기본값과 복원이 동작한다.
- Accent 변경 중 Focus·Selection·Pending이 유지된다.
- Tooltip 정보가 Keyboard Focus로도 접근 가능하다.
- Reduced·Minimal Motion에서 동일 결과를 이해할 수 있다.

### 17.7 Recovery·Role

- Reconnect 단계를 표시한다.
- Role 변경 후 이전 권한 정보와 Context가 남지 않는다.
- Local Preference는 유지되고 Authority-bound UI는 재구성된다.

## 18. 구현 순서

```text
1. Shared Shell·Layer·ModeRoleBadge·System Entry
2. ADR-0088 Input Router·Context Action·Reason Tooltip
3. Exploration HUD·World Action·Movement Preview
4. Encounter HUD 정합화·Turn·Reaction·Dice
5. Inventory·Loot·Equipment·Transfer
6. Journal·Map·Ping 화면
7. Character Sheet·Rest·Death Flow
8. Settings·Preference·Accessibility
9. Entry·Role Change·Reconnect·Recovery
10. DM Live Workspace 정합화
11. 전체 Acceptance·Screenshot·Performance 측정
```

한 단계의 정적 Gate와 Human Evidence가 완료되기 전에 다음 화면을 Runtime PASS로 주장하지 않는다.

## 19. 측정 후 조정 가능 항목

다음은 실제 Roblox Studio에서 측정해 조정할 수 있다.

- Tooltip·Toast Duration
- Panel·Hotbar·Minimap 기준 크기
- Camera 감도·Smoothing·Occlusion 속도
- Gradient·Glow·Motion 강도
- List Virtualization·UI Commit Budget
- Flash·Shake Hard Limit

측정 조정은 Q/E/Pointer 의미, 권한 Projection, Selection Continuity, Server Authority와 Error 공개 경계를 바꾸지 않는다.
