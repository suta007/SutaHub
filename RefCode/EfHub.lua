--!nocheck
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/suta007/Lua_EfHub/refs/heads/master/FluentData/Renewed/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()
local CollapsibleAddon = loadstring(game:HttpGet("https://raw.githubusercontent.com/suta007/Lua_EfHub/refs/heads/master/Core/CollapsibleSection.lua"))()

local Lighting = game:GetService("Lighting")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local DataStream = GameEvents:WaitForChild("DataStream")

local LocalPlayer = game:GetService("Players").LocalPlayer
local MyName = LocalPlayer.Name
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local VirtualUser = game:GetService("VirtualUser")

local Terrain = workspace.Terrain
local GiftMainFrame = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Gift_Notification"):WaitForChild("Frame")
local VirtualInputManager = game:GetService("VirtualInputManager")

local DataService = require(ReplicatedStorage.Modules.DataService)
local CollectEvent = ReplicatedStorage.GameEvents.Crops.Collect
local InventoryService = require(ReplicatedStorage.Modules.InventoryService)
local ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)

CollapsibleAddon(Fluent)

local fVersion = "2569.03.03-14.47"
local ActiveTasks = {}
local LogDisplay
local DevMode = false
local IsLoading = true
local AgeBreakRunning = false

local targetUUID
local Mutanting = false
local IsActivePet = false
local targetWidth = 1400
local targetHeight = 900
local IsScanning1, IsScanning2 = false, false
local FruitQueue1, FruitQueue2 = {}, {}
local currentMainPetUUID = nil
local SpecialHatchType = {}
local SellPetType = {}
local PlaceEggList = {}
local EggHatchList = {}
local isEggProcessing = false

-- =========================================================

local calculateCurrentWeight
local getInventoryList
local findMainPet, findDupePet
local processAgeBreakMachine
local ToggleTask
local SyncBackgroundTasks
local DevNoti
local GetPetUUID
local EquipPet
local UnequipPet
local SwapPetLoadout
local heldPet
local heldItemName
local heldItemUUID
local MakeMutant
local Mutation
local ClaimMutantPet
local QuickSave
local GetSelectedItems
local ApplyAntiLag
local DevLog
local ProcessBuy, GetMyFarm, AutoPlant, GetPosition, ScanFarmTask
local GetRawPetData, GetPetLevel, GetPetMutation, GetPetHunger, GetPetType
local GetPetHungerPercent, CheckMakeMutant, PetNightmare, GetPetBaseWeight
local GetEquippedPetsUUID, FindFruitInv, FeedPet
local MakePetFavorite, GetPetFavorite --, MakePetUnfavorite
local AutoSellAll, PickFinishPet
local HardCoreBuy
local CheckFruit, CheckFruit1, CheckFruit2
local CollectFruitWorker1, CollectFruitWorker2 = nil, nil
local PlaceEggs, HatchEgg, SellPetEgg
local getBoundary, getPlate, ValidEggs, EggInFarm, IsValidSellPet, ScanSellPet
local ShovelPlant, Reclaim --, Trowel, ShovelCosmetic, ShovelCrop

local isPlantHidden, isFruitHidden = false, false
local GetPlantsFolder, IsFruit, SetVisibility, HidePlant, HideFruit, SetupTracker

local ShopKey = {
	Seed = "ROOT/SeedStocks/Shop/Stocks",
	Daily = "ROOT/SeedStocks/Daily Deals/Stocks",
	Gear = "ROOT/GearStock/Stocks",
	Egg = "ROOT/PetEggStock/Stocks",
	Santa = "ROOT/EventShopStock/Santa's Stash/Stocks",
	NewYear = "ROOT/EventShopStock/New Years Shop/Stocks",
	Traveling = "ROOT/TravelingMerchantShopStock/Stocks",
}

local BuyList = {
	[ShopKey.Seed] = {
		Enabled = false,
		BuyAll = false,
		Items = {},
		RemoteName = "BuySeedStock",
		ArgType = "SeedMode",
	},
	[ShopKey.Daily] = {
		Enabled = true,
		BuyAll = true,
		Items = {},
		RemoteName = "BuyDailySeedShopStock",
		ArgType = "NormalMode",
	},
	[ShopKey.Gear] = {
		Enabled = false,
		BuyAll = false,
		Items = {},
		RemoteName = "BuyGearStock",
		ArgType = "NormalMode",
	},
	[ShopKey.Egg] = {
		Enabled = false,
		BuyAll = false,
		Items = {},
		RemoteName = "BuyPetEgg",
		ArgType = "NormalMode",
	},
	[ShopKey.Traveling] = {
		Enabled = false,
		BuyAll = false,
		Items = {},
		RemoteName = "BuyTravelingMerchantShopStock",
		ArgType = "NormalMode",
	},
	[ShopKey.Santa] = {
		Enabled = false,
		BuyAll = false,
		Items = {},
		RemoteName = "BuyEventShopStock",
		ArgType = "EventMode",
		EventArg = "Santa's Stash",
	},
	[ShopKey.NewYear] = {
		Enabled = false,
		BuyAll = false,
		Items = {},
		RemoteName = "BuyEventShopStock",
		ArgType = "EventMode",
		EventArg = "New Years Shop",
	},
}

local function isTableEmpty(t)
	return type(t) ~= "table" or next(t) == nil
end

local RemoteCache = {}

ProcessBuy = function(ShopKey, StockData)
	local Setting = BuyList[ShopKey]
	if not Setting or not Setting.Enabled then return end
	local Remote = RemoteCache[Setting.RemoteName]
	if not Remote then
		Remote = GameEvents:FindFirstChild(Setting.RemoteName)
		if Remote then RemoteCache[Setting.RemoteName] = Remote end
	end

	for itemId, itemInfo in pairs(StockData) do
		local ItemName = itemInfo.EggName or itemId
		local StockAmount = tonumber(itemInfo.Stock) or 0
		local BuyEnabled = false
		local StockInfo = string.format("Found %s : %s", ItemName, StockAmount)
		DevNoti(StockInfo)
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

			local LogMessage = string.format("Bought %s : %s", ItemName, StockAmount)
			DevNoti(LogMessage)
		end
	end
end

local Window = Fluent:CreateWindow({
	Title = "Grow a Garden " .. fVersion,
	SubTitle = "by EfHub",
	TabWidth = 100,
	Size = UDim2.fromOffset(targetWidth, targetHeight),
	Resize = true,
	MinSize = Vector2.new(580, 460),
	Acrylic = true,
	Theme = "Darker",
	MinimizeKey = Enum.KeyCode.RightControl,
})

local Tabs = {
	Main = Window:AddTab({ Title = "Main", Icon = "house" }),
	Buy = Window:AddTab({ Title = "Buy", Icon = "shopping-cart" }),
	Pet = Window:AddTab({ Title = "Pet", Icon = "bone" }),
	Farm = Window:AddTab({ Title = "Farm", Icon = "tree-pine" }),
	Auto = Window:AddTab({ Title = "Automatic", Icon = "bot" }),
	Event = Window:AddTab({ Title = "Event", Icon = "calendar" }),
	Log = Window:AddTab({ Title = "Console", Icon = "terminal" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}
local Options = Fluent.Options

DevNoti = function(content)
	if DevMode then
		--[[         Fluent:Notify({
            Title = "EfHub - Dev Mode",
            Content = content,
            Duration = 5
        }) ]]
		DevLog(content)
	end
end

GetSelectedItems = function(DropdownValue)
	local Items = {}
	if type(DropdownValue) == "table" then
		for Value, State in pairs(DropdownValue) do
			if State then table.insert(Items, Value) end
		end
	end
	return Items
end

Window:SelectTab(1)

------------------------------------------------------
local ToggleGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")

ToggleGui.Name = "EfHub_Toggle"
ToggleGui.Parent = game:GetService("CoreGui")
ToggleGui.ResetOnSpawn = false

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ToggleGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(101, 1, 1)
ToggleButton.Position = UDim2.new(0, 10, 0.5, 0)
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Text = "EfHub"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 25)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
	pcall(function()
		if Window.GUI then
			Window.GUI.Enabled = not Window.GUI.Enabled
		elseif Window.Instance then
			Window.Instance.Enabled = not Window.Instance.Enabled
		elseif Window.Root then
			Window.Root.Visible = not Window.Root.Visible
		end
	end)
end)

Tabs.Main:AddButton({
	Title = "Anti Lag",
	Callback = function()
		pcall(function()
			ApplyAntiLag()
		end)
	end,
})

Tabs.Main:AddToggle("FruitToggle", {
	Title = "Hide Fruits",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if HideFruit then HideFruit(Value) end
	end,
})

Tabs.Main:AddToggle("PlantToggle", {
	Title = "Hide Plants",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if HidePlant then HidePlant(Value) end
	end,
})

local HardCoreSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Hardcore", false)
HardCoreSection:AddToggle("HardCoreBuyEnable", {
	Title = "Buy Hardcore",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
HardCoreSection:AddInput("HardCoreDelay", {
	Title = "Delay (Seconds)",
	Default = 0.3,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

local BuySeedSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Seeds", false)

BuySeedSection:AddToggle("buySeedEnable", {
	Title = "Buy Seeds",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Seed].Enabled = Value
		if Value then
			local GetData_result = DataService:GetData()
			local SeedStocks = GetData_result.SeedStocks.Shop.Stocks
			if not isTableEmpty(SeedStocks) then ProcessBuy(ShopKey.Seed, SeedStocks) end
		end
		if QuickSave then QuickSave() end
	end,
})
BuySeedSection:AddToggle("buySeedAll", {
	Title = "Buy All Seeds",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Seed].BuyAll = Value
		if QuickSave then QuickSave() end
	end,
})

local SeedData = require(game:GetService("ReplicatedStorage").Data.SeedShopData)
local SeedTable = {}
for seedName, seedInfo in pairs(SeedData) do
	table.insert(SeedTable, seedName)
end
table.sort(SeedTable)
BuySeedSection:AddDropdown("SeedList", {
	Title = "Seeds",
	Description = "Select seeds to buy",
	Values = SeedTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		BuyList[ShopKey.Seed].Items = GetSelectedItems(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Buy Daily Deal Section ]]
local BuyDailySection = Tabs.Buy:AddCollapsibleSection("Auto Buy Daily Seed", false)
BuyDailySection:AddToggle("buyDailyEnable", {
	Title = "Buy Daily Seed",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Daily].Enabled = Value
		if Value then
			local GetData_result = DataService:GetData()
			local DailyStocks = GetData_result.SeedStocks["Daily Deals"].Stocks
			if not isTableEmpty(DailyStocks) then ProcessBuy(ShopKey.Daily, DailyStocks) end
		end
		if QuickSave then QuickSave() end
	end,
})
BuyDailySection:AddToggle("buyDailyAll", {
	Title = "Buy All Daily Seed",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Daily].BuyAll = Value
		if QuickSave then QuickSave() end
	end,
})

--[[ Buy Gear Section]]
local buyGearSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Gear", false)
buyGearSection:AddToggle("buyGearEnable", {
	Title = "Buy Gear",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Gear].Enabled = Value
		if Value then
			local GetData_result = DataService:GetData()
			local GearStock = GetData_result.GearStock.Stocks
			if not isTableEmpty(GearStock) then ProcessBuy(ShopKey.Gear, GearStock) end
		end
		if QuickSave then QuickSave() end
	end,
})
buyGearSection:AddToggle("buyGearAll", {
	Title = "Buy All Gear",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Gear].BuyAll = Value
		if QuickSave then QuickSave() end
	end,
})
local GearData = require(game:GetService("ReplicatedStorage").Data.GearShopData)
local GearTable = {}
for gearName, gearInfo in pairs(GearData["Gear"]) do
	table.insert(GearTable, gearName)
