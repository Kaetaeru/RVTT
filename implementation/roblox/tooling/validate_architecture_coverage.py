#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
LEGACY_COVERAGE = ROOT / "manifests/architecture-coverage.json"
BASE_SCENARIOS = ROOT / "manifests/scenario-base-catalog.json"
EXPANDED_SCENARIOS = ROOT / "manifests/scenario-expanded-catalog.json"
CURRENT_MODEL = ROOT / "manifests/implementation-system-model.json"
MODEL_DOC = ROOT / "IMPLEMENTATION-MODEL.md"
SYSTEMS_DOC = ROOT / "SYSTEMS.md"
COVERAGE_POLICY = ROOT / "ARCHITECTURE-COVERAGE-POLICY.md"
ACTIVE_TASK = REPO_ROOT / ".github/CODEX-ACTIVE-TASK.md"
AGENTS = REPO_ROOT / "AGENTS.md"

EXPECTED_SEMANTIC_AUDIT_DIGEST = "sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140"
ALLOWED_SEMANTIC_STAGES = {"READ", "MUTATION", "EVENT", "PROJECTION", "RECOVERY", "HUMAN"}
FORBIDDEN_SCENARIO_KEYS = {"status", "capabilityRefs", "systemRefs", "moduleRefs", "knownGapRefs"}
EXPECTED_CATALOG_POLICY = {
    "legacyGreenfieldReferencesExcluded": True,
    "requirementMappingOwnedBy": "implementation/roblox/manifests/implementation-system-model.json",
    "semanticAuditOwnedBy": "implementation/roblox/manifests/scenario-semantic-audit-v3.json",
    "negativeCaseRequired": True,
}
EXPECTED_GROUP_COUNTS = {"AUTHORITY": 8, "WORLD": 7, "RULES": 5, "DOMAIN": 7, "AUTHORING": 2, "CLIENT": 3, "SUPPORT": 2}
EXPECTED_READY = {
    "authorityRecoveryReady": "A7",
    "projectionSyncReady": "A6",
    "sceneEssentialReady": "W7",
    "clientReplicaReady": "C1",
}
EXPECTED_RESERVATIONS = {
    "OrderingReservation": "A3",
    "ResourceReservation": "R3",
    "OccupancyReservation": "W6",
    "ActivityReservation": "D5",
    "LogisticsAllocationReservation": "D7",
}
EXPECTED_PROVIDER_IDS = {"AUTHORITY_MONOTONIC_CLOCK", "DETERMINISTIC_ID_FACTORY", "RNG_PROVIDER", "TRANSPORT_ADAPTER", "STORAGE_ADAPTER"}
EXPECTED_DEFERRED = {"D6", "D7", "U2"}
REQUIRED_E0 = {"A8", "W5", "W6", "W7", "C1", "C2", "C3", "S2"}


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
        base = load_json(BASE_SCENARIOS)
        expanded = load_json(EXPANDED_SCENARIOS)
        current = load_json(CURRENT_MODEL)
    except Exception as exc:
        return fail([str(exc)])

    authority = legacy.get("authorityCorpus")
    if not isinstance(authority, dict):
        errors.append("legacy authorityCorpus must remain an object")
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
                errors.append(f"authority tree changed for {path}: expected={expected} actual={actual}")
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
                errors.append(f"authority file changed for {path}: expected={expected} actual={actual}")

    if base.get("registryId") != "rvtt-scenario-base-catalog-v1":
        errors.append("canonical Base source must be rvtt-scenario-base-catalog-v1")
    if expanded.get("registryId") != "rvtt-scenario-expanded-catalog-v1":
        errors.append("canonical Expanded source must be rvtt-scenario-expanded-catalog-v1")
    for label, catalog in (("Base", base), ("Expanded", expanded)):
        if catalog.get("policy") != EXPECTED_CATALOG_POLICY:
            errors.append(f"{label} catalog policy drifted from clean current authority")

    base_scenarios = base.get("scenarios", [])
    expanded_scenarios = expanded.get("scenarios", [])
    if not isinstance(base_scenarios, list) or len(base_scenarios) != 14:
        errors.append("canonical Base catalog must contain exactly 14 scenarios")
        base_scenarios = []
    if not isinstance(expanded_scenarios, list) or len(expanded_scenarios) != 47:
        errors.append("canonical Expanded catalog must contain exactly 47 scenarios")
        expanded_scenarios = []

    scenario_ids: list[str] = []
    for source, scenario in [("base", s) for s in base_scenarios] + [("expanded", s) for s in expanded_scenarios]:
        if not isinstance(scenario, dict):
            errors.append(f"{source} scenario entry must be object")
            continue
        sid = scenario.get("id")
        if not isinstance(sid, str) or not sid:
            errors.append(f"{source} scenario.id is required")
            continue
        scenario_ids.append(sid)
        forbidden = sorted(FORBIDDEN_SCENARIO_KEYS & set(scenario))
        if forbidden:
            errors.append(f"{sid}: clean Scenario catalog leaked legacy coverage/mapping keys {forbidden}")
        if not isinstance(scenario.get("phase"), str) or not scenario.get("phase", "").strip():
            errors.append(f"{sid}: phase is required")
        if not isinstance(scenario.get("steps"), list) or not scenario.get("steps"):
            errors.append(f"{sid}: steps must be non-empty")
        if not isinstance(scenario.get("negativeCases"), list) or not scenario.get("negativeCases"):
            errors.append(f"{sid}: negativeCases must be non-empty")
        if not isinstance(scenario.get("expectedOutcome"), str) or not scenario.get("expectedOutcome", "").strip():
            errors.append(f"{sid}: expectedOutcome is required")
    if len(scenario_ids) != 61 or len(set(scenario_ids)) != 61:
        errors.append(f"clean Scenario catalogs must contain 61 unique IDs, found {len(scenario_ids)}")

    if current.get("status") != "ACTIVE_R3_REPAIRED_PENDING_FREEZE":
        errors.append("implementation-system-model structural status drifted")
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
    if current.get("scenarioSemanticAuditVersion") != 1:
        errors.append("scenarioSemanticAuditVersion must remain direct-stage v1")
    if current.get("scenarioSemanticAuditDigest") != EXPECTED_SEMANTIC_AUDIT_DIGEST:
        errors.append("direct semantic trace digest drifted")
    if current.get("sourceImplementationAllowed") is not False:
        errors.append("sourceImplementationAllowed must remain false during R3")
    if current.get("studioImplementationAllowed") is not False:
        errors.append("studioImplementationAllowed must remain false during R3")

    systems = current.get("systems", [])
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
    if len(system_ids) != 34 or len(system_ids) != len(set(system_ids)):
        errors.append("systems must contain 34 unique IDs")
    if len(system_names) != len(set(system_names)):
        errors.append("system names must be unique")
    if dict(group_counts) != EXPECTED_GROUP_COUNTS:
        errors.append(f"system group counts drifted: expected={EXPECTED_GROUP_COUNTS} actual={dict(group_counts)}")
    system_set = set(system_ids)
    if "A8" not in system_set:
        errors.append("A8 Domain Event Delivery Runtime is required")

    requirements = current.get("requirementCapabilities", [])
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
            errors.append(f"{rid}: systemRefs must contain at least two Systems")
            refs = []
        unknown = [ref for ref in refs if ref not in system_set]
        if unknown:
            errors.append(f"{rid}: unknown System refs {unknown}")
        for ref in refs:
            if ref in system_set:
                system_to_requirements[ref].add(rid)
        if not isinstance(source_refs, list) or not source_refs:
            errors.append(f"{rid}: sourceRefs must be non-empty")
        else:
            for ref in source_refs:
                if not isinstance(ref, str) or not (REPO_ROOT / ref).exists():
                    errors.append(f"{rid}: missing authority sourceRef {ref}")
    if len(req_ids) != 30 or len(req_ids) != len(set(req_ids)):
        errors.append("requirementCapabilities must contain 30 unique IDs")
    req_set = set(req_ids)
    unpressured = sorted(system_set - set(system_to_requirements))
    if unpressured:
        errors.append(f"Systems without Requirement Capability pressure: {unpressured}")

    stage_defs = current.get("scenarioSemanticStageDefinitions")
    if not isinstance(stage_defs, dict) or set(stage_defs) != ALLOWED_SEMANTIC_STAGES:
        errors.append(f"scenarioSemanticStageDefinitions must define exactly {sorted(ALLOWED_SEMANTIC_STAGES)}")

    traces = current.get("scenarioTrace", [])
    if not isinstance(traces, list):
        errors.append("scenarioTrace must be an array")
        traces = []
    trace_ids: list[str] = []
    used_requirements: set[str] = set()
    digest_input: list[dict] = []
    for trace in traces:
        if not isinstance(trace, dict):
            errors.append("scenarioTrace entry must be object")
            continue
        sid = trace.get("id")
        srefs = trace.get("systemRefs")
        rrefs = trace.get("requirementCapabilityRefs")
        stages = trace.get("semanticStages")
        if not isinstance(sid, str) or not sid:
            errors.append("scenarioTrace.id is required")
            continue
        trace_ids.append(sid)
        if not isinstance(srefs, list) or not srefs:
            errors.append(f"{sid}: systemRefs must be non-empty")
            srefs = []
        if not isinstance(rrefs, list) or not rrefs:
            errors.append(f"{sid}: requirementCapabilityRefs must be non-empty")
            rrefs = []
        if not isinstance(stages, list) or not stages:
            errors.append(f"{sid}: semanticStages must be non-empty")
            stages = []
        if len(stages) != len(set(stages)):
            errors.append(f"{sid}: semanticStages must be unique")
        if any(stage not in ALLOWED_SEMANTIC_STAGES for stage in stages):
            errors.append(f"{sid}: unknown semantic stage")
        if any(ref not in system_set for ref in srefs):
            errors.append(f"{sid}: unknown System ref")
        if any(ref not in req_set for ref in rrefs):
            errors.append(f"{sid}: unknown Requirement ref")
        used_requirements.update(ref for ref in rrefs if ref in req_set)

        ss = set(srefs)
        rr = set(rrefs)
        st = set(stages)
        if "MUTATION" in st and ("A3" not in ss or "REQ_ATOMIC_CONCURRENCY" not in rr):
            errors.append(f"{sid}: MUTATION requires A3 + REQ_ATOMIC_CONCURRENCY")
        if "EVENT" in st and (not {"A3", "A8"}.issubset(ss) or "REQ_COMMITTED_EVENT_PROPAGATION" not in rr):
            errors.append(f"{sid}: EVENT requires A3+A8 + REQ_COMMITTED_EVENT_PROPAGATION")
        if "PROJECTION" in st and (not {"A5", "A6"}.issubset(ss) or "REQ_VIEWER_SAFE_PROJECTION" not in rr):
            errors.append(f"{sid}: PROJECTION requires A5+A6 + REQ_VIEWER_SAFE_PROJECTION")
        if "RECOVERY" in st:
            if not ({"A6", "A7"} & ss):
                errors.append(f"{sid}: RECOVERY requires A6 or A7")
            if not ({"REQ_RECOVERY_ROLLBACK", "REQ_SESSION_PLAYABILITY"} & rr):
                errors.append(f"{sid}: RECOVERY requires recovery/session requirement pressure")
        if "HUMAN" in st and not ({"C1", "C2", "C3", "U1", "U2"} & ss):
            errors.append(f"{sid}: HUMAN requires client/presentation/authoring System")

        digest_input.append({
            "id": sid,
            "requirementCapabilityRefs": rrefs,
            "systemRefs": srefs,
            "semanticStages": stages,
        })

    if len(trace_ids) != 61 or len(trace_ids) != len(set(trace_ids)):
        errors.append("scenarioTrace must contain 61 unique IDs")
    if set(trace_ids) != set(scenario_ids):
        errors.append("scenarioTrace ID set must exactly match clean Base+Expanded Scenario catalogs")
    unused_requirements = sorted(req_set - used_requirements)
    if unused_requirements:
        errors.append(f"Requirement Capabilities unused by all scenarios: {unused_requirements}")

    payload = json.dumps(digest_input, ensure_ascii=False, separators=(",", ":"))
    actual_digest = "sha256:" + hashlib.sha256(payload.encode("utf-8")).hexdigest()
    if actual_digest != EXPECTED_SEMANTIC_AUDIT_DIGEST:
        errors.append(f"direct semantic trace digest mismatch: expected={EXPECTED_SEMANTIC_AUDIT_DIGEST} actual={actual_digest}")

    semantics = current.get("executionLayerSemantics")
    if not isinstance(semantics, dict):
        errors.append("executionLayerSemantics is required")
    else:
        if "classification" not in str(semantics.get("repositoryLogic", "")):
            errors.append("repositoryLogic must remain a classification")
        if "mandatory pre-Studio foundation subset" not in str(semantics.get("e0CoreEngine", "")):
            errors.append("e0CoreEngine must remain the mandatory pre-Studio foundation subset")

    e0 = current.get("e0RequiredSystemSeams", [])
    deferred = current.get("deferredRepositoryFeatureSystems", [])
    if not isinstance(e0, list) or not isinstance(deferred, list):
        errors.append("E0/deferred System lists are required")
        e0, deferred = [], []
    if set(e0) | set(deferred) != system_set:
        errors.append("every System must be E0-required seam or deferred repository feature")
    if set(e0) & set(deferred):
        errors.append("E0 and deferred System sets must not overlap")
    if set(deferred) != EXPECTED_DEFERRED:
        errors.append(f"deferred repository features must be {sorted(EXPECTED_DEFERRED)}")
    if not REQUIRED_E0.issubset(set(e0)):
        errors.append(f"critical E0 seams missing: {sorted(REQUIRED_E0 - set(e0))}")

    ready = current.get("readyGateComposition", {})
    if ready.get("finalOwner") != "A1" or ready.get("inputs") != EXPECTED_READY:
        errors.append("Ready Gate must remain typed A7/A6/W7/C1 evidence composed solely by A1")

    reservations = current.get("reservationTaxonomy")
    actual_reservations: dict[str, str] = {}
    if isinstance(reservations, list):
        for item in reservations:
            if isinstance(item, dict) and isinstance(item.get("kind"), str) and isinstance(item.get("owner"), str):
                actual_reservations[item["kind"]] = item["owner"]
    if actual_reservations != EXPECTED_RESERVATIONS:
        errors.append(f"reservation taxonomy drifted: expected={EXPECTED_RESERVATIONS} actual={actual_reservations}")

    durability = current.get("eventDeliveryDurability")
    if not isinstance(durability, dict):
        errors.append("eventDeliveryDurability must be an object")
    else:
        expected_durability = {"outboxSemanticOwner": "A3", "deliverySemanticOwner": "A8", "durabilityMechanismOwner": "A7"}
        for key, expected in expected_durability.items():
            if durability.get(key) != expected:
                errors.append(f"eventDeliveryDurability.{key} must be {expected}")
        if "A8 never uses StorageAdapter directly" not in str(durability.get("rule", "")):
            errors.append("eventDeliveryDurability must forbid A8 direct StorageAdapter use")

    providers = current.get("platformProviderContracts")
    provider_ids: set[str] = set()
    storage_consumers = None
    if not isinstance(providers, list):
        errors.append("platformProviderContracts must be an array")
    else:
        for item in providers:
            if not isinstance(item, dict) or not isinstance(item.get("id"), str):
                errors.append("platformProviderContracts entry requires id")
                continue
            provider_ids.add(item["id"])
            if item.get("testOwner") != "S2":
                errors.append(f"{item['id']}: testOwner must be S2")
            if item["id"] == "STORAGE_ADAPTER":
                storage_consumers = item.get("productionConsumers")
    if provider_ids != EXPECTED_PROVIDER_IDS:
        errors.append(f"platform provider set drifted: expected={sorted(EXPECTED_PROVIDER_IDS)} actual={sorted(provider_ids)}")
    if storage_consumers != ["A7"]:
        errors.append("STORAGE_ADAPTER productionConsumers must remain exactly [A7]")

    model_text = MODEL_DOC.read_text(encoding="utf-8")
    systems_text = SYSTEMS_DOC.read_text(encoding="utf-8")
    policy_text = COVERAGE_POLICY.read_text(encoding="utf-8")
    task_text = ACTIVE_TASK.read_text(encoding="utf-8")
    agents_text = AGENTS.read_text(encoding="utf-8")
    markers = [
        ("IMPLEMENTATION-MODEL.md", model_text, "SYSTEM MODEL = V2 · 34 SYSTEMS · REPAIRED"),
        ("IMPLEMENTATION-MODEL.md", model_text, "SEMANTIC AUDIT = V3 · VALIDATED · CLEAN SOURCE BOUND"),
        ("IMPLEMENTATION-MODEL.md", model_text, "A8 delivery semantics → A7 durability seam"),
        ("SYSTEMS.md", systems_text, "34 System Responsibility Model"),
        ("SYSTEMS.md", systems_text, "A8 | Domain Event Delivery Runtime"),
        ("SYSTEMS.md", systems_text, "Scenario Semantic Audit v3"),
        ("Coverage Policy", policy_text, "SEMANTIC_AUDIT_V3_VALIDATED"),
        ("Active Task", task_text, "- status: `R3_VALIDATED_AWAITING_FREEZE_DECISION`"),
        ("Active Task", task_text, "scenarioSemanticAuditV3: `V3_CLEAN_SOURCE_BOUND_61_OF_61_VALIDATED`"),
        ("Active Task", task_text, "sourceImplementationAllowed: `false`"),
        ("Active Task", task_text, "studioImplementationAllowed: `false`"),
        ("AGENTS.md", agents_text, "NEXT = USER R3 FREEZE DECISION"),
    ]
    for label, text, marker in markers:
        if marker not in text:
            errors.append(f"{label}: missing marker {marker}")
    for sid, name in zip(system_ids, system_names):
        if f"| {sid} | {name} |" not in systems_text:
            errors.append(f"SYSTEMS.md missing System table row for {sid} {name}")

    if errors:
        return fail(errors)

    stage_counts = Counter(stage for trace in traces for stage in trace.get("semanticStages", []))
    print(
        "RVTT architecture coverage validation passed: "
        f"systems={len(system_ids)}; requirement_capabilities={len(req_ids)}; "
        f"scenarios={len(trace_ids)} (base={len(base_scenarios)}, expanded={len(expanded_scenarios)}); "
        f"semantic_stages={dict(sorted(stage_counts.items()))}; direct_semantic_digest=PASS; "
        "event_delivery=A8; event_durability=A7; ready_gate=A1; reservation_taxonomy=PASS; provider_contracts=PASS; "
        f"e0_required_seams={len(e0)}; deferred_repository_features={len(deferred)}; "
        "clean_scenario_authority=PASS; source=BLOCKED; studio=BLOCKED; R3=VALIDATED_NOT_FROZEN"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
