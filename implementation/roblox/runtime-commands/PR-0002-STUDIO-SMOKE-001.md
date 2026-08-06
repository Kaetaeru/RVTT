# PR #2 Roblox Studio MCP Smoke Runtime Command 001

- status: `PREPARED_NOT_EXECUTED`
- commandId: `RVTT-PR2-STUDIO-SMOKE-001`
- targetRepository: `Kaetaeru/RVTT`
- pullRequest: `2`
- targetMode: `CURRENT_PR_HEAD_AT_RUNTIME_START`
- projectFile: `implementation/roblox/default.project.json`
- placeMode: `PLAY_SOLO`
- evidenceOutputPath: `implementation/roblox/evidence/<targetSha>/RVTT-PR2-STUDIO-SMOKE-001/attempt-001/`
- authority:
  - `implementation/roblox/ROBLOX-STUDIO-MCP-TEST-POLICY.md`
  - `implementation/roblox/CODEX-REVIEW-TEST-GATE.md`
  - `docs/remake/product/codex-supervised-review-and-test-policy.md`
  - `implementation/roblox/EXECUTION-TEST-RULES.md`

## 목적

연결된 Roblox Studio MCP의 실제 Capability를 기록하고, 가장 작은 Studio Open → Play Solo → Output Read → Screenshot → Stop → Evidence Export 흐름이 재현 가능한지 확인한다.

이 명령은 Capability Handshake와 Smoke Runtime만 다룬다. Multi-client, Persistence, ADR-0092 Survival Runtime, Actor Import Runtime, 성능, 장시간 Soak와 Human Playtest PASS를 주장하지 않는다.

## 현재 Gate 상태

```text
Codex Delta 004: current-SHA NO_SUPPORTED_FINDINGS
Validate remake documentation: success
Validate RVTT content templates: success
Validate RVTT implementation: NOT VERIFIED
Reason: GitHub-hosted Runner가 두 Attempt 모두 Job을 획득하지 못해 Step 0개 상태로 취소됨
Studio MCP in the ChatGPT authoring session: NOT CONNECTED
Runtime Evidence: NONE
```

GitHub Actions의 표시가 `failure`여도 Runner 미배정 취소를 구현 실패로 해석하지 않는다. 반대로 검사가 실행되지 않았으므로 Implementation Gate PASS로도 해석하지 않는다.

## Hard Preconditions

Runtime 실행자는 다음을 모두 확인한다.

1. PR #2의 정확한 40자 HEAD SHA를 Runtime 시작 직전에 조회한다.
2. Local Checkout HEAD가 PR HEAD와 정확히 일치한다.
3. Working Tree가 Clean이다.
4. 현재 SHA에 대한 Codex `STUDIO_PREFLIGHT` 결과가 존재하고 `CONFIRMED` BLOCKER·HIGH Finding이 없다.
5. `Validate RVTT implementation`이 같은 SHA에서 `completed/success`이거나, ChatGPT Lead Reviewer와 사용자가 별도 Local Static Gate Evidence를 명시적으로 승인했다.
6. 위 5번이 충족되지 않으면 Capability Handshake 문서화까지만 허용하고 Place Build·Play를 시작하지 않는다.
7. 연결된 MCP의 실제 Tool 목록을 읽기 전에는 Capability가 존재한다고 가정하지 않는다.
8. Credential, 실제 사용자 Save Data, 비공개 Rulebook 원문과 공개 불가 Asset 원문을 Evidence에 넣지 않는다.

Precondition 실패 결과는 `BLOCKED`이며 PASS가 아니다.

## Capability Handshake

연결된 MCP의 실제 Tool 이름을 다음 논리 Capability에 Mapping한다.

### Required

```text
studio.open_place 또는 studio.open_local_file
studio.start_play_solo
studio.stop_play
studio.read_output
studio.capture_screenshot
studio.export_evidence 또는 동일한 파일 저장 수단
```

### Optional

```text
studio.clear_output
studio.capture_instance_snapshot
studio.read_attributes
studio.set_test_flag
studio.save_local_copy
```

각 항목을 다음 중 하나로 분류한다.

```text
MCP_AUTOMATED
HUMAN_MANUAL
NOT_AVAILABLE
```

Required Capability가 `NOT_AVAILABLE`이면 Runtime 결과는 `BLOCKED`다. Required Capability를 메서드 직접 호출, 임의 Script 삽입 또는 근거 없는 수동 완료 주장으로 우회하지 않는다.

