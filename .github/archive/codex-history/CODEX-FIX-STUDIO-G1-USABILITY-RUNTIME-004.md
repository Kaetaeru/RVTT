# CODEX COMMAND — Studio G1 Usability + Runtime Fix 004

- commandId: `RVTT-PR2-STUDIO-G1-USABILITY-RUNTIME-FIX-004`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_STUDIO_G1_USABILITY_RUNTIME_FIX_004_RESULT -->`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`

## Why this command exists

The first real G1 Studio attempt exposed three concrete issues:

1. The Entry/Recovery UI can remain forever on `최신 권위 Projection을 불러오고 있습니다.` even after a valid initial Projection has already been applied.
2. G1 currently creates separate World and Context acceptance ScreenGuis, producing overlap and poor test readability.
3. Production `WorldActionMenu` explicitly makes action buttons `Selectable = true` and assigns `GuiService.SelectedObject = firstButton` when opened by right-click. That creates gamepad-style GUI focus and causes keyboard WASD to be consumed by GUI navigation instead of the world camera.

This command fixes those issues without weakening authority or acceptance evidence.

---

## A. Production runtime fix — initial Projection must release LOADING

Files expected to be relevant:
- `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/UIRecoveryCoordinator.lua`
- focused unit/spec files for `UIRecoveryCoordinator` / entry recovery

Required behavior:

```text
Replica starts revision=-1
→ Recovery state LOADING
→ normal initial ProjectionReplica.apply(envelope, false)
→ replica revision becomes >= 0
→ Replica.Changed fires
→ Recovery state transitions LOADING → READY
```

Requirements:
- Observe normal `Replica.Changed` in `UIRecoveryCoordinator`.
- Transition to `READY` only when the coordinator is still in initial `LOADING` and the Replica is now valid (`revision >= 0`).
- Do NOT override `REBUILDING`, `RECOVERY`, `NETWORK_ERROR`, `STALE`, `CONFLICT`, `FATAL`, or any explicit recovery/error state.
- Preserve existing `REBUILDING → RECOVERED → READY` behavior for full resync.
- Preserve server/session authority; do not fake session phase or Projection payload.
- Add regression coverage proving a normal first Projection releases LOADING and that a changed Replica does not incorrectly clear explicit recovery/error states.

Known authority fact to preserve:
- `SessionDomain.initialState().phase == "lobby"`; this is not a server `phase="loading"` bug.

---

## B. Production input fix — right-click menu must not steal WASD

Primary file:
- `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldActionMenu.lua`

Current defect:

```text
button.Selectable = true
GuiService.SelectedObject = firstButton
```

Opening the pointer context menu therefore creates keyboard/gamepad GUI selection focus.

Required PC keyboard/mouse behavior:
- Pointer-opened World Action Menu must NOT assign `GuiService.SelectedObject`.
- World action buttons must not become keyboard/gamepad navigation targets in the current PC keyboard/mouse scope (`Selectable = false`).
- Do not globally change `GuiService.AutoSelectGuiEnabled`; solve this locally in RVTT.
- Do not clear or overwrite an unrelated pre-existing `GuiService.SelectedObject` elsewhere in the app.
- Remove obsolete previous-selected-object save/restore behavior if it exists only to support this forced focus.
- Pointer hover must still show viewer-safe disabled reasons.
- Pointer click / `Activated` must still invoke enabled actions.
- Disabled actions remain pointer-inspectable but not invokable.
- Q remains the one-context Cancel/Back path.
- ESC remains gameplay no-op.
- Right-click remains camera no-op.
- With the action menu open, WASD must continue reaching World Camera Pan rather than GUI selection navigation.

Regression tests / static validator must prove at minimum:
- no `GuiService.SelectedObject = firstButton` or equivalent forced focus on menu open;
- action menu buttons are non-selectable for current PC scope;
- opening/closing the menu does not mutate an unrelated pre-existing selected GUI object;
- existing pointer invocation and disabled-reason hover behavior remain intact;
- FIX-001/FIX-002 input grammar protections remain intact.

Do NOT add a gamepad navigation implementation in this command. Gamepad is out of initial scope.

---

## C. Acceptance UX redesign — one draggable G1 Test Console

Current problem:
- `WorldTokenAcceptance.client.lua` creates `RVTT_WorldInteraction_Batch` at left.
- `ContextInputAcceptance.client.lua` creates `RVTT_ContextInput_Acceptance` at right.
- This creates overlapping/competing test UI and forces the tester to mentally correlate two independent checklists.

Required target:

```text
ONE ScreenGui
→ ONE floating G1 Test Console
→ draggable by title/header with mouse left-drag
→ clamped to visible viewport
→ one clear linear next-action flow
→ one combined progress surface
```

Implementation guidance:
- Prefer an acceptance-only shared module, e.g. under `implementation/roblox/tests/AcceptanceShared/`, mounted only by `slice01-acceptance.project.json`.
- Both World and Context acceptance scripts must register into the same singleton Test Console instead of creating their own ScreenGuis/panels.
- Do not move test UI code into normal production UI unless required by build constraints.

