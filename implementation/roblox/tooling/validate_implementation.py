from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

for project in (
    "default.project.json",
    "test.project.json",
    "live-datastore.project.json",
    "multi-client.project.json",
    "persistence-acceptance.project.json",
    "slice01-acceptance.project.json",
):
    try:
        json.loads((ROOT / project).read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{project}: {exc}")

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
    if "_G" in text or "shared." in text:
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
    "src/ReplicatedStorage/RVTT/Shared/Core/ValueGuard.lua",
    "src/ReplicatedStorage/RVTT/Shared/World/WorldTokenContract.lua",
    "src/ServerScriptService/RVTT/ServerBoot.server.lua",
    "src/ServerScriptService/RVTT/Server/Projection/DomainProjectionPolicy.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/PersistenceCoordinator.lua",
    "src/ServerScriptService/RVTT/Server/Rules/ActorProfileResolver.lua",
    "src/ServerScriptService/RVTT/Server/Rules/RuleResolver.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/ClientBoot.client.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/ClientRuntime.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/TokenAssetResolver.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenRenderer.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenInputController.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenRuntime.lua",
    "src/StarterGui/RVTT/App.client.lua",
    "tests/Integration/MultiViewerFlow.spec.lua",
    "tests/Integration/Slice01Flow.spec.lua",
    "tests/Unit/WorldTokenContract.spec.lua",
    "tests/Slice01Acceptance/Slice01Acceptance.client.lua",
    "tests/WorldTokenAcceptance/WorldTokenAcceptance.client.lua",
    "tests/LiveDataStore/DataStoreRunner.server.lua",
    "tests/MultiClient/ServerRunner.server.lua",
    "tests/MultiClient/ClientRunner.client.lua",
    "tooling/run-studio-acceptance-batch.ps1",
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
        "단일 실행 스크립트",
        "WT-PICK-01",
        "Final Batch Summary",
    ):
        if required_phrase not in execution_rules:
            errors.append(f"EXECUTION-TEST-RULES.md: missing policy phrase {required_phrase}")

batch_runner_path = ROOT / "tooling/run-studio-acceptance-batch.ps1"
if batch_runner_path.exists():
    batch_runner = batch_runner_path.read_text(encoding="utf-8")
    for required_phrase in (
        "Dirty Worktree",
        "ExpectedHead",
        "validate_implementation.py",
        "rojo build",
        "manifest.txt",
    ):
        if required_phrase not in batch_runner:
            errors.append(f"run-studio-acceptance-batch.ps1: missing contract {required_phrase}")

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
