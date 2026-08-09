from __future__ import annotations

from pathlib import Path
import json
import math
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]

FILES = {
    "projection": ROOT / "src/ServerScriptService/RVTT/Server/Projection/CharacterSheetProjection.lua",
    "projection_builder": ROOT / "src/ServerScriptService/RVTT/Server/Projection/ProjectionBuilder.lua",
    "layout": ROOT / "src/ReplicatedStorage/RVTT/Shared/UI/CharacterSheetLayout.lua",
    "view_model": ROOT / "src/ReplicatedStorage/RVTT/Shared/UI/CharacterSheetViewModel.lua",
    "surface": ROOT / "src/StarterGui/RVTT/UI/Components/OfficialCharacterSheet.lua",
    "popover": ROOT / "src/StarterGui/RVTT/UI/Components/SheetItemActionPopover.lua",
    "app": ROOT / "src/StarterGui/RVTT/App.client.lua",
    "hud": ROOT / "src/StarterGui/RVTT/UI/Components/GameplayHud.lua",
    "character_domain": ROOT / "src/ServerScriptService/RVTT/Server/Domains/CharacterDomain.lua",
    "inventory_domain": ROOT / "src/ServerScriptService/RVTT/Server/Domains/InventoryDomain.lua",
    "rules_domain": ROOT / "src/ServerScriptService/RVTT/Server/Domains/RulesDomain.lua",
    "content_domain": ROOT / "src/ServerScriptService/RVTT/Server/Domains/ContentDomain.lua",
    "definition_resolver": ROOT / "src/ServerScriptService/RVTT/Server/Rules/ContentDefinitionResolver.lua",
    "actor_profile_resolver": ROOT / "src/ServerScriptService/RVTT/Server/Rules/ActorProfileResolver.lua",
    "spec": ROOT / "tests/Unit/OfficialCharacterSheet.spec.lua",
    "runner": ROOT / "tests/TestRunner.server.lua",
}

MATRIX_PATH = ROOT / "full-ui-ux-acceptance-matrix.json"

REQUIRED_LAYOUT = {
    "REFERENCE_PAGE_WIDTH": 8.5,
    "REFERENCE_PAGE_HEIGHT": 11.0,
    "RATIO_TOLERANCE": 0.02,
    "TOP_HEADER": 0.13,
    "MAIN": 0.87,
    "MAIN_LEFT": 0.35,
    "MAIN_RIGHT": 0.65,
    "RIGHT_WEAPONS": 0.24,
    "RIGHT_CLASS_FEATURES": 0.43,
    "RIGHT_SPECIES_FEATS": 0.33,
    "LEFT": 0.68,
    "RIGHT": 0.32,
    "SPELLCASTING_ABILITY": 0.24,
    "SPELL_SLOTS": 0.76,
    "RIGHT_APPEARANCE": 0.14,
    "RIGHT_BACKSTORY": 0.30,
    "RIGHT_LANGUAGES": 0.10,
    "RIGHT_EQUIPMENT": 0.34,
    "RIGHT_COINS": 0.12,
}

REQUIRED_EVIDENCE = {
    "implementation/roblox/src/ServerScriptService/RVTT/Server/Projection/CharacterSheetProjection.lua",
    "implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/CharacterSheetViewModel.lua",
    "implementation/roblox/src/StarterGui/RVTT/UI/Components/OfficialCharacterSheet.lua",
    "implementation/roblox/src/StarterGui/RVTT/UI/Components/SheetItemActionPopover.lua",
    "implementation/roblox/tests/Unit/OfficialCharacterSheet.spec.lua",
    "implementation/roblox/tooling/validate_official_character_sheet.py",
}


def _contains_all(text: str, markers: set[str], name: str, errors: list[str]) -> None:
    for marker in sorted(markers):
        if marker not in text:
            errors.append(f"{name}: missing required contract marker {marker}")


def _layout_values(text: str) -> dict[str, float]:
    values: dict[str, float] = {}
    for name, raw in re.findall(r"\b([A-Z][A-Z0-9_]*)\s*=\s*([0-9]+(?:\.[0-9]+)?)", text):
        values[name] = float(raw)
    return values


