from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import json
import re
import sys

from validate_asset_registry import run_self_tests as run_asset_registry_self_tests
from validate_asset_registry import validate as validate_asset_registry
from validate_core_rules_reader import validate as validate_core_rules_reader
from validate_dice_slot_reveal_notice import run_self_tests as run_dice_notice_self_tests
from validate_dice_slot_reveal_notice import validate as validate_dice_slot_reveal_notice
from validate_official_character_sheet import run_self_tests as run_official_sheet_self_tests
from validate_official_character_sheet import validate as validate_official_character_sheet
from validate_rules_profile_release_gate import run_self_tests as run_rules_profile_self_tests
from validate_rules_profile_release_gate import validate as validate_rules_profile_gate


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
MATRIX_PATH = ROOT / "full-ui-ux-acceptance-matrix.json"
MANIFEST_PATH = ROOT / "grand-acceptance-manifest.json"
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
EXECUTION_RULES_PATH = ROOT / "EXECUTION-TEST-RULES.md"

EVIDENCE_CLASSES = {
    "STATIC",
    "STUDIO_SINGLE_CLIENT",
    "STUDIO_MULTI_CLIENT",
    "REAL_TRANSPORT",
    "HUMAN_UI_UX",
    "HUMAN_ACCESSIBILITY",
    "PERSISTENCE_DEFERRED",
    "PERFORMANCE_DEFERRED",
    "CONTENT_DEFERRED",
}
ITEM_STATES = {"STATIC_VERIFIED", "NOT_EXECUTED", "BLOCKED", "DEFERRED"}
EVIDENCE_STATES = {"PASS", "NOT_EXECUTED", "BLOCKED", "DEFERRED", "PLANNED"}
NON_STATIC_CLASSES = EVIDENCE_CLASSES - {"STATIC"}

REQUIRED_IDS = {
    "input.esc-gameplay-noop",
    "input.q-one-context-back",
    "input.e-semantic-confirm",
    "input.pointer-grammar",
    "input.preview-before-action",
    "input.player-hostile-attack-pointer",
    "input.action-availability-disclosure",
    "input.selection-camera-continuity",
    "input.projection-reconciliation",
    "input.context-blocks-world-default",
    "hud.exploration-composition",
    "hud.encounter-additive-composition",
    "hud.observer-safe",
    "hud.no-player-persistent-map-surfaces",
    "management.inventory-authorized-intents",
    "management.hidden-item-nondisclosure",
    "management.journal-permission-navigation",
    "settings.preference-contract",
    "settings.preference-no-authority-restore",
    "entry.observer-first",
    "entry.selection-no-player-grant",
    "entry.authoritative-role-transition",
    "entry.owner-controller-role-separation",
    "recovery.full-sync-rebuild",
    "recovery.stale-dangerous-confirm-block",
    "recovery.invalid-local-state-purge",
    "recovery.viewer-safe-error-boundary",
    "dm.workspace-dm-only-window-host",
    "dm.local-layout-server-authority-separation",
    "dm.player-view-preview-policy-parity",
    "dm.preview-sequence-isolation",
    "dm.existing-command-bindings-only",
    "dm.projected-queue-reconciliation",
    "dm.assign-control-newer-revision-proof",
    "dm.terminal-failure-safe-feedback",
    "dm.role-loss-purge-nondisclosure",
}

REQUIRED_FINAL_IDS = {
    "final.asset-registry-separation",
    "final.official-2024-sheet-interactions",
    "final.dice-slot-reveal-notice",
    "final.core-rules-reader-filtering",
    "final.rules-profile-release-leak-gate",
}
RESOLVED_FINAL_IDS = {
    "final.asset-registry-separation",
    "final.official-2024-sheet-interactions",
    "final.dice-slot-reveal-notice",
    "final.core-rules-reader-filtering",
    "final.rules-profile-release-leak-gate",
}
REMAINING_FINAL_GAPS = REQUIRED_FINAL_IDS - RESOLVED_FINAL_IDS

FORBIDDEN_FEATURE_IDS = {
    "player-persistent-minimap",
    "separate-player-map",
    "objective-tracker",
}

FORBIDDEN_SOURCE_PATTERNS = {
    "Minimap": re.compile(r"\bMinimap\b", re.IGNORECASE),
    "ObjectiveTracker": re.compile(r"\bObjectiveTracker\b", re.IGNORECASE),
    "PlayerMap": re.compile(r"\bPlayer[_-]?Map\b|\bMap(?:Panel|Screen)\b", re.IGNORECASE),
}


def _load_json(path: Path, errors: list[str]) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{path.relative_to(REPO_ROOT)}: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"{path.relative_to(REPO_ROOT)}: root must be an object")
        return {}
    return value


def _repo_path(reference: str) -> Path:
    return REPO_ROOT / reference.split("#", 1)[0]


def validate_g2_attack_bookkeeping(matrix: dict) -> list[str]:
    errors: list[str] = []
    items = {
        item.get("id"): item
        for item in matrix.get("acceptanceItems", [])
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }
    attack = items.get("input.player-hostile-attack-pointer")
    if attack is None:
        return ["matrix: G2 Player-vs-hostile attack runtime coverage is missing"]

    if attack.get("roles") != ["PLAYER"]:
        errors.append("matrix: G2 attack evidence requires a real Player role")
    if attack.get("runtimeBatchIds") != ["G2"]:
        errors.append("matrix: Player-vs-hostile attack runtime evidence must belong only to G2")
    if set(attack.get("evidenceClasses", [])) != {"STATIC", "STUDIO_MULTI_CLIENT"}:
        errors.append("matrix: Player-vs-hostile attack evidence must retain STUDIO_MULTI_CLIENT")
    if attack.get("evidenceStatus", {}).get("STUDIO_MULTI_CLIENT") != "NOT_EXECUTED":
        errors.append("matrix: G2 attack runtime evidence must remain NOT_EXECUTED")
    requirement = str(attack.get("requirement", ""))
    for marker in ("uncontrolled hostile actor", "right-click attack action table", "left-click default attack"):
        if marker not in requirement:
            errors.append(f"matrix: G2 attack requirement is missing {marker}")
    required_static_refs = {
        "implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldContextActionResolver.lua",
        "implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenInputController.lua",
        "implementation/roblox/tests/Unit/InputContext.spec.lua",
    }
    if not required_static_refs.issubset(set(attack.get("automatedRefs", []))):
        errors.append("matrix: G2 attack bookkeeping is missing Production and static authority evidence")

    for item_id in ("input.pointer-grammar", "input.preview-before-action"):
        item = items.get(item_id)
        if item is None:
            continue
        if not {"G1", "G2"}.issubset(set(item.get("runtimeBatchIds", []))):
            errors.append(f"matrix: {item_id} must separate G1 input evidence from G2 attack evidence")
        if "STUDIO_MULTI_CLIENT" not in item.get("evidenceClasses", []):
            errors.append(f"matrix: {item_id} must retain STUDIO_MULTI_CLIENT attack coverage")
        if item.get("evidenceStatus", {}).get("STUDIO_MULTI_CLIENT") != "NOT_EXECUTED":
            errors.append(f"matrix: {item_id} G2 evidence must remain NOT_EXECUTED")
        if "G2" not in str(item.get("requirement", "")) or "attack" not in str(item.get("requirement", "")).lower():
            errors.append(f"matrix: {item_id} must name its G2 attack boundary")
    return errors


