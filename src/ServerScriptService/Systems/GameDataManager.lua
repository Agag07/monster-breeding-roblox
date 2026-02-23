-- ServerScriptService/Systems/GameDataManager.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProfileService = require(game.ServerScriptService.ProfileService)

-- Data Template (everything that saves)
local DATA_TEMPLATE = {
	-- Economy
	Coins = 1000,
	Gems = 0,

	-- ?? NEW: Breeding Machine Unlock Status
	BreedingMachines = {
		[1] = {unlocked = false}, -- Tier 1 - Basic (500 coins, 0 monsters)
		[2] = {unlocked = false}, -- Tier 2 - Advanced (1500 coins, 10 monsters)
		[3] = {unlocked = false}, -- Tier 3 - Master (3000 coins, 25 monsters)
	},

	-- Inventory with better structure
	Inventory = {
		Eggs = {}, -- {[eggId] = {type = "Basic", hatchTime = 30, rarity = "Common", monsterName, elements, ivs}}
		Incubators = {}, -- {[incubatorId] = {type = "Normal", speed = 1.0, placed = false}}
		Habitats = {}, -- {[habitatId] = {element = "Fire", placed = false}}
		Buildings = {}, -- {[buildingId] = {type = "BreedingMachine", tier = 1, placed = false}}
	},

	-- Monster Storage (unlimited but with display limit)
	Monsters = {}, -- {[monsterId] = {name, element, rarity, stats, obtainedTime, IVs}}
	BattleTeam = {nil, nil, nil}, -- 3 monster IDs for PvP

	-- Plot Data
	PlotData = {
		PlacedObjects = {}, -- {{type = "Habitat", id = "xxx", position = {x,y,z}, rotation = 0}}
		LastPassiveCollection = os.time(), -- For offline income
	},

	-- Active Incubations (persist through disconnects)
	ActiveIncubations = {}, -- {[incubatorId] = {eggId, startTime, hatchTime}}

	-- Statistics
	Stats = {
		Level = 1,
		Experience = 0,
		MonstersCollected = 0,
		EggsHatched = 0,
		TotalPlayTime = 0,
		LastSaveTime = os.time()
	}
}

-- ProfileStore
local ProfileStore = ProfileService.GetProfileStore("MonsterGame_v1", DATA_TEMPLATE)
local Profiles = {}
local GameDataManager = {}

-- OFFLINE PROGRESS CALCULATION
local function CalculateOfflineProgress(profile)
	local currentTime = os.time()
	local lastSave = profile.Data.Stats.LastSaveTime
	local offlineTime = currentTime - lastSave

	-- Cap offline time to 24 hours to prevent exploitation
	offlineTime = math.min(offlineTime, 86400)

	-- Update incubation timers
	for incubatorId, incubationData in pairs(profile.Data.ActiveIncubations) do
		local timeElapsed = currentTime - incubationData.startTime
		if timeElapsed >= incubationData.hatchTime then
			incubationData.ready = true
		end
	end

	-- Calculate passive income from habitats
	local passiveIncome = 0
	local INCOME_PER_HABITAT_PER_HOUR = 100

	for _, placedObject in pairs(profile.Data.PlotData.PlacedObjects) do
		if placedObject.type == "Habitat" and placedObject.hasMonster then
			passiveIncome = passiveIncome + (offlineTime / 3600) * INCOME_PER_HABITAT_PER_HOUR
		end
	end

	if passiveIncome > 0 then
		profile.Data.Coins = profile.Data.Coins + math.floor(passiveIncome)
		return math.floor(passiveIncome), offlineTime
	end

	return 0, offlineTime
end

-- CREATE COMPATIBILITY FOLDERS
local function CreatePlayerFolders(player)
	-- Leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	-- Inventory folders for compatibility
	for _, folderName in ipairs({"Eggs", "Habitats", "Incubators", "Monsters"}) do
		local folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = player
	end
end

