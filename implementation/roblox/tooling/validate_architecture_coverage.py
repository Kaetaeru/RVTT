#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ROBLOX = ROOT / "implementation" / "roblox"
COVERAGE_PATH = ROBLOX / "manifests" / "architecture-coverage.json"
SCENARIO_PATH = ROBLOX / "manifests" / "architecture-scenarios.json"
MODULE_PATH = ROBLOX / "manifests" / "module-contracts.json"
SYSTEM_PATH = ROBLOX / "manifests" / "system-function-contracts.json"
EXECUTION_PATH = ROBLOX / "manifests" / "execution-layers.json"

ERRORS = []


def error(message):
    ERRORS.append(message)


def load_json(path):
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except Exception as exc:
        error(f"cannot load {path.relative_to(ROOT)}: {exc}")
        return {}


def git_object_sha(path):
    try:
        result = subprocess.run(
            ["git", "rev-parse", f"HEAD:{path}"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.strip()
    except Exception as exc:
        error(f"cannot resolve Git object for {path}: {exc}")
        return None


def require_keys(obj, keys, label):
    if not isinstance(obj, dict):
        error(f"{label} must be an object")
        return
    for key in keys:
        if key not in obj:
            error(f"{label} missing required key: {key}")


def validate_file_ref(path, label):
    if not isinstance(path, str) or not path:
        error(f"{label} must be a non-empty repository path")
        return
    if not (ROOT / path).is_file():
        error(f"{label} does not exist: {path}")


def main():
    coverage = load_json(COVERAGE_PATH)
    scenario_catalog = load_json(SCENARIO_PATH)
    modules_doc = load_json(MODULE_PATH)
    systems_doc = load_json(SYSTEM_PATH)
    execution_doc = load_json(EXECUTION_PATH)

    require_keys(
        coverage,
        [
            "schemaVersion",
            "registryId",
            "authorityDocument",
            "implementationGate",
            "authorityCorpus",
            "crossCuttingDimensions",
            "capabilities",
            "scenarios",
            "knownGaps",
            "phaseGates",
        ],
        "coverage registry",
    )

    if coverage.get("schemaVersion") != 1:
        error("coverage schemaVersion must be 1")

    require_keys(
        scenario_catalog,
        [
            "schemaVersion",
            "registryId",
            "authorityDocument",
            "baseRegistry",
            "policy",
            "scenarios",
        ],
        "scenario catalog",
    )
    if scenario_catalog.get("schemaVersion") != 1:
        error("scenario catalog schemaVersion must be 1")
    if scenario_catalog.get("registryId") != "rvtt-greenfield-architecture-scenarios-v1":
        error("scenario catalog registryId drifted")
    if scenario_catalog.get("authorityDocument") != "implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md":
        error("scenario catalog authorityDocument drifted")
    if scenario_catalog.get("baseRegistry") != "implementation/roblox/manifests/architecture-coverage.json":
        error("scenario catalog baseRegistry drifted")

    scenario_policy = scenario_catalog.get("policy", {})
    required_scenario_policy = {
        "scenarioDoesNotAuthorizeArchitectureChange": True,
        "futureScenarioMayRemainDeferred": True,
        "scenarioMustReferenceExistingCapability": True,
        "negativeCaseRequired": True,
        "preferEndToEndUserOrOperatorFlow": True,
    }
    for key, expected in required_scenario_policy.items():
        if scenario_policy.get(key) is not expected:
            error(f"scenario catalog policy.{key} must remain {expected}")

    validate_file_ref(coverage.get("authorityDocument"), "coverage authorityDocument")
    validate_file_ref(coverage.get("auditDocument"), "coverage auditDocument")

    authority = coverage.get("authorityCorpus", {})
    require_keys(authority, ["treeSnapshots", "directFiles"], "authorityCorpus")

    for entry in authority.get("treeSnapshots", []):
        require_keys(entry, ["path", "expectedTreeSha", "role"], "authority tree snapshot")
        path = entry.get("path")
        if path and not (ROOT / path).is_dir():
            error(f"authority tree path does not exist: {path}")
            continue
        actual = git_object_sha(path) if path else None
        expected = entry.get("expectedTreeSha")
        if actual and expected and actual != expected:
            error(
                f"authority tree changed without coverage reconciliation: {path} "
                f"expected={expected} actual={actual}"
            )

    for entry in authority.get("directFiles", []):
        require_keys(entry, ["path", "expectedBlobSha", "role"], "direct authority file")
        path = entry.get("path")
        validate_file_ref(path, "direct authority file")
        actual = git_object_sha(path) if path else None
        expected = entry.get("expectedBlobSha")
        if actual and expected and actual != expected:
            error(
                f"direct authority file changed without coverage reconciliation: {path} "
                f"expected={expected} actual={actual}"
            )

    module_ids = {
        item.get("id")
        for item in modules_doc.get("modules", [])
        if isinstance(item, dict) and item.get("id")
    }
    system_ids = {
        item.get("id")
        for item in systems_doc.get("systemContracts", [])
        if isinstance(item, dict) and item.get("id")
    }

    dimensions = coverage.get("crossCuttingDimensions", [])
    if not isinstance(dimensions, list) or not dimensions:
        error("crossCuttingDimensions must be a non-empty list")
        dimensions = []
    if len(dimensions) != len(set(dimensions)):
        error("crossCuttingDimensions contains duplicates")

    capabilities = coverage.get("capabilities", [])
    capability_ids = set()
    covered_modules = set()
    covered_systems = set()
    valid_coverage_states = {"MAPPED", "PARTIAL", "UNMAPPED", "DEFERRED"}
    valid_dimension_prefixes = (
        "COVERED",
        "PARTIAL",
        "UNRESOLVED",
        "DEFERRED",
        "N/A",
        "PLANNED",
        "REQUIRED",
    )

    for cap in capabilities:
        require_keys(
            cap,
            [
                "id",
                "title",
                "plannedPhase",
                "coverageState",
                "authorityRefs",
                "systemRefs",
                "moduleRefs",
                "knownGapRefs",
                "flow",
                "crossCutting",
            ],
            "capability",
        )
        cid = cap.get("id")
        if not cid:
            continue
        if cid in capability_ids:
            error(f"duplicate capability id: {cid}")
        capability_ids.add(cid)

        if cap.get("coverageState") not in valid_coverage_states:
            error(f"{cid} has invalid coverageState: {cap.get('coverageState')}")

        refs = cap.get("authorityRefs", [])
        if not isinstance(refs, list) or not refs:
            error(f"{cid} must have at least one authorityRef")
        for ref in refs:
            validate_file_ref(ref, f"{cid} authorityRef")

        for sid in cap.get("systemRefs", []):
            if sid not in system_ids:
                error(f"{cid} references unknown system: {sid}")
            else:
                covered_systems.add(sid)

        for mid in cap.get("moduleRefs", []):
            if mid not in module_ids:
                error(f"{cid} references unknown module: {mid}")
            else:
                covered_modules.add(mid)

        matrix = cap.get("crossCutting", {})
        if set(matrix.keys()) != set(dimensions):
            missing = sorted(set(dimensions) - set(matrix.keys()))
            extra = sorted(set(matrix.keys()) - set(dimensions))
            if missing:
                error(f"{cid} missing cross-cutting dimensions: {missing}")
            if extra:
                error(f"{cid} has unknown cross-cutting dimensions: {extra}")
        for dimension, value in matrix.items():
            if not isinstance(value, str) or not value.strip():
                error(f"{cid}.{dimension} must be a non-empty decision string")
            elif not value.startswith(valid_dimension_prefixes):
                error(f"{cid}.{dimension} has unsupported status prefix: {value}")

    infrastructure = coverage.get("infrastructureModules", [])
    infrastructure_ids = set()
    for entry in infrastructure:
        require_keys(entry, ["moduleId", "reason"], "infrastructureModules entry")
        mid = entry.get("moduleId")
        if mid not in module_ids:
            error(f"infrastructureModules references unknown module: {mid}")
        elif mid:
            infrastructure_ids.add(mid)
        if not entry.get("reason"):
            error(f"infrastructure module {mid} requires a reason")

    orphan_modules = sorted(module_ids - covered_modules - infrastructure_ids)
    if orphan_modules:
        error(f"current Greenfield modules have no Product Capability mapping: {orphan_modules}")

    orphan_systems = sorted(system_ids - covered_systems)
    if orphan_systems:
        error(f"current Greenfield systems have no Product Capability mapping: {orphan_systems}")

    gaps = coverage.get("knownGaps", [])
    gap_ids = set()
    open_blockers = set()
    blocker_severities = {"FOUNDATION_BLOCKER", "INTEGRATION_BLOCKER", "EXPLORATION_BLOCKER"}
    for gap in gaps:
        require_keys(
            gap,
            ["id", "severity", "status", "blockingScopes", "title", "evidenceRefs", "requiredDecision"],
            "knownGap",
        )
        gid = gap.get("id")
        if not gid:
            continue
        if gid in gap_ids:
            error(f"duplicate gap id: {gid}")
        gap_ids.add(gid)
        if gap.get("status") not in {"OPEN", "RESOLVED", "SUPERSEDED"}:
            error(f"{gid} has invalid status: {gap.get('status')}")
        if gap.get("severity") not in blocker_severities | {"TRACKED_DEFERRED"}:
            error(f"{gid} has invalid severity: {gap.get('severity')}")
        for ref in gap.get("evidenceRefs", []):
            validate_file_ref(ref, f"{gid} evidenceRef")
        if gap.get("status") == "OPEN" and gap.get("severity") in blocker_severities:
            open_blockers.add(gid)

    for cap in capabilities:
        for gid in cap.get("knownGapRefs", []):
            if gid not in gap_ids:
                error(f"{cap.get('id')} references unknown gap: {gid}")

    phase_gates = coverage.get("phaseGates", [])
    phase_ids = set()
    for gate in phase_gates:
        require_keys(gate, ["phase", "blockedBy"], "phaseGate")
        phase = gate.get("phase")
        if phase in phase_ids:
            error(f"duplicate phaseGate: {phase}")
        phase_ids.add(phase)
        for gid in gate.get("blockedBy", []):
            if gid not in gap_ids:
                error(f"phase {phase} references unknown gap: {gid}")

    base_scenarios = coverage.get("scenarios", [])
    additional_scenarios = scenario_catalog.get("scenarios", [])
    if not isinstance(base_scenarios, list):
        error("coverage scenarios must be a list")
        base_scenarios = []
    if not isinstance(additional_scenarios, list):
        error("scenario catalog scenarios must be a list")
        additional_scenarios = []
    scenarios = base_scenarios + additional_scenarios

    scenario_ids = set()
    for scenario in scenarios:
        require_keys(
            scenario,
            ["id", "status", "phase", "capabilityRefs", "steps", "expectedOutcome", "negativeCases"],
            "scenario",
        )
        sid = scenario.get("id")
        if not sid:
            continue
        if sid in scenario_ids:
            error(f"duplicate scenario id across scenario catalogs: {sid}")
        scenario_ids.add(sid)
        refs = scenario.get("capabilityRefs", [])
        if not refs:
            error(f"{sid} must reference at least one capability")
        for cid in refs:
            if cid not in capability_ids:
                error(f"{sid} references unknown capability: {cid}")
        steps = scenario.get("steps", [])
        if not isinstance(steps, list) or not steps or not all(isinstance(item, str) and item.strip() for item in steps):
            error(f"{sid} must have at least one non-empty string step")
        negative_cases = scenario.get("negativeCases", [])
        if not isinstance(negative_cases, list) or not negative_cases or not all(
            isinstance(item, str) and item.strip() for item in negative_cases
        ):
            error(f"{sid} must have at least one non-empty negative case")
        if not isinstance(scenario.get("expectedOutcome"), str) or not scenario.get("expectedOutcome", "").strip():
            error(f"{sid} expectedOutcome must be a non-empty string")

    gate = coverage.get("implementationGate", "")
    if open_blockers and not str(gate).startswith("BLOCKED"):
        error(
            "implementationGate must be BLOCKED while open architecture blockers exist: "
            + ", ".join(sorted(open_blockers))
        )
    if not open_blockers and str(gate).startswith("BLOCKED"):
        error("implementationGate is BLOCKED but no open blocking gaps remain")

    execution_module_ids = {
        entry.get("moduleId")
        for entry in execution_doc.get("moduleExecution", [])
        if isinstance(entry, dict) and entry.get("moduleId")
    }
    unknown_execution = sorted(execution_module_ids - module_ids)
    if unknown_execution:
        error(f"execution registry references modules missing from module registry: {unknown_execution}")

    if ERRORS:
        print("RVTT architecture coverage validation FAILED")
        for item in ERRORS:
            print(f"- {item}")
        return 1

    state_counts = {}
    for cap in capabilities:
        state = cap.get("coverageState")
        state_counts[state] = state_counts.get(state, 0) + 1
    print(
        "RVTT architecture coverage validation passed: "
        f"capabilities={len(capabilities)} {state_counts}; "
        f"scenarios={len(scenarios)} (base={len(base_scenarios)}, expanded={len(additional_scenarios)}); "
        f"gaps={len(gaps)}; open_blockers={len(open_blockers)}; implementationGate={gate}; "
        f"modules_covered={len(covered_modules | infrastructure_ids)}/{len(module_ids)}; "
        f"systems_covered={len(covered_systems)}/{len(system_ids)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
