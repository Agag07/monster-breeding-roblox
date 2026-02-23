-- EggIncubationHandler.lua (ServerScriptService) - COMPLETE VERSION WITH HYBRID SUPPORT
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Get/Create RemoteEvents
local placeEggRemote = ReplicatedStorage:WaitForChild("PlaceEgg")
local showMonsterRemote = ReplicatedStorage:WaitForChild("ShowMonster")

-- Get required folders
local EggModels = ReplicatedStorage:WaitForChild("EggModels")
local Plots = workspace:WaitForChild("PlotsF")

-- Active incubations tracking
local activeIncubations = {}
local readyEggs = {} -- Track eggs ready for collection

-- Base monsters definition
local BASE_MONSTERS = {
	{
		Name = "Ignis",
		Element = "Fire",
		BaseStats = {HP = 90, Attack = 65, Defense = 40, Speed = 55}
	},
	{
		Name = "Aquara",
		Element = "Water",
		BaseStats = {HP = 100, Attack = 45, Defense = 60, Speed = 45}
	},
	{
		Name = "Terrock",
		Element = "Earth",
		BaseStats = {HP = 120, Attack = 50, Defense = 70, Speed = 30}
	},
	{
		Name = "Voltwing",
		Element = "Electric",
		BaseStats = {HP = 80, Attack = 60, Defense = 35, Speed = 75}
	},
	{
		Name = "Floraleaf",
		Element = "Plant",
		BaseStats = {HP = 95, Attack = 55, Defense = 50, Speed = 50}
	}
}

-- Hybrid monsters definition
local HYBRID_MONSTERS = {
	Vaporix = {
		Name = "Vaporix",
		Element = "Fire,Water",
		BaseStats = {HP = 95, Attack = 55, Defense = 50, Speed = 50}
	},
	Magmor = {
		Name = "Magmor",
		Element = "Fire,Earth",
		BaseStats = {HP = 105, Attack = 58, Defense = 55, Speed = 42}
	},
	Blazebloom = {
		Name = "Blazebloom",
		Element = "Fire,Plant",
		BaseStats = {HP = 92, Attack = 60, Defense = 45, Speed = 52}
	},
	Voltflare = {
		Name = "Voltflare",
		Element = "Fire,Electric",
		BaseStats = {HP = 85, Attack = 62, Defense = 37, Speed = 65}
	},
	Sludgy = {
		Name = "Sludgy",
		Element = "Water,Earth",
		BaseStats = {HP = 110, Attack = 47, Defense = 65, Speed = 38}
	},
	Hydravine = {
		Name = "Hydravine",
		Element = "Water,Plant",
		BaseStats = {HP = 97, Attack = 50, Defense = 55, Speed = 48}
	},
	Thundersplash = {
		Name = "Thundersplash",
		Element = "Water,Electric",
		BaseStats = {HP = 90, Attack = 52, Defense = 47, Speed = 60}
	},
	Terravine = {
		Name = "Terravine",
		Element = "Earth,Plant",
		BaseStats = {HP = 107, Attack = 52, Defense = 60, Speed = 40}
	},
	Tarick = {
		Name = "Tarick",
		Element = "Earth,Electric",
		BaseStats = {HP = 100, Attack = 55, Defense = 52, Speed = 52}
	},
	Wattsprout = {
		Name = "Wattsprout",
		Element = "Plant,Electric",
		BaseStats = {HP = 87, Attack = 57, Defense = 42, Speed = 62}
	}
}
-- Rarity data
local RarityData = {
	Common = {weight = 50, statMultiplier = 1.0},
	Rare = {weight = 30, statMultiplier = 1.3},
	Epic = {weight = 15, statMultiplier = 1.6},
	Legendary = {weight = 5, statMultiplier = 2.0}
}

-- Sell values by rarity
local SELL_VALUES = {
	Common = 50,
	Rare = 150,
	Epic = 400,
	Legendary = 1000
}

