-- Modules/Pet.lua
local Pet = {}
local Core = nil
local UI = nil
local Farming = nil

Pet.targetUUID = nil
Pet.Mutanting = false
Pet.isEggProcessing = false
Pet.AgeBreakRunning = false
Pet.currentMainPetUUID = nil
Pet.HungerTable = {}
Pet.EnumToNameCache = {}
Pet.SellPetListInternal = {}

function Pet.GetEquippedPetsUUID()
	local GetData_result = Core.DataService:GetData()
	local EquippedPets = GetData_result.PetsData.EquippedPets or {}
	local UUIDtbl = {}
	for _, uuid in pairs(EquippedPets) do
		if uuid then table.insert(UUIDtbl, uuid) end
	end
	return UUIDtbl
end

function Pet.GetRawPetData(uuid)
	local success, result = pcall(function()
		return Core.ActivePetsService:GetPetData(Core.LocalPlayer.Name, uuid)
	end)
	if success and result then return result end
	return nil
end

function Pet.GetPetLevel(uuid)
	local data = Pet.GetRawPetData(uuid)
	if data and data.PetData then return data.PetData.Level or 1 end
	return 1
end

function Pet.GetPetMutation(uuid)
	local data = Pet.GetRawPetData(uuid)
	if data and data.PetData then
		local rawEnum = data.PetData.MutationType
		if rawEnum then
			return Pet.EnumToNameCache and Pet.EnumToNameCache[rawEnum] or "None"
		else
			return "None"
		end
	end
	return nil
end

function Pet.GetPetType(uuid)
	local data = Pet.GetRawPetData(uuid)
	if data then return data.PetType or "Unknown" end
	return "Unknown"
end

function Pet.GetPetHunger(uuid)
	local data = Pet.GetRawPetData(uuid)
	if data and data.PetData then return data.PetData.Hunger or 0 end
	return 0
end

function Pet.GetPetHungerPercent(uuid)
	local petType = Pet.GetPetType(uuid)
	local maxHunger = (Pet.HungerTable and Pet.HungerTable[petType]) or 10000
	if maxHunger <= 0 then return 0 end
	return 100 * (Pet.GetPetHunger(uuid) / maxHunger)
end

function Pet.GetPetFavorite(uuid)
	local data = Pet.GetRawPetData(uuid)
	if data and data.PetData then return data.PetData.IsFavorite == true end
	return false
end

function Pet.MakePetFavorite(uuid)
	local favoriteEvent = Core.GameEvents:WaitForChild("Favorite_Item")
	if not Pet.GetPetFavorite(uuid) then
		local targetItem = nil
		for _, item in ipairs(Core.LocalPlayer.Backpack:GetChildren()) do
			if item:GetAttribute("ItemType") == "Pet" and item:GetAttribute("PET_UUID") == uuid then
				targetItem = item
				break
			end
		end
		if targetItem then
			favoriteEvent:FireServer(targetItem)
			task.wait(0.3)
			return true
		end
	end
	return false
end

function Pet.GetPetBaseWeight(uuid)
	local data = Pet.GetRawPetData(uuid)
	if data and data.PetData then
		local BaseWeight = tonumber(data.PetData.BaseWeight)
		if BaseWeight then return BaseWeight end
	end
	return nil
end

function Pet.GetPetUUID(petNameTable)
	local petMode = UI.Options.PetMode.Value
	local useFavOnly = UI.Options.UseFavoriteOnly.Value
	local targetMutant = "EfHub"

	if petMode == "Nightmare" then
		targetMutant = "Nightmare"
	elseif petMode == "Mutant" then
		targetMutant = UI.Options.TargetMutantDropdown.Value
	end

	local function IsValidPet(uuid, pType)
		if not table.find(petNameTable, pType) then return false end
		if (petMode == "Mutant" or petMode == "Nightmare") and Pet.GetPetMutation(uuid) == targetMutant then return false end
		if (Pet.GetPetFavorite(uuid) or false) ~= useFavOnly then return false end
		if petMode == "Elephant" and Pet.GetPetBaseWeight(uuid) > 3.5 then return false end
		if petMode == "Level" and Pet.GetPetLevel(uuid) >= 100 then return false end
		return true
	end

	for _, uuid in pairs(Pet.GetEquippedPetsUUID()) do
		if IsValidPet(uuid, Pet.GetPetType(uuid)) then return uuid end
	end

	local data = Core.DataService:GetData()
	local inventory = data and data.PetsData and data.PetsData.PetInventory
	if inventory then
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for kUUID, petData in pairs(v) do
					if type(petData) == "table" then
						local tuuid = petData.UUID or kUUID
						if tuuid and IsValidPet(tuuid, petData.PetType) then return tuuid end
					end
				end
			end
		end
	end
	task.wait(0.5)
	return nil
