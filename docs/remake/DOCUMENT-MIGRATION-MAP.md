# RVTT 문서 이동 매핑

- 상태: 실행 대기
- 문서 종류: Audit / Migration Plan
- 즉시 구현 명세 가능성: 해당 없음

이 문서는 기존 평면 구조를 역할·영역별 폴더 구조로 이동하기 위한 단일 권위 매핑이다. 실제 파일 이동이 완료되고 링크 검사가 끝날 때까지 기존 경로를 삭제하지 않는다.

## 목표 구조

```text
docs/remake/
├─ product/
├─ architecture/
├─ systems/
├─ ui/
├─ decisions/
├─ audits/
├─ specs/
├─ templates/
└─ archive/
```

## 이동 원칙

- `decisions/`의 ADR 파일은 현재 경로와 번호를 유지한다.
- `AGENTS.md`, `AGENTS-PLANNING-ADDENDUM.md`, `DOCUMENT-GUIDE.md`, `DOCUMENT-MIGRATION-MAP.md`는 `docs/remake/` 루트에 유지한다.
- 이동은 내용 변경 없이 먼저 수행한다.
- 경로 이동 커밋과 내용 정합성 수정 커밋을 분리한다.
- 대상 파일과 링크가 검증되기 전 원본을 삭제하지 않는다.

## Product

| 기존 경로 | 대상 경로 |
|---|---|
| `02-core-session-loop.md` | `product/core-session-loop.md` |
| `16-campaign-material-component-policy.md` | `product/campaign-material-component-policy.md` |
| `43-platform-movement-and-input-scope.md` | `product/platform-movement-and-input-scope.md` |
| `47-content-automation-rollback-chunk-storage-and-exclusions.md` | `product/content-automation-rollback-storage-and-exclusions.md` |

## Architecture

| 기존 경로 | 대상 경로 |
|---|---|
| `09-scene-editor-tool-module-architecture.md` | `architecture/scene-editor-tool-module-architecture.md` |
| `10-rules-content-grant-capability-model.md` | `architecture/rules-content-grant-capability-model.md` |
| `11-rules-content-execution-and-spell-contract.md` | `architecture/rules-content-execution-and-spell-contract.md` |
| `21-passive-modifier-and-rule-override-model.md` | `architecture/passive-modifier-and-rule-override-model.md` |
| `22-effect-recipe-resolution-and-commit-model.md` | `architecture/effect-recipe-resolution-and-commit-model.md` |
| `36-save-autosave-reconnect-shutdown-and-session-recovery-model.md` | `architecture/persistence-and-session-recovery-model.md` |
| `40-modular-vfx-and-presentation-recipe-model.md` | `architecture/modular-vfx-and-presentation-recipe-model.md` |

## Systems — Scene and Navigation

| 기존 경로 | 대상 경로 |
|---|---|
| `04-scenes-and-world.md` | `systems/scene/scenes-and-world.md` |
| `05-navigation-authoring-pipeline.md` | `systems/navigation/navigation-authoring-pipeline.md` |
| `06-ingame-scene-editor-tools.md` | `systems/scene/ingame-scene-editor-tools.md` |

## Systems — Character and Rules

| 기존 경로 | 대상 경로 |
|---|---|
| `12-spell-acquisition-preparation-and-cast-access-model.md` | `systems/character/spell-acquisition-preparation-and-cast-access-model.md` |
| `13-spellbook-repository-and-copying-model.md` | `systems/character/spellbook-repository-and-copying-model.md` |
| `14-spell-resource-pools-and-cast-payment-model.md` | `systems/rules/spell-resource-pools-and-cast-payment-model.md` |
| `15-spell-components-and-material-inventory-contract.md` | `systems/rules/spell-components-and-material-inventory-contract.md` |
| `17-spell-targeting-area-and-spatial-query-model.md` | `systems/rules/spell-targeting-area-and-spatial-query-model.md` |
| `18-rule-recipe-examples-magic-missile-and-witch-bolt.md` | `systems/rules/rule-recipe-examples-magic-missile-and-witch-bolt.md` |
| `19-feat-feature-trigger-and-cross-turn-execution-model.md` | `systems/rules/feat-feature-trigger-and-cross-turn-execution-model.md` |
| `20-active-feature-and-action-container-execution-model.md` | `systems/rules/active-feature-and-action-container-execution-model.md` |
| `23-condition-ongoing-effect-duration-and-concentration-model.md` | `systems/rules/condition-ongoing-effect-duration-and-concentration-model.md` |
| `25-zero-hit-points-death-saves-rest-and-resource-recovery-model.md` | `systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md` |
| `26-monster-npc-statblock-and-ingame-json-import-model.md` | `systems/character/monster-npc-statblock-and-ingame-json-import-model.md` |

## Systems — Inventory

