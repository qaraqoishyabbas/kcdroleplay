local RS=game:GetService("ReplicatedStorage")
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
