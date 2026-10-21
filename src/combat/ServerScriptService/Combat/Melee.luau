-- Melee: four attack directions, arc + line-of-sight hit test, server authoritative.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Melee = {}
local ctx = nil

function Melee.init(context)
	ctx = context
end

local function flatLook(root)
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.05 then
		return Vector3.new(0, 0, -1)
	end
	return flat.Unit
end

local function slashVisual(character, directionName, weapon)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local forward = flatLook(root)
	local centre = root.Position + Vector3.new(0, 1.4, 0) + forward * (weapon.Reach * 0.45)
	local size = Vector3.new(0.3, 2.2, weapon.Reach * 0.8)
	if directionName == "Stab" then
		size = Vector3.new(0.2, 0.2, weapon.Reach * 0.9)
	elseif directionName == "Overhead" then
		size = Vector3.new(1.6, 2.6, 0.4)
	end
	local part = Instance.new("Part")
	part.Name = "Slash"
	part.Size = size
	part.CFrame = CFrame.lookAt(centre, centre + forward)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(232, 234, 236)
	part.Transparency = 0.6
	part.Parent = workspace
	Debris:AddItem(part, 0.18)
end

function Melee.attack(player, directionName)
	local now = workspace:GetServerTimeNow()
	local state = ctx.stats.get(player)
	if not ctx.stats.canAct(player, now) then
		return
	end
	local weapon = ctx.arsenal.weaponDefinition(state.weapon or "")
	if not weapon or weapon.Kind ~= "Melee" then
		ctx.net.Notice:FireClient(player, { text = "Возьми оружие ближнего боя", kind = "bad" })
		return
	end
	if now - state.lastAttack < weapon.Cooldown then
		return
	end
	if not ctx.stats.spend(player, weapon.Stamina) then
		ctx.net.Notice:FireClient(player, { text = "Не хватает сил на удар", kind = "bad" })
		return
	end
	state.lastAttack = now
	local direction = ctx.config.Directions[directionName] or ctx.config.Directions.Right
	local character = player.Character
	slashVisual(character, directionName, weapon)
	task.delay(math.max(0.05, weapon.Windup + (direction.Windup or 0)), function()
		Melee.resolve(player, weapon, direction)
	end)
end

function Melee.resolve(player, weapon, direction)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local forward = flatLook(root)
	local arc = math.min(weapon.Arc, direction.Arc or weapon.Arc)
	local cosHalf = math.cos(math.rad(arc * 0.5))
	local hits = 0

	for _, other in Players:GetPlayers() do
		if other ~= player then
			local otherCharacter = other.Character
			local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local delta = otherRoot.Position - root.Position
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude > 0.1 and flat.Magnitude <= weapon.Reach and math.abs(delta.Y) <= 5 then
					if forward:Dot(flat.Unit) >= cosHalf then
						local params = RaycastParams.new()
						params.FilterType = Enum.RaycastFilterType.Exclude
						params.FilterDescendantsInstances = { character, otherCharacter }
						local wall = workspace:Raycast(root.Position + Vector3.new(0, 1.5, 0), flat.Unit * (flat.Magnitude - 1), params)
						if not wall then
							local falloff = 1 - math.clamp(flat.Magnitude / weapon.Reach, 0, 1) * 0.2
							ctx.stats.damage(other, weapon.Damage * (direction.Damage or 1) * falloff, player, weapon.Name, direction.ArmorPierce or 0)
							hits += 1
						end
					end
				end
			end
		end
		if hits >= 2 then
			break
		end
	end
end

return Melee
