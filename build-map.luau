-- Edit-time only. Builds the exploration map; adds NO runtime scripts, remotes, NPCs or custom UI.
assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local W=workspace
local terrain=W.Terrain
local HALF=7168 -- 14,336 studs * 0.28 m = 4,014 m per side.
local rng=Random.new(20261020)
local function remove(parent,name) local v=parent:FindFirstChild(name) if v then v:Destroy() end end
-- Previous prototype is backed up locally before this command is run.
for _,name in {"Bootstrap","Services","CrownMultiplayerAcceptance"} do remove(game.ServerScriptService,name) end
for _,name in {"Shared","Remotes","CrownTestReport"} do remove(game.ReplicatedStorage,name) end
for _,name in {"MainMenu","HUD","DialogueUI","InventoryUI","TradeUI","MovementControls"} do remove(game.StarterGui,name) end
for _,name in {"ClientBootstrap","Controllers","CrownMultiplayerClient"} do remove(game.StarterPlayer.StarterPlayerScripts,name) end
for _,name in {"NPCModels","ItemModels","WeaponModels","WorldTemplates"} do remove(game.ServerStorage,name) end
for _,name in {"Map","Baseplate","InteractionPoints","NPCs","NPCSpawns","ResourceNodes","SafeZones","EnemySpawns","MedievalClearing"} do remove(W,name) end
terrain:Clear()
local map=Instance.new("Folder") map.Name="Map" map.Parent=W
map:SetAttribute("Version","Map blockout 0.1")
map:SetAttribute("WidthStuds",HALF*2) map:SetAttribute("LengthStuds",HALF*2)
map:SetAttribute("MetresPerStud",.28) map:SetAttribute("BuildComplete",false)
local function folder(parent,name) local f=Instance.new("Folder") f.Name=name f.Parent=parent return f end
local settlements=folder(map,"Settlements")
local nature=folder(map,"Nature")
local routes=folder(map,"Roads")
local bridges=folder(map,"Bridges")
local fields=folder(map,"Fields")
local forest=folder(nature,"Forests")
local planning=folder(map,"Planning")
local stone=Color3.fromRGB(127,127,114)
local wood=Color3.fromRGB(83,62,43)
local plaster=Color3.fromRGB(191,177,143)
local function part(parent,name,size,cf,color,material,class)
    local v=Instance.new(class or "Part") v.Name=name v.Size=size
    v.CFrame=typeof(cf)=="Vector3" and CFrame.new(cf) or cf
    v.Color=color v.Material=material or Enum.Material.WoodPlanks
    v.Anchored=true v.TopSurface=Enum.SurfaceType.Smooth v.BottomSurface=Enum.SurfaceType.Smooth
    v.Parent=parent return v
end
local function label(parent,words,pos,width)
    local board=part(parent,"PlaceName",Vector3.new(width or 24,3,.5),pos,wood)
    for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
        local g=Instance.new("SurfaceGui") g.Face=face g.PixelsPerStud=24 g.Parent=board
        local t=Instance.new("TextLabel") t.Size=UDim2.fromScale(1,1) t.BackgroundTransparency=1
        t.Text=words t.TextScaled=true t.Font=Enum.Font.Garamond t.TextColor3=Color3.fromRGB(235,216,172) t.Parent=g
    end
end
local function marker(name,pos)
    local v=part(planning,name,Vector3.one,pos,Color3.new(1,1,1)) v.Transparency=1 v.CanCollide=false v.CanTouch=false v.CanQuery=false return v
end
for _,x in {-HALF,HALF} do for _,z in {-HALF,HALF} do marker("WorldCorner",Vector3.new(x,0,z)) end end
local city=Vector3.new(-1200,0,-800)
local riverX=function(z) return 1000+560*math.sin(z/1900)+170*math.sin(z/670) end
local south=Vector3.new(-3500,0,2200)
local east=Vector3.new(riverX(1000)+380,0,1000)
local north=Vector3.new(1900,0,-3400)
local hubs={city,south,east,north}
local roadLegs={}
local function leg(a,b,width)
    table.insert(roadLegs,{a,b,width or 22})
    local delta=b-a local n=math.ceil(delta.Magnitude/160)
    for i=1,n do
        local start=a:Lerp(b,(i-1)/n) local finish=a:Lerp(b,i/n)
        local mid=(start+finish)/2
        part(routes,"DirtTrack",Vector3.new(width or 22,.4,(finish-start).Magnitude+1),CFrame.lookAt(mid+Vector3.new(0,.25,0),finish+Vector3.new(0,.25,0)),Color3.fromRGB(125,108,79),Enum.Material.Ground)
    end
