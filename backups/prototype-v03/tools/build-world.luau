-- Studio edit-time world generation. Preserves the existing forest clearing.
assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local function folder(parent,name)
    local v=parent:FindFirstChild(name)
    if v then return v end
    v=Instance.new("Folder") v.Name=name v.Parent=parent return v
end
local map=folder(workspace,"Map")
local generated=map:FindFirstChild("CrownlandsPrototype")
if generated then generated:Destroy() end
local world=Instance.new("Model") world.Name="CrownlandsPrototype" world.Parent=map
local points=folder(workspace,"InteractionPoints")
local oldPoints=points:FindFirstChild("Crownlands") if oldPoints then oldPoints:Destroy() end
points=folder(points,"Crownlands")
local npcs=folder(workspace,"NPCs")
for _,v in npcs:GetChildren() do if v:GetAttribute("Crownlands") then v:Destroy() end end
for _,name in {"NPCSpawns","ResourceNodes","SafeZones","EnemySpawns"} do folder(workspace,name) end
local wood=Color3.fromRGB(89,64,45)
local plaster=Color3.fromRGB(181,166,130)
local stone=Color3.fromRGB(117,120,113)
local function p(parent,name,size,cf,color,material)
    local v=Instance.new("Part") v.Name=name v.Size=size v.CFrame=typeof(cf)=="Vector3" and CFrame.new(cf) or cf
    v.Color=color v.Material=material or Enum.Material.WoodPlanks v.Anchored=true
    v.TopSurface=Enum.SurfaceType.Smooth v.BottomSurface=Enum.SurfaceType.Smooth
    v.Parent=parent return v
end
local function group(name) return folder(world,name) end
local function text(part,words)
    for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
        local gui=Instance.new("SurfaceGui") gui.Face=face gui.PixelsPerStud=40 gui.Parent=part
        local t=Instance.new("TextLabel") t.Size=UDim2.fromScale(1,1) t.BackgroundTransparency=1 t.Font=Enum.Font.Garamond
        t.TextColor3=Color3.fromRGB(242,221,167) t.TextScaled=true t.Text=words t.Parent=gui
    end
end
local function sign(parent,name,pos,width)
    local v=p(parent,"Sign",Vector3.new(width or 14,2.5,.35),pos,wood)
    text(v,name) return v
end
local function road(a,b,width)
    local mid=(a+b)/2 local distance=(a-b).Magnitude
    p(group("Roads"),"DirtRoad",Vector3.new(width or 10,.15,distance),CFrame.lookAt(Vector3.new(mid.X,.12,mid.Z),Vector3.new(b.X,.12,b.Z)),Color3.fromRGB(130,112,84),Enum.Material.Ground)
end
local function light(parent,pos)
    p(parent,"LanternPost",Vector3.new(.6,6,.6),pos+Vector3.new(0,3,0),wood)
    local bulb=p(parent,"Lantern",Vector3.new(1,1.4,1),pos+Vector3.new(0,6,0),Color3.fromRGB(255,198,102),Enum.Material.Neon)
    local glow=Instance.new("PointLight") glow.Color=bulb.Color glow.Range=18 glow.Brightness=1 glow.Parent=bulb
end
local function prompt(name,pos,action,dialogue)
    local v=p(points,name,Vector3.new(3,3,3),pos,wood)
    v.Transparency=1 v.CanCollide=false v.CanQuery=false
    local pr=Instance.new("ProximityPrompt") pr.ActionText=action=="Water" and "Напиться" or (action=="Rest" and "Отдохнуть" or (action=="Training" and "Взять учебный меч и щит" or "Осмотреть / поговорить"))
    pr.ObjectText=name pr.HoldDuration=.45 pr.MaxActivationDistance=10 pr.RequiresLineOfSight=true
    pr:SetAttribute("Action",action) pr:SetAttribute("Dialogue",dialogue or "") pr.Parent=v return pr
