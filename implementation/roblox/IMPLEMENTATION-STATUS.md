# RVTT Production Implementation Status

- 상태: `GRAND_PERSISTENCE_OUTAGE_LEASE_HOST_STATIC_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice Runtime baseline, Grand Acceptance Campaign, Slices 02–12 자동 Authority Scenario, Deterministic Fault Host, Real Transport·Restart·Injected Outage·Cross-server Lease Pair Host
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 구현된 공통 계약

- Versioned Command Envelope·Authorization·Transaction·Idempotency
- 서버 권위 Revision·AuthorityEpoch·Projection·Negative Disclosure
- Character·Actor·Item Ownership·Rules·D20·HP
- Projection Gap·Full Resync·이전 Epoch Packet 폐기
- Terminal Receipt 유실 Bounded Retry·Timeout·Pending 정리
- Migration·ProfileStore·Persistence Coordinator
- Shutdown-only Dirty Snapshot·Bounded `BindToClose` Retry
- Lease Store·Coordinator·Expiry·Fencing Token
- 실제 Player Lifecycle Disconnect·Reconnect Host
- Restart Seed·Verify Host
- Injected DataStore Outage Recovery Host
- Cross-server Lease Holder·Contender Pair Host
- Semantic Input·Client Runtime·Token 기반 UI Shell
- 16개 Slice Domain Command baseline

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

Camera WASD·Middle-button·Frame Correction
→ IMPLEMENTED · LATEST STUDIO RETEST PENDING
```

새 Outage·Lease Host를 포함한 Grand Runtime Evidence는 아직 없다.

## Grand Acceptance 실행 환경

```text
grand-single-client
→ Unit·Integration·Slices 02–12
→ Cross-slice·Authority Fault
→ Deterministic Network·Storage Fault
→ Persistence Retry·Lease Unit Spec
→ Capacity·Slice 01 Input

grand-multi-client
→ DM·Player·Observer Authority·Projection

grand-real-transport
→ 실제 Player 종료·Replacement Client·Full Sync

grand-persistence-live
→ Live DataStore Baseline

grand-persistence-restart-seed
→ BindToClose Checkpoint

grand-persistence-restart-verify
→ Fresh Server Restore·Epoch 교체

grand-persistence-outage
→ 주입 장애 고갈·Dirty 보존·실제 DataStore 복귀

grand-persistence-lease-pair
→ Holder·Contender 두 Studio 동시 실행·Fencing Takeover
```

Runner는 `studio-published-pair`에서 서로 다른 두 Place를 열고 두 Summary를 독립 판정한다.

## Injected DataStore Outage Host

`datastore-outage.project.json`은 게시된 Studio와 API Access를 전제로 한다.

- 실제 `ProfileStore`와 임시 DataStore Key를 사용한다.
- 장애 구간에는 `GetAsync`·`UpdateAsync` 호출 전에 retryable `PERSISTENCE_FAILED`를 주입한다.
- Save Retry가 고갈돼도 Dirty Snapshot과 이전 Saved Revision을 보존한다.
- 장애 해제 뒤 같은 Dirty Snapshot을 실제 DataStore에 저장한다.
- 실제 재로드로 Revision·AuthorityEpoch를 확인한다.
- Integration Key를 정리한다.

이 Host는 Roblox 서비스 자체 장애를 발생시키거나 증명하지 않는다.

## Lease Store·Coordinator

Production Persistence 모듈에 다음 계약을 추가했다.

```text
LeaseRecord
→ ownerId
→ token
→ expiresAt
→ fencingToken
```

- 최초 획득은 Fencing Token 1이다.
- 활성 소유자가 있으면 Contender는 retryable `LEASE_HELD`다.
- Renew는 동일 Fencing Token으로 만료 시각만 연장한다.
- 만료 뒤 Takeover는 Fencing Token을 증가시킨다.
- 이전 소유자의 Renew·Verify·Release는 `LEASE_LOST`, `LEASE_EXPIRED` 또는 `LEASE_NOT_HELD`로 종료한다.
- DataStore 호출 실패는 retryable `PERSISTENCE_FAILED`다.

