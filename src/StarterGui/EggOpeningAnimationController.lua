-- EggOpeningAnimationController.lua (SIMPLIFIED VERSION - No Egg Animation)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = script.Parent

-- Get UI elements
local backgroundFrame = gui:WaitForChild("BackgroundFrame")
local animationFrame = backgroundFrame:WaitForChild("AnimationFrame")

-- Reel section (main focus)
local reelContainer = animationFrame:WaitForChild("ReelContainer")
local selectionIndicator = reelContainer:WaitForChild("SelectionIndicator")
local reelContent = reelContainer:WaitForChild("ReelContent")

-- Stats section
local statsContainer = animationFrame:WaitForChild("StatsContainer")
local monsterNameLabel = statsContainer:WaitForChild("MonsterNameLabel")
local statsGrid = statsContainer:WaitForChild("StatsGrid")
local hpLabel = statsGrid:WaitForChild("HPLabel")
local atkLabel = statsGrid:WaitForChild("ATKLabel")
local defLabel = statsGrid:WaitForChild("DEFLabel")
local spdLabel = statsGrid:WaitForChild("SPDLabel")

-- Skip button
local skipButton = animationFrame:WaitForChild("SkipButton")
local particleContainer = animationFrame:WaitForChild("ParticleContainer")

-- Optional title
local openingTitle = animationFrame:FindFirstChild("OpeningTitle")

-- Get Monster Images folder
local MonsterImages = ReplicatedStorage:FindFirstChild("MonsterImages")

-- Remote events
local startEggOpeningRemote = ReplicatedStorage:WaitForChild("StartEggOpening", 10)
local finishEggOpeningRemote = ReplicatedStorage:WaitForChild("FinishEggOpening", 10)

if not startEggOpeningRemote or not finishEggOpeningRemote then
	error("? RemoteEvents not found in ReplicatedStorage!")
end

print("? Simplified Egg Opening Animation loaded!")

-- Color schemes
local RarityColors = {
	Common = Color3.fromRGB(158, 158, 158),
	Rare = Color3.fromRGB(33, 150, 243),
	Epic = Color3.fromRGB(156, 39, 176),
	Legendary = Color3.fromRGB(255, 193, 7)
}

local ElementColors = {
	Fire = Color3.fromRGB(255, 87, 34),
	Water = Color3.fromRGB(33, 150, 243),
	Earth = Color3.fromRGB(121, 85, 72),
	Plant = Color3.fromRGB(76, 175, 80),
	Electric = Color3.fromRGB(255, 235, 59)
}

-- Variables
local isSkipping = false
local skipHoldTime = 0
local currentAnimation = nil

-- Function to get monster image
local function getMonsterImage(monsterName)
	if not MonsterImages then return "" end
	local imageValue = MonsterImages:FindFirstChild(monsterName)
	if imageValue and imageValue:IsA("StringValue") and imageValue.Value ~= "" then
		return imageValue.Value
	end
	return ""
end

-- Function to create monster card
local function createMonsterCard(monsterData, isWinner)
	local card = Instance.new("Frame")
	card.Name = "MonsterCard"
	card.Size = UDim2.new(0, 160, 0, 160)
	card.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	-- Rarity glow
	local rarityGlow = Instance.new("Frame")
	rarityGlow.Size = UDim2.new(1, 0, 1, 0)
	rarityGlow.BackgroundColor3 = RarityColors[monsterData.Rarity] or Color3.fromRGB(255, 255, 255)
	rarityGlow.BackgroundTransparency = 0.7
	rarityGlow.BorderSizePixel = 0
	rarityGlow.ZIndex = 2
	rarityGlow.Parent = card

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 12)
	glowCorner.Parent = rarityGlow

	-- Monster image
	local monsterImage = Instance.new("ImageLabel")
	monsterImage.Size = UDim2.new(0, 90, 0, 90)
	monsterImage.Position = UDim2.new(0.5, -45, 0, 15)
	monsterImage.BackgroundTransparency = 1
	monsterImage.BorderSizePixel = 0
	monsterImage.ZIndex = 3
	monsterImage.Parent = card

	local imageId = getMonsterImage(monsterData.Name)
	if imageId ~= "" then
		monsterImage.Image = imageId
	else
		monsterImage.Image = ""
		monsterImage.BackgroundColor3 = ElementColors[monsterData.Element] or Color3.fromRGB(100, 100, 100)
		monsterImage.BackgroundTransparency = 0.3
	end

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 10)
	imageCorner.Parent = monsterImage

	-- Monster name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 25)
	nameLabel.Position = UDim2.new(0, 5, 0, 110)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = monsterData.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.ZIndex = 3
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -10, 0, 18)
	rarityLabel.Position = UDim2.new(0, 5, 0, 135)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = monsterData.Rarity
	rarityLabel.TextColor3 = RarityColors[monsterData.Rarity] or Color3.fromRGB(200, 200, 200)
	rarityLabel.TextSize = 11
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.ZIndex = 3
	rarityLabel.Parent = card

	return card
