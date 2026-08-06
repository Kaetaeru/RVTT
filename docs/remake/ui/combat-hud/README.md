# Combat HUD UI

Baldur's Gate형 이니셔티브, PartyRail, Hotbar, 대상·범위 Preview, Reaction과 Turn UI를 다룬다.

## 최상위 직접 플레이 결정

- [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
  - Left Click: 선택 또는 표시된 기본 행동
  - Right Click: Capability Context Action Table
  - Middle Click Drag: Camera Orbit
  - Q: 최상위 Context 한 단계 취소
  - ESC: Gameplay 의미 없음

## 구현 직전 화면 명세

- [`Full UI·UX and Settings Specification`](../shared/implementation-ready-ui-ux-and-settings-spec.md)
  - Exploration 셸에서 Encounter HUD로 전환되는 구성
  - Hotbar 기본 2행·사용자 1–4
  - EndTurn Disabled Reason, Soft Turn Focus, HP 0·Death Save
  - Tooltip·Settings·Role·Recovery·Acceptance 기본값

## 관련 Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)

## 권위 문서

- [`baldurs-gate-style-combat-hud.md`](baldurs-gate-style-combat-hud.md)
- [`전투 HUD·Character Sheet 공통 Wireframe`](../shared/combat-hud-character-sheet-wireframe-and-shared-ui.md)

## 고정 경계

- Combat HUD는 Exploration 셸을 교체하는 별도 Client가 아니라 동일 Shared Shell의 Encounter Composition이다.
- Turn 전환은 Camera를 강제로 이동하지 않는다.
- 조작 가능한 Initiative·Party Entry Left Click은 Actor 선택 전환을 우선한다.
- 권한에 없는 Action은 Slot·Count·Disabled 자리도 만들지 않는다.
- 현재 불가능 Action은 비활성색과 Hover·Focus Reason을 가진다.
- UI Ribbon·Hotbar·EndTurn은 Authority 원본이 아니라 같은 Projection Revision의 View다.
