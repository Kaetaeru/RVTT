from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "manifests/execution-layers.json"
DOC = ROOT / "GREENFIELD-EXECUTION-LAYERS.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"


def main() -> int:
    errors: list[str] = []
    try:
        registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"retired execution registry validation failed: {exc}")
        return 1

    if registry.get("status") != "RETIRED_IMPLEMENTATION_MODEL":
        errors.append("execution registry must remain RETIRED_IMPLEMENTATION_MODEL during reset")
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
    if "Studio/MCP 작업은 Repository Core Engine 전체 완료 후에만 시작한다" not in model:
        errors.append("implementation model must preserve Core Engine before Studio rule")
    if "U0 Product UI Shell Session" not in model:
        errors.append("implementation model must preserve U0 UI shell gate")

    if errors:
        print("RVTT retired execution-layer validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print("RVTT retired execution-layer validation passed: old classes/phases=0; Core Engine->Studio->U0->Presentation process rules preserved")
    return 0


if __name__ == "__main__":
    sys.exit(main())
