# RVTT Execution State

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-STUDIO-RETEST-HARNESS-FIX-003`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `FOCUSED_ACCEPTANCE_HARNESS_REPAIR`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `RUNTIME_ENTRY_PREFLIGHT_EXPLORATION_CONTEXT_INPUT`
- commandPath: `.github/CODEX-FIX-STUDIO-RETEST-HARNESS-003.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_003_RESULT -->`
- resultStatus: `PENDING`
- broadStaticVerifiedHead: `15711da15225a19e43f54827fabcd8fa0ca0995a`
- harnessFix001ResultHead: `8c8355367729d45555c4143450b91155a943db21`
- harnessFix002ResultHead: `27ca1ac506a2a12cbf3cd760eb75f4a6f085ca3c`
- commandFileCommit: `f0e84a2fe0b8a417bcbe8c30c7d1095fe148c584`
- phase9Status: `FINAL_PASS`
- phase10Status: `BROAD_CURRENT_HEAD_STATIC_PASS`
- sourceStaticFinalContractGaps: `0`
- runtimeEntryPreflightState: `HARNESS_FIX_003_REQUIRED`
- explorationContextStudioRetestState: `NOT_EXECUTED`
- multiClientAttackEvidenceState: `NOT_EXECUTED`
- studioRuntimeState: `NOT_EXECUTED`
- humanUiUxState: `NOT_EXECUTED`
- persistenceRuntimeState: `NOT_EXECUTED_DEFERRED`
- nextRuntimeOnVerifiedSuccess: `EXPLORATION_CONTEXT_INPUT_STUDIO_RETEST`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-12`

## Preserved verified state

```text
ADR-0091 Source/Static = PASS
Full UI/UX Broad Static Gate = PASS
Final Contract Gaps = 0
Studio/Human = NOT_EXECUTED
```

FIX-001 and FIX-002 already corrected:

```text
middle-button drag = Orbit
WASD = Camera Pan
Q = one-context Cancel/Back
ESC = gameplay no-op
G1 single-client DM = no impossible Player-hostile attack gate
G2 Player-hostile attack evidence = STUDIO_MULTI_CLIENT / NOT_EXECUTED
Production DM control authority and selection precedence preserved
```

## Remaining preflight blocker

World G1 still requires real `token-pick` and `selection-highlight` evidence from `PickResolved`.

Production automatically calls `ensureSemanticSelection()` at Runtime startup and after Replica changes. With only one controllable Hero in G1, Hero is already selected before the user clicks it. Production `_leftClick()` does not call `_pick()` when the user clicks the already-selected same actor, so correct Production can leave the two checks pending forever.

This is an Acceptance reachability defect, not grounds to weaken Production selection semantics.

## Active task

Codex must read and execute first:

```text
.github/CODEX-FIX-STUDIO-RETEST-HARNESS-003.md
```

Required repair:

```text
explicit user-visible Arm Token Pick step
→ acceptance-only local Renderer:setSelected(nil)
→ user real left-click on Hero
→ Production _leftClick() / _pick() path
→ real PickResolved
→ token-pick PASS
→ actual renderer Highlight observation
→ selection-highlight PASS
```

Critical boundaries:

```text
no startup-only selection clear
no server command from arm action
no Replica/session/owner/controller mutation
no fake PickResolved
no direct _pick invocation from harness
no Production ensureSemanticSelection weakening
no Production same-token re-click hack
if Replica reselects after arming, require re-arm instead of false PASS
```

Validator must add negative regressions for those boundaries while preserving FIX-001/FIX-002 protections.

## Success condition

```text
Harness FIX-003 static implementation PASS
Broad/focused validators PASS
slice01 acceptance Rojo build PASS
Current result-HEAD required Actions all completed/success
Studio/Multi-client/Human remain NOT_EXECUTED
```

After Codex posts the result, ChatGPT independently verifies the diff and current HEAD.

If that verification passes, **no further preflight source work is planned**. ChatGPT then immediately provides the user the exact current-result-HEAD Windows PowerShell block for:

```text
Exploration · Context Input Studio Retest (G1)
```

plus the real input sequence and PASS Output tokens.

## Out of scope

- Production input grammar changes
- Production authority changes
- G2 Multi-client execution
- Studio/Human execution by Codex
- Persistence Runtime
- ADR-0092 Production
- force push
- merge / ready-for-review

## Result delivery

PR #2 top-level Conversation comment must begin exactly:

```text
<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_003_RESULT -->
```

Codex must not claim `STUDIO_PASS`, `MULTI_CLIENT_PASS`, `HUMAN_PASS`, `RUNTIME_PASS`, `MERGE_READY`, or `FINAL_RELEASE_PASS`.
