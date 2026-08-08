from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = {
    "src/ReplicatedStorage/RVTT/Shared/Rules/RuleLink.lua",
    "src/ReplicatedStorage/RVTT/Shared/Rules/RuleReaderClient.lua",
    "src/ReplicatedStorage/RVTT/Shared/UI/CoreRulesReaderViewModel.lua",
    "src/ServerScriptService/RVTT/Server/Rules/RuleReaderService.lua",
    "src/ServerScriptService/RVTT/Server/Networking/RuleReaderQuery.lua",
    "src/ServerScriptService/RVTT/Server/Domains/SessionDomain.lua",
    "src/ServerScriptService/RVTT/RuleReaderBoot.server.lua",
    "src/ServerStorage/RVTT/Content/Packs/rvtt.core.rules/RuleReaderPackage.lua",
    "src/StarterGui/RVTT/UI/Components/CoreRulesReaderPanel.lua",
    "tests/Unit/CoreRulesReader.spec.lua",
}


def validate(root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    for relative in sorted(REQUIRED_FILES):
        if not (root / relative).is_file():
            errors.append(f"core rules reader: missing {relative}")
    if errors:
        return errors

    service = (root / "src/ServerScriptService/RVTT/Server/Rules/RuleReaderService.lua").read_text(encoding="utf-8")
    query = (root / "src/ServerScriptService/RVTT/Server/Networking/RuleReaderQuery.lua").read_text(encoding="utf-8")
    session = (root / "src/ServerScriptService/RVTT/Server/Domains/SessionDomain.lua").read_text(encoding="utf-8")
    boot = (root / "src/ServerScriptService/RVTT/RuleReaderBoot.server.lua").read_text(encoding="utf-8")
    client = (root / "src/ReplicatedStorage/RVTT/Shared/Rules/RuleReaderClient.lua").read_text(encoding="utf-8")
    panel = (root / "src/StarterGui/RVTT/UI/Components/CoreRulesReaderPanel.lua").read_text(encoding="utf-8")
    package = (root / "src/ServerStorage/RVTT/Content/Packs/rvtt.core.rules/RuleReaderPackage.lua").read_text(encoding="utf-8")
    spec = (root / "tests/Unit/CoreRulesReader.spec.lua").read_text(encoding="utf-8")
    remote_names = (root / "src/ReplicatedStorage/RVTT/Shared/Protocol/RemoteNames.lua").read_text(encoding="utf-8")
    management = (root / "src/StarterGui/RVTT/UI/Components/ManagementPanel.lua").read_text(encoding="utf-8")
    remote_spec = (root / "tests/Unit/RemoteBootstrap.spec.lua").read_text(encoding="utf-8")

    for marker in (
        "function RuleReaderService.manifest",
        "function RuleReaderService.search",
        "function RuleReaderService.open",
        "function RuleReaderService.chunk",
        "roleAllowed",
        "RULE_LINK_UNAVAILABLE",
        "RULE_CHUNK_UNAVAILABLE",
        "filteredLinks",
    ):
        if marker not in service:
            errors.append(f"RuleReaderService.lua: missing contract marker {marker}")
    manifest_body = service[
        service.find("function RuleReaderService.manifest"):
        service.find("function RuleReaderService.search")
    ]
    if "chunks =" in manifest_body or "chunkIds =" in manifest_body:
        errors.append("RuleReaderService.lua: manifest must not replicate the chunk body graph")

    for marker in ('request.action == "manifest"', 'request.action == "search"', 'request.action == "open"', 'request.action == "chunk"', "RATE_LIMITED"):
        if marker not in query:
            errors.append(f"RuleReaderQuery.lua: missing query action/enforcement marker {marker}")
    for marker in (
        "RulePackageResolver",
        "RuleReaderQuery.new",
        "RULE_READER_QUERY",
        "RunService:IsStudio()",
        '"development"',
        '"public"',
        'GetAttribute("RVTT_Role")',
    ):
        if marker not in boot:
            errors.append(f"RuleReaderBoot.server.lua: missing boot/profile marker {marker}")
    if "allowSrdFallback = true" in boot:
        errors.append("RuleReaderBoot.server.lua: implicit SRD fallback is forbidden")

    for marker in ("publishRole", 'SetAttribute("RVTT_Role"', "session.assign_character", "session.connection"):
        if marker not in session:
            errors.append(f"SessionDomain.lua: missing authoritative reader role marker {marker}")

    for marker in ("manifestCache", "chunkCache", 'action = "manifest"', 'action = "chunk"'):
        if marker not in client:
            errors.append(f"RuleReaderClient.lua: missing lazy client marker {marker}")

    for marker in (
        '"RuleTree"',
        '"VirtualizedArticle"',
        '"RuleOutline"',
        '"RuleSearch"',
        '"CopyRuleLink"',
        "PreviousChunk",
        "NextChunk",
    ):
        if marker not in panel:
            errors.append(f"CoreRulesReaderPanel.lua: missing reader surface marker {marker}")
    if "InvokeServer" in panel or "FireServer" in panel:
        errors.append("CoreRulesReaderPanel.lua: UI must not call remotes directly")

    for marker in ("CoreRulesTab", "Core Rules", "RulesReader:setVisible"):
        if marker not in management:
            errors.append(f"ManagementPanel.lua: missing Journal/Core Rules integration marker {marker}")

    if "rvtt.test.rules.2024.integrated.ko" in package or "Kaetaeru/D-D-2024-" in package:
        errors.append("RuleReaderPackage.lua: public package contains private package/source marker")
    for marker in ('packageId = "rvtt.core.rules"', 'licenseId = "CC-BY-4.0"', "chunks ="):
        if marker not in package:
            errors.append(f"RuleReaderPackage.lua: missing public package marker {marker}")

    for marker in (
        "totalBody > 200000",
        "forbidden-needle",
        "manifest.chunks",
        "hiddenSearch",
        "hiddenChunk",
        "RULE_LINK_UNAVAILABLE",
        "RULE_CHUNK_UNAVAILABLE",
    ):
        if marker not in spec:
            errors.append(f"CoreRulesReader.spec.lua: missing focused regression marker {marker}")
    if 'require(script.Parent["CoreRulesReader.spec"])(harness)' not in remote_spec:
        errors.append("RemoteBootstrap.spec.lua: focused Core Rules Reader regression is not registered")
    if "RULE_READER_QUERY" not in remote_names:
        errors.append("RemoteNames.lua: RuleReaderQuery remote name is not canonical")

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("Core Rules Reader validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print("Core Rules Reader validation passed: lazy manifest/search/open/chunk + permission-safe Journal reader")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