end

function Pet.EquipPet(uuid)
	Core.GameEvents:WaitForChild("PetsService"):FireServer("EquipPet", uuid)
end
function Pet.UnequipPet(uuid)
	Core.GameEvents:WaitForChild("PetsService"):FireServer("UnequipPet", uuid)
end
function Pet.SwapPetLoadout(Loadout)
	if Loadout == 2 then
		Loadout = 3
	elseif Loadout == 3 then
		Loadout = 2
	end
	Core.GameEvents:WaitForChild("PetsService"):FireServer("SwapPetLoadout", Loadout)
end

function Pet.heldPet(uuid)
	local timeout = 3
	local startTime = tick()
	repeat
		for _, item in ipairs(Core.LocalPlayer.Backpack:GetChildren()) do
			if item:GetAttribute("ItemType") == "Pet" and item:GetAttribute("PET_UUID") == uuid then
				Core.Humanoid:EquipTool(item)
				task.wait(0.3)
				return true
			end
		end
		task.wait(0.2)
	until tick() - startTime > timeout
	return false
end

function Pet.IsActivePet(uuid)
	local scrollFramePath = Core.LocalPlayer.PlayerGui.ActivePetUI.Frame.Main.PetDisplay.ScrollingFrame
	return scrollFramePath:FindFirstChild(uuid) ~= nil
end

function Pet.MakeMutant(uuid)
	if UI.Options.PetMode.Value ~= "Mutant" then return end
	Pet.SwapPetLoadout(UI.Options.TimeSlots.Value)
	task.wait(UI.Options.LoadOutDelay.Value)
	Core.Character:PivotTo(CFrame.new(-236.17, 4.50, 14.36))
	task.wait(0.2)
	if Pet.IsActivePet(uuid) then
		Pet.UnequipPet(uuid)
		task.wait(1)
	end
	if Pet.heldPet(uuid) then
		task.wait(0.5)
		Core.GameEvents:WaitForChild("PetMutationMachineService_RE"):FireServer("SubmitHeldPet")
		task.wait(0.5)
		Core.GameEvents:WaitForChild("ReplicationChannel"):FireServer("PetAssets", Pet.GetPetType(uuid))
		task.wait(1)
		Core.GameEvents:WaitForChild("PetMutationMachineService_RE"):FireServer("StartMachine")
		Pet.Mutanting = true
	end
end

function Pet.ClaimMutantPet()
	Pet.SwapPetLoadout(UI.Options.MutantSlots.Value)
	task.wait(UI.Options.LoadOutDelay.Value * 2)
	Core.GameEvents:WaitForChild("PetMutationMachineService_RE"):FireServer("ClaimMutatedPet")
	task.wait(3)
	pcall(function()
		Core.Humanoid:UnequipTools()
	end)
	Pet.Mutanting = false
	local TargetMutant = UI.Options.TargetMutantDropdown.Value
	task.wait(10)
	if UI.Options.PetModeEnable.Value then
		if TargetMutant == Pet.GetPetMutation(Pet.targetUUID) then
			Pet.MakePetFavorite(Pet.targetUUID)
			Pet.Mutation()
		else
			Pet.Mutation(Pet.targetUUID)
		end
	end
end

