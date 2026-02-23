local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)
-- SERVER SCRIPT: MonsterHabitatSystem
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Create remote events
local placeMonsterRemote = ReplicatedStorage:FindFirstChild("PlaceMonster")
if not placeMonsterRemote then
	placeMonsterRemote = Instance.new("RemoteEvent")
	placeMonsterRemote.Name = "PlaceMonster"
	placeMonsterRemote.Parent = ReplicatedStorage
end

local removeMonsterRemote = ReplicatedStorage:FindFirstChild("RemoveMonster")
if not removeMonsterRemote then
	removeMonsterRemote = Instance.new("RemoteEvent")
	removeMonsterRemote.Name = "RemoveMonster"
	removeMonsterRemote.Parent = ReplicatedStorage
end

-- Income settings
local INCOME_SETTINGS = {
	baseIncome = 10, -- base coins per minute
	rarityMultipliers = {
		Common = 1,
		Rare = 2,
		Epic = 4,
		Legendary = 8
	},
	elementMultipliers = {
		Fire = 1,
		Water = 1,
		Earth = 1,
		Plant = 1,
		Electric = 1
	},
	incomeInterval = 60 -- seconds between income payments
}

-- Track active income generators
local activeIncomeGenerators = {}

-- Function to create monster model in habitat
local function createMonsterModel(habitatModel, monsterData)
	-- Create a simple monster representation (you can make this more complex)
	local monster = Instance.new("Part")
	monster.Name = "Monster"
	monster.Size = Vector3.new(2, 2, 2)
	monster.Shape = Enum.PartType.Ball
	monster.CanCollide = false
	monster.Anchored = true
	monster.TopSurface = Enum.SurfaceType.Smooth
	monster.BottomSurface = Enum.SurfaceType.Smooth

	-- Set color based on element
	local elementColors = {
		Fire = Color3.fromRGB(255, 100, 100),
		Water = Color3.fromRGB(100, 150, 255),
		Earth = Color3.fromRGB(139, 69, 19),
		Plant = Color3.fromRGB(100, 255, 100),
		Electric = Color3.fromRGB(255, 255, 100)
	}
	monster.Color = elementColors[monsterData.Element.Value] or Color3.fromRGB(150, 150, 150)

	-- Add glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = monster.Color
	pointLight.Brightness = 0.5
	pointLight.Range = 10
	pointLight.Parent = monster

	-- Position monster in center of habitat
	if habitatModel.PrimaryPart then
		local habitatPosition = habitatModel.PrimaryPart.Position
		monster.Position = habitatPosition + Vector3.new(0, 3, 0)
	end

	-- Add name tag
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 100, 0, 50)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.Parent = monster

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = monsterData.MonsterName.Value
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0.4, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.6, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = monsterData.Rarity.Value
	rarityLabel.TextColor3 = elementColors[monsterData.Element.Value] or Color3.fromRGB(150, 150, 150)
	rarityLabel.TextSize = 10
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.Parent = gui

	monster.Parent = habitatModel

	-- Add floating animation
	local floatTween = game:GetService("TweenService"):Create(
		monster,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Position = monster.Position + Vector3.new(0, 1, 0)}
	)
	floatTween:Play()

	return monster
end

-- Function to calculate income for a monster
local function calculateIncome(monsterData)
	local base = INCOME_SETTINGS.baseIncome
	local rarityMult = INCOME_SETTINGS.rarityMultipliers[monsterData.Rarity.Value] or 1
	local elementMult = INCOME_SETTINGS.elementMultipliers[monsterData.Element.Value] or 1
	local levelMult = monsterData.Level.Value * 0.1 + 1 -- 10% bonus per level

	return math.floor(base * rarityMult * elementMult * levelMult)
end

