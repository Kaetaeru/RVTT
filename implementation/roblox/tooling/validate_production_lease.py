from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required_paths = (
    "production-lease-seed.project.json",
    "production-lease-verify.project.json",
    "grand-acceptance-manifest.json",
    "src/ServerScriptService/RVTT/ServerBoot.server.lua",
    "src/ServerScriptService/RVTT/Server/Networking/CommandRouter.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseCoordinator.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseOwnership.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseProtectedStore.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseStore.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/PersistenceCoordinator.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/ProfileStore.lua",
    "tests/TestRunner.server.lua",
    "tests/ProductionLeaseAcceptance/ClientRunner.client.lua",
    "tests/ProductionLeaseAcceptance/ServerRunner.server.lua",
    "tests/Unit/CommandRouterGuard.spec.lua",
    "tests/Unit/Lease.spec.lua",
    "tests/Unit/LeaseOwnership.spec.lua",
    "tests/Unit/LeaseProtectedStore.spec.lua",
    "tests/Unit/ProfileStoreFencing.spec.lua",
)

for relative in required_paths:
    path = ROOT / relative
    if not path.exists():
        errors.append(f"missing {relative}")
    elif path.suffix == ".lua" and not path.read_text(encoding="utf-8").startswith("--!strict"):
        errors.append(f"{relative}: missing --!strict")


def require_phrases(relative: str, phrases: tuple[str, ...]) -> str:
    path = ROOT / relative
    if not path.exists():
        return ""
    text = path.read_text(encoding="utf-8")
    for phrase in phrases:
        if phrase not in text:
            errors.append(f"{relative}: missing production lease contract {phrase}")
    return text


require_phrases(
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseCoordinator.lua",
    (
        "function LeaseCoordinator.validateLocal",
        "function LeaseCoordinator.verify",
        "function LeaseCoordinator.writeFence",
        'result.error.code ~= "PERSISTENCE_FAILED"',
        'Result.err("LEASE_EXPIRED"',
        'Result.err("LEASE_LOST"',
    ),
)

require_phrases(
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseOwnership.lua",
    (
        "function LeaseOwnership.acquire",
        "function LeaseOwnership.guardLocal",
        "function LeaseOwnership.verifyRemote",
        "function LeaseOwnership.renewOnce",
        "function LeaseOwnership.startRenewal",
        "function LeaseOwnership.writeFence",
        "function LeaseOwnership.beginShutdown",
        "function LeaseOwnership.release",
        'result.error.code == "PERSISTENCE_FAILED"',
    ),
)

require_phrases(
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseProtectedStore.lua",
    (
        "initialDocument",
        "self.ownership:verifyRemote()",
        "self.ownership:writeFence()",
        "self.delegate:loadFenced",
        "self.delegate:save",
    ),
)

profile_store = require_phrases(
    "src/ServerScriptService/RVTT/Server/Persistence/ProfileStore.lua",
    (
        "persistenceFence",
        "function ProfileStore.loadFenced",
        "DATASTORE_FENCE_CLAIM_FAILED",
        "DATASTORE_FENCE_CLAIM_REJECTED",
        "DATASTORE_FENCED_WRITE_REJECTED",
        'Result.err(\n\t\t\t"PERSISTENCE_FENCED"',
        "local function isFenced",
        "claimed.persistenceFence = DeepCopy(candidateFence)",
        "document.persistenceFence = nil",
    ),
)
if "higherFence" in profile_store:
    errors.append("ProfileStore.lua: save must not bypass revision checks for a higher fence")
if profile_store.count("if isFenced(candidateFence, currentFence) then") < 2:
    errors.append("ProfileStore.lua: fence comparison is required for both claim and save")

router = require_phrases(
    "src/ServerScriptService/RVTT/Server/Networking/CommandRouter.lua",
    (
        "type CommandGuard",
        "commandGuard: CommandGuard?",
        "if self.commandGuard ~= nil then",
        "terminalResult = guardResult",
        "terminalResult = self.runtime:execute",
    ),
)
if router.find("terminalResult = guardResult") > router.find("terminalResult = self.runtime:execute"):
    errors.append("CommandRouter.lua: command guard must run before authority execution")

