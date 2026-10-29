local Style = {Version="0.1", unionFailures={}, compiledParts=0, sourceParts=0}
Style.materials=MATERIALS
local cache, treeCache = {}, {}
local function color(hex)
    return Color3.fromRGB(bit32.extract(hex,16,8),bit32.extract(hex,8,8),bit32.extract(hex,0,8))
end
local function material(part, id, hex)
    part.Material = Enum.Material[MATERIALS[id][1]]
    part.Color = color(hex or MATERIALS[id][2])
    part:SetAttribute("DesignMaterial", id)
    part:SetAttribute("ArtStyleVersion", Style.Version)
end
function Style.coalesce(model)
    local groups={}
    for _,p in model:GetChildren() do
        if p:IsA("BasePart") then
            Style.sourceParts+=1
            -- Keep analytical roof planes and gables for exact geometry checks.
            local keep = p.Name=="Foundation" or string.find(p.Name,"RoofSlope_",1,true)
                or string.find(p.Name,"ClosedGable",1,true)
            if not keep then
                local key=p:GetAttribute("DesignMaterial")..":"..tostring(p.Color)..":"..tostring(p.CanCollide)..":"..tostring(p.CastShadow)
                groups[key]=groups[key] or {}
                table.insert(groups[key],p)
            end
        end
    end
    for _,parts in groups do
        if #parts>1 then
            local first=parts[1]
            local rest={}
            for i=2,#parts do table.insert(rest,parts[i]) end
            local ok,result=pcall(function()
                return first:UnionAsync(rest,Enum.CollisionFidelity.Default,Enum.RenderFidelity.Automatic)
            end)
            if ok and result then
                result.Name=first:GetAttribute("DesignMaterial").."_Combined_"..(first.CanCollide and "Solid" or "Decor")
                result.Anchored=true
                result.CanCollide=first.CanCollide result.CanTouch=false result.CanQuery=first.CanQuery
                result.CastShadow=first.CastShadow result.UsePartColor=true
                material(result,first:GetAttribute("DesignMaterial"),math.floor(first.Color.R*255+.5)*65536+math.floor(first.Color.G*255+.5)*256+math.floor(first.Color.B*255+.5))
                result.Parent=model
                for _,p in parts do p:Destroy() end
            else
                table.insert(Style.unionFailures,model.Name..": "..tostring(result))
            end
        end
    end
    for _,p in model:GetChildren() do if p:IsA("BasePart") then Style.compiledParts+=1 end end
end
local function makeTemplate(key)
    local def=assert(CATALOG[key],"Unknown building variant "..key)
    local model=Instance.new("Model") model.Name=key model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ArtStyleVersion",Style.Version)
    model:SetAttribute("BuildingVariant",key)
    model:SetAttribute("TemplateWidth",def.width)
    model:SetAttribute("TemplateDepth",def.depth)
    model.Parent=workspace
    for _,r in def.parts do
        local p=Instance.new(r[2])
        p.Name=r[1]:sub(5)
        if p.Name~="Foundation" then p.Name=r[1] end
        p.Size=Vector3.new(table.unpack(r[3]))
        p.CFrame=CFrame.new(table.unpack(r[4]))
        p.Anchored=true p.CanTouch=false p.CanCollide=r[7] p.CanQuery=r[7] p.CastShadow=r[8]
        p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
        material(p,r[5],r[6]) p.Parent=model
    end
    local floor=assert(model:FindFirstChild("Foundation"))
    floor.PivotOffset=CFrame.new(0,-floor.Size.Y/2,0)
    model.PrimaryPart=floor
    Style.coalesce(model)
    model.Parent=nil
    return model
end
local function hash(name)
    local h=0
    for i=1,#name do h=(h*31+string.byte(name,i))%2147483647 end
    return h
