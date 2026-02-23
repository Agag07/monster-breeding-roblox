-- IncubatorInteractionClient.lua (Physical UI Version) - FIXED
-- Put this as LocalScript inside your IncubatorInteractionGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local screenGui = script.Parent
local mouse = player:GetMouse()

-- Get UI elements (with error handling)
local incubatorFrame = screenGui:WaitForChild("IncubatorFrame")
local titleBar = incubatorFrame:WaitForChild("TitleBar")

-- Find title text (try different possible names)
local titleText = titleBar:FindFirstChild("TitleText") or 
	titleBar:FindFirstChild("Title") or 
	titleBar:FindFirstChild("TitleLabel")

if not titleText then
	-- Create missing title text
	titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, -120, 1, 0)
	titleText.Position = UDim2.new(0, 20, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "?? SELECT EGG FOR INCUBATOR"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.TextSize = 20
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar
end

local closeButton = titleBar:WaitForChild("CloseButton")

local incubatorInfo = incubatorFrame:WaitForChild("IncubatorInfo")
-- ? REMOVED: IncubatorIcon (not needed)
local incubatorName = incubatorInfo:WaitForChild("IncubatorName")
local incubatorSpeedLabel = incubatorInfo:WaitForChild("IncubatorSpeedLabel")

local eggSelectionLabel = incubatorFrame:WaitForChild("EggSelectionLabel")
local eggScrollFrame = incubatorFrame:WaitForChild("EggScrollFrame")

-- Remote events (create if they don't exist)
local placeEggRemote = ReplicatedStorage:FindFirstChild("PlaceEgg")
if not placeEggRemote then
	placeEggRemote = Instance.new("RemoteEvent")
	placeEggRemote.Name = "PlaceEgg"
	placeEggRemote.Parent = ReplicatedStorage
end

-- Variables
local currentIncubatorId = nil
local currentIncubatorData = nil

-- Color schemes for rarity
local RarityColors = {
	Common = Color3.fromRGB(160, 160, 160),    -- Light gray
	Rare = Color3.fromRGB(0, 150, 255),        -- Blue
	Epic = Color3.fromRGB(160, 32, 240),       -- Purple
	Legendary = Color3.fromRGB(255, 215, 0)    -- Gold
}

-- Function to create egg cards (matching your UI structure)
local function createEggCard(eggData, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = eggData.uniqueId
	card.Size = UDim2.new(0, 170, 0, 100)
	card.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = eggScrollFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	-- Egg icon
	local eggIcon = Instance.new("TextLabel")
	eggIcon.Name = "EggIcon"
	eggIcon.Size = UDim2.new(0, 40, 0, 40)
	eggIcon.Position = UDim2.new(0, 10, 0, 10)
	eggIcon.BackgroundTransparency = 1
	eggIcon.Text = "??"
	eggIcon.TextSize = 30
	eggIcon.Parent = card

	-- Egg type label
	local typeLabel = Instance.new("TextLabel")
	typeLabel.Name = "TypeLabel"
	typeLabel.Size = UDim2.new(1, -60, 0, 25)
	typeLabel.Position = UDim2.new(0, 55, 0, 10)
	typeLabel.BackgroundTransparency = 1
	typeLabel.Text = eggData.eggType:gsub("Egg", " Egg")
	typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	typeLabel.TextSize = 14
	typeLabel.Font = Enum.Font.GothamBold
	typeLabel.TextXAlignment = Enum.TextXAlignment.Left
	typeLabel.TextWrapped = true
	typeLabel.Parent = card

	-- Hatch time label
	local hatchLabel = Instance.new("TextLabel")
	hatchLabel.Name = "HatchLabel"
	hatchLabel.Size = UDim2.new(1, -60, 0, 20)
	hatchLabel.Position = UDim2.new(0, 55, 0, 35)
	hatchLabel.BackgroundTransparency = 1
	hatchLabel.Text = "?? " .. eggData.hatchTime .. "s"
	hatchLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	hatchLabel.TextSize = 12
	hatchLabel.Font = Enum.Font.Gotham
	hatchLabel.TextXAlignment = Enum.TextXAlignment.Left
	hatchLabel.Parent = card

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, -20, 0, 20)
	rarityLabel.Position = UDim2.new(0, 10, 0, 55)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = eggData.rarity
	rarityLabel.TextSize = 11
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
	rarityLabel.TextColor3 = RarityColors[eggData.rarity] or Color3.fromRGB(200, 200, 200)
	rarityLabel.Parent = card

	-- Select button
	local selectButton = Instance.new("TextButton")
	selectButton.Name = "SelectButton"
	selectButton.Size = UDim2.new(0, 60, 0, 20)
	selectButton.Position = UDim2.new(1, -70, 1, -30)
	selectButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	selectButton.Text = "SELECT"
	selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectButton.TextSize = 10
	selectButton.Font = Enum.Font.GothamBold
	selectButton.BorderSizePixel = 0
	selectButton.Parent = card

	local selectCorner = Instance.new("UICorner")
	selectCorner.CornerRadius = UDim.new(0, 5)
	selectCorner.Parent = selectButton

	-- Button hover effects
	selectButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(selectButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(120, 220, 120)
		})
		tween:Play()
	end)

	selectButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(selectButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		})
		tween:Play()
	end)

	-- Button click functionality
	selectButton.MouseButton1Click:Connect(function()
		print("?? Placing egg:", eggData.eggType, "in incubator:", currentIncubatorId)

		-- Send to server with incubator speed for timer calculation
		placeEggRemote:FireServer(eggData.uniqueId, currentIncubatorId, currentIncubatorData)

		-- Close UI
		incubatorFrame.Visible = false

		-- Show confirmation
		titleText.Text = "?? EGG PLACED! Check your incubator!"
		wait(2)
		titleText.Text = "?? SELECT EGG FOR INCUBATOR"
	end)

	return card
