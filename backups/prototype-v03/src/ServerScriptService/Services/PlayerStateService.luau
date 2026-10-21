local Players=game:GetService("Players")
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