end
function Style.choose(name,parentName)
    if name=="TownHall" or name=="Barn" or name=="Windmill" then return name end
    local variants=string.sub(name,1,9)=="Townhouse" and {"Town_A","Town_B","Town_Workshop"}
        or {"Cottage_A","Cottage_B","Cottage_Porch"}
    return variants[hash(parentName.."/"..name)%#variants+1]
end
function Style.place(parent,name,origin,maxWidth,maxDepth)
    assert(not game:GetService("RunService"):IsRunning(),"Edit-time factory only")
    local key=Style.choose(name,parent.Name)
    if not cache[key] then cache[key]=makeTemplate(key) end
    local m=cache[key]:Clone()
    m.Name=name
    local d=CATALOG[key]
    local scale=math.min(maxWidth/(d.width+1),maxDepth/(d.depth+1),1.15)
    -- Porches stay within the old plot depth so they cannot narrow the road.
    if string.find(key,"Workshop",1,true) or string.find(key,"Porch",1,true) then
        scale=math.min(scale,maxDepth/(d.depth+8))
    end
    m:ScaleTo(scale)
    m:PivotTo(origin)
    m:SetAttribute("OriginalFootprint",Vector3.new(maxWidth,1,maxDepth))
    m:SetAttribute("OriginalOrigin",origin)
    m:SetAttribute("ReplacementApproved","2026-10-29")
    m.Parent=parent
    return m
end
function Style.optimizeTree(model)
    local leaves={}
    local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
    for _,p in model:GetChildren() do
        if p:IsA("BasePart") and (p.Name=="Canopy" or p.Name=="Leaves") then
            table.insert(leaves,p)
            local a,b=p.Position-p.Size/2,p.Position+p.Size/2
            lo=Vector3.new(math.min(lo.X,a.X),math.min(lo.Y,a.Y),math.min(lo.Z,a.Z))
            hi=Vector3.new(math.max(hi.X,b.X),math.max(hi.Y,b.Y),math.max(hi.Z,b.Z))
        end
    end
    if #leaves<2 then return false end
    local kind=model.Name=="Conifer" and "Conifer" or "Oak"
    if not treeCache[kind] then
        local temp=Instance.new("Model") temp.Name="TreeCrown_"..kind temp.Parent=workspace
        for i=1,3 do
            local p=Instance.new("Part") p.Name="Canopy" p.Shape=Enum.PartType.Ball
            local w=kind=="Conifer" and (30-i*5) or (25+i*2)
            p.Size=Vector3.new(w,kind=="Conifer" and 17 or w*.72,w)
            p.CFrame=CFrame.new(kind=="Conifer" and 0 or (i-2)*5,(i-2)*8,0)
            p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
            material(p,"M12") p.Parent=temp
        end
        Style.coalesce(temp)
        local all=temp:GetChildren()
        if #all~=1 then temp:Destroy() return false end
        treeCache[kind]=all[1]:Clone()
        temp:Destroy()
    end
    local crown=treeCache[kind]:Clone()
    crown.Name="LeafCrown" crown.Size=hi-lo crown.CFrame=CFrame.new((hi+lo)/2)
    crown.Parent=model
    for _,p in leaves do p:Destroy() end
    model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ArtStyleVersion",Style.Version)
    return true
end
function Style.addWindmillSails(model,origin)
    local hub=origin*CFrame.new(0,17,12)
    for i=0,3 do
        local frame=hub*CFrame.Angles(0,0,math.pi/4+i*math.pi/2)
        for _,spec in {{"SailArm",Vector3.new(.42,15,.42),CFrame.new(0,7,0),"M02"},
                       {"SailCloth",Vector3.new(2.2,10,.16),CFrame.new(.7,9,.3),"M08"}} do
            local p=Instance.new("Part") p.Name=spec[1] p.Size=spec[2] p.CFrame=frame*spec[3]
            p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
            material(p,spec[4]) p.Parent=model
        end
    end
end
function Style.releaseTemplates()
    for _,m in cache do m:Destroy() end
    for _,m in treeCache do m:Destroy() end
    table.clear(cache) table.clear(treeCache)
end
return Style
