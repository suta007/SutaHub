--!native
--!optimize 2
-- SutaHub Definition File for Delta Executor (v2)

-- === 1. Global Functions (Common Executor API) ===
declare function getgenv(): {[string]: any}
declare function getrenv(): {[string]: any}
declare function getreg(): {[string]: any}
declare function getgc(): {any}
declare function getinstances(): {Instance}
declare function getnilinstances(): {Instance}

declare function identifyexecutor(): (string, string)
declare function getexecutorname(): string
declare function setclipboard(content: string): ()
declare function setfpscap(fps: number): ()

-- === 2. File System Standard ===
declare function readfile(path: string): string
declare function writefile(path: string, content: string): ()
declare function appendfile(path: string, content: string): ()
declare function isfile(path: string): boolean
declare function isfolder(path: string): boolean
declare function makefolder(path: string): ()
declare function delfile(path: string): ()
declare function delfolder(path: string): ()
declare function listfiles(path: string): {string}

-- === 3. Script Loading & Execution ===
-- loadstring คืนค่าเป็น function ที่สามารถรับ/ส่งค่าได้ไม่จำกัด
declare function loadstring(code: string, chunkname: string?): (...any) -> ...any
declare function checkcaller(): boolean
declare function islclosure(f: any): boolean
declare function iscclosure(f: any): boolean
declare function newcclosure(f: (...any) -> ...any): (...any) -> ...any

-- === 4. Metatable & Hooking ===
declare function getrawmetatable(obj: any): {[string]: any}
declare function setrawmetatable(obj: any, mt: {[string]: any}): ()
declare function setreadonly(obj: any, readonly: boolean): ()
declare function isreadonly(obj: any): boolean
declare function hookfunction(old: (...any) -> ...any, new: (...any) -> ...any): (...any) -> ...any
declare function hookmetamethod(obj: any, method: string, new: (...any) -> ...any): (...any) -> ...any

-- === 5. Communication & Task ===
type HttpRequest = {
    Url: string,
    Method: string?,
    Headers: {[string]: string}?,
    Body: string?,
    Cookies: {[string]: string}?
}

type HttpResponse = {
    Success: boolean,
    StatusCode: number,
    StatusMessage: string,
    Headers: {[string]: string},
    Body: string
}

declare function request(options: HttpRequest): HttpResponse
declare function delthread(thread: thread): ()

-- === 6. The "game:HttpGet" Fix (The Master Stroke) ===
-- เราจะทำการ Extend คลาส DataModel เดิมให้รองรับฟังก์ชันของ Executor ค่ะ
declare class ExecutorDataModel extends PostSimulation
    function HttpGet(self: any, url: string, cache: boolean?): string
    function HttpGetAsync(self: any, url: string, cache: boolean?): string
    function GetObjects(self: any, assetId: string): {Instance}
end

-- ประกาศทับตัวแปร global 'game' ให้เป็น Type ผสม (Intersection)
-- เพื่อให้ใช้งานได้ทั้งมาตรฐาน Roblox และฟังก์ชันของ Delta
declare game: ExecutorDataModel & DataModel