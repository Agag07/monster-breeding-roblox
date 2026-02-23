-- MonsterRemovalHandler.lua (ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

-- Get/Create Remote Event
local removeMonsterFromHabitatRemote = ReplicatedStorage:FindFirstChild("RemoveMonsterFromHabitat")
if not removeMonsterFromHabitatRemote then
	removeMonsterFromHabitatRemote = Instance.new("RemoteEvent")
	removeMonsterFromHabitatRemote.Name = "RemoveMonsterFromHabitat"
	removeMonsterFromHabitatRemote.Parent = ReplicatedStorage
end

-- Function to find monster at specific slot index
local function findMonsterAtSlot(habitat, slotIndex)
	local monsters = {}

	-- Collect all monsters in habitat
	for _, child in pairs(habitat:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Monster" then
			table.insert(monsters, child)
		end
	end

	-- Return monster at requested slot (1-indexed)
	return monsters[slotIndex]
end

-- Function to reposition remaining monsters in circle
local function repositionMonstersInCircle(habitat)
	local monsters = {}
	for _, child in pairs(habitat:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Monster" then
			table.insert(monsters, child)
		end
	end

	local monsterCount = #monsters
	if monsterCount == 0 then return end

	-- Get habitat center
	local habitatCF, habitatSize = habitat:GetBoundingBox()
	local habitatCenter = habitatCF.Position

	-- Calculate circle radius
	local mainRadius = math.max(habitatSize.X, habitatSize.Z) * 0.35

	-- Reposition each monster
	for i, monster in ipairs(monsters) do
		local angle = ((i - 1) / monsterCount) * 360
		local radians = math.rad(angle)

		local x = habitatCenter.X + math.cos(radians) * mainRadius
		local z = habitatCenter.Z + math.sin(radians) * mainRadius
		local y = habitatCenter.Y + habitatSize.Y/2

		-- Smooth tween to new position
		local TweenService = game:GetService("TweenService")
		local tween = TweenService:Create(
			monster,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = Vector3.new(x, y, z)}
		)
		tween:Play()
	end

	print("?? Repositioned", monsterCount, "monsters in habitat")
end

-- Handle monster removal
removeMonsterFromHabitatRemote.OnServerEvent:Connect(function(player, habitatId, slotIndex)
	print("?? Remove request from", player.Name, "- Habitat:", habitatId, "Slot:", slotIndex)

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

	-- Verify ownership
	local owner = habitat:GetAttribute("Owner")
	if owner ~= player.UserId then
		warn("? Player doesn't own this habitat")
		return
	end

	-- Find monster at specified slot
	local monster = findMonsterAtSlot(habitat, slotIndex)
	if not monster then
		warn("? No monster found at slot:", slotIndex)
		return
	end

	-- Get monster data from attributes
	local monsterName = monster:GetAttribute("MonsterName") or "Unknown"
	local monsterElement = monster:GetAttribute("Element")
	local monsterRarity = monster:GetAttribute("Rarity") or "Common"
	local monsterLevel = monster:GetAttribute("Level") or 1
	local monsterHP = monster:GetAttribute("HP") or 100
	local monsterAttack = monster:GetAttribute("Attack") or 50
	local monsterDefense = monster:GetAttribute("Defense") or 50
	local monsterSpeed = monster:GetAttribute("Speed") or 50

	-- Return monster to player's inventory
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then
		monstersFolder = Instance.new("Folder")
		monstersFolder.Name = "Monsters"
		monstersFolder.Parent = player
	end

	-- Create monster data folder in inventory
	local monsterFolder = Instance.new("Folder")
	local monsterId = game:GetService("HttpService"):GenerateGUID(false)
	monsterFolder.Name = monsterId

	-- Store all monster data
	local nameValue = Instance.new("StringValue")
	nameValue.Name = "MonsterName"
	nameValue.Value = monsterName
	nameValue.Parent = monsterFolder

	local elementValue = Instance.new("StringValue")
	elementValue.Name = "Element"
	elementValue.Value = monsterElement
	elementValue.Parent = monsterFolder

	local rarityValue = Instance.new("StringValue")
	rarityValue.Name = "Rarity"
	rarityValue.Value = monsterRarity
	rarityValue.Parent = monsterFolder

	local levelValue = Instance.new("IntValue")
	levelValue.Name = "Level"
	levelValue.Value = monsterLevel
	levelValue.Parent = monsterFolder

	local hpValue = Instance.new("IntValue")
	hpValue.Name = "HP"
	hpValue.Value = monsterHP
	hpValue.Parent = monsterFolder

	local attackValue = Instance.new("IntValue")
	attackValue.Name = "Attack"
	attackValue.Value = monsterAttack
	attackValue.Parent = monsterFolder

	local defenseValue = Instance.new("IntValue")
	defenseValue.Name = "Defense"
	defenseValue.Value = monsterDefense
	defenseValue.Parent = monsterFolder

	local speedValue = Instance.new("IntValue")
	speedValue.Name = "Speed"
	speedValue.Value = monsterSpeed
	speedValue.Parent = monsterFolder

	monsterFolder.Parent = monstersFolder

	-- Remove physical monster from habitat
	monster:Destroy()

	-- Reposition remaining monsters
	task.wait(0.1)
	repositionMonstersInCircle(habitat)

	-- Update habitat income (recalculate with fewer monsters)
	local currentIncome = habitat:GetAttribute("IncomeAmount") or 0
	-- Calculate this monster's contribution (simplified)
	local baseIncome = 5
	local rarityMults = {Common = 1, Rare = 2, Epic = 4, Legendary = 8}
	local elementMults = {Fire = 1, Water = 1, Earth = 1.2, Plant = 1.1, Electric = 1.3}
	local monsterIncome = math.floor(baseIncome * (rarityMults[monsterRarity] or 1) * (elementMults[monsterElement] or 1) * (monsterLevel * 0.1 + 1))

	habitat:SetAttribute("IncomeAmount", math.max(0, currentIncome - monsterIncome))

	print("? Monster removed:", monsterName, "from habitat:", habitatId)
	print("  +- Returned to", player.Name .. "'s inventory")
end)

print("? MonsterRemovalHandler loaded!")
