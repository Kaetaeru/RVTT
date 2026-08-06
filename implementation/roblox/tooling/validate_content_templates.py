from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
TEMPLATES = ROOT / "content-templates"

ADR_RELATIVE = "docs/remake/decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md"
RUNTIME_RELATIVE = "docs/remake/architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md"
WORKFLOW_RELATIVE = ".github/workflows/validate-rvtt-content-templates.yml"

errors: list[str] = []


def load_json(name: str) -> Any:
    path = TEMPLATES / name
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - error reporting path
        errors.append(f"{name}: {exc}")
        return None


def load_text(relative_path: str) -> str:
    path = REPO_ROOT / relative_path
    try:
        return path.read_text(encoding="utf-8")
    except Exception as exc:  # pragma: no cover - error reporting path
        errors.append(f"{relative_path}: {exc}")
        return ""


def authority_doc_errors(
    adr_text: str,
    runtime_text: str,
    canonical_source_types: list[str],
    legacy_aliases: list[str],
    canonical_catalog: dict[str, Any],
) -> list[str]:
    findings: list[str] = []

    if len(canonical_source_types) != 4:
        findings.append("AUTHORITY_SOURCE_TYPE_FIXTURE_INVALID: expected four canonical source types")
        return findings
    if len(legacy_aliases) < 2:
        findings.append("AUTHORITY_LEGACY_ALIAS_FIXTURE_INVALID: expected at least two legacy aliases")
        return findings

    no_source_line = (
        "- 출처가 없는 항목의 canonical `sourceType`은 "
        f"`{canonical_source_types[1]}` 또는 `{canonical_source_types[3]}`다."
    )
    adr_legacy_line = (
        f"- `{legacy_aliases[0]}`와 `{legacy_aliases[1]}`은 legacy alias이며 "
        "Strict Schema에서 거부한다."
    )
    runtime_source_block = "\n".join(
        [
            "```text",
            "sourceType",
            f"├─ {canonical_source_types[0]}",
            f"├─ {canonical_source_types[1]}",
            f"├─ {canonical_source_types[2]}",
            f"└─ {canonical_source_types[3]}",
            "```",
        ]
    )
    runtime_legacy_prefix = (
        f"`{legacy_aliases[0]}`와 `{legacy_aliases[1]}`은 이전 문서에서 사용된 legacy alias이며"
    )
    canonical_catalog_block = (
        "```json\n"
        + json.dumps(canonical_catalog, ensure_ascii=False, indent=2)
        + "\n```"
    )

    if no_source_line not in adr_text:
        findings.append("ADR_SOURCE_TYPE_DRIFT: canonical no-source policy does not match fixture")
    if adr_legacy_line not in adr_text:
        findings.append("ADR_LEGACY_ALIAS_DRIFT: legacy rejection policy does not match fixture")
    if canonical_catalog_block not in adr_text:
        findings.append("ADR_EMPTY_CATALOG_DRIFT: canonical empty Catalog does not match fixture")

    if runtime_source_block not in runtime_text:
        findings.append("RUNTIME_SOURCE_TYPE_DRIFT: canonical sourceType block does not match fixture")
    if runtime_legacy_prefix not in runtime_text:
        findings.append("RUNTIME_LEGACY_ALIAS_DRIFT: legacy rejection policy does not match fixture")
    if canonical_catalog_block not in runtime_text:
        findings.append("RUNTIME_EMPTY_CATALOG_DRIFT: canonical empty Catalog does not match fixture")

    return findings


def workflow_trigger_errors(workflow_text: str) -> list[str]:
    findings: list[str] = []
    for required_path in (ADR_RELATIVE, RUNTIME_RELATIVE):
        if f'- "{required_path}"' not in workflow_text:
            findings.append(
                f"WORKFLOW_TRIGGER_DRIFT: content-template workflow must watch {required_path}"
            )
    return findings


