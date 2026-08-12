from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_REGISTRY = ROOT / "manifests/module-contracts.json"
FUNCTION_REGISTRY = ROOT / "manifests/system-function-contracts.json"
CURRENT_MODEL = ROOT / "manifests/implementation-system-model.json"
MODULE_DOC = ROOT / "MODULE-CONTRACTS.md"
FUNCTION_DOC = ROOT / "SYSTEM-FUNCTION-CONTRACTS.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
SYSTEMS = ROOT / "SYSTEMS.md"


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def main() -> int:
    errors: list[str] = []
    try:
        modules = load(MODULE_REGISTRY)
        functions = load(FUNCTION_REGISTRY)
        current = load(CURRENT_MODEL)
    except Exception as exc:
        print(f"retired contract registry validation failed: {exc}")
        return 1

    if modules.get("status") != "RETIRED_IMPLEMENTATION_MODEL":
        errors.append("module registry must remain RETIRED_IMPLEMENTATION_MODEL")
    if modules.get("currentModules") != []:
        errors.append("retired module registry must expose zero currentModules")
    if modules.get("replacementAuthority") != "implementation/roblox/IMPLEMENTATION-MODEL.md":
        errors.append("module registry replacementAuthority drifted")

    if functions.get("status") != "RETIRED_IMPLEMENTATION_MODEL":
        errors.append("system/function registry must remain RETIRED_IMPLEMENTATION_MODEL")
    if functions.get("currentSystems") != []:
        errors.append("retired system/function registry must expose zero currentSystems")
    if functions.get("currentStableFunctions") != []:
        errors.append("retired system/function registry must expose zero currentStableFunctions")
    if functions.get("replacementAuthority") != "implementation/roblox/IMPLEMENTATION-MODEL.md":
        errors.append("system/function registry replacementAuthority drifted")

    if "RETIRED_IMPLEMENTATION_MODEL" not in MODULE_DOC.read_text(encoding="utf-8"):
        errors.append("MODULE-CONTRACTS.md must remain retired")
    if "RETIRED_IMPLEMENTATION_MODEL" not in FUNCTION_DOC.read_text(encoding="utf-8"):
        errors.append("SYSTEM-FUNCTION-CONTRACTS.md must remain retired")

    if current.get("status") != "ACTIVE_R3_REPAIRED_PENDING_FREEZE":
        errors.append("current implementation model manifest status drifted")
    systems = current.get("systems")
    requirements = current.get("requirementCapabilities")
    traces = current.get("scenarioTrace")
    if not isinstance(systems, list) or len(systems) != 34:
        errors.append("current model must expose exactly 34 systems")
    if not isinstance(requirements, list) or len(requirements) != 30:
        errors.append("current model must expose exactly 30 Requirement Capabilities")
    if not isinstance(traces, list) or len(traces) != 61:
        errors.append("current model must expose exactly 61 Scenario traces")

    model_text = MODEL.read_text(encoding="utf-8")
    systems_text = SYSTEMS.read_text(encoding="utf-8") if SYSTEMS.exists() else ""
    if "SYSTEM_MODEL_V2_REPAIRED" not in model_text:
        errors.append("IMPLEMENTATION-MODEL.md must declare repaired System Model v2")
    if "R4 E0 Checkpoint Freeze" not in model_text:
        errors.append("implementation model must preserve R4 checkpoint freeze before new Module/Stable Function contracts")
    if "APPROVED_SYSTEM_AUTHORITY" not in systems_text:
        errors.append("SYSTEMS.md approved system authority marker missing")
    if "34 System Responsibility Model" not in systems_text:
        errors.append("SYSTEMS.md must expose 34-System Responsibility Model")
    if "Requirement Capability Catalog v3" not in systems_text:
        errors.append("SYSTEMS.md must expose Requirement Capability Catalog v3")

    if errors:
        print("RVTT retired module/system/function validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print(
        "RVTT retired module/system/function validation passed: "
        "currentModules=0; currentStableFunctions=0; old registry systems=0; "
        "current model systems=34; requirement capabilities=30; scenario traces=61; "
        "new Module/Stable Function contracts still wait for R4"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
