local RS=game:GetService("ReplicatedStorage")
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