function Pet.Mutation(uuid)
	if UI.Options.PetModeEnable.Value then
		local petMode = UI.Options.PetMode.Value
		local TargetLimit = tonumber(UI.Options.AgeLimitInput.Value) or 50
		local TargetPet = UI.GetSelectedItems(UI.Options.TargetPetDropdown.Value)
		Pet.targetUUID = uuid or Pet.GetPetUUID(TargetPet)

		if Pet.targetUUID then
			local age = Pet.GetPetLevel(Pet.targetUUID)
			local function IsEquipPet()
				if petMode == "Mutant" and age >= TargetLimit then return false end
				if petMode == "Level" and age >= TargetLimit then return false end
				if petMode == "Elephant" and age >= TargetLimit and Pet.GetPetBaseWeight(Pet.targetUUID) > 3.5 then return false end
				if petMode == "Nightmare" and Pet.GetPetMutation(Pet.targetUUID) == "Nightmare" then return false end
				return true
			end

			if IsEquipPet() then
				local MyFarm = Farming.GetMyFarm()
				local FarmPoint = MyFarm and MyFarm:FindFirstChild("Spawn_Point") and MyFarm.Spawn_Point.CFrame
				if FarmPoint then
					Core.Character:PivotTo(CFrame.new(FarmPoint.X, FarmPoint.Y, FarmPoint.Z))
					task.wait(0.3)
				end
				Pet.SwapPetLoadout(UI.Options.LevelSlots.Value)
				task.wait(UI.Options.LoadOutDelay.Value)
				pcall(function()
					Pet.EquipPet(Pet.targetUUID)
				end)
			elseif petMode == "Mutant" then
				Pet.MakeMutant(Pet.targetUUID)
			end
		end
	end
end

function Pet.PickFinishPet()
	if not Pet.targetUUID then return end
	local tPetMode = UI.Options.PetMode.Value
	if UI.Options.PetModeEnable.Value and (tPetMode == "Elephant" or tPetMode == "Level") then
		if Pet.GetPetLevel(Pet.targetUUID) >= tonumber(UI.Options.AgeLimitInput.Value) then
			Pet.UnequipPet(Pet.targetUUID)
			task.wait(1)
			Pet.Mutation()
		end
	end
	task.wait(10)
end

function Pet.CheckMakeMutant()
	if UI.Options.PetMode.Value ~= "Mutant" then return false end
	local TargetLevel = tonumber(UI.Options.AgeLimitInput.Value) or 50
	local age = Pet.GetPetLevel(Pet.targetUUID)
	if not age then return end
	task.wait(0.3)
	if age >= TargetLevel then
		Pet.UnequipPet(Pet.targetUUID)
		task.wait(0.3)
		Pet.MakeMutant(Pet.targetUUID)
	end
	return true
end

function Pet.PetNightmare()
	local mutant = Pet.GetPetMutation(Pet.targetUUID)
	if mutant and mutant ~= "Nightmare" then
		if mutant == "Normal" or mutant == "None" then return end
		local petsPhysical = game.Workspace:WaitForChild("PetsPhysical")
		for _, container in ipairs(petsPhysical:GetChildren()) do
			local PetModel = container:FindFirstChild(Pet.targetUUID)
			if PetModel then
				Farming.heldItemName("Cleansing Pet Shard")
				Core.GameEvents:WaitForChild("PetShardService_RE"):FireServer("ApplyShard", PetModel)
			end
		end
	elseif mutant and mutant == "Nightmare" then
		Pet.UnequipPet(Pet.targetUUID)
		task.wait(1)
		Pet.MakePetFavorite(Pet.targetUUID)
		Pet.Mutation()
	end
end

function Pet.FeedPet()
	local petUUID = Pet.GetEquippedPetsUUID()
	if #petUUID == 0 then return end
	for i, uuid in pairs(petUUID) do
		local hunger = tonumber(Pet.GetPetHungerPercent(uuid))
		if hunger <= UI.Options.PetHungerPercent.Value then
			local data = Core.DataService:GetData()
			local inv = data.InventoryData or {}
			local allowList = UI.GetSelectedItems(UI.Options.AllowFoodType.Value)
			local fruitUUID = nil
			for invUuid, Item in pairs(inv) do
				if Item.ItemType == "Holdable" and Item.ItemData and not Item.ItemData.IsFavorite then
					local FruitInv = Item.ItemData.ItemName
					if UI.Options.AllowAllFood.Value or table.find(allowList, FruitInv) then
						fruitUUID = invUuid
						break
					end
				end
			end
			if fruitUUID and Farming.heldItemName(inv[fruitUUID].ItemData.ItemName) then
				Core.GameEvents:WaitForChild("ActivePetService"):FireServer("Feed", uuid)
				task.wait(1)
			end
		end
	end
end