end
local function house(parent,name,x,z,w,d,color)
    local f=folder(parent,name)
    p(f,"Foundation",Vector3.new(w+1,1,d+1),Vector3.new(x,.5,z),stone,Enum.Material.Cobblestone)
    p(f,"BackWall",Vector3.new(w,10,.7),Vector3.new(x,6,z-d/2),plaster,Enum.Material.Plaster)
    for _,s in {-1,1} do
        p(f,"SideWall",Vector3.new(.7,10,d),Vector3.new(x+s*w/2,6,z),plaster,Enum.Material.Plaster)
        p(f,"DoorWall",Vector3.new((w-5)/2,10,.7),Vector3.new(x+s*(w+5)/4,6,z+d/2),plaster,Enum.Material.Plaster)
        for _,dz in {-d/2,d/2} do p(f,"TimberPost",Vector3.new(.7,11,.7),Vector3.new(x+s*w/2,6,z+dz),wood) end
        p(f,"RoofSlope",Vector3.new(w*.56,.8,d+4),CFrame.new(x+s*w*.245,12.2,z)*CFrame.Angles(0,0,-s*math.rad(25)),color,Enum.Material.WoodPlanks)
    end
    p(f,"DoorLintel",Vector3.new(5,3,.7),Vector3.new(x,9.5,z+d/2),wood)
    p(f,"HorizontalBeam",Vector3.new(w, .6,.8),Vector3.new(x,6,z+d/2+.1),wood)
    sign(f,name,Vector3.new(x,8,z+d/2+.6),math.min(w-1,14))
    return f
end
local base=workspace:FindFirstChild("Baseplate")
if base then base.Size=Vector3.new(760,16,760) base.Position=Vector3.new(0,-8.05,0) base.Color=Color3.fromRGB(86,109,59) base.Material=Enum.Material.Grass end
local clearing=workspace:FindFirstChild("MedievalClearing") or map:FindFirstChild("MedievalClearing")
if clearing then
    if not clearing:GetAttribute("CrownlandsMoved") then clearing:PivotTo(clearing:GetPivot()+Vector3.new(-210,0,0)) clearing:SetAttribute("CrownlandsMoved",true) end
    clearing.Parent=map
    for _,v in clearing:GetDescendants() do if v:IsA("SpawnLocation") then v.Enabled=false end end
end
local village=group("Village")
p(village,"MarketSquare",Vector3.new(79,.12,68),Vector3.new(0,.13,0),Color3.fromRGB(137,128,104),Enum.Material.Cobblestone)
road(Vector3.new(0,0,60),Vector3.new(0,0,-165),12)
road(Vector3.new(-210,0,35),Vector3.new(210,0,35),10)
road(Vector3.new(210,0,35),Vector3.new(210,0,-155),8)
road(Vector3.new(0,0,0),Vector3.new(-60,0,-42),9)
road(Vector3.new(0,0,0),Vector3.new(58,0,-42),9)
for i=1,4 do house(village,"Дом "..i,i%2==0 and 65 or -65,55+math.floor((i-1)/2)*40,22,19,Color3.fromRGB(105,72,47)) end
local tavern=house(village,"Таверна «Три колоса»",-57,-42,32,27,Color3.fromRGB(115,65,42))
for _,x in {-65,-48} do
    p(tavern,"Table",Vector3.new(7,.5,4),Vector3.new(x,3,-40),wood)
    p(tavern,"TableSupport",Vector3.new(2,2.5,2),Vector3.new(x,1.75,-40),wood)
    for _,z in {-36,-44} do
        local seat=Instance.new("Seat") seat.Name="TavernSeat" seat.Size=Vector3.new(5,1,2) seat.Position=Vector3.new(x,2,z) seat.Anchored=true seat.Color=wood seat.Material=Enum.Material.WoodPlanks seat.Parent=tavern
    end
end
local hearth=p(tavern,"Hearth",Vector3.new(4,1,3),Vector3.new(-57,1,-52),stone,Enum.Material.Slate)
local fire=Instance.new("Fire") fire.Size=3 fire.Heat=4 fire.Parent=hearth
prompt("Таверна — отдых",Vector3.new(-57,3,-49),"Rest")
prompt("Доска объявлений",Vector3.new(-49,3,-25),"Board")
local board=p(village,"NoticeBoard",Vector3.new(7,5,.5),Vector3.new(-49,3,-26),wood) text(board,"ОБЪЯВЛЕНИЯ\nТренировочный двор → за мостом")
local forge=house(village,"Кузница",55,-42,27,24,Color3.fromRGB(76,75,70))
p(forge,"Furnace",Vector3.new(6,5,5),Vector3.new(62,3,-48),stone,Enum.Material.Brick)
local coals=p(forge,"HotCoals",Vector3.new(3,.3,3),Vector3.new(62,5.7,-48),Color3.fromRGB(255,115,39),Enum.Material.Neon)
local ff=Instance.new("Fire") ff.Size=3 ff.Heat=3 ff.Parent=coals
p(forge,"AnvilBase",Vector3.new(2.5,2,2.5),Vector3.new(50,1.5,-41),wood)
p(forge,"Anvil",Vector3.new(5,1,2),Vector3.new(50,3,-41),Color3.fromRGB(65,68,69),Enum.Material.Metal)
local well=folder(village,"Well")
for i=1,12 do
    local a=i/12*math.pi*2
    p(well,"WellStone",Vector3.new(2,2.5,2),CFrame.new(math.sin(a)*4,1.5,math.cos(a)*4)*CFrame.Angles(0,a,0),stone,Enum.Material.Cobblestone)
