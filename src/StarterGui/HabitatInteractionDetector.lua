-- HabitatInteractionDetector.lua (LocalScript in StarterGui) - FIXED VERSION
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

print("?? Habitat Interaction Detector loading...")

-- ? Wait for HabitatMonsterSelectionController to load
local function waitForHabitatUI()
	print("? Waiting for HabitatMonsterSelectionController...")
	local attempts = 0
	while not _G.ShowHabitatSelection and attempts < 100 do
		attempts = attempts + 1
		task.wait(0.1)
	end

	if _G.ShowHabitatSelection then
		print("? HabitatMonsterSelectionController found!")
		return true
	else
		warn("? HabitatMonsterSelectionController not found after 10 seconds")
		warn("? Make sure script is in StarterGui/HabitatMonsterSelectionGui/")
		return false
	end
end

-- Wait for UI before continuing
if not waitForHabitatUI() then
	warn("? Cannot start habitat detection - UI not loaded!")
	return
end

-- Variables
local nearbyHabitat = nil
local interactionPrompt = nil
local isPromptVisible = false

-- Create interaction prompt UI
local function createInteractionPrompt()
	local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("HabitatInteractionPrompt")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "HabitatInteractionPrompt"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = player.PlayerGui
	end

	local promptFrame = screenGui:FindFirstChild("PromptFrame")
	if not promptFrame then
		promptFrame = Instance.new("Frame")
		promptFrame.Name = "PromptFrame"
		promptFrame.Size = UDim2.new(0, 250, 0, 60)
		promptFrame.Position = UDim2.new(0.5, -125, 0.8, -30)
		promptFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		promptFrame.BorderSizePixel = 0
		promptFrame.Visible = false
		promptFrame.Parent = screenGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = promptFrame

		local promptText = Instance.new("TextLabel")
		promptText.Name = "PromptText"
		promptText.Size = UDim2.new(1, -20, 1, 0)
		promptText.Position = UDim2.new(0, 10, 0, 0)
		promptText.BackgroundTransparency = 1
		promptText.Text = "[E] Manage Fire Habitat"
		promptText.TextColor3 = Color3.fromRGB(255, 255, 255)
		promptText.TextSize = 16
		promptText.Font = Enum.Font.GothamBold
		promptText.TextXAlignment = Enum.TextXAlignment.Center
		promptText.Parent = promptFrame
	end

	return promptFrame
end

-- Function to show interaction prompt
local function showPrompt(habitatData)
	if not interactionPrompt then
		interactionPrompt = createInteractionPrompt()
	end

	local promptText = interactionPrompt:FindFirstChild("PromptText")
	if promptText then
		local elementIcon = getElementIcon(habitatData.element)
		promptText.Text = "[E] Manage " .. habitatData.element .. " Habitat " .. elementIcon
		promptText.TextColor3 = getElementColor(habitatData.element)
	end

	interactionPrompt.Visible = true
	isPromptVisible = true
end

-- Function to hide interaction prompt
local function hidePrompt()
	if interactionPrompt then
		interactionPrompt.Visible = false
	end
	isPromptVisible = false
	nearbyHabitat = nil
end

-- Function to get element color
function getElementColor(element)
	local ElementColors = {
		Fire = Color3.fromRGB(255, 87, 34),
		Water = Color3.fromRGB(33, 150, 243),
		Earth = Color3.fromRGB(121, 85, 72),
		Plant = Color3.fromRGB(76, 175, 80),
		Electric = Color3.fromRGB(255, 235, 59)
	}
	return ElementColors[element] or Color3.fromRGB(255, 255, 255)
end

-- Function to get element icon
function getElementIcon(element)
	local ElementIcons = {
		Fire = "??",
		Water = "??",
		Earth = "??",
		Plant = "??",
		Electric = "?"
	}
	return ElementIcons[element] or "?"
end

