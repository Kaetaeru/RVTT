#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
AUDIT_V3 = REPO_ROOT / "implementation/roblox/manifests/scenario-semantic-audit-v3.json"

EXPECTED_IMMUTABLE_EVIDENCE = {
    "legacyExpandedEvidenceBlobSha": (
        "implementation/roblox/manifests/architecture-scenarios.json",
        "93f275b373c9f88b12ed3078149ff562642a5b1d",
    ),
    "semanticClassificationAuditV2BlobSha": (
        "implementation/roblox/manifests/scenario-semantic-audit.json",
        "839f05d0d7ba1f53eec87fd35981d4b961d513ef",
    ),
}


def git_blob_sha(path: str) -> str | None:
    proc = subprocess.run(
        ["git", "rev-parse", f"HEAD:{path}"],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    return proc.stdout.strip() if proc.returncode == 0 else None


def main() -> int:
    errors: list[str] = []
    try:
        audit = json.loads(AUDIT_V3.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"RVTT immutable evidence validation failed: {exc}")
        return 1

    binding = audit.get("sourceBinding") if isinstance(audit.get("sourceBinding"), dict) else {}
    policy = audit.get("policy") if isinstance(audit.get("policy"), dict) else {}

    if policy.get("legacyExpandedEvidenceImmutable") is not True:
        errors.append("v3 policy must declare legacyExpandedEvidenceImmutable=true")
    if policy.get("v2SemanticClassificationPreserved") is not True:
        errors.append("v3 policy must declare v2SemanticClassificationPreserved=true")

    for binding_key, (path, expected_sha) in EXPECTED_IMMUTABLE_EVIDENCE.items():
        actual_sha = git_blob_sha(path)
        if actual_sha != expected_sha:
            errors.append(
                f"immutable evidence changed for {path}: expected={expected_sha} actual={actual_sha}"
            )
        if binding.get(binding_key) != expected_sha:
            errors.append(
                f"v3 sourceBinding.{binding_key} must remain pinned to immutable evidence {expected_sha}"
            )

    if errors:
        print("RVTT R3 immutable evidence validation failed:")
        for error in errors:
            print("-", error)
        return 1

    print(
        "RVTT R3 immutable evidence validation passed: "
        "historical_expanded=PINNED; v2_classification_audit=PINNED"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
