local RS=game:GetService("ReplicatedStorage")
assert(RS:FindFirstChild("Shared") and RS:FindFirstChild("Remotes"),"Run the Crownlands installer first")
local services=script.Parent:WaitForChild("Services")
local state=require(services.PlayerStateService)
state.Start()
require(services.InventoryService).Start(state)
require(services.EconomyService).Start()
require(services.InteractionService).Start(state)
local combat=require(services.CombatService)
combat.Start(state)
local accumulated=0
local clock=0
local npcClock=0
local connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
    accumulated+=dt clock+=dt npcClock+=dt
    if accumulated>=.1 then state.Tick(math.min(accumulated,.3)) accumulated=0 end
    if npcClock>=.4 then combat.Tick(npcClock) npcClock=0 end
    if clock>=1 then
        game:GetService("Lighting").ClockTime=(game:GetService("Lighting").ClockTime+1/90)%24
        clock=0
    end
end)
game:BindToClose(function() connection:Disconnect() end)
print("CROWNLANDS_SERVER_READY",#game.Players:GetPlayers())
