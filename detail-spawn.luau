-- Edit-time scenic pass. Run AFTER build-map.luau, with Play stopped.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play before detailing')
local map=assert(workspace:FindFirstChild('Map'))
local terrain=workspace.Terrain
local old=map:FindFirstChild('SpawnApproach') if old then old:Destroy() end
local scene=Instance.new('Folder') scene.Name='SpawnApproach' scene.Parent=map
local rng=Random.new(42017)
local origin=Vector3.new(-1200,0,-380) -- south city entrance; positive Z is outside
local function at(x,y,z) return origin+Vector3.new(x,y,z) end
local stone=Color3.fromRGB(133,130,111)
local timber=Color3.fromRGB(83,65,45)
local function model(name)
 local m=Instance.new('Model') m.Name=name m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=scene return m
end
local function part(parent,name,size,cf,color,mat,solid)
 local p=Instance.new('Part') p.Name=name p.Size=size p.CFrame=typeof(cf)=='Vector3' and CFrame.new(cf) or cf
 p.Color=color p.Material=mat or Enum.Material.Wood p.Anchored=true p.CanCollide=solid~=false
 p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local function ball(parent,name,size,pos,color,mat,solid)
 local p=part(parent,name,size,pos,color,mat,solid) p.Shape=Enum.PartType.Ball return p
end
local function beam(parent,name,a,b,width,color,mat,solid)
 return part(parent,name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,mat,solid)
end
local function rock(x,z,s)
 local m=model('WeatheredRock')
 local p=ball(m,'Rock',Vector3.new(s*1.5,s*.8,s),at(x,s*.18,z),Color3.fromRGB(119+rng:NextInteger(-12,12),121,103),Enum.Material.Slate)
 p.CFrame*=CFrame.Angles(.2,rng:NextNumber(0,6),.15)
 ball(m,'Moss',Vector3.new(s*1.1,s*.14,s*.7),at(x,s*.55,z),Color3.fromRGB(91,104,53),Enum.Material.Grass,false)
end
-- Local surface only: uneven dirt/gravel footprint blends the spawn into the road.
for z=-30,170,6 do
 local bend=math.sin(z/48)*2
 local width=z<20 and 17 or (z<83 and 16+(83-z)*.10 or 15)
 terrain:FillBlock(CFrame.new(at(bend,-2,z)),Vector3.new(width*2,4,9),Enum.Material.Ground)
 for _,s in {-1,1} do
  local edge=width+rng:NextNumber(-2,3)
  terrain:FillBall(at(bend+s*edge,-4,z+rng:NextNumber(-3,3)),5,Enum.Material.Ground)
 end
end
-- Blend out the ruler-straight original road's edges in this small focal area.
-- Keep the original smooth collision surface; gravel covers its visible center.
for z=-32,130,8 do
 local p=part(scene,'WornGravel',Vector3.new(rng:NextNumber(24,29),.12,10),CFrame.new(at(math.sin(z/48)*2,.51,z))*CFrame.Angles(0,rng:NextNumber(-.035,.035),0),Color3.fromRGB(132+rng:NextInteger(-5,5),118,91),Enum.Material.Ground,false)
end
-- Gentle grassy rises outside the unobstructed central corridor.
for _,v in {{-72,63,33},{83,105,37},{-104,139,44},{112,19,38},{-88,-8,25}} do
 terrain:FillBall(at(v[1],-v[3]+5,v[2]),v[3],Enum.Material.Grass)
end
local function oak(x,z,s)
 local m=model('MeadowOak') local base=at(x,0,z)
 local trunk=part(m,'Trunk',Vector3.new(2.6*s,18*s,2.6*s),base+Vector3.new(0,9*s,0),Color3.fromRGB(99,78,53),Enum.Material.Wood)
 trunk.Shape=Enum.PartType.Cylinder trunk.Size=Vector3.new(18*s,2.6*s,2.6*s) trunk.CFrame=CFrame.new(base+Vector3.new(0,9*s,0))*CFrame.Angles(0,0,math.pi/2)
 for i=1,5 do
  local a=i*math.pi*2/5 local offset=Vector3.new(math.cos(a)*6*s,(15+i%2*3)*s,math.sin(a)*6*s)
  beam(m,'Branch',base+Vector3.new(0,10*s,0),base+offset,1.1*s,timber,Enum.Material.Wood,false)
  ball(m,'LeafCrown',Vector3.new(16*s,12*s,15*s),base+offset+Vector3.new(0,5*s,0),Color3.fromRGB(86+i*4,109+i*3,49+i*2),Enum.Material.Grass,false)
 end
 for i=1,4 do
  local a=i*math.pi/2 beam(m,'Root',base+Vector3.new(0,1,0),base+Vector3.new(math.cos(a)*4*s,.3,math.sin(a)*4*s),1*s,timber,Enum.Material.Wood,false)
 end
