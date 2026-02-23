-- HabitatMonsterSelectionController.lua (COMPLETE - REDESIGNED WITH SLOTS & POPUP)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

-- Get UI References
local mainFrame = gui:WaitForChild("MainFrame")
local titleBar = mainFrame:WaitForChild("TitleBar")
local titleText = titleBar:WaitForChild("TitleText")
local closeButton = titleBar:WaitForChild("CloseButton")

-- Info Panel
local infoPanel = mainFrame:WaitForChild("InfoPanel")
local habitatNameLabel = infoPanel:WaitForChild("HabitatNameLabel")
local levelLabel = infoPanel:WaitForChild("LevelLabel")
local capacityLabel = infoPanel:WaitForChild("CapacityLabel")
local upgradeButton = infoPanel:WaitForChild("UpgradeButton")

-- Content Frame (will hold monster slots)
local contentFrame = mainFrame:WaitForChild("ContentFrame")

-- Income Display
local incomeContainer = mainFrame:WaitForChild("IncomeContainer")
local incomeLabel = incomeContainer:WaitForChild("IncomeLabel")

-- Monster Selection Popup
local monsterPopup = mainFrame:WaitForChild("MonsterSelectionPopup")
local popupTitleBar = monsterPopup:WaitForChild("PopupTitleBar")
local popupTitle = popupTitleBar:WaitForChild("PopupTitle")
local popupContent = monsterPopup:WaitForChild("PopupContent")
local cancelButton = monsterPopup:WaitForChild("CancelButton")

-- Get Monster Images folder
local MonsterImages = ReplicatedStorage:FindFirstChild("MonsterImages")

-- Remote Events
local placeMonsterInHabitatRemote = ReplicatedStorage:WaitForChild("PlaceMonsterInHabitat")

local removeMonsterFromHabitatRemote = ReplicatedStorage:FindFirstChild("RemoveMonsterFromHabitat")
if not removeMonsterFromHabitatRemote then
	removeMonsterFromHabitatRemote = Instance.new("RemoteEvent")
	removeMonsterFromHabitatRemote.Name = "RemoveMonsterFromHabitat"
	removeMonsterFromHabitatRemote.Parent = ReplicatedStorage
end

local upgradeHabitatRemote = ReplicatedStorage:FindFirstChild("UpgradeHabitat")
if not upgradeHabitatRemote then
	upgradeHabitatRemote = Instance.new("RemoteEvent")
	upgradeHabitatRemote.Name = "UpgradeHabitat"
	upgradeHabitatRemote.Parent = ReplicatedStorage
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

-- Variables
local currentHabitatData = nil
local currentSlotIndex = nil
local monstersInSlots = {}

-- Upgrade costs and data
local UPGRADE_DATA = {
	[1] = {cost = 500, maxCapacity = 3, incomeMultiplier = 1.5, stars = "??"},
	[2] = {cost = 1500, maxCapacity = 4, incomeMultiplier = 2.0, stars = "???"}
}

-- Function to calculate income preview
local function calculateIncomePreview(monsterData)
	local baseIncome = 5
	local rarityMultipliers = {
		Common = 1,
		Rare = 2,
		Epic = 4,
		Legendary = 8
	}
	local elementMultipliers = {
		Fire = 1,
		Water = 1,
		Earth = 1.2,
		Plant = 1.1,
		Electric = 1.3
	}

	local rarityMult = rarityMultipliers[monsterData.rarity] or 1
	local elementMult = elementMultipliers[monsterData.element] or 1
	local levelMult = monsterData.level * 0.1 + 1
	local habitatLevelMult = currentHabitatData and (currentHabitatData.level == 2 and 1.5 or currentHabitatData.level == 3 and 2.0 or 1.0) or 1.0

	return math.floor(baseIncome * rarityMult * elementMult * levelMult * habitatLevelMult)
end

-- Function to update total income display
local function updateIncomeDisplay()
	local totalIncome = 0

	for slotIndex, monsterData in pairs(monstersInSlots) do
		if monsterData then
			totalIncome = totalIncome + calculateIncomePreview(monsterData)
		end
	end

	incomeLabel.Text = "?? Total Income: " .. totalIncome .. " coins/min"
end

