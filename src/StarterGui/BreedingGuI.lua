-- BreedingGUI.lua (LocalScript) - Put in StarterGui/BreedingGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local screenGui = script.Parent

-- Get UI elements
local breedingFrame = screenGui:WaitForChild("BreedingFrame")
local titleBar = breedingFrame:WaitForChild("TitleBar")
local titleText = titleBar:WaitForChild("TitleText")
local closeButton = titleBar:WaitForChild("CloseButton")

local mainContent = breedingFrame:WaitForChild("MainContent")
local parent1Section = mainContent:WaitForChild("Parent1Section")
local parent2Section = mainContent:WaitForChild("Parent2Section")
local middleSection = mainContent:WaitForChild("MiddleSection")

local bottomSection = mainContent:WaitForChild("BottomSection")
local resultPreview = bottomSection:WaitForChild("ResultPreview")
local resultText = resultPreview:WaitForChild("ResultText")
local costDisplay = bottomSection:WaitForChild("CostDisplay")
local costLabel = costDisplay:WaitForChild("CostLabel")
local breedButton = bottomSection:WaitForChild("BreedButton")

-- Get scroll frames and selected displays
-- Debug: Check what's actually in Parent1Section
print("?? Parent1Section children:")
for _, child in pairs(parent1Section:GetChildren()) do
	print("  -", child.Name, child.ClassName)
end

-- The ScrollingFrame is actually called "ScrollingFrame" not "ScrollFrame"
local parent1Scroll = parent1Section:FindFirstChild("ScrollingFrame") 
	or parent1Section:FindFirstChild("ScrollFrame")
	or parent1Section:FindFirstChild("MonsterScroll")

local parent2Scroll = parent2Section:FindFirstChild("ScrollingFrame")
	or parent2Section:FindFirstChild("ScrollFrame") 
	or parent2Section:FindFirstChild("MonsterScroll")

if not parent1Scroll or not parent2Scroll then
	warn("? ScrollFrame not found! Check Output for available children.")
	return
end

local parent1Selected = parent1Section:FindFirstChild("SelectedDisplay") 
	or parent1Section:FindFirstChild("Selected")

local parent2Selected = parent2Section:FindFirstChild("SelectedDisplay")
	or parent2Section:FindFirstChild("Selected")

if not parent1Selected or not parent2Selected then
	warn("? SelectedDisplay not found! Check Output for available children.")
	return
end

-- Create/Get remote events
local startBreedingRemote = ReplicatedStorage:FindFirstChild("StartBreeding")
if not startBreedingRemote then
	startBreedingRemote = Instance.new("RemoteEvent")
	startBreedingRemote.Name = "StartBreeding"
	startBreedingRemote.Parent = ReplicatedStorage
end

local collectBreedingEggRemote = ReplicatedStorage:FindFirstChild("CollectBreedingEgg")
if not collectBreedingEggRemote then
	collectBreedingEggRemote = Instance.new("RemoteEvent")
	collectBreedingEggRemote.Name = "CollectBreedingEgg"
	collectBreedingEggRemote.Parent = ReplicatedStorage
end

-- Variables
local selectedParent1 = nil
local selectedParent2 = nil
local currentBreedingMachineId = nil
local playerMonsters = {}

-- Element emojis
local ELEMENT_EMOJIS = {
	Fire = "??",
	Water = "??",
	Earth = "??",
	Plant = "??",
	Electric = "?"
}

-- Rarity colors
local RARITY_COLORS = {
	Common = Color3.fromRGB(160, 160, 160),
	Rare = Color3.fromRGB(0, 150, 255),
	Epic = Color3.fromRGB(160, 32, 240),
	Legendary = Color3.fromRGB(255, 215, 0)
}

-- Breeding costs based on rarity combinations
local BREEDING_COSTS = {
	["Common,Common"] = 150,
	["Common,Rare"] = 300,
	["Rare,Rare"] = 500,
	["Common,Epic"] = 500,
	["Rare,Epic"] = 750,
	["Epic,Epic"] = 750,
	["Common,Legendary"] = 750,
	["Rare,Legendary"] = 1000,
	["Epic,Legendary"] = 1000,
	["Legendary,Legendary"] = 1000
}

