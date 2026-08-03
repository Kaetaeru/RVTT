# ADR-0041: 전투 HUD와 캐릭터 시트는 공통 앵커·레이어·반응형 규격을 사용한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0010`](../ui/common-input/common-input-grammar.md)
  - [`ADR-0033`](ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`ADR-0034`](ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0039`](ADR-0039-baldurs-gate-style-combat-hud-and-contextual-action-ui.md)
  - [`ADR-0040`](ADR-0040-official-2024-character-sheet-and-live-player-view.md)
  - [`35. 전투 HUD·캐릭터 시트 와이어프레임과 공통 UI 규격`](../ui/shared/combat-hud-character-sheet-wireframe-and-shared-ui.md)

## 배경

전투 HUD와 캐릭터 시트의 정보 구조는 정해졌지만, 실제 화면 크기와 겹침 규칙이 없으면 다음 문제가 생긴다.

- 이니셔티브, Hotbar, 파티 패널과 전투 로그가 서로 다른 화면 비율에서 겹친다.
- 캐릭터 시트를 열었을 때 반응창, 주사위 연출과 대상 지정이 충돌한다.
- 각 패널이 독자적인 크기와 입력 규칙을 사용해 UI가 일관되지 않는다.
- Feature, Feat, 주문과 사용자 콘텐츠가 늘어날수록 아이콘과 텍스트가 넘친다.
- 화면 해상도별로 별도 UI를 만들면 유지보수 비용이 커진다.

## 결정

RVTT의 PC UI는 `1920 × 1080`, 16:9를 기준 와이어프레임으로 사용한다. 실제 구현은 절대 픽셀 복사가 아니라 `AnchorPoint`, 상대 크기, 최소·최대 크기와 사용자 UI 배율을 조합한다.

```text
ReferenceViewport: 1920 × 1080
DesignSafeInset: 좌우 32 px / 상하 24 px
BaseUiScale: 1.0
UserUiScale: 0.80 ~ 1.40
```

핵심 전투 HUD는 화면 가장자리에 앵커된다.

```text
TopCenter   → InitiativeRibbon
LeftCenter  → PartyRail
BottomLeft  → ActiveActorPanel
BottomCenter→ ActionHotbar + ResourceRail
BottomRight → EndTurnControl
TopRight    → Minimap
RightCenter → CombatLog
CenterWorld → WorldFeedback
```

기본 HUD 위치는 Baldur's Gate 3형 읽기 흐름을 유지하기 위해 자유 배치하지 않는다. 사용자는 다음만 조정할 수 있다.

- 전체 UI 배율
- CombatLog 펼침 폭
- PartyRail 축소·확장
- Hotbar 행 수
- 툴팁 크기
- 캐릭터 시트 표시 방식

## 반응형 구간

```text
wide
→ 가로 1600 px 이상
→ 모든 패널 기본 펼침 가능

compact
→ 가로 1280 ~ 1599 px
→ 파티 패널과 로그 자동 축소
→ Hotbar 아이콘과 간격 축소

constrained
→ 가로 1280 px 미만 또는 세로 720 px 미만
→ 단일 페이지 시트
→ 일부 보조 패널 탭화
→ 중앙 전장 우선
```

화면 비율이 달라도 중앙 전장 안전 영역을 우선 보존한다.

## 캐릭터 시트 표시 방식

캐릭터 시트는 같은 데이터와 컴포넌트를 사용하면서 세 가지 레이아웃을 제공한다.

```text
double_spread
→ 2페이지를 나란히 표시
→ 넓은 화면의 기본값

single_page
→ 한 페이지씩 크게 표시
→ 페이지 탭으로 전환

combat_side_sheet
→ 화면 오른쪽 또는 왼쪽의 측면 패널
→ 핵심 수치와 선택한 섹션만 표시
```

전체 시트가 열리면 전투 HUD는 완전히 제거되지 않는다. 현재 턴, 반응 대기, HP와 위험 경고처럼 필수 정보만 축소 표시한다.

## UI 레이어 우선순위

입력과 표시 우선순위는 다음과 같다.

```text
WorldScene
→ WorldFeedbackLayer
→ PersistentHudLayer
→ CharacterSheetLayer
→ TooltipLayer
→ ContextPromptLayer
→ ReactionAndApprovalLayer
→ DicePresentationLayer
→ CriticalSystemLayer
```

상위 레이어가 입력을 소유하는 동안 하위 레이어는 필요한 범위에서만 비활성화된다.

```text
주사위 연출
→ 결과에 영향을 주는 입력 잠금
→ 카메라와 접근성 Skip은 허용

반응·DM 승인
→ 시트와 Hotbar 입력 중지
→ 관련 정보 읽기는 유지

전체 캐릭터 시트
→ 전장 클릭 차단
→ 실시간 상태 갱신은 유지

측면 시트
→ 전장 카메라와 허용된 조작 유지
```

## 공통 UI 컴포넌트

전투 HUD와 캐릭터 시트는 동일한 컴포넌트 라이브러리를 사용한다.

```text
PanelFrame
PortraitCell
ActionSlot
ResourcePip
StatField
SectionHeader
TooltipCard
StatusBadge
ProgressMeter
VirtualizedList
ModalPrompt
InputHintStrip
```

Feature, Feat, 주문, 장비와 사용자 콘텐츠는 전용 화면 코드를 만들지 않고 Presentation Metadata로 이 컴포넌트에 투영된다.

## 입력 규칙

물리 키는 UI 컴포넌트에 직접 연결하지 않는다.

```text
OpenCharacterSheet
CloseTopLayer
ConfirmContext
CancelContext
SelectContextSlot1..5
ToggleCombatLog
TogglePartyRail
```

`Q`, `E`, `1–5`의 실제 의미는 활성 입력 문맥에 따라 결정되고 `InputHintStrip`에 표시된다.

## 성능

- 패널 전체를 매 프레임 다시 만들지 않는다.
- 서버 Projection의 revision과 delta만 반영한다.
- 긴 주문·특성·장비 목록은 가상화한다.
- 닫힌 페이지와 접힌 섹션은 렌더와 레이아웃 비용을 중지한다.
- 툴팁은 지연 생성하고 재사용한다.
- 화면 크기 변화는 debounce 후 레이아웃을 다시 계산한다.

## 접근성

- 색상만으로 진영, 상태와 사용 가능 여부를 구분하지 않는다.
- 아이콘, 테두리 형태, 텍스트와 패턴을 함께 사용한다.
- UI 배율과 텍스트 배율을 독립 제공한다.
- 긴 애니메이션과 화면 흔들림을 줄이는 설정을 제공한다.
- 키보드 탐색과 명확한 포커스 표시를 제공한다.

## 결과

- 전투 HUD와 캐릭터 시트가 같은 화면 규칙과 컴포넌트를 사용한다.
- 해상도별 별도 UI 복제를 줄인다.
- 반응, 주사위, 캐릭터 시트와 대상 지정의 입력 충돌을 예방한다.
- 새 Feature, Feat와 사용자 콘텐츠가 공통 UI를 통해 자동으로 표시된다.
- 중앙 전장을 유지하면서 공식 시트형 상세 정보도 제공할 수 있다.