-- Function to create monster card for popup selection
local function createMonsterSelectionCard(monsterData, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = monsterData.uniqueId
	card.Size = UDim2.new(0, 170, 0, 160)
	card.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	-- Monster Image
	local monsterImage = Instance.new("ImageLabel")
	monsterImage.Size = UDim2.new(0, 60, 0, 60)
	monsterImage.Position = UDim2.new(0.5, -30, 0, 10)
	monsterImage.BackgroundColor3 = ElementColors[monsterData.element] or Color3.fromRGB(100, 100, 100)
	monsterImage.BackgroundTransparency = 0.3
	monsterImage.BorderSizePixel = 0
	monsterImage.Image = ""
	monsterImage.Parent = card

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 10)
	imageCorner.Parent = monsterImage

	-- Set monster image if available
	if MonsterImages then
		local imageValue = MonsterImages:FindFirstChild(monsterData.name)
		if imageValue and imageValue.Value ~= "" then
			monsterImage.Image = imageValue.Value
			monsterImage.BackgroundTransparency = 0
		end
	end

	-- Monster Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 25)
	nameLabel.Position = UDim2.new(0, 5, 0, 75)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = monsterData.name
	nameLabel.TextColor3 = RarityColors[monsterData.rarity] or Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Level & Rarity
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -10, 0, 18)
	infoLabel.Position = UDim2.new(0, 5, 0, 100)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "LVL " .. monsterData.level .. " • " .. monsterData.rarity
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextSize = 11
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.Parent = card

	-- Income Preview
	local incomePreview = calculateIncomePreview(monsterData)
	local incomePreviewLabel = Instance.new("TextLabel")
	incomePreviewLabel.Size = UDim2.new(1, -10, 0, 18)
	incomePreviewLabel.Position = UDim2.new(0, 5, 0, 118)
	incomePreviewLabel.BackgroundTransparency = 1
	incomePreviewLabel.Text = "?? " .. incomePreview .. "/min"
	incomePreviewLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	incomePreviewLabel.TextSize = 11
	incomePreviewLabel.Font = Enum.Font.GothamBold
	incomePreviewLabel.Parent = card

	-- Select Button
	local selectButton = Instance.new("TextButton")
	selectButton.Size = UDim2.new(0, 70, 0, 22)
	selectButton.Position = UDim2.new(1, -75, 1, -27)
	selectButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	selectButton.Text = "SELECT"
	selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectButton.TextSize = 11
	selectButton.Font = Enum.Font.GothamBold
	selectButton.BorderSizePixel = 0
	selectButton.Parent = card

	local selectCorner = Instance.new("UICorner")
	selectCorner.CornerRadius = UDim.new(0, 5)
	selectCorner.Parent = selectButton

	-- Select button functionality
	selectButton.MouseButton1Click:Connect(function()
		if currentHabitatData and currentSlotIndex then
			-- Place monster in slot
			placeMonsterInHabitatRemote:FireServer(
				monsterData.uniqueId, 
				currentHabitatData.habitatId, 
				currentHabitatData
			)

			-- Store monster in slot locally (will be updated when reopening UI)
			monstersInSlots[currentSlotIndex] = monsterData

			-- Close popup
			hideMonsterSelectionPopup()

			-- Refresh the main UI
			task.wait(0.2)
			showHabitatSelection(currentHabitatData)
		end
	end)

	-- Hover effects
	card.MouseEnter:Connect(function()
		local tween = TweenService:Create(card, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(55, 55, 75)
		})
		tween:Play()
	end)

	card.MouseLeave:Connect(function()
		local tween = TweenService:Create(card, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		})
		tween:Play()
	end)

	return card
end