end

-- Generate reel monsters
local function generateReelMonsters(winnerMonster)
	local allMonsters = {
		{Name = "Ignis", Element = "Fire", Rarity = "Common"},
		{Name = "Aquara", Element = "Water", Rarity = "Common"},
		{Name = "Terrock", Element = "Earth", Rarity = "Rare"},
		{Name = "Voltwing", Element = "Electric", Rarity = "Rare"},
		{Name = "Floraleaf", Element = "Plant", Rarity = "Epic"},
	}

	local reelMonsters = {}
	local winnerIndex = math.random(10, 14)

	for i = 1, winnerIndex - 1 do
		table.insert(reelMonsters, allMonsters[math.random(1, #allMonsters)])
	end

	table.insert(reelMonsters, winnerMonster)

	for i = 1, 8 do
		table.insert(reelMonsters, allMonsters[math.random(1, #allMonsters)])
	end

	return reelMonsters, winnerIndex
end

-- Particle burst
local function createParticleBurst(rarity)
	for i = 1, 40 do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(8, 18), 0, math.random(8, 18))
		particle.Position = UDim2.new(0.5, 0, 0.5, 0)
		particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.BackgroundColor3 = RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
		particle.BorderSizePixel = 0
		particle.ZIndex = 7
		particle.Parent = particleContainer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		local angle = math.random() * math.pi * 2
		local distance = math.random(150, 400)
		local endX = 0.5 + math.cos(angle) * distance / animationFrame.AbsoluteSize.X
		local endY = 0.5 + math.sin(angle) * distance / animationFrame.AbsoluteSize.Y

		local tween = TweenService:Create(particle, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(endX, 0, endY, 0),
			BackgroundTransparency = 1
		})
		tween:Play()

		task.delay(1.2, function()
			particle:Destroy()
		end)
	end
end

-- Count up stats
local function countUpNumber(label, targetNumber, duration, prefix)
	local startNumber = 0
	local elapsed = 0

	while elapsed < duration and not isSkipping do
		elapsed = elapsed + task.wait()
		local progress = math.min(elapsed / duration, 1)
		local currentNumber = math.floor(startNumber + (targetNumber - startNumber) * progress)
		label.Text = prefix .. currentNumber
	end

	label.Text = prefix .. targetNumber
end

-- Main animation
local function playEggOpeningAnimation(monsterData)
	print("?? Starting simplified animation for:", monsterData.Name)

	-- Show UI
	backgroundFrame.Visible = true
	statsContainer.Visible = false
	skipButton.Visible = true
	isSkipping = false
	skipHoldTime = 0

	-- Update title if exists
	if openingTitle then
		openingTitle.Text = "?? OPENING EGG..."
		openingTitle.Visible = true
	end

	-- Clear old content
	for _, child in pairs(reelContent:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, child in pairs(particleContainer:GetChildren()) do
		child:Destroy()
	end

	-- Generate reel
	local reelMonsters, winnerIndex = generateReelMonsters(monsterData)

	for i, monster in ipairs(reelMonsters) do
		local card = createMonsterCard(monster, i == winnerIndex)
		card.Parent = reelContent
	end

	task.wait(0.15)

	-- Calculate positions
	local cardWidth = 180
	local totalWidth = #reelMonsters * cardWidth
	reelContent.Size = UDim2.new(0, totalWidth, 1, 0)

	local containerWidth = reelContainer.AbsoluteSize.X
	local finalPosition = -((winnerIndex - 1) * cardWidth) + (containerWidth / 2) - (cardWidth / 2)
	local startPosition = finalPosition + 2500

	reelContent.Position = UDim2.new(0, startPosition, 0, 0)

	-- Fast scroll
	if not isSkipping then
		local fastTween = TweenService:Create(
			reelContent,
			TweenInfo.new(1.2, Enum.EasingStyle.Linear),
			{Position = UDim2.new(0, finalPosition + 500, 0, 0)}
		)
		fastTween:Play()
		fastTween.Completed:Wait()
	end

	-- Slow scroll (CS:GO moment)
	if isSkipping then
		reelContent.Position = UDim2.new(0, finalPosition, 0, 0)
	else
		local slowTween = TweenService:Create(
			reelContent,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = UDim2.new(0, finalPosition, 0, 0)}
		)
		currentAnimation = slowTween
		slowTween:Play()

		-- Pulse indicator
		task.spawn(function()
			for i = 1, 4 do
				if isSkipping then break end
				TweenService:Create(selectionIndicator, TweenInfo.new(0.25), {BackgroundTransparency = 0.4}):Play()
				task.wait(0.25)
				TweenService:Create(selectionIndicator, TweenInfo.new(0.25), {BackgroundTransparency = 0.8}):Play()
				task.wait(0.25)
			end
		end)

		-- Wait with timeout
		local completed = false
		slowTween.Completed:Connect(function() completed = true end)

		local maxWait = 0
		while not completed and maxWait < 2.5 do
			task.wait(0.1)
			maxWait = maxWait + 0.1
			if isSkipping then break end
		end

		if not completed then
			slowTween:Cancel()
			reelContent.Position = UDim2.new(0, finalPosition, 0, 0)
		end
	end

	-- Winner reveal
	task.wait(0.2)

	local winnerCard = nil
	local cardIndex = 1
	for _, child in pairs(reelContent:GetChildren()) do
		if child:IsA("Frame") then
			if cardIndex == winnerIndex then
				winnerCard = child
				break
			end
			cardIndex = cardIndex + 1
		end
	end

	if winnerCard then
		TweenService:Create(winnerCard, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 4, true), {
			Size = UDim2.new(0, 180, 0, 180)
		}):Play()
	end

	-- Particle explosion
	createParticleBurst(monsterData.Rarity)

	-- Update title
	if openingTitle then
		openingTitle.Text = "? " .. monsterData.Rarity:upper() .. " MONSTER!"
		openingTitle.TextColor3 = RarityColors[monsterData.Rarity]
	end

	task.wait(0.8)

	-- Show stats
	statsContainer.Visible = true
	skipButton.Visible = false

	monsterNameLabel.Text = ""
	monsterNameLabel.TextColor3 = RarityColors[monsterData.Rarity]

	if not isSkipping then
		for i = 1, #monsterData.Name do
			if isSkipping then
				monsterNameLabel.Text = monsterData.Name
				break
			end
			monsterNameLabel.Text = string.sub(monsterData.Name, 1, i)
			task.wait(0.04)
		end
		task.wait(0.2)
	else
		monsterNameLabel.Text = monsterData.Name
	end

	-- Count stats
	if not isSkipping then
		task.spawn(function() countUpNumber(hpLabel, monsterData.HP, 0.8, "HP: ") end)
		task.spawn(function() countUpNumber(atkLabel, monsterData.Attack, 0.8, "ATK: ") end)
		task.spawn(function() countUpNumber(defLabel, monsterData.Defense, 0.8, "DEF: ") end)
		countUpNumber(spdLabel, monsterData.Speed, 0.8, "SPD: ")
		task.wait(0.3)
	else
		hpLabel.Text = "HP: " .. monsterData.HP
		atkLabel.Text = "ATK: " .. monsterData.Attack
		defLabel.Text = "DEF: " .. monsterData.Defense
		spdLabel.Text = "SPD: " .. monsterData.Speed
	end

	-- Close and show catch/sell
	task.wait(0.8)
	backgroundFrame.Visible = false

	finishEggOpeningRemote:FireServer(monsterData)

	print("? Animation complete!")
end

-- Skip button
skipButton.MouseButton1Down:Connect(function()
	skipHoldTime = 0
end)

skipButton.MouseButton1Up:Connect(function()
	skipHoldTime = 0
	skipButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	skipButton.Text = "? HOLD TO SKIP"
end)

-- Skip detection
task.spawn(function()
	while true do
		task.wait(0.1)
		if skipButton.Visible and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			local mousePos = UserInputService:GetMouseLocation()
			local guiPos = skipButton.AbsolutePosition
			local guiSize = skipButton.AbsoluteSize

			if mousePos.X >= guiPos.X and mousePos.X <= guiPos.X + guiSize.X and
				mousePos.Y >= guiPos.Y and mousePos.Y <= guiPos.Y + guiSize.Y then
				skipHoldTime = skipHoldTime + 0.1

				local progress = math.min(skipHoldTime / 1.5, 1)
				skipButton.BackgroundColor3 = Color3.fromRGB(
					100 + (155 * progress),
					100 - (40 * progress),
					120 - (60 * progress)
				)

				if skipHoldTime >= 1.5 then
					isSkipping = true
					if currentAnimation then currentAnimation:Cancel() end
					skipButton.Text = "? SKIPPING..."
				end
			else
				skipHoldTime = 0
			end
		else
			if skipHoldTime > 0 and skipHoldTime < 1.5 then
				skipHoldTime = 0
				skipButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
			end
		end
	end
end)

-- Listen
startEggOpeningRemote.OnClientEvent:Connect(function(monsterData)
	print("?? CLIENT: Received event for:", monsterData.Name)
	if monsterData and monsterData.Name then
		playEggOpeningAnimation(monsterData)
	end
end)

-- Initialize
backgroundFrame.Visible = false

print("? Simplified Egg Opening Animation loaded!")
