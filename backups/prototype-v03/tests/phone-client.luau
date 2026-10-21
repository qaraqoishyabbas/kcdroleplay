-- Run in the CLIENT Command Bar during an iPhone 13 landscape Play test, after Play.
local p=game.Players.LocalPlayer
local hud=p.PlayerGui.HUD
assert(p:GetAttribute("Started") and hud.Enabled)
local jump=assert(p.PlayerGui.TouchGui:FindFirstChild("JumpButton",true))
local names={"TouchLight","TouchHeavy","TouchBlock","TouchDodge","TouchSprint"}
local function overlap(a,b)
    local ap,as=a.AbsolutePosition,a.AbsoluteSize local bp,bs=b.AbsolutePosition,b.AbsoluteSize
    return ap.X<bp.X+bs.X and ap.X+as.X>bp.X and ap.Y<bp.Y+bs.Y and ap.Y+as.Y>bp.Y
end
local buttons={}
for _,name in names do
    local b=assert(hud:FindFirstChild(name),name.." missing")
    assert(b.AbsoluteSize.X>=44 and b.AbsoluteSize.Y>=44,"Touch target too small")
    assert(not overlap(b,jump),name.." overlaps native jump")
    assert(not overlap(b,hud.Tutorial),name.." overlaps tutorial")
    for _,other in buttons do assert(not overlap(b,other),name.." overlaps another action") end
    table.insert(buttons,b)
end
assert(p.PlayerGui.InventoryUI.Panel and p.PlayerGui.TradeUI.Panel)
print("CROWN_PHONE_LAYOUT_PASS",#buttons,"touch controls; no jump/tutorial overlap")
