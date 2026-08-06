from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required_projects = [
    "live-datastore.project.json",
    "restart-seed.project.json",
    "restart-verify.project.json",
    "datastore-outage.project.json",
    "lease-holder.project.json",
    "lease-contender.project.json",
    "production-lease-seed.project.json",
    "production-lease-verify.project.json",
]
required_orders = [40, 50, 60, 70, 80, 81, 90, 91]
required_run_ids = [
    "grand-persistence-live",
    "grand-persistence-restart-seed",
    "grand-persistence-restart-verify",
    "grand-persistence-outage",
    "grand-persistence-lease-pair",
    "grand-production-lease-seed",
    "grand-production-lease-verify",
]
configured_executions = {"studio-published", "studio-published-pair"}

for relative in (
    "grand-acceptance-manifest.json",
    "grand-persistence-config.example.json",
    "GRAND-PERSISTENCE-MILESTONE.md",
    "tooling/run-grand-persistence.ps1",
):
    if not (ROOT / relative).exists():
        errors.append(f"missing {relative}")

try:
    manifest = json.loads((ROOT / "grand-acceptance-manifest.json").read_text(encoding="utf-8"))
    phases = sorted(
        (
            phase
            for phase in manifest["phases"]
            if phase.get("persistence") is True
            and phase.get("execution") in configured_executions
        ),
        key=lambda phase: phase["order"],
    )
    orders = [phase["order"] for phase in phases]
    if orders != required_orders:
        errors.append(f"grand-acceptance-manifest.json: persistence order {orders}")

    projects = {phase.get("project") for phase in phases}
    for project in required_projects:
        if project not in projects:
            errors.append(f"grand-acceptance-manifest.json: missing project {project}")

    run_ids = {phase.get("runId") for phase in phases}
    for run_id in required_run_ids:
        if run_id not in run_ids:
            errors.append(f"grand-acceptance-manifest.json: missing runId {run_id}")

    for phase in phases:
        if phase.get("status") != "deferred":
            errors.append(f"grand-acceptance-manifest.json: {phase['id']} must remain deferred")
        for field in ("project", "runId", "summaryToken", "passRegex"):
            if not phase.get(field):
                errors.append(f"grand-acceptance-manifest.json: {phase['id']} missing {field}")

    pair = [phase for phase in phases if phase.get("runId") == "grand-persistence-lease-pair"]
    if len(pair) != 2 or {phase.get("project") for phase in pair} != {
        "lease-holder.project.json",
        "lease-contender.project.json",
    }:
        errors.append("grand-acceptance-manifest.json: lease pair contract mismatch")
except Exception as exc:
    errors.append(f"grand-acceptance-manifest.json: {exc}")

try:
    config = json.loads((ROOT / "grand-persistence-config.example.json").read_text(encoding="utf-8"))
    if config.get("schemaVersion") != 1:
        errors.append("grand-persistence-config.example.json: schemaVersion must be 1")
    if config.get("universeId") != 0:
        errors.append("grand-persistence-config.example.json: universeId must be a placeholder")
    if config.get("apiAccessConfirmed") is not False:
        errors.append("grand-persistence-config.example.json: apiAccessConfirmed must default false")
    place_ids = config.get("placeIds", {})
    if set(place_ids) != set(required_projects):
        errors.append("grand-persistence-config.example.json: project keys mismatch")
    if any(value != 0 for value in place_ids.values()):
        errors.append("grand-persistence-config.example.json: Place IDs must be placeholders")
except Exception as exc:
    errors.append(f"grand-persistence-config.example.json: {exc}")

try:
    runner = (ROOT / "tooling" / "run-grand-persistence.ps1").read_text(encoding="utf-8")
    for phrase in (
        "Assert-Config",
        "apiAccessConfirmed",
        "ConfiguredPersistenceExecutions",
        "rojoPath @(",
        '"upload", $project, "--asset_id"',
        '"--task", "EditPlace"',
        '"--placeId"',
        '"--universeId"',
        "Wait-ForStudioExit",
        "studio-published-pair",
        "RVTT-grand-persistence-report.json",
        "RVTT-grand-persistence-report.md",
    ):
        if phrase not in runner:
            errors.append(f"run-grand-persistence.ps1: missing {phrase}")
    for project in required_projects:
        if project not in runner:
            errors.append(f"run-grand-persistence.ps1: missing project {project}")
except Exception as exc:
    errors.append(f"run-grand-persistence.ps1: {exc}")

if errors:
    print("RVTT grand persistence validation failed:")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("RVTT grand persistence validation passed: published Place mapping, upload, launch and evidence order")
