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

Production ServerBoot Lease Ownership·Atomic Fence Claim
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

현재 작업
→ Production Lease Integration Acceptance Host
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
| 15 | DONE | Production Lease Ownership Integration | Acquire·Atomic Claim·Guard·Renew·Fenced Save·Release |
| 16 | IN_PROGRESS | Production Lease Acceptance Host | 안전한 Test Store·Key의 실제 ServerBoot Seed·Takeover·Stale Write Evidence |
| 17 | QUEUED | Grand Persistence Milestone | Live·Restart·Outage·Lease·Production Boot 일괄 실행 |
| 18 | QUEUED | Human UI·Accessibility | Checklist·Screenshot Reference·Visual Redesign Gate |
| 19 | BLOCKED | Slices 13–15 Content Acceptance | Source Version·Rights·Distribution·Asset 승인 필요 |
| 20 | QUEUED | Performance·Soak | Budget·다중 Client·장시간 Session Evidence |
| 21 | QUEUED | Full Grand Runtime | Target Phase가 READY인 Milestone에서 사용자 실행 1회 |
| 22 | BLOCKED | Release Hardening | Build·Migration·Fault·Soak·Runbook Evidence 필요 |

## 3. Persistence·Fault 확장 결과

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

### Injected Outage·Lease Pair

- Production Adapter 호출 전 retryable 장애 주입
- Save Retry 고갈·Dirty State 보존
- 장애 해제 후 실제 DataStore Save·Reload
- Holder·Contender 동일 Lease Key
- 활성·갱신 Lease에서 Contender 차단
- 만료 후 Higher Fencing Token Takeover
- 이전 Holder Verify·Release 거부

### Production Lease Ownership·Fenced Persistence

```text
Lease Acquire
→ Remote Verify
→ Authority Document Atomic Fence Claim
→ Latest Document Load·Restore
→ Remote·System Command Guard
→ Background Renew
→ Flush 전 Remote Verify·Write Fence
→ Fenced Save
→ BindToClose Flush-before-Release
```

- Claim은 Authority Document와 같은 `UpdateAsync`에서 `persistenceFence`를 기록한다.
- Claim 이후 이전 서버의 높은 Revision 지연 저장도 `PERSISTENCE_FENCED`로 거부한다.
- Higher Fence는 Revision 단조성 검사를 우회하지 않는다.
- Runtime Snapshot에서는 Persistence Fence Metadata를 제거한다.
- Lease Lost·Expiry·Not Held는 Command와 Persistence를 Fail-closed로 전환한다.
- 전용 `Validate production lease` Workflow가 순서·Spec·금지 우회를 강제한다.

모든 신규 Source는 Format·Lint·13개 Rojo Build·Luau Type·Production Lease Contract·Grand Contract 검증을 통과했다. 새 Studio Runtime Evidence는 없다.

## 4. 현재 Production 공백

Production Lease Source는 연결됐지만 실제 `ServerBoot` Acceptance는 아직 없다.

- 실제 Campaign Store를 건드리지 않는 Acceptance 전용 Store·Key 주입
- Seed Server의 Command Commit·Fenced Flush·Release
- 다음 Server의 Higher Fence Claim·Latest Restore
- 이전 Fence Revision 99 지연 Save 거부
- Integration Key Cleanup
- Lease 미획득·Lease Lost 사용자 UX

따라서 정적 PASS를 실제 다중 서버 Production 보호 완료로 해석하지 않는다.

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
- 향후 Production Lease Integration: 실제 ServerBoot Seed·Takeover

## 6. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. 자동 Gate 실패 상태에서는 사용자 Studio 실행을 요청하지 않는다.
3. Studio Evidence 없이 Runtime PASS를 주장하지 않는다.
4. 주입 장애를 Roblox 플랫폼 장애로 표현하지 않는다.
5. Lease Source·Static Gate와 실제 Production Boot Runtime Evidence를 분리한다.
6. Acceptance는 실제 Campaign Store·Key를 사용하지 않는다.
7. Slices 02–12 자동 baseline을 전체 Slice Acceptance로 해석하지 않는다.
8. 저장 Schema 변경에는 Migration·Version·Last Known Good가 필요하다.
9. DataStore 검사는 Grand Persistence Milestone에서 한 번에 한다.
10. 성능 측정 전 임의 합격선을 확정하지 않는다.
11. Slices 13–15 공식 Content는 승인 전까지 Release 대상에 포함하지 않는다.
12. 공식 Monster Statblock은 승인된 원본을 그대로 사용하고 임의 CR·수치 재조정을 하지 않는다.
13. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 Authority로 사용하지 않는다.

## 7. 다음 단계 Gate

```text
Production Lease Acceptance Store·Key Config
→ 실제 ServerBoot Seed·Fenced Flush·Release
→ Higher Fence Claim·Restore·Stale Write 거부
→ Grand Persistence Milestone
→ UI·Accessibility Human Evidence
→ Performance·Soak
→ Target Phase READY
→ Full Grand Campaign 사용자 실행 1회
→ 전체 실패 Root Cause 수정
→ Release Hardening
```
