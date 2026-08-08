from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from tempfile import TemporaryDirectory
import argparse
import json
import re

from build_public_release_staging import build as build_public_release_staging


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
PRIVATE_PACKAGE_ID = "rvtt.test.rules.2024.integrated.ko"
PUBLIC_PACKAGE_ID = "rvtt.core.rules"
PUBLIC_PROFILES = {"public", "release", "artifact"}
PRIVATE_OUTPUT_MARKERS = {
    "private-rule-chunk",
    "private_rule_chunk",
    "private-search-index",
    "private_search_index",
    "private-snippet-cache",
    "private_snippet_cache",
}
FORBIDDEN_METADATA_KEYS = {
    "credential",
    "credentials",
    "token",
    "sourcerevision",
    "sourcecommit",
    "sourcebinding",
    "sourcebindingkey",
    "privatebinding",
}
REQUIRED_FILES = {
    "src/ServerStorage/RVTT/Content/BuiltinPackIndex.lua",
    "src/ServerStorage/RVTT/Content/RulePackageResolver.lua",
    "src/ServerStorage/RVTT/Content/ReleaseContentLeakGate.lua",
    "src/ReplicatedStorage/RVTT/ContentRuntime/RuleProfileStatus.lua",
    "tests/Unit/RulePackageResolver.spec.lua",
    "tests/Unit/ReleaseContentLeakGate.spec.lua",
    "tooling/build_public_release_staging.py",
}


def _package_block(index_text: str, package_id: str) -> str:
    match = re.search(r'\{\s*packageId\s*=\s*"' + re.escape(package_id) + r'"', index_text)
    if match is None:
        raise ValueError(f"BuiltinPackIndex is missing package {package_id}")
    start = match.start()
    depth = 0
    quoted = False
    escaped = False
    for offset, character in enumerate(index_text[start:], start=start):
        if quoted:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                quoted = False
            continue
        if character == '"':
            quoted = True
        elif character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                return index_text[start : offset + 1]
    raise ValueError(f"BuiltinPackIndex package block is incomplete: {package_id}")


def _string_field(block: str, field: str) -> str:
    match = re.search(r"\b" + re.escape(field) + r'\s*=\s*"([^"]+)"', block)
    if match is None:
        raise ValueError(f"private package record is missing {field}")
    return match.group(1)


def parse_private_contract(index_text: str) -> dict:
    block = _package_block(index_text, PRIVATE_PACKAGE_ID)
    counts_match = re.search(r"expectedContentCounts\s*=\s*\{(?P<body>.*?)\n\s*\}", block, re.DOTALL)
    if counts_match is None:
        raise ValueError("private package record is missing expectedContentCounts")
    counts = {
        name: int(value)
        for name, value in re.findall(r"([A-Za-z][A-Za-z0-9_]*)\s*=\s*(\d+)", counts_match.group("body"))
    }
    if not counts:
        raise ValueError("private package expectedContentCounts must not be empty")
    return {
        "packageId": PRIVATE_PACKAGE_ID,
        "version": _string_field(block, "version"),
        "sourceRepository": _string_field(block, "sourceRepository"),
        "sourceBindingKey": _string_field(block, "sourceBindingKey"),
        "sourceRoot": _string_field(block, "sourceRoot"),
        "expectedContentCounts": counts,
    }


def private_contract(root: Path = ROOT) -> dict:
    index = (root / "src/ServerStorage/RVTT/Content/BuiltinPackIndex.lua").read_text(encoding="utf-8")
    return parse_private_contract(index)


def _forbidden_text_markers(contract: dict) -> set[str]:
    authority_markers = {
        str(contract[field]).lower()
        for field in ("packageId", "version", "sourceRepository", "sourceBindingKey", "sourceRoot")
    }
    return authority_markers | PRIVATE_OUTPUT_MARKERS


