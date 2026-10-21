assert(not game:GetService("RunService"):IsRunning())
local report=game.ReplicatedStorage:FindFirstChild("CrownTestReport") or Instance.new("RemoteEvent",game.ReplicatedStorage) report.Name="CrownTestReport"
do local parent=game.ServerScriptService; local old=parent:FindFirstChild("CrownMultiplayerAcceptance"); if old then old:Destroy() end; local obj=Instance.new("Script"); obj.Name="CrownMultiplayerAcceptance"; obj.Source=[====[local test=game:GetService("StudioTestService")
local ok,args=pcall(function() return test:GetTestArgs() end)
if not ok or type(args)~="table" or args.Mode~="CrownAcceptance" then return end
local passed,result=xpcall(function()
local timeout=os.clock()+40
repeat task.wait(.2) until (#game.Players:GetPlayers()==2 and game.Players:GetPlayers()[1]:GetAttribute("Started") and game.Players:GetPlayers()[2]:GetAttribute("Started")) or os.clock()>timeout
assert(#game.Players:GetPlayers()==2,"Clients failed to connect")
task.wait(4)
-- Install as a temporary Script in ServerScriptService during Play, after pressing Play in the game menu.
-- Requires a fresh session; changes only that test session.
local state=require(game.ServerScriptService.Services.PlayerStateService)
local combat=require(game.ServerScriptService.Services.CombatService)
local p=game.Players:GetPlayers()[1]
assert(p and p:GetAttribute("Started"),"Press the in-game Play button first")
local d=assert(state.Get(p),"No server profile")
local c=p.Character local h=c.Humanoid local r=c.HumanoidRootPart
local checks=0
local function check(ok,message) assert(ok,message) checks+=1 end
check(d.Gold==15 and d.Items.Bread==2 and d.Items.GatheringTool==1,"Starter profile incorrect")
state.Buckets[p]=nil state.Handle(p,"Play",2)
check(d.Gold==15 and d.Items.Bread==2,"Duplicate Play changed starter inventory")
state.Handle(p,{},math.huge) combat.Handle(p,{})
check(d.Stamina>=0 and d.Stamina<=100,"Malformed payload mutated stamina")
c:PivotTo(CFrame.new(35,4,45)) r:SetNetworkOwner(nil)
d.Stamina=100 d.Sprint=true d.LastSpend=os.clock()
h:MoveTo(Vector3.new(55,4,45))
task.wait(.7)
check(d.Stamina<99 and h.WalkSpeed==22,"Server sprint did not drain stamina")
d.Sprint=false h:MoveTo(r.Position)
local spent=d.Stamina task.wait(2)
check(d.Stamina>spent and h.WalkSpeed==14,"Stamina or walk speed did not recover")
print("CROWN_SPRINT_RECOVERY_PASS",d.Stamina)
local interactions=require(game.ServerScriptService.Services.InteractionService)
local rack=workspace.InteractionPoints.Crownlands:FindFirstChild("Стойка учебного оружия")
c:PivotTo(CFrame.new(rack.Position+Vector3.new(0,1,4)))
interactions.Buckets[p]=nil interactions.Handle(rack.ProximityPrompt,p)
check(d.Items.TrainingSword==1,"Training item not granted")
interactions.Buckets[p]=nil interactions.Handle(rack.ProximityPrompt,p)
check(d.Items.TrainingSword==1,"Training pickup duplicated weapon")
check(c:FindFirstChild("CrownSword") and c:FindFirstChild("CrownShield"),"Equipment models missing")
local npc=workspace.NPCs:FindFirstChild("Учебный противник")
local nr=npc.HumanoidRootPart local nh=npc.Humanoid
c:PivotTo(CFrame.lookAt(nr.Position+Vector3.new(0,0,5),nr.Position))
h:MoveTo(r.Position) d.Stamina=100 d.BusyUntil=0 combat.Buckets[p]=nil
local before=nh.Health combat.Handle(p,"Light")
check(d.Stamina==88,"Light stamina cost incorrect")
combat.Handle(p,"Light")
task.wait(.35)
check(nh.Health==before-12,"Light hit/cooldown failed")
combat.Handle(p,"Light") task.wait(.1)
check(nh.Health==before-12,"Cooldown bypass caused duplicate damage")
task.wait(.45)
d.Stamina=100 combat.Buckets[p]=nil combat.Handle(p,"Heavy")
task.wait(.6)
check(nh.Health==before-34,"Heavy damage failed")
print("CROWN_COMBAT_DAMAGE_PASS",nh.Health)
task.wait(.9)
c:PivotTo(CFrame.lookAt(nr.Position+Vector3.new(0,0,18),nr.Position))
d.BusyUntil=0 combat.Buckets[p]=nil combat.Handle(p,"Light") task.wait(.35)
check(nh.Health==before-34,"Out-of-range attack dealt damage")
task.wait(.5)
d.BusyUntil=0 combat.Buckets[p]=nil combat.Handle(p,"Block")
check(d.Block and p:GetAttribute("Blocking"),"Block did not start")
combat.Handle(p,"Unblock")
check(not d.Block and not p:GetAttribute("Blocking"),"Rapid block release was dropped")
state.Buckets[p]=nil state.Handle(p,"Sprint",true) state.Handle(p,"Sprint",false)
check(not d.Sprint,"Rapid sprint release was dropped")
task.wait(.1)
d.BusyUntil=0 d.Stamina=100 combat.Buckets[p]=nil
local dodgeStart=r.Position combat.Handle(p,"Dodge")
check((r.Position-dodgeStart).Magnitude>3 and d.Stamina==78,"Dodge cost/movement failed")
check(d.DodgeUntil>os.clock(),"Dodge invulnerability missing")
print("CROWN_BLOCK_DODGE_PASS")
-- Kill the training opponent and verify its timed replacement.
nh.Health=0
task.wait(12.6)
local fresh=workspace.NPCs:FindFirstChild("Учебный противник")
check(fresh and fresh~=npc and fresh.Humanoid.Health==80,"Opponent failed to respawn")
local old=c h.Health=0
local deadline=os.clock()+12
repeat task.wait(.2) until (p.Character and p.Character~=old) or os.clock()>deadline
local nextCharacter=p.Character
check(nextCharacter and nextCharacter~=old,"Player failed to respawn")
local nextRoot=nextCharacter:WaitForChild("HumanoidRootPart",5)
task.wait(1.4)
check(nextRoot and not nextRoot.Anchored and (nextRoot.Position-Vector3.new(0,3,38)).Magnitude<8,"Respawn location/movement incorrect")
check(nextCharacter:FindFirstChild("CrownSword") and nextCharacter:FindFirstChild("CrownShield"),"Equipment missing after respawn")
check(d.Gold==15 and d.Items.Bread==2,"Death duplicated starter inventory")
print("CROWN_PLAY_SERVER_TESTS_PASS",checks)


-- Temporary server Script during Play, after tests/play-server.luau completes.
local state=require(game.ServerScriptService.Services.PlayerStateService)
local inv=require(game.ServerScriptService.Services.InventoryService)
local economy=require(game.ServerScriptService.Services.EconomyService)
local interactions=require(game.ServerScriptService.Services.InteractionService)
local p=game.Players:GetPlayers()[1] local d=assert(state.Get(p))
local c=p.Character local h=c.Humanoid local r=c.HumanoidRootPart
local checks=0
local function check(ok,message) assert(ok,message) checks+=1 end
local function trigger(prompt)
    interactions.Buckets[p]=nil
    interactions.Handle(prompt,p)
end
local points=workspace.InteractionPoints.Crownlands
local initial=d.Gold
local merchant=points:FindFirstChild("Торговец Мирек")
economy.Buckets[p]=nil economy.Handle(p,"Buy","Bread",1)
check(d.Gold==initial,"Distant purchase accepted")
local resource
for _,v in points:GetDescendants() do if v:IsA("ProximityPrompt") and v:GetAttribute("Resource")=="Wood" then resource=v break end end
trigger(resource)
check(not d.Items.Wood,"Distant gathering accepted")
for _,v in points:GetDescendants() do
    if v:IsA("ProximityPrompt") and (v:GetAttribute("Resource")=="Wood" or v:GetAttribute("Resource")=="Ore") then
        c:PivotTo(CFrame.new(v.Parent.Position+Vector3.new(0,1,4)))
        trigger(v)
        local id=v:GetAttribute("Resource") local count=d.Items[id]
        trigger(v)
        check(d.Items[id]==count,"Resource cooldown bypassed")
    end
end
check(d.Items.Wood==3 and d.Items.Ore==2,"Resource collection failed")
local smith=points:FindFirstChild("Кузнец Радек")
c:PivotTo(CFrame.new(smith.Position+Vector3.new(0,1,4)))
trigger(smith.ProximityPrompt)
check(d.IntroQuestDone and d.Gold==initial+12 and d.Items.Wood==0 and d.Items.Ore==0,"Quest exchange failed")
trigger(smith.ProximityPrompt)
check(d.Gold==initial+12,"Quest reward duplicated")
c:PivotTo(CFrame.new(merchant.Position+Vector3.new(0,1,4)))
local gold=d.Gold local bread=d.Items.Bread
economy.Buckets[p]=nil economy.Handle(p,"Buy","Bread",1)
check(d.Gold==gold-4 and d.Items.Bread==bread+1,"NPC purchase failed")
economy.Buckets[p]=nil economy.Handle(p,"Sell","Bread",1)
check(d.Gold==gold-3 and d.Items.Bread==bread,"NPC sale failed")
gold=d.Gold
for _,n in {0,-1,.5,math.huge,0/0,100} do economy.Buckets[p]=nil economy.Handle(p,"Buy","Bread",n) end
economy.Handle(p,"Buy",{},1)
check(d.Gold==gold and d.Items.Bread==bread,"Malformed trade changed inventory")
economy.Buckets[p]=nil economy.Handle(p,"Buy","TrainingSword",99)
check(d.Gold==gold,"Insufficient-funds purchase charged money")
local ok=inv.Change(p,{Bread=100},{Wood=1},0)
check(not ok and d.Items.Bread==bread,"Partial transaction removed items")
ok=inv.Change(p,{},{Ore=100},0)
check(not ok and (d.Items.Ore or 0)==0,"Hard weight limit bypassed")
h.Health=50 inv.Buckets[p]=nil inv.Handle(p,"Use","Bread")
check(h.Health==75 and d.Items.Bread==bread-1,"Food use failed")
h.Health=h.MaxHealth inv.Buckets[p]=nil inv.Handle(p,"Use","Bread")
check(d.Items.Bread==bread-1,"Food consumed at full health")
-- Restore starter bread for readable UI and verify equipment sale removes the model.
inv.Change(p,{},{Bread=1},0)
economy.Buckets[p]=nil economy.Handle(p,"Sell","TrainingSword",1)
check(not d.Equipped and not c:FindFirstChild("CrownSword") and not c:FindFirstChild("CrownShield"),"Sold weapon stayed equipped")
local rack=points:FindFirstChild("Стойка учебного оружия")
c:PivotTo(CFrame.new(rack.Position+Vector3.new(0,1,4))) trigger(rack.ProximityPrompt)
check((d.Items.TrainingSword or 0)==0,"Training rack can be farmed for gold")
c:PivotTo(CFrame.new(0,4,38))
print("CROWN_ECONOMY_TESTS_PASS",checks,"Gold",d.Gold)


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

return "CROWN_MULTIPLAYER_ALL_PASS"
end,debug.traceback)
print("CROWN_MULTIPLAYER_RESULT",passed,result)
test:EndTest({Passed=passed,Result=result})
]====]; obj.Parent=parent end
do local parent=game.StarterPlayer.StarterPlayerScripts; local old=parent:FindFirstChild("CrownMultiplayerClient"); if old then old:Destroy() end; local obj=Instance.new("LocalScript"); obj.Name="CrownMultiplayerClient"; obj.Source=[====[local test=game:GetService("StudioTestService")
local ok,args=pcall(function() return test:GetTestArgs() end)
if not ok or type(args)~="table" or args.Mode~="CrownAcceptance" then return end
local p=game.Players.LocalPlayer
local rs=game.ReplicatedStorage
local report=rs:WaitForChild("CrownTestReport",30)
assert(report,"Test report remote missing")
local effects=0
rs.Remotes.CombatRemote.OnClientEvent:Connect(function() effects+=1 end)
report.OnClientEvent:Connect(function()
    task.wait(3)
    local okCheck,message=pcall(function()
        assert(p.PlayerGui.HUD.Enabled and not p.PlayerGui.MainMenu.Enabled,"HUD/menu wrong")
        assert(#game.Players:GetPlayers()==2,"Client does not see both players")
        for _,other in game.Players:GetPlayers() do
            local c=assert(other.Character,"Other character missing")
            assert(c:FindFirstChild("CrownSword") and c:FindFirstChild("CrownShield"),"Other equipment missing")
        end
        assert(effects>0,"Combat effects did not replicate")
    end)
    report:FireServer(okCheck,tostring(message),effects)
end)
local deadline=os.clock()+30
repeat
    if p.PlayerGui:FindFirstChild("HUD") and p.PlayerGui.HUD:FindFirstChild("Stats") and p.Character then
        rs.Remotes.InteractionRemote:FireServer("Play",2)
    end
    task.wait(.5)
until p:GetAttribute("Started") or os.clock()>deadline
assert(p:GetAttribute("Started"),"Multiplayer client could not enter game")
]====]; obj.Parent=parent end
task.spawn(function()
local result=game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2,{Mode="CrownAcceptance"})
print("CROWN_MULTIPLAYER_RETURN",game:GetService("HttpService"):JSONEncode(result))
end)
