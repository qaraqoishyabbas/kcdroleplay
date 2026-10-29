-- Native edit-mode verification. Does not start Play or manipulate any UI.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode only")
local count=0
local function check(v,message) assert(v,message) count+=1 end
local map=assert(workspace:FindFirstChild("Map"))
check(map:GetAttribute("ArtStyleVersion")=="0.1","Wrong style version")
check(map:GetAttribute("BuildingReplacementCount")==103,"Replacement count missing")
local buildings,parts,unions,trees,triangles=0,0,0,0,0
local variants={}
for _,settlement in map.Settlements:GetChildren() do
    for _,m in settlement:GetChildren() do
        if m:IsA("Model") and m:FindFirstChild("Foundation") then
            buildings+=1
            check(m:GetAttribute("ArtStyleVersion")=="0.1","Old building remains: "..m:GetFullName())
            local variant=assert(m:GetAttribute("BuildingVariant")) variants[variant]=true
            check(m.ModelStreamingMode==Enum.ModelStreamingMode.Atomic,"Building is not atomic")
            check(m.PrimaryPart==m.Foundation,"Foundation reference lost")
            local original=assert(m:GetAttribute("OriginalOrigin"))
            check((m:GetPivot().Position-original.Position).Magnitude<.01,"Building moved from plot")
            local plot=assert(m:GetAttribute("OriginalFootprint"))
            check(m.Foundation.Size.X<=plot.X+.01 and m.Foundation.Size.Z<=plot.Z+.01,"Foundation exceeds original plot")
            local roofs,gables={},0
            for _,p in m:GetChildren() do
                if p:IsA("BasePart") and string.find(p.Name,"RoofSlope_",1,true) then
                    local rel=original:PointToObjectSpace(p.Position)
                    local side=rel.X<0 and -1 or 1
                    local ridge=original:PointToObjectSpace(p.CFrame:PointToWorldSpace(Vector3.new(-side*p.Size.X/2,-p.Size.Y/2,0)))
                    check(math.abs(ridge.X)<.015,"Roof planes miss center")
                    check(math.abs(p.CFrame.UpVector.Y-math.cos(math.rad(43)))<.001,"Wrong roof pitch")
                    table.insert(roofs,ridge)
                elseif p:IsA("WedgePart") then
                    local high=original:PointToObjectSpace(p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,p.Size.Z/2)))
                    check(math.abs(high.X)<.015,"Gable points outward")
                    gables+=1
                end
            end
            check(#roofs==2 and gables==4,"Incomplete roof or gable")
            check(math.abs(roofs[1].Y-roofs[2].Y)<.015,"Roof ridge height mismatch")
        end
    end
end
check(buildings==103,"Not all buildings replaced")
local variantCount=0 for _ in variants do variantCount+=1 end
check(variantCount==9,"Expected nine building variants")
for _,p in map:GetDescendants() do
    if p:IsA("BasePart") then parts+=1 end
    if p:IsA("UnionOperation") then
        unions+=1 triangles+=p.TriangleCount
        check(p.TriangleCount>0,"CSG geometry missing after saving: "..p:GetFullName())
        check(p.RenderFidelity==Enum.RenderFidelity.Automatic,"Automatic mesh fidelity missing")
    end
end
check(parts==9906,"Part count changed after saving: "..parts)
check(unions==3886,"Shared geometry did not survive serialization")
for _,forest in map.Nature.Forests:GetChildren() do
    for _,tree in forest:GetChildren() do
        if tree:IsA("Model") then
            trees+=1
            local crown=tree:FindFirstChild("LeafCrown")
            check(crown and not crown.CanQuery and not crown.CanTouch and not crown.CastShadow,"Tree optimization missing")
            check(tree.ModelStreamingMode==Enum.ModelStreamingMode.Atomic,"Tree is not atomic")
        end
    end
end
check(trees==3066,"Forest population changed")
local grass=workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
local ground=workspace.Terrain:GetMaterialColor(Enum.Material.Ground)
check((Vector3.new(grass.R,grass.G,grass.B)-Vector3.new(116/255,128/255,90/255)).Magnitude<.01,"Grass palette did not save")
check((Vector3.new(ground.R,ground.G,ground.B)-Vector3.new(137/255,116/255,84/255)).Magnitude<.01,"Ground palette did not save")
local config=require(game.ReplicatedStorage.CombatConfig)
local World=require(game.ServerScriptService.Combat.World)
World.init(config)
check(#World.weaponPoints==4 and World.shieldPoint and World.armorPoint and World.vendorPoint,"Interaction points missing")
local Vendor=require(game.ServerScriptService.Combat.Vendor)
local npc=Vendor.ensure(World.vendorPoint)
check(npc:GetAttribute("AppearanceVersion")==2,"Old merchant appearance")
for _,p in npc:GetDescendants() do
    if p:IsA("BasePart") then check(not p.CanCollide and not p.CanQuery and not p.CanTouch,"Merchant collider was not normalized") end
end
-- Exercise actual server modules with native character parts and a local player
-- adapter. Network calls are captured; multiplayer/physics are not simulated.
local net={}
for _,name in {"Hud","Notice","Shop"} do net[name]={FireClient=function() end} end
local Stats=require(game.ServerScriptService.Combat.Stats)
local Arsenal=require(game.ServerScriptService.Combat.Arsenal)
local Shop=require(game.ServerScriptService.Combat.Shop)
local Arrows=require(game.ServerScriptService.Combat.Arrows)
local ctx={config=config,world=World,net=net,stats=Stats,arsenal=Arsenal}
Stats.init(ctx) Arsenal.init(ctx) Shop.init(ctx) Arrows.init(ctx)
local temporary={}
local function playerAt(pos)
    local char=Instance.new("Model") char.Name="StyleEditVerificationRig" char.Parent=workspace
    table.insert(temporary,char)
    for _,name in {"HumanoidRootPart","RightHand","LeftHand","Head","UpperTorso","LowerTorso"} do
        local p=Instance.new("Part") p.Name=name p.Size=Vector3.one p.Anchored=true p.CanCollide=false p.CFrame=CFrame.new(pos) p.Parent=char
    end
    local hum=Instance.new("Humanoid") hum.Parent=char hum.MaxHealth=100 hum.Health=100
    local values={Gold=200}
    return {Parent=true,Character=char,GetAttribute=function(_,k) return values[k] end,
        SetAttribute=function(_,k,v) values[k]=v end},hum
end
local base=World.vendorPoint.Position+Vector3.new(0,3,0)
local player,hum=playerAt(base)
Shop.buy(player,"Sword")
check(Stats.getGold(player)==160 and Stats.get(player).weapon=="Sword","Native purchase failed")
local sword=player.Character.Weapon_Sword
check(math.abs((sword.Blade.Position-sword.Grip.Position).Magnitude-1.9)<.002,"Weapon parts collapsed")
Arsenal.setShield(player,true) Arsenal.setWeapon(player,"Axe")
check(Stats.get(player).shield and player.Character:FindFirstChild("Weapon_Shield"),"Weapon switch removed shield")
player.Character.HumanoidRootPart.CFrame=CFrame.new(base+Vector3.new(1000,0,0))
Shop.buy(player,"Bow") check(Stats.getGold(player)==160,"Purchase allowed outside vendor range")
player.Character.HumanoidRootPart.CFrame=CFrame.new(base)
Arsenal.wearAll(player) check(math.abs(Arsenal.reduction(player)-.38224)<.0001,"Armor reduction failed")
Arsenal.stripAll(player) check(Arsenal.reduction(player)==0,"Armor removal failed")
local attacker=playerAt(base+Vector3.new(0,0,-3))
Stats.setBlocking(player,true)
check(Stats.damage(player,26,attacker,"test",0)==0 and hum.Health==100,"Native frontal block failed")
check(Stats.get(player).stamina==94,"Shield block stamina cost failed")
Stats.get(player).stamina=0
check(Stats.damage(player,26,attacker,"test",0)>0,"Guard break prevented damage")
check(not Stats.canAct(player,workspace:GetServerTimeNow()),"Guard break did not stagger")
Arsenal.setWeapon(player,"Bow") Arrows.drawStart(player)
check(Stats.get(player).drawStarted==0,"Bow draw allowed while staggered")
for _,o in temporary do o:Destroy() end
print("STYLE_MAIN_EDIT_PASS "..game:GetService("HttpService"):JSONEncode({
    assertions=count,buildings=buildings,variants=variantCount,parts=parts,unions=unions,
    trees=trees,unionTriangles=triangles,playStarted=false,sourceBuild=4,
}))
