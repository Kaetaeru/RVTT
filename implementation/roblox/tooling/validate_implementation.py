from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

for project in ("default.project.json", "test.project.json"):
    try:
        json.loads((ROOT / project).read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{project}: {exc}")

luau = list((ROOT / "src").rglob("*.lua")) + list((ROOT / "tests").rglob("*.lua"))
if len(luau) < 45:
    errors.append(f"expected at least 45 Luau files, found {len(luau)}")

for path in luau:
    text = path.read_text(encoding="utf-8")
    relative = path.relative_to(ROOT)
    if not text.startswith("--!strict"):
        errors.append(f"{relative}: missing --!strict")
    if re.search(r"\bwhile\s+true\s+do\b", text):
        errors.append(f"{relative}: unbounded loop")
    if "_G" in text:
        errors.append(f"{relative}: hidden global state")
    if path.is_relative_to(ROOT / "src" / "StarterGui") and (
        "FireServer" in text or "InvokeServer" in text
    ):
        errors.append(f"{relative}: UI component calls remote directly")

required = [
    "src/ServerScriptService/RVTT/ServerBoot.server.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/ClientBoot.client.lua",
    "src/StarterPlayer/StarterPlayerScripts/RVTT/Client/ClientRuntime.lua",
    "src/StarterGui/RVTT/App.client.lua",
    "manifests/all-slices-script-manifest.md",
]
for relative in required:
    if not (ROOT / relative).exists():
        errors.append(f"missing {relative}")

domains = list(
    (ROOT / "src/ServerScriptService/RVTT/Server/Domains").glob("*Domain.lua")
)
if len(domains) < 18:
    errors.append(
        "expected domain scripts for all slices plus slice-01 support, "
        f"found {len(domains)}"
    )

if errors:
    print("RVTT implementation validation failed:")
    for error in errors:
        print("-", error)
    sys.exit(1)

print(
    "RVTT implementation validation passed: "
    f"{len(luau)} Luau files, {len(domains)} domain files"
)
