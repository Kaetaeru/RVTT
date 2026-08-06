# DM UI 예시 순서

- 전체 HTML: [`../html/index.html`](../html/index.html)
- 상위 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)

## Session 운영

1. [`DM Live Workspace`](../html/index.html#dm-live)
2. [`DM Quick Action Popover`](../html/index.html#dm-quick)
3. [`Fog·Time·Encounter Tools`](../html/index.html#dm-tools)
4. [`Player View Preview·Rollback`](../html/index.html#dm-recovery)

기본 배치:

```text
상단
→ Scene, Scene Editor, Quick Edit, Fog, Time, Encounter, Journal, Players, Rollback

왼쪽
→ Selection Inspector

중앙
→ Live Scene
```

## Full Scene Edit

[`Scene Editor Build Mode`](../html/index.html#scene-editor)을 사용한다.

```text
상단 Tool Bar
+ 왼쪽 Inspector
+ 중앙 Build Viewport
+ 하단 Tile·Prop·Prefab·Blueprint Catalog
```

Quick Action은 큰 창이 아니며 선택 대상 옆의 작은 Popover다.