def validate_layout_text(text: str) -> list[str]:
    errors: list[str] = []
    values = _layout_values(text)
    for name, expected in REQUIRED_LAYOUT.items():
        actual = values.get(name)
        if actual is None or not math.isclose(actual, expected, abs_tol=1e-9):
            errors.append(f"layout: {name} must equal {expected}")
    groups = {
        "page1 vertical": ["TOP_HEADER", "MAIN"],
        "page1 columns": ["MAIN_LEFT", "MAIN_RIGHT"],
        "page1 right sections": ["RIGHT_WEAPONS", "RIGHT_CLASS_FEATURES", "RIGHT_SPECIES_FEATS"],
        "page2 columns": ["LEFT", "RIGHT"],
        "page2 spell header": ["SPELLCASTING_ABILITY", "SPELL_SLOTS"],
        "page2 right sections": [
            "RIGHT_APPEARANCE",
            "RIGHT_BACKSTORY",
            "RIGHT_LANGUAGES",
            "RIGHT_EQUIPMENT",
            "RIGHT_COINS",
        ],
    }
    for group, names in groups.items():
        if all(name in values for name in names):
            total = sum(values[name] for name in names)
            if not math.isclose(total, 1.0, abs_tol=values.get("RATIO_TOLERANCE", 0.02)):
                errors.append(f"layout: {group} must total 1.0 within ±2%")
    return errors


def validate_client_boundary(view_model: str, surface: str, popover: str) -> list[str]:
    errors: list[str] = []
    client_text = "\n".join((view_model, surface, popover))
    forbidden = {
        "FireServer": "direct Remote invocation",
        "InvokeServer": "direct Remote invocation",
        "Random.new": "client dice calculation",
        "math.random": "client dice calculation",
        "Shared.Rules.Dice": "client dice adjudication",
    }
    for marker, reason in forbidden.items():
        if marker in client_text:
            errors.append(f"client boundary: {reason} marker found: {marker}")
    return errors


def validate_forbidden_patterns(projection: str, rules_domain: str, surface: str) -> list[str]:
    errors: list[str] = []
    if "character.attacks" in projection:
        errors.append("CharacterSheetProjection: attack rows must use canonical profile.attacks")
    if "state.equipment[1]" in surface:
        errors.append("OfficialCharacterSheet: first-row-only equipment shortcut is forbidden")
    if re.search(r"(?:tostring|valueText)\(spellcasting\.slots\)", surface):
        errors.append("OfficialCharacterSheet: spell slot tables require structured rendering")
    sheet_block = rules_domain.split('commandType = "rules.update_vitals"', 1)[0]
    for trusted in ("payload.ability", "payload.proficient", "payload.mode"):
        if trusted in sheet_block:
            errors.append(f"RulesDomain: sheet roll must not trust client semantics {trusted}")
    return errors


def validate_capability_authority(
    projection: str,
    rules_domain: str,
    inventory_domain: str,
    character_domain: str,
    actor_profile_resolver: str,
) -> list[str]:
    errors: list[str] = []
    required = {
        "RulesDomain hit die guard": (
            rules_domain,
            {
                '"remaining"',
                "isFiniteInteger(hitDice.remaining)",
                "hitDice.remaining <= 0",
                "hitDice.remaining -= 1",
            },
        ),
        "CharacterSheetProjection hit die parity": (
            projection,
            {"availableHitDice", "hitDice.remaining > 0"},
        ),
        "InventoryDomain trusted equip capability": (
            inventory_domain,
            {
                "item.equipSlot",
                "payload.slot ~= item.equipSlot",
                "location.characterId ~= payload.characterId",
            },
        ),
        "CharacterDomain hotbar capability": (
            character_domain,
            {
                "item.hotbarCapable ~= true",
                "location.characterId ~= payload.characterId",
            },
        ),
        "CharacterSheetProjection attack provenance": (
            projection + actor_profile_resolver,
            {'profile.attackSource == "character_definition"', '"fallback"'},
        ),
    }
    for name, (text, markers) in required.items():
        for marker in markers:
            if marker not in text:
                errors.append(f"{name}: missing {marker}")
    if "slot = payload.slot" in inventory_domain:
        errors.append("InventoryDomain: equip must not trust slot = payload.slot")
    return errors


