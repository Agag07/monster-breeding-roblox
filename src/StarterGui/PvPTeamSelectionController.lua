-- PvPTeamSelectionController.lua (LocalScript in PvPGui)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

-- Get UI References
local pvpButton = gui:WaitForChild("PvPButton")
local teamSelectionFrame = gui:WaitForChild("TeamSelectionFrame")
local titleBar = teamSelectionFrame:WaitForChild("TitleBar")
local closeButton = titleBar:WaitForChild("CloseButton")

-- Team Slots
local teamSlotsContainer = teamSelectionFrame:WaitForChild("TeamSlotsContainer")
local teamSlot1 = teamSlotsContainer:WaitForChild("TeamSlot1")
local teamSlot2 = teamSlotsContainer:WaitForChild("TeamSlot2")
local teamSlot3 = teamSlotsContainer:WaitForChild("TeamSlot3")
local teamSlots = {teamSlot1, teamSlot2, teamSlot3}

-- Monster Picker
local monsterPickerSection = teamSelectionFrame:WaitForChild("MonsterPickerSection")
local monsterPickerFrame = monsterPickerSection:WaitForChild("MonsterPickerFrame")

-- Ready Button
local readyButton = teamSelectionFrame:WaitForChild("ReadyButton")

-- Get Monster Images
local MonsterImages = ReplicatedStorage:FindFirstChild("MonsterImages")

-- Variables
local selectedTeam = {nil, nil, nil} -- Stores monster data for each slot
local currentDetailMonster = nil

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

-- Function to update ready button state
local function updateReadyButton()
	local allSlotsFilled = selectedTeam[1] ~= nil and selectedTeam[2] ~= nil and selectedTeam[3] ~= nil

	if allSlotsFilled then
		readyButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
		readyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		readyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		readyButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
end

-- Function to update team slot display
local function updateTeamSlot(slotIndex)
	local slot = teamSlots[slotIndex]
	local monsterData = selectedTeam[slotIndex]

	local emptyState = slot:FindFirstChild("EmptyState")
	local monsterDisplay = slot:FindFirstChild("MonsterDisplay")

	if monsterData then
		-- Show monster display
		emptyState.Visible = false
		monsterDisplay.Visible = true

		-- Update monster info
		local monsterImage = monsterDisplay:FindFirstChild("MonsterImage")
		local monsterName = monsterDisplay:FindFirstChild("MonsterName")

		monsterName.Text = monsterData.name
		monsterName.TextColor3 = RarityColors[monsterData.rarity] or Color3.fromRGB(255, 255, 255)

		-- Set monster image
		if MonsterImages then
			local imageValue = MonsterImages:FindFirstChild(monsterData.name)
			if imageValue and imageValue.Value ~= "" then
				monsterImage.Image = imageValue.Value
			else
				monsterImage.BackgroundColor3 = ElementColors[monsterData.element] or Color3.fromRGB(100, 100, 100)
				monsterImage.BackgroundTransparency = 0.3
			end
		end

		-- Setup remove button
		local removeButton = monsterDisplay:FindFirstChild("RemoveButton")
		removeButton.MouseButton1Click:Connect(function()
			selectedTeam[slotIndex] = nil
			updateTeamSlot(slotIndex)
			updateReadyButton()
			updateMonsterPicker()
		end)

		-- Setup click to view details
		monsterImage.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				showMonsterDetails(monsterData)
			end
		end)
	else
		-- Show empty state
		emptyState.Visible = true
		monsterDisplay.Visible = false
	end

	updateReadyButton()
end

-- Function to add monster to team
local function addMonsterToTeam(monsterData)
	-- Find first empty slot
	for i = 1, 3 do
		if selectedTeam[i] == nil then
			selectedTeam[i] = monsterData
			updateTeamSlot(i)
			updateMonsterPicker()
			return true
		end
	end
	return false
end

-- Function to check if monster is already in team
local function isMonsterInTeam(monsterId)
	for i = 1, 3 do
		if selectedTeam[i] and selectedTeam[i].uniqueId == monsterId then
			return true
		end
	end
	return false
end

-- Function to create monster picker card
local function createMonsterPickerCard(monsterData, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = monsterData.uniqueId
	card.Size = UDim2.new(0, 180, 0, 140)
	card.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	-- Monster Image
	local monsterImage = Instance.new("ImageLabel")
	monsterImage.Size = UDim2.new(0, 60, 0, 60)
	monsterImage.Position = UDim2.new(0.5, -30, 0, 15)
	monsterImage.BackgroundColor3 = ElementColors[monsterData.element] or Color3.fromRGB(100, 100, 100)
	monsterImage.BackgroundTransparency = 0.3
	monsterImage.BorderSizePixel = 0
	monsterImage.Image = ""
	monsterImage.Parent = card

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 10)
	imageCorner.Parent = monsterImage

	-- Set image if available
	if MonsterImages then
		local imageValue = MonsterImages:FindFirstChild(monsterData.name)
		if imageValue and imageValue.Value ~= "" then
			monsterImage.Image = imageValue.Value
			monsterImage.BackgroundTransparency = 0
		end
	end

	-- Monster Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 80)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = monsterData.name
	nameLabel.TextColor3 = RarityColors[monsterData.rarity] or Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Level
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(1, -20, 0, 20)
	levelLabel.Position = UDim2.new(0, 10, 0, 105)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "LVL " .. monsterData.level
	levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	levelLabel.TextSize = 12
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextXAlignment = Enum.TextXAlignment.Center
	levelLabel.Parent = card

	-- Check if monster is already selected
	if isMonsterInTeam(monsterData.uniqueId) then
		card.BackgroundColor3 = Color3.fromRGB(30, 30, 45)

		local selectedLabel = Instance.new("TextLabel")
		selectedLabel.Size = UDim2.new(1, 0, 0, 20)
		selectedLabel.Position = UDim2.new(0, 0, 1, -20)
		selectedLabel.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
		selectedLabel.BorderSizePixel = 0
		selectedLabel.Text = "? SELECTED"
		selectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		selectedLabel.TextSize = 10
		selectedLabel.Font = Enum.Font.GothamBold
		selectedLabel.Parent = card
	else
		-- Add click functionality
		local selectButton = Instance.new("TextButton")
		selectButton.Size = UDim2.new(1, 0, 1, 0)
		selectButton.BackgroundTransparency = 1
		selectButton.Text = ""
		selectButton.Parent = card

		selectButton.MouseButton1Click:Connect(function()
			if addMonsterToTeam(monsterData) then
				print("Added to team:", monsterData.name)
			else
				print("Team is full!")
			end
		end)

		-- Hover effect
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
	end

	return card
