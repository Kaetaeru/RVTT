from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]

WORLD_ACCEPTANCE_PATH = ROOT / "tests/WorldTokenAcceptance/WorldTokenAcceptance.client.lua"
CONTEXT_ACCEPTANCE_PATH = ROOT / "tests/ContextInputAcceptance/ContextInputAcceptance.client.lua"
G1_TEST_CONSOLE_PATH = ROOT / "tests/AcceptanceShared/G1TestConsole.lua"
WORLD_RUNTIME_PATH = ROOT / "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenRuntime.lua"
CONTEXT_RESOLVER_PATH = ROOT / "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldContextActionResolver.lua"
INPUT_CONTROLLER_PATH = ROOT / "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenInputController.lua"
WORLD_ACTION_MENU_PATH = ROOT / "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldActionMenu.lua"
WORLD_ACTION_MENU_POLICY_PATH = ROOT / "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldActionMenuPolicy.lua"
UI_RECOVERY_COORDINATOR_PATH = ROOT / "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/UIRecoveryCoordinator.lua"
ENTRY_RECOVERY_SPEC_PATH = ROOT / "tests/Unit/EntryRecovery.spec.lua"
INPUT_CONTEXT_SPEC_PATH = ROOT / "tests/Unit/InputContext.spec.lua"
SLICE01_ACCEPTANCE_PROJECT_PATH = ROOT / "slice01-acceptance.project.json"
DEFAULT_PROJECT_PATH = ROOT / "default.project.json"


