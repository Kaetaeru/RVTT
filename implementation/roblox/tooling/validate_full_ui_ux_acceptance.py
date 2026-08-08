from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import json
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
MATRIX_PATH = ROOT / "full-ui-ux-acceptance-matrix.json"
MANIFEST_PATH = ROOT / "grand-acceptance-manifest.json"

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

REQUIRED_FINAL_GAPS = {
    "final.asset-registry-separation",
    "final.official-2024-sheet-interactions",
    "final.dice-slot-reveal-notice",
    "final.core-rules-reader-filtering",
    "final.rules-profile-release-leak-gate",
}

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

    final_gaps = set(matrix.get("finalContractGaps", []))
    if final_gaps != REQUIRED_FINAL_GAPS:
        errors.append("matrix: ADR-0091 final-contract gap audit is incomplete")
    for gap_id in REQUIRED_FINAL_GAPS:
        matching = next((item for item in items if isinstance(item, dict) and item.get("id") == gap_id), None)
        if matching is None or matching.get("currentState") != "BLOCKED":
            errors.append(f"matrix: final gap {gap_id} must remain BLOCKED")

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


def validate(root: Path = ROOT) -> list[str]:
    if root != ROOT:
        raise ValueError("validate_full_ui_ux_acceptance only supports its repository checkout")
    errors: list[str] = []
    matrix = _load_json(MATRIX_PATH, errors)
    manifest = _load_json(MANIFEST_PATH, errors)
    if matrix and manifest:
        errors.extend(validate_matrix_data(matrix, manifest))
    errors.extend(validate_forbidden_player_sources())
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
    blocked = next(item for item in missing_reason["acceptanceItems"] if item["currentState"] == "BLOCKED")
    blocked.pop("blockerReason", None)
    blocked.pop("deferReason", None)
    fixtures.append((missing_reason, "requires blockerReason or deferReason"))

    stale_surface = deepcopy(matrix)
    target = next(item for item in stale_surface["acceptanceItems"] if item["id"] == "hud.exploration-composition")
    target["requirement"] = "Player Minimap is required"
    fixtures.append((stale_surface, "forbidden Player surface was registered as required"))

    for fixture, expected in fixtures:
        fixture_errors = validate_matrix_data(fixture, manifest)
        if not any(expected in error for error in fixture_errors):
            failures.append(f"validator self-test did not reject fixture: {expected}")
    return failures


def main() -> int:
    errors = validate()
    matrix = _load_json(MATRIX_PATH, errors)
    manifest = _load_json(MANIFEST_PATH, errors)
    if matrix and manifest:
        errors.extend(run_self_tests(matrix, manifest))
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
