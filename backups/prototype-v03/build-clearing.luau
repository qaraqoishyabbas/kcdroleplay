-- Run once in the Roblox Studio Command Bar in edit mode.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before building")
assert(not workspace:FindFirstChild("MedievalClearing"), "Clearing already exists")
local model = Instance.new("Model")
model.Name = "MedievalClearing"
local function group(name)
    local f = Instance.new("Folder")
    f.Name = name
    f.Parent = model
    return f
end
local ground, forest, camp, shelter = group("Ground"), group("Forest"), group("Campfire"), group("Shelter")
local wood, stone = Color3.fromRGB(94, 66, 43), Color3.fromRGB(105, 108, 98)
local function part(parent, name, size, cf, color, material, shape)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Color, p.Material = color, material
    p.Anchored = true
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end
local function block(parent, name, size, pos, color, material)
    return part(parent, name, size, CFrame.new(pos), color, material)
end
local function disk(parent, name, x, z, diameter, height, y, color, material)
    return part(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(x,y,z)*CFrame.Angles(0,0,math.pi/2), color, material, Enum.PartType.Cylinder)
end
disk(ground,"GrassyClearing",0,0,142,.5,.25,Color3.fromRGB(91,116,60),Enum.Material.Grass)
disk(ground,"EarthAroundFire",0,-3,27,.12,.56,Color3.fromRGB(120,99,69),Enum.Material.Ground)
for i = 0, 9 do
    local z = 44-i*4.5
    local x = math.sin(i*.38)*2
    disk(ground,"Footpath",x,z,9,.08,.57,Color3.fromRGB(133,115,81),Enum.Material.Ground)
end
local rng = Random.new(731)
for i = 0, 27 do
    local angle = (i/28)*math.pi*2
    local x,z = math.cos(angle)*rng:NextNumber(53,66), math.sin(angle)*rng:NextNumber(53,66)
    if not (z > 45 and math.abs(x) < 15) then
        local tree = Instance.new("Model")
        tree.Name = "Oak_"..i
        tree.Parent = forest
        local h = rng:NextNumber(15,23)
        block(tree,"Trunk",Vector3.new(2.5,h,2.5),Vector3.new(x,h/2+.5,z),wood,Enum.Material.Wood)
        for j=1,3 do
            local crown=part(tree,"Leaves",Vector3.new(14,12,14)*rng:NextNumber(.85,1.2),CFrame.new(x+(j-2)*3,h+1+(j==2 and 4 or 0),z+(j==2 and 2 or -1)),Color3.fromRGB(57+j*9,83+j*9,43+j*3),Enum.Material.Grass,Enum.PartType.Ball)
            crown.CanCollide=false
        end
    end
end
for i=1,18 do
    local a=i/18*math.pi*2
    local x,z=math.cos(a)*rng:NextNumber(43,49),math.sin(a)*rng:NextNumber(43,49)
    if not(z>37 and math.abs(x)<13) then
        local b=part(forest,"FernBush",Vector3.new(5,3.5,5),CFrame.new(x,1.8,z),Color3.fromRGB(76,100,53),Enum.Material.Grass,Enum.PartType.Ball)
        b.CanCollide=false
        part(forest,"Boulder",Vector3.new(4,2.6,3),CFrame.new(x+4,1.3,z+2)*CFrame.Angles(.2,i,.1),stone,Enum.Material.Slate,Enum.PartType.Ball)
    end
end
for i=1,12 do
    local a=i/12*math.pi*2
    part(camp,"FireRingStone",Vector3.new(1.6,1.1,1.2),CFrame.new(math.cos(a)*3,.95,-3+math.sin(a)*3)*CFrame.Angles(.1,a,.1),stone,Enum.Material.Cobblestone,Enum.PartType.Ball)
end
for i=0,2 do
    part(camp,"Firewood",Vector3.new(4.3,.65,.65),CFrame.new(0,.95+i*.32,-3)*CFrame.Angles(0,i*math.pi/3,0),wood,Enum.Material.Wood)
end
local embers=disk(camp,"Embers",0,-3,3,.25,.8,Color3.fromRGB(214,86,27),Enum.Material.Neon)
local fire=Instance.new("Fire")
fire.Name,fire.Size,fire.Heat="CampfireFlame",4,6
fire.Color,fire.SecondaryColor=Color3.fromRGB(255,174,62),Color3.fromRGB(255,86,30)
fire.Parent=embers
local light=Instance.new("PointLight")
light.Color,light.Brightness,light.Range=Color3.fromRGB(255,177,91),2,24
light.Parent=embers
for _,x in {-8,8} do
    block(camp,"Bench",Vector3.new(2,1,8),Vector3.new(x,2,-3),wood,Enum.Material.WoodPlanks)
    for _,z in {-5.5,-.5} do block(camp,"BenchLeg",Vector3.new(1,1.2,1),Vector3.new(x,1.1,z),wood,Enum.Material.Wood) end
