from __future__ import annotations

import argparse
import copy
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROBLOX_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROBLOX_ROOT.parents[1]
DEFAULT_AUTHORITY = ROBLOX_ROOT / "src/ServerStorage/RVTT/Content/BuiltinPackIndex.lua"
PRIVATE_PACKAGE_ID = "rvtt.test.rules.2024.integrated.ko"
PRIVATE_LOCALE = "ko-KR"
TARGET_CHUNK_BYTES = 12 * 1024
MAX_CHUNK_BYTES = 16 * 1024
COUNT_PATTERNS = {
    "classes": "classes/*.md",
    "subclasses": "classes/*/*.md",
    "backgrounds": "backgrounds/*.md",
    "species": "species/*.md",
    "feats": "feats/*.md",
    "spells": "spells/*.md",
}
MODULE_TITLES = {
    "playing-the-game": "Playing the Game",
    "character-creation": "Character Creation",
    "classes": "Classes",
    "backgrounds": "Backgrounds",
    "species": "Species",
    "feats": "Feats",
    "equipment": "Equipment",
    "spells": "Spells",
    "rules-glossary": "Rules Glossary",
}


class ImportFailure(RuntimeError):
    def __init__(self, code: str, detail: str = "") -> None:
        super().__init__(f"{code}: {detail}" if detail else code)
        self.code = code
        self.detail = detail


@dataclass(frozen=True)
class Authority:
    package_id: str
    revision: str
    source_repository: str
    source_binding_key: str
    source_root: str
    expected_digest: str
    counts: dict[str, int]


def _package_block(text: str, package_id: str) -> str:
    marker = f'packageId = "{package_id}"'
    marker_at = text.find(marker)
    if marker_at < 0:
        raise ImportFailure("PRIVATE_PACKAGE_AUTHORITY_MISSING")
    start = text.rfind("\n\t{", 0, marker_at)
    if start < 0:
        raise ImportFailure("PRIVATE_PACKAGE_AUTHORITY_MALFORMED")
    start += 2
    depth = 0
    in_string = False
    escaped = False
    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start : index + 1]
    raise ImportFailure("PRIVATE_PACKAGE_AUTHORITY_MALFORMED")


def _string_field(block: str, name: str) -> str:
    match = re.search(rf"\b{re.escape(name)}\s*=\s*\"([^\"]*)\"", block)
    if match:
        return match.group(1)
    raise ImportFailure("PRIVATE_PACKAGE_AUTHORITY_MALFORMED", f"missing {name}")


def load_authority(path: Path) -> Authority:
    block = _package_block(path.read_text(encoding="utf-8"), PRIVATE_PACKAGE_ID)
    counts_match = re.search(r"expectedContentCounts\s*=\s*\{(.*?)\n\t\t\}", block, re.S)
    if counts_match is None:
        raise ImportFailure("PRIVATE_PACKAGE_AUTHORITY_MALFORMED", "missing expectedContentCounts")
    counts = {
        key: int(value)
        for key, value in re.findall(r"\b([A-Za-z][A-Za-z0-9_]*)\s*=\s*(\d+)", counts_match.group(1))
    }
    if set(counts) != set(COUNT_PATTERNS):
        raise ImportFailure("PRIVATE_PACKAGE_AUTHORITY_MALFORMED", "unexpected count keys")
    expected_digest = _string_field(block, "expectedSourceDigest")
    if not re.fullmatch(r"[0-9a-f]{40}", expected_digest):
        raise ImportFailure("PRIVATE_PACKAGE_AUTHORITY_MALFORMED", "expectedSourceDigest must be a git tree SHA")
    return Authority(
        package_id=_string_field(block, "packageId"),
        revision=_string_field(block, "version"),
        source_repository=_string_field(block, "sourceRepository"),
        source_binding_key=_string_field(block, "sourceBindingKey"),
        source_root=_string_field(block, "sourceRoot"),
        expected_digest=expected_digest,
        counts=counts,
    )


