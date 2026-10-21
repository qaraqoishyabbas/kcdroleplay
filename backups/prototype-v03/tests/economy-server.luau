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
script:Destroy()
