from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "manifests/module-contracts.json"
DOC = ROOT / "MODULE-CONTRACTS.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"


def main() -> int:
    errors: list[str] = []
    try:
        registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"retired module registry validation failed: {exc}")
        return 1

    if registry.get("status") != "RETIRED_IMPLEMENTATION_MODEL":
        errors.append("module registry must remain RETIRED_IMPLEMENTATION_MODEL during reset")
    if registry.get("currentModules") != []:
        errors.append("retired module registry must not expose currentModules")
    if registry.get("replacementAuthority") != "implementation/roblox/IMPLEMENTATION-MODEL.md":
        errors.append("module registry replacementAuthority drifted")

    if "RETIRED_IMPLEMENTATION_MODEL" not in DOC.read_text(encoding="utf-8"):
        errors.append("MODULE-CONTRACTS.md must remain retired")
    if "IMPLEMENTATION_MODEL_RESET" not in MODEL.read_text(encoding="utf-8"):
        errors.append("IMPLEMENTATION-MODEL.md reset marker missing")

    if errors:
        print("RVTT retired module-contract validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print("RVTT retired module-contract validation passed: currentModules=0; new modules must be re-derived at E0 checkpoint freeze")
    return 0


if __name__ == "__main__":
    sys.exit(main())
