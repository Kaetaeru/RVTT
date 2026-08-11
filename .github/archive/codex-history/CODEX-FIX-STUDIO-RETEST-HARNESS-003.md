# Codex Command — Studio Retest Harness FIX-003

- commandId: `RVTT-PR2-STUDIO-RETEST-HARNESS-FIX-003`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetShaAtCommandCreation: `27ca1ac506a2a12cbf3cd760eb75f4a6f085ca3c`
- taskType: `FOCUSED_ACCEPTANCE_HARNESS_REPAIR`
- resultMarker: `<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_003_RESULT -->`

## Purpose

Repair the last known false-fail in the first single-client Studio G1 harness without changing Production authority or Production input grammar.

Current Production Runtime calls `ensureSemanticSelection()` at startup and after Replica changes. The World acceptance harness then requires `PickResolved` to PASS `token-pick` and `selection-highlight`. With only one controllable Hero in G1, the Hero is already selected, and clicking the same selected Hero does not call `_pick()`. Therefore a correct Production Runtime can leave both checks permanently pending.

The repair must make the real user pointer pick reachable while preserving the Production path.

## Accepted repair

Add an explicit acceptance-only local arming step to the WorldTokenAcceptance UI.

After automatic scene/token setup is complete, the user must intentionally activate a control such as `Arm Token Pick` / `Token Pick 준비`.

That control may only clear the acceptance client's local renderer selection, for example through the already-instantiated acceptance `worldTokens.Renderer:setSelected(nil)` boundary. It must not submit a server command, mutate Replica payload/state, alter ownership/control, spawn another actor, fake `PickResolved`, or change Production input code.

The expected flow is:

```text
World/Context automatic setup settles
→ user presses Arm Token Pick
→ acceptance-only local Renderer selection becomes nil
→ UI instructs user to left-click the visible Hero token
→ Production WorldTokenInputController receives the real pointer input
→ target actor is controllable and selectedActorId == nil
→ Production `_pick(actorId, "ray", ...)` executes
→ real `PickResolved` fires
→ World harness PASSes token-pick
→ renderer Highlight is observed
→ World harness PASSes selection-highlight
→ normal selected-Hero flow resumes
```

## Requirements

### A. Explicit manual arm; no startup clear

Do not clear selection automatically at startup, after `prepareScene()`, or on every Replica change. ContextInputAcceptance performs an automatic object setup command and can advance Replica after World setup; a one-shot startup clear can be overwritten by Production `ensureSemanticSelection()` and recreate the false-fail.

The user-visible World harness must expose an explicit arm control after setup. Its instruction must explain that automatic setup should be settled first, then the user presses the arm control and left-clicks the Hero token.

The arm control must verify that a Hero token exists before arming. If not, it should keep the test pending and tell the user to run/wait for automatic setup.

### B. Real Production `_pick()` evidence only

`token-pick` and `selection-highlight` may PASS only from the existing real `worldTokens.PickResolved` callback and renderer highlight observation.

Forbidden shortcuts:

- `pass("token-pick", ...)` from the arm-button handler
- `pass("selection-highlight", ...)` from the arm-button handler
- manually firing `PickResolved`
- direct acceptance invocation of `WorldTokenInputController:_pick`
- fake second actor solely to trigger selection
- changing Production `_leftClick`, `ensureSemanticSelection`, `WorldTokenRuntime`, resolver authority, or renderer semantics to satisfy the test

### C. Local-only safety and reconciliation

The arming step must be acceptance-local and reversible by the next real Hero click.

It must not:

- submit any command
- modify `session.selectedCharacter`
- modify character owner/controller/session role
- modify scene actor authority
- mutate server Projection or Replica payload

If a Replica update reselects the Hero after the user armed but before the real click, the harness should detect that the arm was invalidated and return to a clear pending/re-arm state rather than false-PASSing. It may observe renderer selection and require the user to press Arm again.

### D. User-visible sequence

World batch visible instructions must remain contract-correct:

```text
WASD = Pan
Middle-button drag = Orbit
Wheel = Zoom
F or Token Frame = Frame
```

Add the token-pick sequence clearly, e.g.:

```text
Wait until setup is ready → Arm Token Pick → left-click Hero → verify Highlight
```

Do not reintroduce `middle-button = Pan` wording.

Context G1 continues to exclude Player-vs-hostile attack. G2 attack bookkeeping remains unchanged and `STUDIO_MULTI_CLIENT = NOT_EXECUTED`.

### E. Validator hardening

Extend `implementation/roblox/tooling/validate_full_ui_ux_acceptance.py` so static validation fails if any of these regressions occur:

1. World G1 requires `token-pick`/`selection-highlight` but has no explicit manual arm control/path.
2. The harness clears renderer selection only automatically during startup/prepare instead of through an explicit user arm.
3. The arm handler directly PASSes `token-pick` or `selection-highlight`.
4. The arm handler fires or invokes `PickResolved` / `_pick` directly.
5. The arm handler submits a command or mutates authoritative selection/role/owner/controller/Replica state.
6. Production `ensureSemanticSelection()` is weakened/removed to satisfy the harness.
7. Production `_leftClick()` is changed so re-clicking the already selected same actor artificially calls `_pick()` merely for acceptance.
8. FIX-001/FIX-002 regressions return: middle-button Pan, fake compatibility signal, stale ESC-close instruction, G1 combat attack gates, missing G2 Player attack bookkeeping, weakened DM control-target authority.

Add negative self-test fixtures for the important cases above. Marker-only checks are insufficient where a simple source mutation can prove the regression.

### F. Scope

Expected changed files should be narrowly limited to the acceptance harness/validator and, only if necessary, matrix or execution instructions for accurate G1 bookkeeping.

Do not modify Production source unless a genuine Production defect independent of this acceptance problem is discovered. If such a defect is found, STOP and report it instead of silently expanding this command.

Do not execute or claim Roblox Studio/Human/Multi-client Runtime evidence in this command.

## Validation

Run all focused and broad static checks needed for the changed harness, including at minimum:

- full UI/UX acceptance validator + negative self-tests
- implementation structure/policy validator
- relevant formatting/lint/type checks
- `slice01-acceptance.project.json` Rojo build
- broader required current-head Actions

Preserve the previously verified Source/Static final gap count at `0`.

## Success state

Only after implementation and current result-HEAD Actions are green, report:

```text
harnessFix003 = STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
explorationContextStudioRetestState = NOT_EXECUTED
studioRuntimeState = NOT_EXECUTED
multiClientRuntimeState = NOT_EXECUTED
humanUiUxState = NOT_EXECUTED
```

Do not claim `STUDIO_PASS`, `RUNTIME_PASS`, `HUMAN_PASS`, `MULTI_CLIENT_PASS`, `MERGE_READY`, or `FINAL_RELEASE_PASS`.

## Result comment

Post one top-level PR #2 Conversation comment beginning exactly with:

```text
<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_003_RESULT -->
```

Include:

- commandId
- targetShaAtStart
- resultHeadSha
- exact changed files
- manual arm implementation summary
- proof that token-pick/highlight PASS only from real PickResolved
- invalidation/re-arm behavior
- validator negative regressions
- local validation results
- all current result-HEAD Actions statuses
- Studio/Multi-client/Human = NOT_EXECUTED
- remaining risks
