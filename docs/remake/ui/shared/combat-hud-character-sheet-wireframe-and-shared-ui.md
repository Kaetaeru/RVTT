# 35. 전투 HUD·캐릭터 시트 와이어프레임과 공통 UI 규격

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`08. 공통 입력 교과서`](../../../common-input/common-input-grammar.md)
  - [`27. 주사위 굴림·연출·결과 확정 모델`](../../../../systems/combat/dice-roll-presentation-and-resolution-gating-model.md)
  - [`28. 인카운터·주도권·턴과 제어권 모델`](../../../../systems/combat/encounter-initiative-turn-and-control-authority-model.md)
  - [`33. Baldur's Gate 3형 전투 HUD와 행동 UI 모델`](../../../combat-hud/baldurs-gate-style-combat-hud.md)
  - [`34. 공식 2024 형식 캐릭터 시트와 실시간 플레이어 UI 모델`](../../../character-sheet/official-2024-character-sheet-and-live-player-ui.md)
  - [`ADR-0041`](../../../../decisions/ADR-0041-shared-combat-hud-character-sheet-layout-and-ui-layering.md)

## 1. 문서 목적

이 문서는 전투 HUD와 캐릭터 시트를 실제 Roblox UI로 구현할 수 있도록 다음을 고정한다.

- 16:9 PC 기준 와이어프레임
- 패널별 기준 크기와 최소·최대 크기
- 중앙 전장 안전 영역
- 넓은 화면, 일반 화면과 제한 화면의 반응형 동작
- 캐릭터 시트의 펼침·단일 페이지·측면 보기
- 패널 겹침과 입력 레이어 우선순위
- 공통 UI 컴포넌트와 상태 표현
- 전투, 대상 지정, 주사위 연출과 반응창 사이의 화면 전환
- 긴 Feature·Feat·주문·장비 목록의 표시 방식
- 사용자 UI 배율과 접근성

핵심 원칙:

```text
중앙 전장을 먼저 확보한다.
→ 필요한 HUD를 가장자리에 배치한다.
→ 상세 정보는 요청된 순간에만 확장한다.
```

---

## 2. 기준 화면과 좌표 체계

기준 화면:

```text
ReferenceViewport = 1920 × 1080
DesignSafeInset = Left 32 / Right 32 / Top 24 / Bottom 24
BaseUiScale = 1.0
UserUiScale = 0.80 ~ 1.40
```

실제 위치는 Roblox `AnchorPoint`와 상대 좌표를 사용한다. 아래 px 값은 기준 화면에서의 설계 목표이며 고정값이 아니다.

```text
최종 크기
= 기준 크기
× 해상도 구간 배율
× 사용자 UI 배율
```

화면 상단 Roblox CoreGui inset과 노치·오버스캔 안전 영역을 고려해 `GuiService:GetGuiInset()` 또는 대응 API를 반영한다.

---

## 3. 중앙 전장 안전 영역

1920×1080 기준 기본 전장 안전 영역:

```text
Left   = 260 px
Right  = 360 px
Top    = 108 px
Bottom = 210 px
```

즉 다음 영역에는 지속 패널을 두지 않는다.

```text
X: 260 ~ 1560
Y: 108 ~ 870
```

이 영역은 카메라의 실제 시야를 강제로 잘라내는 것이 아니라, UI가 전술적으로 중요한 중앙 공간을 가리지 않도록 하는 설계 기준이다.

대상 카드, 명중률, 이동 거리와 범위 텍스트는 안전 영역 안에 나타날 수 있지만 다음 규칙을 따른다.

- 커서 또는 선택 대상 가까이에 나타난다.
- 토큰과 범위 중심을 완전히 덮지 않는다.
- 화면 밖이나 고정 HUD와 겹치면 자동으로 반대 방향으로 배치한다.
- 여러 피드백이 겹치면 핵심 결과를 우선하고 세부 정보는 툴팁으로 접는다.

---

## 4. 기본 전투 HUD 와이어프레임

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

기준:

```text
Anchor = TopCenter
Width  = 720 ~ 1120 px
Height = 72 px
PortraitCell = 56 × 56 px
Gap = 6 px
```

표시:

- 현재 Actor는 6 px 전방 돌출과 밝은 외곽선
- 이미 턴을 마친 엔트리는 명도 감소
- 행동 불가·의식 없음은 상태 배지 표시
- 같은 제어 그룹은 얇은 연결 바 표시
- 화면에 들어오지 않는 엔트리는 좌우 스크롤 또는 축약 그룹으로 표시

현재 턴, 다음 2~3개 엔트리와 위험한 보스 엔트리를 화면 중앙에 우선 유지한다.

### 4.2 PartyRail

기준 펼침 상태:

```text
Anchor = LeftCenter
Width  = 220 px
Height = 최대 720 px
Portrait = 64 × 64 px
EntryHeight = 78 px
```

축소 상태:

```text
Width = 76 px
Portrait = 56 × 56 px
텍스트와 상세 자원 숨김
```

한 엔트리의 정보:

- 초상화
- 이름 또는 축약 이름
- HP 바와 임시 HP
- 집중, 의식 없음과 핵심 상태 최대 3개
- 현재 제어자 또는 위임 상태
- 현재 턴 사용 여부

소환수는 소유자 아래에 들여쓰기하여 묶는다. 엔트리가 많으면 가상화된 세로 스크롤을 사용한다.

### 4.3 ActiveActorPanel

기준:

```text
Anchor = BottomLeft
Width  = 300 px
Height = 168 px
Portrait = 104 × 104 px
```

표시:

- 큰 초상화
- 이름, 직업·레벨 또는 NPC 분류
- 현재 HP / 최대 HP / 임시 HP
- AC, 이동력, 집중
- 현재 행동·보너스 행동·반응 상태의 요약
- 캐릭터 시트 열기 버튼

DM이 NPC를 제어할 때는 소유권과 현재 제어 모드를 추가 표시한다.

### 4.4 ResourceRail

ActionHotbar 상단 또는 내부 상단에 위치한다.

```text
Height = 32 ~ 44 px
ResourcePip = 18 ~ 24 px
```

우선순위:

1. 행동
2. 보너스 행동
3. 반응
4. 남은 이동력
5. 현재 행동에 필요한 직업 자원
6. 주문 슬롯
7. 기타 추적 자원

모든 자원을 한 줄에 강제로 표시하지 않는다. 현재 문맥과 관련 없는 자원은 접힌 자원 서랍에서 확인한다.

### 4.5 ActionHotbar

기준:

```text
Anchor = BottomCenter
Width  = 760 ~ 980 px
Height = 116 ~ 176 px
ActionSlot = 52 × 52 px
Gap = 4 px
Rows = 기본 2, 사용자 선택 1 ~ 3
```

Hotbar 영역:

```text
CategoryTabs
PinnedActions
ContextActions
OverflowButton
```

슬롯 상태:

- 사용 가능
- 문맥상 사용 불가
- 자원 부족
- 재사용 대기 또는 사용 횟수 소진
- 선택됨
- 대상 지정 중
- 지속 토글 활성
- 반응 Ask 활성

색상 외에 아이콘 모양, 잠금 표식, 테두리와 짧은 이유 텍스트를 함께 사용한다.

길이가 긴 행동명은 슬롯에는 표시하지 않고 Hover·Focus 툴팁에서 보여준다.

### 4.6 EndTurnControl

기준:

```text
Anchor = BottomRight
Size = 92 × 92 px
```

상태:

```text
End Turn
Cancel End Turn
Waiting
Skip Reaction
End Group Turn
```

현재 아직 행동·이동·자원이 남아 있으면 외곽에 잔여 자원 표시를 제공하지만 턴 종료를 막지는 않는다.

### 4.7 Minimap

```text
Anchor = TopRight
Size = 220 × 220 px
CollapsedSize = 44 × 44 px
```

전투 중에는 현재 교전 범위, 파티 위치와 DM이 공개한 지형만 표시한다. Fog와 탐지되지 않은 Actor의 정보를 우회해 보여주지 않는다.

### 4.8 CombatLog

기준:

```text
Anchor = RightCenter
ExpandedWidth = 340 px
MinWidth = 280 px
MaxWidth = 520 px
Height = 420 ~ 720 px
CollapsedTab = 40 px
```

기본은 접힌 상태 또는 최근 3개 결과 요약 상태다. 사용자가 펼치면 계산 근거, RollRecord와 EffectResolution을 확인한다.

---

## 5. 문맥별 HUD 변화

### 5.1 평상시

```text
InitiativeRibbon 또는 탐험 헤더
PartyRail
ActiveActorPanel
Hotbar
접힌 CombatLog
```

### 5.2 행동 선택

```text
선택한 ActionSlot 강조
사용 가능한 대상 윤곽
필요한 변형·슬롯 레벨 패널
Q 취소 / E 다음 단계
```

### 5.3 대상 지정

Hotbar는 선택한 행동과 비용만 남기고 시각적 소음을 줄인다.

```text
ActionHotbar → CompactTargetingBar
ResourceRail → 필요한 비용만 강조
EndTurn → 일시 비활성
WorldFeedback → 거리·시야·엄폐·명중률
```

### 5.4 주사위 연출

```text
HUD 명도 감소
대상 카드와 행동 이름 유지
주사위 연출 중앙 우선
결과 공개 전 HP·순서 변화 숨김
```

