# RVTT UI·UX Global Policies

- 상태: `CURRENT · POLICY FOUNDATION COMPLETE`
- 문서 종류: UI·UX Policy Hub
- 작성일: 2026-08-05
- 최종 개정일: 2026-08-06
- 현재 작업 순서: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- UI 문서 허브: [`UI 문서`](../README.md)
- 구현 직전 화면 명세: [`구현 직전 UI·UX와 설정 명세`](../shared/implementation-ready-ui-ux-and-settings-spec.md)
- 구현 준비도 감사: [`UI·UX 구현 준비도 감사`](../../audits/ui-ux-implementation-readiness-gap-audit.md)
- UI Main Guide: [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- 검수 체크리스트: [`UI·UX Review Checklist`](UI-UX-REVIEW-CHECKLIST.md)
- 기존 정책 완료 감사: [`UI·UX Policy Completion Audit`](../../audits/ui-ux-policy-completion-audit.md)

이 Policy 묶음은 개별 화면 와이어프레임보다 상위에 있는 공통 시각·색상·상호작용·정보·피드백·접근성 규칙이다. Policy 완료는 화면 구성, 설정 기본값, Production Script 또는 Studio Runtime 완료를 뜻하지 않는다.

## 정책 목록

1. [`Visual Design Policy`](visual-design-policy.md)
   - 디자인 정체성, Semantic Token, 색·타이포·간격·레이어·Component 상태
2. [`Accent Theme and Color Consistency Policy`](accent-theme-and-color-consistency-policy.md)
   - 사용자 Accent, 기본 Gold와 설정 Preset
3. [`Interaction and Input Policy`](interaction-and-input-policy.md)
   - ADR-0088 기반 Q/E·Left·Right·Middle Pointer, Focus, Selection, Confirm 위험도
4. [`Information Architecture and Density Policy`](information-architecture-and-density-policy.md)
   - 전장 우선, 정보 위계, Panel 종류, Progressive Disclosure, Navigation
5. [`Feedback, Error and Recovery Policy`](feedback-error-and-recovery-policy.md)
   - Pending·Receipt·Projection, Error, Retry, Resync, Reconnect, Rollback
6. [`Accessibility and Motion Policy`](accessibility-and-motion-policy.md)
   - UI Scale, Text·Contrast, Keyboard Focus, Motion·Flash·Camera Comfort, 저사양 Fallback

## 적용 우선순위

```text
최신 사용자 결정
→ Product·Architecture·Accepted ADR
→ UI·UX Global Policies
→ Main System Guide
→ 구현 직전 UI·UX와 설정 명세
→ 화면별 UI 문서·Wireframe
→ Component·Script 구현
```

정책이 Gameplay Authority를 새로 정의하지 않는다. 권위 충돌이 있으면 Accepted ADR·Architecture를 먼저 갱신한다.

## 최상위 직접 플레이 계약

```text
왼쪽 클릭
→ 선택 또는 클릭 전에 표시된 기본 행동

오른쪽 클릭
→ Capability 기반 Context Action Table

마우스 휠 클릭 드래그
→ Camera Orbit

Q
→ 최상위 Context 한 단계 닫기·취소

E
→ 현재 Preview·선택·승인·확정

ESC
→ Gameplay 의미 없음
```

권한에 없는 Action은 표시하지 않는다. 권한에는 있으나 현재 불가능한 Action은 비활성 색상으로 표시하고 Hover·Keyboard Focus에서 이유를 제공한다.

## 구현 적용 방식

```text
Semantic Design Token
→ User Preference·Accent Resolver
→ Shared Component
→ Screen Composition
→ ViewModel·Intent Binding
→ Accessibility Variant
→ Screen Acceptance
→ Slice Build Acceptance
```

- UI Script는 Policy와 Shared Component를 우회해 화면별 임의 스타일·입력을 만들지 않는다.
- 기본 사용자 Accent는 `gold`다.
- 모든 화면은 Loading·Empty·Denied·Stale·Unavailable·Error·Recovery 상태를 필요한 범위에서 가진다.
- 모든 Authority Action은 Local Feedback과 Projection Reconciliation을 구분한다.
- Player·DM·Observer 공개 정보는 Server Projection에서 분리한다.
- Reduced Motion과 저사양 Fallback에서도 핵심 결과·위험·Focus가 유지된다.

## 디자인 핵심

```text
중성 Surface와 정돈된 Layout
+ 하나의 사용자 Accent
+ 제한된 Glow·Gradient·Motion
= 깔끔하면서 화려하고 일관된 RVTT UI
```

화려함은 중요한 선택과 결과에 집중한다. 모든 Component에 상시 Glow·Gradient·Particle을 사용하지 않는다.

## 화면 구현 Gate

Production UI와 Slice Acceptance에는 다음이 필요하다.

- 여섯 Global Policy `CURRENT`
- ADR-0088와 Interaction Policy 정합성
- 구현 직전 화면·설정 명세 연결
- Semantic Token과 Theme Resolver
- Settings에서 기본값·Preview·복원·저장 범위 구현
- Exploration·Encounter·Inventory·Journal·Map·Settings·Recovery 화면 상태
- Disabled Color·Hover/Focus Reason
- Player·DM·Observer Permission Projection 분리
- Local Preview·Pending·Denied·Stale·Projection Reconciliation
- UI Scale·Accent·Motion·Role별 Screenshot·Human Evidence
- Review Checklist에 `FAIL` 없음

## 현재 상태

```text
Global Policy Foundation
→ COMPLETE

Direct Play Top-level Contract
→ COMPLETE

Screen·Settings·Flow Specification
→ IMPLEMENTATION READY

Production Source Alignment
→ REQUIRED

Studio Runtime Evidence
→ NOT EXECUTED
```
