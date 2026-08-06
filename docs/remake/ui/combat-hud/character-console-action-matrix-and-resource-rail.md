# Character Console Action Matrix와 Resource Rail 구현 계약

- 상태: `CURRENT · IMPLEMENTATION READY`
- 최종 갱신일: 2026-08-06
- 상위 결정: [`ADR-0090`](../../decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- 기본 Console 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 입력 문법: [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 고정밀 HTML: [`User Guide HTML`](../../user-guides/html/index.html#exploration)

## 1. 목적

하단 Character Console을 Roblox UI Component로 직접 구현할 수 있도록 Layout·Projection·Settings·Interaction을 고정한다.

## 2. Projection

```text
CharacterConsoleProjection
├─ actorIdentity
├─ vitalState
├─ conditions[]
├─ actionEconomy
├─ movement
├─ classResources[]
├─ spellCapacity?
├─ spellSlotGroups[]
├─ attackActions[]
├─ spellActions[]
├─ consoleSettings
├─ permissions
└─ revision
```

Client가 Action 순서·비용·가용성·기억 상태를 추론하지 않는다.

## 3. Layout

1920×1080 기준:

```text
Width                 1450 px
Bottom Inset          18–22 px
Action Row Default    2
Action Row Range      1–4
Action Cell           48 × 48 px
Cell Gap              5 px
Top Resource Rail     42 px
Actor Cluster         292 px
Control Cluster       132 px
```

Console 높이는 다음 방식으로 계산한다.

```text
Base Header·Footer·Padding
+ Action Cell Height × Row Count
```

Console은 `AnchorPoint(0.5, 1)`을 사용해 아래를 고정하고 위로 확장한다.

## 4. Action Matrix 채우기

```text
grid-auto-flow = column
rows = userSetting(1–4)
```

예시:

```text
Rows = 2

A1 A3 A5 A7 ...
A2 A4 A6 A8 ...
```

공격·행동 Matrix와 주문 Matrix는 각자 같은 Row 설정을 적용한다. Matrix별 Horizontal Scroll 위치는 독립적으로 유지한다.

## 5. 분류

Attack/Action Matrix:

- Weapon Attack
- Class Action
- Movement·Utility
- Item Shortcut
- Custom Action

Spell Matrix:

- Cantrip
- Prepared·Memorized Spell
- Known Spell Shortcut
- Spellbook Entry

준비되지 않은 주문을 표시할 수 있는 권한이 있다면 Disabled Icon으로 표시하고 이유를 제공한다. 권한 밖 주문은 자리도 만들지 않는다.

## 6. Action Cell 상태

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

필수 시각 요소:

- RVTT Icon
- 종류별 Frame·Background
- Cost Badge
- Key Marker
- Lock·Cooldown Overlay

Text Label은 Matrix 안에 상시 표시하지 않는다.

## 7. ActionHoverPanel

Hover Delay:

```text
Pointer action description   0.12–0.18 s
Keyboard focus               immediate
```

표시 정보:

- 이름
- 행동 경제
- 사거리·Target
- Spell Level·Resource Cost
- 짧은 규칙 설명
- 현재 가능 여부와 이유

Position:

- Cursor 또는 Focus Cell 위 12–18 px
- Cell과 Cursor를 덮지 않음
- Screen Edge Clamp
- 상단 공간 부족 시 아래로 Flip

Panel은 읽기 전용 Projection이며 Action 실행 권한을 만들지 않는다.

## 8. Resource Rail

순서:

```text
Action · Bonus Action · Reaction · Movement
→ Class Resource
→ Spell Capacity
→ Spell Slots
→ Turn Status
```

`SpellCapacityView`:

```text
SpellCapacityView
├─ mode            // memorized | prepared | known
├─ label
├─ used
├─ maximum
└─ visibility
```

`SpellSlotGroupView`:

```text
SpellSlotGroupView
├─ level
├─ remaining
├─ maximum
└─ temporarySlots?
```

기억·준비 수와 주문 슬롯을 합산하거나 같은 Pip으로 표현하지 않는다.

## 9. Settings

```text
consoleActionRows = 2      // 1–4
consoleLocked = true
attackMatrixOrder[]
spellMatrixOrder[]
attackMatrixScroll
spellMatrixScroll
```

Row 변경은 즉시 Preview하고 User Preference에 저장한다. Character마다 Action 정렬을 저장할 수 있지만 기본 UI 높이는 사용자 Preference다.

## 10. Input

- Left Click: Action 선택·실행 흐름
- Hover/Focus: 설명 Panel
- Drag: Console Unlock 상태에서 재정렬
- Q: 열린 Action Context 또는 Hover 고정 설명 해제
- E: 현재 Preview Confirm
- ESC: Gameplay 의미 없음

## 11. Acceptance

- 1–4행에서 Icon이 잘리거나 겹치지 않는다.
- Compact·Reference·Wide에서 두 Matrix가 구분된다.
- Disabled Icon도 Hover·Focus 이유를 제공한다.
- Row 변경 후 Action 순서가 바뀌지 않는다.
- Resource Rail이 오른쪽 열이 아니라 Console 상단에 있다.
- 기억·준비 수와 주문 슬롯이 동시에 정확히 표시된다.
- Actor 전환 시 동일 Revision의 Action·Resource Projection으로 한 번에 바뀐다.