다음 입력만 허용한다.

- 접근성 Skip
- 카메라 제한 조작
- 로그 또는 설명 읽기
- 연결 문제 처리

### 5.5 반응·DM 승인

반응창은 화면 중앙을 완전히 덮는 거대 모달이 아니라, 전장과 관련 Actor를 볼 수 있는 중앙 하단 카드로 표시한다.

```text
Width = 560 ~ 760 px
MaxHeight = 520 px
```

여러 선택지가 있으면 `1–5`로 선택하고 `E`로 확정하며 `Q`로 거절한다.

### 5.6 전투 일시정지

DM이 전투를 정지하면 전체 화면을 가리지 않고 상단에 상태 바를 표시한다.

```text
전투 일시정지 — DM이 장면을 조정 중입니다.
```

플레이어는 캐릭터 시트, 로그와 툴팁을 계속 볼 수 있다.

---

## 6. 캐릭터 시트 와이어프레임

### 6.1 double_spread

기준:

```text
Viewport 권장 = 1600 px 이상
PanelSize = 최대 1480 × 860 px
PageGap = 20 px
각 Page = 약 710 × 820 px
```

```text
┌────────────────────────────────────────────────────────────┐
│ Character Header / Page Controls / Close                   │
├──────────────────────────┬─────────────────────────────────┤
│ Page 1                   │ Page 2                          │
│ 능력·기술·전투·특성     │ 주문·장비·인물 정보            │
└──────────────────────────┴─────────────────────────────────┘
```

배경은 전장을 어둡게 처리하지만 완전히 가리지 않는다. 위험한 반응·현재 턴·HP 정보는 가장자리 축약 HUD로 남긴다.

### 6.2 single_page

```text
PanelWidth = 760 ~ 940 px
PanelHeight = 화면 높이의 86 ~ 92%
```

상단 탭:

```text
1. 핵심
2. 주문·장비
```

페이지 내부는 종이 시트의 읽기 순서를 유지하되 화면 높이를 넘으면 섹션 단위 스크롤을 사용한다.

### 6.3 combat_side_sheet

```text
Anchor = RightCenter 또는 LeftCenter
Width = 420 ~ 560 px
Height = 화면 높이의 78 ~ 90%
```

측면 시트 탭:

```text
요약
능력·기술
전투
특성
주문
장비
인물
```

전장 조작을 유지할 수 있지만 측면 패널과 겹치는 월드 클릭은 차단한다. 카메라 중심은 남은 전장 안전 영역의 중앙으로 보정할 수 있다.

---

## 7. 캐릭터 시트 내부 배치

### 7.1 공통 헤더

```text
초상화
캐릭터 이름
직업·레벨·하위직업
종족·배경
현재 HP 요약
페이지 또는 섹션 탭
닫기
```

### 7.2 1페이지 핵심 영역

세 열 구조를 기본으로 한다.

```text
LeftColumn
→ 능력치와 기술

CenterColumn
→ 숙련, AC, 우선권, 속도, HP, 죽음 내성, 공격

RightColumn
→ 숙련, 종족 특성, 직업 특성, Feat
```

Feat와 특성은 고정 높이 텍스트 상자가 아니라 가상화 목록으로 표시한다. 중요 항목은 고정할 수 있다.

### 7.3 2페이지 영역

```text
Left / Center
→ 주문 능력, 슬롯, 준비 주문과 주문 목록

RightTop
→ 장비, 화폐, 조율

RightBottom
→ 언어, 외모, 성격, 배경과 메모
```

주문 목록은 레벨별 접힘 섹션과 검색·필터를 제공한다.

```text
준비됨
집중
의식
행동 비용
공격 또는 내성
현재 사용 가능
```

### 7.4 수치 근거 보기

파생 수치에 Hover 또는 세부 보기 명령을 사용하면 계산 근거를 표시한다.

```text
AC 18
├─ 기본 10
├─ 갑옷 6
├─ 방패 2
└─ 상태 보정 0
```

플레이어에게 공개되지 않는 DM 전용 효과는 이름을 숨기고 허용된 결과만 표시한다.

---

## 8. 패널 충돌 해결 순서

공간이 부족할 때 다음 순서로 축소한다.

```text
1. CombatLog를 탭으로 접는다.
2. Minimap을 아이콘으로 접는다.
3. PartyRail을 초상화 전용으로 축소한다.
4. Hotbar의 슬롯 간격과 아이콘을 축소한다.
5. Hotbar를 한 행 + 스크롤로 전환한다.
6. ActiveActorPanel의 부가 정보를 숨긴다.
7. 캐릭터 시트를 single_page로 전환한다.
8. 제한 화면에서는 보조 패널을 탭 메뉴로 전환한다.
```