def validate_matrix_data(matrix: dict, manifest: dict) -> list[str]:
    errors: list[str] = []
    if matrix.get("schemaVersion") != 1:
        errors.append("matrix: schemaVersion must be 1")
    if matrix.get("matrixId") != "rvtt-full-ui-ux-acceptance-v1":
        errors.append("matrix: unexpected matrixId")

    authority = matrix.get("authoritySnapshot")
    if not isinstance(authority, dict):
        errors.append("matrix: authoritySnapshot must be an object")
    else:
        if not re.fullmatch(r"[0-9a-f]{40}", authority.get("targetSha", "")):
            errors.append("matrix: authoritySnapshot.targetSha must be a full lowercase SHA")
        refs = authority.get("refs", [])
        if not isinstance(refs, list) or not refs:
            errors.append("matrix: authoritySnapshot.refs must be non-empty")
        else:
            for reference in refs:
                if not isinstance(reference, str) or not _repo_path(reference).is_file():
                    errors.append(f"matrix: missing authority reference {reference}")

    forbidden = set(matrix.get("forbiddenPlayerPersistentFeatures", []))
    if forbidden != FORBIDDEN_FEATURE_IDS:
        errors.append("matrix: forbidden Player persistent feature set drifted")

    batches = matrix.get("runtimeBatches", [])
    if not isinstance(batches, list):
        errors.append("matrix: runtimeBatches must be an array")
        batches = []
    batch_ids = [batch.get("id") for batch in batches if isinstance(batch, dict)]
    if len(batch_ids) != len(set(batch_ids)):
        errors.append("matrix: duplicate runtime batch id")
    required_batches = {"G1", "G2", "G3", "HUMAN", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "PERFORMANCE"}
    if set(batch_ids) != required_batches:
        errors.append("matrix: runtime batch ids must preserve G1/G2/G3/HUMAN/P1-P7/PERFORMANCE")

    manifest_phase_ids = {
        phase.get("id")
        for phase in manifest.get("phases", [])
        if isinstance(phase, dict)
    }
    for batch in batches:
        if not isinstance(batch, dict):
            errors.append("matrix: runtime batch entry must be an object")
            continue
        batch_id = batch.get("id", "<unknown>")
        if batch.get("evidenceClass") not in EVIDENCE_CLASSES:
            errors.append(f"batch {batch_id}: unknown evidence class")
        if batch.get("status") == "PASS":
            errors.append(f"batch {batch_id}: Phase 10 cannot claim runtime or human PASS")
        for phase_id in batch.get("manifestPhaseIds", []):
            if phase_id not in manifest_phase_ids:
                errors.append(f"batch {batch_id}: unknown manifest phase {phase_id}")
        if batch.get("status") == "DEFERRED" and not batch.get("deferReason"):
            errors.append(f"batch {batch_id}: deferred batch requires deferReason")

    items = matrix.get("acceptanceItems", [])
    if not isinstance(items, list) or not items:
        errors.append("matrix: acceptanceItems must be a non-empty array")
        items = []
    item_ids = [item.get("id") for item in items if isinstance(item, dict)]
    if len(item_ids) != len(set(item_ids)):
        errors.append("matrix: duplicate acceptance id")
    missing_required = REQUIRED_IDS - set(item_ids)
    if missing_required:
        errors.append(f"matrix: missing required acceptance ids {sorted(missing_required)}")
    errors.extend(validate_g2_attack_bookkeeping(matrix))

    for item in items:
        if not isinstance(item, dict):
            errors.append("matrix: acceptance entry must be an object")
            continue
        item_id = item.get("id", "<unknown>")
        for field in ("area", "requirement", "authorityRefs", "roles", "surfaces", "evidenceClasses", "automatedRefs", "runtimeBatchIds", "currentState", "evidenceStatus"):
            if field not in item:
                errors.append(f"{item_id}: missing {field}")
        classes = item.get("evidenceClasses", [])
        unknown_classes = set(classes) - EVIDENCE_CLASSES if isinstance(classes, list) else {"<invalid>"}
        if unknown_classes:
            errors.append(f"{item_id}: unknown evidence classes {sorted(unknown_classes)}")
        if not classes:
            errors.append(f"{item_id}: evidenceClasses must be non-empty")
        state = item.get("currentState")
        if state not in ITEM_STATES:
            errors.append(f"{item_id}: invalid currentState {state}")
        evidence_status = item.get("evidenceStatus", {})
        if not isinstance(evidence_status, dict):
            errors.append(f"{item_id}: evidenceStatus must be an object")
            evidence_status = {}
        for evidence_class in classes:
            status = evidence_status.get(evidence_class)
            if status not in EVIDENCE_STATES:
                errors.append(f"{item_id}: invalid or missing evidence status for {evidence_class}")
            if evidence_class in NON_STATIC_CLASSES and status == "PASS":
                errors.append(f"{item_id}: Phase 10 cannot claim {evidence_class} PASS")
        if set(evidence_status) - set(classes):
            errors.append(f"{item_id}: evidenceStatus has undeclared evidence class")

        authority_refs = item.get("authorityRefs", [])
        if not authority_refs:
            errors.append(f"{item_id}: authorityRefs must be non-empty")
        for reference in authority_refs:
            if not isinstance(reference, str) or not _repo_path(reference).is_file():
                errors.append(f"{item_id}: missing authority reference {reference}")
        for reference in item.get("automatedRefs", []):
            if not isinstance(reference, str) or not _repo_path(reference).is_file():
                errors.append(f"{item_id}: missing automated reference {reference}")
        for batch_id in item.get("runtimeBatchIds", []):
            if batch_id not in batch_ids:
                errors.append(f"{item_id}: unknown runtime batch id {batch_id}")

        if state in {"BLOCKED", "DEFERRED"} and not (item.get("blockerReason") or item.get("deferReason")):
            errors.append(f"{item_id}: {state} requires blockerReason or deferReason")
        if "PASS" in evidence_status.values() and not (item.get("automatedRefs") or item.get("humanScenario")):
            errors.append(f"{item_id}: PASS requires executable or human evidence")

        requirement = str(item.get("requirement", ""))
        mentions_forbidden = any(pattern.search(requirement) for pattern in FORBIDDEN_SOURCE_PATTERNS.values())
        if mentions_forbidden and item.get("polarity") != "forbidden":
            errors.append(f"{item_id}: forbidden Player surface was registered as required")
        if item.get("polarity") == "forbidden":
            if set(item.get("forbiddenFeatureIds", [])) != FORBIDDEN_FEATURE_IDS:
                errors.append(f"{item_id}: forbidden feature ids are incomplete")

    final_items = {
        item.get("id"): item
        for item in items
        if isinstance(item, dict) and item.get("id") in REQUIRED_FINAL_IDS
    }
    if set(final_items) != REQUIRED_FINAL_IDS:
        errors.append("matrix: ADR-0091 final-contract item set is incomplete")
    final_gaps = set(matrix.get("finalContractGaps", []))
    blocked_final_items = {
        item_id
        for item_id, item in final_items.items()
        if item.get("currentState") == "BLOCKED"
    }
    if final_gaps != blocked_final_items:
        errors.append("matrix: finalContractGaps must equal the actual BLOCKED final-contract subset")
    if final_gaps != REMAINING_FINAL_GAPS:
        errors.append("matrix: ADR-0091 unresolved final-contract gap set is incorrect")
    for gap_id in REMAINING_FINAL_GAPS:
        matching = next((item for item in items if isinstance(item, dict) and item.get("id") == gap_id), None)
        if matching is None or matching.get("currentState") != "BLOCKED":
            errors.append(f"matrix: final gap {gap_id} must remain BLOCKED")

    asset_item = final_items.get("final.asset-registry-separation")
    if asset_item is not None:
        if asset_item.get("currentState") != "STATIC_VERIFIED":
            errors.append("matrix: asset registry must be STATIC_VERIFIED after focused implementation")
        required_asset_evidence = {
            "implementation/roblox/tooling/validate_asset_registry.py",
            "implementation/roblox/tests/Unit/AssetRegistry.spec.lua",
            "implementation/roblox/src/ServerStorage/RVTT/Content/AssetPackageRegistry.lua",
            "implementation/roblox/src/ReplicatedStorage/RVTT/ContentRuntime/AssetCatalog.lua",
        }
        if not required_asset_evidence.issubset(set(asset_item.get("automatedRefs", []))):
            errors.append("matrix: asset registry blocker cannot close without production and focused evidence")

    reader_item = final_items.get("final.core-rules-reader-filtering")
    if reader_item is not None:
        if reader_item.get("currentState") != "STATIC_VERIFIED":
            errors.append("matrix: Core Rules Reader must be STATIC_VERIFIED after focused implementation")
        required_reader_evidence = {
            "implementation/roblox/src/ServerScriptService/RVTT/Server/Rules/RuleReaderService.lua",
            "implementation/roblox/src/ServerScriptService/RVTT/Server/Networking/RuleReaderQuery.lua",
            "implementation/roblox/src/ReplicatedStorage/RVTT/Shared/Rules/RuleReaderClient.lua",
            "implementation/roblox/src/StarterGui/RVTT/UI/Components/CoreRulesReaderPanel.lua",
            "implementation/roblox/tests/Unit/CoreRulesReader.spec.lua",
            "implementation/roblox/tests/Unit/RuleRuntimePackageBinding.spec.lua",
            "implementation/roblox/tests/Unit/RuleReaderQueryAccess.spec.lua",
            "implementation/roblox/tooling/build_private_rules_runtime.py",
            "implementation/roblox/tooling/validate_private_rules_runtime_pipeline.py",
            "implementation/roblox/tooling/validate_core_rules_reader.py",
        }
        if not required_reader_evidence.issubset(set(reader_item.get("automatedRefs", []))):
            errors.append(
                "matrix: Core Rules Reader cannot close without lazy-load, private stable-link, and nondisclosure evidence"
            )

    rules_item = final_items.get("final.rules-profile-release-leak-gate")
    if rules_item is not None:
        if rules_item.get("currentState") != "STATIC_VERIFIED":
            errors.append("matrix: rules profile/release leak gate must be STATIC_VERIFIED after focused implementation")
        required_rules_evidence = {
            "implementation/roblox/src/ServerStorage/RVTT/Content/RulePackageResolver.lua",
            "implementation/roblox/src/ServerStorage/RVTT/Content/ReleaseContentLeakGate.lua",
            "implementation/roblox/src/ReplicatedStorage/RVTT/ContentRuntime/RuleProfileStatus.lua",
            "implementation/roblox/tests/Unit/RulePackageResolver.spec.lua",
            "implementation/roblox/tests/Unit/ReleaseContentLeakGate.spec.lua",
            "implementation/roblox/tooling/build_public_release_staging.py",
            "implementation/roblox/tooling/validate_rules_profile_release_gate.py",
            ".github/workflows/validate-rvtt-implementation.yml",
        }
        if not required_rules_evidence.issubset(set(rules_item.get("automatedRefs", []))):
            errors.append("matrix: rules profile gate cannot close without production and focused evidence")

    sheet_item = final_items.get("final.official-2024-sheet-interactions")
    if sheet_item is not None:
        if sheet_item.get("currentState") != "STATIC_VERIFIED":
            errors.append("matrix: Official Character Sheet must be STATIC_VERIFIED after focused implementation")
        required_sheet_evidence = {
            "implementation/roblox/src/ServerScriptService/RVTT/Server/Projection/CharacterSheetProjection.lua",
            "implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/CharacterSheetViewModel.lua",
            "implementation/roblox/src/StarterGui/RVTT/UI/Components/OfficialCharacterSheet.lua",
            "implementation/roblox/src/StarterGui/RVTT/UI/Components/SheetItemActionPopover.lua",
            "implementation/roblox/tests/Unit/OfficialCharacterSheet.spec.lua",
            "implementation/roblox/tooling/validate_official_character_sheet.py",
        }
        if not required_sheet_evidence.issubset(set(sheet_item.get("automatedRefs", []))):
            errors.append("matrix: Official Character Sheet cannot close without production and focused evidence")

    dice_item = final_items.get("final.dice-slot-reveal-notice")
    if dice_item is not None:
        if dice_item.get("currentState") != "STATIC_VERIFIED":
            errors.append("matrix: Dice Slot Reveal Notice must be STATIC_VERIFIED after ChatGPT verification")
        if dice_item.get("evidenceStatus", {}).get("STATIC") != "PASS":
            errors.append("matrix: Dice Slot Reveal Notice STATIC evidence must be PASS")
        required_dice_evidence = {
            "implementation/roblox/src/ServerScriptService/RVTT/Server/Projection/DiceNoticeProjection.lua",
            "implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/DiceNoticeViewModel.lua",
            "implementation/roblox/src/StarterGui/RVTT/UI/Components/DiceSlotRevealNotice.lua",
            "implementation/roblox/tests/Unit/DiceSlotRevealNotice.spec.lua",
            "implementation/roblox/tooling/validate_dice_slot_reveal_notice.py",
        }
        if not required_dice_evidence.issubset(set(dice_item.get("automatedRefs", []))):
            errors.append("matrix: Dice Slot Reveal Notice repair evidence is incomplete")

    return errors


