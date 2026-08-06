# High-Fidelity HTML UI Production Guide Audit

- 상태: `COMPLETE · STATIC HIGH-FIDELITY TARGET`
- 감사일: 2026-08-06
- HTML: [`../user-guides/html/index.html`](../user-guides/html/index.html)
- CSS Tokens: [`../user-guides/html/rvtt-ui.css`](../user-guides/html/rvtt-ui.css)
- Screen Definitions: [`../user-guides/html/rvtt-ui.js`](../user-guides/html/rvtt-ui.js)
- 상위 결정: [`ADR-0089`](../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 직접 플레이 결정: [`ADR-0088`](../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)

## 1. 목적

이 감사는 기존 구조 와이어프레임을 Roblox UI 제작 기준으로 직접 사용할 수 있는 고정밀 HTML 가이드로 교체했는지 확인한다.

```text
이전 HTML
→ 패널 위치와 화면 존재 여부를 확인하는 구조 예시

현재 HTML
→ Layout Metric + Design Token + Component State + Input Contract + Acceptance를 포함한 제작 기준서
```

## 2. 화면 범위

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

제작 기준 Canvas:

- Design Tokens · Layout Grid
- Component States · Layering

## 3. 고정밀 기준

### Layout

- 기준 Viewport `1920 × 1080`
- Design Safe Inset 좌우 `32 px`, 상하 `24 px`
- Player Character Console `1450 × 182 px`
- Compact Context Menu `212 px`, Row `39 px`
- Dice Result Notice Top `35 px`, Min Width `650 px`
- DM Left Inspector `330 px`
- Scene Editor Bottom Catalog `176 px`

### Design System

- Color·Surface·Semantic·Border Token 분리
- 4 px Spacing Scale
- 자체 SVG Icon Sprite
- Accent 6종
- UI Scale `0.80–1.40`
- Text Scale `0.90–1.30`
- Full·Reduced Motion
- 1920×1080·1440×900·2560×1080 Reference

### Component State

- Idle
- Hover
- Keyboard Focus
- Selected
- Disabled
- Pending
- Denied
- Critical

Disabled Action은 비활성 색상·Lock·Hover/Focus 불가능 사유를 함께 사용한다.

## 4. 화면별 구현 정보

각 화면은 HTML Stage 외부에 다음 정보를 표시한다.

```text
레이아웃 규격
→ 위치·크기·간격·Safe Inset

입력·상태
→ Semantic Input·Cancel·Confirm·Pending

구현 Acceptance
→ Roblox Runtime에서 입증할 조건
```

따라서 화면 제작자는 HTML 외형만 복제하지 않고 Authority·Projection·Input Context 요구사항을 함께 확인한다.

## 5. 정적 검증 결과

- [x] HTML parser 통과
- [x] Local CSS·JavaScript 참조 확인
- [x] JavaScript syntax 통과
- [x] 28개 Screen ID 고유
- [x] 28개 Renderer 등록
- [x] 28개 Renderer smoke test 통과
- [x] Navigation·Screen metadata 일치
- [x] Objective·Map·Minimap Runtime Navigation 없음
- [x] Context Action 한 열
- [x] Physical Dice 후 Top Result Notice
- [x] Official Sheet와 VTT Management 분리
- [x] Journal 왼쪽 문서 탭
- [x] DM Inspector 왼쪽
- [x] Scene Editor Catalog 하단

## 6. 자동 Screenshot 제한

현재 실행 환경의 Chromium이 `about:blank`에서도 정상 종료하지 않아 자동 Screenshot 비교를 생성하지 못했다. HTML parser, JavaScript syntax와 Renderer smoke test는 별도로 통과했다.

이 제한 때문에 다음을 완료로 표시하지 않는다.

- Browser pixel-diff
- Roblox ScreenGui와 HTML Screenshot 비교
- 한국어 실제 Font fallback 비교
- Studio UI Scale·Viewport Human Evidence

## 7. Runtime 후속 Gate

```text
High-Fidelity HTML Target
→ Roblox Theme Token·Component Library
→ ScreenGui Layout 구현
→ Player·Observer·DM Projection 연결
→ Studio Screenshot 비교
→ Keyboard·Mouse·Accessibility Evidence
→ Multi-client Authority Evidence
```

HTML 완료는 Runtime PASS가 아니다.
