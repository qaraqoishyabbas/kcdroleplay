-- Combat HUD and input: LMB attack or draw bow, RMB block, mouse direction picks the swing.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Net = require(ReplicatedStorage:WaitForChild("CombatNet"))
local remotes = Net.client()

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "CombatHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 18, 1, -18)
panel.Size = UDim2.fromOffset(300, 136)
panel.BackgroundColor3 = Color3.fromRGB(26, 24, 20)
panel.BackgroundTransparency = 0.25
panel.BorderSizePixel = 0
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local function bar(name, y, color)
	local back = Instance.new("Frame")
	back.Name = name .. "Back"
	back.Position = UDim2.fromOffset(12, y)
	back.Size = UDim2.fromOffset(276, 14)
	back.BackgroundColor3 = Color3.fromRGB(48, 46, 40)
	back.BorderSizePixel = 0
	back.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = name
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = fill
	return fill
end

local healthFill = bar("Health", 10, Color3.fromRGB(168, 58, 52))
local staminaFill = bar("Stamina", 32, Color3.fromRGB(196, 172, 92))

local weaponLabel = Instance.new("TextLabel")
weaponLabel.Position = UDim2.fromOffset(12, 52)
weaponLabel.Size = UDim2.fromOffset(276, 20)
weaponLabel.BackgroundTransparency = 1
weaponLabel.Font = Enum.Font.GothamBold
weaponLabel.TextSize = 14
weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponLabel.TextColor3 = Color3.fromRGB(240, 232, 212)
weaponLabel.Text = "Оружие: нет"
weaponLabel.Parent = panel

local armorLabel = Instance.new("TextLabel")
armorLabel.Position = UDim2.fromOffset(12, 74)
armorLabel.Size = UDim2.fromOffset(276, 18)
armorLabel.BackgroundTransparency = 1
armorLabel.Font = Enum.Font.GothamMedium
armorLabel.TextSize = 13
armorLabel.TextXAlignment = Enum.TextXAlignment.Left
armorLabel.TextColor3 = Color3.fromRGB(196, 200, 186)
armorLabel.Text = "Броня: нет"
armorLabel.Parent = panel

local goldLabel = Instance.new("TextLabel")
goldLabel.Position = UDim2.fromOffset(12, 92)
goldLabel.Size = UDim2.fromOffset(276, 18)
goldLabel.BackgroundTransparency = 1
goldLabel.Font = Enum.Font.GothamMedium
goldLabel.TextSize = 13
goldLabel.TextXAlignment = Enum.TextXAlignment.Left
goldLabel.TextColor3 = Color3.fromRGB(196, 172, 92)
goldLabel.Text = "Золото: " .. tostring(player:GetAttribute("Gold") or 0)
goldLabel.Parent = panel

local hints = Instance.new("TextLabel")
hints.Position = UDim2.fromOffset(12, 112)
hints.Size = UDim2.fromOffset(276, 16)
hints.BackgroundTransparency = 1
hints.Font = Enum.Font.GothamMedium
hints.TextSize = 11
hints.TextXAlignment = Enum.TextXAlignment.Left
hints.TextColor3 = Color3.fromRGB(168, 164, 150)
hints.Text = "ЛКМ — удар/выстрел · ПКМ — блок · мышь задаёт направление"
hints.Parent = panel

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.Size = UDim2.fromOffset(6, 6)
crosshair.BackgroundColor3 = Color3.fromRGB(238, 232, 214)
crosshair.BackgroundTransparency = 0.35
crosshair.BorderSizePixel = 0
crosshair.Parent = gui
local crosshairCorner = Instance.new("UICorner")
crosshairCorner.CornerRadius = UDim.new(1, 0)
crosshairCorner.Parent = crosshair

local drawBack = Instance.new("Frame")
drawBack.Name = "DrawBack"
drawBack.AnchorPoint = Vector2.new(0, 0.5)
drawBack.Position = UDim2.new(0.5, 24, 0.5, 0)
drawBack.Size = UDim2.fromOffset(12, 120)
drawBack.BackgroundColor3 = Color3.fromRGB(46, 44, 38)
drawBack.BorderSizePixel = 0
drawBack.Visible = false
drawBack.Parent = gui
local drawFill = Instance.new("Frame")
drawFill.Name = "Draw"
drawFill.AnchorPoint = Vector2.new(0, 1)
drawFill.Position = UDim2.new(0, 0, 1, 0)
drawFill.Size = UDim2.fromScale(1, 0)
drawFill.BackgroundColor3 = Color3.fromRGB(214, 186, 96)
drawFill.BorderSizePixel = 0
drawFill.Parent = drawBack

