# UI·UX Policy와 화면 구현 현재 작업 순서

- 상태: `ACTIVE · SCREEN_IMPLEMENTATION_ALIGNMENT`
- 문서 종류: UI·UX Policy·Screen Work Order
- 작성일: 2026-08-05
- 최종 개정일: 2026-08-06
- 상위 작업 순서: [`CURRENT-WORK-ORDER`](../../CURRENT-WORK-ORDER.md)
- Policy Hub: [`UI·UX Global Policies`](README.md)
- 구현 직전 화면 명세: [`구현 직전 UI·UX와 설정 명세`](../shared/implementation-ready-ui-ux-and-settings-spec.md)
- 구현 준비도 감사: [`UI·UX 구현 준비도 감사`](../../audits/ui-ux-implementation-readiness-gap-audit.md)
- 검수 체크리스트: [`UI·UX Review Checklist`](UI-UX-REVIEW-CHECKLIST.md)
- 구현 Workspace: [`implementation/roblox`](../../../../implementation/roblox/README.md)

전역 Policy Foundation은 완료됐다. 2026-08-06의 ADR-0088과 구현 준비도 감사에 따라 화면 구성, 설정 기본값, 상태 전환과 Acceptance를 별도 구현 단계로 관리한다.

## 1. 완료 상태

| 순서 | 상태 | 작업 | 산출물 |
|---:|---|---|---|
| 1 | DONE | Visual Design Policy | [`visual-design-policy.md`](visual-design-policy.md) |
| 2 | DONE | Accent Theme·Color Consistency | [`accent-theme-and-color-consistency-policy.md`](accent-theme-and-color-consistency-policy.md) |
| 3 | DONE | Interaction·Input Policy Foundation | [`interaction-and-input-policy.md`](interaction-and-input-policy.md) |
| 4 | DONE | Information Architecture·Density | [`information-architecture-and-density-policy.md`](information-architecture-and-density-policy.md) |
| 5 | DONE | Feedback·Error·Recovery | [`feedback-error-and-recovery-policy.md`](feedback-error-and-recovery-policy.md) |
| 6 | DONE | Accessibility·Motion | [`accessibility-and-motion-policy.md`](accessibility-and-motion-policy.md) |
| 7 | DONE | 공통 Review Checklist | [`UI-UX-REVIEW-CHECKLIST.md`](UI-UX-REVIEW-CHECKLIST.md) |
| 8 | DONE | 기존 Policy Foundation Audit | [`기존 완료 감사`](../../audits/ui-ux-policy-completion-audit.md) |
| 9 | DONE | ADR-0088 직접 플레이 상위 결정 | [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md) |
| 10 | DONE | 구현 준비도 Gap Audit | [`새 감사`](../../audits/ui-ux-implementation-readiness-gap-audit.md) |
| 11 | DONE | 화면·설정·상태 구현 직전 명세 | [`구현 직전 명세`](../shared/implementation-ready-ui-ux-and-settings-spec.md) |
| 12 | IN_PROGRESS | 하위 UI 문서·Source·Acceptance 정합화 | Pointer·화면 셸·설정·Flow·Projection 정합화 |
| 13 | QUEUED | Studio Human UI Acceptance | Role·Scale·Theme·Motion·Screen별 Evidence |

## 2. 최신 고정 입력

```text
왼쪽 클릭
→ 선택 또는 클릭 전에 표시된 기본 행동

오른쪽 클릭
→ Capability 기반 Context Action Table

마우스 휠 클릭 드래그
→ Camera Orbit

Q
→ 최상위 Context 하나만 닫기·취소·거절

E
→ 현재 Preview·선택·승인·확정

ESC
→ Gameplay 의미 없음
```

- 권한에 없는 Action은 Projection하지 않는다.
- 현재 불가능 Action은 비활성 색상과 Hover·Focus Reason을 가진다.
- 행동 후 Actor Selection을 유지한다.
- 턴 전환은 Camera를 강제로 이동하지 않는다.

## 3. 확정된 화면 범위

```text
Global Shell
→ Mode·Role·Party·Actor·Hotbar·Map·Journal·System

Exploration
→ World Action·Movement·Context Action·Objective

Encounter
→ Initiative·Resource·End Turn·Reaction·Dice

Inventory·Loot
→ Equipment·Container·Transfer·Identification

Journal·Map·Ping
→ Stable Navigation·Permission Projection

Character·Rest·Death
→ Sheet·Downtime·HP 0·Death Save

Session·Settings·Recovery
→ Entry·Role·Preference·Reconnect·Resync

DM Live
→ Docked Workspace·Player View Preview·Override
```

## 4. 초기 설정 기본값

핵심 초기값:

```text
accent = gold
uiScale = 1.00
textScale = 1.00
hotbarRows = 2
partyRailMode = auto
combatLog = recent
minimap = medium · camera_up
tooltip = 0.25s
detailedTooltip = 0.75s
disabledReason = 0.15s
motion = full
turnFocus = soft_notification
edgePan = false
ESC gameplay = none
```

전체 기본값과 저장 범위는 구현 직전 명세를 따른다.

## 5. 구현 Gate

모든 새 UI Script와 화면은 다음을 만족해야 한다.

- ADR-0088와 Interaction Policy를 따른다.
- Visual Policy의 Semantic Token만 사용한다.
- 구현 직전 명세의 Mode Composition과 설정 기본값을 사용한다.
- Component가 물리 키·Pointer를 직접 감시하지 않는다.
- Q 한 단계 취소와 ESC No-op을 검증한다.
- 권한 밖 Action·미인지 정보가 Client Projection에 없다.
- Disabled Color·Hover/Focus Reason이 있다.
- Local Preview·Pending·Denied·Stale·Projection Reconciliation이 구분된다.
- Inventory·Journal·Settings·Recovery도 Loading·Empty·Denied·Error 상태를 가진다.
- Accent·Scale·Motion 변경 중 Focus·Selection·Pending을 유지한다.
- Player·DM·Observer Projection을 분리한다.
- `UI-UX-REVIEW-CHECKLIST.md`에 `FAIL`이 없다.

하나라도 충족하지 못하면 해당 화면 또는 Slice Build Acceptance를 통과시키지 않는다.

## 6. 구현 순서

```text
Shared Shell·System Entry·Preference Foundation
→ ADR-0088 Input·Context Action·Reason Tooltip
→ Exploration HUD·Movement Preview
→ Encounter HUD 정합화
→ Inventory·Loot·Transfer
→ Journal·Map·Ping
→ Character·Rest·Death
→ Settings·Accessibility
→ Entry·Role·Reconnect·Recovery
→ DM Live Workspace
→ Studio Human Evidence
```

## 7. 현재 비범위

- 사용자 임의 RGB·Hex 입력
- 화면별 독립 Theme
- 모바일·게임패드 완성 지원
- Screen Reader 플랫폼 통합
- 최종 Font·Icon·VFX Asset 확정
- 음악·환경음·공격·주문·UI SFX
- 측정 전 Performance Budget 완료 판정

## 8. 다음 Gate

```text
하위 UI 문서·Source·Acceptance 정합화
→ Static·Toolchain Validation
→ Exploration·Context Input Studio Retest
→ Inventory·Journal·Settings Human Evidence
→ Player·DM·Observer Permission Test
→ Recovery·Role Change Test
→ Performance·Accessibility 측정
```
