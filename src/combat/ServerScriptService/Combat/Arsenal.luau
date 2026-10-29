-- Grey placeholder weapons, shields and armor welded straight onto the character.
-- No Tool instances: the server owns what a player holds, so the client cannot fake a weapon.
local Arsenal = {}
local ctx = nil

local function makePart(parent, name, size, cframe, color, material)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Color = color
	item.Material = material or ctx.config.Grey.Material
	item.Anchored = false
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.Massless = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function handOf(character, side)
	if not character then
		return nil
	end
	if side == "left" then
		return character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	end
	return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
end

function Arsenal.init(context)
	ctx = context
end

function Arsenal.weaponDefinition(weaponId)
	for _, weapon in ctx.config.Weapons do
		if weapon.Id == weaponId then
			return weapon
		end
	end
	return nil
end

local function weldTo(part, base, cframe)
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = base
	joint.Part1 = part
	joint.Parent = part
	part.CFrame = base.CFrame * cframe
	return joint
end

-- Builds the grey model of a weapon and welds it into the right hand.
local function mountModel(character, modelName, weaponId, side, grip)
	local hand = handOf(character, side)
	if not hand then
		return nil
	end
	local specs = ctx.config.WeaponModels[weaponId]
	if not specs then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = modelName
	local base = nil
	local frame = hand.CFrame * (grip or CFrame.Angles(math.rad(75), 0, 0))
	for index, spec in specs do
		local color = spec.Color == "Dark" and ctx.config.Grey.Dark or ctx.config.Grey.Color
		local item = makePart(model, spec.Name, spec.Size, frame * spec.Offset, color)
		if index == 1 then
			base = item
		end
	end
	if not base then
		model:Destroy()
		return nil
	end
	for _, item in model:GetChildren() do
		if item ~= base and item:IsA("BasePart") then
			local joint = Instance.new("WeldConstraint")
			joint.Part0 = base
			joint.Part1 = item
			joint.Parent = item
		end
	end
	model.Parent = character
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = hand
	joint.Part1 = base
	joint.Parent = base
	model.PrimaryPart = base
	return model
end

local GRIP = {
	Sword = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(70), 0, 0),
	Axe = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(70), 0, 0),
	Spear = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(80), 0, 0),
	Bow = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
	Shield = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
}

function Arsenal.setWeapon(player, weaponId)
	local state = ctx.stats.get(player)
	local character = player.Character
	if not character then
		return false
	end
	local definition = Arsenal.weaponDefinition(weaponId)
	if not definition or (definition.Kind ~= "Melee" and definition.Kind ~= "Bow") then
		return false
	end
	local model = mountModel(character, "Weapon_" .. weaponId, weaponId, "right", GRIP[weaponId])
	if not model then
		return false
	end
	Arsenal.clearWeapon(player, model)
	state.weapon = weaponId
	ctx.net.Hud:FireClient(player, ctx.stats.hudFor(player))
	return true
end

function Arsenal.clearWeapon(player, preserve)
	local state = ctx.stats.get(player)
	state.weapon = nil
	state.drawStarted = 0
	state.actionSerial += 1
	local character = player.Character
	if not character then
		return
	end
	for _, item in character:GetChildren() do
		if item ~= preserve and item:IsA("Model") and item.Name ~= "Weapon_Shield" and string.sub(item.Name, 1, 7) == "Weapon_" then
			item:Destroy()
		end
	end
end

function Arsenal.setShield(player, on)
	local state = ctx.stats.get(player)
	local character = player.Character
	if not character then
		return false
	end
	for _, item in character:GetChildren() do
		if item:IsA("Model") and item.Name == "Weapon_Shield" then
			item:Destroy()
		end
	end
	state.shield = false
	if not on then
		ctx.net.Hud:FireClient(player, ctx.stats.hudFor(player))
		return true
	end
	local model = mountModel(character, "Weapon_Shield", "Shield", "left", GRIP.Shield)
	if not model then
		return false
	end
	state.shield = true
	ctx.net.Hud:FireClient(player, ctx.stats.hudFor(player))
	return true
end

function Arsenal.wear(player, armorId)
	local state = ctx.stats.get(player)
	local character = player.Character
	if not character then
		return false
	end
	local definition = nil
	for _, piece in ctx.config.Armor do
		if piece.Id == armorId then
			definition = piece
		end
	end
	if not definition then
		return false
	end
	Arsenal.remove(player, armorId)
	local anchor = character:FindFirstChild(definition.Part)
	if not anchor then
		return false
	end
	local item = makePart(character, "Armor_" .. armorId, definition.Size, anchor.CFrame * definition.Offset, ctx.config.Grey.Color)
	weldTo(item, anchor, definition.Offset)
	state.armor[armorId] = true
	ctx.net.Hud:FireClient(player, ctx.stats.hudFor(player))
	return true