local notices = Instance.new("Frame")
notices.Name = "Notices"
notices.AnchorPoint = Vector2.new(0, 1)
notices.Position = UDim2.new(0, 18, 1, -162)
notices.Size = UDim2.fromOffset(460, 110)
notices.BackgroundTransparency = 1
notices.Parent = gui
local noticeLayout = Instance.new("UIListLayout")
noticeLayout.SortOrder = Enum.SortOrder.LayoutOrder
noticeLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
noticeLayout.Padding = UDim.new(0, 3)
noticeLayout.Parent = notices

-- ---------------------------------------------------------------- armoury shop
local function itemName(itemId)
	for _, weapon in Config.Weapons do
		if weapon.Id == itemId then
			return weapon.Name
		end
	end
	for _, piece in Config.Armor do
		if piece.Id == itemId then
			return piece.Name
		end
	end
	return itemId
end

local shopPanel = Instance.new("Frame")
shopPanel.Name = "Shop"
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
shopPanel.Size = UDim2.fromOffset(360, 380)
shopPanel.BackgroundColor3 = Color3.fromRGB(30, 27, 22)
shopPanel.BackgroundTransparency = 0.05
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = gui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopPanel

local shopTitle = Instance.new("TextLabel")
shopTitle.Position = UDim2.fromOffset(16, 10)
shopTitle.Size = UDim2.new(1, -32, 0, 26)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 18
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.TextColor3 = Color3.fromRGB(240, 226, 190)
shopTitle.Text = "ОРУЖЕЙНИК"
shopTitle.Parent = shopPanel

local shopGold = Instance.new("TextLabel")
shopGold.Position = UDim2.fromOffset(16, 34)
shopGold.Size = UDim2.new(1, -32, 0, 20)
shopGold.BackgroundTransparency = 1
shopGold.Font = Enum.Font.GothamMedium
shopGold.TextSize = 14
shopGold.TextXAlignment = Enum.TextXAlignment.Left
shopGold.TextColor3 = Color3.fromRGB(226, 200, 120)
shopGold.Text = "Золото: 0"
shopGold.Parent = shopPanel

local shopList = Instance.new("Frame")
shopList.Position = UDim2.fromOffset(16, 62)
shopList.Size = UDim2.new(1, -32, 1, -112)
shopList.BackgroundTransparency = 1
shopList.Parent = shopPanel
local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 4)
shopLayout.Parent = shopList

for _, item in Config.Shop do
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(52, 46, 36)
	row.BorderSizePixel = 0
	row.Font = Enum.Font.GothamMedium
	row.TextSize = 14
	row.TextColor3 = Color3.fromRGB(236, 228, 208)
	row.Text = string.format("%s — %d золота", itemName(item.Id), item.Price)
	row.Parent = shopList
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row
	row.MouseButton1Click:Connect(function()
		remotes.Buy:FireServer(item.Id)
	end)
end

local shopClose = Instance.new("TextButton")
shopClose.AnchorPoint = Vector2.new(0.5, 1)
shopClose.Position = UDim2.new(0.5, 0, 1, -12)
shopClose.Size = UDim2.fromOffset(160, 30)
shopClose.BackgroundColor3 = Color3.fromRGB(60, 52, 40)
shopClose.BorderSizePixel = 0
shopClose.Font = Enum.Font.GothamBold
shopClose.TextSize = 14
shopClose.TextColor3 = Color3.fromRGB(238, 228, 206)
shopClose.Text = "Закрыть"
shopClose.Parent = shopPanel
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = shopClose
shopClose.MouseButton1Click:Connect(function()
	shopPanel.Visible = false
end)

local shopGoldValue = 0

remotes.Shop.OnClientEvent:Connect(function(payload)
	if payload.open == true then
		shopPanel.Visible = true
		shopGoldValue = payload.gold or shopGoldValue
		shopGold.Text = "Золото: " .. tostring(shopGoldValue)
	else
		shopPanel.Visible = false
		shopGoldValue = payload.gold or shopGoldValue
	end
end)

local state = { weaponKind = "None", blocking = false, stamina = 100, staminaMax = 100, gold = 0 }
local drawing = false
local drawStarted = 0
local recentX, recentY = 0, 0

