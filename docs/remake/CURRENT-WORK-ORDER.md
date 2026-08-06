# RVTT Remake 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Planning·Implementation Work Order
- 최종 갱신일: 2026-08-06
- Architecture 완료 근거: [`Runtime Architecture Completion 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 전체 Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- UI·UX Policy: [`ui/policies/README.md`](ui/policies/README.md)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)
- Production Work Order: [`Roblox Implementation Work Order`](../../implementation/roblox/CURRENT-WORK-ORDER.md)
- Grand Campaign: [`Grand Acceptance Campaign`](../../implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md)

이 문서는 RVTT 리메이크의 기획·명세·Policy·구현 순서를 관리하는 상위 기준이다.

## 1. 현재 단계 요약

```text
Product·Architecture·ADR
→ DONE

Main System Guide·Player·DM User Guide
→ DONE

16 Slice Specification·UI Policy
→ DONE

16 Slice Production Source Baseline
→ IMPLEMENTED

Static·Toolchain CI
→ PASSED

Historical Roblox Studio Runtime Baseline
→ VERIFIED

Grand Runner·Manifest·Grouped Runs·Report
→ IMPLEMENTED · STATIC VERIFIED

Slices 02–12·Cross-slice·Authority Fault·Capacity
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Deterministic Network·Storage Fault
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Real Player Disconnect·Reconnect·Server Restart
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Injected DataStore Outage·Cross-server Lease Pair
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

현재 작업
→ Production ServerBoot Lease Ownership·Fenced Persistence 연결
```

## 2. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Product·Architecture·ADR | Runtime·Domain·Integration 권위 계약 완료 |
| 2 | DONE | Main System Guides·User Guides | Player·DM Flow와 System Guide 완료 |
| 3 | DONE | Implementation Slice Roadmap | 16개 Slice 정의·완전성 감사 |
| 4 | DONE | All-slice Specification Checkpoints | 16개 Package·Audit와 Recovery Checkpoint |
| 5 | DONE | UI·UX Global Policy Foundation | Policy·Checklist·Completion Audit |
| 6 | DONE | Production Workspace·Source Baseline | Shared·Server·Client·UI·Test Source 존재 |
| 7 | DONE | Static·Toolchain Validation | Structure·Security·StyLua·Selene·Rojo·Luau 성공 |
| 8 | DONE | Historical Studio Runtime Baseline | Unit·DataStore·3-client 기본 Evidence |
| 9 | DONE | Grand Runner Foundation | Grouped Run·Log Collection·Report |
| 10 | DONE | Slices 02–12 Automated Baseline | Domain Authority·거부·Restore 대표 Scenario |
| 11 | DONE | Cross-slice·Authority Fault·Capacity | Full-session State·Stale/Epoch·측정 Sample |
| 12 | DONE | Deterministic Fault Host | Network·Storage 결정적 장애 계약 |
| 13 | DONE | Real Transport·Restart Host | 실제 Player Lifecycle·Shutdown Retry·두 서버 Restore |
| 14 | DONE | DataStore Outage·Lease Pair Host | 주입 장애 복구·Lease Fencing·두 Studio Pair 등록 |
| 15 | IN_PROGRESS | Production Lease Ownership Integration | ServerBoot Acquire·Renew·Verify·Release·Fenced Save |
| 16 | QUEUED | Grand Persistence Milestone | Live·Restart·Outage·Lease·Production Ownership 일괄 실행 |
| 17 | QUEUED | Human UI·Accessibility | Checklist·Screenshot Reference·Visual Redesign Gate |
| 18 | BLOCKED | Slices 13–15 Content Acceptance | Source Version·Rights·Distribution·Asset 승인 필요 |
| 19 | QUEUED | Performance·Soak | Budget·다중 Client·장시간 Session Evidence |
| 20 | QUEUED | Full Grand Runtime | Target Phase가 READY인 Milestone에서 사용자 실행 1회 |
| 21 | BLOCKED | Release Hardening | Build·Migration·Fault·Soak·Runbook Evidence 필요 |

## 3. Fault Host 확장 결과

### Deterministic Fault

- Projection Drop·Duplicate·Reorder·Gap·Full Resync
- 지연된 이전 AuthorityEpoch 폐기
- Receipt 유실·Bounded Retry·Timeout
- Storage Failure·Ack Loss·Revision Conflict·External Winner

### Real Transport·Restart

- 실제 `PlayerRemoving`·`PlayerAdded`
- 같은 논리 사용자 재접속·Membership 중복 방지
- Shutdown-only Dirty Snapshot
- `BindToClose` Retry·Deadline
- 새 서버 Restore·Epoch 교체·이전 Epoch 거부

### Injected Outage

- Production Adapter 호출 전 retryable 장애 주입
- Save Retry 고갈·Dirty State 보존
- 장애 해제 후 실제 DataStore Save·Reload
- Roblox 플랫폼 자체 장애 Evidence는 아님

### Cross-server Lease Pair

- Holder·Contender가 동일한 실제 DataStore Lease Key 사용
- 활성·갱신 Lease에서 Contender 두 번 차단
- 만료 후 더 높은 Fencing Token Takeover
- 이전 Holder Verify·Release 거부
- 서로 다른 두 Place를 하나의 Pair Run에서 독립 판정

모든 신규 Host는 Source·Format·Lint·13개 Rojo Build·Luau Type·Grand Contract 검증을 통과했다. 새 Studio Runtime Evidence는 없다.

## 4. 현재 Production 공백

Lease Store·Coordinator와 Pair Host는 구현됐지만 Production `ServerBoot`는 아직 다음을 수행하지 않는다.

- Campaign Lease Acquire
- 주기적 Renew와 Grace Window
- Command·Flush 전 Lease Verify
- Fencing Token 기반 지연 Save 차단
- Lease Lost 시 Authority Degrade
- `BindToClose` Release

따라서 Cross-server Lease Host의 정적 PASS를 Production 동시 서버 보호 완료로 해석하지 않는다.

## 5. Grand Acceptance 운영

```text
기능·복구·보안·성능 변경 축적
→ 자동 Gate
→ Grand Manifest 등록
→ 하나의 Windows PowerShell 실행
→ Grouped·Paired Studio Runs
→ 모든 실패 수집
→ Root Cause별 수정 Batch
→ 전체 Grand Campaign 재실행
```

현재 실행 그룹:

- `grand-single-client`: Unit·Slices 02–12·Cross-slice·Fault·Capacity·Slice01
- `grand-multi-client`: DM·Player·Observer Authority·Projection
- `grand-real-transport`: 실제 Client 종료·Replacement Client
- Grand Persistence: Live·Restart Seed·Verify·Injected Outage·Lease Pair

## 6. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. 자동 Gate 실패 상태에서는 사용자 Studio 실행을 요청하지 않는다.
3. Studio Evidence 없이 Runtime PASS를 주장하지 않는다.
4. 주입 장애를 Roblox 플랫폼 장애로 표현하지 않는다.
5. Lease Primitive·Host와 Production Boot 연결 상태를 분리한다.
6. Slices 02–12 자동 baseline을 전체 Slice Acceptance로 해석하지 않는다.
7. 저장 Schema 변경에는 Migration·Version·Last Known Good가 필요하다.
8. DataStore 검사는 Grand Persistence Milestone에서 한 번에 한다.
9. 성능 측정 전 임의 합격선을 확정하지 않는다.
10. Slices 13–15 공식 Content는 승인 전까지 Release 대상에 포함하지 않는다.
11. 공식 Monster Statblock은 승인된 원본을 그대로 사용하고 임의 CR·수치 재조정을 하지 않는다.
12. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 Authority로 사용하지 않는다.

## 7. 다음 단계 Gate

```text
Production ServerBoot Lease Ownership
→ Fenced Authority Save·Delayed Writer 차단
→ Grand Persistence Milestone
→ UI·Accessibility Human Evidence
→ Performance·Soak
→ Target Phase READY
→ Full Grand Campaign 사용자 실행 1회
→ 전체 실패 Root Cause 수정
→ Release Hardening
```
