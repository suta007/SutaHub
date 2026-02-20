--!strict
-- src/main.luau

local env = (typeof(getgenv) == "function" and getgenv()) or shared or _G

print("🚀 SutaHub: เข้าสู่ระบบหลัก (Main) แล้วค่ะพี่เอฟ!")

local config = env.SutaHubConfig

if not config or type(config.BaseUrl) ~= "string" then
	error(
		"❌ SutaHub [Error]: ไม่พบ BaseUrl ค่ะ รบกวนรันสคริปต์ผ่าน loader.luau นะคะ"
	)
end

-- 1. โหลดโมดูล GitHub ขึ้นมาเพื่อใช้เรียกไฟล์อื่นๆ ในโปรเจกต์
local githubUrl: string = `{config.BaseUrl}src/utils/github.luau`
local GitHub = loadstring(game:HttpGet(githubUrl) :: any)()

print("🎨 SutaHub: กำลังสร้าง UI...")

-- 2. โหลดและสร้างหน้าต่างหลัก (Window) จาก Fluent Renewed
-- (ใน window.luau มีการติดตั้ง CollapsibleSection Addon ไว้ให้แล้วค่ะ)
local GUI = GitHub.require("src/gui/window.luau")
local Window = GUI.Window
local Fluent = GUI.Fluent -- เปลี่ยนจาก GUI.Library เป็น GUI.Fluent ตาม Type ที่เราตั้งไว้ใน window.luau

-- 3. โหลด Tabs และสร้างหน้าต่าง UI
print("📁 SutaHub: กำลังโหลด Auto Buy Tab...")
local AutoBuyTab = GitHub.require("src/gui/tabs/autobuy_tab.luau")
AutoBuyTab.init(Window, Fluent)

-- =======================================================
-- [ โซนนี้ขอคอมเมนต์ปิดไว้ก่อน รอสร้างไฟล์เสร็จค่อยมาเปิดนะคะ ]
-- =======================================================
-- local FarmTab = GitHub.require("src/gui/tabs/farm_tab.luau")
-- FarmTab.init(Window, Fluent)

-- local SettingTab = GitHub.require("src/gui/tabs/setting_tab.luau")
-- SettingTab.init(Window, Fluent)

-- print("⚙️ SutaHub: กำลังเตรียมระบบฟาร์มและฟิสิกส์...")
-- local AutoFarm = GitHub.require("src/features/auto_farm.luau")
-- local Motion = GitHub.require("src/features/motion.luau")
-- =======================================================

-- เลือก Tab ที่ 1 ให้แสดงผลเป็นหน้าแรก
Window:SelectTab(1)

print("✅ SutaHub: โหลดเสร็จสมบูรณ์ พร้อมลุยแล้วค่ะ!")

-- สั่งแสดง Notification ให้ผู้ใช้รู้ว่าสคริปต์พร้อมใช้งาน
if Fluent and Fluent.Notify then
	Fluent:Notify({
		Title = "SutaHub",
		Content = `เวอร์ชัน {config.Version} โหลดสำเร็จแล้วค่ะพี่เอฟ!`,
		Duration = 5,
	})
end
