# RVTT Roblox Implementation 현재 작업 순서

- 상태: `GRAND_ACCEPTANCE_FOUNDATION_IMPLEMENTED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- Grand Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)

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

Slice 01 Token Pick·Move·Projection
→ VERIFIED IN STUDIO

WASD·Middle-button·Frame Camera Correction
→ IMPLEMENTED · STUDIO PENDING

Grand Acceptance Manifest·Runner·Report
→ FOUNDATION IMPLEMENTED

현재 작업
→ Grand Campaign Phase Harness 확장
```

## 2. 테스트 운영 방식

기능 하나나 버그 하나마다 Studio를 다시 실행하지 않는다.

```text
관련 기능 구현
→ 자동 회귀 테스트·정적 CI
→ 해당 기능을 Grand Phase에 등록
→ 여러 Slice와 복구·보안 변경 축적
→ Grand Acceptance Campaign 한 번 실행
→ 전체 실패 수집
→ Root Cause별 수정 Batch
→ Grand Campaign 전체 재실행
```

사용자는 하나의 완전한 Windows PowerShell 블록을 한 번 실행한다. Runner는 여러 Place를 Build하고 Studio Phase를 순서대로 열며, Studio를 닫으면 다음 Phase로 진행한다.

## 3. Grand Campaign 현재 실행 범위

| 순서 | 상태 | Phase | 완료 조건 |
|---:|---|---|---|
| 1 | READY | Static Build | 등록된 모든 Rojo Project Build 성공 |
| 2 | READY | Unit·Integration Baseline | `[RVTT Tests] ... failed=0` 수집 |
| 3 | READY | Slice 01 World Interaction | 실제 입력 기반 16개 Check PASS |
| 4 | READY | Multi-client Authority | DM·Player·Observer Summary `failed=0` |
| 5 | DEFERRED | Live DataStore Baseline | Grand Persistence Milestone에서 실행 |
| 6 | DEFERRED | Persistence·Restart Recovery | Load·Save·Restart·Migration·Conflict 일괄 PASS |
| 7 | PLANNED | Slices 02–12 | Slice별 Harness·Summary 연결 |
| 8 | BLOCKED | Slices 13–15 Content | 공식 데이터·권리·Asset 승인 필요 |
| 9 | PLANNED | UI·Accessibility | Human Review 결과 구조화 수집 |
| 10 | PLANNED | Fault·Performance·Soak | 실제 Host와 측정 Evidence 필요 |
| 11 | PLANNED | Slice 16 Full Session | 전체 Phase와 Release Gate PASS |

아직 구현되지 않은 Phase는 Grand Report에서 `blocked`로 표시한다. 현재 실행 가능한 Phase가 PASS하더라도 전체 Campaign 결과는 Blocked Phase가 남아 있으면 `PARTIAL`이다.

## 4. 현재 구현 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Grand Manifest와 상태 모델 | READY·DEFERRED·PLANNED·BLOCKED Phase 등록 |
| 2 | DONE | Windows Grand Runner Foundation | Build·Studio 순차 실행·Log 수집·통합 Report |
| 3 | DONE | Runner Parser·SelfTest CI | Windows Parser와 Manifest SelfTest 성공 |
| 4 | IN_PROGRESS | Slice 01 Grand Phase 안정화 | WASD·중클릭·F·휠 실제 입력 Summary 수집 |
| 5 | QUEUED | Slice 02 Rules·D20 Harness | Check·Attack·Save·Damage·Healing·Disclosure |
| 6 | QUEUED | Slice 03–12 Harness | 각 Slice 사용자·거부·복구 Scenario 연결 |
| 7 | DEFERRED | Persistence Grand Phase | DataStore 변경 축적 후 한 번에 구현·실행 |
| 8 | BLOCKED | Slices 13–15 Content Harness | Rights·Source Version·Distribution 승인 |
| 9 | QUEUED | UI·Accessibility Evidence | Checklist 결과와 Screenshot Reference 수집 |
| 10 | QUEUED | Fault·Performance Host | Drop·Duplicate·Restart·Soak·Capacity 측정 |
| 11 | QUEUED | Slice 16 Release Campaign | Full Session·Migration·Runbook Release Gate |

## 5. Studio 실행 규칙

- 자동 Gate가 실패한 상태에서는 Grand Campaign을 실행하지 않는다.
- Grand Campaign은 첫 실패에서 중단하지 않는다.
- 각 Studio Phase는 최종 Summary를 출력한 뒤 Studio를 닫는다.
- Runner가 최근 Roblox Log에서 Phase Summary를 수집한다.
- Summary 미발견은 PASS가 아니라 `incomplete`다.
- 일반 기능과 Persistence는 같은 보고서 안에서도 별도 Phase로 기록한다.
- Persistence는 `-IncludePersistence`가 명시된 Grand Milestone에서만 실행한다.
- 사용자에게는 저장소 Update·정확한 Head 검사·Runner 실행이 포함된 전체 PowerShell 블록만 제공한다.

## 6. 현재 Studio Evidence

```text
Unit·Integration
→ passed=173 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3

Slice 01 Token Pick·Move·Projection
→ PASS

Camera Zoom
→ PASS

Camera WASD·Middle-button·Frame
→ 최신 Correction Studio 재검증 전
```

기존 Camera 메서드 직접 호출로 생성된 Slice 01 `16/16 PASS`는 전체 사용자 흐름 Evidence로 사용하지 않는다.

## 7. 다음 Gate

```text
Grand Runner 자동 Gate
→ PASS 필요

현재 READY Phase를 Grand Campaign으로 실행
→ 아직 요청하지 않음

Slices 02–12 Harness 연결
→ 구현 진행

Persistence Grand Phase
→ 충분한 변경 축적 전까지 DEFERRED

Full Grand Campaign
→ 모든 Phase가 READY가 된 Milestone에서 한 번 실행
```
