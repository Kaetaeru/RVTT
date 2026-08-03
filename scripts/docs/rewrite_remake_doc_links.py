#!/usr/bin/env python3
"""Rewrite RVTT remake Markdown links after the documentation migration.

The migration moved planning documents into nested folders without changing their
contents. This tool is intentionally idempotent: links that already resolve from
their current document are never touched.
"""

from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote

REPO_ROOT = Path(__file__).resolve().parents[2]
DOCS_ROOT = REPO_ROOT / "docs" / "remake"
MIGRATION_MAP = DOCS_ROOT / "DOCUMENT-MIGRATION-MAP.md"

MAPPING_ROW = re.compile(
    r"^\|\s*`(?P<source>[^`]+\.md)`\s*\|\s*`(?P<target>[^`]+\.md)`\s*\|\s*$"
)
MARKDOWN_LINK = re.compile(r"(?<!!)\[(?P<label>[^\]]*)\]\((?P<target>[^)]+)\)")

LEGACY_ALIAS_BASENAMES = {
    "ADR-0011-persistent-character-runtime-state.md":
        DOCS_ROOT / "decisions/ADR-0011-persistent-character-current-state.md",
    "ADR-0010-common-input-grammar.md":
        DOCS_ROOT / "ui/common-input/common-input-grammar.md",
    "ADR-0018-authoritative-action-intent-and-pending-resolution.md":
        DOCS_ROOT / "architecture/effect-recipe-resolution-and-commit-model.md",
    "03-character-creation-and-progression.md":
        DOCS_ROOT / "architecture/rules-content-grant-capability-model.md",
    "23-item-instance-equipment-and-inventory-model.md":
        DOCS_ROOT / "systems/inventory/item-weapon-attack-profile-and-mastery-model.md",
}


@dataclass(frozen=True)
class MigrationEntry:
    source: Path
    target: Path


def parse_migration_map() -> list[MigrationEntry]:
    entries: list[MigrationEntry] = []
    for line in MIGRATION_MAP.read_text(encoding="utf-8").splitlines():
        match = MAPPING_ROW.match(line)
        if match:
            entries.append(
                MigrationEntry(
                    source=(DOCS_ROOT / match.group("source")).resolve(),
                    target=(DOCS_ROOT / match.group("target")).resolve(),
                )
            )
    return entries


def split_target(raw: str) -> tuple[str, str, bool]:
    target = raw.strip()
    wrapped = target.startswith("<") and target.endswith(">")
    if wrapped:
        target = target[1:-1]

    title = ""
    match = re.match(r"^(?P<path>\S+)(?P<title>\s+[\"'].*)$", target)
    if match:
        target = match.group("path")
        title = match.group("title")
    return target, title, wrapped


def is_external(target: str) -> bool:
    return not target or target.startswith(("#", "mailto:", "http://", "https://"))


def relative_posix(target: Path, parent: Path) -> str:
    return Path(os.path.relpath(target, parent)).as_posix()


def unique_file_index() -> dict[str, Path]:
    candidates: dict[str, list[Path]] = {}
    for path in REPO_ROOT.rglob("*"):
        if path.is_file() and ".git" not in path.parts:
            candidates.setdefault(path.name, []).append(path.resolve())
    return {
        name: paths[0]
        for name, paths in candidates.items()
        if len(paths) == 1
    }


def choose_destination(
    decoded_path: str,
    document: Path,
    original_document: Path,
    source_to_target: dict[Path, Path],
    source_name_to_target: dict[str, Path],
    unique_files: dict[str, Path],
) -> Path | None:
    current_absolute = (document.parent / decoded_path).resolve()
    if current_absolute.exists():
        return None

    basename = Path(decoded_path).name
    if basename in LEGACY_ALIAS_BASENAMES:
        return LEGACY_ALIAS_BASENAMES[basename].resolve()
    if basename in source_name_to_target:
        return source_name_to_target[basename]

    original_absolute = (original_document.parent / decoded_path).resolve()
    mapped_original = source_to_target.get(original_absolute)
    if mapped_original is not None:
        return mapped_original
    if original_absolute.exists():
        return original_absolute

    unique = unique_files.get(basename)
    if unique is not None:
        return unique
    return None


def rewrite_document(
    document: Path,
    original_document: Path,
    source_to_target: dict[Path, Path],
    source_name_to_target: dict[str, Path],
    unique_files: dict[str, Path],
    check_only: bool,
) -> int:
    text = document.read_text(encoding="utf-8")
    changes = 0

    def replace(match: re.Match[str]) -> str:
        nonlocal changes
        label = match.group("label")
        raw_target = match.group("target")
        path_part, title, wrapped = split_target(raw_target)
        decoded_path, separator, fragment = unquote(path_part).partition("#")
        if is_external(decoded_path):
            return match.group(0)

        destination = choose_destination(
            decoded_path,
            document,
            original_document,
            source_to_target,
            source_name_to_target,
            unique_files,
        )
        if destination is None:
            return match.group(0)

        new_path = relative_posix(destination, document.parent)
        if separator:
            new_path += f"#{fragment}"
        if wrapped:
            new_path = f"<{new_path}>"
        new_target = f"{new_path}{title}"
        if new_target == raw_target:
            return match.group(0)

        changes += 1
        return f"[{label}]({new_target})"

    rewritten = MARKDOWN_LINK.sub(replace, text)
    if changes and not check_only:
        document.write_text(rewritten, encoding="utf-8")
    return changes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail when links still require rewriting without modifying files.",
    )
    args = parser.parse_args()

    entries = parse_migration_map()
    source_to_target = {entry.source: entry.target for entry in entries}
    target_to_source = {entry.target: entry.source for entry in entries}
    source_name_to_target = {entry.source.name: entry.target for entry in entries}
    unique_files = unique_file_index()

    total_changes = 0
    changed_documents = 0
    for document in sorted(DOCS_ROOT.rglob("*.md")):
        resolved_document = document.resolve()
        original_document = target_to_source.get(resolved_document, resolved_document)
        changes = rewrite_document(
            resolved_document,
            original_document,
            source_to_target,
            source_name_to_target,
            unique_files,
            args.check,
        )
        if changes:
            total_changes += changes
            changed_documents += 1
            print(f"{document.relative_to(REPO_ROOT)}: {changes} link(s)")

    if args.check and total_changes:
        print(
            f"Documentation links require {total_changes} rewrite(s) "
            f"across {changed_documents} document(s)."
        )
        return 1

    print(
        f"Rewritten links: {total_changes} across {changed_documents} document(s)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
