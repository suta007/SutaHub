--!strict
-- src/env.luau

local env: any = getgenv and getgenv() or shared

getgenv().EF_Script = true :: boolean

getgenv().EF_ShopKey = {
	Seed = "ROOT/SeedStocks/Shop/Stocks",
	Daily = "ROOT/SeedStocks/Daily Deals/Stocks",
	Gear = "ROOT/GearStock/Stocks",
	Egg = "ROOT/PetEggStock/Stocks",
	Santa = "ROOT/EventShopStock/Santa's Stash/Stocks",
	NewYear = "ROOT/EventShopStock/New Years Shop/Stocks",
	Traveling = "ROOT/TravelingMerchantShopStock/Stocks",
}
