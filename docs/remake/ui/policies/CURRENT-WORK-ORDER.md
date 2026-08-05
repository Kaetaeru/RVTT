# UI·UX Policy 현재 작업 순서

- 상태: COMPLETE
- 문서 종류: UI·UX Policy Work Order
- 작성일: 2026-08-05
- 완료일: 2026-08-05
- 최종 개정일: 2026-08-05
- 상위 작업 순서: [`CURRENT-WORK-ORDER`](../../CURRENT-WORK-ORDER.md)
- Policy Hub: [`UI·UX Global Policies`](README.md)
- UI 문서 허브: [`UI 문서`](../README.md)
- UI Main Guide: [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- 완료 감사: [`UI·UX Policy Completion Audit`](../../audits/ui-ux-policy-completion-audit.md)
- 구현 Workspace: [`implementation/roblox`](../../../../implementation/roblox/README.md)

이 문서는 RVTT 전역 UI 시각 언어와 UX 행동 정책의 완료 근거다. 2026-08-05 사용자 결정에 따라 사용자 선택형 Accent Theme과 색상 일관성 정책을 추가했다.

## 1. 완료 흐름

```text
기존 UI·Input·Camera·Presentation 권위 조사
→ Visual Design Policy
→ Accent Theme·Color Consistency Policy
→ Interaction·Input Policy
→ Information Architecture·Density Policy
→ Feedback·Error·Recovery Policy
→ Accessibility·Motion Policy
→ Policy Review Checklist
→ Completion Audit
→ Implementation Workspace·Runtime Baseline
```

정책은 화면별 와이어프레임을 대체하지 않는다. 모든 화면이 공유해야 하는 시각·색상·상호작용·피드백·접근성 불변식을 제공한다.

## 2. 완료 상태

| 순서 | 상태 | 작업 | 산출물 |
|---:|---|---|---|
| 1 | DONE | 기존 UI·UX 권위 조사 | Policy 추적성과 Completion Audit |
| 2 | DONE | Visual Design Policy | [`visual-design-policy.md`](visual-design-policy.md) |
| 3 | DONE | Accent Theme·Color Consistency | [`accent-theme-and-color-consistency-policy.md`](accent-theme-and-color-consistency-policy.md) |
| 4 | DONE | Interaction·Input Policy | [`interaction-and-input-policy.md`](interaction-and-input-policy.md) |
| 5 | DONE | Information Architecture·Density Policy | [`information-architecture-and-density-policy.md`](information-architecture-and-density-policy.md) |
| 6 | DONE | Feedback·Error·Recovery Policy | [`feedback-error-and-recovery-policy.md`](feedback-error-and-recovery-policy.md) |
| 7 | DONE | Accessibility·Motion Policy | [`accessibility-and-motion-policy.md`](accessibility-and-motion-policy.md) |
| 8 | DONE | 공통 Review Checklist | [`UI-UX-REVIEW-CHECKLIST.md`](UI-UX-REVIEW-CHECKLIST.md) |
| 9 | DONE | UI·UX Policy Completion Audit | [`완료 감사`](../../audits/ui-ux-policy-completion-audit.md) |
| 10 | DONE | Implementation Workspace·Studio Baseline | [`implementation/roblox`](../../../../implementation/roblox/README.md) |
| 11 | NEXT | Slice 01 Studio UI Acceptance | Join→Select→Ready→Scene→Move→Reconnect 화면 검수 |

## 3. 최신 고정 결정

```text
시각 방향
→ 깔끔하면서 화려함

색상 체계
→ Semantic Color와 하나의 User Accent

기본 Accent
→ gold

사용자 선택
→ Settings > Interface > Accent Color
```

초기 Preset:

```text
gold
azure
emerald
amethyst
teal
silver
```

사용자 Accent는 Role·Authority·Success·Warning·Danger·Pending·Hidden과 Content 의미색을 변경하지 않는다.

## 4. 정책 우선순위

```text
사용자의 최신 명시적 결정
→ Product·Architecture·ADR
→ UI·UX Global Policy
→ Main System Guide
→ 화면별 UI 문서·Wireframe
→ Component 구현 편의
```

Global Policy가 새로운 Gameplay Authority를 만들 수는 없다. Accent Theme은 사용자별 비권위 Preference로 처리한다.

## 5. 구현 Gate

모든 새 UI Script와 화면은 다음을 만족해야 한다.

- Visual Policy의 Semantic Token만 사용한다.
- Component가 Palette ID·Hex 값을 직접 분기하지 않는다.
- 기본 Accent는 `gold`다.
- Settings에서 승인된 Accent Preset을 선택·Preview·복원할 수 있다.
- Theme 변경 중 Focus·Selection·Pending·Modal을 유지한다.
- User Accent가 역할색·상태색·콘텐츠색을 덮어쓰지 않는다.
- 한 Surface에서 여러 Accent가 경쟁하지 않는다.
- 화려한 Glow·Gradient·Motion은 중요 선택·결과에 제한한다.
- 물리 키를 Component가 직접 감시하지 않는다.
- 현재 Mode·Context·Selection·Pending 상태를 사용자가 구분할 수 있다.
- Client가 권위 결과를 낙관적으로 확정하지 않는다.
- Loading·Waiting·Denied·Retrying·Resync·Recovery 상태가 존재한다.
- 색·Hover·Animation만으로 의미를 전달하지 않는다.
- Player·DM·Observer의 공개 정보가 Projection 단계에서 분리된다.
- 재접속·Rollback·Role Change에서 오래된 Prompt·Focus·Pending을 폐기한다.
- Reduced Motion·Flash·Camera Shake 제한이 Presentation보다 우선한다.
- `UI-UX-REVIEW-CHECKLIST.md`의 `FAIL` 항목이 없다.

하나라도 충족하지 못하면 해당 UI 또는 Slice Build Acceptance를 통과시키지 않는다.

## 6. 현재 다음 단계

```text
Slice 01 default.project.json 실행
→ Join·Character Select·Ready UI
→ Scene·Token Selection·Movement UI
→ Disconnect·Reconnect·Recovery UI
→ Gold 기본 Theme 확인
→ Accent Preset 변경·복구 확인
→ Visual·Accessibility Checklist
→ Slice 01 Production Build Acceptance Audit
```

## 7. 현재 비범위

- 사용자 임의 RGB·Hex 입력
- 개별 화면의 독립 Theme
- 모바일·게임패드 지원
- 모든 최종 Asset·Font·Icon 확정
- 측정 전 렌더링·네트워크 Budget 확정
- 음악·환경음·공격·주문·UI SFX
