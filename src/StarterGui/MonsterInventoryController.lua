-- MonsterInventoryController.lua (COMPLETE - WITH DUAL ELEMENT SUPPORT)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

-- Get UI References
local monsterButton = gui:WaitForChild("MonsterButton")
local mainFrame = gui:WaitForChild("MainFrame")
local titleBar = mainFrame:WaitForChild("TitleBar")
local closeButton = titleBar:WaitForChild("CloseButton")
local filterBar = mainFrame:WaitForChild("FilterBar")
local searchBar = filterBar:WaitForChild("SearchBar")
local filterButtons = filterBar:WaitForChild("FilterButtons")
local contentFrame = mainFrame:WaitForChild("ContentFrame")

-- Filter buttons
local sortButton = filterButtons:WaitForChild("SortButton")
local allButton = filterButtons:WaitForChild("AllButton")
local fireButton = filterButtons:WaitForChild("FireButton")
local waterButton = filterButtons:WaitForChild("WaterButton")
local earthButton = filterButtons:WaitForChild("EarthButton")
local plantButton = filterButtons:WaitForChild("PlantButton")
local electricButton = filterButtons:WaitForChild("ElectricButton")

-- Detail Frame References
local detailFrame = gui:WaitForChild("DetailFrame")
local detailTitleBar = detailFrame:WaitForChild("DetailTitleBar")
local detailCloseButton = detailTitleBar:WaitForChild("DetailCloseButton")
local monsterImage = detailFrame:WaitForChild("MonsterImage")
local nameLabel = detailFrame:WaitForChild("NameLabel")
local elementLabel = detailFrame:WaitForChild("ElementLabel")
local rarityLabel = detailFrame:WaitForChild("RarityLabel")
local levelLabel = detailFrame:WaitForChild("LevelLabel")
local hpLabel = detailFrame:WaitForChild("HPLabel")
local attackLabel = detailFrame:WaitForChild("AttackLabel")
local defenseLabel = detailFrame:WaitForChild("DefenseLabel")
local speedLabel = detailFrame:WaitForChild("SpeedLabel")

-- Get Monster Images folder
local MonsterImages = ReplicatedStorage:FindFirstChild("MonsterImages")

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

local RarityOrder = {
	Common = 1,
	Rare = 2,
	Epic = 3,
	Legendary = 4
}

-- Element icons
local ElementIcons = {
	Fire = "??",
	Water = "??", 
	Earth = "??",
	Plant = "??",
	Electric = "?"
}

-- Filter state
local currentSort = "Newest"
local currentElementFilter = "All"
local currentSearchText = ""
local currentSelectedMonster = nil

-- All monsters cache
local allMonsters = {}

-- Sorting modes
local sortModes = {"Newest", "Oldest", "Level", "Rarity", "Name", "Power"}
local currentSortIndex = 1

print("?? Monster Inventory Controller loading...")

-- Function to update sort button text
local function updateSortButtonText()
	sortButton.Text = "?? " .. currentSort
end

-- Function to highlight active filter button
local function updateFilterButtonColors()
	allButton.BackgroundColor3 = currentElementFilter == "All" and Color3.fromRGB(100, 100, 120) or Color3.fromRGB(60, 60, 80)
	fireButton.BackgroundColor3 = currentElementFilter == "Fire" and ElementColors.Fire or Color3.fromRGB(60, 60, 80)
	waterButton.BackgroundColor3 = currentElementFilter == "Water" and ElementColors.Water or Color3.fromRGB(60, 60, 80)
	earthButton.BackgroundColor3 = currentElementFilter == "Earth" and ElementColors.Earth or Color3.fromRGB(60, 60, 80)
	plantButton.BackgroundColor3 = currentElementFilter == "Plant" and ElementColors.Plant or Color3.fromRGB(60, 60, 80)
	electricButton.BackgroundColor3 = currentElementFilter == "Electric" and ElementColors.Electric or Color3.fromRGB(60, 60, 80)
end

