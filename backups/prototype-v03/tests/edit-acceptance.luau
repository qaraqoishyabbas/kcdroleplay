-- Run in Studio Command Bar in EDIT mode after installation and world build.
local checks=0
local function check(condition,message) assert(condition,message) checks+=1 end
local rs=game.ReplicatedStorage
for _,name in {"Shared","Remotes"} do check(rs:FindFirstChild(name),name.." missing") end
for _,name in {"Config","UtilityModules","WeaponDefinitions","ItemDefinitions"} do
    local object=rs.Shared:FindFirstChild(name) check(object and object:IsA("ModuleScript"),name.." ModuleScript missing") check(type(require(object))=="table",name.." cannot load")
end
for _,name in {"PlayerStateService","InteractionService","CombatService","InventoryService","EconomyService"} do check(type(require(game.ServerScriptService.Services[name]))=="table",name.." cannot load") end
for _,name in {"MainMenu","HUD","DialogueUI","InventoryUI","TradeUI"} do check(game.StarterGui:FindFirstChild(name),name.." missing") end
for _,name in {"Village","Market","Castle","Farm","River","Bridge","TrainingGround","BanditCamp","Roads"} do check(workspace.Map.CrownlandsPrototype:FindFirstChild(name),"Map zone missing: "..name) end
check(workspace.Map:FindFirstChild("MedievalClearing"),"Original clearing lost")
for _,name in {"UIController","InputController","CombatController","InventoryController","TouchControls"} do
    check(type(require(game.StarterPlayer.StarterPlayerScripts.Controllers[name]))=="table",name.." cannot load")
end
check(not game.ServerScriptService:FindFirstChild("CrownMultiplayerAcceptance"),"Temporary server test script remains")
check(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("CrownMultiplayerClient"),"Temporary client test script remains")
check(not rs:FindFirstChild("CrownTestReport"),"Temporary test remote remains")
local active=0
for _,v in workspace:GetDescendants() do if v:IsA("SpawnLocation") and v.Enabled then active+=1 end end
check(active==1,"Expected exactly one active village spawn")
check(workspace.Map.CrownlandsPrototype.VillageSpawn.Neutral,"Spawn must be neutral")
check(#workspace.NPCs:GetChildren()==9,"Expected six civilians and three combat targets")
check(workspace.StreamingEnabled,"Streaming must be enabled")
local U=require(rs.Shared.UtilityModules)
check(not U.finite(0/0) and not U.finite(math.huge) and not U.finite("1"),"Non-finite values accepted")
check(U.finite(2),"Finite number rejected")
check(U.safePosition(Vector3.new(0,0,0)) and not U.safePosition(Vector3.new(170,0,-35)),"Safe zone bounds invalid")
local bucket={} local key={}
check(U.allow(bucket,key,"test",1),"Initial request rejected")
check(not U.allow(bucket,key,"test",1),"Spam accepted")
local combat=require(game.ServerScriptService.Services.CombatService)
local function target(name,position)
    local m=Instance.new("Model") m.Name=name
    local r=Instance.new("Part") r.Name="HumanoidRootPart" r.Size=Vector3.new(2,2,1) r.CFrame=CFrame.new(position) r.Anchored=true r.Parent=m
    local h=Instance.new("Humanoid") h.Parent=m m.Parent=workspace return m
end
local a=target("TestAttacker",Vector3.new(300,5,300))
local b=target("TestTarget",Vector3.new(300,5,295))
check(combat.ValidTarget(a,b,7),"Visible target in reach rejected")
b.HumanoidRootPart.Position=Vector3.new(300,5,280)
check(not combat.ValidTarget(a,b,7),"Distant target accepted")
b.HumanoidRootPart.Position=Vector3.new(300,5,305)
check(not combat.ValidTarget(a,b,7),"Rear target accepted")
b.HumanoidRootPart.Position=Vector3.new(300,5,295)
local wall=Instance.new("Part") wall.Size=Vector3.new(5,8,1) wall.Position=Vector3.new(300,5,297.5) wall.Anchored=true wall.Parent=workspace
check(not combat.ValidTarget(a,b,7),"Attack through wall accepted")
wall:Destroy() a:Destroy() b:Destroy()
print("CROWN_EDIT_TESTS_PASS",checks)
