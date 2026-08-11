# RVTT Codex Command — Studio Retest Harness Contract Repair 001

- commandId: `RVTT-PR2-STUDIO-RETEST-HARNESS-FIX-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `FOCUSED_ACCEPTANCE_HARNESS_REPAIR`
- phase: `RUNTIME_ENTRY_PREFLIGHT_EXPLORATION_CONTEXT_INPUT`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_001_RESULT -->`

## Background

ChatGPT independently verified the ADR-0091 broad Source/Static gate at HEAD `15711da15225a19e43f54827fabcd8fa0ca0995a`:

```text
ADR-0091 Source/Static finalContractGaps = 0
Broad current-head Static Gate = PASS
Studio/Human = NOT_EXECUTED
```

Before asking the user to run the first Studio Batch, ChatGPT inspected the actual Slice 01 acceptance harness and found stale test semantics that can false-fail a correct current implementation.

Production contract and current production source are authoritative:

```text
Middle-button drag = Camera Orbit
WASD = Camera Pan while character movement mode is inactive
Q = one-context Cancel/Back
E = semantic Confirm
ESC = no gameplay meaning
```

Current stale harness problems:

1. `WorldTokenAcceptance.client.lua` labels/listens for middle-button `camera-pan`, while `WorldCameraController` emits `orbit / mouse-middle-screen-delta` for middle drag.
2. `ContextInputAcceptance.client.lua` tells the user to press `Esc` to close the action table, but current gameplay grammar requires `Q`; ESC must not close gameplay context.
3. The generic execution-test PowerShell example is hardcoded to `planning/rvtt-remake`, while this gated runtime retest is intentionally tied to PR #2 branch `agent/survival-logistics-token-authoring`. The repository needs a narrow explicit PR-bound Batch exception rather than silently testing a different branch.

This is an Acceptance Harness / execution-contract repair only. Do not change production input semantics to satisfy stale tests.

## Required implementation

### A. World Interaction harness — middle drag is Orbit

Update:

`implementation/roblox/tests/WorldTokenAcceptance/WorldTokenAcceptance.client.lua`

Requirements:

- Replace the middle-button manual check id/label from `camera-pan` to `camera-orbit` (or an equivalently unambiguous current-contract identifier).
- UI instructions must say middle-click drag = Orbit, not Pan.
- The check must pass only from the production signal:
  - `action == "orbit"`
  - `source == "mouse-middle-screen-delta"`
  - `applied == true`
  - `changed == true`
- Keep `camera-wasd-pan` separate and continue requiring `action == "pan"` with `source == "keyboard-wasd"`.
- Do not make production `WorldCameraController` emit fake pan events for middle drag.

### B. Context Input harness — Q and ESC semantics

Update:

`implementation/roblox/tests/ContextInputAcceptance/ContextInputAcceptance.client.lua`

Requirements:

- Replace every user instruction that uses `Esc` to close an action table with `Q`.
- Add explicit user-input evidence for both:
  - `ESC gameplay no-op`: with a world action table open, pressing Escape must not close that gameplay action table or execute a world/default action.
  - `Q one-context back`: with the action table open, Q must close only that top gameplay context.
- Use production-observable state/signals; do not directly call private cancel functions to fake input evidence.
- The manual sequence should be deterministic and easy to follow, for example:
  - right-click target → action table opens
  - press ESC → gameplay table remains open (`esc-gameplay-noop` PASS)
  - press Q → table closes (`q-one-context-back` PASS)
  - left-click target → default action executes
- One valid observed ESC/Q cycle may satisfy the generic semantic checks; do not require redundant repetitions just to inflate the checklist.
- Keep the existing move/interact/attack menu/default-action checks and middle-button Orbit check.
- Right-click must remain context action only; do not reassign camera semantics.

If Roblox system handling makes direct Escape observation require `processed=true`, the harness may observe the key event for evidence, but it must judge gameplay state from the production action-menu signal/state, not from the processed flag alone.

### C. PR-bound Batch Acceptance execution rule

Update the narrow execution documentation needed for this retest, preferably:

`implementation/roblox/EXECUTION-TEST-RULES.md`

Requirements:

- Preserve `planning/rvtt-remake` as the default/general example.
- Add an explicit PR-bound Batch Acceptance exception:
  - only when the active coordinator task names exact repository, PR, branch, and verified target/result HEAD;
  - fetch/switch/pull that exact branch;
  - verify exact 7-char HEAD before building;
  - use the requested non-persistence acceptance project;
  - do not infer a different branch.
- This exception must not weaken current-head/static gate requirements.
- Do not execute Studio from Codex.

### D. Static regression protection

Strengthen the smallest existing validator(s) so future drift fails automatically.

At minimum detect/reject:

- World acceptance expecting middle drag as `pan` instead of production `orbit`.
- Context acceptance instructing `Esc` as gameplay cancel/close.
- Missing explicit Q close evidence.
- Missing explicit ESC gameplay-noop evidence.
- Loss of the distinction between WASD pan and middle-drag orbit.

Add negative self-test fixtures if the relevant validator has a self-test mechanism.

Do not weaken any existing broad/focused validator.

## Required validation

Run all relevant local/static checks available in the repository, including:

- focused/broad Full UI/UX validators and self-tests
- implementation validator
- StyLua
- Selene
- required Rojo builds/sourcemaps
- Luau type analysis
- documentation validation if `EXECUTION-TEST-RULES.md` changes

Then ensure the result HEAD PR-triggered GitHub Actions are all `completed/success` before claiming candidate success.

## Acceptance state rules

During this task:

```text
Broad Source/Static product gate = remains PASS unless regression is found
Runtime entry preflight = IN_PROGRESS
Exploration/Context Studio Retest = NOT_EXECUTED
Human Playtest = NOT_EXECUTED
Persistence = NOT_EXECUTED / DEFERRED
```

Do not claim `STUDIO_PASS`, `HUMAN_PASS`, `RUNTIME_PASS`, or `MERGE_READY`.

On successful implementation, report only:

`READY_FOR_CHATGPT_HARNESS_VERIFICATION`

ChatGPT will independently inspect the result. Only after ChatGPT verifies this repair will the user receive the exact PowerShell build block for the first Studio retest.

## Out of scope

- production input behavior redesign
- Character Sheet / Dice / Core Rules feature changes
- persistence runtime
- multi-client runtime
- accessibility human judgment
- ADR-0092 Production
- force push
- merge / ready-for-review transition

## Result comment

Post one top-level PR #2 Conversation comment containing exactly this marker:

```text
<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_001_RESULT -->
```

Include:

- commandId
- targetShaAtStart
- resultHeadSha
- changedFiles
- exact harness semantics repaired
- validator/regression evidence
- local validation summary
- current-head Actions summary
- Studio/Human state (`NOT_EXECUTED`)
- remaining risk
