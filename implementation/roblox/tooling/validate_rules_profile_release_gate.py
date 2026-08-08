from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import json
import re


ROOT = Path(__file__).resolve().parents[1]
PRIVATE_PACKAGE_ID = "rvtt.test.rules.2024.integrated.ko"
PUBLIC_PACKAGE_ID = "rvtt.core.rules"
PRIVATE_PROFILES = {"development", "test", "studio-acceptance"}
PUBLIC_PROFILES = {"public", "release", "artifact"}
EXPECTED_COUNTS = {
    "classes": 12,
    "subclasses": 48,
    "backgrounds": 16,
    "species": 10,
    "feats": 75,
    "spells": 391,
}
FORBIDDEN_TEXT_MARKERS = {
    PRIVATE_PACKAGE_ID,
    "kaetaeru/d-d-2024-",
    "rvtt_private_dnd2024_ko_source",
    "10-rulebooks/integrated-2024",
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
}


def _readiness() -> dict:
    return {
        "bindingPresent": True,
        "sourceBindingKey": "RVTT_PRIVATE_DND2024_KO_SOURCE",
        "revision": "d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4",
        "sourceRoot": "10-RULEBOOKS/integrated-2024",
        "contentCounts": dict(EXPECTED_COUNTS),
    }


def resolve_profile(profile: str, options: object = None) -> dict:
    if profile not in PRIVATE_PROFILES | PUBLIC_PROFILES:
        return {"ok": False, "code": "UNKNOWN_PROFILE"}
    if profile in PUBLIC_PROFILES:
        return {
            "ok": True,
            "activeProfile": profile,
            "basePackageId": PUBLIC_PACKAGE_ID,
            "fallbackActive": False,
            "fallbackReasonCode": None,
            "attributionRequired": True,
        }
    safe_options = options if isinstance(options, dict) else {}
    evidence = safe_options.get("privateReadiness")
    code = None
    if not isinstance(evidence, dict) or evidence.get("bindingPresent") is not True:
        code = "PRIVATE_SOURCE_MISSING"
    elif evidence.get("sourceBindingKey") != "RVTT_PRIVATE_DND2024_KO_SOURCE":
        code = "SOURCE_BINDING_MISMATCH"
    elif evidence.get("revision") != "d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4":
        code = "SOURCE_REVISION_MISMATCH"
    elif evidence.get("sourceRoot") != "10-RULEBOOKS/integrated-2024":
        code = "SOURCE_ROOT_MISMATCH"
    elif evidence.get("contentCounts") != EXPECTED_COUNTS:
        code = "CONTENT_COUNT_MISMATCH"
    else:
        declared = evidence.get("declaredDigest")
        verified = evidence.get("verifiedDigest")
        if declared is not None or verified is not None:
            if not declared or not verified or declared != verified:
                code = "SOURCE_DIGEST_MISMATCH"
    if code is not None:
        if safe_options.get("allowSrdFallback") is True:
            return {
                "ok": True,
                "activeProfile": profile,
                "basePackageId": PUBLIC_PACKAGE_ID,
                "fallbackActive": True,
                "fallbackReasonCode": "INTEGRATED_TEST_PACK_UNAVAILABLE",
                "attributionRequired": True,
            }
        return {"ok": False, "code": code}
    return {
        "ok": True,
        "activeProfile": profile,
        "basePackageId": PRIVATE_PACKAGE_ID,
        "fallbackActive": False,
        "fallbackReasonCode": None,
        "attributionRequired": True,
    }


def _artifact() -> dict:
    return {
        "profile": "release",
        "basePackageId": PUBLIC_PACKAGE_ID,
        "packageIds": [PUBLIC_PACKAGE_ID],
        "files": [{
            "path": "rules/srd-index.json",
            "content": "rvtt-rule://rvtt.core.rules/combat/actions",
            "metadata": {"buildKind": "public"},
        }],
        "ruleLinks": ["rvtt-rule://rvtt.core.rules/conditions/prone"],
        "license": {
            "packageId": PUBLIC_PACKAGE_ID,
            "licenseId": "CC-BY-4.0",
            "attributionRequired": True,
            "attributionText": "SRD attribution fixture",
        },
    }


def validate_artifact(artifact: object) -> list[str]:
    errors: set[str] = set()
    if not isinstance(artifact, dict):
        return ["INVALID_ARTIFACT_INVENTORY"]
    if artifact.get("profile") not in PUBLIC_PROFILES:
        errors.add("INVALID_RELEASE_PROFILE")
    if artifact.get("basePackageId") != PUBLIC_PACKAGE_ID:
        errors.add("PUBLIC_BASE_PACKAGE_REQUIRED")

    def inspect_text(value: str) -> None:
        lower = value.lower()
        if any(marker in lower for marker in FORBIDDEN_TEXT_MARKERS):
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
            if package_id == PRIVATE_PACKAGE_ID:
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
    for link in artifact.get("ruleLinks", []):
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