end
local function path(points,width) for i=1,#points-1 do leg(points[i],points[i+1],width) end end
local function distanceToSegment(pos,a,b)
    local d=b-a local t=math.clamp((pos-a):Dot(d)/d:Dot(d),0,1)
    return (pos-(a+d*t)).Magnitude
end
local function reserved(pos,margin)
    for i,h in hubs do
        local half=i==1 and 520 or 230
        if math.abs(pos.X-h.X)<half+margin and math.abs(pos.Z-h.Z)<half+margin then return true end
    end
    for _,v in roadLegs do if distanceToSegment(pos,v[1],v[2])<margin+v[3]/2 then return true end end
    return false
end
local function bridge(z,name)
    local x=riverX(z)
    local f=folder(bridges,name)
    part(f,"Deck",Vector3.new(172,1.5,24),Vector3.new(x,5,z),wood)
    for _,s in {-1,1} do
        part(f,"Ramp",Vector3.new(52,1,24),CFrame.new(x+s*111,2.5,z)*CFrame.Angles(0,0,-s*math.atan(5/52)),wood)
        part(f,"Rail",Vector3.new(172,2,.65),Vector3.new(x,9,z+s*12),wood)
        for dx=-80,80,20 do
            part(f,"RailPost",Vector3.new(.8,5,.8),Vector3.new(x+dx,7,z+s*12),wood)
            part(f,"BridgePier",Vector3.new(4,38,4),Vector3.new(x+dx,-13,z+s*9),wood)
        end
    end
    return Vector3.new(x-137,0,z),Vector3.new(x+137,0,z)
end
local eastA,eastB=bridge(1000,"MillbridgeCrossing")
local northA,northB=bridge(-2800,"NorthRoadCrossing")
path({city,Vector3.new(city.X,0,600),Vector3.new(-2300,0,1500),south},24)
path({city,Vector3.new(-500,0,city.Z),Vector3.new(-250,0,1000),eastA},24)
path({eastB,east},24)
path({city,Vector3.new(city.X,0,-2800),northA},24)
path({northB,Vector3.new(north.X,0,-2800),north},24)
print("MAP_BUILD_PHASE","Ground footprint")
-- Uniform, shallow chunks compress well; avoid a huge dense Lua voxel table.
for x=-HALF,HALF-1,1024 do
    for z=-HALF,HALF-1,1024 do terrain:FillBlock(CFrame.new(x+512,-12,z+512),Vector3.new(1024,24,1024),Enum.Material.Grass) end
    task.wait()
end
print("MAP_BUILD_PHASE","Hills")
local hillCount=0
for i=1,165 do
    local pos=Vector3.new(rng:NextNumber(-HALF+350,HALF-350),0,rng:NextNumber(-HALF+350,HALF-350))
    local radius=rng:NextNumber(100,225)
    if not reserved(pos,radius+80) and math.abs(pos.X-riverX(pos.Z))>radius+120 then
        local rise=radius*rng:NextNumber(.38,.63)
        terrain:FillBall(pos+Vector3.new(0,-radius+rise,0),radius,Enum.Material.Grass)
        hillCount+=1
    end
    if i%12==0 then task.wait() end
end
local function channel(a,b,width)
    local mid=(a+b)/2 local length=(a-b).Magnitude+16
    local direction=Vector3.new(b.X,0,b.Z)
    local cf=CFrame.lookAt(Vector3.new(mid.X,0,mid.Z),direction)
    terrain:FillBlock(cf*CFrame.new(0,-40,0),Vector3.new(width+12,16,length),Enum.Material.Rock)
    terrain:FillBlock(cf*CFrame.new(0,-4,0),Vector3.new(width+44,12,length),Enum.Material.Sand)
    terrain:FillBlock(cf*CFrame.new(0,-8,0),Vector3.new(width,48,length),Enum.Material.Air)
    terrain:FillBlock(cf*CFrame.new(0,-17,0),Vector3.new(width-8,28,length),Enum.Material.Water)
