--!nocheck
-- [[ AI_Code: Main Entry Point ]]
local Main = {}

-- [[ CONFIGURATION ]]
local DevelopmentMode = false -- SET TO TRUE IF TESTING LOCALLY (Requires local file server)

-- ใช้ https://raw.githubusercontent.com/suta007/SutaHub/refs/heads/master/Modules/ ห้ามเปลี่ยน!!!!
local BasePath = DevelopmentMode and "http://127.0.0.1:5500/AI_Code/Modules/" or "https://raw.githubusercontent.com/suta007/SutaHub/refs/heads/master/Modules/"

local function LoadModule(name)
	local success, result = pcall(function()
		return loadstring(game:HttpGet(BasePath .. name .. ".lua"))()
	end)
	if success then return result end
	warn("Failed to load module: " .. name .. " | Error: " .. tostring(result))
	return nil
end

-- 1. Load All Core Modules
local Core = LoadModule("Core")
local CollapsibleSection = LoadModule("CollapsibleSection")
if CollapsibleSection then CollapsibleSection(Core.Fluent) end

local UI = LoadModule("UI")
local Shop = LoadModule("Shop")
local Farming = LoadModule("Farming")
local Pet = LoadModule("Pet")
local Event = LoadModule("Event")

-- Safety Check: Ensure all modules loaded successfully
if not Core or not UI or not Shop or not Farming or not Pet or not Event then return warn("AI_Code Error: One or more modules failed to load. Script execution stopped.") end

-- 2. Sync Background Tasks (The Engine)
-- Helper to safely get Option Value without errors if the UI element doesn't exist yet
local function GetOpt(name)
	if UI.Options and UI.Options[name] then return UI.Options[name].Value end
	return false
end

function Main.SyncBackgroundTasks()
	if not UI.Options then return end

	-- Farming Tasks
	Core.ToggleTask("AutoPlant", GetOpt("tgPlantFruitEnable"), function()
		pcall(Farming.AutoPlant)
		task.wait(tonumber(GetOpt("inPlantDelay")) or 0.3)
	end)

	Core.ToggleTask("CollectFruit1", GetOpt("tgCollectFruitEnable"), function()
		Farming.CollectFruitWorker(1)
	end)
	Core.ToggleTask("CollectFruit2", GetOpt("tgCollectFruitEnable2"), function()
		Farming.CollectFruitWorker(2)
	end)

	Core.ToggleTask("AutoSellALL", GetOpt("tgAutoSellALL"), Farming.AutoSellAll)

	-- Tool Automation
	Core.ToggleTask("ShovelPlant", GetOpt("tgAutoPlantShovel"), Farming.ShovelPlant)
	Core.ToggleTask("ShovelCrop", GetOpt("tgAutoCropShovel"), function()
		-- Implementation for Crop Shovel (Placeholder / Future Logic)
		task.wait(1)
	end)
	Core.ToggleTask("Reclaim", GetOpt("tgReclaim"), Farming.Reclaim)
	Core.ToggleTask("Trowel", GetOpt("tgTrowel"), Farming.Trowel)

	-- Pet Tasks
	Core.ToggleTask("AutoFeedPet", GetOpt("AutoFeedPet"), function()
		pcall(Pet.FeedPet)
		task.wait(10)
	end)

	Core.ToggleTask("PickFinishPet", GetOpt("PetModeEnable"), Pet.PickFinishPet)

	Core.ToggleTask("AutoAgeBreak", GetOpt("AAB_Enabled"), function()
		pcall(Pet.processAgeBreakMachine)
		task.wait(2)
	end)

	-- Egg Management (Grouped for performance)
	local isEggTaskEnabled = GetOpt("tgPlaceEggsEn") or GetOpt("tgAutoHatchEn") or GetOpt("tgSellPetEn")
	Core.ToggleTask("EggManagement", isEggTaskEnabled, function()
		if GetOpt("tgPlaceEggsEn") then
			--pcall(Pet.PlaceEggs)
			Pet.PlaceEggs()
			task.wait(0.3)
		end
		if GetOpt("tgAutoHatchEn") then
			--pcall(Pet.HatchEgg)
			Pet.HatchEgg()
			task.wait(0.3)
		end
		if GetOpt("tgSellPetEn") then
			--pcall(Pet.SellPetEgg)
			Pet.SellPetEgg()
			task.wait(0.3)
		end
		task.wait()
	end)

	Core.ToggleTask("ScanSellPetTask", GetOpt("tgSellPetEn"), function()
		--pcall(Pet.ScanSellPet)
		Pet.ScanSellPet()
		task.wait(2)
	end)

	-- Shop Tasks
	Core.ToggleTask("HardCoreBuy", GetOpt("HardCoreBuyEnable"), Shop.HardCoreBuy)
end

