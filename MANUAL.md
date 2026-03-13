# SutaHub (AI_Code) Developer Manual

คู่มือสำหรับนักพัฒนาเพื่อทำความเข้าใจโครงสร้าง, ฟังก์ชันหลัก, และวิธีการต่อยอดโปรเจกต์ SutaHub

## 1. สถาปัตยกรรมระบบ (System Architecture)

ระบบใช้โครงสร้างแบบ **Modular Architecture** โดยมีองค์ประกอบหลักดังนี้:

*   **Controller (`Main.lua`)**: เปรียบเสมือนสมองของบอท ทำหน้าที่:
    *   โหลด Modules ทั้งหมด
    *   เชื่อมโยง (Dependency Injection) ระหว่าง Module
    *   จัดการ Task Engine (`SyncBackgroundTasks`) เพื่อสั่งเปิด/ปิด Loop การทำงาน
*   **Modules (`Modules/*.lua`)**: เก็บ Logic การทำงานแยกตามหน้าที่ (Single Responsibility Principle)
    *   **Core**: เครื่องมือพื้นฐาน (Logging, Task Manager)
    *   **UI**: หน้าจอและการตั้งค่า
    *   **Game Logic**: Farming, Pet, Shop, Event

---

## 2. API Documentation (ฟังก์ชันที่ต้องรู้)

### 🛠 Core Module (`Modules/Core.lua`)
โมดูลรากฐานที่ทุกไฟล์ต้องเข้าถึง

*   **`Core.ToggleTask(taskName, enabled, funcBody)`**  
    *สำคัญที่สุด* ใช้จัดการ Loop การทำงานเบื้องหลัง
    *   `taskName` (string): ชื่อ Task (ห้ามซ้ำ)
    *   `enabled` (boolean): `true` = เริ่มทำงาน, `false` = หยุดและยกเลิก Thread ทันที
    *   `funcBody` (function): ฟังก์ชันที่จะให้รันวนลูป (**ต้องมี `task.wait()` ภายในเสมอ**)

*   **`Core.DataStream`**  
    RemoteEvent Wrapper สำหรับดักจับข้อมูลจาก Server (ใช้สำหรับระบบ Reactive เช่น Shop Sniper)

*   **`Core.QuickSave()`**  
    สั่งบันทึกการตั้งค่าปัจจุบันลงไฟล์ (ควรเรียกทุกครั้งที่ UI มีการเปลี่ยนแปลง)

### 🖥 UI Module (`Modules/UI.lua`)
*   **`UI.InitSaveManager(SyncCallback)`**  
    โหลด Config และเรียกฟังก์ชัน `SyncCallback` (ปกติคือ `Main.SyncBackgroundTasks`) เพื่อให้บอทเริ่มทำงานตามค่าที่โหลดมาทันที

*   **`UI.GetSelectedItems(DropdownValue)`**  
    แปลงค่าจาก Fluent Dropdown (ที่เป็น Table `[Name]=bool`) ให้กลายเป็น Array รายชื่อ `{"Item1", "Item2"}` เพื่อให้นำไปลูปต่อง่ายๆ

### 🌾 Farming Module (`Modules/Farming.lua`)
*   **`Farming.CollectFruitWorker(mode)`**: ระบบเก็บผลไม้ (รองรับ Mode 1/2)
*   **`Farming.AutoPlant()`**: ปลูกพืช
*   **`Farming.ShovelPlant()`**: ขุดพืชทิ้ง

### 🐾 Pet Module (`Modules/Pet.lua`)
*   **`Pet.PlaceEggs()` / `Pet.HatchEgg()` / `Pet.SellPetEgg()`**: ฟังก์ชันจัดการวงจรชีวิตไข่
*   **`Pet.Mutation()`**: ระบบวิวัฒนาการสัตว์เลี้ยง (รองรับ Nightmare/Mutant)

---

## 3. ขั้นตอนการเพิ่มฟีเจอร์ใหม่ (Development Workflow)

สมมติว่าต้องการเพิ่มฟีเจอร์ **"กระโดดอัตโนมัติ (Auto Jump)"**

### ขั้นตอนที่ 1: สร้าง UI (ใน Module ที่เกี่ยวข้อง)
สมมติว่าเพิ่มใน `Farming.lua` ตรงฟังก์ชัน `BuildUI`:

```lua
-- สร้างฟังก์ชัน Sync เพื่อแจ้ง Main ให้รู้ว่ามีการเปลี่ยนค่า
local Sync = function() if UI.SyncBackgroundTasks then UI.SyncBackgroundTasks() end end

Tabs.Main:AddToggle("tgAutoJump", {
    Title = "Auto Jump",
    Default = false,
    Callback = function(Value)
        Core.QuickSave() -- 1. บันทึกค่า
        Sync()           -- 2. สั่ง Sync Task
    end
})
```

### ขั้นตอนที่ 2: เขียน Logic (ใน Module เดียวกัน)
เขียนฟังก์ชันการทำงานจริง:

```lua
function Farming.AutoJumpLogic()
    if Core.GetHumanoid() then
        Core.GetHumanoid().Jump = true
    end
end
```

### ขั้นตอนที่ 3: เชื่อมต่อ Task (ใน `Main.lua`)
ไปที่ฟังก์ชัน `Main.SyncBackgroundTasks` แล้วเพิ่ม:

```lua
-- ชื่อ Task, ค่า Bool จาก UI, และฟังก์ชันที่จะทำ
Core.ToggleTask("AutoJump", UI.Options.tgAutoJump.Value, function()
    pcall(Farming.AutoJumpLogic) -- ใช้ pcall เสมอเผื่อ error
    task.wait(1)                 -- ต้องมี wait เสมอ!
end)
```

---

## 4. กฎเหล็ก (Golden Rules)
1.  **ห้ามใช้ `require` ข้าม Module**: ให้ส่ง `Core` หรือ `UI` ผ่านฟังก์ชัน `Init` เท่านั้น เพื่อป้องกัน Circular Dependency
2.  **แยกส่วนเสมอ**: อย่าเขียน Logic ใน `Main.lua` ให้เขียนใน Module แล้วเรียกใช้เอา
3.  **Legacy Code**: ไฟล์ `EfHub.lua` มีไว้ดู Logic เก่าเท่านั้น **ห้ามแก้ไข** และห้ามนำมาใช้รันจริง