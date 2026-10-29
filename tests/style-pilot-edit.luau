-- Run in the separate Crownlands-StylePilot-v01.rbxlx, in edit mode only.
assert(not game:GetService("RunService"):IsRunning(), "Style pilot test must not launch Play")
local root = assert(workspace:FindFirstChild("Crownlands_StylePilot_v01"), "Open the separate pilot place")
assert(root:GetAttribute("Style") == "A", "Wrong approved style")
assert(root:GetAttribute("ArtDirectionVersion") == "0.1", "Wrong art version")
assert(root:GetAttribute("ProductionTextures") == "Pending", "Do not label built-in previews as production maps")
assert(not workspace:FindFirstChild("Map"), "Pilot must be isolated from the game map")
local approved = {
	M01 = Enum.Material.Plaster, M02 = Enum.Material.Wood, M03 = Enum.Material.WoodPlanks,
	M04 = Enum.Material.Cobblestone, M05 = Enum.Material.ClayRoofTiles, M06 = Enum.Material.RoofShingles,
	M07 = Enum.Material.Leather, M08 = Enum.Material.Fabric, M09 = Enum.Material.Metal,
	M10 = Enum.Material.Ground, M11 = Enum.Material.Grass, M12 = Enum.Material.Grass,
}
local palette = {
	M01=0xCEC1A5, M02=0x554438, M03=0x8B7357, M04=0x848279,
	M05=0x8C5A43, M06=0x5C5A50, M07=0x795138, M08=0xB7AA88,
	M09=0x5B5E5C, M10=0x897454, M11=0x74805A, M12=0x4F6647,
}
local parts, scripts, collisions, materials = 0, 0, 0, {}
for _, o in root:GetDescendants() do
	if o:IsA("BaseScript") or o:IsA("ModuleScript") then scripts += 1 end
	if o:IsA("BasePart") then
		parts += 1
		local id = o:GetAttribute("DesignMaterial")
		assert(approved[id], "Unregistered material: " .. o:GetFullName())
		assert(o.Material == approved[id], "Material did not deserialize: " .. o:GetFullName())
		local hex = palette[id]
		if string.find(o.Name, "WindowRecess", 1, true) then hex = 0x343D35 end
		if o.Name == "M08_Head" or o.Name == "M08_Hand" then hex = 0xC8A481 end
		local target = Color3.fromRGB(bit32.extract(hex,16,8),bit32.extract(hex,8,8),bit32.extract(hex,0,8))
		assert((Vector3.new(o.Color.R,o.Color.G,o.Color.B)-Vector3.new(target.R,target.G,target.B)).Magnitude < 0.008,
			"Palette did not deserialize: " .. o:GetFullName())
		assert(o.Anchored and not o.CanTouch, "Unexpected physics activity")
		assert(o.Size.X > 0 and o.Size.Y > 0 and o.Size.Z > 0, "Invalid size")
		materials[id] = true
		if o.CanCollide then collisions += 1 end
	end
end
assert(parts == 318, "Unexpected part count: " .. parts)
assert(scripts == 0, "Reference scene must not add runtime scripts")
for id in approved do assert(materials[id], "Missing material " .. id) end
local references = {
	{"Cottage", Vector3.new(-29, 0, -1), 8},
	{"Townhouse", Vector3.new(3, 0, -15), 0},
	{"Workshop", Vector3.new(37, 0, -2), -8},
}
local gableCount = 0
for _, data in references do
	local m = assert(root:FindFirstChild(data[1]))
	assert(m.ModelStreamingMode == Enum.ModelStreamingMode.Atomic, "Buildings must stream together")
	local origin = CFrame.new(data[2]) * CFrame.Angles(0, math.rad(data[3]), 0)
	local half = tonumber(m:GetAttribute("Width")) / 2
	local wall = tonumber(m:GetAttribute("WallTop"))
	local rise = tonumber(m:GetAttribute("RoofRise"))
	local slopes, gables = 0, 0
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and string.find(p.Name, "RoofSlope_", 1, true) then
			slopes += 1
			assert(p.CFrame.UpVector.Y > 0.7, "Roof slope flipped")
			assert(math.abs(p.Size.Y - 0.32) < 0.001, "Roof thickness changed")
			-- Transform the upper inner corner of the UNDERside into building space.
			local rel = origin:PointToObjectSpace(p.Position)
			local side = rel.X < 0 and -1 or 1
			local ridge = origin:PointToObjectSpace(p.CFrame:PointToWorldSpace(Vector3.new(-side*p.Size.X/2,-p.Size.Y/2,0)))
			assert(math.abs(ridge.X) < 0.002, "Roof planes do not meet at the center")
			assert(math.abs(ridge.Y-(wall+rise+0.08)) < 0.002, "Roof ridge height mismatch")
		end
		if p:IsA("WedgePart") then
			gables += 1
			-- Canonical WedgePart's high edge is local +Z. It must be at the ridge.
			local high = origin:PointToObjectSpace(p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,p.Size.Z/2)))
			local low = origin:PointToObjectSpace(p.CFrame:PointToWorldSpace(Vector3.new(0,-p.Size.Y/2,-p.Size.Z/2)))
			assert(math.abs(high.X) < 0.002, "Gable points outward: old roof horn bug")
			assert(math.abs(high.Y-wall-rise) < 0.002, "Gable rises above the roof")
			assert(math.abs(math.abs(low.X)-half) < 0.002, "Gable base width mismatch")
		end
	end
	assert(slopes == 2 and gables == 4, "Each building needs two roof planes and four half-gables")
	local chimney = assert(m:FindFirstChild("M04_Chimney"))
	local center = origin:PointToObjectSpace(chimney.Position)
	local surface = wall+rise+0.08-math.abs(center.X)*math.tan(math.rad(43))
	assert(center.Y-chimney.Size.Y/2 < surface-0.5, "Chimney floats over roof")
	gableCount += gables
end
local npc = assert(root:FindFirstChild("Merchant_Reference"))
assert(#npc:GetChildren() >= 17, "Merchant silhouette missing")
assert(root:FindFirstChild("Oak_Reference"), "Oak missing")
assert(workspace.CurrentCamera, "Review camera missing")
assert(math.abs(game.Lighting.ClockTime-14) < 0.01, "Neutral review daylight not loaded")
print("STYLE_PILOT_EDIT_PASS " .. game:GetService("HttpService"):JSONEncode({
	parts=parts, runtimeScripts=scripts, collisionParts=collisions, buildings=3,
	closedHalfGables=gableCount, materialIds=12, playStarted=false,
	textureStage="BuiltinPreview", engine=version(),
}))