local HYBRID_COMBINATIONS = {
	["Fire,Water"] = "Vaporix",
	["Water,Fire"] = "Vaporix",
	["Fire,Earth"] = "Magmor",
	["Earth,Fire"] = "Magmor",
	["Fire,Plant"] = "Blazebloom",
	["Plant,Fire"] = "Blazebloom",
	["Fire,Electric"] = "Voltflare",
	["Electric,Fire"] = "Voltflare",
	["Water,Earth"] = "Sludgy",
	["Earth,Water"] = "Sludgy",
	["Water,Plant"] = "Hydravine",
	["Plant,Water"] = "Hydravine",
	["Water,Electric"] = "Thundersplash",
	["Electric,Water"] = "Thundersplash",
	["Earth,Plant"] = "Terravine",
	["Plant,Earth"] = "Terravine",
	["Earth,Electric"] = "Tarick",
	["Electric,Earth"] = "Tarick",
	["Plant,Electric"] = "Wattsprout",
	["Electric,Plant"] = "Wattsprout"
}

-- Function to create monster card
local function createMonsterCard(monsterData, scrollFrame, parentNumber)
	local card = Instance.new("Frame")
	card.Name = monsterData.id
	card.Size = UDim2.new(0, 170, 0, 120)
	card.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	card.BorderSizePixel = 0

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(70, 70, 90)
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- Monster icon (use first element emoji)
	local elements = string.split(monsterData.element, ",")
	local firstElement = elements[1]:gsub("%s+", "") -- Remove spaces
	local emoji = ELEMENT_EMOJIS[firstElement] or "?"

	local monsterIcon = Instance.new("TextLabel")
	monsterIcon.Size = UDim2.new(0, 40, 0, 40)
	monsterIcon.Position = UDim2.new(0, 10, 0, 10)
	monsterIcon.BackgroundTransparency = 1
	monsterIcon.Text = emoji
	monsterIcon.TextSize = 30
	monsterIcon.Parent = card

	-- Monster name
	local monsterName = Instance.new("TextLabel")
	monsterName.Size = UDim2.new(0, 100, 0, 25)
	monsterName.Position = UDim2.new(0, 60, 0, 10)
	monsterName.BackgroundTransparency = 1
	monsterName.Text = monsterData.name
	monsterName.TextColor3 = Color3.fromRGB(255, 255, 255)
	monsterName.TextSize = 14
	monsterName.Font = Enum.Font.GothamBold
	monsterName.TextXAlignment = Enum.TextXAlignment.Left
	monsterName.TextTruncate = Enum.TextTruncate.AtEnd
	monsterName.Parent = card

	-- Elements label
	local elementsLabel = Instance.new("TextLabel")
	elementsLabel.Size = UDim2.new(0, 100, 0, 20)
	elementsLabel.Position = UDim2.new(0, 60, 0, 35)
	elementsLabel.BackgroundTransparency = 1
	elementsLabel.Text = monsterData.element:gsub(",", " • ")
	elementsLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	elementsLabel.TextSize = 12
	elementsLabel.Font = Enum.Font.Gotham
	elementsLabel.TextXAlignment = Enum.TextXAlignment.Left
	elementsLabel.TextTruncate = Enum.TextTruncate.AtEnd
	elementsLabel.Parent = card

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -20, 0, 20)
	rarityLabel.Position = UDim2.new(0, 10, 0, 60)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = monsterData.rarity
	rarityLabel.TextColor3 = RARITY_COLORS[monsterData.rarity] or Color3.fromRGB(255, 255, 255)
	rarityLabel.TextSize = 12
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = card

	-- Level label
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(0, 50, 0, 20)
	levelLabel.Position = UDim2.new(0, 10, 0, 80)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv." .. monsterData.level
	levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	levelLabel.TextSize = 11
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.Parent = card

	-- Select button
	local selectButton = Instance.new("TextButton")
	selectButton.Size = UDim2.new(0, 70, 0, 20)
	selectButton.Position = UDim2.new(0.5, -35, 1, -30)
	selectButton.BackgroundColor3 = Color3.fromRGB(80, 150, 80)
	selectButton.Text = "SELECT"
	selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectButton.TextSize = 10
	selectButton.Font = Enum.Font.GothamBold
	selectButton.BorderSizePixel = 0
	selectButton.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 5)
	buttonCorner.Parent = selectButton

	-- Hover effects
	selectButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(selectButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(100, 170, 100)
		})
		tween:Play()
	end)

	selectButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(selectButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(80, 150, 80)
		})
		tween:Play()
	end)

	-- Selection functionality
	selectButton.MouseButton1Click:Connect(function()
		if parentNumber == 1 then
			selectedParent1 = monsterData
			updateSelectedDisplay(parent1Selected, monsterData)
			-- Highlight selected card
			for _, child in pairs(parent1Scroll:GetChildren()) do
				if child:IsA("Frame") then
					local stroke = child:FindFirstChild("UIStroke")
					if stroke then
						stroke.Color = Color3.fromRGB(70, 70, 90)
						stroke.Thickness = 2
					end
				end
			end
			cardStroke.Color = Color3.fromRGB(100, 255, 100)
			cardStroke.Thickness = 3
		else
			selectedParent2 = monsterData
			updateSelectedDisplay(parent2Selected, monsterData)
			-- Highlight selected card
			for _, child in pairs(parent2Scroll:GetChildren()) do
				if child:IsA("Frame") then
					local stroke = child:FindFirstChild("UIStroke")
					if stroke then
						stroke.Color = Color3.fromRGB(70, 70, 90)
						stroke.Thickness = 2
					end
				end
			end
			cardStroke.Color = Color3.fromRGB(100, 255, 100)
			cardStroke.Thickness = 3
		end

		-- Update preview
		updateBreedingPreview()
		updateBreedingCost()
	end)

	card.Parent = scrollFrame
