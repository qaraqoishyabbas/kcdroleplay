-- Run in CLIENT Command Bar during Play; exercises the actual gate passage.
local p=game.Players.LocalPlayer
local c=p.Character or p.CharacterAdded:Wait()
local r=c:WaitForChild('HumanoidRootPart') local h=c:WaitForChild('Humanoid')
assert(h.Health>0 and h.WalkSpeed==22,'Spawn/movement unavailable')
assert((r.Position-Vector3.new(-1200,5,-335)).Magnitude<20,'Unexpected initial spawn')
assert(workspace.Map:WaitForChild('SpawnApproach',10),'Scenic pass missing')
h:MoveTo(Vector3.new(-1200,5,-420))
local deadline=os.clock()+7
repeat task.wait(.1) until r.Position.Z < -414 or os.clock()>deadline
assert(r.Position.Z < -414 and h.Health>0,'Blocked between spawn and city')
print('SPAWN_APPROACH_WALK_PASS',r.Position,'gate crossed alive')
c:PivotTo(CFrame.new(-1200,5,-335)*CFrame.Angles(0,0,0))
