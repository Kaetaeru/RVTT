# RVTT Grand Acceptance Campaign

- 상태: `REAL_TRANSPORT_RESTART_STATIC_VERIFIED`
- 목적: 사용자가 한 번의 Windows PowerShell 실행으로 현재 실행 가능한 모든 Acceptance 환경을 순차 실행하고 하나의 결함 보고서를 얻는다.
- Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
- Runner: [`tooling/run-grand-acceptance.ps1`](tooling/run-grand-acceptance.ps1)
- Single-client Project: [`grand-single-client.project.json`](grand-single-client.project.json)
- Real Transport Project: [`real-transport.project.json`](real-transport.project.json)
- Restart Projects: [`restart-seed.project.json`](restart-seed.project.json), [`restart-verify.project.json`](restart-verify.project.json)

## 1. 실행 모델

Grand Acceptance는 하나의 Roblox Studio Play 세션만을 뜻하지 않는다. 사용자 입장에서는 한 번 실행하지만, 내부에서는 필요한 환경을 실행 그룹별로 순차 처리한다.

```text
PowerShell 실행 1회
→ 등록된 모든 Rojo Project Build
→ grand-single-client Studio Run
→ grand-multi-client Studio Run
→ grand-real-transport Local Server Run
→ 선택적 Grand Persistence Runs
   → Live DataStore
   → Restart Seed
   → Restart Verify
→ 향후 Forced Outage·Lease·Human UI·Soak Runs
→ JSON·Markdown 통합 보고서
```

Studio Run이 끝나면 Studio를 닫는다. 같은 PowerShell Process가 다음 Run을 시작한다.

## 2. `runId` 그룹 계약

Manifest에서 같은 `runId`, `project`, `execution`을 가진 Phase는 한 번의 Studio 실행을 공유한다.

현재 `grand-single-client` Run은 다음 두 Phase를 한 Place에서 판정한다.

```text
unit-integration-baseline
slice01-world-interaction
```

`unit-integration-baseline` 내부에는 기존 Unit·Integration, Slices 02–12 자동 Authority Scenario, Cross-slice Session, Authority Fault, Deterministic Network·Storage Fault Host, Persistence Retry Spec과 Capacity Sample가 포함된다. Slice 01은 같은 Play에서 실제 사용자 입력을 받아 별도 Batch Summary를 출력한다.

Real Transport와 Restart는 환경과 사용자 조작이 다르므로 독립 `runId`를 사용한다.

```text
grand-real-transport
→ real-transport.project.json

grand-persistence-restart-seed
→ restart-seed.project.json

grand-persistence-restart-verify
→ restart-verify.project.json
```

같은 Run의 각 Phase는 서로 다른 `summaryToken`, `evidenceTokens`, `passRegex`를 유지한다. 따라서 Studio 실행 수를 줄여도 판정과 Evidence는 합쳐지지 않는다.

## 3. 핵심 원칙

- 첫 실패에서 Campaign을 중단하지 않는다.
- 가능한 모든 Run을 끝까지 실행해 실패를 한 번에 수집한다.
- 각 Phase는 독립 Summary Token과 PASS Regex를 가진다.
- Studio 종료 후 최근 Roblox Log에서 Summary와 진단 Evidence를 수집한다.
- 모든 결과를 하나의 JSON·Markdown 보고서로 합친다.
- Summary 미발견은 PASS가 아니라 `incomplete`다.
- 아직 구현되지 않은 Phase는 `blocked` 또는 `planned`로 표시한다.
- 일반 기능과 Persistence Evidence는 같은 보고서에서도 Phase 단위로 분리한다.
- 공식 데이터·권리 검토가 필요한 Content Phase는 승인 전까지 `blocked`다.
- Fault Scenario는 결정적 Host로 복구 계약을 고정한 뒤 실제 Player·Server·DataStore 경계로 확장한다.
- Capacity Sample은 실제 수치를 기록하되 측정 전 임의 성능 합격선을 만들지 않는다.

## 4. 현재 `grand-single-client` 범위

### 기존 자동 검사

- Unit·Integration Runtime
- Command Authorization·Idempotency
- Security·Projection Disclosure Source
- Slice 01 Session Flow

### Slices 02–12 자동 baseline