end
table.sort(GearTable)
buyGearSection:AddDropdown("GearList", {
	Title = "Gear",
	Description = "Select gear to buy",
	Values = GearTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		BuyList[ShopKey.Gear].Items = GetSelectedItems(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Buy Pet Section]]
local buyEggSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Pet Eggs", false)
buyEggSection:AddToggle("buyEggEnable", {
	Title = "Buy Pet Eggs",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Egg].Enabled = Value
		if Value then
			local GetData_result = DataService:GetData()
			local EggStock = GetData_result.PetEggStock.Stocks
			if not isTableEmpty(EggStock) then ProcessBuy(ShopKey.Egg, EggStock) end
		end
		if QuickSave then QuickSave() end
	end,
})
buyEggSection:AddToggle("buyEggAll", {
	Title = "Buy All Pet Eggs",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Egg].BuyAll = Value
		if QuickSave then QuickSave() end
	end,
})
local EggData = require(game:GetService("ReplicatedStorage").Data.PetEggData)
local EggTable = {}
for eggName, eggInfo in pairs(EggData) do
	table.insert(EggTable, eggName)
end
table.sort(EggTable)
buyEggSection:AddDropdown("EggList", {
	Title = "Pet Eggs",
	Description = "Select pet eggs to buy",
	Values = EggTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		BuyList[ShopKey.Egg].Items = GetSelectedItems(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Buy Traveling Merchant Items Section]]
local BuyTravelingSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Traveling Merchant Items", false)
BuyTravelingSection:AddToggle("buyTravelingEnable", {
	Title = "Buy Traveling Merchant Items",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Traveling].Enabled = Value
		if Value then
			local GetData_result = DataService:GetData()
			local TravelingStock = GetData_result.TravelingMerchantShopStock.Stocks
			if not isTableEmpty(TravelingStock) then ProcessBuy(ShopKey.Traveling, TravelingStock) end
		end
		if QuickSave then QuickSave() end
	end,
})
BuyTravelingSection:AddToggle("buyTravelingAll", {
	Title = "Buy All Traveling Merchant Items",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Traveling].BuyAll = Value
		if QuickSave then QuickSave() end
	end,
})

local TravelingList = {}
local function TravelSelected(DropdownValue)
	if type(DropdownValue) == "table" then
		for Value, State in pairs(DropdownValue) do
			if State then table.insert(TravelingList, Value) end
		end
	end
	return TravelingList
end

local TravelingData = require(game:GetService("ReplicatedStorage").Data.TravelingMerchant.TravelingMerchantData)
local Traval = {}

local t = 1
for Name, data in pairs(TravelingData) do
	local TravalTable = {}
	if type(data.ShopData) == "table" then
		for itemName, itemInfo in pairs(data.ShopData) do
			table.insert(TravalTable, itemName)
		end
	end
	Traval[t] = BuyTravelingSection:AddDropdown("TravelingList" .. t, {
		Title = Name .. " Items",
		Description = "Select items to buy",
		Values = TravalTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			BuyList[ShopKey.Traveling].Items = TravelSelected(Value)
			if QuickSave then QuickSave() end
		end,
	})
	t = t + 1
end

--[[ Buy Event Shop Items Section]]

--[[ Buy Santa's Stash Section]]
local BuySantaSection = Tabs.Buy:AddCollapsibleSection("Auto Buy Santa's Stash Items", false)
BuySantaSection:AddToggle("buySantaEnable", {
	Title = "Buy Santa's Stash Items",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Santa].Enabled = Value
		if Value then
			local GetData_result = DataService:GetData()
			local SantaStocks = GetData_result.EventShopStock["Santa's Stash"].Stocks
			if not isTableEmpty(SantaStocks) then ProcessBuy(ShopKey.Santa, SantaStocks) end
		end
		if QuickSave then QuickSave() end
	end,
})
BuySantaSection:AddToggle("buySantaAll", {
	Title = "Buy All Santa's Stash Items",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.Santa].BuyAll = Value
		if QuickSave then QuickSave() end
	end,
})

local EventData = require(game:GetService("ReplicatedStorage").Data.EventShopData)
local SantaTable = {}
for itemName, itemInfo in pairs(EventData["Santa's Stash"]) do
	table.insert(SantaTable, itemName)
end
table.sort(SantaTable)
BuySantaSection:AddDropdown("SantaList", {
	Title = "Santa's Stash Items",
	Description = "Select items to buy",
	Values = SantaTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		BuyList[ShopKey.Santa].Items = GetSelectedItems(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Buy New Years Shop Items Section]]
local BuyNewYearSection = Tabs.Buy:AddCollapsibleSection("Auto Buy New Years Shop Items", false)
BuyNewYearSection:AddToggle("buyNewYearEnable", {
	Title = "Buy New Years Shop Items",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.NewYear].Enabled = Value
		if Value then
			local GetData_result = DataService:GetData()
			local NewYearStocks = GetData_result.EventShopStock["New Years Shop"].Stocks
			if not isTableEmpty(NewYearStocks) then ProcessBuy(ShopKey.NewYear, NewYearStocks) end
		end
		if QuickSave then QuickSave() end
	end,
})
BuyNewYearSection:AddToggle("buyNewYearAll", {
	Title = "Buy All New Years Shop Items",
	Default = false,
	Callback = function(Value)
		BuyList[ShopKey.NewYear].BuyAll = Value
		if QuickSave then QuickSave() end
	end,
})
local NewYearTable = {}
for itemName, itemInfo in pairs(EventData["New Years Shop"]) do
	table.insert(NewYearTable, itemName)
