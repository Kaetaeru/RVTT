# Player·Observer·DM User Guide 현재 작업 순서

- 상태: `COMPLETE · ADR-0090 HIGH_FIDELITY_HTML`
- 최종 갱신일: 2026-08-06
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Action Matrix·DM Window 결정: [`ADR-0090`](../decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- 고정밀 HTML: [`html/index.html`](html/index.html)
- 고정밀 감사: [`High-Fidelity HTML UI Production Guide Audit`](../audits/high-fidelity-html-production-guide-audit.md)

## 완료 범위

| 순서 | 상태 | 작업 |
|---:|---|---|
| 1 | DONE | Observer-first·Ownership·Default Actor Guide |
| 2 | DONE | Compact Context·Dice Notice·Death Save Guide |
| 3 | DONE | Official Sheet·VTT Management Guide |
| 4 | DONE | 공격·행동/주문 Action Matrix 1–4행 |
| 5 | DONE | Cursor 위 Action Hover Panel |
| 6 | DONE | Console 상단 Resource Rail·기억 수·Spell Slot |
| 7 | DONE | DM Multi-window Workspace·Module 표현 |
| 8 | DONE | Scene Editor Catalog + Material·Lighting Windows |
| 9 | DONE | HTML parse·JS syntax·28 Renderer smoke test |
| 10 | QUEUED | Browser Screenshot 비교 |
| 11 | QUEUED | Roblox Studio Interaction·Runtime 비교 |

## 현재 User Guide 권위 순서

```text
ADR-0090·ADR-0089·ADR-0088
→ 상세 UI 계약
→ Quick Flow
→ Player·DM Guide
→ High-Fidelity HTML
```

HTML은 구현 길잡이지만 Authority 원본은 아니다.

## Runtime 후속 Gate

- Action Matrix 1–4행 Layout
- Hover·Keyboard Focus 설명 Panel
- 기억·준비 수와 Spell Slot Projection
- DM Window Move·Resize·Dock·Layout 저장
- Window Permission·Stale 처리
- HTML과 Roblox Screenshot 비교
