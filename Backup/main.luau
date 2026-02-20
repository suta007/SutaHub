--!strict
-- src/main.luau

print("🚀 SutaHub: เข้าสู่ระบบหลัก (Main) แล้วค่ะพี่เอฟ!")

local env: any = getgenv and getgenv() or shared
local config = env.SutaHubConfig

if not config or type(config.BaseUrl) ~= "string" then
    error("❌ SutaHub [Error]: ไม่พบ BaseUrl ค่ะ รบกวนรันสคริปต์ผ่าน loader.luau นะคะ")
end

-- 1. โหลดโมดูล GitHub ขึ้นมาเพื่อใช้เรียกไฟล์อื่นๆ ในโปรเจกต์
local githubUrl: string = `{config.BaseUrl}src/utils/github.luau`
local GitHub = loadstring(game:HttpGet(githubUrl))()

print("🎨 SutaHub: กำลังสร้าง UI...")

-- 2. โหลดและสร้างหน้าต่างหลัก (Window) จาก Fluent Renewed
-- สมมติว่าไฟล์นี้ return object ของ Window และ Library กลับมา
local GUI = GitHub.require("src/gui/window.luau")
local Window = GUI.Window
local Fluent = GUI.Library

-- 3. โหลดและติดตั้ง Addons (Component Hooking)
-- ส่ง Library ของ Fluent เข้าไปเพื่อให้ Addon แทรกโค้ดสร้าง CollapsibleSection ได้ค่ะ
local Addons = GitHub.require("src/gui/addons.luau")
Addons.install(Fluent)

-- 4. โหลด Tabs และสร้างหน้าต่าง UI
-- ส่ง Window เข้าไปเพื่อให้แต่ละ Tab รู้ว่าจะต้องเอา UI ไปวาดลงที่ไหน
local FarmTab = GitHub.require("src/gui/tabs/farm_tab.luau")
FarmTab.init(Window, Fluent)

local SettingTab = GitHub.require("src/gui/tabs/setting_tab.luau")
SettingTab.init(Window, Fluent)

print("⚙️ SutaHub: กำลังเตรียมระบบฟาร์มและฟิสิกส์...")

-- 5. โหลด Features (Logic เกม Grow a Garden)
local AutoFarm = GitHub.require("src/features/auto_farm.luau")
local Motion = GitHub.require("src/features/motion.luau")

-- 6. เชื่อมต่อ UI กับ Logic เข้าด้วยกัน (Event Binding)
-- รอรับ Event จาก UI เมื่อพี่เอฟกดเปิด/ปิดปุ่มฟาร์ม
FarmTab.onToggleFarm(function(isFarming: boolean)
    if isFarming then
        -- ส่ง Module การเคลื่อนที่ (Motion) เข้าไปให้ระบบฟาร์มใช้คำนวณการเดิน
        AutoFarm.start(Motion)
    else
        AutoFarm.stop()
    end
end)

print("✅ SutaHub: โหลดเสร็จสมบูรณ์ พร้อมลุยแล้วค่ะ!")

-- สั่งแสดง Notification ให้ผู้ใช้รู้ว่าสคริปต์พร้อมใช้งาน
if Fluent and Fluent.Notify then
    Fluent:Notify({
        Title = "SutaHub",
        Content = `เวอร์ชัน {config.Version} โหลดสำเร็จแล้วค่ะพี่เอฟ!`,
        Duration = 5
    })
end