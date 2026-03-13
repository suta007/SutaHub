-- Modules/Shop.lua
local Shop = {}
local Core = nil
local UI = nil

Shop.ShopKey = {
	Seed = "ROOT/SeedStocks/Shop/Stocks",
	Daily = "ROOT/SeedStocks/Daily Deals/Stocks",
	Gear = "ROOT/GearStock/Stocks",
	Egg = "ROOT/PetEggStock/Stocks",
	Santa = "ROOT/EventShopStock/Santa's Stash/Stocks",
	NewYear = "ROOT/EventShopStock/New Years Shop/Stocks",
	Traveling = "ROOT/TravelingMerchantShopStock/Stocks",
}

Shop.BuyList = {
	[Shop.ShopKey.Seed] = { Enabled = false, BuyAll = false, Items = {}, RemoteName = "BuySeedStock", ArgType = "SeedMode" },
	[Shop.ShopKey.Daily] = { Enabled = true, BuyAll = true, Items = {}, RemoteName = "BuyDailySeedShopStock", ArgType = "NormalMode" },
	[Shop.ShopKey.Gear] = { Enabled = false, BuyAll = false, Items = {}, RemoteName = "BuyGearStock", ArgType = "NormalMode" },
	[Shop.ShopKey.Egg] = { Enabled = false, BuyAll = false, Items = {}, RemoteName = "BuyPetEgg", ArgType = "NormalMode" },
	[Shop.ShopKey.Traveling] = { Enabled = false, BuyAll = false, Items = {}, RemoteName = "BuyTravelingMerchantShopStock", ArgType = "NormalMode" },
	[Shop.ShopKey.Santa] = { Enabled = false, BuyAll = false, Items = {}, RemoteName = "BuyEventShopStock", ArgType = "EventMode", EventArg = "Santa's Stash" },
	[Shop.ShopKey.NewYear] = { Enabled = false, BuyAll = false, Items = {}, RemoteName = "BuyEventShopStock", ArgType = "EventMode", EventArg = "New Years Shop" },
}

local RemoteCache = {}

local function isTableEmpty(t)
	return type(t) ~= "table" or next(t) == nil
end

function Shop.Init(RefCore, RefUI)
	Core = RefCore
	UI = RefUI
	Shop.BuildUI()
end

function Shop.ProcessBuy(ShopKeyType, StockData)
	local Setting = Shop.BuyList[ShopKeyType]
	if not Setting or not Setting.Enabled then return end
	local Remote = RemoteCache[Setting.RemoteName]
	if not Remote then
		Remote = Core.GameEvents:FindFirstChild(Setting.RemoteName)
		if Remote then RemoteCache[Setting.RemoteName] = Remote end
	end

	for itemId, itemInfo in pairs(StockData) do
		local ItemName = itemInfo.EggName or itemId
		local StockAmount = tonumber(itemInfo.Stock) or 0
		local BuyEnabled = false
		local StockInfo = string.format("Found %s : %s", ItemName, StockAmount)
		Core.DevNoti(StockInfo)
		if Setting.BuyAll then
			BuyEnabled = true
		else
			for _, TargetName in ipairs(Setting.Items) do
				if TargetName == ItemName then
					BuyEnabled = true
					break
				end
			end
		end

		if BuyEnabled == true and StockAmount > 0 then
			for i = 1, StockAmount do
				local Args = {}
				if Setting.ArgType == "SeedMode" then
					Args = { "Shop", ItemName }
				elseif Setting.ArgType == "EventMode" then
					Args = { ItemName, Setting.EventArg }
				else
					Args = { ItemName }
				end
				Remote:FireServer(unpack(Args))
				task.wait(0.1)
			end
			BuyEnabled = false
			Core.DevNoti(string.format("Bought %s : %s", ItemName, StockAmount))
		end
	end
end

function Shop.HardCoreBuy()
	if UI.Options.HardCoreBuyEnable.Value then
		local GetData_result = Core.DataService:GetData()
		local SeedStocks = GetData_result.SeedStocks.Shop.Stocks
		local GearStock = GetData_result.GearStock.Stocks
		local EggStock = GetData_result.PetEggStock.Stocks
		if not isTableEmpty(SeedStocks) then Shop.ProcessBuy(Shop.ShopKey.Seed, SeedStocks) end
		if not isTableEmpty(GearStock) then Shop.ProcessBuy(Shop.ShopKey.Gear, GearStock) end
		if not isTableEmpty(EggStock) then Shop.ProcessBuy(Shop.ShopKey.Egg, EggStock) end
		task.wait(tonumber(UI.Options.HardCoreDelay.Value))
	end
end

