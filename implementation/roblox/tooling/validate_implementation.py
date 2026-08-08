from pathlib import Path
import json
import re
import sys

from validate_full_ui_ux_acceptance import validate as validate_full_ui_ux_acceptance

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

errors.extend(validate_full_ui_ux_acceptance(ROOT))

for project in (
    "default.project.json",
    "test.project.json",
    "grand-single-client.project.json",
    "live-datastore.project.json",
    "multi-client.project.json",
    "persistence-acceptance.project.json",
    "slice01-acceptance.project.json",
):
    try:
        json.loads((ROOT / project).read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{project}: {exc}")

try:
    slice_project = json.loads((ROOT / "slice01-acceptance.project.json").read_text(encoding="utf-8"))
    persistence_flag = slice_project["tree"]["ServerStorage"]["RVTT"]["EnableStudioPersistence"]["$properties"]["Value"]
    if persistence_flag is not False:
        errors.append("slice01-acceptance.project.json: regular acceptance must disable Studio persistence")
except Exception as exc:
    errors.append(f"slice01-acceptance.project.json persistence contract: {exc}")

try:
    grand_project = json.loads((ROOT / "grand-single-client.project.json").read_text(encoding="utf-8"))
    grand_persistence_flag = grand_project["tree"]["ServerStorage"]["RVTT"]["EnableStudioPersistence"]["$properties"]["Value"]
    if grand_persistence_flag is not False:
        errors.append("grand-single-client.project.json: single-client grand run must disable Studio persistence")
    grand_mode = grand_project["tree"]["ReplicatedStorage"]["RVTT_GrandMode"]["$properties"]["Value"]
    if grand_mode != "single-client":
        errors.append("grand-single-client.project.json: RVTT_GrandMode must be single-client")
    if "RVTTGrandTests" not in grand_project["tree"]["ServerScriptService"]:
        errors.append("grand-single-client.project.json: RVTTGrandTests mapping is required")
except Exception as exc:
    errors.append(f"grand-single-client.project.json contract: {exc}")

acceptance_manifest_path = ROOT / "acceptance-batch.json"
try:
    acceptance_manifest = json.loads(acceptance_manifest_path.read_text(encoding="utf-8"))
    for field in ("schemaVersion", "repository", "branch", "verifiedHead", "project", "rojo"):
        if field not in acceptance_manifest:
            errors.append(f"acceptance-batch.json: missing {field}")
    if acceptance_manifest.get("schemaVersion") != 1:
        errors.append("acceptance-batch.json: schemaVersion must be 1")
    verified_head = acceptance_manifest.get("verifiedHead", "")
    if not re.fullmatch(r"[0-9a-f]{40}", verified_head):
        errors.append("acceptance-batch.json: verifiedHead must be a full lowercase commit SHA")
    if acceptance_manifest.get("project") != "slice01-acceptance.project.json":
        errors.append("acceptance-batch.json: unexpected default project")
    rojo = acceptance_manifest.get("rojo", {})
    if rojo.get("version") != "7.7.0":
        errors.append("acceptance-batch.json: Rojo version must match CI pin 7.7.0")
    for key in ("windowsX64", "windowsArm64"):
        asset = rojo.get("assets", {}).get(key, {})
        if not asset.get("url", "").startswith("https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/"):
            errors.append(f"acceptance-batch.json: invalid {key} Rojo URL")
        if not re.fullmatch(r"[0-9a-f]{64}", asset.get("sha256", "")):
            errors.append(f"acceptance-batch.json: invalid {key} SHA256")
except Exception as exc:
    errors.append(f"acceptance-batch.json: {exc}")

grand_manifest_path = ROOT / "grand-acceptance-manifest.json"
try:
    grand_manifest = json.loads(grand_manifest_path.read_text(encoding="utf-8"))
    if grand_manifest.get("schemaVersion") != 1:
        errors.append("grand-acceptance-manifest.json: schemaVersion must be 1")
    if grand_manifest.get("campaignId") != "rvtt-grand-acceptance":
        errors.append("grand-acceptance-manifest.json: unexpected campaignId")
    if grand_manifest.get("runner") != "tooling/run-grand-acceptance.ps1":
        errors.append("grand-acceptance-manifest.json: unexpected runner")

    phases = grand_manifest.get("phases", [])
    if len(phases) < 20:
        errors.append("grand-acceptance-manifest.json: expected at least 20 phases")
    phase_ids = [phase.get("id") for phase in phases]
    if len(set(phase_ids)) != len(phase_ids):
        errors.append("grand-acceptance-manifest.json: duplicate phase id")
    phase_orders = [phase.get("order") for phase in phases]
    if len(set(phase_orders)) != len(phase_orders):
        errors.append("grand-acceptance-manifest.json: duplicate phase order")

    static_projects = grand_manifest.get("staticProjects", [])
    for project in static_projects:
        if not (ROOT / project).exists():
            errors.append(f"grand-acceptance-manifest.json: missing static project {project}")
    if "grand-single-client.project.json" not in static_projects:
        errors.append("grand-acceptance-manifest.json: grand single-client project is not registered")

    run_contracts: dict[str, tuple[str, str]] = {}
    for phase in phases:
        status = phase.get("status")
        if status not in {"ready", "deferred", "planned", "blocked"}:
            errors.append(f"grand-acceptance-manifest.json: invalid status for {phase.get('id')}")
        if status == "ready" and phase.get("execution") != "automated":
            for field in ("project", "summaryToken", "passRegex", "runId"):
                if not phase.get(field):
                    errors.append(f"grand-acceptance-manifest.json: {phase.get('id')} missing {field}")
            run_id = phase.get("runId")
            contract = (phase.get("project"), phase.get("execution"))
            if run_id:
                previous = run_contracts.get(run_id)
                if previous is not None and previous != contract:
                    errors.append(f"grand-acceptance-manifest.json: runId contract mismatch for {run_id}")
                run_contracts[run_id] = contract

    single_client_phases = {
        phase.get("id"): phase
        for phase in phases
        if phase.get("runId") == "grand-single-client"
    }
    for phase_id in ("unit-integration-baseline", "slice01-world-interaction"):
        phase = single_client_phases.get(phase_id)
        if phase is None:
            errors.append(f"grand-acceptance-manifest.json: {phase_id} is not in grand-single-client")
        elif phase.get("project") != "grand-single-client.project.json":
            errors.append(f"grand-acceptance-manifest.json: {phase_id} uses the wrong shared project")
except Exception as exc:
    errors.append(f"grand-acceptance-manifest.json: {exc}")

luau = list((ROOT / "src").rglob("*.lua")) + list((ROOT / "tests").rglob("*.lua"))
if len(luau) < 70:
    errors.append(f"expected at least 70 Luau files, found {len(luau)}")

registration_count = 0
authorization_count = 0
for path in luau:
    text = path.read_text(encoding="utf-8")
    relative = path.relative_to(ROOT)
    if not text.startswith("--!strict"):
        errors.append(f"{relative}: missing --!strict")
    if re.search(r"\bwhile\s+true\s+do\b", text):
        errors.append(f"{relative}: unbounded loop")
    uses_global_g = re.search(r"(?<![A-Za-z0-9_])_G(?![A-Za-z0-9_])", text) is not None
    uses_shared_global = re.search(r"(?<![A-Za-z0-9_])shared\.", text) is not None
    if uses_global_g or uses_shared_global:
        errors.append(f"{relative}: hidden global state")
    if path.is_relative_to(ROOT / "src" / "StarterGui") and ("FireServer" in text or "InvokeServer" in text):
        errors.append(f"{relative}: UI component calls remote directly")
    if path.parent.name == "Domains":
        registration_count += text.count("registry:register({")
        authorization_count += text.count("authorize =")

if registration_count == 0 or authorization_count < registration_count:
    errors.append(
        f"every command needs explicit authorization: registrations={registration_count}, authorizations={authorization_count}"
    )

rules_text = (ROOT / "src/ServerScriptService/RVTT/Server/Domains/RulesDomain.lua").read_text(encoding="utf-8")
for forbidden in ("payload.attackBonus", "payload.armorClass", "payload.damage", "payload.modifier", "payload.difficultyClass"):
    if forbidden in rules_text and forbidden != "payload.difficultyClass":
        errors.append(f"RulesDomain trusts client authority field: {forbidden}")

required = [
    "EXECUTION-TEST-RULES.md",
    "GRAND-ACCEPTANCE-CAMPAIGN.md",
    "FULL-UI-UX-ACCEPTANCE.md",
    "acceptance-batch.json",
    "full-ui-ux-acceptance-matrix.json",
    "grand-acceptance-manifest.json",
    "grand-single-client.project.json",
    "src/ReplicatedStorage/RVTT/Shared/Core/ValueGuard.lua",
    "src/ReplicatedStorage/RVTT/ContentRuntime/AssetCatalog.lua",
    "src/ReplicatedStorage/RVTT/Shared/Diagnostics/BatchSummary.lua",
    "src/ReplicatedStorage/RVTT/Shared/World/WorldTokenContract.lua",
    "src/ReplicatedStorage/RVTT/Shared/World/WorldInteractionMath.lua",
    "src/ServerScriptService/RVTT/ServerBoot.server.lua",
    "src/ServerScriptService/RVTT/Server/Projection/DomainProjectionPolicy.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/PersistenceCoordinator.lua",
    "src/ServerScriptService/RVTT/Server/Rules/ActorProfileResolver.lua",
    "src/ServerScriptService/RVTT/Server/Rules/RuleResolver.lua",
    "src/ServerStorage/RVTT/Content/AssetPackageRegistry.lua",
    "src/ServerStorage/RVTT/Content/AssetRegistryValidator.lua",
    "src/ServerStorage/RVTT/Content/ClientAssetViewBuilder.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/ClientBoot.client.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/ClientRuntime.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/TokenAssetResolver.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldCameraController.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenRenderer.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenInputController.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenRuntime.lua",
    "src/StarterGui/RVTT/App.client.lua",
    "tests/TestRunner.server.lua",
    "tests/Integration/ScenarioRuntime.lua",
    "tests/Integration/MultiViewerFlow.spec.lua",
    "tests/Integration/Slice01Flow.spec.lua",
    "tests/Integration/Slice02CoreRules.spec.lua",
    "tests/Integration/Slice03Exploration.spec.lua",
    "tests/Integration/Slice04Encounter.spec.lua",
    "tests/Unit/BatchSummary.spec.lua",
    "tests/Unit/AssetRegistry.spec.lua",
    "tests/Unit/WorldInteractionMath.spec.lua",
    "tests/Unit/WorldTokenContract.spec.lua",
    "tests/Slice01Acceptance/Slice01Acceptance.client.lua",
    "tests/WorldTokenAcceptance/WorldTokenAcceptance.client.lua",
    "tests/LiveDataStore/DataStoreRunner.server.lua",
    "tests/MultiClient/ServerRunner.server.lua",
    "tests/MultiClient/ClientRunner.client.lua",
    "tooling/run-studio-acceptance-batch.ps1",
    "tooling/run-grand-acceptance.ps1",
    "tooling/validate_full_ui_ux_acceptance.py",
    "tooling/validate_asset_registry.py",
    "manifests/all-slices-script-manifest.md",
]
for relative in required:
    if not (ROOT / relative).exists():
        errors.append(f"missing {relative}")

execution_rules_path = ROOT / "EXECUTION-TEST-RULES.md"
if execution_rules_path.exists():
    execution_rules = execution_rules_path.read_text(encoding="utf-8")
    for required_phrase in (
        "Batch Acceptance Gate",
        "완전한 다중 행 Windows PowerShell 블록",
        '$ErrorActionPreference = "Stop"',
        "git switch planning/rvtt-remake",
        "git pull --ff-only origin planning/rvtt-remake",
        '$head = (git rev-parse --short HEAD).Trim()',
        "rojo build slice01-acceptance.project.json --output $output",
        "Start-Process $output",
        "EnableStudioPersistence=false",
        "Persistence 전용 Batch",
        "Batch Summary",
    ):
        if required_phrase not in execution_rules:
            errors.append(f"EXECUTION-TEST-RULES.md: missing policy phrase {required_phrase}")

camera_path = ROOT / "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldCameraController.lua"
if camera_path.exists():
    camera_text = camera_path.read_text(encoding="utf-8")
    for required_phrase in (
        "setMovementModeActive",
        "keyboard-wasd",
        "keyboardPanAxis",
        "mouse-middle-screen-delta",
        "GetFocusedTextBox",
    ):
        if required_phrase not in camera_text:
            errors.append(f"WorldCameraController.lua: missing input contract {required_phrase}")

world_acceptance_path = ROOT / "tests/WorldTokenAcceptance/WorldTokenAcceptance.client.lua"
if world_acceptance_path.exists():
    world_acceptance = world_acceptance_path.read_text(encoding="utf-8")
    for required_phrase in (
        'id = "camera-wasd-pan"',
        'source == "keyboard-wasd"',
        "persistence=disabled",
        "이 Build는 DataStore를 사용하지 않습니다",
    ):
        if required_phrase not in world_acceptance:
            errors.append(f"WorldTokenAcceptance.client.lua: missing contract {required_phrase}")
    for forbidden_phrase in ("state-restore", "detectInitialRestore"):
        if forbidden_phrase in world_acceptance:
            errors.append(f"WorldTokenAcceptance.client.lua: regular acceptance contains {forbidden_phrase}")

test_runner_path = ROOT / "tests/TestRunner.server.lua"
if test_runner_path.exists():
    test_runner = test_runner_path.read_text(encoding="utf-8")
    for required_phrase in (
        "RVTT_GrandMode",
        "[RVTT Spec Summary]",
        'id = "slice02-core-rules"',
        'id = "slice03-exploration"',
        'id = "slice04-encounter"',
        'id = "unit-asset-registry"',
    ):
        if required_phrase not in test_runner:
            errors.append(f"TestRunner.server.lua: missing grand test contract {required_phrase}")

batch_runner_path = ROOT / "tooling/run-studio-acceptance-batch.ps1"
if batch_runner_path.exists():
    batch_runner = batch_runner_path.read_text(encoding="utf-8")
    for required_phrase in (
        "Dirty Worktree",
        "ExpectedHead",
        "acceptance-batch.json",
        "Offline cache",
        "Expand-Archive",
        "Get-FileHash",
        "validate_implementation.py",
        "rojo build",
        "manifest.txt",
        "SelfTest",
    ):
        if required_phrase not in batch_runner:
            errors.append(f"run-studio-acceptance-batch.ps1: missing contract {required_phrase}")

grand_runner_path = ROOT / "tooling/run-grand-acceptance.ps1"
if grand_runner_path.exists():
    grand_runner = grand_runner_path.read_text(encoding="utf-8")
    for required_phrase in (
        "grand-acceptance-manifest.json",
        "IncludePersistence",
        "Get-RecentStudioLines",
        "Get-PhaseTokens",
        "runId",
        "Wait-ForStudioExit",
        "RVTT Grand Summary",
        "RVTT-grand-acceptance-report.json",
        "RVTT-grand-acceptance-report.md",
        "SelfTest",
    ):
        if required_phrase not in grand_runner:
            errors.append(f"run-grand-acceptance.ps1: missing contract {required_phrase}")

domains = list((ROOT / "src/ServerScriptService/RVTT/Server/Domains").glob("*Domain.lua"))
if len(domains) < 18:
    errors.append(f"expected 18 domain scripts, found {len(domains)}")

if errors:
    print("RVTT implementation validation failed:")
    for error in errors:
        print("-", error)
    sys.exit(1)

print(
    "RVTT implementation validation passed: "
    f"{len(luau)} Luau files, {len(domains)} domain files, {registration_count} authorized commands"
)
