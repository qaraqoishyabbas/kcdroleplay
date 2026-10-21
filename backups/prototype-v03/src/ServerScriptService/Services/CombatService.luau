local Players=game:GetService("Players")
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