end

function Arsenal.remove(player, armorId)
	local state = ctx.stats.get(player)
	state.armor[armorId] = nil
	local character = player.Character
	if character then
		local item = character:FindFirstChild("Armor_" .. armorId)
		if item then
			item:Destroy()
		end
	end
	ctx.net.Hud:FireClient(player, ctx.stats.hudFor(player))
	return true
end

function Arsenal.wearAll(player)
	for _, piece in ctx.config.Armor do
		Arsenal.wear(player, piece.Id)
	end
end

function Arsenal.stripAll(player)
	for _, piece in ctx.config.Armor do
		Arsenal.remove(player, piece.Id)
	end
end

function Arsenal.armorLabel(player)
	local state = ctx.stats.get(player)
	local names = {}
	for _, piece in ctx.config.Armor do
		if state.armor[piece.Id] then
			table.insert(names, piece.Name)
		end
	end
	if #names == 0 then
		return "нет"
	end
	return table.concat(names, ", ")
end

function Arsenal.reduction(player)
	local state = ctx.stats.get(player)
	local multiplier = 1
	for _, piece in ctx.config.Armor do
		if state.armor[piece.Id] then
			multiplier = multiplier * (1 - piece.Reduction)
		end
	end
	return math.min(ctx.config.ArmorCap, 1 - multiplier)
end

function Arsenal.reapply(player)
	task.spawn(function()
		local character = player.Character
		if not character then
			return
		end
		-- Hands appear a moment after CharacterAdded; wait for them before welding.
		character:WaitForChild("RightHand", 5)
		character:WaitForChild("LeftHand", 5)
		local state = ctx.stats.get(player)
		if state.weapon then
			local weaponId = state.weapon
			state.weapon = nil
			Arsenal.setWeapon(player, weaponId)
		end
		if state.shield then
			state.shield = false
			Arsenal.setShield(player, true)
		end
		for _, piece in ctx.config.Armor do
			if state.armor[piece.Id] then
				state.armor[piece.Id] = nil
				Arsenal.wear(player, piece.Id)
			end
		end
	end)
end

function Arsenal.clearAll(player)
	local state = ctx.stats.get(player)
	state.weapon = nil
	state.shield = false
	table.clear(state.armor)
	local character = player.Character
	if character then
		for _, item in character:GetChildren() do
			if item:IsA("Model") and string.sub(item.Name, 1, 7) == "Weapon_" then
				item:Destroy()
			elseif item:IsA("BasePart") and string.sub(item.Name, 1, 6) == "Armor_" then
				item:Destroy()
			end
		end
	end
end

-- Grey display models on the racks: anchored copies, no collision, no queries.
function Arsenal.spawnDisplay(anchor, weaponId)
	local specs = ctx.config.WeaponModels[weaponId]
	if not specs then
		return
	end
	for _, spec in specs do
		local color = spec.Color == "Dark" and ctx.config.Grey.Dark or ctx.config.Grey.Color
		local item = Instance.new("Part")
		item.Name = "Display_" .. spec.Name
		item.Size = spec.Size
		item.CFrame = anchor.CFrame * CFrame.new(0, 1.2, 0) * spec.Offset
		item.Color = color
		item.Material = ctx.config.Grey.Material
		item.Anchored = true
		item.CanCollide = false
		item.CanQuery = false
		item.CanTouch = false
		item.Parent = anchor
	end
end

function Arsenal.spawnArmorDisplay(anchor)
	local heights = { Helmet = 4.6, Cuirass = 3.0, Greaves = 1.6 }
	for _, piece in ctx.config.Armor do
		local item = Instance.new("Part")
		item.Name = "Display_" .. piece.Id
		item.Size = piece.Size
		item.CFrame = anchor.CFrame * CFrame.new(0, heights[piece.Id] or 2, 0) * piece.Offset
		item.Color = ctx.config.Grey.Color
		item.Material = ctx.config.Grey.Material
		item.Anchored = true
		item.CanCollide = false
		item.CanQuery = false
		item.CanTouch = false
		item.Parent = anchor
	end
end

return Arsenal
