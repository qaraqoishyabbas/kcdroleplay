local U = {}
function U.alive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health > 0 then return c,h,r end
end
function U.finite(n)
    return type(n)=="number" and n==n and math.abs(n)<1e9
end
function U.safePosition(pos)
    return (Vector3.new(pos.X,0,pos.Z)-Vector3.zero).Magnitude <= 105
end
function U.allow(buckets, player, key, interval)
    local now = os.clock()
    local p = buckets[player]
    if not p then p={} buckets[player]=p end
    if now-(p[key] or -math.huge)<interval then return false end
    p[key]=now
    return true
end
function U.near(player, part, distance)
    local _,_,root=U.alive(player)
    return root and part and part:IsA("BasePart") and (root.Position-part.Position).Magnitude <= distance
end
return U
