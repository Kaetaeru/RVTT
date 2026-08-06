# PR #2 Codex Studio Preflight Delta Review 002 Command

## Role

You are the final Studio Runtime Preflight Delta Reviewer for `Kaetaeru/RVTT`.

Read `.github/CODEX-ACTIVE-TASK.md`, inspect the exact current PR HEAD, and review only the correction for `STUDIO-PREFLIGHT-008` plus regression of the previously resolved Studio Preflight findings.

Post one top-level result comment on PR #2. Do not modify files, run Roblox Studio, claim MCP connection, approve, mark ready, or merge.

## Command

```text
commandId: RVTT-PR2-STUDIO-PREFLIGHT-DELTA-002
reviewPhase: STUDIO_PREFLIGHT_DELTA_REVIEW
reviewerRole: Final Studio Runtime Preflight Delta Reviewer
```

## Target

```text
Repository: Kaetaeru/RVTT
Pull Request: #2
Target Mode: CURRENT_PR_HEAD_AT_START
Previous Reviewed SHA: 91de98ba72a5a119135ff6de71df82fe0d99e569
Runtime Fix Commit: 23ce78ea7fe6a04242424ce9aa9d16f01d595bfa
Runtime Command ID: RVTT-PR2-STUDIO-SMOKE-001
Runtime Command Path: implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md
Triage Path: docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-DELTA-001-TRIAGE.md
```

Resolve the exact 40-character PR HEAD before review and immediately before posting. If it changes, post `STALE_TARGET` and do not claim the new HEAD was reviewed.

## Authority

Read exact target-SHA versions of:

```text
.github/CODEX-ACTIVE-TASK.md
implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md
docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-DELTA-001-TRIAGE.md
implementation/roblox/ROBLOX-STUDIO-MCP-TEST-POLICY.md
implementation/roblox/CODEX-REVIEW-TEST-GATE.md
docs/remake/product/codex-supervised-review-and-test-policy.md
implementation/roblox/EXECUTION-TEST-RULES.md
```

## Finding Under Review

### STUDIO-PREFLIGHT-008

```text
previousClassification: CONFIRMED
expectedResolution: RESOLVED
severity: MEDIUM
category: capability
```

Original defect: a Core mapping could declare `classification=MCP_AUTOMATED` without a real `actualToolName` or invocation evidence and still satisfy the previous Core assertion.

Expected correction:

1. Every `MCP_AUTOMATED` mapping conditionally requires a non-empty actual Tool name that exactly matches a Tool exposed by the connected MCP.
2. Every automated mapping conditionally requires structured invocation evidence with start/end timestamps, result and evidence file linkage.
3. Core minimum successful invocation counts are explicit:
   - Play Start: 1
   - Play Stop: 1
   - Output Read: 2, running and post-stop
4. A logical Capability ID copied into `actualToolName`, or a generic availability string without Tool identity, is rejected.
5. Missing Tool identity or invocation evidence blocks Runtime rather than producing PASS or PARTIAL.
6. Fixture checks cover missing `actualToolName`, missing invocation evidence and a complete valid mapping.

## Required Verification

1. Fetch the Runtime Command from the exact target SHA.
2. Compare `91de98ba...` to Runtime Fix Commit `23ce78ea...` and confirm the production change is limited to the Runtime plan document; later commits may contain only triage, command and active-pointer artifacts.
3. Reproduce the original defect against the corrected contract:
   - Core `MCP_AUTOMATED` with missing `actualToolName` must be `BLOCKED`.
   - Core `MCP_AUTOMATED` with empty invocation evidence must be `BLOCKED`.
   - Core mapping with a logical alias or generic `available` value instead of an exposed Tool identity must be `BLOCKED`.
4. Confirm a complete mapping is only eligible when actual Tool identity, timestamps, successful result and evidence files are all present.
5. Confirm `studio.read_output` requires two distinct successful invocation records linked to running and post-stop logs.
6. Confirm Assertions and Immediate Stop Conditions enforce these requirements rather than merely describing them.
7. Confirm Capability Mapping Fixture Checks record expected dispositions for F01, F02 and F03.
8. Confirm the Evidence Bundle contains the mapping validation and individual Core invocation artifacts.
9. Recheck that the corrections for `STUDIO-PREFLIGHT-003`, `STUDIO-PREFLIGHT-004` and `STUDIO-PREFLIGHT-007` remain intact.
10. Inspect current-SHA GitHub Actions accurately. Absent, queued, cancelled, infrastructure-failed or unexecuted checks are not PASS.
11. Do not execute Studio, MCP, Rojo Build or Human Playtest. This is the final plan Delta review only.
12. Report new findings only when directly caused by the Runtime Fix Commit and supported by a concrete reproduction. Do not extend the plan-review loop for style, optional refinement or queued product work.

## Explicit Non-scope

```text
Roblox Studio execution
MCP Capability Handshake execution
Rojo Build execution
Play Solo execution
Multi-client or Persistence execution
Human Playtest
Production feature validation
PR approval, Ready transition or Merge
```

## Final Disposition

Report exactly one:

```text
preflightDisposition: READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE
preflightDisposition: NEEDS_CORRECTION
preflightDisposition: BLOCKED
```

Use `READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE` when `STUDIO-PREFLIGHT-008` is resolved, the prior three resolutions have not regressed, and no new fix-caused BLOCKER/HIGH/MEDIUM finding is supported.

This disposition does not mean Static Gate PASS, MCP connected, Studio Runtime PASS or Human Playtest PASS.

## Output

Start the PR #2 top-level comment with:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
commandId: RVTT-PR2-STUDIO-PREFLIGHT-DELTA-002
targetSha: <40-character SHA>
reviewPhase: STUDIO_PREFLIGHT_DELTA_REVIEW
reviewerRole: Final Studio Runtime Preflight Delta Reviewer
resultStatus: FINDINGS_REPORTED | NO_SUPPORTED_FINDINGS | STALE_TARGET | BLOCKED
```

Then report:

```text
findingId: STUDIO-PREFLIGHT-008
resolution: RESOLVED | PARTIALLY_RESOLVED | UNRESOLVED | REGRESSION_INTRODUCED
evidence:
  - <exact contract and reproduction evidence>
remainingRisk: <concise>
requiredFollowUp: <concise or none>
```

Also state whether `STUDIO-PREFLIGHT-003`, `004` and `007` remain resolved. Finish with:

```text
preflightDisposition: <one allowed value>
staticGateStatus: VERIFIED | UNVERIFIED | FAILED | STALE
mcpCapabilityHandshakeStatus: NOT_EXECUTED
runtimeExecutionStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED

COVERAGE SUMMARY
- files inspected
- comparison and reproduction performed
- current-SHA CI evidence
- remaining prerequisites
- Runtime/MCP/Human evidence status
```
