# RVTT Production Implementation Status

- 상태: `GRAND_REAL_TRANSPORT_RESTART_HOST_STATIC_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice Runtime baseline, Grand Acceptance Campaign, Slices 02–12 자동 Authority Scenario, Deterministic Fault Host, Real Transport와 Two-run Restart Host
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 구현된 공통 계약

- Versioned Command Envelope와 재귀 Payload 제한
- 명시적 Command Authorization 필수 Registry
- 서버 권위 Transaction·Idempotency·Outbox·Projection
- Viewer별 Domain Projection과 DM 정보 Negative Disclosure
- Character·Actor·Item Ownership·Control 검증
- 서버 계산 D20·Attack·Damage·HP 변경
- AuthorityEpoch·Revision·Projection Gap·Full Resync
- 지연된 이전 AuthorityEpoch Projection 폐기
- Terminal Receipt 유실 Bounded Retry·Timeout·Pending 정리
- Migration·DataStore Adapter·Persistence Coordinator
- Shutdown-only Dirty Snapshot과 Bounded `BindToClose` Retry
- 실제 Player Lifecycle 기반 Disconnect·Reconnect Acceptance Host
- 두 Studio Server 실행을 잇는 Restart Seed·Verify Host
- Semantic Input·Client Runtime·Token 기반 UI Shell
- Roblox 기본 Avatar와 RVTT Token 분리
- 16개 Slice Domain Command baseline
- Unit·Integration·Security·Disclosure·Fault Test Source

## 기존 Studio Evidence

```text
[RVTT Tests] passed=173 failed=0
[RVTT Live DataStore] passed=10 failed=0
[RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3
```

추가 사용자 관측:

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

기존 Camera Harness의 직접 메서드 호출로 생성된 Slice 01 `16/16 PASS`는 실제 입력 Evidence에서 철회했다.

## Grand Acceptance 구현

```text
Grand Manifest
→ IMPLEMENTED

Grouped Windows Runner
→ IMPLEMENTED

Shared Studio Run via runId
→ IMPLEMENTED

Recent Roblox Log Summary Collection
→ IMPLEMENTED

JSON·Markdown Consolidated Report
→ IMPLEMENTED

Grand Single-client Place
→ IMPLEMENTED · DATASTORE DISABLED

Grand Multi-client Place
→ REGISTERED

Real Transport Local Server Place
→ REGISTERED · STUDIO NOT EXECUTED

Restart Seed·Verify Places
→ REGISTERED · PERSISTENCE MILESTONE ONLY · STUDIO NOT EXECUTED

Actual Grand Campaign Runtime
→ NOT YET EXECUTED
```

Runner는 첫 실패에서 중단하지 않고 가능한 모든 선택 Phase를 끝까지 실행한다. 결과는 `pass`, `fail`, `incomplete`, `prepared`, `blocked`로 분리한다.

## Grand Single-client 자동 Scenario

한 번의 Studio Play에서 기존 Unit·Integration과 함께 다음 Spec을 실행하도록 등록했다.

### Slice baseline

- Slice 02 — Ability Check·Save·Attack·HP·Authorization·Idempotency
- Slice 03 — Interaction·Locked/Hidden Object·Search·Knowledge·Fog·Restore
- Slice 04 — Encounter Lifecycle·Turn·Action·Rollback·End·Restore
- Slice 05 — Draft·Ownership·Activation·Level Up·Restore
- Slice 06 — Item Create·Move·Equip·Drop·Restore
- Slice 07 — Clock·Schedule·Activity·Completion·Restore
- Slice 08 — UI Preference Validation·User Isolation·Restore
- Slice 09 — Journal Ownership·Edit·Link·Ping·Restore
- Slice 10 — Source·Compile·Candidate Invalidation·Publish·Restore
- Slice 11 — Control·Quick Action·Runtime Patch·Recovery Request·Restore
- Slice 12 — Pack Rights·Dependency·Activation·Localization·Restore

### Grand authority·capacity scenario

- Cross-slice Full-session State 연결과 Snapshot Restore
- Stale Revision·Stale Epoch·Invalid Payload·Duplicate Replay
- Corrupt Snapshot 거부와 Runtime 보존
- Restore 후 AuthorityEpoch 갱신과 이전 Epoch 폐기
- Capacity Sample: Object 32·Item 32·Document 16
- Capacity `elapsedMs`와 `restoreMs` Evidence

### Deterministic network fault scenario

- Projection Drop 뒤 Gap 감지와 Full Resync
- Duplicate Projection 무시
- Hold·Reorder·Release 뒤 Sequence 복구
- 새 Epoch 전환 뒤 지연된 이전 Epoch Packet 거부
- Terminal Receipt 유실 뒤 동일 Command ID 재전송
- 최대 3회 전송과 8초 Timeout
- retryable `CLIENT_TIMEOUT`과 Pending 정리

### Deterministic storage fault scenario

- Transient Load Failure와 재시도
- Commit 전 Save Failure와 Dirty Snapshot 보존
- Commit 뒤 Ack Loss와 동일 Revision·Epoch 멱등 재저장
- Revision Conflict와 External Winner 보존
- 더 높은 Revision으로 Reconcile
- Invalid Load Revision의 Saved Revision 승격 방지

### Persistence retry scenario

- Shutdown-only Dirty Snapshot
- Retryable Save Failure 뒤 성공
- 최대 Attempt 제한
- Deadline과 지수 Backoff
- Non-retryable Failure 즉시 종료
- Retry Exhaustion 시 Dirty State 보존

구조화 로그:

```text
[RVTT Spec Summary] id=<id> result=PASS|FAIL passed=<n> failed=<n>
[RVTT Spec Failure] <id>: <failure>
[RVTT Fault Host] kind=network ...
[RVTT Fault Host] kind=storage ...
[RVTT Persistence Retry] result=RETRYING|PASS|EXHAUSTED ...
[RVTT Tests] passed=<n> failed=<n>
```

## Real Transport Acceptance

`real-transport.project.json`은 Production ServerBoot를 복제하지 않고 같은 Production Runtime·CommandRouter·ProjectionPublisher를 직접 조립한다.

검사 흐름:

```text
Local Server + 3 Clients
→ DM·Player·Observer 논리 사용자 배정
→ 실제 Player Client 종료
→ PlayerRemoving
→ Connection=disconnected
→ Replacement Client 추가
→ PlayerAdded
→ 같은 논리 사용자 재가입
→ Full Sync 검증
```

완료 계약:

- Physical Player Instance 교체
- Membership 수 3 유지
- Connection State 복구
- 같은 서버 AuthorityEpoch 유지
- Projection Sequence 증가
- 중복 Membership 없음
- `[RVTT Real Transport] result=PASS ... reconnects=1`

## Two-run Restart Acceptance

### Seed

- 전용 DataStore Key 초기화
- Membership·Connection State 생성
- 자동 5초 Flush 없이 Dirty Snapshot 유지
- Studio 종료 시 `BindToClose`
- Retry Policy를 사용해 Shutdown Checkpoint 저장
- `[RVTT Restart Seed] result=PASS ...`

### Verify

- 새 Studio Server가 같은 DataStore 문서 Load
- Authority Runtime Restore
- Revision 유지
- AuthorityEpoch 교체
- 이전 Epoch Command `STALE_EPOCH`
- 현재 Epoch Command 1회 Commit
- Post-restart Snapshot 저장
- Test Key 정리
- `[RVTT Restart Verify] result=PASS ...`

이 두 Phase는 게시된 Experience와 Studio API Access가 필요한 Grand Persistence Milestone에서만 선택한다.

## Production 복구 보강

### Projection Replica

- 최근 AuthorityEpoch 이력을 제한된 크기로 보존한다.
- 현재 Epoch와 다른 Packet이 이미 처리한 이전 Epoch라면 폐기한다.
- 동일 또는 이전 Projection Sequence는 False Gap 없이 무시한다.
- 실제 Sequence Gap은 Full Resync 전까지 현재 연속 Snapshot을 유지한다.

### Command Client

- Terminal Receipt가 유실되면 원본 Envelope와 Command ID를 재사용한다.
- 1.5초 간격으로 최대 3회 전송한다.
- 제출 후 8초가 지나면 retryable `CLIENT_TIMEOUT` Terminal 상태를 생성한다.
- 실제 Terminal Receipt 또는 Timeout 뒤 Pending 상태를 제거한다.

### Persistence Coordinator

- 기본 종료 Retry는 최대 5회다.
- Backoff는 0.25초에서 시작해 최대 2초다.
- 전체 Deadline은 25초다.
- Retryable Failure만 재시도한다.
- Non-retryable Failure와 Attempt·Deadline 고갈은 명시적으로 종료한다.
- 실패 시 Dirty Snapshot을 유지한다.
- `scheduleFlush=false`로 Shutdown-only Snapshot을 만들 수 있다.

## 완료 의미

현재 자동 Harness 상태는 다음과 같다.

```text
SLICES 02–12 + DETERMINISTIC FAULT + REAL TRANSPORT/RESTART HOST
→ SOURCE·FORMAT·LINT·BUILD·TYPE VERIFIED
→ NEW STUDIO RUNTIME NOT YET EXECUTED
→ FORCED OUTAGE·CROSS-SERVER LEASE·FULL ACCEPTANCE NOT COMPLETE
```

실제 Player Disconnect·Reconnect와 Server Restart 검증 환경은 등록됐지만 Studio Runtime PASS는 아직 없다. Roblox Remote Throttle, 강제 DataStore Outage, Cross-server Lease·Conflict, Human Accessibility와 Soak Evidence는 남은 Gate다.

## 일반 기능과 Persistence 분리

일반 Grand Run:

- 입력·카메라
- Token 선택·이동
- Slices 02–12 메모리 내 Authority Scenario
- Cross-slice·Authority Fault·Deterministic Network/Storage Fault·Capacity Sample
- 기존 Multi-client Projection
- Real Player Disconnect·Reconnect Local Server Host

Persistence Grand Run:

- Live DataStore Baseline
- Restart Seed `BindToClose` Save
- Fresh Server Restart Verify
- Migration·Lease·Conflict
- DataStore Throttle·Outage Recovery

Persistence는 관련 변경을 축적한 뒤 `-IncludePersistence`로 한 번에 실행한다.

## Content Blocker

Slices 13–15는 Runtime과 Rights Gate Source는 존재하지만 공식 데이터를 포함하지 않는다.

- 승인된 Source Version
- 권리와 배포 범위
- Localization·Asset 승인
- Package·Catalog 등록

위 조건 전에는 공식 Character·Spell·Item·NPC·Monster Content를 Grand PASS 대상으로 등록하지 않는다. Monster는 승인된 공식 원본 Statblock을 그대로 사용하며 임의 CR·수치 재조정을 하지 않는다.

## 자동 Gate

- Grand Contract Validator: PASS
- Structure·Security·Policy Validator: PASS
- PowerShell Parser: PASS
- Runner SelfTest: PASS
- StyLua: PASS
- Selene: PASS
- Production·Test·Grand Single-client·Multi-client·Real Transport·Persistence·Restart Seed·Restart Verify·Slice01 Rojo Build: PASS
- Production·Test Luau Type Analysis: PASS
- Documentation Validation: PASS

위 결과는 정적·Build Evidence다. 실제 Studio Phase PASS를 대신하지 않는다.

## 아직 미검증

- 최신 Slice 01 Camera WASD·Middle-button·Frame 실제 입력
- Grand Runner의 실제 사용자 PC 순차 Studio 실행과 Log 수집
- Slices 02–12 전체 사용자·Disclosure·Recovery Scenario
- Real Transport Host의 실제 Player 창 종료·Replacement Client 추가
- Restart Seed·Verify의 게시 Experience DataStore 실행
- Roblox 실제 Remote 지연·제한·대역폭 Throttle
- 강제 DataStore Outage·Cross-server Lease·동시 Conflict
- Slices 13–15 공식 데이터·권리·Asset
- Navigation·Physics·Streaming·Large Scene
- UI Visual Redesign·Accessibility Human Review
- 실제 성능 Budget·Memory·Network·장시간 Soak
- Full-session Release Runbook

## 현재 Gate

```text
Grand Real Transport·Restart Host Static Gate
→ PASS

Grand Runtime
→ USER EXECUTION DEFERRED

Forced DataStore Outage·Cross-server Lease Host
→ IMPLEMENTATION IN PROGRESS

Persistence·Human UI·Soak
→ QUEUED

Full Grand Campaign
→ BLOCKED UNTIL TARGET PHASES READY
```
