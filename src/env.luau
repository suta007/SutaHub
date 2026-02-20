--!strict
-- src/env.luau

local getgenv = getgenv :: any
local loadstring = loadstring :: any
local game = game :: any

print("🚀 SutaHub: เข้าสู่ระบบหลัก (Main) แล้วค่ะพี่เอฟ!")

local env = (typeof(getgenv) == "function" and getgenv()) or shared or _G

env.EF_Script = true :: boolean

env.EF_ShopKey = {
	Seed = "ROOT/SeedStocks/Shop/Stocks",
	Daily = "ROOT/SeedStocks/Daily Deals/Stocks",
	Gear = "ROOT/GearStock/Stocks",
	Egg = "ROOT/PetEggStock/Stocks",
	Santa = "ROOT/EventShopStock/Santa's Stash/Stocks",
	NewYear = "ROOT/EventShopStock/New Years Shop/Stocks",
	Traveling = "ROOT/TravelingMerchantShopStock/Stocks",
}
