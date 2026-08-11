# RVTT Execution State

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-STUDIO-G1-USABILITY-RUNTIME-FIX-004`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `FOCUSED_RUNTIME_AND_ACCEPTANCE_UX_REPAIR`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `EXPLORATION_CONTEXT_INPUT_STUDIO_RETEST_G1_REPAIR`
- commandPath: `.github/CODEX-FIX-STUDIO-G1-USABILITY-RUNTIME-004.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_STUDIO_G1_USABILITY_RUNTIME_FIX_004_RESULT -->`
- resultStatus: `PENDING`
- broadStaticVerifiedHead: `15711da15225a19e43f54827fabcd8fa0ca0995a`
- harnessFix003ResultHead: `bab91c0c71ae9f65ba84e0fdc45aac43f461d332`
- commandFileCommit: `6f05aa11fe91547884365c8ce844d50ce272c186`
- phase9Status: `FINAL_PASS`
- phase10Status: `BROAD_CURRENT_HEAD_STATIC_PASS`
- sourceStaticFinalContractGaps: `0`
- explorationContextStudioRetestState: `BLOCKED_BY_G1_RUNTIME_AND_USABILITY_DEFECTS`
- studioRuntimeState: `PARTIALLY_EXECUTED_BLOCKED`
- multiClientRuntimeState: `NOT_EXECUTED`
- humanUiUxState: `NOT_EXECUTED`
- persistenceRuntimeState: `NOT_EXECUTED_DEFERRED`
- nextRuntimeOnVerifiedSuccess: `USER_RERUN_EXPLORATION_CONTEXT_INPUT_STUDIO_RETEST_G1`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-12`

## Preserved verified state

```text
ADR-0091 Source/Static = PASS
Full UI/UX Broad Static Gate = PASS
Final Contract Gaps = 0
FIX-001/002/003 static harness repairs = PASS
```

The first real G1 Studio run is NOT PASS. It exposed concrete runtime/usability defects.

## Confirmed G1 findings

### 1. Initial Projection loading UI can remain forever

```text
Replica starts revision=-1
→ UIRecoveryCoordinator starts LOADING
→ valid initial normal Projection applies
→ Replica revision becomes >=0 and Changed fires
→ coordinator does not transition initial LOADING → READY
→ fallback fullResync is skipped because revision is already valid
→ EntryRecoveryPanel remains blocking
```

Server `SessionDomain.initialState().phase` is `lobby`, so do not hide the defect by changing server phase or forging payload state.

### 2. Acceptance UI is not intuitive

G1 currently creates separate World and Context ScreenGuis. Replace them with one acceptance-only, shared, draggable G1 Test Console.

Required UX:

```text
ONE ScreenGui
ONE floating window
mouse left-drag title/header to move
clamped to viewport
clear current/next action
combined visible progress
low-level details secondary
```

Minimum visible sequence:

```text
0 Projection / Runtime Ready
1 Arm Token Pick → left-click Hero
2 Camera: WASD / Middle Orbit / Wheel / Frame
3 Surface: right-click → ESC no-op → Q close → left-click move
4 Console: right-click → ESC no-op → Q close → left-click interact
5 Final Summary
```

Preserve both authoritative Output summaries and all existing evidence IDs.

### 3. Right-click Action Menu steals WASD

Production `WorldActionMenu` currently does both:

```text
button.Selectable = true
GuiService.SelectedObject = firstButton
```

That forced gamepad/keyboard GUI focus is the cause of the gamepad-style selector and WASD navigation theft.

Required fix for current PC keyboard/mouse scope:

```text
pointer-opened action menu does NOT assign SelectedObject
action buttons Selectable=false
no global AutoSelectGuiEnabled change
unrelated pre-existing SelectedObject remains untouched
pointer Activated and disabled-reason hover remain working
Q close / ESC no-op remain unchanged
WASD continues world-camera Pan while menu is open
```

Acceptance Test Console buttons must also be non-selectable and must not assign `GuiService.SelectedObject`.

## Active task

Codex must read and execute:

```text
.github/CODEX-FIX-STUDIO-G1-USABILITY-RUNTIME-004.md
```

## Success condition

```text
initial normal Projection releases LOADING correctly
+ explicit recovery/error states are not accidentally cleared
+ one shared draggable G1 Test Console
+ no separate overlapping World/Context panels
+ Production WorldActionMenu does not force GUI selection focus
+ WASD not stolen by the pointer context menu
+ all existing G1 evidence semantics preserved
+ focused and broad static validators PASS
+ Slice 01 acceptance build PASS
+ fresh current-result-HEAD Actions completed/success
```

This command does NOT execute or claim a post-fix Studio PASS. After Codex posts the result, ChatGPT independently verifies it. If PASS, the user reruns G1 Studio immediately with the simplified single-window flow.

## Out of scope

- G2 Multi-client execution
- gamepad feature implementation
- server authority weakening
- DM/controller semantic changes
- Q/ESC grammar changes
- persistence Runtime
- ADR-0092 Production
- force push
- merge / ready-for-review

## Result delivery

PR #2 top-level Conversation comment must begin exactly:

```text
<!-- RVTT_CODEX_STUDIO_G1_USABILITY_RUNTIME_FIX_004_RESULT -->
```

Codex must not claim `STUDIO_PASS`, `RUNTIME_PASS`, `MULTI_CLIENT_PASS`, `HUMAN_PASS`, `MERGE_READY`, or `FINAL_RELEASE_PASS`.