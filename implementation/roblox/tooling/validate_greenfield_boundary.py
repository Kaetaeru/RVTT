from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
ACTIVE_TASK = REPO_ROOT / ".github/CODEX-ACTIVE-TASK.md"
MODEL = ROOT / "IMPLEMENTATION-MODEL.md"
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
        print("RVTT implementation model reset boundary validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print(
        "RVTT implementation model reset boundary validation passed: "
        f"resetBaseline={RESET_BASELINE_COMMIT[:12]}; old Greenfield model retired; "
        "source=BLOCKED; studio=BLOCKED; legacy write-lock=PASS"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
