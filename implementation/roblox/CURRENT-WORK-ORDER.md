# RVTT Roblox Implementation 현재 작업 순서

- 상태: `IMPLEMENTED_UNVERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-05
- Script Manifest: [`manifests/all-slices-script-manifest.md`](manifests/all-slices-script-manifest.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)
- 계약→Script 감사: [`All-slice Contract-to-Script Transfer Audit`](../../docs/remake/audits/all-slice-script-transfer-audit.md)
- UI·UX Policy: [`UI·UX Global Policies`](../../docs/remake/ui/policies/README.md)

## 1. 현재 상태

```text
16개 Slice Script Manifest
→ DONE

Shared·Server·Client·UI·Test Source
→ IMPLEMENTED

서버 권위 보강
→ IMPLEMENTED

정적 Structure·Security·Policy Validation
→ PASSED

Luau·Rojo·Roblox Studio Validation
→ NOT RUN
```

현재 baseline:

- Luau Source·Test `76`개
- Domain Script `18`개
- 명시적 Authorization Command `53`개
- Client 입력과 Server Authority 분리
- 서버 계산 D20·Attack·Damage·HP
- Character·Actor·Item Ownership과 Runtime Control 검증
- Command Idempotency와 System·Remote 경계
- Viewer별 Projection과 DM 정보 Negative Disclosure
- Snapshot·Migration·DataStore·Reconnect baseline
- Projection Gap 감지와 Full Resync
- `_G`·`shared` 숨은 전역 금지
- UI Component의 Remote 직접 호출 금지

## 2. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | 53개 Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI | Structure·Policy·Security Validator 성공 |
| 4 | IN_PROGRESS | Luau·Rojo Toolchain 검증 | Build·Type Check·Formatter·Linter 실제 실행 |
| 5 | QUEUED | Roblox Studio Test Host | `test.project.json` 동기화와 Test Runner 실행 |
| 6 | QUEUED | Slice 01 Studio Acceptance | Join→Select→Ready→Scene→Move→Reconnect |
| 7 | QUEUED | Slices 02–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 8 | QUEUED | DataStore·Restart Recovery | 실제 API·Lease·Migration·Restart 검증 |
| 9 | QUEUED | UI Visual·Accessibility QA | Policy Checklist와 실제 화면 검수 |
| 10 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 3. 완료 해석

`IMPLEMENTED_UNVERIFIED`는 16개 계약을 실행 가능한 Roblox Source 구조와 서버 권위 흐름으로 옮기고 정적 검증을 통과했다는 뜻이다.

다음을 의미하지 않는다.

- Roblox Studio에서 정상 실행됨
- 실제 DataStore와 재시작 복구가 검증됨
- 전체 D&D 2024 공식 데이터가 포함됨
- UI가 최종 픽셀 품질로 완성됨
- Production Ready 또는 Release Ready

## 4. 현재 Blocker

- 현재 환경에서 Roblox Studio 실행 불가
- Luau compiler·Rojo·StyLua·Selene 실제 실행 Evidence 없음
- 멀티클라이언트·Streaming·Physics·Navigation Evidence 없음
- 실제 DataStore API·서버 재시작 Evidence 없음
- 공식 D&D 데이터의 Source Version·Rights Review 없음
- 성능·메모리·네트워크·장시간 Soak 측정 없음

## 5. 다음 Gate

```text
Rojo Build·Luau Typecheck
→ 정적 오류 수정
→ Studio Test Runner
→ Slice 01 Acceptance
→ Slice별 Build Acceptance Audit
→ Full-session Release Hardening
```

Studio Evidence가 생기기 전까지 상태는 `IMPLEMENTED_UNVERIFIED`를 유지한다.
