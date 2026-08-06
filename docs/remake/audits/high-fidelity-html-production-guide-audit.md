# High-Fidelity HTML UI Production Guide Audit

- 상태: `COMPLETE · STATIC HIGH-FIDELITY TARGET · ADR-0090 ALIGNED`
- 감사일: 2026-08-06
- HTML: [`../user-guides/html/index.html`](../user-guides/html/index.html)
- Action Matrix·DM Window 결정: [`ADR-0090`](../decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- Character Console 상세: [`../ui/combat-hud/character-console-action-matrix-and-resource-rail.md`](../ui/combat-hud/character-console-action-matrix-and-resource-rail.md)
- DM Window 상세: [`../ui/dm-workspace/modular-dm-tool-window-contract.md`](../ui/dm-workspace/modular-dm-tool-window-contract.md)

## 1. 목적

기존 고정밀 가이드가 Character Console의 행동 밀도와 DM Workspace Modularity까지 실제 제작 기준으로 표현하는지 확인한다.

## 2. 화면 범위

Runtime 화면 26개와 제작 기준 Canvas 2개, 총 28개다.

## 3. ADR-0090 고정밀 기준

### Character Console

- [x] 공격·행동 Matrix와 주문 Matrix 분리
- [x] 사용자 Action Rows `1–4`
- [x] Icon은 행을 채운 뒤 오른쪽으로 연속 배열
- [x] 48×48 px Action Cell
- [x] Hover·Focus Action Description Panel
- [x] Disabled Lock와 불가능 사유
- [x] Resource Rail이 Console 상단 전체 폭
- [x] 기억·준비 `used / maximum` 표시
- [x] 기억·준비 수와 Spell Slot Pip 분리
- [x] Console이 아래 Anchor를 유지하고 위로 확장

### DM Workspace

- [x] Top Authoring Strip은 Window Launcher
- [x] Left Inspector는 Default Dock Window Instance
- [x] Live Workspace에 여러 Window 동시 표시
- [x] Fog·Time·Encounter·Scene Tool을 독립 Window로 표현
- [x] Window별 Titlebar·Move·Resize·Dock·Close Control
- [x] Scene Editor에 Catalog와 Material·Lighting Window 동시 표시
- [x] Quick Action은 작은 Popover 유지

## 4. 정적 검증 결과

- [x] HTML parser 통과
- [x] JavaScript syntax 통과
- [x] 28개 Screen ID 고유
- [x] 28개 Renderer 등록
- [x] 28개 Renderer smoke test 통과
- [x] `consoleActionRows=[1,2,3,4]` Registry 확인
- [x] `dmWindowModules=true` Registry 확인
- [x] ActionHoverPanel event delegation 존재
- [x] Objective·Map·Minimap Runtime Navigation 없음

## 5. 아직 Runtime 증거가 아닌 항목

- Browser pixel-diff
- Roblox ScreenGui와 HTML Screenshot 비교
- 실제 Pointer Hover 위치 Flip·Clamp
- Drag Reorder와 Preference 저장
- DM Window 실제 Move·Resize·Dock Interaction
- Window Layout 재접속 복구
- Multi-client Permission·Stale Window 처리

## 6. Runtime 후속 Gate

```text
ADR-0090 HTML Target
→ Action Matrix·Resource Projection
→ ActionHoverPanel Component
→ DmToolRegistry·DmWindowHost
→ Studio Interaction Evidence
→ Multi-client Permission Evidence
```

HTML 완료는 Runtime PASS가 아니다.