def validate_artifact(artifact: object, contract: dict) -> list[str]:
    errors: set[str] = set()
    if not isinstance(artifact, dict):
        return ["INVALID_ARTIFACT_INVENTORY"]
    if artifact.get("profile") not in PUBLIC_PROFILES:
        errors.add("INVALID_RELEASE_PROFILE")
    if artifact.get("basePackageId") != PUBLIC_PACKAGE_ID:
        errors.add("PUBLIC_BASE_PACKAGE_REQUIRED")

    forbidden_markers = _forbidden_text_markers(contract)

    def inspect_text(value: str) -> None:
        lower = value.lower()
        if any(marker in lower for marker in forbidden_markers):
            errors.add("PRIVATE_CONTENT_MARKER")
        for package_id in re.findall(r"rvtt-rule://([\w.-]+)", lower):
            if package_id != PUBLIC_PACKAGE_ID:
                errors.add("NON_PUBLIC_RULE_LINK")

    def inspect_metadata(value: object) -> None:
        if not isinstance(value, dict):
            return
        for key, nested in value.items():
            normalized = re.sub(r"[^a-z0-9]", "", str(key).lower())
            if normalized in FORBIDDEN_METADATA_KEYS:
                errors.add("PRIVATE_SOURCE_METADATA")
            if isinstance(nested, str):
                inspect_text(nested)
            elif isinstance(nested, dict):
                inspect_metadata(nested)

    package_ids = artifact.get("packageIds")
    if not isinstance(package_ids, list):
        errors.add("PACKAGE_INVENTORY_REQUIRED")
    else:
        for package_id in package_ids:
            if package_id == contract["packageId"]:
                errors.add("PRIVATE_PACKAGE_PRESENT")
            inspect_text(str(package_id))

    files = artifact.get("files")
    if not isinstance(files, list):
        errors.add("OUTPUT_FILE_INVENTORY_REQUIRED")
    else:
        for file in files:
            if not isinstance(file, dict) or not isinstance(file.get("path"), str):
                errors.add("INVALID_OUTPUT_FILE")
                continue
            inspect_text(file["path"])
            if isinstance(file.get("content"), str):
                inspect_text(file["content"])
            inspect_metadata(file.get("metadata"))

    rule_links = artifact.get("ruleLinks")
    if not isinstance(rule_links, list):
        errors.add("RULE_LINK_INVENTORY_REQUIRED")
    else:
        for link in rule_links:
            inspect_text(str(link))

    license_data = artifact.get("license")
    if not isinstance(license_data, dict) or not (
        license_data.get("packageId") == PUBLIC_PACKAGE_ID
        and license_data.get("licenseId") == "CC-BY-4.0"
        and license_data.get("attributionRequired") is True
        and isinstance(license_data.get("attributionText"), str)
        and license_data["attributionText"]
    ):
        errors.add("SRD_ATTRIBUTION_REQUIRED")
    return sorted(errors)


def build_filesystem_inventory(staging_root: Path) -> tuple[dict | None, list[str]]:
    errors: list[str] = []
    if not staging_root.is_dir():
        return None, ["STAGING_ROOT_MISSING"]
    inventory_path = staging_root / "release-content-inventory.json"
    if not inventory_path.is_file():
        return None, ["STAGING_INVENTORY_MISSING"]
    try:
        manifest = json.loads(inventory_path.read_text(encoding="utf-8"))
    except Exception:
        return None, ["STAGING_INVENTORY_INVALID"]
    if not isinstance(manifest, dict):
        return None, ["STAGING_INVENTORY_INVALID"]

    actual_paths = sorted(
        path.relative_to(staging_root).as_posix()
        for path in staging_root.rglob("*")
        if path.is_file() and path != inventory_path
    )
    declared_paths = manifest.get("outputFiles")
    if not isinstance(declared_paths, list) or sorted(declared_paths) != actual_paths:
        errors.append("STAGING_INVENTORY_INCOMPLETE")

    file_metadata = manifest.get("fileMetadata")
    if not isinstance(file_metadata, dict):
        file_metadata = {}
        errors.append("STAGING_FILE_METADATA_INVALID")
    files = []
    for relative in actual_paths:
        path = staging_root / relative
        payload = path.read_bytes()
        files.append(
            {
                "path": relative,
                "content": payload.decode("utf-8", errors="ignore"),
                "metadata": file_metadata.get(relative, {}),
            }
        )
    artifact = deepcopy(manifest)
    artifact["files"] = files
    return artifact, errors


def validate_staging_root(staging_root: Path, contract: dict) -> list[str]:
    artifact, errors = build_filesystem_inventory(staging_root)
    if artifact is not None:
        errors.extend(validate_artifact(artifact, contract))
    return sorted(set(errors))


