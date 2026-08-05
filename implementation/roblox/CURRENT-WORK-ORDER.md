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

User Accent Theme Automated Tests
→ VERIFIED

Studio Boot Sync Deadlock Fix
→ IMPLEMENTED · CI PASSED

현재 작업
→ 수정 Head Studio UI 재검수
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

`173/0`은 깨끗하게 Build한 Test Place에서도 재현됐다.

## 2. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI | Structure·Policy·Security Validator 성공 |
| 4 | DONE | Luau·Rojo Toolchain 검증 | Build·Type Check·Formatter·Linter 성공 |
| 5 | DONE | Roblox Studio Runtime Baseline | Unit·Integration·Live DataStore·3-client 실행 성공 |
| 6 | DONE | User Accent Theme Implementation | Gold 기본값·6개 Palette·Settings·Server Validation·Projection 연결 |
| 7 | DONE | Accent Automated Studio Tests | Unit·Integration `173/0`, Live DataStore `10/0` |
| 8 | IN_PROGRESS | Boot Fix Studio Recheck | Loading 종료·App 표시·Runtime Ready 로그 확인 |
| 9 | QUEUED | Accent Visual·Input Acceptance | 6개 Palette·Q 종료·Reconciliation·Contrast 확인 |
| 10 | QUEUED | Accent Persistence Acceptance | Live Persistence 활성화 상태에서 재접속 복구 |
| 11 | QUEUED | Slice 01 Studio Acceptance | Join→Select→Ready→Scene→Move→Reconnect와 오류·복구 확인 |
| 12 | QUEUED | Slice 01 Build Acceptance Audit | 실행 Evidence와 UI·UX Checklist 판정 |
| 13 | QUEUED | Slices 02–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 14 | QUEUED | DataStore·Restart Recovery | Restart·Lease·Migration·Conflict 검증 |
| 15 | QUEUED | UI Visual·Accessibility QA | Policy Checklist와 실제 화면 검수 |
| 16 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 3. Boot Sync Deadlock 수정 범위

```text
Server Remote Bootstrap 선행
→ DONE

Projection Publisher 선행
→ DONE

Default Studio Live Persistence 차단
→ DONE

Client Runtime 조기 공개
→ DONE

clientReady 우선 Projection
→ DONE

Full Resync 비동기 Fallback
→ DONE

Remote Wait Timeout·진단 UI
→ DONE

Static·Toolchain CI
→ PASSED
```

기본 Studio에서 Live Persistence가 비활성화됐다는 로그는 정상이다.

```text
[RVTT Boot] Studio persistence disabled; use live-datastore.project.json or set RVTT_EnableStudioPersistence=true
[RVTT ClientBoot] runtime ready
```

## 4. 완료 해석

현재 Accent Theme Delta 상태:

```text
ACCENT_THEME_AUTOMATED_TESTS_VERIFIED_UI_PENDING
```

다음을 의미하지 않는다.

- 수정 Head의 실제 Studio UI 표시 완료
- Accent Settings 시각·입력 Acceptance 완료
- Play 종료 후 Preference 영구 복구 완료
- Slice 01 End-to-End 사용자 Acceptance 완료
- Slices 02–16 Acceptance 완료
- 실제 서버 종료·재시작 복구 완료
- UI 최종 픽셀 품질 완료
- Production Ready 또는 Release Ready

## 5. 현재 Blocker

- 수정 Head `fee64cf`의 실제 Studio 재실행 Evidence 없음
- 여섯 Palette의 실제 화면 Contrast·Focus·Hover Evidence 없음
- Live Persistence 활성화 상태의 선택값 복구 Evidence 없음
- Slice 01 전체 Flow의 실제 사용자 Evidence 없음
- 서버 종료·재시작과 Cross-server Lease Evidence 없음
- Navigation·Physics·Streaming·Large Scene Evidence 없음
- 공식 D&D 데이터의 Source Version·Rights Review 없음
- 전체 UI Visual·Accessibility Evidence 없음
- 성능·메모리·네트워크·장시간 Soak 측정 없음

## 6. 현재 실행 Gate: Boot Fix와 Accent UI

`default.project.json`에서 다음을 검증한다.

```text
Fresh Studio Place
→ Rojo default.project.json 연결
→ Play
→ Loading 화면 종료
→ RVTT App·Gold Accent 표시
→ Output의 SERVER_BOOTED·runtime ready 확인
→ Settings 열기
→ 6개 Palette 순차 선택
→ Banner·Prompt·Settings Accent 즉시 변경
→ Q로 Settings 닫기
```

추가 확인:

- 기본 Studio에서는 Live DataStore 요청을 기다리지 않는다.
- 선택된 Palette가 `선택됨` Label과 Stroke로 구분된다.
- 서버 Projection이 미리보기와 다르면 권위값으로 되돌아간다.
- Role·Success·Warning·Danger 의미색은 변경되지 않는다.

## 7. Persistence 별도 Gate

기본 Studio Play는 Session 내 UI 검수용이다. Play 종료 후 복구는 다음 중 하나로 별도 검증한다.

```text
live-datastore.project.json
또는
DataModel Attribute RVTT_EnableStudioPersistence=true
```

Live Persistence를 활성화한 뒤:

```text
Accent 선택
→ 저장 Flush 대기
→ 재접속
→ 마지막 Accent 복구
```

## 8. 다음 Gate

```text
Boot Fix Studio Recheck
→ Accent Visual·Input Acceptance
→ Accent Persistence Acceptance
→ Slice 01 Join·Select·Ready·Scene·Move·Reconnect
→ Slice 01 Production Build Acceptance Audit
```
