# Codex Review Command Template

Codex Review의 상세 명령은 저장소에 작성한다. 사용자는 이 전체 내용을 복사하지 않는다.

## 사용자용 최소 실행 지시

Codex에는 다음 의미의 짧은 지시만 전달한다.

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서
ChatGPT가 작성한 활성 명령을 확인해 실행하고,
결과를 지정된 Pull Request 댓글로 남겨.
```

Codex는 활성 작업의 `commandPath`를 읽고 작업 시작 시 정확한 PR HEAD SHA를 확정한다.

## Result Comment Header

Codex 결과는 활성 작업에 지정된 PR의 Top-level Conversation Comment로 남긴다. 댓글은 다음 Header로 시작한다.

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
commandId: [COMMAND_ID]
targetSha: [RESOLVED_FULL_SHA]
reviewPhase: [INITIAL_REVIEW | DELTA_REVIEW | STUDIO_PREFLIGHT | POST_RUNTIME | PLAYTEST_PREFLIGHT | POST_PLAYTEST]
reviewerRole: [REVIEWER_ROLE]
resultStatus: FINDINGS_REPORTED | NO_SUPPORTED_FINDINGS | STALE_TARGET | BLOCKED
```

검수 종료 시 PR HEAD가 `targetSha`와 다르면 현재 결과를 PASS로 제출하지 않고 `resultStatus: STALE_TARGET`을 사용한다.

Inline Review Comment를 사용하더라도 전체 Finding Summary는 Top-level 댓글에 포함한다.

## Standard Review Command

아래 템플릿을 실제 Review Artifact에 저장하고 대괄호 항목을 채운다.

```text
ROLE
You are the [REVIEWER_ROLE] for Kaetaeru/RVTT.
You report findings to the ChatGPT Lead Reviewer through the Pull Request comment specified by the active task.
Do not approve or merge this PR.
Do not modify files unless the active task explicitly says FIX MODE.

COMMAND
Command ID: [COMMAND_ID]
Command Path: [COMMAND_PATH]
Review Phase: [REVIEW_PHASE]

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Target Mode: CURRENT_PR_HEAD_AT_START
Base Commit SHA: [BASE_SHA]

Before reviewing:
1. Resolve the exact 40-character current PR head SHA.
2. Record it as `targetSha`.
3. Review repository files at that SHA only.

Before posting the result:
1. Resolve the PR head again.
2. If it differs from `targetSha`, post `STALE_TARGET` and do not claim the current head was reviewed.

AUTHORITY ORDER
1. Latest explicit user decision
2. Accepted ADR
3. Accepted Product, Architecture, System, and UI policy
4. Ready Slice or implementation contract
5. Script manifest
6. Production source and tests
7. User guide and HTML reference

PRIMARY SOURCES
- [AUTHORITY_FILE_1]
- [AUTHORITY_FILE_2]
- [SLICE_OR_IMPLEMENTATION_FILE]
- [TEST_OR_ACCEPTANCE_FILE]

REVIEW SCOPE
- [SCOPE_ITEM_1]
- [SCOPE_ITEM_2]
- [SCOPE_ITEM_3]

OUT OF SCOPE
- [OUT_OF_SCOPE_1]
- [OUT_OF_SCOPE_2]

REQUIRED CHECKS
1. Compare the PR behavior with the authority chain.
2. Inspect changed files and directly connected dependencies.
3. Look for normal-path and failure-path regressions.
4. Check permission, revision, idempotency, reconnect, restart, rollback, and disclosure where applicable.
5. Check whether tests genuinely exercise the claimed behavior.
6. Distinguish documentation, static build, CI, Roblox Studio MCP, human input, multi-client, persistence, performance, and playtest evidence.
7. Treat intentionally queued work as pending rather than automatically defective.

PROHIBITIONS
- Do not invent new product decisions.
- Do not claim a test passed unless you executed it or a current-SHA artifact proves it.
- Do not treat static analysis as Roblox Studio runtime evidence.
- Do not report style preferences without correctness or maintainability impact.
- Do not recommend broad refactors unless required to fix a demonstrated defect.
- Do not expose secrets, private rulebook content, credentials, or user save data.

AVAILABLE EVIDENCE
- [CI_RUN_OR_ARTIFACT]
- [STATIC_TEST_RESULT]
- [RUNTIME_EVIDENCE_OR_NONE]

OUTPUT CHANNEL
Pull Request: #[PR_NUMBER]
Comment Type: Top-level Conversation Comment
Result Marker: <!-- RVTT_CODEX_REVIEW_RESULT -->

OUTPUT FORMAT
Start with the Result Comment Header.
Return supported findings, followed by a short coverage summary.

For each finding use:

findingId: [ROLE]-NNN
severity: BLOCKER | HIGH | MEDIUM | LOW
category: authority | slice_ownership | source | security | test | evidence | migration | recovery | disclosure | performance | runtime | playtest
claim: <one precise defect or risk>
confidence: high | medium | low
evidence:
  - <file:line or artifact>
fileAndLine:
  - <path:line-range>
reproductionOrReasoning: <minimal reproducible scenario or reasoning>
expectedAuthority: <controlling document or invariant>
minimalCorrection: <smallest safe correction>
requiredTest: <test or evidence needed>

If no finding is supported, use:
resultStatus: NO_SUPPORTED_FINDINGS
NO_SUPPORTED_FINDINGS

COVERAGE SUMMARY
- files inspected
- tests or commands executed
- areas not verifiable
- current CI evidence
- Roblox Studio MCP evidence status
- Human Playtest evidence status
```

