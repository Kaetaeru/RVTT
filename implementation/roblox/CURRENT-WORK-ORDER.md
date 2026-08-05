# RVTT Roblox Implementation 현재 작업 순서

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-05
- Script Manifest: [`manifests/all-slices-script-manifest.md`](manifests/all-slices-script-manifest.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)
- Studio 검증 근거: [`Roblox Studio Runtime Baseline Validation Audit`](../../docs/remake/audits/roblox-studio-runtime-baseline-validation-audit.md)
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

현재 작업
→ Slice 01 Studio Acceptance
```

Studio 실행 결과:

```text
Unit·Integration
→ passed=108 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3
```

## 2. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI | Structure·Policy·Security Validator 성공 |
| 4 | DONE | Luau·Rojo Toolchain 검증 | Build·Type Check·Formatter·Linter 성공 |
| 5 | DONE | Roblox Studio Runtime Baseline | Unit·Integration·Live DataStore·3-client 실행 성공 |
| 6 | IN_PROGRESS | Slice 01 Studio Acceptance | Join→Select→Ready→Scene→Move→Reconnect와 오류·복구 확인 |
| 7 | QUEUED | Slice 01 Build Acceptance Audit | 실행 Evidence와 UI·UX Checklist 판정 |
| 8 | QUEUED | Slices 02–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 9 | QUEUED | DataStore·Restart Recovery | Restart·Lease·Migration·Conflict 검증 |
| 10 | QUEUED | UI Visual·Accessibility QA | Policy Checklist와 실제 화면 검수 |
| 11 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 3. 완료 해석

`IMPLEMENTED_STUDIO_BASELINE_VERIFIED`는 구현 Source가 정적 검증과 Roblox Studio 기본 Runtime 검증을 통과했다는 뜻이다.

다음을 의미하지 않는다.

- Slice 01 End-to-End 사용자 Acceptance 완료
- Slices 02–16 Acceptance 완료
- 실제 서버 종료·재시작 복구 완료
- 전체 D&D 2024 공식 데이터 포함
- UI 최종 픽셀 품질 완료
- Production Ready 또는 Release Ready

## 4. 현재 Blocker

- Slice 01 전체 Flow의 실제 사용자 Evidence 없음
- 서버 종료·재시작과 Cross-server Lease Evidence 없음
- Navigation·Physics·Streaming·Large Scene Evidence 없음
- 공식 D&D 데이터의 Source Version·Rights Review 없음
- UI Visual·Accessibility Evidence 없음
- 성능·메모리·네트워크·장시간 Soak 측정 없음

## 5. 현재 실행 Gate

Slice 01 Acceptance는 다음 순서로 검증한다.

```text
DM·Player 접속
→ Character Select
→ Ready
→ Scene Projection
→ Token Select
→ 권위 이동
→ Disconnect
→ Reconnect
→ 동일 Character·Scene·Position 복구
```

각 단계에서 확인할 항목:

- 화면에 보이는 상태와 사용자 피드백
- Client Intent와 Server Authority 결과 일치
- Unauthorized·Stale·Disconnect 실패 처리
- Player·DM·Observer Projection 분리
- Revision·AuthorityEpoch·Projection Sequence
- 재접속 후 중복 Membership·Command 없음

## 6. 다음 Gate

```text
Slice 01 Studio Acceptance 실행
→ 실패 수정과 재실행
→ 실행 Evidence 기록
→ Slice 01 Production Build Acceptance Audit
→ Slice 02 Acceptance
```
