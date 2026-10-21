-- Per-player combat state: stamina, blocking, stagger, equipment, damage application.
local Players = game:GetService("Players")

local Stats = {}
local ctx = nil
local states = {}

function Stats.init(context)
	ctx = context
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(Stats.loop)
end

function Stats.get(player)
	local state = states[player]
	if not state then
		state = {
			stamina = ctx.config.Stamina.Max,
			blocking = false,
			staggeredUntil = 0,
			lastAttack = 0,
			lastStaminaUse = 0,
			drawStarted = 0,
			weapon = nil,
			shield = false,
			armor = {},
		}
		states[player] = state
	end
	return state
end

function Stats.all()
	return states
end

function Stats.reset(player)
	local state = Stats.get(player)
	state.stamina = ctx.config.Stamina.Max
	state.blocking = false
	state.staggeredUntil = 0
	state.lastAttack = 0
	state.drawStarted = 0
end

function Stats.canAct(player, now)
	local state = Stats.get(player)
	return now >= state.staggeredUntil
end

function Stats.setStagger(player, seconds, now)
	local state = Stats.get(player)
	local until_ = (now or workspace:GetServerTimeNow()) + seconds
	if until_ > state.staggeredUntil then
		state.staggeredUntil = until_
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 8
	end
	task.delay(seconds, function()
		local current = states[player]
		if current and (current.staggeredUntil <= workspace:GetServerTimeNow()) then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = ctx.config.Movement.Walk
			end
		end
	end)
end

function Stats.spend(player, amount)
	local state = Stats.get(player)
	local now = workspace:GetServerTimeNow()
	if state.stamina < amount then
		return false
	end
	state.stamina = state.stamina - amount
	state.lastStaminaUse = now
	return true
end

function Stats.setBlocking(player, on)
	local state = Stats.get(player)
	state.blocking = on and true or false
	local now = workspace:GetServerTimeNow()
	if now < state.staggeredUntil then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local baseSpeed = ctx.config.Movement.Walk
		if state.blocking then
			humanoid.WalkSpeed = baseSpeed * ctx.config.Block.MoveMultiplier
		else
			humanoid.WalkSpeed = baseSpeed
		end
	end
end

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") or nil
end

function Stats.damage(target, amount, attacker, kind, armorPierce)
	if not target or not target.Parent then
		return 0
	end
	local targetCharacter = target.Character
	local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return 0
	end
	local state = Stats.get(target)
	local now = workspace:GetServerTimeNow()

	if state.blocking then
		local targetRoot = rootOf(target)
		local attackerRoot = attacker and rootOf(attacker)
		local blocked = false
		if targetRoot and attackerRoot then
			local delta = attackerRoot.Position - targetRoot.Position
			local flat = Vector3.new(delta.X, 0, delta.Z)
			local look = targetRoot.CFrame.LookVector
			local forward = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.1 and forward.Magnitude > 0.1 then
				local arc = state.shield and ctx.config.Block.ShieldArc or ctx.config.Block.Arc
				blocked = forward.Unit:Dot(flat.Unit) >= math.cos(math.rad(arc * 0.5))
			end
		end
		if blocked then
			local cost = state.shield and ctx.config.Block.ShieldStaminaPerHit or ctx.config.Block.StaminaPerHit
			if Stats.spend(target, cost) then
				ctx.net.Notice:FireClient(target, { text = "Блок", kind = "good" })
				if attacker then
					ctx.net.Notice:FireClient(attacker, { text = "Удар в блок", kind = "bad" })
				end
				return 0
			end
			Stats.setStagger(target, ctx.config.Stamina.GuardBreak, now)
			ctx.net.Notice:FireClient(target, { text = "Блок пробит: нет сил", kind = "bad" })
		end
	end

	local reduction = ctx.arsenal.reduction(target)
	if armorPierce and armorPierce > 0 then
		reduction = reduction * (1 - armorPierce)
	end
	local final = math.max(1, math.floor(amount * (1 - reduction) + 0.5))
	humanoid:TakeDamage(final)

	ctx.net.Notice:FireClient(target, { text = "Ты получил " .. final .. " (" .. (kind or "удар") .. ")", kind = "bad" })
	if attacker and attacker ~= target then
		ctx.net.Notice:FireClient(attacker, { text = "Ты нанёс " .. final, kind = "good" })
	end
	if humanoid.Health <= 0 then
		Stats.reset(target)
	end
	return final
end

function Stats.loop()
	while true do
		task.wait(0.2)
		local now = workspace:GetServerTimeNow()
		for player, state in states do
			if player.Parent then
				if now - state.lastStaminaUse > ctx.config.Stamina.RegenDelay then
					state.stamina = math.min(ctx.config.Stamina.Max, state.stamina + ctx.config.Stamina.Regen * 0.2)
				end
				if state.blocking and state.stamina <= 0 then
					state.blocking = false
					Stats.setStagger(player, 0.8, now)
					ctx.net.Notice:FireClient(player, { text = "Ты выдохлась — блок снят", kind = "bad" })
				end
			end
		end
	end
end

function Stats.hudFor(player)
	local state = Stats.get(player)
	local weaponName = "кулаки"
	local weaponKind = "None"
	if state.weapon then
		for _, weapon in ctx.config.Weapons do
			if weapon.Id == state.weapon then
				weaponName = weapon.Name
				weaponKind = weapon.Kind
			end
		end
	end
	return {
		stamina = math.floor(state.stamina + 0.5),
		staminaMax = ctx.config.Stamina.Max,
		weapon = weaponName,
		weaponKind = weaponKind,
		shield = state.shield,
		armor = ctx.arsenal.armorLabel(player),
		blocking = state.blocking,
	}
end

function Stats.broadcast()
	for player in states do
		if player.Parent then
			ctx.net.Hud:FireClient(player, Stats.hudFor(player))
		end
	end
end

return Stats
