-- MonsterCollectionUI.lua (Fixed - Complete Version)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MonsterImages = ReplicatedStorage:FindFirstChild("MonsterImages")
local player = Players.LocalPlayer
local screenGui = script.Parent

-- Get UI elements
local collectionFrame = screenGui:WaitForChild("CollectionFrame")
local closeButton = collectionFrame:WaitForChild("CloseButton")
local catchButton = collectionFrame:WaitForChild("CatchButton")
local sellButton = collectionFrame:WaitForChild("SellButton")

local titleLabel = collectionFrame:WaitForChild("TitleLabel")
local monsterName = collectionFrame:WaitForChild("MonsterName")
local elementLabel = collectionFrame:WaitForChild("ElementLabel")
local rarityLabel = collectionFrame:WaitForChild("RarityLabel")
local hpLabel = collectionFrame:WaitForChild("HPLabel")
local attackLabel = collectionFrame:WaitForChild("AttackLabel")
local speedLabel = collectionFrame:WaitForChild("SpeedLabel")
local levelLabel = collectionFrame:WaitForChild("LevelLabel")

local monsterImage = collectionFrame:WaitForChild("ImageLabel")

local defenseLabel = collectionFrame:FindFirstChild("DefenseLabel") or 
	collectionFrame:FindFirstChild("DFNLabel") or
	collectionFrame:FindFirstChild("DefLabel")

-- Remote events
local showMonsterRemote = ReplicatedStorage:WaitForChild("ShowMonster")

local monsterCollectionRemote = ReplicatedStorage:FindFirstChild("MonsterCollection")
if not monsterCollectionRemote then
	monsterCollectionRemote = Instance.new("RemoteEvent")
	monsterCollectionRemote.Name = "MonsterCollection"
	monsterCollectionRemote.Parent = ReplicatedStorage
end

-- Color schemes
local ElementColors = {
	Fire = Color3.fromRGB(255, 87, 34),
	Water = Color3.fromRGB(33, 150, 243),
	Earth = Color3.fromRGB(121, 85, 72),
	Plant = Color3.fromRGB(76, 175, 80),
	Electric = Color3.fromRGB(255, 235, 59)
}

local RarityColors = {
	Common = Color3.fromRGB(158, 158, 158),
	Rare = Color3.fromRGB(33, 150, 243),
	Epic = Color3.fromRGB(156, 39, 176),
	Legendary = Color3.fromRGB(255, 193, 7)
}

local ElementIcons = {
	Fire = "??",
	Water = "??", 
	Earth = "??",
	Plant = "??",
	Electric = "?"
}

local currentMonsterData = nil

-- Animation functions (DEFINE FIRST)
local function animateButtonPress(button)
	local originalSize = button.Size
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

	-- Calculate new size (scale down by 5%)
	local newSize = UDim2.new(
		originalSize.X.Scale * 0.95,
		originalSize.X.Offset * 0.95,
		originalSize.Y.Scale * 0.95,
		originalSize.Y.Offset * 0.95
	)

	local tween = TweenService:Create(button, tweenInfo, {Size = newSize})
	tween:Play()
end

local function showFrame()
	collectionFrame.Visible = true
end

local function hideFrame()
	collectionFrame.Visible = false
end