-- SYNC DATA TO FOLDERS (for compatibility with existing scripts)
local function SyncDataToFolders(player, profileData)
	-- Update coins
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Coins") then
		leaderstats.Coins.Value = profileData.Coins
	end

	-- Sync Eggs (WITH HYBRID EGG SUPPORT)
	local eggsFolder = player:FindFirstChild("Eggs")
	if eggsFolder then
		eggsFolder:ClearAllChildren()
		for eggId, eggData in pairs(profileData.Inventory.Eggs) do
			local eggFolder = Instance.new("Folder")
			eggFolder.Name = eggId

			local typeValue = Instance.new("StringValue")
			typeValue.Name = "EggType"
			typeValue.Value = eggData.type
			typeValue.Parent = eggFolder

			local hatchValue = Instance.new("IntValue")
			hatchValue.Name = "HatchTime"
			hatchValue.Value = eggData.hatchTime
			hatchValue.Parent = eggFolder

			local rarityValue = Instance.new("StringValue")
			rarityValue.Name = "Rarity"
			rarityValue.Value = eggData.rarity
			rarityValue.Parent = eggFolder

			-- Add hybrid egg specific data
			if eggData.type == "HybridEgg" then
				-- Monster name
				if eggData.monsterName then
					local monsterNameValue = Instance.new("StringValue")
					monsterNameValue.Name = "MonsterName"
					monsterNameValue.Value = eggData.monsterName
					monsterNameValue.Parent = eggFolder
				end

				-- Elements
				if eggData.elements then
					local elementsValue = Instance.new("StringValue")
					elementsValue.Name = "Elements"
					elementsValue.Value = eggData.elements
					elementsValue.Parent = eggFolder
				end

				-- Parent names
				if eggData.parent1 then
					local parent1Value = Instance.new("StringValue")
					parent1Value.Name = "Parent1"
					parent1Value.Value = eggData.parent1
					parent1Value.Parent = eggFolder
				end

				if eggData.parent2 then
					local parent2Value = Instance.new("StringValue")
					parent2Value.Name = "Parent2"
					parent2Value.Value = eggData.parent2
					parent2Value.Parent = eggFolder
				end

				-- IVs folder
				if eggData.ivs then
					local ivsFolder = Instance.new("Folder")
					ivsFolder.Name = "IVs"
					ivsFolder.Parent = eggFolder

					for ivName, ivValue in pairs(eggData.ivs) do
						local iv = Instance.new("IntValue")
						iv.Name = ivName
						iv.Value = ivValue
						iv.Parent = ivsFolder
					end
				end
			end

			eggFolder.Parent = eggsFolder
		end
	end

	-- Sync Habitats
	local habitatsFolder = player:FindFirstChild("Habitats")
	if habitatsFolder then
		habitatsFolder:ClearAllChildren()
		for habitatId, habitatData in pairs(profileData.Inventory.Habitats) do
			if not habitatData.placed then
				local habitatValue = Instance.new("StringValue")
				habitatValue.Name = habitatId
				habitatValue.Value = habitatData.element
				habitatValue.Parent = habitatsFolder
			end
		end
	end

	-- Sync Incubators
	local incubatorsFolder = player:FindFirstChild("Incubators")
	if incubatorsFolder then
		incubatorsFolder:ClearAllChildren()
		for incubatorId, incubatorData in pairs(profileData.Inventory.Incubators) do
			if not incubatorData.placed then
				local incubatorValue = Instance.new("StringValue")
				incubatorValue.Name = incubatorId
				incubatorValue.Value = incubatorData.type

				local speedValue = Instance.new("NumberValue")
				speedValue.Name = "Speed"
				speedValue.Value = incubatorData.speed
				speedValue.Parent = incubatorValue

				incubatorValue.Parent = incubatorsFolder
			end
		end
	end

	-- Sync Monsters (WITH IV SUPPORT)
	local monstersFolder = player:FindFirstChild("Monsters")
	if monstersFolder then
		monstersFolder:ClearAllChildren()
		for monsterId, monsterData in pairs(profileData.Monsters) do
			local monsterFolder = Instance.new("Folder")
			monsterFolder.Name = monsterId

			-- Store all monster data as values
			for key, value in pairs(monsterData) do
				if type(value) == "string" then
					local stringValue = Instance.new("StringValue")
					stringValue.Name = key
					stringValue.Value = value
					stringValue.Parent = monsterFolder
				elseif type(value) == "number" then
					local numberValue = Instance.new("NumberValue")
					numberValue.Name = key
					numberValue.Value = value
					numberValue.Parent = monsterFolder
				end
			end

			-- Special handling for Monster Name (compatibility)
			if monsterData.Name and not monsterFolder:FindFirstChild("MonsterName") then
				local nameValue = Instance.new("StringValue")
				nameValue.Name = "MonsterName"
				nameValue.Value = monsterData.Name
				nameValue.Parent = monsterFolder
			end

			monsterFolder.Parent = monstersFolder
		end
	end
end

