-- Edit-mode Command Bar. Changes properties only; never removes map geometry.
-- Select "balanced", "low", or "restore". The first run preserves original values.
local PROFILE = "balanced"
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before optimizing")
assert(PROFILE == "balanced" or PROFILE == "low" or PROFILE == "restore", "Unknown profile")
local map = assert(workspace:FindFirstChild("Map"), "Map missing")
local lighting = game:GetService("Lighting")
local prefix = "MapPerfOriginal_"
local changed = 0

local function set(object, property, value)
	if object[property] == value then return end
	if object:GetAttribute(prefix .. property) == nil then
		object:SetAttribute(prefix .. property, object[property])
	end
	object[property] = value
	changed += 1
end
local function restore(object)
	for _, property in {"CastShadow", "CanTouch", "CanQuery", "GlobalShadows"} do
		local value = object:GetAttribute(prefix .. property)
		if value ~= nil then
			object[property] = value
			object:SetAttribute(prefix .. property, nil)
			changed += 1
		end
	end
end
local decorative = {
	Canopy=true, LeafCrown=true, Leaves=true, Moss=true, Stem=true,
	Petal=true, FlowerCenter=true, WornGravel=true, WindowBar=true,
	Root=true, Branch=true,
}
if PROFILE == "restore" then
	for _, item in map:GetDescendants() do restore(item) end
	restore(lighting)
	map:SetAttribute("PerformanceProfile", nil)
else
	for _, item in map:GetDescendants() do
		if item:IsA("BasePart") and item.Anchored then
			-- Prompts, targets, NPCs, scenery collision and placement are preserved.
			if decorative[item.Name] then
				set(item, "CastShadow", false)
				set(item, "CanTouch", false)
				if not item.CanCollide then set(item, "CanQuery", false) end
			end
		end
	end
	-- Switching low -> balanced also restores the original global shadow setting.
	if PROFILE == "low" then
		set(lighting, "GlobalShadows", false)
	else
		local original = lighting:GetAttribute(prefix .. "GlobalShadows")
		if original ~= nil then lighting.GlobalShadows = original end
	end
	map:SetAttribute("PerformanceProfile", PROFILE)
end
print("MAP_PERFORMANCE", PROFILE, changed, "property changes; geometry preserved")
