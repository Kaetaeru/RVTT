# Roblox Studio MCP Runtime·Playtest 정책

- 상태: `ACTIVE_POLICY_RUNTIME_NOT_CONNECTED_IN_THIS_SESSION`
- 최종 갱신일: 2026-08-07
- 상위 정책: [`Codex 감독형 검수·테스트 정책`](../../docs/remake/product/codex-supervised-review-and-test-policy.md)
- Codex Gate: [`CODEX-REVIEW-TEST-GATE.md`](CODEX-REVIEW-TEST-GATE.md)
- 실행 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 1. 목적

Roblox Studio와 MCP를 연결해 ChatGPT가 작성한 Runtime·Playtest 명령을 재현 가능하게 실행하고, Codex가 실행 전 계획과 실행 후 Evidence를 독립 검수하도록 한다.

```text
ChatGPT
→ Runtime·Playtest 명령 작성

Codex
→ 실행 전 Source·Scenario·Evidence 계획 검수

Roblox Studio MCP
→ 자동화 가능한 Setup·Play·Log·Screenshot·State 수집

Human Playtester
→ 실제 Mouse·Keyboard 입력과 주관적 판단

Codex
→ 실행 후 Evidence·Claim 검수

ChatGPT
→ Finding·버그·UX Risk·제품 결정 분류
```

MCP는 Human Playtest를 대체하지 않는다. Codex는 Roblox Studio Runtime을 대체하지 않는다.

## 2. 연결 상태와 Capability Handshake

Studio Runtime을 시작하기 전에 MCP 연결 상태와 실제 Tool Capability를 기록한다.

```text
McpSessionDescriptor
├─ sessionId
├─ connectedAt
├─ clientName
├─ clientVersion?
├─ studioVersion?
├─ placeId?
├─ universeId?
├─ availableCapabilities[]
├─ unavailableCapabilities[]
├─ connectionScope
└─ evidenceRoot
```

초기 Capability ID:

```text
studio.open_place
studio.open_local_file
studio.start_play_solo
studio.start_server
studio.start_clients
studio.stop_play
studio.execute_test_entrypoint
studio.read_output
studio.clear_output
studio.capture_screenshot
studio.capture_instance_snapshot
studio.read_attributes
studio.set_test_flag
studio.save_local_copy
studio.export_evidence
```

Capability 이름은 연결된 MCP의 실제 Tool에 맞춰 Mapping한다. 위 목록이 존재한다고 가정하지 않는다.

필수 Capability가 없으면 다음 중 하나로 분리한다.

```text
MCP_AUTOMATED
HUMAN_MANUAL
NOT_AVAILABLE
```

`NOT_AVAILABLE` 항목을 통과한 것으로 기록하지 않는다.

## 3. Runtime Command

ChatGPT가 만드는 Runtime Command는 저장소에 Versioned Artifact로 둔다.

```text
RuntimeTestCommand
├─ commandId
├─ targetRepository
├─ pullRequest
├─ targetMode
├─ resolvedTargetSha?
├─ authorityRefs[]
├─ projectFile
├─ placeMode
├─ requiredCapabilities[]
├─ optionalCapabilities[]
├─ serverCount
├─ clientRoles[]
├─ setupSteps[]
├─ automatedActions[]
├─ humanActions[]
├─ assertions[]
├─ expectedLogTokens[]
├─ forbiddenLogTokens[]
├─ screenshotCheckpoints[]
├─ stateSnapshotCheckpoints[]
├─ timeoutPolicy
├─ cleanupSteps[]
└─ evidenceOutputPath
```

`targetMode` 기본값:

```text
CURRENT_PR_HEAD_AT_RUNTIME_START
```

MCP 실행자는 Runtime 시작 직전에 PR HEAD와 Local Checkout HEAD를 비교한다. 일치하지 않으면 실행하지 않는다.

## 4. Preflight Review

Runtime 실행 전 Codex는 활성 ChatGPT 명령을 읽고 PR 댓글로 Preflight Finding을 남긴다.

검수 항목:

- Authority·Slice 계약과 테스트 시나리오가 일치하는가
- 정상 경로와 실패 경로가 모두 있는가
- Client Intent와 Server Authority를 구분하는가
- DM·Player·Observer Projection 누출을 검사하는가
- Retry·Reconnect·Restart·Rollback이 필요한가
- Human Input을 메서드 직접 호출로 대체하지 않는가
- 필요한 MCP Capability와 수동 대체 절차가 명확한가
- PASS·FAIL Log Token과 State Assertion이 모호하지 않은가
- Evidence 경로가 정확한 Target SHA에 연결되는가

`CONFIRMED` BLOCKER·HIGH Finding이 있으면 Runtime을 시작하지 않는다.

## 5. Runtime 실행

### 5.1 준비

```text
활성 PR·HEAD 확인
→ Clean Checkout 확인
→ Pin된 Toolchain 확인
→ Rojo Build
→ Project·Place Open
→ Output Clear
→ Test Flag·Role·Persistence Mode 설정
```

### 5.2 실행

MCP가 지원하는 범위에서 다음을 자동화한다.

```text
Play Solo 또는 Server Start
→ Client 역할 연결
→ Test Entrypoint 실행
→ Runtime 상태 대기
→ Log Token 수집
→ Screenshot·Instance Snapshot
→ Stop·Cleanup
```

실제 Mouse·Keyboard·Focus·Drag·Hover·가독성 검사가 필요한 단계는 Human Action으로 남긴다.

