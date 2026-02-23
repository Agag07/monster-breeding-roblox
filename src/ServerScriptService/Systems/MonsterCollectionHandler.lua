-- ServerScriptService/Systems/MonsterCollectionHandler.lua (COMPLETE - FIXED)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)

-- Create/find remote
local MonsterCollection = ReplicatedStorage:FindFirstChild("MonsterCollection")
if not MonsterCollection then
	MonsterCollection = Instance.new("RemoteEvent")
	MonsterCollection.Name = "MonsterCollection"
	MonsterCollection.Parent = ReplicatedStorage
end

print("?? MonsterCollectionHandler loading...")

MonsterCollection.OnServerEvent:Connect(function(player, action, monsterId, monsterData)
	print("========================================")
	print("?? MonsterCollection event received!")
	print("   Player:", player.Name)
	print("   Action:", action)
	print("   Monster ID:", monsterId)
	print("========================================")

	if action == "catch" then
		-- Verify monsterData has all required fields
		if not monsterData or not monsterData.Name then
			warn("? Invalid monster data - missing Name")
			print("   Received data:", monsterData)
			return
		end

		print("?? Catching monster...")
		print("   Name:", monsterData.Name)
		print("   Elements:", monsterData.Elements)
		print("   Rarity:", monsterData.Rarity)
		print("   HP:", monsterData.HP)
		print("   Attack:", monsterData.Attack)
		print("   Defense:", monsterData.Defense)
		print("   Speed:", monsterData.Speed)
		print("   Level:", monsterData.Level)
		print("   IVs:", monsterData.IVs)

		-- Prepare monster data for saving
		local monsterToSave = {
			Name = monsterData.Name,
			Elements = monsterData.Elements or {monsterData.Element}, -- Array of elements
			Element = type(monsterData.Elements) == "table" and monsterData.Elements[1] or monsterData.Element,
			Rarity = monsterData.Rarity,
			HP = monsterData.HP,
			Attack = monsterData.Attack,
			Defense = monsterData.Defense,
			Speed = monsterData.Speed,
			Level = monsterData.Level or 1,
			IVs = monsterData.IVs or {HP = 0, Attack = 0, Defense = 0, Speed = 0},
			StatQuality = monsterData.StatQuality or "Average",
			SellValue = monsterData.SellValue
		}

		print("?? Saving to GameDataManager...")

		-- Add monster to player's collection
		local success, resultId = GameDataManager:AddMonster(player, monsterToSave)

		if success then
			print("? Monster added successfully!")
			print("   Monster ID:", resultId)
			print("   Name:", monsterData.Name)
			print("   Rarity:", monsterData.Rarity)

			-- Verify it was synced to folders
			local monstersFolder = player:FindFirstChild("Monsters")
			if monstersFolder then
				print("   Monsters in folder:", #monstersFolder:GetChildren())

				-- Check if this specific monster is there
				local savedMonster = monstersFolder:FindFirstChild(resultId)
				if savedMonster then
					print("   ? Monster found in folder!")
				else
					warn("   ?? Monster not found in folder yet (might be delayed)")
				end
			else
				warn("   ?? Monsters folder doesn't exist!")
			end
		else
			warn("? Failed to add monster!")
			warn("   Error:", resultId)
		end

		print("========================================")

	elseif action == "sell" then
		-- Verify monster data
		if not monsterData or not monsterData.Name then
			warn("? Invalid monster data for selling")
			return
		end

		-- Calculate sell value
		local sellValue = monsterData.SellValue or 50

		-- Bonus by level if exists
		local level = monsterData.Level or 1
		sellValue = math.floor(sellValue * (1 + (level - 1) * 0.1))

		print("?? Selling monster:", monsterData.Name, "for", sellValue, "coins")

		GameDataManager:ModifyCoins(player, sellValue)

		print("========================================")
	else
		warn("? Unknown action:", action)
	end
end)

print("? MonsterCollectionHandler loaded!")