- Rules·D20·Attack·HP
- Exploration Interaction·Search·Knowledge·Fog
- Encounter Lifecycle·Turn·Rollback
- Character Draft·Activation·Level Up
- Inventory Location·Ownership·Equip·Drop
- Campaign Time·Schedule·Activity
- UI Preference Validation·User Isolation
- Journal Ownership·Edit·Link·Ping
- Scene Source·Compile·Candidate·Publish
- DM Control·Quick Action·Patch·Recovery Request
- Content Pack Rights·Dependency·Activation·Localization

### Cross-slice

```text
Session·Character·Scene
→ UI Preference
→ Original Content Pack
→ Scene Authoring·Publish
→ Journal
→ Inventory·Equip
→ Exploration
→ Rules Check
→ Encounter
→ Time Activity
→ DM Quick Action
→ Snapshot·Restore
```

### Authority Fault

- Stale Revision
- Stale AuthorityEpoch
- Invalid Payload
- Duplicate Command Replay
- Corrupt Snapshot
- Restore 후 Epoch 갱신
- 이전 Epoch 폐기

### Deterministic Network Fault Host

- Projection Packet Drop
- Duplicate Packet
- Hold·Reorder·Release
- Sequence Gap과 Full Resync
- 새 AuthorityEpoch 뒤 지연된 이전 Epoch Packet
- Terminal Receipt 유실
- 동일 Command ID 재전송
- 최대 3회 전송과 8초 retryable Timeout

### Deterministic Storage Fault Host

- Transient Load Failure와 Retry
- Commit 전 Save Failure
- Dirty Snapshot 보존
- Commit 뒤 Ack Loss
- 동일 Revision·Epoch 멱등 Retry
- Revision Conflict
- External Winner 보존
- 더 높은 Revision Reconcile
- Invalid Revision Load 처리

### Persistence Shutdown Retry

- Shutdown-only Dirty Snapshot
- 최대 5회 Attempt
- 0.25초 시작, 최대 2초 Backoff
- 전체 25초 Deadline
- Retryable Failure 재시도
- Non-retryable Failure 즉시 종료
- Retry 고갈 시 Dirty Snapshot 유지

### Capacity Sample

```text
Scene Object=32
Item=32
Journal Document=16
elapsedMs=<measured>
restoreMs=<measured>
```

현재 Capacity Sample은 개수·Snapshot·Restore 정합성을 PASS 조건으로 사용하고 시간은 Evidence로만 기록한다.

### Slice 01 실제 입력

- WASD Camera Pan
- Middle-button Camera Pan
- F·Token Frame
- Mouse Wheel Zoom
- 3D Token Pick·Highlight
- Destination Marker
- Server-authoritative Movement·Projection

## 5. 다른 Run

### `grand-multi-client`

- DM·Player·Observer
- 권한 없는 Command 거부
- Viewer별 Projection과 Negative Disclosure
- Stale Revision Recovery
- 논리적 Disconnect·Reconnect·Full Resync

### `grand-real-transport`

`real-transport.project.json`을 Local Server 1개와 Client 3개로 실행한다.

```text
DM·Player·Observer 준비
→ Player Client에 종료 지시
→ 사용자가 해당 Client 창 종료
→ PlayerRemoving 확인
→ 논리 사용자 Connection=disconnected
→ 사용자가 Replacement Client 1개 추가
→ 새 PlayerAdded 확인
→ 같은 논리 사용자 재가입
→ Full Sync 확인
```

PASS 계약:

- 실제 Player Instance가 교체된다.
- Membership는 정확히 3개다.
- Connection은 `disconnected → connected`로 복구된다.
- 같은 서버 AuthorityEpoch는 바뀌지 않는다.
- Projection Sequence는 증가한다.
- 최종 로그는 `[RVTT Real Transport] result=PASS ... failed=0 ... reconnects=1`이다.

### Grand Persistence

`-IncludePersistence`를 사용한 전용 Milestone에서만 선택한다.

#### Live DataStore Baseline

- CRUD와 Migration 기본 경로

#### Restart Seed

- Test Key 초기화
- Membership·Connection Snapshot 생성
- 자동 5초 Flush 없이 Dirty 유지
- Studio 종료 시 `BindToClose`
- Bounded Retry로 DataStore Checkpoint 저장
- `[RVTT Restart Seed] result=PASS ...`