end
print("MAP_BUILD_PHASE","Rivers")
for z=-HALF,HALF-1,160 do
    local nextZ=math.min(z+160,HALF)
    channel(Vector3.new(riverX(z),0,z),Vector3.new(riverX(nextZ),0,nextZ),108)
    if z%640==0 then task.wait() end
end
local tributary={Vector3.new(-6000,0,4200),Vector3.new(-4400,0,4900),Vector3.new(-2500,0,5100),Vector3.new(-800,0,4700),Vector3.new(riverX(4700),0,4700)}
for i=1,#tributary-1 do channel(tributary[i],tributary[i+1],54) end
terrain:FillCylinder(CFrame.new(-4700,-40,-1400),16,245,Enum.Material.Rock)
terrain:FillCylinder(CFrame.new(-4700,-8,-1400),48,230,Enum.Material.Air)
terrain:FillCylinder(CFrame.new(-4700,-17,-1400),28,225,Enum.Material.Water)
terrain.WaterColor=Color3.fromRGB(61,103,110) terrain.WaterTransparency=.38 terrain.WaterWaveSize=.16 terrain.WaterWaveSpeed=7
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(100,118,64))
terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(121,104,75))
local function house(parent,name,pos,w,d,roofColor,angle,height)
    local m=Instance.new("Model") m.Name=name m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=parent
    local h=height or 16 local rise=w*.24
    local floor=part(m,"Foundation",Vector3.new(w+1,1,d+1),Vector3.new(0,.5,0),stone,Enum.Material.Cobblestone)
    m.PrimaryPart=floor
    part(m,"BackWall",Vector3.new(w,h,.8),Vector3.new(0,1+h/2,-d/2),plaster,Enum.Material.Plaster)
    for _,s in {-1,1} do
        part(m,"SideWall",Vector3.new(.8,h,d),Vector3.new(s*w/2,1+h/2,0),plaster,Enum.Material.Plaster)
        part(m,"FrontWall",Vector3.new((w-7)/2,h,.8),Vector3.new(s*(w+7)/4,1+h/2,d/2),plaster,Enum.Material.Plaster)
        for _,z in {-d/2,d/2} do part(m,"Timber",Vector3.new(.8,h+1,.9),Vector3.new(s*w/2,1+h/2,z),wood) end
        part(m,"Roof",Vector3.new(w*.58,.7,d+5),CFrame.new(s*w*.25,h+1+rise/2,0)*CFrame.Angles(0,0,-s*math.atan(rise/(w/2))),roofColor)
        for _,z in {-d/2,d/2} do
            part(m,"Gable",Vector3.new(.8,rise,w/2),CFrame.new(s*w/4,h+1+rise/2,z)*CFrame.Angles(0,s*math.pi/2,0),plaster,Enum.Material.Plaster,"WedgePart")
        end
        part(m,"Window",Vector3.new(3.6,4,.3),Vector3.new(s*w*.32,h*.6,d/2+.6),Color3.fromRGB(45,48,40),Enum.Material.Wood)
        part(m,"WindowBar",Vector3.new(.35,4.3,.4),Vector3.new(s*w*.32,h*.6,d/2+.8),wood)
    end
    part(m,"Lintel",Vector3.new(7,h-7,.9),Vector3.new(0,8+(h-7)/2,d/2),wood)
    part(m,"HorizontalBeam",Vector3.new(w,.7,1),Vector3.new(0,h*.68,d/2+.5),wood)
    part(m,"Chimney",Vector3.new(3,9,3),Vector3.new(w*.27,h+rise*.65,-d*.23),stone,Enum.Material.Brick)
    m:PivotTo(CFrame.new(pos+Vector3.new(0,.5,0))*CFrame.Angles(0,angle or 0,0))
    return m