### 5.3 중단 조건

다음이면 즉시 중단하고 Evidence를 보존한다.

```text
Target SHA mismatch
Unexpected Studio crash
Forbidden log token
Authority epoch mismatch
Unhandled error
Client role disclosure leak
DataStore mode mismatch
MCP disconnect
Timeout
```

## 6. Evidence Bundle

각 Runtime 실행은 다음 구조를 권장한다.

```text
implementation/roblox/evidence/<targetSha>/<commandId>/
├─ run-metadata.json
├─ capability-handshake.json
├─ build-manifest.txt
├─ studio-output.log
├─ assertions.json
├─ screenshots/
├─ state-snapshots/
├─ human-observations.md
└─ summary.md
```

`run-metadata.json` 필수 항목:

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

`result`:

```text
PASS
FAIL
BLOCKED
PARTIAL
ABORTED_STALE_HEAD
```

Evidence Bundle에 Credential, Private Rulebook 본문, 실제 사용자 Save Data와 공개하면 안 되는 Asset 원문을 넣지 않는다.

## 7. Post-runtime Review

Runtime 종료 후 Codex는 Evidence Bundle과 Runtime Command를 검수하고 PR 댓글을 남긴다.

검수 항목:

- Evidence의 Target SHA·Project·Session이 일치하는가
- PASS Summary가 실제 Assertion·Log와 일치하는가
- Forbidden Token이나 누락된 Client Role을 숨기지 않았는가
- Screenshot이 주장한 상태를 실제로 보여주는가
- Human Action과 MCP Automated Action이 구분됐는가
- 테스트하지 않은 Persistence·Multi-client·Performance를 PASS로 확대하지 않았는가
- 실패 시 재현 절차와 첫 Root Cause가 보존됐는가

Codex Post-runtime 결과는 다음 Marker를 사용한다.

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
reviewPhase: POST_RUNTIME
```

## 8. Playtest Command

Playtest는 Runtime Test보다 넓은 Human Judgment를 다룬다.

```text
PlaytestCommand
├─ commandId
├─ targetSha
├─ campaignFixture
├─ playerCount
├─ roleAssignments
├─ startingSaveOrSeed
├─ sessionGoals[]
├─ scenarioBeats[]
├─ mandatoryInteractions[]
├─ optionalExploration[]
├─ bugCaptureProtocol
├─ uxObservationPrompts[]
├─ telemetryAndLogs[]
├─ screenshotMoments[]
├─ stopConditions[]
└─ reportTemplate
```

Playtest Scenario는 스크립트대로 모든 행동을 강제하는 Acceptance와 다르다. 필수 Beat는 재현성을 보장하고, 선택 구간은 실제 사용자의 탐색과 진행 판단을 관찰한다.

## 9. Playtest 단계

```text
ChatGPT가 Playtest Command 작성
→ CODEX-ACTIVE-TASK를 PLAYTEST_PREFLIGHT로 설정
→ 사용자가 Codex에 활성 명령 실행 지시
→ Codex가 PR 댓글로 Scenario Finding 게시
→ ChatGPT가 Finding 분류
→ Studio MCP가 Campaign·Scene·Role·Save 준비
→ Human Playtester가 실제 세션 수행
→ MCP가 Log·Screenshot·State Capture
→ Human Report 작성
→ CODEX-ACTIVE-TASK를 POST_PLAYTEST로 전환
→ Codex가 Evidence·Report 검수 댓글 게시
→ ChatGPT가 결과 분류
```

## 10. Human Observation 분류

Human Playtest Report는 최소 다음 범주를 지원한다.

```text
RUNTIME_BUG
UX_FRICTION
DM_WORKLOAD
PLAYER_COMPREHENSION
VISUAL_READABILITY
INPUT_FRICTION
FLOW_PACING
CONTENT_GAP
PERFORMANCE_PERCEPTION
FUN_OR_ENGAGEMENT
PRODUCT_DECISION_REQUIRED
```

`FUN_OR_ENGAGEMENT`는 자동 Test PASS·FAIL이 아니라 사용자·플레이테스터의 주관적 Evidence다.

## 11. 문제 해결 Loop

Runtime 또는 Playtest에서 문제가 발견되면 다음 순서를 사용한다.

```text
Evidence에서 재현 조건 고정
→ ChatGPT Root Cause 범위 지정
→ 필요 시 Codex Source Reviewer 활성화
→ Finding 분류
→ 최소 Patch
→ 자동 CI
→ Codex Delta Review
→ 동일 Runtime Command 재실행
→ Evidence Diff
→ Post-runtime Review
```

재실행 시 Command ID를 유지하고 Attempt 번호를 증가시키거나 새 Command ID에 이전 Attempt를 연결한다.

## 12. 현재 환경 경계

이 정책 문서를 작성한 ChatGPT 세션에는 Roblox Studio MCP Tool이 연결되어 있지 않다. 따라서 이 변경은 Runtime 연결 계약과 향후 실행 흐름을 정의한 것이며, 현재 Roblox Studio 연결·실행·Playtest PASS를 의미하지 않는다.

실제 MCP가 연결되면 첫 작업은 Capability Handshake와 최소 Smoke Command다.

```text
Studio Open
→ 정확한 Place 확인
→ Play Solo Start·Stop
→ Output Log Read
→ Screenshot 1회
→ Evidence Export
```

이 Smoke가 성공한 뒤 Multi-client, Persistence와 Human Playtest 자동화를 단계적으로 추가한다.
