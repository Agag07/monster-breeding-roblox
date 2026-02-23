-- BreedingHandler.lua (ServerScriptService/Systems)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

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

local breedingCompleteRemote = ReplicatedStorage:FindFirstChild("BreedingComplete")
if not breedingCompleteRemote then
	breedingCompleteRemote = Instance.new("RemoteEvent")
	breedingCompleteRemote.Name = "BreedingComplete"
	breedingCompleteRemote.Parent = ReplicatedStorage
end

-- Active breedings tracking
local activeBreedings = {}

-- Breeding costs
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

-- Base breeding times (in seconds)
local BASE_BREEDING_TIME = 10 -- 10 SECONDS FOR TESTING (was 120)
local RARITY_TIME_BONUS = {
	Common = 0,
	Rare = 0,  -- Changed from 15
	Epic = 0,  -- Changed from 30
	Legendary = 0  -- Changed from 45
}

-- Hybrid combinations
local HYBRID_COMBINATIONS = {
	["Fire,Water"] = {name = "Vaporix", elements = "Fire,Water"},
	["Fire,Earth"] = {name = "Magmor", elements = "Fire,Earth"},
	["Fire,Plant"] = {name = "Blazebloom", elements = "Fire,Plant"},
	["Fire,Electric"] = {name = "Voltflare", elements = "Fire,Electric"},
	["Water,Earth"] = {name = "Sludgy", elements = "Water,Earth"},
	["Water,Plant"] = {name = "Hydravine", elements = "Water,Plant"},
	["Water,Electric"] = {name = "Thundersplash", elements = "Water,Electric"},
	["Earth,Plant"] = {name = "Terravine", elements = "Earth,Plant"},
	["Earth,Electric"] = {name = "Tarick", elements = "Earth,Electric"},
	["Plant,Electric"] = {name = "Wattsprout", elements = "Plant,Electric"}
}

-- Rarity inheritance chances
local RARITY_INHERITANCE = {
	["Common,Common"] = {Common = 80, Rare = 20, Epic = 0, Legendary = 0},
	["Common,Rare"] = {Common = 50, Rare = 40, Epic = 10, Legendary = 0},
	["Rare,Rare"] = {Common = 30, Rare = 50, Epic = 20, Legendary = 0},
	["Rare,Epic"] = {Common = 0, Rare = 20, Epic = 60, Legendary = 20},
	["Epic,Epic"] = {Common = 0, Rare = 10, Epic = 60, Legendary = 30},
	["Common,Epic"] = {Common = 20, Rare = 40, Epic = 35, Legendary = 5},
	["Common,Legendary"] = {Common = 20, Rare = 30, Epic = 30, Legendary = 20},
	["Rare,Legendary"] = {Common = 0, Rare = 20, Epic = 50, Legendary = 30},
	["Epic,Legendary"] = {Common = 0, Rare = 0, Epic = 50, Legendary = 50},
	["Legendary,Legendary"] = {Common = 0, Rare = 0, Epic = 20, Legendary = 80}
}

-- ?? CRITICAL FIX: Helper function to get the part from machine (works with both Parts and Models)
local function getMachinePart(machine)
	if machine:IsA("BasePart") then
		-- It's already a part
		return machine
	elseif machine:IsA("Model") then
		-- It's a model, find the primary part or first BasePart
		return machine.PrimaryPart or machine:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

-- Function to calculate breeding cost
local function getBreedingCost(rarity1, rarity2)
	local rarities = {rarity1, rarity2}
	table.sort(rarities)
	local costKey = table.concat(rarities, ",")
	return BREEDING_COSTS[costKey] or 500
end

-- Function to calculate breeding time
local function getBreedingTime(rarity1, rarity2)
	local time1 = RARITY_TIME_BONUS[rarity1] or 0
	local time2 = RARITY_TIME_BONUS[rarity2] or 0
	return BASE_BREEDING_TIME + time1 + time2
end

-- Function to determine offspring rarity
local function determineOffspringRarity(parent1Rarity, parent2Rarity)
	local rarities = {parent1Rarity, parent2Rarity}
	table.sort(rarities)
	local inheritanceKey = table.concat(rarities, ",")

	local chances = RARITY_INHERITANCE[inheritanceKey]
	if not chances then
		-- Default fallback
		return "Common"
	end

	-- Calculate rarity based on chances
	local roll = math.random(1, 100)
	local cumulative = 0

	for rarity, chance in pairs(chances) do
		cumulative = cumulative + chance
		if roll <= cumulative then
			return rarity
		end
	end

	return "Common" -- Fallback