-- Function to start income generation
local function startIncomeGeneration(player, habitatId, monsterData)
	local key = player.UserId .. "_" .. habitatId

	-- Stop existing income if any
	if activeIncomeGenerators[key] then
		activeIncomeGenerators[key]:Disconnect()
	end

	-- Start new income generation
	local connection = task.spawn(function()
		while true do
			task.wait(INCOME_SETTINGS.incomeInterval)

			-- Check if player is still in game and habitat still exists
			if not player.Parent then break end

			local plotName = player:GetAttribute("AssignedPlot")
			local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
			local habitat = plot and plot:FindFirstChild(habitatId)

			if not habitat or not habitat:FindFirstChild("Monster") then
				break -- Stop income if habitat or monster is gone
			end

			-- Give income
			local leaderstats = player:FindFirstChild("leaderstats")
			local coins = leaderstats and leaderstats:FindFirstChild("Coins")
			if coins then
				local income = calculateIncome(monsterData)
				coins.Value += income
				print("?? Income:", income, "coins for", player.Name, "from", monsterData.MonsterName.Value)
			end
		end
	end)

	activeIncomeGenerators[key] = connection
end

-- Function to stop income generation
local function stopIncomeGeneration(player, habitatId)
	local key = player.UserId .. "_" .. habitatId
	if activeIncomeGenerators[key] then
		activeIncomeGenerators[key]:Disconnect()
		activeIncomeGenerators[key] = nil
	end
end

-- Handle placing monster in habitat
placeMonsterRemote.OnServerEvent:Connect(function(player, monsterId, habitatId)
	-- Find monster in player's inventory
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then return end

	local monsterData = monstersFolder:FindFirstChild(monsterId)
	if not monsterData then
		warn("? Monster not found:", monsterId)
		return
	end

	-- Find habitat
	local plotName = player:GetAttribute("AssignedPlot")
	local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
	if not plot then
		warn("? Plot not found for player:", plotName)
		return
	end

	local habitat = plot:FindFirstChild(habitatId)
	if not habitat then
		warn("? Habitat not found:", habitatId)
		return
	end

	-- Check if habitat already has a monster
	if habitat:FindFirstChild("Monster") then
		warn("? Habitat already has a monster")
		return
	end

	-- Check if monster element matches habitat (optional requirement)
	local habitatType = habitatId:match("^(.-)_")
	local monsterElement = monsterData:FindFirstChild("Element")
	if habitatType and monsterElement and habitatType ~= monsterElement.Value then
		warn("? Monster element doesn't match habitat:", monsterElement.Value, "vs", habitatType)
		return
	end

	-- Create monster model
	local monsterModel = createMonsterModel(habitat, monsterData)

	-- Start income generation
	startIncomeGeneration(player, habitatId, monsterData)

	-- Move monster from inventory to habitat (store data in habitat)
	local habitatMonsterData = monsterData:Clone()
	habitatMonsterData.Parent = habitat
	monsterData:Destroy()

	print("? Monster placed:", monsterData.MonsterName.Value, "in habitat:", habitatId)
end)

-- Handle removing monster from habitat
removeMonsterRemote.OnServerEvent:Connect(function(player, habitatId)
	local plotName = player:GetAttribute("AssignedPlot")
	local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
	if not plot then return end

	local habitat = plot:FindFirstChild(habitatId)
	if not habitat then return end

	local monster = habitat:FindFirstChild("Monster")
	local monsterData = nil

	-- Find monster data in habitat
	for _, child in pairs(habitat:GetChildren()) do
		if child:IsA("Folder") and child.Name:match("_") then
			monsterData = child
			break
		end
	end

	if not monster or not monsterData then
		warn("? No monster found in habitat")
		return
	end

	-- Stop income generation
	stopIncomeGeneration(player, habitatId)

	-- Move monster back to inventory
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then
		monstersFolder = Instance.new("Folder")
		monstersFolder.Name = "Monsters"
		monstersFolder.Parent = player
	end

	monsterData.Parent = monstersFolder
	monster:Destroy()

	print("?? Monster removed from habitat:", habitatId)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	-- Stop all income generators for this player
	for key, connection in pairs(activeIncomeGenerators) do
		if key:match("^" .. player.UserId .. "_") then
			connection:Disconnect()
			activeIncomeGenerators[key] = nil
		end
	end
end)

-- Clean up when habitat is destroyed (from the habitat removal system)
workspace.DescendantRemoving:Connect(function(instance)
	if instance.Name:match("_") and instance.Parent and instance.Parent.Name:match("^Plot%d+$") then
		-- This might be a habitat being removed
		task.wait() -- Small delay to ensure removal is complete

		-- Find which player this habitat belonged to
		for _, player in pairs(Players:GetPlayers()) do
			stopIncomeGeneration(player, instance.Name)
		end
	end
end)