from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
ROOT_README = REPO_ROOT / "README.md"
IMPLEMENTATION_README = REPO_ROOT / "implementation/README.md"
ACTIVE_TASK = REPO_ROOT / ".github/CODEX-ACTIVE-TASK.md"
ROUTING_README = REPO_ROOT / ".github/README.md"
AGENTS = REPO_ROOT / "AGENTS.md"
PLANNING_ADDENDUM = REPO_ROOT / "AGENTS-PLANNING-ADDENDUM.md"
AGENT_TEST_STATUS = REPO_ROOT / "AGENT-TEST-STATUS.md"
REMAKE_README = REPO_ROOT / "docs/remake/README.md"
REMAKE_WORK_ORDER = REPO_ROOT / "docs/remake/CURRENT-WORK-ORDER.md"
SPEC_README = REPO_ROOT / "docs/remake/specs/README.md"
SPEC_WORK_ORDER = REPO_ROOT / "docs/remake/specs/CURRENT-SPEC-WORK-ORDER.md"
PROCESS_POLICY = REPO_ROOT / "docs/remake/product/codex-supervised-review-and-test-policy.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
SYSTEMS = ROOT / "SYSTEMS.md"
WORKSPACE_README = ROOT / "README.md"
WORK_ORDER = ROOT / "CURRENT-WORK-ORDER.md"
IMPLEMENTATION_STATUS = ROOT / "IMPLEMENTATION-STATUS.md"
EXECUTION_RULES = ROOT / "EXECUTION-TEST-RULES.md"
STUDIO_POLICY = ROOT / "ROBLOX-STUDIO-MCP-TEST-POLICY.md"
REVIEW_GATE = ROOT / "CODEX-REVIEW-TEST-GATE.md"
BOUNDARY = ROOT / "greenfield-boundary.json"
GREENFIELD_PROJECT = ROOT / "greenfield.project.json"
CURRENT_AUTHORITY = ROOT / "manifests/r3-authority-corpus.json"
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

    texts = {
        "Root README": ROOT_README.read_text(encoding="utf-8"),
        "Implementation README": IMPLEMENTATION_README.read_text(encoding="utf-8"),
        "Active Task": ACTIVE_TASK.read_text(encoding="utf-8"),
        "Routing README": ROUTING_README.read_text(encoding="utf-8"),
        "AGENTS.md": AGENTS.read_text(encoding="utf-8"),
        "Planning Addendum": PLANNING_ADDENDUM.read_text(encoding="utf-8"),
        "Agent Test Status": AGENT_TEST_STATUS.read_text(encoding="utf-8"),
        "Remake README": REMAKE_README.read_text(encoding="utf-8"),
        "Remake Work Order": REMAKE_WORK_ORDER.read_text(encoding="utf-8"),
        "Spec README": SPEC_README.read_text(encoding="utf-8"),
        "Spec Work Order": SPEC_WORK_ORDER.read_text(encoding="utf-8"),
        "Process Policy": PROCESS_POLICY.read_text(encoding="utf-8"),
        "Implementation Model": MODEL.read_text(encoding="utf-8"),
        "SYSTEMS.md": SYSTEMS.read_text(encoding="utf-8"),
        "Workspace README": WORKSPACE_README.read_text(encoding="utf-8"),
        "Current Work Order": WORK_ORDER.read_text(encoding="utf-8"),
        "Implementation Status": IMPLEMENTATION_STATUS.read_text(encoding="utf-8"),
        "Execution Rules": EXECUTION_RULES.read_text(encoding="utf-8"),
        "Studio Policy": STUDIO_POLICY.read_text(encoding="utf-8"),
        "Review Gate": REVIEW_GATE.read_text(encoding="utf-8"),
    }

    required_markers = [
        ("Root README", "R3 = VALIDATED · NOT FROZEN"),
        ("Root README", "NEXT = USER R3 FREEZE DECISION"),
        ("Root README", "CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않습니다"),
        ("Implementation README", "CURRENT · R3_VALIDATED · SOURCE_NOT_STARTED"),
        ("Implementation README", "greenfield/src/**\n→ new Greenfield Source root"),
        ("Implementation README", "CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않는다"),
        ("Active Task", "- status: `R3_VALIDATED_AWAITING_FREEZE_DECISION`"),
        ("Active Task", "currentAuthorityCorpus: `implementation/roblox/manifests/r3-authority-corpus.json`"),
        ("Active Task", "sourceImplementationAllowed: `false`"),
        ("Active Task", "studioImplementationAllowed: `false`"),
        ("AGENTS.md", "OLD GREENFIELD MODEL = RETIRED"),
        ("AGENTS.md", "CURRENT AUTHORITY CORPUS = PRODUCT + ADR + ARCHITECTURE + SYSTEM + UI"),
        ("AGENTS.md", "R3 = VALIDATED · NOT FROZEN · AWAITING USER FREEZE DECISION"),
        ("AGENTS.md", "NEXT = USER R3 FREEZE DECISION"),
        ("Planning Addendum", "CURRENT · SUBORDINATE_TO_ACTIVE_EXECUTION_GATE"),
        ("Planning Addendum", "SOURCE = BLOCKED"),
        ("Planning Addendum", "E1 Studio/MCP gate가 열린 뒤"),
        ("Agent Test Status", "CURRENT · R3_VALIDATED_AWAITING_FREEZE_DECISION"),
        ("Agent Test Status", "STUDIO_BLOCKED"),
        ("Remake README", "ACTIVE · R3_VALIDATED_AWAITING_FREEZE_DECISION"),
        ("Remake README", "CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않는다"),
        ("Remake Work Order", "ACTIVE · CONTEXT_ONLY · R3_VALIDATED_AWAITING_FREEZE_DECISION"),
        ("Remake Work Order", "NEXT = USER R3 FREEZE DECISION"),
        ("Spec README", "REFERENCE_SPEC_CORPUS · NOT_CURRENT_IMPLEMENTATION_MODEL"),
        ("Spec README", "SOURCE = BLOCKED"),
        ("Spec Work Order", "REFERENCE_BASELINE_COMPLETE · NOT_CURRENT_IMPLEMENTATION_AUTHORITY"),
        ("Spec Work Order", "Studio/MCP\n→ BLOCKED UNTIL CORE_ENGINE_COMPLETE"),
        ("Process Policy", "확정 · STAGED_BY_CURRENT_EXECUTION_GATE"),
        ("Process Policy", "E0 Repository Core Engine 구현/자동 검증"),
        ("Process Policy", "CORE_ENGINE_COMPLETE\n→ E1 Runtime Checkpoint Freeze"),
        ("Process Policy", "현재 R3에서는 Source와 Studio/MCP 구현을 시작하지 않는다"),
        ("Implementation Model", "DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED"),
        ("Implementation Model", "CORE_ENGINE_COMPLETE 전 Studio/MCP 작업을 시작하지 않는다"),
        ("SYSTEMS.md", "APPROVED_SYSTEM_AUTHORITY"),
        ("SYSTEMS.md", "34 System Responsibility Model"),
        ("Routing README", "R3_VALIDATED_AWAITING_FREEZE_DECISION"),
        ("Workspace README", "src/**\n= 기존 Production Source\n= READ_ONLY_REFERENCE"),
        ("Workspace README", "greenfield/src/**\n= 새 Greenfield Source root"),
        ("Workspace README", "CORE_ENGINE_COMPLETE 전 Studio/MCP 구현은 금지"),
        ("Current Work Order", "- 상태: `R3_VALIDATED_AWAITING_FREEZE_DECISION`"),
        ("Current Work Order", "NEXT = USER R3 FREEZE DECISION"),
        ("Implementation Status", "R3_VALIDATED · NOT_FROZEN · SOURCE_NOT_STARTED"),
        ("Implementation Status", "Studio/MCP\n→ BLOCKED"),
        ("Execution Rules", "- 상태: `ACTIVE · STAGED_EXECUTION_POLICY`"),
        ("Execution Rules", "CORE_ENGINE_COMPLETE 이후에만"),
        ("Studio Policy", "ACTIVE_FUTURE_E1_PATH · CURRENTLY_BLOCKED"),
        ("Studio Policy", "CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않는다"),
        ("Review Gate", "ACTIVE · STAGED_BY_CURRENT_EXECUTION_GATE"),
        ("Review Gate", "현재는 Studio 반복이 기본 개발 모드가 아니다"),
    ]
    for label, marker in required_markers:
        if marker not in texts[label]:
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
        (CURRENT_AUTHORITY, "r3-authority-corpus.json"),
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
        "entrypoints=CURRENT; routing=CURRENT; current_status_surfaces=PASS; process_policy=STAGED; "
        "greenfield_source=BLOCKED; studio=BLOCKED_UNTIL_CORE_ENGINE_COMPLETE; "
        "legacy_src=READ_ONLY_REFERENCE; legacy_write_lock=PASS"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
