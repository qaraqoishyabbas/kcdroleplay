local UIS=game:GetService("UserInputService")
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
