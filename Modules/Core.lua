--!nocheck
local Core = {}

-- Load Libraries

Core.Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
Core.SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
Core.InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

-- Services
Core.Lighting = game:GetService("Lighting")
Core.ReplicatedStorage = game:GetService("ReplicatedStorage")
Core.VirtualUser = game:GetService("VirtualUser")
Core.VirtualInputManager = game:GetService("VirtualInputManager")
Core.Players = game:GetService("Players")

-- Game Variables
Core.GameEvents = Core.ReplicatedStorage:WaitForChild("GameEvents")
Core.DataStream = Core.GameEvents:WaitForChild("DataStream")
Core.CollectEvent = Core.ReplicatedStorage.GameEvents.Crops.Collect

-- Game Modules
Core.DataService = require(Core.ReplicatedStorage.Modules.DataService)
Core.InventoryService = require(Core.ReplicatedStorage.Modules.InventoryService)
Core.ActivePetsService = require(Core.ReplicatedStorage.Modules.PetServices.ActivePetsService)

-- Player Info
Core.LocalPlayer = Core.Players.LocalPlayer
Core.MyName = Core.LocalPlayer.Name
Core.Backpack = Core.LocalPlayer:WaitForChild("Backpack")

-- Core Variables
Core.fVersion = "2569.03.13-Refactored"
Core.DevMode = false
Core.IsLoading = true
Core.ActiveTasks = {}

function Core.GetCharacter()
	return Core.LocalPlayer.Character or Core.LocalPlayer.CharacterAdded:Wait()
end

function Core.GetHumanoid()
	return Core.GetCharacter():WaitForChild("Humanoid")
end

-- Logging System
Core.MaxLines = 100
Core.DisplayTable = {}
Core.IsUpdateScheduled = false
Core.LogDisplay = nil

local function FlushLogUpdates()
	if Core.LogDisplay then pcall(function()
		Core.LogDisplay:SetValue(table.concat(Core.DisplayTable, "\n"))
	end) end
	Core.IsUpdateScheduled = false
end

function Core.AddLog(message)
	local entry = string.format("[%s] %s", os.date("%X"), message)
	table.insert(Core.DisplayTable, entry)
	if #Core.DisplayTable > Core.MaxLines then table.remove(Core.DisplayTable, 1) end

	if not Core.IsUpdateScheduled then
		Core.IsUpdateScheduled = true
		task.delay(0.3, FlushLogUpdates)
	end
end

function Core.InfoLog(message)
	Core.AddLog("📋 " .. message)
end
function Core.WarnLog(message)
	Core.AddLog("⚠️ " .. message)
end
function Core.ErrorLog(message)
	Core.AddLog("❌ " .. message)
end
function Core.SuccessLog(message)
	Core.AddLog("✅ " .. message)
end
function Core.DevLog(message)
	Core.AddLog("💻 " .. message)
end

function Core.DevNoti(content)
	if Core.DevMode then Core.DevLog(content) end
end

-- Tasks Manager
function Core.ToggleTask(taskName, enabled, funcBody)
	if enabled then
		if Core.ActiveTasks[taskName] then return end
		Core.ActiveTasks[taskName] = task.spawn(function()
			while true do
				local ok, err = pcall(funcBody)
				if not ok then Core.WarnLog("Task '" .. taskName .. "' error: " .. tostring(err)) end
				task.wait()
			end
		end)
	else
		if Core.ActiveTasks[taskName] then
			task.cancel(Core.ActiveTasks[taskName])
			Core.ActiveTasks[taskName] = nil
		end
	end
end

-- Save System
function Core.QuickSave()
	if not Core.IsLoading then Core.SaveManager:Save("EfHub") end
end

return Core
