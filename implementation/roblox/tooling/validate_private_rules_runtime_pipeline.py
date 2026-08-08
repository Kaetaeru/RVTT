from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Iterable


ROBLOX_ROOT = Path(__file__).resolve().parents[1]
IMPORTER = ROBLOX_ROOT / "tooling/build_private_rules_runtime.py"
STUDIO_RUNNER = ROBLOX_ROOT / "tooling/run-private-rules-studio.ps1"
PRIVATE_PACKAGE_ID = "rvtt.test.rules.2024.integrated.ko"
EXPECTED_COUNTS = {
    "classes": 12,
    "subclasses": 48,
    "backgrounds": 16,
    "species": 10,
    "feats": 75,
    "spells": 391,
}
MAX_CHUNK_BYTES = 16 * 1024


def run(command: list[str], *, cwd: Path | None = None, expect_success: bool = True) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(
        command,
        cwd=str(cwd) if cwd else None,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if expect_success and completed.returncode != 0:
        raise RuntimeError(f"command failed: {' '.join(command[:3])} :: {completed.stderr.strip()}")
    return completed


def write_markdown(path: Path, title: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f"# {title}\n\nSynthetic owner-only pipeline fixture.\n\n## Detail\n\nStable anchor fixture {title}.\n",
        encoding="utf-8",
    )


def make_source_repo(root: Path) -> tuple[str, str]:
    run(["git", "init", "-q"], cwd=root)
    run(["git", "config", "user.email", "rvtt-pipeline@example.invalid"], cwd=root)
    run(["git", "config", "user.name", "RVTT Pipeline"], cwd=root)
    source = root / "10-RULEBOOKS/integrated-2024"
    for index in range(1, 13):
        write_markdown(source / f"classes/class-{index:02d}.md", f"Class {index:02d}")
        for subclass in range(1, 5):
            write_markdown(
                source / f"classes/class-{index:02d}/subclass-{subclass:02d}.md",
                f"Subclass {index:02d}-{subclass:02d}",
            )
    for directory, count, label in (
        ("backgrounds", 16, "Background"),
        ("species", 10, "Species"),
        ("feats", 75, "Feat"),
        ("spells", 391, "Spell"),
    ):
        for index in range(1, count + 1):
            write_markdown(source / directory / f"item-{index:03d}.md", f"{label} {index:03d}")
    for directory in ("playing-the-game", "character-creation", "equipment", "rules-glossary"):
        write_markdown(source / directory / "core.md", directory.replace("-", " ").title())
    run(["git", "add", "."], cwd=root)
    run(["git", "commit", "-qm", "synthetic private source"], cwd=root)
    revision = run(["git", "rev-parse", "HEAD"], cwd=root).stdout.strip()
    digest = run(
        ["git", "rev-parse", "HEAD:10-RULEBOOKS/integrated-2024"], cwd=root
    ).stdout.strip()
    return revision, digest


def authority_text(revision: str, digest: str, counts: dict[str, int] = EXPECTED_COUNTS) -> str:
    count_lines = "\n".join(f"\t\t\t{name} = {value}," for name, value in counts.items())
    return f'''--!strict
return {{
\t{{
\t\tpackageId = "rvtt.core.rules",
\t\tversion = "fixture-public",
\t\tcontentKinds = {{ "rule-packs" }},
\t\tdefaultProfiles = {{ "public" }},
\t\tpublicBuildAllowed = true,
\t}},
\t{{
\t\tpackageId = "{PRIVATE_PACKAGE_ID}",
\t\tversion = "{revision}",
\t\tcontentKinds = {{ "rule-packs" }},
\t\tdefaultProfiles = {{ "development", "test", "studio-acceptance" }},
\t\tsourceMode = "external_private_import",
\t\tsourceRepository = "synthetic/private-source",
\t\tsourceBindingKey = "RVTT_PRIVATE_DND2024_KO_SOURCE",
\t\tsourceRoot = "10-RULEBOOKS/integrated-2024",
\t\texpectedSourceDigest = "{digest}",
\t\texpectedContentCounts = {{
{count_lines}
\t\t}},
\t\townerOnly = true,
\t\tfailClosed = true,
\t}},
}}
'''


def run_import(source_repo: Path, output: Path, authority: Path, *, expect_success: bool) -> subprocess.CompletedProcess[str]:
    return run(
        [
            sys.executable,
            str(IMPORTER),
            "--source-repo-root",
            str(source_repo),
            "--output-root",
            str(output),
            "--authority-file",
            str(authority),
            "--base-project",
            str(ROBLOX_ROOT / "default.project.json"),
        ],
        expect_success=expect_success,
    )


def expect_failure(source_repo: Path, output: Path, authority: Path, code: str) -> None:
    completed = run_import(source_repo, output, authority, expect_success=False)
    if completed.returncode == 0 or code not in completed.stderr:
        raise RuntimeError(f"expected importer failure {code}, got rc={completed.returncode}")


def validate_studio_runner_contract() -> None:
    if not STUDIO_RUNNER.is_file():
        raise RuntimeError("private rules Studio runner is missing")
    text = STUDIO_RUNNER.read_text(encoding="utf-8")
    for marker in (
        "RVTT_PRIVATE_DND2024_KO_SOURCE",
        "build_private_rules_runtime.py",
        "private-rules.generated.project.json",
        "Readiness.json",
        "RuleReaderPackage.json",
        'Invoke-NativeChecked $rojoPath @("build", $generatedProject',
    ):
        if marker not in text:
            raise RuntimeError(f"private rules Studio runner is missing marker: {marker}")
    if 'rojoPath @("build", $projectPath' in text:
        raise RuntimeError("private rules Studio runner must not bypass the generated overlay project")


def validate_generated(output: Path, rojo: str | None) -> None:
    runtime = output / "runtime/RVTTPrivateRuleContent"
    readiness = json.loads((runtime / "Readiness.json").read_text(encoding="utf-8"))
    package = json.loads((runtime / "RuleReaderPackage.json").read_text(encoding="utf-8"))
    manifest = json.loads((output / "private-rules.import-manifest.json").read_text(encoding="utf-8"))
    project = json.loads((output / "private-rules.generated.project.json").read_text(encoding="utf-8"))
    if readiness["bindingPresent"] is not True or readiness["contentCounts"] != EXPECTED_COUNTS:
        raise RuntimeError("generated Readiness contract mismatch")
    if package["packageId"] != PRIVATE_PACKAGE_ID or package["version"] != readiness["revision"]:
        raise RuntimeError("generated package identity mismatch")
    if not package.get("modules") or not package.get("chunks") or not package.get("searchIndex", {}).get("entries"):
        raise RuntimeError("generated package is missing modules/chunks/search index")
    if manifest["chunkCount"] != len(package["chunks"]):
        raise RuntimeError("generated import manifest chunk count mismatch")
    for chunk in package["chunks"].values():
        if len(chunk["text"].encode("utf-8")) > MAX_CHUNK_BYTES:
            raise RuntimeError("generated rule chunk exceeds 16KB")
    server_storage = project.get("tree", {}).get("ServerStorage", {})
    if "RVTTPrivateRuleContent" not in server_storage:
        raise RuntimeError("generated project does not inject RVTTPrivateRuleContent")
    serialized = (runtime / "RuleReaderPackage.json").read_text(encoding="utf-8")
    for forbidden in ("Kaetaeru/D-D-2024-", "d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4"):
        if forbidden in serialized:
            raise RuntimeError("synthetic runtime unexpectedly contains production private-source metadata")
    if rojo:
        output_place = output / "synthetic-private-rules.rbxlx"
        run([rojo, "build", str(output / "private-rules.generated.project.json"), "--output", str(output_place)])
        if not output_place.is_file() or output_place.stat().st_size == 0:
            raise RuntimeError("Rojo did not produce the private-rules overlay place")
        xml = output_place.read_text(encoding="utf-8", errors="replace")
        for marker in ("RVTTPrivateRuleContent", "Readiness", "RuleReaderPackage"):
            if marker not in xml:
                raise RuntimeError(f"generated Rojo place is missing private binding instance: {marker}")
        if xml.count('<Item class="ModuleScript"') < 2:
            raise RuntimeError("generated Rojo place does not contain the private JSON modules as ModuleScripts")


def validate_negative_paths(work: Path, source_repo: Path, revision: str, digest: str) -> None:
    authority = work / "authority-negative.lua"
    authority.write_text(authority_text("0" * 40, digest), encoding="utf-8")
    expect_failure(source_repo, work / "out-wrong-revision", authority, "SOURCE_REVISION_MISMATCH")

    authority.write_text(authority_text(revision, "1" * 40), encoding="utf-8")
    expect_failure(source_repo, work / "out-wrong-digest", authority, "SOURCE_DIGEST_MISMATCH")

    wrong_counts = dict(EXPECTED_COUNTS)
    wrong_counts["spells"] += 1
    authority.write_text(authority_text(revision, digest, wrong_counts), encoding="utf-8")
    expect_failure(source_repo, work / "out-wrong-count", authority, "CONTENT_COUNT_MISMATCH")

    authority.write_text(authority_text(revision, digest), encoding="utf-8")
    dirty_file = source_repo / "10-RULEBOOKS/integrated-2024/spells/item-001.md"
    dirty_file.write_text(dirty_file.read_text(encoding="utf-8") + "\nlocal edit\n", encoding="utf-8")
    expect_failure(source_repo, work / "out-dirty", authority, "SOURCE_WORKTREE_DIRTY")
    run(["git", "checkout", "--", "10-RULEBOOKS/integrated-2024/spells/item-001.md"], cwd=source_repo)

    expect_failure(work / "missing-source", work / "out-missing", authority, "PRIVATE_SOURCE_MISSING")


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate private rules importer and generated Rojo overlay with public synthetic content.")
    parser.add_argument("--rojo", default="")
    return parser.parse_args(argv)


def main(argv: Iterable[str] | None = None) -> int:
    args = parse_args(argv)
    validate_studio_runner_contract()
    with tempfile.TemporaryDirectory(prefix="rvtt-private-rules-pipeline-") as temp:
        work = Path(temp)
        source_repo = work / "private-source"
        source_repo.mkdir()
        revision, digest = make_source_repo(source_repo)
        authority = work / "authority.lua"
        authority.write_text(authority_text(revision, digest), encoding="utf-8")
        output = work / "output"
        run_import(source_repo, output, authority, expect_success=True)
        validate_generated(output, args.rojo or None)
        validate_negative_paths(work, source_repo, revision, digest)
    print("Private rules runtime pipeline validation passed: synthetic import + binding instances + overlay build + fail-closed regressions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
