from pathlib import Path
import json, re, sys
ROOT = Path(__file__).resolve().parents[1]
errors=[]
for project in ("default.project.json","test.project.json"):
    try: json.loads((ROOT/project).read_text(encoding="utf-8"))
    except Exception as exc: errors.append(f"{project}: {exc}")
luau=list((ROOT/"src").rglob("*.lua"))+list((ROOT/"tests").rglob("*.lua"))
if len(luau)<45: errors.append(f"expected at least 45 Luau files, found {len(luau)}")
for path in luau:
    text=path.read_text(encoding="utf-8")
    if not text.startswith("--!strict"): errors.append(f"{path.relative_to(ROOT)}: missing --!strict")
    if re.search(r"\bwhile\s+true\s+do\b", text): errors.append(f"{path.relative_to(ROOT)}: unbounded loop")
    if path.is_relative_to(ROOT/"src"/"StarterGui") and ("FireServer" in text or "InvokeServer" in text): errors.append(f"{path.relative_to(ROOT)}: UI component calls remote directly")
required=[
 "src/ServerScriptService/RVTT/ServerBoot.server.lua",
 "src/StarterPlayer/StarterPlayerScripts/RVTT/ClientBoot.client.lua",
 "src/StarterGui/RVTT/App.client.lua",
 "manifests/all-slices-script-manifest.md",
]
for rel in required:
    if not (ROOT/rel).exists(): errors.append(f"missing {rel}")
domains=list((ROOT/"src/ServerScriptService/RVTT/Server/Domains").glob("*Domain.lua"))
if len(domains)<18: errors.append(f"expected domain scripts for all slices plus slice-01 support, found {len(domains)}")
if errors:
    print("RVTT implementation validation failed:")
    for error in errors: print("-",error)
    sys.exit(1)
print(f"RVTT implementation validation passed: {len(luau)} Luau files, {len(domains)} domain files")
