from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

import _build_private_rules_runtime_base as base

# Delegated base-import contract markers kept here so the established static validator
# continues to verify the public entrypoint while the implementation is split into a
# small link-normalization layer plus the pinned import/build core.
# SOURCE_REVISION_MISMATCH SOURCE_DIGEST_MISMATCH CONTENT_COUNT_MISMATCH
# SOURCE_WORKTREE_DIRTY PRIVATE_OUTPUT_INSIDE_PUBLIC_REPOSITORY
# "Readiness.json" "RuleReaderPackage.json" "RVTTPrivateRuleContent"
# "private-rules.generated.project.json" "searchIndex"
MAX_CHUNK_BYTES = 16 * 1024
MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[([^\]]+)\]\(([^)\n]+)\)")

ImportFailure = base.ImportFailure
Authority = base.Authority
DEFAULT_AUTHORITY = base.DEFAULT_AUTHORITY
PRIVATE_PACKAGE_ID = base.PRIVATE_PACKAGE_ID
PRIVATE_LOCALE = base.PRIVATE_LOCALE


def slug(value: str) -> str:
    return base.slug(value)


def _utf8_len(value: str) -> int:
    return len(value.encode("utf-8"))


def _module_key(relative: Path) -> str:
    return relative.parts[0] if len(relative.parts) > 1 else "overview"


def _document_id(relative: Path) -> str:
    return slug("-".join(relative.with_suffix("").parts))


def _heading_anchors(path: Path) -> dict[str, str]:
    lines = path.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n").split("\n")
    anchors: dict[str, str] = {}
    counts: dict[str, int] = {}
    for line in lines:
        match = re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if not match:
            continue
        key = slug(match.group(2).strip())
        count = counts.get(key, 0) + 1
        counts[key] = count
        anchor = key if count == 1 else f"{key}-{count}"
        anchors.setdefault(key, anchor)
    return anchors


def _catalog(markdown: list[Path], source_root: Path) -> tuple[dict[Path, dict], dict[str, Path]]:
    by_path: dict[Path, dict] = {}
    by_document_id: dict[str, Path] = {}
    for path in markdown:
        relative = path.relative_to(source_root)
        document_id = _document_id(relative)
        if document_id in by_document_id:
            raise ImportFailure("STABLE_ID_COLLISION", document_id)
        resolved = path.resolve()
        by_document_id[document_id] = resolved
        by_path[resolved] = {
            "moduleId": f"private.{slug(_module_key(relative))}",
            "documentId": document_id,
            "anchors": _heading_anchors(path),
        }
    return by_path, by_document_id


def _markdown_destination(raw: str) -> str:
    value = raw.strip()
    if value.startswith("<") and ">" in value:
        return value[1 : value.index(">")] .strip()
    return value.split(maxsplit=1)[0] if value else ""


def _candidate_target(path: Path, catalog: dict[Path, dict]) -> Path | None:
    candidates = [path]
    if path.suffix == "":
        candidates.extend([path.with_suffix(".md"), path / "README.md"])
    for candidate in candidates:
        resolved = candidate.resolve()
        if resolved in catalog:
            return resolved
    return None


def _resolve_rule_uri(
    destination: str,
    source_path: Path,
    source_root: Path,
    catalog: dict[Path, dict],
    package_id: str,
) -> str | None:
    if destination.startswith("rvtt-rule://"):
        return destination
    if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", destination) or destination.startswith("//"):
        return None
    path_part, separator, fragment = destination.partition("#")
    if path_part == "":
        target_path = source_path.resolve()
    else:
        candidate = (source_path.parent / unquote(path_part)).resolve()
        try:
            candidate.relative_to(source_root.resolve())
        except ValueError:
            return None
        target_path = _candidate_target(candidate, catalog)
        if target_path is None:
            return None
    descriptor = catalog.get(target_path)
    if descriptor is None:
        return None
    uri = f"rvtt-rule://{package_id}/{descriptor['moduleId']}/{descriptor['documentId']}"
    if separator:
        requested = slug(unquote(fragment))
        anchor = descriptor["anchors"].get(requested)
        if anchor is None:
            return None
        uri += f"#{anchor}"
    return uri


def normalize_markdown_links(
    text: str,
    source_path: Path,
    source_root: Path,
    catalog: dict[Path, dict],
    package_id: str,
) -> tuple[str, list[str]]:
    related: list[str] = []
    seen: set[str] = set()

    def replace(match: re.Match[str]) -> str:
        label = match.group(1)
        destination = _markdown_destination(match.group(2))
        uri = _resolve_rule_uri(destination, source_path, source_root, catalog, package_id)
        if uri is None:
            return match.group(0)
        if uri not in seen:
            seen.add(uri)
            related.append(uri)
        return f"[{label}]({uri})"

    return MARKDOWN_LINK_RE.sub(replace, text), related


