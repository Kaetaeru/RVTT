# RVTT Remake 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Planning·Implementation Work Order
- 최종 갱신일: 2026-08-06
- 전체 Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)
- Production Work Order: [`Roblox Implementation Work Order`](../../implementation/roblox/CURRENT-WORK-ORDER.md)
- Grand Campaign: [`Grand Acceptance Campaign`](../../implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md)
- Production Lease Host: [`Production Lease Acceptance Host`](../../implementation/roblox/PRODUCTION-LEASE-ACCEPTANCE-HOST.md)

## 1. 현재 단계

```text
Product·Architecture·ADR·16 Slice Specification·UI Policy
→ DONE

Production Runtime·Domain·Client·UI·Test Source
→ IMPLEMENTED BASELINE

Static·Security·Formatter·Lint·Rojo·Luau Type
→ PASSED

Historical Studio Baseline
→ VERIFIED

Grand Runner·Manifest·Grouped/Paired Runs·Report
→ IMPLEMENTED · STATIC VERIFIED

Slices 02–12·Cross-slice·Fault·Capacity
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Real Transport·Restart·Outage·Lease Pair
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Production Lease Ownership·Atomic Fence Claim
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Production Lease Seed·Verify Acceptance Host
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

현재 작업
→ Grand Persistence Milestone 실행 계약 확정
```

## 2. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Product·Architecture·ADR | Runtime·Domain·Integration 계약 |
| 2 | DONE | Guides·16 Slice Specs·UI Policy | 사용자 Flow와 Acceptance 정의 |
| 3 | DONE | Production Source Baseline | Shared·Server·Client·UI·Test Source |
| 4 | DONE | Static·Toolchain Validation | Security·StyLua·Selene·Rojo·Luau |
| 5 | DONE | Historical Studio Baseline | Unit·DataStore·3-client Evidence |
| 6 | DONE | Grand Runner Foundation | Grouped Runs·Log Collection·Report |
| 7 | DONE | Slices 02–12 Automated Baseline | Authority·거부·Restore Scenario |
| 8 | DONE | Cross-slice·Fault·Capacity | 대표 Full-session·Fault·측정 Sample |
| 9 | DONE | Real Transport·Restart·Outage·Lease Pair | Lifecycle·Persistence Host |
| 10 | DONE | Production Lease Ownership | Acquire·Claim·Guard·Renew·Fenced Save |
| 11 | DONE | Production Lease Acceptance Host | 안전한 Seed·Verify Place와 Summary |
| 12 | IN_PROGRESS | Grand Persistence Milestone | 7개 Persistence Phase 실행 순서와 게시 안내 |
| 13 | QUEUED | Human UI·Accessibility | Checklist·Screenshot·Visual Gate |
| 14 | QUEUED | Performance·Soak | Budget·Memory·Network·장시간 Session |
| 15 | BLOCKED | Slices 13–15 Content | Rights·Distribution·Asset 승인 |
| 16 | QUEUED | Full Grand Runtime | 대상 Phase가 READY인 Milestone에서 실행 1회 |
| 17 | BLOCKED | Release Hardening | Migration·Fault·Soak·Runbook Evidence |

## 3. Production Lease Acceptance

```text
Seed
→ Acceptance Key Cleanup
→ 실제 ServerBoot Lease Acquire·Fence 1 Claim
→ Remote session.join·Authority Commit
→ Fenced Flush·Metadata·Release

Verify
→ Higher Fence Claim·Seed Membership Restore
→ Remote session.join
→ 이전 Fence Revision 99 저장 거부
→ Revision·Fence 불변
→ Fenced Flush·Release·Key Cleanup
```

Acceptance Mode는 별도 Store·Authority Key·Owner 접두사를 강제하므로 실제 Campaign Store를 사용하지 않는다.

## 4. Grand Persistence 순서

```text
Live DataStore
→ Restart Seed
→ Restart Verify
→ Injected Outage
→ Lease Holder·Contender Pair
→ Production Lease Seed
→ Production Lease Verify
```

DataStore 검사는 관련 변경을 축적한 뒤 이 Milestone에서 한 번에 한다. 일반 기능 테스트에서는 DataStore를 연결하지 않는다.

## 5. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. 자동 Gate 실패 상태에서는 사용자 Studio 실행을 요청하지 않는다.
3. Studio Evidence 없이 Runtime PASS를 주장하지 않는다.
4. 주입 장애를 Roblox 플랫폼 자체 장애로 표현하지 않는다.
5. 정적 Lease Host와 실제 Published Runtime Evidence를 분리한다.
6. Slices 02–12 자동 baseline을 전체 Slice 완료로 해석하지 않는다.
7. 성능 측정 전 임의 합격선을 확정하지 않는다.
8. Slices 13–15 공식 Content는 권리 승인 전까지 Release 대상에 포함하지 않는다.
9. 공식 Monster Statblock은 승인된 원본을 그대로 사용하고 임의 CR·수치 재조정을 하지 않는다.
10. 사용자 실행 명령은 완전한 다중 행 Windows PowerShell 블록으로만 제공한다.

## 6. 다음 Gate

```text
Grand Persistence 실행 계약
→ Human UI·Accessibility Evidence
→ Performance·Soak Host
→ Target Phase READY
→ Full Grand Campaign 사용자 실행 1회
→ 전체 실패 Root Cause 수정
→ Grand Campaign 전체 재실행
→ Release Hardening
```
