from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
ACTIVE_TASK = REPO_ROOT / ".github/CODEX-ACTIVE-TASK.md"
ROUTING_README = REPO_ROOT / ".github/README.md"
AGENTS = REPO_ROOT / "AGENTS.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
SYSTEMS = ROOT / "SYSTEMS.md"
WORKSPACE_README = ROOT / "README.md"
WORK_ORDER = ROOT / "CURRENT-WORK-ORDER.md"
EXECUTION_RULES = ROOT / "EXECUTION-TEST-RULES.md"
STUDIO_POLICY = ROOT / "ROBLOX-STUDIO-MCP-TEST-POLICY.md"
BOUNDARY = ROOT / "greenfield-boundary.json"
GREENFIELD_PROJECT = ROOT / "greenfield.project.json"
CURRENT_MANIFEST = ROOT / "manifests/implementation-system-model.json"
BASE_SCENARIOS = ROOT / "manifests/scenario-base-catalog.json"
EXPANDED_SCENARIOS = ROOT / "manifests/scenario-expanded-catalog.json"
SEMANTIC_AUDIT_V3 = ROOT / "manifests/scenario-semantic-audit-v3.json"

RESET_BASELINE_COMMIT = "cce0f4fbc01e91437ccbfc8b2341d903f15bc785"
LEGACY_LOCK_PATHS = [
    "implementation/roblox/src",
    "implementation/roblox/default.project.json",
]


