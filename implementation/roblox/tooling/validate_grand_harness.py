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
    "grand-capacity-sample": "GrandCapacitySample.spec.lua",
}

for relative in (
    "grand-single-client.project.json",
    "grand-acceptance-manifest.json",
    "tests/TestRunner.server.lua",
    "tests/Integration/ScenarioRuntime.lua",
    "tooling/run-grand-acceptance.ps1",
):
    if not (ROOT / relative).exists():
        errors.append(f"missing {relative}")

for filename in required_specs.values():
    path = ROOT / "tests" / "Integration" / filename
    if not path.exists():
        errors.append(f"missing tests/Integration/{filename}")
    elif not path.read_text(encoding="utf-8").startswith("--!strict"):
        errors.append(f"tests/Integration/{filename}: missing --!strict")

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
    manifest = json.loads((ROOT / "grand-acceptance-manifest.json").read_text(encoding="utf-8"))
    phases = {phase["id"]: phase for phase in manifest["phases"]}
    if "grand-single-client.project.json" not in manifest["staticProjects"]:
        errors.append("grand-acceptance-manifest.json: grand project missing from staticProjects")
    for phase_id in ("unit-integration-baseline", "slice01-world-interaction"):
        phase = phases.get(phase_id)
        if phase is None:
            errors.append(f"grand-acceptance-manifest.json: missing {phase_id}")
            continue
        if phase.get("runId") != "grand-single-client":
            errors.append(f"grand-acceptance-manifest.json: {phase_id} has wrong runId")
        if phase.get("project") != "grand-single-client.project.json":
            errors.append(f"grand-acceptance-manifest.json: {phase_id} has wrong project")
    baseline = phases.get("unit-integration-baseline", {})
    if "Slices 02-12" not in baseline.get("name", ""):
        errors.append("grand-acceptance-manifest.json: baseline name does not cover Slices 02-12")
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

capacity_text = (ROOT / "tests" / "Integration" / "GrandCapacitySample.spec.lua").read_text(encoding="utf-8")
for phrase in ("[RVTT Capacity Sample]", "elapsedMs", "restoreMs"):
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
    f"{len(required_specs)} Slice, cross-slice, fault and capacity scenarios in one single-client run"
)