-- Function to format element display (DUAL ELEMENT SUPPORT)
local function formatElementDisplay(elements)
	if type(elements) == "table" and #elements > 1 then
		-- Hybrid: Show both elements
		local icon1 = ElementIcons[elements[1]] or "?"
		local icon2 = ElementIcons[elements[2]] or "?"
		return icon1 .. " • " .. icon2, elements[1]  -- Return display text and primary color
	elseif type(elements) == "table" and #elements == 1 then
		-- Single element from array
		local element = elements[1]
		return (ElementIcons[element] or "?") .. " " .. element, element
	else
		-- Fallback for old format
		local element = tostring(elements)
		return (ElementIcons[element] or "?") .. " " .. element, element
	end
end

-- Function to create monster card (UPDATED FOR DUAL ELEMENTS)
local function createMonsterCard(monsterData, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = monsterData.uniqueId
	card.Size = UDim2.new(0, 200, 0, 160)
	card.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 15)
	cardCorner.Parent = card

	-- Monster Image
	local smallImage = Instance.new("ImageLabel")
	smallImage.Name = "SmallImage"
	smallImage.Size = UDim2.new(0, 60, 0, 60)
	smallImage.Position = UDim2.new(0, 15, 0, 15)
	smallImage.BackgroundColor3 = ElementColors[monsterData.element] or Color3.fromRGB(100, 100, 100)
	smallImage.BorderSizePixel = 0
	smallImage.Image = ""
	smallImage.Parent = card

	local smallImageCorner = Instance.new("UICorner")
	smallImageCorner.CornerRadius = UDim.new(0, 10)
	smallImageCorner.Parent = smallImage

	-- Load image
	if MonsterImages then
		local imageValue = MonsterImages:FindFirstChild(monsterData.name)
		if imageValue and imageValue.Value ~= "" then
			smallImage.Image = imageValue.Value
			smallImage.BackgroundTransparency = 0
		else
			smallImage.BackgroundTransparency = 0.3
		end
	else
		smallImage.BackgroundTransparency = 0.3
	end

	-- Monster Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -90, 0, 25)
	nameLabel.Position = UDim2.new(0, 85, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = monsterData.name
	nameLabel.TextColor3 = RarityColors[monsterData.rarity] or Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Element Label (DUAL ELEMENT SUPPORT)
	local elementText, primaryElement = formatElementDisplay(monsterData.elements)

	local elementLabel = Instance.new("TextLabel")
	elementLabel.Size = UDim2.new(1, -90, 0, 20)
	elementLabel.Position = UDim2.new(0, 85, 0, 40)
	elementLabel.BackgroundTransparency = 1
	elementLabel.Text = elementText
	elementLabel.TextColor3 = ElementColors[primaryElement] or Color3.fromRGB(200, 200, 200)
	elementLabel.TextSize = 12
	elementLabel.Font = Enum.Font.Gotham
	elementLabel.TextXAlignment = Enum.TextXAlignment.Left
	elementLabel.Parent = card

	-- Level & Rarity
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(0.5, -10, 0, 20)
	levelLabel.Position = UDim2.new(0, 15, 0, 85)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "LVL " .. monsterData.level
	levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	levelLabel.TextSize = 12
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = card

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.5, -10, 0, 20)
	rarityLabel.Position = UDim2.new(0.5, 5, 0, 85)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = monsterData.rarity
	rarityLabel.TextColor3 = RarityColors[monsterData.rarity] or Color3.fromRGB(150, 150, 150)
	rarityLabel.TextSize = 12
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Right
	rarityLabel.Parent = card

	-- Power indicator
	local powerLabel = Instance.new("TextLabel")
	powerLabel.Size = UDim2.new(1, -20, 0, 18)
	powerLabel.Position = UDim2.new(0, 10, 0, 108)
	powerLabel.BackgroundTransparency = 1
	powerLabel.Text = "? " .. monsterData.power
	powerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	powerLabel.TextSize = 11
	powerLabel.Font = Enum.Font.Gotham
	powerLabel.TextXAlignment = Enum.TextXAlignment.Left
	powerLabel.Parent = card

	-- View Details Button
	local detailsButton = Instance.new("TextButton")
	detailsButton.Size = UDim2.new(0, 80, 0, 25)
	detailsButton.Position = UDim2.new(1, -90, 1, -35)
	detailsButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
	detailsButton.Text = "VIEW"
	detailsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	detailsButton.TextSize = 12
	detailsButton.Font = Enum.Font.GothamBold
	detailsButton.BorderSizePixel = 0
	detailsButton.Parent = card

	local detailsCorner = Instance.new("UICorner")
	detailsCorner.CornerRadius = UDim.new(0, 6)
	detailsCorner.Parent = detailsButton

	detailsButton.MouseButton1Click:Connect(function()
		showMonsterDetails(monsterData)
	end)

	-- Hover effects
	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(55, 55, 75)
		}):Play()
	end)

	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		}):Play()
	end)

	return card
