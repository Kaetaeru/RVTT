# RVTT Codex Fix Command — Phase 9 Control Projection Revision

- commandId: `RVTT-PR2-PHASE9-CONTROL-REVISION-FIX-001`
- taskType: `IMPLEMENTATION_FIX`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_9_CONTROL_REVISION_FIX`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_PHASE9_REVISION_FIX_RESULT -->`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`

## 1. Goal

Do not expand Phase 9 or implement Phase 10.

Close the final reconciliation edge case found by ChatGPT after `RVTT-PR2-PHASE9-QUEUE-RECONCILIATION-001`.

Current source correctly fixes recovery dedup, terminal failure retention, and ordinary control projection reconciliation, but `dm.assign_control` can still be marked `projection_confirmed` against a projection value that already matched before the command was submitted.

The required contract is:

```text
success receipt alone
→ NOT projection_confirmed

pre-existing matching control value at the command base revision
→ NOT projection_confirmed

newer authoritative projection than the command base revision
+ projected control value matches submitted expected controller
→ projection_confirmed
```

Only this edge case, its regression tests, and the known stale Work Order sentence are in scope.

## 2. Authority and current source facts

Read in this order before editing:

```text
AGENTS.md
→ current PR #2 / current remote HEAD
→ CODEX-ACTIVE-TASK.md / this command
→ accepted ADR-0088 / ADR-0089 / ADR-0090 / ADR-0091
→ modular-dm-tool-window-contract.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ AGENT-TEST-STATUS.md
→ current Phase 9 source/tests
```

Reconfirm current HEAD before editing.

At command-authoring time the relevant current source behavior is:

- `DmWorkspacePanel:_submit` stores `baseRevision`, `expectedActorId`, and `expectedControllerUserId` for `dm.assign_control`.
- terminal success marks the local record `accepted = true`.
- `DmWorkspaceViewModel.build` currently considers control confirmed when the accepted record's expected actor/controller matches `dm_workspace.control[actorId]`.
- that comparison does not currently require the projection revision to be newer than the submitted record's `baseRevision`.

Codex must inspect the actual current source and command receipt/revision semantics before changing it. Do not assume undocumented result fields.

## 3. Confirmed edge case

Reproduce or statically prove this case before editing:

```text
projection revision = R
workspace.control[actor:A] = user:22

submit dm.assign_control(actor:A, user:22)
local pending.baseRevision = R

terminal success receipt arrives
but no newer projection has arrived yet
current projection is still revision R and still says actor:A → user:22
```

Expected:

```text
accepted_awaiting_projection
```

Forbidden:

```text
projection_confirmed
```

Only after a newer authoritative projection for this command boundary is observed may the matching control value confirm the local command.

## 4. Minimal correction requirements

### 4.1 Revision-aware confirmation

Keep using the existing authoritative `dm_workspace.control` projection and local reconciliation metadata. Do not add a new gameplay-authority command or parallel authority store.

A control pending record may become `projection_confirmed` only when all are true:

1. the command has an accepted terminal success receipt;
2. expected actor/controller metadata is valid;
3. the currently rendered authoritative projection is demonstrably newer than the command's submitted base revision, or meets a stronger existing command-result revision boundary if current source already exposes one safely;
4. authoritative projected `dm_workspace.control[expectedActorId]` equals `expectedControllerUserId`.

At minimum, a projection at the same `baseRevision` must never confirm the command.

If current command receipt infrastructure exposes an authoritative committed revision, prefer preserving/using that exact boundary when it is already part of the repository contract. Otherwise require `currentProjectionRevision > baseRevision`. Do not invent a fake revision.

### 4.2 Conflict behavior

A newer projection with a different controller must remain unconfirmed. Do not silently convert it to success.

Use the existing reconciliation vocabulary. Do not create a new server error system.

### 4.3 Existing Phase 9 fixes must remain intact

Preserve all behavior from the previous fix:

- recovery `recovery:<commandId>` dedup;
- runtime patch/quick action dedup;
- terminal failure local viewer-safe feedback and max-8 bound;
- role-loss/full-sync/recovery purge;
- Player/Observer `dm_workspace` negative disclosure;
- Player View Preview server-policy reuse;
- preview does not consume live projection sequence;
- no new `dm.*` gameplay-authority command;
- no client gameplay authority.

## 5. Required focused tests

Add or adjust focused tests in the smallest suitable current test file.

Required control cases:

### Case A — success receipt alone

```text
baseRevision = 10
projected revision = 10
projected control does not yet prove the command
→ accepted_awaiting_projection
```

### Case B — pre-existing identical assignment

```text
before submission at revision 10:
control.actor = 22