-- Function to show monster selection popup
local function showMonsterSelectionPopup(slotIndex, habitatElement)
	currentSlotIndex = slotIndex

	-- Update popup title
	popupTitle.Text = "SELECT MONSTER FOR SLOT " .. slotIndex

	-- Clear existing cards
	for _, child in pairs(popupContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Get monsters from player folder filtered by element
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then
		-- Show no monsters message
		local noMonstersLabel = Instance.new("TextLabel")
		noMonstersLabel.Size = UDim2.new(1, -20, 0, 100)
		noMonstersLabel.Position = UDim2.new(0, 10, 0, 50)
		noMonstersLabel.BackgroundTransparency = 1
		noMonstersLabel.Text = "No " .. habitatElement .. " monsters available!\n\nCatch some first."
		noMonstersLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noMonstersLabel.TextSize = 16
		noMonstersLabel.Font = Enum.Font.Gotham
		noMonstersLabel.TextWrapped = true
		noMonstersLabel.Parent = popupContent

		popupContent.CanvasSize = UDim2.new(0, 0, 0, 150)
		monsterPopup.Visible = true
		return
	end

	-- Filter compatible monsters
	local compatibleMonsters = {}
	for _, monster in pairs(monstersFolder:GetChildren()) do
		if monster:IsA("Folder") then
			local elementValue = monster:FindFirstChild("Element")
			if elementValue and elementValue.Value == habitatElement then
				local monsterData = {
					uniqueId = monster.Name,
					name = (monster:FindFirstChild("Name") and monster:FindFirstChild("Name").Value) or 
						(monster:FindFirstChild("MonsterName") and monster:FindFirstChild("MonsterName").Value) or "Unknown",
					element = elementValue.Value,
					rarity = monster:FindFirstChild("Rarity") and monster:FindFirstChild("Rarity").Value or "Common",
					level = monster:FindFirstChild("Level") and monster:FindFirstChild("Level").Value or 1
				}
				table.insert(compatibleMonsters, monsterData)
			end
		end
	end

	-- Create cards for compatible monsters
	if #compatibleMonsters == 0 then
		local noMonstersLabel = Instance.new("TextLabel")
		noMonstersLabel.Size = UDim2.new(1, -20, 0, 100)
		noMonstersLabel.Position = UDim2.new(0, 10, 0, 50)
		noMonstersLabel.BackgroundTransparency = 1
		noMonstersLabel.Text = "No " .. habitatElement .. " monsters in collection!"
		noMonstersLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noMonstersLabel.TextSize = 16
		noMonstersLabel.Font = Enum.Font.Gotham
		noMonstersLabel.Parent = popupContent

		popupContent.CanvasSize = UDim2.new(0, 0, 0, 150)
	else
		for i, monsterData in ipairs(compatibleMonsters) do
			local card = createMonsterSelectionCard(monsterData, i)
			card.Parent = popupContent
		end

		-- Update canvas size
		popupContent.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#compatibleMonsters / 3) * 175 + 20)
	end

	-- Show popup with animation
	monsterPopup.Visible = true
	monsterPopup.Size = UDim2.new(0, 0, 0, 0)
	monsterPopup.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(monsterPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 600, 0, 500),
		Position = UDim2.new(0.5, -300, 0.5, -250)
	})
	tween:Play()
end

-- Function to hide monster selection popup
function hideMonsterSelectionPopup()
	local tween = TweenService:Create(monsterPopup, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		monsterPopup.Visible = false
		currentSlotIndex = nil
	end)
end

