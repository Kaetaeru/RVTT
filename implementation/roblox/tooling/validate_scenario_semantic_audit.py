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
BASE = ROOT / "manifests/architecture-coverage.json"
EXPANDED = ROOT / "manifests/architecture-scenarios.json"
MODEL = ROOT / "manifests/implementation-system-model.json"
AUDIT = ROOT / "manifests/scenario-semantic-audit.json"

EXPECTED_ENTRY_KINDS = {
    "LOCAL", "COMMAND", "READ_REQUEST", "SYNC_CONTROL",
    "SERVER_TRIGGER", "EVENT_TRIGGER", "TEST_HARNESS",
}
EXPECTED_RECOVERY_KINDS = {
    "CLIENT_RESYNC", "RECONNECT", "SERVER_RESTART", "ROLLBACK_BRANCH",
    "RETRY_AFTER_RESTART", "LAST_KNOWN_GOOD", "CONTROL_FAILOVER",
}


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

    if audit.get("registryId") != "rvtt-scenario-semantic-audit-v2":
        errors.append("audit registryId must be rvtt-scenario-semantic-audit-v2")
    if audit.get("status") != "ACTIVE_R3_PENDING_FREEZE":
        errors.append("audit status must remain ACTIVE_R3_PENDING_FREEZE during R3")
    if audit.get("scenarioCount") != 61:
        errors.append("audit scenarioCount must be 61")

    base_scenarios = base.get("scenarios", [])
    expanded_scenarios = expanded.get("scenarios", [])
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

    binding = audit.get("sourceBinding")
    if not isinstance(binding, dict):
        errors.append("sourceBinding must be object")
        binding = {}

    actual_base_sha = blob_sha(BASE)
    actual_expanded_sha = blob_sha(EXPANDED)
    if binding.get("baseScenarioBlobSha") != actual_base_sha:
        errors.append(
            "base scenario body changed without semantic re-audit: "
            f"expected={binding.get('baseScenarioBlobSha')} actual={actual_base_sha}"
        )
    if binding.get("expandedScenarioBlobSha") != actual_expanded_sha:
        errors.append(
            "expanded scenario body changed without semantic re-audit: "
            f"expected={binding.get('expandedScenarioBlobSha')} actual={actual_expanded_sha}"
        )

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
        errors.append("implementation model scenarioTrace IDs must match source scenario IDs before v2 audit")

    entry_defs = audit.get("entryKindDefinitions")
    recovery_defs = audit.get("recoveryKindDefinitions")
    if not isinstance(entry_defs, dict) or set(entry_defs) != EXPECTED_ENTRY_KINDS:
        errors.append(f"entryKindDefinitions must define exactly {sorted(EXPECTED_ENTRY_KINDS)}")
    if not isinstance(recovery_defs, dict) or set(recovery_defs) != EXPECTED_RECOVERY_KINDS:
        errors.append(f"recoveryKindDefinitions must define exactly {sorted(EXPECTED_RECOVERY_KINDS)}")

    entry_expansion = audit.get("entryBoundaryExpansion")
    recovery_expansion = audit.get("recoveryBoundaryExpansion")
    if not isinstance(entry_expansion, dict) or set(entry_expansion) != EXPECTED_ENTRY_KINDS:
        errors.append("entryBoundaryExpansion keys must match entryKindDefinitions")
        entry_expansion = {}
    if not isinstance(recovery_expansion, dict) or set(recovery_expansion) != EXPECTED_RECOVERY_KINDS:
        errors.append("recoveryBoundaryExpansion keys must match recoveryKindDefinitions")
        recovery_expansion = {}

    def validate_expansion(name: str, mapping: dict) -> None:
        for kind, value in mapping.items():
            if not isinstance(value, dict):
                errors.append(f"{name}.{kind} must be object")
                continue
            srefs = value.get("systemRefs")
            rrefs = value.get("requirementRefs")
            if not isinstance(srefs, list) or not isinstance(rrefs, list):
                errors.append(f"{name}.{kind} requires systemRefs[] and requirementRefs[]")
                continue
            unknown_s = [x for x in srefs if x not in system_ids]
            unknown_r = [x for x in rrefs if x not in req_ids]
            if unknown_s:
                errors.append(f"{name}.{kind}: unknown systems {unknown_s}")
            if unknown_r:
                errors.append(f"{name}.{kind}: unknown requirements {unknown_r}")

    validate_expansion("entryBoundaryExpansion", entry_expansion)
    validate_expansion("recoveryBoundaryExpansion", recovery_expansion)

    mutation = audit.get("mutationSemantic")
    if not isinstance(mutation, dict) or mutation.get("stage") != "MUTATION":
        errors.append("mutationSemantic must define the existing MUTATION stage")
    else:
        meaning = mutation.get("meaning", "")
        if not isinstance(meaning, str) or "transactional authoritative domain/source commit" not in meaning:
            errors.append("mutationSemantic must explicitly scope MUTATION to transactional authoritative domain/source commit")
        if mutation.get("eventWithoutMutationAllowed") is not True:
            errors.append("mutationSemantic.eventWithoutMutationAllowed must be true")

    audit_entries = audit.get("scenarioAudit")
    if not isinstance(audit_entries, list):
        errors.append("scenarioAudit must be an array")
        audit_entries = []
    audit_ids = [x.get("id") for x in audit_entries if isinstance(x, dict)]
    if len(audit_ids) != 61 or len(set(audit_ids)) != 61:
        errors.append(f"scenarioAudit must contain 61 unique ids, found {len(audit_ids)}")
    if set(audit_ids) != set(source_ids):
        errors.append(
            "scenarioAudit IDs must exactly match source scenarios; "
            f"missing={sorted(set(source_ids)-set(audit_ids))} extra={sorted(set(audit_ids)-set(source_ids))}"
        )

    lkg_candidates = set(audit.get("lastKnownGoodOwnerCandidates", []))
    if not lkg_candidates or not lkg_candidates.issubset(system_ids):
        errors.append("lastKnownGoodOwnerCandidates must be a non-empty subset of System IDs")

    entry_counts: Counter[str] = Counter()
    recovery_counts: Counter[str] = Counter()
    effective_recovery_scenarios = 0

    for item in audit_entries:
        if not isinstance(item, dict):
            errors.append("scenarioAudit entry must be object")
            continue
        sid = item.get("id")
        entry_kinds = item.get("entryKinds")
        recovery_kinds = item.get("recoveryKinds")
        if not isinstance(sid, str) or sid not in trace_by_id:
            errors.append(f"invalid audit scenario id {sid!r}")
            continue
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
        unknown_entry = [x for x in entry_kinds if x not in EXPECTED_ENTRY_KINDS]
        unknown_recovery = [x for x in recovery_kinds if x not in EXPECTED_RECOVERY_KINDS]
        if unknown_entry:
            errors.append(f"{sid}: unknown entryKinds {unknown_entry}")
        if unknown_recovery:
            errors.append(f"{sid}: unknown recoveryKinds {unknown_recovery}")
        entry_counts.update(x for x in entry_kinds if x in EXPECTED_ENTRY_KINDS)
        recovery_counts.update(x for x in recovery_kinds if x in EXPECTED_RECOVERY_KINDS)

        trace = trace_by_id[sid]
        trace_systems = set(trace.get("systemRefs", []))
        trace_requirements = set(trace.get("requirementCapabilityRefs", []))
        stages = set(trace.get("semanticStages", []))

        effective_systems = set(trace_systems)
        effective_requirements = set(trace_requirements)
        for kind in entry_kinds:
            expansion = entry_expansion.get(kind, {})
            effective_systems.update(expansion.get("systemRefs", []))
            effective_requirements.update(expansion.get("requirementRefs", []))
        for kind in recovery_kinds:
            expansion = recovery_expansion.get(kind, {})
            effective_systems.update(expansion.get("systemRefs", []))
            effective_requirements.update(expansion.get("requirementRefs", []))

        if "MUTATION" in stages and "A3" not in effective_systems:
            errors.append(f"{sid}: effective MUTATION path must include A3")
        if entry_kinds == ["LOCAL"] and "MUTATION" in stages:
            errors.append(f"{sid}: LOCAL-only scenario cannot claim transactional MUTATION")
        if "COMMAND" in entry_kinds and not {"A2", "A1"}.issubset(effective_systems):
            errors.append(f"{sid}: COMMAND ingress must expand through A2+A1")
        if "READ_REQUEST" in entry_kinds and "A2" not in effective_systems:
            errors.append(f"{sid}: READ_REQUEST ingress must expand through A2")
        if "SYNC_CONTROL" in entry_kinds and not {"A6", "A1"}.issubset(effective_systems):
            errors.append(f"{sid}: SYNC_CONTROL ingress must expand through A6+A1")
        if "EVENT_TRIGGER" in entry_kinds and "A8" not in effective_systems:
            errors.append(f"{sid}: EVENT_TRIGGER ingress must expand through A8")
        if "TEST_HARNESS" in entry_kinds and "S2" not in effective_systems:
            errors.append(f"{sid}: TEST_HARNESS ingress must expand through S2")

        if recovery_kinds:
            effective_recovery_scenarios += 1
        if "RECOVERY" in stages and not recovery_kinds:
            errors.append(f"{sid}: v1 RECOVERY stage requires typed recoveryKinds in v2")
        if "CLIENT_RESYNC" in recovery_kinds and "A6" not in effective_systems:
            errors.append(f"{sid}: CLIENT_RESYNC requires A6")
        if "RECONNECT" in recovery_kinds and not {"A1", "A6"}.issubset(effective_systems):
            errors.append(f"{sid}: RECONNECT requires A1+A6")
        if {"SERVER_RESTART", "ROLLBACK_BRANCH", "RETRY_AFTER_RESTART"} & set(recovery_kinds):
            if "A7" not in effective_systems:
                errors.append(f"{sid}: restart/rollback recovery requires A7")
        if "LAST_KNOWN_GOOD" in recovery_kinds and not (effective_systems & lkg_candidates):
            errors.append(f"{sid}: LAST_KNOWN_GOOD requires an explicit LKG owner candidate")
        if "CONTROL_FAILOVER" in recovery_kinds and "A1" not in effective_systems:
            errors.append(f"{sid}: CONTROL_FAILOVER requires A1")

        if not effective_systems.issubset(system_ids):
            errors.append(f"{sid}: effective system expansion introduced unknown system")
        if not effective_requirements.issubset(req_ids):
            errors.append(f"{sid}: effective requirement expansion introduced unknown requirement")

    normalized_entries = [
        {"id": x.get("id"), "entryKinds": x.get("entryKinds"), "recoveryKinds": x.get("recoveryKinds")}
        for x in audit_entries if isinstance(x, dict)
    ]
    actual_entry_digest = digest(normalized_entries)
    if binding.get("entryRecoveryDigest") != actual_entry_digest:
        errors.append(
            "entry/recovery semantic audit changed without digest update: "
            f"expected={binding.get('entryRecoveryDigest')} actual={actual_entry_digest}"
        )

    combined_input = (
        f"base:{actual_base_sha}\n"
        f"expanded:{actual_expanded_sha}\n"
        f"trace:{trace_digest}\n"
        f"entryRecovery:{actual_entry_digest}"
    )
    actual_combined = "sha256:" + hashlib.sha256(combined_input.encode("utf-8")).hexdigest()
    if binding.get("combinedAuditDigest") != actual_combined:
        errors.append(
            "combined scenario/body/trace audit digest mismatch: "
            f"expected={binding.get('combinedAuditDigest')} actual={actual_combined}"
        )

    declared_recovery_count = audit.get("effectiveRecoveryScenarioCount")
    if declared_recovery_count != effective_recovery_scenarios:
        errors.append(f"effectiveRecoveryScenarioCount must be {effective_recovery_scenarios}, found {declared_recovery_count}")

    if errors:
        return fail(errors)

    print(
        "RVTT scenario semantic audit passed: "
        f"scenarios={len(audit_ids)}; effective_recovery_scenarios={effective_recovery_scenarios}; "
        f"entryKinds={dict(sorted(entry_counts.items()))}; "
        f"recoveryKinds={dict(sorted(recovery_counts.items()))}; "
        f"combinedDigest={actual_combined}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