def _git(repo: Path, *args: str) -> str:
    completed = subprocess.run(
        ["git", "-C", str(repo), *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        raise ImportFailure("PRIVATE_SOURCE_GIT_ERROR")
    return completed.stdout.strip()


def verify_source(repo: Path, authority: Authority) -> tuple[Path, str, dict[str, int]]:
    if not repo.is_dir() or not (repo / ".git").exists():
        raise ImportFailure("PRIVATE_SOURCE_MISSING")
    revision = _git(repo, "rev-parse", "HEAD")
    if revision != authority.revision:
        raise ImportFailure("SOURCE_REVISION_MISMATCH")
    source_root = (repo / authority.source_root).resolve()
    try:
        source_root.relative_to(repo.resolve())
    except ValueError as exc:
        raise ImportFailure("SOURCE_ROOT_MISMATCH") from exc
    if not source_root.is_dir():
        raise ImportFailure("SOURCE_ROOT_MISMATCH")
    dirty = _git(repo, "status", "--porcelain", "--untracked-files=all", "--", authority.source_root)
    if dirty:
        raise ImportFailure("SOURCE_WORKTREE_DIRTY")
    digest = _git(repo, "rev-parse", f"HEAD:{authority.source_root}")
    if digest != authority.expected_digest:
        raise ImportFailure("SOURCE_DIGEST_MISMATCH")
    counts = count_content(source_root)
    if counts != authority.counts:
        raise ImportFailure("CONTENT_COUNT_MISMATCH")
    return source_root, digest, counts


def _markdown_files(root: Path, pattern: str) -> list[Path]:
    return sorted(
        path
        for path in root.glob(pattern)
        if path.is_file() and path.suffix.lower() == ".md" and path.name.lower() != "readme.md"
    )


def count_content(root: Path) -> dict[str, int]:
    return {key: len(_markdown_files(root, pattern)) for key, pattern in COUNT_PATTERNS.items()}


def slug(value: str) -> str:
    normalized = value.strip().lower()
    normalized = re.sub(r"[`*_~]+", "", normalized)
    normalized = re.sub(r"[^0-9a-z가-힣]+", "-", normalized)
    normalized = normalized.strip("-")
    return normalized or "section"


def _title_from_stem(stem: str) -> str:
    return " ".join(part.capitalize() for part in re.split(r"[-_]+", stem) if part)


def _utf8_len(value: str) -> int:
    return len(value.encode("utf-8"))


def _split_oversize(value: str, limit: int) -> list[str]:
    if _utf8_len(value) <= limit:
        return [value]
    pieces: list[str] = []
    remaining = value
    while remaining:
        if _utf8_len(remaining) <= limit:
            pieces.append(remaining)
            break
        low, high = 1, len(remaining)
        while low < high:
            mid = (low + high + 1) // 2
            if _utf8_len(remaining[:mid]) <= limit:
                low = mid
            else:
                high = mid - 1
        cut = low
        whitespace = max(remaining.rfind("\n", 0, cut), remaining.rfind(" ", 0, cut))
        if whitespace >= max(1, cut // 2):
            cut = whitespace + 1
        pieces.append(remaining[:cut].strip())
        remaining = remaining[cut:].lstrip()
    return [piece for piece in pieces if piece]


def semantic_chunks(text: str) -> list[str]:
    normalized = text.replace("\r\n", "\n").replace("\r", "\n").strip()
    if not normalized:
        return []
    units: list[str] = []
    for paragraph in re.split(r"\n\s*\n", normalized):
        paragraph = paragraph.strip()
        if not paragraph:
            continue
        units.extend(_split_oversize(paragraph, MAX_CHUNK_BYTES))
    chunks: list[str] = []
    current = ""
    for unit in units:
        candidate = unit if not current else f"{current}\n\n{unit}"
        if current and _utf8_len(candidate) > TARGET_CHUNK_BYTES:
            chunks.append(current)
            current = unit
        else:
            current = candidate
    if current:
        chunks.append(current)
    for chunk in chunks:
        if _utf8_len(chunk) > MAX_CHUNK_BYTES:
            raise ImportFailure("CHUNK_SIZE_INVALID")
    return chunks


def _keywords(*values: str) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for value in values:
        for token in re.findall(r"[0-9A-Za-z가-힣]{2,}", value.lower()):
            if token not in seen:
                seen.add(token)
                output.append(token)
            if len(output) >= 24:
                return output
    return output


def parse_document(path: Path, source_root: Path) -> tuple[str, dict, dict[str, dict], list[dict]]:
    relative = path.relative_to(source_root)
    module_key = relative.parts[0]
    raw = path.read_text(encoding="utf-8")
    lines = raw.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    headings: list[tuple[int, str]] = []
    for index, line in enumerate(lines):
        match = re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if match:
            headings.append((index, match.group(2).strip()))
    document_title = headings[0][1] if headings else _title_from_stem(path.stem)
    document_id = slug("-".join(relative.with_suffix("").parts))
    sections: list[dict] = []
    chunks: dict[str, dict] = {}
    search_entries: list[dict] = []
    anchor_counts: dict[str, int] = {}

    boundaries: list[tuple[int, str]] = []
    if headings:
        if headings[0][0] > 0 and any(line.strip() for line in lines[: headings[0][0]]):
            boundaries.append((0, "Overview"))
        boundaries.extend(headings)
    else:
        boundaries.append((0, document_title))

    for section_index, (start, section_title) in enumerate(boundaries):
        end = boundaries[section_index + 1][0] if section_index + 1 < len(boundaries) else len(lines)
        section_text = "\n".join(lines[start:end]).strip()
        base_anchor = slug(section_title)
        count = anchor_counts.get(base_anchor, 0) + 1
        anchor_counts[base_anchor] = count
        anchor = base_anchor if count == 1 else f"{base_anchor}-{count}"
        texts = semantic_chunks(section_text) or [section_title]
        chunk_ids: list[str] = []
        for chunk_index, chunk_text in enumerate(texts, start=1):
            chunk_id = f"private.{slug(module_key)}.{document_id}.{anchor}.{chunk_index}"
            chunk_ids.append(chunk_id)
            keywords = _keywords(document_title, section_title)
            chunks[chunk_id] = {
                "id": chunk_id,
                "moduleId": f"private.{slug(module_key)}",
                "documentId": document_id,
                "anchorId": anchor,
                "text": chunk_text,
                "keywords": keywords,
                "relatedLinks": [],
                "backlinks": [],
            }
            search_entries.append({"chunkId": chunk_id, "terms": keywords})
        sections.append({"anchorId": anchor, "title": section_title, "chunkIds": chunk_ids})

    document = {
        "id": document_id,
        "title": document_title,
        "sourceLabel": "Integrated 2024 Test Pack",
        "visibility": "public",
        "sections": sections,
    }
    return module_key, document, chunks, search_entries


def build_package(source_root: Path, authority: Authority) -> dict:
    module_documents: dict[str, list[dict]] = {}
    chunks: dict[str, dict] = {}
    search_entries: list[dict] = []
    markdown = sorted(
        path for path in source_root.rglob("*.md") if path.is_file() and path.name.lower() != "readme.md"
    )
    if not markdown:
        raise ImportFailure("PRIVATE_SOURCE_EMPTY")
    for path in markdown:
        module_key, document, document_chunks, document_search = parse_document(path, source_root)
        module_documents.setdefault(module_key, []).append(document)
        for chunk_id, chunk in document_chunks.items():
            if chunk_id in chunks:
                raise ImportFailure("STABLE_ID_COLLISION", chunk_id)
            chunks[chunk_id] = chunk
        search_entries.extend(document_search)
    modules = [
        {
            "id": f"private.{slug(module_key)}",
            "title": MODULE_TITLES.get(module_key, _title_from_stem(module_key)),
            "visibility": "public",
            "documents": sorted(module_documents[module_key], key=lambda item: item["id"]),
        }
        for module_key in sorted(module_documents)
    ]
    return {
        "schemaVersion": 1,
        "packageId": authority.package_id,
        "version": authority.revision,
        "locale": PRIVATE_LOCALE,
        "license": {
            "licenseId": "PRIVATE-USE-ONLY",
            "attributionRequired": True,
            "attributionText": "Owner-only integrated 2024 test content.",
        },
        "modules": modules,
        "chunks": chunks,
        "searchIndex": {"locale": PRIVATE_LOCALE, "entries": search_entries},
    }


def _is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def safe_output_root(path: Path) -> Path:
    resolved = path.resolve()
    if _is_relative_to(resolved, REPO_ROOT.resolve()):
        raise ImportFailure("PRIVATE_OUTPUT_INSIDE_PUBLIC_REPOSITORY")
    return resolved


def write_runtime(output_root: Path, authority: Authority, digest: str, counts: dict[str, int], package: dict) -> Path:
    runtime = output_root / "runtime" / "RVTTPrivateRuleContent"
    runtime.mkdir(parents=True, exist_ok=True)
    readiness = {
        "bindingPresent": True,
        "sourceBindingKey": authority.source_binding_key,
        "revision": authority.revision,
        "sourceRoot": authority.source_root,
        "verifiedDigest": digest,
        "contentCounts": counts,
        "importSchemaVersion": 1,
    }
    (runtime / "Readiness.json").write_text(
        json.dumps(readiness, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (runtime / "RuleReaderPackage.json").write_text(
        json.dumps(package, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8"
    )
    manifest = {
        "schemaVersion": 1,
        "packageId": authority.package_id,
        "revision": authority.revision,
        "verifiedDigest": digest,
        "contentCounts": counts,
        "documentCount": sum(len(module["documents"]) for module in package["modules"]),
        "chunkCount": len(package["chunks"]),
    }
    (output_root / "private-rules.import-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return runtime


def _rebase_paths(value: object, base_dir: Path, generated_dir: Path) -> object:
    if isinstance(value, list):
        return [_rebase_paths(item, base_dir, generated_dir) for item in value]
    if not isinstance(value, dict):
        return value
    output = {}
    for key, nested in value.items():
        if key == "$path" and isinstance(nested, str):
            source_path = (base_dir / nested).resolve()
            output[key] = Path(os.path.relpath(source_path, generated_dir)).as_posix()
        else:
            output[key] = _rebase_paths(nested, base_dir, generated_dir)
    return output


def write_generated_project(base_project: Path, output_root: Path, runtime: Path) -> Path:
    base = json.loads(base_project.read_text(encoding="utf-8"))
    generated = _rebase_paths(copy.deepcopy(base), base_project.parent.resolve(), output_root)
    if not isinstance(generated, dict) or not isinstance(generated.get("tree"), dict):
        raise ImportFailure("BASE_PROJECT_INVALID")
    tree = generated["tree"]
    server_storage = tree.setdefault("ServerStorage", {"$className": "ServerStorage"})
    if not isinstance(server_storage, dict):
        raise ImportFailure("BASE_PROJECT_INVALID")
    server_storage["RVTTPrivateRuleContent"] = {
        "$path": Path(os.path.relpath(runtime, output_root)).as_posix()
    }
    generated["name"] = f"{generated.get('name', 'RVTT')} Private Rules"
    project_path = output_root / "private-rules.generated.project.json"
    project_path.write_text(json.dumps(generated, indent=2) + "\n", encoding="utf-8")
    return project_path


def build(
    source_repo_root: Path,
    output_root: Path,
    authority_file: Path = DEFAULT_AUTHORITY,
    base_project: Path | None = None,
) -> dict[str, object]:
    output_root = safe_output_root(output_root)
    authority = load_authority(authority_file)
    source_root, digest, counts = verify_source(source_repo_root.resolve(), authority)
    package = build_package(source_root, authority)
    output_root.mkdir(parents=True, exist_ok=True)
    runtime = write_runtime(output_root, authority, digest, counts, package)
    project_path = None
    if base_project is not None:
        project_path = write_generated_project(base_project.resolve(), output_root, runtime)
    return {
        "packageId": authority.package_id,
        "revision": authority.revision,
        "verifiedDigest": digest,
        "contentCounts": counts,
        "documentCount": sum(len(module["documents"]) for module in package["modules"]),
        "chunkCount": len(package["chunks"]),
        "runtimeRoot": str(runtime),
        "generatedProject": str(project_path) if project_path else None,
    }


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build the owner-only private RuleContentPackage into a temporary workspace.")
    parser.add_argument("--source-repo-root", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--authority-file", type=Path, default=DEFAULT_AUTHORITY)
    parser.add_argument("--base-project", type=Path)
    return parser.parse_args(argv)


def main(argv: Iterable[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        result = build(
            source_repo_root=args.source_repo_root,
            output_root=args.output_root,
            authority_file=args.authority_file,
            base_project=args.base_project,
        )
    except ImportFailure as exc:
        print(f"private rules import failed: {exc.code}", file=sys.stderr)
        return 2
    print(
        "private rules import passed: "
        f"package={result['packageId']} documents={result['documentCount']} chunks={result['chunkCount']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