-- Function to create a monster slot card
local function createMonsterSlot(slotIndex, maxCapacity, monsterData)
	local isLocked = slotIndex > maxCapacity

	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. slotIndex
	slot.Size = UDim2.new(0, 180, 0, 220)
	slot.BackgroundColor3 = isLocked and Color3.fromRGB(35, 35, 50) or Color3.fromRGB(50, 50, 70)
	slot.BorderSizePixel = 0
	slot.LayoutOrder = slotIndex

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 12)
	slotCorner.Parent = slot

	if isLocked then
		-- Locked slot display
		local lockIcon = Instance.new("TextLabel")
		lockIcon.Size = UDim2.new(1, 0, 0, 60)
		lockIcon.Position = UDim2.new(0, 0, 0, 60)
		lockIcon.BackgroundTransparency = 1
		lockIcon.Text = "??"
		lockIcon.TextSize = 40
		lockIcon.Parent = slot

		local lockText = Instance.new("TextLabel")
		lockText.Size = UDim2.new(1, -20, 0, 40)
		lockText.Position = UDim2.new(0, 10, 0, 130)
		lockText.BackgroundTransparency = 1
		lockText.Text = "LOCKED\n\nUpgrade habitat to unlock"
		lockText.TextColor3 = Color3.fromRGB(120, 120, 120)
		lockText.TextSize = 12
		lockText.Font = Enum.Font.Gotham
		lockText.TextWrapped = true
		lockText.Parent = slot

	elseif monsterData then
		-- Filled slot with monster
		local monsterImage = Instance.new("ImageLabel")
		monsterImage.Size = UDim2.new(0, 80, 0, 80)
		monsterImage.Position = UDim2.new(0.5, -40, 0, 15)
		monsterImage.BackgroundColor3 = ElementColors[monsterData.element] or Color3.fromRGB(100, 100, 100)
		monsterImage.BackgroundTransparency = 0.3
		monsterImage.BorderSizePixel = 0
		monsterImage.Image = ""
		monsterImage.Parent = slot

		local imageCorner = Instance.new("UICorner")
		imageCorner.CornerRadius = UDim.new(0, 12)
		imageCorner.Parent = monsterImage

		-- Set image if available
		if MonsterImages then
			local imageValue = MonsterImages:FindFirstChild(monsterData.name)
			if imageValue and imageValue.Value ~= "" then
				monsterImage.Image = imageValue.Value
				monsterImage.BackgroundTransparency = 0
			end
		end

		-- Monster name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -10, 0, 25)
		nameLabel.Position = UDim2.new(0, 5, 0, 100)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = monsterData.name
		nameLabel.TextColor3 = RarityColors[monsterData.rarity] or Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextWrapped = true
		nameLabel.Parent = slot

		-- Level & Rarity
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(1, -10, 0, 20)
		infoLabel.Position = UDim2.new(0, 5, 0, 125)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "LVL " .. monsterData.level .. " • " .. monsterData.rarity
		infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		infoLabel.TextSize = 11
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.Parent = slot

		-- Income display
		local income = calculateIncomePreview(monsterData)
		local incomeSlotLabel = Instance.new("TextLabel")
		incomeSlotLabel.Size = UDim2.new(1, -10, 0, 20)
		incomeSlotLabel.Position = UDim2.new(0, 5, 0, 145)
		incomeSlotLabel.BackgroundTransparency = 1
		incomeSlotLabel.Text = "?? " .. income .. " coins/min"
		incomeSlotLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		incomeSlotLabel.TextSize = 12
		incomeSlotLabel.Font = Enum.Font.GothamBold
		incomeSlotLabel.Parent = slot

		-- Remove button
		local removeButton = Instance.new("TextButton")
		removeButton.Size = UDim2.new(0, 70, 0, 28)
		removeButton.Position = UDim2.new(0.5, -35, 1, -38)
		removeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		removeButton.Text = "? REMOVE"
		removeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		removeButton.TextSize = 11
		removeButton.Font = Enum.Font.GothamBold
		removeButton.BorderSizePixel = 0
		removeButton.Parent = slot

		local removeCorner = Instance.new("UICorner")
		removeCorner.CornerRadius = UDim.new(0, 6)
		removeCorner.Parent = removeButton

		-- Remove button functionality
		removeButton.MouseButton1Click:Connect(function()
			removeMonsterFromHabitatRemote:FireServer(currentHabitatData.habitatId, slotIndex)
			monstersInSlots[slotIndex] = nil

			-- Refresh UI
			task.wait(0.2)
			showHabitatSelection(currentHabitatData)
		end)

	else
		-- Empty slot - show add button
		local addIcon = Instance.new("TextLabel")
		addIcon.Size = UDim2.new(1, 0, 0, 80)
		addIcon.Position = UDim2.new(0, 0, 0, 50)
		addIcon.BackgroundTransparency = 1
		addIcon.Text = "+"
		addIcon.TextSize = 60
		addIcon.TextColor3 = Color3.fromRGB(100, 100, 120)
		addIcon.Font = Enum.Font.GothamBold
		addIcon.Parent = slot

		local emptyText = Instance.new("TextLabel")
		emptyText.Size = UDim2.new(1, -10, 0, 30)
		emptyText.Position = UDim2.new(0, 5, 0, 135)
		emptyText.BackgroundTransparency = 1
		emptyText.Text = "EMPTY SLOT\n\nClick to add monster"
		emptyText.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyText.TextSize = 12
		emptyText.Font = Enum.Font.Gotham
		emptyText.TextWrapped = true
		emptyText.Parent = slot

		-- Make slot clickable
		local clickButton = Instance.new("TextButton")
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.Parent = slot

		clickButton.MouseButton1Click:Connect(function()
			if currentHabitatData then
				showMonsterSelectionPopup(slotIndex, currentHabitatData.element)
			end
		end)

		-- Hover effect
		clickButton.MouseEnter:Connect(function()
			slot.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		end)

		clickButton.MouseLeave:Connect(function()
			slot.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		end)
	end

	return slot
end

