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
EXPANDED = ROOT / "manifests/scenario-expanded-catalog.json"
LEGACY_EXPANDED = ROOT / "manifests/architecture-scenarios.json"
MODEL = ROOT / "manifests/implementation-system-model.json"
AUDIT_V2 = ROOT / "manifests/scenario-semantic-audit.json"
AUDIT_V3 = ROOT / "manifests/scenario-semantic-audit-v3.json"

FORBIDDEN_SCENARIO_KEYS = {"capabilityRefs", "systemRefs", "moduleRefs", "knownGapRefs"}
BODY_KEYS = ("id", "phase", "steps", "expectedOutcome", "negativeCases")
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


def body_projection(scenario: dict) -> dict:
    return {key: scenario.get(key) for key in BODY_KEYS}


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
        legacy_expanded = load(LEGACY_EXPANDED)
        model = load(MODEL)
        audit_v2 = load(AUDIT_V2)
        audit_v3 = load(AUDIT_V3)
    except Exception as exc:
        return fail([str(exc)])

    if base.get("registryId") != "rvtt-scenario-base-catalog-v1":
        errors.append("canonical Base source must be rvtt-scenario-base-catalog-v1")
    if expanded.get("registryId") != "rvtt-scenario-expanded-catalog-v1":
        errors.append("canonical Expanded source must be rvtt-scenario-expanded-catalog-v1")
    for label, catalog in (("Base", base), ("Expanded", expanded)):
        policy = catalog.get("policy") if isinstance(catalog.get("policy"), dict) else {}
        if policy.get("legacyGreenfieldReferencesExcluded") is not True:
            errors.append(f"{label} catalog must exclude legacy Greenfield references")

    base_scenarios = base.get("scenarios", [])
    expanded_scenarios = expanded.get("scenarios", [])
    legacy_expanded_scenarios = legacy_expanded.get("scenarios", [])
    if not isinstance(base_scenarios, list) or len(base_scenarios) != 14:
        errors.append("canonical Base catalog must contain exactly 14 scenarios")
        base_scenarios = []
    if not isinstance(expanded_scenarios, list) or len(expanded_scenarios) != 47:
        errors.append("canonical Expanded catalog must contain exactly 47 scenarios")
        expanded_scenarios = []
    if not isinstance(legacy_expanded_scenarios, list) or len(legacy_expanded_scenarios) != 47:
        errors.append("historical Expanded registry must still contain 47 evidence scenarios")
        legacy_expanded_scenarios = []

    for label, scenarios in (("Base", base_scenarios), ("Expanded", expanded_scenarios)):
        for scenario in scenarios:
            if not isinstance(scenario, dict):
                errors.append(f"{label} scenario entry must be object")
                continue
            sid = scenario.get("id", "<missing>")
            forbidden = sorted(FORBIDDEN_SCENARIO_KEYS & set(scenario))
            if forbidden:
                errors.append(f"{sid}: clean {label} catalog leaked legacy mapping keys {forbidden}")
            if not isinstance(scenario.get("steps"), list) or not scenario.get("steps"):
                errors.append(f"{sid}: steps must be non-empty")
            if not isinstance(scenario.get("expectedOutcome"), str) or not scenario.get("expectedOutcome", "").strip():
                errors.append(f"{sid}: expectedOutcome must be non-empty")
            if not isinstance(scenario.get("negativeCases"), list) or not scenario.get("negativeCases"):
                errors.append(f"{sid}: negativeCases must be non-empty")

    expected_base_registry = "implementation/roblox/manifests/scenario-base-catalog.json"
    if legacy_expanded.get("baseRegistry") != expected_base_registry:
        errors.append("historical architecture-scenarios.baseRegistry must point to canonical Base catalog")

    clean_projection = [body_projection(x) for x in expanded_scenarios if isinstance(x, dict)]
    legacy_projection = [body_projection(x) for x in legacy_expanded_scenarios if isinstance(x, dict)]
    if clean_projection != legacy_projection:
        errors.append("clean Expanded catalog must exactly preserve the semantic body projection of historical architecture-scenarios")

    source_scenarios = [*base_scenarios, *expanded_scenarios]
    source_ids = [x.get("id") for x in source_scenarios if isinstance(x, dict)]
    if len(source_ids) != 61 or len(set(source_ids)) != 61:
        errors.append("clean Scenario catalogs must contain exactly 61 unique IDs")

    if audit_v2.get("schemaVersion") != 2 or audit_v2.get("registryId") != "rvtt-scenario-semantic-audit-v2":
        errors.append("v2 semantic classification audit identity drifted")
    if audit_v2.get("status") != "ACTIVE_R3_VALIDATED_AWAITING_FREEZE":
        errors.append("v2 semantic classification audit must remain validated awaiting Freeze")
    if audit_v3.get("schemaVersion") != 3 or audit_v3.get("registryId") != "rvtt-scenario-semantic-audit-v3":
        errors.append("effective v3 semantic audit identity drifted")
    if audit_v3.get("status") != "ACTIVE_R3_VALIDATED_AWAITING_FREEZE":
        errors.append("effective v3 semantic audit must remain validated awaiting Freeze")
    if audit_v3.get("scenarioCount") != 61:
        errors.append("effective v3 semantic audit scenarioCount must be 61")

    systems = model.get("systems", [])
    requirements = model.get("requirementCapabilities", [])
    traces = model.get("scenarioTrace", [])
    system_ids = {x.get("id") for x in systems if isinstance(x, dict) and isinstance(x.get("id"), str)}
    req_ids = {x.get("id") for x in requirements if isinstance(x, dict) and isinstance(x.get("id"), str)}
    trace_by_id = {x.get("id"): x for x in traces if isinstance(x, dict) and isinstance(x.get("id"), str)}
    if set(trace_by_id) != set(source_ids):
        errors.append("implementation model scenarioTrace IDs must exactly match clean Scenario catalog IDs")

    entry_defs = audit_v2.get("entryKindDefinitions")
    recovery_defs = audit_v2.get("recoveryKindDefinitions")
    if not isinstance(entry_defs, dict) or set(entry_defs) != set(EXPECTED_ENTRY_EXPANSIONS):
        errors.append("v2 entryKindDefinitions keys drifted")
    if not isinstance(recovery_defs, dict) or set(recovery_defs) != set(EXPECTED_RECOVERY_EXPANSIONS):
        errors.append("v2 recoveryKindDefinitions keys drifted")
    if audit_v2.get("entryBoundaryExpansion") != EXPECTED_ENTRY_EXPANSIONS:
        errors.append("v2 entryBoundaryExpansion drifted")
    if audit_v2.get("recoveryBoundaryExpansion") != EXPECTED_RECOVERY_EXPANSIONS:
        errors.append("v2 recoveryBoundaryExpansion drifted")

    mutation = audit_v2.get("mutationSemantic")
    if not isinstance(mutation, dict) or mutation.get("stage") != "MUTATION":
        errors.append("v2 mutationSemantic must define MUTATION")
    else:
        meaning = mutation.get("meaning", "")
        if not isinstance(meaning, str) or "transactional authoritative domain/source commit" not in meaning:
            errors.append("MUTATION must remain scoped to A3 transactional authoritative domain/source commit")
        if mutation.get("eventWithoutMutationAllowed") is not True:
            errors.append("mutationSemantic.eventWithoutMutationAllowed must remain true")

    lkg_candidates = set(audit_v2.get("lastKnownGoodOwnerCandidates", []))
    if not lkg_candidates or not lkg_candidates.issubset(system_ids):
        errors.append("lastKnownGoodOwnerCandidates must remain a non-empty System subset")

    audit_entries = audit_v2.get("scenarioAudit", [])
    audit_by_id = {x.get("id"): x for x in audit_entries if isinstance(x, dict) and isinstance(x.get("id"), str)}
    if not isinstance(audit_entries, list) or len(audit_entries) != 61 or len(audit_by_id) != 61 or set(audit_by_id) != set(source_ids):
        errors.append("v2 scenarioAudit must contain exactly the 61 clean Scenario IDs")

    recovery_counts: Counter[str] = Counter()
    effective_recovery_scenarios = 0
    for sid in source_ids:
        item = audit_by_id.get(sid, {})
        entry_kinds = item.get("entryKinds", [])
        recovery_kinds = item.get("recoveryKinds", [])
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
            recovery_counts[kind] += 1

        if "MUTATION" in stages and "A3" not in effective_systems:
            errors.append(f"{sid}: effective MUTATION path must include A3")
        if entry_kinds == ["LOCAL"] and "MUTATION" in stages:
            errors.append(f"{sid}: LOCAL-only scenario cannot claim transactional MUTATION")
        if recovery_kinds:
            effective_recovery_scenarios += 1
        if "RECOVERY" in stages and not recovery_kinds:
            errors.append(f"{sid}: v1 RECOVERY stage requires typed recoveryKinds")
        if "LAST_KNOWN_GOOD" in recovery_kinds and not (effective_systems & lkg_candidates):
            errors.append(f"{sid}: LAST_KNOWN_GOOD requires an LKG owner candidate")
        if not effective_systems.issubset(system_ids):
            errors.append(f"{sid}: effective semantic path introduced unknown System")
        if not effective_requirements.issubset(req_ids):
            errors.append(f"{sid}: effective semantic path introduced unknown Requirement Capability")

    for sid, required in REQUIRED_RECOVERY_SENTINELS.items():
        actual = set(audit_by_id.get(sid, {}).get("recoveryKinds", []))
        if not required.issubset(actual):
            errors.append(f"{sid}: required recovery sentinel missing {sorted(required - actual)}")

    schema_payload = {key: audit_v2.get(key) for key in SCHEMA_KEYS}
    actual_schema_digest = digest(schema_payload)
    v2_binding = audit_v2.get("sourceBinding") if isinstance(audit_v2.get("sourceBinding"), dict) else {}
    if v2_binding.get("semanticSchemaDigest") != actual_schema_digest:
        errors.append("v2 semantic schema digest no longer matches classification/schema content")

    binding = audit_v3.get("sourceBinding") if isinstance(audit_v3.get("sourceBinding"), dict) else {}
    expected_paths = {
        "baseScenarioPath": "implementation/roblox/manifests/scenario-base-catalog.json",
        "expandedScenarioPath": "implementation/roblox/manifests/scenario-expanded-catalog.json",
        "legacyExpandedEvidencePath": "implementation/roblox/manifests/architecture-scenarios.json",
        "directModelPath": "implementation/roblox/manifests/implementation-system-model.json",
        "semanticClassificationAuditV2Path": "implementation/roblox/manifests/scenario-semantic-audit.json",
    }
    for key, expected in expected_paths.items():
        if binding.get(key) != expected:
            errors.append(f"v3 sourceBinding.{key} must be {expected}")

    actual_base_sha = blob_sha(BASE)
    actual_expanded_sha = blob_sha(EXPANDED)
    actual_v2_sha = blob_sha(AUDIT_V2)
    trace_digest = model.get("scenarioSemanticAuditDigest")
    if binding.get("baseScenarioBlobSha") != actual_base_sha:
        errors.append("v3 Base catalog blob binding drifted")
    if binding.get("expandedScenarioBlobSha") != actual_expanded_sha:
        errors.append("v3 Expanded catalog blob binding drifted")
    if binding.get("semanticClassificationAuditV2BlobSha") != actual_v2_sha:
        errors.append("v3 v2-classification audit blob binding drifted")
    if binding.get("scenarioTraceDigest") != trace_digest:
        errors.append("v3 scenarioTraceDigest must match implementation model")
    if binding.get("semanticSchemaDigest") != actual_schema_digest:
        errors.append("v3 semanticSchemaDigest must match v2 semantic schema")

    combined_input = (
        f"base:{actual_base_sha}\n"
        f"expanded:{actual_expanded_sha}\n"
        f"trace:{trace_digest}\n"
        f"v2audit:{actual_v2_sha}\n"
        f"schema:{actual_schema_digest}"
    )
    actual_combined = "sha256:" + hashlib.sha256(combined_input.encode("utf-8")).hexdigest()
    if binding.get("combinedAuditDigest") != actual_combined:
        errors.append(f"v3 combined audit digest mismatch: expected={binding.get('combinedAuditDigest')} actual={actual_combined}")

    if effective_recovery_scenarios != 27:
        errors.append(f"effective typed recovery Scenario count must remain 27, found {effective_recovery_scenarios}")
    if audit_v2.get("effectiveRecoveryScenarioCount") != 27 or audit_v3.get("effectiveRecoveryScenarioCount") != 27:
        errors.append("v2/v3 effectiveRecoveryScenarioCount must both be 27")

    policy = audit_v3.get("policy") if isinstance(audit_v3.get("policy"), dict) else {}
    required_policy = {
        "v2SemanticClassificationPreserved": True,
        "cleanCatalogsForbidLegacyMappingKeys": True,
        "legacyExpandedRegistryHistoricalOnly": True,
        "legacyExpandedProjectionMustMatchCleanExpanded": True,
        "scenarioMeaningChanged": False,
    }
    if policy != required_policy:
        errors.append("v3 source-hygiene policy drifted")

    if errors:
        return fail(errors)

    print(
        "RVTT scenario semantic audit validation passed: "
        "clean_base=14; clean_expanded=47; scenarios=61; legacy_expanded_projection=EQUIVALENT; "
        f"recovery_scenarios={effective_recovery_scenarios}; recovery_kinds={dict(sorted(recovery_counts.items()))}; "
        "v2_semantic_classification=PASS; v3_clean_source_binding=PASS; R3=VALIDATED_NOT_FROZEN"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