end
table.sort(NewYearTable)
BuyNewYearSection:AddDropdown("NewYearList", {
	Title = "New Years Shop Items",
	Description = "Select items to buy",
	Values = NewYearTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		BuyList[ShopKey.NewYear].Items = GetSelectedItems(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Auto Pet Tab]]
local PetWorkSection = Tabs.Pet:AddCollapsibleSection("Pet Farming", false)
PetWorkSection:AddDropdown("PetMode", {
	Title = "Pet Mode",
	Description = "Select Pet Mode",
	Values = { "Nightmare", "Elephant", "Mutant", "Level" },
	Multi = false,
	Default = "Nightmare",
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
PetWorkSection:AddToggle("PetModeEnable", {
	Title = "Enable Pet Farm",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
		if Value then
			task.wait(1)
			Mutation()
		end
	end,
})
local PetData = require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetList)
local PetTable = {}
local HungerTable = {}
for petName, petInfo in pairs(PetData) do
	table.insert(PetTable, petName)
	HungerTable[petName] = petInfo["DefaultHunger"]
end
table.sort(PetTable)
PetWorkSection:AddDropdown("TargetPetDropdown", {
	Title = "Target Pet",
	Description = "Select Target Pet for Farming",
	Values = PetTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

PetWorkSection:AddToggle("UseFavoriteOnly", {
	Title = "Use Favorite Pet Only",
	Description = "Use Favorite Pet Only",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

local MutantData = require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetMutationRegistry)
local MutantTable = {}
local EnumToNameCache = {}
for mutantName, mutantInfo in pairs(MutantData["PetMutationRegistry"]) do
	if type(mutantInfo) == "table" and mutantInfo.EnumId then
		table.insert(MutantTable, mutantName)
		EnumToNameCache[mutantInfo.EnumId] = mutantName
	end
end

table.sort(MutantTable)
PetWorkSection:AddDropdown("TargetMutantDropdown", {
	Title = "Target Mutant",
	Description = "Select Target Mutant for Farming",
	Values = MutantTable,
	Multi = false,
	Default = "",
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

-- make input for age limit just integer only bestween 0 - 100
PetWorkSection:AddInput("AgeLimitInput", {
	Title = "Age Limit",
	Description = "Enter age limit (0-100)",
	Placeholder = "Enter age limit",
	Filter = "Number",
	Default = 50,
	Callback = function(Value)
		local numValue = tonumber(Value) or 101
		if numValue < 0 or numValue > 100 then
			numValue = 50
			Options.AgeLimitInput:SetValue(numValue)
		end
		if QuickSave then QuickSave() end
	end,
})

PetWorkSection:AddInput("LoadOutDelay", {
	Title = "Loadout Switch Delay time",
	Description = "Enter delay time in seconds",
	Placeholder = "Enter delay time",
	Filter = "Number",
	Default = 10,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

PetWorkSection:AddDropdown("LevelSlots", {
	Title = "Select Loadout",
	Values = { 1, 2, 3, 4, 5, 6 },
	Default = 1,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

PetWorkSection:AddDropdown("TimeSlots", {
	Title = "Select Time Slot",
	Values = { 1, 2, 3, 4, 5, 6 },
	Default = 2,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

PetWorkSection:AddDropdown("MutantSlots", {
	Title = "Select Mutant Slot",
	Values = { 1, 2, 3, 4, 5, 6 },
	Default = 3,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

local AutoAgeBreakSection = Tabs.Pet:AddCollapsibleSection("Auto Age Break")

AutoAgeBreakSection:AddToggle("AAB_Enabled", {
	Title = "Enable Auto Age Break",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

AutoAgeBreakSection:AddDropdown("AAB_PetType", {
	Title = "Select Pet Type",
	Values = PetTable,
	Default = "",
	Multi = false,
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

AutoAgeBreakSection:AddInput("AAB_TargetAge", {
	Title = "Target Break Age",
	Description = "Min: 101, Max: 125",
	Default = 125,
	Numeric = true,
	Finished = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

AutoAgeBreakSection:AddToggle("AAB_CheckWeight", {
	Title = "Check Dupe Weight?",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
AutoAgeBreakSection:AddDropdown("AAB_WeightCond", {
	Title = "Weight Condition",
	Values = { "<=", ">=" },
	Default = "<=",
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
AutoAgeBreakSection:AddInput("AAB_WeightVal", {
	Title = "Dupe Weight Value",
	Default = 10,
	Numeric = true,
	Finished = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

AutoAgeBreakSection:AddToggle("AAB_CheckAge", {
	Title = "Check Dupe Age?",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
AutoAgeBreakSection:AddDropdown("AAB_AgeCond", {
	Title = "Age Condition",
	Values = { "<=", ">=" },
	Default = "<=",
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
AutoAgeBreakSection:AddInput("AAB_AgeVal", {
	Title = "Dupe Age Value",
	Default = 30,
	Numeric = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

local PetFeedSection = Tabs.Pet:AddCollapsibleSection("Pet Feeding", false)

PetFeedSection:AddToggle("AutoFeedPet", {
	Title = "Auto Feed",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

PetFeedSection:AddToggle("AllowAllFood", {
	Title = "Allow All Food",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
local FruitData = require(game:GetService("ReplicatedStorage").Data.SeedData)
local FruitTable = {}
for FruitName, FruitInfo in pairs(FruitData) do
	table.insert(FruitTable, FruitName)
end
table.sort(FruitTable)

PetFeedSection:AddDropdown("AllowFoodType", {
	Title = "Allow Food Type",
	Values = FruitTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
PetFeedSection:AddSlider("PetHungerPercent", {
	Title = "Pet Hunger Percent",
	Min = 1,
	Max = 100,
	Default = 80,
	Rounding = 1,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

-- Auto Accept Pet gift
local PetGiftSection = Tabs.Pet:AddCollapsibleSection("Auto Accept Pet gift", false)

PetGiftSection:AddToggle("tgAcceptPetGift", {
	Title = "Enable Auto Accept",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

PetGiftSection:AddInput("inPetGiftDelay", {
	Title = "Accept Delay (s)",
	Description = "Delay between accept checks",
	Filter = "Number",
	Default = 0.1,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

local HatchSection = Tabs.Pet:AddCollapsibleSection("Auto Hatch Eggs", false)

HatchSection:AddToggle("tgPlaceEggsEn", {
	Title = "Place Eggs",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
		isEggProcessing = false
	end,
})

local AllPetEggs = require(ReplicatedStorage.Data.PetRegistry.PetEggs)
local AllEggTable = {}
for EggName, v in pairs(AllPetEggs) do
	table.insert(AllEggTable, EggName)
end
HatchSection:AddDropdown("ddPlaceEgg", {
	Title = "Select Eggs",
	Values = AllEggTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if GetSelectedItems then PlaceEggList = GetSelectedItems(Value) end
	end,
})

HatchSection:AddInput("ipMaxEggs", {
	Title = "Max Eggs",
	Default = 3,
	Numeric = true,
	Finished = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddDropdown("ddSpeedEggSlot", {
	Title = "Select Speed Loadout",
	Values = { 1, 2, 3, 4, 5, 6 },
	Default = 1,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddInput("ipPlaceEggDelay", {
	Title = "Place Eggs Delay",
	Default = 0.2,
	Numeric = true,
	Finished = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddDivider()

HatchSection:AddToggle("tgAutoHatchEn", {
	Title = "Auto Hatch",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
		isEggProcessing = false
	end,
})
local tempTable = { "ALL" }
table.move(AllEggTable, 1, #AllEggTable, 2, tempTable)
HatchSection:AddDropdown("ddEggHatch", {
	Title = "Select Egg to Hatch",
	Values = tempTable,
	Multi = true,
	Default = { "ALL" },
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if GetSelectedItems then EggHatchList = GetSelectedItems(Value) end
	end,
})

HatchSection:AddDropdown("ddHatchSlot", {
	Title = "Select Hatch Loadout",
	Values = { 1, 2, 3, 4, 5, 6 },
	Default = 2,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddInput("ipHatchDelay", {
	Title = "Hatch Egg Delay",
	Default = 0.2,
	Numeric = true,
	Finished = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddInput("ipSpecialHatchWeight", {
	Title = "Special Hatch Weight",
	Description = "Special Hatch if Weight above (0 = disable)",
	Default = 0,
	Numeric = true,
	Finished = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddDropdown("ddSpecialHatchType", {
	Title = "Special Hatch Pet",
	Values = PetTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if GetSelectedItems then SpecialHatchType = GetSelectedItems(Value) end
	end,
})

HatchSection:AddDropdown("ddSpecialHatchSlot", {
	Title = "Select Hatch Loadout",
	Values = { 1, 2, 3, 4, 5, 6 },
	Default = 4,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddDivider()

HatchSection:AddToggle("tgSellPetEn", {
	Title = "Auto Sell Pet",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
		isEggProcessing = false
	end,
})

HatchSection:AddDropdown("ddSellPetSlot", {
	Title = "Select Sell Pet Loadout",
	Values = { 1, 2, 3, 4, 5, 6 },
	Default = 3,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddDropdown("ddSellPetType", {
	Title = "Sell Pet Type",
	Values = PetTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if GetSelectedItems then SellPetType = GetSelectedItems(Value) end
	end,
})

HatchSection:AddDropdown("ddSellMode", {
	Title = "Sell Pet Mode",
	Values = { "ALL", "White list", "Black list" },
	Default = "White list",
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddInput("ipSellWeight", {
	Title = "Sell Pet Weight",
	Description = "(0 = disable)",
	Default = 0,
	Numeric = true,
	Finished = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddDropdown("ddSellWeightMode", {
	Title = "Sell Weight Mode",
	Values = { "Below", "Above" },
	Default = "Below",
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

HatchSection:AddToggle("tgSellMutantPet", {
	Title = "Sell Mutant Pet",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
HatchSection:AddInput("ipSellPetDelay", {
	Title = "Sell Pet Delay",
	Default = 0.2,
	Numeric = true,
	Finished = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Farm Section]]

local SellFruitSection = Tabs.Farm:AddCollapsibleSection("Sell Fruit", false)
SellFruitSection:AddToggle("tgAutoSellALL", {
	Title = "Auto Sell ALL",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})
SellFruitSection:AddToggle("AutoSellFruit", {
	Title = "Auto Sell Fruit",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

local CollectDelay = 0.3

local CheckFruitType = false
local FruitType = {}
local ExcludeFruitType = false

local CheckMutant = false
local MutantType = {}
local ExceptMutant = false

local CheckVariant = false
local VariantType = "Normal"
local ExceptVariant = false

local CheckWeight = false
local WeightType = "Below"
local WeightValue = 100

local CollectSection = Tabs.Farm:AddCollapsibleSection("Collect Fruit", false)
CollectSection:AddToggle("tgCollectFruitEnable", {
	Title = "Enable Auto Collect Fruit ",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

CollectSection:AddInput("inCollectDelay", {
	Title = "Collect Delay",
	Default = 0.3,
	Min = 0.1,
	Max = 3600,
	Callback = function(Value)
		CollectDelay = tonumber(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection:AddDivider()
CollectSection:AddToggle("tgCheckFruitType", {
	Title = "Check Fruit Type",
	Default = false,
	Callback = function(Value)
		CheckFruitType = Value
		if QuickSave then QuickSave() end
	end,
})

CollectSection:AddDropdown("ddFruitType", {
	Title = "Fruit Type",
	Values = FruitTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		FruitType = GetSelectedItems(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection:AddToggle("tgExcludeFruitType", {
	Title = "Exclude Fruit Type",
	Default = false,
	Callback = function(Value)
		ExcludeFruitType = Value
		if QuickSave then QuickSave() end
	end,
})

CollectSection:AddDivider()

CollectSection:AddToggle("tgCheckMutant", {
	Title = "Check Mutant",
	Default = false,
	Callback = function(Value)
		CheckMutant = Value
		if QuickSave then QuickSave() end
	end,
})

local MutationData = DataService:GetData().GardenGuide.MutationData
local MutationTable = {}
for MutationName, MutationInfo in pairs(MutationData) do
	table.insert(MutationTable, MutationName)
end

CollectSection:AddDropdown("ddMutantType", {
	Title = "Mutant Type",
	Values = MutationTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		MutantType = GetSelectedItems(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection:AddToggle("tgExceptMutant", {
	Title = "Except Mutant",
	Default = false,
	Callback = function(Value)
		ExceptMutant = Value
		if QuickSave then
		end
	end,
})
CollectSection:AddDivider()

CollectSection:AddToggle("tgCheckVariant", {
	Title = "Check Variant",
	Default = false,
	Callback = function(Value)
		CheckVariant = Value
		if QuickSave then QuickSave() end
	end,
})

CollectSection:AddDropdown("ddVariantType", {
	Title = "Variant Type",
	Values = { "Normal", "Silver", "Gold", "Rainbow", "Diamond" },
	Multi = false,
	Default = "Normal",
	Callback = function(Value)
		VariantType = Value
		if QuickSave then QuickSave() end
	end,
})

CollectSection:AddToggle("tgExceptVariant", {
	Title = "Except Variant",
	Default = false,
	Callback = function(Value)
		ExceptVariant = Value
		if QuickSave then QuickSave() end
	end,
})

CollectSection:AddDivider()

CollectSection:AddToggle("tgCheckWeight", {
	Title = "Check Weight",
	Default = false,
	Callback = function(Value)
		CheckWeight = Value
		if QuickSave then QuickSave() end
	end,
})
CollectSection:AddDropdown("ddWeightType", {
	Title = "Weight Type",
	Values = { "Above", "Below" },
	Multi = false,
	Default = "Below",
	Callback = function(Value)
		WeightType = Value
		if QuickSave then QuickSave() end
	end,
})
CollectSection:AddInput("ipWeightValue", {
	Title = "Weight Value",
	Default = "100",
	Numeric = true,
	Finished = false,
	Callback = function(Value)
		WeightValue = tonumber(Value) or 100
		if QuickSave then QuickSave() end
	end,
})
-- Collect2
local CollectSection2 = Tabs.Farm:AddCollapsibleSection("Collect Fruit 2", false)
CollectSection2:AddToggle("tgCollectFruitEnable2", {
	Title = "Enable Auto Collect Fruit ",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

CollectSection2:AddInput("inCollectDelay2", {
	Title = "Collect Delay",
	Default = 0.3,
	Min = 0.1,
	Max = 3600,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection2:AddDivider()
CollectSection2:AddToggle("tgCheckFruitType2", {
	Title = "Check Fruit Type",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection2:AddDropdown("ddFruitType2", {
	Title = "Fruit Type",
	Values = FruitTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection2:AddToggle("tgExcludeFruitType2", {
	Title = "Exclude Fruit Type",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection2:AddDivider()
--CheckMutant
CollectSection2:AddToggle("tgCheckMutant2", {
	Title = "Check Mutant",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection2:AddDropdown("ddMutantType2", {
	Title = "Mutant Type",
	Values = MutationTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

-- ExceptMutant
CollectSection2:AddToggle("tgExceptMutant2", {
	Title = "Except Mutant",
	Default = false,
	Callback = function(Value)
		if QuickSave then
		end
	end,
})
CollectSection2:AddDivider()

CollectSection2:AddToggle("tgCheckVariant2", {
	Title = "Check Variant",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection2:AddDropdown("ddVariantType2", {
	Title = "Variant Type",
	Values = { "Normal", "Silver", "Gold", "Rainbow", "Diamond" },
	Multi = false,
	Default = "Normal",
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection2:AddToggle("tgExceptVariant2", {
	Title = "Except Variant",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

CollectSection2:AddDivider()

CollectSection2:AddToggle("tgCheckWeight2", {
	Title = "Check Weight",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
CollectSection2:AddDropdown("ddWeightType2", {
	Title = "Weight Type",
	Values = { "Above", "Below" },
	Multi = false,
	Default = "Below",
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
CollectSection2:AddInput("ipWeightValue2", {
	Title = "Weight Value",
	Default = "100",
	Numeric = true,
	Finished = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

local PlantSection = Tabs.Farm:AddCollapsibleSection("Plant Fruit", false)
PlantSection:AddToggle("tgPlantFruitEnable", {
	Title = "Plant Fruit",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

PlantSection:AddDropdown("ddPlantFruitType", {
	Title = "Seed to Plant",
	Values = FruitTable,
	Multi = false,
	Default = "",
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

PlantSection:AddDropdown("ddPlantPosition", {
	Title = "Plant Position",
	Values = { "User Position" },
	Multi = false,
	Default = "",
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

--delay
PlantSection:AddInput("inPlantDelay", {
	Title = "Plant Delay (ms)",
	Default = "0.3",
	Numeric = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Automatic Section In Automatic tab]]
local ShovelSection = Tabs.Auto:AddCollapsibleSection("Shovel", false)

ShovelSection:AddToggle("tgAutoPlantShovel", {
	Title = "Auto Plant Shovel",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

local tempShovelDD = { "ALL" }
table.move(FruitTable, 1, #FruitTable, 2, tempShovelDD)

ShovelSection:AddDropdown("ddShovelPlant", {
	Title = "Select Plant(s) to Shovel",
	Values = tempShovelDD,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

ShovelSection:AddDivider()

ShovelSection:AddToggle("tgAutoCropShovel", {
	Title = "Auto Crop Shovel",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

ShovelSection:AddDropdown("ddShovelCrop", {
	Title = "Select Crop(s) to Shovel",
	Values = tempShovelDD,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Add a lot of Fruit Shovel Conditions ]]
ShovelSection:AddDivider()

--[[ Shovel Cosmetic]]
ShovelSection:AddToggle("tgShovelCosmetic", {
	Title = "Shovel All Cosmetic",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

local ReclaimSection = Tabs.Auto:AddCollapsibleSection("Reclaim", false)
ReclaimSection:AddToggle("tgReclaim", {
	Title = "Reclaim",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

ReclaimSection:AddDropdown("ddReclaim", {
	Title = "Reclaim Type",
	Values = tempShovelDD,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Trowel Section ]]
local TrowelSection = Tabs.Auto:AddCollapsibleSection("Trowel", false)
TrowelSection:AddToggle("tgTrowel", {
	Title = "Trowel",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

TrowelSection:AddDropdown("ddTrowel", {
	Title = "Trowel Type",
	Values = tempShovelDD,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

--[[ Event Section ]]

local AlienEventSection = Tabs.Event:AddCollapsibleSection("Alien Event", false)
AlienEventSection:AddToggle("tgAlienEventEnable", {
	Title = "Alien Event Enable",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

AlienEventSection:AddDropdown("ddAlienLoadout", {
	Title = "Alien Event Type",
	Values = { 1, 2, 3, 4, 5, 6 },
	Default = 6,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

AlienEventSection:AddDropdown("ddAlienPet", {
	Title = "Alien Pet",
	Values = PetTable,
	Multi = true,
	Default = {},
	Searchable = true,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

AlienEventSection:AddDropdown("ddAlienMaxPet", {
	Title = "Alien Max Pet",
	Values = { 1, 2, 3, 4, 5, 6, 7, 8 },
	Default = 3,
	Multi = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
AlienEventSection:AddDivider()

AlienEventSection:AddToggle("tgAlienAutoClaim", {
	Title = "Alien Auto Claim",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

AlienEventSection:AddToggle("tgAlienAutoHatch", {
	Title = "Alien Auto Hatch",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})
AlienEventSection:AddDivider()
AlienEventSection:AddToggle("tgAlienDefaultPetMode", {
	Title = "Default Pet Mode",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
AlienEventSection:AddToggle("tgAlienDefaultPlaceEggs", {
	Title = "Default Place Eggs",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
AlienEventSection:AddToggle("tgAlienDefaultHatchEggs", {
	Title = "Default Hatch Eggs",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})
AlienEventSection:AddToggle("tgAlienDefaultSellPets", {
	Title = "Default Sell Pets",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
	end,
})

AlienEventSection:AddToggle("tgAutoGiftAlien", {
	Title = "Auto Gift Alien Pet",
	Default = false,
	Callback = function(Value)
		if QuickSave then QuickSave() end
		if SyncBackgroundTasks then SyncBackgroundTasks() end
	end,
})

--[[ Log Section ]]

local MaxLines = 100
local DisplayTable = {}
local IsUpdateScheduled = false

Tabs.Log:AddButton({
	Title = "Clear Logs",
	Callback = function()
		DisplayTable = {}
		if LogDisplay then LogDisplay:SetValue("") end
	end,
})

LogDisplay = Tabs.Log:CreateParagraph("MyConsole", {
	Title = "Recent Logs",
	Content = "System initialized...",
})

local function FlushLogUpdates()
	if LogDisplay then pcall(function()
		LogDisplay:SetValue(table.concat(DisplayTable, "\n"))
	end) end
	IsUpdateScheduled = false
end

local function AddLog(message)
	local entry = string.format("[%s] %s", os.date("%X"), message)

	table.insert(DisplayTable, entry)
	if #DisplayTable > MaxLines then table.remove(DisplayTable, 1) end

	if not IsUpdateScheduled then
		IsUpdateScheduled = true
		task.delay(0.3, FlushLogUpdates)
	end
end

local function InfoLog(message)
	AddLog("📋 " .. message)
end

local function WarnLog(message)
	AddLog("⚠️ " .. message)
end

local function ErrorLog(message)
	AddLog("❌ " .. message)
end

local function SuccessLog(message)
	AddLog("✅ " .. message)
end

DevLog = function(message)
	AddLog("💻 " .. message)
end

--[[
 SaveManager and InterfaceManager Setup
]]
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("EfHub")
SaveManager:SetFolder("EfHub/GAG")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

--[[
 Quick Save Function
]]
QuickSave = function()
	if not IsLoading then SaveManager:Save("EfHub") end
end

task.spawn(function()
	while not SaveManager.Options.SaveManager_ConfigList do
		task.wait()
	end
	SaveManager.Options.SaveManager_ConfigList:SetValue("EfHub")
	SaveManager:Load("EfHub")
	task.wait(1)
	IsLoading = false
	if SyncBackgroundTasks then SyncBackgroundTasks() end
	Fluent:Notify({
		Title = "EfHub",
		Content = "Settings loaded automatically",
		Duration = 3,
	})
end)

--[[
 Auto Buy System
]]

GetMyFarm = function()
	local farmFolder = workspace:FindFirstChild("Farm")
	if not farmFolder then return nil end
	for _, oFarm in pairs(farmFolder:GetChildren()) do
		local success, owner = pcall(function()
			return oFarm.Important.Data.Owner.Value
		end)

		if success and owner == MyName then return oFarm end
	end
	return nil
end

local MyFarm = GetMyFarm()
local FarmPoint
if MyFarm then
	if MyFarm:FindFirstChild("Spawn_Point") then FarmPoint = MyFarm.Spawn_Point.CFrame end
end

GetPlantsFolder = function()
	local Farm_Important = MyFarm:FindFirstChild("Important")
	return Farm_Important and Farm_Important:FindFirstChild("Plants_Physical")
end

GetEquippedPetsUUID = function()
	local GetData_result = DataService:GetData()
	local EquippedPets = GetData_result.PetsData.EquippedPets or {}
	local UUIDtbl = {}
	for _, uuid in pairs(EquippedPets) do
		if uuid then table.insert(UUIDtbl, uuid) end
	end
	return UUIDtbl
end

GetRawPetData = function(uuid)
	local success, result = pcall(function()
		return ActivePetsService:GetPetData(LocalPlayer.Name, uuid)
	end)

	if success and result then return result end
	return nil
end

GetPetLevel = function(uuid)
	local data = GetRawPetData(uuid)

	if data and data.PetData then return data.PetData.Level or 1 end
	return 1
end

GetPetMutation = function(uuid)
	local data = GetRawPetData(uuid)
	if data and data.PetData then
		local rawEnum = data.PetData.MutationType
		if rawEnum then
			return EnumToNameCache and EnumToNameCache[rawEnum] or "None"
		else
			return "None"
		end
	end
	return nil
end

GetPetHunger = function(uuid)
	local data = GetRawPetData(uuid)
	if data and data.PetData then return data.PetData.Hunger or 0 end
	return 0
end

GetPetType = function(uuid)
	local data = GetRawPetData(uuid)
	if data then return data.PetType or "Unknown" end
	return "Unknown"
end

GetPetHungerPercent = function(uuid)
	local petType = GetPetType(uuid)
	local maxHunger = (HungerTable and HungerTable[petType]) or 10000
	if maxHunger <= 0 then return 0 end
	return 100 * (GetPetHunger(uuid) / maxHunger)
end

GetPetFavorite = function(uuid)
	local data = GetRawPetData(uuid)
	if data and data.PetData then return data.PetData.IsFavorite == true end
	return false
end

MakePetFavorite = function(uuid)
	local timeout = 3
	local startTime = tick()

	local favoriteEvent = GameEvents:WaitForChild("Favorite_Item")

	if not GetPetFavorite(uuid) then
		repeat
			local targetItem = nil

			for _, item in ipairs(Backpack:GetChildren()) do
				if item:GetAttribute("ItemType") == "Pet" and item:GetAttribute("PET_UUID") == uuid then
					targetItem = item
					break
				end
			end

			if not targetItem and LocalPlayer.Character then
				for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
					if item:GetAttribute("ItemType") == "Pet" and item:GetAttribute("PET_UUID") == uuid then
						targetItem = item
						break
					end
				end
			end

			if targetItem then
				favoriteEvent:FireServer(targetItem)
				task.wait(0.3)
				return true
			end

			task.wait(0.2)
		until tick() - startTime > timeout
	end
	return false
end

MakePetUnfavorite = function(uuid)
	local timeout = 3
	local startTime = tick()

	local favoriteEvent = GameEvents:WaitForChild("Favorite_Item")

	if GetPetFavorite(uuid) then
		repeat
			local targetItem = nil

			for _, item in ipairs(Backpack:GetChildren()) do
				if item:GetAttribute("ItemType") == "Pet" and item:GetAttribute("PET_UUID") == uuid then
					targetItem = item
					break
				end
			end

			if not targetItem and LocalPlayer.Character then
				for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
					if item:GetAttribute("ItemType") == "Pet" and item:GetAttribute("PET_UUID") == uuid then
						targetItem = item
						break
					end
				end
			end

			if targetItem then
				favoriteEvent:FireServer(targetItem)
				task.wait(0.3)
				return true
			end

			task.wait(0.2)
		until tick() - startTime > timeout
	end
	return false
end

GetPetBaseWeight = function(uuid)
	local data = GetRawPetData(uuid)
	if data and data.PetData then
		local BaseWeight = tonumber(data.PetData.BaseWeight)
		if BaseWeight then return BaseWeight end
	end
	return nil
end

GetPetUUID = function(petName)
	local petMode = Options.PetMode.Value
	local useFavOnly = Options.UseFavoriteOnly.Value
	local targetMutant = "EfHub"

	if petMode == "Nightmare" then
		targetMutant = "Nightmare"
	elseif petMode == "Mutant" then
		targetMutant = Options.TargetMutantDropdown.Value
	end

	local function IsValidPet(uuid, pType)
		if not table.find(petName, pType) then return false end
		if (petMode == "Mutant" or petMode == "Nightmare") and GetPetMutation(uuid) == targetMutant then return false end
		if (GetPetFavorite(uuid) or false) ~= useFavOnly then return false end
		if petMode == "Elephant" and GetPetBaseWeight(uuid) > 3.5 then return false end
		if petMode == "Level" and GetPetLevel(uuid) >= 100 then return false end

		return true
	end

	for _, uuid in pairs(GetEquippedPetsUUID()) do
		local pType = GetPetType(uuid)
		if IsValidPet(uuid, pType) then
			InfoLog("Found pet (Equipped): " .. pType .. " [" .. uuid .. "]")
			return uuid
		end
	end

	local data = DataService:GetData()
	local inventory = data and data.PetsData and data.PetsData.PetInventory
	if inventory then
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for kUUID, petData in pairs(v) do
					if type(petData) == "table" then
						local tuuid = petData.UUID or kUUID
						if tuuid then
							local tPetType = petData.PetType
							if IsValidPet(tuuid, tPetType) then
								InfoLog("Found pet (Backpack): " .. tPetType .. " : " .. tuuid)
								return tuuid
							end
						end
					end
				end
			end
		end
	end

	task.wait(0.5)

	return nil
end

EquipPet = function(uuid)
	local args = { "EquipPet", uuid }
	GameEvents:WaitForChild("PetsService"):FireServer(unpack(args))
end

UnequipPet = function(uuid)
	local args = { "UnequipPet", uuid }
	GameEvents:WaitForChild("PetsService"):FireServer(unpack(args))
end

SwapPetLoadout = function(Loadout)
	if Loadout == 2 then
		Loadout = 3
	elseif Loadout == 3 then
		Loadout = 2
	end
	local args = { "SwapPetLoadout", Loadout }
	GameEvents:WaitForChild("PetsService"):FireServer(unpack(args))
end

heldPet = function(uuid)
	local timeout = 3
	local startTime = tick()

	repeat
		for _, item in ipairs(Backpack:GetChildren()) do
			if item:GetAttribute("ItemType") == "Pet" and item:GetAttribute("PET_UUID") == uuid then
				Humanoid:EquipTool(item)
				task.wait(0.3)
				return true
			end
		end
		task.wait(0.2)
	until tick() - startTime > timeout

	WarnLog("Failed to hold pet: " .. tostring(uuid))
	return false
end

heldItemUUID = function(uuid)
	for _, item in ipairs(Backpack:GetChildren()) do
		if item:GetAttribute("c") == uuid then
			Humanoid:EquipTool(item)
			return true
		end
	end
	return false
end

heldItemName = function(itemName)
	for _, item in ipairs(Backpack:GetChildren()) do
		local name = string.match(item.Name, "^(.-)%s*%[") or string.match(item.Name, "^(.-)%s*[xX]%d+") or item.Name
		name = string.gsub(name, "^%s*(.-)%s*$", "%1")

		if name == itemName then
			pcall(function()
				Humanoid:EquipTool(item)
			end)
			return true
		end
	end
	return false
end

IsActivePet = function(uuid)
	local scrollFramePath = LocalPlayer.PlayerGui.ActivePetUI.Frame.Main.PetDisplay.ScrollingFrame
	local targetPet = scrollFramePath:FindFirstChild(uuid)
	if targetPet then
		return true
	else
		return false
	end
end

MakeMutant = function(uuid)
	if Options.PetMode.Value ~= "Mutant" then return end
	SwapPetLoadout(Options.TimeSlots.Value)
	task.wait(Options.LoadOutDelay.Value)
	Character:PivotTo(CFrame.new(-236.17, 4.50, 14.36))
	task.wait(0.2)
	if IsActivePet(uuid) then
		UnequipPet(uuid)
		task.wait(1)
	end
	if heldPet(uuid) then
		task.wait(0.5)

		local args1 = { "SubmitHeldPet" }
		GameEvents:WaitForChild("PetMutationMachineService_RE"):FireServer(unpack(args1))
		task.wait(0.5)
		local args2 = { "PetAssets", GetPetType(uuid) }
		GameEvents:WaitForChild("ReplicationChannel"):FireServer(unpack(args2))
		task.wait(1)
		local args3 = { "StartMachine" }
		GameEvents:WaitForChild("PetMutationMachineService_RE"):FireServer(unpack(args3))
		Mutanting = true
	end
end

ClaimMutantPet = function(uuid)
	SwapPetLoadout(Options.MutantSlots.Value)
	task.wait(Options.LoadOutDelay.Value)
	task.wait(Options.LoadOutDelay.Value)
	local args = { "ClaimMutatedPet" }
	GameEvents:WaitForChild("PetMutationMachineService_RE"):FireServer(unpack(args))

	task.wait(3)
	if Character and Humanoid then pcall(function()
		Humanoid:UnequipTools()
	end) end

	SuccessLog("Successfully claimed " .. GetPetType(uuid) .. " Mutant : " .. GetPetMutation(uuid))
	Mutanting = false
	local TargetMutant = Options.TargetMutantDropdown.Value
	task.wait(10)
	if Options.PetModeEnable.Value then
		if TargetMutant == GetPetMutation(uuid) then
			MakePetFavorite(uuid)
			Mutation()
		else
			Mutation(uuid)
		end
	end
end

Mutation = function(uuid)
	if Options.PetModeEnable.Value then
		local petMode = Options.PetMode.Value
		local TargetLimit = tonumber(Options.AgeLimitInput.Value) or 50
		local TargetPet = GetSelectedItems(Options.TargetPetDropdown.Value)

		targetUUID = uuid or GetPetUUID(TargetPet)

		if targetUUID then
			local age = GetPetLevel(targetUUID)

			local function IsEquipPet()
				if petMode == "Mutant" and age >= TargetLimit then return false end

				if petMode == "Level" and age >= TargetLimit then return false end

				if petMode == "Elephant" and age >= TargetLimit and GetPetBaseWeight(targetUUID) > 3.5 then return false end

				if petMode == "Nightmare" and GetPetMutation(targetUUID) == "Nightmare" then return false end

				return true
			end

			if IsEquipPet() then
				Character:PivotTo(CFrame.new(FarmPoint.X, FarmPoint.Y, FarmPoint.Z))
				task.wait(0.3)

				InfoLog("Swapping to loadout " .. Options.LevelSlots.Value .. " to equip pet...")
				SwapPetLoadout(Options.LevelSlots.Value)
				task.wait(Options.LoadOutDelay.Value)

				InfoLog("Equipping pet...")
				pcall(function()
					EquipPet(targetUUID)
				end)
			elseif petMode == "Mutant" then
				InfoLog("Send " .. GetPetType(targetUUID) .. " to the Mutant Machine")
				MakeMutant(targetUUID)
			else
				return
			end
		else
			ErrorLog("Target pet not found in backpack.")
		end
	end
end

DataStream.OnClientEvent:Connect(function(Type, Profile, Data)
	local TargetLevel = tonumber(Options.AgeLimitInput.Value) or 50

	if Type ~= "UpdateData" then return end
	if not string.find(Profile, LocalPlayer.Name) then return end
	if not Data or type(Data) ~= "table" then return end
	for _, Packet in ipairs(Data) do
		local Key = Packet[1]
		local Content = Packet[2]

		if BuyList[Key] then task.spawn(function()
			ProcessBuy(Key, Content)
		end) end

		if Options.PetModeEnable.Value then
			task.spawn(function()
				if string.find(Key, "ROOT/GardenGuide/PetData") or Key == "ROOT/BadgeData/PetMaster" then
					if Options.PetMode.Value == "Nightmare" then
						PetNightmare(targetUUID)
					elseif Options.PetMode.Value == "Mutant" then
						CheckMakeMutant(targetUUID)
					else
						if GetPetLevel(targetUUID) >= TargetLevel then
							pcall(function()
								UnequipPet(targetUUID)
							end)
							task.wait(1)
							Mutation()
						end
					end
				elseif Key == "ROOT/PetMutationMachine/PetReady" then
					if Mutanting and Options.PetMode.Value == "Mutant" then ClaimMutantPet(targetUUID) end
					task.wait(0.3)
				end
			end)
		end
	end
end)

ApplyAntiLag = function()
	-- Lighting
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.Brightness = 0
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.OutdoorAmbient = Color3.new(0, 0, 0)

	-- Terrain Water
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 1

	-- Workspace optimize
	for i, v in ipairs(workspace:GetDescendants()) do
		if i % 200 == 0 then task.wait() end

		if v:IsA("BasePart") then
			v.Material = Enum.Material.SmoothPlastic
			v.Reflectance = 0
		elseif v:IsA("ParticleEmitter") then
			v.Enabled = false
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 1
		end
	end

	-- Rendering quality (safe)
	pcall(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
end

--[[ Anti-AFK ]]

LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

IsFruit = function(obj)
	local current = obj
	while current and current ~= workspace do
		if current.Name == "Fruits" then return true end
		current = current.Parent
	end
	return false
end

SetVisibility = function(obj, isHidden)
	if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Decal") or obj:IsA("Texture") then
		if isHidden then
			-- ใช้คีย์เวิร์ดเดิม OriginalTrans
			if not obj:GetAttribute("OriginalTrans") then obj:SetAttribute("OriginalTrans", obj.Transparency) end
			obj.Transparency = 1
		else
			local orig = obj:GetAttribute("OriginalTrans")
			if orig then obj.Transparency = orig end
		end
	elseif obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") or obj:IsA("Fire") or obj:IsA("Trail") then
		if isHidden then
			-- ใช้คีย์เวิร์ดเดิม OriginalEnabled
			if obj:GetAttribute("OriginalEnabled") == nil then obj:SetAttribute("OriginalEnabled", obj.Enabled) end
			obj.Enabled = false
		else
			local orig = obj:GetAttribute("OriginalEnabled")
			if orig ~= nil then obj.Enabled = orig end
		end
	end
end

HidePlant = function(state)
	isPlantHidden = state
	local PlantFolder = GetPlantsFolder()
	if not PlantFolder then return end

	for _, obj in ipairs(PlantFolder:GetDescendants()) do
		if not IsFruit(obj) then SetVisibility(obj, state) end
	end
end

HideFruit = function(state)
	isFruitHidden = state
	local PlantFolder = GetPlantsFolder()
	if not PlantFolder then return end

	for _, obj in ipairs(PlantFolder:GetDescendants()) do
		if IsFruit(obj) then SetVisibility(obj, state) end
	end
end

SetupTracker = function()
	local PlantFolder = GetPlantsFolder()
	if PlantFolder then
		-- ดักจับเฉพาะของที่งอกใหม่ในสวนของเราโดยตรง (ลดภาระเครื่องได้เยอะมาก)
		PlantFolder.DescendantAdded:Connect(function(newObj)
			task.wait()
			if IsFruit(newObj) then
				if isFruitHidden then SetVisibility(newObj, true) end
			else
				if isPlantHidden then SetVisibility(newObj, true) end
			end
		end)
	end
end

FindFruitInv = function()
	local GetData_result = DataService:GetData()
	local InventoryData = GetData_result.InventoryData or {}
	local AllowList = GetSelectedItems(Options.AllowFoodType.Value)
	for uuid, Item in pairs(InventoryData) do
		if Item.ItemType and Item.ItemType == "Holdable" and Item.ItemData and not Item.ItemData.IsFavorite then
			local FruitInv = Item.ItemData.ItemName
			if Options.AllowAllFood.Value then
				return uuid
			else
				--AllowFoodType
				for _, Fruit in pairs(AllowList) do
					if FruitInv == Fruit then return uuid end
				end
			end
		end
	end
	return nil
end

FeedPet = function()
	local petUUID = GetEquippedPetsUUID()
	if #petUUID == 0 then return end
	for i, uuid in pairs(petUUID) do
		local hunger = tonumber(GetPetHungerPercent(uuid))

		if hunger <= Options.PetHungerPercent.Value then
			local FruitInvUUID = FindFruitInv()
			if FruitInvUUID then
				if heldItemUUID(FruitInvUUID) then
					local args = { "Feed", uuid }
					GameEvents:WaitForChild("ActivePetService"):FireServer(unpack(args))

					task.wait(1)
				end
			else
				break
			end
		end
	end
end

CheckFruit = function(model)
	if not model or not model:IsA("Model") then return false end

	if CheckFruitType then
		local tFruitType = model.Name

		local isFound = table.find(FruitType, tFruitType) ~= nil

		if isFound == ExcludeFruitType then return false end
	end

	if CheckMutant then
		local hasMutant = false
		for _, v in pairs(MutantType) do
			if model:GetAttribute(v) == true then
				hasMutant = true
				break
			end
		end

		if hasMutant == ExceptMutant then return false end
	end

	if CheckVariant then
		local VariantObj = model:FindFirstChild("Variant")

		if not VariantObj then return false end

		local tVariant = VariantObj.Value
		local isVariantMatch = (tVariant == VariantType)

		if isVariantMatch == ExceptVariant then return false end
	end

	if CheckWeight then
		local weightObj = model:FindFirstChild("Weight")
		if not weightObj then return false end

		local tWeight = weightObj.Value

		if WeightType == "Above" and not (tWeight >= WeightValue) then
			return false
		elseif WeightType == "Below" and not (tWeight < WeightValue) then
			return false
		end
	end

	return true
end

CheckFruit1 = function(Fruit)
	CheckFruitType = Options.tgCheckFruitType.Value
	FruitType = GetSelectedItems(Options.ddFruitType.Value)
	ExcludeFruitType = Options.tgExcludeFruitType.Value
	CheckMutant = Options.tgCheckMutant.Value
	MutantType = GetSelectedItems(Options.ddMutantType.Value)
	ExceptMutant = Options.tgExceptMutant.Value
	CheckVariant = Options.tgCheckVariant.Value
	VariantType = Options.ddVariantType.Value
	ExceptVariant = Options.tgExceptVariant.Value
	CheckWeight = Options.tgCheckWeight.Value
	WeightType = Options.ddWeightType.Value
	WeightValue = tonumber(Options.ipWeightValue.Value)
	return CheckFruit(Fruit)
end

CheckFruit2 = function(Fruit)
	CheckFruitType = Options.tgCheckFruitType2.Value
	FruitType = GetSelectedItems(Options.ddFruitType2.Value)
	ExcludeFruitType = Options.tgExcludeFruitType2.Value
	CheckMutant = Options.tgCheckMutant2.Value
	MutantType = GetSelectedItems(Options.ddMutantType2.Value)
	ExceptMutant = Options.tgExceptMutant2.Value
	CheckVariant = Options.tgCheckVariant2.Value
	VariantType = Options.ddVariantType2.Value
	ExceptVariant = Options.tgExceptVariant2.Value
	CheckWeight = Options.tgCheckWeight2.Value
	WeightType = Options.ddWeightType2.Value
	WeightValue = tonumber(Options.ipWeightValue2.Value)
	return CheckFruit(Fruit)
end

ScanFarmTask = function(mode)
	local sMode = mode or 1
	local sIsScanning
	local sFruitQueue
	local sCheckFruit
	local sEnable
	if sMode == 1 then
		sIsScanning = IsScanning1
		sFruitQueue = FruitQueue1
		sCheckFruit = CheckFruit1
		sEnable = Options.tgCollectFruitEnable.Value
	elseif sMode == 2 then
		sIsScanning = IsScanning2
		sFruitQueue = FruitQueue2
		sCheckFruit = CheckFruit2
		sEnable = Options.tgCollectFruitEnable2.Value
	end
	if sIsScanning then return end
	sIsScanning = true

	task.spawn(function()
		table.clear(sFruitQueue)

		local MyFarm = GetMyFarm()
		if not MyFarm then
			sIsScanning = false
			IsScanning1 = false
			IsScanning2 = false
			return
		end
		local Plants_Physical = GetPlantsFolder()

		if Plants_Physical then
			local count = 0

			for _, plant in ipairs(Plants_Physical:GetChildren()) do
				if not sEnable then break end

				local FruitsContainer = plant:FindFirstChild("Fruits")
				local itemsToCheck = FruitsContainer and FruitsContainer:GetChildren() or { plant }

				for _, item in ipairs(itemsToCheck) do
					if item:IsA("Model") then
						local Prompt = item:FindFirstChild("ProximityPrompt", true)

						if Prompt and Prompt.Enabled then
							if sCheckFruit(item) then table.insert(sFruitQueue, item) end
						end
					end
				end

				count = count + 1
				if count % 50 == 0 then task.wait() end
			end
		end
		sIsScanning = false
		if sMode == 1 then
			IsScanning1 = sIsScanning
			FruitQueue1 = sFruitQueue
		elseif sMode == 2 then
			IsScanning2 = sIsScanning
			FruitQueue2 = sFruitQueue
		end
	end)
end

CollectFruitWorker1 = function()
	if not Options.tgCollectFruitEnable.Value then
		table.clear(FruitQueue1)
		task.wait(1)
		return
	end

	local success, isFull = pcall(function()
		return InventoryService.IsMaxInventory(LocalPlayer)
	end)

	if success and isFull then
		table.clear(FruitQueue1)
		task.wait(1)
		return
	end

	if #FruitQueue1 > 0 then
		local itemToCollect = table.remove(FruitQueue1, 1)
		if itemToCollect and itemToCollect.Parent and itemToCollect:FindFirstChild("ProximityPrompt", true) then
			CollectEvent:FireServer({ itemToCollect })
			task.wait(CollectDelay)
			return
		end
	else
		if not IsScanning1 then ScanFarmTask(1) end
		task.wait(0.5)
		return
	end

	task.wait()
end

CollectFruitWorker2 = function()
	if not Options.tgCollectFruitEnable2.Value then
		table.clear(FruitQueue2)
		task.wait(1)
		return
	end

	local success, isFull = pcall(function()
		return InventoryService.IsMaxInventory(LocalPlayer)
	end)

	if success and isFull then
		table.clear(FruitQueue2)
		task.wait(1)
		return
	end

	if #FruitQueue2 > 0 then
		local itemToCollect = table.remove(FruitQueue2, 1)
		if itemToCollect and itemToCollect.Parent and itemToCollect:FindFirstChild("ProximityPrompt", true) then
			CollectEvent:FireServer({ itemToCollect })
			task.wait(CollectDelay)
			return
		end
	else
		if not IsScanning2 then ScanFarmTask(2) end
		task.wait(0.5)
		return
	end

	task.wait()
end

GetPosition = function()
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if HumanoidRootPart then
		local pivot = Character:GetPivot()
		return pivot.Position
	end
	return nil
end

AutoPlant = function()
	local pos = nil
	if Options.ddPlantPosition.Value == "User Position" then pos = GetPosition() end
	local tPlant = Options.ddPlantFruitType.Value
	local tSeed = tPlant .. " Seed"
	heldItemName(tSeed)
	if pos then
		local args = { vector.create(pos.X, pos.Y, pos.Z), tPlant }
		GameEvents:WaitForChild("Plant_RE"):FireServer(unpack(args))
	end
end

CheckMakeMutant = function(uuid)
	if Options.PetMode.Value ~= "Mutant" then return false end
	local TargetLevel = tonumber(Options.AgeLimitInput.Value) or 50
	local age = GetPetLevel(uuid)
	if not age then return end
	task.wait(0.3)

	if age >= TargetLevel then
		UnequipPet(uuid)
		task.wait(0.3)
		MakeMutant(uuid)
	end
	return true
end

PetNightmare = function(uuid)
	local mutant = GetPetMutation(uuid)
	if mutant and GetPetMutation(uuid) ~= "Nightmare" then
		local petsPhysical = game.Workspace:WaitForChild("PetsPhysical")
		for _, container in ipairs(petsPhysical:GetChildren()) do
			local PetModel = container:FindFirstChild(uuid)
			if PetModel then
				heldItemName("Cleansing Pet Shard")
				local args = { "ApplyShard", PetModel }
				GameEvents:WaitForChild("PetShardService_RE"):FireServer(unpack(args))
			end
		end
	elseif mutant and GetPetMutation(uuid) == "Nightmare" then
		UnequipPet(uuid)
		task.wait(1)
		MakePetFavorite(uuid)
		Mutation()
	end
end

AutoSellAll = function()
	if Options.tgAutoSellALL.Value then
		local success, isFull = pcall(function()
			return InventoryService.IsMaxInventory(LocalPlayer)
		end)

		if success and isFull then
			local Previous = Character:GetPivot()
			Character:PivotTo(CFrame.new(36.58, 4.50, 0.43))
			task.wait(0.3)
			GameEvents.Sell_Inventory:FireServer()
			task.wait(0.5)
			Character:PivotTo(Previous)
		end
	end
	task.wait(1)
end

PickFinishPet = function()
	if not targetUUID then return end
	local tPetMode = Options.PetMode.Value
	if Options.PetModeEnable.Value and (tPetMode == "Elephant" or tPetMode == "Level") then
		if GetPetLevel(targetUUID) >= tonumber(Options.AgeLimitInput.Value) then
			SuccessLog("UnequipPet")
			UnequipPet(targetUUID)
			task.wait(1)
			Mutation()
		end
	end
	task.wait(10)
end

HardCoreBuy = function()
	if Options.HardCoreBuyEnable.Value then
		local GetData_result = DataService:GetData()
		local SeedStocks = GetData_result.SeedStocks.Shop.Stocks
		local GearStock = GetData_result.GearStock.Stocks
		local EggStock = GetData_result.PetEggStock.Stocks
		if not isTableEmpty(SeedStocks) then ProcessBuy(ShopKey.Seed, SeedStocks) end
		if not isTableEmpty(GearStock) then ProcessBuy(ShopKey.Gear, GearStock) end
		if not isTableEmpty(EggStock) then ProcessBuy(ShopKey.Egg, EggStock) end
		task.wait(tonumber(Options.HardCoreDelay.Value))
	end
end

calculateCurrentWeight = function(uuid, petAge)
	local baseWeight = GetPetBaseWeight(uuid) or 0
	return baseWeight * (0.909 + (0.091 * petAge))
end

getInventoryList = function()
	local data = DataService:GetData()
	return data and data.PetsData and data.PetsData.PetInventory
end

findMainPet = function()
	local targetType = Options.AAB_PetType.Value
	local targetAge = tonumber(Options.AAB_TargetAge.Value) or 125
	local inventory = getInventoryList()

	if inventory then
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for _, petData in pairs(v) do
					local uuid = petData.UUID
					local tPetType = petData.PetType

					if tPetType == targetType and not GetPetFavorite(uuid) then
						local petAge = GetPetLevel(uuid) or 0
						if petAge >= 100 and petAge < targetAge then return uuid end
					end
				end
			end
		end
	end
	return nil
end

findDupePet = function(mainUUID, targetType)
	local checkWeight = Options.AAB_CheckWeight.Value
	local weightCond = Options.AAB_WeightCond.Value
	local weightVal = tonumber(Options.AAB_WeightVal.Value) or 0

	local checkAge = Options.AAB_CheckAge.Value
	local ageCond = Options.AAB_AgeCond.Value
	local ageVal = tonumber(Options.AAB_AgeVal.Value) or 0

	local inventory = getInventoryList()

	if inventory then
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for _, petData in pairs(v) do
					local uuid = petData.UUID
					local tPetType = petData.PetType
					if uuid ~= mainUUID and tPetType == targetType and not GetPetFavorite(uuid) then
						local petAge = GetPetLevel(uuid) or 0
						if petAge < 100 then
							local isValid = true

							if checkAge then
								if ageCond == "<=" and petAge > ageVal then isValid = false end
								if ageCond == ">=" and petAge < ageVal then isValid = false end
							end

							if isValid and checkWeight then
								local currentWeight = calculateCurrentWeight(uuid, petAge)
								if weightCond == "<=" and currentWeight > weightVal then isValid = false end
								if weightCond == ">=" and currentWeight < weightVal then isValid = false end
							end

							if isValid then return uuid end
						end
					end
				end
			end
		end
	end
	return nil
end

processAgeBreakMachine = function()
	if AgeBreakRunning then return end

	local playerData = DataService:GetData()
	if not playerData then return end

	local machineData = playerData.PetAgeBreakMachine
	if not machineData then return end

	AgeBreakRunning = true

	local success, err = pcall(function()
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChild("Humanoid")

		if machineData.PetReady then
			GameEvents.PetAgeLimitBreak_Claim:FireServer()
			task.wait(1.5)
			return
		end

		if machineData.IsRunning then return end

		local submittedPet = machineData.SubmittedPet
		local hasPetInMachine = submittedPet and type(submittedPet) == "table" and submittedPet.UUID ~= nil

		if not hasPetInMachine then
			local targetAge = tonumber(Options.AAB_TargetAge.Value) or 125

			if currentMainPetUUID then
				local petAge = GetPetLevel(currentMainPetUUID)
				if not petAge or petAge >= targetAge then currentMainPetUUID = nil end
			end

			if not currentMainPetUUID then currentMainPetUUID = findMainPet() end

			if currentMainPetUUID then
				if humanoid then humanoid:UnequipTools() end
				task.wait(0.3)

				heldPet(currentMainPetUUID)
				task.wait(0.5)

				GameEvents.PetAgeLimitBreak_SubmitHeld:FireServer()
				task.wait(2)
			end
		elseif hasPetInMachine and not machineData.IsRunning then
			local targetType = submittedPet.PetType
			local inMachineUUID = submittedPet.UUID

			local dupeUUID = findDupePet(inMachineUUID, targetType)
			if dupeUUID then
				GameEvents.PetAgeLimitBreak_Submit:FireServer({ dupeUUID })
				task.wait(2)
			end
		end
	end)

	if not success then WarnLog("EfHub - Age Break Task Error: " .. err) end

	AgeBreakRunning = false
end

getBoundary = function(plate)
	if not plate then return nil end

	local bCf = plate.CFrame
	local size = plate.Size

	local bMinX, bMaxX = -size.X / 2 + 1, size.X / 2 - 1
	local bMinZ, bMaxZ = -size.Z / 2 + 1, size.Z / 2 - 1
	return {
		cf = bCf,
		minX = bMinX,
		maxX = bMaxX,
		minZ = bMinZ,
		maxZ = bMaxZ,
	}
end

getPlate = function()
	local myPlate = {}
	local plantLocations = MyFarm.Important.Plant_Locations:GetChildren()
	for _, plate in pairs(plantLocations) do
		if plate.Name == "Can_Plant" or plate:IsA("Part") then table.insert(myPlate, plate) end
	end
	return myPlate
end

EggInFarm = function()
	local Farm_Important = MyFarm:FindFirstChild("Important")
	local Objects_Physical = Farm_Important and Farm_Important:FindFirstChild("Objects_Physical")
	local tempEggInFarm = {}
	if Objects_Physical then
		for _, oEgg in pairs(Objects_Physical:GetChildren()) do
			if oEgg and oEgg:GetAttribute("OBJECT_TYPE") == "PetEgg" then table.insert(tempEggInFarm, oEgg) end
		end
	end
	return tempEggInFarm
end

ValidEggs = function(EggsData, rEggs)
	local spWeight = tonumber(Options.ipSpecialHatchWeight.Value)

	local spEggs = {}
	local nmEggs = {}

	if not EggsData or not rEggs then return nil, nil end
	for _, rEgg in rEggs do
		local EggData = EggsData[rEgg:GetAttribute("OBJECT_UUID")]
		if EggData then
			local HatchWeight = EggData.Data.BaseWeight * 1.1
			local HatchPetType = EggData.Data.Type
			if spWeight ~= 0 and HatchWeight >= spWeight then
				table.insert(spEggs, rEgg)
			elseif #SpecialHatchType > 0 and table.find(SpecialHatchType, HatchPetType) then
				table.insert(spEggs, rEgg)
			else
				table.insert(nmEggs, rEgg)
			end
		end
	end
	return nmEggs, spEggs
end

HatchEgg = function()
	if Options.tgAutoHatchEn.Value then
		if isEggProcessing then return end

		if #EggHatchList == 0 then return end
		local GetData_result = DataService:GetData()
		isEggProcessing = true
		local ReadyEggs = {}
		local PetsData = {}
		local myEggs = EggInFarm()
		local SelectedSlot = GetData_result.SaveSlots.SelectedSlot
		local fData = GetData_result.SaveSlots.AllSlots[SelectedSlot].SavedObjects
		if not fData or type(fData) ~= "table" then return end
		local petCount = 0
		for Key, PetData in pairs(fData) do
			if PetData.Data.CanHatch then
				PetsData[Key] = PetData
				petCount = petCount + 1
			end
		end

		for _, nEggs in pairs(myEggs) do
			if nEggs:GetAttribute("READY") then
				if table.find(EggHatchList, "ALL") or table.find(EggHatchList, nEggs:GetAttribute("EggName")) then table.insert(ReadyEggs, nEggs) end
			end
		end

		if petCount ~= #ReadyEggs then
			isEggProcessing = false
			return
		end

		local NormalEggs, SpecialEggs = ValidEggs(PetsData, ReadyEggs)
		if #NormalEggs > 0 then
			SwapPetLoadout(tonumber(Options.ddHatchSlot.Value))
			task.wait(10)
			for _, rEgg in pairs(NormalEggs) do
				GameEvents.PetEggService:FireServer("HatchPet", rEgg)
				task.wait(tonumber(Options.ipHatchDelay.Value))
			end
		end
		task.wait(10)
		if #SpecialEggs > 0 then
			SwapPetLoadout(tonumber(Options.ddSpecialHatchSlot.Value))
			task.wait(10)
			for _, sEgg in pairs(SpecialEggs) do
				GameEvents.PetEggService:FireServer("HatchPet", sEgg)
				task.wait(tonumber(Options.ipHatchDelay.Value))
			end
		end

		Humanoid:UnequipTools()
		isEggProcessing = false
	end
end

local EggMultiple = 0
PlaceEggs = function()
	if Options.tgPlaceEggsEn.Value then
		if isEggProcessing then return end
		if #PlaceEggList == 0 then return nil end
		local farmEgg = EggInFarm()

		if #farmEgg >= tonumber(Options.ipMaxEggs.Value) then
			local GetData_result = DataService:GetData()
			local lo = GetData_result.PetsData.SelectedPetLoadout
			if lo ~= tonumber(Options.ddSpeedEggSlot.Value) then
				SwapPetLoadout(tonumber(Options.ddSpeedEggSlot.Value))
				task.wait(5)
			end
			EggMultiple = 0
			return
		end
		isEggProcessing = true
		local Plate = getPlate()
		local Boundary = getBoundary(Plate[2])
		local x = Boundary.maxX
		local y = 0.1355266571044922
		local z = Boundary.minZ
		local cf = Boundary.cf

		z = z + (4 * EggMultiple)
		EggMultiple = EggMultiple + 1
		if z > Boundary.maxZ then
			x = x - 4
			z = Boundary.minZ
			EggMultiple = 1
		end
		if x < Boundary.minX then
			isEggProcessing = false
			return
		end
		local NewPos = (cf * CFrame.new(x, 0, z)).Position
		local finalPos = Vector3.new(NewPos.X, y, NewPos.Z)

		local myIndex = Random.new():NextInteger(1, #PlaceEggList)
		local Egg = PlaceEggList[myIndex]

		heldItemName(Egg)
		task.wait(0.1)
		GameEvents:WaitForChild("PetEggService"):FireServer("CreateEgg", finalPos)
		task.wait(tonumber(Options.ipPlaceEggDelay.Value))
		isEggProcessing = false
	end
	Humanoid:UnequipTools()
	return
end
IsValidSellPet = function(petData)
	local sSellMode = Options.ddSellMode.Value
	local sSellWeight = tonumber(Options.ipSellWeight.Value)
	if sSellWeight == nil then return false end
	local sSellWeightMode = Options.ddSellWeightMode.Value
	local sSellMutantPet = Options.tgSellMutantPet.Value

	local sPetType = petData.PetType
	local sBaseWeight = petData.PetData.BaseWeight
	local sMutant = petData.PetData.MutationType or "m"
	local sFavorite = petData.PetData.IsFavorite
	if sFavorite then return false end
	if not sSellMutantPet and sMutant ~= "m" then
		return false
	elseif sSellWeight ~= 0 and sSellWeightMode == "Below" and sBaseWeight >= sSellWeight then
		return false
	elseif sSellWeight ~= 0 and sSellWeightMode == "Above" and sBaseWeight <= sSellWeight then
		return false
	elseif sSellMode == "Black list" and table.find(SellPetType, sPetType) then
		return false
	elseif sSellMode == "White list" and not table.find(SellPetType, sPetType) then
		return false
	end
	return true
end
local SellPetList = {}

ScanSellPet = function()
	if not Options.tgSellPetEn.Value then return end
	if isEggProcessing then return end
	local GetData_result = DataService:GetData()
	local inventory = GetData_result.PetsData.PetInventory
	if inventory then
		table.clear(SellPetList)
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for _, petData in pairs(v) do
					if type(petData) == "table" and IsValidSellPet(petData) then table.insert(SellPetList, petData.UUID) end
				end
			end
		end
	end
end
SellPetEgg = function()
	if not Options.tgSellPetEn.Value then return end
	if isEggProcessing then return end
	if #SellPetList > 0 then
		print("Selling Pet")
		isEggProcessing = true

		SwapPetLoadout(tonumber(Options.ddSellPetSlot.Value))
		task.wait(10)

		for _, uuid in pairs(SellPetList) do
			if heldPet(uuid) then GameEvents:WaitForChild("SellPet_RE"):FireServer() end
			task.wait(Options.ipSellPetDelay.Value)
		end
		table.clear(SellPetList)
		isEggProcessing = false
		print("End of Sell pet")
	end
end

ShovelPlant = function()
	if not Options.tgAutoPlantShovel.Value then return end
	local Plants_Physical = GetPlantsFolder()
	pcall(function()
		Humanoid:UnequipTools()
	end)
	local ShovelPlantList = GetSelectedItems(Options.ddShovelPlant.Value)
	local myShovel = LocalPlayer.Backpack:FindFirstChild("Shovel [Destroy Plants]")

	if Plants_Physical then
		for _, plant in pairs(Plants_Physical:GetChildren()) do
			if table.find(ShovelPlantList, plant.Name) then
				pcall(function()
					Humanoid:EquipTool(myShovel)
				end)
				GameEvents:WaitForChild("Remove_Item"):FireServer(plant)
				task.wait(0.1)
			end
		end
	end
end

Reclaim = function()
	if not Options.tgReclaim.Value then return end
	pcall(function()
		Humanoid:UnequipTools()
	end)
	local Backpack = LocalPlayer.Backpack
	local myReclaimer
	for _, item in pairs(Backpack:GetChildren()) do
		if item:IsA("Tool") and string.find(item.Name, "^Reclaimer") then
			myReclaimer = item
			break
		end
	end

	local Plants_Physical = GetPlantsFolder()

	local ReclaimPlantList = GetSelectedItems(Options.ddReclaim.Value)
	if Plants_Physical then
		for _, plant in pairs(Plants_Physical:GetChildren()) do
			if table.find(ReclaimPlantList, plant.Name) then
				pcall(function()
					Humanoid:EquipTool(myReclaimer)
				end)
				GameEvents:WaitForChild("ReclaimerService_RE"):FireServer("TryReclaim", plant)
				task.wait(0.1)
			end
		end
	end
end

GiftMainFrame.ChildAdded:Connect(function(child)
	task.wait(0.5)
	if not Options.tgAcceptPetGift.Value then return end
	local playerGui = LocalPlayer.PlayerGui
	local hiddenGuis = {}

	for _, uiElement in pairs(GiftMainFrame:GetChildren()) do
		if uiElement:FindFirstChild("Holder") and uiElement.Holder:FindFirstChild("Frame") then
			local acceptButton = uiElement.Holder.Frame:FindFirstChild("Accept")

			if acceptButton then
				for _, gui in pairs(playerGui:GetChildren()) do
					if gui:IsA("ScreenGui") and gui.Name ~= "Gift_Notification" and gui.Enabled == true then
						gui.Enabled = false
						table.insert(hiddenGuis, gui)
					end
				end

				local inset, _ = game:GetService("GuiService"):GetGuiInset()
				local x = acceptButton.AbsolutePosition.X + (acceptButton.AbsoluteSize.X / 2) + inset.X
				local y = acceptButton.AbsolutePosition.Y + (acceptButton.AbsoluteSize.Y / 2) + inset.Y

				VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
				task.wait(0.05)
				VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)

				for _, gui in ipairs(hiddenGuis) do
					gui.Enabled = true
				end

				task.wait(tonumber(Options.inPetGiftDelay.Value))
			end
		end
	end
end)

local function initToggle()
	Options.PetModeEnable:SetValue(false)
	Options.tgPlaceEggsEn:SetValue(false)
	Options.tgAutoHatchEn:SetValue(false)
	Options.tgSellPetEn:SetValue(false)
end

local function restoreToggle()
	Options.PetModeEnable:SetValue(Options.tgAlienDefaultPetMode.Value)
	Options.tgPlaceEggsEn:SetValue(Options.tgAlienDefaultPlaceEggs.Value)
	Options.tgAutoHatchEn:SetValue(Options.tgAlienDefaultHatchEggs.Value)
	Options.tgSellPetEn:SetValue(Options.tgAlienDefaultSellPets.Value)
end

local lastTriggerMinute = -1
local StopFlag = false
local function AlienEvent()
	if not Options.tgAlienEventEnable.Value then return end
	local AlienLoadout = tonumber(Options.ddAlienLoadout.Value)
	local AlienPet = GetSelectedItems(Options.ddAlienPet.Value)
	local AlienMaxPet = tonumber(Options.ddAlienMaxPet.Value)

	local timeData = os.date("!*t")
	local currentMinute = timeData.min
	local data = DataService:GetData()
	local inventory = data and data.PetsData and data.PetsData.PetInventory
	local CountPet = 0

	if currentMinute == 58 and currentMinute ~= lastTriggerMinute then
		lastTriggerMinute = currentMinute
		pcall(initToggle)
		task.wait(1)
		SwapPetLoadout(AlienLoadout)
		task.wait(0.5)
		for _, uuid in pairs(GetEquippedPetsUUID()) do
			UnequipPet(uuid)
			task.wait(0.2)
		end
		if inventory and not StopFlag then
			for _, v in pairs(inventory) do
				if type(v) == "table" then
					for kUUID, petData in pairs(v) do
						if type(petData) == "table" then
							local tPetType = petData.PetType
							if table.find(AlienPet, tPetType) then
								local tuuid = petData.UUID or kUUID
								if tuuid and (GetPetMutation(tuuid) == nil or GetPetMutation(tuuid) == "None") then
									if CountPet < AlienMaxPet then
										EquipPet(tuuid)
										CountPet = CountPet + 1
									else
										StopFlag = true
										break
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if currentMinute == 12 and currentMinute ~= lastTriggerMinute then
		lastTriggerMinute = currentMinute
		for _, uuid in pairs(GetEquippedPetsUUID()) do
			UnequipPet(uuid)
			task.wait(0.2)
		end
		StopFlag = false
		task.wait(2)
		pcall(restoreToggle)
	end
	task.wait(30)
end

local function CatchAlien()
	if not Options.tgAlienEventEnable.Value or not StopFlag then return end

	for _, uuid in pairs(GetEquippedPetsUUID()) do
		local mutant = GetPetMutation(uuid)
		if mutant == "Alienated" then
			UnequipPet(uuid)
			task.wait(0.2)
		end
	end

	local ActivePet = GetEquippedPetsUUID()
	local currentEquipped = #ActivePet
	local AlienMaxPet = tonumber(Options.ddAlienMaxPet.Value) or 0

	if currentEquipped < AlienMaxPet then
		local data = DataService:GetData()
		local inventory = data and data.PetsData and data.PetsData.PetInventory

		if inventory then
			local AlienPet = GetSelectedItems(Options.ddAlienPet.Value)

			for _, v in pairs(inventory) do
				if currentEquipped >= AlienMaxPet then break end

				if type(v) == "table" then
					for kUUID, petData in pairs(v) do
						if currentEquipped >= AlienMaxPet then break end

						if type(petData) == "table" then
							local tPetType = petData.PetType
							if table.find(AlienPet, tPetType) then
								local tuuid = petData.UUID or kUUID

								if tuuid and (GetPetMutation(tuuid) == nil or GetPetMutation(tuuid) == "None") then
									if not table.find(GetEquippedPetsUUID(), tuuid) then
										EquipPet(tuuid)
										currentEquipped = currentEquipped + 1
										task.wait(0.3)
									end
								end
							end
						end
					end
				end
			end
		end
		task.wait(1)
	end
end
local isOverrideActive = false

local function CheckAlienPet()
	if not Options.tgAlienEventEnable.Value or not Options.tgAlienAutoHatch.Value or StopFlag then return end

	local AlienPetCount = 13
	local data = DataService:GetData()
	local inventory = data and data.PetsData and data.PetsData.PetInventory
	local AlienMaxPet = tonumber(Options.ddAlienMaxPet.Value)
	if inventory then
		AlienPetCount = 0
		local AlienPet = GetSelectedItems(Options.ddAlienPet.Value)
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for kUUID, petData in pairs(v) do
					if type(petData) == "table" then
						local tPetType = petData.PetType
						if table.find(AlienPet, tPetType) then
							local tuuid = petData.UUID or kUUID
							if tuuid and GetPetMutation(tuuid) ~= "Alienated" then AlienPetCount = AlienPetCount + 1 end
						end
					end
				end
			end
		end
	end
	task.wait(0.2)
	if AlienPetCount <= AlienMaxPet then
		if not isOverrideActive then
			pcall(initToggle)
			task.wait(1)
			isOverrideActive = true

			Options.tgPlaceEggsEn:SetValue(true)
			Options.tgAutoHatchEn:SetValue(true)
			task.wait(1)
		end
	else
		if isOverrideActive then
			pcall(restoreToggle)
			task.wait(1)
			isOverrideActive = false
			pcall(function()
				Humanoid:UnequipTools()
			end)
			task.wait(1)
		end
	end
end

local function AutoAlienClaim()
	if not Options.tgAlienAutoClaim.Value then return end

	local data = DataService:GetData()
	local inventory = data and data.PetsData and data.PetsData.PetInventory
	local AlienedPet = 0
	if inventory then
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for kUUID, petData in pairs(v) do
					local tuuid = petData.UUID or kUUID
					if type(petData) == "table" then
						if GetPetMutation(tuuid) == "Alienated" then AlienedPet = AlienedPet + 1 end
					end
				end
			end
		end
	end

	task.wait(0.1)
	if AlienedPet >= 10 then
		GameEvents:WaitForChild("GetPetMutationNames"):InvokeServer()
		task.wait(0.2)
		GameEvents:WaitForChild("AlienEvent"):WaitForChild("GiveAlienatedPets"):InvokeServer()
		task.wait(10)
	end
end

ToggleTask = function(taskName, enabled, funcBody)
	if enabled then
		if ActiveTasks[taskName] then return end
		ActiveTasks[taskName] = task.spawn(function()
			while true do
				local ok, err = pcall(funcBody)
				if not ok then WarnLog("Task '" .. taskName .. "' error: " .. tostring(err)) end
				task.wait()
			end
		end)
	else
		if ActiveTasks[taskName] then
			task.cancel(ActiveTasks[taskName])
			ActiveTasks[taskName] = nil
		end
	end
end

local function AutoGiftAlien()
	if not Options.tgAutoGiftAlien.Value then return end
	local TargetPlayer = "PawZx_111"
	local TargetPlayerObj = game:GetService("Players"):FindFirstChild(TargetPlayer)
	if not TargetPlayerObj then return end

	local data = DataService:GetData()
	local inventory = data and data.PetsData and data.PetsData.PetInventory
	if inventory then
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for kUUID, petData in pairs(v) do
					local tuuid = petData.UUID or kUUID
					if type(petData) == "table" then
						if GetPetMutation(tuuid) == "Alienated" then
							if heldPet(tuuid) then
								local args = {
									"GivePet",
									TargetPlayerObj,
								}
								GameEvents:WaitForChild("PetGiftingService"):FireServer(unpack(args))
								task.wait(7)
							end
						end
					end
				end
			end
		end
	end
end

SyncBackgroundTasks = function()
	ToggleTask("AutoFeedPet", Options.AutoFeedPet.Value, function()
		if Options.AutoFeedPet.Value then
			pcall(FeedPet)
			task.wait(10)
		end
	end)

	ToggleTask("AutoPlant", Options.tgPlantFruitEnable.Value, function()
		pcall(AutoPlant)
		task.wait(tonumber(Options.inPlantDelay.Value) or 0.3)
	end)

	ToggleTask("CollectFruit1", Options.tgCollectFruitEnable.Value, CollectFruitWorker1)

	ToggleTask("CollectFruit2", Options.tgCollectFruitEnable2.Value, CollectFruitWorker2)

	ToggleTask("AutoSellALL", Options.tgAutoSellALL.Value, AutoSellAll)

	ToggleTask("PickFinishPet", Options.PetModeEnable.Value, PickFinishPet)

	ToggleTask("HardCoreBuy", Options.HardCoreBuyEnable.Value, HardCoreBuy)

	ToggleTask("ShovelPlant", Options.tgAutoPlantShovel.Value, ShovelPlant)

	ToggleTask("Reclaim", Options.tgReclaim.Value, Reclaim)

	ToggleTask("AutoAgeBreak", Options.AAB_Enabled.Value, function()
		pcall(processAgeBreakMachine)
		task.wait(2)
	end)

	local isEggTaskEnabled = Options.tgPlaceEggsEn.Value or Options.tgAutoHatchEn.Value or Options.tgSellPetEn.Value

	ToggleTask("EggManagement", isEggTaskEnabled, function()
		if Options.tgPlaceEggsEn.Value then
			PlaceEggs()
			task.wait(0.1)
		end
		if Options.tgAutoHatchEn.Value then
			HatchEgg()
			task.wait(0.1)
		end
		if Options.tgSellPetEn.Value then
			pcall(SellPetEgg)
			task.wait(0.1)
		end
		task.wait()
	end)

	ToggleTask("ScanSellPetTask", Options.tgSellPetEn.Value, function()
		pcall(ScanSellPet)
		task.wait(1)
	end)
	ToggleTask("AlienEvent", Options.tgAlienEventEnable.Value, AlienEvent)
	ToggleTask("CatchAlien", Options.tgAlienEventEnable.Value, function()
		pcall(CatchAlien)
		task.wait(5)
	end)
	ToggleTask("CheckAlienPet", Options.tgAlienAutoHatch.Value, function()
		pcall(CheckAlienPet)
		task.wait(10)
	end)
	ToggleTask("AutoAlienClaim", Options.tgAlienAutoClaim.Value, AutoAlienClaim)
	ToggleTask("AutoGiftAlien", Options.tgAutoGiftAlien.Value, AutoGiftAlien)
end

pcall(SetupTracker)

SuccessLog("Script Loaded!")
