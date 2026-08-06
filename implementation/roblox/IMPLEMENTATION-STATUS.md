# RVTT Production Implementation Status

- 상태: `GRAND_PRODUCTION_LEASE_FENCED_PERSISTENCE_STATIC_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice Runtime baseline, Grand Acceptance Campaign, Deterministic Fault·Real Transport·Restart·Outage·Lease Pair Host, Production ServerBoot Lease Ownership·Atomic Fence Claim
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
- Production Lease Ownership State Machine
- Authority Document Atomic Fence Claim
- Remote·System Command Lease Guard
- Fenced Load·Save·Flush-before-Release
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

Production Lease 통합을 포함한 새 Grand Runtime Evidence는 아직 없다.

## Grand Acceptance 실행 환경

```text
grand-single-client
→ Unit·Integration·Slices 02–12
→ Cross-slice·Authority Fault
→ Deterministic Network·Storage Fault
→ Persistence Retry·Production Lease Unit Spec
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

향후 grand-persistence-production-lease
→ 실제 ServerBoot Seed·Atomic Claim·Takeover·Stale Write Rejection
```

## Production ServerBoot Lease Ownership

Persistence가 활성화된 Production Boot는 다음 순서를 사용한다.

```text
Lease Acquire
→ Remote Lease Verify
→ Authority Document Atomic Fence Claim
→ Claimed Document Load·Migration·Restore
→ Command Guard 활성화
→ Background Renew
→ Commit Dirty Mark
→ Flush 전 Remote Verify·Write Fence
→ BindToClose Fenced Flush
→ Lease Release
```

### Acquire·준비 실패

- Lease를 얻지 못한 서버는 Authority 문서를 Load하지 않는다.
- Load·Migration·Restore 실패는 `persistenceStartupFailure`로 보존한다.
- Persistence 준비 전 Remote·System Command는 실행되지 않는다.
- 실패 뒤 Projection publish는 가능하지만 서버 권위 변경은 Fail-closed다.

### Atomic Fence Claim

`ProfileStore.loadFenced`는 Authority 문서를 읽기 전에 같은 `UpdateAsync`에서 `persistenceFence`를 Claim한다.

```text
persistenceFence
→ ownerId
→ token
→ fencingToken
```

- 기존 문서가 있으면 Revision·AuthorityEpoch·Domain State를 그대로 보존한다.
- 문서가 없으면 현재 Runtime Snapshot을 Revision 0 baseline으로 생성한다.
- 높은 Fencing Token만 이전 Claim을 인수할 수 있다.
- 낮은 Token, 같은 Token의 다른 Identity, Unfenced Writer는 `PERSISTENCE_FENCED`다.
- Claim 이후 이전 서버의 Revision 99 지연 저장도 거부된다.
- Runtime에 반환할 때 `persistenceFence`는 제거된다.
- 저장 메타데이터는 Domain Snapshot Schema와 분리된다.

### Revision 안전성

- 높은 Fence가 Revision 검사를 우회하지 않는다.
- 현재 소유자도 낮은 Revision을 저장하면 `PERSISTENCE_CONFLICT`다.
- 동일 Revision의 다른 AuthorityEpoch도 Conflict다.
- 새 소유자는 Claim된 최신 Revision을 Restore한 뒤 다음 Commit에서 단조 증가한다.

### Renew·Lease Lost

- 기본 TTL은 30초, Renew 주기는 10초다.
- Retryable DataStore Renew 실패는 Local Expiry 전까지만 Active 상태를 유지한다.
- `LEASE_LOST`, `LEASE_EXPIRED`, `LEASE_NOT_HELD`는 Command와 Persistence를 Degrade한다.
- `LeaseProtectedStore`는 Load·Save 직전에 Remote Lease Verify를 수행한다.

### Shutdown

```text
Renew Loop 중단
→ Dirty Snapshot Fenced Flush
→ 성공 또는 Bounded Retry 종료
→ 현재 Lease Release
```

Lease는 Flush보다 먼저 Release하지 않는다.

## 자동 회귀 Spec

- `CommandRouterGuard.spec` — Guard 실패 시 Runtime·Projection 차단과 Terminal Receipt
- `Lease.spec` — Acquire·Renew·Expiry·Takeover·Release·DataStore 장애
- `LeaseOwnership.spec` — Transient Renew·Terminal Loss·Shutdown 상태 전이
- `LeaseProtectedStore.spec` — Verify·Fence Claim Load·Fenced Save 경계
- `ProfileStoreFencing.spec` — Atomic Claim·Initial Document·Lower Fence·Delayed Revision 99 거부

`validate_production_lease.py`와 `Validate production lease` Workflow가 필수 파일·순서·Spec 문구를 독립적으로 강제한다.

## 기존 Persistence Host

### Injected DataStore Outage

- 실제 `ProfileStore`와 임시 DataStore Key를 사용한다.
- 장애 구간에는 호출 전 retryable `PERSISTENCE_FAILED`를 주입한다.
- Retry 고갈 뒤 Dirty Snapshot과 Saved Revision을 보존한다.
- 장애 해제 뒤 실제 DataStore에 저장하고 재로드한다.
- Roblox 서비스 자체 장애 Evidence는 아니다.

### Cross-server Lease Pair

```text
Holder Acquire
→ Contender LEASE_HELD
→ Holder Renew
→ Contender LEASE_HELD
→ Expiry
→ Higher Fencing Token Takeover
→ 이전 Holder Verify·Release 거부
```

Primitive Pair Host는 실제 두 Studio Runtime에서 아직 실행되지 않았다.

## 완료 의미

```text
PRODUCTION SERVERBOOT LEASE OWNERSHIP
+ ATOMIC AUTHORITY FENCE CLAIM
+ GUARDED COMMAND·LOAD·SAVE
+ FENCED FLUSH-BEFORE-RELEASE
→ SOURCE·FORMAT·LINT·BUILD·TYPE·CONTRACT VERIFIED
→ PUBLISHED STUDIO RUNTIME NOT YET EXECUTED
```

정적 PASS를 실제 다중 서버 Production 보호 완료나 Roblox 플랫폼 장애 PASS로 해석하지 않는다.

## 다음 Acceptance 통합

- Production Store·Authority Key·Lease Store를 Acceptance 전용 값으로 주입하는 Project Config
- 실제 `ServerBoot` Seed Run
- Command Commit·Fenced Flush·Lease Release
- 다음 Server의 Higher Fence Claim·Restore
- 이전 Fence를 사용한 지연 Save 거부
- 전용 DataStore Key Cleanup
- Grand Manifest Summary·Runner 등록

이 Host가 준비된 뒤 Live·Restart·Outage·Lease Pair·Production Boot를 하나의 Grand Persistence Milestone으로 실행한다.

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
- Production ServerBoot Lease·Atomic Claim·Fenced Save

## 자동 Gate

- Production Lease Contract Validator: PASS
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
- Production ServerBoot Lease Seed·Takeover·Fenced Save
- Lease 미획득·Lease Lost 사용자 UX와 운영자 Recovery
- Roblox 실제 Remote Throttle·플랫폼 DataStore 장애
- UI Visual Redesign·Accessibility Human Review
- 성능 Budget·Memory·Network·장시간 Soak
- Full-session Release Runbook

## 현재 Gate

```text
Production Lease·Atomic Fence Claim Static Gate
→ PASS

Production Lease Integration Acceptance Host
→ IMPLEMENTATION IN PROGRESS

Grand Persistence Runtime
→ USER EXECUTION DEFERRED

Human UI·Soak
→ QUEUED

Full Grand Campaign
→ BLOCKED UNTIL TARGET PHASES READY
```