end

-- Function to update egg list from player inventory
local function updateEggList()
	-- Clear existing egg cards
	for _, child in pairs(eggScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get eggs from player inventory
	local eggsFolder = player:FindFirstChild("Eggs")
	if not eggsFolder or #eggsFolder:GetChildren() == 0 then
		-- Show "no eggs" message
		local noEggsLabel = Instance.new("TextLabel")
		noEggsLabel.Name = "NoEggsMessage"
		noEggsLabel.Size = UDim2.new(1, -20, 0, 100)
		noEggsLabel.Position = UDim2.new(0, 10, 0, 10)
		noEggsLabel.BackgroundTransparency = 1
		noEggsLabel.Text = "No eggs in inventory!\n\nBuy some eggs from the Egg Shop first."
		noEggsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noEggsLabel.TextSize = 16
		noEggsLabel.Font = Enum.Font.Gotham
		noEggsLabel.TextWrapped = true
		noEggsLabel.TextXAlignment = Enum.TextXAlignment.Center
		noEggsLabel.TextYAlignment = Enum.TextYAlignment.Center
		noEggsLabel.Parent = eggScrollFrame

		eggScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 120)
		return
	end

	-- Create cards for each egg
	local order = 1
	for _, egg in pairs(eggsFolder:GetChildren()) do
		if egg:IsA("Folder") then
			local eggTypeValue = egg:FindFirstChild("EggType")
			local hatchTimeValue = egg:FindFirstChild("HatchTime")
			local rarityValue = egg:FindFirstChild("Rarity")

			if eggTypeValue and hatchTimeValue and rarityValue then
				local eggData = {
					uniqueId = egg.Name,
					eggType = eggTypeValue.Value,
					hatchTime = hatchTimeValue.Value,
					rarity = rarityValue.Value
				}
				createEggCard(eggData, order)
				order += 1
			end
		end
	end

	-- Update canvas size for scrolling
	eggScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(order / 3) * 110 + 20)
end

-- Function to open incubator UI
local function openIncubatorUI(incubatorId, incubatorType, incubatorSpeed)
	currentIncubatorId = incubatorId
	currentIncubatorData = {
		type = incubatorType,
		speed = incubatorSpeed or 1.0
	}

	-- Update incubator info display
	local displayName = incubatorType:gsub("Incubator", " Incubator")
	incubatorName.Text = displayName

	-- Set incubator-specific info (without icon)
	if incubatorType == "NormalIncubator" then
		incubatorSpeedLabel.Text = "Normal hatching speed (1.0x)"
	elseif incubatorType == "SuperIncubator" then
		incubatorSpeedLabel.Text = "50% faster hatching (1.5x)"
	elseif incubatorType == "UltraIncubator" then
		incubatorSpeedLabel.Text = "100% faster hatching (2.0x)"
	else
		incubatorSpeedLabel.Text = "Normal hatching speed"
	end

	-- Update egg list and show UI
	updateEggList()

	-- Show UI with animation
	incubatorFrame.Visible = true
	incubatorFrame.Size = UDim2.new(0, 0, 0, 0)
	incubatorFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(incubatorFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 600, 0, 500),
		Position = UDim2.new(0.5, -300, 0.5, -250)
	})
	tween:Play()
end

-- Function to close incubator UI
local function closeIncubatorUI()
	local tween = TweenService:Create(incubatorFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		incubatorFrame.Visible = false
	end)
end

-- Event connections
closeButton.MouseButton1Click:Connect(function()
	closeIncubatorUI()
end)

-- Handle clicking on incubators in the world - FIXED
mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if target then
		-- Check if clicking on an incubator in player's plot
		local plotName = player:GetAttribute("AssignedPlot")
		
		-- FIXED: Validate plotName is not nil
		if not plotName then
			print("? Player has no assigned plot yet")
			return
		end
		
		local plotsFolder = workspace:FindFirstChild("PlotsF")
		if not plotsFolder then
			print("? PlotsF folder not found in workspace")
			return
		end
		
		local plot = plotsFolder:FindFirstChild(plotName)
		if not plot then
			print("? Plot not found:", plotName)
			return
		end

		if target:IsDescendantOf(plot) then
			local object = target
			while object and object.Parent ~= plot do
				object = object.Parent
			end

			if object and object:IsA("Model") and object:GetAttribute("Type") == "Incubator" then
				-- Check if incubator already has an egg
				if not object:GetAttribute("EggId") then
					local incubatorType = object:GetAttribute("IncubatorType") or "NormalIncubator"
					local speedMultiplier = object:GetAttribute("Speed") or 1.0
					openIncubatorUI(object.Name, incubatorType, speedMultiplier)
				else
					print("?? This incubator already has an egg incubating!")
					-- TODO: Show timer UI for existing egg
				end
			end
		end
	end
end)

-- Global function for other scripts
_G.OpenIncubatorUI = openIncubatorUI

-- Initialize as hidden
incubatorFrame.Visible = false

print("? Incubator Interaction UI loaded!")
