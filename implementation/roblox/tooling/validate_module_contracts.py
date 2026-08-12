from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
REGISTRY_PATH = ROOT / "manifests/module-contracts.json"
FUNCTION_REGISTRY_PATH = ROOT / "manifests/system-function-contracts.json"
LEGACY_REGISTRY_PATH = ROOT / "manifests/legacy-module-contracts.json"

VALID_STATUSES = {"PLANNED", "IMPLEMENTED", "ACCEPTED", "DEPRECATED"}
VALID_CHECKPOINT_STATUSES = {"PLANNED", "IMPLEMENTING", "READY_FOR_USER", "ACCEPTED", "BLOCKED"}
VALID_KINDS = {
    "bootstrap", "app_composition", "shared_contract", "client_input", "client_transport",
    "client_projection", "client_system", "client_controller", "client_presenter", "server_runtime",
    "server_transport", "session_authority", "authorization", "state_store", "domain", "projection",
}
VALID_AUTHORITIES = {
    "server_authoritative", "server_projection", "client_intent_only", "client_projection_only",
    "client_local_state", "pure_contract", "no_authority",
}
VALID_FUNCTION_KINDS = {
    "CONSTRUCTOR", "LIFECYCLE", "VALIDATOR", "QUERY", "MUTATION", "AUTHORIZATION",
    "REGISTRATION", "COMMAND", "TRANSPORT", "SUBSCRIPTION", "PROJECTION",
}
VALID_IDEMPOTENCY = {
    "PURE", "READ_ONLY", "CONSTRUCTOR", "IDEMPOTENT", "REPEAT_SAFE", "NOT_IDEMPOTENT",
    "REGISTRATION", "LIFECYCLE",
}
VALID_SURFACES = {"CALLABLE_MODULE", "DATA_ONLY_MODULE", "AUTO_EXEC_SCRIPT"}
MODULE_ID = re.compile(r"^[a-z0-9]+(?:[.-][a-z0-9]+)*$")
FUNCTION_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
EXPECTED_SAFETY = {
    "failClosedServerAuthority": True,
    "clientInputIsUntrusted": True,
    "trustClientRoleClaims": False,
    "allowDirectUiRemoteCalls": False,
    "allowNetworkInstanceReferences": False,
    "requireBoundedNetworkPayloads": True,
    "requireCommandIds": True,
    "requireExpectedRevisionForMutation": True,
    "requireMonotonicProjectionRevision": True,
    "requireViewerSafeProjection": True,
    "allowGameplayLogicInBootstrap": False,
    "allowStudioOnlyProductionLogic": False,
    "allowPersistenceDuringFoundation": False,
    "requireLifecycleCleanup": True,
}
EXPECTED_FUNCTION_POLICY = {
    "declareSystemBeforeImplementation": True,
    "declareModuleBeforeImplementation": True,
    "declareStableCrossModuleFunctionsBeforeImplementation": True,
    "allowUndeclaredCrossModuleCalls": False,
    "privateHelpersAreSourceDerived": True,
    "manualPrivateCallGraph": False,
    "futureSystemsDetailedOnlyWhenApproachingImplementation": True,
}
FUNCTION_FIELDS = {
    "name", "kind", "purpose", "inputs", "output", "authority", "reads", "writes",
    "sideEffects", "failureModes", "idempotency", "validation", "permission", "revisionBehavior",
}
SYSTEM_FIELDS = {
    "id", "status", "stageOrCheckpoint", "responsibility", "modules", "authority", "stateOwners",
    "inputs", "outputs", "invariants", "flow",
}


def load_json(path: Path) -> tuple[dict, list[str]]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {}, [f"{path.relative_to(REPO_ROOT)}: {exc}"]
    if not isinstance(value, dict):
        return {}, [f"{path.relative_to(REPO_ROOT)}: root must be an object"]
    return value, []


def status_started(status: str) -> bool:
    return status in {"IMPLEMENTED", "ACCEPTED"}


def string_list(value: object, *, nonempty: bool = False) -> bool:
    return (
        isinstance(value, list)
        and (not nonempty or bool(value))
        and all(isinstance(item, str) and item.strip() for item in value)
    )


