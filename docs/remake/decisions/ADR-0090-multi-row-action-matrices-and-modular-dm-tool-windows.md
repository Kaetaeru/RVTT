# ADR-0090: Character Console은 다중 행 Action Matrix를 사용하고 DM 도구는 독립 Window Module로 동작한다

- 상태: 확정
- 결정일: 2026-08-06
- 결정 종류: Character Console · Action Presentation · Class Resource · DM Workspace Modularity
- 보강 대상:
  - [`ADR-0089`](ADR-0089-observer-first-session-and-ui-surface-realignment.md)
  - [`ADR-0045`](ADR-0045-dm-workspace-and-scene-lighting-authoring.md)
  - [`ADR-0088`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 상세 Player UI: [`character-console-action-matrix-and-resource-rail.md`](../ui/combat-hud/character-console-action-matrix-and-resource-rail.md)
- 상세 DM UI: [`modular-dm-tool-window-contract.md`](../ui/dm-workspace/modular-dm-tool-window-contract.md)
- 고정밀 예시: [`User Guide HTML`](../user-guides/html/index.html)

## 1. 배경

ADR-0089는 Player 하단을 하나의 Character Console로 통합하고 DM의 기본 읽기 흐름을 `Top Authoring Strip + Left Inspector + Center World`로 정했다. 그러나 고정밀 HTML의 첫 버전은 다음을 충분히 표현하지 못했다.

- Character Console의 Action이 일반 Hotbar처럼 보였다.
- 공격과 주문이 하나의 단순 Grid에 섞였다.
- 사용자 설정 높이에 따른 다중 행 표시가 보이지 않았다.
- 핵심 자원이 Console 오른쪽에 분리돼 행동 아이콘과 읽기 흐름이 끊겼다.
- 직업별 기억·준비 가능 주문 수가 주문 슬롯과 함께 읽히지 않았다.
- DM Workspace가 기본 배치를 고정 구조처럼 표현해 ADR-0045의 Docking·Floating·다중 Window 원칙이 약화됐다.

이 결정은 Baldur's Gate형 전술 Console의 밀도와 빠른 읽기 흐름을 참고하되, RVTT의 자체 디자인·권한·Input Context·서버 권위 계약으로 구현한다.

## 2. Character Console 구조

Character Console은 하단에 고정되며 아래에서 위로 확장한다.

```text
Top Resource Rail
→ 행동 경제 · 이동 · 직업 자원 · 기억/준비 수 · 주문 슬롯 · Turn 상태

Body Left
→ Actor Portrait · HP · 상태 · 집중

Body Center
→ Attack/Action Matrix + Spell Matrix

Body Right
→ Sheet · Inventory · Turn Control
```

핵심 자원은 Console 오른쪽 별도 열에 두지 않는다. Action Matrix와 같은 시선 흐름에서 읽히도록 Console 상단 전체 폭의 Resource Rail에 둔다.

## 3. 공격·주문 Action Matrix

Action은 작은 정사각형 Icon Cell로 표시한다.

```text
Attack/Action Matrix
→ 무기 공격 · 직업 행동 · 이동 · Utility · Item Shortcut

Spell Matrix
→ Cantrip · 기억/준비 주문 · Spellbook Shortcut
```

두 Matrix는 별도 영역과 별도 순서를 가진다. 하나의 혼합 Grid로 합치지 않는다.

사용자는 `Action Matrix Rows`를 `1–4`로 설정한다.

```text
1행
→ 가장 낮은 Console

2행
→ 기본값

3행
→ 확장

4행
→ 최대 높이
```

Icon은 현재 행 수를 위에서 아래로 채운 뒤 오른쪽으로 계속 배열한다. 행 수 변경은 두 Matrix에 동시에 적용되며 Console은 하단 Anchor를 유지하고 위쪽으로만 확장한다.

최근 사용만으로 Action 위치를 자동 재배치하지 않는다. 사용자가 고정·정렬·분류를 명시적으로 변경한 경우에만 순서를 바꾼다.

## 4. Action Icon 정보와 Hover Panel

Matrix 안에는 긴 Text Label을 상시 표시하지 않는다.

각 Icon은 다음 정보를 표현한다.

- 자체 RVTT Icon
- Action 종류별 Frame·Surface
- Key Binding 또는 Slot Marker
- Action·Bonus Action·Reaction·Spell Level 등의 작은 Cost Badge
- Cooldown·Concentration·Prepared·Disabled 상태
- Disabled Lock Marker

Mouse Hover 또는 Keyboard Focus 시 Cursor 바로 위에 `ActionHoverPanel`을 표시한다.

```text
Action Name
Action Economy · Range · Target · Spell Level
짧은 규칙 설명
현재 실행 가능 여부
불가능하면 구체적인 이유
```

Panel은 Hover 대상과 Cursor를 가리지 않고 Screen Edge에서 반전·Clamp한다. 일반 Tooltip보다 상세하지만 Modal·Side Sheet를 열지 않는다.

Disabled Icon도 Hover·Keyboard Focus를 받아 불가능 이유를 보여야 한다. 실행은 차단한다.

## 5. 상단 Resource Rail

Resource Rail은 사용자가 현재 행동 가능성을 Icon Grid를 보기 전에 읽을 수 있게 한다.

기본 순서:

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

직업·Feature에 따라 존재하지 않는 Resource는 빈 자리나 Disabled Placeholder를 만들지 않는다.

### 기억·준비 수와 주문 슬롯

기억·준비 가능 주문 수와 실제 주문 슬롯은 별도 Resource다.

```text
기억/준비
→ 8 / 10

1레벨 주문 슬롯
→ ● ● ● ○

2레벨 주문 슬롯
→ ● ○
```

Label은 Character의 실제 규칙 모델에 맞게 `기억`, `준비`, `알고 있는 주문` 등으로 바꿀 수 있다. 단, 주문 슬롯과 같은 값으로 합치지 않는다.

## 6. DM Window Module 원칙

ADR-0089의 `Top Authoring Strip + Left Inspector`는 **기본 Workspace Layout**이며 고정 단일 Panel 구조가 아니다.

ADR-0045의 다음 원칙을 유지한다.

- 여러 Tool Window를 동시에 열 수 있다.
- 각 Window는 이동·크기 변경·최소화·닫기·Dock·Undock·Tab Group을 독립적으로 수행한다.
- Window Layout은 사용자별 Preference로 저장한다.
- Left Inspector는 기본 Dock 위치일 뿐 다른 위치로 이동하거나 추가 Inspector Instance를 열 수 있다.
- Top Authoring Strip은 Tool Window Launcher이며 Tool의 전체 UI를 Strip 안에 고정하지 않는다.

## 7. DmToolModule 계약

모든 DM Tool은 독립 Module Instance로 등록한다.

```text
DmToolModule
├─ moduleId
├─ instanceId
├─ toolKind
├─ title
├─ iconId
├─ projectionScope
├─ permissionQuery
├─ commandBindings
├─ windowConstraints
├─ localViewState
├─ serializeLayout()
├─ restoreLayout()
└─ dispose()
```

공통 `DmWindowHost`가 다음만 담당한다.

- Z-order·Focus
- Move·Resize
- Dock·Undock·Tab Group
- Window Layout 저장·복구
- Input Context Stack 연결
- Role·Scene·Permission 변경 시 Stale 처리

Tool Module이 다른 Tool의 내부 상태를 직접 수정하지 않는다. 공유 Domain 상태는 Projection과 Command를 통해서만 전달한다.

## 8. Window Instance 정책

도구별 Instance 정책을 명시한다.

```text
Singleton 권장
→ Players · Rollback · Session Settings

Multiple Instance 허용
→ Inspector · Journal Document · Scene Preview · Actor Sheet · Asset Detail

Context Popover
→ Quick Action · Inline Value Stepper
```

Quick Action은 계속 작은 Popover다. 사용자가 `상세 열기`를 선택한 경우에만 관련 Window Module을 연다.

## 9. 권위와 상태 경계

Window의 위치·크기·Dock 상태는 Local Preference다.

Window 안에서 실행하는 실제 편집·전투·권한 변경은 기존 서버 권위 Command를 사용한다.

```text
Local Window Interaction
→ Layout Preference

Authoritative Tool Action
→ Capability 확인
→ 최신 Revision 재검증
→ Command Journal
→ Commit
→ 모든 관련 Window Projection 갱신
```

Role·Owner·Scene이 변경되면 권한을 잃은 Window는 내용을 숨긴 채 남아 있지 않고 Close 또는 Permission-safe Empty State로 전환한다.

## 10. Acceptance

### Character Console

- 공격·행동과 주문이 별도 Matrix다.
- Action Matrix Rows 1·2·3·4가 모두 동작한다.
- Console은 아래에 Anchor되고 위로 확장한다.
- 작은 Icon Cell이 행을 채운 뒤 오른쪽으로 이어진다.
- Hover·Keyboard Focus Panel이 Cursor 위에 표시된다.
- Disabled Action의 이유를 Hover·Focus로 확인할 수 있다.
- 핵심 자원이 Console 상단 전체 폭에 있다.
- 직업별 기억·준비 수와 주문 슬롯이 분리돼 표시된다.

### DM Workspace

- 최소 3개 Tool Window를 동시에 열 수 있다.
- 각 Window가 독립적으로 Move·Resize·Dock·Close된다.
- Left Inspector는 기본 Dock이지만 고정 불변 Panel이 아니다.
- 동일 종류의 허용된 Window를 여러 Instance로 열 수 있다.
- Window 하나를 닫거나 Stale 처리해도 다른 Window 상태가 손상되지 않는다.
- Quick Action은 큰 Window로 변하지 않는다.
- Window Layout과 권위 Domain State가 분리된다.

## 11. 결과

- Character Console이 단순 Hotbar가 아니라 공격·주문을 빠르게 훑는 전술 Action Deck이 된다.
- Console 높이를 사용자가 조절하면서도 같은 Action 순서와 Resource 문법을 유지한다.
- 기억·준비 수와 주문 슬롯을 한눈에 구분한다.
- DM은 편집 프로그램처럼 여러 도구를 동시에 구성하면서도 각 Tool을 독립 Module로 유지한다.
- ADR-0089의 기본 화면 배치와 ADR-0045의 Workspace Modularity가 충돌하지 않는다.