-- RESTORE PLOT PLACEMENTS (COMPLETE FUNCTION)
-- REPLACE THE ENTIRE RestorePlotPlacements FUNCTION (lines 258-340) WITH THIS:

function GameDataManager:RestorePlotPlacements(player)
	local profile = Profiles[player]
	if not profile then return end

	-- ?? FIXED: Wrap in pcall to catch restoration errors
	local success, err = pcall(function()
		local plotName = player:GetAttribute("AssignedPlot")
		if not plotName then return end

		local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
		if not plot then return end

		-- Get model folders
		local HabitatModels = ReplicatedStorage:WaitForChild("HabitatModels")
		local IncubatorModels = ReplicatedStorage:FindFirstChild("IncubatorModels")

		-- Restore each placed object
		for _, objectData in pairs(profile.Data.PlotData.PlacedObjects) do
			if objectData.type == "Habitat" then
				-- Find the habitat data
				local habitatData = profile.Data.Inventory.Habitats[objectData.id]
				if habitatData and habitatData.placed then
					-- Get the model
					local modelName = "Habitat" .. habitatData.element
					local baseModel = HabitatModels:FindFirstChild(modelName)
					if baseModel then
						local model = baseModel:Clone()
						model.Name = objectData.id
						model:PivotTo(
							CFrame.new(objectData.position.x, objectData.position.y, objectData.position.z) 
								* CFrame.Angles(0, math.rad(objectData.rotation), 0)
						)
						model.Parent = plot
						print("? Restored habitat:", habitatData.element, "at position", objectData.position)
					end
				end

			elseif objectData.type == "Incubator" then
				local incubatorData = profile.Data.Inventory.Incubators[objectData.id]
				if incubatorData and incubatorData.placed then
					local baseModel = nil

					-- Try to find proper incubator model
					if IncubatorModels then
						baseModel = IncubatorModels:FindFirstChild(incubatorData.type)
					end

					-- Fallback to habitat model
					if not baseModel then
						baseModel = HabitatModels:FindFirstChild("HabitatFire")
					end

					if baseModel then
						local model = baseModel:Clone()
						model.Name = objectData.id

						-- Color based on type
						for _, part in pairs(model:GetDescendants()) do
							if part:IsA("BasePart") then
								if incubatorData.type == "NormalIncubator" then
									part.Color = Color3.fromRGB(255, 255, 100)
								elseif incubatorData.type == "SuperIncubator" then
									part.Color = Color3.fromRGB(100, 255, 255)
								elseif incubatorData.type == "UltraIncubator" then
									part.Color = Color3.fromRGB(255, 100, 255)
								end
							end
						end

						-- Set attributes
						model:SetAttribute("Type", "Incubator")
						model:SetAttribute("IncubatorType", incubatorData.type)
						model:SetAttribute("Speed", incubatorData.speed or 1.0)

						model:PivotTo(
							CFrame.new(objectData.position.x, objectData.position.y, objectData.position.z) 
								* CFrame.Angles(0, math.rad(objectData.rotation), 0)
						)
						model.Parent = plot
						print("? Restored incubator:", incubatorData.type, "at position", objectData.position)
					end
				end
			end
		end
	end)

	if not success then
		warn("?? Error restoring plot placements:", err)
		warn("   Type /wipe to clear old placement data")
	end
end
-- PLAYER JOINED
function GameDataManager:PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync(
		"Player_" .. player.UserId,
		"ForceLoad"
	)

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Profile loaded on another server")
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile

			-- Developer bonus
			if player.UserId == 167972042 then
				profile.Data.Coins = 99999
			end

			-- Calculate offline progress
			local passiveIncome, offlineTime = CalculateOfflineProgress(profile)
			if passiveIncome > 0 then
				print(player.Name .. " earned " .. passiveIncome .. " coins while offline (" .. offlineTime .. "s)")
			end

			-- Create folders and sync
			CreatePlayerFolders(player)
			SyncDataToFolders(player, profile.Data)

			-- Restore plot placements
			task.wait(2) -- Wait for plot assignment
			self:RestorePlotPlacements(player)

			print("? Profile loaded:", player.Name)
		else
			profile:Release()
		end
	else
		player:Kick("Failed to load data")
	end
end

-- PLAYER LEAVING
function GameDataManager:PlayerRemoving(player)
	local profile = Profiles[player]
	if profile then
		profile.Data.Stats.LastSaveTime = os.time()
		profile:Release()
	end
end

-- PUBLIC API FUNCTIONS
function GameDataManager:GetProfile(player)
	return Profiles[player]
end