-- 3. Initialization
function Main.Init()
	print("AI_Code System: Initializing Components...")

	-- Start Modules
	UI.Init(Core, Main.SyncBackgroundTasks)
	Shop.Init(Core, UI) -- Shop has no external module dependencies
	Farming.Init(Core, UI) -- Farming has no external module dependencies
	Pet.Init(Core, UI, Farming) -- Pet depends on Farming
	Event.Init(Core, UI, Pet) -- Event depends on Pet

	-- Hook DataStream for reactive features
	Core.DataStream.OnClientEvent:Connect(function(Type, Profile, Data)
		if Type ~= "UpdateData" or not string.find(Profile, Core.MyName) or not Data then return end

		for _, Packet in ipairs(Data) do
			local Key = Packet[1]
			local Content = Packet[2]

			-- Sync Shop Stocks
			if Shop.BuyList and Shop.BuyList[Key] then task.spawn(function()
				Shop.ProcessBuy(Key, Content)
			end) end

			-- Sync Pet Progress
			if GetOpt("PetModeEnable") then
				task.spawn(function()
					if string.find(Key, "ROOT/GardenGuide/PetData") or Key == "ROOT/BadgeData/PetMaster" then
						if GetOpt("PetMode") == "Nightmare" then
							Pet.PetNightmare()
						elseif GetOpt("PetMode") == "Mutant" then
							Pet.CheckMakeMutant()
						else
							Pet.Mutation()
						end
					elseif Key == "ROOT/PetMutationMachine/PetReady" then
						if Pet.Mutanting and GetOpt("PetMode") == "Mutant" then Pet.ClaimMutantPet() end
					end
				end)
			end
		end
	end)

	-- AFK Protection
	Core.LocalPlayer.Idled:Connect(function()
		Core.VirtualUser:CaptureController()
		Core.VirtualUser:ClickButton2(Vector2.new())
	end)

	-- Setup Save Manager UI (without loading)
	UI.InitSaveManager()
end

function Main.InitAction()
	if GetOpt("tgHideFruitToggle") then Farming.HideFruit(true) end
	if GetOpt("tgHidePlantToggle") then Farming.HidePlant(true) end
	if GetOpt("PetModeEnable") then Pet.Mutation() end
	if GetOpt("HardCoreBuyEnable") then Shop.HardCoreBuy() end
	if GetOpt("buySeedEnable") then
		local GetData_result = Core.DataService:GetData()
		local SeedStocks = GetData_result.SeedStocks.Shop.Stocks
		if type(SeedStocks) == "table" and next(SeedStocks) ~= nil then Shop.ProcessBuy(Shop.ShopKey.Seed, SeedStocks) end
	end

	if GetOpt("buyDailyEnable") then
		local GetData_result = Core.DataService:GetData()
		local DailyStocks = GetData_result.SeedStocks["Daily Deals"].Stocks
		if type(DailyStocks) == "table" and next(DailyStocks) ~= nil then Shop.ProcessBuy(Shop.ShopKey.Daily, DailyStocks) end
	end

	if GetOpt("buyGearEnable") then
		local GetData_result = Core.DataService:GetData()
		local GearStock = GetData_result.GearStock.Stocks
		if type(GearStock) == "table" and next(GearStock) ~= nil then Shop.ProcessBuy(Shop.ShopKey.Gear, GearStock) end
	end

	if GetOpt("buyEggEnable") then
		local GetData_result = Core.DataService:GetData()
		local EggStock = GetData_result.PetEggStock.Stocks
		if type(EggStock) == "table" and next(EggStock) ~= nil then Shop.ProcessBuy(Shop.ShopKey.Egg, EggStock) end
	end

	if GetOpt("buyTravelingEnable") then
		local GetData_result = Core.DataService:GetData()
		local TravelingStock = GetData_result.TravelingMerchantShopStock.Stocks
		if type(TravelingStock) == "table" and next(TravelingStock) ~= nil then Shop.ProcessBuy(Shop.ShopKey.Traveling, TravelingStock) end
	end

	if GetOpt("buySantaEnable") then
		local GetData_result = Core.DataService:GetData()
		local SantaStocks = GetData_result.EventShopStock["Santa's Stash"].Stocks
		if type(SantaStocks) == "table" and next(SantaStocks) ~= nil then Shop.ProcessBuy(Shop.ShopKey.Santa, SantaStocks) end
	end
	if GetOpt("buyNewYearEnable") then
		local GetData_result = Core.DataService:GetData()
		local NewYearStocks = GetData_result.EventShopStock["New Years Shop"].Stocks
		if type(NewYearStocks) == "table" and next(NewYearStocks) ~= nil then Shop.ProcessBuy(Shop.ShopKey.NewYear, NewYearStocks) end
	end
end

-- Run initialization
Main.Init()
task.wait(2)
task.spawn(Main.InitAction)
