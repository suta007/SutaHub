-- Modules/UI.lua
local UI = {}
local Core = nil

UI.Window = nil
UI.Tabs = {}
UI.SyncBackgroundTasks = nil

function UI.Init(RefCore, SyncTask)
	Core = RefCore
	UI.SyncBackgroundTasks = SyncTask
	UI.Window = Core.Fluent:CreateWindow({
		Title = "Grow a Garden " .. Core.fVersion,
		SubTitle = "by SutaHub",
		TabWidth = 100,
		Size = UDim2.fromOffset(1400, 900),
		Resize = true,
		MinSize = Vector2.new(580, 460),
		Acrylic = true,
		Theme = "Darker",
		MinimizeKey = Enum.KeyCode.RightControl,
	})

	UI.Options = Core.Fluent.Options

	UI.Tabs = {
		Main = UI.Window:AddTab({ Title = "Main", Icon = "house" }),
		Buy = UI.Window:AddTab({ Title = "Buy", Icon = "shopping-cart" }),
		Pet = UI.Window:AddTab({ Title = "Pet", Icon = "bone" }),
		Farm = UI.Window:AddTab({ Title = "Farm", Icon = "tree-pine" }),
		Auto = UI.Window:AddTab({ Title = "Automatic", Icon = "bot" }),
		Event = UI.Window:AddTab({ Title = "Event", Icon = "calendar" }),
		Log = UI.Window:AddTab({ Title = "Console", Icon = "terminal" }),
		Settings = UI.Window:AddTab({ Title = "Settings", Icon = "settings" }),
	}

	UI.Window:SelectTab(1)
	UI.CreateToggleGui()
	UI.CreateLogConsole()
end

function UI.CreateLogConsole()
	UI.Tabs.Log:AddButton({
		Title = "Clear Logs",
		Callback = function()
			Core.DisplayTable = {}
			if Core.LogDisplay then Core.LogDisplay:SetValue("") end
		end,
	})

	Core.LogDisplay = UI.Tabs.Log:CreateParagraph("MyConsole", {
		Title = "Recent Logs",
		Content = "System initialized...",
	})
end

function UI.CreateToggleGui()
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
	ToggleButton.Text = "SutaHub"
	ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleButton.Draggable = true

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 25)
	UICorner.Parent = ToggleButton

	ToggleButton.MouseButton1Click:Connect(function()
		pcall(function()
			if UI.Window.GUI then
				UI.Window.GUI.Enabled = not UI.Window.GUI.Enabled
			elseif UI.Window.Instance then
				UI.Window.Instance.Enabled = not UI.Window.Instance.Enabled
			elseif UI.Window.Root then
				UI.Window.Root.Visible = not UI.Window.Root.Visible
			end
		end)
	end)
end

function UI.GetSelectedItems(DropdownValue)
	local Items = {}
	if type(DropdownValue) == "table" then
		for Value, State in pairs(DropdownValue) do
			if State then table.insert(Items, Value) end
		end
	end
	return Items
end

function UI.InitSaveManager()
	Core.SaveManager:SetLibrary(Core.Fluent)
	Core.InterfaceManager:SetLibrary(Core.Fluent)

	Core.SaveManager:SetIgnoreIndexes({})
	Core.InterfaceManager:SetFolder("EfHub")
	Core.SaveManager:SetFolder("EfHub/GAG")

	Core.InterfaceManager:BuildInterfaceSection(UI.Tabs.Settings)
	Core.SaveManager:BuildConfigSection(UI.Tabs.Settings)

	-- Load settings at the very end to prevent race conditions
	task.spawn(function()
		-- Wait for the SaveManager UI to be ready
		while not (Core.SaveManager.Options and Core.SaveManager.Options.SaveManager_ConfigList) do
			task.wait()
		end

		-- Ensure UI is fully ready
		task.wait(0.5)

		-- Load the config, which will trigger UI callbacks
		Core.SaveManager.Options.SaveManager_ConfigList:SetValue("EfHub")
		pcall(function()
			Core.SaveManager:Load("EfHub")
		end)

		-- Mark loading as complete and start all background tasks based on the loaded settings
		Core.IsLoading = false

		-- Force a sync once loaded
		if UI.SyncBackgroundTasks then UI.SyncBackgroundTasks() end

		-- Notify user
		Core.SuccessLog("AI_Code System Loaded Successfully!")
		Core.Fluent:Notify({ Title = "SutaHub", Content = "Settings loaded automatically", Duration = 3 })
	end)
end

return UI