end
p(well,"Water",Vector3.new(6,.3,6),Vector3.new(0,.5,0),Color3.fromRGB(66,117,126),Enum.Material.Glass)
for _,x in {-5,5} do p(well,"Post",Vector3.new(.6,9,.6),Vector3.new(x,4.5,0),wood) end
p(well,"WellRoof",Vector3.new(13,.7,9),Vector3.new(0,9,0),wood)
prompt("Колодец",Vector3.new(0,2,6),"Water")
local market=group("Market")
for i=1,3 do
    local x=-28+(i-1)*27
    p(market,"StallCounter",Vector3.new(10,3,5),Vector3.new(x,1.6,21),wood)
    for _,dx in {-5,5} do p(market,"StallPost",Vector3.new(.5,8,.5),Vector3.new(x+dx,4,21),wood) end
    p(market,"Canopy",Vector3.new(12,.4,8),Vector3.new(x,8,21),i%2==0 and Color3.fromRGB(119,63,48) or Color3.fromRGB(148,132,84),Enum.Material.Fabric)
    for j=1,4 do p(market,"ProduceCrate",Vector3.new(1.5,1,1.5),Vector3.new(x-4+j*1.6,3.6,21),Color3.fromRGB(148,103,47)) end
end
local castle=group("Castle")
p(castle,"Courtyard",Vector3.new(84,.2,70),Vector3.new(0,.15,-178),stone,Enum.Material.Cobblestone)
for _,x in {-42,42} do
    p(castle,"CurtainWall",Vector3.new(4,18,74),Vector3.new(x,9,-178),stone,Enum.Material.Cobblestone)
    for _,z in {-214,-142} do
        p(castle,"Tower",Vector3.new(14,25,14),Vector3.new(x,12.5,z),stone,Enum.Material.Cobblestone)
        for i=-1,1 do p(castle,"Merlon",Vector3.new(3,3,3),Vector3.new(x+i*4,26,z-5),stone,Enum.Material.Cobblestone) end
    end
end
p(castle,"NorthWall",Vector3.new(88,18,4),Vector3.new(0,9,-215),stone,Enum.Material.Cobblestone)
for _,x in {-27,27} do p(castle,"GateWall",Vector3.new(30,18,4),Vector3.new(x,9,-142),stone,Enum.Material.Cobblestone) end
house(castle,"Казарма",0,-196,34,20,Color3.fromRGB(83,82,78))
sign(castle,"КРЕПОСТЬ КОРОНЫ",Vector3.new(0,17,-139),20)
local river=group("River")
local water=p(river,"RiverWater",Vector3.new(23,2,510),Vector3.new(112,-.5,-10),Color3.fromRGB(59,119,127),Enum.Material.Glass) water.Transparency=.22 water.CanCollide=false
for _,x in {98,126} do p(river,"RiverBank",Vector3.new(5,.3,510),Vector3.new(x,.15,-10),Color3.fromRGB(137,129,97),Enum.Material.Sand) end
local bridge=group("Bridge")
p(bridge,"BridgeDeck",Vector3.new(34,1,15),Vector3.new(112,1,35),wood)
for _,z in {28,42} do
    p(bridge,"BridgeRail",Vector3.new(34,.5,.5),Vector3.new(112,4,z),wood)
    for x=96,128,8 do p(bridge,"BridgePost",Vector3.new(.7,4,.7),Vector3.new(x,2.5,z),wood) end
end
local farm=group("Farm")
house(farm,"Амбар",211,100,32,25,Color3.fromRGB(127,81,44))
for row=1,4 do
    p(farm,"TilledSoil",Vector3.new(40,.2,5),Vector3.new(211,.2,46+row*8),Color3.fromRGB(91,67,44),Enum.Material.Ground)
    for col=1,12 do p(farm,"Wheat",Vector3.new(.35,3,.35),CFrame.new(190+col*3.5,1.8,46+row*8)*CFrame.Angles(0,0,.12),Color3.fromRGB(192,162,75),Enum.Material.Grass) end
