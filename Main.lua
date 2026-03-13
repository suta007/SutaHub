--!nocheck
-- [[ AI_Code: Main Entry Point ]]
local Main = {}

-- [[ CONFIGURATION ]]
local DevelopmentMode = false -- SET TO TRUE IF TESTING LOCALLY (Requires local file server)
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
function Main.SyncBackgroundTasks()
	if not UI.Options then return end
	local Options = UI.Options

	-- Farming Tasks
	Core.ToggleTask("AutoPlant", Options.tgPlantFruitEnable.Value, function()
		pcall(Farming.AutoPlant)
		task.wait(tonumber(Options.inPlantDelay.Value) or 0.3)
	end)

	Core.ToggleTask("CollectFruit1", Options.tgCollectFruitEnable.Value, function()
		Farming.CollectFruitWorker(1)
	end)
	Core.ToggleTask("CollectFruit2", Options.tgCollectFruitEnable2.Value, function()
		Farming.CollectFruitWorker(2)
	end)

	Core.ToggleTask("AutoSellALL", Options.tgAutoSellALL.Value, Farming.AutoSellAll)

	-- NEW: Auto Sell Fruit specifically
	Core.ToggleTask("AutoSellFruit", Options.AutoSellFruit.Value, function()
		-- Logic handled in Farming.lua if needed, otherwise trigger here
		task.wait(5)
	end)

	-- Tool Automation
	Core.ToggleTask("ShovelPlant", Options.tgAutoPlantShovel.Value, Farming.ShovelPlant)
	Core.ToggleTask("ShovelCrop", Options.tgAutoCropShovel and Options.tgAutoCropShovel.Value or false, function()
		-- Implementation for Crop Shovel if needed
		task.wait(1)
	end)
	Core.ToggleTask("Reclaim", Options.tgReclaim.Value, Farming.Reclaim)
	Core.ToggleTask("Trowel", Options.tgTrowel.Value, Farming.Trowel)

	-- Pet Tasks
	Core.ToggleTask("AutoFeedPet", Options.AutoFeedPet.Value, function()
		pcall(Pet.FeedPet)
		task.wait(10)
	end)

	Core.ToggleTask("PickFinishPet", Options.PetModeEnable.Value, Pet.PickFinishPet)

	Core.ToggleTask("AutoAgeBreak", Options.AAB_Enabled.Value, function()
		pcall(Pet.processAgeBreakMachine)
		task.wait(2)
	end)

	-- Egg Management (Grouped for performance)
	local isEggTaskEnabled = Options.tgPlaceEggsEn.Value or Options.tgAutoHatchEn.Value or Options.tgSellPetEn.Value
	Core.ToggleTask("EggManagement", isEggTaskEnabled, function()
		if Options.tgPlaceEggsEn.Value then pcall(Pet.PlaceEggs) end
		if Options.tgAutoHatchEn.Value then pcall(Pet.HatchEgg) end
		if Options.tgSellPetEn.Value then pcall(Pet.SellPetEgg) end
		task.wait(0.5)
	end)

	Core.ToggleTask("ScanSellPetTask", Options.tgSellPetEn.Value, function()
		pcall(Pet.ScanSellPet)
		task.wait(2)
	end)

	-- Event Tasks
	Core.ToggleTask("AlienEvent", Options.tgAlienEventEnable.Value, Event.AlienEvent)
	Core.ToggleTask("CatchAlien", Options.tgAlienEventEnable.Value, function()
		pcall(Event.CatchAlien)
		task.wait(5)
	end)
	Core.ToggleTask("CheckAlienPet", Options.tgAlienAutoHatch.Value, function()
		pcall(Event.CheckAlienPet)
		task.wait(10)
	end)
	Core.ToggleTask("AutoAlienClaim", Options.tgAlienAutoClaim.Value, Event.AutoAlienClaim)
	Core.ToggleTask("AutoGiftAlien", Options.tgAutoGiftAlien.Value, Event.AutoGiftAlien)

	-- Shop Tasks
	Core.ToggleTask("HardCoreBuy", Options.HardCoreBuyEnable.Value, Shop.HardCoreBuy)
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
			if UI.Options.PetModeEnable.Value then
				task.spawn(function()
					if string.find(Key, "ROOT/GardenGuide/PetData") or Key == "ROOT/BadgeData/PetMaster" then
						if UI.Options.PetMode.Value == "Nightmare" then
							Pet.PetNightmare()
						elseif UI.Options.PetMode.Value == "Mutant" then
							Pet.CheckMakeMutant()
						else
							Pet.Mutation()
						end
					elseif Key == "ROOT/PetMutationMachine/PetReady" then
						if Pet.Mutanting and UI.Options.PetMode.Value == "Mutant" then Pet.ClaimMutantPet() end
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

-- Run initialization
Main.Init()
task.wait(1)
Main.SyncBackgroundTasks()