local bowDrawMin, bowDrawMax = 0.35, 1.2
for _, weapon in Config.Weapons do
	if weapon.Kind == "Bow" then
		bowDrawMin = weapon.DrawMin
		bowDrawMax = weapon.DrawMax
	end
end

local function pushNotice(text, kind)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	if kind == "bad" then
		label.TextColor3 = Color3.fromRGB(255, 158, 148)
	elseif kind == "good" then
		label.TextColor3 = Color3.fromRGB(178, 226, 168)
	else
		label.TextColor3 = Color3.fromRGB(228, 226, 212)
	end
	label.LayoutOrder = -math.floor(os.clock() * 10)
	label.Parent = notices
	task.delay(5, function()
		if label.Parent then
			label:Destroy()
		end
	end)
end

remotes.Hud.OnClientEvent:Connect(function(hud)
	if hud.gold ~= nil then
		state.gold = hud.gold
		shopGoldValue = hud.gold
		goldLabel.Text = "Золото: " .. tostring(hud.gold)
		shopGold.Text = goldLabel.Text
	end
	if hud.weaponKind then
		state.weaponKind = hud.weaponKind
	end
	if hud.stamina then
		state.stamina = hud.stamina
		state.staminaMax = hud.staminaMax or state.staminaMax
	end
	if hud.weapon then
		weaponLabel.Text = "Оружие: " .. hud.weapon
	end
	if hud.armor then
		armorLabel.Text = "Броня: " .. hud.armor
	end
	if hud.blocking ~= nil then
		state.blocking = hud.blocking
		panel.BackgroundColor3 = state.blocking and Color3.fromRGB(40, 48, 40) or Color3.fromRGB(26, 24, 20)
	end
end)

remotes.Notice.OnClientEvent:Connect(function(notice)
	pushNotice(notice.text or "", notice.kind)
end)

local function chooseDirection()
	if math.abs(recentX) > 12 and math.abs(recentX) >= math.abs(recentY) then
		return recentX > 0 and "Right" or "Left"
	end
	if recentY < -12 then
		return "Overhead"
	elseif recentY > 12 then
		return "Stab"
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local move = humanoid.MoveDirection
		if move.Z < -0.4 then
			return "Overhead"
		elseif move.Z > 0.4 then
			return "Stab"
		elseif move.X > 0.4 then
			return "Right"
		elseif move.X < -0.4 then
			return "Left"
		end
	end
	return "Right"
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if state.weaponKind == "Bow" then
			drawing = true
			drawStarted = os.clock()
			drawBack.Visible = true
			remotes.DrawStart:FireServer()
		else
			remotes.Attack:FireServer(chooseDirection())
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		remotes.Block:FireServer(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and drawing then
		drawing = false
		drawBack.Visible = false
		drawFill.Size = UDim2.fromScale(1, 0)
		local camera = workspace.CurrentCamera
		remotes.Release:FireServer(camera and camera.CFrame.LookVector or nil)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		remotes.Block:FireServer(false)
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	remotes.Block:FireServer(false)
	if drawing then remotes.DrawStart:FireServer(false) end
	drawing = false
	drawBack.Visible = false
	drawFill.Size = UDim2.fromScale(1, 0)
end)

player.CharacterAdded:Connect(function()
	drawing = false
	drawBack.Visible = false
	drawFill.Size = UDim2.fromScale(1, 0)
	recentX, recentY = 0, 0
end)

local lastHealth, lastStamina, lastDraw = -1, -1, -1
RunService.RenderStepped:Connect(function()
	local delta = UserInputService:GetMouseDelta()
	recentX = recentX * 0.7 + delta.X
	recentY = recentY * 0.7 + delta.Y

	-- Safety: the button can be released outside the window, which would leave the draw stuck.
	if drawing and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		remotes.DrawStart:FireServer(false)
		drawing = false
		drawBack.Visible = false
		drawFill.Size = UDim2.fromScale(1, 0)
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local health = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
		if health ~= lastHealth then healthFill.Size = UDim2.fromScale(health, 1) lastHealth = health end
	end
	local stamina = math.clamp(state.stamina / math.max(1, state.staminaMax), 0, 1)
	if stamina ~= lastStamina then staminaFill.Size = UDim2.fromScale(stamina, 1) lastStamina = stamina end

	if drawing then
		local power = math.clamp((os.clock() - drawStarted - bowDrawMin) / math.max(0.01, bowDrawMax - bowDrawMin), 0, 1)
		if power ~= lastDraw then drawFill.Size = UDim2.fromScale(1, power) lastDraw = power end
	end
end)