function Pet.calculateCurrentWeight(uuid, petAge)
	local baseWeight = Pet.GetPetBaseWeight(uuid) or 0
	return baseWeight * (0.909 + (0.091 * petAge))
end

function Pet.findMainPet()
	local inventory = Core.DataService:GetData().PetsData.PetInventory
	if not inventory then return nil end
	local targetType = UI.Options.AAB_PetType.Value
	local targetAge = tonumber(UI.Options.AAB_TargetAge.Value) or 125
	for _, v in pairs(inventory) do
		if type(v) == "table" then
			for _, petData in pairs(v) do
				local uuid = petData.UUID
				if petData.PetType == targetType and not Pet.GetPetFavorite(uuid) then
					local petAge = Pet.GetPetLevel(uuid) or 0
					if petAge >= 100 and petAge < targetAge then return uuid end
				end
			end
		end
	end
	return nil
end

function Pet.findDupePet(mainUUID, targetType)
	local inventory = Core.DataService:GetData().PetsData.PetInventory
	if not inventory then return nil end
	for _, v in pairs(inventory) do
		if type(v) == "table" then
			for _, petData in pairs(v) do
				local uuid = petData.UUID
				if uuid ~= mainUUID and petData.PetType == targetType and not Pet.GetPetFavorite(uuid) then
					local petAge = Pet.GetPetLevel(uuid) or 0
					if petAge < 100 then
						local isValid = true
						if UI.Options.AAB_CheckAge.Value then
							local aC, aV = UI.Options.AAB_AgeCond.Value, tonumber(UI.Options.AAB_AgeVal.Value) or 0
							if aC == "Below" and petAge >= aV then isValid = false end
							if aC == "Above" and petAge <= aV then isValid = false end
						end
						if isValid and UI.Options.AAB_CheckWeight.Value then
							local cWeight = Pet.calculateCurrentWeight(uuid, petAge)
							local wC, wV = UI.Options.AAB_WeightCond.Value, tonumber(UI.Options.AAB_WeightVal.Value) or 0
							if wC == "Below" and cWeight >= wV then isValid = false end
							if wC == "Above" and cWeight <= wV then isValid = false end
						end
						if isValid then return uuid end
					end
				end
			end
		end
	end
	return nil
end

function Pet.processAgeBreakMachine()
	if Pet.AgeBreakRunning then return end
	local machineData = Core.DataService:GetData() and Core.DataService:GetData().PetAgeBreakMachine
	if not machineData then return end
	Pet.AgeBreakRunning = true
	pcall(function()
		if machineData.PetReady then
			Core.GameEvents.PetAgeLimitBreak_Claim:FireServer()
			task.wait(1.5)
			return
		end
		if machineData.IsRunning then return end
		local submittedPet = machineData.SubmittedPet
		local hasPetInMachine = submittedPet and type(submittedPet) == "table" and submittedPet.UUID ~= nil
		if not hasPetInMachine then
			if Pet.currentMainPetUUID and Pet.GetPetLevel(Pet.currentMainPetUUID) >= (tonumber(UI.Options.AAB_TargetAge.Value) or 125) then Pet.currentMainPetUUID = nil end
			Pet.currentMainPetUUID = Pet.currentMainPetUUID or Pet.findMainPet()
			if Pet.currentMainPetUUID then
				pcall(function()
					Core.Humanoid:UnequipTools()
				end)
				task.wait(0.3)
				Pet.heldPet(Pet.currentMainPetUUID)
				task.wait(0.5)
				Core.GameEvents.PetAgeLimitBreak_SubmitHeld:FireServer()
				task.wait(2)
			end
		elseif hasPetInMachine and not machineData.IsRunning then
			local dupeUUID = Pet.findDupePet(submittedPet.UUID, submittedPet.PetType)
			if dupeUUID then
				Core.GameEvents.PetAgeLimitBreak_Submit:FireServer({ dupeUUID })
				task.wait(2)
			end
		end
	end)
	Pet.AgeBreakRunning = false
end

function Pet.getBoundary(plate)
	if not plate then return nil end
	local size = plate.Size
	return { cf = plate.CFrame, minX = -size.X / 2 + 1, maxX = size.X / 2 - 1, minZ = -size.Z / 2 + 1, maxZ = size.Z / 2 - 1 }
end

