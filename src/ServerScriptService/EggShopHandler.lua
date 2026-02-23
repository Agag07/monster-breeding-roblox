-- EggShopHandler.lua (Uses ShopDataModule)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)
local ShopDataModule = require(game.ServerScriptService.ShopDataModule)

-- Get egg shop data from module
local eggShop = ShopDataModule.eggShop

-- Create remote events
local buyEggRemote = ReplicatedStorage:FindFirstChild("BuyEgg")
if not buyEggRemote then
	buyEggRemote = Instance.new("RemoteEvent")
	buyEggRemote.Name = "BuyEgg"
	buyEggRemote.Parent = ReplicatedStorage
end

local openEggShopRemote = ReplicatedStorage:FindFirstChild("OpenEggShop")
if not openEggShopRemote then
	openEggShopRemote = Instance.new("RemoteEvent")
	openEggShopRemote.Name = "OpenEggShop"
	openEggShopRemote.Parent = ReplicatedStorage
end

local eggResultRemote = ReplicatedStorage:FindFirstChild("EggResult")
if not eggResultRemote then
	eggResultRemote = Instance.new("RemoteEvent")
	eggResultRemote.Name = "EggResult"
	eggResultRemote.Parent = ReplicatedStorage
end

print("?? EggShopHandler loaded - Using ShopDataModule")

-- Handle egg purchase
buyEggRemote.OnServerEvent:Connect(function(player, eggType)
	local eggData = eggShop[eggType]
	if not eggData then
		warn("? Invalid egg type:", eggType)
		eggResultRemote:FireClient(player, false, "Invalid egg type")
		return
	end

	-- Build egg data structure
	local eggToSave = {
		type = eggType,
		hatchTime = eggData.hatchTime,
		rarity = eggData.rarity
	}

	-- Use GameDataManager for purchase
	local success, eggId = GameDataManager:PurchaseItem(
		player,
		"Egg",
		eggToSave,
		eggData.price
	)

	if success then
		print("? Egg purchased:", eggData.name, "by", player.Name)
		eggResultRemote:FireClient(player, true, {
			type = eggType,
			name = eggData.name,
			hatchTime = eggData.hatchTime,
			id = eggId
		})
	else
		print("? Failed:", eggId)
		eggResultRemote:FireClient(player, false, eggId or "Not enough coins")
	end
end)

-- Function to get shop data for client
local function getShopData()
	local shopData = {}
	for eggType, data in pairs(eggShop) do
		shopData[eggType] = {
			name = data.name,
			price = data.price,
			hatchTime = data.hatchTime,
			description = data.description
		}
	end
	return shopData
end

-- Send shop data when requested (not used if NPC sends directly)
openEggShopRemote.OnServerEvent:Connect(function(player)
	openEggShopRemote:FireClient(player, getShopData())
end)

print("? EggShopHandler ready!")