| 기존 경로 | 대상 경로 |
|---|---|
| `24-item-weapon-attack-profile-and-mastery-model.md` | `systems/inventory/item-weapon-attack-profile-and-mastery-model.md` |
| `46-inventory-loot-and-item-transfer-model.md` | `systems/inventory/inventory-loot-and-item-transfer-model.md` |

## Systems — Combat

| 기존 경로 | 대상 경로 |
|---|---|
| `27-dice-roll-presentation-and-resolution-gating-model.md` | `systems/combat/dice-roll-presentation-and-resolution-gating-model.md` |
| `28-encounter-initiative-turn-and-control-authority-model.md` | `systems/combat/encounter-initiative-turn-and-control-authority-model.md` |
| `37-encounter-turn-snapshot-timeline-and-dm-rollback-model.md` | `systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md` |

## Systems — Perception

| 기존 경로 | 대상 경로 |
|---|---|
| `29-manual-fog-of-war-and-optional-assist-model.md` | `systems/perception/manual-fog-of-war-and-optional-assist-model.md` |
| `30-visibility-senses-stealth-and-detection-model.md` | `systems/perception/visibility-senses-stealth-and-detection-model.md` |

## Systems — Interaction

| 기존 경로 | 대상 경로 |
|---|---|
| `31-zero-metadata-interaction-prefab-and-state-transition-model.md` | `systems/interaction/zero-metadata-interaction-prefab-and-state-transition-model.md` |
| `32-zero-metadata-trap-secret-door-and-destructible-object-model.md` | `systems/interaction/trap-secret-door-and-destructible-object-model.md` |

## Systems — Session, Camera, Journal

| 기존 경로 | 대상 경로 |
|---|---|
| `38-linked-journal-and-two-mode-ping-model.md` | `systems/journal/linked-journal-and-two-mode-ping-model.md` |
| `44-campaign-lobby-hot-join-ownership-and-control.md` | `systems/session/campaign-lobby-hot-join-ownership-and-control.md` |
| `45-free-tactical-camera-model.md` | `systems/camera/free-tactical-camera-model.md` |

## UI

| 기존 경로 | 대상 경로 |
|---|---|
| `07-scene-editor-interaction-and-layout.md` | `ui/scene-editor/scene-editor-interaction-and-layout.md` |
| `08-common-input-grammar.md` | `ui/common-input/common-input-grammar.md` |
| `33-baldurs-gate-style-combat-hud-and-contextual-action-ui-model.md` | `ui/combat-hud/baldurs-gate-style-combat-hud.md` |
| `34-official-2024-character-sheet-and-live-player-ui-model.md` | `ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md` |
| `35-combat-hud-character-sheet-wireframe-and-shared-ui-spec.md` | `ui/shared/combat-hud-character-sheet-wireframe-and-shared-ui.md` |
| `39-dm-workspace-and-scene-lighting-model.md` | `ui/dm-workspace/dm-workspace-and-scene-lighting.md` |
| `41-dm-quick-action-and-context-command-model.md` | `ui/dm-workspace/dm-quick-action-and-context-command.md` |

## Audits

| 기존 경로 | 대상 경로 |
|---|---|
| `42-pre-implementation-planning-readiness-audit.md` | `audits/pre-implementation-planning-readiness-audit.md` |
| `48-planning-audit-resolution-status.md` | `audits/planning-audit-resolution-status.md` |

## 루트 문서 처리

| 기존 경로 | 처리 |
|---|---|
| `README.md` | 새 구조의 문서 허브로 전면 갱신 |
| `AGENTS.md` | 유지 |
| `AGENTS-PLANNING-ADDENDUM.md` | 유지하되 `AGENTS.md`로 통합 검토 |

## 누락 확인 체크리스트

- [ ] 기존 `02`~`48` 문서가 모두 매핑되었는가
- [ ] ADR 파일 수가 이동 전후 동일한가
- [ ] 새 대상 파일의 내용 해시가 원본과 동일한가
- [ ] Markdown 상대 링크가 모두 존재하는가
- [ ] README의 읽기 순서가 새 경로를 사용하는가
- [ ] ADR의 관련 문서 링크가 새 경로를 사용하는가
- [ ] 원본 경로를 참조하는 문자열이 남아 있지 않은가
- [ ] 중복 파일이 제거되었는가
- [ ] `git diff --summary`에서 이동이 rename으로 인식되는가
- [ ] 문서별 준비도 필드가 유지되었는가

## 마이그레이션 단계

1. 폴더 README와 템플릿 생성
2. Product·Audit 문서 이동
3. Architecture 문서 이동
4. Systems 문서 영역별 이동
5. UI 문서 이동
6. 전체 상대 링크 갱신
7. 루트 README 갱신
8. 원본 삭제
9. 링크·누락·중복 검사
10. 마이그레이션 상태를 `완료`로 변경
