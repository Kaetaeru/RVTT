# PR #2 Codex Studio Preflight Review 001 Command

## Role

You are the Studio Runtime Preflight Reviewer for `Kaetaeru/RVTT`.

Read `.github/CODEX-ACTIVE-TASK.md`, inspect the exact current PR HEAD, and review the prepared Studio MCP Smoke Runtime Command. Post the result as the specified PR #2 top-level comment.

Do not modify files, run Roblox Studio, claim MCP connection, approve, mark ready, or merge.

## Command

```text
commandId: RVTT-PR2-STUDIO-PREFLIGHT-001
reviewPhase: STUDIO_PREFLIGHT
reviewerRole: Studio Runtime Preflight Reviewer
```

## Target

```text
Repository: Kaetaeru/RVTT
Pull Request: #2
Target Mode: CURRENT_PR_HEAD_AT_START
Runtime Command ID: RVTT-PR2-STUDIO-SMOKE-001
Runtime Command Path: implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md
```

Resolve the exact 40-character PR HEAD before review and again immediately before posting. If it changes, post `STALE_TARGET` and do not claim the new HEAD was reviewed.

## Authority

Review against the exact target-SHA versions of:

```text
implementation/roblox/ROBLOX-STUDIO-MCP-TEST-POLICY.md
implementation/roblox/CODEX-REVIEW-TEST-GATE.md
docs/remake/product/codex-supervised-review-and-test-policy.md
implementation/roblox/EXECUTION-TEST-RULES.md
implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md
.github/CODEX-ACTIVE-TASK.md
```

## Current Evidence Boundary

The following is known before this review:

```text
Codex Delta 004 result: current-SHA NO_SUPPORTED_FINDINGS at its reviewed SHA
Validate remake documentation: completed/success at 0ee26425997c41ff674353be2acbb2627a8da66a
Validate RVTT content templates: completed/success at 0ee26425997c41ff674353be2acbb2627a8da66a
Validate RVTT implementation: NOT VERIFIED
Implementation attempt 1 and attempt 2: both jobs cancelled before Step execution
GitHub annotation: The job was not acquired by Runner of type hosted even after multiple attempts
Roblox Studio MCP connected in ChatGPT authoring session: no
Capability Handshake: none
Runtime execution: none
Human Playtest: none
```

Later review-artifact commits move the PR HEAD. Re-check all current-SHA evidence rather than reusing an older SHA as current proof.

The hosted Runner cancellation is infrastructure evidence, not an implementation test failure. It is also not a PASS because no Step executed.

## Review Scope

Review only the readiness, safety, authority alignment and evidence design of `RVTT-PR2-STUDIO-SMOKE-001`.

Confirm whether the command:

1. Uses `CURRENT_PR_HEAD_AT_RUNTIME_START` and requires exact PR/Local HEAD equality.
2. Prevents Runtime start when the current-SHA static implementation Gate remains unverified, unless an explicitly approved equivalent Local Static Gate exists.
3. Distinguishes Capability Handshake from Runtime PASS.
4. Maps actual MCP tools instead of assuming listed Capability names exist.
5. Classifies every capability as `MCP_AUTOMATED`, `HUMAN_MANUAL` or `NOT_AVAILABLE`.
6. Blocks on missing Required Capability instead of silently bypassing it.
7. Separates MCP automation from real Human observation.
8. Uses the smallest valid Smoke scope: Place Open, Play Solo Start/Stop, Output Read, Screenshot and Evidence Export.
9. Does not expand Smoke PASS into Multi-client, Persistence, ADR-0092 Runtime, Performance, Accessibility, Human Playtest or Merge Ready claims.
10. Defines objective Assertions, timeouts, stop conditions and cleanup.
11. Captures target-SHA-linked metadata, Build manifest, Output, Screenshots and capability evidence.
12. Protects credentials, private rules content, private assets and real user Save Data.
13. Does not require invented app-specific PASS log tokens.
14. Handles common error/stack patterns without hiding errors behind an undefined allowlist.
15. Leaves repository Source unchanged during Runtime execution.

## Required Verification

