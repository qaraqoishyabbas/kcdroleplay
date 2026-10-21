"""Build the one-click Studio plugin for the medieval combat project (RPG place).

The plugin waits for the place, checks the project marker Workspace.HermesCombat and,
when it is missing or outdated, runs build-combat.luau + install-combat.luau on its own.
"""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build-combat.luau"
INSTALL = ROOT / "install-combat.luau"
TARGET = ROOT / "hermes-combat-plugin.rbxmx"
BUILD_ID = 1  # must match BUILD_ID in tools/package-combat.py

HEADER = """-- Hermes: бой. Плагин сам собирает тренировочный двор и ставит систему боя.
-- Источники встроены дословно из репозитория K:\\AI_Studio\\Hermes_roblox\\RPG.

local toolbar = plugin:CreateToolbar("Hermes: бой")
local button = toolbar:CreateButton("Бой + двор", "Собрать тренировочный двор и поставить боевую систему", "rbxassetid://14978048121", "Бой")
button.ClickableWhenViewportHidden = true

local function buildYard()
"""

MIDDLE = """
end

local function installCombat()
"""

FOOTER = """
end

local function currentBuild()
	local config = game:GetService("ReplicatedStorage"):FindFirstChild("CombatConfig")
	return config and config:GetAttribute("InstalledBuild") or 0
end

local function yardParts()
	local map = workspace:FindFirstChild("Map")
	local yard = map and map:FindFirstChild("TrainingYard")
	local parts = 0
	if yard then
		for _, item in yard:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1
			end
		end
	end
	return yard, parts
end

local function isCombatProject()
	return workspace:GetAttribute("HermesCombat") == true
end

local function verify()
	local yard, parts = yardParts()
	local serverScriptService = game:GetService("ServerScriptService")
	local replicatedStorage = game:GetService("ReplicatedStorage")
	print(
		"HERMES_COMBAT_VERIFY",
		"yard=" .. tostring(yard ~= nil),
		"parts=" .. parts,
		"bootstrap=" .. tostring(serverScriptService:FindFirstChild("CombatBootstrap") ~= nil),
		"modules=" .. tostring(serverScriptService:FindFirstChild("Combat") ~= nil),
		"config=" .. tostring(replicatedStorage:FindFirstChild("CombatConfig") ~= nil),
		"build=" .. currentBuild()
	)
end

local function installOnly()
	installCombat()
	verify()
	print("HERMES_COMBAT_UPDATED: скрипты боя обновлены до сборки " .. BUILD_ID)
end

local function run(forceYard)
	if game:GetService("RunService"):IsRunning() then
		warn("HERMES_COMBAT_FAIL: идёт Play — нажми Stop и повтори")
		return
	end
	local changeHistory = game:GetService("ChangeHistoryService")
	local recording = nil
	local okRecording, result = pcall(function()
		return changeHistory:TryBeginRecording("Hermes: бой")
	end)
	if okRecording then
		recording = result
	end
	local yard, parts = yardParts()
	if forceYard or parts == 0 then
		buildYard()
	end
	installCombat()
	verify()
	if recording then
		pcall(function()
			changeHistory:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
		end)
	end
	print("HERMES_COMBAT_DONE: двор и бой готовы. Сохрани место (Ctrl+S).")
end

button.Click:Connect(function()
	button:SetActive(true)
	local ok, err = pcall(function()
		return run(true)
	end)
	button:SetActive(false)
	if not ok then
		warn("HERMES_COMBAT_FAIL: " .. tostring(err))
	end
end)

task.spawn(function()
	local playing = game:GetService("RunService"):IsRunning()
	print("HERMES_COMBAT_PLUGIN_LOADED", "play=" .. tostring(playing))
	if playing then
		return
	end
	for _ = 1, 80 do
		if workspace:FindFirstChild("Map") then
			break
		end
		task.wait(0.25)
	end
	task.wait(1)
	if not workspace:FindFirstChild("Map") then
		warn("HERMES_COMBAT_FAIL: место не загружено (нет Workspace.Map)")
		return
	end
	local yard, parts = yardParts()
	if not isCombatProject() and parts == 0 then
		print("HERMES_COMBAT_SKIP: это не проект боя (нет маркера Workspace.HermesCombat) — ничего не делаю")
		return
	end
	if parts > 0 and currentBuild() == BUILD_ID then
		print("HERMES_COMBAT_SKIP: двор и бой уже установлены")
		verify()
		return
	end
	if parts > 0 then
		local ok, err = pcall(installOnly)
		if not ok then
			warn("HERMES_COMBAT_FAIL: " .. tostring(err))
		end
		return
	end
	local ok, err = pcall(function()
		return run(false)
	end)
	if not ok then
		warn("HERMES_COMBAT_FAIL: " .. tostring(err))
	end
end)
"""


def indent(text: str, prefix: str = "\t") -> str:
    return "\n".join(prefix + line if line.strip() else line for line in text.splitlines())


def main() -> int:
    build = BUILD.read_text(encoding="utf-8")
    install = INSTALL.read_text(encoding="utf-8")
    source = HEADER + indent(build) + MIDDLE + indent(install) + FOOTER

    root = ET.Element("roblox", {
        "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
        "version": "4",
    })
    item = ET.SubElement(root, "Item", {"class": "Script", "referent": "RBX1"})
    props = ET.SubElement(item, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = "HermesCombatButton"
    ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = source
    ET.SubElement(props, "bool", {"name": "Disabled"}).text = "false"

    ET.ElementTree(root).write(TARGET, encoding="utf-8", xml_declaration=True)
    ET.parse(TARGET)
    print(f"plugin written: {TARGET} ({TARGET.stat().st_size} bytes, source {len(source)} chars)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
