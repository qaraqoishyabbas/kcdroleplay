-- Edit-time builder: training yard with weapon racks, armor stand and archery targets.
-- Run in the Studio Command Bar with Play stopped, after build-map.luau.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play first")

local W = workspace
local map = assert(W:FindFirstChild("Map"), "Map missing: run build-map.luau first")
local terrain = W.Terrain

local ORIGIN = Vector3.new(-1000, 0, -330)
local X0, X1 = -60, 60
local Z0, Z1 = -40, 40

local wood = Color3.fromRGB(104, 80, 54)
local dirt = Color3.fromRGB(126, 110, 80)
local stone = Color3.fromRGB(150, 144, 126)
local cloth = Color3.fromRGB(176, 168, 148)

local previous = map:FindFirstChild("TrainingYard")
if previous then
	previous:Destroy()
end

local yard = Instance.new("Model")
yard.Name = "TrainingYard"
local structure = Instance.new("Folder") structure.Name = "Structure" structure.Parent = yard
local props = Instance.new("Folder") props.Name = "Props" props.Parent = yard
local targets = Instance.new("Folder") targets.Name = "Targets" targets.Parent = yard

local function part(parent, name, size, cframe, color, material, shape)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Color = color
	item.Material = material or Enum.Material.WoodPlanks
	item.Anchored = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	if shape then
		item.Shape = shape
	end
	return item
end

local function at(localPosition, angle)
	return CFrame.new(ORIGIN + localPosition) * CFrame.Angles(0, angle or 0, 0)
end