function Shop.BuildUI()
	local Tabs = UI.Tabs
	local Options = UI.Options
	local Sync = function()
		if UI.SyncBackgroundTasks then UI.SyncBackgroundTasks() end
	end

	local HardCoreSection = Tabs.Buy:AddCollapsibleSection("Hardcore Buy", false)
	HardCoreSection:AddToggle("HardCoreBuyEnable", {
		Title = "Buy Hardcore",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HardCoreSection:AddInput("HardCoreDelay", {
		Title = "Delay (Seconds)",
		Default = 0.3,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	-- Seed Section
	local BuySeedSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Seeds", false)
	BuySeedSection:AddToggle("buySeedEnable", {
		Title = "Buy Seeds",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Seed].Enabled = Value
			if Value then
				local GetData_result = Core.DataService:GetData()
				local SeedStocks = GetData_result.SeedStocks.Shop.Stocks
				if not isTableEmpty(SeedStocks) then Shop.ProcessBuy(Shop.ShopKey.Seed, SeedStocks) end
			end
			Core.QuickSave()
			Sync()
		end,
	})
	BuySeedSection:AddToggle("buySeedAll", {
		Title = "Buy All Seeds",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Seed].BuyAll = Value
			Core.QuickSave()
			Sync()
		end,
	})

	local SeedData = require(Core.ReplicatedStorage.Data.SeedShopData)
	local SeedTable = {}
	for seedName, _ in pairs(SeedData) do
		table.insert(SeedTable, seedName)
	end
	table.sort(SeedTable)
	BuySeedSection:AddDropdown("SeedList", {
		Title = "Seeds",
		Values = SeedTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Seed].Items = UI.GetSelectedItems(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	-- Daily Section
	local BuyDailySection = Tabs.Buy:AddCollapsibleSection("Auto Buy Daily Seed", false)
	BuyDailySection:AddToggle("buyDailyEnable", {
		Title = "Buy Daily Seed",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Daily].Enabled = Value
			if Value then
				local GetData_result = Core.DataService:GetData()
				local DailyStocks = GetData_result.SeedStocks["Daily Deals"].Stocks
				if not isTableEmpty(DailyStocks) then Shop.ProcessBuy(Shop.ShopKey.Daily, DailyStocks) end
			end
			Core.QuickSave()
			Sync()
		end,
	})
	BuyDailySection:AddToggle("buyDailyAll", {
		Title = "Buy All Daily Seed",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Daily].BuyAll = Value
			Core.QuickSave()
			Sync()
		end,
	})

	-- Gear Section
	local buyGearSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Gear", false)
	buyGearSection:AddToggle("buyGearEnable", {
		Title = "Buy Gear",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Gear].Enabled = Value
			if Value then
				local GetData_result = Core.DataService:GetData()
				local GearStock = GetData_result.GearStock.Stocks
				if not isTableEmpty(GearStock) then Shop.ProcessBuy(Shop.ShopKey.Gear, GearStock) end
			end
			Core.QuickSave()
			Sync()
		end,
	})
	buyGearSection:AddToggle("buyGearAll", {
		Title = "Buy All Gear",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Gear].BuyAll = Value
			Core.QuickSave()
			Sync()
		end,
	})

	local GearData = require(Core.ReplicatedStorage.Data.GearShopData)
	local GearTable = {}
	for gearName, _ in pairs(GearData["Gear"]) do
		table.insert(GearTable, gearName)
	end
	table.sort(GearTable)
	buyGearSection:AddDropdown("GearList", {
		Title = "Gear",
		Values = GearTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Gear].Items = UI.GetSelectedItems(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	-- Pet Egg Section
	local buyEggSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Pet Eggs", false)
	buyEggSection:AddToggle("buyEggEnable", {
		Title = "Buy Pet Eggs",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Egg].Enabled = Value
			if Value then
				local GetData_result = Core.DataService:GetData()
				local EggStock = GetData_result.PetEggStock.Stocks
				if not isTableEmpty(EggStock) then Shop.ProcessBuy(Shop.ShopKey.Egg, EggStock) end
			end
			Core.QuickSave()
			Sync()
		end,
	})
	buyEggSection:AddToggle("buyEggAll", {
		Title = "Buy All Pet Eggs",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Egg].BuyAll = Value
			Core.QuickSave()
			Sync()
		end,
	})

	local EggData = require(Core.ReplicatedStorage.Data.PetEggData)
	local EggTable = {}
	for eggName, _ in pairs(EggData) do
		table.insert(EggTable, eggName)
	end
	table.sort(EggTable)
	buyEggSection:AddDropdown("EggList", {
		Title = "Pet Eggs",
		Values = EggTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Egg].Items = UI.GetSelectedItems(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	-- Traveling Merchant Items Section
	local BuyTravelingSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Traveling Merchant Items", false)
	BuyTravelingSection:AddToggle("buyTravelingEnable", {
		Title = "Buy Traveling Merchant Items",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Traveling].Enabled = Value
			if Value then
				local GetData_result = Core.DataService:GetData()
				local TravelingStock = GetData_result.TravelingMerchantShopStock.Stocks
				if not isTableEmpty(TravelingStock) then Shop.ProcessBuy(Shop.ShopKey.Traveling, TravelingStock) end
			end
			Core.QuickSave()
			Sync()
		end,
	})
	BuyTravelingSection:AddToggle("buyTravelingAll", {
		Title = "Buy All Traveling Merchant Items",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Traveling].BuyAll = Value
			Core.QuickSave()
			Sync()
		end,
	})
	local tCount = 1

	local function TravelSelected()
		local selected = {}
		for i = 1, tCount do -- Assuming max 10 traveling merchant types
			local dd = Options["TravelingList" .. i]
			if dd then
				local items = UI.GetSelectedItems(dd.Value)
				for _, item in ipairs(items) do
					table.insert(selected, item)
				end
			end
		end
		return selected
	end

	local TravelingData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData)
	local t = 1
	for Name, data in pairs(TravelingData) do
		local TravalTable = {}
		if type(data.ShopData) == "table" then
			for itemName, itemInfo in pairs(data.ShopData) do
				table.insert(TravalTable, itemName)
			end
		end
		BuyTravelingSection:AddDropdown("TravelingList" .. t, {
			Title = Name .. " Items",
			Values = TravalTable,
			Multi = true,
			Default = {},
			Searchable = true,
			Callback = function(Value)
				Shop.BuyList[Shop.ShopKey.Traveling].Items = TravelSelected()
				Core.QuickSave()
				Sync()
			end,
		})
		tCount = t
		t = t + 1
	end

	-- Event Shop Section (Santa's Stash)
	local BuySantaSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Santa's Stash Items", false)
	BuySantaSection:AddToggle("buySantaEnable", {
		Title = "Buy Santa's Stash Items",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Santa].Enabled = Value
			if Value then
				local GetData_result = Core.DataService:GetData()
				local SantaStocks = GetData_result.EventShopStock["Santa's Stash"].Stocks
				if not isTableEmpty(SantaStocks) then Shop.ProcessBuy(Shop.ShopKey.Santa, SantaStocks) end
			end
			Core.QuickSave()
			Sync()
		end,
	})
	BuySantaSection:AddToggle("buySantaAll", {
		Title = "Buy All Santa's Stash Items",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Santa].BuyAll = Value
			Core.QuickSave()
			Sync()
		end,
	})

	local EventData = require(Core.ReplicatedStorage.Data.EventShopData)
	local SantaTable = {}
	for itemName, _ in pairs(EventData["Santa's Stash"]) do
		table.insert(SantaTable, itemName)
	end
	table.sort(SantaTable)
	BuySantaSection:AddDropdown("SantaList", {
		Title = "Santa's Stash Items",
		Values = SantaTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.Santa].Items = UI.GetSelectedItems(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	-- Event Shop Section (New Years Shop)
	local BuyNewYearSection = Tabs.Buy:AddCollapsibleSection("Auto Buy New Years Shop Items", false)
	BuyNewYearSection:AddToggle("buyNewYearEnable", {
		Title = "Buy New Years Shop Items",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.NewYear].Enabled = Value
			if Value then
				local GetData_result = Core.DataService:GetData()
				local NewYearStocks = GetData_result.EventShopStock["New Years Shop"].Stocks
				if not isTableEmpty(NewYearStocks) then Shop.ProcessBuy(Shop.ShopKey.NewYear, NewYearStocks) end
			end
			Core.QuickSave()
			Sync()
		end,
	})
	BuyNewYearSection:AddToggle("buyNewYearAll", {
		Title = "Buy All New Years Shop Items",
		Default = false,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.NewYear].BuyAll = Value
			Core.QuickSave()
			Sync()
		end,
	})

	local NewYearTable = {}
	for itemName, _ in pairs(EventData["New Years Shop"]) do
		table.insert(NewYearTable, itemName)
	end
	table.sort(NewYearTable)
	BuyNewYearSection:AddDropdown("NewYearList", {
		Title = "New Years Shop Items",
		Values = NewYearTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Shop.BuyList[Shop.ShopKey.NewYear].Items = UI.GetSelectedItems(Value)
			Core.QuickSave()
			Sync()
		end,
	})
end

return Shop
