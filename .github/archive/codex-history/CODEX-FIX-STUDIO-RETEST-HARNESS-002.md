# Codex Command — Studio Retest Harness FIX-002

- commandId: `RVTT-PR2-STUDIO-RETEST-HARNESS-FIX-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetShaAtStartExpected: `8c8355367729d45555c4143450b91155a943db21`
- resultMarker: `<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_002_RESULT -->`
- taskType: `FOCUSED_ACCEPTANCE_HARNESS_REPAIR`
- phase: `RUNTIME_ENTRY_PREFLIGHT_EXPLORATION_CONTEXT_INPUT`

## 0. Purpose

ChatGPT independently verified FIX-001 and rejected final Runtime entry for two remaining Harness defects. Repair only those defects and the acceptance bookkeeping required to preserve honest coverage.

Do **not** change Production authority/input behavior to make a single-client test pass.

Current accepted Product/Runtime grammar remains:

```text
Left click = select / default world action
Right click = context action table
Middle-button drag = camera Orbit
WASD = camera Pan while character movement mode is inactive
Q = one-context Cancel/Back
E = semantic Confirm
ESC = no gameplay meaning
```

Broad Source/Static Gate remains previously accepted. This command is a Runtime-entry Harness repair, not a feature redesign.

## 1. Confirm start state

Before editing:

1. Fetch PR #2 and record the actual current HEAD as `targetShaAtStart`.
2. Read `.github/CODEX-ACTIVE-TASK.md`.
3. Read at minimum:
   - `implementation/roblox/tests/WorldTokenAcceptance/WorldTokenAcceptance.client.lua`
   - `implementation/roblox/tests/ContextInputAcceptance/ContextInputAcceptance.client.lua`
   - `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldContextActionResolver.lua`
   - `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenInputController.lua`
   - `implementation/roblox/full-ui-ux-acceptance-matrix.json`
   - `implementation/roblox/EXECUTION-TEST-RULES.md`
   - `implementation/roblox/tooling/validate_full_ui_ux_acceptance.py`
   - existing `implementation/roblox/tests/MultiClient/*`
4. If HEAD moved from the expected SHA, continue only after determining that the movement is compatible and report the actual SHA.

## 2. Blocker A — World batch visible instruction is stale

FIX-001 changed the actual camera check to:

```text
action=orbit / source=mouse-middle-screen-delta
```

but the visible World batch instruction still tells the human tester that middle-drag is `Pan`.

Repair the human-facing instruction so it is unambiguous:

```text
WASD = Pan
Middle-button drag = Orbit
Wheel = Zoom
F or Token Frame = Frame
```

Requirements:

- no human-facing text in the Slice 01 / Exploration Context Studio batch may say middle-button drag is Pan;
- do not change `WorldCameraController` semantics;
- keep WASD Pan and middle-drag Orbit as distinct evidence rows/signals.

## 3. Blocker B — single-client DM combat attack checks are structurally invalid

The current single-client Context harness runs as DM. Production authority intentionally treats DM as controlling all scene actors. Production `WorldContextActionResolver` therefore does not expose an attack against a target actor that is also controllable by the same DM, and `WorldTokenInputController` prioritizes selecting another controllable actor over default attack execution.

The current G1 single-client harness nevertheless requires `attack-menu` and `attack-default` against its Dummy. That is a false-fail contract.

### 3.1 Do not weaken Production

Forbidden fixes include:

- changing `controlsActor` / `Resolver:isControllable` so DM no longer controls scene actors;
- special-casing the acceptance Dummy as hostile/uncontrollable only in Production code;
- adding a test-only Production bypass that permits DM to attack a DM-controllable actor;
- changing left-click selection precedence only to satisfy this harness;
- fabricating a Player role inside the same single-client DM session.

Production role/authority semantics are not the bug in this command.

### 3.2 Make G1 single-client scope honest

Refactor `ContextInputAcceptance.client.lua` so the first user Studio batch gates only flows that are actually valid in the single-client DM environment.

Required G1 scope:

```text
setup exploration object
middle-button Orbit
surface right-click Move table
ESC gameplay no-op while a table is open
Q closes one context only
surface left-click default Move
exploration object right-click action table
object left-click default interaction
right-click must not move camera
```

Remove `attack-menu` and `attack-default` from the G1 `BatchSummary` PASS requirements.

Prefer removing the single-client combat Dummy setup / combat-only instructions / combat button when they no longer serve another valid G1 assertion. Do not leave dead manual instructions that suggest the first Studio batch must attack the Dummy.

Do not claim the removed attack interaction has been runtime-tested.

## 4. Preserve attack coverage by moving it to real Player authority evidence

Attack interaction must not disappear from the acceptance plan.

The Player-vs-hostile actor default attack / attack action-table behavior requires a real Player role and a target the Player does not control. Record that runtime requirement under the existing G2 / `STUDIO_MULTI_CLIENT` lane rather than pretending G1 tested it.

At minimum update the acceptance matrix so any requirement that explicitly includes attack preview/default behavior is not satisfied solely by `STUDIO_SINGLE_CLIENT` G1.

Specifically inspect and correct:

- `input.preview-before-action`
- `input.pointer-grammar` if its recorded runtime evidence is intended to include actor-target default behavior
- related attack/action-availability items if they currently imply G1 alone proves Player-vs-hostile behavior.

Expected principle:

```text
G1 single-client = camera + surface/object contextual input + Q/ESC + default move/interact
G2 multi-client = Player role + hostile/uncontrolled actor attack action table/default attack + role/disclosure authority
```

`STUDIO_MULTI_CLIENT` remains `NOT_EXECUTED` after this command. Do not mark it PASS.

You may extend the existing matrix/runtime-batch metadata or add a narrowly scoped acceptance item if that is the cleanest schema-compatible representation, but do not create a new Production feature or execute the multi-client test in this command.

## 5. Static regression protection

Strengthen `validate_full_ui_ux_acceptance.py` (and self-tests/fixtures as appropriate) so it fails at least these regressions:

1. World human instructions again say middle-drag = Pan.
2. World camera evidence collapses WASD Pan and middle-drag Orbit into the same path.
3. G1 `ContextInputAcceptance` again requires `attack-menu` or `attack-default` while running in the single-client DM acceptance environment.
4. G1 instructions again require Dummy attack completion.
5. Attack preview/default runtime coverage is silently deleted instead of being represented under G2 / `STUDIO_MULTI_CLIENT`.
6. A repair mutates Production `controlsActor` / target-control exclusion / left-click controllable-target selection precedence merely to make the single-client attack test pass.

Self-tests must mutate representative snippets/data and prove the validator rejects them; marker presence alone is insufficient where a small semantic mutation can be tested.

## 6. Preserve FIX-001 good work

Do not regress:

- actual middle-button `orbit / mouse-middle-screen-delta` evidence;
- WASD `pan / keyboard-wasd` evidence;
- removal of the acceptance-only fake `pan / mouse-middle-orbit` compatibility emission;
- real ESC no-op observation;
- real Q `context-cancel` one-table close evidence;
- PR-bound exact-branch / exact-7-char-head non-persistence build exception;
- Broad Source/Static final-contract gap = 0;
- all ADR-0091 static acceptance states.

## 7. Validation

Run the focused/broad checks appropriate to the changed files, including at least:

- full UI/UX acceptance validator and its self-tests;
- implementation validator;
- formatting/lint for changed Luau;
- relevant Rojo builds including `slice01-acceptance.project.json` and `multi-client.project.json`;
- Production/tests Luau type analysis;
- any existing Grand/acceptance validator touched by the matrix change.

Then push the repair to the existing PR #2 branch and verify **current result HEAD** PR-triggered Actions.

All required current-head workflows must be completed/success before reporting readiness for ChatGPT verification.

## 8. Runtime boundary

Do not run or claim Roblox Studio / Human evidence in this command.

Expected status after successful implementation:

```text
Broad Source/Static = PASS retained
Harness FIX-002 = IMPLEMENTED_PENDING_CHATGPT_VERIFICATION
Exploration Context Studio Retest = NOT_EXECUTED
G2 Multi-client attack evidence = NOT_EXECUTED
Human UI/UX = NOT_EXECUTED
Persistence = NOT_EXECUTED / DEFERRED
```

Only after ChatGPT independently verifies this repair will the user receive the first Studio PowerShell block.

## 9. Result comment

Post one top-level PR #2 Conversation comment beginning exactly with:

```text
<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_002_RESULT -->
```

Include:

- `commandId`
- `targetShaAtStart`
- `resultHeadSha`
- `resultStatus: READY_FOR_CHATGPT_HARNESS_VERIFICATION`
- changed files
- World visible-instruction repair summary
- G1 combat false-fail removal summary
- G2 attack coverage bookkeeping summary
- validator negative-regression summary
- local validation summary
- current-head Actions summary
- `studioRuntimeState: NOT_EXECUTED`
- `multiClientRuntimeState: NOT_EXECUTED`
- `humanUiUxState: NOT_EXECUTED`
- residual risks
- `nextRuntimeGate: EXPLORATION_CONTEXT_INPUT_STUDIO_RETEST`

Do not claim `STUDIO_PASS`, `MULTI_CLIENT_PASS`, `HUMAN_PASS`, `RUNTIME_PASS`, `MERGE_READY`, or `FINAL_RELEASE_PASS`.
