# RVTT Grand Acceptance Campaign

- 상태: `PRODUCTION_LEASE_FENCED_PERSISTENCE_STATIC_VERIFIED`
- 목적: 사용자가 한 번의 Windows PowerShell 실행으로 현재 실행 가능한 모든 Acceptance 환경을 순차 실행하고 하나의 결함 보고서를 얻는다.
- Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
- Runner: [`tooling/run-grand-acceptance.ps1`](tooling/run-grand-acceptance.ps1)
- Single-client Project: [`grand-single-client.project.json`](grand-single-client.project.json)
- Real Transport Project: [`real-transport.project.json`](real-transport.project.json)
- Restart Projects: [`restart-seed.project.json`](restart-seed.project.json), [`restart-verify.project.json`](restart-verify.project.json)
- Outage Project: [`datastore-outage.project.json`](datastore-outage.project.json)
- Lease Pair Projects: [`lease-holder.project.json`](lease-holder.project.json), [`lease-contender.project.json`](lease-contender.project.json)

## 1. 실행 모델

```text
PowerShell 실행 1회
→ 등록된 13개 Rojo Project Build
→ grand-single-client
→ grand-multi-client
→ grand-real-transport
→ 선택적 Grand Persistence
   → Live DataStore
   → Restart Seed
   → Restart Verify
   → Injected DataStore Outage
   → Lease Holder·Contender Pair
   → 향후 Production ServerBoot Lease Integration
→ JSON·Markdown 통합 보고서
```

Studio Run이 끝나면 Studio를 닫고 같은 PowerShell Process가 다음 Run을 시작한다.

## 2. `runId`와 Pair 계약

일반 Run은 같은 `runId`, `project`, `execution`을 공유하는 Phase를 한 Studio 실행으로 묶는다.

```text
grand-single-client
→ unit-integration-baseline
→ slice01-world-interaction

grand-real-transport
→ real-transport-reconnect
```

`studio-published-pair`는 예외적으로 같은 `runId`에서 서로 다른 정확히 두 Project를 허용한다.

```text
grand-persistence-lease-pair
→ lease-holder.project.json
→ lease-contender.project.json
```

Runner는 두 Studio 창을 열고 Holder를 먼저 Play한 뒤 Contender를 Play하도록 안내한다. 두 창이 닫히면 최근 Roblox Log를 합쳐도 각 Phase의 `summaryToken`과 `passRegex`는 독립적으로 판정한다.

## 3. 핵심 원칙

- 첫 실패에서 Campaign을 중단하지 않는다.
- 가능한 모든 Run을 끝까지 실행한다.
- Summary 미발견은 PASS가 아니라 `incomplete`다.
- 아직 실행하지 않은 Phase는 `blocked`, `deferred`, `prepared`로 분리한다.
- 일반 기능과 Persistence Evidence를 Phase 단위로 분리한다.
- 정적·Build·Type PASS를 Studio Runtime PASS로 해석하지 않는다.
- 주입 장애를 Roblox 플랫폼 실제 장애로 해석하지 않는다.
- Production Acceptance는 실제 Campaign Store·Key를 사용하지 않는다.
- 공식 Content Phase는 권리 승인 전까지 `blocked`다.
- 성능 측정 전 임의 합격선을 만들지 않는다.

## 4. 일반 Grand Run

### `grand-single-client`

- Unit·Integration·Security·Disclosure
- Slices 02–12 자동 Authority Scenario
- Cross-slice Session·Authority Fault
- Deterministic Network·Storage Fault
- Persistence Retry·Production Lease·Fence Unit Spec
- Capacity Sample
- Slice 01 실제 입력

### `grand-multi-client`

- DM·Player·Observer Authority
- 권한 없는 Command 거부
- Viewer별 Projection·Negative Disclosure
- Stale Revision Recovery

### `grand-real-transport`

