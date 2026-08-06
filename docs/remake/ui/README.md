# UI 문서

화면 배치, 입력 문맥, Panel 상태, 사용자 설정과 피드백을 정의한다.

## 구현 직전 권위 명세

- [`Shared UI 구현 직전 UI·UX와 설정 명세`](shared/implementation-ready-ui-ux-and-settings-spec.md)
  - 전역 화면 셸과 Mode별 HUD
  - Exploration·Encounter·Downtime·Observer·DM Live Mode
  - Inventory·Loot·Journal·Map·Settings·Entry·Rest·Death·Recovery
  - Tooltip·Toast·Hotbar·Camera·Accessibility 초기 기본값
  - 설정 저장 범위, Shared Component와 Acceptance Matrix
- [`UI·UX 구현 준비도와 빈 영역 감사`](../audits/ui-ux-implementation-readiness-gap-audit.md)
  - 기존 문서가 채운 범위와 구현자가 추측해야 했던 공백
  - 충돌 문서, 초기값과 아직 Runtime에서 검증되지 않은 항목

## Global UI·UX Policy

Production UI Script와 모든 화면이 먼저 따라야 하는 전역 정책:

- [`UI·UX Global Policy Hub`](policies/README.md)
- [`Visual Design Policy`](policies/visual-design-policy.md)
- [`Accent Theme and Color Consistency Policy`](policies/accent-theme-and-color-consistency-policy.md)
- [`Interaction and Input Policy`](policies/interaction-and-input-policy.md)
- [`Information Architecture and Density Policy`](policies/information-architecture-and-density-policy.md)
- [`Feedback, Error and Recovery Policy`](policies/feedback-error-and-recovery-policy.md)
- [`Accessibility and Motion Policy`](policies/accessibility-and-motion-policy.md)
- [`UI·UX Review Checklist`](policies/UI-UX-REVIEW-CHECKLIST.md)
- [`UI·UX Policy Completion Audit`](../audits/ui-ux-policy-completion-audit.md)

우선순위:

```text
최신 사용자 결정
→ Product·Architecture·Accepted ADR
→ Global UI·UX Policy
→ Main System Guide
→ 구현 직전 UI·UX 명세
→ 화면별 UI 문서·Wireframe
→ Component·Script
```

## 최상위 직접 플레이 결정

- [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)

```text
왼쪽 클릭
→ 선택 또는 클릭 전에 표시된 기본 행동

오른쪽 클릭
→ Capability 기반 Context Action Table

마우스 휠 클릭 드래그
→ Camera Orbit

Q
→ 최상위 Context 하나만 닫기·취소

E
→ 현재 Preview·선택·승인·확정

ESC
→ Gameplay 의미 없음
```

## Main System Guide

- [`UI, Camera와 Presentation Guide`](../guides/ui/README.md)
  - Projection Replica·ViewModel·Panel·Semantic Input·UI Intent의 공통 Client 흐름
  - CameraRequest·Focus·Follow·Bookmark와 Presentation Recipe·Queue·Marker·Fallback
  - Reconnect·Rollback·Role Change 후 Epoch-safe UI·Camera·Presentation 복구
- [`Journal과 Ping Guide`](../guides/journal/README.md)
  - Journal Document·Outline·Search·Backlink·Edit Projection과 Recoverable Draft
  - Safe Navigation CameraRequest·Selection Intent와 위치·경로 Ping Input·Presentation 경계
- [`Character, Inventory와 Downtime Guide`](../guides/character/README.md)
  - Inventory·Equipment·Rest·Persistent Character State와 화면 Projection 경계
- [`Combat와 Encounter Guide`](../guides/combat/README.md)
  - Initiative·Turn·Opportunity·Reaction·Death Save·Encounter Projection
- [`Extension, Plugin과 Content Pack Guide`](../guides/extension/README.md)
  - Presentation Recipe·Module·Step Handler·Augment의 Version·Fallback·오류 격리

## 최상위 권위 계약

- [`UI Projection, ViewModel, Input Context와 Recovery Runtime 계약`](../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Session Play Mode, Context, Overlay와 Transition 계약`](../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Selection Runtime 계약`](../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Presentation Runtime 계약`](../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`Interaction Capability 계약`](../architecture/interaction-capability-contextual-command-and-adjudication-contract.md)

## 영역

- `policies/`: 전역 시각·상호작용·정보·피드백·접근성 정책과 Checklist
- `common-input/`: Q/E, Left·Right·Middle Pointer, 1–5와 Input Context
- `shared/`: 전역 셸, Mode별 HUD, Settings, 공통 Component와 구현 직전 명세
- `combat-hud/`: Encounter HUD, 행동·대상 지정과 Prompt UI
- `character-sheet/`: 공식 2024형 Character Sheet와 실시간 상태
- `dm-workspace/`: DM Workspace, Quick Action과 Docking
- `scene-editor/`: Scene Authoring 화면과 도구

Inventory·Loot·Journal·Map·Settings·Session Entry·Recovery는 초기 Production에서 `shared/implementation-ready-ui-ux-and-settings-spec.md`를 화면 권위로 사용한다. 화면 규모가 커져 별도 문서로 분리할 때도 해당 명세와 동일한 상태·설정·입력 계약을 유지한다.

## 추천 읽기 순서

1. `../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md`
2. `policies/README.md`
3. `../guides/ui/README.md`
4. `../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md`
5. `common-input/common-input-grammar.md`
6. `shared/implementation-ready-ui-ux-and-settings-spec.md`
7. 대상 화면 UI 문서
8. 관련 Gameplay Domain Guide·Architecture·System
9. `policies/UI-UX-REVIEW-CHECKLIST.md`
10. `../audits/ui-ux-implementation-readiness-gap-audit.md`

## 고정 경계

- UI는 Raw Domain State가 아니라 사용자별 Projection을 읽는다.
- 같은 Projection Event Batch를 부분 적용하지 않는다.
- Component는 Remote와 Domain Store를 직접 호출하지 않고 UI Intent를 제출한다.
- Command Result만으로 HP, Item, Turn과 Resource를 직접 변경하지 않는다.
- Character Sheet·Inventory·Journal·Map·Settings Panel은 Gameplay Mode가 아니다.
- Authority Prompt는 로컬 Close로 완료하지 않고 응답 Command와 Projection으로 종료한다.
- Q는 최상위 Input Context 하나만 소비하며 ESC에는 Gameplay 의미가 없다.
- Viewer 권한에 없는 Action과 미인지 정보는 Disabled 자리로 남기지 않고 Projection하지 않는다.
- Rollback과 재접속 후 이전 AuthorityEpoch의 Prompt·Selection·Command·Focus Token을 재사용하지 않는다.
- Panel Layout, UI Scale, Accent와 접근성 설정은 Gameplay Authority와 분리한다.
- 화면별 임의 Style 값 대신 Semantic Design Token을 사용한다.
- 색·Hover·Motion만으로 핵심 의미를 전달하지 않는다.
- Production UI Script는 구현 직전 명세와 UI·UX Review Checklist를 모두 통과해야 한다.

## 상태

```text
Global Policy Foundation
→ COMPLETE

Screen·Settings·Flow Specification
→ IMPLEMENTATION READY

Production Source Alignment
→ REQUIRED

Studio Runtime Evidence
→ NOT EXECUTED
```
