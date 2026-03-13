-- [[ EfHub Addon: Collapsible Section (Final Stable Version) ]] --
-- Features: Auto-Layout, Lua 5.1 Support, Snapshot Capture, Visibility Toggle
return function(FluentLibrary)
	local AddonName = "AddCollapsibleSection"

	-- Helper: หาเลขลำดับถัดไป (Auto LayoutOrder) เพื่อเรียง Element ให้ถูกต้อง
	local function GetNextLayoutOrder(Container)
		local MaxOrder = 0
		local Children = Container:GetChildren()
		for _, Child in ipairs(Children) do
			if Child:IsA("GuiObject") and Child.LayoutOrder > MaxOrder then
				MaxOrder = Child.LayoutOrder
			end
		end
		return MaxOrder + 1
	end

	local function CreateCollapsibleSection(self, Title, Opened)
		local Section = {}
		local ParentTab = self
		local IsOpened = (Opened == nil and false) or Opened
		local SectionElements = {}

		-- [ 1. สร้าง Header ]
		local HeaderHolder = Instance.new("Frame")
		HeaderHolder.Name = "Header_" .. Title
		HeaderHolder.BackgroundTransparency = 1
		HeaderHolder.Size = UDim2.new(1, 0, 0, 32)
		HeaderHolder.Parent = ParentTab.Container

		-- บังคับรันคิวลำดับให้ Header
		HeaderHolder.LayoutOrder = GetNextLayoutOrder(ParentTab.Container)

		local HeaderBtn = Instance.new("TextButton")
		HeaderBtn.Name = "Button"
		HeaderBtn.Size = UDim2.new(1, 0, 0, 30)
		HeaderBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		HeaderBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
		HeaderBtn.Font = Enum.Font.GothamBold
		HeaderBtn.TextSize = 14
		HeaderBtn.TextXAlignment = Enum.TextXAlignment.Left
		HeaderBtn.AutoButtonColor = true
		HeaderBtn.Parent = HeaderHolder

		Instance.new("UICorner", HeaderBtn).CornerRadius = UDim.new(0, 4)
		local Padding = Instance.new("UIPadding")
		Padding.PaddingLeft = UDim.new(0, 10)
		Padding.Parent = HeaderBtn

		-- [ 2. ฟังก์ชันอัปเดตสถานะ ]
		local function UpdateState()
			HeaderBtn.Text = (IsOpened and "▼  " or "▶  ") .. Title
			for _, Item in ipairs(SectionElements) do
				if Item.Frame then
					Item.Frame.Visible = IsOpened
				end
			end
		end

		HeaderBtn.MouseButton1Click:Connect(function()
			IsOpened = not IsOpened
			UpdateState()
		end)

		-- [ 3. ฟังก์ชันจับตาดู UI ใหม่ (Snapshot Logic) ]
		function Section:Wrap(Callback)
			local OldChildren = ParentTab.Container:GetChildren()

			-- สร้าง Element
			local Element = Callback()

			local NewChildren = ParentTab.Container:GetChildren()
			local FoundFrame = nil

			if Element and type(Element) == "table" and Element.Frame then
				FoundFrame = Element.Frame
			else
				for _, Child in ipairs(NewChildren) do
					local IsOld = false
					for _, Old in ipairs(OldChildren) do
						if Old == Child then
							IsOld = true
							break
						end
					end
					if not IsOld and Child ~= HeaderHolder and Child:IsA("GuiObject") then
						FoundFrame = Child
						break
					end
				end
			end

			if FoundFrame then
				table.insert(SectionElements, {
					Frame = FoundFrame,
				})
				FoundFrame.Visible = IsOpened

				-- บังคับรันคิวลำดับให้ Element ต่อท้าย Header หรือ Element ก่อนหน้า
				FoundFrame.LayoutOrder = GetNextLayoutOrder(ParentTab.Container)
			end

			return Element
		end

		-- [ 4. Wrapper Functions (Lua 5.1 Safe) ]
		function Section:AddToggle(...)
			local args = { ... }
			return Section:Wrap(function()
				return ParentTab:AddToggle(unpack(args))
			end)
		end

		function Section:AddButton(...)
			local args = { ... }
			return Section:Wrap(function()
				return ParentTab:AddButton(unpack(args))
			end)
		end

		function Section:AddSlider(...)
			local args = { ... }
			return Section:Wrap(function()
				return ParentTab:AddSlider(unpack(args))
			end)
		end

		function Section:AddDropdown(...)
			local args = { ... }
			return Section:Wrap(function()
				return ParentTab:AddDropdown(unpack(args))
			end)
		end

		function Section:AddInput(...)
			local args = { ... }
			return Section:Wrap(function()
				return ParentTab:AddInput(unpack(args))
			end)
		end

		function Section:AddParagraph(...)
			local args = { ... }
			return Section:Wrap(function()
				return ParentTab:AddParagraph(unpack(args))
			end)
		end

		function Section:AddKeybind(...)
			local args = { ... }
			return Section:Wrap(function()
				return ParentTab:AddKeybind(unpack(args))
			end)
		end

		function Section:AddColorpicker(...)
			local args = { ... }
			return Section:Wrap(function()
				return ParentTab:AddColorpicker(unpack(args))
			end)
		end

		-- [[ เพิ่มส่วนนี้เข้าไปในไฟล์ CollapsibleSection.lua ในส่วนที่ 4 ]] --

		-- ฟังก์ชันสำหรับสร้างเส้นคั่น (Divider) ภายใน Section
		function Section:AddDivider()
			return Section:Wrap(function()
				local DividerFrame = Instance.new("Frame")
				DividerFrame.Name = "Divider"
				DividerFrame.Size = UDim2.new(1, -20, 0, 1) -- สูง 1 pixel
				DividerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				DividerFrame.BackgroundTransparency = 0.8
				DividerFrame.BorderSizePixel = 0
				DividerFrame.Parent = ParentTab.Container

				-- ใส่ Padding เล็กน้อยเพื่อให้เส้นไม่ติดขอบเกินไป
				local UIListLayout = ParentTab.Container:FindFirstChildOfClass("UIListLayout")
				DividerFrame.LayoutOrder = GetNextLayoutOrder(ParentTab.Container)

				return { Frame = DividerFrame } -- ส่งกลับในรูปแบบ Table เพื่อให้ Wrap ทำงานได้
			end)
		end

		-- ฟังก์ชันสำหรับสร้างช่องว่าง (Spacer) ภายใน Section
		function Section:AddSpacer(height)
			return Section:Wrap(function()
				local SpacerFrame = Instance.new("Frame")
				SpacerFrame.Name = "Spacer"
				SpacerFrame.Size = UDim2.new(1, 0, 0, height or 10)
				SpacerFrame.BackgroundTransparency = 1
				SpacerFrame.BorderSizePixel = 0
				SpacerFrame.Parent = ParentTab.Container

				return { Frame = SpacerFrame }
			end)
		end
		task.delay(0.1, UpdateState)
		return Section
	end

	-- [ 5. ติดตั้งระบบ (Hook) ]
	local OldCreateWindow = FluentLibrary.CreateWindow
	FluentLibrary.CreateWindow = function(self, Config)
		local Window = OldCreateWindow(self, Config)
		local OldAddTab = Window.AddTab
		Window.AddTab = function(self, TabConfig)
			local Tab = OldAddTab(self, TabConfig)
			Tab[AddonName] = CreateCollapsibleSection
			return Tab
		end
		return Window
	end

	-- print("EfHub Addon: Collapsible Section Installed Successfully")
end