-- Function to generate monster stats (UPDATED FOR HYBRIDS)
local function generateMonsterStats(eggData, customRarity)
	local selectedMonster = nil
	local rarity = customRarity or (type(eggData) == "table" and eggData.rarity) or nil
	local ivs = type(eggData) == "table" and eggData.ivs or nil

	-- Handle legacy calls (when eggData is just a string eggType)
	if type(eggData) == "string" then
		eggData = {type = eggData}
	end

	-- Check if this is a hybrid egg from breeding
	if eggData.type == "HybridEgg" and eggData.monsterName then
		-- Use the specific hybrid monster
		selectedMonster = HYBRID_MONSTERS[eggData.monsterName]
		if not selectedMonster then
			-- Fallback to random base monster if hybrid not found
			selectedMonster = BASE_MONSTERS[math.random(1, #BASE_MONSTERS)]
		end
	else
		-- Regular egg - select random base monster
		selectedMonster = BASE_MONSTERS[math.random(1, #BASE_MONSTERS)]
	end

	-- Determine rarity if not specified
	if not rarity then
		local totalWeight = 0
		for _, data in pairs(RarityData) do
			totalWeight = totalWeight + data.weight
		end

		local randomNum = math.random(1, totalWeight)
		local currentWeight = 0

		for rarityName, data in pairs(RarityData) do
			currentWeight = currentWeight + data.weight
			if randomNum <= currentWeight then
				rarity = rarityName
				break
			end
		end
	end

	-- Apply rarity multiplier to stats
	local rarityMultiplier = RarityData[rarity].statMultiplier

	-- Calculate final stats with IVs if provided
	local stats = {}
	for statName, baseValue in pairs(selectedMonster.BaseStats) do
		local finalStat = math.floor(baseValue * rarityMultiplier)

		-- Add IV bonus if available
		if ivs and ivs[statName .. "IV"] then
			finalStat = finalStat + ivs[statName .. "IV"]
		else
			-- Generate random IV if not inherited
			local randomIV = math.random(0, 31)
			finalStat = finalStat + randomIV
			if not ivs then ivs = {} end
			ivs[statName .. "IV"] = randomIV
		end

		stats[statName] = finalStat
	end

	-- Return complete monster data
	local monsterData = {
		Name = selectedMonster.Name,
		Element = selectedMonster.Element,
		Rarity = rarity,
		HP = stats.HP,
		Attack = stats.Attack,
		Defense = stats.Defense,
		Speed = stats.Speed,
		Level = 1,
		SellValue = SELL_VALUES[rarity] or 50,
		Id = "Monster_" .. tostring(tick()) .. "_" .. math.random(1000, 9999)
	}

	-- Include IVs in the data
	if ivs then
		monsterData.HPIV = ivs.HPIV or math.random(0, 31)
		monsterData.AttackIV = ivs.AttackIV or math.random(0, 31)
		monsterData.DefenseIV = ivs.DefenseIV or math.random(0, 31)
		monsterData.SpeedIV = ivs.SpeedIV or math.random(0, 31)
	end

	-- Add breeding heritage if it's a hybrid egg
	if eggData.type == "HybridEgg" and eggData.parent1 and eggData.parent2 then
		monsterData.Parent1 = eggData.parent1
		monsterData.Parent2 = eggData.parent2
		monsterData.BredGeneration = (eggData.generation or 0) + 1
	end

	return monsterData
end

-- Function to collect monster
local function collectMonster(player, incubatorId)
	local eggData = readyEggs[incubatorId]
	if not eggData or eggData.player ~= player then
		warn("No ready egg found for collection:", incubatorId)
		return
	end

	-- Generate monster - pass the full eggData object
	local monsterData = generateMonsterStats(eggData.eggData, eggData.eggData.rarity)

	print("Monster generated:", monsterData.Name, "Rarity:", monsterData.Rarity, "Element:", monsterData.Element)

	-- Show monster collection UI
	showMonsterRemote:FireClient(player, monsterData)

	-- Clean up egg and incubator
	if eggData.eggModel then
		eggData.eggModel:Destroy()
	end

	eggData.incubator:SetAttribute("EggId", nil)
	eggData.incubator:SetAttribute("StartTime", nil)
	eggData.incubator:SetAttribute("HatchTime", nil)
	eggData.incubator:SetAttribute("EggType", nil)
	eggData.incubator:SetAttribute("EggRarity", nil)

	readyEggs[incubatorId] = nil

	print("Monster ready for collection by:", player.Name)
end

-- Function to place egg model on incubator
local function placeEggModel(incubator, eggData)
	local eggModel = EggModels:FindFirstChild("Egg1")
	if not eggModel then
		warn("Egg1 model not found in EggModels!")
		return nil
	end

	local clonedEgg = eggModel:Clone()
	clonedEgg.Name = "IncubatedEgg"

	-- Position egg above incubator
	local incubatorCF, incubatorSize = incubator:GetBoundingBox()
	local eggPosition = incubatorCF.Position + Vector3.new(0, incubatorSize.Y/2 + 2, 0)

	if clonedEgg.PrimaryPart then
		clonedEgg:PivotTo(CFrame.new(eggPosition))
	else
		local eggPart = clonedEgg:FindFirstChildWhichIsA("BasePart")
		if eggPart then
			eggPart.Position = eggPosition
		end
	end

	-- Add egg data as attributes
	clonedEgg:SetAttribute("EggType", eggData.eggType)
	clonedEgg:SetAttribute("OriginalHatchTime", eggData.hatchTime)
	clonedEgg:SetAttribute("RemainingTime", eggData.adjustedHatchTime)
	clonedEgg:SetAttribute("StartTime", tick())
	clonedEgg:SetAttribute("IsReady", false)

	clonedEgg.Parent = incubator

	-- Add floating animation
	local animatePart = clonedEgg.PrimaryPart or clonedEgg:FindFirstChildWhichIsA("BasePart")
	if animatePart then
		local floatTween = game:GetService("TweenService"):Create(
			animatePart,
			TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Position = animatePart.Position + Vector3.new(0, 1, 0)}
		)
		floatTween:Play()
	end

	return clonedEgg
end

-- Function to make egg ready for collection
local function makeEggReady(incubatorId, incubationData)
	local eggModel = incubationData.eggModel
	if not eggModel or not eggModel.Parent then return end

	-- Mark egg as ready
	eggModel:SetAttribute("IsReady", true)

	-- Add visual effect
	local eggPart = eggModel.PrimaryPart or eggModel:FindFirstChildWhichIsA("BasePart")
	if eggPart then
		-- Add glow effect
		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(255, 255, 0)
		pointLight.Brightness = 2
		pointLight.Range = 10
		pointLight.Parent = eggPart

		-- Change egg color to gold
		eggPart.Color = Color3.fromRGB(255, 255, 0)
		eggPart.Material = Enum.Material.Neon

		-- Add ProximityPrompt for Press E
		local proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ActionText = "Collect Monster"
		proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
		proximityPrompt.MaxActivationDistance = 10
		proximityPrompt.RequiresLineOfSight = false
		proximityPrompt.Parent = eggPart

		-- Handle E key press
		proximityPrompt.Triggered:Connect(function(playerWhoPressed)
			if playerWhoPressed == incubationData.player then
				collectMonster(playerWhoPressed, incubatorId)
			end
		end)
	end

	-- Move to ready eggs tracking
	readyEggs[incubatorId] = incubationData
	activeIncubations[incubatorId] = nil

	print("Egg ready for collection! Press E to collect:", incubatorId)
end

-- Handle egg placement
placeEggRemote.OnServerEvent:Connect(function(player, eggId, incubatorId, incubatorData)
	local eggsFolder = player:FindFirstChild("Eggs")
	local egg = eggsFolder and eggsFolder:FindFirstChild(eggId)

	if not egg then
		warn("Egg not found:", eggId, "for player:", player.Name)
		return
	end

	local plotName = player:GetAttribute("AssignedPlot")
	local plot = Plots:FindFirstChild(plotName)
	local incubator = plot and plot:FindFirstChild(incubatorId)

	if not incubator or incubator:GetAttribute("Type") ~= "Incubator" then
		warn("Invalid incubator:", incubatorId, "for player:", player.Name)
		return
	end

	if incubator:GetAttribute("EggId") then
		warn("Incubator already in use:", incubatorId)
		return
	end

	local eggTypeValue = egg:FindFirstChild("EggType")
	local hatchTimeValue = egg:FindFirstChild("HatchTime")
	local rarityValue = egg:FindFirstChild("Rarity")

	if not eggTypeValue or not hatchTimeValue then
		warn("Invalid egg data for:", eggId)
		return
	end

	local speedMultiplier = incubatorData.speed or 1.0
	local originalHatchTime = hatchTimeValue.Value
	local adjustedHatchTime = math.ceil(originalHatchTime / speedMultiplier)

	print("Placing egg:", eggTypeValue.Value, "- Adjusted time:", adjustedHatchTime, "seconds")

	local eggModel = placeEggModel(incubator, {
		eggType = eggTypeValue.Value,
		hatchTime = originalHatchTime,
		adjustedHatchTime = adjustedHatchTime
	})

	if not eggModel then
		warn("Failed to place egg model")
		return
	end

	incubator:SetAttribute("EggId", eggId)
	incubator:SetAttribute("StartTime", tick())
	incubator:SetAttribute("HatchTime", adjustedHatchTime)
	incubator:SetAttribute("EggType", eggTypeValue.Value)
	incubator:SetAttribute("EggRarity", rarityValue and rarityValue.Value or "Common")

	activeIncubations[incubatorId] = {
		player = player,
		incubator = incubator,
		eggModel = eggModel,
		startTime = tick(),
		hatchTime = adjustedHatchTime,
		eggData = {
			type = eggTypeValue.Value,
			rarity = rarityValue and rarityValue.Value or "Common",
			-- Add these for hybrid eggs:
			ivs = egg:FindFirstChild("IVs") and {
				HPIV = egg.IVs:FindFirstChild("HPIV") and egg.IVs.HPIV.Value,
				AttackIV = egg.IVs:FindFirstChild("AttackIV") and egg.IVs.AttackIV.Value,
				DefenseIV = egg.IVs:FindFirstChild("DefenseIV") and egg.IVs.DefenseIV.Value,
				SpeedIV = egg.IVs:FindFirstChild("SpeedIV") and egg.IVs.SpeedIV.Value
			},
			monsterName = egg:FindFirstChild("MonsterName") and egg.MonsterName.Value,
			parent1 = egg:FindFirstChild("Parent1") and egg.Parent1.Value,
			parent2 = egg:FindFirstChild("Parent2") and egg.Parent2.Value
		}
	}

	egg:Destroy()
	print("Egg placed successfully in incubator:", incubatorId)
end)

-- Main incubation timer loop
RunService.Heartbeat:Connect(function()
	local currentTime = tick()

	for incubatorId, incubationData in pairs(activeIncubations) do
		local timeElapsed = currentTime - incubationData.startTime
		local timeRemaining = incubationData.hatchTime - timeElapsed

		if incubationData.eggModel and incubationData.eggModel.Parent then
			incubationData.eggModel:SetAttribute("RemainingTime", math.max(0, timeRemaining))
		end

		-- Check if egg is ready for collection
		if timeElapsed >= incubationData.hatchTime then
			makeEggReady(incubatorId, incubationData)
		end
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	for incubatorId, incubationData in pairs(activeIncubations) do
		if incubationData.player == player then
			if incubationData.eggModel then
				incubationData.eggModel:Destroy()
			end
			activeIncubations[incubatorId] = nil
		end
	end

	for incubatorId, eggData in pairs(readyEggs) do
		if eggData.player == player then
			if eggData.eggModel then
				eggData.eggModel:Destroy()
			end
			readyEggs[incubatorId] = nil
		end
	end
end)

print("?? Egg Incubation Handler loaded with hybrid monster support!")