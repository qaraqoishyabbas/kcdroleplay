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
	for _, item in yard:GetDescendants() do
		if item:IsA("BasePart") then
			local point = item:GetAttribute("CombatPoint")
			if point == "Weapon" then
				table.insert(World.weaponPoints, item)
			elseif point == "Shield" then
				World.shieldPoint = item
			elseif point == "Armor" then
				World.armorPoint = item
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
