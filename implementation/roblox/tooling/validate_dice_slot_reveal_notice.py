from __future__ import annotations

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
FILES = {
    "projection": ROOT / "src/ServerScriptService/RVTT/Server/Projection/DiceNoticeProjection.lua",
    "projection_builder": ROOT / "src/ServerScriptService/RVTT/Server/Projection/ProjectionBuilder.lua",
    "rules": ROOT / "src/ServerScriptService/RVTT/Server/Domains/RulesDomain.lua",
    "policy": ROOT / "src/ServerScriptService/RVTT/Server/Projection/DomainProjectionPolicy.lua",
    "view_model": ROOT / "src/ReplicatedStorage/RVTT/Shared/UI/DiceNoticeViewModel.lua",
    "component": ROOT / "src/StarterGui/RVTT/UI/Components/DiceSlotRevealNotice.lua",
    "app": ROOT / "src/StarterGui/RVTT/App.client.lua",
    "spec": ROOT / "tests/Unit/DiceSlotRevealNotice.spec.lua",
    "runner": ROOT / "tests/TestRunner.server.lua",
}

EXPECTED_STATES = [
    "hidden",
    "square_enter",
    "slot_spin",
    "natural_lock",
    "formula_expand",
    "adjudication_append",
    "hold",
    "dismiss",
]


def _contains_all(text: str, markers: set[str], name: str, errors: list[str]) -> None:
    for marker in sorted(markers):
        if marker not in text:
            errors.append(f"{name}: missing {marker}")


def validate_contract_texts(texts: dict[str, str]) -> list[str]:
    errors: list[str] = []
    view_model = texts["view_model"]
    state_block = view_model.split("ViewModel.STATE_ORDER = {", 1)[-1].split("}", 1)[0]
    states = re.findall(r'"([a-z_]+)"', state_block)
    if states != EXPECTED_STATES:
        errors.append(f"DiceNoticeViewModel: state order must be {EXPECTED_STATES}")

    timing_markers = {
        "squareEnterMs = 120",
        "slotSpinMs = 560",
        "naturalLockMs = 180",
        "formulaExpandMs = 260",
        "adjudicationAppendMs = 180",
        "holdMs = 2000",
        "dismissMs = 240",
    }
    _contains_all(texts["rules"], timing_markers, "RulesDomain timing profile", errors)
    _contains_all(
        view_model,
        {
            "ViewModel.STACK_CAP = 2",
            "width = 64, height = 64",
            "width = 148, height = 64",
            "ViewModel.DISCARDED_CONTRAST = 0.5",
            "function ViewModel.suspend",
            'crossfadeSteps = if reducedMotion and name == "slot_spin" then 3 else nil',
            "shake = not reducedMotion",
        },
        "DiceNoticeViewModel presentation contract",
        errors,
    )
    _contains_all(
        texts["projection"],
        {
            "rollId = record.id",
            "audience = record.audience",
            "diceMode = notice.diceMode",
            "naturalResults = naturalResults",
            "appliedIndex = notice.appliedIndex",
            "modifierTerms = modifierTerms",
            "total = notice.total",
            "adjudication = notice.adjudication",
            "semanticCritical = notice.semanticCritical",
            "revealRevision = record.revealRevision",
            "timingProfile = table.clone(notice.timingProfile)",
            "audienceVisible(record, viewer)",
        },
        "DiceNoticeProjection authority contract",
        errors,
    )
    _contains_all(
        texts["policy"],
        {'record.audience ~= "public"', 'record.audience == "owner"'},
        "raw roll disclosure policy",
        errors,
    )
    _contains_all(
        texts["projection_builder"] + texts["app"],
        {
            "DiceNoticeProjection.build",
            "diceNotices =",
            "DiceNoticeViewModel.reconcile",
            "DiceSlotRevealNotice.new",
        },
        "projection/app integration",
        errors,
    )
    _contains_all(
        texts["component"],
        {
            'root.Name = "DiceSlotRevealNotice"',
            'frame:SetAttribute("RVTTDiceRevealPhase"',
            'value:SetAttribute("RVTTApplied"',
            'value:SetAttribute("RVTTSemanticCritical"',
            'frame:SetAttribute("RVTTNaturalOneShake"',
        },
        "DiceSlotRevealNotice presentation",
        errors,
    )
    client_text = "\n".join((texts["view_model"], texts["component"], texts["app"]))
    for marker in ("Random.new", "math.random", "Shared.Rules.Dice", "Dice.roll", "math.max", "math.min"):
        if marker in client_text:
            errors.append(f"client dice notice path: forbidden rule calculation marker {marker}")
    if re.search(r"appliedIndex\s*=\s*.*(?:>|<|max|min)", view_model):
        errors.append("DiceNoticeViewModel: appliedIndex must not be recalculated")
    if re.search(r"total\s*=\s*[^\n]*(?:\+|-|\*|/)", view_model):
        errors.append("DiceNoticeViewModel: total arithmetic is forbidden")
    _contains_all(
        texts["spec"],
        {
            "production RulesDomain creates a presentable roll record",
            "normal reveal state order is exact",
            "client does not choose max for advantage",
            "disadvantage also obeys projection appliedIndex",
            "discarded natural 20 has no critical visual",
            "discarded natural 1 has no shake semantic",
            "reduced motion uses three-step slot crossfade",
            "simultaneous stack is capped at two",
            "duplicate rollId is not re-enqueued",
            "stale revealRevision is suppressed",
            "already revealed active roll is not replayed after reconnect",
            "recovery clears active notices immediately",
            "unauthorized viewer receives no private roll placeholder or count",
            "initiative collision offset is deterministic",
            "incomplete authoritative record is excluded without fabricated fields",
        },
        "DiceSlotRevealNotice.spec",
        errors,
    )
    if 'require(script.Parent.Unit["DiceSlotRevealNotice.spec"])' not in texts["runner"]:
        errors.append("TestRunner: DiceSlotRevealNotice.spec is not registered")
    return errors