end
for _,v in {{-67,55,1.3},{79,92,1.15},{-104,127,1.2},{108,23,1.05},{-61,157,.85},{90,165,1.25},{-126,44,.95},{134,121,1.0}} do oak(v[1],v[2],v[3]) end
local function shrub(x,z,s)
 local m=model('Hedgerow')
 for i=1,4 do
  ball(m,'Leaves',Vector3.new(3.6*s,3.1*s,3.3*s),at(x+(i-2.5)*1.7*s,1.3*s,z+rng:NextNumber(-1,1)),Color3.fromRGB(84+rng:NextInteger(-9,12),106+rng:NextInteger(-9,10),53),Enum.Material.Grass,false)
 end
end
for _,v in {{-35,33,1.5},{-44,50,1.2},{47,69,1.3},{58,95,1.7},{-49,106,1.4},{-68,123,1.1},{72,139,1.3},{-86,13,1.5},{86,9,1.3},{-55,174,1.4}} do shrub(v[1],v[2],v[3]) end
for _,v in {{-42,20,6},{-48,27,3},{62,64,7},{68,71,3},{-73,109,5},{93,137,6},{101,141,3},{-28,137,2.5}} do rock(v[1],v[2],v[3]) end
-- Small meadow flowers clustered along the edge, never a uniform grid.
for patch=1,16 do
 local side=patch%2==0 and -1 or 1 local z=rng:NextNumber(15,170) local x=side*rng:NextNumber(27,64)
 local m=model('Wildflowers')
 for i=1,rng:NextInteger(6,12) do
  local px=x+rng:NextNumber(-7,7) local pz=z+rng:NextNumber(-6,6)
  local y=rng:NextNumber(.8,1.8)
  part(m,'Stem',Vector3.new(.1,y,.1),at(px,y/2,pz),Color3.fromRGB(83,107,48),Enum.Material.Grass,false)
  local color=patch%3==0 and Color3.fromRGB(151,139,174) or (patch%3==1 and Color3.fromRGB(224,209,143) or Color3.fromRGB(220,216,189))
  for k=1,3 do
   part(m,'Petal',Vector3.new(.85,.1,.28),CFrame.new(at(px,y,pz))*CFrame.Angles(0,k*math.pi/3,0),color,Enum.Material.SmoothPlastic,false)
  end
  ball(m,'FlowerCenter',Vector3.new(.23,.18,.23),at(px,y+.08,pz),Color3.fromRGB(192,157,68),Enum.Material.SmoothPlastic,false)
 end
end
-- Wooden roadside fence, with an open break at the clearing.
for _,side in {-1,1} do
 for i=0,3 do
  local x=side*(47+i*3) local z=105+i*18
  part(scene,'FencePost',Vector3.new(.8,5,.8),at(x,2.5,z),timber)
  if i<3 then
   for _,y in {1.7,3.7} do beam(scene,'FenceRail',at(x,y,z),at(side*(50+i*3),y,z+18),.55,timber,Enum.Material.Wood,false) end
  end
 end
