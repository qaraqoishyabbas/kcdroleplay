-- Run in edit-mode Command Bar.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play first')
local p=game.StarterPlayer.StarterPlayerScripts
local old=p:FindFirstChild('ExplorerFlight') if old then old:Destroy() end
local s=Instance.new('LocalScript') s.Name='ExplorerFlight'
s.Source=[====[-- Local map exploration: Q toggle, WASD camera-relative, Space/Ctrl vertical, wheel speed.
local Players=game:GetService('Players')
local Input=game:GetService('UserInputService')
local Actions=game:GetService('ContextActionService')
local Run=game:GetService('RunService')
local Gui=game:GetService('GuiService')
local player=Players.LocalPlayer
local MIN_SPEED,MAX_SPEED=10,800
local speed=80
local flying=false
local character,humanoid,root
local velocity,orientation,attachment
local originalParts={}
local collisionConnections={}
local descendantConnection
local originalAutoRotate,originalPlatformStand
local ACTION='ExplorerFlightWheel'
local gui=Instance.new('ScreenGui')
gui.Name='ExplorerFlightInfo' gui.ResetOnSpawn=false gui.IgnoreGuiInset=false
local label=Instance.new('TextLabel')
label.Name='Speed' label.AnchorPoint=Vector2.new(0,1) label.Position=UDim2.new(0,18,1,-18)
label.Size=UDim2.fromOffset(540,36) label.BackgroundColor3=Color3.fromRGB(30,34,27)
label.BackgroundTransparency=.18 label.BorderSizePixel=0 label.TextColor3=Color3.fromRGB(237,231,207)
label.Font=Enum.Font.Gotham label.TextSize=15 label.Visible=false label.Parent=gui
gui.Parent=player:WaitForChild('PlayerGui')
local function updateInfo()
 script:SetAttribute('FlightSpeed',speed)
 label.Text=string.format('NOCLIP  •  %d studs/s  •  Колесо: скорость  •  Q: выход',math.floor(speed+.5))
end
local function protectPart(p)
 if not flying or not p:IsA('BasePart') then return end
 if originalParts[p]==nil then
  originalParts[p]=p.CanCollide
  collisionConnections[p]=p:GetPropertyChangedSignal('CanCollide'):Connect(function()
   if flying and p.Parent and p.CanCollide then p.CanCollide=false end
  end)
 end
 p.CanCollide=false
end
local function noCollision()
 if character then for _,p in character:GetDescendants() do protectPart(p) end end
end
local function stop()
 flying=false script:SetAttribute('NoclipEnabled',false) label.Visible=false
 Actions:UnbindAction(ACTION)
 if velocity then velocity:Destroy() velocity=nil end
 if orientation then orientation:Destroy() orientation=nil end
 if attachment then attachment:Destroy() attachment=nil end
 for _,connection in collisionConnections do connection:Disconnect() end
 table.clear(collisionConnections)
 for p,value in originalParts do if p.Parent then p.CanCollide=value end end
 table.clear(originalParts)
 if root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero end
 if humanoid and humanoid.Parent and originalAutoRotate~=nil then
  humanoid.AutoRotate=originalAutoRotate humanoid.PlatformStand=originalPlatformStand
  if humanoid.Health>0 and not originalPlatformStand then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
 end
 originalAutoRotate=nil originalPlatformStand=nil
end
local function start()
 if not character or not root or not root.Parent or not humanoid or humanoid.Health<=0 or root.Anchored then return end
 originalAutoRotate=humanoid.AutoRotate originalPlatformStand=humanoid.PlatformStand
 humanoid.Sit=false humanoid.AutoRotate=false humanoid.PlatformStand=true
 attachment=Instance.new('Attachment') attachment.Name='ExplorerFlightAttachment' attachment.Parent=root
 velocity=Instance.new('LinearVelocity') velocity.Name='ExplorerFlightVelocity' velocity.Attachment0=attachment
 velocity.RelativeTo=Enum.ActuatorRelativeTo.World velocity.ForceLimitsEnabled=false velocity.VectorVelocity=Vector3.zero velocity.Parent=root
 orientation=Instance.new('AlignOrientation') orientation.Name='ExplorerFlightOrientation'
 orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment orientation.Attachment0=attachment
 orientation.MaxTorque=math.huge orientation.Responsiveness=35 orientation.Parent=root
 flying=true script:SetAttribute('NoclipEnabled',true) noCollision() label.Visible=true updateInfo()
 Actions:BindActionAtPriority(ACTION,function(_,state,input)
  if state==Enum.UserInputState.Change and not Input:GetFocusedTextBox() and not Gui.MenuIsOpen then
   speed=math.clamp(speed*1.2^input.Position.Z,MIN_SPEED,MAX_SPEED) updateInfo()
  end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+100,Enum.UserInputType.MouseWheel)
end
local generation=0
local function added(c)
 generation+=1 local current=generation
 if descendantConnection then descendantConnection:Disconnect() descendantConnection=nil end
 stop() character=c humanoid=nil root=nil
 local h=c:WaitForChild('Humanoid') local r=c:WaitForChild('HumanoidRootPart')
 if generation~=current or player.Character~=c then return end
 humanoid=h root=r
 descendantConnection=c.DescendantAdded:Connect(protectPart)
 h.Died:Connect(function() if character==c then stop() end end)
end
player.CharacterAdded:Connect(added)
player.CharacterRemoving:Connect(function(c) if character==c then
 generation+=1 stop()
 if descendantConnection then descendantConnection:Disconnect() descendantConnection=nil end
 character=nil humanoid=nil root=nil
end end)
if player.Character then task.spawn(added,player.Character) end
Input.InputBegan:Connect(function(input,processed)
 if processed or Input:GetFocusedTextBox() or Gui.MenuIsOpen then return end
 if input.KeyCode==Enum.KeyCode.Q then if flying then stop() else start() end end
end)
Input.WindowFocusReleased:Connect(function() if velocity then velocity.VectorVelocity=Vector3.zero end end)
Run.PreSimulation:Connect(function()
 if not flying then return end
 if not root or not root.Parent or not humanoid or humanoid.Health<=0 then stop() return end
 local camera=workspace.CurrentCamera
 local direction=Vector3.zero
 if camera and not Input:GetFocusedTextBox() and not Gui.MenuIsOpen then
  local function down(key) return Input:IsKeyDown(key) and 1 or 0 end
  direction=camera.CFrame.LookVector*(down(Enum.KeyCode.W)-down(Enum.KeyCode.S))
   +camera.CFrame.RightVector*(down(Enum.KeyCode.D)-down(Enum.KeyCode.A))
   +Vector3.yAxis*(down(Enum.KeyCode.Space)-down(Enum.KeyCode.LeftControl)-down(Enum.KeyCode.RightControl))
  local look=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
  if look.Magnitude>.01 then orientation.CFrame=CFrame.lookAt(Vector3.zero,look) end
 end
 velocity.VectorVelocity=direction.Magnitude>0 and direction.Unit*speed or Vector3.zero
 root.AssemblyAngularVelocity=Vector3.zero
end)
script.Destroying:Connect(function()
 stop()
 if descendantConnection then descendantConnection:Disconnect() end
 gui:Destroy()
end)
script:SetAttribute('NoclipEnabled',false) updateInfo() script:SetAttribute('Ready',true)
]====]
s.Parent=p
print('EXPLORER_FLIGHT_INSTALLED')
