#!/usr/bin/env python3
"""Validate the RVTT remake documentation migration and relative Markdown links."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote

REPO_ROOT = Path(__file__).resolve().parents[2]
DOCS_ROOT = REPO_ROOT / "docs" / "remake"
MIGRATION_MAP = DOCS_ROOT / "DOCUMENT-MIGRATION-MAP.md"

MAPPING_ROW = re.compile(
    r"^\|\s*`(?P<source>[^`]+\.md)`\s*\|\s*`(?P<target>[^`]+\.md)`\s*\|\s*$"
)
MARKDOWN_LINK = re.compile(r"(?<!!)\[[^\]]*\]\((?P<target>[^)]+)\)")
NUMBERED_ROOT_DOC = re.compile(r"^(?:02|0[4-9]|[1-4][0-9])-.*\.md$")
EXPECTED_MIGRATION_COUNT = 46


@dataclass(frozen=True)
class MigrationEntry:
    source: Path
    target: Path


def parse_migration_map() -> list[MigrationEntry]:
    entries: list[MigrationEntry] = []
    for line in MIGRATION_MAP.read_text(encoding="utf-8").splitlines():
        match = MAPPING_ROW.match(line)
        if not match:
            continue
        entries.append(
            MigrationEntry(
                source=DOCS_ROOT / match.group("source"),
                target=DOCS_ROOT / match.group("target"),
            )
        )
    return entries


def normalize_link_target(raw_target: str) -> str | None:
    target = raw_target.strip().strip("<>")
    if not target or target.startswith(("#", "mailto:", "http://", "https://")):
        return None

    # Optional Markdown title: path "title" or path 'title'.
    target = re.split(r"\s+[\"']", target, maxsplit=1)[0]
    target = unquote(target.split("#", 1)[0])
    return target or None


def validate_migration(entries: list[MigrationEntry]) -> list[str]:
    errors: list[str] = []

    if len(entries) != EXPECTED_MIGRATION_COUNT:
        errors.append(
            f"migration map contains {len(entries)} entries; expected {EXPECTED_MIGRATION_COUNT}"
        )

    duplicate_sources = sorted(
        str(path.relative_to(DOCS_ROOT))
        for path in {entry.source for entry in entries}
        if sum(1 for item in entries if item.source == path) > 1
    )
    duplicate_targets = sorted(
        str(path.relative_to(DOCS_ROOT))
        for path in {entry.target for entry in entries}
        if sum(1 for item in entries if item.target == path) > 1
    )

    for path in duplicate_sources:
        errors.append(f"duplicate migration source: {path}")
    for path in duplicate_targets:
        errors.append(f"duplicate migration target: {path}")

    for entry in entries:
        source = entry.source.relative_to(REPO_ROOT)
        target = entry.target.relative_to(REPO_ROOT)
        if entry.source.exists():
            errors.append(f"old migration source still exists: {source}")
        if not entry.target.is_file():
            errors.append(f"migration target missing: {target}")

    numbered_docs = sorted(
        path.relative_to(REPO_ROOT)
        for path in DOCS_ROOT.glob("*.md")
        if NUMBERED_ROOT_DOC.match(path.name)
    )
    for path in numbered_docs:
        errors.append(f"numbered planning document remains at docs/remake root: {path}")

    return errors


def validate_relative_links() -> list[str]:
    errors: list[str] = []

    for document in sorted(DOCS_ROOT.rglob("*.md")):
        text = document.read_text(encoding="utf-8")
        for line_number, line in enumerate(text.splitlines(), start=1):
            for match in MARKDOWN_LINK.finditer(line):
                normalized = normalize_link_target(match.group("target"))
                if normalized is None:
                    continue

                resolved = (document.parent / normalized).resolve()
                try:
                    resolved.relative_to(REPO_ROOT.resolve())
                except ValueError:
                    errors.append(
                        f"{document.relative_to(REPO_ROOT)}:{line_number}: "
                        f"relative link leaves repository: {normalized}"
                    )
                    continue

                if not resolved.exists():
                    errors.append(
                        f"{document.relative_to(REPO_ROOT)}:{line_number}: "
                        f"broken relative link: {normalized}"
                    )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--skip-links",
        action="store_true",
        help="Only validate the migration map and file locations.",
    )
    args = parser.parse_args()

    if not MIGRATION_MAP.is_file():
        print(f"ERROR: migration map not found: {MIGRATION_MAP}", file=sys.stderr)
        return 2

    entries = parse_migration_map()
    errors = validate_migration(entries)
    if not args.skip_links:
        errors.extend(validate_relative_links())

    if errors:
        print(f"Documentation validation failed with {len(errors)} issue(s):")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Documentation validation passed.")
    print(f"- mapped documents: {len(entries)}")
    print("- old numbered root documents: 0")
    if not args.skip_links:
        print("- broken relative links: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