server_boot = require_phrases(
    "src/ServerScriptService/RVTT/ServerBoot.server.lua",
    (
        "LeaseCoordinator",
        "LeaseOwnership",
        "LeaseProtectedStore",
        'projectStringValue("AuthorityStoreName"',
        'projectStringValue("AuthorityKey"',
        'projectStringValue("LeaseStoreName"',
        'projectStringValue("LeaseOwnerId"',
        '"ProductionLeaseAcceptancePhase"',
        "ACCEPTANCE_STORE_PREFIX",
        "ACCEPTANCE_KEY_PREFIX",
        "removeAcceptanceData",
        "leaseOwnership:acquire()",
        "runtime:snapshot()",
        "persistence:load()",
        "leaseOwnership:startRenewal()",
        'Result.err("PERSISTENCE_NOT_READY"',
        "SYSTEM_COMMAND_LEASE_BLOCKED",
        "ProductionLeaseAcceptanceChecksPassed",
        "ProductionLeaseAcceptanceStaleBlocked",
        "PRODUCTION_LEASE_ACCEPTANCE_META_KEY",
        "[RVTT Production Lease Seed]",
        "[RVTT Production Lease Verify]",
        "game:BindToClose",
        "persistence:flushUntilClean()",
        "leaseOwnership:release()",
        "PERSISTENCE_SHUTDOWN_LEASE_RELEASE_FAILED",
    ),
)
sequence = (
    "leaseOwnership:acquire()",
    "LeaseProtectedStore.new",
    "persistence:load()",
    "leaseOwnership:startRenewal()",
)
positions = [server_boot.find(token) for token in sequence]
if any(position < 0 for position in positions) or positions != sorted(positions):
    errors.append("ServerBoot.server.lua: expected Acquire -> Fence Claim/Load -> Renew order")
close_start = server_boot.find("game:BindToClose")
flush_position = server_boot.find("persistence:flushUntilClean()", close_start)
release_position = server_boot.find("leaseOwnership:release()", close_start)
cleanup_position = server_boot.find("removeAcceptanceData()", close_start)
if close_start < 0 or flush_position < 0 or release_position < 0 or flush_position > release_position:
    errors.append("ServerBoot.server.lua: shutdown must flush before releasing the lease")
if cleanup_position < 0 or cleanup_position < release_position:
    errors.append("ServerBoot.server.lua: verify cleanup must run after lease release")

runner = require_phrases(
    "tests/TestRunner.server.lua",
    (
        'id = "unit-command-router-guard"',
        'id = "unit-lease"',
        'id = "unit-lease-ownership"',
        'id = "unit-lease-protected-store"',
        'id = "unit-profile-store-fencing"',
    ),
)

require_phrases(
    "tests/Unit/ProfileStoreFencing.spec.lua",
    (
        "atomically claims the existing document",
        "claim blocks a delayed previous owner even with a larger revision",
        "lower fencing token cannot reclaim the authority document",
        "fenced load creates an initial document when none exists",
        "invalid stored fencing metadata fails closed during claim",
    ),
)
require_phrases(
    "tests/Unit/LeaseOwnership.spec.lua",
    (
        "transient renew failure preserves ownership until local expiry",
        "terminal renew failure deactivates ownership",
        "shutdown prevents another renewal cycle",
    ),
)
require_phrases(
    "tests/Unit/LeaseProtectedStore.spec.lua",
    (
        "verified ownership permits fenced load",
        "fenced load forwards the active write fence",
        "lost lease blocks save",
        "missing fence blocks delegate load",
    ),
)
require_phrases(
    "tests/Unit/CommandRouterGuard.spec.lua",
    (
        "failed guard prevents authority execution",
        "failed guard prevents projection publication",
        "successful guard permits authority execution",
    ),
)

client_runner = require_phrases(
    "tests/ProductionLeaseAcceptance/ClientRunner.client.lua",
    (
        'commandType = "session.join"',
        "syncRemote:InvokeServer()",
        "membershipBefore",
        "membershipAfter",
        "[RVTT Production Lease Client]",
    ),
)
server_runner = require_phrases(
    "tests/ProductionLeaseAcceptance/ServerRunner.server.lua",
    (
        "ProductionLeasePersistenceReady",
        "ProductionLeaseLeaseFencingToken",
        "seedMeta.fencingToken",
        "staleCandidate.revision = math.max(99",
        'staleResult.error.code == "PERSISTENCE_FENCED"',
        "ProductionLeaseAcceptanceStaleBlocked",
        "[RVTT Production Lease Prompt]",
    ),
)
if client_runner.find('commandType = "session.join"') < client_runner.find("requestProjection()"):
    errors.append("ClientRunner.client.lua: command must use a synchronized authority envelope")
if server_runner.find("staleCandidate.revision = math.max(99") > server_runner.find("profileStore:save"):
    errors.append("ServerRunner.server.lua: stale revision must be prepared before the stale save")

