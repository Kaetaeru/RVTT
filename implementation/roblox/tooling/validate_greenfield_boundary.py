from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
ACTIVE_TASK = REPO_ROOT / ".github/CODEX-ACTIVE-TASK.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
SYSTEMS = ROOT / "SYSTEMS.md"
AGENTS = REPO_ROOT / "AGENTS.md"
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


def main() -> int:
    errors: list[str] = []

    active = ACTIVE_TASK.read_text(encoding="utf-8")
    model = MODEL.read_text(encoding="utf-8")
    systems = SYSTEMS.read_text(encoding="utf-8") if SYSTEMS.exists() else ""
    agents = AGENTS.read_text(encoding="utf-8")

    if "- status: `R3_VALIDATED_AWAITING_FREEZE_DECISION`" not in active:
        errors.append("active task status must be exactly R3_VALIDATED_AWAITING_FREEZE_DECISION until user Freeze decision")
    if "sourceImplementationAllowed: `false`" not in active:
        errors.append("source implementation must remain disabled during R3 planning")
    if "studioImplementationAllowed: `false`" not in active:
        errors.append("Studio implementation must remain disabled during R3 planning")
    if "OLD GREENFIELD MODEL = RETIRED" not in agents:
        errors.append("AGENTS.md must declare old Greenfield model retired")
    if "R3 = VALIDATED · NOT FROZEN · AWAITING USER FREEZE DECISION" not in agents:
        errors.append("AGENTS.md current state must match validated-awaiting-freeze execution state")
    if "NEXT = USER R3 FREEZE DECISION" not in agents:
        errors.append("AGENTS.md next action must be user R3 Freeze decision")
    if "SYSTEM_MODEL_V2_REPAIRED" not in model:
        errors.append("implementation model must declare repaired System Model v2")
    if "APPROVED_SYSTEM_AUTHORITY" not in systems or "34 System Responsibility Model" not in systems:
        errors.append("SYSTEMS.md repaired 34-System authority marker missing")
    for path, label in (
        (CURRENT_MANIFEST, "implementation-system-model.json"),
        (BASE_SCENARIOS, "scenario-base-catalog.json"),
        (EXPANDED_SCENARIOS, "scenario-expanded-catalog.json"),
        (SEMANTIC_AUDIT_V3, "scenario-semantic-audit-v3.json"),
    ):
        if not path.exists():
            errors.append(f"{label} must exist before R3 Freeze")
    if "DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED" not in model:
        errors.append("dedicated implementation branch must not be created before R4 E0 checkpoint freeze")

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
        f"resetBaseline={RESET_BASELINE_COMMIT[:12]}; systemModel=34-v2-repaired; "
        "R3=VALIDATED_AWAITING_FREEZE; cleanScenarioCatalogs=PASS; "
        "source=BLOCKED; studio=BLOCKED; legacy write-lock=PASS"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
