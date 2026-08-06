# RVTT Roblox Implementation 현재 작업 순서

- 상태: `GRAND_PERSISTENCE_EXECUTION_CONTRACT_READY`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- Grand Persistence: [`GRAND-PERSISTENCE-MILESTONE.md`](GRAND-PERSISTENCE-MILESTONE.md)
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

Grand Persistence Published Runner·Config·CI
→ IMPLEMENTED · EXECUTION CONTRACT READY

현재 작업
→ Human UI·Accessibility Evidence 계약
```

## 2. Grand Persistence Milestone

Grand Persistence는 일반 Grand Runner와 분리한다.

```text
로컬 Config의 Universe·Place ID 검증
→ 8개 Rojo Project를 전용 Acceptance Place에 업로드
→ 게시 Place를 Universe ID·Place ID로 실행
→ 7개 Run을 고정 순서로 진행
→ Summary·PASS Regex 수집
→ JSON·Markdown Report 생성
```

고정 순서:

1. Live DataStore Baseline
2. Restart Seed
3. Restart Verify
4. Injected DataStore Outage
5. Cross-server Lease Holder·Contender Pair
6. Production Lease Seed
7. Production Lease Verify

실제 Campaign Universe와 Campaign Store는 사용하지 않는다. 실제 ID가 들어간 `grand-persistence-config.json`은 로컬 전용이며 저장소에 커밋하지 않는다.

## 3. Production Lease Acceptance Host

```text
Seed
→ Acceptance Key Cleanup
→ Lease Acquire·Fence 1 Claim
→ Remote session.join·Authority Commit
→ Fenced Flush·Metadata·Release

Verify
→ Higher Fence Claim·Seed Membership Restore
→ Remote session.join
→ 이전 Fence Revision 99 저장 거부
→ Revision·Fence 불변
→ Fenced Flush·Release·Key Cleanup
```

성공 Summary:

```text
[RVTT Production Lease Seed] result=PASS failed=0 checks=true flush=true metadata=true release=true ...
[RVTT Production Lease Verify] result=PASS failed=0 checks=true flush=true release=true cleanup=true staleBlocked=true ...
```

## 4. 자동 Gate

- Production Lease Contract Validator
- Grand Contract Validator
- Grand Persistence Contract Validator
- PowerShell Parser·Runner SelfTest
- Structure·Security·Policy
- StyLua·Selene
- 등록된 Rojo Project Build
- Production·Test Luau Type
- Documentation Validation

자동 Gate는 Source·Build·Type Evidence이며 Studio Runtime PASS가 아니다.

## 5. 현재 Studio Evidence

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

## 6. 다음 구현 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Grand Runner Foundation | Grouped Runs·Log Collection·JSON/Markdown Report |
| 2 | DONE | Slices 02–12 Automated Baseline | Slice별 Authority Scenario |
| 3 | DONE | Cross-slice·Fault·Capacity | 대표 Full-session·Fault·측정 Sample |
| 4 | DONE | Real Transport·Restart·Outage·Lease Pair | 실제 Lifecycle와 Persistence Host 등록 |
| 5 | DONE | Production Lease Ownership | Acquire·Claim·Guard·Renew·Fenced Save·Release |
| 6 | DONE | Production Lease Acceptance Host | 안전한 Seed·Verify Place와 Summary 계약 |
| 7 | DONE | Grand Persistence Milestone | 게시 Place Mapping·Upload·순서·Evidence·Report 계약 |
| 8 | IN_PROGRESS | UI·Accessibility Evidence | Human Checklist·Screenshot Reference·판정 계약 |
| 9 | QUEUED | Performance·Soak Host | Budget·다중 Client·장시간 Session |
| 10 | BLOCKED | Slices 13–15 Content | Source Version·Rights·Distribution·Asset 승인 |
| 11 | QUEUED | Slice 16 Release Campaign | 전체 Phase·Migration·Runbook Gate |

## 7. 다음 Gate

```text
Grand Persistence 실행 계약
→ READY

Grand Persistence Runtime
→ 전용 Universe·8개 Place ID 준비 뒤 사용자 실행 가능

Human UI·Accessibility Evidence
→ IN PROGRESS

Performance·Soak Host
→ QUEUED

Full Grand Campaign
→ 대상 Phase가 READY인 Milestone에서 한 번 실행
```
