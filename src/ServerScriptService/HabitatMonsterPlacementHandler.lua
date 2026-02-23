-- HabitatMonsterPlacementHandler.lua (ServerScript in ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

-- Get/Create remote event
local placeMonsterInHabitatRemote = ReplicatedStorage:FindFirstChild("PlaceMonsterInHabitat")
if not placeMonsterInHabitatRemote then
	placeMonsterInHabitatRemote = Instance.new("RemoteEvent")
	placeMonsterInHabitatRemote.Name = "PlaceMonsterInHabitat"
	placeMonsterInHabitatRemote.Parent = ReplicatedStorage
end

-- Get monster models folder (create if it doesn't exist)
local MonsterModels = ReplicatedStorage:FindFirstChild("MonsterModels")
if not MonsterModels then
	MonsterModels = Instance.new("Folder")
	MonsterModels.Name = "MonsterModels"
	MonsterModels.Parent = ReplicatedStorage

	-- Create basic monster models for testing
	createBasicMonsterModels()
end

-- Function to create basic monster models (for testing)
function createBasicMonsterModels()
	local monsterNames = {"Ignis", "Aquara", "Terrock", "Voltwing", "Floraleaf"}
	local elementColors = {
		Ignis = Color3.fromRGB(255, 100, 100),    -- Fire - Red
		Aquara = Color3.fromRGB(100, 150, 255),   -- Water - Blue  
		Terrock = Color3.fromRGB(139, 69, 19),    -- Earth - Brown
		Voltwing = Color3.fromRGB(255, 255, 100), -- Electric - Yellow
		Floraleaf = Color3.fromRGB(100, 255, 100) -- Plant - Green
	}

	for _, monsterName in pairs(monsterNames) do
		local monsterModel = Instance.new("Part")
		monsterModel.Name = monsterName
		monsterModel.Size = Vector3.new(2, 3, 1.5)
		monsterModel.Shape = Enum.PartType.Block
		monsterModel.Material = Enum.Material.Neon
		monsterModel.Color = elementColors[monsterName] or Color3.fromRGB(150, 150, 150)
		monsterModel.CanCollide = false
		monsterModel.Anchored = true
		monsterModel.TopSurface = Enum.SurfaceType.Smooth
		monsterModel.BottomSurface = Enum.SurfaceType.Smooth
		monsterModel.Parent = MonsterModels

		-- Add glow effect
		local pointLight = Instance.new("PointLight")
		pointLight.Color = monsterModel.Color
		pointLight.Brightness = 0.8
		pointLight.Range = 8
		pointLight.Parent = monsterModel
	end

	print("? Created basic monster models for testing")
end

-- Function to get all monsters in a habitat
local function getMonstersInHabitat(habitat)
	local monsters = {}
	for _, child in pairs(habitat:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Monster" then
			table.insert(monsters, child)
		end
	end
	return monsters
end

-- Calculate circle zones for monsters
local function calculateMonsterZones(habitat)
	local monsters = getMonstersInHabitat(habitat)
	local monsterCount = #monsters

	if monsterCount == 0 then return {} end

	-- Get habitat center and size
	local habitatCF, habitatSize = habitat:GetBoundingBox()
	local habitatCenter = habitatCF.Position

	-- Calculate circle radius (monsters roam within zones)
	local mainRadius = math.max(habitatSize.X, habitatSize.Z) * 0.35
	local zoneRadius = mainRadius * 0.3 -- Each monster has a zone to roam in

	local zones = {}

	-- Calculate zone center for each monster
	for i, monster in ipairs(monsters) do
		local angle = ((i - 1) / monsterCount) * 360
		local radians = math.rad(angle)

		-- Calculate zone center position on circle
		local x = habitatCenter.X + math.cos(radians) * mainRadius
		local z = habitatCenter.Z + math.sin(radians) * mainRadius
		-- Match the monster creation height
		local y = habitatCenter.Y + habitatSize.Y/2 + 1

		zones[monster] = {
			center = Vector3.new(x, y, z),
			radius = zoneRadius
		}
	end

	return zones
end

-- ?? FIXED: Roaming animation within assigned circle zone (NO SPINNING)
local function startRoamingInZone(monster, habitat, zone)
	local isRoaming = true

	local function moveToRandomPositionInZone()
		-- Verify monster still exists
		if not monster or not monster.Parent or not isRoaming then
			return
		end

		-- Generate random position within monster's zone
		local angle = math.random() * math.pi * 2
		local distance = math.random() * zone.radius
		local targetX = zone.center.X + math.cos(angle) * distance
		local targetZ = zone.center.Z + math.sin(angle) * distance
		local targetY = zone.center.Y

		local targetPosition = Vector3.new(targetX, targetY, targetZ)

		-- Create movement tween (position only, no rotation)
		local moveTime = math.random(3, 6)
		local moveTween = TweenService:Create(
			monster,
			TweenInfo.new(moveTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Position = targetPosition}
		)

		moveTween:Play()

		-- When movement completes, wait then move again
		moveTween.Completed:Connect(function()
			task.wait(math.random(1, 3))

			-- Verify monster still exists and is in habitat
			if monster and monster.Parent == habitat and isRoaming then
				moveToRandomPositionInZone()
			end
		end)
	end

	-- Start roaming after a small delay
	task.wait(0.5)
	moveToRandomPositionInZone()

	-- Return function to stop roaming
	return function()
		isRoaming = false
	end
end

-- Update all monster zones when a new monster is added
local function updateAllMonsterZones(habitat)
	local zones = calculateMonsterZones(habitat)
	local monsterCount = 0

	for monster, zone in pairs(zones) do
		monsterCount = monsterCount + 1

		-- Move monster to their new zone center first
		local moveTween = TweenService:Create(
			monster,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = zone.center}
		)
		moveTween:Play()

		-- After moving to zone, start roaming within it
		moveTween.Completed:Once(function()
			task.wait(0.1)
			startRoamingInZone(monster, habitat, zone)
		end)
	end

	print("?? Updated zones for", monsterCount, "monsters in circle formation")
end

-- ?? FIXED: Function to create physical monster in habitat (NO FLYING)
local function createMonsterInHabitat(habitat, monsterData)
	-- Get monster model
	local monsterModel = MonsterModels:FindFirstChild(monsterData.name)
	if not monsterModel then
		warn("? Monster model not found:", monsterData.name)
		return nil
	end

	-- Clone the model
	local monster = monsterModel:Clone()
	monster.Name = "Monster"

	-- ?? FIX: Make sure it stays anchored and grounded!
	monster.Anchored = true
	monster.CanCollide = false

	-- Reset any physics properties
	monster.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	monster.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

	-- Initial position at habitat center (will be repositioned)
	local habitatCF, habitatSize = habitat:GetBoundingBox()
	-- Place monster ON TOP of habitat surface
	local initialY = habitatCF.Position.Y + habitatSize.Y/2 + 1
	monster.Position = Vector3.new(habitatCF.Position.X, initialY, habitatCF.Position.Z)

	-- ?? FIX: Reset rotation to prevent spinning
	monster.Orientation = Vector3.new(0, 0, 0)

	-- Add monster data as attributes
	monster:SetAttribute("MonsterName", monsterData.name)
	monster:SetAttribute("Element", monsterData.element)
	monster:SetAttribute("Rarity", monsterData.rarity)
	monster:SetAttribute("Level", monsterData.level)
	monster:SetAttribute("HP", monsterData.hp)
	monster:SetAttribute("Attack", monsterData.attack)
	monster:SetAttribute("Defense", monsterData.defense)
	monster:SetAttribute("Speed", monsterData.speed)

	-- Add name tag
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 100, 0, 50)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = monster

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = monsterData.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0.4, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.6, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = monsterData.rarity .. " � LVL " .. monsterData.level
	rarityLabel.TextColor3 = getRarityColor(monsterData.rarity)
	rarityLabel.TextSize = 10
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rarityLabel.Parent = gui

	monster.Parent = habitat

	print("? Created physical monster:", monsterData.name, "in habitat:", habitat.Name)
	return monster
end

-- Function to get rarity color
function getRarityColor(rarity)
	local rarityColors = {
		Common = Color3.fromRGB(158, 158, 158),
		Rare = Color3.fromRGB(33, 150, 243),
		Epic = Color3.fromRGB(156, 39, 176),
		Legendary = Color3.fromRGB(255, 193, 7)
	}
	return rarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

-- Function to calculate income for monster
local function calculateMonsterIncome(monsterData)
	local baseIncome = 5 -- base coins per minute
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

	return math.floor(baseIncome * rarityMult * elementMult * levelMult)
end

-- Function to start income generation
local function startIncomeGeneration(player, habitat, monsterData)
	local income = calculateMonsterIncome(monsterData)
	local incomeInterval = 60 -- seconds

	-- Get current income or initialize
	local currentIncome = habitat:GetAttribute("IncomeAmount") or 0
	habitat:SetAttribute("IncomeAmount", currentIncome + income)
	habitat:SetAttribute("IncomeInterval", incomeInterval)
	habitat:SetAttribute("LastIncome", tick())
	habitat:SetAttribute("HasMonster", true)

	print("?? Started income generation:", income, "coins/min for", monsterData.name)
end

-- Handle monster placement
placeMonsterInHabitatRemote.OnServerEvent:Connect(function(player, monsterId, habitatId, habitatData)
	print("?? Server: Processing monster placement from", player.Name)
	print("  MonsterID:", monsterId, "HabitatID:", habitatId)

	-- Find monster in player's inventory
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then
		warn("? No monsters folder found for player:", player.Name)
		return
	end

	local monsterFolder = monstersFolder:FindFirstChild(monsterId)
	if not monsterFolder then
		warn("? Monster not found in inventory:", monsterId)
		return
	end

	-- Extract monster data
	local monsterData = {
		name = (monsterFolder:FindFirstChild("Name") and monsterFolder:FindFirstChild("Name").Value) or 
			(monsterFolder:FindFirstChild("MonsterName") and monsterFolder:FindFirstChild("MonsterName").Value) or "Unknown",
		element = monsterFolder:FindFirstChild("Element") and monsterFolder:FindFirstChild("Element").Value or "Unknown",
		rarity = monsterFolder:FindFirstChild("Rarity") and monsterFolder:FindFirstChild("Rarity").Value or "Common",
		level = monsterFolder:FindFirstChild("Level") and monsterFolder:FindFirstChild("Level").Value or 1,
		hp = monsterFolder:FindFirstChild("HP") and monsterFolder:FindFirstChild("HP").Value or 0,
		attack = monsterFolder:FindFirstChild("Attack") and monsterFolder:FindFirstChild("Attack").Value or 0,
		defense = monsterFolder:FindFirstChild("Defense") and monsterFolder:FindFirstChild("Defense").Value or 0,
		speed = monsterFolder:FindFirstChild("Speed") and monsterFolder:FindFirstChild("Speed").Value or 0
	}

	print("  Monster data:", monsterData.name, monsterData.element, monsterData.rarity)

	-- Find habitat in player's plot
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

	-- Verify element compatibility
	local habitatElement = habitat:GetAttribute("Element") or habitatData.element
	if monsterData.element ~= habitatElement then
		warn("? Element mismatch:", monsterData.element, "vs", habitatElement)
		return
	end

	-- Count current monsters in habitat
	local currentMonsterCount = #getMonstersInHabitat(habitat)
	local maxCapacity = habitatData.maxCapacity or 2

	-- Check if habitat is at capacity
	if currentMonsterCount >= maxCapacity then
		warn("? Habitat is at maximum capacity:", currentMonsterCount .. "/" .. maxCapacity)
		return
	end

	-- Create physical monster
	local physicalMonster = createMonsterInHabitat(habitat, monsterData)
	if not physicalMonster then
		warn("? Failed to create physical monster")
		return
	end

	-- Update all monster zones with circle positioning
	task.wait(0.1) -- Small delay to ensure monster is fully created
	updateAllMonsterZones(habitat)

	-- Remove monster from inventory
	monsterFolder:Destroy()

	-- Start income generation
	startIncomeGeneration(player, habitat, monsterData)

	print("? Successfully placed", monsterData.name, "in", habitatElement, "habitat")
	print("  +- Total monsters:", #getMonstersInHabitat(habitat) .. "/" .. maxCapacity)
end)

-- Income generation loop (runs every minute)
task.spawn(function()
	while true do
		task.wait(60) -- Check every minute

		for _, player in pairs(Players:GetPlayers()) do
			local plotName = player:GetAttribute("AssignedPlot")
			if plotName then
				local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
				if plot then
					-- Check all habitats in plot
					for _, child in pairs(plot:GetChildren()) do
						if child:IsA("Model") and child:GetAttribute("HasMonster") then
							local incomeAmount = child:GetAttribute("IncomeAmount")
							if incomeAmount and incomeAmount > 0 then
								-- Give income to player
								-- ?? FIXED: Give income to player AND save to ProfileService
								GameDataManager:ModifyCoins(player, incomeAmount)
								print("?? Gave", incomeAmount, "coins to", player.Name, "from habitat income (SAVED)")
							end
						end
					end
				end
			end
		end
	end
end)

print("? Habitat Monster Placement Handler loaded with FIXED circle zone roaming!")

--[[
?? FIXES APPLIED:
? Monsters stay anchored (no flying)
? No rotation tweening (no spinning)
? Reset physics properties on spawn
? Proper Y-position calculation
? Circle zone positioning works smoothly

?? HABITAT MONSTER PLACEMENT:
? Removes monster from player inventory
? Creates physical monster model in habitat
? Smooth roaming within circle zones
? Shows monster name and rarity tags
? Automatic income generation
? Element compatibility validation
? Capacity checking (2 monsters per Level 1 habitat)

?? INCOME SYSTEM:
? Base 5 coins/minute with multipliers
? Rarity: Common(1x), Rare(2x), Epic(4x), Legendary(8x)
? Element: Earth(1.2x), Plant(1.1x), Electric(1.3x)
? Level scaling (10% bonus per level)
? Automatic income every 60 seconds
? Income accumulates for multiple monsters

?? READY FOR:
- Habitat upgrade system (increase capacity to 3-4 monsters)
- Monster removal/management
- Custom monster models
--]]
