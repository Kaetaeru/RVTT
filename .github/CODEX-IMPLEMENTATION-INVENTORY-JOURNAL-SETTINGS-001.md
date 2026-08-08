# RVTT Codex Implementation Command — Phase 7 Inventory·Journal·Settings

- commandId: `RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_7`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`

## Goal

Implement only Phase 7 of the current Full UI·UX Alignment lane:

```text
Inventory · Journal · Settings
→ Screen · Intent · Permission · Preference
```

Phase 4 Shared Shell/Preference Foundation, Phase 5 Input/Context Action, and Phase 6 Exploration/Encounter HUD are already complete. Reuse those systems. Do not create parallel UI, input, preference, projection, or command-authority stacks.

## Authority order

Read and obey, in order:

1. `AGENTS.md`
2. `AGENT-TEST-STATUS.md`
3. `implementation/roblox/CURRENT-WORK-ORDER.md`
4. accepted ADR-0088 / ADR-0089 / ADR-0090 / ADR-0091
5. latest `final-ui-content-implementation-contract.md`
6. `implementation-ready-ui-ux-and-settings-spec.md` only where it is not superseded by higher authority
7. relevant Inventory / Journal / Character / Settings architecture, slice specs, and system guides
8. `implementation/roblox/EXECUTION-TEST-RULES.md`

Important supersession rule: the player persistent UI is Character Console-centered. Do not add a player minimap, separate map screen, or objective tracker just because older work-order/spec text still mentions them.

## Existing source to inspect and reuse

At minimum inspect the current versions of:

- `implementation/roblox/src/StarterGui/RVTT/App.client.lua`
- `implementation/roblox/src/StarterGui/RVTT/UI/AppShell.lua`
- `implementation/roblox/src/StarterGui/RVTT/UI/Components/PanelShell.lua`
- `implementation/roblox/src/StarterGui/RVTT/UI/Components/SettingsPanel.lua`
- `implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/PreferenceSchema.lua`
- `implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/ShellContract.lua`
- `implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/ThemeContract.lua`
- `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/UiPreferenceStore.lua`
- `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/ProjectionReplica.lua`
- `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/CommandClient.lua`
- current Inventory, Journal, Character, Item, Permission, and Projection domain source/tests

If an equivalent screen/view-model/controller already exists, extend it instead of replacing it.

## Fixed contracts

### Inventory

The management surface must be projection-backed and permission-safe.

Support the current authoritative flows that actually exist in the repository, including where applicable:

- inventory browsing and item details
- equipment state
- loot / transfer
- identification state
- item availability and disabled reasons
- ownership / controller / viewer permission boundaries

Do not invent item counts, identity, hidden properties, source ownership, container contents, or transfer capability that the server projection does not expose.

UI actions are intents. They must route through the existing command boundary and remain server-authorized. No direct client mutation of domain stores.

### Journal

Journal presentation must use the existing Journal projection and permissions.

- Render only entries/fields visible to the current viewer.
- Preserve hidden/private/DM-only disclosure boundaries.
- Navigation and selection are local presentation state unless the repository defines an authoritative command for them.
- Do not add a separate player Map or Objective Tracker.
- If older documentation describes Journal·Map together, follow the newer top-level no-player-map rule.

### Settings

Reuse `PreferenceSchema`, `UiPreferenceStore`, `ThemeContract`, `ThemeApplicator`, and the existing Settings panel.

Bring the screen into alignment for the settings that the current authoritative schema actually supports, including relevant UI/accessibility/input preferences.

Required behavior:

```text
open settings
→ read current preference snapshot
→ edit local candidate
→ validate through preference schema/store
→ apply supported local presentation preference
→ preserve gameplay selection/focus where applicable
```

Implement/reset behavior only according to the current schema/store contract. Do not fabricate persistence guarantees beyond what the current preference architecture supports.

Binding conflicts must be presented safely if bindings are editable in the current contract; do not silently overwrite conflicting bindings.

Accent, scale, text scale, motion and other existing visual preferences must reuse the established Theme/Preference path.

### Screen / Intent / Permission / Preference

For every Phase 7 control distinguish:

```text
not visible to viewer
→ do not render

visible but currently unavailable
→ disabled + viewer-safe reason

available
→ enabled intent
```

No hidden capability placeholders.

Screen state and projection revisions must not silently authorize stale commands. If the underlying revision changes, refresh/reconcile presentation before commit where the existing command contract requires it.

## Scope boundaries

Do NOT perform:

- Roblox Studio, MCP, or Human Playtest
- Phase 8 Entry·Role·Recovery work
- Phase 9 DM Live Workspace work
- Phase 10 Acceptance completion
- ADR-0092 runtime implementation
- persistence runtime expansion
- touch/controller-specific UI
- player minimap, separate map, or objective tracker
- new client gameplay authority
- direct UI mutation of authoritative domain state
- private/hidden-data placeholders
- PR ready, approval, or merge

## Implementation procedure

1. Resolve PR #2 current remote HEAD and record `targetShaAtStart`.
2. Align a clean checkout to `agent/survival-logistics-token-authoring`; do not stop merely because the checkout began detached or stale.
3. Read the authority files above before editing.
4. Confirm Work Order Phase 6 is `DONE` and Phase 7 is `IN_PROGRESS`.
5. Inspect existing Inventory/Journal/Settings UI, projection, domain, permission, command, and preference source before designing changes.
6. Reuse the existing Shared Shell, PanelShell, ProjectionReplica, CommandClient, PreferenceSchema, UiPreferenceStore, ThemeContract/ThemeApplicator, and domain authorities.
7. Implement only Phase 7.
8. Add/update focused unit/integration tests for screen composition, permissions/negative disclosure, intent routing, preference validation/reset/conflict behavior, and relevant revision handling.
9. Run the repository-defined available static/automated validation, including validator, formatter, lint, Rojo builds, sourcemaps/Luau analysis, and relevant tests where executable without Studio.
10. Only if implementation and required static validation pass, set Phase 7 `DONE`, Phase 8 `IN_PROGRESS`, and update `AGENT-TEST-STATUS.md` truthfully.
11. Commit and non-force publish to the same PR branch. Plain git is preferred; absence of `gh` CLI is not a blocker. If connector fallback is required, verify tree equality and remote head.
12. Before posting the result, re-check current remote PR HEAD.
13. Post one top-level PR #2 comment with the required marker/result fields.
14. Do not claim Studio Runtime/Human UX PASS.

## Required result comment

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_7
implementedScope: <concise list>
changedFiles: <count and/or paths>
testsRun: <commands/results>
staticValidationStatus: <status>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 7/8 status>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
negativeDisclosure: <what was intentionally not exposed/invented>
notes: <limitations>
```

`PASS` means only Phase 7 Source/Static completion. It is not Studio Runtime, Human UX, Accessibility, Persistence, Multi-client, Performance, or Release PASS.
