# PR #2 Roblox Studio MCP Smoke Runtime Command 001

- status: `PREPARED_NOT_EXECUTED`
- commandId: `RVTT-PR2-STUDIO-SMOKE-001`
- targetRepository: `Kaetaeru/RVTT`
- pullRequest: `2`
- targetMode: `CURRENT_PR_HEAD_AT_RUNTIME_START`
- projectFile: `implementation/roblox/default.project.json`
- placeMode: `PLAY_SOLO`
- executionEvidenceRoot: `/tmp/rvtt-studio-evidence/<targetSha>/RVTT-PR2-STUDIO-SMOKE-001/attempt-001/`
- repositoryEvidenceArchive: `implementation/roblox/evidence/<targetSha>/RVTT-PR2-STUDIO-SMOKE-001/attempt-001/`
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
3. Source Working Tree가 Clean이다.
4. 현재 SHA에 대한 Codex `STUDIO_PREFLIGHT` 결과가 존재하고 `CONFIRMED` BLOCKER·HIGH Finding이 없다.
5. `Validate RVTT implementation`이 같은 SHA에서 `completed/success`이거나, ChatGPT Lead Reviewer와 사용자가 별도 Local Static Gate Evidence를 명시적으로 승인했다.
6. 위 5번이 충족되지 않으면 Capability Handshake 문서화까지만 허용하고 Place Build·Play를 시작하지 않는다.
7. 연결된 MCP의 실제 Tool 목록을 읽기 전에는 Capability가 존재한다고 가정하지 않는다.
8. Credential, 실제 사용자 Save Data, 비공개 Rulebook 원문과 공개 불가 Asset 원문을 Evidence에 넣지 않는다.
9. Runtime 중 Evidence는 저장소 밖 `executionEvidenceRoot`에만 기록한다. 저장소 내부 `repositoryEvidenceArchive`로의 복사는 Runtime 종료 후 별도 승인된 Archive 단계에서만 수행한다.

Precondition 실패 결과는 `BLOCKED`이며 PASS가 아니다.

## Source-clean Predicate

Runtime 시작 전과 각 주요 단계 이후 다음을 기록한다.

```text
git status --porcelain=v1 --untracked-files=all
```

허용되는 Runtime 출력은 저장소 밖 `executionEvidenceRoot`와 `/tmp/RVTT-studio-smoke.rbxlx`뿐이다. 저장소 내부의 tracked 또는 untracked 변경은 모두 예상 밖 Source 변경이며 즉시 `BLOCKED` 또는 `FAIL`로 종료한다.

`repositoryEvidenceArchive`에 Evidence를 복사하는 후속 Archive 단계는 Runtime Result 판정과 Source-clean 검사 이후에만 수행하며, 복사 전 사용자 승인과 별도 Commit 범위를 기록한다.

## Capability Handshake

연결된 MCP의 실제 Tool 이름을 다음 논리 Capability에 Mapping한다.

### Core Required

```text
studio.start_play_solo
studio.stop_play
studio.read_output
```

Core Required는 반드시 `MCP_AUTOMATED`여야 한다. 하나라도 `HUMAN_MANUAL` 또는 `NOT_AVAILABLE`이면 이 MCP Smoke Runtime은 `BLOCKED`다. 사람이 대신 Play·Stop·Output Read를 수행해 MCP 자동화 PASS로 기록하지 않는다.

Core Required의 `MCP_AUTOMATED` 선언은 분류 문자열만으로 성립하지 않는다. 각 Mapping에 연결 시점에 실제로 노출된 비어 있지 않은 `actualToolName`과 성공한 호출 Evidence가 있어야 한다.

```text
studio.start_play_solo: successful invocationEvidence 1개 이상
studio.stop_play: successful invocationEvidence 1개 이상
studio.read_output: successful invocationEvidence 2개 이상
                    (running Output 1개 + post-stop Output 1개)
```

논리 Capability ID 자체를 `actualToolName`으로 복사하거나, `available` 같은 일반 문자열만 기록한 항목은 실제 Tool Mapping Evidence가 아니며 `BLOCKED`다.

### Required With Manual Fallback

```text
studio.open_place 또는 studio.open_local_file
studio.capture_screenshot
studio.export_evidence 또는 동일한 파일 저장 수단
```

위 항목은 `MCP_AUTOMATED`, `HUMAN_MANUAL`, `NOT_AVAILABLE` 중 하나로 분류한다.

- `NOT_AVAILABLE`: `BLOCKED`
- `HUMAN_MANUAL`: 아래 `Manual Action Record`와 연결된 실제 수행·시각·Evidence가 모두 있어야 허용
- `MCP_AUTOMATED`: 실제 Tool 이름, 호출 시각과 결과 Evidence를 기록