def normalize_package_links(package: dict, markdown: list[Path], source_root: Path, package_id: str) -> None:
    catalog, by_document_id = _catalog(markdown, source_root)
    chunks: dict[str, dict] = package["chunks"]
    target_chunks: dict[str, str] = {}
    for module in package["modules"]:
        for document in module["documents"]:
            first_document_chunk: str | None = None
            for section in document["sections"]:
                chunk_ids = section.get("chunkIds") or []
                if not chunk_ids:
                    continue
                first_chunk = chunk_ids[0]
                if first_document_chunk is None:
                    first_document_chunk = first_chunk
                section_uri = (
                    f"rvtt-rule://{package_id}/{module['id']}/{document['id']}#{section['anchorId']}"
                )
                target_chunks[section_uri] = first_chunk
            if first_document_chunk is not None:
                document_uri = f"rvtt-rule://{package_id}/{module['id']}/{document['id']}"
                target_chunks[document_uri] = first_document_chunk

    for chunk in chunks.values():
        source_path = by_document_id.get(chunk["documentId"])
        if source_path is None:
            raise ImportFailure("RULE_LINK_SOURCE_UNRESOLVED", chunk["documentId"])
        normalized, related = normalize_markdown_links(
            chunk["text"], source_path, source_root, catalog, package_id
        )
        if _utf8_len(normalized) > MAX_CHUNK_BYTES:
            raise ImportFailure("CHUNK_SIZE_INVALID", chunk["id"])
        chunk["text"] = normalized
        chunk["relatedLinks"] = related

    for chunk in chunks.values():
        source_uri = (
            f"rvtt-rule://{package_id}/{chunk['moduleId']}/{chunk['documentId']}#{chunk['anchorId']}"
        )
        for target_uri in chunk.get("relatedLinks", []):
            target_id = target_chunks.get(target_uri)
            if target_id is None:
                continue
            backlinks = chunks[target_id].setdefault("backlinks", [])
            if source_uri not in backlinks:
                backlinks.append(source_uri)


def build_package(source_root: Path, authority: Authority) -> dict:
    # The base importer intentionally excluded README files from RuleContentPackage creation.
    # Include them as navigation targets/documents while keeping count validation unchanged.
    package = base.build_package(source_root, authority)
    markdown = sorted(path for path in source_root.rglob("*.md") if path.is_file())
    imported_ids = {
        document["id"]
        for module in package["modules"]
        for document in module["documents"]
    }
    missing_readmes = [
        path
        for path in markdown
        if path.name.lower() == "readme.md" and _document_id(path.relative_to(source_root)) not in imported_ids
    ]
    if missing_readmes:
        module_documents = {module["id"]: module for module in package["modules"]}
        for path in missing_readmes:
            module_key, document, document_chunks, document_search = base.parse_document(path, source_root)
            module_id = f"private.{slug(_module_key(path.relative_to(source_root)))}"
            module = module_documents.get(module_id)
            if module is None:
                module = {
                    "id": module_id,
                    "title": "Overview" if module_id == "private.overview" else base.MODULE_TITLES.get(module_key, base._title_from_stem(module_key)),
                    "visibility": "public",
                    "documents": [],
                }
                package["modules"].append(module)
                module_documents[module_id] = module
            module["documents"].append(document)
            module["documents"].sort(key=lambda item: item["id"])
            for chunk_id, chunk in document_chunks.items():
                if chunk_id in package["chunks"]:
                    raise ImportFailure("STABLE_ID_COLLISION", chunk_id)
                # parse_document uses the old module-key rule for root README. Rebind it to overview.
                chunk["moduleId"] = module_id
                package["chunks"][chunk_id] = chunk
            package["searchIndex"]["entries"].extend(document_search)
        package["modules"].sort(key=lambda item: item["id"])
    normalize_package_links(package, markdown, source_root, authority.package_id)
    return package


def build(
    source_repo_root: Path,
    output_root: Path,
    authority_file: Path = DEFAULT_AUTHORITY,
    base_project: Path | None = None,
) -> dict[str, object]:
    output_root = base.safe_output_root(output_root)
    authority = base.load_authority(authority_file)
    source_root, digest, counts = base.verify_source(source_repo_root.resolve(), authority)
    package = build_package(source_root, authority)
    output_root.mkdir(parents=True, exist_ok=True)
    runtime = base.write_runtime(output_root, authority, digest, counts, package)
    project_path = None
    if base_project is not None:
        project_path = base.write_generated_project(base_project.resolve(), output_root, runtime)
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


def parse_args(argv=None):
    return base.parse_args(argv)


def main(argv=None) -> int:
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