#### Restart Verify

- 새 Studio Server에서 Checkpoint Load
- Runtime Restore
- Revision 보존
- AuthorityEpoch 교체
- 이전 Epoch Command `STALE_EPOCH`
- 현재 Epoch Command Commit
- Post-restart Snapshot 저장과 Key 정리
- `[RVTT Restart Verify] result=PASS ...`

게시된 Experience와 Studio API Access가 필요한 항목은 일반 Grand Run에서 실행하지 않는다.

## 6. Production 복구 보강

### Projection Replica

- 최근 Epoch 이력을 유지하고 지연된 이전 Epoch rollback을 거부한다.
- 동일 또는 이전 Projection Sequence는 False Gap 없이 무시한다.

### Command Client

- Terminal Receipt 유실 시 원본 Envelope와 Command ID를 bounded retry한다.
- Terminal Receipt가 끝내 없으면 `CLIENT_TIMEOUT` Terminal 상태와 Pending 정리를 수행한다.

### Persistence Coordinator

- `markDirty(state, false)`로 Shutdown-only Snapshot을 만든다.
- `flushUntilClean(policy)`는 Retryable Failure만 재시도한다.
- Attempt·Deadline 고갈 또는 Non-retryable Failure를 명시적으로 기록한다.
- 실패한 Snapshot은 Dirty 상태로 보존한다.

## 7. 아직 남은 범위

- Slices 02–12의 전체 사용자 UI·Disclosure·Recovery Scenario
- Slices 13–15 공식 데이터·권리·Asset 승인
- UI Visual Redesign·Accessibility Human Review 수집
- Roblox 실제 Remote 지연·제한·대역폭 Throttle
- 강제 DataStore Throttle·Outage Host
- Cross-server Lease 획득·갱신·만료·동시 Conflict Host
- 실제 Performance Budget·Memory·Network·Soak
- Slice 16 Full-session Release Gate와 Runbook

Real Transport와 Restart Host가 등록됐어도 Studio Runtime Evidence가 생기기 전에는 해당 Phase를 PASS로 해석하지 않는다.

## 8. 보고서

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
[RVTT Spec Summary] id=<id> result=PASS|FAIL passed=<n> failed=<n>
[RVTT Spec Failure] <id>: <failure>
[RVTT Fault Host] kind=network ...
[RVTT Fault Host] kind=storage ...
[RVTT Persistence Retry] result=RETRYING|PASS|EXHAUSTED ...
[RVTT Real Transport Prompt] action=close-client|start-replacement-client ...
[RVTT Real Transport] result=PASS|FAIL ...
[RVTT Restart Prompt] phase=seed action=close-studio ...
[RVTT Restart Seed] result=PASS|FAIL ...
[RVTT Restart Verify] result=PASS|FAIL ...
[RVTT Spec Summary] id=grand-capacity-sample sample=capacity ... elapsedMs=... restoreMs=...
[RVTT Tests] passed=<n> failed=<n>
[RVTT Batch Summary] batch=slice01-world-interaction ...
[RVTT MultiClient] ...
[RVTT Grand Summary] campaign=rvtt-grand-acceptance ...
```

판정:

- `PASS`: 선택된 Phase가 모두 PASS이고 Blocked·Prepared가 없음
- `PARTIAL`: 선택된 Phase는 PASS했지만 Blocked 또는 `-NoOpen` Prepared Phase가 있음
- `FAIL`: 실행한 Phase에 FAIL 또는 Summary 미발견이 있음

## 9. 결함 처리

```text
Grand Campaign 끝까지 실행
→ 모든 실패 수집
→ 동일 Root Cause 통합
→ Subsystem별 수정 Batch
→ 자동 Gate
→ Grand Campaign 전체 재실행
```

카메라·입력·Projection·Persistence처럼 같은 원인에서 파생된 실패를 항목별 Micro-fix로 처리하지 않는다.

## 10. 사용자 실행 계약

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

현재는 Forced DataStore Outage·Cross-server Lease, Human UI와 Soak Phase를 더 연결하는 중이므로 사용자 Grand Runtime 실행을 요청하지 않는다.