The single console should make the test sequence obvious. Minimum user-facing flow:

```text
0. Projection / Runtime Ready
1. Arm Token Pick → left-click Hero
2. Camera: WASD Pan / Middle drag Orbit / Wheel Zoom / Frame
3. Surface: right-click → ESC no-op → Q close → left-click default move
4. Console: right-click → ESC no-op → Q close → left-click default interaction
5. Final Summary
```

UI requirements:
- A header/title bar that is the drag handle.
- Mouse left-drag moves the whole Test Console.
- Dragging is clamped so the console cannot be lost completely off-screen.
- Show overall progress (`passed / total`) and an obvious current/next action.
- Keep low-level individual check IDs available, but do not make the raw checklist the primary instruction surface. A details section/tab/collapse is acceptable.
- Consolidate existing actions into one console: Prepare, Arm Token Pick, Token Frame, Exploration, Final Summary (or a clearer equivalent flow).
- Test-console buttons must set `Selectable = false` so the acceptance UI itself does not steal WASD.
- Test console must not assign `GuiService.SelectedObject`.
- No TextBox should capture keyboard input during the core G1 sequence.
- Preserve all existing BatchSummary IDs and PASS semantics unless a rename is required solely for presentation; do not weaken evidence.
- Final Output must still emit the two authoritative batch summaries:
  - `slice01-world-interaction`
  - `contextual-pointer-actions`

The test console may display one combined visual progress count, but Output evidence remains separately attributable to the two BatchSummary objects.

---

## D. Acceptance/project wiring

Update `implementation/roblox/slice01-acceptance.project.json` only as needed to mount the shared acceptance UI module.

Requirements:
- Production `default.project.json` must not gain acceptance-only UI.
- Existing World and Context LocalScripts remain acceptance-only.
- No DataStore/persistence activation.
- No G2 multi-client attack evidence execution in this command.

---

## E. Validator hardening

Update focused validator(s), primarily `implementation/roblox/tooling/validate_full_ui_ux_acceptance.py`, so static acceptance rejects regressions including:

1. two independent G1 ScreenGuis/panels returning;
2. absence of a single shared G1 acceptance console;
3. missing mouse-drag title/header behavior;
4. acceptance buttons becoming selectable / setting `GuiService.SelectedObject`;
5. Production WorldActionMenu restoring forced selected-object focus;
6. initial Projection normal apply leaving UIRecoveryCoordinator in LOADING;
7. a naive Replica.Changed handler that clears non-LOADING recovery/error states;
8. removal/weakening of existing FIX-001/FIX-002/FIX-003 protections.

Use mutation/negative fixtures where the validator already follows that pattern.

---

## F. Scope boundaries

Allowed Production changes:
- `UIRecoveryCoordinator` initial Projection readiness transition.
- `WorldActionMenu` pointer/GUI-focus behavior required to stop WASD theft.

Allowed Acceptance changes:
- G1 test UI consolidation, drag behavior, test flow clarity, project wiring, focused validators/tests.

Forbidden:
- server authority weakening;
- fake Projection / fake Replica readiness;
- changing Session initial phase from `lobby` just to hide the loading UI;
- changing DM/controller semantics;
- changing Q/ESC grammar;
- global gamepad/navigation feature work;
- ADR-0092 production work;
- persistence runtime;
- G2 execution;
- claiming Studio PASS from static checks;
- merge / ready-for-review / force push.

---

## G. Required verification

Run and report:
- focused unit/spec tests for Recovery coordinator and ActionMenu/input behavior;
- Full UI/UX acceptance validator including new negative regressions;
- implementation validator;
- Grand harness validator;
- private rules runtime pipeline validator;
- StyLua / Selene;
- Slice 01 acceptance Rojo build;
- all required Rojo builds/sourcemaps and Luau analysis normally required by current implementation workflow;
- `git diff --check`;
- fresh current-result-HEAD GitHub Actions, all required workflows completed/success.

Do not report Studio/Human PASS. The user will rerun Studio after ChatGPT independently verifies this result.

---

## H. Result comment

Post exactly one top-level PR #2 Conversation comment beginning with:

```text
<!-- RVTT_CODEX_STUDIO_G1_USABILITY_RUNTIME_FIX_004_RESULT -->
```

Include:
- commandId
- targetShaAtStart
- resultHeadSha
- exact changed files
- Projection LOADING root-cause fix
- unified draggable Test Console behavior
- WorldActionMenu focus/WASD fix
- validator/test evidence
- current-result-HEAD Actions status
- explicit states:
  - `explorationContextStudioRetestState: BLOCKED_PENDING_USER_RERUN`
  - `studioRuntimeState: NOT_VERIFIED_AFTER_FIX`
  - `multiClientRuntimeState: NOT_EXECUTED`
  - `humanUiUxState: NOT_EXECUTED`

Do not claim `STUDIO_PASS`, `RUNTIME_PASS`, `HUMAN_PASS`, `MULTI_CLIENT_PASS`, `MERGE_READY`, or `FINAL_RELEASE_PASS`.