end
for _,x in {182,239} do p(farm,"Fence",Vector3.new(.7,2,54),Vector3.new(x,2,63),wood) end
local camp=group("BanditCamp")
for _,x in {192,221} do
    local tent=folder(camp,"Tent_"..x)
    for _,s in {-1,1} do p(tent,"Canvas",Vector3.new(8,.4,13),CFrame.new(x+s*2.8,3,-160)*CFrame.Angles(0,0,-s*math.rad(40)),Color3.fromRGB(101,91,65),Enum.Material.Fabric) end
end
sign(camp,"ОПАСНО • РАЗБОЙНИКИ",Vector3.new(210,5,-126),20)
local training=group("TrainingGround")
p(training,"TrainingSoil",Vector3.new(46,.1,42),Vector3.new(170,.15,-35),Color3.fromRGB(140,119,85),Enum.Material.Ground)
sign(training,"УЧЕБНЫЙ ДВОР",Vector3.new(170,6,-13),20)
prompt("Стойка учебного оружия",Vector3.new(151,3,-20),"Training")
p(training,"WeaponRack",Vector3.new(7,4,1),Vector3.new(151,2,-23),wood)
local function rig(name,pos,color,hostile,dummy)
    local m=Instance.new("Model") m.Name=name m:SetAttribute("Crownlands",true) m:SetAttribute("Hostile",hostile) m:SetAttribute("TrainingDummy",dummy or false)
    local parts={}
    local specs={HumanoidRootPart={Vector3.new(2,2,1),Vector3.zero},Torso={Vector3.new(2,2,1),Vector3.zero},Head={Vector3.new(2,1,1),Vector3.new(0,1.5,0)},["Left Arm"]={Vector3.new(1,2,1),Vector3.new(-1.5,0,0)},["Right Arm"]={Vector3.new(1,2,1),Vector3.new(1.5,0,0)},["Left Leg"]={Vector3.new(1,2,1),Vector3.new(-.5,-2,0)},["Right Leg"]={Vector3.new(1,2,1),Vector3.new(.5,-2,0)}}
    for n,v in specs do
        local part=Instance.new("Part") part.Name=n part.Size=v[1] part.Position=pos+v[2] part.Color=n=="Head" and Color3.fromRGB(198,164,125) or color
        part.TopSurface=Enum.SurfaceType.Smooth part.BottomSurface=Enum.SurfaceType.Smooth
        part.CanCollide=n=="Torso" part.Anchored=n=="HumanoidRootPart" and (not hostile or dummy)
        if n=="HumanoidRootPart" then part.Transparency=1 part.CanCollide=false end
        part.Parent=m parts[n]=part
    end
    local function joint(name,a,b,c0,c1)
        local j=Instance.new("Motor6D") j.Name=name j.Part0=parts[a] j.Part1=parts[b] j.C0=c0 j.C1=c1 j.Parent=parts[a]
    end
    joint("RootJoint","HumanoidRootPart","Torso",CFrame.new(),CFrame.new())
    joint("Neck","Torso","Head",CFrame.new(0,1,0),CFrame.new(0,-.5,0))
    joint("Left Shoulder","Torso","Left Arm",CFrame.new(-1, .5,0),CFrame.new(.5,.5,0))
    joint("Right Shoulder","Torso","Right Arm",CFrame.new(1,.5,0),CFrame.new(-.5,.5,0))
    joint("Left Hip","Torso","Left Leg",CFrame.new(-.5,-1,0),CFrame.new(0,1,0))
    joint("Right Hip","Torso","Right Leg",CFrame.new(.5,-1,0),CFrame.new(0,1,0))
    local h=Instance.new("Humanoid") h.DisplayName=name h.MaxHealth=dummy and 80 or 60 h.Health=h.MaxHealth h.WalkSpeed=10 h.Parent=m
    m.PrimaryPart=parts.HumanoidRootPart m.Parent=npcs
    if dummy then parts.HumanoidRootPart.CFrame=CFrame.new(pos)*CFrame.Angles(0,math.pi,0) end
    return m