1. Fetch every Authority file and Runtime Command from the exact target SHA.
2. Confirm the Runtime Command is a Versioned Artifact in the repository.
3. Check every required `RuntimeTestCommand` field from the MCP policy and identify missing or ambiguous fields.
4. Check Capability requirements against the policy's initial logical Capability set.
5. Verify Hard Preconditions cannot be interpreted as permission to skip current-SHA static validation merely because GitHub Actions is unavailable.
6. Verify the Build and Place-open flow identifies the exact built Place and SHA.
7. Verify `serverCount`, `clientRoles`, `persistenceMode`, Result semantics and Evidence path are explicit.
8. Verify Required Capability missing means `BLOCKED`, not `PARTIAL` or PASS.
9. Verify Human Actions are observable and do not replace required automated evidence without disclosure.
10. Verify Forbidden Log handling has a bounded, evidence-linked allowlist rule.
11. Verify Timeout and Immediate Stop Conditions preserve failure Evidence.
12. Inspect current-SHA GitHub Actions and report statuses accurately. Do not treat queued, cancelled, infrastructure-failed or unexecuted Jobs as PASS.
13. Do not execute Studio, MCP, Rojo Build or Human Playtest as part of this review unless needed only to inspect repository text. This is a plan review, not Runtime execution.
14. Report only direct, supported findings. Do not request broad refactors or queued product features.

## Explicit Non-scope

```text
Production Runtime execution
MCP Capability Handshake execution
Roblox Studio Open or Play
Multi-client execution
Persistence execution
ADR-0092 Survival or Actor Import implementation validation
Performance or Soak testing
Human Playtest
PR approval, Ready transition or Merge
```

## Finding Standard

Report a Finding only when the Runtime Command creates a concrete safety, reproducibility, authority, evidence or claim-boundary defect.

Each new Finding must include:

```text
findingId
severity: BLOCKER | HIGH | MEDIUM | LOW
category: authority | safety | capability | runtime-plan | evidence | test | privacy | claim-boundary
claim
confidence
evidence
fileAndLine
reproductionOrReasoning
expectedAuthority
minimalCorrection
requiredTest
```

Suggested stable IDs when applicable:

```text
STUDIO-PREFLIGHT-001 — Static Gate prerequisite can be bypassed or is ambiguous
STUDIO-PREFLIGHT-002 — Required MCP Capability is assumed or silently bypassed
STUDIO-PREFLIGHT-003 — Human and MCP evidence are conflated
STUDIO-PREFLIGHT-004 — Assertion, timeout, cleanup or evidence contract is non-reproducible
STUDIO-PREFLIGHT-005 — Smoke PASS claim expands beyond tested scope
STUDIO-PREFLIGHT-006 — Evidence privacy or target-SHA linkage is unsafe
```

Do not invent a Finding solely to use these IDs.

## Preflight Disposition

After Findings, report exactly one:

```text
preflightDisposition: READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE
preflightDisposition: NEEDS_CORRECTION
preflightDisposition: BLOCKED
```

`READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE` means the plan is acceptable but does not mean current-SHA Static Gate PASS, MCP connected or Runtime PASS.

Use `BLOCKED` when repository evidence needed for plan review cannot be accessed, the target became stale, or the command is fundamentally non-executable without a product decision.

## Output

Start the PR #2 top-level comment with:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
commandId: RVTT-PR2-STUDIO-PREFLIGHT-001
targetSha: <40-character SHA>
reviewPhase: STUDIO_PREFLIGHT
reviewerRole: Studio Runtime Preflight Reviewer
resultStatus: FINDINGS_REPORTED | NO_SUPPORTED_FINDINGS | STALE_TARGET | BLOCKED
```

Then include:

```text
runtimeCommandId: RVTT-PR2-STUDIO-SMOKE-001
preflightDisposition: <one allowed value>
staticGateStatus: VERIFIED | UNVERIFIED_INFRA_BLOCKED | FAILED | STALE
mcpCapabilityHandshakeStatus: NOT_EXECUTED
runtimeExecutionStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
```

If no supported findings exist, state `NO_SUPPORTED_FINDINGS` and still report any execution prerequisites as prerequisites rather than defects.

Finish with:

```text
COVERAGE SUMMARY
- files inspected
- commands or checks executed
- current-SHA CI evidence
- unresolved prerequisites
- Runtime/MCP/Human evidence status
```
