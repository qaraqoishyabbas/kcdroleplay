-- Read-only inventory. Run in the Studio Command Bar with Play stopped.
assert(not game:GetService("RunService"):IsRunning(), "Run this audit in edit mode")
local map = assert(workspace:FindFirstChild("Map"), "Map missing")
local function count(root)
	local n = {instances=0, parts=0, shadows=0, collidable=0, touch=0, query=0, unanchored=0, lights=0}
	for _, item in root:GetDescendants() do
		n.instances += 1
		if item:IsA("BasePart") then
			n.parts += 1
			if item.CastShadow then n.shadows += 1 end
			if item.CanCollide then n.collidable += 1 end
			if item.CanTouch then n.touch += 1 end
			if item.CanQuery then n.query += 1 end
			if not item.Anchored then n.unanchored += 1 end
		elseif item:IsA("Light") then n.lights += 1 end
	end
	return n
end
local roots = {map}
for _, child in map:GetChildren() do table.insert(roots, child) end
for _, root in roots do
	local n = count(root)
	print("MAP_AUDIT", root.Name, "instances", n.instances, "parts", n.parts,
		"shadows", n.shadows, "collidable", n.collidable, "touch", n.touch,
		"query", n.query, "unanchored", n.unanchored, "lights", n.lights)
end
print("MAP_AUDIT_STREAMING", workspace.StreamingEnabled,
	"min", workspace.StreamingMinRadius, "target", workspace.StreamingTargetRadius,
	"streamOut", workspace.StreamOutBehavior)
