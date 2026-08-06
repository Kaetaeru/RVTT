# PR #2 Codex Delta Review 002 Command

## Role

You are the Test·Authority Drift Delta Reviewer for `Kaetaeru/RVTT`.

You report the result through the Pull Request comment specified by `.github/CODEX-ACTIVE-TASK.md`.

Do not modify files, approve the PR, mark it ready, or merge it.

## Command

```text
commandId: RVTT-PR2-ADR0092-DELTA-002
reviewPhase: DELTA_REVIEW
```

## Target

```text
Repository: Kaetaeru/RVTT
Pull Request: #2
Target Mode: CURRENT_PR_HEAD_AT_START
Base Commit: c4347e5adafe72b3bdf98a9675f6c155a3b95b33
Previous Reviewed SHA: 6052808ab36adf1918c056792eaf132bf47c8528
```

Before reviewing:

1. Resolve the exact current PR #2 HEAD SHA.
2. Record it as `targetSha`.
3. Read and review files at that SHA only.

Before posting:

1. Resolve PR #2 HEAD again.
2. If it differs from `targetSha`, post `resultStatus: STALE_TARGET` and stop.

## Triaged Finding

### DELTA-NEW-001

```text
classification: CONFIRMED
severity: MEDIUM
category: test
```

Expected correction:

- Content Template validation must compare machine-readable actor Source Type and Empty Catalog fixtures with the Accepted ADR and Actor Import Runtime contract.
- The content-template Workflow must run when either Authority document changes.
- Negative regression checks must prove that ADR Source Type drift, Runtime Empty Catalog drift and missing Workflow Authority paths are detected.

## Files in Scope

- `implementation/roblox/tooling/validate_content_templates.py`
- `.github/workflows/validate-rvtt-content-templates.yml`
- `implementation/roblox/content-templates/actor-statblock-source-type-fixtures.json`
- `implementation/roblox/content-templates/actor-model-catalog.example.json`
- `docs/remake/decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md`
- `docs/remake/architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md`
- `docs/remake/audits/codex-reviews/PR-0002-DELTA-001-TRIAGE.md`

## Required Verification

1. Confirm the Validator resolves the repository root correctly from its own path.
2. Confirm it reads both Authority documents and the Workflow file rather than only Template files.
3. Confirm canonical Source Type ordering comes from `canonicalAllowed` and legacy aliases come from `legacyRejected`.
4. Confirm Empty Catalog canonical JSON comes from the actual example fixture and is compared exactly against both documents.
5. Confirm the ADR no-source policy and Runtime full Source Type block are separately checked.
6. Confirm Prompt checks require exact backticked canonical IDs and legacy aliases rather than accepting `homebrew` only as a substring of `campaign_homebrew`.
7. Confirm the Workflow path filters include both Authority documents for Pull Request and Push events.
8. Confirm the Validator also verifies those Workflow path entries.
9. Inspect the three negative regression self-tests:
   - mutated ADR Source Type policy
   - mutated Runtime Empty Catalog block
   - removed Workflow ADR path
10. Confirm each self-test checks the intended error code and cannot pass merely because an unrelated error already exists.
11. Execute the Validator when possible and report the exact result.
12. Review the current-SHA GitHub Actions state without treating queued or running jobs as PASS.
13. Confirm the fix does not claim Production Runtime, Roblox Studio, MCP or Human Playtest evidence.

## Out of Scope

- Implementing Actor Importer or Prompt Builder Production Runtime
- Roblox Studio execution
- Adding new Source Type values
- Changing the canonical Empty Catalog format
- Reopening resolved `AUTH-SLICE-001`, `AUTH-SLICE-002` or `AUTH-SLICE-003` without a fix-caused regression
- General style refactoring

## Result Comment Format

Start the PR #2 top-level comment with:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
commandId: RVTT-PR2-ADR0092-DELTA-002
targetSha: <40-character SHA>
reviewPhase: DELTA_REVIEW
reviewerRole: Test·Authority Drift Delta Reviewer
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
```

Report fix-caused new findings only when supported by direct evidence.

If no new finding is supported, include:

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
