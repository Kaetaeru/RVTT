# PR #2 Codex Delta Review Command

- 상태: `ACTIVE_COMMAND`
- Command ID: `RVTT-PR2-ADR0092-DELTA-001`
- Pull Request: `#2`
- Target Mode: `CURRENT_PR_HEAD_AT_START`
- Review Phase: `DELTA_REVIEW`
- Reviewer Role: `Authority·Slice·Review-Process Delta Reviewer`
- Result Channel: `PR #2 Top-level Conversation Comment`
- Result Marker: `<!-- RVTT_CODEX_REVIEW_RESULT -->`
- Lead Reviewer: ChatGPT

## Role

You are the Delta Reviewer for Kaetaeru/RVTT PR #2.

Do not modify files, approve the PR, mark it ready, or merge it.

Read `.github/CODEX-ACTIVE-TASK.md` first. Resolve the exact current PR #2 head SHA at the start of the task and record it as `targetSha`. Before posting the result, resolve the PR head again. If it changed, post `STALE_TARGET` and do not claim that the new head was reviewed.

## Previous Review

Previous reviewed SHA:

```text
50538dbf3c1c0150f6e4c20f45ff2b948981b1d5
```

Original findings:

```text
AUTH-SLICE-001 — Supply Source priority had dual ownership.
AUTH-SLICE-002 — Actor sourceType stable IDs conflicted.
AUTH-SLICE-003 — Empty Actor Model Catalog had multiple canonical shapes.
```

The user forwarded the original Codex result from Codex Prompt Chat. The repository records this as a temporary exception. This Delta Review must use the new PR-comment result channel.

## Expected Resolutions

### AUTH-SLICE-001

```text
Slice 06
→ Supply Source membership·ACL·disclosure·revision

Slice 07
→ survival.source_priority Frozen Policy
→ Candidate Snapshot
→ Impact Preview
→ Safe Boundary Activation
→ sourceOrderDigest
→ stale Pending Plan·Reservation
```

Slice 06 must not independently store mutable Source priority or own `ReorderSupplySources`.

### AUTH-SLICE-002

Canonical values must be exactly:

```text
rules_package
campaign_homebrew
imported_reference
unknown_draft
```

Legacy aliases must be rejected:

```text
homebrew
campaign_custom
```

ADR, Runtime contract, JSON Schema, AI Prompt and fixtures must agree.

### AUTH-SLICE-003

The canonical Actor Model Catalog must use:

```text
schemaVersion
catalogRevision
packageVersionSet
models
disclosureDigest
```

Empty Registry, ADR example, Runtime contract, JSON Schema, example fixture and Prompt Builder must agree.

## Additional Process Change to Verify

The current head also changes the supervised review handoff.

Expected operational contract:

```text
ChatGPT writes the detailed command in the repository
→ .github/CODEX-ACTIVE-TASK.md points to it
→ user gives Codex only a short execution instruction
→ Codex resolves current PR HEAD
→ Codex posts findings to the target PR comment
→ user asks ChatGPT to inspect Codex feedback
→ ChatGPT reads the PR comments and triages current-SHA findings
```

Roblox Studio MCP and Playtest policy must keep these evidence boundaries:

```text
Codex Review ≠ Studio Runtime
Studio MCP Automation ≠ Human Input
Static CI ≠ Multi-client·Persistence·Performance PASS
Playtest subjective evidence ≠ automated assertion
```

The policy must not claim that Studio MCP is currently connected when no MCP capability evidence exists.

## Primary Files

