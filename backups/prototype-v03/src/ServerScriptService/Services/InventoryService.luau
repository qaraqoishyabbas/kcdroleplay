local RS=game:GetService("ReplicatedStorage")
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
