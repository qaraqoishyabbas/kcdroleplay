local players=game.Players:GetPlayers()
assert(#players==2,"Expected two connected clients")
local a,b=players[1],players[2]
local state=require(game.ServerScriptService.Services.PlayerStateService)
local combat=require(game.ServerScriptService.Services.CombatService)
local inv=require(game.ServerScriptService.Services.InventoryService)
for _,player in players do
    local pd=state.Get(player)
    inv.Change(player,{},{TrainingSword=1},0) combat.Equip(player)
    local char=player.Character char.HumanoidRootPart:SetNetworkOwner(nil)
    local ff=char:FindFirstChildOfClass("ForceField") if ff then ff:Destroy() end
    pd.BusyUntil=0 pd.Block=false pd.Stamina=100
end
local ar,br=a.Character.HumanoidRootPart,b.Character.HumanoidRootPart
local ah,bh=a.Character.Humanoid,b.Character.Humanoid
local startB=bh.Health
a.Character:PivotTo(CFrame.lookAt(Vector3.new(20,4,38),Vector3.new(20,4,33)))
b.Character:PivotTo(CFrame.lookAt(Vector3.new(20,4,33),Vector3.new(20,4,38)))
assert(not combat.ValidTarget(a.Character,b.Character,7),"Safe-zone PvP accepted")
combat.Buckets[a]=nil combat.Handle(a,"Light") task.wait(.4)
assert(bh.Health==startB,"Safe-zone player took damage")
task.wait(.5)
a.Character:PivotTo(CFrame.lookAt(Vector3.new(300,4,50),Vector3.new(300,4,45)))
b.Character:PivotTo(CFrame.lookAt(Vector3.new(300,4,45),Vector3.new(300,4,50)))
state.Get(a).BusyUntil=0 combat.Buckets[a]=nil
combat.Handle(a,"Light") task.wait(.4)
assert(bh.Health==startB-12,"Legal wilderness PvP failed")
a.Character:PivotTo(CFrame.new(0,4,38)) b.Character:PivotTo(CFrame.new(6,4,38))
print("CROWN_TWO_PLAYER_SERVER_PASS",#players,bh.Health)
local received={}
local report=game.ReplicatedStorage.CrownTestReport
local connection=report.OnServerEvent:Connect(function(player,passed,message,effects)
    received[player]={Passed=passed,Message=message,Effects=effects}
end)
report:FireAllClients()
local deadline=os.clock()+15
repeat task.wait(.2) until (received[a] and received[b]) or os.clock()>deadline
connection:Disconnect()
for _,player in players do
    local result=assert(received[player],"Client report timed out: "..player.Name)
    assert(result.Passed,result.Message)
    print("CROWN_TWO_PLAYER_CLIENT_PASS",player.Name,result.Effects)
end