-- Update monster display with dual elements
local function updateMonsterDisplay(monsterData)
	currentMonsterData = monsterData

	titleLabel.Text = "?? MONSTER HATCHED!"

	-- Monster name
	monsterName.Text = monsterData.Name
	monsterName.TextColor3 = RarityColors[monsterData.Rarity] or Color3.fromRGB(255, 255, 255)

	-- DUAL ELEMENT DISPLAY
	if type(monsterData.Elements) == "table" and #monsterData.Elements > 1 then
		-- Hybrid with 2 elements
		local icon1 = ElementIcons[monsterData.Elements[1]] or "?"
		local icon2 = ElementIcons[monsterData.Elements[2]] or "?"
		elementLabel.Text = icon1 .. " " .. monsterData.Elements[1] .. " • " .. icon2 .. " " .. monsterData.Elements[2]
		elementLabel.TextColor3 = ElementColors[monsterData.Elements[1]] or Color3.fromRGB(200, 200, 200)
	elseif type(monsterData.Elements) == "table" then
		-- Single element in array
		local element = monsterData.Elements[1]
		elementLabel.Text = (ElementIcons[element] or "?") .. " " .. element
		elementLabel.TextColor3 = ElementColors[element] or Color3.fromRGB(200, 200, 200)
	else
		-- Legacy single element (fallback)
		local element = monsterData.Element or "Unknown"
		elementLabel.Text = (ElementIcons[element] or "?") .. " " .. element
		elementLabel.TextColor3 = ElementColors[element] or Color3.fromRGB(200, 200, 200)
	end

	-- Rarity
	rarityLabel.Text = monsterData.Rarity
	rarityLabel.TextColor3 = RarityColors[monsterData.Rarity] or Color3.fromRGB(150, 150, 150)

	-- Stats
	hpLabel.Text = "HP: " .. monsterData.HP
	attackLabel.Text = "ATK: " .. monsterData.Attack
	speedLabel.Text = "SPD: " .. monsterData.Speed
	levelLabel.Text = "LVL: " .. monsterData.Level

	if defenseLabel then
		defenseLabel.Text = "DEF: " .. monsterData.Defense
	end

	-- Stat colors
	hpLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	attackLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
	speedLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

	if defenseLabel then
		defenseLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
	end

	-- Set monster image
	if MonsterImages then
		local imageValue = MonsterImages:FindFirstChild(monsterData.Name)
		if imageValue and imageValue.Value ~= "" then
			monsterImage.Image = imageValue.Value
			monsterImage.BackgroundTransparency = 0
			monsterImage.ImageTransparency = 0
			monsterImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		else
			monsterImage.Image = ""
			local primaryElement = type(monsterData.Elements) == "table" and monsterData.Elements[1] or monsterData.Element
			monsterImage.BackgroundColor3 = ElementColors[primaryElement] or Color3.fromRGB(100, 100, 100)
			monsterImage.BackgroundTransparency = 0.7
		end
	else
		monsterImage.Image = ""
		local primaryElement = type(monsterData.Elements) == "table" and monsterData.Elements[1] or monsterData.Element
		monsterImage.BackgroundColor3 = ElementColors[primaryElement] or Color3.fromRGB(100, 100, 100)
		monsterImage.BackgroundTransparency = 0.7
	end

	showFrame()

	print("?? Monster:", monsterData.Name, "| Quality:", monsterData.StatQuality or "N/A")
	print("?? Elements:", monsterData.Elements)
end

-- Button handlers
catchButton.MouseButton1Click:Connect(function()
	animateButtonPress(catchButton)

	if currentMonsterData then
		print("?? Catching monster:", currentMonsterData.Name)
		monsterCollectionRemote:FireServer("catch", currentMonsterData.Id, currentMonsterData)
		hideFrame()
	end
end)

sellButton.MouseButton1Click:Connect(function()
	animateButtonPress(sellButton)

	if currentMonsterData then
		print("?? Selling monster:", currentMonsterData.Name, "for", currentMonsterData.SellValue)
		monsterCollectionRemote:FireServer("sell", currentMonsterData.Id, currentMonsterData)
		hideFrame()
	end
end)

closeButton.MouseButton1Click:Connect(function()
	animateButtonPress(closeButton)
	hideFrame()
end)

-- Listen for monster display
showMonsterRemote.OnClientEvent:Connect(function(monsterData)
	print("?? CLIENT: Received monster data:", monsterData)
	updateMonsterDisplay(monsterData)
end)

-- Initialize as hidden
collectionFrame.Visible = false

print("? Monster Collection UI with Dual Elements loaded!")