-- Function to show habitat selection UI
function showHabitatSelection(habitatData)
	currentHabitatData = habitatData

	-- Update UI colors and text
	local elementColor = ElementColors[habitatData.element] or Color3.fromRGB(255, 255, 255)
	local elementIcon = ElementIcons[habitatData.element] or "?"

	-- Update title
	titleText.Text = elementIcon .. " SELECT " .. habitatData.element:upper() .. " MONSTER FOR HABITAT"
	titleText.TextColor3 = elementColor

	-- Update habitat name
	habitatNameLabel.Text = habitatData.element:upper() .. " HABITAT"
	habitatNameLabel.TextColor3 = elementColor

	-- Update level display
	local level = habitatData.level or 1
	local maxLevel = 3
	local starsText = ""
	for i = 1, maxLevel do
		if i <= level then
			starsText = starsText .. "?"
		else
			starsText = starsText .. "?"
		end
	end
	levelLabel.Text = "LEVEL: " .. level .. " " .. starsText

	-- Update capacity
	local currentMonsters = habitatData.currentMonsters or 0
	local maxCapacity = habitatData.maxCapacity or 2
	capacityLabel.Text = "CAPACITY " .. currentMonsters .. "/" .. maxCapacity

	-- Update upgrade button
	if level < maxLevel then
		local upgradeData = UPGRADE_DATA[level]
		upgradeButton.Text = "? UPGRADE - " .. upgradeData.cost
		upgradeButton.Visible = true
	else
		upgradeButton.Visible = false
	end

	-- Clear existing slots
	for _, child in pairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Reset monsters in slots
	monstersInSlots = {}

	-- Get monsters currently in habitat from the world
	local plotName = player:GetAttribute("AssignedPlot")
	local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
	if plot then
		local habitat = plot:FindFirstChild(habitatData.habitatId)
		if habitat then
			-- Count monsters in habitat
			local monsterIndex = 1
			for _, child in pairs(habitat:GetChildren()) do
				if child:IsA("BasePart") and child.Name == "Monster" then
					-- Extract monster data from attributes
					monstersInSlots[monsterIndex] = {
						name = child:GetAttribute("MonsterName") or "Unknown",
						element = child:GetAttribute("Element") or habitatData.element,
						rarity = child:GetAttribute("Rarity") or "Common",
						level = child:GetAttribute("Level") or 1
					}
					monsterIndex = monsterIndex + 1
				end
			end
		end
	end

	-- Create slots (max 4 slots for level 3)
	local maxSlots = 4
	for i = 1, maxSlots do
		local monsterData = monstersInSlots[i]
		local slot = createMonsterSlot(i, maxCapacity, monsterData)
		slot.Parent = contentFrame
	end

	-- Update income display
	updateIncomeDisplay()

	-- Show main frame with animation
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 900, 0, 650),
		Position = UDim2.new(0.5, -450, 0.5, -325)
	})
	tween:Play()

	print("?? Opened habitat selection for:", habitatData.element, "Level:", level)
end

-- Function to hide habitat selection UI
local function hideHabitatSelection()
	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		mainFrame.Visible = false
		currentHabitatData = nil
		monstersInSlots = {}
	end)
end

-- Event connections
closeButton.MouseButton1Click:Connect(function()
	hideHabitatSelection()
end)

cancelButton.MouseButton1Click:Connect(function()
	hideMonsterSelectionPopup()
end)

-- Handle upgrade button
upgradeButton.MouseButton1Click:Connect(function()
	if not currentHabitatData then return end

	local currentLevel = currentHabitatData.level or 1
	if currentLevel >= 3 then
		print("?? Habitat already at max level!")
		return
	end

	local upgradeData = UPGRADE_DATA[currentLevel]
	if not upgradeData then return end

	-- Check if player has enough coins
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	if coins and coins.Value >= upgradeData.cost then
		-- Send upgrade request to server
		upgradeHabitatRemote:FireServer(currentHabitatData.habitatId)

		-- Temporarily
		-- Temporarily disable button to prevent spam
		upgradeButton.Text = "? UPGRADING..."
		upgradeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		task.wait(0.5)

		-- Refresh UI (level will be updated by server)
		hideHabitatSelection()

	else
		-- Not enough coins - show feedback
		local originalText = upgradeButton.Text
		local originalColor = upgradeButton.BackgroundColor3

		upgradeButton.Text = "? NOT ENOUGH COINS!"
		upgradeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)

		task.wait(1.5)

		upgradeButton.Text = originalText
		upgradeButton.BackgroundColor3 = originalColor
	end
end)

-- Global function for habitat interaction system
_G.ShowHabitatSelection = showHabitatSelection

-- Initialize as hidden
mainFrame.Visible = false
monsterPopup.Visible = false

print("? Habitat Monster Selection Controller loaded with SLOTS & UPGRADE system!")

--[[
?? NEW HABITAT UI FEATURES:
? Visual monster slots (shows filled/empty/locked)
? Monster selection popup (filtered by element)
? Upgrade button with cost display
? Level display with stars (???)
? Total income calculator
? Remove monster functionality
? Clean slot-based layout
? Responsive animations

?? USER FLOW:
1. Walk near habitat ? Press E
2. See slots (filled monsters or empty [+])
3. Click empty slot ? Popup opens
4. Select monster from filtered list
5. Monster appears in slot
6. Click REMOVE to take monster back
7. Click UPGRADE when ready

?? STILL NEEDED:
- Server-side upgrade handler
- Server-side monster removal handler
- Update GameDataManager for habitat levels
--]]