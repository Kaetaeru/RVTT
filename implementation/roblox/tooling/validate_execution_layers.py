from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
MODULES_PATH = ROOT / "manifests/module-contracts.json"
EXECUTION_PATH = ROOT / "manifests/execution-layers.json"
COVERAGE_PATH = ROOT / "manifests/architecture-coverage.json"

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
    coverage, coverage_errors = load_json(COVERAGE_PATH)
    errors.extend(exec_errors)
    errors.extend(coverage_errors)
    if not module_registry or not execution or not coverage:
        return errors

    if execution.get("schemaVersion") != 1:
        errors.append("execution layers: schemaVersion must be 1")
    if execution.get("registryId") != "rvtt-greenfield-execution-layers-v1":
        errors.append("execution layers: unexpected registryId")
    if execution.get("authorityDocument") != "implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md":
        errors.append("execution layers: authorityDocument drifted")
    if execution.get("architectureCoverageAuthority") != "implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md":
        errors.append("execution layers: architectureCoverageAuthority drifted")
    if execution.get("architectureCoverageRegistry") != "implementation/roblox/manifests/architecture-coverage.json":
        errors.append("execution layers: architectureCoverageRegistry drifted")
    if execution.get("moduleRegistry") != "implementation/roblox/manifests/module-contracts.json":
        errors.append("execution layers: moduleRegistry drifted")
    if execution.get("canonicalSourceRoot") != "greenfield/src":
        errors.append("execution layers: canonicalSourceRoot must be greenfield/src")
    if execution.get("canonicalTestRoot") != "greenfield/tests":
        errors.append("execution layers: canonicalTestRoot must be greenfield/tests")

    policy = execution.get("policy")
    required_policy = {
        "requireCoverageGateBeforePhase": True,
        "canonicalSourceAlwaysGitHub": True,
        "coreEngineRepositoryFirst": True,
        "studioExecutionRequiresCoreEngineComplete": True,
        "runtimeCoupledRunsOnlyAfterCoreEngineComplete": True,
        "studioIsRuntimeIntegrationWorkbench": True,
        "humanReviewIsForPresentationAndFeel": True,
        "runtimeCoupledStudioAuthoringAllowed": True,
        "runtimeCoupledMustCanonicalizeToGitHub": True,
        "doNotHumanTestPureEngineFunctions": True,
        "futureCompatibilityReviewRequiredAtCheckpointFreeze": True,
        "futureCapabilitiesConstrainArchitectureWithoutExpandingScope": True,
        "futureScenarioPressureSetRequired": True,
        "extensionSeamsRequired": True,
        "forbiddenShortcutsRequired": True,
    }
    if not isinstance(policy, dict):
        errors.append("execution layers: policy must be an object")
    else:
        for key, expected in required_policy.items():
            if policy.get(key) is not expected:
                errors.append(f"execution layers: policy.{key} must remain {expected}")

    expected_concretization = {
        "E0_REPOSITORY_CORE_ENGINE": "AFTER_COVERAGE_AND_SYSTEM_BOUNDARY_FREEZE_BEFORE_SOURCE",
        "E1_ROBLOX_RUNTIME_INTEGRATION": "AFTER_CORE_ENGINE_COMPLETE_BEFORE_STUDIO",
        "E2_PRESENTATION_AND_FEEL": "AFTER_INTEGRATION_READY_JIT_ONE_USER_CHECKPOINT_AT_A_TIME",
    }
    concretization = execution.get("checkpointConcretization")
    if concretization != expected_concretization:
        errors.append(
            "execution layers: checkpointConcretization must preserve E0-before-source, "
            "E1-after-core-before-Studio, and E2-JIT-after-integration timing"
        )

    spec_requirements = execution.get("implementationSpecRequirements")
    expected_scenario_sources = [
        "implementation/roblox/manifests/architecture-coverage.json",
        "implementation/roblox/manifests/architecture-scenarios.json",
    ]
    required_checkpoint_fields = {
        "currentDeliverable",
        "systemModuleScope",
        "stableFunctionScope",
        "authorityStateOwnership",
        "inputOutputContract",
        "currentScenarioWorkingSet",
        "futureConsumers",
        "futureScenarioPressureSet",
        "extensionSeams",
        "stableOwnershipAndIdentitySeams",
        "persistenceReconnectRollbackSeams",
        "observabilityFailureSeams",
        "forbiddenShortcuts",
        "explicitDeferredNonGoals",
        "automatedTests",
        "futureCompatibilityContractTests",
        "completionCondition",
    }
    if not isinstance(spec_requirements, dict):
        errors.append("execution layers: implementationSpecRequirements is required")
    else:
        if spec_requirements.get("scenarioSources") != expected_scenario_sources:
            errors.append("execution layers: implementation spec must derive pressure from base and expanded scenario registries")
        if spec_requirements.get("futureCapabilitiesAre") != "COMPATIBILITY_CONSTRAINTS_NOT_CURRENT_IMPLEMENTATION_SCOPE":
            errors.append("execution layers: future capabilities must constrain architecture without expanding current source scope")
        required_fields = spec_requirements.get("requiredAtCheckpointFreeze")
        if not isinstance(required_fields, list) or set(required_fields) != required_checkpoint_fields:
            errors.append(
                "execution layers: requiredAtCheckpointFreeze must include current scope plus future consumers, "
                "scenario pressure, extension seams, forbidden shortcuts, deferred non-goals and compatibility tests"
            )
        freeze_rejected = spec_requirements.get("freezeRejectedWhen")
        if not isinstance(freeze_rejected, list) or len(freeze_rejected) < 5 or not all(
            isinstance(item, str) and item.strip() for item in freeze_rejected
        ):
            errors.append("execution layers: freezeRejectedWhen must define future-compatibility failure conditions")
        if spec_requirements.get("implementationEscalation") != "ESCALATE_TO_PLANNING_ON_UNMODELED_FUTURE_CONFLICT":
            errors.append("execution layers: unmodeled future conflict must escalate to planning")

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
        if runtime_rule.get("coverageRequiredFirst") is not True:
            errors.append("execution layers: runtimeCoupledRule.coverageRequiredFirst must remain true")
        if runtime_rule.get("coreEngineCompleteRequiredBeforeStudio") is not True:
            errors.append(
                "execution layers: runtimeCoupledRule.coreEngineCompleteRequiredBeforeStudio must remain true"
            )
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

    coverage_phase_gates = {}
    for gate in coverage.get("phaseGates", []):
        if isinstance(gate, dict) and isinstance(gate.get("phase"), str):
            coverage_phase_gates[gate["phase"]] = gate

    open_gaps = {
        gap.get("id")
        for gap in coverage.get("knownGaps", [])
        if isinstance(gap, dict) and gap.get("status") == "OPEN"
    }

    phases = execution.get("phases")
    phase_modules: set[str] = set()
    if not isinstance(phases, list) or not phases:
        errors.append("execution layers: phases must be a non-empty array")
        phases = []
    orders: set[int] = set()
    phase_by_id: dict[str, dict] = {}
    expected_phase_runtime = {
        "E0_REPOSITORY_CORE_ENGINE": {
            "checkpointFreeze": "REQUIRED_BEFORE_FIRST_SOURCE",
            "studioAllowed": False,
        },
        "E1_ROBLOX_RUNTIME_INTEGRATION": {
            "checkpointFreeze": "AFTER_CORE_ENGINE_COMPLETE_BEFORE_STUDIO",
            "studioAllowed": True,
        },
        "E2_PRESENTATION_AND_FEEL": {
            "checkpointFreeze": "JIT_ONE_CHECKPOINT_AFTER_INTEGRATION_READY",
            "studioAllowed": True,
        },
    }
    for phase in phases:
        if not isinstance(phase, dict):
            errors.append("execution layers: phase must be an object")
            continue
        phase_id = phase.get("id")
        order = phase.get("order")
        modules_required = phase.get("modules")
        gate = phase.get("gate")
        coverage_phase = phase.get("coveragePhaseGate")
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
        expected_runtime = expected_phase_runtime.get(phase_id)
        if expected_runtime:
            for key, expected in expected_runtime.items():
                if phase.get(key) != expected:
                    errors.append(f"execution layers: {phase_id}.{key} must remain {expected!r}")
        if not isinstance(modules_required, list) or not all(isinstance(item, str) for item in modules_required):
            errors.append(f"execution layers: {phase_id}.modules must be a string array")
            continue
        if not isinstance(gate, list) or not gate or not all(isinstance(item, str) and item.strip() for item in gate):
            errors.append(f"execution layers: {phase_id}.gate must be a non-empty string array")
        if phase_id in {"E0_REPOSITORY_CORE_ENGINE", "E1_ROBLOX_RUNTIME_INTEGRATION"}:
            if coverage_phase != phase_id:
                errors.append(f"execution layers: {phase_id}.coveragePhaseGate must equal {phase_id}")
        elif phase_id == "E2_PRESENTATION_AND_FEEL" and coverage_phase != "CHECKPOINT_SPECIFIC":
            errors.append("execution layers: E2 coveragePhaseGate must be CHECKPOINT_SPECIFIC")
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

    for phase_id in ("E0_REPOSITORY_CORE_ENGINE", "E1_ROBLOX_RUNTIME_INTEGRATION"):
        phase = phase_by_id.get(phase_id, {})
        coverage_gate = coverage_phase_gates.get(phase_id)
        if not coverage_gate:
            errors.append(f"execution layers: coverage registry missing phaseGate {phase_id}")
            continue
        blockers = set(coverage_gate.get("blockedBy", [])) & open_gaps
        status = phase.get("status")
        if blockers and not isinstance(status, str):
            errors.append(f"execution layers: {phase_id} must expose blocked/waiting status")
        if phase_id == "E0_REPOSITORY_CORE_ENGINE" and blockers:
            if not str(status).startswith("BLOCKED"):
                errors.append(f"execution layers: E0 must be BLOCKED while coverage blockers are open: {sorted(blockers)}")
        if phase_id == "E0_REPOSITORY_CORE_ENGINE" and not blockers and str(status).startswith("BLOCKED"):
            errors.append("execution layers: E0 remains BLOCKED after coverage blockers were resolved")

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

    e0_blocked = bool(
        set(coverage_phase_gates.get("E0_REPOSITORY_CORE_ENGINE", {}).get("blockedBy", []))
        & open_gaps
    )
    e1_blocked = bool(
        set(coverage_phase_gates.get("E1_ROBLOX_RUNTIME_INTEGRATION", {}).get("blockedBy", []))
        & open_gaps
    )
    if e0_blocked and any(started(mid) for mid in core_modules):
        errors.append("execution layers: core engine modules started while E0 architecture coverage is blocked")
    if e1_blocked and any(started(mid) for mid in integration_modules):
        errors.append("execution layers: integration modules started while E1 architecture coverage is blocked")

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
    coverage, _ = load_json(COVERAGE_PATH)
    counts = Counter(item["class"] for item in execution["moduleExecution"])
    open_blockers = [
        gap.get("id")
        for gap in coverage.get("knownGaps", [])
        if isinstance(gap, dict)
        and gap.get("status") == "OPEN"
        and gap.get("severity") in {"FOUNDATION_BLOCKER", "INTEGRATION_BLOCKER", "EXPLORATION_BLOCKER"}
    ]
    print(
        "RVTT Greenfield execution layer validation passed: "
        + ", ".join(f"{class_id}={counts.get(class_id, 0)}" for class_id in sorted(VALID_CLASSES))
        + f"; phases={len(execution['phases'])}; checkpoints={len(execution['checkpointOrder'])}"
        + f"; future_spec_fields={len(execution['implementationSpecRequirements']['requiredAtCheckpointFreeze'])}"
        + f"; open_architecture_blockers={len(open_blockers)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