end

-- Function to update monster picker
function updateMonsterPicker()
	-- Clear existing cards
	for _, child in pairs(monsterPickerFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get monsters from player folder
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder or #monstersFolder:GetChildren() == 0 then
		local noMonstersLabel = Instance.new("TextLabel")
		noMonstersLabel.Size = UDim2.new(1, 0, 0, 100)
		noMonstersLabel.Position = UDim2.new(0, 0, 0, 50)
		noMonstersLabel.BackgroundTransparency = 1
		noMonstersLabel.Text = "No monsters in collection!\n\nCatch some monsters first."
		noMonstersLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noMonstersLabel.TextSize = 18
		noMonstersLabel.Font = Enum.Font.Gotham
		noMonstersLabel.TextWrapped = true
		noMonstersLabel.Parent = monsterPickerFrame
		return
	end

	-- Create cards for each monster
	local order = 1
	for _, monster in pairs(monstersFolder:GetChildren()) do
		if monster:IsA("Folder") then
			local monsterData = {
				uniqueId = monster.Name,
				name = (monster:FindFirstChild("Name") and monster:FindFirstChild("Name").Value) or 
					(monster:FindFirstChild("MonsterName") and monster:FindFirstChild("MonsterName").Value) or "Unknown",
				element = monster:FindFirstChild("Element") and monster:FindFirstChild("Element").Value or "Unknown",
				rarity = monster:FindFirstChild("Rarity") and monster:FindFirstChild("Rarity").Value or "Common",
				level = monster:FindFirstChild("Level") and monster:FindFirstChild("Level").Value or 1,
				hp = monster:FindFirstChild("HP") and monster:FindFirstChild("HP").Value or 0,
				attack = monster:FindFirstChild("Attack") and monster:FindFirstChild("Attack").Value or 0,
				defense = monster:FindFirstChild("Defense") and monster:FindFirstChild("Defense").Value or 0,
				speed = monster:FindFirstChild("Speed") and monster:FindFirstChild("Speed").Value or 0
			}

			local card = createMonsterPickerCard(monsterData, order)
			card.Parent = monsterPickerFrame
			order = order + 1
		end
	end

	-- Update canvas size
	monsterPickerFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(order / 4) * 155 + 20)
end

-- Function to show monster details (placeholder for now)
function showMonsterDetails(monsterData)
	print("Showing details for:", monsterData.name)
	print("HP:", monsterData.hp, "ATK:", monsterData.attack, "DEF:", monsterData.defense, "SPD:", monsterData.speed)
	-- TODO: Create detail popup UI in next phase
end

-- Function to open team selection
local function openTeamSelection()
	updateMonsterPicker()

	teamSelectionFrame.Visible = true
	teamSelectionFrame.Size = UDim2.new(0, 0, 0, 0)
	teamSelectionFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(teamSelectionFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 900, 0, 650),
		Position = UDim2.new(0.5, -450, 0.5, -325)
	})
	tween:Play()
end

-- Function to close team selection
local function closeTeamSelection()
	local tween = TweenService:Create(teamSelectionFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		teamSelectionFrame.Visible = false
	end)
end

-- Event connections
pvpButton.MouseButton1Click:Connect(function()
	openTeamSelection()
end)

closeButton.MouseButton1Click:Connect(function()
	closeTeamSelection()
end)

readyButton.MouseButton1Click:Connect(function()
	local allSlotsFilled = selectedTeam[1] and selectedTeam[2] and selectedTeam[3]

	if allSlotsFilled then
		print("Starting battle with team:")
		print("Slot 1:", selectedTeam[1].name)
		print("Slot 2:", selectedTeam[2].name)
		print("Slot 3:", selectedTeam[3].name)

		-- TODO: Start battle with NPC in next phase
		closeTeamSelection()
	end
end)

-- Initialize
teamSelectionFrame.Visible = false
updateReadyButton()

print("PvP Team Selection Controller loaded!")

--[[
PVP TEAM SELECTION FEATURES:
? PvP button opens team selection UI
? 3 team slots with empty state (+) and filled state (monster display)
? Monster picker shows all collected monsters
? Click monster cards to add to team
? Remove button (X) to remove from team
? Visual feedback for selected monsters
? Ready button enables when 3 monsters selected
? Click monster in slot to view details (placeholder)

NEXT PHASE:
- Battle arena UI
- Move system implementation  
- NPC opponent generation
- Combat mechanics
--]]