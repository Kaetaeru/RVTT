# DM Workspace UI

Dockable DM 작업공간, Scene Lighting, Quick Action, Request Queue, Player View Preview와 Recovery Surface를 다룬다.

## 구현 직전 화면 명세

- [`Full UI·UX and Settings Specification`](../shared/implementation-ready-ui-ux-and-settings-spec.md)
  - DM Live Mode와 Shared Player Shell 결합
  - Player View Preview와 DM-only Source 분리
  - 일반 Player Action과 DM Override 구분
  - Role Change·Reconnect·Recovery·Settings·Acceptance

## 관련 Main System Guide

- [`Scene Editor와 Authoring Guide`](../../guides/scene-editor/README.md)
  - Live DM Mode와 Full Scene Edit, Authoring Overlay·Pause Gate와 Source Command 경계
- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - Dockable Panel·ViewModel·Input Context·Focus·UI Intent와 Permission-aware Projection
  - DM Observe·Camera Focus·Presentation, Local Layout과 Role Change 복구
- [`Journal과 Ping Guide`](../../guides/journal/README.md)

## 권위 문서

- [`dm-workspace-and-scene-lighting.md`](dm-workspace-and-scene-lighting.md)
- [`dm-quick-action-and-context-command.md`](dm-quick-action-and-context-command.md)
- [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)

## 고정 경계

- DM Live Mode는 Player 전장 셸을 제거하지 않고 Docked Workspace를 추가한다.
- Player View Preview는 별도 Projection·Viewport이며 Control Assignment를 바꾸지 않는다.
- Right Pointer Action Table에서 Player Action과 DM Override를 섹션·Label로 구분한다.
- 권한에 없는 Action은 자리·Count도 표시하지 않는다.
- Tier 3 Override는 영향 Preview·Audit·별도 Confirm을 사용한다.
- Q는 최상위 Context 하나만 닫으며 ESC에는 Gameplay 의미가 없다.
- Recovery Review와 Quick Action이 Domain Store를 직접 수정하지 않는다.