def validate(root: Path = ROOT) -> list[str]:
    if root != ROOT:
        raise ValueError("validate_official_character_sheet only supports its repository checkout")
    errors: list[str] = []
    texts: dict[str, str] = {}
    for name, path in FILES.items():
        if not path.is_file():
            errors.append(f"missing production/focused file: {path.relative_to(REPO_ROOT)}")
        else:
            texts[name] = path.read_text(encoding="utf-8")
    if errors:
        return errors

    errors.extend(validate_layout_text(texts["layout"]))
    errors.extend(validate_client_boundary(texts["view_model"], texts["surface"], texts["popover"]))
    errors.extend(
        validate_forbidden_patterns(
            texts["projection"], texts["rules_domain"], texts["surface"]
        )
    )
    errors.extend(
        validate_capability_authority(
            texts["projection"],
            texts["rules_domain"],
            texts["inventory_domain"],
            texts["character_domain"],
            texts["actor_profile_resolver"],
        )
    )

    _contains_all(
        texts["projection"],
        {
            "CharacterSheetProjection.build",
            "canReadFullSheet",
            "viewerRole",
            "requestedCharacterId",
            "ownerUserId == viewer.userId",
            "revision = revision",
            "rules.sheet_roll",
            "inventory.equip",
            "inventory.unequip",
            "inventory.use",
            "inventory.split",
            "inventory.set_attunement",
            "character.sheet_set_prepared",
            "character.sheet_set_hotbar",
            "character.sheet_spend_inspiration",
        },
        "CharacterSheetProjection",
        errors,
    )
    _contains_all(
        texts["view_model"],
        {
            'OPEN_ACTION = "OpenCharacterSheet"',
            "candidateRevision ~= state.revision",
            'state = "pending_receipt"',
            'state = "accepted_awaiting_projection"',
            'state = "reconciled"',
            'state = "permission_revoked"',
        },
        "CharacterSheetViewModel",
        errors,
    )
    _contains_all(
        texts["surface"],
        {
            "Official2024CharacterSheetSurface",
            "OfficialSheetPage1",
            "OfficialSheetPage2",
            "TwoPageSpread",
            "CompactPageTabs",
            "UIAspectRatioConstraint",
            "Page1TopHeader13",
            "Page1MainLeft35",
            "Page2Left68",
            "Page2Right32",
            "LevelXP",
            "ArmorClassShield",
            "HitPointsTemp",
            "HitDice",
            "DeathSaves",
            "ProficiencyInspirationTraining",
            "AllEquipmentRows",
            "EquipmentDetailsSurface",
            "structuredSlots",
        },
        "OfficialCharacterSheet",
        errors,
    )
    _contains_all(
        texts["popover"],
        {"SheetItemActionPopover", "RVTTDisabledReason", "Selectable"},
        "SheetItemActionPopover",
        errors,
    )
    _contains_all(
        texts["app"] + texts["hud"],
        {"OpenCharacterSheet", "character_sheet_surface", "client.Command:submit", "renderCharacterSheet"},
        "App integration",
        errors,
    )
    _contains_all(
        texts["projection_builder"],
        {"CharacterSheetProjection", "state.revision", "characterSheet ="},
        "ProjectionBuilder",
        errors,
    )
    _contains_all(
        texts["rules_domain"],
        {
            'commandType = "rules.sheet_roll"',
            'commandType = "rules.update_vitals"',
            "CLIENT_RULE_FIELDS",
            "SOURCE_REQUIRED",
            "profile.attacks[payload.sourceId]",
            'Dice.rollD20(nil)',
            'death save requires zero hit points',
        },
        "RulesDomain",
        errors,
    )
    _contains_all(
        texts["definition_resolver"] + texts["content_domain"],
        {
            "ContentDefinitionResolver.resolve",
            "characterSheets",
            'collectionName ~= "characterSheets"',
            'collectionName ~= "items"',
            "active[packId] == pack.version",
        },
        "server-owned content definitions",
        errors,
    )
    _contains_all(
        texts["inventory_domain"],
        {
            'commandType = "inventory.equip"',
            'commandType = "inventory.unequip"',
            'commandType = "inventory.use"',
            'commandType = "inventory.split"',
            'commandType = "inventory.send"',
            'commandType = "inventory.set_attunement"',
        },
        "InventoryDomain",
        errors,
    )
    _contains_all(
        texts["character_domain"],
        {
            'commandType = "character.sheet_spend_inspiration"',
            'commandType = "character.sheet_set_prepared"',
            'commandType = "character.sheet_set_hotbar"',
        },
        "CharacterDomain",
        errors,
    )
    _contains_all(
        texts["spec"],
        {
            "unrelated player cannot read",
            "authorized DM can read and control",
            "stale candidate revision fails closed",
            "receipt success does not mutate local sheet state",
            "Page 1 header ratio is locked",
            "Page 2 right sections fill the page without reflow",
            "forged ability roll semantics are rejected",
            "forged proficient roll semantics are rejected",
            "forged mode roll semantics are rejected",
            "forged damage formula is rejected",
            "another user's actor roll is rejected",
            "production inventory path snapshots trusted capabilities",
            "valid hit die roll consumes one trusted die",
            "zero remaining removes hit die action",
            "forged equip slot fails closed",
            "non-hotbar-capable item cannot be pinned",
            "another character's capable item cannot be pinned",
            "unpin cannot bypass the item-character relationship guard",
            "trusted attack-less production character receives no invented attack row",
            "out-of-order terminal receipt cannot replace latest feedback",
        },
        "OfficialCharacterSheet.spec",
        errors,
    )
    if 'require(script.Parent.Unit["OfficialCharacterSheet.spec"])' not in texts["runner"]:
        errors.append("TestRunner: OfficialCharacterSheet.spec is not registered")

    try:
        matrix = json.loads(MATRIX_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"acceptance matrix: {exc}")
        return errors
    item = next(
        (entry for entry in matrix.get("acceptanceItems", []) if entry.get("id") == "final.official-2024-sheet-interactions"),
        None,
    )
    if not isinstance(item, dict) or item.get("currentState") != "STATIC_VERIFIED":
        errors.append("acceptance matrix: Official Sheet must be STATIC_VERIFIED")
    elif not REQUIRED_EVIDENCE.issubset(set(item.get("automatedRefs", []))):
        errors.append("acceptance matrix: Official Sheet production/focused evidence is incomplete")
    if matrix.get("finalContractGaps") != ["final.dice-slot-reveal-notice"]:
        errors.append("acceptance matrix: Dice Slot Reveal Notice must be the sole remaining gap")
    return errors


