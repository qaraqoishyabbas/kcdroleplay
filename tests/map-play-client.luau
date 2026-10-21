-- CLIENT Command Bar during Play. Uses normal Roblox character controls and native streaming.
local p=game.Players.LocalPlayer
local deadline=os.clock()+15
repeat task.wait(.1) until (p.Character and p.Character:FindFirstChild("HumanoidRootPart")) or os.clock()>deadline
local c=assert(p.Character,"No character") local r=assert(c:FindFirstChild("HumanoidRootPart")) local h=c:FindFirstChildOfClass("Humanoid")
assert(h and h.Health>0 and not r.Anchored,"Character cannot move")
assert(h.WalkSpeed==22,"Unexpected speed")
assert((r.Position-Vector3.new(-1200,4,-335)).Magnitude<20,"Not at the exploration spawn")
for _,name in {"MainMenu","HUD","InventoryUI","TradeUI","DialogueUI"} do assert(not p.PlayerGui:FindFirstChild(name),"Old GUI remains: "..name) end
assert(not game.ReplicatedStorage:FindFirstChild("Remotes"),"Old remotes remain")
assert(p:GetAttribute("Stamina")==nil,"Old stamina system remains")
local start=r.Position h:MoveTo(start+Vector3.new(0,0,-32))
task.wait(1)
assert((r.Position-start).Magnitude>8,"Character failed to run")
h:MoveTo(r.Position)
print("MAP_RUN_PASS",h.WalkSpeed,r.Position)
local village=workspace.Map.Settlements:WaitForChild("Oakmere",10)
assert(village,"Village folder did not replicate")
local at=village:GetAttribute("Center")
local before=#village:GetDescendants()
p:RequestStreamAroundAsync(at,8)
c:PivotTo(CFrame.new(at+Vector3.new(0,6,15)))
task.wait(2)
assert(#village:GetDescendants()>50,"Village geometry did not stream in")
assert(r.Position.Y> -5 and h.Health>0,"Terrain missing after streaming")
print("MAP_STREAM_PASS",before,#village:GetDescendants(),r.Position)
p:RequestStreamAroundAsync(Vector3.new(-1200,4,-335),8)
c:PivotTo(CFrame.new(-1200,4,-335))
print("MAP_PLAY_PASS","Run-only character; no game UI; distant village streamed")
