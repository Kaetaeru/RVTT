# RVTT Codex Implementation Command — Entry · Role · Recovery 001

- commandId: `RVTT-PR2-ENTRY-ROLE-RECOVERY-IMPLEMENTATION-001`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_8`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- studioRuntime: `FORBIDDEN`
- humanPlaytest: `FORBIDDEN`

## Goal

Implement only Phase 8:

```text
Entry · Role · Recovery
→ Projection rebuild · Reconnect · Error Boundary
```

Phase 4–7 are complete. Reuse the existing Session, Projection, Command, Shared Shell, and client runtime paths. Do not create a parallel session/role/recovery authority system.

## Authority order

Read in this order before implementation:

```text
AGENTS.md
→ AGENT-TEST-STATUS.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ ADR-0088 / ADR-0089 / ADR-0090 / ADR-0091
→ final-ui-content-implementation-contract.md
→ implementation-ready-ui-ux-and-settings-spec.md, except superseded portions
→ Session / Character / Projection / Networking / Recovery architecture and slice specs
→ EXECUTION-TEST-RULES.md
```

Higher Accepted ADR/final contract wins over stale lower-level examples.

## Existing paths to inspect and reuse

At minimum inspect the current implementation of:

- `SessionDomain.lua`
- `CharacterDomain.lua`
- `DomainProjectionPolicy.lua`
- `ProjectionReplica.lua`
- `CommandClient.lua`
- `ClientRuntime.lua`
- `App.client.lua`
- `AppShell.lua`
- current session/network bootstrap and full-sync transport
- current role/context derivation and authorization helpers
- current error/result/reconciliation utilities

Do not assume a command exists merely because the UI spec names an action. Use only existing authoritative commands/capabilities, or make the minimum server-authoritative addition required by Accepted authority after proving the gap.

## Fixed product contract

### Entry / Observer-first

- A non-DM user enters as `Observer` until authoritative session/character assignment says otherwise.
- Do not infer Player role merely from local UI selection, cached character ownership, or a pending command.
- Entry UI derives role, available character choices, ready state, and session phase from viewer-safe Projection.
- DM identity/role remains authoritative; do not expose DM-only controls to Observer/Player.
- Character Owner, Runtime Controller, and Session Role remain separate concepts.

### Character assignment / Player transition

- Follow the current authoritative assignment/selection model after inspecting repository source and Accepted ADR-0089.
- A Player transition must be projection-backed and server-authorized.
- If the current source cannot legally express the Accepted observer→player assignment contract, implement only the smallest authoritative server-side delta required; do not solve it with client-only role mutation.
- Pending assignment/selection must not unlock gameplay authority before confirmed Projection revision.
- Revocation or reassignment must remove obsolete capabilities on the next authoritative Projection without leaking previous private state.

### Ready / Session phase

- Reuse current `session.ready` / session phase semantics where applicable.
- Do not fabricate readiness for Observer or disconnected users.
- UI must distinguish waiting, pending, denied/conflict, and authoritative ready/session-active state.

### Reconnect / Projection rebuild

- Reconnect must rebuild client-visible state from authoritative full/current Projection, not replay stale local assumptions as authority.
- Preserve purely local UI preferences where the existing preference boundary allows it.
- Restore semantic selection/focus only when the referenced projected entity is still visible and valid; otherwise clear/degrade safely.
- A reconnect/full-sync must invalidate stale previews, pending UI claims, and revision-bound actions that no longer match the authoritative revision.
- Do not duplicate command side effects during retry/reconnect.

### Recovery / Error boundary

Support the repository’s existing result/error taxonomy and presentation boundary. At minimum distinguish where existing source supports them:

```text
loading / rebuilding projection
ready
pending
stale / resync required
permission denied
validation/conflict
network/disconnected
recovering
recovered
fatal or unrecoverable boundary
```

- Recoverable transport/projection errors must not destroy authoritative domain state from the client.
- Error UI must be viewer-safe and must not reveal hidden entity/capability details.
- Retry/resync controls must call existing safe transport/sync paths; do not invent client authority.
- Fatal/error boundary presentation must not silently convert the user to Player/DM or bypass Entry.

### Role-change continuity

On authoritative role/assignment changes:

- recompute Shell/Surface composition from Projection;
- remove controls no longer authorized;
- preserve local preference state;
- preserve world/management selection only if still visible/valid for the new role;
- never retain hidden private data from the previous role in rendered UI/state caches;
- do not force camera recenter solely because role changed.

### Negative disclosure

```text
not projected / no permission
→ no placeholder, count, label, action, identity, or reason that reveals the hidden fact

authorized but temporarily unavailable
→ disabled with viewer-safe reason
```

Player/Observer projections must remain separated from DM-only data.

## Required tests

Add or extend focused tests for the implemented contract. Cover at minimum, where repository architecture allows static/unit/integration verification:

1. Observer-first derivation for non-DM entry.
2. No optimistic Player authority from local/pending character selection.
3. Authoritative assignment/role projection changes shell/action availability.
4. Role revocation/reassignment removes stale capabilities/private projected data.
5. Ready/session phase state is projection-backed.
6. Reconnect/full-sync rebuild invalidates stale revision-bound local action/preview state.
7. Local preferences survive projection rebuild within the existing preference boundary.
8. Selection/focus restoration only for still-visible valid entities.
9. Network/stale/conflict/permission recovery presentation is viewer-safe.
10. Retry/reconnect does not duplicate an already-authorized domain mutation.
11. Player/Observer do not receive DM-only projection data or controls.

Register new tests in the repository test runner as required.

## Validation

Run the repository-defined feasible static/automated gates, including at least the currently applicable:

- implementation validator
- formatter check
- Selene
- all Rojo project builds
- default/test sourcemaps
- production/test Luau analysis
- relevant general validators if touched by the change
- focused Phase 8 unit/integration tests through available non-Studio analysis/registration checks

Do not run Roblox Studio, Studio MCP, or Human Playtest.

## Scope exclusions

Do not implement or claim completion for:

- Phase 9 DM Live Workspace alignment
- Phase 10 Full UI/UX Acceptance expansion
- Studio Human Retest
- Accessibility Human Evidence
- Grand Persistence Runtime
- ADR-0092 runtime expansion
- touch/controller UI
- Player minimap, separate map, or objective tracker
- client-side role/gameplay authority
- PR ready/approval/merge

## Status transition

Only if Phase 8 implementation and required static validation PASS:

```text
Phase 8 Entry·Role·Recovery → DONE
Phase 9 DM Live Workspace → IN_PROGRESS
```

Update `AGENT-TEST-STATUS.md` consistently. Do not mark Studio Runtime/Human UX PASS.

## Result comment

Post one PR #2 top-level comment containing:

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-ENTRY-ROLE-RECOVERY-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_8
implementedScope: <concise list>
changedFiles: <count and/or paths>
testsRun: <commands/results>
staticValidationStatus: <status>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 8/9 status>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
negativeDisclosure: <summary>
notes: <limitations>
```

PASS means Phase 8 Source/Static completion only.