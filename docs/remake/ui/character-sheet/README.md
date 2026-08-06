# Character Sheet·Inventory·Rest UI

공식 2024 캐릭터 시트의 정보 구조를 RVTT 실시간 상태와 연결하고, Inventory·Equipment·Loot·Rest·HP 0 흐름을 같은 Character Projection 경계에서 구성한다.

## 구현 직전 화면 명세

- [`Full UI·UX and Settings Specification`](../shared/implementation-ready-ui-ux-and-settings-spec.md)
  - Character Sheet 표시 Mode와 전투 Side Sheet
  - Inventory·Equipment·Loot·Transfer·Identification
  - Short·Long Rest, Downtime, HP 0·Death Save
  - Settings·Preference 저장 범위와 Acceptance

## 관련 Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - CharacterSheetProjection→ViewModel→Panel·Input Context→UI Intent
  - Local Layout·접근성·Command Reconciliation과 Reconnect·Rollback 복구
- [`Character, Inventory와 Downtime Guide`](../../guides/character/README.md)
  - Character Progression Source·Compiled Build·Persistent State
  - Inventory·Equipment·Spell Preparation·Resource·Rest·Level Up Projection
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)
- [`Combat와 Encounter Guide`](../../guides/combat/README.md)

## 권위 문서

- [`official-2024-character-sheet-and-live-player-ui.md`](official-2024-character-sheet-and-live-player-ui.md)
- [`ADR-0051 Inventory·Loot·Transfer·Identification`](../../decisions/ADR-0051-inventory-loot-transfer-and-identification.md)
- [`Shared Wireframe`](../shared/combat-hud-character-sheet-wireframe-and-shared-ui.md)

## 고정 경계

- Character Sheet·Inventory는 Source·Build·State의 권위 원본이 아니다.
- Item Definition·ItemInstance·Location·Owner를 구분한다.
- 미식별 Item의 실제 이름·희귀도·효과를 UI로 누출하지 않는다.
- Pickup은 자동 Equip을 실행하지 않는다.
- Transfer·Use·Equip은 Pending 후 Authority Projection에서 확정한다.
- Drag는 빠른 경로이며 Click 기반 대체 경로가 반드시 존재한다.
- HP 0은 전체 HUD를 제거하는 Game Over Modal이 아니라 허용된 Action만 남기는 Actor 상태다.
- Q는 Detail·Panel을 한 단계씩 닫으며 ESC에는 Gameplay 의미가 없다.
