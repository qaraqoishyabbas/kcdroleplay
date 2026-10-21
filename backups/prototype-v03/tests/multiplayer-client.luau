local test=game:GetService("StudioTestService")
local ok,args=pcall(function() return test:GetTestArgs() end)
if not ok or type(args)~="table" or args.Mode~="CrownAcceptance" then return end
local p=game.Players.LocalPlayer
local rs=game.ReplicatedStorage
local report=rs:WaitForChild("CrownTestReport",30)
assert(report,"Test report remote missing")
local effects=0
rs.Remotes.CombatRemote.OnClientEvent:Connect(function() effects+=1 end)
report.OnClientEvent:Connect(function()
    task.wait(3)
    local okCheck,message=pcall(function()
        assert(p.PlayerGui.HUD.Enabled and not p.PlayerGui.MainMenu.Enabled,"HUD/menu wrong")
        assert(#game.Players:GetPlayers()==2,"Client does not see both players")
        for _,other in game.Players:GetPlayers() do
            local c=assert(other.Character,"Other character missing")
            assert(c:FindFirstChild("CrownSword") and c:FindFirstChild("CrownShield"),"Other equipment missing")
        end
        assert(effects>0,"Combat effects did not replicate")
    end)
    report:FireServer(okCheck,tostring(message),effects)
end)
local deadline=os.clock()+30
repeat
    if p.PlayerGui:FindFirstChild("HUD") and p.PlayerGui.HUD:FindFirstChild("Stats") and p.Character then
        rs.Remotes.InteractionRemote:FireServer("Play",2)
    end
    task.wait(.5)
until p:GetAttribute("Started") or os.clock()>deadline
assert(p:GetAttribute("Started"),"Multiplayer client could not enter game")