def validate_studio_retest_harness_texts(
    world_acceptance: str,
    context_acceptance: str,
    world_runtime: str,
    context_resolver: str,
    input_controller: str,
    shared_console: str,
) -> list[str]:
    """Validate executable G1 input/runtime contracts, never prose policy wording."""
    errors: list[str] = []
    visible_acceptance = world_acceptance + "\n" + shared_console

    world_markers = {
        'id = "camera-orbit", label = "3D Camera Middle-button Orbit"': "middle-button Orbit summary",
        '["camera-orbit"] = "middle-click drag to orbit"': "middle-button Orbit requirement",
        'action == "orbit" and source == "mouse-middle-screen-delta"': "exact middle-button Orbit signal",
        'action == "pan" and source == "keyboard-wasd"': "separate WASD Pan signal",
        "applied == true": "applied camera evidence",
        "changed == true": "changed camera evidence",
        "2 Camera: WASD Pan / Middle drag Orbit / Wheel Zoom / Frame": "unambiguous visible camera instruction",
    }
    for marker, description in world_markers.items():
        if marker not in visible_acceptance:
            errors.append(f"studio runtime contract: missing {description}")
    if 'id = "camera-pan"' in world_acceptance or 'action == "pan" then "camera-pan"' in world_acceptance:
        errors.append("studio runtime contract: middle-button Camera Pan regression is forbidden")
    if "Middle-button drag = Pan" in visible_acceptance or "중클릭 드래그=Pan" in visible_acceptance:
        errors.append("studio runtime contract: visible middle-button Pan instruction is forbidden")

    arm_markers = {
        '{ id = "ArmTokenPick", label = "Arm Token Pick"': "explicit Arm Token Pick control",
        "1 Arm Token Pick → left-click Hero": "manual token-pick instruction",
        "tokenPickArmed = true": "manual arm state",
        "worldTokens.SelectionChanged:Connect": "arm invalidation observer",
        "invalidateTokenPickArm": "explicit re-arm invalidation",
        'summary:pending("token-pick"': "token-pick pending/re-arm state",
        'summary:pending("selection-highlight"': "selection-highlight pending/re-arm state",
    }
    for marker, description in arm_markers.items():
        if marker not in visible_acceptance:
            errors.append(f"studio runtime contract: missing {description}")

    arm_start = world_acceptance.find('testConsole:registerAction("ArmTokenPick", function()')
    arm_end = world_acceptance.find('testConsole:registerAction("Frame", function()', arm_start)
    arm_handler = world_acceptance[arm_start:arm_end] if arm_start >= 0 and arm_end >= 0 else ""
    if not arm_handler:
        errors.append("studio runtime contract: token-pick selection clear requires an explicit user arm handler")
    else:
        if "worldTokens.Renderer:getTokenModel(heroActorId)" not in arm_handler:
            errors.append("studio runtime contract: Arm Token Pick must verify the Hero token exists")
        if "worldTokens.Renderer:setSelected(nil)" not in arm_handler:
            errors.append("studio runtime contract: Arm Token Pick must clear only local Renderer selection")
        if arm_handler.find("tokenPickArmed = true") > arm_handler.find("worldTokens.Renderer:setSelected(nil)"):
            errors.append("studio runtime contract: arm state must be explicit before local selection clear")
        if re.search(r'pass\s*\(\s*"(?:token-pick|selection-highlight)"', arm_handler):
            errors.append("studio runtime contract: arm handler cannot directly PASS token-pick or Highlight")
        for forbidden in ("PickResolved:Fire", ":_pick(", "submit("):
            if forbidden in arm_handler:
                errors.append(f"studio runtime contract: arm handler cannot invoke {forbidden}")
        if re.search(r"\b(?:selectedCharacter|ownerUserId|controllerUserId|role)\s*=(?!=)", arm_handler):
            errors.append("studio runtime contract: arm handler cannot mutate authority fields")
        if re.search(r"client\.Replica(?:\.payload)?[^\n]*=(?!=)", arm_handler):
            errors.append("studio runtime contract: arm handler cannot mutate Replica state")

    if world_acceptance.count("worldTokens.Renderer:setSelected(nil)") != 1 or (
        arm_handler and "worldTokens.Renderer:setSelected(nil)" not in arm_handler
    ):
        errors.append("studio runtime contract: local selection clear must exist only in the manual arm handler")

    pick_start = world_acceptance.find("worldTokens.PickResolved:Connect(function(")
    pick_end = world_acceptance.find("worldTokens.SelectionChanged:Connect(function(", pick_start)
    pick_handler = world_acceptance[pick_start:pick_end] if pick_start >= 0 and pick_end >= 0 else ""
    pick_markers = {
        "realArmedPick": "armed real-pick guard",
        'method == "ray"': "real ray-pick method guard",
        'pass("token-pick"': "token-pick PASS from PickResolved",
        "worldTokens.Renderer:isSelectedHighlighted(actorId)": "actual Highlight observation",
        'pass("selection-highlight"': "selection-highlight PASS from PickResolved",
    }
    for marker, description in pick_markers.items():
        if marker not in pick_handler:
            errors.append(f"studio runtime contract: missing {description}")
    for pass_id in ("token-pick", "selection-highlight"):
        matches = list(re.finditer(rf'pass\s*\(\s*"{pass_id}"', world_acceptance))
        if len(matches) != 1 or not pick_handler or not (pick_start <= matches[0].start() < pick_end):
            errors.append(f"studio runtime contract: {pass_id} may PASS only from real PickResolved")

    context_markers = {
        'id = "esc-gameplay-noop"': "ESC gameplay no-op summary",
        'id = "q-one-context-back"': "Q one-context Back summary",
        'id = "right-click-camera-noop"': "right-click camera no-op summary",
        "UserInputService.InputBegan": "user-input observer",
        "input.KeyCode == Enum.KeyCode.Escape": "explicit ESC input evidence",
        "input.KeyCode == Enum.KeyCode.Q": "explicit Q input evidence",
        "worldTokens.ActionMenu:isOpen()": "production action-menu observable",
        'close.reason == "context-cancel"': "production context-cancel signal",
        'pass("esc-gameplay-noop"': "ESC no-op PASS evidence",
        'pass("q-one-context-back"': "Q close PASS evidence",
        "cameraInputResolutionCount == cameraCountBefore": "right-click camera no-op evidence",
    }
    for marker, description in context_markers.items():
        if marker not in context_acceptance:
            errors.append(f"studio runtime contract: missing {description}")
    if "→Esc→" in context_acceptance or "→Escape→" in context_acceptance:
        errors.append("studio runtime contract: stale Esc-close instruction is forbidden")
    for forbidden in ('id = "setup-dummy"', 'id = "attack-menu"', 'id = "attack-default"'):
        if forbidden in context_acceptance:
            errors.append("studio runtime contract: G1 single-client DM cannot require attack checks")
    for forbidden in ("training-dummy", "npc.spawn", "combatButton", "Dummy"):
        if forbidden in context_acceptance:
            errors.append("studio runtime contract: G1 cannot retain Dummy combat setup or instructions")

    if "mouse-middle-orbit" in world_runtime:
        errors.append("studio runtime contract: fake middle-button Pan compatibility signal is forbidden")
    if world_runtime.count("self.Input:ensureSemanticSelection()") < 2:
        errors.append("studio runtime contract: Production ensureSemanticSelection must remain at startup and Replica change")

    resolver_markers = {
        'if membershipRole(allDomains, playerId) == "dm" then\n\t\treturn true': "DM controls scene actors",
        'type(targetActor) ~= "table" or controlsActor(allDomains, playerId, target.actorId)': "controlled target attack exclusion",
    }
    for marker, description in resolver_markers.items():
        if marker not in context_resolver:
            errors.append(f"studio runtime contract: Production authority drifted: {description}")

    selection_marker = """if
\t\ttarget.actorId ~= nil
\t\tand target.actorId ~= selectedActorId
\t\tand self.resolver:isControllable(target.actorId)
\tthen
\t\tself:_pick(target.actorId, \"ray\", target.instance)
\t\treturn
\tend"""
    left_click_start = input_controller.find("function Controller:_leftClick()")
    left_click_end = input_controller.find("function Controller:refreshPreview()", left_click_start)
    left_click = input_controller[left_click_start:left_click_end]
    if left_click_start < 0 or left_click_end < 0 or selection_marker not in left_click:
        errors.append("studio runtime contract: Production controllable-target selection precedence drifted")
    elif left_click.index(selection_marker) > left_click.index("local actions = self:resolveActionsForTarget(target)"):
        errors.append("studio runtime contract: controllable-target selection must precede default action resolution")
    if left_click.count("self:_pick(") != 2:
        errors.append("studio runtime contract: Production _leftClick pick reachability semantics drifted")

    return errors


