#!/usr/bin/env python3
"""Rewrite RVTT remake Markdown links after the documentation migration.

The migration moved planning documents into nested folders without changing their
contents. Relative links therefore still resolve from the old locations. This
script interprets each link from the document's pre-migration location and then
writes the correct relative path from its new location.
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

# Links that were already stale before the folder migration.
LEGACY_ALIASES = {
    "decisions/ADR-0011-persistent-character-runtime-state.md":
        "decisions/ADR-0011-persistent-character-current-state.md",
    "decisions/ADR-0010-common-input-grammar.md":
        "ui/common-input/common-input-grammar.md",
    "decisions/ADR-0018-authoritative-action-intent-and-pending-resolution.md":
        "architecture/effect-recipe-resolution-and-commit-model.md",
    "03-character-creation-and-progression.md":
        "architecture/rules-content-grant-capability-model.md",
    "23-item-instance-equipment-and-inventory-model.md":
        "systems/inventory/item-weapon-attack-profile-and-mastery-model.md",
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


def split_target(raw: str) -> tuple[str, str, str]:
    target = raw.strip()
    wrapper_left = "<" if target.startswith("<") else ""
    wrapper_right = ">" if target.endswith(">") else ""
    if wrapper_left:
        target = target[1:]
    if wrapper_right:
        target = target[:-1]

    title = ""
    match = re.match(r"^(?P<path>\S+)(?P<title>\s+[\"'].*)$", target)
    if match:
        target = match.group("path")
        title = match.group("title")
    return target, title, wrapper_left + wrapper_right


def is_external(target: str) -> bool:
    return not target or target.startswith(("#", "mailto:", "http://", "https://"))


def relative_posix(target: Path, parent: Path) -> str:
    return Path(os.path.relpath(target, parent)).as_posix()


def rewrite_document(
    document: Path,
    original_document: Path,
    source_to_target: dict[Path, Path],
    check_only: bool,
) -> int:
    text = document.read_text(encoding="utf-8")
    changes = 0

    def replace(match: re.Match[str]) -> str:
        nonlocal changes
        label = match.group("label")
        raw_target = match.group("target")
        path_part, title, wrappers = split_target(raw_target)
        decoded_path, separator, fragment = unquote(path_part).partition("#")
        if is_external(decoded_path):
            return match.group(0)

        old_absolute = (original_document.parent / decoded_path).resolve()
        try:
            old_relative = old_absolute.relative_to(DOCS_ROOT).as_posix()
        except ValueError:
            # Repository-root links such as ../../AGENTS.md still need rebasing.
            try:
                old_absolute.relative_to(REPO_ROOT)
            except ValueError:
                return match.group(0)
            destination = old_absolute
        else:
            alias = LEGACY_ALIASES.get(old_relative)
            if alias is not None:
                destination = (DOCS_ROOT / alias).resolve()
            else:
                destination = source_to_target.get(old_absolute, old_absolute)

        new_path = relative_posix(destination, document.parent)
        if separator:
            new_path += f"#{fragment}"
        wrapper_left = "<" if wrappers else ""
        wrapper_right = ">" if wrappers else ""
        new_target = f"{wrapper_left}{new_path}{wrapper_right}{title}"
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

    total_changes = 0
    changed_documents = 0
    for document in sorted(DOCS_ROOT.rglob("*.md")):
        original_document = target_to_source.get(document.resolve(), document.resolve())
        changes = rewrite_document(
            document.resolve(), original_document, source_to_target, args.check
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