function Pet.getPlate()
	local myPlate = {}
	local MyFarm = Farming.GetMyFarm()
	local plantLocations = MyFarm and MyFarm.Important.Plant_Locations:GetChildren() or {}
	for _, plate in pairs(plantLocations) do
		if plate.Name == "Can_Plant" or plate:IsA("Part") then table.insert(myPlate, plate) end
	end
	return myPlate
end

function Pet.EggInFarm()
	local MyFarm = Farming.GetMyFarm()
	local Objects_Physical = MyFarm and MyFarm:FindFirstChild("Important") and MyFarm.Important:FindFirstChild("Objects_Physical")
	local eggs = {}
	if Objects_Physical then
		for _, oEgg in pairs(Objects_Physical:GetChildren()) do
			if oEgg and oEgg:GetAttribute("OBJECT_TYPE") == "PetEgg" then table.insert(eggs, oEgg) end
		end
	end
	return eggs
end

function Pet.ValidEggs(EggsData, rEggs)
	local spWeight = tonumber(UI.Options.ipSpecialHatchWeight.Value)
	local spEggs, nmEggs = {}, {}
	if not EggsData or not rEggs then return nil, nil end
	local spTypeList = UI.GetSelectedItems(UI.Options.ddSpecialHatchType.Value)
	for _, rEgg in pairs(rEggs) do
		local EggData = EggsData[rEgg:GetAttribute("OBJECT_UUID")]
		if EggData then
			local HatchWeight = EggData.Data.BaseWeight * 1.1
			if spWeight ~= 0 and HatchWeight >= spWeight then
				table.insert(spEggs, rEgg)
			elseif #spTypeList > 0 and table.find(spTypeList, EggData.Data.Type) then
				table.insert(spEggs, rEgg)
			else
				table.insert(nmEggs, rEgg)
			end
		end
	end
	return nmEggs, spEggs
end

function Pet.HatchEgg()
	if not UI.Options.tgAutoHatchEn.Value or Pet.isEggProcessing then return end
	local HatchList = UI.GetSelectedItems(UI.Options.ddEggHatch.Value)
	if #HatchList == 0 then return end

	Pet.isEggProcessing = true
	local myEggs = Pet.EggInFarm()
	local SelectedSlot = Core.DataService:GetData().SaveSlots.SelectedSlot
	local fData = Core.DataService:GetData().SaveSlots.AllSlots[SelectedSlot].SavedObjects
	if not fData or type(fData) ~= "table" then
		Pet.isEggProcessing = false
		return
	end
	local PetsData, petCount, ReadyEggs = {}, 0, {}
	for Key, PetData in pairs(fData) do
		if PetData.Data.CanHatch then
			PetsData[Key] = PetData
			petCount = petCount + 1
		end
	end
	for _, nEggs in pairs(myEggs) do
		if nEggs:GetAttribute("READY") and (table.find(HatchList, "ALL") or table.find(HatchList, nEggs:GetAttribute("EggName"))) then table.insert(ReadyEggs, nEggs) end
	end
	if petCount ~= #ReadyEggs then
		Pet.isEggProcessing = false
		return
	end

	local NormalEggs, SpecialEggs = Pet.ValidEggs(PetsData, ReadyEggs)
	if #NormalEggs > 0 then
		Pet.SwapPetLoadout(tonumber(UI.Options.ddHatchSlot.Value))
		task.wait(10)
		for _, rEgg in pairs(NormalEggs) do
			Core.GameEvents.PetEggService:FireServer("HatchPet", rEgg)
			task.wait(tonumber(UI.Options.ipHatchDelay.Value))
		end
	end
	task.wait(10)
	if #SpecialEggs > 0 then
		Pet.SwapPetLoadout(tonumber(UI.Options.ddSpecialHatchSlot.Value))
		task.wait(10)
		for _, sEgg in pairs(SpecialEggs) do
			Core.GameEvents.PetEggService:FireServer("HatchPet", sEgg)
			task.wait(tonumber(UI.Options.ipHatchDelay.Value))
		end
	end
	pcall(function()
		Core.Humanoid:UnequipTools()
	end)
	Pet.isEggProcessing = false
end