function GameDataManager:GetData(player)
	local profile = Profiles[player]
	return profile and profile.Data
end

function GameDataManager:ModifyCoins(player, amount)
	local profile = Profiles[player]
	if not profile then return false end

	profile.Data.Coins = math.max(0, profile.Data.Coins + amount)

	-- Update visual
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Coins") then
		leaderstats.Coins.Value = profile.Data.Coins
	end

	return true
end

function GameDataManager:PurchaseItem(player, itemType, itemData, price)
	local profile = Profiles[player]
	if not profile then return false, "No profile" end

	if profile.Data.Coins < price then
		return false, "Insufficient coins"
	end

	-- Deduct coins
	self:ModifyCoins(player, -price)

	local itemId = game:GetService("HttpService"):GenerateGUID(false)

	-- Add to inventory based on type
	if itemType == "Egg" then
		profile.Data.Inventory.Eggs[itemId] = itemData
	elseif itemType == "Incubator" then
		profile.Data.Inventory.Incubators[itemId] = itemData
	elseif itemType == "Habitat" then
		profile.Data.Inventory.Habitats[itemId] = itemData
	end

	-- Sync to folders
	SyncDataToFolders(player, profile.Data)

	return true, itemId
end

function GameDataManager:AddMonster(player, monsterData)
	local profile = Profiles[player]
	if not profile then return false end

	local monsterId = game:GetService("HttpService"):GenerateGUID(false)
	monsterData.obtainedTime = os.time()

	profile.Data.Monsters[monsterId] = monsterData
	profile.Data.Stats.MonstersCollected = profile.Data.Stats.MonstersCollected + 1

	-- Sync
	SyncDataToFolders(player, profile.Data)

	return true, monsterId
end

function GameDataManager:StartIncubation(player, incubatorId, eggId, hatchTime)
	local profile = Profiles[player]
	if not profile then return false end

	profile.Data.ActiveIncubations[incubatorId] = {
		eggId = eggId,
		startTime = os.time(),
		hatchTime = hatchTime,
		ready = false
	}

	-- Remove egg from inventory
	profile.Data.Inventory.Eggs[eggId] = nil

	-- Sync
	SyncDataToFolders(player, profile.Data)

	return true
end

function GameDataManager:SavePlotPlacement(player, objectType, objectId, position, rotation)
	local profile = Profiles[player]
	if not profile then return false end

	table.insert(profile.Data.PlotData.PlacedObjects, {
		type = objectType,
		id = objectId,
		position = {x = position.X, y = position.Y, z = position.Z},
		rotation = rotation,
		hasMonster = false
	})

	-- Mark item as placed
	if objectType == "Habitat" then
		if profile.Data.Inventory.Habitats[objectId] then
			profile.Data.Inventory.Habitats[objectId].placed = true
		end
	elseif objectType == "Incubator" then
		if profile.Data.Inventory.Incubators[objectId] then
			profile.Data.Inventory.Incubators[objectId].placed = true
		end
	end

	return true
end

function GameDataManager:RemovePlotPlacement(player, objectId)
	local profile = Profiles[player]
	if not profile then return false end

	-- Find and remove from placed objects
	local placedObjects = profile.Data.PlotData.PlacedObjects
	for i = #placedObjects, 1, -1 do
		if placedObjects[i].id == objectId then
			local objectType = placedObjects[i].type
			table.remove(placedObjects, i)

			-- Mark item as not placed
			if objectType == "Habitat" then
				if profile.Data.Inventory.Habitats[objectId] then
					profile.Data.Inventory.Habitats[objectId].placed = false
				end
			elseif objectType == "Incubator" then
				if profile.Data.Inventory.Incubators[objectId] then
					profile.Data.Inventory.Incubators[objectId].placed = false
				end
			end

			-- Sync to folders
			SyncDataToFolders(player, profile.Data)
			return true
		end
	end

	return false
end

function GameDataManager:SyncDataToFolders(player, profileData)
	SyncDataToFolders(player, profileData)
end

-- Initialize
Players.PlayerAdded:Connect(function(player)
	GameDataManager:PlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	GameDataManager:PlayerRemoving(player)
end)

return GameDataManager

--[[
?? WHAT CHANGED:
Lines 13-17: Added BreedingMachines table to DATA_TEMPLATE
- Stores unlock status for all 3 breeding machine tiers
- Each tier has {unlocked = false} by default
- ProfileService will auto-reconcile this for existing players

THAT'S IT! Only 5 lines added to your existing script.
--]]
