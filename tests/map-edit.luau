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
for _,parent in {workspace,game.ServerScriptService,game.ReplicatedStorage,game.StarterGui,game.StarterPlayer.StarterPlayerScripts} do
    for _,v in parent:GetDescendants() do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
            scripts+=1
            check(v:IsA("LocalScript") and v.Name=="ExplorerFlight" and v.Parent==game.StarterPlayer.StarterPlayerScripts,"Unexpected runtime script: "..v:GetFullName())
        end
        if v:IsA("ProximityPrompt") then error("Gameplay interaction remains: "..v:GetFullName()) end
    end
end
check(scripts==1,"Expected only the exploration flight controller")
check(#game.StarterGui:GetChildren()==0,"Custom game UI remains")
check(not workspace:FindFirstChild("NPCs"),"Old NPCs remain")
check(not game.ReplicatedStorage:FindFirstChild("Remotes"),"Old remotes remain")
local spawns=0
for _,v in workspace:GetDescendants() do
    if v:IsA("SpawnLocation") and v.Enabled then spawns+=1 end
    if v:IsA("BasePart") and v:IsDescendantOf(map) then check(v.Anchored,"Unanchored scenery: "..v:GetFullName()) end
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
print("MAP_EDIT_PASS",count,"assertions; flight controller only, no RPG scripts or UI")