def validate() -> list[str]:
    registry, errors = load_json(REGISTRY_PATH)
    function_registry, function_errors = load_json(FUNCTION_REGISTRY_PATH)
    legacy, legacy_errors = load_json(LEGACY_REGISTRY_PATH)
    errors.extend(function_errors)
    errors.extend(legacy_errors)
    if not registry or not function_registry:
        return errors

    if legacy and legacy.get("schemaVersion") != 1:
        errors.append("module contracts: legacy registry must remain schemaVersion 1 historical reference")

    if registry.get("schemaVersion") != 3:
        errors.append("module contracts: schemaVersion must be 3")
    if registry.get("registryId") != "rvtt-greenfield-module-contracts-v3":
        errors.append("module contracts: unexpected registryId")
    if registry.get("authorityDocument") != "implementation/roblox/MODULE-CONTRACTS.md":
        errors.append("module contracts: authorityDocument drifted")
    if registry.get("sequenceAuthority") != "implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md":
        errors.append("module contracts: sequenceAuthority drifted")
    if registry.get("functionContractRegistry") != "implementation/roblox/manifests/system-function-contracts.json":
        errors.append("module contracts: functionContractRegistry drifted")
    if registry.get("buildMode") != "GREENFIELD_ARCHITECTURE_FIRST":
        errors.append("module contracts: buildMode must be GREENFIELD_ARCHITECTURE_FIRST")
    if registry.get("sourceRoot") != "greenfield/src":
        errors.append("module contracts: sourceRoot must be greenfield/src")
    if registry.get("legacyReferenceRegistry") != "implementation/roblox/manifests/legacy-module-contracts.json":
        errors.append("module contracts: legacyReferenceRegistry drifted")
    if registry.get("internalCallGraphPolicy") != "source-derived":
        errors.append("module contracts: internalCallGraphPolicy must remain source-derived")

    safety = registry.get("technicalSafety")
    if not isinstance(safety, dict):
        errors.append("module contracts: technicalSafety must be an object")
    else:
        for key, expected in EXPECTED_SAFETY.items():
            if safety.get(key) is not expected:
                errors.append(f"module contracts: technicalSafety.{key} must remain {expected}")
        unexpected = sorted(set(safety) - set(EXPECTED_SAFETY))
        if unexpected:
            errors.append(f"module contracts: unexpected technicalSafety keys {unexpected}")

    modules = registry.get("modules")
    if not isinstance(modules, list) or not modules:
        errors.append("module contracts: modules must be a non-empty array")
        return errors

    required_fields = {
        "id", "status", "plannedPath", "kind", "responsibility", "entryPoints", "dependsOn",
        "authority", "stateOwnership", "legacyCandidates", "testRefs",
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
        if module.get("kind") not in VALID_KINDS:
            errors.append(f"module contracts: {module_id} has invalid kind {module.get('kind')!r}")
        if module.get("authority") not in VALID_AUTHORITIES:
            errors.append(f"module contracts: {module_id} has invalid authority {module.get('authority')!r}")

        path = module.get("plannedPath")
        if not isinstance(path, str) or not path.startswith("greenfield/src/") or not path.endswith(".lua"):
            errors.append(f"module contracts: {module_id} has invalid plannedPath {path!r}")
        elif path in paths:
            errors.append(f"module contracts: duplicate plannedPath {path}")
        else:
            paths.add(path)

        if not isinstance(module.get("responsibility"), str) or not module["responsibility"].strip():
            errors.append(f"module contracts: {module_id} requires responsibility")
        for field in ("entryPoints", "dependsOn", "stateOwnership", "legacyCandidates", "testRefs"):
            if not isinstance(module.get(field), list) or not all(isinstance(item, str) for item in module[field]):
                errors.append(f"module contracts: {module_id}.{field} must be an array of strings")
        if isinstance(module.get("stateOwnership"), list) and not module["stateOwnership"]:
            errors.append(f"module contracts: {module_id}.stateOwnership must state ownership or 'none'")

        entry_points = module.get("entryPoints", [])
        if isinstance(entry_points, list):
            if len(entry_points) != len(set(entry_points)):
                errors.append(f"module contracts: {module_id} duplicates entryPoints")
            for entry_point in entry_points:
                if not isinstance(entry_point, str) or not FUNCTION_NAME.fullmatch(entry_point):
                    errors.append(f"module contracts: {module_id} has invalid entry point {entry_point!r}")

        if status in {"IMPLEMENTED", "ACCEPTED"} and isinstance(path, str):
            source_path = ROOT / path
            if not source_path.is_file():
                errors.append(f"module contracts: {module_id} is {status} but source is missing: {path}")
            else:
                source = source_path.read_text(encoding="utf-8")
                for entry_point in entry_points if isinstance(entry_points, list) else []:
                    if re.search(rf"\b{re.escape(entry_point)}\b", source) is None:
                        errors.append(f"module contracts: {module_id} stable entry point token disappeared: {entry_point}")

        test_refs = module.get("testRefs", [])
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

    # Function/system registry is the stable meaning authority for Module.entryPoints.
    if function_registry.get("schemaVersion") != 1:
        errors.append("system/function contracts: schemaVersion must be 1")
    if function_registry.get("registryId") != "rvtt-greenfield-system-function-contracts-v1":
        errors.append("system/function contracts: unexpected registryId")
    if function_registry.get("moduleRegistry") != "implementation/roblox/manifests/module-contracts.json":
        errors.append("system/function contracts: moduleRegistry drifted")
    if function_registry.get("authorityDocument") != "implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md":
        errors.append("system/function contracts: authorityDocument drifted")
    if function_registry.get("scope") != "CURRENT_GREENFIELD_FOUNDATION_PLUS_EXPLORATION":
        errors.append("system/function contracts: scope drifted")
    policy = function_registry.get("policy")
    if not isinstance(policy, dict):
        errors.append("system/function contracts: policy must be an object")
    else:
        for key, expected in EXPECTED_FUNCTION_POLICY.items():
            if policy.get(key) is not expected:
                errors.append(f"system/function contracts: policy.{key} must remain {expected}")
        unexpected = sorted(set(policy) - set(EXPECTED_FUNCTION_POLICY))
        if unexpected:
            errors.append(f"system/function contracts: unexpected policy keys {unexpected}")

    systems = function_registry.get("systemContracts")
    module_system_coverage: set[str] = set()
    if not isinstance(systems, list) or not systems:
        errors.append("system/function contracts: systemContracts must be a non-empty array")
    else:
        system_ids: set[str] = set()
        for index, system in enumerate(systems):
            if not isinstance(system, dict):
                errors.append(f"system/function contracts: systemContracts[{index}] must be an object")
                continue
            missing = SYSTEM_FIELDS - set(system)
            system_id = system.get("id")
            if missing:
                errors.append(f"system/function contracts: {system_id or index} missing fields {sorted(missing)}")
                continue
            if not isinstance(system_id, str) or not MODULE_ID.fullmatch(system_id):
                errors.append(f"system/function contracts: invalid system id {system_id!r}")
                continue
            if system_id in system_ids:
                errors.append(f"system/function contracts: duplicate system id {system_id}")
            system_ids.add(system_id)
            if system.get("status") not in VALID_STATUSES:
                errors.append(f"system/function contracts: {system_id} invalid status {system.get('status')!r}")
            if system.get("authority") not in VALID_AUTHORITIES:
                errors.append(f"system/function contracts: {system_id} invalid authority {system.get('authority')!r}")
            if not isinstance(system.get("stageOrCheckpoint"), str) or not system["stageOrCheckpoint"].strip():
                errors.append(f"system/function contracts: {system_id}.stageOrCheckpoint must be non-empty")
            if not isinstance(system.get("responsibility"), str) or not system["responsibility"].strip():
                errors.append(f"system/function contracts: {system_id}.responsibility must be non-empty")
            for field in ("modules", "stateOwners", "inputs", "outputs", "invariants", "flow"):
                if not string_list(system.get(field), nonempty=True):
                    errors.append(f"system/function contracts: {system_id}.{field} must be a non-empty string array")
            module_refs = system.get("modules", []) if isinstance(system.get("modules"), list) else []
            for module_id in module_refs:
                if module_id not in by_id:
                    errors.append(f"system/function contracts: {system_id} references unknown module {module_id}")
                else:
                    module_system_coverage.add(module_id)
            flow = system.get("flow", []) if isinstance(system.get("flow"), list) else []
            for module_id in flow:
                if module_id not in by_id:
                    errors.append(f"system/function contracts: {system_id}.flow references unknown module {module_id}")
                elif module_id not in module_refs:
                    errors.append(f"system/function contracts: {system_id}.flow module not declared in system.modules: {module_id}")

    uncovered = sorted(set(by_id) - module_system_coverage)
    if uncovered:
        errors.append(f"system/function contracts: modules missing system coverage: {uncovered}")

    function_records = function_registry.get("moduleFunctionContracts")
    function_by_module: dict[str, dict] = {}
    if not isinstance(function_records, list) or not function_records:
        errors.append("system/function contracts: moduleFunctionContracts must be a non-empty array")
    else:
        for index, record in enumerate(function_records):
            if not isinstance(record, dict):
                errors.append(f"system/function contracts: moduleFunctionContracts[{index}] must be an object")
                continue
            module_id = record.get("moduleId")
            if not isinstance(module_id, str) or module_id not in by_id:
                errors.append(f"system/function contracts: unknown module function record {module_id!r}")
                continue
            if module_id in function_by_module:
                errors.append(f"system/function contracts: duplicate module function record {module_id}")
            function_by_module[module_id] = record
            surface = record.get("surface")
            if surface not in VALID_SURFACES:
                errors.append(f"system/function contracts: {module_id} invalid surface {surface!r}")
            functions = record.get("functions")
            if not isinstance(functions, list):
                errors.append(f"system/function contracts: {module_id}.functions must be an array")
                continue
            if surface == "CALLABLE_MODULE" and not functions:
                errors.append(f"system/function contracts: callable module {module_id} must declare functions")
            if surface in {"DATA_ONLY_MODULE", "AUTO_EXEC_SCRIPT"} and functions:
                errors.append(f"system/function contracts: {surface} {module_id} must not declare callable functions")
            if surface == "AUTO_EXEC_SCRIPT":
                if not isinstance(record.get("scriptEntrypoint"), str) or not record["scriptEntrypoint"].strip():
                    errors.append(f"system/function contracts: auto-exec module {module_id} requires scriptEntrypoint")

            names: list[str] = []
            for function in functions:
                if not isinstance(function, dict):
                    errors.append(f"system/function contracts: {module_id} function must be an object")
                    continue
                missing = FUNCTION_FIELDS - set(function)
                name = function.get("name")
                if missing:
                    errors.append(f"system/function contracts: {module_id}.{name or '?'} missing fields {sorted(missing)}")
                    continue
                if not isinstance(name, str) or not FUNCTION_NAME.fullmatch(name):
                    errors.append(f"system/function contracts: {module_id} invalid function name {name!r}")
                    continue
                if name in names:
                    errors.append(f"system/function contracts: {module_id} duplicate function {name}")
                names.append(name)
                if function.get("kind") not in VALID_FUNCTION_KINDS:
                    errors.append(f"system/function contracts: {module_id}.{name} invalid kind {function.get('kind')!r}")
                if function.get("authority") not in VALID_AUTHORITIES:
                    errors.append(f"system/function contracts: {module_id}.{name} invalid authority {function.get('authority')!r}")
                elif function.get("authority") != by_id[module_id].get("authority"):
                    errors.append(
                        f"system/function contracts: {module_id}.{name} authority must equal module authority "
                        f"{by_id[module_id].get('authority')!r}"
                    )
                if function.get("idempotency") not in VALID_IDEMPOTENCY:
                    errors.append(f"system/function contracts: {module_id}.{name} invalid idempotency {function.get('idempotency')!r}")
                for field in ("inputs", "reads", "writes", "sideEffects", "failureModes", "validation"):
                    if not isinstance(function.get(field), list) or not all(isinstance(item, str) and item.strip() for item in function[field]):
                        errors.append(f"system/function contracts: {module_id}.{name}.{field} must be a string array")
                for field in ("purpose", "output", "permission", "revisionBehavior"):
                    if not isinstance(function.get(field), str) or not function[field].strip():
                        errors.append(f"system/function contracts: {module_id}.{name}.{field} must be non-empty")

            entry_points = by_id[module_id].get("entryPoints", [])
            if isinstance(entry_points, list) and names != entry_points:
                errors.append(
                    f"system/function contracts: {module_id} function names must exactly match entryPoints; "
                    f"functions={names} entryPoints={entry_points}"
                )

    missing_function_records = sorted(set(by_id) - set(function_by_module))
    extra_function_records = sorted(set(function_by_module) - set(by_id))
    if missing_function_records:
        errors.append(f"system/function contracts: modules missing function records: {missing_function_records}")
    if extra_function_records:
        errors.append(f"system/function contracts: unknown extra function records: {extra_function_records}")

    # Existing fixed foundation order and dependency gates.
    stages = registry.get("systemStages")
    stage_module_order: dict[str, int] = {}
    ordered_stages: list[tuple[int, str, list[str]]] = []
    if not isinstance(stages, list) or not stages:
        errors.append("module contracts: systemStages must be a non-empty array")
    else:
        stage_ids: set[str] = set()
        stage_orders: set[int] = set()
        for stage in stages:
            if not isinstance(stage, dict):
                errors.append("module contracts: system stage must be an object")
                continue
            stage_id = stage.get("id")
            order = stage.get("order")
            required = stage.get("modulesRequired")
            gate = stage.get("gate")
            if not isinstance(stage_id, str) or not stage_id:
                errors.append("module contracts: system stage requires id")
                continue
            if stage_id in stage_ids:
                errors.append(f"module contracts: duplicate system stage {stage_id}")
            stage_ids.add(stage_id)
            if not isinstance(order, int) or order < 0:
                errors.append(f"module contracts: {stage_id}.order must be a non-negative integer")
                continue
            if order in stage_orders:
                errors.append(f"module contracts: duplicate system stage order {order}")
            stage_orders.add(order)
            if not isinstance(required, list) or not required or not all(isinstance(item, str) for item in required):
                errors.append(f"module contracts: {stage_id}.modulesRequired must be a non-empty array")
                continue
            if not string_list(gate, nonempty=True):
                errors.append(f"module contracts: {stage_id}.gate must be a non-empty string array")
            for module_id in required:
                if module_id not in by_id:
                    errors.append(f"module contracts: {stage_id} references unknown module {module_id}")
                    continue
                if module_id in stage_module_order:
                    errors.append(f"module contracts: foundation module appears in more than one stage: {module_id}")
                stage_module_order[module_id] = order
            ordered_stages.append((order, stage_id, required))
        if stage_orders and sorted(stage_orders) != list(range(len(stage_orders))):
            errors.append("module contracts: system stage orders must be contiguous starting at 0")

    foundation_required = registry.get("foundationRequired")
    if not isinstance(foundation_required, list) or not all(isinstance(item, str) for item in foundation_required):
        errors.append("module contracts: foundationRequired must be an array of module ids")
        foundation_required = []
    if set(foundation_required) != set(stage_module_order):
        missing = sorted(set(stage_module_order) - set(foundation_required))
        extra = sorted(set(foundation_required) - set(stage_module_order))
        errors.append(f"module contracts: foundationRequired must equal system stage module union; missing={missing} extra={extra}")

    for module_id, stage_order in stage_module_order.items():
        module = by_id.get(module_id)
        if not module:
            continue
        for dependency in module.get("dependsOn", []):
            if dependency not in stage_module_order:
                errors.append(f"module contracts: foundation module {module_id} depends on non-foundation module {dependency}")
            elif stage_module_order[dependency] > stage_order:
                errors.append(f"module contracts: foundation dependency points forward: {module_id} -> {dependency}")

    for order, stage_id, required in sorted(ordered_stages):
        if any(status_started(by_id[module_id].get("status")) for module_id in required if module_id in by_id):
            prior = [
                module_id
                for prior_order, _, prior_required in ordered_stages
                if prior_order < order
                for module_id in prior_required
            ]
            incomplete = [
                module_id for module_id in prior
                if module_id in by_id and not status_started(by_id[module_id].get("status"))
            ]
            if incomplete:
                errors.append(f"module contracts: {stage_id} started before prior stages completed: {incomplete}")

    checkpoints = registry.get("deliveryCheckpoints")
    checkpoint_by_id: dict[str, dict] = {}
    if not isinstance(checkpoints, list) or not checkpoints:
        errors.append("module contracts: deliveryCheckpoints must be a non-empty array")
    else:
        orders: set[int] = set()
        for checkpoint in checkpoints:
            if not isinstance(checkpoint, dict):
                errors.append("module contracts: checkpoint must be an object")
                continue
            checkpoint_id = checkpoint.get("id")
            order = checkpoint.get("order")
            status = checkpoint.get("status")
            previous = checkpoint.get("previousCheckpoint")
            required = checkpoint.get("modulesRequired")
            if not isinstance(checkpoint_id, str) or not checkpoint_id:
                errors.append("module contracts: checkpoint requires id")
                continue
            if checkpoint_id in checkpoint_by_id:
                errors.append(f"module contracts: duplicate checkpoint {checkpoint_id}")
            checkpoint_by_id[checkpoint_id] = checkpoint
            if not isinstance(order, int) or order < 1:
                errors.append(f"module contracts: {checkpoint_id}.order must be a positive integer")
            elif order in orders:
                errors.append(f"module contracts: duplicate checkpoint order {order}")
            else:
                orders.add(order)
            if status not in VALID_CHECKPOINT_STATUSES:
                errors.append(f"module contracts: {checkpoint_id} has invalid checkpoint status {status!r}")
            if previous is not None and not isinstance(previous, str):
                errors.append(f"module contracts: {checkpoint_id}.previousCheckpoint must be string or null")
            if checkpoint.get("requiresUserAcceptance") is not True:
                errors.append(f"module contracts: {checkpoint_id} must require user acceptance")
            if not isinstance(required, list) or not required or not all(isinstance(item, str) for item in required):
                errors.append(f"module contracts: {checkpoint_id}.modulesRequired must be a non-empty array")
                continue
            for module_id in required:
                if module_id not in by_id:
                    errors.append(f"module contracts: {checkpoint_id} references unknown module {module_id}")
        if orders and sorted(orders) != list(range(1, len(orders) + 1)):
            errors.append("module contracts: checkpoint orders must be contiguous starting at 1")

        ordered_checkpoints = sorted(
            (cp for cp in checkpoint_by_id.values() if isinstance(cp.get("order"), int)),
            key=lambda cp: cp["order"],
        )
        for index, checkpoint in enumerate(ordered_checkpoints):
            checkpoint_id = checkpoint["id"]
            expected_previous = None if index == 0 else ordered_checkpoints[index - 1]["id"]
            if checkpoint.get("previousCheckpoint") != expected_previous:
                errors.append(f"module contracts: {checkpoint_id}.previousCheckpoint must be {expected_previous!r}")
            status = checkpoint.get("status")
            if status in {"IMPLEMENTING", "READY_FOR_USER", "ACCEPTED"}:
                incomplete_foundation = [
                    module_id for module_id in foundation_required
                    if module_id in by_id and not status_started(by_id[module_id].get("status"))
                ]
                if incomplete_foundation:
                    errors.append(f"module contracts: {checkpoint_id} started before foundation completed: {incomplete_foundation}")
                if expected_previous is not None and checkpoint_by_id.get(expected_previous, {}).get("status") != "ACCEPTED":
                    errors.append(f"module contracts: {checkpoint_id} started before {expected_previous} was ACCEPTED")
            if status in {"READY_FOR_USER", "ACCEPTED"}:
                incomplete_modules = [
                    module_id for module_id in checkpoint.get("modulesRequired", [])
                    if module_id in by_id and not status_started(by_id[module_id].get("status"))
                ]
                if incomplete_modules:
                    errors.append(f"module contracts: {checkpoint_id} is {status} but modules are not implemented: {incomplete_modules}")
            if status == "ACCEPTED":
                not_accepted = [
                    module_id for module_id in checkpoint.get("modulesRequired", [])
                    if module_id in by_id and by_id[module_id].get("status") != "ACCEPTED"
                ]
                if not_accepted:
                    errors.append(f"module contracts: {checkpoint_id} is ACCEPTED but modules are not ACCEPTED: {not_accepted}")

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("RVTT Greenfield module/system/function contract validation failed:")
        for error in errors:
            print("-", error)
        return 1

    registry, _ = load_json(REGISTRY_PATH)
    function_registry, _ = load_json(FUNCTION_REGISTRY_PATH)
    counts = Counter(module["status"] for module in registry["modules"])
    checkpoint_counts = Counter(cp["status"] for cp in registry["deliveryCheckpoints"])
    function_count = sum(len(record.get("functions", [])) for record in function_registry["moduleFunctionContracts"])
    print(
        "RVTT Greenfield module/system/function contract validation passed: "
        f"{len(registry['modules'])} modules; {len(function_registry['systemContracts'])} systems; "
        f"{function_count} stable functions; "
        + ", ".join(f"{status}={counts.get(status, 0)}" for status in sorted(VALID_STATUSES))
        + "; checkpoints "
        + ", ".join(f"{status}={checkpoint_counts.get(status, 0)}" for status in sorted(VALID_CHECKPOINT_STATUSES))
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
