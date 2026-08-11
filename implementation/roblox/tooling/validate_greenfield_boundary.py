from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
CONFIG_PATH = ROOT / "greenfield-boundary.json"
MODULE_REGISTRY_PATH = ROOT / "manifests/module-contracts.json"


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def git_object(spec: str) -> str:
    result = subprocess.run(
        ["git", "rev-parse", spec],
        cwd=REPO_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"git rev-parse failed for {spec}")
    return result.stdout.strip()


def collect_paths(value: Any, found: list[str]) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "$path" and isinstance(child, str):
                found.append(PurePosixPath(child).as_posix())
            else:
                collect_paths(child, found)
    elif isinstance(value, list):
        for child in value:
            collect_paths(child, found)


def validate() -> list[str]:
    errors: list[str] = []
    try:
        config = load_json(CONFIG_PATH)
    except Exception as exc:
        return [f"greenfield boundary: cannot read config: {exc}"]

    expected = {
        "schemaVersion": 1,
        "status": "ACTIVE_PRE_G0_BOUNDARY",
        "greenfieldProject": "greenfield.project.json",
        "sourceRoot": "greenfield/src",
        "testRoot": "greenfield/tests",
        "legacySourceRoot": "src",
        "legacyProject": "default.project.json",
        "legacyWritePolicy": "READ_ONLY_REFERENCE",
        "preflightAuthority": "GREENFIELD-PREFLIGHT.md",
    }
    for key, wanted in expected.items():
        if config.get(key) != wanted:
            errors.append(f"greenfield boundary: {key} must be {wanted!r}")

    for key in ("legacySourceTreeSha", "legacyProjectBlobSha", "lockedAtCommit"):
        value = config.get(key)
        if not isinstance(value, str) or len(value) != 40:
            errors.append(f"greenfield boundary: {key} must be a 40-character git SHA")

    source_root = ROOT / str(config.get("sourceRoot", ""))
    test_root = ROOT / str(config.get("testRoot", ""))
    project_path = ROOT / str(config.get("greenfieldProject", ""))
    if not source_root.is_dir():
        errors.append("greenfield boundary: canonical source root is missing")
    if not test_root.is_dir():
        errors.append("greenfield boundary: canonical test root is missing")
    if not project_path.is_file():
        errors.append("greenfield boundary: greenfield Rojo project is missing")

    try:
        registry = load_json(MODULE_REGISTRY_PATH)
        if registry.get("sourceRoot") != config.get("sourceRoot"):
            errors.append("greenfield boundary: module contract sourceRoot disagrees with boundary config")
    except Exception as exc:
        errors.append(f"greenfield boundary: cannot read module contracts: {exc}")

    if project_path.is_file():
        try:
            project = load_json(project_path)
            paths: list[str] = []
            collect_paths(project, paths)
            if not paths:
                errors.append("greenfield boundary: Rojo project must contain at least one $path mapping")
            greenfield_prefix = str(config.get("sourceRoot", "")).rstrip("/") + "/"
            legacy_root = str(config.get("legacySourceRoot", "")).rstrip("/")
            for path in paths:
                if path == legacy_root or path.startswith(legacy_root + "/"):
                    errors.append(f"greenfield boundary: Rojo project references legacy source: {path}")
                if not path.startswith(greenfield_prefix):
                    errors.append(f"greenfield boundary: Rojo mapping escapes canonical source root: {path}")
                if not (ROOT / path).exists():
                    errors.append(f"greenfield boundary: Rojo mapping path does not exist: {path}")
        except Exception as exc:
            errors.append(f"greenfield boundary: cannot validate Rojo project: {exc}")

    legacy_root = str(config.get("legacySourceRoot", ""))
    legacy_project = str(config.get("legacyProject", ""))
    try:
        actual_tree = git_object(f"HEAD:implementation/roblox/{legacy_root}")
        if actual_tree != config.get("legacySourceTreeSha"):
            errors.append(
                "greenfield boundary: legacy src changed after Greenfield lock; "
                "do not modify it during Greenfield work"
            )
    except Exception as exc:
        errors.append(f"greenfield boundary: cannot verify legacy src lock: {exc}")

    try:
        actual_blob = git_object(f"HEAD:implementation/roblox/{legacy_project}")
        if actual_blob != config.get("legacyProjectBlobSha"):
            errors.append(
                "greenfield boundary: legacy default.project.json changed after Greenfield lock; "
                "use greenfield.project.json instead"
            )
    except Exception as exc:
        errors.append(f"greenfield boundary: cannot verify legacy project lock: {exc}")

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("RVTT Greenfield boundary validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print("RVTT Greenfield boundary validation passed: isolated project/source/tests; legacy source locked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
