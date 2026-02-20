--!strict
-- src/gui/tabs/autobuy_tab.luau

-- สร้าง Type เพื่อให้ main.luau รู้ว่าเรามีฟังก์ชัน init ให้เรียกใช้
export type TabModule = {
    init: (Window: any, Fluent: any) -> ()
}

local AutoBuyTab: TabModule = {} :: TabModule

function AutoBuyTab.init(Window: any, Fluent: any)
    -- 1. สร้าง Tab ใหม่บน Window
    local Tab = Window:AddTab({
        Title = "Auto Buy",
        Icon = "shopping-cart" -- อิงตามชื่อไอคอนของ Lucide ที่ Fluent รองรับ
    })

    -- ==========================================
    -- 🌟 ตัวอย่างที่ 1: Section ซื้อเมล็ดพันธุ์ (ตั้งค่าเปิดไว้เป็น Default)
    -- ==========================================
    local SeedSection = Tab:AddCollapsibleSection("ซื้อเมล็ดพันธุ์ (Seeds)", true)

    -- สร้าง UI ไว้ภายใน Section โดยใช้คำสั่งผ่านตัวแปร SeedSection ที่พี่เอฟทำ Wrapper ไว้
    local SeedDropdown = SeedSection:AddDropdown("SelectedSeed", {
        Title = "เลือกชนิดเมล็ด",
        Values = {"Apple Seed", "Orange Seed", "Mango Seed", "Banana Seed"},
        Multi = false,
        Default = 1,
    })

    local AmountSlider = SeedSection:AddSlider("BuyAmount", {
        Title = "จำนวนที่ต้องการซื้อ",
        Description = "กำหนดจำนวนเมล็ดที่จะซื้อต่อรอบ",
        Default = 10,
        Min = 1,
        Max = 100,
        Rounding = 0
    })

    local AutoBuyToggle = SeedSection:AddToggle("EnableAutoBuy", {
        Title = "เปิดระบบ Auto Buy",
        Default = false
    })

    -- การดักจับ Event เมื่อผู้เล่นกดเปิด/ปิดสวิตช์
    AutoBuyToggle:OnChanged(function(Value: boolean)
        if Value then
            local seedType = SeedDropdown.Value
            local amount = AmountSlider.Value
            print(`🛒 SutaHub: เริ่มซื้อ {seedType} จำนวน {amount} ชิ้น...`)
            
            -- [!] พี่เอฟสามารถเอา Logic วนลูปซื้อของในเกม Grow a Garden มาใส่หรือเรียกใช้จากที่นี่ได้เลยค่ะ
        else
            print("🛒 SutaHub: หยุดระบบ Auto Buy แล้ว")
        end
    end)


    -- ==========================================
    -- 🌟 ตัวอย่างที่ 2: Section ซื้ออุปกรณ์ (ตั้งค่าปิดไว้เป็น Default เพื่อประหยัดพื้นที่)
    -- ==========================================
    local ToolsSection = Tab:AddCollapsibleSection("ซื้ออุปกรณ์ (Tools)", false)
    
    ToolsSection:AddButton({
        Title = "ซื้อบัวรดน้ำ (Watering Can)",
        Description = "ราคา: 50 Coins",
        Callback = function()
            print("💦 ซื้อบัวรดน้ำสำเร็จ!")
        end
    })
    
    -- ทดสอบฟังก์ชัน AddDivider สร้างเส้นคั่นที่พี่เอฟเขียนไว้
    ToolsSection:AddDivider()
    
    ToolsSection:AddButton({
        Title = "ซื้อปุ๋ย (Fertilizer)",
        Description = "ราคา: 20 Coins",
        Callback = function()
            print("✨ ซื้อปุ๋ยสำเร็จ!")
        end
    })
    
    ToolsSection:AddSpacer(20) -- ทดสอบเพิ่มช่องว่างด้านล่าง
end

return AutoBuyTab