## Cross-server Lease Pair Host

`lease-holder.project.json`과 `lease-contender.project.json`은 동일한 실제 DataStore Lease Key를 사용한다.

```text
Holder Acquire
→ Contender LEASE_HELD
→ Holder Renew
→ Contender LEASE_HELD
→ Holder Renew 중단·Expiry
→ Contender Higher Fencing Token Takeover
→ 이전 Holder Verify·Release 거부
→ Contender Release·Integration Key Cleanup
```

Summary:

```text
[RVTT Lease Holder] result=PASS ... renewals=1 takeovers=1
[RVTT Lease Contender] result=PASS ... blocked=2 takeovers=1
```

두 Host는 정적·Build·Type 검증만 완료했으며 실제 두 Studio Runtime PASS는 없다.

## 완료 의미

```text
SLICES 02–12 + DETERMINISTIC FAULT
+ REAL TRANSPORT/RESTART
+ INJECTED OUTAGE/CROSS-SERVER LEASE PAIR
→ SOURCE·FORMAT·LINT·BUILD·TYPE VERIFIED
→ NEW STUDIO RUNTIME NOT YET EXECUTED
→ PRODUCTION SERVERBOOT LEASE OWNERSHIP NOT YET CONNECTED
```

현재 Lease 모듈과 Pair Host는 동시 소유권 계약을 검증하지만 Production `ServerBoot`의 Campaign Load·Command Commit·Save 경로는 아직 Lease를 획득하거나 Fencing Token을 검증하지 않는다.

## 다음 Production 통합

- `ServerBoot` 시작 시 Campaign Lease Acquire
- Lease 미획득 서버의 Authority Command 차단
- Renew Loop와 Grace Window
- Commit·Flush 전 authoritative Lease Verify
- Fencing Token을 저장 문서 또는 별도 write fence에 연결
- Lease Lost 시 Dirty Flush 중단·진단·Server Degrade
- `BindToClose` Release
- 이전 서버의 지연 Save 차단
- 이 통합에 대한 Unit·Integration·Published Pair Evidence

## 일반 기능과 Persistence 분리

일반 Grand Run:

- 입력·카메라·Token 이동
- Slices 02–12 메모리 Authority Scenario
- Cross-slice·Deterministic Fault·Capacity
- Multi-client·Real Player Transport

Persistence Grand Run:

- Live DataStore
- Restart Seed·Verify
- Injected Outage Recovery
- Cross-server Lease Pair
- 향후 Production Boot Lease·Fenced Save

## 자동 Gate

- Grand Contract Validator: PASS
- Structure·Security·Policy Validator: PASS
- PowerShell Parser·Runner SelfTest: PASS
- StyLua: PASS
- Selene: PASS
- 13개 등록 Rojo Project Build: PASS
- Production·Test Luau Type Analysis: PASS
- Documentation Validation: PASS

위 결과는 Source·Build·Type Evidence이며 실제 Studio Phase PASS를 대신하지 않는다.

## 아직 미검증

- 최신 Slice 01 Camera 실제 입력
- Grand Runner 실제 사용자 PC 순차 실행과 Log 수집
- Slices 02–12 전체 사용자·Disclosure·Recovery
- Real Transport Client 종료·Replacement Client
- Restart Seed·Verify Published DataStore
- Injected Outage Published DataStore
- Cross-server Lease Pair 두 Studio 동시 실행
- Production ServerBoot Lease Ownership·Fenced Save
- Roblox 실제 Remote Throttle·플랫폼 DataStore 장애
- UI Visual Redesign·Accessibility Human Review
- 성능 Budget·Memory·Network·장시간 Soak
- Full-session Release Runbook

## 현재 Gate

```text
Grand Outage·Lease Host Static Gate
→ PASS

Production ServerBoot Lease Ownership·Fenced Persistence
→ IMPLEMENTATION IN PROGRESS

Grand Persistence Runtime
→ USER EXECUTION DEFERRED

Human UI·Soak
→ QUEUED

Full Grand Campaign
→ BLOCKED UNTIL TARGET PHASES READY
```
