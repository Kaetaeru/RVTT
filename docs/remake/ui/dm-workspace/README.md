# DM Workspace UI

Dockable·Floating DM Tool Window, Scene Lighting, Quick Action, Request Queue, Player View Preview와 Recovery Surface를 다룬다.

## 최상위 결정

- [`ADR-0090`](../../decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
  - Top Authoring Strip은 Module Launcher
  - Left Inspector는 Default Dock Instance
  - Tool Window는 독립 Module로 여러 개 동시 실행
  - Move·Resize·Dock·Undock·Tab·Close·Layout 저장
- [`ADR-0045`](../../decisions/ADR-0045-dm-workspace-and-scene-lighting-authoring.md)
  - 공통 Docking·Floating Workspace
- [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
  - 기본 읽기 흐름과 Quick Action Popover

## 구현 직전 명세

- [`Modular DM Tool Window와 Workspace Host 계약`](modular-dm-tool-window-contract.md)
- [`Full UI·UX and Settings Specification`](../shared/implementation-ready-ui-ux-and-settings-spec.md)

## 관련 Main System Guide

- [`Scene Editor와 Authoring Guide`](../../guides/scene-editor/README.md)
- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- [`Journal과 Ping Guide`](../../guides/journal/README.md)

## 권위 문서

- [`dm-workspace-and-scene-lighting.md`](dm-workspace-and-scene-lighting.md)
- [`dm-quick-action-and-context-command.md`](dm-quick-action-and-context-command.md)
- [`modular-dm-tool-window-contract.md`](modular-dm-tool-window-contract.md)

## 고정 경계

- DM Live Mode는 Player 전장 셸을 제거하지 않고 Module Window Workspace를 추가한다.
- Top Strip과 Left Inspector는 초기 Layout이며 Window 이동을 금지하지 않는다.
- Window 위치·크기·Dock 상태는 Local Preference다.
- Window 안의 실제 편집·전투·권한 변경은 서버 권위 Command다.
- Tool Module 하나가 다른 Tool의 Local State를 직접 변경하지 않는다.
- Player View Preview는 별도 Projection·Viewport이며 Control Assignment를 바꾸지 않는다.
- Quick Action은 작은 Context Popover이며 자동으로 큰 Window를 열지 않는다.
- Q는 Focus된 최상위 Window Context 하나만 닫고 ESC에는 Gameplay 의미가 없다.
