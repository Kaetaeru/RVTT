from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
ACTIVE_TASK = REPO_ROOT / ".github/CODEX-ACTIVE-TASK.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
AGENTS = REPO_ROOT / "AGENTS.md"


def changed_paths() -> list[str]:
    candidates = ["origin/main...HEAD", "HEAD^...HEAD"]
    for diff_range in candidates:
        result = subprocess.run(
            ["git", "diff", "--name-only", diff_range],
            cwd=REPO_ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode == 0:
            return [line.strip() for line in result.stdout.splitlines() if line.strip()]
    return []


def main() -> int:
    errors: list[str] = []

    active = ACTIVE_TASK.read_text(encoding="utf-8")
    model = MODEL.read_text(encoding="utf-8")
    agents = AGENTS.read_text(encoding="utf-8")

    if "IMPLEMENTATION_MODEL_RESET" not in active:
        errors.append("active task must remain in IMPLEMENTATION_MODEL_RESET")
    if "sourceImplementationAllowed: `false`" not in active:
        errors.append("source implementation must remain disabled during model reset")
    if "studioImplementationAllowed: `false`" not in active:
        errors.append("Studio implementation must remain disabled during model reset")
    if "OLD GREENFIELD MODEL = RETIRED" not in agents:
        errors.append("AGENTS.md must declare old Greenfield model retired")
    if "DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED" not in model:
        errors.append("dedicated implementation branch must not be created before E0 checkpoint freeze")

    legacy_prefix = "implementation/roblox/src/"
    forbidden_legacy_files = {"implementation/roblox/default.project.json"}
    legacy_changes = [
        path for path in changed_paths()
        if path.startswith(legacy_prefix) or path in forbidden_legacy_files
    ]
    if legacy_changes:
        errors.append(f"legacy implementation source/project changed during reset: {legacy_changes}")

    if errors:
        print("RVTT implementation model reset boundary validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print(
        "RVTT implementation model reset boundary validation passed: "
        "old Greenfield model retired; source=BLOCKED; studio=BLOCKED; legacy write-lock=PASS"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