```text
3 Clients 준비
→ Player Client 종료
→ PlayerRemoving·Connection=disconnected
→ Replacement Client 추가
→ PlayerAdded·Connection=connected
→ 같은 논리 사용자 재가입·Full Sync
```

PASS 로그:

```text
[RVTT Real Transport] result=PASS ... failed=0 ... reconnects=1
```

## 5. Grand Persistence Run

`-IncludePersistence`에서만 선택한다. 게시된 Experience와 Studio API Access가 필요하다.

### Live DataStore

- 실제 CRUD·Migration 기본 경로

### Restart Seed

- Shutdown-only Dirty Snapshot
- Studio 종료 시 `BindToClose`
- Bounded Retry·Deadline 저장

### Restart Verify

- 새 Studio Server Restore
- Revision 보존·AuthorityEpoch 교체
- 이전 Epoch Command `STALE_EPOCH`
- Post-restart Save·Key 정리

### Injected DataStore Outage

```text
호출 전 장애 주입
→ Load Failure
→ 장애 해제·빈 Key Load
→ Dirty Snapshot 생성
→ Save Retry 3회 고갈
→ Dirty·Saved Revision 보존
→ 장애 해제
→ 실제 DataStore Save·Reload
→ 재차 Load 장애·복구
→ Key 정리
```

PASS 로그:

```text
[RVTT DataStore Outage] result=PASS ... failed=0 injectedFailures=<n> recoveredRevision=1
```

장애는 Production Adapter 앞에서 주입한다. 복구 뒤 저장과 재로드는 실제 DataStore를 사용하지만 Roblox 플랫폼 자체 Outage를 발생시키지는 않는다.

### Cross-server Lease Pair

Holder와 Contender가 동일한 실제 DataStore Lease Key를 사용한다.

```text
Holder Acquire fence=1
→ Contender LEASE_HELD
→ Holder Renew fence 유지
→ Contender LEASE_HELD
→ Holder Expiry
→ Contender Takeover fence 증가
→ 이전 Holder Verify·Release 거부
→ Contender Release·Key Cleanup
```

PASS 로그:

```text
[RVTT Lease Holder] result=PASS ... failed=0 ... renewals=1 takeovers=1
[RVTT Lease Contender] result=PASS ... failed=0 ... blocked=2 takeovers=1
```

### Production ServerBoot Lease Integration

현재 Production Source는 구현됐지만 Published Acceptance Project는 아직 준비 중이다.

예정 흐름:

```text
Acceptance 전용 Authority Store·Key·Lease Store
→ 실제 ServerBoot Seed 시작
→ Lease Acquire
→ Atomic Authority Fence Claim
→ Command Commit·Fenced Flush
→ BindToClose Release
→ 다음 Server 시작
→ Higher Fence Claim·Latest Document Restore
→ 이전 Fence Revision 99 지연 Save 거부
→ Key Cleanup
```

이 Host가 Manifest에 등록되기 전에는 Grand Persistence 사용자 실행을 요청하지 않는다.

## 6. Production 복구 모듈

### Projection Replica

- 이전 AuthorityEpoch rollback 차단
- Duplicate·이전 Sequence 무시
- 실제 Gap에서 Full Resync

### Command Client

- 원본 Command ID Bounded Retry
- retryable `CLIENT_TIMEOUT`
- Terminal 뒤 Pending 정리

### Persistence Coordinator

- Shutdown-only Dirty Snapshot
- 최대 5회·25초 Deadline·지수 Backoff
- Retryable Failure만 재시도
- 실패 시 Dirty 보존

### Lease Store·Coordinator

- `ownerId`, `token`, `expiresAt`, `fencingToken`
- `LEASE_HELD`, `LEASE_LOST`, `LEASE_EXPIRED`
- Renew·Verify·Release
- Takeover마다 Fencing Token 증가
- DataStore 실패는 retryable `PERSISTENCE_FAILED`

### Production Lease Ownership