end
rig("Учебный противник",Vector3.new(170,3,-36),Color3.fromRGB(119,98,62),true,true)
for i=1,2 do rig("Разбойник "..i,Vector3.new(202+i*8,3,-150),Color3.fromRGB(89,66,58),true,false) end
local civilians={
    {"Торговец Мирек",Vector3.new(-27,3,17),"Здесь торгуют урожаем и ремесленными товарами. Торговля появится на этапе экономики."},
    {"Кузнец Радек",Vector3.new(47,3,-34),"Кузница работает на угле. Руда и заготовки понадобятся нам для будущих заказов."},
    {"Трактирщица Марта",Vector3.new(-57,3,-33),"Отдохните у очага. Колодец на площади даёт чистую воду."},
    {"Стражник Северин",Vector3.new(8,3,-131),"Деревня и рынок — безопасная зона. За мостом будьте осторожны."},
    {"Фермер Бартол",Vector3.new(183,3,43),"Наши поля кормят Crownlands. У моста — учебный двор, севернее — разбойники."},
    {"Охотник Лешек",Vector3.new(-139,3,35),"На западе лесной привал. Держитесь тропы — так быстрее добраться до деревни."},
}
for _,v in civilians do rig(v[1],v[2],Color3.fromRGB(102,92,68),false) prompt(v[1],v[2]+Vector3.new(0,1,0),v[1]=="Торговец Мирек" and "Merchant" or (v[1]=="Кузнец Радек" and "SmithQuest" or "Talk"),v[3]) end
for _,pos in {Vector3.new(-12,0,38),Vector3.new(12,0,38),Vector3.new(-25,0,-25),Vector3.new(25,0,-25),Vector3.new(95,0,35),Vector3.new(130,0,35),Vector3.new(-6,0,-130)} do light(world,pos) end
local safe=workspace.SafeZones:FindFirstChild("Village") or p(workspace.SafeZones,"Village",Vector3.new(210,30,210),Vector3.new(0,10,0),Color3.new(0,1,0))
safe.Transparency=1 safe.CanCollide=false safe.CanTouch=false safe.CanQuery=false
safe:SetAttribute("Radius",105)
local spawn=world:FindFirstChild("VillageSpawn") or Instance.new("SpawnLocation")
spawn.Name="VillageSpawn" spawn.Size=Vector3.new(8,.2,8) spawn.Position=Vector3.new(0,.3,38)
spawn.Neutral=true spawn.Enabled=true spawn.Anchored=true spawn.Transparency=1 spawn.CanCollide=false spawn.CanQuery=false spawn.Duration=3 spawn.Parent=world
for _,v in workspace:GetDescendants() do if v:IsA("SpawnLocation") and v~=spawn then v.Enabled=false end end
local lighting=game:GetService("Lighting") lighting.ClockTime=14.5 lighting.Brightness=2 lighting.GlobalShadows=true
lighting.Ambient=Color3.fromRGB(112,106,91) lighting.OutdoorAmbient=Color3.fromRGB(139,143,122)
local atmosphere=lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",lighting)
atmosphere.Density=.23 atmosphere.Offset=.1 atmosphere.Color=Color3.fromRGB(204,204,179) atmosphere.Decay=Color3.fromRGB(118,122,101)
workspace.StreamingEnabled=true
-- Streaming radii use Studio defaults; these properties are Not Scriptable.
-- Keep the editor camera unchanged; the player camera is managed by Roblox.
local starter=game:GetService("StarterPlayer") starter.CameraMode=Enum.CameraMode.Classic starter.CameraMaxZoomDistance=35 starter.CharacterWalkSpeed=14 starter.LoadCharacterAppearance=false
print("CROWN_WORLD_OK",#world:GetDescendants(),"objects",#npcs:GetChildren(),"NPCs")

local resources=group("ResourceOutcrops")
for index,data in {
    {"Wood",Vector3.new(-125,1,27),Color3.fromRGB(110,75,45)},
    {"Wood",Vector3.new(-136,1,18),Color3.fromRGB(110,75,45)},
    {"Wood",Vector3.new(-145,1,28),Color3.fromRGB(110,75,45)},
    {"Ore",Vector3.new(-152,1,38),Color3.fromRGB(120,126,128)},
    {"Ore",Vector3.new(-160,1,45),Color3.fromRGB(120,126,128)},
    {"Coal",Vector3.new(-165,1,26),Color3.fromRGB(50,53,51)},
} do
    local node=p(resources,"Resource_"..index,Vector3.new(4,2,3),data[2],data[3],data[1]=="Wood" and Enum.Material.Wood or Enum.Material.Slate)
    local pr=prompt(data[1]=="Wood" and "Собрать древесину" or (data[1]=="Ore" and "Добыть руду" or "Собрать уголь"),data[2]+Vector3.new(0,2,0),"Gather")
    pr.Name="ResourcePrompt_"..index pr:SetAttribute("Resource",data[1]) pr.HoldDuration=1.4
end
