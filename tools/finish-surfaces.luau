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
