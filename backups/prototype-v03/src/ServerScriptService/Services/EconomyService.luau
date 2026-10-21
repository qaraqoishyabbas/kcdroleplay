local RS=game:GetService("ReplicatedStorage")
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