def validate(root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    for relative in REQUIRED_FILES:
        if not (root / relative).is_file():
            errors.append(f"rules profile gate: missing {relative}")
    if errors:
        return errors

    index = (root / "src/ServerStorage/RVTT/Content/BuiltinPackIndex.lua").read_text(encoding="utf-8")
    resolver = (root / "src/ServerStorage/RVTT/Content/RulePackageResolver.lua").read_text(encoding="utf-8")
    gate = (root / "src/ServerStorage/RVTT/Content/ReleaseContentLeakGate.lua").read_text(encoding="utf-8")
    status = (root / "src/ReplicatedStorage/RVTT/ContentRuntime/RuleProfileStatus.lua").read_text(encoding="utf-8")
    runner = (root / "tests/TestRunner.server.lua").read_text(encoding="utf-8")
    for marker in (PUBLIC_PACKAGE_ID, PRIVATE_PACKAGE_ID, "defaultProfiles"):
        if marker not in index:
            errors.append(f"BuiltinPackIndex.lua: missing package authority marker {marker}")
    for marker in ("BuiltinPackIndex", "allowSrdFallback", "INTEGRATED_TEST_PACK_UNAVAILABLE", "clientSafeStatus"):
        if marker not in resolver:
            errors.append(f"RulePackageResolver.lua: missing enforcement marker {marker}")
    for marker in ("validate", "rvtt%-rule://", "SRD_ATTRIBUTION_REQUIRED", "PRIVATE_SOURCE_METADATA"):
        if marker not in gate:
            errors.append(f"ReleaseContentLeakGate.lua: missing enforcement marker {marker}")
    allowed_status_fields = {
        "activeProfile", "basePackageId", "fallbackActive", "fallbackReasonCode", "attributionRequired"
    }
    assigned_fields = set(re.findall(r"^\s*([A-Za-z][A-Za-z0-9_]*)\s*=", status, re.MULTILINE))
    if assigned_fields != allowed_status_fields:
        errors.append("RuleProfileStatus.lua: client-safe field allowlist drifted")
    if "unit-rule-package-resolver" not in runner or "unit-release-content-leak-gate" not in runner:
        errors.append("TestRunner.server.lua: focused rules profile gate specs are not registered")
    return errors


def run_self_tests() -> list[str]:
    failures: list[str] = []

    for profile in PRIVATE_PROFILES:
        result = resolve_profile(profile, {"privateReadiness": _readiness()})
        if not result.get("ok") or result.get("basePackageId") != PRIVATE_PACKAGE_ID:
            failures.append(f"profile self-test: valid {profile} did not select exactly one private base")
    for profile in PUBLIC_PROFILES:
        result = resolve_profile(profile, {"allowSrdFallback": True, "privateReadiness": "malformed"})
        if not result.get("ok") or result.get("basePackageId") != PUBLIC_PACKAGE_ID or result.get("fallbackActive"):
            failures.append(f"profile self-test: {profile} did not ignore private/fallback options")
    if resolve_profile("unknown", {"allowSrdFallback": True}).get("code") != "UNKNOWN_PROFILE":
        failures.append("profile self-test: unknown profile did not fail closed")
    fallback = resolve_profile("test", {"allowSrdFallback": True})
    if fallback.get("fallbackReasonCode") != "INTEGRATED_TEST_PACK_UNAVAILABLE":
        failures.append("profile self-test: explicit fallback was not visible")
    if resolve_profile("test", {"allowSrdFallback": "true"}).get("ok"):
        failures.append("profile self-test: malformed fallback opt-in was accepted")
    for field, code in (
        ("sourceBindingKey", "SOURCE_BINDING_MISMATCH"),
        ("revision", "SOURCE_REVISION_MISMATCH"),
        ("sourceRoot", "SOURCE_ROOT_MISMATCH"),
    ):
        evidence = _readiness()
        evidence[field] = "mismatch"
        if resolve_profile("test", {"privateReadiness": evidence}).get("code") != code:
            failures.append(f"profile self-test: {field} mismatch was not rejected")
    for count_name in EXPECTED_COUNTS:
        evidence = _readiness()
        evidence["contentCounts"][count_name] += 1
        if resolve_profile("test", {"privateReadiness": evidence}).get("code") != "CONTENT_COUNT_MISMATCH":
            failures.append(f"profile self-test: {count_name} mismatch was not rejected")
    evidence = _readiness()
    evidence.update({"declaredDigest": "a", "verifiedDigest": "b"})
    if resolve_profile("test", {"privateReadiness": evidence}).get("code") != "SOURCE_DIGEST_MISMATCH":
        failures.append("profile self-test: digest mismatch was not rejected")

    if validate_artifact(_artifact()):
        failures.append("release gate self-test: clean synthetic public artifact was rejected")
    fixtures: list[tuple[dict, str]] = []
    private_package = _artifact()
    private_package["packageIds"].append(PRIVATE_PACKAGE_ID)
    fixtures.append((private_package, "PRIVATE_PACKAGE_PRESENT"))
    for marker in (
        "Kaetaeru/D-D-2024-private",
        "RVTT_PRIVATE_DND2024_KO_SOURCE",
        "10-RULEBOOKS/integrated-2024",
        "private-rule-chunk",
        "private-search-index",
        "private-snippet-cache",
    ):
        fixture = _artifact()
        fixture["files"][0]["content"] = marker
        fixtures.append((fixture, "PRIVATE_CONTENT_MARKER"))
    source_metadata = _artifact()
    source_metadata["files"][0]["metadata"]["sourceRevision"] = "private"
    fixtures.append((source_metadata, "PRIVATE_SOURCE_METADATA"))
    private_link = _artifact()
    private_link["ruleLinks"] = ["rvtt-rule://rvtt.test.rules.2024.integrated.ko/classes/fighter"]
    fixtures.append((private_link, "NON_PUBLIC_RULE_LINK"))
    no_license = _artifact()
    no_license["license"] = None
    fixtures.append((no_license, "SRD_ATTRIBUTION_REQUIRED"))
    for fixture, expected in fixtures:
        if expected not in validate_artifact(fixture):
            failures.append(f"release gate self-test: fixture was not rejected with {expected}")
    return failures


def main() -> int:
    errors = validate()
    errors.extend(run_self_tests())
    if errors:
        print("Rules profile/release leak gate validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print("Rules profile/release leak gate validation passed: 6 profiles, 20 focused fail-closed fixtures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
