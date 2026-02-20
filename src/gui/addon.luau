--!strict
-- src/gui/addons.luau
-- [[ SutaHub Addon: Collapsible Section (Luau Typed Version) ]] --

-- กำหนด Type สำหรับเก็บข้อมูล Element ภายใน Section
type ElementRecord = {
    Frame: GuiObject
}

return function(FluentLibrary: any)
    local AddonName: string = "AddCollapsibleSection"

    -- Helper: หาเลขลำดับถัดไป (Auto LayoutOrder)
    local function GetNextLayoutOrder(Container: Instance): number
        local MaxOrder: number = 0
        local Children = Container:GetChildren()
        
        for _, Child in ipairs(Children) do
            if Child:IsA("GuiObject") and Child.LayoutOrder > MaxOrder then
                MaxOrder = Child.LayoutOrder
            end
        end
        return MaxOrder + 1
    end

    -- ฟังก์ชันหลักสำหรับสร้าง Section
    local function CreateCollapsibleSection(self: any, Title: string, Opened: boolean?): any
        local Section: any = {}
        local ParentTab = self
        
        -- ใช้ If-then-else Expression แบบ Luau แทน (A and B or C)
        local IsOpened: boolean = if Opened ~= nil then Opened else false
        local SectionElements: {ElementRecord} = {}

        -- [ 1. สร้าง Header ]
        local HeaderHolder = Instance.new("Frame")
        HeaderHolder.Name = `Header_{Title}` -- ใช้ String Interpolation
        HeaderHolder.BackgroundTransparency = 1
        HeaderHolder.Size = UDim2.new(1, 0, 0, 32)
        HeaderHolder.Parent = ParentTab.Container

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

        local UICorner = Instance.new("UICorner", HeaderBtn)
        UICorner.CornerRadius = UDim.new(0, 4)
        
        local Padding = Instance.new("UIPadding")
        Padding.PaddingLeft = UDim.new(0, 10)
        Padding.Parent = HeaderBtn

        -- [ 2. ฟังก์ชันอัปเดตสถานะ ]
        local function UpdateState()
            -- ใช้ If-then-else Expression สลับไอคอน
            HeaderBtn.Text = `{if IsOpened then "▼  " else "▶  "}{Title}`
            
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
        function Section:Wrap(Callback: () -> any): any
            local OldChildren = ParentTab.Container:GetChildren()
            local Element = Callback()
            local NewChildren = ParentTab.Container:GetChildren()
            local FoundFrame: GuiObject? = nil

            if Element and type(Element) == "table" and Element.Frame then
                FoundFrame = Element.Frame
            else
                for _, Child in ipairs(NewChildren) do
                    local IsOld: boolean = false
                    for _, Old in ipairs(OldChildren) do
                        if Old == Child then
                            IsOld = true
                            break
                        end
                    end
                    if not IsOld and Child ~= HeaderHolder and Child:IsA("GuiObject") then
                        -- Cast Type เป็น GuiObject เพื่อป้องกัน Strict Mode แจ้งเตือน
                        FoundFrame = Child :: GuiObject
                        break
                    end
                end
            end

            if FoundFrame then
                table.insert(SectionElements, {
                    Frame = FoundFrame
                })
                FoundFrame.Visible = IsOpened
                FoundFrame.LayoutOrder = GetNextLayoutOrder(ParentTab.Container)
            end

            return Element
        end

        -- [ 4. Wrapper Functions (Luau Safe) ]
        -- ใช้ ...any เพื่อรับค่าพารามิเตอร์แบบไม่จำกัดและป้องกัน Type Error
        function Section:AddToggle(...: any): any
            local args = { ... }
            return Section:Wrap(function()
                return ParentTab:AddToggle(table.unpack(args)) -- ใช้ table.unpack ตามมาตรฐานใหม่
            end)
        end

        function Section:AddButton(...: any): any
            local args = { ... }
            return Section:Wrap(function()
                return ParentTab:AddButton(table.unpack(args))
            end)
        end

        function Section:AddSlider(...: any): any
            local args = { ... }
            return Section:Wrap(function()
                return ParentTab:AddSlider(table.unpack(args))
            end)
        end

        function Section:AddDropdown(...: any): any
            local args = { ... }
            return Section:Wrap(function()
                return ParentTab:AddDropdown(table.unpack(args))
            end)
        end

        function Section:AddInput(...: any): any
            local args = { ... }
            return Section:Wrap(function()
                return ParentTab:AddInput(table.unpack(args))
            end)
        end

        function Section:AddParagraph(...: any): any
            local args = { ... }
            return Section:Wrap(function()
                return ParentTab:AddParagraph(table.unpack(args))
            end)
        end

        function Section:AddKeybind(...: any): any
            local args = { ... }
            return Section:Wrap(function()
                return ParentTab:AddKeybind(table.unpack(args))
            end)
        end

        function Section:AddColorpicker(...: any): any
            local args = { ... }
            return Section:Wrap(function()
                return ParentTab:AddColorpicker(table.unpack(args))
            end)
        end

        -- [ 5. Custom Methods (Divider & Spacer) ]
        function Section:AddDivider(): any
            return Section:Wrap(function()
                local DividerFrame = Instance.new("Frame")
                DividerFrame.Name = "Divider"
                DividerFrame.Size = UDim2.new(1, -20, 0, 1)
                DividerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                DividerFrame.BackgroundTransparency = 0.8
                DividerFrame.BorderSizePixel = 0
                DividerFrame.Parent = ParentTab.Container
                DividerFrame.LayoutOrder = GetNextLayoutOrder(ParentTab.Container)

                return { Frame = DividerFrame }
            end)
        end

        function Section:AddSpacer(height: number?): any
            return Section:Wrap(function()
                local SpacerFrame = Instance.new("Frame")
                SpacerFrame.Name = "Spacer"
                -- ใช้ if-then-else เพื่อเช็กค่า height
                SpacerFrame.Size = UDim2.new(1, 0, 0, if height then height else 10)
                SpacerFrame.BackgroundTransparency = 1
                SpacerFrame.BorderSizePixel = 0
                SpacerFrame.Parent = ParentTab.Container

                return { Frame = SpacerFrame }
            end)
        end

        task.delay(0.1, UpdateState)
        return Section
    end

    -- [ 6. ติดตั้งระบบ (Hook) ]
    local OldCreateWindow = FluentLibrary.CreateWindow
    
    FluentLibrary.CreateWindow = function(self: any, Config: any)
        local Window = OldCreateWindow(self, Config)
        local OldAddTab = Window.AddTab
        
        Window.AddTab = function(self: any, TabConfig: any)
            local Tab = OldAddTab(self, TabConfig)
            -- ฝังฟังก์ชันเข้าสู่อ็อบเจกต์ Tab
            Tab[AddonName] = CreateCollapsibleSection
            return Tab
        end
        
        return Window
    end
end