### Optional

```text
studio.clear_output
studio.capture_instance_snapshot
studio.read_attributes
studio.set_test_flag
studio.save_local_copy
```

Optional은 `MCP_AUTOMATED`, `HUMAN_MANUAL`, `NOT_AVAILABLE`로 기록할 수 있다. 누락을 PASS로 확대하지 않는다.

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
  "executionEvidenceRoot": "/tmp/rvtt-studio-evidence/<targetSha>/RVTT-PR2-STUDIO-SMOKE-001/attempt-001/"
}
```

각 `capabilityMappings[]` 항목은 최소 다음을 가진다.

```text
logicalCapability
classification
actualToolName
manualActionId?
checkedAt
checker
result
invocationEvidence[]
```

조건부 필수 규칙:

- `classification == MCP_AUTOMATED`이면 `actualToolName`은 비어 있지 않아야 하고, 연결된 MCP가 실제 노출한 Tool 이름과 정확히 일치해야 한다.
- `classification == MCP_AUTOMATED`이면 `invocationEvidence[]`는 비어 있으면 안 된다.
- `classification == HUMAN_MANUAL`이면 `actualToolName`과 `invocationEvidence[]`를 자동화 증거로 사용하지 않고, 완전한 `manualActionId`를 요구한다.
- `classification == NOT_AVAILABLE`이면 `result`는 누락 상태를 명확히 기록하고 Required 항목은 `BLOCKED`다.

각 `invocationEvidence[]` 항목은 다음을 가진다.

```text
invocationId
logicalCapability
actualToolName
invokedAt
finishedAt
invocationResult: SUCCESS | FAILURE | TIMEOUT | DISCONNECTED
requestSummary
responseSummary
evidenceFiles[]
```

`evidenceFiles[]`는 실제 호출 결과와 연결된 파일을 가리킨다. 예:

```text
start_play_solo → play-start-invocation.json, S02-play-solo-running.png
read_output(running) → output-running-invocation.json, studio-output-running.log
stop_play → play-stop-invocation.json, S03-post-stop-edit-mode.png
read_output(post-stop) → output-final-invocation.json, studio-output-final.log
```

호출 실패 Evidence를 보존할 수 있지만 성공 Evidence로 세지 않는다.

## Capability Mapping Fixture Checks

Build 또는 Play 전에 다음 세 Fixture 판정을 수행하고 `capability-mapping-validation.json`에 기록한다.

```text
F01 classification=MCP_AUTOMATED + actualToolName 누락
    → BLOCKED_EXPECTED

F02 classification=MCP_AUTOMATED + invocationEvidence 누락
    → BLOCKED_EXPECTED

F03 classification=MCP_AUTOMATED + 실제 actualToolName
    + 최소 성공 호출 수
    + timestamp/result/evidenceFiles 완전
    → ELIGIBLE_EXPECTED