end
-- Proper gatehouse framing the 64-stud break in the original south wall.
local gate=model('SouthGatehouse')
for _,side in {-1,1} do
 local x=side*27
 part(gate,'GateTower',Vector3.new(12,34,20),at(x,17,0),stone,Enum.Material.Cobblestone)
 part(gate,'TowerFoot',Vector3.new(14,3,23),at(x,1.5,0),Color3.fromRGB(112,113,98),Enum.Material.Slate)
 part(gate,'TowerCornice',Vector3.new(14,1.3,22),at(x,32,0),stone,Enum.Material.Slate)
 for _,dx in {-4,4} do for _,dz in {-8,8} do part(gate,'Battlement',Vector3.new(4,3,4),at(x+dx,35,dz),stone,Enum.Material.Cobblestone) end end
 part(gate,'ArrowSlit',Vector3.new(.7,5,.12),at(x,22,10.1),Color3.fromRGB(45,46,38),Enum.Material.Slate,false)
 -- Raised vertical buttresses and contrasting stone around the opening.
 part(gate,'Buttress',Vector3.new(3,25,3),at(side*20,12.5,11),stone,Enum.Material.Slate)
 -- Open wooden leaves fold back inside, no player obstruction.
 part(gate,'OpenGateLeaf',Vector3.new(1,14,15),at(side*19,7,-8),timber,Enum.Material.WoodPlanks)
 for _,y in {3,11} do part(gate,'GateIronStrap',Vector3.new(1.2,.6,15.3),at(side*19,y,-8),Color3.fromRGB(65,65,57),Enum.Material.Metal) end
end
part(gate,'GateLintel',Vector3.new(42,6,20),at(0,27,0),stone,Enum.Material.Cobblestone)
part(gate,'LintelCap',Vector3.new(44,1.5,22),at(0,30.7,0),stone,Enum.Material.Slate)
-- Segmented arch trims: inner radius 18, bottom at height 13; all above walking headroom.
for i=0,10 do
 local a=math.pi*i/10
 part(gate,'ArchStone',Vector3.new(5,2.5,1.8),CFrame.new(at(math.cos(a)*18,13+math.sin(a)*10,10.8))*CFrame.Angles(0,0,a-math.pi/2),Color3.fromRGB(161,151,126),Enum.Material.Slate)
end
local city=map.Settlements.Crownford
for _,p in city:GetChildren() do if p.Name=='PlaceName' then p:Destroy() end end
local sign=part(gate,'CitySign',Vector3.new(23,3,.7),at(0,27,10.6),timber,Enum.Material.WoodPlanks,false)
local sg=Instance.new('SurfaceGui') sg.Face=Enum.NormalId.Back sg.PixelsPerStud=40 sg.Parent=sign
local text=Instance.new('TextLabel') text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Text='КРОУНФОРД' text.TextColor3=Color3.fromRGB(226,211,165) text.Font=Enum.Font.Garamond text.TextScaled=true text.Parent=sg
for _,side in {-1,1} do
 local lantern=model('GateLantern') local x=side*23
 beam(lantern,'Bracket',at(x,11,10),at(x,11,14),.5,timber,Enum.Material.Wood,false)
 part(lantern,'LanternFrame',Vector3.new(1.8,3,1.8),at(x,9.5,14),Color3.fromRGB(58,55,43),Enum.Material.Metal,false)
 local pane=part(lantern,'LanternGlass',Vector3.new(1.4,2.3,1.9),at(x,9.5,14),Color3.fromRGB(244,194,102),Enum.Material.Neon,false)
 local light=Instance.new('PointLight') light.Color=pane.Color light.Brightness=.7 light.Range=17 light.Shadows=false light.Parent=pane
end
-- A small resting spot beside the approach.
local rest=model('WaysideBench')
part(rest,'Seat',Vector3.new(13,.8,3.8),at(-34,3,72),timber,Enum.Material.WoodPlanks)
for _,x in {-39,-29} do part(rest,'BenchLeg',Vector3.new(1,3,3),at(x,1.5,72),timber) end
part(rest,'Backrest',Vector3.new(13,2,.7),at(-34,4.5,74),timber)
local barrel=model('RoadsideBarrel')
local b=part(barrel,'Barrel',Vector3.new(4,3,3),at(34,2,17),Color3.fromRGB(114,87,52),Enum.Material.WoodPlanks) b.Shape=Enum.PartType.Cylinder b.CFrame*=CFrame.Angles(0,0,math.pi/2)
for _,y in {.7,3.3} do local ring=part(barrel,'BarrelHoop',Vector3.new(.25,3.15,3.15),CFrame.new(at(34,y,17))*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(70,69,59),Enum.Material.Metal) ring.Shape=Enum.PartType.Cylinder end
scene:SetAttribute('DetailVersion',1)
scene:SetAttribute('PassageWidth',36)
print('SPAWN_DETAIL_BUILT',#scene:GetDescendants(),'instances; free central passage')
