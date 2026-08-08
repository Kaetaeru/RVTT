from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any
import json
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
PACKAGE_ID = "rvtt.core.baseline"
PACKAGE_ROOT = ROOT / "content-source" / "packages" / PACKAGE_ID
SERVER_ROOT = ROOT / "src" / "ServerStorage" / "RVTT" / "Content"
PACK_ROOT = SERVER_ROOT / "Packs" / PACKAGE_ID
CLIENT_ROOT = ROOT / "src" / "ReplicatedStorage" / "RVTT" / "ContentRuntime"

REQUIRED_PATHS = {
    PACKAGE_ROOT / "package.manifest.json",
    SERVER_ROOT / "AssetPackageRegistry.lua",
    SERVER_ROOT / "AssetRegistryValidator.lua",
    SERVER_ROOT / "ClientAssetViewBuilder.lua",
    PACK_ROOT / "SourceIdentity.lua",
    PACK_ROOT / "Manifest.lua",
    PACK_ROOT / "AssetRegistry.lua",
    PACK_ROOT / "ValidationProfile.lua",
    CLIENT_ROOT / "AssetCatalog.lua",
    ROOT / "tests" / "Unit" / "AssetRegistry.spec.lua",
}
EXECUTABLE_CLASSES = {
    "Script",
    "LocalScript",
    "ModuleScript",
    "RemoteEvent",
    "RemoteFunction",
    "UnreliableRemoteEvent",
}
CLIENT_SAFE_FIELDS = {
    "assetId",
    "packageId",
    "version",
    "kind",
    "displayNameKey",
    "publishedAssetId",
    "thumbnailAssetId",
    "bounds",
    "pivot",
    "placementProfile",
    "collisionProfile",
    "navigationProfile",
    "interactionCapabilities",
    "performanceBudget",
    "rights",
}


def _identity() -> dict[str, Any]:
    return {
        "packageId": "rvtt.test.assets",
        "version": "1.0.0",
        "assetSetDigest": "fixture-digest",
        "clientExportAllowed": True,
    }


def _asset(asset_id: str, kind: str = "token-prefab") -> dict[str, Any]:
    value: dict[str, Any] = {
        "assetId": asset_id,
        "stableKey": asset_id,
        "packageId": "rvtt.test.assets",
        "version": "1.0.0",
        "kind": kind,
        "displayNameKey": "test.asset",
        "sourceContentHash": "test-only-source-hash",
        "runtimeContentAddress": "test-only/runtime",
        "thumbnailAssetId": "test-only-thumbnail",
        "bounds": {"x": 4, "y": 6, "z": 4},
        "pivot": {"mode": "feet", "x": 0, "y": -3, "z": 0},
        "placementProfile": {
            "footprint": {"x": 4, "y": 0, "z": 4},
            "selectionBounds": {"x": 4, "y": 6, "z": 4},
            "surface": "floor",
        },
        "collisionProfile": {"mode": "query-only"},
        "navigationProfile": {"mode": "token"},
        "interactionCapabilities": ["select"],
        "performanceBudget": {"instances": 3, "triangles": 100, "textureMemoryKb": 64},
        "dependencies": [],
        "rights": {"licenseId": "TEST-ONLY", "status": "synthetic_fixture", "redistributable": False},
        "provenance": {
            "sourceType": "synthetic_test_fixture",
            "sourceReference": "validate_asset_registry.py",
            "sourceRevision": "1",
            "privateNote": "never project",
        },
        "rigProfile": {"mode": "none"},
        "animationProfile": {"mode": "none"},
        "cameraFocus": {"height": 3},
        "sourcePayloadClasses": ["Model", "MeshPart"],
        "clientExportAllowed": True,
        "serverValidationSecret": "never project",
    }
    if kind == "prop-prefab":
        value.pop("rigProfile")
        value.pop("animationProfile")
        value.pop("cameraFocus")
        value["interactionSockets"] = []
        value["stateVariants"] = []
    return value