```

Core Required 세 Capability 각각에 F01·F02를 적용한다. `studio.read_output`의 F03은 running과 post-stop 두 성공 호출이 모두 있어야 한다. Fixture 판정이 예상과 다르면 Runtime을 시작하지 않고 `BLOCKED`로 기록한다.

## Manual Action Record

`HUMAN_MANUAL`이 허용된 Required With Manual Fallback 항목은 `manual-action-records.json`에 다음을 기록한다.

```text
manualActionId
logicalCapability
operator
startedAt
finishedAt
exactAction
studioStateBefore
studioStateAfter
evidenceFiles[]
result
notes
```

허용 Manual Action:

```text
M01 — 승인된 exact build/place를 Roblox Studio에서 열기
M02 — 지정 Screenshot checkpoint를 수동 저장하기
M03 — executionEvidenceRoot로 Evidence 파일을 수동 Export하기
```

금지 Manual 대체:

```text
Play Solo Start
Play Stop
Output Read
```

금지 항목을 사람이 수행했더라도 MCP Smoke PASS에 사용하지 않으며 결과는 `BLOCKED`다.

## Setup Steps

1. PR HEAD, Local HEAD와 Source-clean Evidence를 기록한다.
2. 저장소 밖 `executionEvidenceRoot`를 만든다.
3. Pin된 Rojo를 확인한다.
4. 승인된 Static Gate Evidence를 기록한다.
5. MCP Tool 목록을 수집하고 Capability Mapping Fixture Checks를 수행한다.
6. 다음 Build를 실행한다.

```bash
cd implementation/roblox
rojo build default.project.json --output /tmp/RVTT-studio-smoke.rbxlx
```

7. Build exit code와 SHA-256을 `executionEvidenceRoot/build-manifest.txt`에 기록한다.
8. MCP 자동화 또는 M01 절차로 `/tmp/RVTT-studio-smoke.rbxlx`를 연다.
9. 실제 열린 Place와 Target SHA의 관계를 확인한다.
10. 지원되면 Output을 Clear한다.
11. Source-clean Predicate를 다시 실행한다.

Build 실패, Place 불일치, Target SHA mismatch, Capability Mapping Fixture 실패 또는 저장소 Source 변경이면 즉시 중단한다.

## Automated Actions

MCP가 지원하는 범위에서 순서대로 수행한다.

1. Place가 Edit Mode로 열린 상태의 Screenshot을 저장한다. MCP Screenshot이 없으면 M02로 수행한다.
2. 지원되면 핵심 Root Instance Snapshot을 저장한다.
3. Mapping에 기록된 실제 MCP Tool로 Play Solo를 시작하고 Invocation Evidence를 저장한다.
4. Studio가 Running 상태가 될 때까지 최대 30초 대기한다.
5. Running 상태 확인 후 최소 5초 동안 유지한다.
6. Mapping에 기록된 실제 MCP Tool로 Output 전체를 읽고 호출 Evidence와 `studio-output-running.log`를 저장한다.
7. Running 상태 Screenshot을 저장한다. MCP Screenshot이 없으면 M02로 수행한다.
8. 지원되면 `Players`, `Workspace`, `ReplicatedStorage`, `ServerScriptService`, `StarterGui`의 고수준 Snapshot을 저장한다. Private value나 대용량 Source 본문은 제외한다.
9. Mapping에 기록된 실제 MCP Tool로 Play를 중지하고 Invocation Evidence를 저장한다.
10. Edit Mode 복귀를 최대 30초 기다린다.
11. Mapping에 기록된 실제 MCP Tool로 Stop 이후 Output을 읽고 호출 Evidence와 `studio-output-final.log`를 저장한다.
12. Post-stop Screenshot을 저장한다. MCP Screenshot이 없으면 M02로 수행한다.
13. MCP Export 또는 M03 절차로 Evidence를 `executionEvidenceRoot`에 완성한다.
14. Source-clean Predicate를 다시 실행한다.

## Human Actions

Human Action은 MCP Automated Action으로 표시하지 않는다.

1. M01이 필요한 경우 승인된 build manifest의 SHA-256과 실제 연 Place 경로를 대조하고 Edit Mode Screenshot과 함께 기록한다.
2. M02가 필요한 경우 Screenshot마다 operator, timestamp, Studio state, checkpoint ID와 실제 파일 경로를 기록한다.
3. M03이 필요한 경우 export 전후 파일 목록과 SHA-256 manifest를 기록한다.
4. 실제 Roblox Studio 창과 올바른 Place가 열렸는지 확인한다.
5. Play Solo 전후 상태 전환이 화면에서 확인되는지 관찰한다.
6. Running Screenshot에서 UI가 완전히 비어 있거나 치명적으로 깨져 보이는지 관찰한다.

이 Smoke에서 재미, 입력 감각, 가독성 완성도 또는 전체 UX PASS를 판정하지 않는다.

## Assertions

```text
A01 targetSha == PR HEAD at runtime start
A02 localHead == targetSha
A03 sourceWorkingTreeCleanBefore == true
A04 staticGateApproved == true
A05 each Core Required mapping is MCP_AUTOMATED
    and has a non-empty real actualToolName
    and complete successful invocationEvidence at the required count
A06 each MCP_AUTOMATED mapping has matching actualToolName in the exposed Tool list
    and every invocation has timestamps, result and evidenceFiles
A07 capability fixture F01 and F02 are BLOCKED_EXPECTED
    and F03 is ELIGIBLE_EXPECTED for every Core Required capability
