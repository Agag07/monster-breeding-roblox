-- ShopDataModule.lua (COMPLETE - FIXED SYNTAX)
local ShopDataModule = {}

-- HABITAT & INCUBATOR & BUILDING SHOP
ShopDataModule.habitatShop = {
	-- HABITATS
	["Fire"] = {
		type = "habitat",
		name = "Fire Habitat",
		price = 150,
		description = "Houses Fire element monsters",
		icon = "??"
	},
	["Water"] = {
		type = "habitat", 
		name = "Water Habitat",
		price = 150,
		description = "Houses Water element monsters",
		icon = "??"
	},
	["Earth"] = {
		type = "habitat",
		name = "Earth Habitat", 
		price = 150,
		description = "Houses Earth element monsters",
		icon = "??"
	},
	["Plant"] = {
		type = "habitat",
		name = "Plant Habitat",
		price = 150,
		description = "Houses Plant element monsters",
		icon = "??"
	},
	["Electric"] = {
		type = "habitat",
		name = "Electric Habitat",
		price = 150,
		description = "Houses Electric element monsters", 
		icon = "?"
	},

	-- INCUBATORS
	["NormalIncubator"] = {
		type = "incubator",
		name = "Normal Incubator",
		price = 250,
		description = "Basic egg incubator",
		icon = "??",
		speed = 1.0
	},
	["SuperIncubator"] = {
		type = "incubator",
		name = "Super Incubator", 
		price = 750,
		description = "50% faster hatching",
		icon = "?",
		speed = 1.5
	},
	["UltraIncubator"] = {
		type = "incubator",
		name = "Ultra Incubator",
		price = 1500, 
		description = "100% faster hatching",
		icon = "??",
		speed = 2.0
	},

	-- BREEDING MACHINES
	["BreedingMachine"] = {
		type = "building",
		name = "Breeding Machine",
		price = 500,
		description = "Breed two monsters to create hybrid eggs",
		icon = "??"
	}
}

-- EGG SHOP
ShopDataModule.eggShop = {
	["BasicEgg"] = {
		price = 100,
		name = "Basic Egg",
		hatchTime = 10,
		rarity = "Common",
		description = "70% Common, 25% Rare, 5% Epic",
		gemPrice = 20
	},
	["ElementalEgg"] = {
		price = 350,
		name = "Elemental Egg",
		hatchTime = 20,
		rarity = "Rare",
		description = "50% Common, 30% Rare, 18% Epic, 2% Legendary",
		gemPrice = 50
	},
	["LegendaryEgg"] = {
		price = 1000,
		name = "Legendary Egg",
		hatchTime = 30,
		rarity = "Epic",
		description = "20% Common, 35% Rare, 35% Epic, 10% Legendary",
		gemPrice = 150
	}
}

-- Debug print
print("========================================")
print("?? ShopDataModule Loaded")
print("========================================")
print("HABITAT SHOP:")
print("  Fire Habitat:", ShopDataModule.habitatShop["Fire"].price, "coins")
print("  Normal Incubator:", ShopDataModule.habitatShop["NormalIncubator"].price, "coins")
print("  Breeding Machine:", ShopDataModule.habitatShop["BreedingMachine"].price, "coins")
print("EGG SHOP:")
print("  Basic Egg:", ShopDataModule.eggShop["BasicEgg"].price, "coins")
print("  Legendary Egg:", ShopDataModule.eggShop["LegendaryEgg"].price, "coins")
print("========================================")

return ShopDataModule