local EggMultiple = 0
function Pet.PlaceEggs()
	if not UI.Options.tgPlaceEggsEn.Value or Pet.isEggProcessing then return end
	local PlaceList = UI.GetSelectedItems(UI.Options.ddPlaceEgg.Value)
	if #PlaceList == 0 then return end

	local farmEgg = Pet.EggInFarm()
	if #farmEgg >= tonumber(UI.Options.ipMaxEggs.Value) then
		local lo = Core.DataService:GetData().PetsData.SelectedPetLoadout
		if lo ~= tonumber(UI.Options.ddSpeedEggSlot.Value) then
			Pet.SwapPetLoadout(tonumber(UI.Options.ddSpeedEggSlot.Value))
			task.wait(5)
		end
		EggMultiple = 0
		return
	end
	Pet.isEggProcessing = true
	local Plate = Pet.getPlate()
	local Boundary = Pet.getBoundary(Plate[2])
	local x, y, z = Boundary.maxX, 0.1355266571044922, Boundary.minZ
	z = z + (4 * EggMultiple)
	EggMultiple = EggMultiple + 1
	if z > Boundary.maxZ then
		x = x - 4
		z = Boundary.minZ
		EggMultiple = 1
	end
	if x < Boundary.minX then
		Pet.isEggProcessing = false
		return
	end
	local NewPos = (Boundary.cf * CFrame.new(x, 0, z)).Position

	if #PlaceList > 0 then Farming.heldItemName(PlaceList[Random.new():NextInteger(1, #PlaceList)]) end
	task.wait(0.1)
	Core.GameEvents:WaitForChild("PetEggService"):FireServer("CreateEgg", Vector3.new(NewPos.X, y, NewPos.Z))
	task.wait(tonumber(UI.Options.ipPlaceEggDelay.Value))
	Pet.isEggProcessing = false
	pcall(function()
		Core.Humanoid:UnequipTools()
	end)
end

function Pet.IsValidSellPet(petData)
	local sSellMode, sSellWeight = UI.Options.ddSellMode.Value, tonumber(UI.Options.ipSellWeight.Value)
	if not sSellWeight then return false end
	local base, sMutant, isFav = petData.PetData.BaseWeight, petData.PetData.MutationType or "m", petData.PetData.IsFavorite
	if isFav then return false end
	local typeList = UI.GetSelectedItems(UI.Options.ddSellPetType.Value)
	if not UI.Options.tgSellMutantPet.Value and sMutant ~= "m" then
		return false
	elseif sSellWeight ~= 0 and UI.Options.ddSellWeightMode.Value == "Below" and base >= sSellWeight then
		return false
	elseif sSellWeight ~= 0 and UI.Options.ddSellWeightMode.Value == "Above" and base <= sSellWeight then
		return false
	elseif sSellMode == "Black list" and table.find(typeList, petData.PetType) then
		return false
	elseif sSellMode == "White list" and not table.find(typeList, petData.PetType) then
		return false
	end
	return true
end

function Pet.ScanSellPet()
	if not UI.Options.tgSellPetEn.Value or Pet.isEggProcessing then return end
	local inventory = Core.DataService:GetData().PetsData.PetInventory
	if inventory then
		table.clear(Pet.SellPetListInternal)
		for _, v in pairs(inventory) do
			if type(v) == "table" then
				for _, petData in pairs(v) do
					if type(petData) == "table" and Pet.IsValidSellPet(petData) then table.insert(Pet.SellPetListInternal, petData.UUID) end
				end
			end
		end
	end
end

function Pet.SellPetEgg()
	if not UI.Options.tgSellPetEn.Value or Pet.isEggProcessing or #Pet.SellPetListInternal == 0 then return end
	Pet.isEggProcessing = true
	Pet.SwapPetLoadout(tonumber(UI.Options.ddSellPetSlot.Value))
	task.wait(10)
	for _, uuid in pairs(Pet.SellPetListInternal) do
		if Pet.heldPet(uuid) then Core.GameEvents:WaitForChild("SellPet_RE"):FireServer() end
		task.wait(UI.Options.ipSellPetDelay.Value)
	end
	table.clear(Pet.SellPetListInternal)
	Pet.isEggProcessing = false
end