end
local function fence(parent,a,b)
    local n=math.ceil((b-a).Magnitude/18)
    local cf=CFrame.lookAt((a+b)/2+Vector3.new(0,3,0),b+Vector3.new(0,3,0))
    part(parent,"FenceRail",Vector3.new(.5,1,(b-a).Magnitude),cf,wood)
    for i=0,n do part(parent,"FencePost",Vector3.new(.7,5,.7),a:Lerp(b,i/n)+Vector3.new(0,2.5,0),wood) end
end
local function farm(parent,center,w,d)
    local f=folder(fields,parent.Name.."_Fields")
    for i=1,5 do
        part(f,"CultivatedStrip",Vector3.new(w,.2,d/6),center+Vector3.new(0,.12,-d/2+i*d/6),Color3.fromRGB(126+i*6,111+i*4,65),i%2==0 and Enum.Material.Ground or Enum.Material.Grass)
        for j=1,12 do
            part(f,"CropRow",Vector3.new(.8,1.8,d/7),center+Vector3.new(-w/2+j*w/13,1,-d/2+i*d/6),Color3.fromRGB(174,151,78),Enum.Material.Grass)
        end
    end
    fence(f,center+Vector3.new(-w/2-5,0,-d/2),center+Vector3.new(-w/2-5,0,d/2))
    fence(f,center+Vector3.new(w/2+5,0,-d/2),center+Vector3.new(w/2+5,0,d/2))
