from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
REGISTRY_PATH = ROOT / "manifests/module-contracts.json"
LEGACY_REGISTRY_PATH = ROOT / "manifests/legacy-module-contracts.json"

VALID_STATUSES = {"PLANNED", "IMPLEMENTED", "ACCEPTED", "DEPRECATED"}
VALID_KINDS = {
    "bootstrap",
    "app_composition",
    "shared_contract",
    "client_input",
    "client_transport",
    "client_projection",
    "client_system",
    "client_controller",
    "client_presenter",
    "server_runtime",
    "authorization",
    "state_store",
    "domain",
    "projection",
}
VALID_AUTHORITIES = {
    "server_authoritative",
    "server_projection",
    "client_intent_only",
    "client_projection_only",
    "client_local_state",
    "pure_contract",
    "no_authority",
}
MODULE_ID = re.compile(r"^[a-z0-9]+(?:[.-][a-z0-9]+)*$")
ENTRY_POINT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def load_json(path: Path) -> tuple[dict, list[str]]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {}, [f"{path.relative_to(REPO_ROOT)}: {exc}"]
    if not isinstance(value, dict):
        return {}, [f"{path.relative_to(REPO_ROOT)}: root must be an object"]
    return value, []


def validate() -> list[str]:
    registry, errors = load_json(REGISTRY_PATH)
    if not registry:
        return errors

    legacy, legacy_errors = load_json(LEGACY_REGISTRY_PATH)
    errors.extend(legacy_errors)
    if legacy and legacy.get("schemaVersion") != 1:
        errors.append("module contracts: legacy registry must remain schemaVersion 1 historical reference")

    if registry.get("schemaVersion") != 2:
        errors.append("module contracts: schemaVersion must be 2")
    if registry.get("registryId") != "rvtt-greenfield-module-contracts-v2":
        errors.append("module contracts: unexpected registryId")
    if registry.get("authorityDocument") != "implementation/roblox/MODULE-CONTRACTS.md":
        errors.append("module contracts: authorityDocument drifted")
    if registry.get("buildMode") != "GREENFIELD_ARCHITECTURE_FIRST":
        errors.append("module contracts: buildMode must be GREENFIELD_ARCHITECTURE_FIRST")
    if registry.get("sourceRoot") != "greenfield/src":
        errors.append("module contracts: sourceRoot must be greenfield/src")
    if registry.get("legacyReferenceRegistry") != "implementation/roblox/manifests/legacy-module-contracts.json":
        errors.append("module contracts: legacyReferenceRegistry drifted")
    if registry.get("internalCallGraphPolicy") != "source-derived":
        errors.append("module contracts: internalCallGraphPolicy must remain source-derived")

    modules = registry.get("modules")
    if not isinstance(modules, list) or not modules:
        errors.append("module contracts: modules must be a non-empty array")
        return errors

    required_fields = {
        "id",
        "status",
        "plannedPath",
        "kind",
        "responsibility",
        "entryPoints",
        "dependsOn",
        "authority",
        "stateOwnership",
        "legacyCandidates",
        "testRefs",
    }

    ids: set[str] = set()
    paths: set[str] = set()
    by_id: dict[str, dict] = {}

    for index, module in enumerate(modules):
        if not isinstance(module, dict):
            errors.append(f"module contracts: modules[{index}] must be an object")
            continue
        missing = required_fields - set(module)
        module_id = module.get("id")
        if missing:
            errors.append(f"module contracts: {module_id or index} missing fields {sorted(missing)}")
            continue
        if not isinstance(module_id, str) or not MODULE_ID.fullmatch(module_id):
            errors.append(f"module contracts: invalid module id {module_id!r}")
            continue
        if module_id in ids:
            errors.append(f"module contracts: duplicate module id {module_id}")
        ids.add(module_id)
        by_id[module_id] = module

        status = module.get("status")
        if status not in VALID_STATUSES:
            errors.append(f"module contracts: {module_id} has invalid status {status!r}")
        kind = module.get("kind")
        if kind not in VALID_KINDS:
            errors.append(f"module contracts: {module_id} has invalid kind {kind!r}")
        authority = module.get("authority")
        if authority not in VALID_AUTHORITIES:
            errors.append(f"module contracts: {module_id} has invalid authority {authority!r}")

        path = module.get("plannedPath")
        if not isinstance(path, str) or not path.startswith("greenfield/src/") or not path.endswith(".lua"):
            errors.append(f"module contracts: {module_id} has invalid plannedPath {path!r}")
        elif path in paths:
            errors.append(f"module contracts: duplicate plannedPath {path}")
        else:
            paths.add(path)

        responsibility = module.get("responsibility")
        if not isinstance(responsibility, str) or not responsibility.strip():
            errors.append(f"module contracts: {module_id} requires responsibility")

        for field in ("entryPoints", "dependsOn", "stateOwnership", "legacyCandidates", "testRefs"):
            value = module.get(field)
            if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
                errors.append(f"module contracts: {module_id}.{field} must be an array of strings")
        state_ownership = module.get("stateOwnership")
        if isinstance(state_ownership, list) and not state_ownership:
            errors.append(f"module contracts: {module_id}.stateOwnership must state ownership or 'none'")

        entry_points = module.get("entryPoints")
        if isinstance(entry_points, list):
            for entry_point in entry_points:
                if not ENTRY_POINT.fullmatch(entry_point):
                    errors.append(f"module contracts: {module_id} has invalid entry point {entry_point!r}")

        if status in {"IMPLEMENTED", "ACCEPTED"} and isinstance(path, str):
            source_path = ROOT / path
            if not source_path.is_file():
                errors.append(f"module contracts: {module_id} is {status} but source is missing: {path}")
            else:
                source = source_path.read_text(encoding="utf-8")
                if isinstance(entry_points, list):
                    for entry_point in entry_points:
                        if re.search(rf"\b{re.escape(entry_point)}\b", source) is None:
                            errors.append(
                                f"module contracts: {module_id} stable entry point token disappeared: {entry_point}"
                            )

        test_refs = module.get("testRefs")
        if status == "ACCEPTED" and isinstance(test_refs, list) and not test_refs:
            errors.append(f"module contracts: {module_id} is ACCEPTED but has no focused testRefs")
        if isinstance(test_refs, list):
            for test_ref in test_refs:
                if not test_ref.startswith("greenfield/tests/"):
                    errors.append(f"module contracts: {module_id} test ref must be under greenfield/tests/: {test_ref}")
                elif status in {"IMPLEMENTED", "ACCEPTED"} and not (ROOT / test_ref).is_file():
                    errors.append(f"module contracts: {module_id} missing test ref {test_ref}")

    for module_id, module in by_id.items():
        dependencies = module.get("dependsOn", [])
        if not isinstance(dependencies, list):
            continue
        seen: set[str] = set()
        for dependency in dependencies:
            if dependency == module_id:
                errors.append(f"module contracts: {module_id} cannot depend on itself")
            if dependency in seen:
                errors.append(f"module contracts: {module_id} duplicates dependency {dependency}")
            seen.add(dependency)
            if dependency not in by_id:
                errors.append(f"module contracts: {module_id} references unknown dependency {dependency}")

    foundation_required = registry.get("foundationRequired")
    if not isinstance(foundation_required, list) or not all(isinstance(item, str) for item in foundation_required):
        errors.append("module contracts: foundationRequired must be an array of module ids")
        foundation_required = []
    for module_id in foundation_required:
        if module_id not in by_id:
            errors.append(f"module contracts: foundationRequired references unknown module {module_id}")

    checkpoints = registry.get("deliveryCheckpoints")
    if not isinstance(checkpoints, list) or not checkpoints:
        errors.append("module contracts: deliveryCheckpoints must be a non-empty array")
    else:
        checkpoint_ids: set[str] = set()
        for checkpoint in checkpoints:
            if not isinstance(checkpoint, dict):
                errors.append("module contracts: checkpoint must be an object")
                continue
            checkpoint_id = checkpoint.get("id")
            if not isinstance(checkpoint_id, str) or not checkpoint_id:
                errors.append("module contracts: checkpoint requires id")
                continue
            if checkpoint_id in checkpoint_ids:
                errors.append(f"module contracts: duplicate checkpoint {checkpoint_id}")
            checkpoint_ids.add(checkpoint_id)
            if checkpoint.get("requiresUserAcceptance") is not True:
                errors.append(f"module contracts: {checkpoint_id} must require user acceptance")
            required = checkpoint.get("modulesRequired")
            if not isinstance(required, list) or not all(isinstance(item, str) for item in required):
                errors.append(f"module contracts: {checkpoint_id}.modulesRequired must be an array")
                continue
            for module_id in required:
                if module_id not in by_id:
                    errors.append(f"module contracts: {checkpoint_id} references unknown module {module_id}")

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("RVTT Greenfield module contract validation failed:")
        for error in errors:
            print("-", error)
        return 1

    registry, _ = load_json(REGISTRY_PATH)
    counts = Counter(module["status"] for module in registry["modules"])
    print(
        "RVTT Greenfield module contract validation passed: "
        f"{len(registry['modules'])} modules; "
        + ", ".join(f"{status}={counts.get(status, 0)}" for status in sorted(VALID_STATUSES))
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
