assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local editor=game:GetService("ScriptEditorService")
local function ensure(parent,name,class)
local o=parent:FindFirstChild(name)
if o then assert(o.ClassName==class,"Class mismatch: "..o:GetFullName()) return o end
local n=Instance.new(class) n.Name=name n.Parent=parent return n end
local rs=game:GetService("ReplicatedStorage")
ensure(rs,"Shared","Folder")
local remotes=ensure(rs,"Remotes","Folder")
for _,n in {"InteractionRemote","UIUpdateRemote","CombatRemote","InventoryRemote","TradeRemote"} do ensure(remotes,n,"RemoteEvent") end
local ss=game:GetService("ServerStorage")
for _,n in {"NPCModels","ItemModels","WeaponModels","WorldTemplates"} do ensure(ss,n,"Folder") end
for _,name in {"MainMenu","HUD","DialogueUI","InventoryUI","TradeUI"} do
local gui=ensure(game:GetService("StarterGui"),name,"ScreenGui")
gui.ResetOnSpawn=false gui.IgnoreGuiInset=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=name=="MainMenu" and 40 or (name=="DialogueUI" and 35 or (name=="HUD" and 10 or 30))
end
do local parent=game:GetService("ReplicatedStorage")
parent=ensure(parent,"Shared","Folder")
local obj=ensure(parent,"Config","ModuleScript")
local source=[[return table.freeze({
    Title = "CROWNLANDS", Subtitle = "MEDIEVAL LIFE", Version = "0.3.0 • FOUNDATION / COMBAT / ITEMS",
    WalkSpeed = 14, SprintSpeed = 22, MaxStamina = 100,
    SprintDrain = 18, StaminaRegen = 13, RegenDelay = 1.2,
    InteractionDistance = 13, Spawn = Vector3.new(0, 5, 38),
    SafeCenter = Vector3.new(0,0,0), SafeRadius = 105,
    Presets = {
        {Name = "Лён и кожа", Color = Color3.fromRGB(126, 105, 73)},
        {Name = "Лесной путник", Color = Color3.fromRGB(77, 91, 59)},
        {Name = "Серый холст", Color = Color3.fromRGB(99, 103, 105)},
    },
    Tutorial = {
        "Добро пожаловать в Crownlands. Двигайтесь WASD или стиком. Осмотрите деревню.",
        "Shift / кнопка «Бег» — бег. Следите за выносливостью; отпустите кнопку для восстановления.",
        "Подойдите к колодцу и удерживайте E / кнопку взаимодействия. Вода восстанавливает здоровье.",
        "Загляните в таверну и на рынок. Для боя возьмите учебное оружие у тренировочной площадки.",
    },
})
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("ReplicatedStorage")
parent=ensure(parent,"Shared","Folder")
local obj=ensure(parent,"ItemDefinitions","ModuleScript")
local source=[[return table.freeze({
    Bread={Name="Хлеб",Category="Еда",Icon="◒",Description="Восстанавливает 25 здоровья. Нельзя использовать при полном здоровье.",Weight=.3,Buy=4,Sell=1,Heal=25},
    GatheringTool={Name="Инструмент собирателя",Category="Инструменты",Icon="⚒",Description="Простой инструмент для сбора древесины, руды и угля.",Weight=1.5,Buy=10,Sell=4},
    TrainingSword={Name="Учебный меч и щит",Category="Оружие",Icon="⚔",Description="Лёгкое учебное оружие. Удар 12, тяжёлый 22; дальность 7 studs.",Weight=5,Buy=30,Sell=12},
    PeasantClothes={Name="Крестьянская одежда",Category="Броня",Icon="♙",Description="Простая ткань. Защиты не даёт, одежда применяется автоматически.",Weight=1,Buy=8,Sell=2},
    Wood={Name="Древесина",Category="Сырьё",Icon="♣",Description="Собирается в лесу. Нужна для изготовления учебного оружия.",Weight=1,Buy=5,Sell=2},
    Ore={Name="Железная руда",Category="Сырьё",Icon="◆",Description="Переплавляется в кузнице с углём.",Weight=2,Buy=7,Sell=3},
    Coal={Name="Уголь",Category="Сырьё",Icon="●",Description="Топливо для кузницы.",Weight=1,Buy=5,Sell=2},
    IronBar={Name="Железный слиток",Category="Сырьё",Icon="▬",Description="Материал для оружия и ремонта.",Weight=2,Buy=16,Sell=8},
    Wheat={Name="Пшеница",Category="Сырьё",Icon="♧",Description="Урожай можно продать или обменять на хлеб у очага.",Weight=.5,Buy=4,Sell=2},
})
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("ReplicatedStorage")
parent=ensure(parent,"Shared","Folder")
local obj=ensure(parent,"UtilityModules","ModuleScript")
local source=[[local U = {}
function U.alive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health > 0 then return c,h,r end
end
function U.finite(n)
    return type(n)=="number" and n==n and math.abs(n)<1e9
end
function U.safePosition(pos)
    return (Vector3.new(pos.X,0,pos.Z)-Vector3.zero).Magnitude <= 105
end
function U.allow(buckets, player, key, interval)
    local now = os.clock()
    local p = buckets[player]
    if not p then p={} buckets[player]=p end
    if now-(p[key] or -math.huge)<interval then return false end
    p[key]=now
    return true
end
function U.near(player, part, distance)
    local _,_,root=U.alive(player)
    return root and part and part:IsA("BasePart") and (root.Position-part.Position).Magnitude <= distance
end
return U
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("ReplicatedStorage")
parent=ensure(parent,"Shared","Folder")
local obj=ensure(parent,"WeaponDefinitions","ModuleScript")
local source=[[return table.freeze({
    TrainingSword={Name="Учебный меч", Damage=12, HeavyDamage=22, Reach=7, Cooldown=.7, HeavyCooldown=1.4, Stamina=12, HeavyStamina=26, Weight=3, Windup=.18, HeavyWindup=.48},
})
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("ServerScriptService")
local obj=ensure(parent,"Bootstrap","Script")
obj.Enabled=false
local source=[[local RS=game:GetService("ReplicatedStorage")
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
]]
editor:UpdateSourceAsync(obj,function() return source end)
obj.Enabled=true
end
do local parent=game:GetService("ServerScriptService")
parent=ensure(parent,"Services","Folder")
local obj=ensure(parent,"CombatService","ModuleScript")
local source=[[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local U=require(RS.Shared.UtilityModules)
local Weapons=require(RS.Shared.WeaponDefinitions)
local S={Buckets={}, NPCs={}, State=nil}
local FX=RS.Remotes.CombatRemote
local function root(model) return model:FindFirstChild("HumanoidRootPart") end
local function validTarget(attacker,target,reach)
    local ar,tr=root(attacker),root(target)
    local th=target:FindFirstChildOfClass("Humanoid")
    if not ar or not tr or not th or th.Health<=0 or attacker==target then return false end
    local delta=tr.Position-ar.Position
    if delta.Magnitude>reach or delta.Magnitude<.1 or ar.CFrame.LookVector:Dot(delta.Unit)<.3 then return false end
    local ap,tp=Players:GetPlayerFromCharacter(attacker),Players:GetPlayerFromCharacter(target)
    if ap and tp and (U.safePosition(ar.Position) or U.safePosition(tr.Position)) then return false end
    local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={attacker}
    local result=workspace:Raycast(ar.Position,delta,params)
    return not result or result.Instance:IsDescendantOf(target)
end
S.ValidTarget=validTarget
local function weldPart(name,size,cf,color,material,parent,hand)
    local p=Instance.new("Part") p.Name=name p.Size=size p.Color=color p.Material=material
    p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.CFrame=cf p.Parent=parent
    local w=Instance.new("WeldConstraint") w.Part0=hand w.Part1=p w.Parent=p
    return p
end
function S.Equip(p)
    local d=S.State.Get(p)
    local c=U.alive(p)
    if not d or not d.Started or not c then return end
    if (d.Items.TrainingSword or 0)<1 then return end
    d.Equipped="TrainingSword"
    if c:FindFirstChild("CrownSword") then return end
    local hand=c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm")
    local left=c:FindFirstChild("LeftHand") or c:FindFirstChild("Left Arm")
    if not hand or not left then return end
    local sword=Instance.new("Model") sword.Name="CrownSword" sword.Parent=c
    weldPart("Grip",Vector3.new(.32,1.1,.32),hand.CFrame*CFrame.new(0,-.7,0),Color3.fromRGB(86,56,32),Enum.Material.Wood,sword,hand)
    weldPart("Guard",Vector3.new(1.4,.2,.35),hand.CFrame*CFrame.new(0,-1.25,0),Color3.fromRGB(125,122,111),Enum.Material.Metal,sword,hand)
    weldPart("Blade",Vector3.new(.46,3.4,.18),hand.CFrame*CFrame.new(0,-3,0),Color3.fromRGB(165,171,171),Enum.Material.Metal,sword,hand)
    local shield=Instance.new("Model") shield.Name="CrownShield" shield.Parent=c
    weldPart("Shield",Vector3.new(2.1,2.7,.35),left.CFrame*CFrame.new(0,-.1,-.55),Color3.fromRGB(87,61,39),Enum.Material.WoodPlanks,shield,left)
    weldPart("Boss",Vector3.new(.75,.75,.3),left.CFrame*CFrame.new(0,-.1,-.85),Color3.fromRGB(134,136,129),Enum.Material.Metal,shield,left)
    S.State.Snapshot(p) S.State.Notify(p,"Учебный меч и щит: ЛКМ — удар, R — тяжёлый, F — блок / парирование, Q — уклонение.")
end
local function damage(attacker,target,amount)
    local targetPlayer=Players:GetPlayerFromCharacter(target)
    local d=targetPlayer and S.State.Get(targetPlayer)
    local now=os.clock()
    if d and now<(d.DodgeUntil or 0) then return end
    if d and d.Block and root(target).CFrame.LookVector:Dot((root(attacker).Position-root(target).Position).Unit)>.2 then
        local cost=now-d.BlockSince<=.25 and 4 or 12
        if d.Stamina>=cost then
            d.Stamina-=cost d.LastSpend=now
            FX:FireAllClients(now-d.BlockSince<=.25 and "Parry" or "Block",target)
            if now-d.BlockSince<=.25 then
                local a=Players:GetPlayerFromCharacter(attacker)
                local ad=a and S.State.Get(a)
                if ad then ad.StunnedUntil=now+1 end
            end
            return
        else d.Block=false targetPlayer:SetAttribute("Blocking",false) FX:FireAllClients("BlockEnd",target) end
    end
    local h=target:FindFirstChildOfClass("Humanoid")
    local before=h.Health
    h:TakeDamage(amount)
    FX:FireAllClients("Hit",target)
    if before>0 and h.Health<=0 then FX:FireAllClients("Death",target) end
end
function S.Handle(p,action)
    if type(action)~="string" then return end
    local d=S.State.Get(p)
    local c,h,r=U.alive(p)
    if not d or not d.Started or not c then return end
    local now=os.clock()
    if action=="Unblock" then
        if d.Block then d.Block=false p:SetAttribute("Blocking",false) FX:FireAllClients("BlockEnd",c) end
        return
    end
    if not U.allow(S.Buckets,p,"Network",.06) then return end
    if not d.Equipped or now<d.StunnedUntil or now<d.BusyUntil then return end
    local weapon=Weapons[d.Equipped]
    if not weapon then return end
    if action=="Block" then
        if d.Block or d.Stamina<5 then return end
        d.Block=true d.Sprint=false d.BlockSince=now
        p:SetAttribute("Blocking",true) FX:FireAllClients("BlockStart",c)
    elseif action=="Dodge" then
        if d.Block or d.Stamina<22 then return end
        d.Stamina-=22 d.LastSpend=now d.BusyUntil=now+.7 d.DodgeUntil=now+.22
        local velocity=r.AssemblyLinearVelocity
        local horizontal=Vector3.new(velocity.X,0,velocity.Z)
        local delta=horizontal.Magnitude>1 and horizontal.Unit*6 or -r.CFrame.LookVector*6
        local params=RaycastParams.new() params.FilterDescendantsInstances={c} params.FilterType=Enum.RaycastFilterType.Exclude
        local hit=workspace:Raycast(r.Position,delta,params)
        if hit then delta=delta.Unit*math.max(0,hit.Distance-2) end
        c:PivotTo(c:GetPivot()+delta)
        FX:FireAllClients("Dodge",c)
    elseif action=="Light" or action=="Heavy" then
        if d.Block then return end
        local heavy=action=="Heavy"
        local cost=heavy and weapon.HeavyStamina or weapon.Stamina
        if d.Stamina<cost then return end
        d.Stamina-=cost d.LastSpend=now d.Sprint=false
        d.BusyUntil=now+(heavy and weapon.HeavyCooldown or weapon.Cooldown)
        FX:FireAllClients(action,c)
        task.delay(heavy and weapon.HeavyWindup or weapon.Windup,function()
            if not p.Parent or p.Character~=c or h.Health<=0 or d.Equipped~="TrainingSword" or os.clock()<d.StunnedUntil then return end
            local targets={}
            for _,v in workspace.NPCs:GetChildren() do if v:GetAttribute("Hostile") then table.insert(targets,v) end end
            for _,v in Players:GetPlayers() do if v~=p and v.Character then table.insert(targets,v.Character) end end
            table.sort(targets,function(a,b) return (root(a) and (root(a).Position-r.Position).Magnitude or math.huge)<(root(b) and (root(b).Position-r.Position).Magnitude or math.huge) end)
            for _,target in targets do
                if validTarget(c,target,weapon.Reach) then damage(c,target,heavy and weapon.HeavyDamage or weapon.Damage) break end
            end
        end)
    end
end
function S.RegisterNPC(model)
    local h=model:FindFirstChildOfClass("Humanoid")
    local r=root(model)
    if not h or not r then return end
    local template=model:Clone()
    S.NPCs[model]={Home=model:GetPivot(),Attack=0,Template=template}
    h.Died:Connect(function()
        local record=S.NPCs[model]
        S.NPCs[model]=nil
        task.delay(12,function()
            if model.Parent then model:Destroy() end
            local fresh=template:Clone() fresh.Parent=workspace.NPCs fresh:PivotTo(record.Home)
            local nr=root(fresh) if nr and not nr.Anchored then nr:SetNetworkOwner(nil) end
            S.RegisterNPC(fresh) template:Destroy()
        end)
    end)
end
function S.Tick()
    local now=os.clock()
    for model,d in S.NPCs do
        local h=model:FindFirstChildOfClass("Humanoid") local r=root(model)
        if not model.Parent or not h or h.Health<=0 or not r then continue end
        if model:GetAttribute("TrainingDummy") then continue end
        local nearest,dist=nil,45
        for p,pd in S.State.Profiles do
            local c,_,pr=U.alive(p)
            if c and pd.Started and not U.safePosition(pr.Position) then
                local range=(pr.Position-r.Position).Magnitude
                if range<dist and (pr.Position-d.Home.Position).Magnitude<60 then nearest=c dist=range end
            end
        end
        if nearest then
            h:MoveTo(root(nearest).Position)
            if dist<6 and now-d.Attack>1.8 and validTarget(model,nearest,6) then
                d.Attack=now FX:FireAllClients("Light",model)
                task.delay(.3,function()
                    if model.Parent and h.Health>0 and nearest.Parent and validTarget(model,nearest,6) then damage(model,nearest,9) end
                end)
            end
        elseif (r.Position-d.Home.Position).Magnitude>4 then h:MoveTo(d.Home.Position) end
    end
end
function S.Start(state)
    S.State=state
    FX.OnServerEvent:Connect(S.Handle)
    local function onPlayer(p)
        p.CharacterAdded:Connect(function(c)
            task.delay(1,function()
                local d=state.Get(p)
                if p.Character==c and d and d.Equipped then S.Equip(p) end
            end)
        end)
    end
    Players.PlayerAdded:Connect(onPlayer)
    Players.PlayerRemoving:Connect(function(p) S.Buckets[p]=nil end)
    for _,p in Players:GetPlayers() do onPlayer(p) end
    for _,npc in workspace.NPCs:GetChildren() do
        if npc:GetAttribute("Hostile") then
            local r=root(npc) if r and not r.Anchored then r:SetNetworkOwner(nil) end
            S.RegisterNPC(npc)
        end
    end
end
return S
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("ServerScriptService")
parent=ensure(parent,"Services","Folder")
local obj=ensure(parent,"EconomyService","ModuleScript")
local source=[[local RS=game:GetService("ReplicatedStorage")
local U=require(RS.Shared.UtilityModules)
local Defs=require(RS.Shared.ItemDefinitions)
local Inventory=require(script.Parent.InventoryService)
local S={Buckets={}}
function S.Handle(p,action,id,count)
    if (action~="Buy" and action~="Sell") or type(id)~="string" or not Defs[id] then return end
    if not U.finite(count) or count%1~=0 or count<1 or count>99 then return end
    if not U.allow(S.Buckets,p,"Trade",.2) then return end
    local point=workspace.InteractionPoints.Crownlands:FindFirstChild("Торговец Мирек")
    if not U.near(p,point,13) then return end
    local def=Defs[id]
    local ok,message
    if action=="Buy" then ok,message=Inventory.Change(p,{},{[id]=count},-def.Buy*count)
    else ok,message=Inventory.Change(p,{[id]=count},{},def.Sell*count) end
    Inventory.State.Notify(p,ok and (action=="Buy" and "Покупка завершена." or "Продажа завершена.") or message)
end
function S.Start()
    RS.Remotes.TradeRemote.OnServerEvent:Connect(S.Handle)
    game.Players.PlayerRemoving:Connect(function(p) S.Buckets[p]=nil end)
end
return S
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("ServerScriptService")
parent=ensure(parent,"Services","Folder")
local obj=ensure(parent,"InteractionService","ModuleScript")
local source=[[local RS=game:GetService("ReplicatedStorage")
local U=require(RS.Shared.UtilityModules)
local Config=require(RS.Shared.Config)
local S={Buckets={},Nodes={},State=nil}
function S.Handle(prompt,p)
    local state=S.State
    local d=state.Get(p)
    local target=prompt.Parent
    if not d or not d.Started or not prompt:IsDescendantOf(workspace.InteractionPoints) then return end
    if not U.allow(S.Buckets,p,"Prompt",1) or not U.near(p,target,Config.InteractionDistance) then return end
    local action=prompt:GetAttribute("Action")
    local _,h=U.alive(p)
    if action=="Water" or action=="Rest" then
        h.Health=math.min(h.MaxHealth,h.Health+30)
        d.Stamina=100 p:SetAttribute("Stamina",100)
        state.Notify(p,action=="Water" and "Прохладная вода: +30 здоровья, выносливость восстановлена." or "Вы отдохнули у очага: +30 здоровья, выносливость восстановлена.")
    elseif action=="Board" then
        state.Notify(p,"Первый заказ: соберите 3 древесины и 2 руды у лесной тропы и принесите кузнецу. Награда — 12 Gold.")
    elseif action=="Training" then
        local combat=require(script.Parent.CombatService)
        if not d.ClaimedTraining then
            local ok=require(script.Parent.InventoryService).Change(p,{},{TrainingSword=1},0)
            if not ok then state.Notify(p,"Освободите место для учебного оружия.") return end
            d.ClaimedTraining=true
        end
        combat.Equip(p)
    elseif action=="Gather" then
        local resource=prompt:GetAttribute("Resource")
        if resource~="Wood" and resource~="Ore" and resource~="Coal" then return end
        if (d.Items.GatheringTool or 0)<1 then state.Notify(p,"Нужен инструмент собирателя.") return end
        if os.clock()-(S.Nodes[prompt] or -math.huge)<12 then state.Notify(p,"Здесь пока нечего собирать. Подождите немного.") return end
        local ok,message=require(script.Parent.InventoryService).Change(p,{},{[resource]=1},0)
        if ok then S.Nodes[prompt]=os.clock() end
        state.Notify(p,ok and "Материал собран. Заказ кузнеца: 3 древесины, 2 руды." or message)
    elseif action=="SmithQuest" then
        if d.IntroQuestDone then state.Notify(p,"Спасибо за помощь! Этот заказ уже оплачен.") return end
        local ok,message=require(script.Parent.InventoryService).Change(p,{Wood=3,Ore=2},{},12)
        if ok then d.IntroQuestDone=true state.Snapshot(p) end
        state.Notify(p,ok and "Заказ выполнен: +12 Gold. Следующий шаг — торговец на площади." or ("Кузнецу нужны 3 древесины и 2 руды. "..message))
    elseif action=="Merchant" then
        RS.Remotes.UIUpdateRemote:FireClient(p,"Trade",{Name=prompt.ObjectText})
    elseif action=="Talk" then
        RS.Remotes.UIUpdateRemote:FireClient(p,"Dialogue",{Name=prompt.ObjectText,Text=prompt:GetAttribute("Dialogue")})
    end
end
function S.Start(state)
    S.State=state
    game:GetService("Players").PlayerRemoving:Connect(function(p) S.Buckets[p]=nil end)
    game:GetService("ProximityPromptService").PromptTriggered:Connect(S.Handle)
end
return S
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("ServerScriptService")
parent=ensure(parent,"Services","Folder")
local obj=ensure(parent,"InventoryService","ModuleScript")
local source=[[local RS=game:GetService("ReplicatedStorage")
local Defs=require(RS.Shared.ItemDefinitions)
local U=require(RS.Shared.UtilityModules)
local S={State=nil,Buckets={},MaxWeight=30}
function S.Weight(items)
    local total=0 for id,n in items do local def=Defs[id] if def then total+=def.Weight*n end end
    return total
end
-- Non-yielding transaction: validate the entire new inventory and balance before committing.
function S.Change(p,inputs,outputs,gold)
    local d=S.State.Get(p)
    if not d or not d.Started then return false,"Персонаж ещё не готов." end
    local nextItems=table.clone(d.Items)
    for id,n in inputs do
        if not Defs[id] or not U.finite(n) or n<0 or n%1~=0 or (nextItems[id] or 0)<n then return false,"Не хватает материалов." end
        nextItems[id]=(nextItems[id] or 0)-n
    end
    for id,n in outputs do
        if not Defs[id] or not U.finite(n) or n<0 or n%1~=0 then return false,"Некорректный предмет." end
        nextItems[id]=(nextItems[id] or 0)+n
    end
    if not U.finite(gold) or gold%1~=0 or d.Gold+gold<0 or d.Gold+gold>10000000 then return false,"Недостаточно Gold." end
    if S.Weight(nextItems)>45 then return false,"Слишком тяжело: предел 45 кг. Продайте или используйте часть вещей." end
    d.Items=nextItems d.Gold+=gold
    if d.Equipped and (d.Items[d.Equipped] or 0)==0 then S.Unequip(p) end
    S.State.Snapshot(p)
    return true
end
function S.Unequip(p)
    local d=S.State.Get(p) if not d then return end
    d.Equipped=nil d.Block=false p:SetAttribute("Blocking",false)
    RS.Remotes.CombatRemote:FireAllClients("BlockEnd",p.Character)
    local c=p.Character
    if c then for _,name in {"CrownSword","CrownShield"} do local v=c:FindFirstChild(name) if v then v:Destroy() end end end
end
function S.Handle(p,action,id)
    if type(action)~="string" or type(id)~="string" or #id>40 or not U.allow(S.Buckets,p,"Item",.2) then return end
    local d=S.State.Get(p) local c,h=U.alive(p)
    if not d or not d.Started or not c or not Defs[id] or (d.Items[id] or 0)<1 then return end
    if action=="Use" and Defs[id].Heal then
        if h.Health>=h.MaxHealth then return end
        if S.Change(p,{[id]=1},{},0) then h.Health=math.min(h.MaxHealth,h.Health+Defs[id].Heal) S.State.Notify(p,"Вы съели хлеб: +25 здоровья.") end
    elseif action=="Equip" and id=="TrainingSword" then
        require(script.Parent.CombatService).Equip(p)
    elseif action=="Unequip" then S.Unequip(p) S.State.Snapshot(p) end
end
function S.Start(state)
    S.State=state
    RS.Remotes.InventoryRemote.OnServerEvent:Connect(S.Handle)
    game.Players.PlayerRemoving:Connect(function(p) S.Buckets[p]=nil end)
end
return S
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("ServerScriptService")
parent=ensure(parent,"Services","Folder")
local obj=ensure(parent,"PlayerStateService","ModuleScript")
local source=[[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local U=require(RS.Shared.UtilityModules)
local S={Profiles={}, Buckets={}}
local remotes=RS:WaitForChild("Remotes")
function S.Notify(p,text)
    remotes.UIUpdateRemote:FireClient(p,"Notice",text)
end
function S.Get(p) return S.Profiles[p] end
function S.Snapshot(p)
    local d=S.Get(p)
    if not d then return end
    remotes.UIUpdateRemote:FireClient(p,"State",{Gold=d.Gold, Items=d.Items, Equipped=d.Equipped, Tutorial=d.Tutorial, Started=d.Started, Persistence="SESSION ONLY", IntroQuestDone=d.IntroQuestDone or false})
end
function S.SetupCharacter(p,c)
    local h=c:WaitForChild("Humanoid",10)
    local r=c:WaitForChild("HumanoidRootPart",10)
    if not h or not r then return end
    local d=S.Get(p)
    if not d then return end
    d.Sprint=false d.Stamina=100 d.Block=false d.DodgeUntil=0
    p:SetAttribute("Stamina",100) p:SetAttribute("Blocking",false)
    h.DisplayName=p.DisplayName
    h.WalkSpeed=d.Started and Config.WalkSpeed or 0
    h.JumpPower=50 h.UseJumpPower=true
    if not d.Started then r.Anchored=true else c:PivotTo(CFrame.new(Config.Spawn)) end
    for _,v in c:GetDescendants() do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then v:Destroy() end
    end
    local preset=Config.Presets[d.Appearance]
    for _,v in c:GetChildren() do
        if v:IsA("BasePart") and v.Name~="Head" and v.Name~="HumanoidRootPart" and not v.Name:find("Hand") then
            v.Color=preset.Color
        end
    end
    h.Died:Connect(function() d.Sprint=false d.Block=false p:SetAttribute("Blocking",false) end)
    S.Snapshot(p)
end
function S.Add(p)
    if S.Profiles[p] then return end
    S.Profiles[p]={Started=false, Gold=15, Items={Bread=2, GatheringTool=1, PeasantClothes=1}, Equipped=nil, Tutorial=1, Appearance=1, Stamina=100, Sprint=false, LastSpend=0, BusyUntil=0, Block=false, BlockSince=0, StunnedUntil=0, DodgeUntil=0}
    p:SetAttribute("Started",false) p:SetAttribute("Stamina",100) p:SetAttribute("SafeZone",true)
    p.CharacterAdded:Connect(function(c) S.SetupCharacter(p,c) end)
    p.CharacterAppearanceLoaded:Connect(function(c)
        local d=S.Get(p)
        if d and p.Character==c then
            for _,v in c:GetChildren() do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then v:Destroy() end
            end
            for _,v in c:GetChildren() do
                if v:IsA("BasePart") and v.Name~="Head" and v.Name~="HumanoidRootPart" and not v.Name:find("Hand") then v.Color=Config.Presets[d.Appearance].Color end
            end
        end
    end)
    if p.Character then task.spawn(S.SetupCharacter,p,p.Character) end
end
function S.Handle(p,action,value)
    if type(action)~="string" then return end
    local d=S.Get(p)
    if not d then return end
    if action=="Sprint" and value==false then d.Sprint=false return end
    if not U.allow(S.Buckets,p,"Input",.08) then return end
    if action=="Ready" then S.Snapshot(p) return end
    if action=="Play" then
        if d.Started or not U.finite(value) or value%1~=0 or not Config.Presets[value] then return end
        local c,h,r=U.alive(p)
        if not c then return end
        d.Started=true d.Appearance=value
        p:SetAttribute("Started",true)
        r.Anchored=false h.WalkSpeed=Config.WalkSpeed
        c:PivotTo(CFrame.new(Config.Spawn))
        for _,v in c:GetChildren() do
            if v:IsA("BasePart") and v.Name~="Head" and v.Name~="HumanoidRootPart" and not v.Name:find("Hand") then v.Color=Config.Presets[value].Color end
        end
        S.Notify(p,"Вы в Crownlands. У вас 15 Gold, хлеб и инструмент собирателя.")
        S.Snapshot(p)
    elseif action=="Sprint" and type(value)=="boolean" and d.Started then
        d.Sprint=value
    elseif action=="Tutorial" and d.Started then
        d.Tutorial=math.min(#Config.Tutorial+1,d.Tutorial+1)
        S.Snapshot(p)
    end
end
function S.Tick(dt)
    local now=os.clock()
    for p,d in S.Profiles do
        local _,h,r=U.alive(p)
        if h and d.Started then
            local sprint=d.Sprint and d.Stamina>0 and not d.Block and now>d.BusyUntil and now>d.StunnedUntil
            local velocity=r.AssemblyLinearVelocity
            local moving=Vector3.new(velocity.X,0,velocity.Z).Magnitude>1
            if sprint and moving then
                d.Stamina=math.max(0,d.Stamina-Config.SprintDrain*dt) d.LastSpend=now
                if d.Stamina==0 then d.Sprint=false end
            elseif now-d.LastSpend>Config.RegenDelay and not d.Block then
                d.Stamina=math.min(100,d.Stamina+Config.StaminaRegen*dt)
            end
            local weight=require(script.Parent.InventoryService).Weight(d.Items)
            h.WalkSpeed=now<d.StunnedUntil and 0 or (weight>30 and 9 or (d.Block and 7 or (sprint and Config.SprintSpeed or Config.WalkSpeed)))
            p:SetAttribute("Stamina",math.floor(d.Stamina+.5))
            p:SetAttribute("SafeZone",U.safePosition(r.Position))
        end
    end
end
function S.Start()
    Players.PlayerAdded:Connect(S.Add)
    Players.PlayerRemoving:Connect(function(p) S.Profiles[p]=nil S.Buckets[p]=nil end)
    for _,p in Players:GetPlayers() do S.Add(p) end
    remotes.InteractionRemote.OnServerEvent:Connect(S.Handle)
end
return S
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("StarterPlayer")
parent=parent:WaitForChild("StarterPlayerScripts")
local obj=ensure(parent,"ClientBootstrap","LocalScript")
obj.Enabled=false
local source=[[local controllers=script.Parent:WaitForChild("Controllers")
require(controllers.UIController).Start()
require(controllers.InventoryController).Start()
require(controllers.InputController).Start()
require(controllers.CombatController).Start()
]]
editor:UpdateSourceAsync(obj,function() return source end)
obj.Enabled=true
end
do local parent=game:GetService("StarterPlayer")
parent=parent:WaitForChild("StarterPlayerScripts")
parent=ensure(parent,"Controllers","Folder")
local obj=ensure(parent,"CombatController","ModuleScript")
local source=[[local RS=game:GetService("ReplicatedStorage")
local CAS=game:GetService("ContextActionService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local player=game:GetService("Players").LocalPlayer
local Touch=require(script.Parent.TouchControls)
local C={Bases=setmetatable({},{__mode="k"}),Serials=setmetatable({},{__mode="k"})}
local function pose(model,side,angle,duration)
    local joint
    for _,v in model:GetDescendants() do if v:IsA("Motor6D") and (v.Name==side.."Shoulder" or v.Name==side.." Shoulder") then joint=v break end end
    if not joint then return end
    local base=C.Bases[joint] or joint.C0 C.Bases[joint]=base
    C.Serials[joint]=(C.Serials[joint] or 0)+1 local serial=C.Serials[joint]
    Tween:Create(joint,TweenInfo.new(.11),{C0=base*CFrame.Angles(math.rad(angle),0,math.rad(side=="Right" and -20 or 20))}):Play()
    if duration then task.delay(duration,function() if joint.Parent and C.Serials[joint]==serial then Tween:Create(joint,TweenInfo.new(.18),{C0=base}):Play() end end) end
end
local function active()
    if not player:GetAttribute("Started") then return false end
    for _,name in {"InventoryUI","TradeUI","DialogueUI"} do
        local gui=player.PlayerGui:FindFirstChild(name)
        local panel=gui and (gui:FindFirstChild("Panel") or gui:FindFirstChild("DialoguePanel"))
        if panel and panel.Visible then return false end
    end
    return true
end
function C.Start()
    local actions={
        {"Light","Удар",Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2,Vector2.new(.83,.50)},
        {"Heavy","Сильный",Enum.KeyCode.R,Enum.KeyCode.ButtonY,Vector2.new(.93,.50)},
        {"Block","Блок",Enum.KeyCode.F,Enum.KeyCode.ButtonL2,Vector2.new(.83,.65)},
        {"Dodge","Уклон",Enum.KeyCode.Q,Enum.KeyCode.ButtonB,Vector2.new(.93,.65)},
    }
    for _,a in actions do
        CAS:BindAction("Crown"..a[1],function(_,state)
            if not active() then return Enum.ContextActionResult.Pass end
            if state==Enum.UserInputState.Begin then RS.Remotes.CombatRemote:FireServer(a[1])
            elseif a[1]=="Block" and (state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel) then RS.Remotes.CombatRemote:FireServer("Unblock") end
            return Enum.ContextActionResult.Sink
        end,false,a[3],a[4])
        Touch.Add("Touch"..a[1],a[1]=="Heavy" and "Тяжёлый" or a[2],UDim2.fromScale(a[5].X,a[5].Y),function()
            if active() then RS.Remotes.CombatRemote:FireServer(a[1]) end
        end,a[1]=="Block" and function() RS.Remotes.CombatRemote:FireServer("Unblock") end or nil)
    end
    RS.Remotes.CombatRemote.OnClientEvent:Connect(function(action,model)
        if typeof(model)~="Instance" or not model:IsA("Model") or not model.Parent then return end
        if action=="Light" or action=="Heavy" then pose(model,"Right",action=="Heavy" and -145 or -90,action=="Heavy" and .55 or .25)
        elseif action=="BlockStart" then pose(model,"Left",-85,nil)
        elseif action=="BlockEnd" then pose(model,"Left",0,.1)
        else
            local color=action=="Hit" and Color3.fromRGB(210,75,48) or (action=="Parry" and Color3.fromRGB(255,226,126) or Color3.fromRGB(165,195,209))
            local h=Instance.new("Highlight") h.Adornee=model h.FillColor=color h.OutlineTransparency=1 h.FillTransparency=.55 h.Parent=model Debris:AddItem(h,.18)
            if action=="Hit" then pose(model,"Left",20,.18) end
        end
    end)
end
return C
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("StarterPlayer")
parent=parent:WaitForChild("StarterPlayerScripts")
parent=ensure(parent,"Controllers","Folder")
local obj=ensure(parent,"InputController","ModuleScript")
local source=[[local CAS=game:GetService("ContextActionService")
local RS=game:GetService("ReplicatedStorage")
local p=game:GetService("Players").LocalPlayer
local S={}
function S.Start()
    CAS:BindAction("CrownSprint",function(_,state)
        if p:GetAttribute("Started") then
            if state==Enum.UserInputState.Begin then RS.Remotes.InteractionRemote:FireServer("Sprint",true)
            elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then RS.Remotes.InteractionRemote:FireServer("Sprint",false) end
        end
        return Enum.ContextActionResult.Sink
    end,false,Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonL3)
    require(script.Parent.TouchControls).Add("TouchSprint","Бег",UDim2.fromScale(.15,.61),function()
        if p:GetAttribute("Started") then RS.Remotes.InteractionRemote:FireServer("Sprint",true) end
    end,function() RS.Remotes.InteractionRemote:FireServer("Sprint",false) end)
    game:GetService("UserInputService").WindowFocusReleased:Connect(function()
        RS.Remotes.InteractionRemote:FireServer("Sprint",false)
        RS.Remotes.CombatRemote:FireServer("Unblock")
    end)
end
return S
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("StarterPlayer")
parent=parent:WaitForChild("StarterPlayerScripts")
parent=ensure(parent,"Controllers","Folder")
local obj=ensure(parent,"InventoryController","ModuleScript")
local source=[[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local Defs=require(RS.Shared.ItemDefinitions)
local C={State=nil,Category="Все"}
local bg=Color3.fromRGB(36,30,24) local gold=Color3.fromRGB(205,178,118) local ink=Color3.fromRGB(237,223,188)
local function make(class,parent,props)
    local o=Instance.new(class) for k,v in props do o[k]=v end o.Parent=parent return o
end
local function text(parent,value,pos,size)
    local t=make("TextLabel",parent,{Text=value,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=ink,TextSize=17,TextScaled=true,Font=Enum.Font.Garamond,TextWrapped=true})
    make("UITextSizeConstraint",t,{MinTextSize=10,MaxTextSize=17}) return t
end
local function btn(parent,value,pos,size,callback)
    local b=make("TextButton",parent,{Text=value,Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(73,59,39),TextColor3=ink,TextSize=17,Font=Enum.Font.Garamond})
    b.Activated:Connect(callback) return b
end
local function window(gui,title)
    local f=make("Frame",gui,{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.48),Size=UDim2.fromScale(.82,.72),BackgroundColor3=bg,BorderSizePixel=0,Visible=false})
    if UIS.TouchEnabled then f.Position=UDim2.fromScale(.49,.43) f.Size=UDim2.fromScale(.58,.60) end
    make("UISizeConstraint",f,{MaxSize=Vector2.new(680,490)}) make("UIStroke",f,{Color=gold,Thickness=1})
    text(f,title,UDim2.fromScale(.04,.01),UDim2.fromScale(.80,.09))
    btn(f,"×",UDim2.fromScale(.90,.01),UDim2.fromScale(.07,.08),function() f.Visible=false require(script.Parent.UIController).Tutorial() end)
    local list=make("ScrollingFrame",f,{Name="Items",Position=UDim2.fromScale(.03,.21),Size=UDim2.fromScale(.94,.75),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
    make("UIListLayout",list,{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
    return f,list
end
function C.Render()
    if not C.State then return end
    for _,list in {C.InventoryList,C.TradeList} do for _,v in list:GetChildren() do if not v:IsA("UIListLayout") then v:Destroy() end end end
    local ids={} for id in Defs do table.insert(ids,id) end table.sort(ids)
    local weight=0
    for id,n in C.State.Items do if Defs[id] then weight+=Defs[id].Weight*n end end
    C.Weight.Text=string.format("%.1f / 30 кг • предел 45 кг  |  %d Gold",weight,C.State.Gold)
    for _,id in ids do
        local def=Defs[id] local amount=C.State.Items[id] or 0
        if amount>0 and (C.Category=="Все" or C.Category==def.Category) then
            local row=make("Frame",C.InventoryList,{Name=id,Size=UDim2.new(1,-8,0,108),BackgroundColor3=Color3.fromRGB(49,41,31),BorderSizePixel=0})
            text(row,def.Icon,UDim2.fromScale(0,.05),UDim2.fromScale(.09,.3))
            text(row,def.Name.." ×"..amount.."  •  "..def.Category,UDim2.fromScale(.09,0),UDim2.fromScale(.88,.26))
            text(row,def.Description,UDim2.fromScale(.08,.28),UDim2.fromScale(.89,.36))
            if def.Heal then btn(row,"Съесть",UDim2.fromScale(.65,.70),UDim2.fromScale(.30,.24),function() RS.Remotes.InventoryRemote:FireServer("Use",id) end)
            elseif id=="TrainingSword" then btn(row,C.State.Equipped==id and "Снять" or "Экипировать",UDim2.fromScale(.55,.70),UDim2.fromScale(.4,.24),function() RS.Remotes.InventoryRemote:FireServer(C.State.Equipped==id and "Unequip" or "Equip",id) end) end
            text(row,tostring(def.Weight*amount).." кг",UDim2.fromScale(.05,.72),UDim2.fromScale(.3,.22))
        end
        local row=make("Frame",C.TradeList,{Name=id,Size=UDim2.new(1,-8,0,78),BackgroundColor3=Color3.fromRGB(49,41,31),BorderSizePixel=0})
        text(row,def.Icon.." "..def.Name.."  ×"..amount,UDim2.fromScale(.02,.03),UDim2.fromScale(.96,.39))
        btn(row,"Купить • "..def.Buy.." G",UDim2.fromScale(.04,.53),UDim2.fromScale(.43,.37),function() RS.Remotes.TradeRemote:FireServer("Buy",id,1) end)
        btn(row,"Продать • "..def.Sell.." G",UDim2.fromScale(.52,.53),UDim2.fromScale(.43,.37),function() RS.Remotes.TradeRemote:FireServer("Sell",id,1) end)
    end
end
function C.Start()
    local p=Players.LocalPlayer local pg=p:WaitForChild("PlayerGui")
    local inv=pg:WaitForChild("InventoryUI") local trade=pg:WaitForChild("TradeUI")
    C.Inventory,C.InventoryList=window(inv,"ИНВЕНТАРЬ") C.Trade,C.TradeList=window(trade,"МИРЕК • ТОРГОВЛЯ")
    C.Weight=text(C.Inventory,"",UDim2.fromScale(.03,.10),UDim2.fromScale(.60,.08))
    local categories={"Все","Оружие","Броня","Еда","Сырьё","Инструменты"}
    local ci=1
    local filter
    filter=btn(C.Inventory,"Все ▾",UDim2.fromScale(.67,.10),UDim2.fromScale(.29,.08),function() ci=ci%#categories+1 C.Category=categories[ci] filter.Text=C.Category.." ▾" C.Render() end)
    C.QuestText=text(pg:WaitForChild("HUD"),"",UDim2.new(1,-260,0,54),UDim2.fromOffset(245,82))
    C.QuestText.BackgroundColor3=bg C.QuestText.BackgroundTransparency=.1
    local function toggle()
        if p:GetAttribute("Started") then C.Inventory.Visible=not C.Inventory.Visible C.Trade.Visible=false require(script.Parent.UIController).Tutorial() end
    end
    btn(pg:WaitForChild("HUD"),"Инвентарь [I]",UDim2.new(1,-150,0,15),UDim2.fromOffset(135,32),toggle)
    CAS:BindAction("CrownInventory",function(_,state) if state==Enum.UserInputState.Begin then toggle() end return Enum.ContextActionResult.Sink end,false,Enum.KeyCode.I,Enum.KeyCode.ButtonSelect)
    RS.Remotes.UIUpdateRemote.OnClientEvent:Connect(function(kind,data)
        if kind=="State" then C.State=data C.Render()
            C.QuestText.Text=data.IntroQuestDone and "Заказ кузнеца выполнен • +12 Gold" or string.format("ЗАКАЗ КУЗНЕЦА\nДревесина %d/3 • Руда %d/2\nНаграда: 12 Gold",math.min(data.Items.Wood or 0,3),math.min(data.Items.Ore or 0,2))
        elseif kind=="Trade" then C.Trade.Visible=true C.Inventory.Visible=false C.Render() require(script.Parent.UIController).Tutorial() end
    end)
end
return C
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("StarterPlayer")
parent=parent:WaitForChild("StarterPlayerScripts")
parent=ensure(parent,"Controllers","Folder")
local obj=ensure(parent,"TouchControls","ModuleScript")
local source=[[local UIS=game:GetService("UserInputService")
local player=game:GetService("Players").LocalPlayer
local T={}
function T.Add(name,title,position,beginAction,endAction)
    if not UIS.TouchEnabled then return end
    local b=Instance.new("TextButton") b.Name=name b.Text=title
    b.AnchorPoint=Vector2.new(.5,.5) b.Position=position b.Size=UDim2.fromOffset(44,44)
    b.Font=Enum.Font.Garamond b.TextScaled=true b.TextWrapped=true b.TextColor3=Color3.fromRGB(241,223,178)
    b.BackgroundColor3=Color3.fromRGB(54,44,30) b.BackgroundTransparency=.1 b.BorderSizePixel=0
    b.Parent=player:WaitForChild("PlayerGui"):WaitForChild("HUD")
    local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(1,0) corner.Parent=b
    local stroke=Instance.new("UIStroke") stroke.Color=Color3.fromRGB(194,166,101) stroke.Transparency=.15 stroke.Parent=b
    local limit=Instance.new("UITextSizeConstraint") limit.MaxTextSize=16 limit.MinTextSize=11 limit.Parent=b
    if endAction then
        local held
        b.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then held=input beginAction() end
        end)
        UIS.InputEnded:Connect(function(input) if input==held then held=nil endAction() end end)
    else b.Activated:Connect(beginAction) end
    return b
end
return T
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
do local parent=game:GetService("StarterPlayer")
parent=parent:WaitForChild("StarterPlayerScripts")
parent=ensure(parent,"Controllers","Folder")
local obj=ensure(parent,"UIController","ModuleScript")
local source=[[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local Config=require(RS.Shared.Config)
local player=Players.LocalPlayer
local UI={Preset=1, Started=false, State=nil}
local colors={bg=Color3.fromRGB(31,27,23),panel=Color3.fromRGB(48,40,30),gold=Color3.fromRGB(202,173,108),text=Color3.fromRGB(237,224,193),dim=Color3.fromRGB(169,158,132)}
local function make(class,parent,props)
    local v=Instance.new(class)
    for k,x in props do v[k]=x end
    v.Parent=parent return v
end
local function label(parent,name,text,pos,size,textsize,color)
    local t=make("TextLabel",parent,{Name=name,Text=text,Position=pos,Size=size,TextSize=textsize or 18,TextScaled=true,TextColor3=color or colors.text,BackgroundTransparency=1,Font=Enum.Font.Garamond,TextWrapped=true})
    make("UITextSizeConstraint",t,{MaxTextSize=textsize or 18,MinTextSize=10})
    return t
end
local function button(parent,name,text,pos,size,callback)
    local b=make("TextButton",parent,{Name=name,Text=text,Position=pos,Size=size,TextSize=20,TextColor3=colors.text,BackgroundColor3=colors.panel,Font=Enum.Font.Garamond,AutoButtonColor=true})
    make("UIStroke",b,{Color=colors.gold,Thickness=1,Transparency=.25}) make("UICorner",b,{CornerRadius=UDim.new(0,4)})
    b.Activated:Connect(callback)
    return b
end
local function bar(parent,name,pos,color)
    local f=make("Frame",parent,{Name=name,Position=pos,Size=UDim2.new(1,0,0,17),BackgroundColor3=Color3.fromRGB(29,25,22),BorderSizePixel=0})
    local fill=make("Frame",f,{Name="Fill",Size=UDim2.fromScale(1,1),BackgroundColor3=color,BorderSizePixel=0})
    local t=label(f,"Value","",UDim2.fromScale(0,0),UDim2.fromScale(1,1),15)
    return fill,t
end
function UI.Notice(text)
    UI.NoticeSerial=(UI.NoticeSerial or 0)+1 local serial=UI.NoticeSerial
    UI.Toast.Text=text UI.Toast.Visible=true
    task.delay(5,function() if UI.NoticeSerial==serial then UI.Toast.Visible=false end end)
end
function UI.Tutorial()
    local n=UI.State and UI.State.Tutorial or 1
    UI.TutorialText.Text=Config.Tutorial[n] or ""
    local modal=false
    for _,name in {"InventoryUI","TradeUI","DialogueUI"} do
        local gui=player.PlayerGui:FindFirstChild(name)
        local panel=gui and (gui:FindFirstChild("Panel") or gui:FindFirstChild("DialoguePanel"))
        if panel and panel.Visible then modal=true end
    end
    UI.TutorialFrame.Visible=UI.Started and n<=#Config.Tutorial and not modal
end
function UI.Start()
    local pg=player:WaitForChild("PlayerGui")
    local menu=pg:WaitForChild("MainMenu") local hud=pg:WaitForChild("HUD") local dialogue=pg:WaitForChild("DialogueUI")
    menu:ClearAllChildren() hud:ClearAllChildren() dialogue:ClearAllChildren()
    menu.Enabled=true hud.Enabled=false dialogue.Enabled=true
    local backdrop=make("Frame",menu,{Name="Backdrop",Size=UDim2.fromScale(1,1),BackgroundColor3=colors.bg,BackgroundTransparency=.08,BorderSizePixel=0})
    local panel=make("Frame",backdrop,{Name="MenuPanel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.9,.86),BackgroundColor3=colors.bg,BackgroundTransparency=.15,BorderSizePixel=0})
    make("UISizeConstraint",panel,{MaxSize=Vector2.new(560,610)})
    label(panel,"Crown","♜",UDim2.fromScale(0,.01),UDim2.fromScale(1,.10),42,colors.gold)
    label(panel,"Title",Config.Title,UDim2.fromScale(0,.12),UDim2.fromScale(1,.12),40,colors.gold)
    label(panel,"Subtitle",Config.Subtitle,UDim2.fromScale(0,.24),UDim2.fromScale(1,.06),18,colors.dim)
    label(panel,"Description","Живи по своим правилам.\nКоролевство начинается с первого шага.",UDim2.fromScale(.05,.33),UDim2.fromScale(.9,.13),21)
    label(panel,"Identity","Имя в мире: "..player.DisplayName,UDim2.fromScale(.05,.47),UDim2.fromScale(.9,.06),18,colors.dim)
    UI.PresetLabel=label(panel,"Appearance",Config.Presets[1].Name,UDim2.fromScale(.20,.55),UDim2.fromScale(.60,.08),21)
    UI.Swatch=make("Frame",panel,{Name="ClothingSwatch",Position=UDim2.fromScale(.45,.64),Size=UDim2.fromScale(.10,.035),BackgroundColor3=Config.Presets[1].Color,BorderSizePixel=0})
    local function choose(delta)
        UI.Preset=(UI.Preset-1+delta)%#Config.Presets+1
        UI.PresetLabel.Text=Config.Presets[UI.Preset].Name UI.Swatch.BackgroundColor3=Config.Presets[UI.Preset].Color
    end
    button(panel,"PreviousPreset","‹",UDim2.fromScale(.05,.55),UDim2.fromScale(.13,.08),function() choose(-1) end)
    button(panel,"NextPreset","›",UDim2.fromScale(.82,.55),UDim2.fromScale(.13,.08),function() choose(1) end)
    UI.PlayButton=button(panel,"Play","ЗАГРУЗКА…",UDim2.fromScale(.12,.72),UDim2.fromScale(.76,.11),function()
        if not UI.State or UI.PlayPending then return end
        UI.PlayPending=true UI.PlayButton.Text="ВХОД В КОРОЛЕВСТВО…"
        RS.Remotes.InteractionRemote:FireServer("Play",UI.Preset)
        task.delay(5,function() if not UI.Started then UI.PlayPending=false UI.PlayButton.Text="PLAY • ИГРАТЬ" end end)
    end)
    UI.LoadingText=label(panel,"LoadingStatus","Подключение к серверу…",UDim2.fromScale(.05,.85),UDim2.fromScale(.9,.06),16,colors.dim)
    label(panel,"Version",Config.Version.."\nТестовая версия • прогресс только до выхода",UDim2.fromScale(.05,.92),UDim2.fromScale(.9,.08),13,colors.dim)
    local stats=make("Frame",hud,{Name="Stats",Position=UDim2.new(0,14,0,12),Size=UDim2.new(.38,0,0,108),BackgroundColor3=colors.bg,BackgroundTransparency=.12,BorderSizePixel=0})
    make("UISizeConstraint",stats,{MaxSize=Vector2.new(320,108),MinSize=Vector2.new(180,108)})
    UI.HealthFill,UI.HealthText=bar(stats,"Health",UDim2.new(0,0,0,24),Color3.fromRGB(132,51,43))
    UI.StaminaFill,UI.StaminaText=bar(stats,"Stamina",UDim2.new(0,0,0,47),Color3.fromRGB(146,133,68))
    UI.GoldText=label(stats,"Gold","15 Gold",UDim2.new(0,0,0,70),UDim2.new(.5,0,0,24),19,colors.gold)
    UI.ZoneText=label(stats,"Zone","Безопасная зона",UDim2.fromScale(.40,0),UDim2.new(.6,0,0,24),14,colors.dim)
    UI.EquipText=label(stats,"Equipment","Инструмент собирателя",UDim2.new(0,4,0,93),UDim2.new(1,-8,0,15),13,colors.dim)
    label(stats,"Brand","CROWNLANDS",UDim2.new(0,4,0,0),UDim2.new(.43,0,0,23),16,colors.gold)
    UI.Toast=label(hud,"Notification","",UDim2.fromScale(.2,.17),UDim2.fromScale(.6,.12),20)
    UI.Toast.BackgroundColor3=colors.bg UI.Toast.BackgroundTransparency=.1 UI.Toast.Visible=false
    if UIS.TouchEnabled then UI.Toast.Position=UDim2.fromScale(.27,.40) UI.Toast.Size=UDim2.fromScale(.46,.12) end
    UI.TutorialFrame=make("Frame",hud,{Name="Tutorial",AnchorPoint=Vector2.new(.5,1),Position=UDim2.fromScale(.5,.96),Size=UDim2.new(.56,0,0,95),BackgroundColor3=colors.bg,BackgroundTransparency=.12,BorderSizePixel=0})
    make("UISizeConstraint",UI.TutorialFrame,{MaxSize=Vector2.new(570,95),MinSize=Vector2.new(230,95)})
    UI.TutorialText=label(UI.TutorialFrame,"Objective","",UDim2.fromScale(.03,0),UDim2.fromScale(.94,.63),17)
    button(UI.TutorialFrame,"NextTutorial","Понятно →",UDim2.fromScale(.27,.68),UDim2.fromScale(.46,.27),function() RS.Remotes.InteractionRemote:FireServer("Tutorial") end)
    local death=make("Frame",hud,{Name="DeathScreen",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(25,15,13),BackgroundTransparency=.3,Visible=false,ZIndex=10})
    label(death,"DeathTitle","ВЫ ПАЛИ\nВозвращение в деревню…",UDim2.fromScale(.15,.38),UDim2.fromScale(.7,.22),34,colors.gold)
    UI.DeathScreen=death
    local dialog=make("Frame",dialogue,{Name="DialoguePanel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.55),Size=UDim2.fromScale(.8,.42),BackgroundColor3=colors.bg,Visible=false,BorderSizePixel=0})
    make("UISizeConstraint",dialog,{MaxSize=Vector2.new(580,320)})
    UI.Dialogue=dialog
    UI.DialogueName=label(dialog,"Speaker","",UDim2.fromScale(.05,.06),UDim2.fromScale(.9,.15),26,colors.gold)
    UI.DialogueText=label(dialog,"Speech","",UDim2.fromScale(.07,.25),UDim2.fromScale(.86,.43),20)
    button(dialog,"CloseDialogue","До встречи",UDim2.fromScale(.3,.76),UDim2.fromScale(.4,.17),function() dialog.Visible=false UI.Tutorial() end)
    local function character(c)
        UI.DeathScreen.Visible=false
        if UI.HealthConnection then UI.HealthConnection:Disconnect() end
        if UI.DeathConnection then UI.DeathConnection:Disconnect() end
        local h=c:WaitForChild("Humanoid",10) if not h then return end
        local function health()
            UI.HealthFill.Size=UDim2.fromScale(math.clamp(h.Health/h.MaxHealth,0,1),1)
            UI.HealthText.Text=string.format("Здоровье  %d / %d",h.Health,h.MaxHealth)
        end
        health() UI.HealthConnection=h.HealthChanged:Connect(health)
        UI.DeathConnection=h.Died:Connect(function() UI.DeathScreen.Visible=true end)
    end
    player.CharacterAdded:Connect(character)
    if player.Character then task.spawn(character,player.Character) end
    player:GetAttributeChangedSignal("Stamina"):Connect(function()
        local value=player:GetAttribute("Stamina") or 100
        UI.StaminaFill.Size=UDim2.fromScale(value/100,1) UI.StaminaText.Text="Выносливость  "..value.." / 100"
    end)
    UI.StaminaText.Text="Выносливость  100 / 100"
    player:GetAttributeChangedSignal("SafeZone"):Connect(function() UI.ZoneText.Text=player:GetAttribute("SafeZone") and "Безопасная зона" or "Дикие земли • PvP" end)
    RS.Remotes.UIUpdateRemote.OnClientEvent:Connect(function(kind,data)
        if kind=="State" then
            UI.State=data UI.Started=data.Started
            UI.PlayButton.Text="PLAY • ИГРАТЬ" UI.LoadingText.Text="Мир готов • выберите одежду"
            menu.Enabled=not data.Started hud.Enabled=data.Started
            UI.GoldText.Text=tostring(data.Gold).." Gold"
            UI.EquipText.Text=data.Equipped and "Учебный меч + щит" or "Инструмент собирателя • хлеб ×2"
            UI.Tutorial()
        elseif kind=="Notice" then UI.Notice(data)
        elseif kind=="Dialogue" then UI.Dialogue.Visible=true UI.DialogueName.Text=data.Name UI.DialogueText.Text=data.Text UI.Tutorial() end
    end)
    task.spawn(function()
        for _=1,20 do
            if UI.State then break end
            RS.Remotes.InteractionRemote:FireServer("Ready") task.wait(1)
        end
        if not UI.State then UI.LoadingText.Text="Сервер не ответил. Проверьте Output и перезапустите Play." end
    end)
    print("CROWNLANDS_CLIENT_READY",UIS.TouchEnabled and "touch" or "desktop")
end
return UI
]]
editor:UpdateSourceAsync(obj,function() return source end)
end
print("CROWN_INSTALL_OK",16,"source files")