def validate_forbidden_player_sources() -> list[str]:
    errors: list[str] = []
    roots = [
        ROOT / "src/StarterGui/RVTT",
        ROOT / "src/StarterPlayer/StarterPlayerScripts/RVTT/Client",
    ]
    for source_root in roots:
        for path in source_root.rglob("*.lua"):
            text = path.read_text(encoding="utf-8")
            for name, pattern in FORBIDDEN_SOURCE_PATTERNS.items():
                if pattern.search(text):
                    relative = path.relative_to(REPO_ROOT)
                    errors.append(f"{relative}: forbidden Player persistent surface token {name}")
    return errors


def validate_studio_retest_harness_texts(
    world_acceptance: str,
    context_acceptance: str,
    world_runtime: str,
    execution_rules: str,
    context_resolver: str,
    input_controller: str,
    shared_console: str,
) -> list[str]:
    errors: list[str] = []
    visible_acceptance = world_acceptance + "\n" + shared_console

    world_markers = {
        'id = "camera-orbit", label = "3D Camera Middle-button Orbit"': "middle-button Orbit summary",
        '["camera-orbit"] = "middle-click drag to orbit"': "middle-button Orbit requirement",
        'action == "orbit" and source == "mouse-middle-screen-delta"': "exact middle-button Orbit signal",
        'action == "pan" and source == "keyboard-wasd"': "separate WASD Pan signal",
        "applied == true": "applied camera evidence",
        "changed == true": "changed camera evidence",
        "2 Camera: WASD Pan / Middle drag Orbit / Wheel Zoom / Frame": (
            "unambiguous visible camera instruction"
        ),
    }
    for marker, description in world_markers.items():
        if marker not in visible_acceptance:
            errors.append(f"studio retest harness: missing {description}")
    if 'id = "camera-pan"' in world_acceptance or 'action == "pan" then "camera-pan"' in world_acceptance:
        errors.append("studio retest harness: middle-button Camera Pan regression is forbidden")
    if "Middle-button drag = Pan" in visible_acceptance or "중클릭 드래그=Pan" in visible_acceptance:
        errors.append("studio retest harness: visible middle-button Pan instruction is forbidden")

    arm_markers = {
        '{ id = "ArmTokenPick", label = "Arm Token Pick"': "explicit Arm Token Pick control",
        "1 Arm Token Pick → left-click Hero": (
            "manual token-pick instruction"
        ),
        "tokenPickArmed = true": "manual arm state",
        "worldTokens.SelectionChanged:Connect": "arm invalidation observer",
        "invalidateTokenPickArm": "explicit re-arm invalidation",
        'summary:pending("token-pick"': "token-pick pending/re-arm state",
        'summary:pending("selection-highlight"': "selection-highlight pending/re-arm state",
    }
    for marker, description in arm_markers.items():
        if marker not in visible_acceptance:
            errors.append(f"studio retest harness: missing {description}")

    arm_start = world_acceptance.find('testConsole:registerAction("ArmTokenPick", function()')
    arm_end = world_acceptance.find('testConsole:registerAction("Frame", function()', arm_start)
    arm_handler = world_acceptance[arm_start:arm_end] if arm_start >= 0 and arm_end >= 0 else ""
    if not arm_handler:
        errors.append("studio retest harness: token-pick selection clear requires an explicit user arm handler")
    else:
        if "worldTokens.Renderer:getTokenModel(heroActorId)" not in arm_handler:
            errors.append("studio retest harness: Arm Token Pick must verify the Hero token exists")
        if "worldTokens.Renderer:setSelected(nil)" not in arm_handler:
            errors.append("studio retest harness: Arm Token Pick must clear only local Renderer selection")
        if arm_handler.find("tokenPickArmed = true") > arm_handler.find("worldTokens.Renderer:setSelected(nil)"):
            errors.append("studio retest harness: arm state must be explicit before local selection clear")
        if re.search(r'pass\s*\(\s*"(?:token-pick|selection-highlight)"', arm_handler):
            errors.append("studio retest harness: arm handler cannot directly PASS token-pick or Highlight")
        for forbidden in ("PickResolved:Fire", ":_pick(", "submit("):
            if forbidden in arm_handler:
                errors.append(f"studio retest harness: arm handler cannot invoke {forbidden}")
        if re.search(r"\b(?:selectedCharacter|ownerUserId|controllerUserId|role)\s*=(?!=)", arm_handler):
            errors.append("studio retest harness: arm handler cannot mutate authority fields")
        if re.search(r"client\.Replica(?:\.payload)?[^\n]*=(?!=)", arm_handler):
            errors.append("studio retest harness: arm handler cannot mutate Replica state")

    if world_acceptance.count("worldTokens.Renderer:setSelected(nil)") != 1 or (
        arm_handler and "worldTokens.Renderer:setSelected(nil)" not in arm_handler
    ):
        errors.append("studio retest harness: local selection clear must exist only in the manual arm handler")

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
            errors.append(f"studio retest harness: missing {description}")
    for pass_id in ("token-pick", "selection-highlight"):
        matches = list(re.finditer(rf'pass\s*\(\s*"{pass_id}"', world_acceptance))
        if len(matches) != 1 or not pick_handler or not (pick_start <= matches[0].start() < pick_end):
            errors.append(f"studio retest harness: {pass_id} may PASS only from real PickResolved")

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
            errors.append(f"studio retest harness: missing {description}")
    if "→Esc→" in context_acceptance or "→Escape→" in context_acceptance:
        errors.append("studio retest harness: stale Esc-close instruction is forbidden")
    for forbidden in ('id = "setup-dummy"', 'id = "attack-menu"', 'id = "attack-default"'):
        if forbidden in context_acceptance:
            errors.append("studio retest harness: G1 single-client DM cannot require attack checks")
    for forbidden in ("training-dummy", "npc.spawn", "combatButton", "Dummy"):
        if forbidden in context_acceptance:
            errors.append("studio retest harness: G1 cannot retain Dummy combat setup or instructions")

    if "mouse-middle-orbit" in world_runtime:
        errors.append("studio retest harness: fake middle-button Pan compatibility signal is forbidden")
    if world_runtime.count("self.Input:ensureSemanticSelection()") < 2:
        errors.append("studio retest harness: Production ensureSemanticSelection must remain at startup and Replica change")

    resolver_markers = {
        'if membershipRole(allDomains, playerId) == "dm" then\n\t\treturn true': "DM controls scene actors",
        "type(targetActor) ~= \"table\" or controlsActor(allDomains, playerId, target.actorId)": (
            "controlled target attack exclusion"
        ),
    }
    for marker, description in resolver_markers.items():
        if marker not in context_resolver:
            errors.append(f"studio retest harness: Production authority drifted: {description}")

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
        errors.append("studio retest harness: Production controllable-target selection precedence drifted")
    elif left_click.index(selection_marker) > left_click.index("local actions = self:resolveActionsForTarget(target)"):
        errors.append("studio retest harness: controllable-target selection must precede default action resolution")
    if left_click.count("self:_pick(") != 2:
        errors.append("studio retest harness: Production _leftClick pick reachability semantics drifted")

    rules_markers = {
        "`planning/rvtt-remake`": "general planning branch default",
        "PR-bound Batch Acceptance 예외": "narrow PR-bound exception",
        '$repository = "Kaetaeru/RVTT"': "exact repository",
        "$pullRequest = 2": "exact Pull Request",
        '$branch = "agent/survival-logistics-token-authoring"': "exact branch",
        "git fetch origin $branch": "exact branch fetch",
        "git switch $branch": "exact branch switch",
        "git pull --ff-only origin $branch": "exact branch pull",
        "git rev-parse --short=7 HEAD": "exact 7-character HEAD check",
        "REQUESTED-NON-PERSISTENCE-ACCEPTANCE-PROJECT": "requested non-persistence project",
        "branch나 project를 추론하지 않는다": "no-inference boundary",
        "current-head Static Gate": "static-gate boundary",
        "중클릭 Camera Orbit": "current batch middle-button Orbit instruction",
    }
    for marker, description in rules_markers.items():
        if marker not in execution_rules:
            errors.append(f"studio retest harness: missing execution-rule {description}")

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
            errors.append("G1 usability fix: independent legacy acceptance ScreenGui returned")
    if 'Instance.new("ScreenGui")' in world_acceptance or 'Instance.new("ScreenGui")' in context_acceptance:
        errors.append("G1 usability fix: World and Context scripts must not create independent ScreenGuis")
    if shared_console.count('Instance.new("ScreenGui")') != 1:
        errors.append("G1 usability fix: exactly one shared G1 ScreenGui is required")

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
            errors.append(f"G1 usability fix: missing {description}")
    if "TextBox" in shared_console or "GuiService.SelectedObject" in shared_console:
        errors.append("G1 usability fix: shared console cannot capture text or mutate SelectedObject")

    for source, batch_name in (
        (world_acceptance, "slice01-world-interaction"),
        (context_acceptance, "contextual-pointer-actions"),
    ):
        if 'WaitForChild("AcceptanceShared"):WaitForChild("G1TestConsole")' not in source:
            errors.append(f"G1 usability fix: {batch_name} does not use the shared console")
        if "testConsole:registerBatch(BATCH_NAME, summary)" not in source:
            errors.append(f"G1 usability fix: {batch_name} does not register combined progress")
        if "summary:log(client.Replica.revision)" not in source:
            errors.append(f"G1 usability fix: {batch_name} authoritative Output summary was removed")
    for action_id in ("Prepare", "ArmTokenPick", "Frame"):
        if f'testConsole:registerAction("{action_id}"' not in world_acceptance:
            errors.append(f"G1 usability fix: missing shared World action {action_id}")
    for action_id in ("Exploration", "FinalSummary"):
        if f'testConsole:registerAction("{action_id}"' not in context_acceptance:
            errors.append(f"G1 usability fix: missing shared Context action {action_id}")

    if '"AcceptanceShared": {' not in slice_project or '"$path": "tests/AcceptanceShared"' not in slice_project:
        errors.append("G1 usability fix: Slice 01 project does not mount acceptance-only shared UI")
    if "AcceptanceShared" in default_project or "tests/AcceptanceShared" in default_project:
        errors.append("G1 usability fix: production default project mounted acceptance-only UI")

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
            errors.append(f"G1 usability fix: WorldActionMenu missing {description}")
    if re.search(r"GuiService\.SelectedObject\s*=", action_menu):
        errors.append("G1 usability fix: WorldActionMenu cannot assign GuiService.SelectedObject")
    if "previousSelectedObject" in action_menu:
        errors.append("G1 usability fix: obsolete WorldActionMenu selected-object restore returned")
    if "AutoSelectGuiEnabled" in action_menu:
        errors.append("G1 usability fix: global AutoSelectGuiEnabled mutation is forbidden")
    policy_markers = {
        "actionButtonSelectable = false": "PC pointer buttons non-selectable policy",
        "mutatesSelectedObject = false": "selected-object preservation policy",
    }
    for marker, description in policy_markers.items():
        if marker not in action_menu_policy:
            errors.append(f"G1 usability fix: missing {description}")

    changed_start = recovery_coordinator.find("replica.Changed:Connect(function()")
    changed_end = recovery_coordinator.find("replica.RebuildStarted:Connect(function()", changed_start)
    changed_handler = recovery_coordinator[changed_start:changed_end] if changed_start >= 0 and changed_end >= 0 else ""
    recovery_markers = {
        "self.state.state == ViewState.LOADING": "initial LOADING-only guard",
        "replica.revision >= 0": "valid Replica revision guard",
        "self:_set(ViewState.READY, nil, false)": "normal Projection READY transition",
    }
    for marker, description in recovery_markers.items():
        if marker not in changed_handler:
            errors.append(f"G1 usability fix: recovery coordinator missing {description}")
    for forbidden in (
        "ViewState.REBUILDING",
        "ViewState.RECOVERY",
        "ViewState.NETWORK_ERROR",
        "ViewState.STALE",
        "ViewState.CONFLICT",
        "ViewState.FATAL",
    ):
        if forbidden in changed_handler:
            errors.append("G1 usability fix: Replica.Changed handler must not clear explicit recovery/error states")
    if 'phase = "loading"' in recovery_coordinator or 'phase = "ready"' in recovery_coordinator:
        errors.append("G1 usability fix: recovery coordinator cannot forge Session phase")

    recovery_spec_markers = {
        '"a normal first Projection releases initial loading"': "normal first Projection regression",
        '"Replica changes do not clear explicit "': "protected recovery/error regression",
        "ViewState.REBUILDING": "REBUILDING protected state",
        "ViewState.RECOVERY": "RECOVERY protected state",
        "ViewState.NETWORK_ERROR": "NETWORK_ERROR protected state",
        "ViewState.STALE": "STALE protected state",
        "ViewState.CONFLICT": "CONFLICT protected state",
        "ViewState.FATAL": "FATAL protected state",
    }
    for marker, description in recovery_spec_markers.items():
        if marker not in entry_recovery_spec:
            errors.append(f"G1 usability fix: EntryRecovery spec missing {description}")
    input_spec_markers = {
        "not WorldActionMenuPolicy.actionButtonSelectable": "non-selectable action-menu spec",
        "not WorldActionMenuPolicy.mutatesSelectedObject": "selected-object preservation spec",
        '"right click is consumed while the action table is open"': "existing pointer input spec",
        '"Q closes the action table"': "existing Q grammar spec",
        '"middle drag remains available to the independent camera controller"': "existing camera grammar spec",
    }
    for marker, description in input_spec_markers.items():
        if marker not in input_context_spec:
            errors.append(f"G1 usability fix: InputContext spec missing {description}")

    return errors


