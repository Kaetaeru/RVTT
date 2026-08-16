from __future__ import annotations

from pathlib import Path
import argparse
import json
import shutil


ROOT = Path(__file__).resolve().parents[1]
PUBLIC_PACKAGE_ID = "rvtt.core.rules"


def build(staging_root: Path, source_root: Path = ROOT) -> list[Path]:
    staging_root = staging_root.resolve()
    staging_root.mkdir(parents=True, exist_ok=True)
    if any(staging_root.iterdir()):
        raise ValueError(f"staging root must be empty: {staging_root}")

    rules_dir = staging_root / "rules"
    runtime_dir = staging_root / "runtime"
    rules_dir.mkdir()
    runtime_dir.mkdir()

    public_index = rules_dir / "public-index.json"
    public_index.write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "packageId": PUBLIC_PACKAGE_ID,
                "ruleLinks": ["rvtt-rule://rvtt.core.rules/srd521.playing-the-game/actions#help"],
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )

    notice = staging_root / "NOTICE.txt"
    notice.write_text(
        "RVTT public rules release\n"
        "SRD 5.2.1 content is provided under CC BY 4.0.\n",
        encoding="utf-8",
    )

    status_source = source_root / "src/ReplicatedStorage/RVTT/ContentRuntime/RuleProfileStatus.lua"
    if not status_source.is_file():
        raise FileNotFoundError(f"missing client-safe profile status source: {status_source}")
    status_target = runtime_dir / "RuleProfileStatus.lua"
    shutil.copyfile(status_source, status_target)

    output_files = [
        notice.relative_to(staging_root).as_posix(),
        public_index.relative_to(staging_root).as_posix(),
        status_target.relative_to(staging_root).as_posix(),
    ]
    inventory = staging_root / "release-content-inventory.json"
    inventory.write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "profile": "release",
                "basePackageId": PUBLIC_PACKAGE_ID,
                "packageIds": [PUBLIC_PACKAGE_ID],
                "outputFiles": sorted(output_files),
                "fileMetadata": {
                    "rules/public-index.json": {"contentKind": "public-rule-index"},
                    "runtime/RuleProfileStatus.lua": {"contentKind": "client-safe-status"},
                },
                "ruleLinks": ["rvtt-rule://rvtt.core.rules/srd521.playing-the-game/actions#help"],
                "license": {
                    "packageId": PUBLIC_PACKAGE_ID,
                    "licenseId": "CC-BY-4.0",
                    "attributionRequired": True,
                    "attributionText": "SRD 5.2.1 content is provided under CC BY 4.0.",
                },
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    return [inventory, notice, public_index, status_target]


def main() -> int:
    parser = argparse.ArgumentParser(description="Build deterministic RVTT public rules staging output")
    parser.add_argument("staging_root", type=Path)
    args = parser.parse_args()
    files = build(args.staging_root)
    print(f"Public rules release staging built: {len(files)} files at {args.staging_root.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