function Pet.Init(RefCore, RefUI, RefFarming)
	Core = RefCore
	UI = RefUI
	Farming = RefFarming

	local PetData = require(Core.ReplicatedStorage.Data.PetRegistry.PetList)
	for petName, petInfo in pairs(PetData) do
		Pet.HungerTable[petName] = petInfo["DefaultHunger"]
	end

	local MutantData = require(Core.ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)
	for mutantName, mutantInfo in pairs(MutantData["PetMutationRegistry"]) do
		if type(mutantInfo) == "table" and mutantInfo.EnumId then Pet.EnumToNameCache[mutantInfo.EnumId] = mutantName end
	end

	Pet.BuildUI()
end

function Pet.BuildUI()
	local Tabs = UI.Tabs
	local Options = UI.Options
	local Sync = function()
		if UI.SyncBackgroundTasks then UI.SyncBackgroundTasks() end
	end

	local PetTable = {}
	local PetData = require(Core.ReplicatedStorage.Data.PetRegistry.PetList)
	for petName, _ in pairs(PetData) do
		table.insert(PetTable, petName)
	end
	table.sort(PetTable)

	local MutantData = require(Core.ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)
	local MutantTable = {}
	for mutantName, mutantInfo in pairs(MutantData["PetMutationRegistry"]) do
		if type(mutantInfo) == "table" and mutantInfo.EnumId then table.insert(MutantTable, mutantName) end
	end
	table.sort(MutantTable)

	local PetWorkSection = Tabs.Pet:AddCollapsibleSection("Pet Farming", false)
	PetWorkSection:AddDropdown("PetMode", {
		Title = "Pet Mode",
		Values = { "Nightmare", "Elephant", "Mutant", "Level" },
		Default = "Nightmare",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetWorkSection:AddToggle("PetModeEnable", {
		Title = "Enable Pet Farm",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			pcall(Pet.Mutation)
			--if Pet.Mutation then Pet.Mutation() end
			Sync()
		end,
	})
	PetWorkSection:AddDropdown("TargetPetDropdown", {
		Title = "Target Pet",
		Values = PetTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetWorkSection:AddToggle("UseFavoriteOnly", {
		Title = "Use Favorite Pet Only",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetWorkSection:AddDropdown("TargetMutantDropdown", {
		Title = "Target Mutant",
		Values = MutantTable,
		Multi = false,
		Default = "",
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetWorkSection:AddInput("AgeLimitInput", {
		Title = "Age Limit",
		Default = 50,
		Filter = "Number",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetWorkSection:AddInput("LoadOutDelay", {
		Title = "Loadout Switch Delay time",
		Default = 10,
		Filter = "Number",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetWorkSection:AddDropdown("LevelSlots", {
		Title = "Select Loadout",
		Values = { 1, 2, 3, 4, 5, 6 },
		Default = 1,
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetWorkSection:AddDropdown("TimeSlots", {
		Title = "Select Time Slot",
		Values = { 1, 2, 3, 4, 5, 6 },
		Default = 2,
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetWorkSection:AddDropdown("MutantSlots", {
		Title = "Select Mutant Slot",
		Values = { 1, 2, 3, 4, 5, 6 },
		Default = 3,
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local AutoAgeBreakSection = Tabs.Pet:AddCollapsibleSection("Auto Age Break")
	AutoAgeBreakSection:AddToggle("AAB_Enabled", {
		Title = "Enable Auto Age Break",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	AutoAgeBreakSection:AddDropdown("AAB_PetType", {
		Title = "Select Pet Type",
		Values = PetTable,
		Default = "",
		Multi = false,
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	AutoAgeBreakSection:AddInput("AAB_TargetAge", {
		Title = "Target Break Age",
		Default = 125,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	AutoAgeBreakSection:AddToggle("AAB_CheckWeight", {
		Title = "Check Dupe Weight?",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	AutoAgeBreakSection:AddDropdown("AAB_WeightCond", {
		Title = "Weight Condition",
		Values = { "Below", "Above" },
		Default = "Below",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	AutoAgeBreakSection:AddInput("AAB_WeightVal", {
		Title = "Dupe Weight Value",
		Default = 10,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	AutoAgeBreakSection:AddToggle("AAB_CheckAge", {
		Title = "Check Dupe Age?",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	AutoAgeBreakSection:AddDropdown("AAB_AgeCond", {
		Title = "Age Condition",
		Values = { "Below", "Above" },
		Default = "Below",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	AutoAgeBreakSection:AddInput("AAB_AgeVal", {
		Title = "Dupe Age Value",
		Default = 30,
		Numeric = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local FruitTable = {}
	local SeedData = require(Core.ReplicatedStorage.Data.SeedData)
	for FruitName, _ in pairs(SeedData) do
		table.insert(FruitTable, FruitName)
	end
	table.sort(FruitTable)

	local PetFeedSection = Tabs.Pet:AddCollapsibleSection("Pet Feeding", false)
	PetFeedSection:AddToggle("AutoFeedPet", {
		Title = "Auto Feed",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetFeedSection:AddToggle("AllowAllFood", {
		Title = "Allow All Food",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetFeedSection:AddDropdown("AllowFoodType", {
		Title = "Allow Food Type",
		Values = FruitTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetFeedSection:AddSlider("PetHungerPercent", {
		Title = "Pet Hunger Percent",
		Min = 1,
		Max = 100,
		Default = 80,
		Rounding = 1,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local PetGiftSection = Tabs.Pet:AddCollapsibleSection("Auto Accept Pet gift", false)
	PetGiftSection:AddToggle("tgAcceptPetGift", {
		Title = "Enable Auto Accept",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PetGiftSection:AddInput("inPetGiftDelay", {
		Title = "Accept Delay (s)",
		Default = 0.1,
		Filter = "Number",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local HatchSection = Tabs.Pet:AddCollapsibleSection("Auto Hatch Eggs", false)
	HatchSection:AddToggle("tgPlaceEggsEn", {
		Title = "Place Eggs",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	local AllEggTable = {}
	local AllPetEggs = require(Core.ReplicatedStorage.Data.PetRegistry.PetEggs)
	for EggName, _ in pairs(AllPetEggs) do
		table.insert(AllEggTable, EggName)
	end
	HatchSection:AddDropdown("ddPlaceEgg", {
		Title = "Select Eggs",
		Values = AllEggTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddInput("ipMaxEggs", {
		Title = "Max Eggs",
		Default = 3,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddDropdown("ddSpeedEggSlot", {
		Title = "Select Speed Loadout",
		Values = { 1, 2, 3, 4, 5, 6 },
		Default = 1,
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddInput("ipPlaceEggDelay", {
		Title = "Place Eggs Delay",
		Default = 0.2,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddToggle("tgAutoHatchEn", {
		Title = "Auto Hatch",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	local tempTable = { "ALL" }
	for i, v in ipairs(AllEggTable) do
		table.insert(tempTable, v)
	end
	HatchSection:AddDropdown("ddEggHatch", {
		Title = "Select Egg to Hatch",
		Values = tempTable,
		Multi = true,
		Default = { "ALL" },
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddDropdown("ddHatchSlot", {
		Title = "Select Hatch Loadout",
		Values = { 1, 2, 3, 4, 5, 6 },
		Default = 2,
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddInput("ipHatchDelay", {
		Title = "Hatch Egg Delay",
		Default = 0.2,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddInput("ipSpecialHatchWeight", {
		Title = "Special Hatch Weight",
		Default = 0,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddDropdown("ddSpecialHatchType", {
		Title = "Special Hatch Pet",
		Values = PetTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddDropdown("ddSpecialHatchSlot", {
		Title = "Select Hatch Loadout",
		Values = { 1, 2, 3, 4, 5, 6 },
		Default = 4,
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddToggle("tgSellPetEn", {
		Title = "Auto Sell Pet",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddDropdown("ddSellPetSlot", {
		Title = "Select Sell Pet Loadout",
		Values = { 1, 2, 3, 4, 5, 6 },
		Default = 3,
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddDropdown("ddSellPetType", {
		Title = "Sell Pet Type",
		Values = PetTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddDropdown("ddSellMode", {
		Title = "Sell Pet Mode",
		Values = { "ALL", "White list", "Black list" },
		Default = "White list",
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddInput("ipSellWeight", {
		Title = "Sell Pet Weight",
		Default = 0,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddDropdown("ddSellWeightMode", {
		Title = "Sell Weight Mode",
		Values = { "Below", "Above" },
		Default = "Below",
		Multi = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddToggle("tgSellMutantPet", {
		Title = "Sell Mutant Pet",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	HatchSection:AddInput("ipSellPetDelay", {
		Title = "Sell Pet Delay",
		Default = 0.2,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
end

return Pet