end

-- Function to inherit IVs from parents
local function inheritIVs(parent1Stats, parent2Stats)
	local newIVs = {}

	-- For each stat, 50% chance to inherit from either parent
	local stats = {"HP", "Attack", "Defense", "Speed"}

	for _, stat in ipairs(stats) do
		local parent1IV = parent1Stats[stat .. "IV"] or math.random(0, 31)
		local parent2IV = parent2Stats[stat .. "IV"] or math.random(0, 31)

		-- 50% chance to inherit from each parent
		local inheritedIV = math.random() < 0.5 and parent1IV or parent2IV

		-- Add small variation (-3 to +3)
		local variation = math.random(-3, 3)
		newIVs[stat .. "IV"] = math.clamp(inheritedIV + variation, 0, 31)
	end

	return newIVs
end

-- Function to determine breeding result
local function determineBreedingResult(parent1Data, parent2Data)
	-- Extract elements
	local parent1Elements = string.split(parent1Data.Element, ",")
	local parent2Elements = string.split(parent2Data.Element, ",")

	-- Clean up element names
	for i, element in ipairs(parent1Elements) do
		parent1Elements[i] = element:gsub("%s+", "")
	end
	for i, element in ipairs(parent2Elements) do
		parent2Elements[i] = element:gsub("%s+", "")
	end

	-- Check for hybrid combinations
	local resultMonster = nil
	local resultElements = nil

	-- Try all element combinations
	for _, elem1 in ipairs(parent1Elements) do
		for _, elem2 in ipairs(parent2Elements) do
			local combo1 = elem1 .. "," .. elem2
			local combo2 = elem2 .. "," .. elem1

			if HYBRID_COMBINATIONS[combo1] then
				resultMonster = HYBRID_COMBINATIONS[combo1].name
				resultElements = HYBRID_COMBINATIONS[combo1].elements
				break
			elseif HYBRID_COMBINATIONS[combo2] then
				resultMonster = HYBRID_COMBINATIONS[combo2].name
				resultElements = HYBRID_COMBINATIONS[combo2].elements
				break
			end
		end
		if resultMonster then break end
	end

	-- If no hybrid found, 50% chance for either parent
	if not resultMonster then
		if math.random() < 0.5 then
			resultMonster = parent1Data.MonsterName
			resultElements = parent1Data.Element
		else
			resultMonster = parent2Data.MonsterName
			resultElements = parent2Data.Element
		end
	end

	return resultMonster, resultElements
end