end
block(shelter,"TimberFloor",Vector3.new(19,.65,16),Vector3.new(-24,.85,-18),wood,Enum.Material.WoodPlanks)
for _,x in {-32,-16} do
    for _,z in {-24,-12} do block(shelter,"Post",Vector3.new(.8,10,.8),Vector3.new(x,5.5,z),wood,Enum.Material.Wood) end
end
for _,x in {-32,-16} do block(shelter,"RoofBeam",Vector3.new(.9,.8,15),Vector3.new(x,10.4,-18),wood,Enum.Material.Wood) end
for _,side in {-1,1} do
    part(shelter,"PitchedRoof",Vector3.new(11,.65,19),CFrame.new(-24+side*4.65,11.6,-18)*CFrame.Angles(0,0,-side*math.rad(20)),Color3.fromRGB(79,60,42),Enum.Material.WoodPlanks)
end
block(shelter,"BackRail",Vector3.new(17,.7,.6),Vector3.new(-24,4,-24),wood,Enum.Material.Wood)
block(shelter,"Table",Vector3.new(7,.6,3.5),Vector3.new(-24,3.5,-21),wood,Enum.Material.WoodPlanks)
for _,x in {-26.5,-21.5} do block(shelter,"TableLeg",Vector3.new(.6,2.4,2.8),Vector3.new(x,2.1,-21),wood,Enum.Material.Wood) end
for _,x in {-29,-26} do block(shelter,"SupplyCrate",Vector3.new(2.6,2.6,2.6),Vector3.new(x,2.5,-15),Color3.fromRGB(138,105,62),Enum.Material.WoodPlanks) end
local entrance=group("Entrance")
for _,x in {-9,9} do
    block(entrance,"GatePost",Vector3.new(1,7,1),Vector3.new(x,4,48),wood,Enum.Material.Wood)
    local lamp=block(entrance,"Lantern",Vector3.new(1.4,1.6,1.4),Vector3.new(x,7.6,48),Color3.fromRGB(255,204,113),Enum.Material.Neon)
    local glow=Instance.new("PointLight") glow.Color=lamp.Color glow.Brightness=.8 glow.Range=13 glow.Parent=lamp
end
local sign=block(entrance,"CampSign",Vector3.new(10,2.4,.5),Vector3.new(0,8.2,48),wood,Enum.Material.WoodPlanks)
local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Back gui.Parent=sign
local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text="ЛЕСНОЙ ПРИВАЛ" label.Font=Enum.Font.Garamond label.TextScaled=true label.TextColor3=Color3.fromRGB(238,219,176) label.Parent=gui
model.Parent=workspace
local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation") or Instance.new("SpawnLocation",workspace)
spawn.Name="ClearingSpawn"
spawn.Size=Vector3.new(7,.3,7)
spawn.CFrame=CFrame.new(0,.73,39)
spawn.Anchored=true spawn.Neutral=true spawn.Enabled=true spawn.Duration=0
spawn.Material=Enum.Material.Ground spawn.Color=Color3.fromRGB(133,115,81)
for _,v in spawn:GetChildren() do if v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end end
spawn.Parent=model
local base=workspace:FindFirstChild("Baseplate")
if base then base.Material=Enum.Material.Grass base.Color=Color3.fromRGB(79,102,53) end
game:GetService("Players").CharacterAutoLoads=true
local starter=game:GetService("StarterPlayer")
starter.CameraMode=Enum.CameraMode.Classic
starter.CameraMinZoomDistance=.5 starter.CameraMaxZoomDistance=28
starter.CharacterWalkSpeed=16
local lighting=game:GetService("Lighting")
lighting.ClockTime=16.3 lighting.Brightness=2
lighting.Ambient=Color3.fromRGB(109,108,91)
lighting.OutdoorAmbient=Color3.fromRGB(139,143,116)
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(96,87,116),Vector3.new(0,1,-5))
game:GetService("ChangeHistoryService"):SetWaypoint("Added medieval clearing")
assert(model:FindFirstChild("ClearingSpawn").Enabled)
assert(#forest:GetChildren()>30)
assert(camp:FindFirstChild("Embers"):FindFirstChildOfClass("Fire"))
print("CLEARING_BUILD_OK",#model:GetDescendants(),"objects; spawn",spawn.Position)
