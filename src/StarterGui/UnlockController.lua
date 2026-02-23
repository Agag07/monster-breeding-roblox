-- StarterGui/BreedingMachineUnlockUI/UnlockController.lua (LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

-- Get UI elements
local unlockFrame = gui:WaitForChild("UnlockFrame")
local titleLabel = unlockFrame:WaitForChild("TitleLabel")
local infoLabel = unlockFrame:WaitForChild("InfoLabel")
local requirementsFrame = unlockFrame:WaitForChild("RequirementsFrame")
local monstersReqLabel = requirementsFrame:WaitForChild("MonstersRequirement")
local coinsReqLabel = requirementsFrame:WaitForChild("CoinsRequirement")
local unlockButton = unlockFrame:WaitForChild("UnlockButton")
local closeButton = unlockFrame:WaitForChild("CloseButton")
local progressLabel = unlockFrame:WaitForChild("ProgressLabel")

-- Get remote events
local unlockBreedingTierRemote = ReplicatedStorage:WaitForChild("UnlockBreedingTier", 10)

if not unlockBreedingTierRemote then
	warn("? UnlockBreedingTier remote not found!")
	return
end

print("? Unlock Controller: Remote event found")

-- Variables
local currentTier = nil
local currentTierData = {
	[1] = {price = 500, monstersRequired = 0, name = "Basic Breeding Machine"},
	[2] = {price = 1500, monstersRequired = 10, name = "Advanced Breeding Machine"},
	[3] = {price = 3000, monstersRequired = 25, name = "Master Breeding Machine"}
}

-- Function to show unlock prompt
local function showUnlockPrompt(tier)
	print("?? Showing unlock prompt for Tier", tier)

	currentTier = tier
	local tierData = currentTierData[tier]

	if not tierData then 
		warn("? Invalid tier data for tier:", tier)
		return 
	end

	-- Update UI
	titleLabel.Text = "?? " .. tierData.name
	infoLabel.Text = "Tier " .. tier .. " Breeding Machine"

	-- Get player stats
	local monstersFolder = player:FindFirstChild("Monsters")
	local monstersCollected = monstersFolder and #monstersFolder:GetChildren() or 0

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local playerCoins = coins and coins.Value or 0

	-- Update requirements
	local monstersNeeded = tierData.monstersRequired
	local hasMonstersReq = monstersCollected >= monstersNeeded

	if hasMonstersReq then
		monstersReqLabel.Text = "? Monsters: " .. monstersCollected .. "/" .. monstersNeeded
		monstersReqLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		monstersReqLabel.Text = "? Monsters: " .. monstersCollected .. "/" .. monstersNeeded
		monstersReqLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	local hasCoinsReq = playerCoins >= tierData.price

	if hasCoinsReq then
		coinsReqLabel.Text = "? Coins: " .. playerCoins .. "/" .. tierData.price
		coinsReqLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		coinsReqLabel.Text = "? Coins: " .. playerCoins .. "/" .. tierData.price
		coinsReqLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	-- Update progress label
	if monstersNeeded > 0 then
		local percent = math.floor((monstersCollected / monstersNeeded) * 100)
		progressLabel.Text = "Collection Progress: " .. percent .. "%"
		progressLabel.Visible = true
	else
		progressLabel.Visible = false
	end

	-- Enable/disable unlock button
	local canUnlock = hasMonstersReq and hasCoinsReq
	unlockButton.BackgroundColor3 = canUnlock and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(100, 100, 100)
	unlockButton.TextColor3 = canUnlock and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
	unlockButton.Text = canUnlock and ("UNLOCK (" .. tierData.price .. " coins)") or "NOT READY"

	-- Show frame with animation
	unlockFrame.Visible = true
	unlockFrame.Size = UDim2.new(0, 0, 0, 0)
	unlockFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(unlockFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 400, 0, 350),
		Position = UDim2.new(0.5, -200, 0.5, -175)
	})
	tween:Play()

	print("? Unlock UI shown successfully")
end

-- Function to close unlock prompt
local function closeUnlockPrompt()
	local tween = TweenService:Create(unlockFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		unlockFrame.Visible = false
		currentTier = nil
	end)
end

-- Handle unlock button click
unlockButton.MouseButton1Click:Connect(function()
	if not currentTier then return end

	local tierData = currentTierData[currentTier]

	-- Check requirements again
	local monstersFolder = player:FindFirstChild("Monsters")
	local monstersCollected = monstersFolder and #monstersFolder:GetChildren() or 0

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local playerCoins = coins and coins.Value or 0

	if monstersCollected < tierData.monstersRequired or playerCoins < tierData.price then
		-- Flash button red
		local originalColor = unlockButton.BackgroundColor3
		unlockButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		task.wait(0.2)
		unlockButton.BackgroundColor3 = originalColor
		return
	end

	-- Send unlock request to server
	print("?? Requesting unlock for Tier", currentTier)
	unlockBreedingTierRemote:FireServer(currentTier)

	-- Disable button temporarily
	unlockButton.Text = "UNLOCKING..."
	unlockButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
end)

-- Handle close button
closeButton.MouseButton1Click:Connect(function()
	closeUnlockPrompt()
end)

-- Handle server responses
unlockBreedingTierRemote.OnClientEvent:Connect(function(action, message)
	print("?? [CLIENT] Received unlock response:", action, message)

	-- Case 1: Server wants us to show unlock UI
	if action == "ShowUnlockUI" then
		local tier = message -- In this case, message is the tier number
		print("?? [CLIENT] Server requested to show unlock UI for tier:", tier)
		showUnlockPrompt(tier)

		-- Case 2: Unlock was successful
	elseif action == true then
		print("? [CLIENT] Unlock successful!")
		unlockButton.Text = "? UNLOCKED!"
		unlockButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		task.wait(1)
		closeUnlockPrompt()

		-- Case 3: Unlock failed
	elseif action == false then
		warn("? [CLIENT] Unlock failed:", message)
		unlockButton.Text = "? " .. message
		unlockButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		task.wait(2)
		-- Reset button
		if currentTier then
			showUnlockPrompt(currentTier)
		end
	end
end)

-- Initialize
unlockFrame.Visible = false

print("?? Breeding Machine Unlock Controller loaded!")

--[[
?? DEBUGGING ADDED:
- Print statements at key points to track execution
- Better error messages
- Validates remote event exists
--]]