-- Function to create breeding egg
local function createBreedingEgg(player, parent1Id, parent2Id, breedingMachineId)
	-- Get parent data
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then return nil end

	local parent1Folder = monstersFolder:FindFirstChild(parent1Id)
	local parent2Folder = monstersFolder:FindFirstChild(parent2Id)

	if not parent1Folder or not parent2Folder then
		warn("? Parent monsters not found")
		return nil
	end

	-- Extract parent data
	local parent1Data = {
		MonsterName = parent1Folder:FindFirstChild("MonsterName") and parent1Folder.MonsterName.Value or "Unknown",
		Element = parent1Folder:FindFirstChild("Element") and parent1Folder.Element.Value or "Fire",
		Rarity = parent1Folder:FindFirstChild("Rarity") and parent1Folder.Rarity.Value or "Common",
		Level = parent1Folder:FindFirstChild("Level") and parent1Folder.Level.Value or 1,
		HP = parent1Folder:FindFirstChild("HP") and parent1Folder.HP.Value or 100,
		Attack = parent1Folder:FindFirstChild("Attack") and parent1Folder.Attack.Value or 50,
		Defense = parent1Folder:FindFirstChild("Defense") and parent1Folder.Defense.Value or 50,
		Speed = parent1Folder:FindFirstChild("Speed") and parent1Folder.Speed.Value or 50,
		HPIV = parent1Folder:FindFirstChild("HPIV") and parent1Folder.HPIV.Value or math.random(0, 31),
		AttackIV = parent1Folder:FindFirstChild("AttackIV") and parent1Folder.AttackIV.Value or math.random(0, 31),
		DefenseIV = parent1Folder:FindFirstChild("DefenseIV") and parent1Folder.DefenseIV.Value or math.random(0, 31),
		SpeedIV = parent1Folder:FindFirstChild("SpeedIV") and parent1Folder.SpeedIV.Value or math.random(0, 31)
	}

	local parent2Data = {
		MonsterName = parent2Folder:FindFirstChild("MonsterName") and parent2Folder.MonsterName.Value or "Unknown",
		Element = parent2Folder:FindFirstChild("Element") and parent2Folder.Element.Value or "Fire",
		Rarity = parent2Folder:FindFirstChild("Rarity") and parent2Folder.Rarity.Value or "Common",
		Level = parent2Folder:FindFirstChild("Level") and parent2Folder.Level.Value or 1,
		HP = parent2Folder:FindFirstChild("HP") and parent2Folder.HP.Value or 100,
		Attack = parent2Folder:FindFirstChild("Attack") and parent2Folder.Attack.Value or 50,
		Defense = parent2Folder:FindFirstChild("Defense") and parent2Folder.Defense.Value or 50,
		Speed = parent2Folder:FindFirstChild("Speed") and parent2Folder.Speed.Value or 50,
		HPIV = parent2Folder:FindFirstChild("HPIV") and parent2Folder.HPIV.Value or math.random(0, 31),
		AttackIV = parent2Folder:FindFirstChild("AttackIV") and parent2Folder.AttackIV.Value or math.random(0, 31),
		DefenseIV = parent2Folder:FindFirstChild("DefenseIV") and parent2Folder.DefenseIV.Value or math.random(0, 31),
		SpeedIV = parent2Folder:FindFirstChild("SpeedIV") and parent2Folder.SpeedIV.Value or math.random(0, 31)
	}

	-- Determine offspring
	local offspringName, offspringElements = determineBreedingResult(parent1Data, parent2Data)
	local offspringRarity = determineOffspringRarity(parent1Data.Rarity, parent2Data.Rarity)
	local offspringIVs = inheritIVs(parent1Data, parent2Data)

	-- Create hybrid egg data
	local hybridEggData = {
		type = "HybridEgg",
		hatchTime = 45, -- 45 seconds for bred eggs
		rarity = offspringRarity,
		monsterName = offspringName,
		elements = offspringElements,
		ivs = offspringIVs,
		parent1 = parent1Data.MonsterName,
		parent2 = parent2Data.MonsterName
	}

	return hybridEggData
end

-- Handle breeding start
startBreedingRemote.OnServerEvent:Connect(function(player, breedingMachineId, parent1Id, parent2Id)
	-- Validate breeding machine
	local plotName = player:GetAttribute("AssignedPlot")
	local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
	if not plot then return end

	local breedingMachine = plot:FindFirstChild(breedingMachineId)
	if not breedingMachine or breedingMachine:GetAttribute("Type") ~= "BreedingMachine" then
		warn("? Invalid breeding machine:", breedingMachineId)
		return
	end

	-- Check if machine is already breeding
	if breedingMachine:GetAttribute("BreedingStartTime") then
		warn("?? Breeding machine already in use")
		return
	end

	-- Get parent monsters data
	local monstersFolder = player:FindFirstChild("Monsters")
	if not monstersFolder then return end

	local parent1 = monstersFolder:FindFirstChild(parent1Id)
	local parent2 = monstersFolder:FindFirstChild(parent2Id)

	if not parent1 or not parent2 then
		warn("? Parent monsters not found")
		return
	end

	-- Get rarities for cost calculation
	local rarity1 = parent1:FindFirstChild("Rarity") and parent1.Rarity.Value or "Common"
	local rarity2 = parent2:FindFirstChild("Rarity") and parent2.Rarity.Value or "Common"

	-- Calculate and deduct cost
	local cost = getBreedingCost(rarity1, rarity2)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	if not coins or coins.Value < cost then
		warn("?? Not enough coins for breeding")
		return
	end

	-- Deduct cost
	GameDataManager:ModifyCoins(player, -cost)

	-- Calculate breeding time
	local breedingTime = getBreedingTime(rarity1, rarity2)

	-- Set breeding machine attributes
	breedingMachine:SetAttribute("BreedingStartTime", tick())
	breedingMachine:SetAttribute("BreedingDuration", breedingTime)
	breedingMachine:SetAttribute("Parent1Id", parent1Id)
	breedingMachine:SetAttribute("Parent2Id", parent2Id)

	-- Create egg data for when breeding completes
	local eggData = createBreedingEgg(player, parent1Id, parent2Id, breedingMachineId)

	-- Track active breeding
	activeBreedings[breedingMachineId] = {
		player = player,
		machine = breedingMachine,
		startTime = tick(),
		duration = breedingTime,
		eggData = eggData
	}

	-- ?? FIXED: Add visual effects using helper function
	local machinePart = getMachinePart(breedingMachine)
	if machinePart then
		-- Add particles or glow effect
		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(255, 150, 255)
		pointLight.Brightness = 2
		pointLight.Range = 15
		pointLight.Name = "BreedingLight"
		pointLight.Parent = machinePart

		-- Add breeding particles
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 150, 255))
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Rate = 50
		particles.Speed = NumberRange.new(2)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Name = "BreedingParticles"
		particles.Parent = machinePart
	else
		warn("?? Could not get part from breeding machine for visual effects")
	end

	print("?? Breeding started:", parent1.MonsterName.Value, "+", parent2.MonsterName.Value)
	print("?? Breeding duration:", breedingTime, "seconds")
