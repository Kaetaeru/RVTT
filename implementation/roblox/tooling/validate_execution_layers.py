from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "manifests/execution-layers.json"
CURRENT_MODEL = ROOT / "manifests/implementation-system-model.json"
DOC = ROOT / "GREENFIELD-EXECUTION-LAYERS.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
SYSTEMS = ROOT / "SYSTEMS.md"
ACTIVE_TASK = ROOT.parents[1] / ".github/CODEX-ACTIVE-TASK.md"
AGENTS = ROOT.parents[1] / "AGENTS.md"


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def main() -> int:
    errors: list[str] = []
    try:
        registry = load(REGISTRY)
        current = load(CURRENT_MODEL)
    except Exception as exc:
        print(f"execution-layer validation failed: {exc}")
        return 1

    if registry.get("status") != "RETIRED_IMPLEMENTATION_MODEL":
        errors.append("old execution registry must remain RETIRED_IMPLEMENTATION_MODEL")
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

    semantics = current.get("executionLayerSemantics")
    if not isinstance(semantics, dict):
        errors.append("current executionLayerSemantics is required")
    else:
        repository_logic = semantics.get("repositoryLogic", "")
        e0_core = semantics.get("e0CoreEngine", "")
        if not isinstance(repository_logic, str) or "classification" not in repository_logic:
            errors.append("repositoryLogic must be explicitly defined as a classification")
        if not isinstance(e0_core, str) or "mandatory pre-Studio foundation subset" not in e0_core:
            errors.append("e0CoreEngine must be explicitly defined as the mandatory pre-Studio subset")

    systems = current.get("systems", [])
    all_system_ids = {item.get("id") for item in systems if isinstance(item, dict)}
    e0 = current.get("e0RequiredSystemSeams", [])
    deferred = current.get("deferredRepositoryFeatureSystems", [])
    if not isinstance(e0, list) or not isinstance(deferred, list):
        errors.append("E0/deferred system lists are required")
        e0 = []
        deferred = []
    if set(e0) | set(deferred) != all_system_ids:
        errors.append(
            "every current System must currently be classified as E0-required seam or deferred repository feature; "
            f"unclassified={sorted(all_system_ids - (set(e0) | set(deferred)))}"
        )
    if set(e0) & set(deferred):
        errors.append("E0-required and deferred repository feature sets must not overlap")
    if len(e0) >= len(all_system_ids):
        errors.append("E0 must remain a strict subset of all repository-capable System responsibilities")
    if set(deferred) != {"D6", "D7", "U2"}:
        errors.append("current deferred feature set must be D6,D7,U2")

    for required_e0 in ["A8", "W5", "W6", "W7", "C1", "C2", "C3", "S2"]:
        if required_e0 not in e0:
            errors.append(f"{required_e0} must preserve an E0 seam before its E1/human integration")

    ready = current.get("readyGateComposition", {})
    if ready.get("finalOwner") != "A1":
        errors.append("A1 must remain sole final gameplay-ready gate owner")
    expected_ready = {
        "authorityRecoveryReady": "A7",
        "projectionSyncReady": "A6",
        "sceneEssentialReady": "W7",
        "clientReplicaReady": "C1",
    }
    if ready.get("inputs") != expected_ready:
        errors.append("typed readiness evidence mapping drifted")

    model = MODEL.read_text(encoding="utf-8")
    systems_text = SYSTEMS.read_text(encoding="utf-8")
    task = ACTIVE_TASK.read_text(encoding="utf-8")
    agents = AGENTS.read_text(encoding="utf-8")
    markers = [
        ("implementation model", model, "REPOSITORY_LOGIC"),
        ("implementation model", model, "E0_CORE_ENGINE"),
        ("implementation model", model, "CORE_ENGINE_COMPLETE"),
        ("implementation model", model, "U0-A HTML/UI Reference Distillation"),
        ("system model", systems_text, "Repository Core Engine 전체 완료 전 Studio/MCP 구현을 시작하지 않는다"),
        ("system model", systems_text, "A3 Ordering + Transaction + Outbox atomic commit"),
        ("system model", systems_text, "A8 Event Delivery"),
        ("active task", task, "- status: `R3_VALIDATED_AWAITING_FREEZE_DECISION`"),
        ("active task", task, "CORE_ENGINE_COMPLETE 전 Studio/MCP 작업 금지"),
        ("agent rules", agents, "R3 = VALIDATED · NOT FROZEN · AWAITING USER FREEZE DECISION"),
        ("agent rules", agents, "NEXT = USER R3 FREEZE DECISION"),
    ]
    for label, text, marker in markers:
        if marker not in text:
            errors.append(f"{label} missing required execution marker: {marker}")

    if errors:
        print("RVTT execution-layer validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print(
        "RVTT execution-layer validation passed: "
        f"systems={len(all_system_ids)}; e0_required_seams={len(e0)}; deferred_repository_features={len(deferred)}; "
        "REPOSITORY_LOGIC!=E0_CORE_ENGINE; A1_ready_gate=PASS; A3_to_A8_event_boundary=PASS; "
        "R3=VALIDATED_AWAITING_FREEZE; R3->user freeze->R4->Implementation Branch->E0->CORE_ENGINE_COMPLETE->E1 Studio->U0->E2 preserved"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