statblock_schema = load_json("actor-statblock.schema.json")
source_fixtures = load_json("actor-statblock-source-type-fixtures.json")
catalog_schema = load_json("actor-model-catalog.schema.json")
catalog_example = load_json("actor-model-catalog.example.json")

canonical_source_types: list[str] = []
legacy_aliases: list[str] = []

if isinstance(statblock_schema, dict) and isinstance(source_fixtures, dict):
    try:
        source_enum = statblock_schema["$defs"]["source"]["properties"]["sourceType"]["enum"]
    except Exception as exc:
        errors.append(f"actor-statblock.schema.json: sourceType enum missing: {exc}")
    else:
        canonical = source_fixtures.get("canonicalAllowed")
        rejected = source_fixtures.get("legacyRejected")
        if source_fixtures.get("schemaVersion") != "rvtt.actor-source-type-fixtures.v1":
            errors.append("actor-statblock-source-type-fixtures.json: unexpected schemaVersion")
        if source_enum != canonical:
            errors.append(
                "actor source types: schema enum must exactly match canonicalAllowed in stable order"
            )
        if isinstance(canonical, list) and all(isinstance(value, str) for value in canonical):
            canonical_source_types = canonical
        else:
            errors.append("actor source types: canonicalAllowed must be a string list")
        if not isinstance(rejected, list) or not rejected:
            errors.append("actor source types: legacyRejected must contain at least one alias")
        else:
            legacy_aliases = [value for value in rejected if isinstance(value, str)]
            if len(legacy_aliases) != len(rejected):
                errors.append("actor source types: legacyRejected must contain strings only")
            overlap = sorted(set(source_enum).intersection(rejected))
            if overlap:
                errors.append(f"actor source types: legacy aliases accepted by schema: {overlap}")
            for expected_alias in ("homebrew", "campaign_custom"):
                if expected_alias not in rejected:
                    errors.append(f"actor source types: missing rejected alias {expected_alias}")

EXPECTED_CATALOG_KEYS = [
    "schemaVersion",
    "catalogRevision",
    "packageVersionSet",
    "models",
    "disclosureDigest",
]
EXPECTED_EMPTY_DIGEST = (
    "sha256:e3b0c44298fc1c149afbf4c8996fb924"
    "27ae41e4649b934ca495991b7852b855"
)

if isinstance(catalog_schema, dict):
    if catalog_schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        errors.append("actor-model-catalog.schema.json: must use JSON Schema draft 2020-12")
    required = catalog_schema.get("required")
    if required != EXPECTED_CATALOG_KEYS:
        errors.append("actor-model-catalog.schema.json: required fields or stable order mismatch")
    properties = catalog_schema.get("properties", {})
    schema_version = properties.get("schemaVersion", {}).get("const")
    if schema_version != "rvtt.actor-model-catalog.v1":
        errors.append("actor-model-catalog.schema.json: unexpected schemaVersion const")
    digest_pattern = properties.get("disclosureDigest", {}).get("pattern")
    if digest_pattern != "^sha256:[0-9a-f]{64}$":
        errors.append("actor-model-catalog.schema.json: disclosureDigest pattern mismatch")

if isinstance(catalog_example, dict):
    if list(catalog_example.keys()) != EXPECTED_CATALOG_KEYS:
        errors.append("actor-model-catalog.example.json: canonical key set or order mismatch")
    if catalog_example.get("schemaVersion") != "rvtt.actor-model-catalog.v1":
        errors.append("actor-model-catalog.example.json: unexpected schemaVersion")
    if catalog_example.get("catalogRevision") != 0:
        errors.append("actor-model-catalog.example.json: empty fixture revision must be 0")
    if catalog_example.get("packageVersionSet") != []:
        errors.append("actor-model-catalog.example.json: empty fixture packageVersionSet must be []")
    if catalog_example.get("models") != []:
        errors.append("actor-model-catalog.example.json: empty fixture models must be []")
    if catalog_example.get("disclosureDigest") != EXPECTED_EMPTY_DIGEST:
        errors.append("actor-model-catalog.example.json: empty disclosure digest mismatch")

    package_versions = catalog_example.get("packageVersionSet", [])
    if package_versions != sorted(set(package_versions)):
        errors.append("actor-model-catalog.example.json: packageVersionSet must be unique and sorted")

    models = catalog_example.get("models", [])
    if isinstance(models, list):
        model_ids = [model.get("actorModelAssetId") for model in models if isinstance(model, dict)]
        if len(model_ids) != len(models) or any(not isinstance(model_id, str) for model_id in model_ids):
            errors.append("actor-model-catalog.example.json: every model needs actorModelAssetId")
        elif model_ids != sorted(model_ids):
            errors.append("actor-model-catalog.example.json: models must use stable actorModelAssetId order")

