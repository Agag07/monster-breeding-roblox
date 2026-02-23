-- HabitatUpgradeHandler.lua (ServerScriptService) - CORREGIDO
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

-- Create/Get Remote Event
local upgradeHabitatRemote = ReplicatedStorage:FindFirstChild("UpgradeHabitat")
if not upgradeHabitatRemote then
	upgradeHabitatRemote = Instance.new("RemoteEvent")
	upgradeHabitatRemote.Name = "UpgradeHabitat"
	upgradeHabitatRemote.Parent = ReplicatedStorage
end

-- Upgrade costs and capacities
local UPGRADE_DATA = {
	[1] = {cost = 500, maxCapacity = 3, incomeMultiplier = 1.5, nextLevel = 2},
	[2] = {cost = 1500, maxCapacity = 4, incomeMultiplier = 2.0, nextLevel = 3}
}

-- Handle habitat upgrade
upgradeHabitatRemote.OnServerEvent:Connect(function(player, habitatId)
	print("?? Upgrade request from", player.Name, "for habitat:", habitatId)

	-- Validate player
	if not player or not player.Parent then
		warn("? Invalid player")
		return
	end

	-- Get player's profile
	local profile = GameDataManager:GetProfile(player)
	if not profile then
		warn("? No profile found for player:", player.Name)
		return
	end

	-- Find habitat data in profile
	local habitatData = profile.Data.Inventory.Habitats[habitatId]
	if not habitatData then
		warn("? Habitat not found in inventory:", habitatId)
		return
	end

	-- Get current level
	local currentLevel = habitatData.level or 1

	-- Check if already max level
	if currentLevel >= 3 then
		warn("?? Habitat already at max level (3)")
		return
	end

	-- Get upgrade data with validation
	local upgradeData = UPGRADE_DATA[currentLevel]
	if not upgradeData then
		warn("? No upgrade data for level:", currentLevel)
		return
	end

	-- Validate upgrade data structure
	if not upgradeData.cost or not upgradeData.nextLevel or not upgradeData.maxCapacity then
		warn("? Invalid upgrade data structure for level:", currentLevel)
		return
	end

	-- Check if player has enough coins
	if profile.Data.Coins < upgradeData.cost then
		warn("? Not enough coins. Need:", upgradeData.cost, "Have:", profile.Data.Coins)
		return
	end

	-- Deduct coins
	GameDataManager:ModifyCoins(player, -upgradeData.cost)

	-- Upgrade habitat level in profile
	habitatData.level = upgradeData.nextLevel

	-- Update habitat model in workspace
	local plotName = player:GetAttribute("AssignedPlot")
	local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
	if plot then
		local habitat = plot:FindFirstChild(habitatId)
		if habitat then
			-- Update level attribute
			habitat:SetAttribute("Level", upgradeData.nextLevel)

			-- Optional: Visual upgrade
			if upgradeData.nextLevel == 2 then
				print("? Applying Level 2 visual upgrade...")
				for _, part in pairs(habitat:GetDescendants()) do
					if part:IsA("BasePart") then
						local pointLight = part:FindFirstChild("UpgradeGlow")
						if not pointLight then
							pointLight = Instance.new("PointLight")
							pointLight.Name = "UpgradeGlow"
							pointLight.Brightness = 0.5
							pointLight.Range = 15
							pointLight.Color = part.Color
							pointLight.Parent = part
						end
					end
				end

			elseif upgradeData.nextLevel == 3 then
				print("? Applying Level 3 visual upgrade...")
				for _, part in pairs(habitat:GetDescendants()) do
					if part:IsA("BasePart") then
						local pointLight = part:FindFirstChild("UpgradeGlow")
						if pointLight then
							pointLight.Brightness = 1.0
							pointLight.Range = 20
						end
						part.Material = Enum.Material.Neon
					end
				end
			end
		end
	end

	print("? Habitat upgraded to Level", upgradeData.nextLevel, "for", player.Name)
	print("  +- New capacity:", upgradeData.maxCapacity)
	print("  +- Income multiplier:", upgradeData.incomeMultiplier .. "x")
	print("  +- Cost:", upgradeData.cost, "coins")
end)

print("? HabitatUpgradeHandler loaded!")