end

-- Function to show monster details (UPDATED FOR DUAL ELEMENTS)
function showMonsterDetails(monsterData)
	currentSelectedMonster = monsterData

	nameLabel.Text = monsterData.name
	nameLabel.TextColor3 = RarityColors[monsterData.rarity] or Color3.fromRGB(255, 255, 255)

	-- Display elements
	local elementText, primaryElement = formatElementDisplay(monsterData.elements)
	elementLabel.Text = elementText
	elementLabel.TextColor3 = ElementColors[primaryElement] or Color3.fromRGB(200, 200, 200)

	rarityLabel.Text = monsterData.rarity
	rarityLabel.TextColor3 = RarityColors[monsterData.rarity] or Color3.fromRGB(150, 150, 150)

	levelLabel.Text = "Level " .. monsterData.level

	hpLabel.Text = "HP: " .. monsterData.hp
	hpLabel.TextColor3 = Color3.fromRGB(255, 100, 100)

	attackLabel.Text = "ATK: " .. monsterData.attack
	attackLabel.TextColor3 = Color3.fromRGB(255, 150, 100)

	defenseLabel.Text = "DEF: " .. monsterData.defense
	defenseLabel.TextColor3 = Color3.fromRGB(100, 150, 255)

	speedLabel.Text = "SPD: " .. monsterData.speed
	speedLabel.TextColor3 = Color3.fromRGB(150, 255, 150)

	-- Load image
	if MonsterImages then
		local imageValue = MonsterImages:FindFirstChild(monsterData.name)
		if imageValue and imageValue.Value ~= "" then
			monsterImage.Image = imageValue.Value
			monsterImage.BackgroundTransparency = 0
			monsterImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		else
			monsterImage.Image = ""
			monsterImage.BackgroundColor3 = ElementColors[monsterData.element] or Color3.fromRGB(100, 100, 100)
			monsterImage.BackgroundTransparency = 0.3
		end
	else
		monsterImage.Image = ""
		monsterImage.BackgroundColor3 = ElementColors[monsterData.element] or Color3.fromRGB(100, 100, 100)
		monsterImage.BackgroundTransparency = 0.3
	end

	-- Show with animation
	detailFrame.Visible = true
	detailFrame.Size = UDim2.new(0, 0, 0, 0)
	detailFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(detailFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 450, 0, 550),
		Position = UDim2.new(0.5, -225, 0.5, -275)
	}):Play()
end

-- Function to hide detail frame
local function hideDetailFrame()
	local tween = TweenService:Create(detailFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		detailFrame.Visible = false
		currentSelectedMonster = nil
	end)
end