def validate_g1_usability_fix_texts(
    world_acceptance: str,
    context_acceptance: str,
    shared_console: str,
    action_menu: str,
    action_menu_policy: str,
    recovery_coordinator: str,
    entry_recovery_spec: str,
    input_context_spec: str,
    slice_project: str,
    default_project: str,
) -> list[str]:
    errors: list[str] = []

    for old_name in ("RVTT_WorldInteraction_Batch", "RVTT_ContextInput_Acceptance"):
        if old_name in world_acceptance or old_name in context_acceptance or old_name in shared_console:
            errors.append("G1 usability contract: independent legacy acceptance ScreenGui returned")
    if 'Instance.new("ScreenGui")' in world_acceptance or 'Instance.new("ScreenGui")' in context_acceptance:
        errors.append("G1 usability contract: World and Context scripts must not create independent ScreenGuis")
    if shared_console.count('Instance.new("ScreenGui")') != 1:
        errors.append("G1 usability contract: exactly one shared G1 ScreenGui is required")

    shared_markers = {
        'gui.Name = "RVTT_G1_Test_Console"': "shared G1 Test Console singleton",
        'panel.Name = "G1TestConsole"': "single floating console window",
        'header.Name = "DragHeader"': "title/header drag handle",
        "header.InputBegan:Connect": "mouse drag start",
        "UserInputService.InputChanged:Connect": "mouse drag movement",
        "Enum.UserInputType.MouseButton1": "left-mouse drag gesture",
        "clampPosition": "viewport clamp",
        'button.Selectable = false': "non-selectable acceptance buttons",
        '"Combined progress  %d / %d"': "combined visible progress",
        '"Evidence details (secondary)"': "secondary low-level evidence",
        "0 Projection / Runtime Ready": "step 0 Projection readiness",
        "1 Arm Token Pick → left-click Hero": "step 1 token pick",
        "2 Camera: WASD Pan / Middle drag Orbit / Wheel Zoom / Frame": "step 2 camera",
        "3 Surface: right-click → ESC no-op → Q close → left-click default move": "step 3 surface",
        "4 Console: right-click → ESC no-op → Q close → left-click default interaction": "step 4 console",
        "5 Final Summary": "step 5 final summary",
    }
    for marker, description in shared_markers.items():
        if marker not in shared_console:
            errors.append(f"G1 usability contract: missing {description}")
    if "TextBox" in shared_console or "GuiService.SelectedObject" in shared_console:
        errors.append("G1 usability contract: shared console cannot capture text or mutate SelectedObject")

    for source, batch_name in (
        (world_acceptance, "slice01-world-interaction"),
        (context_acceptance, "contextual-pointer-actions"),
    ):
        if 'WaitForChild("AcceptanceShared"):WaitForChild("G1TestConsole")' not in source:
            errors.append(f"G1 usability contract: {batch_name} does not use the shared console")
        if "testConsole:registerBatch(BATCH_NAME, summary)" not in source:
            errors.append(f"G1 usability contract: {batch_name} does not register combined progress")
        if "summary:log(client.Replica.revision)" not in source:
            errors.append(f"G1 usability contract: {batch_name} authoritative Output summary was removed")

    if '"AcceptanceShared": {' not in slice_project or '"$path": "tests/AcceptanceShared"' not in slice_project:
        errors.append("G1 usability contract: Slice 01 project does not mount acceptance-only shared UI")
    if "AcceptanceShared" in default_project or "tests/AcceptanceShared" in default_project:
        errors.append("G1 usability contract: production default project mounted acceptance-only UI")

    menu_markers = {
        "local WorldActionMenuPolicy = require(script.Parent.WorldActionMenuPolicy)": "local menu focus policy",
        "button.Selectable = WorldActionMenuPolicy.actionButtonSelectable": "non-selectable action button",
        "button.MouseEnter:Connect": "disabled-reason pointer hover",
        "button.MouseLeave:Connect": "disabled-reason pointer leave",
        "button.Activated:Connect": "pointer action activation",
        "if not action.enabled then": "disabled action invocation guard",
    }
    for marker, description in menu_markers.items():
        if marker not in action_menu:
            errors.append(f"G1 usability contract: WorldActionMenu missing {description}")
    if re.search(r"GuiService\.SelectedObject\s*=", action_menu):
        errors.append("G1 usability contract: WorldActionMenu cannot assign GuiService.SelectedObject")
    if "previousSelectedObject" in action_menu:
        errors.append("G1 usability contract: obsolete WorldActionMenu selected-object restore returned")
    if "AutoSelectGuiEnabled" in action_menu:
        errors.append("G1 usability contract: global AutoSelectGuiEnabled mutation is forbidden")
    for marker, description in {
        "actionButtonSelectable = false": "PC pointer buttons non-selectable policy",
        "mutatesSelectedObject = false": "selected-object preservation policy",
    }.items():
        if marker not in action_menu_policy:
            errors.append(f"G1 usability contract: missing {description}")

    changed_start = recovery_coordinator.find("replica.Changed:Connect(function()")
    changed_end = recovery_coordinator.find("replica.RebuildStarted:Connect(function()", changed_start)
    changed_handler = recovery_coordinator[changed_start:changed_end] if changed_start >= 0 and changed_end >= 0 else ""
    for marker, description in {
        "self.state.state == ViewState.LOADING": "initial LOADING-only guard",
        "replica.revision >= 0": "valid Replica revision guard",
        "self:_set(ViewState.READY, nil, false)": "normal Projection READY transition",
    }.items():
        if marker not in changed_handler:
            errors.append(f"G1 usability contract: recovery coordinator missing {description}")
    for forbidden in (
        "ViewState.REBUILDING",
        "ViewState.RECOVERY",
        "ViewState.NETWORK_ERROR",
        "ViewState.STALE",
        "ViewState.CONFLICT",
        "ViewState.FATAL",
    ):
        if forbidden in changed_handler:
            errors.append("G1 usability contract: Replica.Changed handler must not clear explicit recovery/error states")
    if 'phase = "loading"' in recovery_coordinator or 'phase = "ready"' in recovery_coordinator:
        errors.append("G1 usability contract: recovery coordinator cannot forge Session phase")

    for marker, description in {
        '"a normal first Projection releases initial loading"': "normal first Projection regression",
        '"Replica changes do not clear explicit "': "protected recovery/error regression",
        "ViewState.REBUILDING": "REBUILDING protected state",
        "ViewState.RECOVERY": "RECOVERY protected state",
        "ViewState.NETWORK_ERROR": "NETWORK_ERROR protected state",
        "ViewState.STALE": "STALE protected state",
        "ViewState.CONFLICT": "CONFLICT protected state",
        "ViewState.FATAL": "FATAL protected state",
    }.items():
        if marker not in entry_recovery_spec:
            errors.append(f"G1 usability contract: EntryRecovery spec missing {description}")
    for marker, description in {
        "not WorldActionMenuPolicy.actionButtonSelectable": "non-selectable action-menu spec",
        "not WorldActionMenuPolicy.mutatesSelectedObject": "selected-object preservation spec",
        '"right click is consumed while the action table is open"': "existing pointer input spec",
        '"Q closes the action table"': "existing Q grammar spec",
        '"middle drag remains available to the independent camera controller"': "existing camera grammar spec",
    }.items():
        if marker not in input_context_spec:
            errors.append(f"G1 usability contract: InputContext spec missing {description}")

    return errors