end)

-- Handle breeding collection
collectBreedingEggRemote.OnServerEvent:Connect(function(player, breedingMachineId)
	local breedingData = activeBreedings[breedingMachineId]
	if not breedingData or breedingData.player ~= player then
		warn("? No breeding data found for collection")
		return
	end

	-- Check if breeding is complete
	local elapsed = tick() - breedingData.startTime
	if elapsed < breedingData.duration then
		warn("?? Breeding not complete yet:", breedingData.duration - elapsed, "seconds remaining")
		return
	end

	-- Add egg to player's inventory
	local success, eggId = GameDataManager:PurchaseItem(
		player,
		"Egg",
		breedingData.eggData,
		0 -- No cost, already paid during breeding
	)

	if success then
		print("?? Hybrid egg created:", breedingData.eggData.monsterName, "Rarity:", breedingData.eggData.rarity)

		-- Clean up breeding machine
		local machine = breedingData.machine
		machine:SetAttribute("BreedingStartTime", nil)
		machine:SetAttribute("BreedingDuration", nil)
		machine:SetAttribute("Parent1Id", nil)
		machine:SetAttribute("Parent2Id", nil)
		machine:SetAttribute("BreedingReady", nil)

		-- ?? FIXED: Remove visual effects using helper function
		local machinePart = getMachinePart(machine)
		if machinePart then
			local light = machinePart:FindFirstChild("BreedingLight")
			local particles = machinePart:FindFirstChild("BreedingParticles")
			local prompt = machinePart:FindFirstChildOfClass("ProximityPrompt")
			if light then light:Destroy() end
			if particles then particles:Destroy() end
			if prompt then prompt:Destroy() end
		end

		-- Notify client
		breedingCompleteRemote:FireClient(player, true, breedingData.eggData)

		-- Remove from active breedings
		activeBreedings[breedingMachineId] = nil
	else
		warn("? Failed to create hybrid egg")
	end
end)

