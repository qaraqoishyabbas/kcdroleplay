-- Run in the Studio Command Bar after build-combat.luau and install-combat.luau.
-- Verifies the training yard, its interaction points and the installed combat scripts.
local count = 0
local function check(value, message)
	assert(value, message)
	count += 1
end

local map = assert(workspace:FindFirstChild("Map"), "Map missing")
local yard = assert(map:FindFirstChild("TrainingYard"), "TrainingYard missing: run build-combat.luau")
check(yard:GetAttribute("BuildComplete") == true, "Yard is not finished")
check(workspace:GetAttribute("HermesCombat") == true, "Project marker Workspace.HermesCombat is missing")

local weaponPoints, shieldPoints, armorPoints, vendorPoints, parts = 0, 0, 0, 0, 0
for _, item in yard:GetDescendants() do
	if item:IsA("BasePart") then
		parts += 1
		local point = item:GetAttribute("CombatPoint")
		if point == "Weapon" then
			weaponPoints += 1
			check(typeof(item:GetAttribute("WeaponId")) == "string", "Weapon point without WeaponId: " .. item.Name)
		elseif point == "Shield" then
			shieldPoints += 1
		elseif point == "Armor" then
			armorPoints += 1
		elseif point == "Vendor" then
			vendorPoints += 1
		end
	end
end
check(parts > 40, "Yard looks empty: " .. parts .. " parts")
check(weaponPoints == 4, "Expected four weapon points, found " .. weaponPoints)
check(shieldPoints == 1, "Expected one shield rack")
check(armorPoints == 1, "Expected one armor stand")
check(vendorPoints == 1, "Expected one weapon vendor")

local targets = yard:FindFirstChild("Targets")
check(targets ~= nil, "Targets folder missing")
check(#targets:GetChildren() == 3, "Expected three archery targets")

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

check(ServerScriptService:FindFirstChild("CombatBootstrap") ~= nil, "CombatBootstrap missing")
local folder = assert(ServerScriptService:FindFirstChild("Combat"), "Combat module folder missing")
for _, name in { "World", "Arsenal", "Stats", "Melee", "Arrows" } do
	local module = folder:FindFirstChild(name)
	check(module ~= nil and module:IsA("ModuleScript"), "Module missing: " .. name)
	check(#module.Source > 400, "Module looks empty: " .. name)
end
check(ReplicatedStorage:FindFirstChild("CombatConfig") ~= nil, "CombatConfig missing")
check(ReplicatedStorage:FindFirstChild("CombatNet") ~= nil, "CombatNet missing")
check(StarterPlayerScripts:FindFirstChild("CombatClient") ~= nil, "CombatClient missing")

local config = ReplicatedStorage:FindFirstChild("CombatConfig")
if config then
	check(config:GetAttribute("InstalledBuild") == 1, "Combat scripts are not the current build")
end

-- The yard must stand on solid ground and its racks must be reachable.
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { yard }
local ground = workspace:Raycast(Vector3.new(-1000, 60, -330), Vector3.new(0, -120, 0), params)
check(ground ~= nil, "No ground under the training yard")

local racks = workspace:Raycast(Vector3.new(-46, 60, -24), Vector3.new(0, -120, 0), params)
check(racks ~= nil and racks.Position.Y > -2, "Weapon racks float or sink")

for _, child in workspace:GetChildren() do
	if child:IsA("Model") and child.Name == "TrainingYard" and child ~= yard then
		error("Duplicate training yard")
	end
end

print("COMBAT_EDIT_PASS", count, "assertions;", parts, "parts")
