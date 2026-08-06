# RVTT 고정밀 UI HTML 제작 가이드

- 상태: `CURRENT · HIGH_FIDELITY_PRODUCTION_TARGET · ADR-0090 ALIGNED`
- 최종 갱신일: 2026-08-06
- 실행 파일: [`index.html`](index.html)
- Loader: [`rvtt-ui.js`](rvtt-ui.js)
- Loading Fallback Style: [`rvtt-ui.css`](rvtt-ui.css)
- 압축 제작 자산: [`assets/`](assets/)
- Action Matrix·DM Window 결정: [`ADR-0090`](../../decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- 전체 UI 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 직접 플레이 입력: [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- Character Console 상세: [`character-console-action-matrix-and-resource-rail.md`](../../ui/combat-hud/character-console-action-matrix-and-resource-rail.md)
- DM Window 상세: [`modular-dm-tool-window-contract.md`](../../ui/dm-workspace/modular-dm-tool-window-contract.md)

```text
High-Fidelity HTML Production Target
≠ Roblox Studio Runtime Evidence
≠ Release Screenshot
```

이 HTML은 단순 화면 배치 예시가 아니다. Roblox `ScreenGui`, `Frame`, `UIGridLayout`, `UIListLayout`, `UIScale`, `UIStroke`, `UICorner`와 Input Context를 구현할 때 사용하는 시각·상태 기준서다.

## 제작 기준

- 기준 Viewport: `1920 × 1080`
- Design Safe Inset: 좌우 `32 px`, 상하 `24 px`
- Base Spacing Unit: `4 px`
- UI Scale: `0.80–1.40`
- Text Scale: `0.90–1.30`
- Character Console: 하단 Anchor, 사용자 `1–4행`
- Action Cell: `48 × 48 px`
- 공격·행동 Matrix와 주문 Matrix 분리
- Resource Rail: Console 상단 전체 폭
- Compact Context Menu: `212 px`, 한 열, Row `39 px`
- Dice Result Notice: 상단 `35 px`, 최소 폭 `650 px`
- DM Default Inspector: 왼쪽 `330 px` Dock Instance
- DM Tool Window: 독립 Move·Resize·Dock·Close Module
- Scene Editor Catalog: 하단 `176 px` Default Dock Module

## 포함 범위

Runtime 화면 26개와 제작 기준 Canvas 2개, 총 28개다.

```text
제작 기준       2
세션·공통       3
Player 전장     8
Player 관리     6
설정·복구       3
Observer        1
DM              5
합계           28
```

주요 화면:

- Exploration Action Matrix Console
- Compact Context Action Menu
- Movement·Target·Reaction·Dice·Death Save
- Official Sheet·VTT Management·Inventory·Loot
- Journal·Downtime·Settings·Recovery
- DM Live Multi-window Workspace
- DM Quick Action Popover
- DM Modular Tool Windows
- Scene Editor + Catalog + Material·Lighting Windows

## 화면 사용법

1. `index.html`을 브라우저에서 연다.
2. 왼쪽 Navigation에서 화면을 선택한다.
3. Accent, Viewport, UI Scale, Text Scale, `Action Rows 1–4`와 Motion을 변경한다.
4. `Grid`를 켜 Safe Area와 간격을 확인한다.
5. Character Console의 Action Icon에 마우스를 올려 Cursor 위 설명 Panel을 확인한다.
6. Disabled Action에 Hover·Keyboard Focus를 두어 불가능 사유를 확인한다.
7. DM 화면에서 여러 Tool Window의 독립 Titlebar·Dock·Resize 표현을 확인한다.
8. 화면 Focus 상태에서 `Q`, `E`, `ESC`를 눌러 공통 입력 Notice를 확인한다.

직접 캡처 모드:

```text
index.html?capture=1#exploration
index.html?capture=1#dm-tools
index.html?capture=1#scene-editor
```

## 구현 시 사용 방법

각 화면 아래에는 다음 세 묶음이 표시된다.

```text
레이아웃 규격
→ 위치·크기·간격·Safe Inset

입력·상태
→ Semantic Input·Pending·Disabled·Cancel·Confirm

구현 Acceptance
→ Runtime에서 반드시 입증할 조건
```

HTML의 픽셀은 `1920 × 1080` Reference다. Roblox에서는 절대 좌표만 복사하지 않고 다음 조합으로 변환한다.

```text
AnchorPoint
+ Scale 중심 UDim2
+ Offset Min/Max
+ User UIScale
+ Responsive breakpoint
```

## 권위·저작권 경계

- 공식 D&D 2024 Character Sheet는 정보 계층과 읽기 순서의 기준이다.
- Baldur’s Gate 3는 작은 Action Icon, 다중 행 전술 Console과 Resource 읽기 흐름의 참고점이다.
- TaleSpire는 전장 중심 Build Mode와 Catalog workflow의 참고점이다.
- 외부 제품의 로고, 고유 폰트, 일러스트, Texture, Icon과 픽셀 단위 외형은 복제하지 않는다.
- HTML은 RVTT 자체 Design Token과 자체 SVG Icon으로 구성한다.

## 정적 검증

- HTML parse: PASS
- JavaScript syntax: PASS
- 압축 CSS·Renderer와 원본 Byte 일치: PASS
- 28개 Renderer smoke test: PASS
- Screen ID unique: PASS
- Action Matrix Rows contract: `1,2,3,4`
- 공격·주문 Matrix 분리: PASS
- Cursor 위 ActionHoverPanel: PASS
- Resource Rail 상단 배치: PASS
- 기억·준비 수와 Spell Slot 분리: PASS
- DM Window Module contract: PASS
- DM 동시 Multi-window 화면: PASS
- Objective·Map·Minimap Runtime Navigation: 없음

현재 실행 환경에서는 Chromium 프로세스가 정상 종료되지 않아 자동 Screenshot 비교를 생성하지 못했다. Roblox Studio Layout·Input·Projection과 다중 Client Evidence는 아직 실행하지 않았다.
