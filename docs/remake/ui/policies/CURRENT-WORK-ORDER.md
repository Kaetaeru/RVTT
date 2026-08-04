# UI·UX Policy 현재 작업 순서

- 상태: COMPLETE
- 문서 종류: UI·UX Policy Work Order
- 작성일: 2026-08-05
- 완료일: 2026-08-05
- 상위 작업 순서: [`CURRENT-WORK-ORDER`](../../CURRENT-WORK-ORDER.md)
- Policy Hub: [`UI·UX Global Policies`](README.md)
- UI 문서 허브: [`UI 문서`](../README.md)
- UI Main Guide: [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- 완료 감사: [`UI·UX Policy Completion Audit`](../../audits/ui-ux-policy-completion-audit.md)
- 구현 Workspace: [`implementation/roblox`](../../../../implementation/roblox/README.md)

이 문서는 Production Script 작성 전에 확정해야 하는 전역 UI 시각 언어와 UX 행동 정책의 완료 근거다.

## 1. 완료 흐름

```text
기존 UI·Input·Camera·Presentation 권위 조사
→ Visual Design Policy
→ Interaction·Input Policy
→ Information Architecture·Density Policy
→ Feedback·Error·Recovery Policy
→ Accessibility·Motion Policy
→ Policy Review Checklist
→ Completion Audit
→ Implementation Workspace Bootstrap
```

정책은 화면별 와이어프레임을 대체하지 않는다. 모든 화면이 공유해야 하는 시각·상호작용·피드백·접근성 불변식을 제공한다.

## 2. 완료 상태

| 순서 | 상태 | 작업 | 산출물 |
|---:|---|---|---|
| 1 | DONE | 기존 UI·UX 권위 조사 | Policy 추적성과 Completion Audit |
| 2 | DONE | Visual Design Policy | [`visual-design-policy.md`](visual-design-policy.md) |
| 3 | DONE | Interaction·Input Policy | [`interaction-and-input-policy.md`](interaction-and-input-policy.md) |
| 4 | DONE | Information Architecture·Density Policy | [`information-architecture-and-density-policy.md`](information-architecture-and-density-policy.md) |
| 5 | DONE | Feedback·Error·Recovery Policy | [`feedback-error-and-recovery-policy.md`](feedback-error-and-recovery-policy.md) |
| 6 | DONE | Accessibility·Motion Policy | [`accessibility-and-motion-policy.md`](accessibility-and-motion-policy.md) |
| 7 | DONE | 공통 Review Checklist | [`UI-UX-REVIEW-CHECKLIST.md`](UI-UX-REVIEW-CHECKLIST.md) |
| 8 | DONE | UI·UX Policy Completion Audit | [`완료 감사`](../../audits/ui-ux-policy-completion-audit.md) |
| 9 | DONE | Implementation Workspace Bootstrap | [`implementation/roblox`](../../../../implementation/roblox/README.md) |
| 10 | NEXT | Slice 01 Script Manifest | `implementation/roblox/manifests/slice-01-script-manifest.md` |

## 3. 정책 우선순위

```text
사용자의 최신 명시적 결정
→ Product·Architecture·ADR
→ UI·UX Global Policy
→ Main System Guide
→ 화면별 UI 문서·Wireframe
→ Component 구현 편의
```

Global Policy가 새로운 Gameplay Authority를 만들 수는 없다. Authority 경계가 필요하면 Architecture를 먼저 수정한다.

## 4. 구현 Gate

모든 새 UI Script와 화면은 다음을 만족해야 한다.

- Visual Policy의 Semantic Token만 사용한다.
- 물리 키를 Component가 직접 감시하지 않는다.
- 현재 Mode·Context·Selection·Pending 상태를 사용자가 구분할 수 있다.
- Client가 권위 결과를 낙관적으로 확정하지 않는다.
- Loading·Waiting·Denied·Retrying·Resync·Recovery 상태가 존재한다.
- 색·Hover·Animation만으로 의미를 전달하지 않는다.
- Player·DM·Observer의 공개 정보가 Projection 단계에서 분리된다.
- Q는 가장 가까운 취소, E는 현재 공개된 확정 의미를 따른다.
- 파괴적 행동은 위험도에 맞는 확인과 결과 Preview를 제공한다.
- 재접속·Rollback·Role Change에서 오래된 Prompt·Focus·Pending을 폐기한다.
- Reduced Motion·Flash·Camera Shake 제한이 Presentation보다 우선한다.
- `UI-UX-REVIEW-CHECKLIST.md`의 `FAIL` 항목이 없다.

하나라도 충족하지 못하면 해당 UI 또는 Slice Build Acceptance를 통과시키지 않는다.

## 5. 다음 단계

```text
Slice 01 Script Manifest
→ Roblox Toolchain·Service Mapping 확정
→ 첫 Shared Contract Script
→ 대응 Test
→ Script 단위 검수
→ 다음 Script
```

Policy 완료는 Production Luau Script 작성 완료를 의미하지 않는다.

## 6. 현재 비범위

- 개별 화면의 최종 픽셀 배치와 모든 Asset 제작
- 실제 Roblox Font·Icon Asset ID 확정
- 측정 전 네트워크·렌더링 Budget 확정
- 모바일·게임패드 지원
- 음악·환경음·공격·주문·UI SFX
- Production Luau Script 작성