def git_object(commit: str, path: str) -> str | None:
    result = subprocess.run(
        ["git", "rev-parse", f"{commit}:{path}"],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be object")
    return value


def collect_paths(value: object) -> list[str]:
    paths: list[str] = []
    if isinstance(value, dict):
        for key, item in value.items():
            if key == "$path" and isinstance(item, str):
                paths.append(item)
            else:
                paths.extend(collect_paths(item))
    elif isinstance(value, list):
        for item in value:
            paths.extend(collect_paths(item))
    return paths


def main() -> int:
    errors: list[str] = []

    try:
        boundary = load_json(BOUNDARY)
        greenfield_project = load_json(GREENFIELD_PROJECT)
    except Exception as exc:
        print(f"RVTT implementation planning boundary validation failed: {exc}")
        return 1

    active = ACTIVE_TASK.read_text(encoding="utf-8")
    routing = ROUTING_README.read_text(encoding="utf-8")
    agents = AGENTS.read_text(encoding="utf-8")
    model = MODEL.read_text(encoding="utf-8")
    systems = SYSTEMS.read_text(encoding="utf-8")
    workspace = WORKSPACE_README.read_text(encoding="utf-8")
    work_order = WORK_ORDER.read_text(encoding="utf-8")
    execution_rules = EXECUTION_RULES.read_text(encoding="utf-8")
    studio_policy = STUDIO_POLICY.read_text(encoding="utf-8")

    required_markers = [
        ("Active Task", active, "- status: `R3_VALIDATED_AWAITING_FREEZE_DECISION`"),
        ("Active Task", active, "sourceImplementationAllowed: `false`"),
        ("Active Task", active, "studioImplementationAllowed: `false`"),
        ("AGENTS.md", agents, "OLD GREENFIELD MODEL = RETIRED"),
        ("AGENTS.md", agents, "R3 = VALIDATED · NOT FROZEN · AWAITING USER FREEZE DECISION"),
        ("AGENTS.md", agents, "NEXT = USER R3 FREEZE DECISION"),
        ("Implementation Model", model, "DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED"),
        ("Implementation Model", model, "CORE_ENGINE_COMPLETE 전 Studio/MCP 작업을 시작하지 않는다"),
        ("SYSTEMS.md", systems, "APPROVED_SYSTEM_AUTHORITY"),
        ("SYSTEMS.md", systems, "34 System Responsibility Model"),
        ("Routing README", routing, "R3_VALIDATED_AWAITING_FREEZE_DECISION"),
        ("Workspace README", workspace, "src/**\n= 기존 Production Source\n= READ_ONLY_REFERENCE"),
        ("Workspace README", workspace, "greenfield/src/**\n= 새 Greenfield Source root"),
        ("Workspace README", workspace, "CORE_ENGINE_COMPLETE 전 Studio/MCP 구현은 금지"),
        ("Current Work Order", work_order, "- 상태: `R3_VALIDATED_AWAITING_FREEZE_DECISION`"),
        ("Current Work Order", work_order, "NEXT = USER R3 FREEZE DECISION"),
        ("Execution Rules", execution_rules, "- 상태: `ACTIVE · STAGED_EXECUTION_POLICY`"),
        ("Execution Rules", execution_rules, "CORE_ENGINE_COMPLETE 이후에만"),
        ("Studio Policy", studio_policy, "ACTIVE_FUTURE_E1_PATH · CURRENTLY_BLOCKED"),
        ("Studio Policy", studio_policy, "CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않는다"),
    ]
    for label, text, marker in required_markers:
        if marker not in text:
            errors.append(f"{label}: missing current-boundary marker {marker}")

    expected_boundary = {
        "status": "ACTIVE_R3_VALIDATED_AWAITING_FREEZE",
        "currentAuthority": ".github/CODEX-ACTIVE-TASK.md",
        "implementationModelAuthority": "implementation/roblox/IMPLEMENTATION-MODEL.md",
        "systemAuthority": "implementation/roblox/SYSTEMS.md",
        "greenfieldProject": "greenfield.project.json",
        "sourceRoot": "greenfield/src",
        "testRoot": "greenfield/tests",
        "sourceImplementationAllowed": False,
        "studioImplementationAllowed": False,
        "legacySourceRoot": "src",
        "legacyProject": "default.project.json",
        "legacyWritePolicy": "READ_ONLY_REFERENCE",
        "nextGate": "USER_R3_FREEZE_DECISION",
        "studioActivationGate": "CORE_ENGINE_COMPLETE",
    }
    for key, expected in expected_boundary.items():
        if boundary.get(key) != expected:
            errors.append(f"greenfield-boundary.json {key} drifted: expected={expected!r} actual={boundary.get(key)!r}")

    project_paths = collect_paths(greenfield_project)
    if not project_paths:
        errors.append("greenfield.project.json must map greenfield source paths")
    for path in project_paths:
        if not path.startswith("greenfield/src/"):
            errors.append(f"greenfield.project.json must not map legacy source path: {path}")

    for path, label in (
        (CURRENT_MANIFEST, "implementation-system-model.json"),
        (BASE_SCENARIOS, "scenario-base-catalog.json"),
        (EXPANDED_SCENARIOS, "scenario-expanded-catalog.json"),
        (SEMANTIC_AUDIT_V3, "scenario-semantic-audit-v3.json"),
    ):
        if not path.exists():
            errors.append(f"{label} must exist before R3 Freeze")

    for path in LEGACY_LOCK_PATHS:
        baseline = git_object(RESET_BASELINE_COMMIT, path)
        current = git_object("HEAD", path)
        if baseline is None:
            errors.append(f"cannot resolve reset baseline object for {path}")
            continue
        if current != baseline:
            errors.append(
                f"legacy write-lock drift after reset for {path}: "
                f"baseline={baseline} current={current}"
            )

    if errors:
        print("RVTT implementation planning boundary validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print(
        "RVTT implementation planning boundary validation passed: "
        f"resetBaseline={RESET_BASELINE_COMMIT[:12]}; R3=VALIDATED_AWAITING_FREEZE; "
        "routing=CURRENT; greenfield_source=BLOCKED; studio=BLOCKED_UNTIL_CORE_ENGINE_COMPLETE; "
        "legacy_src=READ_ONLY_REFERENCE; legacy_write_lock=PASS"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
