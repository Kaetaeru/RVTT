# Character Sheet UI

공식 2024 캐릭터 시트의 정보 구조를 RVTT 실시간 상태와 연결한다.

## 관련 Main System Guide

- [`Character, Inventory와 Downtime Guide`](../../guides/character/README.md)
  - Character Progression Source·Compiled Build·Persistent State와 Derived Character View
  - Inventory·Equipment·Spell Preparation·Resource·Rest·Level Up Projection 경계
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)
  - 시트의 Capability·Spell·Roll Intent가 RuleExecution으로 이어지는 경계
- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
  - HP·DeathSave·Opportunity·Encounter 상태를 전투 HUD와 일관되게 표시하는 경계

## 권위 문서

- [`official-2024-character-sheet-and-live-player-ui.md`](official-2024-character-sheet-and-live-player-ui.md)
  - 공식 2024 시트의 정보 계층과 RVTT 실시간 CharacterSheetProjection
  - Owner·DM·Observer 역할별 정보와 변경 Intent

공통 화면 규격은 [`../shared/`](../shared/)를 참고한다.

캐릭터 시트는 Source·Build·State의 권위 원본이 아니며 서버가 만든 Permission-aware Projection만 표시한다.
