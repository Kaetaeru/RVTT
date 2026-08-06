# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · ADR_0089_SOURCE_ALIGNMENT`
- 최종 갱신일: 2026-08-06
- UI 재정렬 결정: [`ADR-0089`](decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 직접 플레이 결정: [`ADR-0088`](decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 구현 직전 UI·UX: [`implementation-ready-ui-ux-and-settings-spec.md`](ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- 충돌 감사: [`ui-html-authority-conflict-and-realignment-audit.md`](audits/ui-html-authority-conflict-and-realignment-audit.md)
- HTML 예시: [`user-guides/html/index.html`](user-guides/html/index.html)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)

## 1. 현재 단계

```text
Product·Architecture·Domain Baseline
→ IMPLEMENTED BASELINE

Direct Play Pointer UX
→ ACCEPTED · ADR-0088

Observer-first Session·UI Surface Realignment
→ ACCEPTED · ADR-0089

User Guide HTML
→ REALIGNED · 26 STATIC SCREENS

Production UI Source·Acceptance
→ ADR-0089 ALIGNMENT REQUIRED

Historical Slice 01 Runtime
→ USER VERIFIED · OLD INPUT/UI CONTRACT
```

이전 HTML 28개 화면과 기존 Slice 01 PASS는 ADR-0089의 Runtime 증거가 아니다.

## 2. 확정된 화면 방향

```text
Entry
→ Observer first
→ DM Character Assignment
→ Owner + Controller + Player Projection

Player
→ Default Owned Actor Selection
→ Bottom Character Console
→ Compact Vertical Context Menu
→ No Objective·Map·Minimap UI

Dice
→ Physical Presentation
→ Top Transparent Result Notice

Character
→ Official Sheet View
→ VTT Management View

DM
→ Top Authoring Strip
→ Left Inspector
→ Compact Quick Action
→ Scene Editor Bottom Catalog
```

## 3. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | ADR-0089 결정과 충돌 감사 | 기존 ADR·HTML 충돌 분류 |
| 2 | DONE | 구현 직전 UI 명세 재작성 | Observer·Console·Sheet·DM·Editor 계약 |
| 3 | DONE | User Guide·HTML 재작성 | 26개 화면·역할별 흐름 |
| 4 | IN_PROGRESS | Production Projection·UI Source 정합화 | Observer→Player, Default Actor, Character Console |
| 5 | QUEUED | Context·Dice·Death UI 정합화 | Compact Menu·Top Notice·Urgency |
| 6 | QUEUED | Character Sheet 두 View | Official·VTT 동일 Revision |
| 7 | QUEUED | DM Workspace·Scene Editor | Left Inspector·Top Strip·Bottom Catalog |
| 8 | QUEUED | Static·Rojo·Luau Revalidation | 전체 Gate PASS |
| 9 | QUEUED | Observer→Player Multi-client Test | Ownership·Projection·정보 제거 Evidence |
| 10 | QUEUED | Player UI Human Evidence | Console·Context·Dice·Sheet·Death |
| 11 | QUEUED | DM UI Human Evidence | Live·Quick Action·Editor |
| 12 | QUEUED | Accessibility·Performance | Scale·Motion·한국어·Soak |
| 13 | QUEUED | Grand Persistence Runtime | Published phases |

## 4. Source 정합화 범위

### Session·Projection

- 모든 미배정 참가자 Observer 진입
- DM Assign Character Command
- Owner·Controller·Role 원자 전환
- Default Owned Actor Selection
- Role change 시 오래된 Projection 제거

### Player UI

- Unified Character Console
- Objective·Map·Minimap 제거
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

1. ADR-0089가 충돌하는 기존 Layout·Entry 표현보다 우선한다.
2. 문서·HTML 완료를 Runtime PASS로 해석하지 않는다.
3. 자동 Gate 실패 중에는 Studio 실행을 요청하지 않는다.
4. 권한 밖 정보는 Client에 보낸 뒤 숨기지 않는다.
5. 이전 입력·UI 계약의 Runtime PASS를 새 계약에 재사용하지 않는다.
6. 공식 D&D·TaleSpire 고유 자산은 복제하지 않는다.
