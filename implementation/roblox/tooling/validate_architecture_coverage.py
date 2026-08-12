#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
LEGACY_COVERAGE = ROOT / "manifests/architecture-coverage.json"
SCENARIOS = ROOT / "manifests/architecture-scenarios.json"
CURRENT_MODEL = ROOT / "manifests/implementation-system-model.json"
MODEL_DOC = ROOT / "IMPLEMENTATION-MODEL.md"
SYSTEMS_DOC = ROOT / "SYSTEMS.md"
COVERAGE_POLICY = ROOT / "ARCHITECTURE-COVERAGE-POLICY.md"
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
    print("RVTT architecture coverage validation failed:")
    for error in errors:
        print("-", error)
    return 1


def main() -> int:
    errors: list[str] = []
    try:
        legacy = load_json(LEGACY_COVERAGE)
        expanded = load_json(SCENARIOS)
        current = load_json(CURRENT_MODEL)
    except Exception as exc:
        return fail([str(exc)])

    # Preserve semantic-review tripwire for upstream authority documents.
    authority = legacy.get("authorityCorpus")
    if not isinstance(authority, dict):
        errors.append("legacy authorityCorpus must be an object")
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

    # Legacy scenario definitions remain the canonical scenario bodies.
    base_scenarios = legacy.get("scenarios", [])
    expanded_scenarios = expanded.get("scenarios", [])
    if not isinstance(base_scenarios, list):
        errors.append("legacy coverage.scenarios must be an array")
        base_scenarios = []
    if not isinstance(expanded_scenarios, list):
        errors.append("architecture-scenarios.scenarios must be an array")
        expanded_scenarios = []

    legacy_scenario_ids: list[str] = []
    for source, scenario in [("base", s) for s in base_scenarios] + [("expanded", s) for s in expanded_scenarios]:
        if not isinstance(scenario, dict):
            errors.append(f"{source} scenario entry must be object")
            continue
        sid = scenario.get("id")
        if not isinstance(sid, str) or not sid:
            errors.append(f"{source} scenario.id is required")
            continue
        legacy_scenario_ids.append(sid)
        if not isinstance(scenario.get("steps"), list) or not scenario.get("steps"):
            errors.append(f"{sid}: steps must be non-empty")
        if not isinstance(scenario.get("negativeCases"), list) or not scenario.get("negativeCases"):
            errors.append(f"{sid}: negativeCases must be non-empty")
        if not isinstance(scenario.get("expectedOutcome"), str) or not scenario.get("expectedOutcome", "").strip():
            errors.append(f"{sid}: expectedOutcome is required")

    if len(legacy_scenario_ids) != len(set(legacy_scenario_ids)):
        errors.append("base + expanded scenario ids must be unique")
    if len(legacy_scenario_ids) != 61:
        errors.append(f"representative scenario catalog must contain 61 scenarios, found {len(legacy_scenario_ids)}")

    # Current machine-readable implementation model.
    if current.get("status") != "ACTIVE_R3_REPAIRED_PENDING_FREEZE":
        errors.append("implementation-system-model status must be ACTIVE_R3_REPAIRED_PENDING_FREEZE")
    if current.get("systemModelVersion") != 2:
        errors.append("systemModelVersion must be 2")
    if current.get("requirementCapabilityCatalogVersion") != 3:
        errors.append("requirementCapabilityCatalogVersion must be 3")
    if current.get("systemCount") != 34:
        errors.append("systemCount must be 34")
    if current.get("requirementCapabilityCount") != 30:
        errors.append("requirementCapabilityCount must be 30")
    if current.get("scenarioTraceCount") != 61:
        errors.append("scenarioTraceCount must be 61")
    if current.get("sourceImplementationAllowed") is not False:
        errors.append("sourceImplementationAllowed must remain false during R3")
    if current.get("studioImplementationAllowed") is not False:
        errors.append("studioImplementationAllowed must remain false during R3")

    systems = current.get("systems")
    if not isinstance(systems, list):
        errors.append("systems must be an array")
        systems = []
    system_ids: list[str] = []
    system_names: list[str] = []
    group_counts: Counter[str] = Counter()
    for item in systems:
        if not isinstance(item, dict):
            errors.append("system entry must be object")
            continue
        sid = item.get("id")
        name = item.get("name")
        group = item.get("group")
        if not isinstance(sid, str) or not sid:
            errors.append("system.id is required")
            continue
        if not isinstance(name, str) or not name:
            errors.append(f"{sid}: system.name is required")
        if not isinstance(group, str) or not group:
            errors.append(f"{sid}: system.group is required")
        system_ids.append(sid)
        system_names.append(name if isinstance(name, str) else "")
        if isinstance(group, str):
            group_counts[group] += 1

    if len(system_ids) != 34:
        errors.append(f"systems must contain 34 entries, found {len(system_ids)}")
    if len(system_ids) != len(set(system_ids)):
        errors.append("system ids must be unique")
    if len(system_names) != len(set(system_names)):
        errors.append("system names must be unique")
    expected_group_counts = {"AUTHORITY": 8, "WORLD": 7, "RULES": 5, "DOMAIN": 7, "AUTHORING": 2, "CLIENT": 3, "SUPPORT": 2}
    if dict(group_counts) != expected_group_counts:
        errors.append(f"system group counts drifted: expected={expected_group_counts} actual={dict(group_counts)}")
    system_set = set(system_ids)
    if "A8" not in system_set:
        errors.append("A8 Domain Event Delivery Runtime is required")

    requirements = current.get("requirementCapabilities")
    if not isinstance(requirements, list):
        errors.append("requirementCapabilities must be an array")
        requirements = []
    req_ids: list[str] = []
    system_to_requirements: dict[str, set[str]] = defaultdict(set)
    for req in requirements:
        if not isinstance(req, dict):
            errors.append("requirement capability entry must be object")
            continue
        rid = req.get("id")
        refs = req.get("systemRefs")
        source_refs = req.get("sourceRefs")
        if not isinstance(rid, str) or not rid:
            errors.append("requirement capability id is required")
            continue
        req_ids.append(rid)
        if not isinstance(refs, list) or len(refs) < 2:
            errors.append(f"{rid}: systemRefs must contain at least two systems to preserve requirement/system independence")
            refs = []
        unknown = [ref for ref in refs if ref not in system_set]
        if unknown:
            errors.append(f"{rid}: unknown system refs {unknown}")
        for ref in refs:
            if ref in system_set:
                system_to_requirements[ref].add(rid)
        if not isinstance(source_refs, list) or not source_refs:
            errors.append(f"{rid}: sourceRefs must be non-empty")
        else:
            for ref in source_refs:
                if not isinstance(ref, str) or not (REPO_ROOT / ref).exists():
                    errors.append(f"{rid}: missing authority sourceRef {ref}")

    if len(req_ids) != 30:
        errors.append(f"requirementCapabilities must contain 30 entries, found {len(req_ids)}")
    if len(req_ids) != len(set(req_ids)):
        errors.append("requirement capability ids must be unique")
    req_set = set(req_ids)
    unpressured_systems = sorted(system_set - set(system_to_requirements))
    if unpressured_systems:
        errors.append(f"systems without Requirement Capability pressure: {unpressured_systems}")

    traces = current.get("scenarioTrace")
    if not isinstance(traces, list):
        errors.append("scenarioTrace must be an array")
        traces = []
    trace_ids: list[str] = []
    used_requirements: set[str] = set()
    trace_by_id: dict[str, dict] = {}
    for trace in traces:
        if not isinstance(trace, dict):
            errors.append("scenarioTrace entry must be object")
            continue
        sid = trace.get("id")
        srefs = trace.get("systemRefs")
        rrefs = trace.get("requirementCapabilityRefs")
        if not isinstance(sid, str) or not sid:
            errors.append("scenarioTrace.id is required")
            continue
        trace_ids.append(sid)
        trace_by_id[sid] = trace
        if not isinstance(srefs, list) or not srefs:
            errors.append(f"{sid}: systemRefs must be non-empty")
            srefs = []
        if not isinstance(rrefs, list) or not rrefs:
            errors.append(f"{sid}: requirementCapabilityRefs must be non-empty")
            rrefs = []
        unknown_systems = [ref for ref in srefs if ref not in system_set]
        unknown_reqs = [ref for ref in rrefs if ref not in req_set]
        if unknown_systems:
            errors.append(f"{sid}: unknown system refs {unknown_systems}")
        if unknown_reqs:
            errors.append(f"{sid}: unknown requirement refs {unknown_reqs}")
        used_requirements.update(ref for ref in rrefs if ref in req_set)

    if len(trace_ids) != 61:
        errors.append(f"scenarioTrace must contain 61 entries, found {len(trace_ids)}")
    if len(trace_ids) != len(set(trace_ids)):
        errors.append("scenarioTrace ids must be unique")
    if set(trace_ids) != set(legacy_scenario_ids):
        errors.append(
            "scenarioTrace ID set must exactly match base+expanded scenario catalogs; "
            f"missing={sorted(set(legacy_scenario_ids)-set(trace_ids))} extra={sorted(set(trace_ids)-set(legacy_scenario_ids))}"
        )
    unused_requirements = sorted(req_set - used_requirements)
    if unused_requirements:
        errors.append(f"Requirement Capabilities unused by all scenarios: {unused_requirements}")

    # Sentinel traces protect the repaired Event Delivery boundary.
    for sid in ["SCN_CONCURRENT_DOOR_INTERACTION", "SCN_ATTACK_REACTION_RESOLUTION", "SCN_ITEM_PICKUP", "SCN_FULL_SESSION_CROSS_SYSTEM_RECOVERY"]:
        trace = trace_by_id.get(sid, {})
        if "A8" not in trace.get("systemRefs", []):
            errors.append(f"{sid}: must include A8 committed-event delivery pressure")
        if "REQ_COMMITTED_EVENT_PROPAGATION" not in trace.get("requirementCapabilityRefs", []):
            errors.append(f"{sid}: must include REQ_COMMITTED_EVENT_PROPAGATION")

    # R3 execution semantics and repaired invariants.
    semantics = current.get("executionLayerSemantics")
    if not isinstance(semantics, dict):
        errors.append("executionLayerSemantics must be object")
    else:
        for key in ["repositoryLogic", "e0CoreEngine", "e1RobloxRuntime", "humanPresentation", "coreEngineCompleteDefinition"]:
            if not isinstance(semantics.get(key), str) or not semantics.get(key, "").strip():
                errors.append(f"executionLayerSemantics.{key} is required")

    e0 = current.get("e0RequiredSystemSeams")
    deferred = current.get("deferredRepositoryFeatureSystems")
    if not isinstance(e0, list) or not e0:
        errors.append("e0RequiredSystemSeams must be non-empty")
        e0 = []
    if len(e0) != len(set(e0)):
        errors.append("e0RequiredSystemSeams must be unique")
    unknown_e0 = [ref for ref in e0 if ref not in system_set]
    if unknown_e0:
        errors.append(f"e0RequiredSystemSeams contains unknown systems {unknown_e0}")
    mandatory_e1_precursors = {"W5", "W6", "W7", "C1", "C2", "C3", "S2", "A8"}
    missing_precursors = sorted(mandatory_e1_precursors - set(e0))
    if missing_precursors:
        errors.append(f"E1-consuming Core seams missing from E0 set: {missing_precursors}")
    if not isinstance(deferred, list):
        errors.append("deferredRepositoryFeatureSystems must be array")
        deferred = []
    if set(e0) & set(deferred):
        errors.append(f"systems cannot be both E0-required and deferred feature systems: {sorted(set(e0)&set(deferred))}")
    if set(deferred) != {"D6", "D7", "U2"}:
        errors.append("deferredRepositoryFeatureSystems must currently be exactly D6,D7,U2")

    ready = current.get("readyGateComposition")
    if not isinstance(ready, dict) or ready.get("finalOwner") != "A1":
        errors.append("readyGateComposition.finalOwner must be A1")
    else:
        expected_ready_inputs = {
            "authorityRecoveryReady": "A7",
            "projectionSyncReady": "A6",
            "sceneEssentialReady": "W7",
            "clientReplicaReady": "C1",
        }
        if ready.get("inputs") != expected_ready_inputs:
            errors.append(f"readyGateComposition.inputs drifted: expected={expected_ready_inputs} actual={ready.get('inputs')}")

    reservations = current.get("reservationTaxonomy")
    expected_reservations = {
        "OrderingReservation": "A3",
        "ResourceReservation": "R3",
        "OccupancyReservation": "W6",
        "ActivityReservation": "D5",
        "LogisticsAllocationReservation": "D7",
    }
    actual_reservations: dict[str, str] = {}
    if not isinstance(reservations, list):
        errors.append("reservationTaxonomy must be an array")
    else:
        for item in reservations:
            if isinstance(item, dict) and isinstance(item.get("kind"), str) and isinstance(item.get("owner"), str):
                actual_reservations[item["kind"]] = item["owner"]
    if actual_reservations != expected_reservations:
        errors.append(f"reservation taxonomy drifted: expected={expected_reservations} actual={actual_reservations}")

    providers = current.get("platformProviderContracts")
    expected_provider_ids = {"AUTHORITY_MONOTONIC_CLOCK", "DETERMINISTIC_ID_FACTORY", "RNG_PROVIDER", "TRANSPORT_ADAPTER", "STORAGE_ADAPTER"}
    provider_ids: set[str] = set()
    if not isinstance(providers, list):
        errors.append("platformProviderContracts must be array")
    else:
        for item in providers:
            if not isinstance(item, dict) or not isinstance(item.get("id"), str):
                errors.append("platformProviderContracts entry requires id")
                continue
            provider_ids.add(item["id"])
            if item.get("testOwner") != "S2":
                errors.append(f"{item['id']}: testOwner must be S2")
    if provider_ids != expected_provider_ids:
        errors.append(f"platform provider set drifted: expected={sorted(expected_provider_ids)} actual={sorted(provider_ids)}")

    # Human-readable authority must agree with the machine model.
    model_text = MODEL_DOC.read_text(encoding="utf-8")
    systems_text = SYSTEMS_DOC.read_text(encoding="utf-8")
    policy_text = COVERAGE_POLICY.read_text(encoding="utf-8")
    task_text = ACTIVE_TASK.read_text(encoding="utf-8")
    required_markers = [
        ("IMPLEMENTATION-MODEL.md", model_text, "SYSTEM MODEL = V2 · 34 SYSTEMS · REPAIRED"),
        ("IMPLEMENTATION-MODEL.md", model_text, "REPOSITORY_LOGIC"),
        ("IMPLEMENTATION-MODEL.md", model_text, "E0_CORE_ENGINE"),
        ("SYSTEMS.md", systems_text, "34 System Responsibility Model"),
        ("SYSTEMS.md", systems_text, "A8 | Domain Event Delivery Runtime"),
        ("SYSTEMS.md", systems_text, "Requirement Capability Catalog v3"),
        ("Coverage Policy", policy_text, "30 Requirement Capability Catalog v3"),
        ("Active Task", task_text, "R3_REPAIRED_AWAITING_FREEZE_DECISION"),
        ("Active Task", task_text, "sourceImplementationAllowed: `false`"),
        ("Active Task", task_text, "studioImplementationAllowed: `false`"),
    ]
    for label, text, marker in required_markers:
        if marker not in text:
            errors.append(f"{label}: missing marker {marker}")

    for sid, name in zip(system_ids, system_names):
        if f"| {sid} | {name} |" not in systems_text:
            errors.append(f"SYSTEMS.md missing system table row for {sid} {name}")

    if errors:
        return fail(errors)

    print(
        "RVTT architecture coverage validation passed: "
        f"systems={len(system_ids)}; requirement_capabilities={len(req_ids)}; "
        f"scenarios={len(trace_ids)} (base={len(base_scenarios)}, expanded={len(expanded_scenarios)}); "
        "event_delivery=A8; ready_gate=A1; reservation_taxonomy=PASS; provider_contracts=PASS; "
        f"e0_required_seams={len(e0)}; deferred_repository_features={len(deferred)}; "
        "source=BLOCKED; studio=BLOCKED; R3=REPAIRED_NOT_FROZEN"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