`capability-handshake.json` 최소 필드:

```json
{
  "commandId": "RVTT-PR2-STUDIO-SMOKE-001",
  "targetSha": "<40-character SHA>",
  "sessionId": "<MCP session id>",
  "connectedAt": "<ISO-8601>",
  "clientName": "<name>",
  "clientVersion": "<version or null>",
  "studioVersion": "<version or null>",
  "placeId": "<id or null>",
  "universeId": "<id or null>",
  "connectionScope": "<scope>",
  "capabilityMappings": [],
  "unavailableCapabilities": [],
  "evidenceRoot": "implementation/roblox/evidence/<targetSha>/RVTT-PR2-STUDIO-SMOKE-001/attempt-001/"
}
```

## Setup Steps

1. PR HEAD, Local HEAD와 Clean Working Tree Evidence를 기록한다.
2. Pin된 Rojo를 확인한다.
3. 승인된 Static Gate Evidence를 기록한다.
4. 다음 Build를 실행한다.

```bash
cd implementation/roblox
rojo build default.project.json --output /tmp/RVTT-studio-smoke.rbxlx
```

5. Build exit code와 SHA-256을 `build-manifest.txt`에 기록한다.
6. MCP로 `/tmp/RVTT-studio-smoke.rbxlx` 또는 동일 내용의 승인된 Local Place를 연다.
7. 실제 열린 Place와 Target SHA의 관계를 확인한다.
8. 지원되면 Output을 Clear한다.

Build 실패, Place 불일치 또는 Target SHA mismatch면 즉시 중단한다.

## Automated Actions

MCP가 지원하는 범위에서 순서대로 수행한다.

1. Place가 Edit Mode로 열린 상태의 Screenshot을 저장한다.
2. 지원되면 핵심 Root Instance Snapshot을 저장한다.
3. Play Solo를 시작한다.
4. Studio가 Running 상태가 될 때까지 최대 30초 대기한다.
5. Running 상태 확인 후 최소 5초 동안 유지한다.
6. Output 전체를 읽어 `studio-output-running.log`에 저장한다.
7. Running 상태 Screenshot을 저장한다.
8. 지원되면 `Players`, `Workspace`, `ReplicatedStorage`, `ServerScriptService`, `StarterGui`의 고수준 Snapshot을 저장한다. Private value나 대용량 Source 본문은 제외한다.
9. Play를 중지한다.
10. Edit Mode 복귀를 최대 30초 기다린다.
11. Stop 이후 Output을 `studio-output-final.log`에 저장한다.
12. Post-stop Screenshot을 저장한다.
13. Evidence Bundle을 지정 경로로 Export한다.

## Human Actions

MCP가 자동화하지 못하는 경우에만 수행하고 `human-observations.md`에 수동임을 명확히 기록한다.

1. 실제 Roblox Studio 창과 올바른 Place가 열렸는지 확인한다.
2. Play Solo 전후 상태 전환이 화면에서 확인되는지 기록한다.
3. Running Screenshot에서 UI가 완전히 비어 있거나 치명적으로 깨져 보이는지 관찰한다.
4. 자동 Screenshot 또는 Export가 불가능하면 수동 저장 경로와 수행자를 기록한다.

Human Action은 MCP Automated Action으로 표시하지 않는다. 이 Smoke에서 재미, 입력 감각, 가독성 완성도 또는 전체 UX PASS를 판정하지 않는다.

## Assertions

```text
A01 targetSha == PR HEAD at runtime start
A02 localHead == targetSha
A03 workingTreeClean == true
A04 staticGateApproved == true
A05 requiredCapabilities contain no NOT_AVAILABLE
A06 rojoBuildExitCode == 0
A07 openedPlace matches build manifest
A08 playSolo reached running state within 30s
A09 output logs were captured while running and after stop
A10 no unhandled error or stack trace exists without an explicit allowed explanation
A11 running screenshot exists and is readable
A12 stop returned Studio to edit state within 30s
A13 evidence bundle metadata references the exact targetSha and commandId
```

모든 Assertion이 충족돼야 `PASS`다. 선택 Capability만 빠진 경우에 한해 `PARTIAL`을 사용할 수 있으며, Required Capability나 Hard Precondition이 빠지면 `BLOCKED`다.

