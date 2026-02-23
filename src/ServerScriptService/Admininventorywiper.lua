-- ADMIN INVENTORY WIPER (PROFILESERVICE VERSION)
-- Put this in ServerScriptService as a Script (NOT LocalScript)
-- Type "/wipe" in chat to PERMANENTLY clear your inventory

local Players = game:GetService("Players")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

-- Function to wipe a player's profile data
local function wipePlayerProfile(player)
	print("??? WIPING PROFILE DATA for:", player.Name)

	-- Get the player's profile
	local profile = GameDataManager:GetProfile(player)

	if not profile then
		warn("? No profile found for:", player.Name)
		return
	end

	-- Reset all inventory data to empty
	profile.Data.Inventory.Eggs = {}
	profile.Data.Inventory.Incubators = {}
	profile.Data.Inventory.Habitats = {}
	profile.Data.Inventory.Buildings = {}

	-- Clear all monsters
	profile.Data.Monsters = {}

	-- Clear battle team
	profile.Data.BattleTeam = {nil, nil, nil}

	-- Clear plot data
	profile.Data.PlotData.PlacedObjects = {}

	-- Clear active incubations
	profile.Data.ActiveIncubations = {}

	-- Reset stats
	profile.Data.Stats.MonstersCollected = 0
	profile.Data.Stats.EggsHatched = 0

	-- Reset coins (optional - comment out to keep coins)
	profile.Data.Coins = 1000

	-- Clear the player's current folders
	local eggsFolder = player:FindFirstChild("Eggs")
	if eggsFolder then
		eggsFolder:ClearAllChildren()
	end

	local monstersFolder = player:FindFirstChild("Monsters")
	if monstersFolder then
		monstersFolder:ClearAllChildren()
	end

	local buildingsFolder = player:FindFirstChild("Buildings")
	if buildingsFolder then
		buildingsFolder:ClearAllChildren()
	end

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Coins") then
		leaderstats.Coins.Value = profile.Data.Coins
	end

	-- Clear placed items in plot
	local plotName = player:GetAttribute("AssignedPlot")
	if plotName then
		local plot = workspace:FindFirstChild("PlotsF") and workspace.PlotsF:FindFirstChild(plotName)
		if plot then
			-- Remove all habitats
			for _, child in pairs(plot:GetChildren()) do
				if child:GetAttribute("Type") == "Habitat" then
					child:Destroy()
				end
			end

			-- Remove all incubators
			for _, child in pairs(plot:GetChildren()) do
				if child:GetAttribute("Type") == "Incubator" then
					child:Destroy()
				end
			end

			-- Remove all buildings (except breeding machines which are permanent)
			for _, child in pairs(plot:GetChildren()) do
				local objType = child:GetAttribute("Type")
				if objType and objType ~= "BreedingMachine" then
					if objType == "Building" or child.Name:find("Building") then
						child:Destroy()
					end
				end
			end

			print("  ? Cleared placed items from plot")
		end
	end

	print("?? PROFILE PERMANENTLY WIPED for:", player.Name)
	print("   This will persist even if you rejoin!")
end

-- Listen for chat commands
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local lowerMessage = message:lower()

		if lowerMessage == "/wipe" or lowerMessage == "/clear" or lowerMessage == "/reset" then
			wipePlayerProfile(player)

		elseif lowerMessage == "/wipehelp" or lowerMessage == "/help" then
			print("?? WIPE COMMANDS:")
			print("  /wipe   - Permanently clear your entire inventory")
			print("  /clear  - Same as /wipe")
			print("  /reset  - Same as /wipe")
			print("  /help   - Show this message")
		end
	end)
end)

print("??? ProfileService Inventory Wiper loaded!")
print("   Type '/wipe' in chat to PERMANENTLY clear your inventory")
print("   Type '/help' for more info")

--[[
WHAT THIS CLEARS:
? All eggs (ProfileService data)
? All monsters (ProfileService data)
? All inventory items (ProfileService data)
? All placed items in your plot
? Active incubations
? Battle team
? Stats (monsters collected, eggs hatched)
? Coins reset to 1000 (optional)

WHAT IT KEEPS:
? Your plot assignment
? Breeding machines (permanent)
? Your level/experience (if you want)

This wipe is PERMANENT - even if you rejoin, your inventory stays cleared!
--]]