def run_self_tests() -> list[str]:
    failures: list[str] = []
    layout = FILES["layout"].read_text(encoding="utf-8")
    broken_layout = layout.replace("TOP_HEADER = 0.13", "TOP_HEADER = 0.25")
    if not validate_layout_text(broken_layout):
        failures.append("self-test: invalid Page 1 ratio was not rejected")
    boundary_errors = validate_client_boundary("Random.new()", "", "")
    if not boundary_errors:
        failures.append("self-test: client dice calculation was not rejected")
    boundary_errors = validate_client_boundary("", "remote:FireServer()", "")
    if not boundary_errors:
        failures.append("self-test: direct Remote invocation was not rejected")
    authority_errors = validate_forbidden_patterns(
        "character.attacks",
        'payload.ability\ncommandType = "rules.update_vitals"',
        "state.equipment[1]\nvalueText(spellcasting.slots)",
    )
    if len(authority_errors) != 4:
        failures.append("self-test: authority/UI shortcut regressions were not all rejected")
    capability_errors = validate_capability_authority(
        "",
        "",
        "slot = payload.slot",
        "",
        "",
    )
    if len(capability_errors) < 10:
        failures.append("self-test: capability authority guard omissions were not rejected")
    return failures


def main() -> int:
    errors = validate()
    errors.extend(run_self_tests())
    if errors:
        print("Official Character Sheet validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print("Official Character Sheet validation passed: projection, ratios, authority, interaction, and runner contracts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
