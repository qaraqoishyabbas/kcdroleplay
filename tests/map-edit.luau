-- Run in the Studio Command Bar after build-map.luau finishes.
local count=0
local function check(value,message) assert(value,message) count+=1 end
local map=assert(workspace:FindFirstChild("Map"),"Map missing")
check(map:GetAttribute("BuildComplete"),"Map is still building")
check(map:GetAttribute("WidthStuds")==14336 and map:GetAttribute("LengthStuds")==14336,"Incorrect footprint")
check(math.abs(map:GetAttribute("WidthStuds")*map:GetAttribute("MetresPerStud")-4000)<20,"Not approximately 4 km")
check(#map.Settlements:GetChildren()==4,"Expected a city and three villages")
local cities,villages=0,0
for _,v in map.Settlements:GetChildren() do
    if v:GetAttribute("Kind")=="City" then cities+=1 else villages+=1 end
end
check(cities==1 and villages==3,"Settlement kinds incorrect")
check(#map.Bridges:GetChildren()==2,"Expected two river crossings")
check(map:GetAttribute("TreeCount")>2000,"Forest coverage too sparse")
check(map:GetAttribute("HillCount")>50,"Hills missing")
check(workspace.StreamingEnabled,"Streaming is disabled")
check(game.StarterPlayer.CharacterWalkSpeed==22,"Run speed incorrect")
check(game.Players.CharacterAutoLoads,"Character auto-load is disabled")
local scripts=0
local combat=game.ReplicatedStorage:FindFirstChild("CombatConfig")~=nil
local allowed={ExplorerFlight=true,CombatClient=true,CombatBootstrap=true,CombatConfig=true,CombatNet=true,
    World=true,Arsenal=true,Stats=true,Melee=true,Arrows=true,Shop=true,Vendor=true}
for _,parent in {workspace,game.ServerScriptService,game.ReplicatedStorage,game.StarterGui,game.StarterPlayer.StarterPlayerScripts} do
    for _,v in parent:GetDescendants() do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
            scripts+=1
            local known=allowed[v.Name] and (v.Parent==game.StarterPlayer.StarterPlayerScripts
                or v.Parent==game.ReplicatedStorage or v.Parent==game.ServerScriptService
                or (v.Parent.Name=="Combat" and v.Parent.Parent==game.ServerScriptService))
            check(known and (combat or v.Name=="ExplorerFlight"),"Unexpected runtime script: "..v:GetFullName())
        end
        if v:IsA("ProximityPrompt") then check(combat and v:IsDescendantOf(map.TrainingYard),"Unexpected interaction: "..v:GetFullName()) end
    end
end
check(scripts==(combat and 12 or 1),"Unexpected number of active source scripts")
check(#game.StarterGui:GetChildren()==0,"Custom game UI remains")
check(not workspace:FindFirstChild("NPCs"),"Old NPCs remain")
check(not game.ReplicatedStorage:FindFirstChild("Remotes"),"Old remotes remain")
local spawns=0
for _,v in workspace:GetDescendants() do
    if v:IsA("SpawnLocation") and v.Enabled then spawns+=1 end
    if v:IsA("BasePart") and v:IsDescendantOf(map) then
        local rig=v:FindFirstAncestorOfClass("Model")
        local npc=rig and rig:FindFirstChildOfClass("Humanoid") and rig.PrimaryPart and rig.PrimaryPart.Anchored
        check(v.Anchored or (npc and v.Massless and not v.CanCollide),"Unanchored scenery: "..v:GetFullName())
    end
end
check(spawns==1,"Expected one spawn")
local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={workspace.Terrain}
for _,pos in {Vector3.new(-7000,0,-7000),Vector3.new(7000,0,7000),Vector3.new(-7000,0,7000),Vector3.new(7000,0,-7000),map.ExplorationSpawn.Position} do
    local hit=workspace:Raycast(Vector3.new(pos.X,1024,pos.Z),Vector3.new(0,-2048,0),params)
    check(hit and hit.Material~=Enum.Material.Water,"Terrain/solid spawn ground missing")
end
for _,z in {-6000,0,6000} do
    local x=1000+560*math.sin(z/1900)+170*math.sin(z/670)
    local hit=workspace:Raycast(Vector3.new(x,1024,z),Vector3.new(0,-2048,0),params)
    check(hit and hit.Material==Enum.Material.Water,"River water missing")
end
print("MAP_EDIT_PASS",count,"assertions; combat=",combat,"source scripts=",scripts)
