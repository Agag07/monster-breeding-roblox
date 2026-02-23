-- HabitatUpgradeHandler.lua (ServerScriptService)
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

	-- Get upgrade data
	local upgradeData = UPGRADE_DATA[currentLevel]
	if not upgradeData then
		warn("? No upgrade data for level:", currentLevel)
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

			-- Optional: Visual upgrade (change size, color, add particles, etc.)
			local habitatElement = habitat:GetAttribute("Element")
			if upgradeData.nextLevel == 2 then
				-- Level 2 visual changes
				print("? Applying Level 2 visual upgrade...")

				-- Add glow effect
				for _, part in pairs(habitat:GetDescendants()) do
					if part:IsA("BasePart") then
						-- Add subtle glow
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
				-- Level 3 visual changes
				print("? Applying Level 3 visual upgrade...")

				-- Increase glow
				for _, part in pairs(habitat:GetDescendants()) do
					if part:IsA("BasePart") then
						local pointLight = part:FindFirstChild("UpgradeGlow")
						if pointLight then
							pointLight.Brightness = 1.0
							pointLight.Range = 20
						end

						-- Add sparkle effect
						part.Material = Enum.Material.Neon
					end
				end
			end
		end
	end

	-- Save to ProfileService
	-- (ProfileService auto-saves, but this ensures it's tracked)

	print("? Habitat upgraded to Level", upgradeData.nextLevel, "for", player.Name)
	print("  +- New capacity:", upgradeData.maxCapacity)
	print("  +- Income multiplier:", upgradeData.incomeMultiplier .. "x")
	print("  +- Cost:", upgradeData.cost, "coins")
end)

print("? HabitatUpgradeHandler loaded!")