def validate_studio_retest_harness() -> list[str]:
    return validate_studio_retest_harness_texts(
        WORLD_ACCEPTANCE_PATH.read_text(encoding="utf-8"),
        CONTEXT_ACCEPTANCE_PATH.read_text(encoding="utf-8"),
        WORLD_RUNTIME_PATH.read_text(encoding="utf-8"),
        EXECUTION_RULES_PATH.read_text(encoding="utf-8"),
        CONTEXT_RESOLVER_PATH.read_text(encoding="utf-8"),
        INPUT_CONTROLLER_PATH.read_text(encoding="utf-8"),
        G1_TEST_CONSOLE_PATH.read_text(encoding="utf-8"),
    )


def validate_g1_usability_fix() -> list[str]:
    return validate_g1_usability_fix_texts(
        WORLD_ACCEPTANCE_PATH.read_text(encoding="utf-8"),
        CONTEXT_ACCEPTANCE_PATH.read_text(encoding="utf-8"),
        G1_TEST_CONSOLE_PATH.read_text(encoding="utf-8"),
        WORLD_ACTION_MENU_PATH.read_text(encoding="utf-8"),
        WORLD_ACTION_MENU_POLICY_PATH.read_text(encoding="utf-8"),
        UI_RECOVERY_COORDINATOR_PATH.read_text(encoding="utf-8"),
        ENTRY_RECOVERY_SPEC_PATH.read_text(encoding="utf-8"),
        INPUT_CONTEXT_SPEC_PATH.read_text(encoding="utf-8"),
        SLICE01_ACCEPTANCE_PROJECT_PATH.read_text(encoding="utf-8"),
        DEFAULT_PROJECT_PATH.read_text(encoding="utf-8"),
    )


