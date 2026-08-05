# RVTT UI·UX Global Policies

- 상태: CURRENT
- 문서 종류: UI·UX Policy Hub
- 작성일: 2026-08-05
- 최종 개정일: 2026-08-05
- 현재 작업 순서: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- UI 문서 허브: [`UI 문서`](../README.md)
- UI Main Guide: [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- 검수 체크리스트: [`UI·UX Review Checklist`](UI-UX-REVIEW-CHECKLIST.md)
- 완료 감사: [`UI·UX Policy Completion Audit`](../../audits/ui-ux-policy-completion-audit.md)

이 Policy 묶음은 개별 화면 와이어프레임보다 상위에 있는 공통 시각·색상·상호작용·정보·피드백·접근성 규칙이다.

## 정책 목록

1. [`Visual Design Policy`](visual-design-policy.md)
   - 디자인 정체성, Semantic Token, 색·타이포·간격·레이어·Component 상태
2. [`Accent Theme and Color Consistency Policy`](accent-theme-and-color-consistency-policy.md)
   - 깔끔하면서 화려한 시각 방향, 일관된 사용자 Accent, 기본 Gold와 설정 Preset
3. [`Interaction and Input Policy`](interaction-and-input-policy.md)
   - Semantic Input, Q/E·1–5, Pointer, Focus, Selection, Confirm 위험도
4. [`Information Architecture and Density Policy`](information-architecture-and-density-policy.md)
   - 전장 우선, 정보 위계, Panel 종류, Progressive Disclosure, Navigation
5. [`Feedback, Error and Recovery Policy`](feedback-error-and-recovery-policy.md)
   - Pending·Receipt·Projection, Error, Retry, Resync, Reconnect, Rollback
6. [`Accessibility and Motion Policy`](accessibility-and-motion-policy.md)
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
→ User Accent Preference
→ Theme·Palette Resolver
→ Shared Component
→ Screen Composition
→ ViewModel·Intent Binding
→ Accessibility Variant
→ Policy Checklist
→ Slice Build Acceptance
```

- UI Script는 Policy와 Shared Component를 우회해 화면별 임의 스타일·입력을 만들지 않는다.
- 기본 사용자 Accent는 `gold`다.
- 사용자는 Settings에서 승인된 Accent Preset을 선택할 수 있다.
- User Accent는 일반 선택·Primary Action·Navigation·장식에만 적용한다.
- Role·Authority·Success·Warning·Danger·Pending·Hidden·Content 의미색은 사용자 Accent로 변경하지 않는다.
- 모든 화면은 Loading·Empty·Denied·Stale·Error·Recovery 상태를 가진다.
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

## 현재 구현 Gate

Production UI와 Slice Acceptance에는 다음이 필요하다.

- 여섯 Policy `CURRENT`
- Review Checklist 완료
- Completion Audit `COMPLETE`
- Semantic Token과 Theme Resolver 사용
- `gold` 기본값과 사용자 Accent 설정 경로
- Accent별 Contrast·Focus·State 검수
- Slice 01 실제 화면 Visual·Accessibility Acceptance

Policy 완료가 곧 화면 구현 완료를 뜻하지 않는다. 화면별 Wireframe과 Slice Acceptance는 별도로 검증한다.
