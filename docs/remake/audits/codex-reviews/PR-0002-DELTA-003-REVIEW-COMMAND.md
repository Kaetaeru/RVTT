# PR #2 Codex Delta Review 003 Command

## Role

You are the Event-qualified Workflow Drift Delta Reviewer for `Kaetaeru/RVTT`.

You report the result through the Pull Request comment specified by `.github/CODEX-ACTIVE-TASK.md`.

Do not modify files, approve the PR, mark it ready, or merge it.

## Command

```text
commandId: RVTT-PR2-ADR0092-DELTA-003
reviewPhase: DELTA_REVIEW
```

## Target

```text
Repository: Kaetaeru/RVTT
Pull Request: #2
Target Mode: CURRENT_PR_HEAD_AT_START
Base Commit: c4347e5adafe72b3bdf98a9675f6c155a3b95b33
Previous Reviewed SHA: 0c343fbc911310b058466fc3a68b91835df33e29
Fix Commit: e8ee33f4c82de646a7cc7ae2670066d57e3a9361
```

Before reviewing:

1. Resolve the exact current PR #2 HEAD SHA.
2. Record it as `targetSha`.
3. Read and review files at that SHA only.

Before posting:

1. Resolve PR #2 HEAD again.
2. If it differs from `targetSha`, post `resultStatus: STALE_TARGET` and stop.

## Triaged Findings

### DELTA-NEW-001

```text
classification: CONFIRMED_REMAINING
severity: MEDIUM
category: test
```

Expected correction:

- Workflow Authority paths must be validated separately inside the `pull_request` and `push` events.
- Removing a path from one event must not be hidden by the same path remaining in the other event.
- Normal Workflow content must not fail because of the negative self-test.

### DELTA-NEW-002

```text
classification: DUPLICATE
representativeFinding: DELTA-NEW-001
```

Confirm that the concrete always-fail reproduction is removed by the representative fix.

## Files in Scope

- `implementation/roblox/tooling/validate_content_templates.py`
- `.github/workflows/validate-rvtt-content-templates.yml`
- `docs/remake/audits/codex-reviews/PR-0002-DELTA-002-TRIAGE.md`
- `.github/CODEX-ACTIVE-TASK.md`

## Required Verification

1. Confirm `event_section_bounds` isolates one Workflow event without crossing into the next event or a top-level key.
2. Confirm `extract_event_paths` reads `paths` separately for `pull_request` and `push`.
3. Confirm `workflow_trigger_errors` emits event-qualified errors.
4. Confirm `remove_event_path` removes only the requested path from the requested event.
5. Confirm the negative self-test covers all four combinations:
   - pull_request × ADR path
   - pull_request × Runtime path
   - push × ADR path
   - push × Runtime path
6. Confirm each mutation requires its exact event-qualified `WORKFLOW_TRIGGER_DRIFT` error.
7. Execute the Validator against the target-SHA repository checkout when possible and report the exact exit code and output.
8. Confirm the normal target-SHA Workflow produces `exit 0` rather than the previous always-fail self-test error.
9. Independently remove each Authority path from each event and confirm the expected event-qualified error occurs.
10. Check current-SHA GitHub Actions without treating queued, pending, running or cancelled jobs as PASS.
11. Confirm no Production Runtime, Roblox Studio MCP or Human Playtest evidence is claimed.
12. Report new findings only when directly caused by this fix.

## Out of Scope

- Reopening resolved Source Type or Empty Catalog authority decisions
- Implementing Actor Importer or Prompt Builder Runtime
- Roblox Studio execution
- General refactoring or style preferences
- PR approval, Ready transition or Merge

## Result Comment Format

Start the PR #2 top-level comment with:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
commandId: RVTT-PR2-ADR0092-DELTA-003
targetSha: <40-character SHA>
reviewPhase: DELTA_REVIEW
reviewerRole: Event-qualified Workflow Drift Delta Reviewer
resultStatus: FINDINGS_REPORTED | NO_SUPPORTED_FINDINGS | STALE_TARGET | BLOCKED
```

Then report:

```text
findingId: DELTA-NEW-001
resolution: RESOLVED | PARTIALLY_RESOLVED | UNRESOLVED | REGRESSION_INTRODUCED
evidence:
  - <file:line and command result>
remainingRisk: <concise>
requiredFollowUp: <concise or none>

findingId: DELTA-NEW-002
resolution: RESOLVED_AS_DUPLICATE | STILL_REPRODUCIBLE | REGRESSION_INTRODUCED
evidence:
  - <file:line and command result>
remainingRisk: <concise>
requiredFollowUp: <concise or none>
```

If no fix-caused new finding is supported, include:

```text
NO_NEW_FIX_CAUSED_FINDINGS
```

Finish with:

```text
COVERAGE SUMMARY
- files inspected
- tests or commands executed
- current CI evidence
- areas not verifiable
- Roblox Studio MCP evidence status
- Human Playtest evidence status
```
