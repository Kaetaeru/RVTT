#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
COVERAGE = ROOT / "manifests/architecture-coverage.json"
SCENARIOS = ROOT / "manifests/architecture-scenarios.json"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
ACTIVE_TASK = REPO_ROOT / ".github/CODEX-ACTIVE-TASK.md"


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def git_object(expr: str) -> str | None:
    result = subprocess.run(
        ["git", "rev-parse", expr],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def fail(errors: list[str]) -> int:
    print("RVTT implementation-model-neutral coverage validation failed:")
    for error in errors:
        print("-", error)
    return 1


def main() -> int:
    errors: list[str] = []
    try:
        coverage = load_json(COVERAGE)
        expanded = load_json(SCENARIOS)
    except Exception as exc:
        return fail([str(exc)])

    authority = coverage.get("authorityCorpus")
    if not isinstance(authority, dict):
        errors.append("authorityCorpus must be an object")
    else:
        for snapshot in authority.get("treeSnapshots", []):
            if not isinstance(snapshot, dict):
                errors.append("treeSnapshots entry must be object")
                continue
            path = snapshot.get("path")
            expected = snapshot.get("expectedTreeSha")
            if not isinstance(path, str) or not isinstance(expected, str):
                errors.append("treeSnapshots entry requires path + expectedTreeSha")
                continue
            actual = git_object(f"HEAD:{path}")
            if actual != expected:
                errors.append(
                    f"authority tree changed for {path}: expected={expected} actual={actual}; "
                    "perform semantic coverage review before updating the snapshot"
                )
        for direct in authority.get("directFiles", []):
            if not isinstance(direct, dict):
                errors.append("directFiles entry must be object")
                continue
            path = direct.get("path")
            expected = direct.get("expectedBlobSha")
            if not isinstance(path, str) or not isinstance(expected, str):
                errors.append("directFiles entry requires path + expectedBlobSha")
                continue
            actual = git_object(f"HEAD:{path}")
            if actual != expected:
                errors.append(
                    f"authority file changed for {path}: expected={expected} actual={actual}; "
                    "perform semantic coverage review before updating the snapshot"
                )

    capabilities = coverage.get("capabilities")
    if not isinstance(capabilities, list) or not capabilities:
        errors.append("coverage capabilities must be a non-empty array")
        capabilities = []

    capability_ids: list[str] = []
    required_dimensions = coverage.get("crossCuttingDimensions")
    if not isinstance(required_dimensions, list) or not required_dimensions:
        errors.append("crossCuttingDimensions must be a non-empty array")
        required_dimensions = []

    for capability in capabilities:
        if not isinstance(capability, dict):
            errors.append("capability entry must be an object")
            continue
        cid = capability.get("id")
        if not isinstance(cid, str) or not cid:
            errors.append("capability.id is required")
            continue
        capability_ids.append(cid)
        for field in ("title", "plannedPhase", "authorityRefs", "flow", "crossCutting"):
            if field not in capability:
                errors.append(f"{cid}: missing {field}")
        refs = capability.get("authorityRefs")
        if not isinstance(refs, list) or not refs:
            errors.append(f"{cid}: authorityRefs must be non-empty")
        matrix = capability.get("crossCutting")
        if not isinstance(matrix, dict):
            errors.append(f"{cid}: crossCutting must be an object")
        else:
            missing = [dim for dim in required_dimensions if dim not in matrix]
            if missing:
                errors.append(f"{cid}: missing cross-cutting dimensions {missing}")

    if len(capability_ids) != len(set(capability_ids)):
        errors.append("capability ids must be unique")
    capability_set = set(capability_ids)

    base_scenarios = coverage.get("scenarios", [])
    expanded_scenarios = expanded.get("scenarios", [])
    if not isinstance(base_scenarios, list):
        errors.append("coverage.scenarios must be an array")
        base_scenarios = []
    if not isinstance(expanded_scenarios, list):
        errors.append("architecture-scenarios.scenarios must be an array")
        expanded_scenarios = []

    all_scenarios = [("base", item) for item in base_scenarios] + [
        ("expanded", item) for item in expanded_scenarios
    ]
    scenario_ids: list[str] = []
    for source, scenario in all_scenarios:
        if not isinstance(scenario, dict):
            errors.append(f"{source} scenario entry must be an object")
            continue
        sid = scenario.get("id")
        if not isinstance(sid, str) or not sid:
            errors.append(f"{source} scenario.id is required")
            continue
        scenario_ids.append(sid)
        refs = scenario.get("capabilityRefs")
        if not isinstance(refs, list) or not refs:
            errors.append(f"{sid}: capabilityRefs must be non-empty")
        else:
            unknown = [ref for ref in refs if ref not in capability_set]
            if unknown:
                errors.append(f"{sid}: unknown capability refs {unknown}")
        steps = scenario.get("steps")
        if not isinstance(steps, list) or not steps:
            errors.append(f"{sid}: steps must be non-empty")
        if not isinstance(scenario.get("expectedOutcome"), str) or not scenario.get("expectedOutcome", "").strip():
            errors.append(f"{sid}: expectedOutcome is required")
        negatives = scenario.get("negativeCases")
        if not isinstance(negatives, list) or not negatives:
            errors.append(f"{sid}: negativeCases must be non-empty")

    if len(scenario_ids) != len(set(scenario_ids)):
        errors.append("base + expanded scenario ids must be unique")

    gate = coverage.get("implementationGate")
    if isinstance(gate, str) and gate.startswith("READY"):
        errors.append("legacy coverage registry must not advertise READY while implementation model reset is active")

    if not MODEL.exists() or "IMPLEMENTATION_MODEL_RESET" not in MODEL.read_text(encoding="utf-8"):
        errors.append("IMPLEMENTATION-MODEL.md must declare IMPLEMENTATION_MODEL_RESET")
    if not ACTIVE_TASK.exists() or "IMPLEMENTATION_MODEL_RESET" not in ACTIVE_TASK.read_text(encoding="utf-8"):
        errors.append("CODEX-ACTIVE-TASK.md must declare IMPLEMENTATION_MODEL_RESET")

    if errors:
        return fail(errors)

    print(
        "RVTT implementation-model-neutral coverage validation passed: "
        f"capabilities={len(capability_ids)}; "
        f"scenarios={len(scenario_ids)} (base={len(base_scenarios)}, expanded={len(expanded_scenarios)}); "
        "authority_snapshot=PASS; legacy systemRefs/moduleRefs ignored during model reset; source=BLOCKED; studio=BLOCKED"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
