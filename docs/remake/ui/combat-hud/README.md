# Combat HUD UI

Baldur's Gate형 Initiative, Party Rail, Character Console, Action Matrix, 대상·범위 Preview, Reaction과 Turn UI를 다룬다.

## 최상위 결정

- [`ADR-0090`](../../decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
  - 공격·행동과 주문을 별도 Matrix로 표시
  - 사용자 설정 1–4행
  - Hover·Focus Action Description Panel
  - Console 상단 Resource Rail
  - 직업별 기억·준비 수와 주문 슬롯 분리
- [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
  - Owned Actor 기본 선택
  - 하단 통합 Character Console
  - Objective·Map·Minimap 제거
- [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
  - Left 기본 행동, Right Context, Middle Orbit, Q Cancel, ESC No-op

## 구현 직전 명세

- [`Character Console Action Matrix와 Resource Rail`](character-console-action-matrix-and-resource-rail.md)
- [`Full UI·UX and Settings Specification`](../shared/implementation-ready-ui-ux-and-settings-spec.md)

## 관련 Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)

## 권위 문서

- [`baldurs-gate-style-combat-hud.md`](baldurs-gate-style-combat-hud.md)
- [`전투 HUD·Character Sheet 공통 Wireframe`](../shared/combat-hud-character-sheet-wireframe-and-shared-ui.md)

## 고정 경계

- Combat HUD는 Exploration 셸을 교체하는 별도 Client가 아니라 동일 Shared Shell의 Encounter Composition이다.
- Action Matrix Row 설정은 1–4이며 공격·주문 Matrix에 동시에 적용한다.
- Action Icon 위치는 사용자가 명시적으로 바꿀 때만 변경한다.
- Disabled Action은 Icon을 유지하고 Hover·Focus 이유를 제공한다.
- 기억·준비 수와 Spell Slot은 다른 Projection Field다.
- Turn 전환은 Camera를 강제로 이동하지 않는다.
- 권한에 없는 Action은 Slot·Count·Disabled 자리도 만들지 않는다.
