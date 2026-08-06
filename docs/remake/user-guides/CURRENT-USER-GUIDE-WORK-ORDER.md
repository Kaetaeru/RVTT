# Player·Observer·DM User Guide 현재 작업 순서

- 상태: `COMPLETE · HIGH_FIDELITY_HTML_GUIDE`
- 최종 갱신일: 2026-08-06
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 상위 결정: [`ADR-0089`](../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 고정밀 HTML: [`html/index.html`](html/index.html)
- 고정밀 감사: [`High-Fidelity HTML UI Production Guide Audit`](../audits/high-fidelity-html-production-guide-audit.md)
- 권위 충돌 감사: [`UI HTML Authority Conflict Audit`](../audits/ui-html-authority-conflict-and-realignment-audit.md)

## 완료 범위

| 순서 | 상태 | 작업 |
|---:|---|---|
| 1 | DONE | Observer-first Session Entry Guide |
| 2 | DONE | DM Character Assignment·Ownership Guide |
| 3 | DONE | Character Console·Default Actor Guide |
| 4 | DONE | Compact Context·Dice Notice·Death Save Guide |
| 5 | DONE | Official Sheet·VTT Management Guide |
| 6 | DONE | DM Live·Quick Action·Scene Editor Guide |
| 7 | DONE | 26개 Runtime 화면 고정밀 재작성 |
| 8 | DONE | Design Token·Component State Canvas 2개 추가 |
| 9 | DONE | 화면별 Layout·Input·Acceptance metadata 추가 |
| 10 | DONE | HTML parse·JavaScript syntax·28 Renderer smoke test |
| 11 | QUEUED | Browser Screenshot 비교 |
| 12 | QUEUED | Roblox Studio Screenshot·Runtime 비교 |

## 현재 User Guide 권위 순서

```text
ADR-0089·ADR-0088
→ 구현 직전 UI·UX 명세
→ Quick Flow
→ Player·DM Guide
→ High-Fidelity HTML Production Target
```

HTML은 구현 길잡이지만 Authority 원본은 아니다. 충돌 시 ADR과 UI 명세를 따른다.

## 고정밀 HTML 범위

```text
Runtime Screens       26
Production Canvases    2
Total                  28
```

고정밀 HTML은 다음을 포함한다.

- 1920×1080 기준 Layout Metric
- Compact·Wide Responsive Reference
- UI Scale·Text Scale
- Accent 6종
- Full·Reduced Motion
- Design Token과 자체 SVG Icon
- Idle·Hover·Focus·Selected·Disabled·Pending·Denied·Critical 상태
- Disabled Hover·Focus 사유 Tooltip
- 화면별 Input Contract와 Runtime Acceptance

## Runtime 후속 Gate

- Roblox Theme Token·Component Library 정합화
- Observer→Owner·Player Multi-client 전환
- Character Console Layout
- Official Sheet 한국어 가독성
- Dice Notice Timing
- Death Save 접근성
- DM Scene Editor Bottom Catalog 성능
- HTML과 Roblox Screenshot 비교
