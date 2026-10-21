local Players=game:GetService("Players")
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