def validate(root: Path = ROOT) -> list[str]:
    if root != ROOT:
        raise ValueError("validate_dice_slot_reveal_notice only supports its repository checkout")
    errors: list[str] = []
    texts: dict[str, str] = {}
    for name, path in FILES.items():
        if not path.is_file():
            errors.append(f"missing Dice Notice file: {path.relative_to(REPO_ROOT)}")
        else:
            texts[name] = path.read_text(encoding="utf-8")
    if errors:
        return errors
    errors.extend(validate_contract_texts(texts))
    return errors


def run_self_tests() -> list[str]:
    texts = {name: path.read_text(encoding="utf-8") for name, path in FILES.items()}
    mutations = [
        ("view_model", '"natural_lock",', "", "state order"),
        ("rules", "slotSpinMs = 560", "slotSpinMs = 900", "timing"),
        ("view_model", "ViewModel.STACK_CAP = 2", "ViewModel.STACK_CAP = 3", "stack cap"),
        ("view_model", "width = 64, height = 64", "width = 80, height = 64", "normal size"),
        ("view_model", "ViewModel.DISCARDED_CONTRAST = 0.5", "ViewModel.DISCARDED_CONTRAST = 0.8", "contrast"),
        ("projection", "naturalResults = naturalResults", "naturalResults = nil", "projection fields"),
        ("policy", 'record.audience ~= "public"', "false", "audience filter"),
        ("runner", 'require(script.Parent.Unit["DiceSlotRevealNotice.spec"])', "require(script.Parent.Unit.Missing)", "runner"),
    ]
    failures: list[str] = []
    for key, old, new, label in mutations:
        broken = dict(texts)
        broken[key] = broken[key].replace(old, new, 1)
        if not validate_contract_texts(broken):
            failures.append(f"self-test: broken {label} fixture was not rejected")
    forbidden = dict(texts)
    forbidden["view_model"] += "\nlocal forged = math.max(1, 20)"
    if not validate_contract_texts(forbidden):
        failures.append("self-test: client max-based adjudication was not rejected")
    return failures


def main() -> int:
    errors = validate()
    errors.extend(run_self_tests())
    if errors:
        print("Dice Slot Reveal Notice validation failed:")
        for error in errors:
            print("-", error)
        return 1
    print("Dice Slot Reveal Notice validation passed: authority, disclosure, state, motion, queue, and focused contracts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
