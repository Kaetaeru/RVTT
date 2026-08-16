from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Iterable


ROBLOX_ROOT = Path(__file__).resolve().parents[1]
IMPORTER = ROBLOX_ROOT / "tooling/build_private_rules_runtime.py"
AUTHORIZED_USERS_ENV = "RVTT_PRIVATE_RULES_AUTHORIZED_USER_IDS"


class PrepareFailure(RuntimeError):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


def parse_authorized_user_ids(values: list[str]) -> list[int]:
    raw: list[str] = []
    for value in values:
        raw.extend(part.strip() for part in value.split(","))
    if not raw:
        env_value = os.environ.get(AUTHORIZED_USERS_ENV, "")
        raw.extend(part.strip() for part in env_value.split(","))
    ids: list[int] = []
    seen: set[int] = set()
    for value in raw:
        if not value:
            continue
        try:
            user_id = int(value, 10)
        except ValueError as exc:
            raise PrepareFailure("PRIVATE_RULE_ACCESS_INVALID") from exc
        if user_id <= 0:
            raise PrepareFailure("PRIVATE_RULE_ACCESS_INVALID")
        if user_id not in seen:
            seen.add(user_id)
            ids.append(user_id)
    if not ids:
        raise PrepareFailure("PRIVATE_RULE_ACCESS_MISSING")
    return ids


def prepare(
    source_repo_root: Path,
    output_root: Path,
    base_project: Path | None,
    authority_file: Path | None,
    authorized_user_ids: list[int],
) -> None:
    command = [
        sys.executable,
        str(IMPORTER),
        "--source-repo-root",
        str(source_repo_root),
        "--output-root",
        str(output_root),
    ]
    if authority_file is not None:
        command.extend(["--authority-file", str(authority_file)])
    if base_project is not None:
        command.extend(["--base-project", str(base_project)])
    completed = subprocess.run(command, text=True, check=False)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)

    runtime = output_root.resolve() / "runtime/RVTTPrivateRuleContent"
    readiness_path = runtime / "Readiness.json"
    manifest_path = output_root.resolve() / "private-rules.import-manifest.json"
    if not readiness_path.is_file() or not manifest_path.is_file():
        raise PrepareFailure("PRIVATE_RUNTIME_OUTPUT_MISSING")

    readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
    readiness["authorizedUserIds"] = authorized_user_ids
    readiness_path.write_text(
        json.dumps(readiness, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["authorizationMode"] = "explicit-user-allowlist"
    manifest["authorizedUserCount"] = len(authorized_user_ids)
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Prepare a fail-closed owner-only private RuleContentPackage runtime overlay."
    )
    parser.add_argument("--source-repo-root", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--authority-file", type=Path)
    parser.add_argument("--base-project", type=Path)
    parser.add_argument("--authorized-user-id", action="append", default=[])
    return parser.parse_args(argv)


def main(argv: Iterable[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        authorized = parse_authorized_user_ids(args.authorized_user_id)
        prepare(
            source_repo_root=args.source_repo_root,
            output_root=args.output_root,
            base_project=args.base_project,
            authority_file=args.authority_file,
            authorized_user_ids=authorized,
        )
    except PrepareFailure as exc:
        print(f"private rules prepare failed: {exc.code}", file=sys.stderr)
        return 2
    print(
        "private rules prepare passed: owner-only runtime overlay generated "
        f"with {len(authorized)} authorized user(s)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