projects: dict[str, dict] = {}
for name in ("production-lease-seed.project.json", "production-lease-verify.project.json"):
    try:
        projects[name] = json.loads((ROOT / name).read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{name}: {exc}")

for name, expected_phase, expected_owner in (
    ("production-lease-seed.project.json", "seed", "acceptance:production-lease:seed"),
    ("production-lease-verify.project.json", "verify", "acceptance:production-lease:verify"),
):
    project = projects.get(name)
    if project is None:
        continue
    try:
        tree = project["tree"]
        replicated = tree["ReplicatedStorage"]
        storage = tree["ServerStorage"]["RVTT"]
        if replicated["RVTT_ProductionLeasePhase"]["$properties"]["Value"] != expected_phase:
            errors.append(f"{name}: wrong client phase")
        if storage["ProductionLeaseAcceptancePhase"]["$properties"]["Value"] != expected_phase:
            errors.append(f"{name}: wrong server phase")
        if storage["EnableStudioPersistence"]["$properties"]["Value"] is not True:
            errors.append(f"{name}: persistence must be enabled")
        authority_store = storage["AuthorityStoreName"]["$properties"]["Value"]
        lease_store = storage["LeaseStoreName"]["$properties"]["Value"]
        authority_key = storage["AuthorityKey"]["$properties"]["Value"]
        owner_id = storage["LeaseOwnerId"]["$properties"]["Value"]
        if not authority_store.startswith("RVTT_ProductionLeaseAcceptance_"):
            errors.append(f"{name}: unsafe authority store")
        if not lease_store.startswith("RVTT_ProductionLeaseAcceptance_"):
            errors.append(f"{name}: unsafe lease store")
        if not authority_key.startswith("acceptance:production-lease:"):
            errors.append(f"{name}: unsafe authority key")
        if owner_id != expected_owner:
            errors.append(f"{name}: wrong owner id")
        if "RVTTProductionLeaseAcceptance" not in tree["ServerScriptService"]:
            errors.append(f"{name}: server acceptance runner missing")
        if "RVTTProductionLeaseClient" not in tree["StarterPlayer"]["StarterPlayerScripts"]:
            errors.append(f"{name}: client acceptance runner missing")
    except Exception as exc:
        errors.append(f"{name}: invalid acceptance project contract: {exc}")

if len(projects) == 2:
    seed_storage = projects["production-lease-seed.project.json"]["tree"]["ServerStorage"]["RVTT"]
    verify_storage = projects["production-lease-verify.project.json"]["tree"]["ServerStorage"]["RVTT"]
    for field in ("AuthorityStoreName", "AuthorityKey", "LeaseStoreName"):
        seed_value = seed_storage[field]["$properties"]["Value"]
        verify_value = verify_storage[field]["$properties"]["Value"]
        if seed_value != verify_value:
            errors.append(f"production lease projects must share {field}")
    if seed_storage["LeaseOwnerId"]["$properties"]["Value"] == verify_storage["LeaseOwnerId"]["$properties"]["Value"]:
        errors.append("production lease projects require distinct owners")

try:
    manifest = json.loads((ROOT / "grand-acceptance-manifest.json").read_text(encoding="utf-8"))
    static_projects = manifest["staticProjects"]
    phases = {phase["id"]: phase for phase in manifest["phases"]}
    for project in ("production-lease-seed.project.json", "production-lease-verify.project.json"):
        if project not in static_projects:
            errors.append(f"grand manifest missing static project {project}")
    seed_phase = phases.get("production-lease-seed")
    verify_phase = phases.get("production-lease-verify")
    if seed_phase is None or verify_phase is None:
        errors.append("grand manifest missing production lease phases")
    else:
        if seed_phase.get("order", 999) >= verify_phase.get("order", -1):
            errors.append("production lease seed must run before verify")
        if seed_phase.get("project") != "production-lease-seed.project.json":
            errors.append("production lease seed phase uses wrong project")
        if verify_phase.get("project") != "production-lease-verify.project.json":
            errors.append("production lease verify phase uses wrong project")
        if "[RVTT Production Lease Seed]" not in seed_phase.get("summaryToken", ""):
            errors.append("production lease seed summary token missing")
        if "[RVTT Production Lease Verify]" not in verify_phase.get("summaryToken", ""):
            errors.append("production lease verify summary token missing")
        if "staleBlocked=true" not in verify_phase.get("passRegex", ""):
            errors.append("production lease verify pass regex omits stale writer evidence")
except Exception as exc:
    errors.append(f"grand-acceptance-manifest.json: {exc}")

if errors:
    print("RVTT production lease validation failed:")
    for error in errors:
        print("-", error)
    sys.exit(1)

print(
    "RVTT production lease validation passed: "
    "acquire, atomic fence claim, guarded command/save, renewal, shutdown, "
    "and published seed/verify acceptance contracts"
)
