--!strict
-- src/gui/window.luau

export type SutaUI = {
    Fluent: any,
    Window: any,
    SaveManager: any,
    InterfaceManager: any
}

local GUI: SutaUI = {} :: SutaUI
local env: any = getgenv and getgenv() or shared
local config = env.SutaHubConfig

-- ดึง GitHub Module มาใช้ในไฟล์นี้เพื่อโหลด Addons
local GitHub = loadstring(game:HttpGet(`{config.BaseUrl}src/utils/github.luau`))()

print("🎨 SutaHub: กำลังโหลด Fluent Renewed และ Addons...")

-- 1. โหลด Library หลักและ Managers
local Fluent = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

-- ==========================================
-- 🌟 2. ติดตั้ง Addon ของพี่เอฟตรงนี้เลยค่ะ! 🌟
-- ==========================================
print("⚙️ SutaHub: กำลังติดตั้ง Collapsible Section Addon...")
local InstallCollapsible = GitHub.require("src/gui/addons.luau")
InstallCollapsible(Fluent) -- เรียกใช้ฟังก์ชันที่พี่เอฟ return มาและส่ง Fluent เข้าไป
-- ==========================================

-- 3. สร้างหน้าต่างหลัก (Window) 
-- (ตอนนี้ CreateWindow ถูก Hook ด้วยระบบของพี่เอฟแล้ว!)
local Window = Fluent:CreateWindow({
    Title = "SutaHub",
    SubTitle = "by พี่เอฟ",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- 4. ตั้งค่าพื้นฐานให้ Managers
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("SutaHub")
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder("SutaHub/GrowAGarden")

Fluent:Notify({
    Title = "SutaHub UI",
    Content = "โหลดอินเทอร์เฟซหลักและ Addons สำเร็จแล้วค่ะ!",
    Duration = 3
})

-- 5. ส่งกลับไปให้ main.luau
GUI.Fluent = Fluent
GUI.Window = Window
GUI.SaveManager = SaveManager
GUI.InterfaceManager = InterfaceManager

return GUI