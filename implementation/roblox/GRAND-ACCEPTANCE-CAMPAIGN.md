# RVTT Grand Acceptance Campaign

- 상태: `AUTOMATED_BASELINE_EXPANDED_STATIC_VERIFIED`
- 목적: 사용자가 한 번의 Windows PowerShell 실행으로 현재 실행 가능한 모든 Acceptance 환경을 순차 실행하고 하나의 결함 보고서를 얻는다.
- Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
- Runner: [`tooling/run-grand-acceptance.ps1`](tooling/run-grand-acceptance.ps1)
- Single-client Project: [`grand-single-client.project.json`](grand-single-client.project.json)

## 1. 실행 모델

Grand Acceptance는 하나의 Roblox Studio Play 세션만을 뜻하지 않는다. 사용자 입장에서는 한 번 실행하지만, 내부에서는 필요한 환경을 실행 그룹별로 순차 처리한다.

```text
PowerShell 실행 1회
→ 등록된 모든 Rojo Project Build
→ grand-single-client Studio Run
→ grand-multi-client Studio Run
→ 선택적 Grand Persistence Runs
→ 향후 Human UI·Full Fault·Soak Runs
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

`unit-integration-baseline` 내부에는 기존 Unit·Integration과 Slices 02–12 자동 Authority Scenario, Cross-slice Session, Authority Fault, Capacity Sample가 포함된다. Slice 01은 같은 Play에서 실제 사용자 입력을 받아 별도 Batch Summary를 출력한다.

같은 Run의 각 Phase는 서로 다른 `summaryToken`, `evidenceTokens`, `passRegex`를 유지한다. 따라서 Studio 실행 수를 줄여도 판정과 Evidence는 합쳐지지 않는다.

## 3. 핵심 원칙

- 첫 실패에서 Campaign을 중단하지 않는다.
- 가능한 모든 Run을 끝까지 실행해 실패를 한 번에 수집한다.
- 각 Phase는 독립 Summary Token과 PASS Regex를 가진다.
- Studio 종료 후 최근 Roblox Log에서 Summary와 진단 Evidence를 수집한다.
- 모든 결과를 하나의 JSON·Markdown 보고서로 합친다.
- Summary 미발견은 PASS가 아니라 `incomplete`다.
- 아직 구현되지 않은 Phase는 `blocked`로 표시한다.
- 일반 기능과 Persistence Evidence는 같은 보고서에서도 Phase 단위로 분리한다.
- 공식 데이터·권리 검토가 필요한 Content Phase는 승인 전까지 `blocked`다.
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
- Disconnect·Reconnect·Full Resync

### Grand Persistence

`-IncludePersistence`를 사용한 전용 Milestone에서만 선택한다.

- Live DataStore Baseline
- Load·Save·Dirty·Flush
- Stop·Play·Server Restart Restore
- Migration·Lease·Conflict
- Failure Recovery·Rollback

게시된 Experience와 Studio API Access가 필요한 항목은 일반 Grand Run에서 실행하지 않는다.

## 6. 아직 남은 범위

- Slices 02–12의 전체 사용자 UI·Disclosure·Recovery Scenario
- Slices 13–15 공식 데이터·권리·Asset 승인
- UI Visual Redesign·Accessibility Human Review 수집
- Network Drop·Delay·Duplicate·Reorder Host
- DataStore Throttle·Partial Commit·Restart Fault Host
- 실제 Performance Budget·Memory·Network·Soak
- Slice 16 Full-session Release Gate와 Runbook

자동 baseline이 존재하더라도 전체 Slice Phase는 남은 범위가 완료되기 전까지 `planned`다.

## 7. 보고서

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

## 8. 결함 처리

```text
Grand Campaign 끝까지 실행
→ 모든 실패 수집
→ 동일 Root Cause 통합
→ Subsystem별 수정 Batch
→ 자동 Gate
→ Grand Campaign 전체 재실행
```

카메라·입력·Projection·Persistence처럼 같은 원인에서 파생된 실패를 항목별 Micro-fix로 처리하지 않는다.

## 9. 사용자 실행 계약

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

현재는 Persistence·Human UI·Full Fault·Soak Phase를 더 연결하는 중이므로 사용자 Grand Runtime 실행을 요청하지 않는다.
