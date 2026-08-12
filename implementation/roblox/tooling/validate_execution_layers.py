from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
MODULES_PATH = ROOT / "manifests/module-contracts.json"
EXECUTION_PATH = ROOT / "manifests/execution-layers.json"

VALID_CLASSES = {
    "CORE_ENGINE",
    "ROBLOX_RUNTIME_ENGINE",
    "ROBLOX_INTEGRATION",
    "PRESENTATION_FEEL",
}
STARTED = {"IMPLEMENTED", "ACCEPTED"}


def load_json(path: Path) -> tuple[dict, list[str]]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {}, [f"{path.relative_to(REPO_ROOT)}: {exc}"]
    if not isinstance(value, dict):
        return {}, [f"{path.relative_to(REPO_ROOT)}: root must be an object"]
    return value, []


def validate() -> list[str]:
    module_registry, errors = load_json(MODULES_PATH)
    execution, exec_errors = load_json(EXECUTION_PATH)
    errors.extend(exec_errors)
    if not module_registry or not execution:
        return errors

    if execution.get("schemaVersion") != 1:
        errors.append("execution layers: schemaVersion must be 1")
    if execution.get("registryId") != "rvtt-greenfield-execution-layers-v1":
        errors.append("execution layers: unexpected registryId")
    if execution.get("authorityDocument") != "implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md":
        errors.append("execution layers: authorityDocument drifted")
    if execution.get("moduleRegistry") != "implementation/roblox/manifests/module-contracts.json":
        errors.append("execution layers: moduleRegistry drifted")
    if execution.get("canonicalSourceRoot") != "greenfield/src":
        errors.append("execution layers: canonicalSourceRoot must be greenfield/src")
    if execution.get("canonicalTestRoot") != "greenfield/tests":
        errors.append("execution layers: canonicalTestRoot must be greenfield/tests")

    policy = execution.get("policy")
    required_policy = {
        "canonicalSourceAlwaysGitHub": True,
        "coreEngineRepositoryFirst": True,
        "studioIsRuntimeIntegrationWorkbench": True,
        "humanReviewIsForPresentationAndFeel": True,
        "runtimeCoupledStudioAuthoringAllowed": True,
        "runtimeCoupledMustCanonicalizeToGitHub": True,
        "doNotHumanTestPureEngineFunctions": True,
    }
    if not isinstance(policy, dict):
        errors.append("execution layers: policy must be an object")
    else:
        for key, expected in required_policy.items():
            if policy.get(key) is not expected:
                errors.append(f"execution layers: policy.{key} must remain {expected}")

    class_defs = execution.get("executionClasses")
    if not isinstance(class_defs, dict):
        errors.append("execution layers: executionClasses must be an object")
    else:
        if set(class_defs) != VALID_CLASSES:
            errors.append(
                f"execution layers: executionClasses must be exactly {sorted(VALID_CLASSES)}"
            )
        for class_id, spec in class_defs.items():
            if not isinstance(spec, dict):
                errors.append(f"execution layers: {class_id} definition must be an object")
                continue
            if not isinstance(spec.get("authoring"), str) or not spec["authoring"].strip():
                errors.append(f"execution layers: {class_id}.authoring is required")
            verification = spec.get("verification")
            if not isinstance(verification, list) or not verification or not all(
                isinstance(item, str) and item.strip() for item in verification
            ):
                errors.append(f"execution layers: {class_id}.verification must be a non-empty string array")
            if not isinstance(spec.get("humanReview"), bool):
                errors.append(f"execution layers: {class_id}.humanReview must be boolean")

    runtime_rule = execution.get("runtimeCoupledRule")
    if not isinstance(runtime_rule, dict):
        errors.append("execution layers: runtimeCoupledRule must be an object")
    else:
        if runtime_rule.get("class") != "ROBLOX_RUNTIME_ENGINE":
            errors.append("execution layers: runtimeCoupledRule.class must be ROBLOX_RUNTIME_ENGINE")
        if runtime_rule.get("canonicalSource") != "GITHUB":
            errors.append("execution layers: runtime-coupled canonical source must remain GITHUB")
        for key in (
            "studioAuthoringAllowed",
            "studioAutomatedVerificationRequired",
            "humanAcceptanceRequiredOnlyForVisibleFeel",
        ):
            if runtime_rule.get(key) is not True:
                errors.append(f"execution layers: runtimeCoupledRule.{key} must remain true")
        example = runtime_rule.get("pathfindingExample")
        if not isinstance(example, dict):
            errors.append("execution layers: pathfindingExample is required")
        else:
            for key in ("repositorySide", "studioSide", "humanSide"):
                value = example.get(key)
                if not isinstance(value, list) or not value or not all(isinstance(item, str) for item in value):
                    errors.append(f"execution layers: pathfindingExample.{key} must be a non-empty string array")

    modules = module_registry.get("modules")
    if not isinstance(modules, list) or not modules:
        errors.append("execution layers: module registry has no modules")
        return errors
    by_id = {
        module.get("id"): module
        for module in modules
        if isinstance(module, dict) and isinstance(module.get("id"), str)
    }

    mappings = execution.get("moduleExecution")
    if not isinstance(mappings, list):
        errors.append("execution layers: moduleExecution must be an array")
        mappings = []

    class_by_module: dict[str, str] = {}
    for mapping in mappings:
        if not isinstance(mapping, dict):
            errors.append("execution layers: moduleExecution entry must be an object")
            continue
        module_id = mapping.get("moduleId")
        class_id = mapping.get("class")
        if not isinstance(module_id, str) or not module_id:
            errors.append("execution layers: moduleExecution.moduleId is required")
            continue
        if module_id in class_by_module:
            errors.append(f"execution layers: duplicate module classification {module_id}")
            continue
        if class_id not in VALID_CLASSES:
            errors.append(f"execution layers: {module_id} has invalid class {class_id!r}")
        class_by_module[module_id] = class_id

    module_ids = set(by_id)
    classified = set(class_by_module)
    missing = sorted(module_ids - classified)
    extra = sorted(classified - module_ids)
    if missing or extra:
        errors.append(
            f"execution layers: module coverage must be exact; missing={missing} extra={extra}"
        )

    phases = execution.get("phases")
    phase_modules: set[str] = set()
    if not isinstance(phases, list) or not phases:
        errors.append("execution layers: phases must be a non-empty array")
        phases = []
    orders: set[int] = set()
    phase_by_id: dict[str, dict] = {}
    for phase in phases:
        if not isinstance(phase, dict):
            errors.append("execution layers: phase must be an object")
            continue
        phase_id = phase.get("id")
        order = phase.get("order")
        modules_required = phase.get("modules")
        gate = phase.get("gate")
        if not isinstance(phase_id, str) or not phase_id:
            errors.append("execution layers: phase id is required")
            continue
        if phase_id in phase_by_id:
            errors.append(f"execution layers: duplicate phase {phase_id}")
        phase_by_id[phase_id] = phase
        if not isinstance(order, int) or order < 0:
            errors.append(f"execution layers: {phase_id}.order must be a non-negative integer")
        elif order in orders:
            errors.append(f"execution layers: duplicate phase order {order}")
        else:
            orders.add(order)
        if not isinstance(modules_required, list) or not all(isinstance(item, str) for item in modules_required):
            errors.append(f"execution layers: {phase_id}.modules must be a string array")
            continue
        if not isinstance(gate, list) or not gate or not all(isinstance(item, str) and item.strip() for item in gate):
            errors.append(f"execution layers: {phase_id}.gate must be a non-empty string array")
        for module_id in modules_required:
            if module_id not in by_id:
                errors.append(f"execution layers: {phase_id} references unknown module {module_id}")
            if module_id in phase_modules:
                errors.append(f"execution layers: module appears in multiple phases: {module_id}")
            phase_modules.add(module_id)

    if orders and sorted(orders) != list(range(len(orders))):
        errors.append("execution layers: phase orders must be contiguous starting at 0")
    if phase_modules != module_ids:
        errors.append(
            "execution layers: phase module union must cover every current module exactly once"
        )

    expected_phase_classes = {
        "E0_REPOSITORY_CORE_ENGINE": {"CORE_ENGINE"},
        "E1_ROBLOX_RUNTIME_INTEGRATION": {"ROBLOX_RUNTIME_ENGINE", "ROBLOX_INTEGRATION"},
        "E2_PRESENTATION_AND_FEEL": {"PRESENTATION_FEEL"},
    }
    if set(phase_by_id) != set(expected_phase_classes):
        errors.append(
            f"execution layers: phases must be exactly {sorted(expected_phase_classes)}"
        )
    for phase_id, allowed_classes in expected_phase_classes.items():
        phase = phase_by_id.get(phase_id)
        if not phase:
            continue
        for module_id in phase.get("modules", []):
            class_id = class_by_module.get(module_id)
            if class_id not in allowed_classes:
                errors.append(
                    f"execution layers: {module_id} class {class_id} cannot be in {phase_id}"
                )

    checkpoints = module_registry.get("deliveryCheckpoints")
    expected_checkpoints = execution.get("checkpointOrder")
    if not isinstance(checkpoints, list) or not isinstance(expected_checkpoints, list):
        errors.append("execution layers: checkpoint data is missing")
    else:
        actual_order = [cp.get("id") for cp in sorted(
            (cp for cp in checkpoints if isinstance(cp, dict) and isinstance(cp.get("order"), int)),
            key=lambda cp: cp["order"],
        )]
        if actual_order != expected_checkpoints:
            errors.append(
                f"execution layers: checkpoint order drifted: registry={actual_order} execution={expected_checkpoints}"
            )

    core_modules = [mid for mid, cls in class_by_module.items() if cls == "CORE_ENGINE"]
    integration_modules = [
        mid for mid, cls in class_by_module.items()
        if cls in {"ROBLOX_RUNTIME_ENGINE", "ROBLOX_INTEGRATION"}
    ]
    presentation_modules = [mid for mid, cls in class_by_module.items() if cls == "PRESENTATION_FEEL"]

    def started(module_id: str) -> bool:
        return by_id.get(module_id, {}).get("status") in STARTED

    if any(started(mid) for mid in integration_modules):
        incomplete = [mid for mid in core_modules if not started(mid)]
        if incomplete:
            errors.append(
                f"execution layers: Roblox integration started before core engine completed: {incomplete}"
            )

    if any(started(mid) for mid in presentation_modules):
        incomplete = [mid for mid in core_modules + integration_modules if not started(mid)]
        if incomplete:
            errors.append(
                f"execution layers: presentation started before engine/integration completed: {incomplete}"
            )

    for module_id, class_id in class_by_module.items():
        module = by_id.get(module_id, {})
        status = module.get("status")
        test_refs = module.get("testRefs")
        if status not in STARTED:
            continue
        if not isinstance(test_refs, list):
            continue
        if class_id == "CORE_ENGINE" and not test_refs:
            errors.append(
                f"execution layers: CORE_ENGINE module {module_id} is {status} but has no repository testRefs"
            )
        if class_id in {"ROBLOX_RUNTIME_ENGINE", "ROBLOX_INTEGRATION"}:
            if not any(
                isinstance(ref, str) and ref.startswith("greenfield/tests/studio/")
                for ref in test_refs
            ):
                errors.append(
                    f"execution layers: {class_id} module {module_id} is {status} but has no greenfield/tests/studio/ verification"
                )

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("RVTT Greenfield execution layer validation failed:")
        for error in errors:
            print("-", error)
        return 1

    execution, _ = load_json(EXECUTION_PATH)
    counts = Counter(item["class"] for item in execution["moduleExecution"])
    print(
        "RVTT Greenfield execution layer validation passed: "
        + ", ".join(f"{class_id}={counts.get(class_id, 0)}" for class_id in sorted(VALID_CLASSES))
        + f"; phases={len(execution['phases'])}; checkpoints={len(execution['checkpointOrder'])}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