## Expected Log Policy

이 Smoke는 앱 전용 PASS 문자열을 꾸며내지 않는다.

```text
expectedLogTokens: []
```

Output에 로그가 없더라도 Play 상태와 Screenshot·State Evidence가 모두 있으면 Smoke를 평가할 수 있다. 다만 Output 읽기 자체는 반드시 성공해야 한다.

다음은 기본 Forbidden Pattern이다.

```text
Script timeout
Infinite yield possible
attempt to index nil
attempt to call a nil value
stack overflow
Unhandled
Stack Begin
```

`Stack Begin`이 정상적으로 처리된 의도적 테스트 오류에 속한다고 주장하려면 동일 Evidence Bundle에 명시적 Allowlist 근거가 있어야 한다. Allowlist 없는 Forbidden Pattern은 `FAIL`이다.

## Screenshot Checkpoints

```text
S01-edit-mode-open.png
S02-play-solo-running.png
S03-post-stop-edit-mode.png
```

각 Screenshot은 Target SHA, Command ID, Attempt와 촬영 시점을 Sidecar Metadata 또는 Summary에 연결한다.

## State Snapshot Checkpoints

```text
T01-edit-mode-root-snapshot.json
T02-running-root-snapshot.json
T03-post-stop-root-snapshot.json
```

Snapshot Capability가 없으면 `HUMAN_MANUAL` 또는 `NOT_AVAILABLE`로 기록한다. Snapshot은 Optional이므로 다른 Required Evidence가 충족된 경우에만 결과를 `PARTIAL`로 제한할 수 있다.

## Timeout Policy

```text
placeOpen: 60s
playStart: 30s
runningObservation: 5s minimum / 60s maximum
outputRead: 30s
stopPlay: 30s
evidenceExport: 60s
totalCommand: 10m
```

Timeout은 Evidence를 보존하고 `FAIL` 또는 `BLOCKED`로 종료한다. 무한 재시도하지 않는다.

## Immediate Stop Conditions

```text
Target SHA mismatch
Dirty working tree after setup
Build failure
Wrong Place or Project
MCP disconnect
Studio crash
Required Capability unavailable
Forbidden log pattern without allowlist
Unhandled error
Play start or stop timeout
Evidence target mismatch
```

## Cleanup Steps

1. Play 중이면 반드시 Stop을 시도한다.
2. Studio와 MCP 연결 상태를 기록한다.
3. 임시 `/tmp/RVTT-studio-smoke.rbxlx`는 Evidence Hash 기록 후 삭제할 수 있다.
4. 저장소 Source와 PR 파일은 Runtime 과정에서 수정하지 않는다.
5. 실패·중단 Evidence도 삭제하지 않는다.
6. Credential과 Private Data가 포함됐는지 최종 점검한다.

## Evidence Bundle

```text
implementation/roblox/evidence/<targetSha>/RVTT-PR2-STUDIO-SMOKE-001/attempt-001/
├─ run-metadata.json
├─ capability-handshake.json
├─ build-manifest.txt
├─ studio-output-running.log
├─ studio-output-final.log
├─ assertions.json
├─ screenshots/
│  ├─ S01-edit-mode-open.png
│  ├─ S02-play-solo-running.png
│  └─ S03-post-stop-edit-mode.png
├─ state-snapshots/
├─ human-observations.md
└─ summary.md
```

`run-metadata.json` 최소 필드:

```text
commandId
targetSha
branch
projectFile
studioVersion
mcpSessionId
startedAt
finishedAt
serverCount
clientRoles
persistenceMode
result
```

이 Smoke의 고정값:

```text
serverCount: 1
clientRoles: [solo_player]
persistenceMode: studio_smoke_no_persistence_claim
```

Result:

```text
PASS
FAIL
BLOCKED
PARTIAL
ABORTED_STALE_HEAD
```

## Claim Boundary

이 명령의 PASS는 다음만 의미한다.

```text
정확한 SHA의 Place를 Build·Open할 수 있음
Play Solo Start·Stop이 가능함
Output을 읽을 수 있음
Screenshot과 최소 Evidence를 저장할 수 있음
```

다음은 의미하지 않는다.

```text
전체 게임 기능 PASS
ADR-0092 Runtime PASS
Multi-client PASS
Persistence PASS
Performance PASS
Accessibility PASS
Human Playtest PASS
Merge Ready
```