local function marker(name, localPosition, attributes)
	local item = part(props, name, Vector3.one, at(localPosition), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	item.Transparency = 1
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	if attributes then
		for key, value in attributes do
			item:SetAttribute(key, value)
		end
	end
	return item
end

-- Ground: flatten the plot, lay a trampled dirt pad.
terrain:FillBlock(CFrame.new(ORIGIN + Vector3.new(0, 18, 0)), Vector3.new(X1 - X0 + 30, 36, Z1 - Z0 + 30), Enum.Material.Air)
terrain:FillBlock(CFrame.new(ORIGIN + Vector3.new(0, -5, 0)), Vector3.new(X1 - X0 + 30, 10, Z1 - Z0 + 30), Enum.Material.Ground)
local pad = part(structure, "Ground", Vector3.new(X1 - X0 + 8, 0.6, Z1 - Z0 + 8), at(Vector3.new(0, 0.3, 0)), dirt, Enum.Material.Ground)
yard.PrimaryPart = pad

-- Fence with an opening on the north side (towards Crownford).
local function fenceRun(name, fromLocal, toLocal)
	local delta = toLocal - fromLocal
	local length = delta.Magnitude
	local middle = ORIGIN + (fromLocal + toLocal) / 2
	local cframe = CFrame.lookAt(middle + Vector3.new(0, 3, 0), middle + Vector3.new(delta.X, 3, delta.Z))
	part(structure, name .. "_Rail", Vector3.new(0.4, 0.8, length), cframe, wood)
	local count = math.max(1, math.floor(length / 8))
	for index = 0, count do
		local point = fromLocal:Lerp(toLocal, index / count)
		part(structure, name .. "_Post", Vector3.new(0.6, 6, 0.6), at(point + Vector3.new(0, 3, 0)), wood)
	end
end

fenceRun("FenceWest", Vector3.new(X0, 0, Z0), Vector3.new(X0, 0, Z1))
fenceRun("FenceEast", Vector3.new(X1, 0, Z0), Vector3.new(X1, 0, Z1))
fenceRun("FenceSouth", Vector3.new(X0, 0, Z1), Vector3.new(X1, 0, Z1))
fenceRun("FenceNorthLeft", Vector3.new(X0, 0, Z0), Vector3.new(-12, 0, Z0))
fenceRun("FenceNorthRight", Vector3.new(12, 0, Z0), Vector3.new(X1, 0, Z0))

-- Weapon racks: two posts and a bar; the grey weapon models are added at runtime.
local rackSpots = {
	{ z = -24, weapon = "Sword" },
	{ z = -16, weapon = "Axe" },
	{ z = 4, weapon = "Spear" },
	{ z = 12, weapon = "Bow" },
}
for index, spot in rackSpots do
	local postZ = spot.z - 3
	part(props, "RackPost", Vector3.new(0.8, 6, 0.8), at(Vector3.new(-52, 3, postZ)), wood)
	part(props, "RackPost", Vector3.new(0.8, 6, 0.8), at(Vector3.new(-52, 3, postZ + 6)), wood)
	part(props, "RackBar", Vector3.new(0.6, 0.6, 7), at(Vector3.new(-52, 5.4, postZ + 3)), wood)
	marker("WeaponPoint_" .. index, Vector3.new(-50, 3.4, spot.z), { CombatPoint = "Weapon", WeaponId = spot.weapon })
end

-- Shield rack
part(props, "ShieldPost", Vector3.new(0.8, 6, 0.8), at(Vector3.new(-52, 3, 18)), wood)
part(props, "ShieldBar", Vector3.new(0.6, 0.6, 5), at(Vector3.new(-52, 5.2, 20)), wood)
marker("ShieldPoint", Vector3.new(-50, 3.2, 20), { CombatPoint = "Shield" })

-- Armor stand
part(props, "ArmorPost", Vector3.new(0.7, 7, 0.7), at(Vector3.new(-52, 3.5, 30)), wood)
part(props, "ArmorCross", Vector3.new(0.5, 0.5, 4), at(Vector3.new(-52, 5.6, 30)), wood)
marker("ArmorPoint", Vector3.new(-50, 3, 30), { CombatPoint = "Armor" })

-- Archery targets on the east side: post plus a board with rings.
for index, z in { -26, 0, 26 } do
	local targetFolder = Instance.new("Folder")
	targetFolder.Name = "Target_" .. index
	targetFolder.Parent = targets
	part(targetFolder, "Post", Vector3.new(0.7, 6, 0.7), at(Vector3.new(48, 3, z)), wood)
	local board = part(targetFolder, "Board", Vector3.new(0.5, 7, 7), at(Vector3.new(47.6, 6, z)), cloth, Enum.Material.Fabric)
	board.Shape = Enum.PartType.Cylinder
	board.CFrame = at(Vector3.new(47.6, 6, z)) * CFrame.Angles(0, 0, math.pi / 2)
	for ring = 1, 3 do
		local ringPart = part(targetFolder, "Ring", Vector3.new(0.2, 7 - ring * 1.6, 7 - ring * 1.6), at(Vector3.new(47.2, 6, z)), ring % 2 == 0 and Color3.fromRGB(196, 186, 160) or Color3.fromRGB(140, 60, 52), Enum.Material.Fabric)
		ringPart.Shape = Enum.PartType.Cylinder
		ringPart.CFrame = at(Vector3.new(47.2, 6, z)) * CFrame.Angles(0, 0, math.pi / 2)
		ringPart.CanCollide = false
	end
end

-- Shooting line
local line = part(structure, "ShootingLine", Vector3.new(1, 0.1, 40), at(Vector3.new(20, 0.65, 0)), Color3.fromRGB(226, 222, 208), Enum.Material.SmoothPlastic)
line.CanCollide = false

-- Training dummies
for index, spot in { { x = 0, z = -20 }, { x = 2, z = 14 } } do
	local dummy = Instance.new("Folder")
	dummy.Name = "Dummy_" .. index
	dummy.Parent = props
	part(dummy, "Post", Vector3.new(1, 6, 1), at(Vector3.new(spot.x, 3, spot.z)), wood)
	part(dummy, "Crossbar", Vector3.new(6, 0.6, 0.6), at(Vector3.new(spot.x, 4.6, spot.z)), wood)
	local head = part(dummy, "Head", Vector3.new(1.6, 1.6, 1.6), at(Vector3.new(spot.x, 6.4, spot.z)), stone, Enum.Material.SmoothPlastic)
	head.Shape = Enum.PartType.Ball
end

-- Vendor stall right next to the Crownford south gate spawn (200 studs west of the yard itself).
local stallAt = Vector3.new(-196, 0, -6)
part(props, "VendorCounter", Vector3.new(9, 3, 3), at(stallAt + Vector3.new(0, 1.5, 0)), wood)
part(props, "VendorCanopy", Vector3.new(11, 0.4, 6), at(stallAt + Vector3.new(0, 5.4, 0)), cloth, Enum.Material.Fabric)
for _, side in { -1, 1 } do
	part(props, "VendorPost", Vector3.new(0.5, 5.5, 0.5), at(stallAt + Vector3.new(side * 5, 2.75, 2.6)), wood)
end
marker("VendorPoint", stallAt + Vector3.new(0, 1, 2), { CombatPoint = "Vendor" })

-- Signpost at the spawn: where the training yard is.
local post = part(props, "YardSignPost", Vector3.new(0.6, 7, 0.6), at(Vector3.new(-188, 3.5, 8)), wood)
local board = part(props, "YardSign", Vector3.new(12, 2.4, 0.4), at(Vector3.new(-188, 7, 8)), wood)
for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.PixelsPerStud = 16
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "ДВОР →"
	label.TextScaled = true
	label.Font = Enum.Font.Garamond
	label.TextColor3 = Color3.fromRGB(238, 224, 190)
	label.Parent = gui
end

local sign = part(structure, "Sign", Vector3.new(22, 3.5, 0.5), at(Vector3.new(0, 8.5, Z0 - 1)), wood)
for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.PixelsPerStud = 18
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "ТРЕНИРОВОЧНЫЙ ДВОР"
	label.TextScaled = true
	label.Font = Enum.Font.Garamond
	label.TextColor3 = Color3.fromRGB(238, 224, 190)
	label.Parent = gui
end

yard:SetAttribute("Origin", ORIGIN)
yard:SetAttribute("BuildComplete", true)
yard:SetAttribute("Kind", "TrainingYard")
yard.Parent = map

-- Project marker: the combat plugin only touches places with this attribute.
W:SetAttribute("HermesCombat", true)

local partCount = 0
for _, item in yard:GetDescendants() do
	if item:IsA("BasePart") then
		partCount += 1
	end
end
print("COMBAT_YARD_OK", partCount, "parts", "origin", tostring(ORIGIN))
