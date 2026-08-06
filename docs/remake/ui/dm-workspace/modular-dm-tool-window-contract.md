# Modular DM Tool Window와 Workspace Host 계약

- 상태: `CURRENT · IMPLEMENTATION READY`
- 최종 갱신일: 2026-08-06
- 상위 결정: [`ADR-0090`](../../decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- 기존 Workspace 결정: [`ADR-0045`](../../decisions/ADR-0045-dm-workspace-and-scene-lighting-authoring.md)
- 기본 화면 배치: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 고정밀 HTML: [`User Guide HTML`](../../user-guides/html/index.html#dm-tools)

## 1. 목적

DM이 편집 프로그램처럼 여러 창을 동시에 열어도 Tool 간 상태 결합과 권위 누수를 만들지 않는 Module·Window Host 구조를 정의한다.

## 2. 기본 Workspace

기본 저장 Layout:

```text
Top Authoring Strip
→ Module Launcher

Left Dock
→ Selection Inspector Instance

Center
→ Live Scene 또는 Build Viewport

Bottom Dock
→ Scene Catalog in Full Scene Edit
```

이 배치는 초기값이다. Inspector·Journal·Encounter·Fog·Time·Scene·Player·Rollback 도구는 Window Module로 열리고 이동·도킹할 수 있다.

## 3. Module Registry

```text
DmToolRegistry:Register({
  moduleId,
  title,
  iconId,
  instancePolicy,
  supportedContexts,
  minimumPermissions,
  createProjectionAdapter,
  createCommandBindings,
  defaultWindowPlacement,
  minimumSize,
  maximumSize,
})
```

`instancePolicy`:

- `singleton`
- `per_entity`
- `per_document`
- `multiple`
- `context_popover`

## 4. Module Instance

```text
DmToolModuleInstance
├─ instanceId
├─ moduleId
├─ contextKey?
├─ projectionRevision
├─ localViewState
├─ windowState
├─ inputContextId
├─ pendingCommands[]
└─ lifecycleState
```

Lifecycle:

```text
created
→ mounted
→ visible
→ minimized?
→ stale?
→ disposed
```

Module은 자신의 Local View State만 직접 수정한다. 다른 Module과의 공유 상태는 Domain Projection·Event 또는 User Preference Store를 통한다.

## 5. Window Host

```text
DmWindowHost
├─ windowsByInstanceId
├─ zOrder[]
├─ dockTree
├─ tabGroups[]
├─ focusedInstanceId?
├─ layoutRevision
└─ inputContextStack
```

지원:

- Move
- Resize
- Minimize·Restore
- Close
- Dock Left·Right·Bottom
- Undock
- Tab Group
- Focus·Z-order
- Workspace Layout Save·Restore

## 6. 권위 경계

Window 조작은 Local Preference다.

Tool Action은 서버 Command다.

```text
Window Move·Resize·Dock
→ Local Workspace Layout

Fog Reveal·HP Change·Scene Publish
→ Capability Check
→ Revision Check
→ Command Journal
→ Commit
```

Window Host는 Domain State를 직접 변경하지 않는다.

## 7. Stale·Permission 처리

Role·Scene·Selection·Authority Revision이 바뀌면 각 Module이 독립적으로 재평가된다.

```text
권한 유지
→ Projection Refresh

Context만 사라짐
→ Safe Empty State 또는 Close

권한 상실
→ 즉시 Sensitive Projection 폐기
→ Window Close 또는 Permission-safe Surface
```

다른 Window는 영향을 받지 않는다.

## 8. Quick Action

Quick Action은 `context_popover` Module이다.

- 작은 세로 Popover
- Cursor·Selection 인접
- 값 입력은 Inline Stepper
- 위험 작업만 Confirmation Surface
- `상세 열기`를 선택해야 Full Window Module 생성

## 9. Scene Editor

Full Scene Editor에서도 다음은 독립 Module이다.

- Hierarchy
- Inspector
- Material
- Lighting
- Navigation
- Asset Detail
- Diagnostics
- Publish Review

Bottom Catalog는 기본 Dock Module이며 필요하면 높이 변경·최소화·다른 Monitor Workspace로 이동할 수 있다.

## 10. Layout Persistence

```text
DmWorkspacePreference
├─ workspaceProfileId
├─ viewportClass
├─ windowPlacements[]
├─ dockTree
├─ tabGroups[]
├─ minimized[]
└─ updatedAt
```

Campaign 권위 데이터와 분리 저장한다. 잘못된 Layout은 초기 Default Layout으로 Reset할 수 있다.

## 11. Acceptance

- 3개 이상 Window를 동시에 표시한다.
- 한 Window 이동·크기 변경·닫기가 다른 Window State를 변경하지 않는다.
- Inspector 두 개를 서로 다른 Entity Context로 열 수 있다.
- Singleton 도구의 중복 Open은 기존 Instance Focus로 처리한다.
- Permission 제거 시 해당 Window의 민감 정보가 즉시 사라진다.
- Workspace Layout은 재접속 후 복구된다.
- Q는 Focus된 Window의 최상위 Context 하나만 닫는다.
- Quick Action은 Full Window로 자동 확장되지 않는다.
- Scene Editor의 Catalog·Material·Lighting Module이 동시에 동작한다.