def validate_fixture(source: dict[str, Any], manifest: dict[str, Any], assets: list[dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    for field in ("packageId", "version", "assetSetDigest"):
        if source.get(field) != manifest.get(field):
            errors.append(f"source/server identity drift: {field}")
    by_id: dict[str, dict[str, Any]] = {}
    stable_keys: set[str] = set()
    for asset in assets:
        asset_id = str(asset.get("assetId", "<missing>"))
        if asset_id in by_id:
            errors.append(f"{asset_id}: duplicate assetId")
        by_id[asset_id] = asset
        stable_key = asset.get("stableKey")
        if stable_key in stable_keys:
            errors.append(f"{asset_id}: duplicate stableKey")
        stable_keys.add(stable_key)
        if asset.get("packageId") != manifest.get("packageId") or asset.get("version") != manifest.get("version"):
            errors.append(f"{asset_id}: package identity mismatch")
        if not isinstance(asset.get("clientExportAllowed"), bool):
            errors.append(f"{asset_id}: clientExportAllowed must be explicit")
        rights = asset.get("rights", {})
        if not rights.get("licenseId") or not rights.get("status") or not isinstance(rights.get("redistributable"), bool):
            errors.append(f"{asset_id}: missing rights metadata")
        provenance = asset.get("provenance", {})
        if not all(provenance.get(field) for field in ("sourceType", "sourceReference", "sourceRevision")):
            errors.append(f"{asset_id}: missing provenance metadata")
        budget = asset.get("performanceBudget", {})
        if any(not isinstance(budget.get(field), (int, float)) or budget[field] < 0 for field in ("instances", "triangles", "textureMemoryKb")):
            errors.append(f"{asset_id}: invalid performanceBudget")
        if asset.get("kind") == "token-prefab":
            placement = asset.get("placementProfile", {})
            if asset.get("pivot", {}).get("mode") != "feet" or not asset.get("bounds"):
                errors.append(f"{asset_id}: missing token geometry")
            if not placement.get("footprint") or not placement.get("selectionBounds"):
                errors.append(f"{asset_id}: missing token footprint")
            if any(not asset.get(field) for field in ("rigProfile", "animationProfile", "cameraFocus")):
                errors.append(f"{asset_id}: missing token metadata")
        if EXECUTABLE_CLASSES.intersection(asset.get("sourcePayloadClasses", [])):
            errors.append(f"{asset_id}: executable payload declaration")

    marks: dict[str, str] = {}
    def visit(asset_id: str) -> None:
        if marks.get(asset_id) == "visiting":
            errors.append(f"{asset_id}: dependency cycle")
            return
        if marks.get(asset_id) == "done":
            return
        marks[asset_id] = "visiting"
        for dependency in by_id[asset_id].get("dependencies", []):
            if dependency not in by_id:
                errors.append(f"{asset_id}: invalid dependency {dependency}")
            else:
                visit(dependency)
        marks[asset_id] = "done"
    for asset_id in by_id:
        visit(asset_id)
    return errors


def project_client_safe(manifest: dict[str, Any], assets: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if manifest.get("clientExportAllowed") is not True:
        return []
    return [
        {field: deepcopy(asset[field]) for field in CLIENT_SAFE_FIELDS if field in asset}
        for asset in assets
        if asset.get("clientExportAllowed") is True
    ]


def validate_required_paths(available: set[Path]) -> list[str]:
    return [f"missing asset-registry boundary {path.relative_to(REPO_ROOT)}" for path in sorted(REQUIRED_PATHS - available)]


def validate(root: Path = ROOT) -> list[str]:
    if root != ROOT:
        raise ValueError("validate_asset_registry only supports its repository checkout")
    errors = validate_required_paths({path for path in REQUIRED_PATHS if path.is_file()})
    manifest_path = PACKAGE_ROOT / "package.manifest.json"
    if not manifest_path.is_file():
        return errors
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as exc:
        return errors + [f"{manifest_path.relative_to(REPO_ROOT)}: {exc}"]
    if manifest.get("schemaVersion") != 1:
        errors.append("asset source manifest schemaVersion must be 1")
    if manifest.get("packageId") != PACKAGE_ID or manifest.get("version") != "2026.08.06":
        errors.append("asset source manifest identity drift")
    if manifest.get("assets") != []:
        errors.append("baseline production asset registry must stay empty until approved assets exist")
    policy = manifest.get("importPolicy", {})
    if policy.get("allowExecutablePayloads") is not False:
        errors.append("asset source import policy must fail closed for executable payloads")
    if EXECUTABLE_CLASSES.intersection(policy.get("allowedPayloadClasses", [])):
        errors.append("asset source import policy allows executable payload classes")

    identity_literals = (PACKAGE_ID, manifest.get("version", ""), manifest.get("assetSetDigest", ""))
    for path in (PACK_ROOT / "SourceIdentity.lua", PACK_ROOT / "Manifest.lua"):
        if path.is_file():
            text = path.read_text(encoding="utf-8")
            for literal in identity_literals:
                if not literal or f'"{literal}"' not in text:
                    errors.append(f"{path.relative_to(REPO_ROOT)}: source/server identity drift")
    if (SERVER_ROOT / "AssetPackageRegistry.lua").is_file():
        registry_text = (SERVER_ROOT / "AssetPackageRegistry.lua").read_text(encoding="utf-8")
        for marker in ("BuiltinPackIndex", "ClientAssetViewBuilder", "validatePackage", "pack.assetRegistry"):
            if marker not in registry_text:
                errors.append(f"AssetPackageRegistry.lua: missing one-way registry link {marker}")
    if (SERVER_ROOT / "ClientAssetViewBuilder.lua").is_file():
        builder_text = (SERVER_ROOT / "ClientAssetViewBuilder.lua").read_text(encoding="utf-8")
        for forbidden_field in (
            "sourceContentHash",
            "runtimeContentAddress",
            "provenance",
            "sourcePayloadClasses",
            "serverValidationSecret",
        ):
            if re.search(rf"\b{re.escape(forbidden_field)}\s*=", builder_text):
                errors.append(f"ClientAssetViewBuilder.lua: projects forbidden field {forbidden_field}")
    if (SERVER_ROOT / "BuiltinPackIndex.lua").is_file() and PACKAGE_ID not in (SERVER_ROOT / "BuiltinPackIndex.lua").read_text(encoding="utf-8"):
        errors.append("BuiltinPackIndex.lua: missing baseline package authority")
    if (CLIENT_ROOT / "AssetCatalog.lua").is_file():
        client_catalog = (CLIENT_ROOT / "AssetCatalog.lua").read_text(encoding="utf-8")
        for forbidden in ("sourceContentHash", "runtimeContentAddress", "provenance", "private", "placeholder", "count"):
            if re.search(rf"\b{re.escape(forbidden)}\b", client_catalog, re.IGNORECASE):
                errors.append(f"AssetCatalog.lua: client-safe view contains forbidden token {forbidden}")
    return errors


def run_self_tests() -> list[str]:
    failures: list[str] = []
    source = _identity()
    manifest = _identity()
    token = _asset("asset.test.token")
    prop = _asset("asset.test.prop", "prop-prefab")
    prop["dependencies"] = [token["assetId"]]
    if validate_fixture(source, manifest, []):
        failures.append("empty registry fixture should pass")
    if validate_fixture(source, manifest, [token, prop]):
        failures.append("synthetic token/prop fixture should pass")

    fixtures: list[tuple[str, dict[str, Any], dict[str, Any], list[dict[str, Any]], str]] = []
    fixtures.append(("duplicate", source, manifest, [token, deepcopy(token)], "duplicate assetId"))
    duplicate_key_a = _asset("asset.test.key-a"); duplicate_key_b = _asset("asset.test.key-b")
    duplicate_key_b["stableKey"] = duplicate_key_a["stableKey"]
    fixtures.append(("duplicate-key", source, manifest, [duplicate_key_a, duplicate_key_b], "duplicate stableKey"))
    missing_rights = deepcopy(token); missing_rights["rights"] = {}; missing_rights["provenance"] = {}
    fixtures.append(("rights", source, manifest, [missing_rights], "missing rights metadata"))
    missing_geometry = deepcopy(token); missing_geometry["pivot"] = {}; missing_geometry["placementProfile"] = {}
    fixtures.append(("geometry", source, manifest, [missing_geometry], "missing token geometry"))
    cycle_a = _asset("asset.test.cycle-a"); cycle_b = _asset("asset.test.cycle-b")
    cycle_a["dependencies"] = [cycle_b["assetId"]]; cycle_b["dependencies"] = [cycle_a["assetId"]]
    fixtures.append(("cycle", source, manifest, [cycle_a, cycle_b], "dependency cycle"))
    missing_dependency = deepcopy(token); missing_dependency["dependencies"] = ["asset.test.does-not-exist"]
    fixtures.append(("missing-dependency", source, manifest, [missing_dependency], "invalid dependency"))
    drift = deepcopy(source); drift["version"] = "2.0.0"
    fixtures.append(("drift", drift, manifest, [], "source/server identity drift"))
    executable = deepcopy(token); executable["sourcePayloadClasses"] = ["Model", "ModuleScript"]
    fixtures.append(("executable", source, manifest, [executable], "executable payload declaration"))
    negative = deepcopy(token); negative["performanceBudget"]["triangles"] = -1
    fixtures.append(("budget", source, manifest, [negative], "invalid performanceBudget"))
    for name, fixture_source, fixture_manifest, fixture_assets, expected in fixtures:
        if not any(expected in error for error in validate_fixture(fixture_source, fixture_manifest, fixture_assets)):
            failures.append(f"fixture {name} did not reject {expected}")

    private = deepcopy(token); private["clientExportAllowed"] = False
    view = project_client_safe(manifest, [token, private])
    if len(view) != 1 or view[0].get("assetId") != token["assetId"]:
        failures.append("private asset was not completely absent from client projection")
    if set(view[0]) - CLIENT_SAFE_FIELDS:
        failures.append("client projection emitted a non-allowlisted field")
    if any(field in view[0] for field in ("sourceContentHash", "runtimeContentAddress", "provenance", "serverValidationSecret")):
        failures.append("client projection leaked server/private metadata")
    private_manifest = deepcopy(manifest); private_manifest["clientExportAllowed"] = False
    if project_client_safe(private_manifest, [token]):
        failures.append("non-exportable package was not completely absent from client projection")

    available = set(REQUIRED_PATHS)
    missing_boundary = next(path for path in REQUIRED_PATHS if path.name == "AssetCatalog.lua")
    if not validate_required_paths(available - {missing_boundary}):
        failures.append("missing client-safe boundary fixture was not rejected")
    return failures


def main() -> int:
    errors = validate()
    errors.extend(run_self_tests())
    if errors:
        print("Asset registry validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print("Asset registry validation passed: empty production registry and 14 focused boundary/validation fixtures")
    return 0


if __name__ == "__main__":
    sys.exit(main())
