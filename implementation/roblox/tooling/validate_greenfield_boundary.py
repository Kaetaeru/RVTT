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

# User-directed implementation-model reset started from this PR head.
# Legacy files already changed earlier in the planning PR are accepted as historical baseline,
# but no new Legacy mutation is allowed after this point.
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

    if "R3_BOUNDARY_FREEZE" not in active:
        errors.append("active task must remain in R3_BOUNDARY_FREEZE until user approves the boundary matrix")
    if "sourceImplementationAllowed: `false`" not in active:
        errors.append("source implementation must remain disabled during R3 planning")
    if "studioImplementationAllowed: `false`" not in active:
        errors.append("Studio implementation must remain disabled during R3 planning")
    if "OLD GREENFIELD MODEL = RETIRED" not in agents:
        errors.append("AGENTS.md must declare old Greenfield model retired")
    if "SYSTEM_MODEL_V1_APPROVED" not in model:
        errors.append("implementation model must declare approved System Model v1")
    if "APPROVED_SYSTEM_AUTHORITY" not in systems:
        errors.append("SYSTEMS.md approved authority marker missing")
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
        f"resetBaseline={RESET_BASELINE_COMMIT[:12]}; systemModel=33-v1; R3=ACTIVE; "
        "source=BLOCKED; studio=BLOCKED; legacy write-lock=PASS"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
