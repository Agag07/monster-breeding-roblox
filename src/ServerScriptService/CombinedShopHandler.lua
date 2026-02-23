-- CombinedShopHandler.lua (Uses ShopDataModule)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameDataManager = require(game.ServerScriptService.Systems.GameDataManager)
local ShopDataModule = require(game.ServerScriptService.ShopDataModule)

-- Get shop items from module
local shopItems = ShopDataModule.habitatShop

-- Create remote events
local buyItemRemote = ReplicatedStorage:FindFirstChild("BuyItem")
if not buyItemRemote then
	buyItemRemote = Instance.new("RemoteEvent")
	buyItemRemote.Name = "BuyItem"
	buyItemRemote.Parent = ReplicatedStorage
end

local buyResultRemote = ReplicatedStorage:FindFirstChild("BuyResult")
if not buyResultRemote then
	buyResultRemote = Instance.new("RemoteEvent")
	buyResultRemote.Name = "BuyResult"
	buyResultRemote.Parent = ReplicatedStorage
end

print("?? CombinedShopHandler loaded - Using ShopDataModule")
-- Handle item purchase
buyItemRemote.OnServerEvent:Connect(function(player, itemId)
	local itemData = shopItems[itemId]
	if not itemData then
		warn("? Invalid item:", itemId)
		buyResultRemote:FireClient(player, false, "Invalid item")
		return
	end

	-- Build proper item data structure
	local itemToSave = {}

	if itemData.type == "habitat" then
		itemToSave = {element = itemId, placed = false}
	elseif itemData.type == "incubator" then
		itemToSave = {type = itemId, speed = itemData.speed, placed = false}
	elseif itemData.type == "building" then  -- ? NEW
		itemToSave = {type = itemId, placed = false}
	end

	-- Use GameDataManager for purchase
	local success, result = GameDataManager:PurchaseItem(
		player,
		-- Determine category
		itemData.type == "habitat" and "Habitat" or 
			itemData.type == "incubator" and "Incubator" or
			itemData.type == "building" and "Building" or "Item",  -- ? NEW
		itemToSave,
		itemData.price
	)

	if success then
		print("? Purchase:", itemData.name, "by", player.Name)
		buyResultRemote:FireClient(player, true, itemData.name)
	else
		print("? Failed:", result)
		buyResultRemote:FireClient(player, false, result)
	end
end)
