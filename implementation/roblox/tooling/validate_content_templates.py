from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = ROOT / "content-templates"
errors: list[str] = []


def load_json(name: str) -> Any:
    path = TEMPLATES / name
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - error reporting path
        errors.append(f"{name}: {exc}")
        return None


statblock_schema = load_json("actor-statblock.schema.json")
source_fixtures = load_json("actor-statblock-source-type-fixtures.json")
catalog_schema = load_json("actor-model-catalog.schema.json")
catalog_example = load_json("actor-model-catalog.example.json")

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
        if not isinstance(rejected, list) or not rejected:
            errors.append("actor source types: legacyRejected must contain at least one alias")
        else:
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
    for source_type in (
        "rules_package",
        "campaign_homebrew",
        "imported_reference",
        "unknown_draft",
    ):
        if source_type not in prompt_text:
            errors.append(f"actor-statblock-ai-prompt.md: missing canonical source type {source_type}")
    for legacy_alias in ("homebrew", "campaign_custom"):
        if legacy_alias not in prompt_text:
            errors.append(f"actor-statblock-ai-prompt.md: missing explicit legacy rejection {legacy_alias}")
    if "rvtt.actor-model-catalog.v1" not in prompt_text:
        errors.append("actor-statblock-ai-prompt.md: missing catalog schema version")

if errors:
    print("RVTT content template validation failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("RVTT content template validation passed")
