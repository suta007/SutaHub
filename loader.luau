--!strict
-- SutaHub Bootstrapper (loader.luau)

-- กำหนด Type สำหรับ Config เพื่อความเป็นระเบียบค่ะ
type SutaConfig = {
	Owner: string,
	Repo: string,
	Branch: string,
	BaseUrl: string,
	Version: string,
}

local CONFIG = {
	Owner = "suta007",
	Repo = "SutaHub",
	Branch = "master",
}

-- ใช้ String Interpolation แบบ Luau ในการต่อ URL
local baseUrl: string = `https://raw.githubusercontent.com/{CONFIG.Owner}/{CONFIG.Repo}/{CONFIG.Branch}/`

-- เนื่องจาก getgenv() เป็นฟังก์ชันเฉพาะของ Executor น้องเลยใช้ type any ดักไว้ก่อนเพื่อไม่ให้ strict mode โวยวายค่ะ

env.SutaHubConfig = {
	BaseUrl = baseUrl,
	Version = "0.0.1",
} :: SutaConfig -- บังคับ Cast Type ให้ตรงกับที่ประกาศไว้

local envUrl: string = `{baseUrl}src/env.luau`

local success: boolean, result: any = pcall(function(): string
	return game:HttpGet(envUrl)
end)

repeat
	task.wait()
until getgenv().EF_Script

print("🌱 SutaHub: กำลังโหลดระบบจาก GitHub...")

local githubUtilUrl: string = `{baseUrl}src/utils/github.luau`

local success: boolean, result: any = pcall(function(): string
	return game:HttpGet(githubUtilUrl)
end)

if success and type(result) == "string" then
	local func, compileErr = loadstring(result)

	if func then
		local GitHub = func()
		-- เรียกไฟล์ main.luau ต่อเลยค่ะ
		GitHub.require("src/main.luau")
	else
		warn(`❌ SutaHub [Compile Error]: {compileErr}`)
	end
else
	warn(
		"❌ SutaHub [Error]: ไม่สามารถเชื่อมต่อ GitHub ได้ โปรดเช็กอินเทอร์เน็ตหรือ URL ค่ะ"
	)
end
