local CAS=game:GetService("ContextActionService")
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