def validate(root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    for relative in REQUIRED_FILES:
        if not (root / relative).is_file():
            errors.append(f"rules profile gate: missing {relative}")
    if errors:
        return errors

    try:
        contract = private_contract(root)
    except ValueError as exc:
        return [f"BuiltinPackIndex.lua: {exc}"]

    resolver = (root / "src/ServerStorage/RVTT/Content/RulePackageResolver.lua").read_text(encoding="utf-8")
    gate = (root / "src/ServerStorage/RVTT/Content/ReleaseContentLeakGate.lua").read_text(encoding="utf-8")
    status = (root / "src/ReplicatedStorage/RVTT/ContentRuntime/RuleProfileStatus.lua").read_text(encoding="utf-8")
    resolver_spec = (root / "tests/Unit/RulePackageResolver.spec.lua").read_text(encoding="utf-8")
    runner = (root / "tests/TestRunner.server.lua").read_text(encoding="utf-8")
    workflow = (REPO_ROOT / ".github/workflows/validate-rvtt-implementation.yml").read_text(encoding="utf-8")

    for marker in (
        "BuiltinPackIndex",
        "resolveWithIndex",
        "readinessFailure(package",
        "package.version",
        "package.sourceBindingKey",
        "package.sourceRoot",
        "package.expectedContentCounts",
        "allowSrdFallback",
        "clientSafeStatus",
    ):
        if marker not in resolver:
            errors.append(f"RulePackageResolver.lua: missing single-authority marker {marker}")
    duplicated_values = [
        contract["version"],
        contract["sourceBindingKey"],
        contract["sourceRoot"],
        *[str(value) for value in contract["expectedContentCounts"].values()],
    ]
    for value in duplicated_values:
        if value in resolver:
            errors.append(f"RulePackageResolver.lua: duplicates BuiltinPackIndex private metadata value {value}")
    for marker in ("fixture-revision-from-index", "expectedContentCounts.classes = 77", "resolveWithIndex"):
        if marker not in resolver_spec:
            errors.append(f"RulePackageResolver.spec.lua: missing package-index drift regression {marker}")
    for marker in ("BuiltinPackIndex", "PRIVATE_PACKAGE_AUTHORITY_MISSING", "SRD_ATTRIBUTION_REQUIRED"):
        if marker not in gate:
            errors.append(f"ReleaseContentLeakGate.lua: missing authority/enforcement marker {marker}")

    allowed_status_fields = {
        "activeProfile", "basePackageId", "fallbackActive", "fallbackReasonCode", "attributionRequired"
    }
    assigned_fields = set(re.findall(r"^\s*([A-Za-z][A-Za-z0-9_]*)\s*=", status, re.MULTILINE))
    if assigned_fields != allowed_status_fields:
        errors.append("RuleProfileStatus.lua: client-safe field allowlist drifted")
    if "unit-rule-package-resolver" not in runner or "unit-release-content-leak-gate" not in runner:
        errors.append("TestRunner.server.lua: focused rules profile gate specs are not registered")
    for marker in (
        "build_public_release_staging.py",
        "validate_rules_profile_release_gate.py --staging-root",
    ):
        if marker not in workflow:
            errors.append(f"validate-rvtt-implementation.yml: missing filesystem release gate marker {marker}")
    release_steps = workflow[workflow.find("Build public rules release staging") : workflow.find("Download pinned Roblox type definitions")]
    if "continue-on-error" in release_steps or "|| true" in release_steps:
        errors.append("validate-rvtt-implementation.yml: filesystem release gate must propagate failures")
    return errors


def run_self_tests() -> list[str]:
    failures: list[str] = []
    contract = private_contract()
    with TemporaryDirectory(prefix="rvtt-rules-release-gate-") as temporary:
        base = Path(temporary)

        def clean(name: str) -> Path:
            root = base / name
            build_public_release_staging(root)
            return root

        clean_root = clean("clean")
        if validate_staging_root(clean_root, contract):
            failures.append("filesystem gate self-test: clean public staging was rejected")
        if "STAGING_ROOT_MISSING" not in validate_staging_root(base / "missing", contract):
            failures.append("filesystem gate self-test: missing staging root was accepted")

        fixtures: list[tuple[Path, str]] = []
        private_package = clean("private-package")
        manifest_path = private_package / "release-content-inventory.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["packageIds"].append(contract["packageId"])
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        fixtures.append((private_package, "PRIVATE_PACKAGE_PRESENT"))

        private_marker = clean("private-marker")
        (private_marker / "unlisted-private-marker.txt").write_text(contract["sourceRoot"], encoding="utf-8")
        fixtures.append((private_marker, "PRIVATE_CONTENT_MARKER"))
        fixtures.append((private_marker, "STAGING_INVENTORY_INCOMPLETE"))

        private_metadata = clean("private-metadata")
        manifest_path = private_metadata / "release-content-inventory.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["fileMetadata"]["rules/public-index.json"]["sourceRevision"] = "synthetic"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        fixtures.append((private_metadata, "PRIVATE_SOURCE_METADATA"))

        private_link = clean("private-link")
        manifest_path = private_link / "release-content-inventory.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["ruleLinks"] = [f"rvtt-rule://{contract['packageId']}/fixture/document"]
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        fixtures.append((private_link, "NON_PUBLIC_RULE_LINK"))

        missing_license = clean("missing-license")
        manifest_path = missing_license / "release-content-inventory.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest.pop("license")
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        fixtures.append((missing_license, "SRD_ATTRIBUTION_REQUIRED"))

        wrong_license = clean("wrong-license")
        manifest_path = wrong_license / "release-content-inventory.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["license"]["licenseId"] = "WRONG"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        fixtures.append((wrong_license, "SRD_ATTRIBUTION_REQUIRED"))

        for staging_root, expected in fixtures:
            if expected not in validate_staging_root(staging_root, contract):
                failures.append(f"filesystem gate self-test: {staging_root.name} did not fail with {expected}")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate RVTT rules profile and staged public release output")
    parser.add_argument("--staging-root", required=True, type=Path)
    args = parser.parse_args()
    errors = validate()
    errors.extend(run_self_tests())
    errors.extend(validate_staging_root(args.staging_root.resolve(), private_contract()))
    if errors:
        print("Rules profile/filesystem release gate validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print("Rules profile/filesystem release gate validation passed: single authority + actual staging + 8 fail-closed filesystem fixtures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
