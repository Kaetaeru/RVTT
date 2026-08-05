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

Authority·Security 보강
→ IMPLEMENTED

Structure·Policy·Toolchain CI
→ PASSED

Roblox Studio Runtime Baseline
→ VERIFIED

User Accent Theme Implementation
→ CI VERIFIED

현재 작업
→ Accent Theme Studio Acceptance
```

기존 Studio 실행 결과:

```text
Unit·Integration
→ passed=108 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3
```

새 Accent Test Source를 포함한 예상 Unit·Integration 결과는 `passed=150 failed=0`이며 아직 Studio Evidence가 아니다.

## 2. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI | Structure·Policy·Security Validator 성공 |
| 4 | DONE | Luau·Rojo Toolchain 검증 | Build·Type Check·Formatter·Linter 성공 |
| 5 | DONE | Roblox Studio Runtime Baseline | Unit·Integration·Live DataStore·3-client 실행 성공 |
| 6 | DONE | User Accent Theme Implementation | Gold 기본값·6개 Palette·Settings·Server Validation·Projection 연결 |
| 7 | IN_PROGRESS | Accent Theme Studio Acceptance | 기본 Gold·Palette 전환·Q 종료·Reconciliation·재접속 복구·Contrast 확인 |
| 8 | QUEUED | Slice 01 Studio Acceptance | Join→Select→Ready→Scene→Move→Reconnect와 오류·복구 확인 |
| 9 | QUEUED | Slice 01 Build Acceptance Audit | 실행 Evidence와 UI·UX Checklist 판정 |
| 10 | QUEUED | Slices 02–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 11 | QUEUED | DataStore·Restart Recovery | Restart·Lease·Migration·Conflict 검증 |
| 12 | QUEUED | UI Visual·Accessibility QA | Policy Checklist와 실제 화면 검수 |
| 13 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 3. Accent 구현 완료 범위

```text
AccentPreference Contract
→ DONE

Accent Palette Resolver
→ DONE

Semantic Theme Applicator
→ DONE

Settings Modal
→ DONE

ui.set_preference Server Validation
→ DONE

Viewer-only Projection Reconciliation
→ DONE

Unit·Integration Test Source
→ DONE

Static·Toolchain CI
→ PASSED
```

Accent 변경은 Role·Authority·Success·Warning·Danger·Content Semantic Color를 덮어쓰지 않는다.

## 4. 완료 해석

`IMPLEMENTED_STUDIO_BASELINE_VERIFIED`는 기존 구현 Source가 정적 검증과 Roblox Studio 기본 Runtime 검증을 통과했다는 뜻이다.

새 Accent Theme Delta의 현재 상태:

```text
IMPLEMENTED_CI_VERIFIED_STUDIO_PENDING
```

다음을 의미하지 않는다.

- Accent Settings Studio Acceptance 완료
- Slice 01 End-to-End 사용자 Acceptance 완료
- Slices 02–16 Acceptance 완료
- 실제 서버 종료·재시작 복구 완료
- 전체 D&D 2024 공식 데이터 포함
- UI 최종 픽셀 품질 완료
- Production Ready 또는 Release Ready

## 5. 현재 Blocker

- 새 Accent Test Source의 Studio 실행 Evidence 없음
- 여섯 Palette의 실제 화면 Contrast·Focus·Hover Evidence 없음
- 선택값의 Play 종료·재접속 복구 Evidence 없음
- Slice 01 전체 Flow의 실제 사용자 Evidence 없음
- 서버 종료·재시작과 Cross-server Lease Evidence 없음
- Navigation·Physics·Streaming·Large Scene Evidence 없음
- 공식 D&D 데이터의 Source Version·Rights Review 없음
- 전체 UI Visual·Accessibility Evidence 없음
- 성능·메모리·네트워크·장시간 Soak 측정 없음

## 6. 현재 실행 Gate: Accent Theme

`default.project.json`에서 다음을 검증한다.

```text
Fresh User 접속
→ 기본 Gold 확인
→ Settings 열기
→ 6개 Palette 순차 선택
→ Banner·Prompt·Settings Accent 즉시 변경
→ Role·Success·Warning·Danger 의미색 불변 확인
→ Q로 Settings 닫기
→ Play 종료
→ 재접속
→ 마지막 Accent 복구 확인
```

추가 확인:

- 선택된 Palette가 `선택됨` Label과 Stroke로도 구분된다.
- Hover와 Focus가 색만으로 전달되지 않는다.
- 알 수 없는 Preference는 Gold로 복구된다.
- 서버 Projection이 미리보기와 다르면 권위값으로 되돌아간다.
- 다른 사용자의 Preference가 Projection에 포함되지 않는다.

`test.project.json`에서 다음 결과를 확인한다.

```text
[RVTT Tests] passed=150 failed=0
```

## 7. 다음 Gate

```text
Accent Theme Studio Acceptance
→ 실행 Evidence 기록
→ Slice 01 Join·Select·Ready·Scene·Move·Reconnect
→ 실패 수정과 재실행
→ Slice 01 Production Build Acceptance Audit
→ Slice 02 Acceptance
```