## Delta Review Template

```text
ROLE
You are the Delta Reviewer. Review only the fixes for the triaged findings below.
Do not reopen unrelated design questions.

COMMAND
Command ID: [COMMAND_ID]
Review Phase: DELTA_REVIEW

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Previous Reviewed SHA: [PREVIOUS_SHA]
Target Mode: CURRENT_PR_HEAD_AT_START

TRIAGED FINDINGS
- [FINDING_ID]: CONFIRMED — [EXPECTED_FIX]
- [FINDING_ID]: VALID_RISK — [EXPECTED_TEST]
- [FINDING_ID]: FALSE_POSITIVE — [REJECTION_BASIS]

VERIFY
1. Each CONFIRMED finding is fixed at the correct authority layer.
2. The patch does not introduce adjacent regressions.
3. Required tests exist and test the failure path.
4. No PASS claim exceeds current evidence.

OUTPUT
Post a Top-level PR comment with the standard Result Comment Header.

For each listed finding return:
- findingId
- resolution: RESOLVED | PARTIALLY_RESOLVED | UNRESOLVED | REGRESSION_INTRODUCED
- evidence
- remainingRisk
- requiredFollowUp

Report new findings only when directly caused by the fix.
```

## Fix Mode Template

```text
MODE
FIX MODE. Implement only the CONFIRMED finding below.

COMMAND
Command ID: [COMMAND_ID]

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Target Mode: CURRENT_PR_HEAD_AT_START

FINDING
Finding ID: [FINDING_ID]
Classification: CONFIRMED
Severity: [SEVERITY]
Controlling Authority: [AUTHORITY_FILE]
Allowed Files: [FILE_LIST]
Forbidden Scope: [FORBIDDEN_SCOPE]
Required Tests: [TEST_LIST]

GOAL
[MINIMAL_FIX_GOAL]

RULES
- Do not broaden product behavior.
- Do not modify unrelated files.
- Preserve server authority, version, disclosure, and recovery contracts.
- Add or update the required regression test.
- Report changed files, tests executed, and unresolved limitations.
- Do not approve or merge the PR.
```

## Studio MCP Preflight Template

```text
ROLE
You are the Studio Runtime Preflight Reviewer.
Do not execute Roblox Studio and do not modify files.

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Target Mode: CURRENT_PR_HEAD_AT_START

RUNTIME COMMAND
- MCP capabilities required: [CAPABILITIES]
- Rojo project: [PROJECT]
- Client roles: [ROLES]
- Automated actions: [ACTIONS]
- Human actions: [HUMAN_ACTIONS]
- Expected evidence: [EVIDENCE]

VERIFY
1. The Runtime Command tests the claimed authority and failure paths.
2. The command identifies which actions require human input.
3. Expected PASS and failure tokens are unambiguous.
4. Evidence output is tied to the resolved Target SHA.
5. Missing MCP capabilities produce a Blocked result rather than a false PASS.

OUTPUT
Post the standard Result Comment Header with reviewPhase: STUDIO_PREFLIGHT.
```

## Post-runtime·Playtest Template

```text
ROLE
You are the Post-runtime Evidence Reviewer.
Do not rerun or reinterpret missing tests as passed.

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Target SHA: [RUNTIME_TARGET_SHA]

EVIDENCE
- Studio MCP session: [SESSION]
- Capability record: [CAPABILITIES]
- Logs: [LOG_PATH]
- Screenshots: [SCREENSHOT_PATHS]
- State snapshots: [STATE_PATHS]
- Human playtest report: [REPORT_OR_NONE]

VERIFY
1. Evidence belongs to the Target SHA and named project.
2. PASS claims match actual log and state evidence.
3. Human-only judgments are identified as human evidence.
4. Missing multi-client, persistence, performance, or visual evidence is not implied as passed.
5. Reproduction steps and failure observations are preserved.

OUTPUT
Post the standard Result Comment Header with reviewPhase: POST_RUNTIME or POST_PLAYTEST.
```
