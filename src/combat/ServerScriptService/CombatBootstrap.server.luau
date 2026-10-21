-- Server entry point for medieval combat. Requires the training yard from build-combat.luau.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Net = require(ReplicatedStorage:WaitForChild("CombatNet"))

local folder = ServerScriptService:WaitForChild("Combat")
local World = require(folder.World)
local Arsenal = require(folder.Arsenal)
local Stats = require(folder.Stats)
local Melee = require(folder.Melee)
local Arrows = require(folder.Arrows)

local net = Net.server()
World.init(Config)

local ctx = {
	config = Config,
	net = net,
	world = World,
	arsenal = Arsenal,
	stats = Stats,
	melee = Melee,
	arrows = Arrows,
}

Arsenal.init(ctx)
Stats.init(ctx)
Melee.init(ctx)
Arrows.init(ctx)
World.attach(ctx)

Players.RespawnTime = Config.Player.RespawnTime

local function onCharacter(player, character)
	Stats.reset(player)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.MaxHealth = Config.Player.MaxHealth
		humanoid.Health = humanoid.MaxHealth
		humanoid.WalkSpeed = Config.Movement.Walk
	end
	Arsenal.reapply(player)
	net.Hud:FireClient(player, Stats.hudFor(player))
end

local function onPlayer(player)
	Stats.get(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end

net.Attack.OnServerEvent:Connect(function(player, direction)
	if type(direction) ~= "string" then
		return
	end
	Melee.attack(player, direction)
end)

net.Block.OnServerEvent:Connect(function(player, on)
	Stats.setBlocking(player, on == true)
end)

net.DrawStart.OnServerEvent:Connect(function(player)
	Arrows.drawStart(player)
end)

net.Release.OnServerEvent:Connect(function(player, aim)
	if aim ~= nil and typeof(aim) ~= "Vector3" then
		return
	end
	Arrows.release(player, aim)
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		Stats.broadcast()
	end
end)

print("COMBAT_READY", Config.Version)
