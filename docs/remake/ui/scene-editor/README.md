# Scene Editor UI

선택·배치 모드, 기즈모, 스포이드, 복제, 인스펙터와 도킹 창을 다룬다.

## 관련 Main System Guide

- [`Scene Editor와 Authoring Guide`](../../guides/scene-editor/README.md)
  - DM Authoring Overlay, Scene Source·Tool Module·Authoring Command와 Edit History
  - 선택·연속 배치·ViewY·Surface-first Cursor·Snap·Inspector·Blueprint 흐름
  - Candidate Build·Diagnostic·Test Play·Atomic Publish, Quick Edit·Source Promotion과 Live Patch
- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - Scene Editor가 공유하는 Panel·ViewModel·Input Context·Focus·Error Boundary와 Local Layout
  - Authoring Intent를 Gameplay Store 직접 수정 없이 전달하는 공통 Client 경계
  - Reconnect·Rollback·Role Change 후 Editor UI와 Local Workspace State 복구

## 권위 문서

- [`scene-editor-interaction-and-layout.md`](scene-editor-interaction-and-layout.md)

도구 동작은 [`../../systems/scene/`](../../systems/scene/), 모듈 계약은 [`../../architecture/scene-editor-tool-module-architecture.md`](../../architecture/scene-editor-tool-module-architecture.md)를 참고한다.

## Guide 상태

```text
Guide Status: CURRENT
```

현재 Scene Editor와 Authoring의 권위 문서 관계, 사용자 흐름과 복구 경계는 Main System Guide에 반영되어 있다. 관련 권위 계약이 변경되면 Guide를 `UPDATE_REQUIRED`로 전환한다.