-- ?? FIXED: Get habitat data using attributes
local function getHabitatData(habitat)
	-- Check attributes first (for restored habitats)
	local element = habitat:GetAttribute("Element")
	local owner = habitat:GetAttribute("Owner")
	local habitatType = habitat:GetAttribute("Type")
	local level = habitat:GetAttribute("Level") or 1

	-- Verify it's actually a habitat
	if habitatType ~= "Habitat" then
		print("? Not a habitat (Type:", habitatType, ")")
		return nil
	end

	-- Verify ownership
	if owner ~= player.UserId then
		print("? Not your habitat (Owner:", owner, "You:", player.UserId, ")")
		return nil
	end

	-- Make sure element exists
	if not element then
		-- Fallback: try to get from name pattern
		element = habitat.Name:match("^(.-)_")

		if not element then
			warn("? Habitat missing Element attribute:", habitat.Name)
			return nil
		end
	end

	-- Get current monsters in habitat
	local currentMonsters = 0

	-- Count monsters currently in habitat
	for _, child in pairs(habitat:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Monster" then
			currentMonsters = currentMonsters + 1
		end
	end

	-- Calculate max capacity based on level
	local maxCapacities = {
		[1] = 2,
		[2] = 3,
		[3] = 4
	}
	local maxCapacity = maxCapacities[level] or 2

	print("? Valid habitat detected:", element, "Level:", level, "Capacity:", currentMonsters .. "/" .. maxCapacity)

	return {
		habitatId = habitat.Name,
		element = element,
		level = level,
		currentMonsters = currentMonsters,
		maxCapacity = maxCapacity,
		position = habitat:GetPivot().Position,
		model = habitat
	}
end

-- Check nearby habitats with proper attribute checking
local function checkNearbyHabitats()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local playerPosition = character.HumanoidRootPart.Position
	local plotName = player:GetAttribute("AssignedPlot")

	if not plotName then
		return
	end

	local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
	if not plot then
		return
	end

	local closestHabitat = nil
	local closestDistance = math.huge
	local maxInteractionDistance = 15

	-- Check for habitats using Type attribute
	for _, child in pairs(plot:GetChildren()) do
		if child:IsA("Model") then
			local habitatType = child:GetAttribute("Type")
			local owner = child:GetAttribute("Owner")

			-- Only process if it's a habitat owned by this player
			if habitatType == "Habitat" and owner == player.UserId then
				local habitatPosition = child:GetPivot().Position
				local distance = (playerPosition - habitatPosition).Magnitude

				if distance < maxInteractionDistance and distance < closestDistance then
					closestDistance = distance
					closestHabitat = child
				end
			end
		end
	end

	-- Update prompt based on closest habitat
	if closestHabitat and closestHabitat ~= nearbyHabitat then
		nearbyHabitat = closestHabitat
		local habitatData = getHabitatData(closestHabitat)
		if habitatData then
			showPrompt(habitatData)
		end
	elseif not closestHabitat and nearbyHabitat then
		hidePrompt()
	end
end

-- Function to handle E key press
local function handleEKeyPress()
	if nearbyHabitat and isPromptVisible then
		local habitatData = getHabitatData(nearbyHabitat)
		if habitatData then
			-- Open monster selection UI (UI now handles capacity checking)
			if _G.ShowHabitatSelection then
				print("?? Opening habitat management for:", habitatData.element, "Level:", habitatData.level)
				_G.ShowHabitatSelection(habitatData)
			else
				warn("? UI function not available")
			end
		end
	end
end

-- Main detection loop
local detectionConnection = RunService.Heartbeat:Connect(function()
	checkNearbyHabitats()
end)

-- Handle E key input
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.KeyCode == Enum.KeyCode.E then
		handleEKeyPress()
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		hidePrompt()
		if detectionConnection then
			detectionConnection:Disconnect()
		end
	end
end)

print("? Habitat Interaction Detector loaded and running!")

--[[
?? FIXES APPLIED:
? Waits for HabitatMonsterSelectionController before starting
? Uses Type="Habitat" attribute for detection
? Verifies ownership with Owner attribute
? Gets Element attribute (no more guessing)
? Gets Level attribute for capacity calculation
? Counts monsters in habitat correctly
? Shows [E] prompt with element icon
? Opens new slot-based UI

?? HABITAT DETECTION:
? Detects models with Type="Habitat"
? Only shows prompt for player's own habitats
? Shows element and level in prompt
? 15 stud detection range
? Smooth prompt showing/hiding

?? USER FLOW:
1. Walk within 15 studs of your habitat
2. [E] prompt appears at bottom of screen
3. Press E to open slot-based management UI
4. Manage monsters, upgrade habitat, view income
--]]


print("? Habitat Interaction Detector loaded and running!")