InitiativeRibbon, 현재 Actor의 HP, 행동 자원과 핵심 확인·취소 입력은 마지막까지 유지한다.

---

## 9. UI 레이어와 입력 소유권

```text
Layer 0: WorldScene
Layer 1: WorldFeedback
Layer 2: PersistentHud
Layer 3: CharacterSheet
Layer 4: Tooltip
Layer 5: ContextPrompt
Layer 6: ReactionAndApproval
Layer 7: DicePresentation
Layer 8: CriticalSystem
```

입력 규칙:

- 상위 레이어가 포인터를 소비하면 하위 레이어로 전달하지 않는다.
- 전체 시트는 전장 클릭과 Hotbar 입력을 차단한다.
- 측면 시트는 패널 영역 밖의 카메라 입력을 허용한다.
- 반응창은 시트보다 우선한다.
- 주사위 연출은 반응 선택이 이미 끝난 이후에만 열린다.
- 오류·연결 복구 창은 모든 게임 입력보다 우선한다.

전체 시트를 열기 전에 대상 지정 중이었다면:

```text
TargetingSession 유지
→ 입력 일시중지
→ 시트 닫기
→ 서버 revision 재검증
→ 유효하면 대상 지정 복귀
→ 무효하면 안전하게 취소
```

---

## 10. 공통 컴포넌트 계약

### PanelFrame

```text
variant: hud | sheet | modal | tooltip
header
body
footer
collapsible
resizable
```

### PortraitCell

```text
portrait
name
health
temporaryHealth
statusBadges
turnState
controlState
factionState
```

### ActionSlot

```text
icon
name
costBadges
uses
cooldownOrRecovery
availability
selectionState
hotkeyHint
sourceBadge
```

### ResourcePip

```text
resourceType
current
maximum
spendState
recoveryHint
```

### StatField

```text
label
value
modifier
proficiencyState
clickAction
breakdown
editPolicy
```

### StatusBadge

```text
icon
shortLabel
stacksOrDuration
severity
visibilityPolicy
```

### TooltipCard

```text
title
classification
summary
numbers
costs
requirements
source
nestedTerms
```

컴포넌트는 서버 규칙 객체를 직접 참조하지 않고 UI Projection DTO만 받는다.

---

## 11. 사용자 설정

저장 가능한 사용자별 설정:

```text
uiScale
textScale
hotbarRows
partyRailMode
combatLogWidth
combatLogDefaultState
characterSheetMode
characterSheetSide
characterSheetLastPage
sectionCollapseState
tooltipDelay
reducedMotion
highContrast
colorVisionProfile
```

UI 배율을 변경해도 클릭 영역은 최소 40×40 px 이하로 내려가지 않게 한다.

---

## 12. 성능 규칙

- Hotbar는 `CapabilitySnapshot.revision`이 바뀔 때만 재계산한다.
- HP와 자원은 해당 필드만 delta 갱신한다.
- 긴 Feature, Feat, 주문과 장비 목록은 `VirtualizedList`를 사용한다.
- 화면 밖 항목의 툴팁과 아이콘 상세는 지연 로드한다.
- 닫힌 시트 페이지는 레이아웃 계산과 애니메이션을 중단한다.
- UI 애니메이션은 Tween 수를 제한하고 같은 속성 Tween을 병합한다.
- 해상도 변경은 짧은 debounce 후 한 번만 재배치한다.

---

## 13. 테스트 기준

### 해상도

- 1920×1080
- 2560×1440
- 3440×1440
- 1600×900
- 1366×768
- 1280×720

### 내용량

- 파티 1명 / 4명 / 8명
- 이니셔티브 5명 / 20명 / 50명
- Hotbar 행동 5개 / 40개 / 120개
- Feature·Feat 5개 / 30개 / 100개
- 준비 주문 5개 / 30개 / 100개
- 장비 10개 / 100개 / 500개

### 상태 전환

- 캐릭터 시트 열린 중 자신의 턴 시작
- 시트 열린 중 반응 요청
- 대상 지정 중 시트 열기와 닫기
- 주사위 연출 중 해상도 변경
- DM이 제어권을 회수하는 순간 NPC 시트 열림
- 재접속 후 기존 페이지·스크롤·Hotbar 복구

완료 기준:

- 중앙 전장의 핵심 대상과 범위가 지속 패널에 가려지지 않는다.
- 작은 화면에서도 턴, HP, 행동 자원과 Confirm·Cancel 의미를 잃지 않는다.
- 반응창과 주사위 연출이 캐릭터 시트 뒤에 숨지 않는다.
- 대량의 사용자 콘텐츠가 추가되어도 전체 UI를 재작성하지 않는다.
- UI에서 보이는 수치와 서버 권위 상태가 항상 같은 revision을 가리킨다.
