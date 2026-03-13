-- Modules/Farming.lua
local Farming = {}
local Core = nil
local UI = nil

-- State variables
Farming.FruitQueue1 = {}
Farming.FruitQueue2 = {}
Farming.IsScanning1 = false
Farming.IsScanning2 = false
Farming.isPlantHidden = false
Farming.isFruitHidden = false
Farming.CollectDelay = 0.3

local FruitTable = {}

function Farming.Init(RefCore, RefUI)
	Core = RefCore
	UI = RefUI

	local FruitData = require(Core.ReplicatedStorage.Data.SeedData)
	for FruitName, _ in pairs(FruitData) do
		table.insert(FruitTable, FruitName)
	end
	table.sort(FruitTable)

	Farming.BuildUI()
	Farming.SetupTracker()
end

function Farming.ApplyAntiLag()
	local Lighting = Core.Lighting
	local Terrain = workspace.Terrain
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.Brightness = 0
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 1
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
	pcall(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
end

function Farming.GetMyFarm()
	local farmFolder = workspace:FindFirstChild("Farm")
	if not farmFolder then return nil end
	for _, oFarm in pairs(farmFolder:GetChildren()) do
		local success, owner = pcall(function()
			return oFarm.Important.Data.Owner.Value
		end)
		if success and owner == Core.MyName then return oFarm end
	end
	return nil
end

function Farming.GetPlantsFolder()
	local MyFarm = Farming.GetMyFarm()
	local Farm_Important = MyFarm and MyFarm:FindFirstChild("Important")
	return Farm_Important and Farm_Important:FindFirstChild("Plants_Physical")
end

function Farming.IsFruit(obj)
	local current = obj
	while current and current ~= workspace do
		if current.Name == "Fruits" then return true end
		current = current.Parent
	end
	return false
end

function Farming.SetVisibility(obj, isHidden)
	if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Decal") or obj:IsA("Texture") then
		if isHidden then
			if not obj:GetAttribute("OriginalTrans") then obj:SetAttribute("OriginalTrans", obj.Transparency) end
			obj.Transparency = 1
		else
			local orig = obj:GetAttribute("OriginalTrans")
			if orig then obj.Transparency = orig end
		end
	elseif obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") or obj:IsA("Fire") or obj:IsA("Trail") then
		if isHidden then
			if obj:GetAttribute("OriginalEnabled") == nil then obj:SetAttribute("OriginalEnabled", obj.Enabled) end
			obj.Enabled = false
		else
			local orig = obj:GetAttribute("OriginalEnabled")
			if orig ~= nil then obj.Enabled = orig end
		end
	end
end

function Farming.HidePlant(state)
	Farming.isPlantHidden = state
	local PlantFolder = Farming.GetPlantsFolder()
	if not PlantFolder then return end
	for _, obj in ipairs(PlantFolder:GetDescendants()) do
		if not Farming.IsFruit(obj) then Farming.SetVisibility(obj, state) end
	end
end

function Farming.HideFruit(state)
	Farming.isFruitHidden = state
	local PlantFolder = Farming.GetPlantsFolder()
	if not PlantFolder then return end
	for _, obj in ipairs(PlantFolder:GetDescendants()) do
		if Farming.IsFruit(obj) then Farming.SetVisibility(obj, state) end
	end
end

function Farming.SetupTracker()
	local PlantFolder = Farming.GetPlantsFolder()
	if PlantFolder then
		PlantFolder.DescendantAdded:Connect(function(newObj)
			task.wait()
			if Farming.IsFruit(newObj) then
				if Farming.isFruitHidden then Farming.SetVisibility(newObj, true) end
			else
				if Farming.isPlantHidden then Farming.SetVisibility(newObj, true) end
			end
		end)
	end
end

-- Collect Logic (optimized)
function Farming.CheckFruit(model, config)
	if not model or not model:IsA("Model") then return false end
	if config.CheckFruitType then
		local tFruitType = model.Name
		local isFound = table.find(config.FruitType, tFruitType) ~= nil
		if isFound == config.ExcludeFruitType then return false end
	end
	if config.CheckMutant then
		local hasMutant = false
		for _, v in pairs(config.MutantType) do
			if model:GetAttribute(v) == true then
				hasMutant = true
				break
			end
		end
		if hasMutant == config.ExceptMutant then return false end
	end
	if config.CheckVariant then
		local VariantObj = model:FindFirstChild("Variant")
		if not VariantObj then return false end
		local isVariantMatch = (VariantObj.Value == config.VariantType)
		if isVariantMatch == config.ExceptVariant then return false end
	end
	if config.CheckWeight then
		local weightObj = model:FindFirstChild("Weight")
		if not weightObj then return false end
		local tWeight = weightObj.Value
		if config.WeightType == "Above" and not (tWeight >= config.WeightValue) then
			return false
		elseif config.WeightType == "Below" and not (tWeight < config.WeightValue) then
			return false
		end
	end
	return true
end

function Farming.GetFruitConfig1()
	return {
		CheckFruitType = UI.Options.tgCheckFruitType and UI.Options.tgCheckFruitType.Value,
		FruitType = UI.Options.ddFruitType and UI.GetSelectedItems(UI.Options.ddFruitType.Value) or {},
		ExcludeFruitType = UI.Options.tgExcludeFruitType and UI.Options.tgExcludeFruitType.Value,
		CheckMutant = UI.Options.tgCheckMutant and UI.Options.tgCheckMutant.Value,
		MutantType = UI.Options.ddMutantType and UI.GetSelectedItems(UI.Options.ddMutantType.Value) or {},
		ExceptMutant = UI.Options.tgExceptMutant and UI.Options.tgExceptMutant.Value,
		CheckVariant = UI.Options.tgCheckVariant and UI.Options.tgCheckVariant.Value,
		VariantType = UI.Options.ddVariantType and UI.Options.ddVariantType.Value or "Normal",
		ExceptVariant = UI.Options.tgExceptVariant and UI.Options.tgExceptVariant.Value,
		CheckWeight = UI.Options.tgCheckWeight and UI.Options.tgCheckWeight.Value,
		WeightType = UI.Options.ddWeightType and UI.Options.ddWeightType.Value or "Below",
		WeightValue = UI.Options.ipWeightValue and tonumber(UI.Options.ipWeightValue.Value) or 100,
	}
end

function Farming.GetFruitConfig2()
	return {
		CheckFruitType = UI.Options.tgCheckFruitType2 and UI.Options.tgCheckFruitType2.Value,
		FruitType = UI.Options.ddFruitType2 and UI.GetSelectedItems(UI.Options.ddFruitType2.Value) or {},
		ExcludeFruitType = UI.Options.tgExcludeFruitType2 and UI.Options.tgExcludeFruitType2.Value,
		CheckMutant = UI.Options.tgCheckMutant2 and UI.Options.tgCheckMutant2.Value,
		MutantType = UI.Options.ddMutantType2 and UI.GetSelectedItems(UI.Options.ddMutantType2.Value) or {},
		ExceptMutant = UI.Options.tgExceptMutant2 and UI.Options.tgExceptMutant2.Value,
		CheckVariant = UI.Options.tgCheckVariant2 and UI.Options.tgCheckVariant2.Value,
		VariantType = UI.Options.ddVariantType2 and UI.Options.ddVariantType2.Value or "Normal",
		ExceptVariant = UI.Options.tgExceptVariant2 and UI.Options.tgExceptVariant2.Value,
		CheckWeight = UI.Options.tgCheckWeight2 and UI.Options.tgCheckWeight2.Value,
		WeightType = UI.Options.ddWeightType2 and UI.Options.ddWeightType2.Value or "Below",
		WeightValue = UI.Options.ipWeightValue2 and tonumber(UI.Options.ipWeightValue2.Value) or 100,
	}
end

function Farming.ScanFarmTask(mode)
	local sIsScanning, sFruitQueue, sEnable
	if mode == 1 then
		sIsScanning, sFruitQueue, sEnable = Farming.IsScanning1, Farming.FruitQueue1, UI.Options.tgCollectFruitEnable.Value
	else
		sIsScanning, sFruitQueue, sEnable = Farming.IsScanning2, Farming.FruitQueue2, UI.Options.tgCollectFruitEnable2.Value
	end
	if sIsScanning then return end

	local function setScanningState(state)
		if mode == 1 then
			Farming.IsScanning1 = state
		else
			Farming.IsScanning2 = state
		end
	end

	setScanningState(true)

	task.spawn(function()
		table.clear(sFruitQueue)
		local Plants_Physical = Farming.GetPlantsFolder()
		if Plants_Physical then
			local count = 0
			local config = Farming.GetFruitConfig1()
			for _, plant in ipairs(Plants_Physical:GetChildren()) do
				if not sEnable then break end
				local FruitsContainer = plant:FindFirstChild("Fruits")
				local itemsToCheck = FruitsContainer and FruitsContainer:GetChildren() or { plant }
				for _, item in ipairs(itemsToCheck) do
					if item:IsA("Model") then
						local Prompt = item:FindFirstChild("ProximityPrompt", true)
						if Prompt and Prompt.Enabled and Farming.CheckFruit(item, config) then table.insert(sFruitQueue, item) end
					end
				end
				count = count + 1
				if count % 50 == 0 then task.wait() end
			end
		end
		setScanningState(false)
	end)
end

function Farming.CollectFruitWorker(mode)
	local isEnabled, queue, isScanning, scanMode

	if mode == 1 then
		isEnabled, queue, isScanning, scanMode = UI.Options.tgCollectFruitEnable.Value, Farming.FruitQueue1, Farming.IsScanning1, 1
	elseif mode == 2 then
		isEnabled, queue, isScanning, scanMode = UI.Options.tgCollectFruitEnable2.Value, Farming.FruitQueue2, Farming.IsScanning2, 2
	end

	if not isEnabled then
		table.clear(queue)
		task.wait(1)
		return
	end
	local success, isFull = pcall(function()
		return Core.InventoryService.IsMaxInventory(Core.LocalPlayer)
	end)
	if success and isFull then
		table.clear(queue)
		task.wait(1)
		return
	end

	if #queue > 0 then
		local itemToCollect = table.remove(queue, 1)
		if itemToCollect and itemToCollect.Parent and itemToCollect:FindFirstChild("ProximityPrompt", true) then
			Core.CollectEvent:FireServer({ itemToCollect })
			task.wait(Farming.CollectDelay)
			return
		end
	else
		if not isScanning then Farming.ScanFarmTask(scanMode) end
		task.wait(0.5)
		return
	end
	task.wait()
end

function Farming.AutoPlant()
	local pos = nil
	if UI.Options.ddPlantPosition.Value == "User Position" then
		local root = Core.GetCharacter() and Core.GetCharacter():FindFirstChild("HumanoidRootPart")
		if root then pos = Core.GetCharacter():GetPivot().Position end
	end
	local tPlant = UI.Options.ddPlantFruitType.Value
	local tSeed = tPlant .. " Seed"

	if Farming.heldItemName then Farming.heldItemName(tSeed) end

	if pos then
		local args = { vector.create(pos.X, pos.Y, pos.Z), tPlant }
		Core.GameEvents:WaitForChild("Plant_RE"):FireServer(unpack(args))
	end
end

function Farming.heldItemName(itemName)
	if not Core.LocalPlayer.Character then return false end
	local Humanoid = Core.LocalPlayer.Character:FindFirstChild("Humanoid")
	if not Humanoid then return false end

	for _, item in ipairs(Core.LocalPlayer.Backpack:GetChildren()) do
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

function Farming.AutoSellAll()
	if UI.Options.tgAutoSellALL.Value then
		local success, isFull = pcall(function()
			return Core.InventoryService.IsMaxInventory(Core.LocalPlayer)
		end)
		if success and isFull then
			local Previous = Core.GetCharacter() and Core.GetCharacter():GetPivot()
			if Previous then
				Core.GetCharacter():PivotTo(CFrame.new(36.58, 4.50, 0.43))
				task.wait(0.3)
				Core.GameEvents.Sell_Inventory:FireServer()
				task.wait(0.5)
				Core.GetCharacter():PivotTo(Previous)
			end
		end
	end
	task.wait(1)
end

function Farming.ShovelPlant()
	if not UI.Options.tgAutoPlantShovel.Value then return end
	local Plants_Physical = Farming.GetPlantsFolder()

	local character = Core.LocalPlayer.Character
	if character and character:FindFirstChild("Humanoid") then pcall(function()
		character.Humanoid:UnequipTools()
	end) end

	local ShovelPlantList = UI.GetSelectedItems(UI.Options.ddShovelPlant.Value)
	local myShovel = Core.LocalPlayer.Backpack:FindFirstChild("Shovel [Destroy Plants]")

	if Plants_Physical and myShovel then
		for _, plant in pairs(Plants_Physical:GetChildren()) do
			if table.find(ShovelPlantList, plant.Name) then
				if character and character:FindFirstChild("Humanoid") then pcall(function()
					character.Humanoid:EquipTool(myShovel)
				end) end
				Core.GameEvents:WaitForChild("Remove_Item"):FireServer(plant)
				task.wait(0.1)
			end
		end
	end
end

function Farming.Reclaim()
	if not UI.Options.tgReclaim.Value then return end

	local character = Core.LocalPlayer.Character
	if character and character:FindFirstChild("Humanoid") then pcall(function()
		character.Humanoid:UnequipTools()
	end) end

	local Backpack = Core.LocalPlayer.Backpack
	local myReclaimer
	for _, item in pairs(Backpack:GetChildren()) do
		if item:IsA("Tool") and string.find(item.Name, "^Reclaimer") then
			myReclaimer = item
			break
		end
	end

	local Plants_Physical = Farming.GetPlantsFolder()
	local ReclaimPlantList = UI.GetSelectedItems(UI.Options.ddReclaim.Value)
	if Plants_Physical and myReclaimer then
		for _, plant in pairs(Plants_Physical:GetChildren()) do
			if table.find(ReclaimPlantList, plant.Name) then
				if character and character:FindFirstChild("Humanoid") then pcall(function()
					character.Humanoid:EquipTool(myReclaimer)
				end) end
				Core.GameEvents:WaitForChild("ReclaimerService_RE"):FireServer("TryReclaim", plant)
				task.wait(0.1)
			end
		end
	end
end

function Farming.Trowel()
	if not UI.Options.tgTrowel.Value then return end

	local character = Core.LocalPlayer.Character
	if character and character:FindFirstChild("Humanoid") then pcall(function()
		character.Humanoid:UnequipTools()
	end) end

	local Backpack = Core.LocalPlayer.Backpack
	local myTrowel
	for _, item in pairs(Backpack:GetChildren()) do
		if item:IsA("Tool") and string.find(item.Name, "Trowel") then
			myTrowel = item
			break
		end
	end

	local Plants_Physical = Farming.GetPlantsFolder()
	local TrowelPlantList = UI.GetSelectedItems(UI.Options.ddTrowel.Value)
	if Plants_Physical and myTrowel then
		for _, plant in pairs(Plants_Physical:GetChildren()) do
			if table.find(TrowelPlantList, plant.Name) then
				if character and character:FindFirstChild("Humanoid") then pcall(function()
					character.Humanoid:EquipTool(myTrowel)
				end) end
				Core.GameEvents:WaitForChild("Move_Item"):FireServer(plant)
				task.wait(0.1)
			end
		end
	end
end

function Farming.BuildUI()
	local Tabs = UI.Tabs
	local Options = UI.Options
	local Sync = function()
		if UI.SyncBackgroundTasks then UI.SyncBackgroundTasks() end
	end

	local FruitTable = {}
	local FruitData = require(Core.ReplicatedStorage.Data.SeedData)
	for FruitName, _ in pairs(FruitData) do
		table.insert(FruitTable, FruitName)
	end
	table.sort(FruitTable)

	local MutationData = Core.DataService:GetData().GardenGuide.MutationData
	local MutationTable = {}
	if MutationData then
		for MutationName, _ in pairs(MutationData) do
			table.insert(MutationTable, MutationName)
		end
	end

	Tabs.Main:AddButton({
		Title = "Anti Lag",
		Callback = function()
			pcall(Farming.ApplyAntiLag)
		end,
	})
	Tabs.Main:AddToggle("tgHideFruitToggle", {
		Title = "Hide Fruits",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Farming.HideFruit(Value)
		end,
	})
	Tabs.Main:AddToggle("tgHidePlantToggle", {
		Title = "Hide Plants",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Farming.HidePlant(Value)
		end,
	})

	local SellFruitSection = Tabs.Farm:AddCollapsibleSection("Sell Fruit", false)
	SellFruitSection:AddToggle("tgAutoSellALL", {
		Title = "Auto Sell ALL",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	SellFruitSection:AddToggle("AutoSellFruit", {
		Title = "Auto Sell Fruit",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local CollectSection = Tabs.Farm:AddCollapsibleSection("Collect Fruit", false)
	CollectSection:AddToggle("tgCollectFruitEnable", {
		Title = "Enable Auto Collect Fruit",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddInput("inCollectDelay", {
		Title = "Collect Delay",
		Default = 0.3,
		Min = 0.1,
		Max = 3600,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddToggle("tgCheckFruitType", {
		Title = "Check Fruit Type",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddDropdown("ddFruitType", {
		Title = "Fruit Type",
		Values = FruitTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddToggle("tgExcludeFruitType", {
		Title = "Exclude Fruit Type",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	CollectSection:AddToggle("tgCheckMutant", {
		Title = "Check Mutant",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddDropdown("ddMutantType", {
		Title = "Mutant Type",
		Values = MutationTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddToggle("tgExceptMutant", {
		Title = "Except Mutant",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	CollectSection:AddToggle("tgCheckVariant", {
		Title = "Check Variant",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddDropdown("ddVariantType", {
		Title = "Variant Type",
		Values = { "Normal", "Silver", "Gold", "Rainbow", "Diamond" },
		Multi = false,
		Default = "Normal",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddToggle("tgExceptVariant", {
		Title = "Except Variant",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	CollectSection:AddToggle("tgCheckWeight", {
		Title = "Check Weight",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddDropdown("ddWeightType", {
		Title = "Weight Type",
		Values = { "Above", "Below" },
		Multi = false,
		Default = "Below",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection:AddInput("ipWeightValue", {
		Title = "Weight Value",
		Default = "100",
		Numeric = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local CollectSection2 = Tabs.Farm:AddCollapsibleSection("Collect Fruit 2", false)
	CollectSection2:AddToggle("tgCollectFruitEnable2", {
		Title = "Enable Auto Collect Fruit 2",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddInput("inCollectDelay2", {
		Title = "Collect Delay 2",
		Default = 0.3,
		Min = 0.1,
		Max = 3600,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddToggle("tgCheckFruitType2", {
		Title = "Check Fruit Type",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddDropdown("ddFruitType2", {
		Title = "Fruit Type",
		Values = FruitTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddToggle("tgExcludeFruitType2", {
		Title = "Exclude Fruit Type",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	CollectSection2:AddToggle("tgCheckMutant2", {
		Title = "Check Mutant",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddDropdown("ddMutantType2", {
		Title = "Mutant Type",
		Values = MutationTable,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddToggle("tgExceptMutant2", {
		Title = "Except Mutant",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	CollectSection2:AddToggle("tgCheckVariant2", {
		Title = "Check Variant",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddDropdown("ddVariantType2", {
		Title = "Variant Type",
		Values = { "Normal", "Silver", "Gold", "Rainbow", "Diamond" },
		Multi = false,
		Default = "Normal",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddToggle("tgExceptVariant2", {
		Title = "Except Variant",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	CollectSection2:AddToggle("tgCheckWeight2", {
		Title = "Check Weight",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddDropdown("ddWeightType2", {
		Title = "Weight Type",
		Values = { "Above", "Below" },
		Multi = false,
		Default = "Below",
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	CollectSection2:AddInput("ipWeightValue2", {
		Title = "Weight Value",
		Default = "100",
		Numeric = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local PlantSection = Tabs.Farm:AddCollapsibleSection("Plant Fruit", false)
	PlantSection:AddToggle("tgPlantFruitEnable", {
		Title = "Plant Fruit",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	PlantSection:AddDropdown("ddPlantFruitType", {
		Title = "Seed to Plant",
		Values = FruitTable,
		Multi = false,
		Default = "",
		Searchable = true,
		Callback = function()
			Core.QuickSave()
			Sync()
		end,
	})
	PlantSection:AddDropdown("ddPlantPosition", {
		Title = "Plant Position",
		Values = { "User Position" },
		Multi = false,
		Default = "",
		Callback = function()
			Core.QuickSave()
			Sync()
		end,
	})
	PlantSection:AddInput("inPlantDelay", {
		Title = "Plant Delay (ms)",
		Default = "0.3",
		Numeric = true,
		Callback = function()
			Core.QuickSave()
			Sync()
		end,
	})

	local tempShovelDD = { "ALL" }
	for _, v in ipairs(FruitTable) do
		table.insert(tempShovelDD, v)
	end

	local ShovelSection = Tabs.Auto:AddCollapsibleSection("Shovel", false)
	ShovelSection:AddToggle("tgAutoPlantShovel", {
		Title = "Auto Plant Shovel",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	ShovelSection:AddDropdown("ddShovelPlant", {
		Title = "Select Plant(s) to Shovel",
		Values = tempShovelDD,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	ShovelSection:AddToggle("tgAutoCropShovel", {
		Title = "Auto Crop Shovel",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	ShovelSection:AddDropdown("ddShovelCrop", {
		Title = "Select Crop(s) to Shovel",
		Values = tempShovelDD,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	ShovelSection:AddToggle("tgShovelCosmetic", {
		Title = "Shovel All Cosmetic",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local ReclaimSection = Tabs.Auto:AddCollapsibleSection("Reclaim", false)
	ReclaimSection:AddToggle("tgReclaim", {
		Title = "Reclaim",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	ReclaimSection:AddDropdown("ddReclaim", {
		Title = "Reclaim Type",
		Values = tempShovelDD,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})

	local TrowelSection = Tabs.Auto:AddCollapsibleSection("Trowel", false)
	TrowelSection:AddToggle("tgTrowel", {
		Title = "Trowel",
		Default = false,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
	TrowelSection:AddDropdown("ddTrowel", {
		Title = "Trowel Type",
		Values = tempShovelDD,
		Multi = true,
		Default = {},
		Searchable = true,
		Callback = function(Value)
			Core.QuickSave()
			Sync()
		end,
	})
end

return Farming
