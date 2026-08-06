# Player·Observer·DM User Guide 현재 작업 순서

- 상태: `COMPLETE · ADR-0089 REALIGNED`
- 최종 갱신일: 2026-08-06
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 상위 결정: [`ADR-0089`](../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- HTML 감사: [`UI HTML Authority Conflict Audit`](../audits/ui-html-authority-conflict-and-realignment-audit.md)

## 완료 범위

| 순서 | 상태 | 작업 |
|---:|---|---|
| 1 | DONE | Observer-first Session Entry Guide |
| 2 | DONE | DM Character Assignment·Ownership Guide |
| 3 | DONE | Character Console·Default Actor Guide |
| 4 | DONE | Compact Context·Dice Notice·Death Save Guide |
| 5 | DONE | Official Sheet·VTT Management Guide |
| 6 | DONE | DM Live·Quick Action·Scene Editor Guide |
| 7 | DONE | 26-screen HTML 재작성 |
| 8 | DONE | Authority Conflict Audit |
| 9 | QUEUED | Roblox Studio Screenshot·Runtime 비교 |

## 현재 User Guide 권위 순서

```text
ADR-0089·ADR-0088
→ 구현 직전 UI·UX 명세
→ Quick Flow
→ Player·DM Guide
→ HTML Example
```

HTML과 User Guide는 비권위 Reference다. 충돌 시 ADR과 UI 명세를 따른다.

## Runtime 후속 Gate

- Observer→Owner·Player Multi-client 전환
- Character Console Layout
- Official Sheet 한국어 가독성
- Dice Notice Timing
- Death Save 접근성
- DM Scene Editor Bottom Catalog 성능