end
print("MAP_BUILD_PHASE","City and villages")
local cityFolder=folder(settlements,"Crownford") cityFolder:SetAttribute("Kind","City") cityFolder:SetAttribute("Center",city)
local roofs={Color3.fromRGB(112,69,47),Color3.fromRGB(99,84,61),Color3.fromRGB(112,103,78),Color3.fromRGB(89,83,76)}
for ix=-4,4 do
    for iz=-4,4 do
        if ix~=0 and iz~=0 and not (math.abs(ix)<=1 and math.abs(iz)<=1) then
            local pos=city+Vector3.new(ix*79,0,iz*79)
            house(cityFolder,"Townhouse_"..ix.."_"..iz,pos,rng:NextInteger(28,39),rng:NextInteger(30,43),roofs[rng:NextInteger(1,#roofs)],ix>0 and -math.pi/2 or math.pi/2,rng:NextInteger(16,23))
        end
    end
end
part(cityFolder,"MarketSquare",Vector3.new(150,.35,150),city+Vector3.new(0,.3,0),stone,Enum.Material.Cobblestone)
for i=-2,2 do
    local x=city.X+i*26
    part(cityFolder,"MarketStall",Vector3.new(16,4,6),Vector3.new(x,2,city.Z+43),wood)
    for _,s in {-1,1} do part(cityFolder,"MarketPost",Vector3.new(.6,12,.6),Vector3.new(x+s*8,6,city.Z+43),wood) end
    part(cityFolder,"MarketCanopy",Vector3.new(19,.5,11),Vector3.new(x,12,city.Z+43),i%2==0 and Color3.fromRGB(132,109,65) or Color3.fromRGB(123,66,46),Enum.Material.Fabric)
end
local well=part(cityFolder,"Well",Vector3.new(9,3,9),city+Vector3.new(0,1.5,0),stone,Enum.Material.Cobblestone)
well.Shape=Enum.PartType.Cylinder well.Size=Vector3.new(3,9,9) well.CFrame=CFrame.new(city+Vector3.new(0,1.5,0))*CFrame.Angles(0,0,math.pi/2)
for _,s in {-1,1} do part(cityFolder,"WellPost",Vector3.new(.7,13,.7),city+Vector3.new(s*6,6.5,0),wood) end
part(cityFolder,"WellRoof",Vector3.new(17,.8,12),city+Vector3.new(0,13,0),wood)
for _,axis in {"X","Z"} do
    for _,side in {-1,1} do
        for _,section in {-1,1} do
            local pos=city+(axis=="X" and Vector3.new(side*420,13,section*226) or Vector3.new(section*226,13,side*420))
            part(cityFolder,"CityWall",axis=="X" and Vector3.new(8,26,388) or Vector3.new(388,26,8),pos,stone,Enum.Material.Cobblestone)
        end
        for i=-20,20 do
            if math.abs(i)>1 then part(cityFolder,"Merlon",Vector3.new(7,4,7),city+(axis=="X" and Vector3.new(side*420,28,i*20) or Vector3.new(i*20,28,side*420)),stone,Enum.Material.Cobblestone) end
        end
    end
end
for _,x in {-420,420} do for _,z in {-420,420} do
    local at=city+Vector3.new(x,0,z)
    part(cityFolder,"CornerTower",Vector3.new(29,55,29),at+Vector3.new(0,27.5,0),stone,Enum.Material.Cobblestone)
    for _,dx in {-11,0,11} do for _,dz in {-11,11} do part(cityFolder,"TowerMerlon",Vector3.new(6,5,6),at+Vector3.new(dx,57,dz),stone,Enum.Material.Cobblestone) end end
end end
label(cityFolder,"КРОУНФОРД",city+Vector3.new(0,18,421),30)
path({city+Vector3.new(-442,0,0),city+Vector3.new(442,0,0)},28)
path({city+Vector3.new(0,0,-442),city+Vector3.new(0,0,442)},28)
house(cityFolder,"TownHall",city+Vector3.new(0,0,-190),75,60,roofs[1],0,30)
farm(cityFolder,city+Vector3.new(-260,0,720),240,200)
local villageData={{"Oakmere","ДУБРАВА",south,15},{"Millbridge","МЕЛЬНИЧНЫЙ БРОД",east,12},{"Highfield","ВЫСЕЛКИ",north,11}}
for _,data in villageData do
    local f=folder(settlements,data[1]) f:SetAttribute("Kind","Village") f:SetAttribute("Center",data[3])
    local center=data[3]
    for i=1,data[4] do
        local side=i%2==0 and -1 or 1 local row=math.ceil(i/2)
        house(f,"Cottage_"..i,center+Vector3.new(side*(48+(row%2)*24),0,(row-4)*52),rng:NextInteger(25,33),rng:NextInteger(28,38),roofs[(i%#roofs)+1],side>0 and -math.pi/2 or math.pi/2,14)
    end
    path({center+Vector3.new(0,0,-240),center+Vector3.new(0,0,240)},18)
    label(f,data[2],center+Vector3.new(0,9,225),30)
    house(f,"Barn",center+Vector3.new(155,0,105),54,44,roofs[3],0,21)
    farm(f,center+Vector3.new(240,0,-100),220,200)
end
-- Windmill landmark; deliberately static scenery in this map-only version.
local mill=settlements.Millbridge
local millAt=east+Vector3.new(-145,0,90)
part(mill,"WindmillBase",Vector3.new(20,42,20),millAt+Vector3.new(0,21,0),plaster,Enum.Material.Plaster)
for i=0,3 do
    part(mill,"WindmillSail",Vector3.new(3,31,.8),CFrame.new(millAt+Vector3.new(0,33,11))*CFrame.Angles(0,0,i*math.pi/2+math.pi/4)*CFrame.new(0,13,0),Color3.fromRGB(188,175,139),Enum.Material.WoodPlanks)
end
print("MAP_BUILD_PHASE","Forests")
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={terrain}
local patches={
    {Vector3.new(-2350,0,-650),750,450}, {Vector3.new(-4700,0,-3800),1200,400},
    {Vector3.new(-4600,0,3600),1050,400}, {Vector3.new(4100,0,-4300),1250,450},
    {Vector3.new(4300,0,2300),1100,450}, {Vector3.new(5100,0,5100),1000,350},
    {Vector3.new(-1400,0,5700),1000,350}, {Vector3.new(-100,0,-5200),950,350},
}
local treeCount=0
for index,patch in patches do
    local f=folder(forest,"Forest_"..index)
    for i=1,patch[3] do
        local angle=rng:NextNumber(0,math.pi*2) local radius=math.sqrt(rng:NextNumber())*patch[2]
        local pos=patch[1]+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
        if not reserved(pos,35) then
            local hit=W:Raycast(pos+Vector3.new(0,1024,0),Vector3.new(0,-2048,0),ray)
            if hit and hit.Material~=Enum.Material.Water and hit.Normal.Y>.75 then
                local model=Instance.new("Model") model.Name=i%4==0 and "Conifer" or "Oak" model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model.Parent=f
                local at=hit.Position local h=rng:NextNumber(30,62)
                local trunk=part(model,"Trunk",Vector3.new(h,2.5,2.5),CFrame.new(at+Vector3.new(0,h/2,0))*CFrame.Angles(0,0,math.pi/2),wood,Enum.Material.Wood)
                trunk.Shape=Enum.PartType.Cylinder
                for level=1,3 do
                    local s=(i%4==0 and (33-level*5) or (27+level*2))*rng:NextNumber(.85,1.1)
                    local leaves=part(model,"Canopy",Vector3.new(s,i%4==0 and 17 or s*.72,s),at+Vector3.new((i%4==0 and 0 or level-2)*5,h-7+level*8,0),Color3.fromRGB(48+level*5,75+level*7,41+level*3),Enum.Material.Grass)
                    leaves.Shape=Enum.PartType.Ball leaves.CanCollide=false leaves.CanTouch=false leaves.CanQuery=false
                end
                treeCount+=1
            end
        end
        if i%80==0 then task.wait() end
    end
end
local spawn=Instance.new("SpawnLocation") spawn.Name="ExplorationSpawn" spawn.Size=Vector3.new(8,.2,8)
spawn.CFrame=CFrame.new(city+Vector3.new(0,1,465)) spawn.Anchored=true spawn.Neutral=true spawn.Enabled=true
spawn.Transparency=1 spawn.CanCollide=false spawn.CanTouch=false spawn.CanQuery=false spawn.Duration=0 spawn.Parent=map
local starter=game:GetService("StarterPlayer")
starter.CharacterWalkSpeed=22 starter.CharacterUseJumpPower=true starter.CharacterJumpPower=50
starter.LoadCharacterAppearance=true starter.CameraMode=Enum.CameraMode.Classic starter.CameraMinZoomDistance=.5 starter.CameraMaxZoomDistance=45
local players=game:GetService("Players") players.CharacterAutoLoads=true players.RespawnTime=3
W.StreamingEnabled=true W.FallenPartsDestroyHeight=-200
local lighting=game:GetService("Lighting") lighting.ClockTime=14 lighting.Brightness=2 lighting.GlobalShadows=true
lighting.Ambient=Color3.fromRGB(108,111,93) lighting.OutdoorAmbient=Color3.fromRGB(139,145,121)
local atmo=lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",lighting)
atmo.Density=.22 atmo.Offset=.15 atmo.Color=Color3.fromRGB(204,210,188) atmo.Decay=Color3.fromRGB(130,143,111)
-- Paint terrain below roads/floors so decorative terrain grass does not grow through them.
local terrain=workspace.Terrain
local map=workspace.Map
for _,v in map.Roads:GetChildren() do
    if v:IsA("BasePart") then
        terrain:FillBlock(v.CFrame*CFrame.new(0,-2.25,0),Vector3.new(v.Size.X+2,4,v.Size.Z),Enum.Material.Ground)
    end
end
for _,v in map.Settlements:GetDescendants() do
    if v:IsA("BasePart") and (v.Name=="Foundation" or v.Name=="MarketSquare") then
        terrain:FillBlock(v.CFrame*CFrame.new(0,-v.Position.Y-2,0),Vector3.new(v.Size.X+2,4,v.Size.Z+2),v.Name=="MarketSquare" and Enum.Material.Cobblestone or Enum.Material.Ground)
    end
end
for _,v in map.Fields:GetDescendants() do
    if v:IsA("BasePart") and v.Name=="CultivatedStrip" then terrain:FillBlock(v.CFrame*CFrame.new(0,-2.12,0),Vector3.new(v.Size.X,4,v.Size.Z),Enum.Material.Ground) end
end
print("MAP_SURFACES_FINISHED")

map:SetAttribute("HillCount",hillCount) map:SetAttribute("TreeCount",treeCount) map:SetAttribute("BuildComplete",true)
print("MAP_ONLY_BUILD_OK",treeCount,"trees",hillCount,"hills",HALF*2,"studs wide; no custom runtime scripts")
