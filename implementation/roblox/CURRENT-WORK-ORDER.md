# RVTT Roblox Implementation 현재 작업 순서

- 상태: `GRAND_PRODUCTION_LEASE_ACCEPTANCE_HOST_STATIC_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- Grand Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
- Production Lease Host: [`PRODUCTION-LEASE-ACCEPTANCE-HOST.md`](PRODUCTION-LEASE-ACCEPTANCE-HOST.md)
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)

## 1. 현재 상태

```text
16개 Slice Production Source
→ IMPLEMENTED BASELINE

Static·Security·Formatter·Lint·Rojo·Luau Type
→ PASSED

Historical Roblox Studio Baseline
→ VERIFIED

Slice 01 Token Pick·Move·Projection
→ USER VERIFIED

Latest Camera WASD·Middle-button·Frame
→ IMPLEMENTED · STUDIO RETEST PENDING

Slices 02–12·Cross-slice·Deterministic Fault·Capacity
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Real Transport·Restart·Injected Outage·Lease Pair
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Production ServerBoot Lease Ownership·Atomic Fence Claim
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Production Lease Seed·Verify Acceptance Host
→ IMPLEMENTED · STATIC VERIFIED · PUBLISHED STUDIO NOT EXECUTED

현재 작업
→ Grand Persistence Milestone 실행 계약 확정
```

## 2. 테스트 운영 방식

기능 하나나 버그 하나마다 Studio를 다시 실행하지 않는다.

```text
관련 기능 구현
→ 자동 회귀·정적 CI
→ Grand Manifest 등록
→ 여러 Slice·복구·보안·성능 변경 축적
→ Grand Acceptance Campaign 한 번 실행
→ 모든 실패 수집
→ Root Cause별 수정 Batch
→ Grand Campaign 전체 재실행
```

사용자에게는 저장소 갱신, 정확한 Head 검사, Build와 Runner 실행을 포함한 완전한 다중 행 Windows PowerShell 블록만 제공한다.

## 3. Grand 실행 그룹

### 일반 기능

- `grand-single-client`
  - Unit·Integration·Slices 02–12
  - Cross-slice·Authority Fault
  - Deterministic Network·Storage Fault
  - Capacity Sample
  - Slice 01 실제 입력
- `grand-multi-client`
  - DM·Player·Observer Authority·Projection
- `grand-real-transport`
  - 실제 Player Client 종료·Replacement Client·Full Sync

### Grand Persistence

`-IncludePersistence` 전용 Milestone에서 다음을 순서대로 실행한다.

1. Live DataStore Baseline
2. Restart Seed
3. Restart Verify
4. Injected DataStore Outage
5. Cross-server Lease Holder·Contender Pair
6. Production Lease Seed
7. Production Lease Verify

일반 기능 Place에서는 DataStore를 연결하지 않는다.

## 4. Production Lease Acceptance Host

### 안전한 설정

```text
Authority Store
→ RVTT_ProductionLeaseAcceptance_Authority_v1

Lease Store
→ RVTT_ProductionLeaseAcceptance_Lease_v1

