# RVTT Production Implementation Status

- 상태: `GRAND_PRODUCTION_LEASE_ACCEPTANCE_HOST_STATIC_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice Runtime baseline, Grand Acceptance Campaign, Fault·Transport·Restart·Outage·Lease Host, Production Lease Ownership과 Seed·Verify Acceptance Host
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- Production Lease Host: [`PRODUCTION-LEASE-ACCEPTANCE-HOST.md`](PRODUCTION-LEASE-ACCEPTANCE-HOST.md)

## 구현된 공통 계약

- Versioned Command Envelope·Authorization·Transaction·Idempotency
- Revision·AuthorityEpoch·Projection·Negative Disclosure
- Projection Gap·Full Resync·이전 Epoch 폐기
- Terminal Receipt 유실 Bounded Retry·Timeout·Pending 정리
- ProfileStore·Migration·Persistence Coordinator
- Shutdown-only Dirty Snapshot·Bounded `BindToClose` Retry
- Lease Store·Coordinator·Ownership State Machine
- Authority Document Atomic Fence Claim
- Remote·System Command Lease Guard
- Fenced Load·Save·Flush-before-Release
- Grand grouped·paired Studio Runner와 통합 Report
- Slices 02–12 자동 Authority Scenario
- Deterministic Network·Storage Fault Host
- Real Player Disconnect·Reconnect Host
- Restart Seed·Verify Host
- Injected DataStore Outage Host
- Cross-server Lease Holder·Contender Pair
- Production Lease Seed·Verify Acceptance Host

## Production Lease Acceptance Host

### Project Config

- `production-lease-seed.project.json`
- `production-lease-verify.project.json`
- 실제 Production `ServerBoot`, Command Router, Projection, ProfileStore와 Lease 계층 사용
- Acceptance 전용 Store·Key·Owner만 사용
- Studio 외 실행과 안전 접두사 위반을 `assert`로 차단

### Seed 검증

- 기존 Acceptance Key Cleanup
- Lease Acquire와 Fence 1 Claim
- 실제 Sync Projection
- 실제 Remote `session.join`
- Authority Revision Commit
- `BindToClose` Fenced Flush
- Seed Fence Metadata 저장
- Lease Release

### Verify 검증

- Higher Fence Claim
- Seed Membership Restore
- 실제 Remote `session.join`
- Seed Fence를 이용한 Revision 99 지연 저장 시도
- `PERSISTENCE_FENCED`
- 현재 Authority Revision과 Fence 불변
- Fenced Flush·Release
- 전용 Authority·Metadata·Lease Key Cleanup

### Summary 계약

```text
[RVTT Production Lease Seed] result=PASS failed=0 checks=true flush=true metadata=true release=true ...
[RVTT Production Lease Verify] result=PASS failed=0 checks=true flush=true release=true cleanup=true staleBlocked=true ...
```

두 Phase는 Grand Manifest에서 Seed→Verify 순서로 등록됐으며 `-IncludePersistence` 전용이다.

## Production ServerBoot Persistence

```text
Lease Acquire
→ Remote Verify
→ Atomic Fence Claim
→ Latest Document Load·Migration·Restore
→ Command Guard
→ Renew
→ Dirty Mark
→ Fenced Flush
→ Lease Release
```

- Lease 미획득 서버는 Authority 문서를 Load하지 않는다.
- Load·Migration·Restore 실패는 Fail-closed다.
- Persistence 준비 전이나 Lease Lost 뒤 Command를 차단한다.
- 이전 Fence와 Unfenced Writer는 `PERSISTENCE_FENCED`다.
- Higher Fence도 Revision·AuthorityEpoch 단조성 검사를 우회하지 않는다.
- Retryable Renew 장애는 Local Expiry 전까지만 Active다.
- Shutdown은 Renew 중단→Fenced Flush→Release 순서다.

## Grand 실행 환경

### 일반 기능

```text
grand-single-client
→ Unit·Integration·Slices 02–12·Cross-slice·Fault·Capacity·Slice01

grand-multi-client
→ DM·Player·Observer Authority·Projection

grand-real-transport
→ 실제 Player 종료·Replacement Client·Full Sync
```

### Persistence

```text
grand-persistence-live
grand-persistence-restart-seed
grand-persistence-restart-verify
grand-persistence-outage
grand-persistence-lease-pair
grand-production-lease-seed
grand-production-lease-verify
```

일반 Place는 DataStore를 사용하지 않는다. Persistence는 전용 Milestone에서만 일괄 실행한다.

## 자동 Gate

- Production Lease Contract Validator: PASS
- Production Lease Seed Place Build: PASS
- Production Lease Verify Place Build: PASS
- Grand Contract Validator: PASS
- Structure·Security·Policy: PASS
- Windows PowerShell Parser·Runner SelfTest: PASS
- StyLua·Selene: PASS
- 기존 등록 Place Build: PASS
- Production·Test Luau Type: PASS
- Documentation Validation: PASS

정적·Build·Type PASS를 실제 Studio Runtime PASS로 해석하지 않는다.

## 기존 Studio Evidence

```text
[RVTT Tests] passed=173 failed=0
[RVTT Live DataStore] passed=10 failed=0
[RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3
```

사용자 관측:

```text
Slice 01 Token Pick·Highlight·Destination·Movement
→ PASS

Server Acceptance·Projection Move
→ PASS · revision 72→73

Camera Zoom
→ PASS

Camera WASD·Middle-button·Frame
→ LATEST STUDIO RETEST PENDING
```

신규 Grand Scenario와 Production Lease Seed·Verify의 Studio Evidence는 아직 없다.

## 아직 미검증

- 최신 Slice 01 Camera 실제 입력
- Grand Runner의 실제 사용자 PC Log 수집
- Slices 02–12 전체 사용자·Disclosure·Recovery
- Real Transport Replacement Client
- Restart·Outage·Lease Pair Published Runtime
- Production Lease Seed·Verify Published Runtime
- Lease 미획득·Lease Lost 사용자 UX와 운영자 Recovery
- Roblox 실제 Remote Throttle·플랫폼 DataStore 장애
- UI Visual Redesign·Accessibility Human Review
- 성능 Budget·Memory·Network·장시간 Soak
- Full-session Release Runbook

## 현재 Gate

```text
Production Lease Acceptance Host Static Gate
→ PASS

Grand Persistence Milestone
→ EXECUTION CONTRACT IN PROGRESS

Grand Runtime
→ USER EXECUTION DEFERRED

Human UI·Soak
→ QUEUED

Full Grand Campaign
→ BLOCKED UNTIL TARGET PHASES READY
```
