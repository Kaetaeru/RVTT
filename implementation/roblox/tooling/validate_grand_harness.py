from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required_specs = {
    "slice02-core-rules": "Slice02CoreRules.spec.lua",
    "slice03-exploration": "Slice03Exploration.spec.lua",
    "slice04-encounter": "Slice04Encounter.spec.lua",
    "slice05-character": "Slice05Character.spec.lua",
    "slice06-inventory": "Slice06Inventory.spec.lua",
    "slice07-time-progression": "Slice07TimeProgression.spec.lua",
    "slice08-ui-preference": "Slice08UiPreference.spec.lua",
    "slice09-journal": "Slice09Journal.spec.lua",
    "slice10-scene-authoring": "Slice10SceneAuthoring.spec.lua",
    "slice11-dm-workspace": "Slice11DmWorkspace.spec.lua",
    "slice12-content-platform": "Slice12ContentPlatform.spec.lua",
    "grand-cross-slice-session": "GrandCrossSliceSession.spec.lua",
    "grand-authority-faults": "GrandAuthorityFaults.spec.lua",
    "grand-network-fault-host": "GrandNetworkFaultHost.spec.lua",
    "grand-storage-fault-host": "GrandStorageFaultHost.spec.lua",
    "grand-capacity-sample": "GrandCapacitySample.spec.lua",
}

required_paths = (
    "test.project.json",
    "grand-single-client.project.json",
    "real-transport.project.json",
    "restart-seed.project.json",
    "restart-verify.project.json",
    "grand-acceptance-manifest.json",
    "tests/TestRunner.server.lua",
    "tests/Unit/PersistenceRetry.spec.lua",
    "tests/Integration/ScenarioRuntime.lua",
    "tests/Integration/FaultTransport.lua",
    "tests/Integration/FaultStore.lua",
    "tests/RealTransport/ServerRunner.server.lua",
    "tests/RealTransport/ClientRunner.client.lua",
    "tests/RestartAcceptance/ServerRunner.server.lua",
    "tooling/run-grand-acceptance.ps1",
)
for relative in required_paths:
    if not (ROOT / relative).exists():
        errors.append(f"missing {relative}")

for filename in required_specs.values():
    path = ROOT / "tests" / "Integration" / filename
    if not path.exists():
        errors.append(f"missing tests/Integration/{filename}")
    elif not path.read_text(encoding="utf-8").startswith("--!strict"):
        errors.append(f"tests/Integration/{filename}: missing --!strict")

for relative in (
    "tests/Unit/PersistenceRetry.spec.lua",
    "tests/RealTransport/ServerRunner.server.lua",
    "tests/RealTransport/ClientRunner.client.lua",
    "tests/RestartAcceptance/ServerRunner.server.lua",
):
    path = ROOT / relative
    if path.exists() and not path.read_text(encoding="utf-8").startswith("--!strict"):
        errors.append(f"{relative}: missing --!strict")

try:
    test_project = json.loads((ROOT / "test.project.json").read_text(encoding="utf-8"))
    test_scripts = test_project["tree"]["StarterPlayer"]["StarterPlayerScripts"]
    if "RVTT" not in test_scripts:
        errors.append("test.project.json: client modules are not mapped for fault tests")
except Exception as exc:
    errors.append(f"test.project.json: {exc}")

try:
    project = json.loads((ROOT / "grand-single-client.project.json").read_text(encoding="utf-8"))
    tree = project["tree"]
    if tree["ReplicatedStorage"]["RVTT_GrandMode"]["$properties"]["Value"] != "single-client":
        errors.append("grand-single-client.project.json: invalid RVTT_GrandMode")
    if tree["ServerStorage"]["RVTT"]["EnableStudioPersistence"]["$properties"]["Value"] is not False:
        errors.append("grand-single-client.project.json: persistence must be disabled")
    if "RVTTGrandTests" not in tree["ServerScriptService"]:
        errors.append("grand-single-client.project.json: RVTTGrandTests is not mapped")
    if "RVTTWorldTokenAcceptance" not in tree["StarterPlayer"]["StarterPlayerScripts"]:
        errors.append("grand-single-client.project.json: Slice 01 manual acceptance is not mapped")
except Exception as exc:
    errors.append(f"grand-single-client.project.json: {exc}")

try:
    project = json.loads((ROOT / "real-transport.project.json").read_text(encoding="utf-8"))
    mode = project["tree"]["ReplicatedStorage"]["RVTT_TestMode"]["$properties"]["Value"]
    if mode != "real-transport":
        errors.append("real-transport.project.json: invalid RVTT_TestMode")
    if "RVTTRealTransportTests" not in project["tree"]["ServerScriptService"]:
        errors.append("real-transport.project.json: server host is not mapped")
    if "RVTTRealTransportClient" not in project["tree"]["StarterPlayer"]["StarterPlayerScripts"]:
        errors.append("real-transport.project.json: client host is not mapped")
