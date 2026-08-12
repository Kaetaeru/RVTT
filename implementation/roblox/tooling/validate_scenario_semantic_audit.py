#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
BASE = ROOT / "manifests/scenario-base-catalog.json"
EXPANDED = ROOT / "manifests/architecture-scenarios.json"
MODEL = ROOT / "manifests/implementation-system-model.json"
AUDIT = ROOT / "manifests/scenario-semantic-audit.json"

EXPECTED_ENTRY_EXPANSIONS = {
    "LOCAL": {"systemRefs": [], "requirementRefs": []},
    "COMMAND": {"systemRefs": ["A2", "A1"], "requirementRefs": ["REQ_REQUEST_PROTOCOL", "REQ_CONTROL_PERMISSION"]},
    "READ_REQUEST": {"systemRefs": ["A2"], "requirementRefs": ["REQ_REQUEST_PROTOCOL"]},
    "SYNC_CONTROL": {"systemRefs": ["A6", "A1"], "requirementRefs": ["REQ_SESSION_PLAYABILITY"]},
    "SERVER_TRIGGER": {"systemRefs": [], "requirementRefs": []},
    "EVENT_TRIGGER": {"systemRefs": ["A8"], "requirementRefs": ["REQ_COMMITTED_EVENT_PROPAGATION"]},
    "TEST_HARNESS": {"systemRefs": ["S2"], "requirementRefs": ["REQ_DIAGNOSTICS_REPRODUCIBILITY"]},
}
EXPECTED_RECOVERY_EXPANSIONS = {
    "CLIENT_RESYNC": {"systemRefs": ["A6"], "requirementRefs": ["REQ_RECOVERY_ROLLBACK", "REQ_VIEWER_SAFE_PROJECTION"]},
    "RECONNECT": {"systemRefs": ["A1", "A6"], "requirementRefs": ["REQ_SESSION_PLAYABILITY", "REQ_RECOVERY_ROLLBACK"]},
    "SERVER_RESTART": {"systemRefs": ["A7"], "requirementRefs": ["REQ_RECOVERY_ROLLBACK"]},
    "ROLLBACK_BRANCH": {"systemRefs": ["A7", "A1"], "requirementRefs": ["REQ_RECOVERY_ROLLBACK"]},
    "RETRY_AFTER_RESTART": {"systemRefs": ["A7"], "requirementRefs": ["REQ_RECOVERY_ROLLBACK"]},
    "LAST_KNOWN_GOOD": {"systemRefs": [], "requirementRefs": []},
    "CONTROL_FAILOVER": {"systemRefs": ["A1"], "requirementRefs": ["REQ_SESSION_PLAYABILITY", "REQ_CONTROL_PERMISSION"]},
}
REQUIRED_RECOVERY_SENTINELS = {
    "SCN_ATTACK_REACTION_RESOLUTION": {"RECONNECT"},
    "SCN_CHARACTER_SHEET_LIVE_DAMAGE_SYNC": {"CLIENT_RESYNC"},
    "SCN_SCENE_CANDIDATE_TEST_PUBLISH": {"LAST_KNOWN_GOOD"},
    "SCN_DM_RECOVERY_REVIEW_BRANCH": {"SERVER_RESTART", "ROLLBACK_BRANCH", "CLIENT_RESYNC"},
}
SCHEMA_KEYS = [
    "mutationSemantic",
    "entryKindDefinitions",
    "entryBoundaryExpansion",
    "recoveryKindDefinitions",
    "recoveryBoundaryExpansion",
    "lastKnownGoodOwnerCandidates",
    "scenarioAudit",
]
FORBIDDEN_BASE_SCENARIO_KEYS = {"capabilityRefs", "systemRefs", "moduleRefs", "knownGapRefs"}


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def blob_sha(path: Path) -> str | None:
    rel = path.relative_to(REPO_ROOT).as_posix()
    proc = subprocess.run(
        ["git", "rev-parse", f"HEAD:{rel}"],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    return proc.stdout.strip() if proc.returncode == 0 else None


def digest(value: object) -> str:
    payload = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return "sha256:" + hashlib.sha256(payload.encode("utf-8")).hexdigest()


def fail(errors: list[str]) -> int:
    print("RVTT scenario semantic audit validation failed:")
    for error in errors:
        print("-", error)
    return 1


def main() -> int:
    errors: list[str] = []
    try:
        base = load(BASE)
        expanded = load(EXPANDED)
        model = load(MODEL)
        audit = load(AUDIT)
    except Exception as exc:
        return fail([str(exc)])

    if base.get("registryId") != "rvtt-scenario-base-catalog-v1":
        errors.append("base scenario source must be the clean rvtt-scenario-base-catalog-v1 registry")
    base_policy = base.get("policy") if isinstance(base.get("policy"), dict) else {}
    if base_policy.get("legacyGreenfieldReferencesExcluded") is not True:
        errors.append("base scenario catalog must exclude legacy Greenfield references")

    base_scenarios = base.get("scenarios", [])
    expanded_scenarios = expanded.get("scenarios", [])
    if not isinstance(base_scenarios, list) or len(base_scenarios) != 14:
        errors.append(f"canonical base scenario catalog must contain 14 scenarios, found {len(base_scenarios) if isinstance(base_scenarios, list) else 'non-list'}")
        base_scenarios = []
    if not isinstance(expanded_scenarios, list) or len(expanded_scenarios) != 47:
        errors.append(f"expanded scenario catalog must contain 47 scenarios, found {len(expanded_scenarios) if isinstance(expanded_scenarios, list) else 'non-list'}")
        expanded_scenarios = []

    for scenario in base_scenarios:
        if not isinstance(scenario, dict):
            errors.append("base scenario entry must be object")
            continue
        forbidden = sorted(FORBIDDEN_BASE_SCENARIO_KEYS & set(scenario))
        if forbidden:
            errors.append(f"{scenario.get('id', '<missing>')}: canonical base scenario leaked legacy mapping keys {forbidden}")

    source_scenarios = [*base_scenarios, *expanded_scenarios]
    source_ids = [s.get("id") for s in source_scenarios if isinstance(s, dict)]
    if len(source_ids) != 61 or len(set(source_ids)) != 61:
        errors.append(f"source scenario catalog must contain 61 unique ids, found {len(source_ids)}")
    for scenario in source_scenarios:
        if not isinstance(scenario, dict):
            errors.append("source scenario entry must be object")
            continue
        sid = scenario.get("id", "<missing>")
        if not isinstance(scenario.get("steps"), list) or not scenario.get("steps"):
            errors.append(f"{sid}: source steps must be non-empty")
        if not isinstance(scenario.get("expectedOutcome"), str) or not scenario.get("expectedOutcome", "").strip():
            errors.append(f"{sid}: source expectedOutcome must be non-empty")
        if not isinstance(scenario.get("negativeCases"), list) or not scenario.get("negativeCases"):
            errors.append(f"{sid}: source negativeCases must be non-empty")

    if audit.get("schemaVersion") != 2:
        errors.append("audit schemaVersion must be 2")
    if audit.get("registryId") != "rvtt-scenario-semantic-audit-v2":
        errors.append("audit registryId must be rvtt-scenario-semantic-audit-v2")
    if audit.get("status") != "ACTIVE_R3_VALIDATED_AWAITING_FREEZE":
        errors.append("audit status must be ACTIVE_R3_VALIDATED_AWAITING_FREEZE after full R3 validation")
    if audit.get("scenarioCount") != 61:
        errors.append("audit scenarioCount must be 61")

    binding = audit.get("sourceBinding") if isinstance(audit.get("sourceBinding"), dict) else {}
    actual_base_sha = blob_sha(BASE)
    actual_expanded_sha = blob_sha(EXPANDED)
    if binding.get("baseScenarioBlobSha") != actual_base_sha:
        errors.append(f"base scenario body changed without semantic re-audit: expected={binding.get('baseScenarioBlobSha')} actual={actual_base_sha}")
    if binding.get("expandedScenarioBlobSha") != actual_expanded_sha:
        errors.append(f"expanded scenario body changed without semantic re-audit: expected={binding.get('expandedScenarioBlobSha')} actual={actual_expanded_sha}")

    trace_digest = model.get("scenarioSemanticAuditDigest")
    if binding.get("scenarioTraceDigest") != trace_digest:
        errors.append("sourceBinding.scenarioTraceDigest must equal implementation model scenarioSemanticAuditDigest")

    systems = model.get("systems", [])
    requirements = model.get("requirementCapabilities", [])
    traces = model.get("scenarioTrace", [])
    system_ids = {x.get("id") for x in systems if isinstance(x, dict) and isinstance(x.get("id"), str)}
    req_ids = {x.get("id") for x in requirements if isinstance(x, dict) and isinstance(x.get("id"), str)}
    trace_by_id = {x.get("id"): x for x in traces if isinstance(x, dict) and isinstance(x.get("id"), str)}
    if set(trace_by_id) != set(source_ids):
        errors.append("implementation model scenarioTrace IDs must exactly match canonical source scenario IDs")

    entry_defs = audit.get("entryKindDefinitions")
    recovery_defs = audit.get("recoveryKindDefinitions")
    if not isinstance(entry_defs, dict) or set(entry_defs) != set(EXPECTED_ENTRY_EXPANSIONS):
        errors.append("entryKindDefinitions keys drifted")
    if not isinstance(recovery_defs, dict) or set(recovery_defs) != set(EXPECTED_RECOVERY_EXPANSIONS):
        errors.append("recoveryKindDefinitions keys drifted")
    if audit.get("entryBoundaryExpansion") != EXPECTED_ENTRY_EXPANSIONS:
        errors.append("entryBoundaryExpansion must exactly preserve System + Requirement ingress semantics")
    if audit.get("recoveryBoundaryExpansion") != EXPECTED_RECOVERY_EXPANSIONS:
        errors.append("recoveryBoundaryExpansion must exactly preserve typed recovery semantics")

    for mapping_name, mapping in (("entryBoundaryExpansion", EXPECTED_ENTRY_EXPANSIONS), ("recoveryBoundaryExpansion", EXPECTED_RECOVERY_EXPANSIONS)):
        for kind, expansion in mapping.items():
            unknown_s = [x for x in expansion["systemRefs"] if x not in system_ids]
            unknown_r = [x for x in expansion["requirementRefs"] if x not in req_ids]
            if unknown_s:
                errors.append(f"{mapping_name}.{kind}: unknown systems {unknown_s}")
            if unknown_r:
                errors.append(f"{mapping_name}.{kind}: unknown requirements {unknown_r}")

    mutation = audit.get("mutationSemantic")
    if not isinstance(mutation, dict) or mutation.get("stage") != "MUTATION":
        errors.append("mutationSemantic must define MUTATION")
    else:
        meaning = mutation.get("meaning", "")
        if not isinstance(meaning, str) or "transactional authoritative domain/source commit" not in meaning:
            errors.append("mutationSemantic must scope MUTATION to A3 transactional authoritative domain/source commit")
        if mutation.get("eventWithoutMutationAllowed") is not True:
            errors.append("mutationSemantic.eventWithoutMutationAllowed must be true")

    lkg_candidates = set(audit.get("lastKnownGoodOwnerCandidates", []))
    if not lkg_candidates or not lkg_candidates.issubset(system_ids):
        errors.append("lastKnownGoodOwnerCandidates must be a non-empty subset of System IDs")

    audit_entries = audit.get("scenarioAudit")
    if not isinstance(audit_entries, list):
        errors.append("scenarioAudit must be an array")
        audit_entries = []
    audit_by_id = {x.get("id"): x for x in audit_entries if isinstance(x, dict) and isinstance(x.get("id"), str)}
    if len(audit_entries) != 61 or len(audit_by_id) != 61 or set(audit_by_id) != set(source_ids):
        errors.append("scenarioAudit must contain exactly the 61 canonical source scenario IDs")

    entry_counts: Counter[str] = Counter()
    recovery_counts: Counter[str] = Counter()
    effective_recovery_scenarios = 0

    for sid in source_ids:
        item = audit_by_id.get(sid, {})
        entry_kinds = item.get("entryKinds")
        recovery_kinds = item.get("recoveryKinds")
        if not isinstance(entry_kinds, list) or not entry_kinds:
            errors.append(f"{sid}: entryKinds must be non-empty")
            entry_kinds = []
        if not isinstance(recovery_kinds, list):
            errors.append(f"{sid}: recoveryKinds must be an array")
            recovery_kinds = []
        if len(entry_kinds) != len(set(entry_kinds)):
            errors.append(f"{sid}: entryKinds must be unique")
        if len(recovery_kinds) != len(set(recovery_kinds)):
            errors.append(f"{sid}: recoveryKinds must be unique")
        unknown_entry = [x for x in entry_kinds if x not in EXPECTED_ENTRY_EXPANSIONS]
        unknown_recovery = [x for x in recovery_kinds if x not in EXPECTED_RECOVERY_EXPANSIONS]
        if unknown_entry:
            errors.append(f"{sid}: unknown entryKinds {unknown_entry}")
        if unknown_recovery:
            errors.append(f"{sid}: unknown recoveryKinds {unknown_recovery}")
        entry_counts.update(x for x in entry_kinds if x in EXPECTED_ENTRY_EXPANSIONS)
        recovery_counts.update(x for x in recovery_kinds if x in EXPECTED_RECOVERY_EXPANSIONS)

        trace = trace_by_id.get(sid, {})
        effective_systems = set(trace.get("systemRefs", []))
        effective_requirements = set(trace.get("requirementCapabilityRefs", []))
        stages = set(trace.get("semanticStages", []))
        for kind in entry_kinds:
            expansion = EXPECTED_ENTRY_EXPANSIONS.get(kind, {"systemRefs": [], "requirementRefs": []})
            effective_systems.update(expansion["systemRefs"])
            effective_requirements.update(expansion["requirementRefs"])
        for kind in recovery_kinds:
            expansion = EXPECTED_RECOVERY_EXPANSIONS.get(kind, {"systemRefs": [], "requirementRefs": []})
            effective_systems.update(expansion["systemRefs"])
            effective_requirements.update(expansion["requirementRefs"])

        if "MUTATION" in stages and "A3" not in effective_systems:
            errors.append(f"{sid}: effective MUTATION path must include A3")
        if entry_kinds == ["LOCAL"] and "MUTATION" in stages:
            errors.append(f"{sid}: LOCAL-only scenario cannot claim transactional MUTATION")
        if recovery_kinds:
            effective_recovery_scenarios += 1
        if "RECOVERY" in stages and not recovery_kinds:
            errors.append(f"{sid}: v1 RECOVERY stage requires typed recoveryKinds in v2")
        if "LAST_KNOWN_GOOD" in recovery_kinds and not (effective_systems & lkg_candidates):
            errors.append(f"{sid}: LAST_KNOWN_GOOD requires a direct/effective LKG owner candidate")
        if not effective_systems.issubset(system_ids):
            errors.append(f"{sid}: effective semantic path introduced unknown System")
        if not effective_requirements.issubset(req_ids):
            errors.append(f"{sid}: effective semantic path introduced unknown Requirement Capability")

    for sid, required in REQUIRED_RECOVERY_SENTINELS.items():
        actual = set(audit_by_id.get(sid, {}).get("recoveryKinds", []))
        if not required.issubset(actual):
            errors.append(f"{sid}: required recovery sentinel missing {sorted(required - actual)}")

    schema_payload = {key: audit.get(key) for key in SCHEMA_KEYS}
    actual_schema_digest = digest(schema_payload)
    if binding.get("semanticSchemaDigest") != actual_schema_digest:
        errors.append(f"semantic schema digest mismatch: expected={binding.get('semanticSchemaDigest')} actual={actual_schema_digest}")

    combined_input = (
        f"base:{actual_base_sha}\n"
        f"expanded:{actual_expanded_sha}\n"
        f"trace:{trace_digest}\n"
        f"schema:{actual_schema_digest}"
    )
    actual_combined = "sha256:" + hashlib.sha256(combined_input.encode("utf-8")).hexdigest()
    if binding.get("combinedAuditDigest") != actual_combined:
        errors.append(f"combined scenario/body/trace/schema audit digest mismatch: expected={binding.get('combinedAuditDigest')} actual={actual_combined}")

    declared_recovery_count = audit.get("effectiveRecoveryScenarioCount")
    if declared_recovery_count != effective_recovery_scenarios:
        errors.append(f"effectiveRecoveryScenarioCount must be {effective_recovery_scenarios}, found {declared_recovery_count}")

    if errors:
        return fail(errors)

    print(
        "RVTT scenario semantic audit passed: "
        f"base=14; expanded=47; scenarios={len(audit_by_id)}; effective_recovery_scenarios={effective_recovery_scenarios}; "
        f"entryKinds={dict(sorted(entry_counts.items()))}; recoveryKinds={dict(sorted(recovery_counts.items()))}; "
        f"schemaDigest={actual_schema_digest}; combinedDigest={actual_combined}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
