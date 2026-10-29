-- Small deterministic API double for logic tests. No Roblox engine, renderer or physics.
local game, workspace, task, script, require
local clock, queue, services, instances
local factories = {}
local Vector3 = {}
local vectorMeta = {}
function Vector3.new(x, y, z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0}, vectorMeta) end
vectorMeta.__index = function(v,k)
    if k == "Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if k == "Unit" then return v / v.Magnitude end
    if k == "Dot" then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
    if k == "Cross" then return function(a,b) return Vector3.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end end
    if k == "Lerp" then return function(a,b,t) return a+(b-a)*t end end
end
vectorMeta.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMeta.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMeta.__unm=function(a) return Vector3.new(-a.X,-a.Y,-a.Z) end
vectorMeta.__mul=function(a,b) if type(a)=="number" then a,b=b,a end return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vectorMeta.__div=function(a,b) return Vector3.new(a.X/b,a.Y/b,a.Z/b) end
Vector3.zero=Vector3.new() Vector3.one=Vector3.new(1,1,1) Vector3.yAxis=Vector3.new(0,1,0)
local Vector2={new=function(x,y) return {X=x or 0,Y=y or 0} end}
local CFrame={}
local cfMeta={}
local function cf(p,r,u,b) return setmetatable({Position=p,RightVector=r or Vector3.new(1,0,0),UpVector=u or Vector3.yAxis,LookVector=-(b or Vector3.new(0,0,1))},cfMeta) end
function CFrame.new(x,y,z) return cf(type(x)=="table" and x or Vector3.new(x,y,z)) end
local function rotate(c,v) return c.RightVector*v.X+c.UpVector*v.Y-c.LookVector*v.Z end
cfMeta.__mul=function(a,b)
    if getmetatable(b)==vectorMeta then return a.Position+rotate(a,b) end
    return cf(a*b.Position,rotate(a,b.RightVector),rotate(a,b.UpVector),rotate(a,-b.LookVector))
end
function CFrame.Angles(x,y,z)
    local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
    return cf(Vector3.zero,Vector3.new(cy*cz,cx*sz+sx*sy*cz,sx*sz-cx*sy*cz),Vector3.new(-cy*sz,cx*cz-sx*sy*sz,sx*cz+cx*sy*sz),Vector3.new(sy,-sx*cy,cx*cy))
end
function CFrame.lookAt(p,q)
    local look=(q-p).Unit
    local right=look:Cross(Vector3.yAxis).Unit
    return cf(p,right,right:Cross(look),-look)
