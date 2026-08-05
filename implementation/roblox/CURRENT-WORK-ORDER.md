# RVTT Roblox Implementation 현재 작업 순서

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-05
- Script Manifest: [`manifests/all-slices-script-manifest.md`](manifests/all-slices-script-manifest.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)
- Studio 검증 근거: [`Roblox Studio Runtime Baseline Validation Audit`](../../docs/remake/audits/roblox-studio-runtime-baseline-validation-audit.md)
- Accent Policy: [`Accent Theme and Color Consistency Policy`](../../docs/remake/ui/policies/accent-theme-and-color-consistency-policy.md)
- 계약→Script 감사: [`All-slice Contract-to-Script Transfer Audit`](../../docs/remake/audits/all-slice-script-transfer-audit.md)
- UI·UX Policy: [`UI·UX Global Policies`](../../docs/remake/ui/policies/README.md)

## 1. 현재 상태

```text
16개 Slice Script Manifest
→ DONE

Shared·Server·Client·UI·Test Source
→ IMPLEMENTED

Structure·Policy·Toolchain CI
→ PASSED

Roblox Studio Runtime Baseline
→ VERIFIED

Accent Theme Visual·Input·Persistence
→ VERIFIED IN STUDIO

Roblox Avatar Auto-Spawn Disable
→ VERIFIED IN STUDIO

Slice 01 Acceptance Harness
→ IMPLEMENTED · CI PASSED

현재 작업
→ Slice 01 Studio Acceptance
```

Studio 실행 Evidence:

```text
Unit·Integration
→ passed=173 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3
```

2026-08-05 Accent·Avatar·Persistence 결과:

```text
6개 Palette·입력·Reconciliation
→ PASS

Roblox Player.Character 비생성
→ PASS

Persistence Enable·Load·Save
→ PASS

재실행 후 Accent 복구
→ PASS

Canonical Remote Bootstrap
→ PASS
```

## 2. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI | Structure·Policy·Security Validator 성공 |
| 4 | DONE | Luau·Rojo Toolchain 검증 | Build·Type Check·Formatter·Linter 성공 |
| 5 | DONE | Roblox Studio Runtime Baseline | Unit·Integration·Live DataStore·3-client 성공 |
| 6 | DONE | User Accent Theme Implementation | Gold·6 Palette·Settings·Server Validation·Projection |
| 7 | DONE | Accent Automated Studio Tests | Unit·Integration `173/0`, Live DataStore `10/0` |
| 8 | DONE | Boot Fix Studio Recheck | Loading 종료와 App 표시 |
| 9 | DONE | Accent Visual·Input Acceptance | 6 Palette·Q 종료·Reconciliation·선택 유지 |
| 10 | DONE | Roblox Avatar Auto-Spawn Disable | CharacterAutoLoads 차단·UI 독립 Boot·Studio 확인 |
| 11 | DONE | Accent Persistence Acceptance | Load·Save·재실행 후 마지막 Accent 복구 |
| 12 | DONE | Slice 01 Acceptance Harness | 실제 Production Command·Projection·Persistence 기반 전용 Place |
| 13 | IN_PROGRESS | Slice 01 Studio Acceptance | Join→Select→Ready→Scene→Move→Reconnect |
| 14 | QUEUED | Slice 01 Build Acceptance Audit | 실행 Evidence와 UI·UX Checklist 판정 |
| 15 | QUEUED | Slices 02–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 16 | QUEUED | DataStore·Restart Recovery | Restart·Lease·Migration·Conflict 검증 |
| 17 | QUEUED | UI Visual Redesign | 전체 화면을 Token·공통 Component 기준으로 일괄 개편 |
| 18 | QUEUED | UI Accessibility QA | Keyboard·Focus·Contrast·User Test |
| 19 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 3. Slice 01 Acceptance Harness

Production UI는 아직 Placeholder Shell이며 Slice 01 조작면을 제공하지 않는다. 부분적인 임시 UI 확장을 Production 화면에 누적하지 않고, 제거 가능한 전용 Acceptance Place를 사용한다.

```text
slice01-acceptance.project.json
→ Production Server·Client·UI Source 사용
→ Live Persistence 활성화
→ Studio Tester DM 역할 Override
→ Slice 01 전용 조작·Projection Harness만 추가
```

Harness가 실행하는 실제 명령:

```text
session.join
→ character.create_draft
→ character.activate
→ session.select_character
→ session.ready
→ session.start
→ scene.enter
→ movement.commit
```

자동 회귀 테스트는 Authority Snapshot을 새 Runtime에 복구한 뒤 Character·Scene·Actor Position·Connection을 확인한다.

Studio에서는 다음을 직접 확인한다.

```text
Join·DM Membership
→ Character 생성·활성화·선택
→ Ready Projection
→ Scene 활성화
→ Actor·Token Projection
→ Token 직접 선택
→ Server-authoritative Move
→ Persistence Save
→ Stop·Play
→ Character·Scene·Position Recovery
```

Acceptance 전용 DM Override Flag는 `slice01-acceptance.project.json`에만 존재한다. `default.project.json`의 Production Authorization에는 영향을 주지 않는다.

## 4. 현재 UI 디자인 해석

현재 Production UI와 Acceptance Harness는 기능 검증용 Placeholder다.

- 현재 외형을 최종 디자인으로 확장하지 않는다.
- 화면별 직접 스타일 추가를 피한다.
- Production 화면의 Token과 공통 Component 계약을 유지한다.
- Acceptance Harness는 테스트 전용 조작면으로만 사용한다.
- 전면 수정은 별도 `UI Visual Redesign` 작업에서 일관되게 수행한다.
- 기능 테스트는 상태·입력·서버 권위·Persistence 계약을 기준으로 유지한다.

## 5. 현재 상태 해석

Accent Delta:

```text
ACCENT_THEME_PERSISTENCE_VERIFIED
```

Slice 01 Delta:

```text
SLICE_01_ACCEPTANCE_HARNESS_READY_STUDIO_PENDING
```

다음을 의미하지 않는다.

- Slice 01 End-to-End Acceptance 완료
- Slices 02–16 Acceptance 완료
- Cross-server 복구 완료
- UI 최종 디자인 완료
- Production Ready 또는 Release Ready

## 6. 현재 실행 Gate: Slice 01

`slice01-acceptance.project.json`을 새 Place로 Build하고 기존 Persistence 테스트 Place에 게시한 뒤 Play한다.

통과 기준:

- Harness와 `ClientBoot runtime ready`가 표시된다.
- Join부터 Move까지 모든 단계가 PASS가 된다.
- Scene Canvas에서 Token 선택이 가능하다.
- 이동 후 Position과 Revision이 Projection으로 갱신된다.
- 저장 로그 이후 Stop·Play하면 Character·Scene·Position이 복구된다.
- Roblox 기본 아바타는 계속 생성되지 않는다.
- Accent Preference가 유지된다.
- 관련 Output 오류가 없다.

최종 정적 Gate Head:

```text
0dae097891c28172792eb2326bce636b0d31e0a2
```

- Structure·Policy Validator: PASS
- StyLua: PASS
- Selene: PASS
- Production·Test·Multi-client·Persistence·Slice 01 Rojo Build: PASS
- Production·Test Luau Type Analysis: PASS

## 7. 다음 Gate

```text
Slice 01 Studio Acceptance
→ Slice 01 Production Build Acceptance Audit
→ Slices 02–16 Studio Acceptance
→ DataStore·Restart Recovery
→ UI Visual Redesign
```
