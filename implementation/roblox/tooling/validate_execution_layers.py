from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "manifests/execution-layers.json"
DOC = ROOT / "GREENFIELD-EXECUTION-LAYERS.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
SYSTEMS = ROOT / "SYSTEMS.md"


def main() -> int:
    errors: list[str] = []
    try:
        registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"retired execution registry validation failed: {exc}")
        return 1

    if registry.get("status") != "RETIRED_IMPLEMENTATION_MODEL":
        errors.append("execution registry must remain RETIRED_IMPLEMENTATION_MODEL")
    if registry.get("currentExecutionClasses") != []:
        errors.append("retired execution registry must not expose currentExecutionClasses")
    if registry.get("currentPhases") != []:
        errors.append("retired execution registry must not expose currentPhases")

    preserved = registry.get("preservedProcessRules")
    if not isinstance(preserved, dict):
        errors.append("preservedProcessRules is required")
    else:
        required = {
            "studioStartsOnlyAfterCoreEngineComplete": True,
            "uiShellSessionRunsAfterIntegrationReadyBeforePresentation": True,
            "throwawayTestUiForbiddenAfterUiShellReady": True,
            "dedicatedImplementationBranchCreatedAfterE0CheckpointFreeze": True,
        }
        for key, expected in required.items():
            if preserved.get(key) is not expected:
                errors.append(f"preservedProcessRules.{key} must remain true")

    if "RETIRED_IMPLEMENTATION_MODEL" not in DOC.read_text(encoding="utf-8"):
        errors.append("GREENFIELD-EXECUTION-LAYERS.md must remain retired")

    model = MODEL.read_text(encoding="utf-8")
    systems = SYSTEMS.read_text(encoding="utf-8") if SYSTEMS.exists() else ""
    if "CORE_ENGINE_COMPLETE" not in model or "Studio/MCP" not in model:
        errors.append("implementation model must preserve CORE_ENGINE_COMPLETE before Studio/MCP")
    if "UI_SHELL_READY" not in model or "HTML/UI Reference Distillation" not in model:
        errors.append("implementation model must preserve U0 UI shell preparation and UI_SHELL_READY gate")
    if "R3 Core/Runtime/Presentation Boundary Freeze" not in model:
        errors.append("implementation model must preserve R3 before R4/E0")
    if "R4 E0 Checkpoint Freeze" not in model:
        errors.append("implementation model must preserve R4 E0 checkpoint freeze")
    if "Repository Core Engine 전체 완료 전 Studio/MCP 구현을 시작하지 않는다" not in systems:
        errors.append("SYSTEMS.md must preserve Core Engine before Studio rule")

    if errors:
        print("RVTT retired execution-layer validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print(
        "RVTT retired execution-layer validation passed: "
        "old classes/phases=0; R3->R4->Implementation Branch->E0 Core->CORE_ENGINE_COMPLETE->E1 Studio->U0->E2 preserved"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
