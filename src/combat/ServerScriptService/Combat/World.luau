-- Finds the training yard built by build-combat.luau and wires its interaction points.
local World = {}

function World.init(config)
	local map = workspace:FindFirstChild("Map")
	assert(map, "Map missing: run build-map.luau first")
	local yard = map:FindFirstChild(config.ModelName)
	assert(yard, "TrainingYard missing: run build-combat.luau")
	World.yard = yard
	World.weaponPoints = {}
	World.shieldPoint = nil
	World.armorPoint = nil
	World.vendorPoint = nil
	World.trainingParts = {}
	for _, item in yard:GetDescendants() do
		if item:IsA("BasePart") then
			local point = item:GetAttribute("CombatPoint")
			if point == "Weapon" then
				table.insert(World.weaponPoints, item)
			elseif point == "Shield" then
				World.shieldPoint = item
			elseif point == "Armor" then
				World.armorPoint = item
			elseif point == "Vendor" then
				World.vendorPoint = item
			end
			local parentName = item.Parent and item.Parent.Name or ""
			if string.sub(parentName, 1, 6) == "Target" or string.sub(parentName, 1, 5) == "Dummy" or parentName == "Targets" then
				table.insert(World.trainingParts, item)
			end
		end
	end
	return World
end

local function makePrompt(part, action, object, distance)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = distance or 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

function World.attach(ctx)
	World.prompts = {}

	local function makeVendor(point)
		local base = point.Position
		local function piece(name, size, offset, color, shape)
			local item = Instance.new("Part")
			item.Name = name
			item.Size = size
			item.CFrame = CFrame.new(base + offset)
			item.Color = color
			item.Material = Enum.Material.SmoothPlastic
			item.Anchored = true
			item.CanCollide = false
			item.CanQuery = false
			item.CanTouch = false
			item.Parent = point
			if shape then
				item.Shape = shape
			end
			return item
		end
		piece("Torso", Vector3.new(2.2, 2.4, 1.2), Vector3.new(0, 2.6, 0), Color3.fromRGB(74, 62, 48))
		piece("Head", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 4.5, 0), Color3.fromRGB(212, 180, 148), Enum.PartType.Ball)
		piece("Hood", Vector3.new(1.9, 0.6, 1.9), Vector3.new(0, 5.1, 0), Color3.fromRGB(58, 48, 38))
		local board = Instance.new("BillboardGui")
		board.Size = UDim2.fromOffset(200, 40)
		board.StudsOffset = Vector3.new(0, 3.4, 0)
		board.AlwaysOnTop = true
		board.Parent = point
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(240, 224, 186)
		label.Text = "ОРУЖЕЙНИК"
		label.Parent = board
	end

	if World.vendorPoint then
		makeVendor(World.vendorPoint)
		local prompt = makePrompt(World.vendorPoint, "Торговать", "Оружейник", 12)
		prompt.Triggered:Connect(function(player)
			ctx.shop.open(player)
		end)
		table.insert(World.prompts, prompt)
	end

	for _, part in World.weaponPoints do
		local weaponId = part:GetAttribute("WeaponId")
		local definition = ctx.arsenal.weaponDefinition(weaponId)
		if definition then
			ctx.arsenal.spawnDisplay(part, weaponId)
			local prompt = makePrompt(part, "Взять", definition.Name)
			prompt.Triggered:Connect(function(player)
				if ctx.arsenal.setWeapon(player, weaponId) then
					ctx.net.Notice:FireClient(player, { text = "Взяла: " .. definition.Name, kind = "good" })
				end
			end)
			table.insert(World.prompts, prompt)
		end
	end

	if World.shieldPoint then
		ctx.arsenal.spawnDisplay(World.shieldPoint, "Shield")
		local prompt = makePrompt(World.shieldPoint, "Взять щит", "Стойка со щитами")
		prompt.Triggered:Connect(function(player)
			local state = ctx.stats.get(player)
			local had = state.shield
			ctx.arsenal.setShield(player, not had)
			ctx.net.Notice:FireClient(player, { text = had and "Щит убран" or "Щит взят", kind = "good" })
		end)
		table.insert(World.prompts, prompt)
	end

	if World.armorPoint then
		ctx.arsenal.spawnArmorDisplay(World.armorPoint)
		local prompt = makePrompt(World.armorPoint, "Надеть броню", "Стойка с бронёй")
		prompt.Triggered:Connect(function(player)
			local state = ctx.stats.get(player)
			local wearing = false
			for _, piece in ctx.config.Armor do
				if state.armor[piece.Id] then
					wearing = true
					break
				end
			end
			if wearing then
				ctx.arsenal.stripAll(player)
				ctx.net.Notice:FireClient(player, { text = "Броня снята", kind = "info" })
			else
				ctx.arsenal.wearAll(player)
				ctx.net.Notice:FireClient(player, { text = "Броня надета", kind = "good" })
			end
		end)
		table.insert(World.prompts, prompt)
	end
end

return World