-- Breeding timer loop
RunService.Heartbeat:Connect(function()
	local currentTime = tick()

	for machineId, breedingData in pairs(activeBreedings) do
		local elapsed = currentTime - breedingData.startTime
		local remaining = breedingData.duration - elapsed

		-- Update machine display
		if breedingData.machine and breedingData.machine.Parent then
			breedingData.machine:SetAttribute("RemainingTime", math.max(0, remaining))

			-- Check if ready for collection
			if elapsed >= breedingData.duration and not breedingData.machine:GetAttribute("BreedingReady") then
				breedingData.machine:SetAttribute("BreedingReady", true)

				print("? BREEDING TIMER COMPLETE - Starting egg collection setup")

				-- ?? FIXED: Add collection prompt using helper function
				local machinePart = getMachinePart(breedingData.machine)
				print("?? Machine part found:", machinePart ~= nil)

				if machinePart then
					-- ?? CRITICAL: Remove any existing proximity prompts first!
					local removedCount = 0
					for _, child in pairs(machinePart:GetChildren()) do
						if child:IsA("ProximityPrompt") then
							child:Destroy()
							removedCount = removedCount + 1
						end
					end
					print("??? Removed", removedCount, "old proximity prompts")

					-- Change light color to golden
					local light = machinePart:FindFirstChild("BreedingLight")
					if light then
						light.Color = Color3.fromRGB(255, 255, 0)
						light.Brightness = 3
						print("?? Changed light to golden")
					else
						warn("?? No BreedingLight found")
					end

					-- Add ProximityPrompt for collection
					local prompt = Instance.new("ProximityPrompt")
					prompt.ActionText = "Collect Egg"
					prompt.ObjectText = "Breeding Complete!"
					prompt.KeyboardKeyCode = Enum.KeyCode.E
					prompt.MaxActivationDistance = 10
					prompt.RequiresLineOfSight = false
					prompt.HoldDuration = 0
					prompt.Parent = machinePart

					print("? Collection prompt added to:", machinePart.Name)
					print("? Prompt parent:", prompt.Parent and prompt.Parent.Name)

					prompt.Triggered:Connect(function(playerWhoPressed)
						print("?? Collection prompt triggered by:", playerWhoPressed.Name)
						if playerWhoPressed == breedingData.player then
							print("? Correct player - processing egg collection")

							-- We're already on the server, so call the collection logic directly
							local elapsed = tick() - breedingData.startTime
							if elapsed < breedingData.duration then
								warn("?? Breeding not complete yet:", breedingData.duration - elapsed, "seconds remaining")
								return
							end

							-- Add egg to player's inventory
							local success, eggId = GameDataManager:PurchaseItem(
								playerWhoPressed,
								"Egg",
								breedingData.eggData,
								0 -- No cost, already paid during breeding
							)

							if success then
								print("?? Hybrid egg created:", breedingData.eggData.monsterName, "Rarity:", breedingData.eggData.rarity)

								-- Clean up breeding machine
								local machine = breedingData.machine
								machine:SetAttribute("BreedingStartTime", nil)
								machine:SetAttribute("BreedingDuration", nil)
								machine:SetAttribute("Parent1Id", nil)
								machine:SetAttribute("Parent2Id", nil)
								machine:SetAttribute("BreedingReady", nil)

								-- Remove visual effects
								local cleanupPart = getMachinePart(machine)
								if cleanupPart then
									local light = cleanupPart:FindFirstChild("BreedingLight")
									local particles = cleanupPart:FindFirstChild("BreedingParticles")
									if light then light:Destroy() end
									if particles then particles:Destroy() end
								end

								-- Notify client
								breedingCompleteRemote:FireClient(playerWhoPressed, true, breedingData.eggData)

								-- Remove from active breedings
								activeBreedings[machineId] = nil

								-- Destroy the prompt
								prompt:Destroy()

								print("? Egg collected successfully!")
							else
								warn("? Failed to create hybrid egg")
							end
						else
							print("? Wrong player triggered prompt")
						end
					end)
				else
					warn("?? Could not get part from breeding machine for collection prompt")
					warn("?? Machine type:", breedingData.machine.ClassName)
					warn("?? Machine name:", breedingData.machine.Name)
				end

				print("?? Breeding complete! Egg ready for collection:", machineId)
			end
		end
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	-- Cancel any active breedings for this player
	for machineId, breedingData in pairs(activeBreedings) do
		if breedingData.player == player then
			-- Clean up machine
			if breedingData.machine and breedingData.machine.Parent then
				breedingData.machine:SetAttribute("BreedingStartTime", nil)
				breedingData.machine:SetAttribute("BreedingDuration", nil)
				breedingData.machine:SetAttribute("Parent1Id", nil)
				breedingData.machine:SetAttribute("Parent2Id", nil)

				-- ?? FIXED: Clean up visual effects using helper function
				local machinePart = getMachinePart(breedingData.machine)
				if machinePart then
					local light = machinePart:FindFirstChild("BreedingLight")
					local particles = machinePart:FindFirstChild("BreedingParticles")
					local prompt = machinePart:FindFirstChildOfClass("ProximityPrompt")
					if light then light:Destroy() end
					if particles then particles:Destroy() end
					if prompt then prompt:Destroy() end
				end
			end

			activeBreedings[machineId] = nil
		end
	end
end)

print("?? Breeding Handler loaded!")

--[[
?? CRITICAL FIXES IN THIS VERSION:
1. ? Added getMachinePart() helper function (lines 92-101)
2. ? Fixed breeding start visual effects (lines 386-404)
3. ? Fixed breeding completion prompt creation (lines 469-493)
4. ? Fixed egg collection cleanup (lines 447-454)
5. ? Fixed player leaving cleanup (lines 512-521)

Now works with BOTH Part and Model breeding machines!
---]]
