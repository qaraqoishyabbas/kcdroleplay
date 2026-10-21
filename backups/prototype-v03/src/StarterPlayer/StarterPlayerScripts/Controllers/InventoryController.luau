local Players=game:GetService("Players")
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