def validate() -> list[str]:
    world = WORLD_ACCEPTANCE_PATH.read_text(encoding="utf-8")
    context = CONTEXT_ACCEPTANCE_PATH.read_text(encoding="utf-8")
    runtime = WORLD_RUNTIME_PATH.read_text(encoding="utf-8")
    resolver = CONTEXT_RESOLVER_PATH.read_text(encoding="utf-8")
    controller = INPUT_CONTROLLER_PATH.read_text(encoding="utf-8")
    shared = G1_TEST_CONSOLE_PATH.read_text(encoding="utf-8")

    errors = validate_studio_retest_harness_texts(world, context, runtime, resolver, controller, shared)
    errors.extend(
        validate_g1_usability_fix_texts(
            world,
            context,
            shared,
            WORLD_ACTION_MENU_PATH.read_text(encoding="utf-8"),
            WORLD_ACTION_MENU_POLICY_PATH.read_text(encoding="utf-8"),
            UI_RECOVERY_COORDINATOR_PATH.read_text(encoding="utf-8"),
            ENTRY_RECOVERY_SPEC_PATH.read_text(encoding="utf-8"),
            INPUT_CONTEXT_SPEC_PATH.read_text(encoding="utf-8"),
            SLICE01_ACCEPTANCE_PROJECT_PATH.read_text(encoding="utf-8"),
            DEFAULT_PROJECT_PATH.read_text(encoding="utf-8"),
        )
    )
    return errors