- `.github/CODEX-ACTIVE-TASK.md`
- `.github/CODEX-REVIEW-COMMAND-TEMPLATE.md`
- `docs/remake/product/codex-supervised-review-and-test-policy.md`
- `docs/remake/audits/codex-reviews/PR-0002-AUTHORITY-SLICE-REVIEW.md`
- `docs/remake/decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md`
- `docs/remake/architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md`
- `docs/remake/architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md`
- `docs/remake/specs/slices/06-inventory-equipment-world-items/ADR-0092-DELTA.md`
- `docs/remake/specs/slices/07-rest-time-downtime-progression/ADR-0092-DELTA.md`
- `implementation/roblox/content-templates/actor-statblock.schema.json`
- `implementation/roblox/content-templates/actor-statblock-source-type-fixtures.json`
- `implementation/roblox/content-templates/actor-statblock-ai-prompt.md`
- `implementation/roblox/content-templates/actor-model-catalog.schema.json`
- `implementation/roblox/content-templates/actor-model-catalog.example.json`
- `implementation/roblox/tooling/validate_content_templates.py`
- `.github/workflows/validate-rvtt-content-templates.yml`
- `implementation/roblox/CODEX-REVIEW-TEST-GATE.md`
- `implementation/roblox/ROBLOX-STUDIO-MCP-TEST-POLICY.md`

## Required Checks

1. Confirm that Slice 06 no longer stores a mutable Supply Source priority.
2. Confirm that Slice 06 no longer owns `ReorderSupplySources`.
3. Confirm that Slice 07 exclusively owns Source ordering through a Frozen Policy Snapshot.
4. Confirm that a changed `sourceOrderDigest` makes pending Settlement Plans and Reservations stale.
5. Confirm Safe Boundary activation, retry, restart, rollback and Ledger immutability are consistent.
6. Confirm all Actor Source Type authorities use the four canonical IDs.
7. Confirm `homebrew` and `campaign_custom` are rejected rather than silently normalized.
8. Confirm the Catalog Schema and empty fixture use the same required fields and stable ordering.
9. Inspect whether `validate_content_templates.py` would fail if any corrected enum or empty Catalog contract drifted.
10. Confirm `.github/CODEX-ACTIVE-TASK.md` provides a deterministic command discovery path.
11. Confirm the result-comment Marker, Command ID and resolved Target SHA are mandatory.
12. Confirm stale-head handling prevents an old result from satisfying the current Merge Gate.
13. Confirm the Studio MCP policy starts with Capability Handshake and records unavailable capabilities as Blocked.
14. Confirm the Playtest policy preserves Human Judgment and does not replace it with Codex or MCP.
15. Confirm no document claims current Roblox Studio MCP connection or Runtime PASS without evidence.
16. Inspect current-SHA CI status but do not treat queued or missing runs as passed.

## Out of Scope

- Implementing ADR-0092 Production Luau
- Connecting or installing a Roblox Studio MCP server
- Executing Roblox Studio in this review
- Visual redesign of the supplemental HTML
- Reopening accepted product decisions without a direct contradiction

## Output Channel

Post one Top-level Conversation Comment on PR #2.

Start exactly with:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
commandId: RVTT-PR2-ADR0092-DELTA-001
targetSha: <resolved 40-character PR head SHA>
reviewPhase: DELTA_REVIEW
reviewerRole: Authority·Slice·Review-Process Delta Reviewer
resultStatus: FINDINGS_REPORTED | NO_SUPPORTED_FINDINGS | STALE_TARGET | BLOCKED
```

## Output

For each original Finding return:

```text
findingId: AUTH-SLICE-NNN
resolution: RESOLVED | PARTIALLY_RESOLVED | UNRESOLVED | REGRESSION_INTRODUCED
evidence:
  - <exact file and line>
remainingRisk: <concise description>
requiredFollowUp: <test or correction, or none>
```

For any new defect directly introduced by the fixes or process policy:

```text
findingId: DELTA-NEW-NNN
severity: BLOCKER | HIGH | MEDIUM | LOW
category: authority | slice_ownership | process | evidence | test | runtime | playtest
claim: <one precise defect>
confidence: high | medium | low
evidence:
  - <exact file and line>
reproductionOrReasoning: <minimal reasoning>
expectedAuthority: <controlling invariant>
minimalCorrection: <smallest correction>
requiredTest: <test or evidence>
```

If no new defect is supported, return:

```text
NO_NEW_FIX_CAUSED_FINDINGS
```

End with:

```text
COVERAGE SUMMARY
- files inspected
- tests or commands executed
- areas not verifiable
- current CI evidence
- Roblox Studio MCP evidence status
- Human Playtest evidence status
```
