--!strict
-- src/utils/github.luau

-- ประกาศ Type Export เผื่อให้ไฟล์อื่นเอา Type นี้ไปใช้อ้างอิงได้ค่ะ
export type GitHubModule = {
    require: (path: string) -> any
}

-- สร้าง Table เปล่าๆ แล้วผูก Type เข้าไป
local GitHub: GitHubModule = {} :: GitHubModule

local env: any = getgenv and getgenv() or shared
local config = env.SutaHubConfig

-- ใช้ If-then-else Expression แบบใหม่ของ Luau
local baseUrl: string = if config and config.BaseUrl then config.BaseUrl else ""

function GitHub.require(path: string): any
    if baseUrl == "" then
        error("❌ SutaHub [Error]: ไม่พบ BaseUrl ใน getgenv().SutaHubConfig")
    end

    local url: string = `{baseUrl}{path}`
    
    local success: boolean, response: any = pcall(function(): string
        return game:HttpGet(url)
    end)

    if not success then
        error(`❌ SutaHub [Error]: ดึงไฟล์ไม่สำเร็จ -> {path}`)
    end

    local func, compileErr = loadstring(response :: string)
    
    if not func then
        -- แจ้ง Error ระบุตำแหน่งไฟล์ให้ชัดเจน พี่เอฟจะได้แก้บักง่ายๆ ค่ะ
        error(`❌ SutaHub [Compile Error]: โค้ดมีปัญหาที่ไฟล์ -> {path}\nรายละเอียด: {tostring(compileErr)}`)
    end

    return func()
end

return GitHub