Authority Key
→ acceptance:production-lease:default
```

Acceptance Mode는 Studio와 위 Store·Key 접두사를 강제한다. 실제 Campaign Store·Key로는 실행할 수 없다.

### Seed

```text
전용 Key Cleanup
→ Production ServerBoot Lease Acquire
→ Atomic Fence Claim fence=1
→ 실제 Remote session.join
→ Authority Commit
→ BindToClose Fenced Flush
→ Seed Fence Metadata
→ Lease Release
```

### Verify

```text
Production ServerBoot Higher Fence Claim
→ Seed Membership Restore
→ 실제 Remote session.join
→ 이전 Seed Fence Revision 99 저장 시도
→ PERSISTENCE_FENCED
→ Authority Revision·Fence 불변
→ Fenced Flush·Release
→ 전용 Authority·Metadata·Lease Key Cleanup
```

성공 Summary:

```text
[RVTT Production Lease Seed] result=PASS failed=0 checks=true flush=true metadata=true release=true ...
[RVTT Production Lease Verify] result=PASS failed=0 checks=true flush=true release=true cleanup=true staleBlocked=true ...
```

## 5. Production Persistence 계약

```text
Lease Acquire
→ Remote Verify
→ Authority Document Atomic Fence Claim
→ Latest Document Load·Restore
→ Remote·System Command Guard
→ Background Renew
→ Commit Dirty Mark
→ Flush 전 Verify·Write Fence
→ BindToClose Fenced Flush
→ Lease Release
```

- Lease 미획득 서버는 Authority 문서를 Load하지 않는다.
- Persistence 준비 전이나 Lease Lost 뒤에는 Command를 실행하지 않는다.
- 이전 Fence, 동일 Fence의 다른 Identity, Unfenced Writer는 `PERSISTENCE_FENCED`다.
- Higher Fence도 Revision·AuthorityEpoch 단조성 검사를 우회하지 않는다.
- Shutdown은 Flush-before-Release다.

## 6. 자동 Gate 결과

- Production Lease Contract Validator: PASS
- Grand Contract Validator: PASS
- Structure·Security·Policy: PASS
- Windows PowerShell Parser·Runner SelfTest: PASS
- StyLua·Selene: PASS
- 등록된 기존 Place Build: PASS
- Production Lease Seed Place Build: PASS
- Production Lease Verify Place Build: PASS
- Production·Test Luau Type: PASS
- Documentation Validation: PASS

위 결과는 Source·Build·Type Evidence이며 Studio Runtime PASS가 아니다.

## 7. 현재 Studio Evidence

```text
[RVTT Tests] passed=173 failed=0 · HISTORICAL
[RVTT Live DataStore] passed=10 failed=0 · HISTORICAL
[RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3 · HISTORICAL

Slice 01 Token Pick·Move·Projection
→ USER VERIFIED

Camera Zoom
→ USER VERIFIED

Latest Camera WASD·Middle-button·Frame
→ RETEST PENDING

새 Grand·Persistence·Production Lease Host
→ NEW STUDIO EVIDENCE NONE
```

## 8. 다음 구현 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Grand Runner Foundation | Grouped Runs·Log Collection·JSON/Markdown Report |
| 2 | DONE | Slices 02–12 Automated Baseline | Slice별 Authority Scenario |
| 3 | DONE | Cross-slice·Fault·Capacity | 대표 Full-session·Fault·측정 Sample |
| 4 | DONE | Real Transport·Restart·Outage·Lease Pair | 실제 Lifecycle와 Persistence Host 등록 |
| 5 | DONE | Production Lease Ownership | Acquire·Claim·Guard·Renew·Fenced Save·Release |
| 6 | DONE | Production Lease Acceptance Host | 안전한 Seed·Verify Place와 Summary 계약 |
| 7 | IN_PROGRESS | Grand Persistence Milestone | 7개 Persistence Phase의 게시·순서·사용자 안내 확정 |
| 8 | QUEUED | UI·Accessibility Evidence | Human Checklist·Screenshot Reference |
| 9 | QUEUED | Performance·Soak Host | Budget·다중 Client·장시간 Session |
| 10 | BLOCKED | Slices 13–15 Content | Source Version·Rights·Distribution·Asset 승인 |
| 11 | QUEUED | Slice 16 Release Campaign | 전체 Phase·Migration·Runbook Gate |

## 9. 다음 Gate

```text
Production Lease Acceptance Host Static Gate
→ PASS

Grand Persistence Milestone 계약
→ IN PROGRESS

Grand Runtime
→ 사용자 실행 보류

UI·Accessibility·Soak
→ 이후 연결

Full Grand Campaign
→ 대상 Phase가 READY인 Milestone에서 한 번 실행
```