except Exception as exc:
    errors.append(f"real-transport.project.json: {exc}")

for project_name, expected_phase in (
    ("restart-seed.project.json", "seed"),
    ("restart-verify.project.json", "verify"),
):
    try:
        project = json.loads((ROOT / project_name).read_text(encoding="utf-8"))
        replicated = project["tree"]["ReplicatedStorage"]
        if replicated["RVTT_TestMode"]["$properties"]["Value"] != "restart-acceptance":
            errors.append(f"{project_name}: invalid RVTT_TestMode")
        if replicated["RVTT_RestartPhase"]["$properties"]["Value"] != expected_phase:
            errors.append(f"{project_name}: invalid restart phase")
    except Exception as exc:
        errors.append(f"{project_name}: {exc}")

try:
    manifest = json.loads((ROOT / "grand-acceptance-manifest.json").read_text(encoding="utf-8"))
    phases = {phase["id"]: phase for phase in manifest["phases"]}
    for project in (
        "grand-single-client.project.json",
        "real-transport.project.json",
        "restart-seed.project.json",
        "restart-verify.project.json",
    ):
        if project not in manifest["staticProjects"]:
            errors.append(f"grand-acceptance-manifest.json: {project} missing from staticProjects")
    for phase_id in ("unit-integration-baseline", "slice01-world-interaction"):
        phase = phases.get(phase_id)
        if phase is None:
            errors.append(f"grand-acceptance-manifest.json: missing {phase_id}")
            continue
        if phase.get("runId") != "grand-single-client":
            errors.append(f"grand-acceptance-manifest.json: {phase_id} has wrong runId")
        if phase.get("project") != "grand-single-client.project.json":
            errors.append(f"grand-acceptance-manifest.json: {phase_id} has wrong project")
    real_transport = phases.get("real-transport-reconnect", {})
    if real_transport.get("status") != "ready":
        errors.append("grand-acceptance-manifest.json: real transport phase is not ready")
    if real_transport.get("project") != "real-transport.project.json":
        errors.append("grand-acceptance-manifest.json: real transport project mismatch")
    if real_transport.get("execution") != "studio-multi-client":
        errors.append("grand-acceptance-manifest.json: real transport execution mismatch")
    restart_contracts = {
        "persistence-restart-seed": ("restart-seed.project.json", "[RVTT Restart Seed]"),
        "persistence-restart-verify": ("restart-verify.project.json", "[RVTT Restart Verify]"),
    }
    for phase_id, (project, token) in restart_contracts.items():
        phase = phases.get(phase_id, {})
        if phase.get("status") != "deferred" or phase.get("persistence") is not True:
            errors.append(f"grand-acceptance-manifest.json: invalid {phase_id} selection contract")
        if phase.get("project") != project or phase.get("summaryToken") != token:
            errors.append(f"grand-acceptance-manifest.json: invalid {phase_id} evidence contract")
    baseline = phases.get("unit-integration-baseline", {})
    if "Slices 02-12" not in baseline.get("name", ""):
        errors.append("grand-acceptance-manifest.json: baseline name does not cover Slices 02-12")
    fault_phase = phases.get("fault-injection", {})
    blocker = fault_phase.get("blocker", "").lower()
    for phrase in ("deterministic", "disconnect", "restart", "outage"):
        if phrase not in blocker:
            errors.append(f"grand-acceptance-manifest.json: fault phase omits {phrase}")
    for slice_number in range(2, 13):
        matching = [phase for phase in manifest["phases"] if phase["id"].startswith(f"slice{slice_number:02d}-")]
        if len(matching) != 1:
            errors.append(f"grand-acceptance-manifest.json: expected one Slice {slice_number:02d} phase")
            continue
        blocker = matching[0].get("blocker", "")
        if "grand-single-client" not in blocker:
            errors.append(f"grand-acceptance-manifest.json: Slice {slice_number:02d} blocker omits automated baseline")
except Exception as exc:
    errors.append(f"grand-acceptance-manifest.json: {exc}")

runner_text = (ROOT / "tests" / "TestRunner.server.lua").read_text(encoding="utf-8")
for spec_id, filename in required_specs.items():
    if f'id = "{spec_id}"' not in runner_text:
        errors.append(f"TestRunner.server.lua: missing id {spec_id}")
    module_name = filename.removesuffix(".lua")
    if f'["{module_name}"]' not in runner_text:
        errors.append(f"TestRunner.server.lua: missing module {module_name}")
