-- Offline file assembly with Lune. Does not start Studio or access the desktop.
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local process=require("@lune/process")
local serde=require("@lune/serde")
local args=process.args
assert(#args==5,"source.rbxl native.rbxm output.rbxl output.rbxlx project-root")
local g=roblox.deserializePlace(fs.readFile(args[1]))
local roots=roblox.deserializeModel(fs.readFile(args[2]))
assert(#roots==7,"Expected map and six installed source roots")
local imported={}
for _,o in roots do
    local destination=assert(o:GetAttribute("StyleSaveDestination"),"Missing source destination")
    local parent=g
    for segment in destination:gmatch("[^/]+") do
        local child=parent:FindFirstChild(segment)
        if not child then child=roblox.Instance.new(segment) child.Name=segment child.Parent=parent end
        parent=child
    end
    local previous=parent:FindFirstChild(o.Name)
    if previous then previous:Destroy() end
    o:SetAttribute("StyleSaveDestination",nil)
    o.Parent=parent
    table.insert(imported,destination.."/"..o.Name)
end
local ws=g:GetService("Workspace")
-- Source files remain authoritative, including fixes found by native edit tests.
local manifest=serde.decode("json",fs.readFile(args[5].."/docs/combat-manifest.json"))
for _,entry in manifest do
    local obj=g
    for segment in entry.path:gmatch("[^/]+") do obj=assert(obj:FindFirstChild(segment),entry.path) end
    assert(obj.ClassName==entry.class)
    obj.Source=fs.readFile(args[5].."/src/combat/"..entry.file:gsub("\\","/")):gsub("\r\n","\n")
end
ws.Map.TrainingYard.Props.VendorPoint.WeaponVendor.Torso.CanCollide=false
ws.StreamingEnabled=true
ws.StreamingMinRadius=128
ws.StreamingTargetRadius=512
ws:SetAttribute("HermesCombat",true)
ws.Map:SetAttribute("StreamingMinRadiusConfigured",128)
ws.Map:SetAttribute("StreamingTargetRadiusConfigured",512)
g:GetService("MaterialService").Use2022Materials=true
assert(ws.Map:GetAttribute("ArtStyleVersion")=="0.1")
assert(g:GetService("ReplicatedStorage").CombatConfig:GetAttribute("InstalledBuild")==4)
fs.writeFile(args[3],roblox.serializePlace(g))
fs.writeFile(args[4],roblox.serializePlace(g,true))
print("ASSEMBLED_STYLE_PLACE",#ws.Map:GetDescendants(),table.concat(imported,", "))