end

-- Function to update selected monster display
function updateSelectedDisplay(displayFrame, monsterData)
	-- Clear existing
	for _, child in pairs(displayFrame:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end

	if monsterData then
		-- Get first element emoji
		local elements = string.split(monsterData.element, ",")
		local firstElement = elements[1]:gsub("%s+", "")
		local emoji = ELEMENT_EMOJIS[firstElement] or "?"

		-- Monster icon
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 60, 0, 60)
		icon.Position = UDim2.new(0.5, -30, 0, 15)
		icon.BackgroundTransparency = 1
		icon.Text = emoji
		icon.TextSize = 50
		icon.Parent = displayFrame

		-- Monster name
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -10, 0, 25)
		name.Position = UDim2.new(0, 5, 0, 80)
		name.BackgroundTransparency = 1
		name.Text = monsterData.name
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.TextSize = 16
		name.Font = Enum.Font.GothamBold
		name.TextScaled = true
		name.Parent = displayFrame

		-- Monster details
		local details = Instance.new("TextLabel")
		details.Size = UDim2.new(1, -10, 0, 40)
		details.Position = UDim2.new(0, 5, 0, 110)
		details.BackgroundTransparency = 1
		details.Text = monsterData.element .. "\n" .. monsterData.rarity .. " • Lv." .. monsterData.level
		details.TextColor3 = RARITY_COLORS[monsterData.rarity] or Color3.fromRGB(200, 200, 200)
		details.TextSize = 12
		details.Font = Enum.Font.Gotham
		details.TextYAlignment = Enum.TextYAlignment.Top
		details.Parent = displayFrame
	else
		-- Empty state
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 1, -20)
		emptyLabel.Position = UDim2.new(0, 10, 0, 10)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "?\n\nNo monster\nselected"
		emptyLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
		emptyLabel.TextSize = 16
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = displayFrame
	end
end

-- Function to update breeding preview
function updateBreedingPreview()
	-- Clear existing outcome labels
	for _, child in pairs(resultPreview:GetChildren()) do
		if child:IsA("TextLabel") and child ~= resultText then
			child:Destroy()
		end
	end

	if not selectedParent1 or not selectedParent2 then
		resultText.Text = "?? Breeding Result"
		return
	end

	resultText.Text = "?? Possible Results"

	-- Calculate possible outcomes
	local possibleOutcomes = {}

	-- Check hybrid combinations
	local parent1Elements = string.split(selectedParent1.element, ",")
	local parent2Elements = string.split(selectedParent2.element, ",")

	for _, elem1 in ipairs(parent1Elements) do
		elem1 = elem1:gsub("%s+", "")
		for _, elem2 in ipairs(parent2Elements) do
			elem2 = elem2:gsub("%s+", "")
			local combo1 = elem1 .. "," .. elem2
			local combo2 = elem2 .. "," .. elem1

			local hybrid = HYBRID_COMBINATIONS[combo1] or HYBRID_COMBINATIONS[combo2]
			if hybrid and not table.find(possibleOutcomes, hybrid) then
				table.insert(possibleOutcomes, hybrid)
			end
		end
	end

	-- If same species breeding, add parents as possible outcomes
	if selectedParent1.name == selectedParent2.name then
		table.insert(possibleOutcomes, selectedParent1.name)
	end

	-- Display outcomes
	local outcomeLabel = Instance.new("TextLabel")
	outcomeLabel.Size = UDim2.new(1, -20, 1, -40)
	outcomeLabel.Position = UDim2.new(0, 10, 0, 35)
	outcomeLabel.BackgroundTransparency = 1

	if #possibleOutcomes > 0 then
		outcomeLabel.Text = "Possible outcomes:\n" .. table.concat(possibleOutcomes, "\n")
		outcomeLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
	else
		outcomeLabel.Text = "No compatible breeding combination"
		outcomeLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
	end

	outcomeLabel.TextSize = 14
	outcomeLabel.Font = Enum.Font.Gotham
	outcomeLabel.TextYAlignment = Enum.TextYAlignment.Top
	outcomeLabel.Parent = resultPreview
