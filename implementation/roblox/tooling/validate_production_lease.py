from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required_paths = (
    "src/ServerScriptService/RVTT/ServerBoot.server.lua",
    "src/ServerScriptService/RVTT/Server/Networking/CommandRouter.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseCoordinator.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseOwnership.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseProtectedStore.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/LeaseStore.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/PersistenceCoordinator.lua",
    "src/ServerScriptService/RVTT/Server/Persistence/ProfileStore.lua",
    "tests/TestRunner.server.lua",
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


coordinator = require_phrases(
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

ownership = require_phrases(
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

protected_store = require_phrases(
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
        "leaseOwnership:acquire()",
        "runtime:snapshot()",
        "persistence:load()",
        "leaseOwnership:startRenewal()",
        'Result.err("PERSISTENCE_NOT_READY"',
        "SYSTEM_COMMAND_LEASE_BLOCKED",
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
if close_start < 0 or flush_position < 0 or release_position < 0 or flush_position > release_position:
    errors.append("ServerBoot.server.lua: shutdown must flush before releasing the lease")

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

if errors:
    print("RVTT production lease validation failed:")
    for error in errors:
        print("-", error)
    sys.exit(1)

print(
    "RVTT production lease validation passed: "
    "acquire, atomic fence claim, guarded command/save, renewal, and flush-before-release contracts"
)
