-- Included by package-world-style.py after the edit-time Style factory.
assert(not game:GetService("RunService"):IsRunning(),"Stop Play before replacing buildings")
local map=assert(workspace:FindFirstChild("Map"),"Map missing")
local report={buildings=0,trees=0,painted=0,optimized=0,variants={},beforeParts=0}
for _,p in map:GetDescendants() do if p:IsA("BasePart") then report.beforeParts+=1 end end
for _,settlement in map.Settlements:GetChildren() do
    local buildings={}
    for _,m in settlement:GetChildren() do
        if m:IsA("Model") and m:FindFirstChild("Foundation") and m:GetAttribute("ArtStyleVersion")~=Style.Version then
            table.insert(buildings,m)
        end
    end
    table.sort(buildings,function(a,b) return a.Name<b.Name end)
    for _,old in buildings do
        local f=old.Foundation
        local origin=f.CFrame*CFrame.new(0,-f.Size.Y/2,0)
        local replacement=Style.place(settlement,old.Name,origin,f.Size.X,f.Size.Z)
        local variant=replacement:GetAttribute("BuildingVariant")
        report.variants[variant]=(report.variants[variant] or 0)+1
        old:Destroy()
        report.buildings+=1
    end
end
local mill=map.Settlements.Millbridge
local oldMill=mill:FindFirstChild("WindmillBase")
if oldMill then
    local center=oldMill.Position-Vector3.new(0,oldMill.Size.Y/2,0)
    local m=Style.place(mill,"Windmill",CFrame.new(center),21,24)
    for _,p in mill:GetChildren() do if p.Name=="WindmillBase" or p.Name=="WindmillSail" then p:Destroy() end end
    Style.addWindmillSails(m,CFrame.new(center))
    report.buildings+=1 report.variants.Windmill=1
end
for _,forest in map.Nature.Forests:GetChildren() do
    for _,tree in forest:GetChildren() do
        if tree:IsA("Model") and Style.optimizeTree(tree) then report.trees+=1 end
    end
end
local function trainingTarget(p)
    local a=p.Parent
    while a and a~=map do
        if string.sub(a.Name,1,6)=="Target" or string.sub(a.Name,1,5)=="Dummy" then return true end
        a=a.Parent
    end
    return false
end
local palette={
    [Enum.Material.Wood]={"M02",Color3.fromRGB(85,68,56)},
    [Enum.Material.WoodPlanks]={"M03",Color3.fromRGB(139,115,87)},
    [Enum.Material.Cobblestone]={"M04",Color3.fromRGB(132,130,121)},
    [Enum.Material.Brick]={"M04",Color3.fromRGB(132,130,121)},
    [Enum.Material.Plaster]={"M01",Color3.fromRGB(206,193,165)},
    [Enum.Material.Fabric]={"M08",Color3.fromRGB(183,170,136)},
    [Enum.Material.Ground]={"M10",Color3.fromRGB(137,116,84)},
}
for _,p in map:GetDescendants() do
    if p:IsA("BasePart") then
        if p.Anchored then
            if p.CanTouch then p:SetAttribute("MapPerfOriginal_CanTouch",true) p.CanTouch=false report.optimized+=1 end
            local target=trainingTarget(p)
            if not p.CanCollide and not target and p.CanQuery then
                p:SetAttribute("MapPerfOriginal_CanQuery",true) p.CanQuery=false report.optimized+=1
            end
            if not p.CanCollide and not target and p.CastShadow then
                p:SetAttribute("MapPerfOriginal_CastShadow",true) p.CastShadow=false report.optimized+=1
            end
        end
        if not p:GetAttribute("DesignMaterial") and not trainingTarget(p) and p.Transparency<1 then
            local v=palette[p.Material]
            if p.Name=="Canopy" or p.Name=="Leaves" or p.Name=="LeafCrown" then
                if p.Material==Enum.Material.Grass then v={"M12",Color3.fromRGB(79,102,71)} end
            end
            if v then p.Material=Enum.Material[Style.materials[v[1]][1]] p.Color=v[2] p:SetAttribute("DesignMaterial",v[1]) report.painted+=1 end
        end
    end
end
map:SetAttribute("ArtStyleVersion",Style.Version)
map:SetAttribute("ArtStyle","A")
map:SetAttribute("PerformanceProfile","balanced")
if report.buildings>0 then map:SetAttribute("BuildingReplacementCount",report.buildings) end
if report.trees>0 then map:SetAttribute("OptimizedTreeCount",report.trees) end
map:SetAttribute("CustomTextureStage","BuiltinPreview")
report.afterParts=0 report.unions=0 report.unionTriangles=0
for _,p in map:GetDescendants() do
    if p:IsA("BasePart") then report.afterParts+=1 end
    if p:IsA("UnionOperation") then report.unions+=1 report.unionTriangles+=p.TriangleCount end
end
report.unionFailures=Style.unionFailures
report.templateSourceParts=Style.sourceParts report.templateCompiledParts=Style.compiledParts
Style.releaseTemplates()
assert(report.buildings==103 or report.buildings==0,"Expected 102 houses/barns/hall and one windmill")
assert(#report.unionFailures==0,"Could not compile shared geometry: "..table.concat(report.unionFailures,"; "))
assert(report.afterParts<report.beforeParts or report.buildings==0,"Part budget increased")
print("STYLE_MAIN_JSON "..game:GetService("HttpService"):JSONEncode(report))