def run_self_tests() -> list[str]:
    failures: list[str] = []
    world = WORLD_ACCEPTANCE_PATH.read_text(encoding="utf-8")
    context = CONTEXT_ACCEPTANCE_PATH.read_text(encoding="utf-8")
    runtime = WORLD_RUNTIME_PATH.read_text(encoding="utf-8")
    resolver = CONTEXT_RESOLVER_PATH.read_text(encoding="utf-8")
    controller = INPUT_CONTROLLER_PATH.read_text(encoding="utf-8")
    shared = G1_TEST_CONSOLE_PATH.read_text(encoding="utf-8")

    fixtures = [
        (world.replace('action == "orbit" and source == "mouse-middle-screen-delta"', 'action == "pan"'), context, runtime, resolver, controller, shared, "exact middle-button Orbit signal"),
        (world, context.replace("input.KeyCode == Enum.KeyCode.Q", "input.KeyCode == Enum.KeyCode.Unknown"), runtime, resolver, controller, shared, "explicit Q input evidence"),
        (world, context.replace("input.KeyCode == Enum.KeyCode.Escape", "input.KeyCode == Enum.KeyCode.Unknown"), runtime, resolver, controller, shared, "explicit ESC input evidence"),
        (world.replace('action == "pan" and source == "keyboard-wasd"', 'action == "orbit"'), context, runtime, resolver, controller, shared, "separate WASD Pan signal"),
        (world, context, runtime + '\nlocal source = "mouse-middle-orbit"\n', resolver, controller, shared, "fake middle-button Pan compatibility signal"),
        (world, context + '\nlocal required = { id = "attack-menu" }\n', runtime, resolver, controller, shared, "G1 single-client DM cannot require attack checks"),
        (world, context + '\nlocal instruction = "Attack the Dummy"\n', runtime, resolver, controller, shared, "G1 cannot retain Dummy combat setup or instructions"),
        (world, context, runtime, resolver.replace('if membershipRole(allDomains, playerId) == "dm" then\n\t\treturn true', 'if membershipRole(allDomains, playerId) == "dm" then\n\t\treturn false'), controller, shared, "DM controls scene actors"),
        (world, context, runtime, resolver, controller.replace("and target.actorId ~= selectedActorId\n\t\tand self.resolver:isControllable(target.actorId)", "and target.actorId ~= selectedActorId\n\t\tand false", 1), shared, "controllable-target selection precedence"),
    ]
    for world_fixture, context_fixture, runtime_fixture, resolver_fixture, controller_fixture, shared_fixture, expected in fixtures:
        errors = validate_studio_retest_harness_texts(
            world_fixture,
            context_fixture,
            runtime_fixture,
            resolver_fixture,
            controller_fixture,
            shared_fixture,
        )
        if not any(expected in error for error in errors):
            failures.append(f"studio runtime validator self-test did not reject fixture: {expected}")

    return failures


def main() -> int:
    errors = validate()
    errors.extend(run_self_tests())
    if errors:
        print("Studio runtime contract validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print("Studio runtime contract validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
