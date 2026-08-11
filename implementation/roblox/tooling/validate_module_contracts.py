from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
REGISTRY_PATH = ROOT / "manifests/module-contracts.json"

VALID_KINDS = {
    "server_runtime",
    "command_registry",
    "transaction",
    "event_outbox",
    "domain",
    "projection",
    "persistence",
    "rules",
    "content_registry",
    "security_boundary",
    "client_runtime",
    "client_transport",
    "client_projection",
    "client_controller",
    "shared_contract",
}

VALID_AUTHORITIES = {
    "server_authoritative",
    "server_projection",
    "persistence_authority",
    "security_boundary",
    "client_intent_only",
    "client_projection_only",
    "client_local_state",
    "pure_contract",
    "no_authority",
}

MODULE_ID = re.compile(r"^[a-z0-9]+(?:[.-][a-z0-9]+)*$")
ENTRY_POINT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def load_registry() -> tuple[dict, list[str]]:
    errors: list[str] = []
    try:
        value = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        return {}, [f"{REGISTRY_PATH.relative_to(REPO_ROOT)}: {exc}"]
    if not isinstance(value, dict):
        errors.append("module contracts: registry root must be an object")
        return {}, errors
    return value, errors


def validate() -> list[str]:
    registry, errors = load_registry()
    if not registry:
        return errors

    if registry.get("schemaVersion") != 1:
        errors.append("module contracts: schemaVersion must be 1")
    if registry.get("registryId") != "rvtt-module-contracts-v1":
        errors.append("module contracts: unexpected registryId")
    if registry.get("authorityDocument") != "implementation/roblox/MODULE-CONTRACTS.md":
        errors.append("module contracts: authorityDocument drifted")
    if registry.get("internalCallGraphPolicy") != "source-derived":
        errors.append("module contracts: internalCallGraphPolicy must remain source-derived")

    modules = registry.get("modules")
    if not isinstance(modules, list) or not modules:
        errors.append("module contracts: modules must be a non-empty array")
        return errors

    ids: set[str] = set()
    paths: set[str] = set()
    modules_by_id: dict[str, dict] = {}

    required_fields = {
        "id",
        "path",
        "kind",
        "responsibility",
        "entryPoints",
        "dependsOn",
        "authority",
        "stateOwnership",
        "testRefs",
    }

    for index, module in enumerate(modules):
        if not isinstance(module, dict):
            errors.append(f"module contracts: modules[{index}] must be an object")
            continue
        module_id = module.get("id")
        path = module.get("path")
        missing = required_fields - set(module)
        if missing:
            errors.append(f"module contracts: {module_id or index} missing fields {sorted(missing)}")
            continue

        if not isinstance(module_id, str) or not MODULE_ID.fullmatch(module_id):
            errors.append(f"module contracts: invalid module id {module_id!r}")
            continue
        if module_id in ids:
            errors.append(f"module contracts: duplicate module id {module_id}")
        ids.add(module_id)
        modules_by_id[module_id] = module

        if not isinstance(path, str) or not path.startswith("src/") or not path.endswith(".lua"):
            errors.append(f"module contracts: {module_id} has invalid source path {path!r}")
        elif path in paths:
            errors.append(f"module contracts: duplicate source path {path}")
        else:
            paths.add(path)
            source_path = ROOT / path
            if not source_path.is_file():
                errors.append(f"module contracts: {module_id} source does not exist: {path}")
            else:
                source = source_path.read_text(encoding="utf-8")
                entry_points = module.get("entryPoints")
                if isinstance(entry_points, list):
                    for entry_point in entry_points:
                        if not isinstance(entry_point, str) or not ENTRY_POINT.fullmatch(entry_point):
                            errors.append(f"module contracts: {module_id} has invalid entry point {entry_point!r}")
                            continue
                        if re.search(rf"\b{re.escape(entry_point)}\b", source) is None:
                            errors.append(
                                f"module contracts: {module_id} stable entry point token disappeared: {entry_point}"
                            )

        kind = module.get("kind")
        if kind not in VALID_KINDS:
            errors.append(f"module contracts: {module_id} has unknown kind {kind!r}")
        authority = module.get("authority")
        if authority not in VALID_AUTHORITIES:
            errors.append(f"module contracts: {module_id} has unknown authority {authority!r}")
        responsibility = module.get("responsibility")
        if not isinstance(responsibility, str) or not responsibility.strip():
            errors.append(f"module contracts: {module_id} requires a responsibility")

        for field in ("entryPoints", "dependsOn", "stateOwnership", "testRefs"):
            value = module.get(field)
            if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
                errors.append(f"module contracts: {module_id}.{field} must be an array of strings")
        state_ownership = module.get("stateOwnership")
        if isinstance(state_ownership, list) and not state_ownership:
            errors.append(f"module contracts: {module_id}.stateOwnership must state what is owned or explicitly say none")

        test_refs = module.get("testRefs")
        if isinstance(test_refs, list):
            for test_ref in test_refs:
                if not test_ref.startswith("tests/"):
                    errors.append(f"module contracts: {module_id} test ref must be under tests/: {test_ref}")
                elif not (ROOT / test_ref).is_file():
                    errors.append(f"module contracts: {module_id} missing test ref {test_ref}")

    for module_id, module in modules_by_id.items():
        dependencies = module.get("dependsOn", [])
        if not isinstance(dependencies, list):
            continue
        seen_dependencies: set[str] = set()
        for dependency in dependencies:
            if dependency == module_id:
                errors.append(f"module contracts: {module_id} cannot depend on itself")
            if dependency in seen_dependencies:
                errors.append(f"module contracts: {module_id} duplicates dependency {dependency}")
            seen_dependencies.add(dependency)
            if dependency not in modules_by_id:
                errors.append(f"module contracts: {module_id} references unknown dependency {dependency}")

    coverage = registry.get("coverage")
    if not isinstance(coverage, dict):
        errors.append("module contracts: coverage must be an object")
        return errors

    required_globs = coverage.get("requiredGlobs")
    required_paths = coverage.get("requiredPaths")
    if not isinstance(required_globs, list) or not all(isinstance(item, str) for item in required_globs):
        errors.append("module contracts: coverage.requiredGlobs must be an array of strings")
        required_globs = []
    if not isinstance(required_paths, list) or not all(isinstance(item, str) for item in required_paths):
        errors.append("module contracts: coverage.requiredPaths must be an array of strings")
        required_paths = []

    required: set[str] = set()
    for pattern in required_globs:
        matches = sorted(path for path in ROOT.glob(pattern) if path.is_file())
        if not matches:
            errors.append(f"module contracts: coverage glob matched no files: {pattern}")
        for match in matches:
            required.add(match.relative_to(ROOT).as_posix())
    for path in required_paths:
        if not (ROOT / path).is_file():
            errors.append(f"module contracts: required coverage source does not exist: {path}")
        required.add(path)

    missing_coverage = sorted(required - paths)
    if missing_coverage:
        errors.append(f"module contracts: contract-bearing source is not registered: {missing_coverage}")

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("RVTT module contract validation failed:")
        for error in errors:
            print("-", error)
        return 1

    registry, _ = load_registry()
    coverage = registry["coverage"]
    print(
        "RVTT module contract validation passed: "
        f"{len(registry['modules'])} modules, "
        f"{len(coverage['requiredGlobs'])} required globs, "
        f"{len(coverage['requiredPaths'])} required paths"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
