-- Modules/Event.lua
local Event = {}
local Core = nil
local UI = nil

local lastTriggerMinute = -1
local StopFlag = false
local isOverrideActive = false

Event.initToggle = function()
    UI.Options.PetModeEnable:SetValue(false)
    UI.Options.tgPlaceEggsEn:SetValue(false)
    UI.Options.tgAutoHatchEn:SetValue(false)
    UI.Options.tgSellPetEn:SetValue(false)
end

Event.restoreToggle = function()
    UI.Options.PetModeEnable:SetValue(UI.Options.tgAlienDefaultPetMode.Value)
    UI.Options.tgPlaceEggsEn:SetValue(UI.Options.tgAlienDefaultPlaceEggs.Value)
    UI.Options.tgAutoHatchEn:SetValue(UI.Options.tgAlienDefaultHatchEggs.Value)
    UI.Options.tgSellPetEn:SetValue(UI.Options.tgAlienDefaultSellPets.Value)
end

Event.AlienEvent = function()
    if not UI.Options.tgAlienEventEnable.Value then return end
    local AlienLoadout = tonumber(UI.Options.ddAlienLoadout.Value)
    local AlienPet = UI.GetSelectedItems(UI.Options.ddAlienPet.Value)
    local AlienMaxPet = tonumber(UI.Options.ddAlienMaxPet.Value)

    local timeData = os.date("!*t")
    local currentMinute = timeData.min
    local data = Core.DataService:GetData()
    local inventory = data and data.PetsData and data.PetsData.PetInventory
    local CountPet = 0

    if currentMinute == 58 and currentMinute ~= lastTriggerMinute then
        lastTriggerMinute = currentMinute
        pcall(Event.initToggle)
        task.wait(1)
        local Pet = require(script.Parent.Pet)
        Pet.SwapPetLoadout(AlienLoadout)
        task.wait(0.5)
        for _, uuid in pairs(Pet.GetEquippedPetsUUID()) do
            Pet.UnequipPet(uuid)
            task.wait(0.2)
        end
        task.wait(2)
        if inventory and not StopFlag then
            for _, v in pairs(inventory) do
                if type(v) == "table" then
                    for kUUID, petData in pairs(v) do
                        if type(petData) == "table" then
                            local tPetType = petData.PetType
                            if table.find(AlienPet, tPetType) then
                                local tuuid = petData.UUID or kUUID
                                if tuuid and (Pet.GetPetMutation(tuuid) == nil or Pet.GetPetMutation(tuuid) == "None") then
                                    if CountPet < AlienMaxPet then
                                        Pet.EquipPet(tuuid)
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
        local Pet = require(script.Parent.Pet)
        for _, uuid in pairs(Pet.GetEquippedPetsUUID()) do
            Pet.UnequipPet(uuid)
            task.wait(0.2)
        end
        StopFlag = false
        task.wait(2)
        pcall(Event.restoreToggle)
    end
    task.wait(30)
end

Event.CatchAlien = function()
    if not UI.Options.tgAlienEventEnable.Value or not StopFlag then return end
    local Pet = require(script.Parent.Pet)
    for _, uuid in pairs(Pet.GetEquippedPetsUUID()) do
        local mutant = Pet.GetPetMutation(uuid)
        if mutant == "Alienated" then
            Pet.UnequipPet(uuid)
            task.wait(0.2)
        end
    end

    local ActivePet = Pet.GetEquippedPetsUUID()
    local currentEquipped = #ActivePet
    local AlienMaxPet = tonumber(UI.Options.ddAlienMaxPet.Value) or 0

    if currentEquipped < AlienMaxPet then
        local data = Core.DataService:GetData()
        local inventory = data and data.PetsData and data.PetsData.PetInventory

        if inventory then
            local AlienPet = UI.GetSelectedItems(UI.Options.ddAlienPet.Value)

            for _, v in pairs(inventory) do
                if currentEquipped >= AlienMaxPet then break end

                if type(v) == "table" then
                    for kUUID, petData in pairs(v) do
                        if currentEquipped >= AlienMaxPet then break end

                        if type(petData) == "table" then
                            local tPetType = petData.PetType
                            if table.find(AlienPet, tPetType) then
                                local tuuid = petData.UUID or kUUID

                                if tuuid and (Pet.GetPetMutation(tuuid) == nil or Pet.GetPetMutation(tuuid) == "None") then
                                    if not table.find(Pet.GetEquippedPetsUUID(), tuuid) then
                                        Pet.EquipPet(tuuid)
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