end

-- Function to update breeding cost
function updateBreedingCost()
	if not selectedParent1 or not selectedParent2 then
		costLabel.Text = "?? COST: 0 COINS"
		breedButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		breedButton.Text = "SELECT PARENTS"
		return
	end

	-- Get rarities and sort them
	local rarities = {selectedParent1.rarity, selectedParent2.rarity}
	table.sort(rarities)
	local costKey = table.concat(rarities, ",")

	local cost = BREEDING_COSTS[costKey] or 500 -- Default cost
	costLabel.Text = "?? COST: " .. cost .. " COINS"

	-- Check if player has enough coins
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	if coins and coins.Value >= cost then
		breedButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		breedButton.Text = "START BREEDING"
	else
		breedButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
		breedButton.Text = "NOT ENOUGH COINS"
	end
end

-- Function to load player monsters
local function loadPlayerMonsters()
	-- Clear existing cards
	for _, child in pairs(parent1Scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, child in pairs(parent2Scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Reset selections
	selectedParent1 = nil
	selectedParent2 = nil
	updateSelectedDisplay(parent1Selected, nil)
	updateSelectedDisplay(parent2Selected, nil)
	updateBreedingPreview()
	updateBreedingCost()

	-- Get monsters from player's Monsters folder
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then
		print("? No monsters folder found")
		return
	end

	playerMonsters = {}

	-- Convert folder structure to monster data
	for _, monsterFolder in pairs(monstersFolder:GetChildren()) do
		if monsterFolder:IsA("Folder") then
			local monsterData = {
				id = monsterFolder.Name,
				name = monsterFolder:FindFirstChild("MonsterName") and monsterFolder.MonsterName.Value or "Unknown",
				element = monsterFolder:FindFirstChild("Element") and monsterFolder.Element.Value or "Unknown",
				rarity = monsterFolder:FindFirstChild("Rarity") and monsterFolder.Rarity.Value or "Common",
				level = monsterFolder:FindFirstChild("Level") and monsterFolder.Level.Value or 1,
				hp = monsterFolder:FindFirstChild("HP") and monsterFolder.HP.Value or 100,
				attack = monsterFolder:FindFirstChild("Attack") and monsterFolder.Attack.Value or 50,
				defense = monsterFolder:FindFirstChild("Defense") and monsterFolder.Defense.Value or 50,
				speed = monsterFolder:FindFirstChild("Speed") and monsterFolder.Speed.Value or 50
			}

			table.insert(playerMonsters, monsterData)

			-- Create cards for both parents
			createMonsterCard(monsterData, parent1Scroll, 1)
			createMonsterCard(monsterData, parent2Scroll, 2)
		end
	end

	-- Update canvas size
	local gridLayout1 = parent1Scroll:FindFirstChild("UIGridLayout")
	local gridLayout2 = parent2Scroll:FindFirstChild("UIGridLayout")

	if gridLayout1 then
		parent1Scroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#playerMonsters / 2) * 130 + 20)
	end
	if gridLayout2 then
		parent2Scroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#playerMonsters / 2) * 130 + 20)
	end

	print("? Loaded", #playerMonsters, "monsters for breeding")
end

-- Function to open breeding UI
local function openBreedingUI(breedingMachineId)
	currentBreedingMachineId = breedingMachineId

	-- Load monsters
	loadPlayerMonsters()

	-- Show UI with animation
	breedingFrame.Visible = true
	breedingFrame.Size = UDim2.new(0, 0, 0, 0)
	breedingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(breedingFrame, 
		TweenInfo.new(0.3, Enum.EasingStyle.Back), 
		{
			Size = UDim2.new(0, 900, 0, 650),
			Position = UDim2.new(0.5, -450, 0.5, -325)
		}
	)
	tween:Play()
end

-- Function to close breeding UI
local function closeBreedingUI()
	local tween = TweenService:Create(breedingFrame, 
		TweenInfo.new(0.2, Enum.EasingStyle.Quad), 
		{
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}
	)
	tween:Play()

	tween.Completed:Connect(function()
		breedingFrame.Visible = false
	end)
end

-- Button connections
closeButton.MouseButton1Click:Connect(function()
	closeBreedingUI()
end)

breedButton.MouseButton1Click:Connect(function()
	if not selectedParent1 or not selectedParent2 then
		return
	end

	-- Check if player has enough coins
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	local rarities = {selectedParent1.rarity, selectedParent2.rarity}
	table.sort(rarities)
	local costKey = table.concat(rarities, ",")
	local cost = BREEDING_COSTS[costKey] or 500

	if not coins or coins.Value < cost then
		-- Flash button red
		local originalColor = breedButton.BackgroundColor3
		breedButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		wait(0.2)
		breedButton.BackgroundColor3 = originalColor
		return
	end

	print("?? Starting breeding:", selectedParent1.name, "+", selectedParent2.name)

	-- Send breeding request to server
	startBreedingRemote:FireServer(
		currentBreedingMachineId,
		selectedParent1.id,
		selectedParent2.id
	)

	-- Close UI after starting breeding
	closeBreedingUI()
end)

-- ?? NEW: Remote for opening from fixed breeding machines
local openBreedingUIRemote = ReplicatedStorage:WaitForChild("OpenBreedingUI", 10)

print("?? OpenBreedingUI remote found:", openBreedingUIRemote ~= nil)

-- ?? NEW: Handle opening UI from fixed breeding machines via proximity prompts
if openBreedingUIRemote then
	print("? Setting up OpenBreedingUI event listener...")
	openBreedingUIRemote.OnClientEvent:Connect(function(breedingMachineId)
		print("?? [CLIENT] Opening breeding UI for machine:", breedingMachineId)
		print("?? Step 1: Event received successfully")

		-- Get player's plot
		local plotName = player:GetAttribute("AssignedPlot")
		print("?? Step 2: Plot name:", plotName)

		local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
		print("?? Step 3: Plot found:", plot ~= nil)

		if not plot then 
			warn("? Plot not found")
			return 
		end

		-- Get the machine
		local machine = plot:FindFirstChild(breedingMachineId)
		print("?? Step 4: Machine found:", machine ~= nil)

		if not machine then 
			warn("? Machine not found:", breedingMachineId)
			warn("? Available children in plot:")
			for _, child in pairs(plot:GetChildren()) do
				warn("   -", child.Name, child.ClassName)
			end
			return 
		end

		-- Check if unlocked
		local isUnlocked = machine:GetAttribute("Unlocked")
		print("?? Step 5: Machine unlocked:", isUnlocked)

		if not isUnlocked then
			warn("?? Machine is locked!")
			return
		end

		-- Check if already breeding
		if machine:GetAttribute("BreedingStartTime") then
			warn("? Machine is already breeding!")
			-- TODO: Show timer UI
			return
		end

		print("?? Step 6: About to call openBreedingUI()")
		-- Open the breeding UI!
		openBreedingUI(breedingMachineId)
		print("?? Step 7: openBreedingUI() called successfully")
	end)
else
	warn("?? OpenBreedingUI remote event not found - proximity prompts won't work!")
end

-- ?? UPDATED: Handle clicking on breeding machines (backwards compatibility + lock checking)
mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if target then
		-- Check if clicking on a breeding machine in player's plot
		local plotName = player:GetAttribute("AssignedPlot")
		local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)

		if plot and target:IsDescendantOf(plot) then
			local object = target

			-- Walk up the hierarchy to find the breeding machine
			while object and object.Parent ~= plot do
				object = object.Parent
			end

			-- ?? FIXED: Works with both Models AND Parts
			if object and object:GetAttribute("Type") == "BreedingMachine" then
				-- ?? Check if machine is unlocked
				local isUnlocked = object:GetAttribute("Unlocked")

				if not isUnlocked then
					print("?? This breeding machine is locked!")
					print("?? Walk up to it and use the proximity prompt to unlock")
					return
				end

				-- Check if machine is already breeding
				if not object:GetAttribute("BreedingStartTime") then
					openBreedingUI(object.Name)
				else
					print("? Breeding machine is already in use!")
					-- TODO: Show timer UI for active breeding
				end
			end
		end
	end
end)

-- Make function global for other scripts
_G.OpenBreedingUI = openBreedingUI

-- Initialize as hidden
breedingFrame.Visible = false

print("? Breeding UI loaded!")

--[[
?? CHANGES IN THIS VERSION:
1. ? Added OpenBreedingUI remote event listener (lines 549-588)
2. ? Added proximity prompt handler
3. ? Added lock checking to mouse click handler
4. ? Updated emojis to actual emojis
5. ? Better error messages with emojis

NOTES:
- This works with both OLD (click) and NEW (proximity prompt) systems
- Backwards compatible with existing UI structure
- The CRITICAL FIX: Added the remote event listener that was missing!
--]]