-- Function to load all monsters (UPDATED FOR DUAL ELEMENTS)
local function loadAllMonsters()
	allMonsters = {}

	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then 
		print("?? No Monsters folder found!")
		return 
	end

	print("?? Loading monsters from folder...")
	print("   Total monsters in folder:", #monstersFolder:GetChildren())

	for _, monster in pairs(monstersFolder:GetChildren()) do
		if monster:IsA("Folder") then
			print("   Reading monster:", monster.Name)

			-- Read Elements (NEW FORMAT - array as comma-separated string)
			local elementsValue = monster:FindFirstChild("Elements")
			local elements = {}

			if elementsValue then
				-- Parse comma-separated string: "Fire,Water" ? {"Fire", "Water"}
				for element in string.gmatch(elementsValue.Value, "[^,]+") do
					table.insert(elements, element)
				end
				print("      Elements found:", table.concat(elements, " + "))
			else
				-- Fallback to old single Element format
				local elementValue = monster:FindFirstChild("Element")
				if elementValue then
					elements = {elementValue.Value}
					print("      Single element (old format):", elementValue.Value)
				else
					elements = {"Unknown"}
					print("      No element found, using Unknown")
				end
			end

			-- Read IVs if they exist
			local ivs = {HP = 0, Attack = 0, Defense = 0, Speed = 0}
			local ivsFolder = monster:FindFirstChild("IVs")
			if ivsFolder then
				for _, ivValue in pairs(ivsFolder:GetChildren()) do
					if ivValue:IsA("NumberValue") then
						ivs[ivValue.Name] = ivValue.Value
					end
				end
				print("      IVs:", ivs.HP, ivs.Attack, ivs.Defense, ivs.Speed)
			end

			local monsterData = {
				uniqueId = monster.Name,
				name = (monster:FindFirstChild("Name") and monster:FindFirstChild("Name").Value) or 
					(monster:FindFirstChild("MonsterName") and monster:FindFirstChild("MonsterName").Value) or "Unknown",
				elements = elements,  -- Array of elements
				element = elements[1] or "Unknown",  -- Primary element for compatibility
				rarity = monster:FindFirstChild("Rarity") and monster:FindFirstChild("Rarity").Value or "Common",
				level = monster:FindFirstChild("Level") and monster:FindFirstChild("Level").Value or 1,
				hp = monster:FindFirstChild("HP") and monster:FindFirstChild("HP").Value or 0,
				attack = monster:FindFirstChild("Attack") and monster:FindFirstChild("Attack").Value or 0,
				defense = monster:FindFirstChild("Defense") and monster:FindFirstChild("Defense").Value or 0,
				speed = monster:FindFirstChild("Speed") and monster:FindFirstChild("Speed").Value or 0,
				obtainedTime = monster:FindFirstChild("obtainedTime") and monster:FindFirstChild("obtainedTime").Value or 0,
				ivs = ivs,
				statQuality = monster:FindFirstChild("StatQuality") and monster:FindFirstChild("StatQuality").Value or "Average"
			}

			monsterData.power = monsterData.hp + monsterData.attack + monsterData.defense + monsterData.speed

			table.insert(allMonsters, monsterData)
			print("   ? Loaded:", monsterData.name, "Power:", monsterData.power)
		end
	end

	print("?? Total monsters loaded:", #allMonsters)
end

-- Function to filter and sort monsters (UPDATED FOR DUAL ELEMENTS)
local function getFilteredAndSortedMonsters()
	local filtered = {}

	for _, monster in ipairs(allMonsters) do
		-- Check if monster matches element filter (works with dual elements)
		local matchesElement = false
		if currentElementFilter == "All" then
			matchesElement = true
		else
			-- Check if monster has this element (supports dual elements)
			for _, element in ipairs(monster.elements) do
				if element == currentElementFilter then
					matchesElement = true
					break
				end
			end
		end

		local matchesSearch = (currentSearchText == "") or string.find(string.lower(monster.name), string.lower(currentSearchText))

		if matchesElement and matchesSearch then
			table.insert(filtered, monster)
		end
	end

	-- Apply sorting
	if currentSort == "Newest" then
		table.sort(filtered, function(a, b)
			return (a.obtainedTime or 0) > (b.obtainedTime or 0)
		end)
	elseif currentSort == "Oldest" then
		table.sort(filtered, function(a, b)
			return (a.obtainedTime or 0) < (b.obtainedTime or 0)
		end)
	elseif currentSort == "Level" then
		table.sort(filtered, function(a, b)
			return a.level > b.level
		end)
	elseif currentSort == "Rarity" then
		table.sort(filtered, function(a, b)
			return (RarityOrder[a.rarity] or 0) > (RarityOrder[b.rarity] or 0)
		end)
	elseif currentSort == "Name" then
		table.sort(filtered, function(a, b)
			return a.name < b.name
		end)
	elseif currentSort == "Power" then
		table.sort(filtered, function(a, b)
			return a.power > b.power
		end)
	end

	return filtered
end

-- Function to update monster list
local function updateMonsterList()
	-- Clear existing
	for _, child in pairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") or (child:IsA("TextLabel") and child.Name == "NoMonstersMessage") then
			child:Destroy()
		end
	end

	loadAllMonsters()
	local monsters = getFilteredAndSortedMonsters()

	if #monsters == 0 then
		local noMonstersLabel = Instance.new("TextLabel")
		noMonstersLabel.Name = "NoMonstersMessage"
		noMonstersLabel.Size = UDim2.new(1, -20, 0, 100)
		noMonstersLabel.Position = UDim2.new(0, 10, 0, 50)
		noMonstersLabel.BackgroundTransparency = 1

		if #allMonsters == 0 then
			noMonstersLabel.Text = "No monsters in collection!\n\nHatch some eggs to collect monsters."
		else
			noMonstersLabel.Text = "No monsters match your filters.\n\nTry adjusting your search or filters."
		end

		noMonstersLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noMonstersLabel.TextSize = 18
		noMonstersLabel.Font = Enum.Font.Gotham
		noMonstersLabel.TextWrapped = true
		noMonstersLabel.TextXAlignment = Enum.TextXAlignment.Center
		noMonstersLabel.TextYAlignment = Enum.TextYAlignment.Center
		noMonstersLabel.Parent = contentFrame

		contentFrame.CanvasSize = UDim2.new(0, 0, 0, 150)
		return
	end

	for i, monsterData in ipairs(monsters) do
		local card = createMonsterCard(monsterData, i)
		card.Parent = contentFrame
	end

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#monsters / 4) * 175 + 50)

	print("?? Showing", #monsters, "monsters (Total:", #allMonsters, ")")
end

-- Event connections
monsterButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	if mainFrame.Visible then
		updateMonsterList()
		updateFilterButtonColors()
		updateSortButtonText()
	end
end)

closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

detailCloseButton.MouseButton1Click:Connect(function()
	hideDetailFrame()
end)

-- Sort button
sortButton.MouseButton1Click:Connect(function()
	currentSortIndex = currentSortIndex + 1
	if currentSortIndex > #sortModes then
		currentSortIndex = 1
	end
	currentSort = sortModes[currentSortIndex]
	updateSortButtonText()
	updateMonsterList()
	print("?? Sort:", currentSort)
end)

-- Element filters
allButton.MouseButton1Click:Connect(function()
	currentElementFilter = "All"
	updateFilterButtonColors()
	updateMonsterList()
end)

fireButton.MouseButton1Click:Connect(function()
	currentElementFilter = "Fire"
	updateFilterButtonColors()
	updateMonsterList()
end)

waterButton.MouseButton1Click:Connect(function()
	currentElementFilter = "Water"
	updateFilterButtonColors()
	updateMonsterList()
end)

earthButton.MouseButton1Click:Connect(function()
	currentElementFilter = "Earth"
	updateFilterButtonColors()
	updateMonsterList()
end)

plantButton.MouseButton1Click:Connect(function()
	currentElementFilter = "Plant"
	updateFilterButtonColors()
	updateMonsterList()
end)

electricButton.MouseButton1Click:Connect(function()
	currentElementFilter = "Electric"
	updateFilterButtonColors()
	updateMonsterList()
end)

-- Search bar
searchBar:GetPropertyChangedSignal("Text"):Connect(function()
	currentSearchText = searchBar.Text
	updateMonsterList()
end)

-- Initialize
mainFrame.Visible = false
detailFrame.Visible = false

print("? Monster Collection with Dual Element Support loaded!")