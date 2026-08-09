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
    "src/ServerStorage/RVTT/Content/BuiltinPackIndex.lua",
    "src/ServerStorage/RVTT/Content/RuleRuntimePackageBinding.lua",
    "src/ServerStorage/RVTT/Content/Packs/rvtt.core.rules/RuleReaderPackage.lua",
    "src/StarterGui/RVTT/UI/Components/CoreRulesReaderPanel.lua",
    "tests/Unit/CoreRulesReader.spec.lua",
    "tests/Unit/RuleReaderQueryAccess.spec.lua",
    "tests/Unit/RuleRuntimePackageBinding.spec.lua",
    "tooling/build_private_rules_runtime.py",
    "tooling/prepare_private_rules_runtime.py",
    "tooling/validate_private_rules_runtime_pipeline.py",
    "tooling/run-private-rules-studio.ps1",
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
    builtin = (root / "src/ServerStorage/RVTT/Content/BuiltinPackIndex.lua").read_text(encoding="utf-8")
    binding = (root / "src/ServerStorage/RVTT/Content/RuleRuntimePackageBinding.lua").read_text(encoding="utf-8")
    client = (root / "src/ReplicatedStorage/RVTT/Shared/Rules/RuleReaderClient.lua").read_text(encoding="utf-8")
    panel = (root / "src/StarterGui/RVTT/UI/Components/CoreRulesReaderPanel.lua").read_text(encoding="utf-8")
    package = (root / "src/ServerStorage/RVTT/Content/Packs/rvtt.core.rules/RuleReaderPackage.lua").read_text(encoding="utf-8")
    spec = (root / "tests/Unit/CoreRulesReader.spec.lua").read_text(encoding="utf-8")
    binding_spec = (root / "tests/Unit/RuleRuntimePackageBinding.spec.lua").read_text(encoding="utf-8")
    importer = (root / "tooling/build_private_rules_runtime.py").read_text(encoding="utf-8")
    preparer = (root / "tooling/prepare_private_rules_runtime.py").read_text(encoding="utf-8")
    pipeline = (root / "tooling/validate_private_rules_runtime_pipeline.py").read_text(encoding="utf-8")
    studio_runner = (root / "tooling/run-private-rules-studio.ps1").read_text(encoding="utf-8")
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

    for marker in (
        'request.action == "manifest"',
        'request.action == "search"',
        'request.action == "open"',
        'request.action == "chunk"',
        "RATE_LIMITED",
        "profileAccessResolver",
        "profileUnavailable",
    ):
        if marker not in query:
            errors.append(f"RuleReaderQuery.lua: missing query action/enforcement marker {marker}")

    for marker in (
        "RuleRuntimePackageBinding",
        "RuleRuntimePackageBinding.resolveProfile(configuredProfile())",
        "RuleRuntimePackageBinding.packageForId(packageId, configuredProfile())",
        "RuleRuntimePackageBinding.viewerCanAccessProfile(configuredProfile(), player.UserId)",
        "profileAccessResolver",
        "RULE_READER_QUERY",
        "RunService:IsStudio()",
        '"development"',
        '"public"',
        'GetAttribute("RVTT_Role")',
        "RVTTPrivateRuleContent",
    ):
        if marker not in boot:
            errors.append(f"RuleReaderBoot.server.lua: missing boot/profile marker {marker}")
    if "RulePackageResolver.resolve(configuredProfile(), {})" in boot:
        errors.append("RuleReaderBoot.server.lua: private profile must not bypass runtime binding readiness")
    if "allowSrdFallback = true" in boot:
        errors.append("RuleReaderBoot.server.lua: implicit SRD fallback is forbidden")

    for marker in (
        'RUNTIME_BINDING_ROOT_NAME = "RVTTPrivateRuleContent"',
        "function RuleRuntimePackageBinding.loadRuntimeBinding",
        "function RuleRuntimePackageBinding.resolveProfileWithBinding",
        "function RuleRuntimePackageBinding.packageForIdWithBinding",
        "function RuleRuntimePackageBinding.viewerCanAccessProfileWithBinding",
        "function RuleRuntimePackageBinding.viewerCanAccessProfile",
        "privateReadiness = binding.readiness",
        "pcall(require, readinessModule)",
        "pcall(require, packageModule)",
        "PRIVATE_RULE_PACKAGE_MISMATCH",
        "PRIVATE_RULE_ACCESS_MISSING",
        "PRIVATE_RULE_ACCESS_INVALID",
        "authorizedUserIds",
        "package.packageId ~= authority.packageId",
        "package.version ~= authority.version",
    ):
        if marker not in binding:
            errors.append(f"RuleRuntimePackageBinding.lua: missing private positive-path marker {marker}")

    for marker in (
        'expectedSourceDigest = "47ad33532e95a2a8834d470085524673231dd260"',
        'sourceBindingKey = "RVTT_PRIVATE_DND2024_KO_SOURCE"',
        'sourceRoot = "10-RULEBOOKS/integrated-2024"',
    ):
        if marker not in builtin:
            errors.append(f"BuiltinPackIndex.lua: missing pinned private source marker {marker}")

    for marker in (
        "SOURCE_REVISION_MISMATCH",
        "SOURCE_DIGEST_MISMATCH",
        "CONTENT_COUNT_MISMATCH",
        "SOURCE_WORKTREE_DIRTY",
        "PRIVATE_OUTPUT_INSIDE_PUBLIC_REPOSITORY",
        '"Readiness.json"',
        '"RuleReaderPackage.json"',
        '"RVTTPrivateRuleContent"',
        '"private-rules.generated.project.json"',
        "MAX_CHUNK_BYTES = 16 * 1024",
        "searchIndex",
        "normalize_markdown_links",
        "RULE_LINK_TARGET_UNRESOLVED",
        "return label",
    ):
        if marker not in importer:
            errors.append(f"build_private_rules_runtime.py: missing importer marker {marker}")

    for marker in (
        'AUTHORIZED_USERS_ENV = "RVTT_PRIVATE_RULES_AUTHORIZED_USER_IDS"',
        'readiness["authorizedUserIds"] = authorized_user_ids',
        "PRIVATE_RULE_ACCESS_MISSING",
        "PRIVATE_RULE_ACCESS_INVALID",
        'manifest["authorizationMode"] = "explicit-user-allowlist"',
    ):
        if marker not in preparer:
            errors.append(f"prepare_private_rules_runtime.py: missing owner-only preparation marker {marker}")

    for marker in (
        "EXPECTED_COUNTS",
        "make_source_repo",
        "validate_generated",
        "SOURCE_REVISION_MISMATCH",
        "SOURCE_DIGEST_MISMATCH",
        "CONTENT_COUNT_MISMATCH",
        "SOURCE_WORKTREE_DIRTY",
        "PRIVATE_SOURCE_MISSING",
        "PRIVATE_RULE_ACCESS_MISSING",
        "authorizedUserIds",
        "synthetic-private-rules.rbxlx",
        "ModuleScript",
        "write_link_graph",
        "validate_link_graph",
        "duplicate-heading-2",
        "missing-local.md",
        "../../../outside.md",
        "relatedLinks",
        "backlinks",
    ):
        if marker not in pipeline:
            errors.append(f"validate_private_rules_runtime_pipeline.py: missing pipeline marker {marker}")

    for marker in (
        'SourceBindingEnv = "RVTT_PRIVATE_DND2024_KO_SOURCE"',
        'AuthorizedUsersEnv = "RVTT_PRIVATE_RULES_AUTHORIZED_USER_IDS"',
        "prepare_private_rules_runtime.py",
        'Invoke-NativeChecked $rojoPath @("build", $generatedProject',
        "private-rules.generated.project.json",
    ):
        if marker not in studio_runner:
            errors.append(f"run-private-rules-studio.ps1: missing fail-closed Studio marker {marker}")
    if 'rojoPath @("build", $projectPath' in studio_runner:
        errors.append("run-private-rules-studio.ps1: must build the generated private overlay, not the base project")

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

    for marker in (
        "resolves with an exact runtime binding",
        "provider returns the injected package",
        "authorizes the explicit owner user",
        "denies an unlisted user without disclosure",
        "PRIVATE_SOURCE_MISSING",
        "SOURCE_REVISION_MISMATCH",
        "SOURCE_DIGEST_MISMATCH",
        "PRIVATE_RULE_ACCESS_MISSING",
        "PRIVATE_RULE_ACCESS_INVALID",
        "PRIVATE_RULE_PACKAGE_MISMATCH",
        "public profile cannot request the private package",
        "Binding.loadRuntimeBinding(fakeStorage)",
    ):
        if marker not in binding_spec:
            errors.append(f"RuleRuntimePackageBinding.spec.lua: missing positive-path regression marker {marker}")

    if 'require(script.Parent["CoreRulesReader.spec"])(harness)' not in remote_spec:
        errors.append("RemoteBootstrap.spec.lua: focused Core Rules Reader regression is not registered")
    if 'require(script.Parent["RuleRuntimePackageBinding.spec"])(harness)' not in remote_spec:
        errors.append("RemoteBootstrap.spec.lua: private runtime binding regression is not registered")
    if 'require(script.Parent["RuleReaderQueryAccess.spec"])(harness)' not in remote_spec:
        errors.append("RemoteBootstrap.spec.lua: private query access regression is not registered")
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
    print("Core Rules Reader validation passed: private import overlay + owner-only runtime binding + lazy permission-safe Journal reader")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
