# PR #2 Codex Studio Preflight Delta Review 001 Command

## Role

You are the Studio Runtime Preflight Delta Reviewer for `Kaetaeru/RVTT`.

Read `.github/CODEX-ACTIVE-TASK.md`, inspect the exact current PR HEAD, and verify only the focused corrections to `RVTT-PR2-STUDIO-SMOKE-001`. Post the result as the specified PR #2 top-level comment.

Do not modify files, run Roblox Studio, claim MCP connection, approve, mark ready, or merge.

## Command

```text
commandId: RVTT-PR2-STUDIO-PREFLIGHT-DELTA-001
reviewPhase: STUDIO_PREFLIGHT_DELTA_REVIEW
reviewerRole: Studio Runtime Preflight Delta Reviewer
```

## Target

```text
Repository: Kaetaeru/RVTT
Pull Request: #2
Target Mode: CURRENT_PR_HEAD_AT_START
Previous Reviewed SHA: 45415fb1f94f3a32ca4ef0bc1cff80d8c6a7cee4
Runtime Fix Commit: 7cdb9e83989666f430447bcebcb61f3049dda962
Runtime Command ID: RVTT-PR2-STUDIO-SMOKE-001
Runtime Command Path: implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md
Triage Path: docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-001-TRIAGE.md
Previous Result: https://github.com/Kaetaeru/RVTT/pull/2#issuecomment-5208363657
```

Resolve the exact 40-character PR HEAD before review and immediately before posting. If it changes, post `STALE_TARGET`.

## Authority

Review against exact target-SHA versions of:

```text
implementation/roblox/ROBLOX-STUDIO-MCP-TEST-POLICY.md
implementation/roblox/CODEX-REVIEW-TEST-GATE.md
docs/remake/product/codex-supervised-review-and-test-policy.md
implementation/roblox/EXECUTION-TEST-RULES.md
implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md
docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-001-TRIAGE.md
.github/CODEX-ACTIVE-TASK.md
```

## Findings Under Review

### STUDIO-PREFLIGHT-003

```text
previousClassification: CONFIRMED
expectedResolution: RESOLVED
```

Verify that:

1. `studio.start_play_solo`, `studio.stop_play` and `studio.read_output` are Core Required and must be `MCP_AUTOMATED`.
2. A Human action cannot satisfy MCP Smoke PASS for those Core Required capabilities.
3. Place Open, Screenshot and Evidence Export manual fallbacks have explicit action IDs, operator, timing, exact action, before/after state and evidence linkage.
4. Assertions block incomplete or undisclosed manual fallback execution.

### STUDIO-PREFLIGHT-004

```text
previousClassification: CONFIRMED
expectedResolution: RESOLVED
```

Verify that:

1. Runtime Evidence is written outside the Git working tree during execution.
2. Source-clean checks include tracked and untracked repository changes.
3. Normal Evidence creation cannot trigger the Source-dirty stop condition.
4. Evidence archival into the repository is a separate post-result approved operation.
5. An arbitrary repository file modification still causes BLOCKED or FAIL.

### STUDIO-PREFLIGHT-007

```text
previousClassification: CONFIRMED
expectedResolution: RESOLVED
```

Verify that:

1. Forbidden Log exceptions use a structured `log-allowlist.json` artifact.
2. Entries bind exact pattern, source log, line span or stable event ID, maximum and actual occurrences, reason, authority and approval.
3. Additional matching occurrences outside the approved scope remain FAIL.
4. A free-form explanation alone cannot suppress a Forbidden Pattern.

## Required Verification

1. Fetch the exact target-SHA Runtime Command and triage artifact.
2. Compare the Runtime Command at `45415fb1f94f3a32ca4ef0bc1cff80d8c6a7cee4` with the Runtime Fix Commit, excluding later triage and review-artifact commits.
3. Trace each of the three original reproductions through the corrected assertions, stop conditions and Evidence artifacts.
4. Confirm no correction weakens current-SHA Static Gate, target-SHA equality, privacy, cleanup or Claim Boundary requirements.
5. Confirm no Studio Runtime, Capability Handshake, Rojo Build or Human Playtest was executed by these documentation changes.
6. Inspect current-SHA GitHub Actions. Do not treat queued, absent, cancelled, infrastructure-failed or unexecuted Jobs as PASS.
7. Report new fix-caused findings only with direct evidence and keep them limited to the correction diff.

## Explicit Non-scope

```text
Studio execution
MCP Capability Handshake execution
Rojo Build execution
Human Playtest
Multi-client or Persistence
ADR-0092 feature Runtime validation
Broad rewrite of the Runtime policy
PR approval, Ready transition or Merge
```

## Output

Start with:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
commandId: RVTT-PR2-STUDIO-PREFLIGHT-DELTA-001
targetSha: <40-character SHA>
reviewPhase: STUDIO_PREFLIGHT_DELTA_REVIEW
reviewerRole: Studio Runtime Preflight Delta Reviewer
resultStatus: FINDINGS_REPORTED | NO_SUPPORTED_FINDINGS | STALE_TARGET | BLOCKED
```

Then report each finding:

```text
findingId: STUDIO-PREFLIGHT-003 | STUDIO-PREFLIGHT-004 | STUDIO-PREFLIGHT-007
resolution: RESOLVED | PARTIALLY_RESOLVED | UNRESOLVED | REGRESSION_INTRODUCED
evidence:
  - <exact file, line and reasoning>
remainingRisk: <concise>
requiredFollowUp: <concise or none>
```

Then report exactly one:

```text
preflightDisposition: READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE
preflightDisposition: NEEDS_CORRECTION
preflightDisposition: BLOCKED
```

`READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE` is a plan disposition only. It does not mean Static Gate PASS, MCP connection or Runtime PASS.

Finish with:

```text
COVERAGE SUMMARY
- files inspected
- correction diff inspected
- commands or checks executed
- current-SHA CI evidence
- unresolved prerequisites
- Runtime/MCP/Human evidence status
```