```text
Acquire
→ Remote Verify
→ Atomic Fence Claim
→ Load·Restore
→ Local Command Guard
→ Background Renew
→ Flush 전 Remote Verify
→ Fenced Save
→ Flush-before-Release
```

- Lease 미획득 서버는 Authority Document를 Load하지 않는다.
- Remote·System Command는 Persistence 준비 전 또는 Lease Lost 뒤 실행되지 않는다.
- `ProfileStore.loadFenced`는 기존 문서를 보존하면서 같은 `UpdateAsync`에서 `persistenceFence`를 Claim한다.
- Claim 뒤 낮은 Fence, 같은 Fence의 다른 Identity, Unfenced Writer는 `PERSISTENCE_FENCED`다.
- 이전 서버의 높은 Revision 지연 저장도 Claim 이후에는 거부된다.
- Higher Fence는 Revision 단조성 검사를 우회하지 않는다.
- `persistenceFence`는 Runtime Snapshot에서 제거된다.
- Shutdown은 Fenced Flush 뒤 Lease를 Release한다.

## 7. 자동 Contract Gate

`validate_production_lease.py`와 `Validate production lease` Workflow는 다음을 고정한다.

- Acquire→Fence Claim→Load→Renew 순서
- Command Guard가 Authority Execute보다 먼저 실행
- Load·Save 전 Lease Verify·Write Fence
- Claim과 Save 모두 Fencing 비교
- Higher Fence의 Revision 우회 금지
- BindToClose Flush→Release 순서
- Command·Ownership·Protected Store·Profile Fencing Spec 등록

## 8. 아직 남은 범위

- Acceptance 전용 Production Store·Key Project Config
- 실제 ServerBoot Seed·Takeover·Stale Write Published Host
- Lease 미획득·Lease Lost 사용자 UX
- Roblox 플랫폼 실제 DataStore 장애 Evidence
- Roblox Remote 지연·대역폭 Throttle
- Slices 02–12 전체 UI·Disclosure·Recovery
- Slices 13–15 Content 권리·Asset
- UI Visual Redesign·Accessibility Human Review
- Performance Budget·Memory·Network·Soak
- Slice 16 Full-session Release Gate·Runbook

## 9. 보고서

기본 출력 위치:

```text
%TEMP%\RVTT-Grand-Acceptance\<timestamp>-<head>\
```

생성 파일:

```text
RVTT-grand-acceptance-report.json
RVTT-grand-acceptance-report.md
places\*.rbxlx
```

주요 로그:

```text
[RVTT DataStore Outage] ...
[RVTT Lease Pair Prompt] ...
[RVTT Lease Holder] ...
[RVTT Lease Contender] ...
향후 [RVTT Production Lease Seed] ...
향후 [RVTT Production Lease Verify] ...
```

판정:

- `PASS`: 선택된 Phase가 모두 PASS이고 Blocked·Prepared가 없음
- `PARTIAL`: 실행 Phase는 PASS했지만 Blocked 또는 Prepared가 있음
- `FAIL`: FAIL 또는 Summary 미발견이 있음

## 10. 결함 처리

```text
Grand Campaign 끝까지 실행
→ 모든 실패 수집
→ 동일 Root Cause 통합
→ Subsystem별 수정 Batch
→ 자동 Gate
→ Grand Campaign 전체 재실행
```

## 11. 사용자 실행 계약

사용자에게는 항상 다음 요소를 포함한 완전한 다중 행 Windows PowerShell 블록을 제공한다.

```text
$ErrorActionPreference = "Stop"
RobloxStudioBeta 종료
$HOME\RVTT 저장소 이동
planning/rvtt-remake fetch·switch·pull
정확한 7자리 Head 검사
run-grand-acceptance.ps1 실행
```

한 줄 Bootstrap, 원격 `Invoke-Expression`, 중첩 `powershell -Command`는 제공하지 않는다.

현재 Production Lease Integration Acceptance Host가 준비되지 않았으므로 사용자 Grand Persistence Runtime 실행을 요청하지 않는다.