pending command expects actor → 22
accepted receipt arrives
projection still revision 10
→ accepted_awaiting_projection
```

This is the regression case that must fail against the current pre-fix implementation.

### Case C — newer conflicting projection

```text
baseRevision = 10
projection revision = 11
control.actor = 23
expected controller = 22
→ NOT projection_confirmed
```

### Case D — newer matching projection

```text
baseRevision = 10
projection revision > 10
control.actor = 22
expected controller = 22
→ projection_confirmed
```

### Existing reconciliation regressions

Ensure previous recovery dedup and terminal failure redaction/bounding tests continue to pass. Do not delete, skip, or weaken them.

## 6. Work Order drift correction

`implementation/roblox/CURRENT-WORK-ORDER.md` currently has a stale prose sentence equivalent to:

```text
DM Workspace와 Acceptance 정합화가 남아 있으므로 Studio Retest를 시작하지 않는다.
```

The table/current state already has Phase 9 done and Phase 10 Acceptance in progress.

On successful fix, minimally correct that prose so it says only Acceptance alignment plus the new current-HEAD Static Gate remain before Studio Retest. Do not resurrect stale Minimap/Map/Objective Tracker authority.

Do not otherwise rewrite the Work Order.

## 7. Status bookkeeping

During this fix, ChatGPT final approval for Phase 9 is still HOLD.

Only after focused regression + local/static validation + new current-HEAD related GitHub Actions all succeed may repository status remain/resolve to:

```text
Phase 9 DM Live Workspace → FINAL PASS / DONE
Phase 10 Full UI·UX Acceptance → IN_PROGRESS
Studio Human Retest → BLOCKED pending Phase 10 + new current-HEAD Static Gate
```

If any required check fails:

```text
Phase 9 → HOLD / IN_PROGRESS as appropriate
Phase 10 → DO NOT ADVANCE
```

Update `AGENT-TEST-STATUS.md` only if needed to accurately record this final revision-aware reconciliation fix and target SHA. Do not claim Studio/Human evidence.

## 8. Validation

Run the repository's current required static/automatic validation, including at least:

```text
focused DmWorkspace reconciliation tests registered/static analyzed
python implementation/roblox/tooling/validate_implementation.py
python implementation/roblox/tooling/validate_remake_docs.py
relevant repository validators
StyLua --check
Selene
git diff --check
all required Rojo builds
default/test/multi-client sourcemaps as expected by current workflow
production/test Luau analysis
```

Roblox Studio/TestRunner/Human playtest are excluded from this fix.

After non-force push, verify the new current HEAD's related GitHub Actions:

- Validate RVTT implementation
- Validate remake documentation
- Validate RVTT content templates
- Validate Grand harness
- Validate production lease

Do not report PASS if any related current-HEAD workflow fails or is still unresolved.

## 9. Explicit exclusions

Do not perform:

- Phase 10 Acceptance implementation;
- new DM tools/features;
- new gameplay-authority commands;
- Full Scene Editor;
- ADR-0092 runtime;
- Persistence runtime;
- Performance/Soak;
- Studio / Studio MCP / Human Playtest;
- Player Minimap / separate Player Map / Objective Tracker;
- test deletion/skip/assertion weakening;
- validator/lint/CI bypass;
- force push;
- PR Ready/Approve/Merge.

## 10. Success criteria

All of the following are required:

```text
pre-existing identical control assignment cannot confirm on same/base revision
+ success receipt alone cannot confirm
+ newer conflicting projection cannot confirm
+ newer matching authoritative projection confirms
+ recovery/terminal-feedback regressions remain fixed
+ negative disclosure unchanged
+ stale Work Order prose corrected
+ focused tests PASS
+ local/static validation PASS
+ new current HEAD related GitHub Actions SUCCESS
```

Only then is Phase 9 final PASS eligible for ChatGPT approval.

## 11. Result comment format

Post a PR #2 top-level comment with:

```text
<!-- RVTT_CODEX_PHASE9_REVISION_FIX_RESULT -->
commandId: RVTT-PR2-PHASE9-CONTROL-REVISION-FIX-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_9_CONTROL_REVISION_FIX
edgeCaseConfirmed: <pre-existing identical assignment / same revision evidence>
revisionBoundaryApplied: <actual source rule used>
changedFiles: <count / paths>
focusedRegression: <cases A-D and previous regressions>
workOrderCorrection: <actual correction or none>
negativeDisclosure: <unchanged evidence>
testsRun: <actual commands/results>
staticValidationStatus: <status>
remoteCiStatus: <new current-head workflow conclusions/run ids>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
phase9FinalStatus: PASS | HOLD
phase10State: IN_PROGRESS | DO_NOT_ADVANCE
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <limitations>
```

## 12. ChatGPT follow-up verification

When the user says `확인`, ChatGPT will independently:

1. re-query PR #2 current HEAD;
2. find the latest `RVTT_CODEX_PHASE9_REVISION_FIX_RESULT` comment;
3. compare target/result SHAs and actual files;
4. inspect the revision-aware control confirmation source and focused regression;
5. verify Work Order prose/state;
6. verify current-HEAD GitHub Actions directly;
7. approve Phase 9 only if all checks match;
8. only then proceed to Phase 10 Acceptance.