end
local Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end,new=function(r,g,b) return {R=r,G=g,B=b} end}
local UDim={new=function(s,o) return {Scale=s,Offset=o} end}
local UDim2={new=function(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local Enum=setmetatable({}, {__index=function(t,k)
    local e=setmetatable({}, {__index=function(t2,k2) local v={Name=k2,Value=100}; rawset(t2,k2,v); return v end})
    rawset(t,k,e) return e
end})
local function typeof(v) if getmetatable(v)==vectorMeta then return "Vector3" end return type(v) end
local RaycastParams={new=function() return {} end}
local function signal()
    local s={handlers={}}
    function s:Connect(fn)
        local connected=true
        table.insert(self.handlers,function(...) if connected then fn(...) end end)
        return {Disconnect=function() connected=false end}
    end
    function s:Fire(...) for _,fn in self.handlers do fn(...) end end
    return s
end
local methods={}
local instanceMeta={}
local baseClasses={Part=true,SpawnLocation=true,MeshPart=true}
function methods:IsA(c) return self.ClassName==c or (c=="BasePart" and baseClasses[self.ClassName]==true) end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
    self._descendantReads=(self._descendantReads or 0)+1
    local out={}
    local function visit(o) for _,c in o._children do table.insert(out,c); visit(c) end end
    visit(self) return out
end
function methods:FindFirstChild(name,recursive)
    for _,c in self._children do if c.Name==name then return c end end
    if recursive then for _,c in self._children do local found=c:FindFirstChild(name,true); if found then return found end end end
end
function methods:WaitForChild(name,timeout) return self:FindFirstChild(name) end
function methods:FindFirstChildOfClass(c) for _,o in self._children do if o.ClassName==c then return o end end end
function methods:FindFirstAncestorOfClass(c) local p=self.Parent; while p do if p:IsA(c) then return p end p=p.Parent end end
function methods:IsDescendantOf(o) local p=self.Parent; while p do if p==o then return true end p=p.Parent end return false end
function methods:SetAttribute(k,v) self._attrs[k]=v end
function methods:GetAttribute(k) return self._attrs[k] end
function methods:GetPropertyChangedSignal(k)
    if not self._propertySignals[k] then self._propertySignals[k]=signal() end
    return self._propertySignals[k]
end
function methods:GetFullName() return self.Parent and self.Parent:GetFullName().."."..self.Name or self.Name end
function methods:Destroy() self.Destroying:Fire(); for _,c in self:GetChildren() do c:Destroy() end self.Parent=nil; self._destroyed=true end
function methods:TakeDamage(d) self.Health=math.max(0,self.Health-d); if self.Health==0 then self.Died:Fire() end end
function methods:ChangeState(s) self.LastState=s end
function methods:FireClient(player,...) table.insert(self.calls,{player=player,args={...}}) end
function methods:FireServer(...) table.insert(self.calls,{args={...}}) end
instanceMeta.__index=function(o,k)
    if methods[k]~=nil then return methods[k] end
    if o._props[k]~=nil then return o._props[k] end
    return o:FindFirstChild(k)
end
instanceMeta.__newindex=function(o,k,v)
    if string.sub(k,1,1)=="_" then rawset(o,k,v) return end
    if k=="Parent" then
        local prev=o._props.Parent
        if prev then local i=table.find(prev._children,o); if i then table.remove(prev._children,i) end end
        o._props.Parent=v
        if v then
            table.insert(v._children,o)
            local added={o}
            for _,child in o:GetDescendants() do table.insert(added,child) end
            local parent=v
            while parent do
                for _,child in added do parent.DescendantAdded:Fire(child) end
                parent=parent.Parent
            end
        end
    elseif k=="CFrame" then o._props.CFrame=v; o._props.Position=v.Position
    elseif k=="Position" and baseClasses[o.ClassName] then o._props.Position=v; o._props.CFrame=CFrame.new(v)
    else
        local old=o._props[k]
        o._props[k]=v
        if old~=v and o._propertySignals[k] then o._propertySignals[k]:Fire() end
    end
end
local Instance={}
function Instance.new(class)
    local o=setmetatable({_props={ClassName=class,Name=class},_children={},_attrs={},_propertySignals={}},instanceMeta)
    o.Destroying=signal()
    o.DescendantAdded=signal()
    if baseClasses[class] then
        o.CFrame=CFrame.new(); o.Size=Vector3.one; o.CanCollide=true; o.CanTouch=true; o.CanQuery=true; o.CastShadow=true; o.Anchored=false
        o.AssemblyLinearVelocity=Vector3.zero; o.AssemblyAngularVelocity=Vector3.zero
    end
    if class=="Humanoid" then o.Health=100; o.MaxHealth=100; o.WalkSpeed=22; o.AutoRotate=true; o.PlatformStand=false; o.MoveDirection=Vector3.zero; o.Died=signal() end
    if class=="Player" then o.CharacterAdded=signal(); o.CharacterRemoving=signal() end
    if class=="TextButton" then o.MouseButton1Click=signal() end
    if class=="ProximityPrompt" then o.Triggered=signal() end
    if class=="RemoteEvent" then o.calls={}; o.OnClientEvent=signal(); o.OnServerEvent=signal() end
    table.insert(instances,o)
    return o
end
local function schedule(delay,fn,...) table.insert(queue,{time=clock+delay,co=type(fn)=="thread" and fn or coroutine.create(fn),args={...}}) end
local function advance(dt)
    local target=clock+dt
    local steps=0
    while true do
        local index,best=nil,math.huge
        for i,q in queue do if q.time<best then index,best=i,q.time end end
        if not index or best>target+1e-9 then break end
        steps+=1 assert(steps<10000,"Scheduler runaway")
        local q=table.remove(queue,index) clock=q.time
        local ok,delay=coroutine.resume(q.co,table.unpack(q.args))
        assert(ok,tostring(delay))
        if coroutine.status(q.co)~="dead" then schedule(delay or 0,q.co) end
    end
    clock=target
end
local function resetEnvironment()
    clock=100 queue={} services={} instances={}
    task={spawn=function(fn,...) schedule(0,fn,...) end,delay=function(d,fn,...) schedule(d,fn,...) end,wait=function(d) return coroutine.yield(d or 0.03) end}
    workspace=Instance.new("Workspace") workspace.Name="Workspace"
    function workspace:GetServerTimeNow() return clock end
    workspace.raycastLog={}
    function workspace:Raycast(origin,direction,params)
        table.insert(self.raycastLog,{origin=origin,direction=direction,params=params})
        return self.raycastResult
    end
    workspace.CurrentCamera={CFrame=CFrame.new()}
    services.Players=Instance.new("Players") services.Players.PlayerRemoving=signal(); services.Players.PlayerAdded=signal()
    function services.Players:GetPlayers() return self:GetChildren() end
    function services.Players:GetPlayerFromCharacter(c) for _,p in self:GetChildren() do if p.Character==c then return p end end end
    for _,name in {"ReplicatedStorage","ServerScriptService","StarterPlayer","Lighting"} do services[name]=Instance.new(name) end
    services.Lighting.GlobalShadows=true
    local starterScripts=Instance.new("Folder") starterScripts.Name="StarterPlayerScripts" starterScripts.Parent=services.StarterPlayer
    services.RunService={RenderStepped=signal(),PreSimulation=signal(),IsRunning=function() return false end}
    services.UserInputService={InputBegan=signal(),InputEnded=signal(),WindowFocusReleased=signal(),keys={},buttons={},delta=Vector2.new(),focused=nil}
    function services.UserInputService:GetFocusedTextBox() return self.focused end
    function services.UserInputService:IsMouseButtonPressed(b) return self.buttons[b]==true end
    function services.UserInputService:IsKeyDown(k) return self.keys[k]==true end
    function services.UserInputService:GetMouseDelta() return self.delta end
    services.ContextActionService={bindings={}}
    function services.ContextActionService:BindActionAtPriority(name,fn) self.bindings[name]=fn end
    function services.ContextActionService:UnbindAction(name) self.bindings[name]=nil end
    services.GuiService={MenuIsOpen=false}
    services.Debris={AddItem=function(_,o,d) task.delay(d,function() if o.Parent then o:Destroy() end end) end}
    game={GetService=function(_,name) assert(services[name],"Unmocked service: "..name) return services[name] end}
    script=Instance.new("LocalScript") script.Name="TestScript"
end
local function makePlayer(name,pos)
    local p=Instance.new("Player") p.Name=name; p.Parent=services.Players
    local c=Instance.new("Model") c.Name=name c.Parent=workspace p.Character=c
    local h=Instance.new("Humanoid") h.Name="Humanoid" h.Parent=c
    for _,name in {"HumanoidRootPart","RightHand","LeftHand","Head","UpperTorso","LowerTorso"} do
        local part=Instance.new("Part") part.Name=name part.CFrame=CFrame.new(pos or Vector3.zero); part.Parent=c
    end
    local gui=Instance.new("Folder") gui.Name="PlayerGui" gui.Parent=p
    p:SetAttribute("Gold",200)
    return p,h,c.HumanoidRootPart
end
local function loadModule(name) return factories[name]() end
local function context()
    resetEnvironment()
    local ctx={config=loadModule("CombatConfig"),net={},world={trainingParts={}},vendor=loadModule("Vendor")}
    local vendorPoint=Instance.new("Part"); vendorPoint.Name="VendorPoint"; vendorPoint.Position=Vector3.zero; vendorPoint.Parent=workspace
    ctx.world.vendorPoint=vendorPoint
    for _,name in {"Hud","Notice","Shop","Attack","Block","DrawStart","Release","Buy"} do ctx.net[name]=Instance.new("RemoteEvent") end
    for key,name in {stats="Stats",arsenal="Arsenal",melee="Melee",arrows="Arrows",shop="Shop"} do ctx[key]=loadModule(name) end
    ctx.arsenal.init(ctx); ctx.stats.init(ctx); ctx.melee.init(ctx); ctx.arrows.init(ctx); ctx.shop.init(ctx)
    return ctx
end
local function setupClient(ctx,p)
    services.Players.LocalPlayer=p
    local cache={CombatConfig=ctx.config,CombatNet={client=function() return ctx.net end}}
    for _,name in {"CombatConfig","CombatNet"} do local m=Instance.new("ModuleScript"); m.Name=name; m.Parent=services.ReplicatedStorage end
    require=function(obj) return assert(cache[obj.Name]) end
    factories.CombatClient()
    return p.PlayerGui.CombatHUD
end
local results={}
local function equal(actual,expected,message) assert(actual==expected,(message or "Unexpected value")..": expected "..tostring(expected)..", actual "..tostring(actual)) end
local function near(actual,expected,epsilon,message) assert(math.abs(actual-expected)<(epsilon or 1e-6),(message or "Unexpected value")..": expected "..tostring(expected)..", actual "..tostring(actual)) end
local function check(name,fn)
    local ok,err=pcall(fn)
    table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil})
    print((ok and "PASS" or "FAIL").."\t"..name..(ok and "" or "\t"..tostring(err)))
end
