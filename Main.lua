--!nocheck
-- [[ AI_Code: Main Entry Point ]]
local Main = {}

-- [[ CONFIGURATION ]]
local DevelopmentMode = false -- SET TO TRUE IF TESTING LOCALLY (Requires local file server)
local BasePath = DevelopmentMode and "http://127.0.0.1:5500/AI_Code/Modules/" or "https://raw.githubusercontent.com/suta007/Lua_EfHub/refs/heads/master/Modules/"

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
		if GetOpt("tgPlaceEggsEn") then pcall(Pet.PlaceEggs) end
		if GetOpt("tgAutoHatchEn") then pcall(Pet.HatchEgg) end
		if GetOpt("tgSellPetEn") then pcall(Pet.SellPetEgg) end
		task.wait(0.5)
	end)

	Core.ToggleTask("ScanSellPetTask", GetOpt("tgSellPetEn"), function()
		pcall(Pet.ScanSellPet)
		task.wait(2)
	end)

	-- Event Tasks
	Core.ToggleTask("AlienEvent", GetOpt("tgAlienEventEnable"), Event.AlienEvent)
	Core.ToggleTask("CatchAlien", GetOpt("tgAlienEventEnable"), function()
		pcall(Event.CatchAlien)
		task.wait(5)
	end)
	Core.ToggleTask("CheckAlienPet", GetOpt("tgAlienAutoHatch"), function()
		pcall(Event.CheckAlienPet)
		task.wait(10)
	end)
	Core.ToggleTask("AutoAlienClaim", GetOpt("tgAlienAutoClaim"), Event.AutoAlienClaim)
	Core.ToggleTask("AutoGiftAlien", GetOpt("tgAutoGiftAlien"), Event.AutoGiftAlien)

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

-- Run initialization
Main.Init()
