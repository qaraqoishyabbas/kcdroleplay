"""Validate enum members used in the project against the official Roblox API dump.

`luau-compile` cannot catch a wrong enum member (Enum is an unknown global for it),
so a typo like Enum.Material.Ceramic compiles fine and only fails at run time inside
Studio. This script catches it before the build.

Usage:
    python tools/check-enums.py            # uses API-Dump.json next to the repo root
    curl -sL -o API-Dump.json https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
"""
from pathlib import Path
import json
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DUMP = ROOT / "API-Dump.json"
PATTERN = re.compile(r"Enum\.(\w+)\.(\w+)")


def sources():
    for path in sorted(ROOT.rglob("*.luau")):
        if ".git" in path.parts:
            continue
        yield path, path.read_text(encoding="utf-8")
    for plugin in sorted(ROOT.glob("*.rbxmx")):
        try:
            node = ET.parse(plugin).find('.//ProtectedString[@name="Source"]')
        except ET.ParseError as error:
            print(f"plugin parse error {plugin}: {error}")
            continue
        if node is not None and node.text:
            yield plugin, node.text


def main() -> int:
    if not DUMP.exists():
        print(f"API dump missing: {DUMP}")
        print("fetch: curl -sL -o API-Dump.json https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json")
        return 2
    dump = json.loads(DUMP.read_text(encoding="utf-8"))
    enums = {item["Name"]: {member["Name"] for member in item["Items"]} for item in dump["Enums"]}

    problems = []
    checked = 0
    for path, text in sources():
        for match in PATTERN.finditer(text):
            checked += 1
            enum_name, member = match.group(1), match.group(2)
            if enum_name not in enums:
                problems.append((path, enum_name, member, "unknown enum"))
            elif member not in enums[enum_name]:
                suggestions = [name for name in enums[enum_name] if name.lower().startswith(member.lower()[:4])][:4]
                problems.append((path, enum_name, member, "unknown member; close: " + ", ".join(suggestions)))

    for path, enum_name, member, why in problems:
        print(f"{path.relative_to(ROOT)}: Enum.{enum_name}.{member} -> {why}")
    print(f"checked {checked} enum usages in {len(list(sources()))} files, problems: {len(problems)}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
