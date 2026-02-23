-- ServerScriptService/RemoveHabitatHandler.lua (COMPLETE FIXED VERSION)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

-- Create the remove habitat remote
local removeHabitatRemote = ReplicatedStorage:FindFirstChild("RemoveHabitat")
if not removeHabitatRemote then
	removeHabitatRemote = Instance.new("RemoteEvent")
	removeHabitatRemote.Name = "RemoveHabitat"
	removeHabitatRemote.Parent = ReplicatedStorage
end

local Plots = workspace:WaitForChild("PlotsF")

-- Habitat prices for refund calculation (50% refund)
local prices = {
	["Fire"] = 150,
	["Water"] = 150,
	["Earth"] = 150,
	["Plant"] = 150,
	["Electric"] = 150,
}

removeHabitatRemote.OnServerEvent:Connect(function(player, habitatId)
	-- Validate player - CORREGIDO
	if not player or not player.Parent then
		warn("? Invalid player")
		return
	end

	local plotName = player:GetAttribute("AssignedPlot")
	local plot = Plots:FindFirstChild(plotName)
	if not plot then 
		warn("? Plot not found for player:", plotName)
		return 
	end

	local habitat = plot:FindFirstChild(habitatId)
	if not habitat then 
		warn("? Habitat not found:", habitatId)
		return 
	end

	-- Verify ownership - CORREGIDO
	local habitatOwner = habitat:GetAttribute("Owner")
	if habitatOwner ~= player.UserId then
		warn("? Player doesn't own this habitat")
		return
	end

	-- Get habitat type from the ID
	local habitatType = habitatId:match("^(.-)_")
	if habitatType and prices[habitatType] then
		-- Give back 50% of original price
		local refund = math.floor(prices[habitatType] * 0.5)
		GameDataManager:ModifyCoins(player, refund)
		print("?? Refunded", refund, "coins to", player.Name)
	end

	-- Return habitat to inventory and remove from plot data - CORREGIDO
	local profile = GameDataManager:GetProfile(player)
	if profile then
		-- Validate profile structure
		if not profile.Data then
			warn("? Profile data invalid for player:", player.Name)
			return
		end

		-- Find and remove from placed objects
		local placedObjects = profile.Data.PlotData and profile.Data.PlotData.PlacedObjects
		if placedObjects then
			for i = #placedObjects, 1, -1 do
				if placedObjects[i].id == habitatId then
					table.remove(placedObjects, i)
					break
				end
			end
		end

		-- Mark habitat as not placed in inventory
		if profile.Data.Inventory and profile.Data.Inventory.Habitats and profile.Data.Inventory.Habitats[habitatId] then
			profile.Data.Inventory.Habitats[habitatId].placed = false
		end

		-- Sync to folders
		if GameDataManager.SyncDataToFolders then
			GameDataManager:SyncDataToFolders(player, profile.Data)
		end
	else
		warn("? No profile found for player:", player.Name)
		return
	end

	habitat:Destroy()
	print("??? Habitat removed:", habitatId, "by", player.Name)
end)

print("? RemoveHabitatHandler loaded!")
