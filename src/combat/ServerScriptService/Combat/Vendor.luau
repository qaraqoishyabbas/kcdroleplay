-- Local-asset R6 shopkeeper. Built in edit mode by the installer and reused at runtime.
-- No avatar downloads, animation loop, AI loop or moving physics assembly.
local Vendor = {}
Vendor.Version = 2

function Vendor.ensure(point)
	local existing = point:FindFirstChild("WeaponVendor")
	if existing and existing:GetAttribute("AppearanceVersion") == Vendor.Version then
		-- Humanoid initialization can restore Torso.CanCollide on place load.
		for _, part in existing:GetDescendants() do
			if part:IsA("BasePart") then part.CanCollide=false part.CanTouch=false part.CanQuery=false end
		end
		return existing
	end
	if existing then existing:Destroy() end
	-- Remove only the generated three-piece placeholder from the old installer.
	for _, child in point:GetChildren() do
		if child.Name == "Torso" or child.Name == "Head" or child.Name == "Hood" or child:IsA("BillboardGui") then
			child:Destroy()
		end
	end

	local model = Instance.new("Model")
	model.Name = "WeaponVendor"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("AppearanceVersion", Vendor.Version)
	local origin = CFrame.new(point.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.pi, 0)
	local skin = Color3.fromRGB(204, 165, 126)
	local tunic = Color3.fromRGB(183, 170, 136)
	local leather = Color3.fromRGB(121, 81, 56)
	local dark = Color3.fromRGB(85, 68, 56)

	local function part(name, size, offset, color)
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.CFrame = origin * offset
		item.Color = color
		item.Material = (name=="Head" or name=="Left Arm" or name=="Right Arm") and Enum.Material.SmoothPlastic or Enum.Material.Fabric
		item.CanCollide = false
		item.CanTouch = false
		item.CanQuery = false
		item.CastShadow = false
		item.Massless = true
		item.TopSurface = Enum.SurfaceType.Smooth
		item.BottomSurface = Enum.SurfaceType.Smooth
		item.Parent = model
		return item
	end
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(), tunic)
	root.Anchored = true
	root.Transparency = 1
	local torso = part("Torso", Vector3.new(2, 2, 1), CFrame.new(), tunic)
	local head = part("Head", Vector3.new(2, 1, 1), CFrame.new(0, 1.5, 0), skin)
	local leftArm = part("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0), skin)
	local rightArm = part("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0), skin)
	local leftLeg = part("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0), dark)
	local rightLeg = part("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0), dark)

	local function joint(name, a, b, c0, c1)
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = a
		motor.Part1 = b
		motor.C0 = c0
		motor.C1 = c1
		motor.Parent = a
	end
	joint("RootJoint", root, torso, CFrame.new(), CFrame.new())
	joint("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	joint("Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
	joint("Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
	joint("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
	joint("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.2, 1.2, 1.2)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head

	local function garment(name, anchor, size, offset, color, material)
		local item = part(name, size, CFrame.new(), color)
		item.Material = material or Enum.Material.Leather
		item.CFrame = anchor.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = anchor
		weld.Part1 = item
		weld.Parent = item
		return item
	end
	garment("LeatherApron", torso, Vector3.new(1.65, 2.4, 0.12), CFrame.new(0, -0.45, -0.57), leather)
	garment("ApronStrap", torso, Vector3.new(0.22, 1.8, 0.12), CFrame.new(-0.5, 0.25, -0.59), dark)
	garment("Belt", torso, Vector3.new(2.08, 0.22, 1.08), CFrame.new(0, -0.65, 0), dark)
	garment("Buckle", torso, Vector3.new(0.34, 0.3, 0.12), CFrame.new(0, -0.65, -0.63), Color3.fromRGB(91,94,92), Enum.Material.Metal)
	garment("LeftSleeve", leftArm, Vector3.new(1.04, 1.05, 1.04), CFrame.new(0, 0.48, 0), tunic, Enum.Material.Fabric)
	garment("RightSleeve", rightArm, Vector3.new(1.04, 1.05, 1.04), CFrame.new(0, 0.48, 0), tunic, Enum.Material.Fabric)
	garment("LeftBoot", leftLeg, Vector3.new(1.06, 0.65, 1.15), CFrame.new(0, -0.67, -0.04), leather)
	garment("RightBoot", rightLeg, Vector3.new(1.06, 0.65, 1.15), CFrame.new(0, -0.67, -0.04), leather)
	local cap = garment("MerchantCap", head, Vector3.new(2.05, 0.65, 1.45), CFrame.new(0, 0.68, 0.05), dark, Enum.Material.Fabric)
	cap.Shape = Enum.PartType.Ball

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = "Оружейник"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.BreakJointsOnDeath = false
	humanoid.EvaluateStateMachine = false
	humanoid.Parent = model
	model.PrimaryPart = root

	local board = Instance.new("BillboardGui")
	board.Name = "VendorLabel"
	board.Size = UDim2.fromOffset(180, 32)
	board.StudsOffset = Vector3.new(0, 1.6, 0)
	board.MaxDistance = 70
	board.AlwaysOnTop = false
	board.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(240, 224, 186)
	label.Text = "ОРУЖЕЙНИК"
	label.Parent = board
	model.Parent = point
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then item.CanCollide=false item.CanTouch=false item.CanQuery=false end
	end
	return model
end

return Vendor