for phrase in (
    'id = "unit-persistence-retry"',
    '["PersistenceRetry.spec"]',
    "RVTT_GrandMode",
    "[RVTT Spec Summary]",
    "[RVTT Spec Failure]",
    "[RVTT Tests]",
):
    if phrase not in runner_text:
        errors.append(f"TestRunner.server.lua: missing {phrase}")

scenario_runtime = (ROOT / "tests" / "Integration" / "ScenarioRuntime.lua").read_text(encoding="utf-8")
for phrase in ("executeAtAuthority", "expectedRevision", "authorityEpoch"):
    if phrase not in scenario_runtime:
        errors.append(f"ScenarioRuntime.lua: missing fault contract {phrase}")

projection_replica = (
    ROOT / "src" / "StarterPlayer" / "StarterPlayerScripts" / "RVTT" / "Client" / "ProjectionReplica.lua"
).read_text(encoding="utf-8")
for phrase in ("seenEpochs", "epochOrder", "projectionSequence <= self.sequence"):
    if phrase not in projection_replica:
        errors.append(f"ProjectionReplica.lua: missing delayed epoch contract {phrase}")

command_client = (
    ROOT / "src" / "StarterPlayer" / "StarterPlayerScripts" / "RVTT" / "Client" / "CommandClient.lua"
).read_text(encoding="utf-8")
for phrase in ("CLIENT_TIMEOUT", "retrying", "MAX_ATTEMPTS", "RETRY_INTERVAL_SECONDS"):
    if phrase not in command_client:
        errors.append(f"CommandClient.lua: missing receipt-loss recovery contract {phrase}")

persistence = (
    ROOT / "src" / "ServerScriptService" / "RVTT" / "Server" / "Persistence" / "PersistenceCoordinator.lua"
).read_text(encoding="utf-8")
for phrase in ("RetryPolicy", "persistence.retry_scheduled", "persistence.retry_exhausted", "scheduleFlush"):
    if phrase not in persistence:
        errors.append(f"PersistenceCoordinator.lua: missing shutdown retry contract {phrase}")

network_fault = (ROOT / "tests" / "Integration" / "GrandNetworkFaultHost.spec.lua").read_text(encoding="utf-8")
for phrase in ("kind=network", "delayed previous epoch", "CLIENT_TIMEOUT", "retrying"):
    if phrase not in network_fault:
        errors.append(f"GrandNetworkFaultHost.spec.lua: missing network fault evidence {phrase}")

storage_fault = (ROOT / "tests" / "Integration" / "GrandStorageFaultHost.spec.lua").read_text(encoding="utf-8")
for phrase in ("kind=storage", "commit_then_fail", "external-winner", "PERSISTENCE_CONFLICT"):
    if phrase not in storage_fault:
        errors.append(f"GrandStorageFaultHost.spec.lua: missing storage fault evidence {phrase}")

real_transport = (ROOT / "tests" / "RealTransport" / "ServerRunner.server.lua").read_text(encoding="utf-8")
for phrase in ("PlayerRemoving", "PlayerAdded", "start-replacement-client", "reconnects=%d"):
    if phrase not in real_transport:
        errors.append(f"RealTransport/ServerRunner.server.lua: missing lifecycle evidence {phrase}")

restart_host = (ROOT / "tests" / "RestartAcceptance" / "ServerRunner.server.lua").read_text(encoding="utf-8")
for phrase in ("BindToClose", "[RVTT Restart Seed]", "[RVTT Restart Verify]", "STALE_EPOCH"):
    if phrase not in restart_host:
        errors.append(f"RestartAcceptance/ServerRunner.server.lua: missing restart evidence {phrase}")

capacity_text = (ROOT / "tests" / "Integration" / "GrandCapacitySample.spec.lua").read_text(encoding="utf-8")
for phrase in ("[RVTT Spec Summary] id=grand-capacity-sample sample=capacity", "elapsedMs", "restoreMs"):
    if phrase not in capacity_text:
        errors.append(f"GrandCapacitySample.spec.lua: missing measurement {phrase}")

powershell_text = (ROOT / "tooling" / "run-grand-acceptance.ps1").read_text(encoding="utf-8")
for phrase in (
    "Get-PhaseTokens",
    "runId",
    "runGroups",
    "Wait-ForStudioExit",
    "RVTT-grand-acceptance-report.json",
    "RVTT-grand-acceptance-report.md",
):
    if phrase not in powershell_text:
        errors.append(f"run-grand-acceptance.ps1: missing {phrase}")

if errors:
    print("RVTT grand harness validation failed:")
    for error in errors:
        print("-", error)
    sys.exit(1)

print(
    "RVTT grand harness validation passed: "
    f"{len(required_specs)} automated specs plus real transport and two-run restart hosts"
)