A08 manual-fallback Required capability is not NOT_AVAILABLE
A09 each HUMAN_MANUAL mapping has a complete linked manual-action record and evidence
A10 rojoBuildExitCode == 0
A11 openedPlace matches build manifest
A12 playSolo reached running state within 30s through the mapped MCP Tool
A13 output logs were captured through the mapped MCP Tool while running and after stop
A14 forbidden log occurrences are zero or exactly bounded by log-allowlist.json
A15 running screenshot exists and is readable
A16 stop returned Studio to edit state within 30s through the mapped MCP Tool
A17 evidence bundle metadata references exact targetSha and commandId
A18 sourceWorkingTreeCleanAfter == true
```

모든 Assertion이 충족돼야 `PASS`다. Optional Capability만 빠진 경우에 한해 `PARTIAL`을 사용할 수 있다. Core Required 또는 Hard Precondition이 빠지면 `BLOCKED`다.

## Expected Log Policy

이 Smoke는 앱 전용 PASS 문자열을 꾸며내지 않는다.

```text
expectedLogTokens: []
```

Output에 로그가 없더라도 Play 상태와 Screenshot·State Evidence가 모두 있으면 Smoke를 평가할 수 있다. 다만 Output 읽기 자체는 MCP를 통해 반드시 성공해야 한다.

기본 Forbidden Pattern:

```text
Script timeout
Infinite yield possible
attempt to index nil
attempt to call a nil value
stack overflow
Unhandled
Stack Begin
```

Allowlist 기본값은 빈 배열이다. Allowlist가 필요한 경우 `log-allowlist.json`에 다음 구조를 사용한다.

```json
{
  "commandId": "RVTT-PR2-STUDIO-SMOKE-001",
  "targetSha": "<40-character SHA>",
  "entries": [
    {
      "pattern": "Stack Begin",
      "sourceLog": "studio-output-running.log",
      "startLine": 10,
      "endLine": 18,
      "eventId": "<optional stable event id>",
      "maxOccurrences": 1,
      "actualOccurrences": 1,
      "reason": "<specific intentional test reason>",
      "authority": "<test or policy reference>",
      "approvedBy": "<name>",
      "approvedAt": "<ISO-8601>"
    }
  ]
}
```

Allowlist는 exact pattern, exact log 범위 또는 stable event ID, 허용 횟수와 승인 근거를 모두 가져야 한다. 허용 범위 밖의 동일 Pattern이나 `maxOccurrences` 초과분은 `FAIL`이다. 자유형 설명만으로 Forbidden Log를 숨기지 않는다.

## Screenshot Checkpoints

```text
S01-edit-mode-open.png
S02-play-solo-running.png
S03-post-stop-edit-mode.png
```

각 Screenshot은 Target SHA, Command ID, Attempt, 촬영 시점, 자동 또는 수동 수행 구분과 연결한다.

## State Snapshot Checkpoints

```text
T01-edit-mode-root-snapshot.json
T02-running-root-snapshot.json
T03-post-stop-root-snapshot.json
```

Snapshot은 Optional이다. Capability가 없으면 `NOT_AVAILABLE`로 기록하며 필수 Runtime PASS 주장에 사용하지 않는다.

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
Unexpected repository Source working-tree change
Build failure
Wrong Place or Project
MCP disconnect
Studio crash
Core Required Capability not MCP_AUTOMATED
MCP_AUTOMATED mapping missing real actualToolName
MCP_AUTOMATED mapping missing required successful invocationEvidence
Capability Mapping Fixture result differs from expected disposition
Required With Manual Fallback capability unavailable
Incomplete manual-action record
Forbidden log occurrence outside bounded allowlist
Unhandled error
Play start or stop timeout
Evidence target mismatch
```

## Cleanup Steps

1. Play 중이면 반드시 Mapping에 기록된 MCP Stop Tool 호출을 시도한다.
2. Studio와 MCP 연결 상태를 기록한다.
3. 임시 `/tmp/RVTT-studio-smoke.rbxlx`는 Evidence Hash 기록 후 삭제할 수 있다.
4. 저장소 Source와 PR 파일은 Runtime 과정에서 수정하지 않는다.
5. 실패·중단 Evidence도 `executionEvidenceRoot`에서 삭제하지 않는다.
6. Credential과 Private Data가 포함됐는지 최종 점검한다.
7. Source-clean Predicate 최종 결과를 기록한다.
8. Runtime Result 판정 후 Evidence Archive가 필요하면 별도 승인된 작업으로 `repositoryEvidenceArchive`에 복사한다.

## Evidence Bundle

```text
/tmp/rvtt-studio-evidence/<targetSha>/RVTT-PR2-STUDIO-SMOKE-001/attempt-001/
├─ run-metadata.json
├─ capability-handshake.json
├─ capability-mapping-validation.json
├─ manual-action-records.json
├─ build-manifest.txt
├─ source-clean-before.txt
├─ source-clean-after.txt
├─ play-start-invocation.json
├─ output-running-invocation.json
├─ play-stop-invocation.json
├─ output-final-invocation.json
├─ studio-output-running.log
├─ studio-output-final.log
├─ log-allowlist.json
├─ assertions.json
├─ screenshots/
│  ├─ S01-edit-mode-open.png
│  ├─ S02-play-solo-running.png
│  └─ S03-post-stop-edit-mode.png
├─ state-snapshots/
├─ human-observations.md
├─ evidence-sha256.txt
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
executionEvidenceRoot
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
실제 Mapping된 MCP Tool로 Play Solo Start·Stop이 가능함
실제 Mapping된 MCP Tool로 Output을 읽을 수 있음
각 Core 호출이 timestamp·result·Evidence에 연결됨
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
