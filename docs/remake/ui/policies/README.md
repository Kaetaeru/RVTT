# RVTT UI·UX Global Policies

- 상태: CURRENT
- 문서 종류: UI·UX Policy Hub
- 작성일: 2026-08-05
- 현재 작업 순서: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- UI 문서 허브: [`UI 문서`](../README.md)
- UI Main Guide: [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- 검수 체크리스트: [`UI·UX Review Checklist`](UI-UX-REVIEW-CHECKLIST.md)
- 완료 감사: [`UI·UX Policy Completion Audit`](../../audits/ui-ux-policy-completion-audit.md)

이 Policy 묶음은 개별 화면 와이어프레임보다 상위에 있는 공통 시각·상호작용·정보·피드백·접근성 규칙이다.

## 정책 목록

1. [`Visual Design Policy`](visual-design-policy.md)
   - 디자인 정체성, Semantic Token, 색·타이포·간격·레이어·Component 상태
2. [`Interaction and Input Policy`](interaction-and-input-policy.md)
   - Semantic Input, Q/E·1–5, Pointer, Focus, Selection, Confirm 위험도
3. [`Information Architecture and Density Policy`](information-architecture-and-density-policy.md)
   - 전장 우선, 정보 위계, Panel 종류, Progressive Disclosure, Navigation
4. [`Feedback, Error and Recovery Policy`](feedback-error-and-recovery-policy.md)
   - Pending·Receipt·Projection, Error, Retry, Resync, Reconnect, Rollback
5. [`Accessibility and Motion Policy`](accessibility-and-motion-policy.md)
   - UI Scale, Text·Contrast, Keyboard Focus, Motion·Flash·Camera Comfort, 저사양 Fallback

## 적용 우선순위

```text
Product·Architecture·ADR
→ UI·UX Global Policies
→ Main System Guide
→ 화면별 UI 문서·Wireframe
→ Component·Script 구현
```

정책이 Gameplay Authority를 새로 정의하지 않는다. 권위 충돌이 있으면 Architecture를 먼저 갱신한다.

## 구현 적용 방식

```text
Semantic Design Token
→ Shared Component
→ Screen Composition
→ ViewModel·Intent Binding
→ Accessibility Variant
→ Policy Checklist
→ Slice Build Acceptance
```

- UI Script는 Policy와 Shared Component를 우회해 화면별 임의 스타일·입력을 만들지 않는다.
- 모든 화면은 Loading·Empty·Denied·Stale·Error·Recovery 상태를 가진다.
- 모든 Authority Action은 Local Feedback과 Projection Reconciliation을 구분한다.
- Player·DM·Observer 공개 정보는 Server Projection에서 분리한다.
- Reduced Motion과 저사양 Fallback에서도 핵심 결과·위험·Focus가 유지된다.

## 현재 구현 Gate

Production Script를 추가하기 전에 다음이 필요하다.

- 다섯 Policy `CURRENT`
- Review Checklist 완료
- Completion Audit `COMPLETE`
- `implementation/roblox/` Workspace와 Script 추가 규칙 확정
- Slice 01 Script Manifest 작성

Policy 완료가 곧 화면 구현 완료를 뜻하지 않는다. 화면별 Wireframe과 Slice Acceptance는 계속 별도로 검증한다.