prompt_path = TEMPLATES / "actor-statblock-ai-prompt.md"
try:
    prompt_text = prompt_path.read_text(encoding="utf-8")
except Exception as exc:  # pragma: no cover - error reporting path
    errors.append(f"actor-statblock-ai-prompt.md: {exc}")
else:
    for source_type in canonical_source_types:
        if f"`{source_type}`" not in prompt_text:
            errors.append(f"actor-statblock-ai-prompt.md: missing canonical source type {source_type}")
    for legacy_alias in legacy_aliases:
        if f"`{legacy_alias}`" not in prompt_text:
            errors.append(f"actor-statblock-ai-prompt.md: missing explicit legacy rejection {legacy_alias}")
    if "rvtt.actor-model-catalog.v1" not in prompt_text:
        errors.append("actor-statblock-ai-prompt.md: missing catalog schema version")

adr_text = load_text(ADR_RELATIVE)
runtime_text = load_text(RUNTIME_RELATIVE)
workflow_text = load_text(WORKFLOW_RELATIVE)

if canonical_source_types and legacy_aliases and isinstance(catalog_example, dict):
    errors.extend(
        authority_doc_errors(
            adr_text,
            runtime_text,
            canonical_source_types,
            legacy_aliases,
            catalog_example,
        )
    )
    errors.extend(workflow_trigger_errors(workflow_text))

    expected_adr_line = (
        "- 출처가 없는 항목의 canonical `sourceType`은 "
        f"`{canonical_source_types[1]}` 또는 `{canonical_source_types[3]}`다."
    )
    mutated_adr = adr_text.replace(expected_adr_line, "- BROKEN SOURCE TYPE POLICY", 1)
    negative_adr_errors = authority_doc_errors(
        mutated_adr,
        runtime_text,
        canonical_source_types,
        legacy_aliases,
        catalog_example,
    )
    if not any(item.startswith("ADR_SOURCE_TYPE_DRIFT:") for item in negative_adr_errors):
        errors.append("negative regression self-test: ADR sourceType drift was not detected")

    canonical_catalog_block = (
        "```json\n"
        + json.dumps(catalog_example, ensure_ascii=False, indent=2)
        + "\n```"
    )
    mutated_runtime = runtime_text.replace(
        canonical_catalog_block,
        "```json\n{\"models\": []}\n```",
        1,
    )
    negative_runtime_errors = authority_doc_errors(
        adr_text,
        mutated_runtime,
        canonical_source_types,
        legacy_aliases,
        catalog_example,
    )
    if not any(item.startswith("RUNTIME_EMPTY_CATALOG_DRIFT:") for item in negative_runtime_errors):
        errors.append("negative regression self-test: Runtime empty Catalog drift was not detected")

    mutated_workflow = workflow_text.replace(f'- "{ADR_RELATIVE}"', "", 1)
    negative_workflow_errors = workflow_trigger_errors(mutated_workflow)
    if not any(item.startswith("WORKFLOW_TRIGGER_DRIFT:") for item in negative_workflow_errors):
        errors.append("negative regression self-test: Workflow authority path drift was not detected")

if errors:
    print("RVTT content template validation failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("RVTT content template validation passed")