def validate(root: Path = ROOT) -> list[str]:
    if root != ROOT:
        raise ValueError("validate_full_ui_ux_acceptance only supports its repository checkout")
    errors: list[str] = []
    matrix = _load_json(MATRIX_PATH, errors)
    manifest = _load_json(MANIFEST_PATH, errors)
    if matrix and manifest:
        errors.extend(validate_matrix_data(matrix, manifest))
    errors.extend(validate_asset_registry(ROOT))
    errors.extend(validate_rules_profile_gate(ROOT))
    errors.extend(validate_core_rules_reader(ROOT))
    errors.extend(validate_official_character_sheet(ROOT))
    errors.extend(validate_dice_slot_reveal_notice(ROOT))
    errors.extend(validate_forbidden_player_sources())
    errors.extend(validate_studio_retest_harness())
    errors.extend(validate_g1_usability_fix())
    return errors


def run_self_tests(matrix: dict, manifest: dict) -> list[str]:
    failures: list[str] = []
    fixtures = []

    duplicate = deepcopy(matrix)
    duplicate["acceptanceItems"].append(deepcopy(duplicate["acceptanceItems"][0]))
    fixtures.append((duplicate, "duplicate acceptance id"))

    unknown_class = deepcopy(matrix)
    unknown_class["acceptanceItems"][0]["evidenceClasses"].append("MAGIC")
    unknown_class["acceptanceItems"][0]["evidenceStatus"]["MAGIC"] = "PASS"
    fixtures.append((unknown_class, "unknown evidence classes"))

    false_runtime_pass = deepcopy(matrix)
    false_runtime_pass["runtimeBatches"][0]["status"] = "PASS"
    fixtures.append((false_runtime_pass, "cannot claim runtime or human PASS"))

    missing_reason = deepcopy(matrix)
    blocked = missing_reason["acceptanceItems"][0]
    blocked["currentState"] = "BLOCKED"
    blocked.pop("blockerReason", None)
    blocked.pop("deferReason", None)
    fixtures.append((missing_reason, "requires blockerReason or deferReason"))

    stale_surface = deepcopy(matrix)
    target = next(item for item in stale_surface["acceptanceItems"] if item["id"] == "hud.exploration-composition")
    target["requirement"] = "Player Minimap is required"
    fixtures.append((stale_surface, "forbidden Player surface was registered as required"))

    missing_asset_evidence = deepcopy(matrix)
    asset_item = next(item for item in missing_asset_evidence["acceptanceItems"] if item["id"] == "final.asset-registry-separation")
    asset_item["automatedRefs"] = []
    fixtures.append((missing_asset_evidence, "asset registry blocker cannot close without production and focused evidence"))

    missing_reader_evidence = deepcopy(matrix)
    reader_item = next(item for item in missing_reader_evidence["acceptanceItems"] if item["id"] == "final.core-rules-reader-filtering")
    reader_item["automatedRefs"] = []
    fixtures.append(
        (
            missing_reader_evidence,
            "Core Rules Reader cannot close without lazy-load, private stable-link, and nondisclosure evidence",
        )
    )

    missing_rules_evidence = deepcopy(matrix)
    rules_item = next(item for item in missing_rules_evidence["acceptanceItems"] if item["id"] == "final.rules-profile-release-leak-gate")
    rules_item["automatedRefs"] = []
    fixtures.append((missing_rules_evidence, "rules profile gate cannot close without production and focused evidence"))

    missing_sheet_evidence = deepcopy(matrix)
    sheet_item = next(item for item in missing_sheet_evidence["acceptanceItems"] if item["id"] == "final.official-2024-sheet-interactions")
    sheet_item["automatedRefs"] = []
    fixtures.append((missing_sheet_evidence, "Official Character Sheet cannot close without production and focused evidence"))

    missing_dice_evidence = deepcopy(matrix)
    dice_item = next(item for item in missing_dice_evidence["acceptanceItems"] if item["id"] == "final.dice-slot-reveal-notice")
    dice_item["automatedRefs"] = []
    fixtures.append((missing_dice_evidence, "Dice Slot Reveal Notice repair evidence is incomplete"))

    dice_blocked = deepcopy(matrix)
    dice_item = next(item for item in dice_blocked["acceptanceItems"] if item["id"] == "final.dice-slot-reveal-notice")
    dice_item["currentState"] = "BLOCKED"
    dice_item["evidenceStatus"]["STATIC"] = "BLOCKED"
    dice_item["blockerReason"] = "negative fixture"
    fixtures.append((dice_blocked, "Dice Slot Reveal Notice must be STATIC_VERIFIED"))

    dice_static_not_pass = deepcopy(matrix)
    dice_item = next(
        item for item in dice_static_not_pass["acceptanceItems"] if item["id"] == "final.dice-slot-reveal-notice"
    )
    dice_item["evidenceStatus"]["STATIC"] = "NOT_EXECUTED"
    fixtures.append((dice_static_not_pass, "Dice Slot Reveal Notice STATIC evidence must be PASS"))

    stale_dice_gap = deepcopy(matrix)
    stale_dice_gap["finalContractGaps"] = ["final.dice-slot-reveal-notice"]
    fixtures.append((stale_dice_gap, "finalContractGaps must equal the actual BLOCKED final-contract subset"))

    hidden_blocked_final = deepcopy(matrix)
    asset_item = next(
        item for item in hidden_blocked_final["acceptanceItems"] if item["id"] == "final.asset-registry-separation"
    )
    asset_item["currentState"] = "BLOCKED"
    asset_item["evidenceStatus"]["STATIC"] = "BLOCKED"
    asset_item["blockerReason"] = "negative fixture"
    fixtures.append((hidden_blocked_final, "finalContractGaps must equal the actual BLOCKED final-contract subset"))

    missing_g2_attack = deepcopy(matrix)
    missing_g2_attack["acceptanceItems"] = [
        item for item in missing_g2_attack["acceptanceItems"] if item["id"] != "input.player-hostile-attack-pointer"
    ]
    fixtures.append((missing_g2_attack, "G2 Player-vs-hostile attack runtime coverage is missing"))

    g2_attack_in_g1 = deepcopy(matrix)
    attack_item = next(
        item for item in g2_attack_in_g1["acceptanceItems"] if item["id"] == "input.player-hostile-attack-pointer"
    )
    attack_item["runtimeBatchIds"] = ["G1"]
    fixtures.append((g2_attack_in_g1, "Player-vs-hostile attack runtime evidence must belong only to G2"))

    pointer_loses_g2 = deepcopy(matrix)
    pointer_item = next(item for item in pointer_loses_g2["acceptanceItems"] if item["id"] == "input.pointer-grammar")
    pointer_item["runtimeBatchIds"] = ["G1"]
    pointer_item["evidenceClasses"] = ["STATIC", "STUDIO_SINGLE_CLIENT"]
    pointer_item["evidenceStatus"].pop("STUDIO_MULTI_CLIENT")
    fixtures.append((pointer_loses_g2, "input.pointer-grammar must separate G1 input evidence from G2 attack evidence"))

    for fixture, expected in fixtures:
        fixture_errors = validate_matrix_data(fixture, manifest)
        if not any(expected in error for error in fixture_errors):
            failures.append(f"validator self-test did not reject fixture: {expected}")

    world = WORLD_ACCEPTANCE_PATH.read_text(encoding="utf-8")
    context = CONTEXT_ACCEPTANCE_PATH.read_text(encoding="utf-8")
    runtime = WORLD_RUNTIME_PATH.read_text(encoding="utf-8")
    rules = EXECUTION_RULES_PATH.read_text(encoding="utf-8")
    resolver = CONTEXT_RESOLVER_PATH.read_text(encoding="utf-8")
    controller = INPUT_CONTROLLER_PATH.read_text(encoding="utf-8")
    shared = G1_TEST_CONSOLE_PATH.read_text(encoding="utf-8")
    harness_fixtures = [
        (
            world.replace('action == "orbit" and source == "mouse-middle-screen-delta"', 'action == "pan"'),
            context,
            runtime,
            rules,
            "exact middle-button Orbit signal",
        ),
        (
            world,
            context.replace("input.KeyCode == Enum.KeyCode.Q", "input.KeyCode == Enum.KeyCode.Unknown"),
            runtime,
            rules,
            "explicit Q input evidence",
        ),
        (
            world,
            context.replace("input.KeyCode == Enum.KeyCode.Escape", "input.KeyCode == Enum.KeyCode.Unknown"),
            runtime,
            rules,
            "explicit ESC input evidence",
        ),
        (
            world,
            context + '\nlocal staleInstruction = "→Esc→"\n',
            runtime,
            rules,
            "stale Esc-close instruction",
        ),
        (
            world.replace('action == "pan" and source == "keyboard-wasd"', 'action == "orbit"'),
            context,
            runtime,
            rules,
            "separate WASD Pan signal",
        ),
        (
            world,
            context,
            runtime + '\nlocal source = "mouse-middle-orbit"\n',
            rules,
            "fake middle-button Pan compatibility signal",
        ),
        (
            world,
            context,
            runtime,
            rules,
            "visible middle-button Pan instruction",
        ),
        (
            world,
            context + '\nlocal required = { id = "attack-menu" }\n',
            runtime,
            rules,
            "G1 single-client DM cannot require attack checks",
        ),
        (
            world,
            context + '\nlocal instruction = "Attack the Dummy"\n',
            runtime,
            rules,
            "G1 cannot retain Dummy combat setup or instructions",
        ),
        (
            world.replace(
                'testConsole:registerAction("ArmTokenPick", function()',
                'testConsole:registerAction("MissingArm", function()',
                1,
            ),
            context,
            runtime,
            rules,
            "selection clear requires an explicit user arm handler",
        ),
        (
            world.replace("\tlocal cleared = worldTokens.Renderer:setSelected(nil)\n", "", 1).replace(
                "local function prepareScene()",
                "worldTokens.Renderer:setSelected(nil)\n\nlocal function prepareScene()",
                1,
            ),
            context,
            runtime,
            rules,
            "local selection clear must exist only in the manual arm handler",
        ),
        (
            world.replace(
                "\ttokenPickArmed = true\n",
                '\tpass("token-pick", "fake arm PASS")\n\ttokenPickArmed = true\n',
                1,
            ),
            context,
            runtime,
            rules,
            "arm handler cannot directly PASS token-pick or Highlight",
        ),
        (
            world.replace(
                "\tlocal cleared = worldTokens.Renderer:setSelected(nil)\n",
                "\tworldTokens.PickResolved:Fire(heroActorId, \"ray\", true, \"fake\")\n"
                "\tlocal cleared = worldTokens.Renderer:setSelected(nil)\n",
                1,
            ),
            context,
            runtime,
            rules,
            "arm handler cannot invoke PickResolved:Fire",
        ),
        (
            world.replace(
                "\tlocal cleared = worldTokens.Renderer:setSelected(nil)\n",
                '\tsubmit("session.select_character", { characterId = heroActorId })\n'
                "\tlocal cleared = worldTokens.Renderer:setSelected(nil)\n",
                1,
            ),
            context,
            runtime,
            rules,
            "arm handler cannot invoke submit(",
        ),
        (
            world.replace(
                'testConsole:registerAction("ArmTokenPick", function()\n\tlocal state = currentState()\n',
                'testConsole:registerAction("ArmTokenPick", function()\n'
                '\tlocal state = currentState()\n\tstate.membership.role = "player"\n',
                1,
            ),
            context,
            runtime,
            rules,
            "arm handler cannot mutate authority fields",
        ),
        (
            world,
            context,
            runtime.replace("\tself.Input:ensureSemanticSelection()\n", ""),
            rules,
            "Production ensureSemanticSelection must remain at startup and Replica change",
        ),
    ]
    for world_fixture, context_fixture, runtime_fixture, rules_fixture, expected in harness_fixtures:
        shared_fixture = (
            shared.replace(
                "2 Camera: WASD Pan / Middle drag Orbit / Wheel Zoom / Frame",
                "2 Camera: WASD Pan / Middle-button drag = Pan / Wheel Zoom / Frame",
            )
            if expected == "visible middle-button Pan instruction"
            else shared
        )
        fixture_errors = validate_studio_retest_harness_texts(
            world_fixture,
            context_fixture,
            runtime_fixture,
            rules_fixture,
            resolver,
            controller,
            shared_fixture,
        )
        if not any(expected in error for error in fixture_errors):
            failures.append(f"validator self-test did not reject harness fixture: {expected}")

    authority_fixtures = [
        (
            resolver.replace(
                'if membershipRole(allDomains, playerId) == "dm" then\n\t\treturn true',
                'if membershipRole(allDomains, playerId) == "dm" then\n\t\treturn false',
            ),
            controller,
            "DM controls scene actors",
        ),
        (
            resolver.replace(
                'type(targetActor) ~= "table" or controlsActor(allDomains, playerId, target.actorId)',
                'type(targetActor) ~= "table"',
            ),
            controller,
            "controlled target attack exclusion",
        ),
        (
            resolver,
            controller.replace(
                "and target.actorId ~= selectedActorId\n\t\tand self.resolver:isControllable(target.actorId)",
                "and target.actorId ~= selectedActorId\n\t\tand false",
                1,
            ),
            "controllable-target selection precedence",
        ),
        (
            resolver,
            controller.replace(
                "\t\treturn\n\tend\n\n\tlocal actions = self:resolveActionsForTarget(target)\n",
                "\t\treturn\n\tend\n\n"
                '\tself:_pick(selectedActorId, "acceptance-reclick", target.instance)\n'
                "\tlocal actions = self:resolveActionsForTarget(target)\n",
                1,
            ),
            "Production _leftClick pick reachability semantics drifted",
        ),
    ]
    for resolver_fixture, controller_fixture, expected in authority_fixtures:
        fixture_errors = validate_studio_retest_harness_texts(
            world,
            context,
            runtime,
            rules,
            resolver_fixture,
            controller_fixture,
            shared,
        )
        if not any(expected in error for error in fixture_errors):
            failures.append(f"validator self-test did not reject authority fixture: {expected}")

    fix004_sources = {
        "world_acceptance": world,
        "context_acceptance": context,
        "shared_console": shared,
        "action_menu": WORLD_ACTION_MENU_PATH.read_text(encoding="utf-8"),
        "action_menu_policy": WORLD_ACTION_MENU_POLICY_PATH.read_text(encoding="utf-8"),
        "recovery_coordinator": UI_RECOVERY_COORDINATOR_PATH.read_text(encoding="utf-8"),
        "entry_recovery_spec": ENTRY_RECOVERY_SPEC_PATH.read_text(encoding="utf-8"),
        "input_context_spec": INPUT_CONTEXT_SPEC_PATH.read_text(encoding="utf-8"),
        "slice_project": SLICE01_ACCEPTANCE_PROJECT_PATH.read_text(encoding="utf-8"),
        "default_project": DEFAULT_PROJECT_PATH.read_text(encoding="utf-8"),
    }
    fix004_fixtures = [
        (
            "world_acceptance",
            world + '\nlocal duplicateGui = Instance.new("ScreenGui")\n',
            "World and Context scripts must not create independent ScreenGuis",
        ),
        (
            "shared_console",
            shared.replace('local gui = Instance.new("ScreenGui")', 'local gui = Instance.new("Frame")', 1),
            "exactly one shared G1 ScreenGui is required",
        ),
        (
            "shared_console",
            shared.replace("header.InputBegan:Connect", "header.MouseEnter:Connect", 1),
            "missing mouse drag start",
        ),
        (
            "shared_console",
            shared.replace("button.Selectable = false", "button.Selectable = true", 1),
            "missing non-selectable acceptance buttons",
        ),
        (
            "shared_console",
            shared + "\nGuiService.SelectedObject = panel\n",
            "shared console cannot capture text or mutate SelectedObject",
        ),
        (
            "action_menu",
            fix004_sources["action_menu"] + "\nGuiService.SelectedObject = firstButton\n",
            "WorldActionMenu cannot assign GuiService.SelectedObject",
        ),
        (
            "action_menu",
            fix004_sources["action_menu"] + "\nlocal previousSelectedObject = GuiService.SelectedObject\n",
            "obsolete WorldActionMenu selected-object restore returned",
        ),
        (
            "recovery_coordinator",
            fix004_sources["recovery_coordinator"].replace(
                "self.state.state == ViewState.LOADING and replica.revision >= 0",
                "replica.revision >= 0",
                1,
            ),
            "initial LOADING-only guard",
        ),
        (
            "recovery_coordinator",
            fix004_sources["recovery_coordinator"].replace(
                "self.state.state == ViewState.LOADING and replica.revision >= 0",
                "self.state.state == ViewState.NETWORK_ERROR or replica.revision >= 0",
                1,
            ),
            "must not clear explicit recovery/error states",
        ),
        (
            "default_project",
            fix004_sources["default_project"] + '\n"AcceptanceShared": {"$path": "tests/AcceptanceShared"}\n',
            "production default project mounted acceptance-only UI",
        ),
    ]
    for key, value, expected in fix004_fixtures:
        fixture_sources = dict(fix004_sources)
        fixture_sources[key] = value
        fixture_errors = validate_g1_usability_fix_texts(**fixture_sources)
        if not any(expected in error for error in fixture_errors):
            failures.append(f"validator self-test did not reject FIX-004 fixture: {expected}")
    return failures


def main() -> int:
    errors = validate()
    matrix = _load_json(MATRIX_PATH, errors)
    manifest = _load_json(MANIFEST_PATH, errors)
    if matrix and manifest:
        errors.extend(run_self_tests(matrix, manifest))
    errors.extend(run_asset_registry_self_tests())
    errors.extend(run_rules_profile_self_tests())
    errors.extend(run_official_sheet_self_tests())
    errors.extend(run_dice_notice_self_tests())
    if errors:
        print("Full UI/UX acceptance validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print(
        "Full UI/UX acceptance validation passed: "
        f"{len(matrix['acceptanceItems'])} items, {len(matrix['runtimeBatches'])} batches, "
        f"{len(matrix['finalContractGaps'])} explicit final-contract gaps"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
