# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · HIGH_FIDELITY_UI_SOURCE_ALIGNMENT`
- 최종 갱신일: 2026-08-06
- UI 재정렬 결정: [`ADR-0089`](decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 직접 플레이 결정: [`ADR-0088`](decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 구현 직전 UI·UX: [`implementation-ready-ui-ux-and-settings-spec.md`](ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- 권위 충돌 감사: [`ui-html-authority-conflict-and-realignment-audit.md`](audits/ui-html-authority-conflict-and-realignment-audit.md)
- 고정밀 HTML 감사: [`high-fidelity-html-production-guide-audit.md`](audits/high-fidelity-html-production-guide-audit.md)
- 고정밀 HTML: [`user-guides/html/index.html`](user-guides/html/index.html)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)

## 1. 현재 단계

```text
Product·Architecture·Domain Baseline
→ IMPLEMENTED BASELINE

Direct Play Pointer UX
→ ACCEPTED · ADR-0088

Observer-first Session·UI Surface Realignment
→ ACCEPTED · ADR-0089

High-Fidelity User Guide HTML
→ COMPLETE · 26 RUNTIME SCREENS + 2 PRODUCTION CANVASES

Production UI Source·Acceptance
→ HIGH-FIDELITY TARGET ALIGNMENT REQUIRED

Historical Slice 01 Runtime
→ USER VERIFIED · OLD INPUT/UI CONTRACT
```

이전 구조 HTML과 기존 Slice 01 PASS는 ADR-0089·고정밀 UI의 Runtime 증거가 아니다.

## 2. 현재 제작 기준

```text
Reference Viewport
→ 1920 × 1080

Player
→ Default Owned Actor Selection
→ Bottom Character Console 1450 × 182
→ Compact Vertical Context Menu 212 px
→ Physical Dice 뒤 Top Result Notice
→ Official Sheet + VTT Management
→ No Objective·Map·Minimap UI

DM
→ Top Authoring Strip
→ Left Inspector 330 px
→ Compact Quick Action
→ Scene Editor Bottom Catalog 176 px

Guide
→ Design Tokens
→ Component States
→ Screen Layout Metrics
→ Input·State Contract
→ Runtime Acceptance
```

## 3. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | ADR-0089 결정과 충돌 감사 | 기존 ADR·HTML 충돌 분류 |
| 2 | DONE | 구현 직전 UI 명세 재작성 | Observer·Console·Sheet·DM·Editor 계약 |
| 3 | DONE | 고정밀 HTML 제작 기준서 | 26 Runtime 화면·2 Reference Canvas·Token·State |
| 4 | IN_PROGRESS | Roblox Theme Token·Component Library | HTML Token과 1:1 의미 대응 |
| 5 | QUEUED | Session·Projection Source 정합화 | Observer→Owner·Player·Default Actor |
| 6 | QUEUED | Character Console·Context·Dice·Death | 고정밀 Layout와 State 구현 |
| 7 | QUEUED | Character Sheet 두 View·Inventory | 동일 Projection Revision |
| 8 | QUEUED | DM Workspace·Scene Editor | Left Inspector·Top Strip·Bottom Catalog |
| 9 | QUEUED | Static·Rojo·Luau Revalidation | 전체 Gate PASS |
| 10 | QUEUED | Browser·Studio Screenshot 비교 | Reference·Compact·Wide Evidence |
| 11 | QUEUED | Observer→Player Multi-client Test | Ownership·Projection·정보 제거 Evidence |
| 12 | QUEUED | Player·DM Human UI Evidence | Input·Tooltip·Notice·Sheet·Editor |
| 13 | QUEUED | Accessibility·Performance | Scale·Motion·한국어·Soak |
| 14 | QUEUED | Grand Persistence Runtime | Published phases |

## 4. Source 정합화 범위

### Shared UI Foundation

- Theme Token과 Semantic Color
- 자체 Icon Registry
- Panel·Button·ActionSlot·Tooltip·Notice·Prompt Component
- UI Scale·Text Scale·Viewport Breakpoint
- Layer Priority와 Focus Order

### Session·Projection

- 모든 미배정 참가자 Observer 진입
- DM Assign Character Command
- Owner·Controller·Role 원자 전환
- Default Owned Actor Selection
- Role change 시 오래된 Projection 제거

### Player UI

- Unified Character Console
- Compact vertical Context Menu
- Physical dice 뒤 Top Result Notice
- Official Sheet + VTT Management
- DM-assigned Downtime
- Urgent Death Save
- Journal left tabs

### DM UI

- Top Authoring Strip
- Left Inspector
- Compact Quick Action Popover
- Full Scene Editor Bottom Catalog

## 5. 운영 규칙

1. ADR-0089와 고정밀 HTML이 충돌하는 이전 Layout 예시보다 우선한다.
2. HTML의 픽셀을 절대 Offset만으로 복사하지 않고 Anchor·Scale·Min/Max로 변환한다.
3. 문서·HTML 완료를 Runtime PASS로 해석하지 않는다.
4. 권한 밖 정보는 Client에 보낸 뒤 숨기지 않는다.
5. 이전 입력·UI 계약의 Runtime PASS를 새 계약에 재사용하지 않는다.
6. 공식 D&D·Baldur's Gate·TaleSpire 고유 자산은 복제하지 않는다.
