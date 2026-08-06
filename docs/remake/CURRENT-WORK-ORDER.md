# RVTT Remake 현재 작업 순서

- 상태: `PLANNING COMPLETE · MERGE GATE`
- 최종 갱신일: 2026-08-06
- 최종 UI 결정: [`ADR-0091`](decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)
- 고정밀 HTML: [`user-guides/html/index.html`](user-guides/html/index.html)
- Final UI Audit: [`audits/final-ui-surface-gap-audit.md`](audits/final-ui-surface-gap-audit.md)

## 현재 단계

```text
ADR-0088 Direct Play
→ ACCEPTED

ADR-0089 Observer-first Surface
→ ACCEPTED

ADR-0090 Console Matrix·DM Windows
→ ACCEPTED

ADR-0091 Asset·Official Sheet·Dice·Core Rules
→ ACCEPTED

Final High-Fidelity HTML
→ COMPLETE · 33 SCREENS

Production Runtime
→ IMPLEMENTATION REQUIRED AFTER MERGE
```

## 확정된 Production 순서

1. Content Package Registry·Asset Compile
2. Theme Token·Shared Component Library
3. Session Invite→Observer→Assignment Projection
4. Character Console Matrix·Resource Rail
5. Interactive Official 2024 Sheet·VTT Inventory synchronization
6. Dice Slot Reveal Notice
7. Core Rules Package·Chunk Reader·Search
8. DM Window Host·Asset Registry·Scene Editor
9. Static·Rojo·Luau·Security
10. Browser·Studio Screenshot comparison
11. Multi-client Authority·Permission Evidence
12. Accessibility·Performance·Persistence

## Merge 후 첫 Runtime Gate

- `rvtt.core.baseline` Token/Prop sample package compile
- `rvtt.core.rules` Module manifest load
- Official Sheet Roll/Equip command smoke
- Dice Notice state machine smoke
- 200,000자 synthetic Rule Package virtualization

문서·HTML PASS는 Runtime PASS가 아니다.
