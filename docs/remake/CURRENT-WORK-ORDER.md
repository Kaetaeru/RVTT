# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · ADR_0090_UI_SOURCE_ALIGNMENT`
- 최종 갱신일: 2026-08-06
- Action Matrix·DM Window 결정: [`ADR-0090`](decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- UI 재정렬 결정: [`ADR-0089`](decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 직접 플레이 결정: [`ADR-0088`](decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- Character Console 상세: [`character-console-action-matrix-and-resource-rail.md`](ui/combat-hud/character-console-action-matrix-and-resource-rail.md)
- DM Window 상세: [`modular-dm-tool-window-contract.md`](ui/dm-workspace/modular-dm-tool-window-contract.md)
- 고정밀 HTML 감사: [`high-fidelity-html-production-guide-audit.md`](audits/high-fidelity-html-production-guide-audit.md)
- 고정밀 HTML: [`user-guides/html/index.html`](user-guides/html/index.html)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)

## 1. 현재 단계

```text
Product·Architecture·Domain Baseline
→ IMPLEMENTED BASELINE

Direct Play Pointer UX
→ ACCEPTED · ADR-0088

Observer-first Session·UI Surface
→ ACCEPTED · ADR-0089

Action Matrix·Modular DM Windows
→ ACCEPTED · ADR-0090

High-Fidelity User Guide HTML
→ ADR-0090 ALIGNED · 28 SCREENS

Production UI Source·Acceptance
→ ADR-0090 ALIGNMENT REQUIRED
```

## 2. 현재 제작 기준

```text
Player Console
→ Bottom Anchor
→ Top Resource Rail
→ Attack/Action Matrix + Spell Matrix
→ User Rows 1–4
→ Cursor-above ActionHoverPanel
→ Memory/Prepared Capacity ≠ Spell Slots

DM Workspace
→ Top Module Launcher
→ Left Inspector Default Dock
→ Multiple Independent Tool Windows
→ Move·Resize·Dock·Tab·Close
→ Local Layout Preference ≠ Domain State
```

## 3. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | ADR-0090 결정·상세 UI 계약 | Console·Window Module 권위 확정 |
| 2 | DONE | 고정밀 HTML 정합화 | 1–4행·Hover·Resource Rail·Multi-window |
| 3 | IN_PROGRESS | Roblox Theme·Action Cell·Hover Component | HTML Token과 1:1 의미 대응 |
| 4 | QUEUED | CharacterConsoleProjection 정합화 | Attack·Spell·Resource·Memory View |
| 5 | QUEUED | DmToolRegistry·DmWindowHost | 독립 Window Lifecycle·Layout |
| 6 | QUEUED | Session·Projection Source | Observer→Owner·Player·Default Actor |
| 7 | QUEUED | Dice·Death·Sheet·Inventory | 동일 Projection Revision |
| 8 | QUEUED | Scene Editor Module Integration | Catalog·Material·Lighting 동시 실행 |
| 9 | QUEUED | Static·Rojo·Luau Revalidation | 전체 Gate PASS |
| 10 | QUEUED | Browser·Studio Screenshot 비교 | 1·2·3·4행과 Multi-window Evidence |
| 11 | QUEUED | Multi-client Permission Test | Window Stale·정보 제거 Evidence |
| 12 | QUEUED | Accessibility·Performance | Hover Focus·Scale·Window Soak |
| 13 | QUEUED | Grand Persistence Runtime | Published phases |

## 4. Source 정합화 범위

### Player UI

- ActionMatrix Component
- ActionHoverPanel
- ResourceRail
- SpellCapacityView
- Attack·Spell Order Preference
- Console Rows Preference

### DM UI

- DmToolRegistry
- DmToolModuleInstance
- DmWindowHost
- DockTree·TabGroup
- Workspace Layout Preference
- Permission·Stale Lifecycle

## 5. 운영 규칙

1. Character Console·DM Workspace 세부가 충돌하면 ADR-0090을 따른다.
2. Top Strip·Left Inspector는 Default Layout이며 Window 이동을 금지하지 않는다.
3. Action Row 변경으로 Action 의미·순서가 자동 변경되지 않는다.
4. Window Layout은 Local Preference이고 Tool Action은 서버 권위 Command다.
5. 문서·HTML 완료를 Runtime PASS로 해석하지 않는다.
6. 외부 제품의 고유 UI Asset은 복제하지 않는다.
