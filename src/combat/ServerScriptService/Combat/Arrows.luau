-- Bows: draw time sets damage and speed; the arrow is a real projectile with gravity.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Arrows = {}
local ctx = nil
local active = {}

function Arrows.init(context)
	ctx = context
	task.spawn(Arrows.loop)
end

function Arrows.drawStart(player)
	local now = workspace:GetServerTimeNow()
	local state = ctx.stats.get(player)
	if not ctx.stats.canAct(player, now) then
		return
	end
	local weapon = ctx.arsenal.weaponDefinition(state.weapon or "")
	if not weapon or weapon.Kind ~= "Bow" then
		return
	end
	ctx.stats.setBlocking(player, false)
	state.drawStarted = now
end

function Arrows.release(player, aim)
	local now = workspace:GetServerTimeNow()
	local state = ctx.stats.get(player)
	if not ctx.stats.canAct(player, now) then state.drawStarted = 0 return end
	if aim ~= nil then
		if typeof(aim) ~= "Vector3" then state.drawStarted = 0 return end
		for _, n in {aim.X,aim.Y,aim.Z} do
			if n ~= n or math.abs(n) > 1e6 then state.drawStarted = 0 return end
		end
	end
	local weapon = ctx.arsenal.weaponDefinition(state.weapon or "")
	if not weapon or weapon.Kind ~= "Bow" then
		return
	end
	local held = state.drawStarted > 0 and (now - state.drawStarted) or 0
	state.drawStarted = 0
	if held < weapon.DrawMin then
		ctx.net.Notice:FireClient(player, { text = "Лук не натянут", kind = "bad" })
		return
	end
	if now - state.lastAttack < ctx.config.Bow.MinInterval then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hand = character and (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"))
	if not root then
		return
	end
	if not ctx.stats.spend(player, ctx.config.Bow.StaminaCost) then
		ctx.net.Notice:FireClient(player, { text = "Не хватает сил на выстрел", kind = "bad" })
		return
	end
	state.lastAttack = now

	local power = math.clamp((held - weapon.DrawMin) / math.max(0.01, weapon.DrawMax - weapon.DrawMin), 0, 1)
	local damage = weapon.DamageMin + (weapon.DamageMax - weapon.DamageMin) * power
	local speed = weapon.SpeedMin + (weapon.SpeedMax - weapon.SpeedMin) * power

	local direction = root.CFrame.LookVector
	if typeof(aim) == "Vector3" and aim.Magnitude > 0.1 then
		direction = aim.Unit
	end
	if direction.Y > 0.92 then
		direction = (direction + Vector3.new(0, -0.45, 0)).Unit
	end

	local origin = (hand and hand.Position or root.Position + Vector3.new(0, 1, 0)) + direction * 1.4
	local arrow = Instance.new("Part")
	arrow.Name = "Arrow"
	arrow.Size = Vector3.new(0.12, 0.12, 1.9)
	arrow.CFrame = CFrame.lookAt(origin, origin + direction)
	arrow.Color = ctx.config.Grey.Dark
	arrow.Material = Enum.Material.Metal
	arrow.Anchored = false
	arrow.CanCollide = false
	arrow.CanTouch = false
	arrow.CanQuery = false
	arrow.Massless = false
	arrow.Parent = workspace
	if arrow.SetNetworkOwner then arrow:SetNetworkOwner(nil) end
	arrow.AssemblyLinearVelocity = direction * speed

	table.insert(active, {
		part = arrow,
		previousPosition = origin,
		owner = player,
		damage = damage,
		expire = now + ctx.config.Arrow.Lifetime,
	})
end

function Arrows.loop()
	while true do
		task.wait(ctx.config.Arrow.Step)
		local now = workspace:GetServerTimeNow()
		for index = #active, 1, -1 do
			local record = active[index]
			local arrow = record.part
			local dead = arrow == nil or arrow.Parent == nil or now > record.expire or arrow.Position.Y < -60
			if dead then
				if arrow then
					arrow:Destroy()
				end
				table.remove(active, index)
			else
				local from = record.previousPosition or arrow.Position
				local step = arrow.Position + arrow.AssemblyLinearVelocity * ctx.config.Arrow.Step - from
				record.previousPosition = arrow.Position
				if step.Magnitude > 0.05 then
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					local exclude = { arrow }
					local ownerCharacter = record.owner and record.owner.Character
					if ownerCharacter then
						table.insert(exclude, ownerCharacter)
					end
					params.FilterDescendantsInstances = exclude
					local hit = workspace:Raycast(from, step, params)
					if hit then
						local hitModel = hit.Instance and hit.Instance:FindFirstAncestorOfClass("Model")
						local target = hitModel and Players:GetPlayerFromCharacter(hitModel) or nil
						if target and target ~= record.owner then
							ctx.stats.damage(target, record.damage, record.owner, "стрела", 0.15)
						elseif record.owner and record.owner.Parent then
							local state = ctx.stats.get(record.owner)
							if now-state.lastTrainReward >= ctx.config.Gold.DummyCooldown then
								for _, training in ctx.world.trainingParts do
									if hit.Instance == training then
										state.lastTrainReward = now
										ctx.stats.addGold(record.owner, ctx.config.Gold.DummyReward, "мишень")
										break
									end
								end
							end
						end
						arrow.AssemblyLinearVelocity = Vector3.zero
						arrow.Anchored = true
						Debris:AddItem(arrow, ctx.config.Arrow.StickTime)
						table.remove(active, index)
					end
				end
			end
		end
	end
end

function Arrows.count()
	return #active
end

return Arrows