Event.CheckAlienPet = function()
    if not UI.Options.tgAlienEventEnable.Value or not UI.Options.tgAlienAutoHatch.Value or StopFlag then return end
    local Pet = require(script.Parent.Pet)

    local AlienPetCount = 13
    local data = Core.DataService:GetData()
    local inventory = data and data.PetsData and data.PetsData.PetInventory
    local AlienMaxPet = tonumber(UI.Options.ddAlienMaxPet.Value)
    if inventory then
        AlienPetCount = 0
        local AlienPet = UI.GetSelectedItems(UI.Options.ddAlienPet.Value)
        for _, v in pairs(inventory) do
            if type(v) == "table" then
                for kUUID, petData in pairs(v) do
                    if type(petData) == "table" then
                        local tPetType = petData.PetType
                        if table.find(AlienPet, tPetType) then
                            local tuuid = petData.UUID or kUUID
                            if tuuid and Pet.GetPetMutation(tuuid) ~= "Alienated" then AlienPetCount = AlienPetCount + 1 end
                        end
                    end
                end
            end
        end
    end
    task.wait(0.2)
    if AlienPetCount <= AlienMaxPet then
        if not isOverrideActive then
            pcall(Event.initToggle)
            task.wait(1)
            isOverrideActive = true

            UI.Options.tgPlaceEggsEn:SetValue(true)
            UI.Options.tgAutoHatchEn:SetValue(true)
            task.wait(1)
        end
    else
        if isOverrideActive then
            pcall(Event.restoreToggle)
            task.wait(1)
            isOverrideActive = false
            pcall(function() Core.Humanoid:UnequipTools() end)
            task.wait(1)
        end
    end
end

Event.AutoAlienClaim = function()
    if not UI.Options.tgAlienAutoClaim.Value then return end
    local Pet = require(script.Parent.Pet)
    local data = Core.DataService:GetData()
    local inventory = data and data.PetsData and data.PetsData.PetInventory
    local AlienedPet = 0
    if inventory then
        for _, v in pairs(inventory) do
            if type(v) == "table" then
                for kUUID, petData in pairs(v) do
                    local tuuid = petData.UUID or kUUID
                    if type(petData) == "table" then
                        if Pet.GetPetMutation(tuuid) == "Alienated" then AlienedPet = AlienedPet + 1 end
                    end
                end
            end
        end
    end

    task.wait(0.1)
    if AlienedPet >= 10 then
        Core.GameEvents:WaitForChild("GetPetMutationNames"):InvokeServer()
        task.wait(0.2)
        Core.GameEvents:WaitForChild("AlienEvent"):WaitForChild("GiveAlienatedPets"):InvokeServer()
        task.wait(10)
    end
end

Event.AutoGiftAlien = function()
    if not UI.Options.tgAutoGiftAlien.Value then return end
    local TargetPlayer = "PawZx_111"
    local TargetPlayerObj = game:GetService("Players"):FindFirstChild(TargetPlayer)
    if not TargetPlayerObj then return end

    local data = Core.DataService:GetData()
    local inventory = data and data.PetsData and data.PetsData.PetInventory
    local Pet = require(script.Parent.Pet)
    
    if inventory then
        for _, v in pairs(inventory) do
            if type(v) == "table" then
                for kUUID, petData in pairs(v) do
                    local tuuid = petData.UUID or kUUID
                    if type(petData) == "table" then
                        if Pet.GetPetMutation(tuuid) == "Alienated" then
                            if Pet.heldPet(tuuid) then
                                local args = { "GivePet", TargetPlayerObj }
                                Core.GameEvents:WaitForChild("PetGiftingService"):FireServer(unpack(args))
                                task.wait(7)
                            end
                        end
                    end
                end
            end
        end
    end
end

function Event.Init(RefCore, RefUI)
    Core = RefCore
    UI = RefUI
    -- Real Event logic (Alien, Setup flags) fits here completely 
    Event.BuildUI()
end

function Event.BuildUI()
    local Tabs = UI.Tabs
    local Options = UI.Options
    local Sync = function() if UI.SyncBackgroundTasks then UI.SyncBackgroundTasks() end end

    local PetTable = {}
    local PetData = require(Core.ReplicatedStorage.Data.PetRegistry.PetList)
    for petName, _ in pairs(PetData) do table.insert(PetTable, petName) end
    table.sort(PetTable)

    local AlienEventSection = Tabs.Event:AddCollapsibleSection("Alien Event", false)
    AlienEventSection:AddToggle("tgAlienEventEnable", { Title = "Alien Event Enable", Default = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddDropdown("ddAlienLoadout", { Title = "Alien Event Type", Values = { 1, 2, 3, 4, 5, 6 }, Default = 6, Multi = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddDropdown("ddAlienPet", { Title = "Alien Pet", Values = PetTable, Multi = true, Default = {}, Searchable = true, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddDropdown("ddAlienMaxPet", { Title = "Alien Max Pet", Values = { 1, 2, 3, 4, 5, 6, 7, 8 }, Default = 3, Multi = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddToggle("tgAlienAutoClaim", { Title = "Alien Auto Claim", Default = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddToggle("tgAlienAutoHatch", { Title = "Alien Auto Hatch", Default = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddToggle("tgAlienDefaultPetMode", { Title = "Default Pet Mode", Default = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddToggle("tgAlienDefaultPlaceEggs", { Title = "Default Place Eggs", Default = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddToggle("tgAlienDefaultHatchEggs", { Title = "Default Hatch Eggs", Default = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddToggle("tgAlienDefaultSellPets", { Title = "Default Sell Pets", Default = false, Callback = function(Value) Core.QuickSave(); Sync() end })
    AlienEventSection:AddToggle("tgAutoGiftAlien", { Title = "Auto Gift Alien Pet", Default = false, Callback = function(Value) Core.QuickSave(); Sync() end })
end

return Event
