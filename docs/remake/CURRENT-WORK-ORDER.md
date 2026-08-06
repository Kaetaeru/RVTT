# RVTT Remake 현재 작업 순서

- 상태: `PLANNING COMPLETE · MERGE GATE`
- 최종 갱신일: 2026-08-06
- 최종 UI·Content 결정: [`ADR-0091`](decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)
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

ADR-0091 Asset·Official Sheet·Dice·Rule Profiles
→ ACCEPTED

Development/Test Rule Default
→ rvtt.test.rules.2024.integrated.ko
→ PRIVATE OWNER-ONLY · PINNED SOURCE

Public/Release Rule Default
→ rvtt.core.rules
→ SRD 5.2.1 ONLY

Final High-Fidelity HTML
→ COMPLETE · 33 SCREENS

Production Runtime
→ IMPLEMENTATION REQUIRED AFTER MERGE
```

## 확정된 Production 순서

1. Content Package Registry·Asset Compile
2. Private Integrated Rule Importer·Profile Resolver
3. Public SRD Release Leak Gate
4. Theme Token·Shared Component Library
5. Session Invite→Observer→Assignment Projection
6. Character Console Matrix·Resource Rail
7. Interactive Official 2024 Sheet·VTT Inventory synchronization
8. Dice Slot Reveal Notice
9. Core Rules Package·Chunk Reader·Search
10. DM Window Host·Asset Registry·Scene Editor
11. Static·Rojo·Luau·Security
12. Browser·Studio Screenshot comparison
13. Multi-client Authority·Permission Evidence
14. Accessibility·Performance·Persistence

## Merge 후 첫 Runtime Gate

- `rvtt.core.baseline` Token/Prop sample package compile
- `Kaetaeru/D-D-2024-@d3d5747`의 `10-RULEBOOKS/integrated-2024` Private Import
- `rvtt.test.rules.2024.integrated.ko` 12/48/16/10/75/391 Count 검증
- Private Source Missing·Revision Mismatch Fail-closed 검증
- `rvtt.core.rules` SRD Module manifest load
- Public·Release Artifact Private Rule Content Leak Scan
- Official Sheet Roll/Equip command smoke
- Dice Notice state machine smoke
- 200,000자 synthetic Rule Package virtualization

문서·HTML PASS는 Runtime PASS가 아니다. Private 통합판 본문은 공개 RVTT Git Tree와 Release Artifact에 포함하지 않는다.
