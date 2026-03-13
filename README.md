# SutaHub (AI_Code) - Grow a Garden Automation

สคริปต์บอทสำหรับเกม **Grow a Garden** บน Roblox พัฒนาด้วยโครงสร้างแบบ Modular Architecture แยกส่วนการทำงานชัดเจนเพื่อความเสถียร, ปรับแต่งง่าย, และมีประสิทธิภาพสูง

## 🚀 ฟีเจอร์หลัก (Features)

### 🌾 ระบบฟาร์ม (Farming Automation)
*   **Multi-Worker Collection**: แยกเทรดการเก็บผลไม้เป็น 2 ชุด (`CollectFruit1`, `CollectFruit2`) เพื่อความรวดเร็วสูงสุด
*   **Advanced Filtering**: ระบบกรองที่ละเอียดมาก สามารถเลือกเก็บเฉพาะ:
    *   ชนิดผลไม้ (Fruit Type)
    *   ประเภท Mutant (เช่น Glossy, Magnetic, Giant ฯลฯ)
    *   ระดับความหายาก (Variant: Silver, Gold, Rainbow)
    *   น้ำหนัก (Weight Condition)
*   **Smart Planting**: ปลูกพืชอัตโนมัติในตำแหน่งผู้เล่น หรือตำแหน่งที่กำหนด
*   **Tool Automation**: ใช้พลั่ว (Shovel), คราด (Trowel), และ Reclaim อัตโนมัติตามเงื่อนไข
*   **Anti-Lag**: ระบบลดกราฟิกอัตโนมัติ (ลบเงา, น้ำ, Particle) เพื่อลดภาระเครื่อง

### 🐾 ระบบสัตว์เลี้ยง (Pet System)
*   **Lifecycle Management**: จัดการวงจรชีวิตสัตว์เลี้ยงครบวงจร:
    *   วางไข่ (Place Eggs) -> ฟักไข่ (Hatch) -> ขายตัวที่ไม่ต้องการ (Auto Sell)
    *   รองรับ Whitelist/Blacklist สำหรับการขาย
*   **Evolution Modes**:
    *   **Nightmare**: ใส่ Shard และทำ Mutation อัตโนมัติ
    *   **Mutant**: นำสัตว์เลี้ยงเข้าเครื่อง Mutate เมื่อเลเวลครบ
    *   **Level/Elephant**: เก็บเมื่ออายุครบตามกำหนด
*   **Maintenance**: ให้อาหารอัตโนมัติ (Auto Feed) ตามค่าความหิว
*   **Auto Age Break**: นำสัตว์เลี้ยงไปทำ Age Break อัตโนมัติเมื่อถึงขีดจำกัด

### 🛒 ระบบร้านค้า (Shop Sniper)
*   **Reactive Buying**: ใช้ระบบ `DataStream` ดักจับข้อมูลจาก Server เพื่อซื้อของทันทีที่ Stock เข้า (เร็วกว่าการ Loop เช็ค)
*   **Hardcore Mode**: โหมดกวาดซื้อของหายากแบบรัวๆ (Seeds, Gear, Eggs)
*   **Traveling Merchant**: เลือกซื้อของจากพ่อค้าเร่อัตโนมัติ
*   **Event Shop**: รองรับร้านค้าเทศกาล (Santa's Stash, New Year)

## 📂 โครงสร้างโฟลเดอร์ (Project Structure)
เพื่อให้ระบบทำงานได้ถูกต้อง ไฟล์จะต้องถูกจัดเรียงดังนี้:
```
AI_Code/
├── Main.lua            # จุดเริ่มต้น (Entry Point) และตัวควบคุม Task
└── Modules/            # โฟลเดอร์รวมโมดูลแยกส่วน
    ├── Core.lua        # ระบบพื้นฐาน (Services, Logging, Task Manager)
    ├── UI.lua          # ระบบจัดหน้าจอ (Fluent UI, Save Manager)
    ├── Shop.lua        # ระบบซื้อของอัตโนมัติ
    ├── Farming.lua     # ระบบทำฟาร์มและ Anti-Lag
    ├── Pet.lua         # ระบบสัตว์เลี้ยงและการฟักไข่
    └── Event.lua       # ระบบกิจกรรม (Alien Event)
```

## 🛠 โครงสร้างไฟล์ (Module Structure)

โปรเจกต์ถูกแบ่งออกเป็นโมดูลย่อย เพื่อความง่ายในการดูแลรักษา:

| ไฟล์ | หน้าที่หลัก |
| :--- | :--- |
| **`Main.lua`** | จุดเริ่มต้น (Entry Point) โหลดโมดูล, เชื่อมต่อ UI กับ Logic, และจัดการ Loop หลัก |
| **`Core.lua`** | ระบบพื้นฐาน (Utilities), Logger, Task Manager (`ToggleTask`), และ Service Wrappers |
| **`UI.lua`** | สร้างหน้าต่างเมนูด้วย Fluent Library และจัดการระบบ Save/Load Config |
| **`Farming.lua`** | Logic เกี่ยวกับพืช, การเก็บเกี่ยว, และการใช้เครื่องมือ |
| **`Pet.lua`** | Logic สัตว์เลี้ยง, การจัดการ Inventory, และเครื่องจักรต่างๆ |
| **`Shop.lua`** | Logic การซื้อของ และการดักจับ Remote Event ของร้านค้า |
| **`Event.lua`** | Logic เฉพาะกิจสำหรับ Event (เช่น Alien) ที่ทำงานตามเงื่อนไขเวลา |

## 🌟 เจาะลึกฟีเจอร์ใหม่ที่ Antigravity เพิ่มให้ (How to use New Features)

ผมได้ออกแบบระบบใหม่เพื่อให้คุณพัฒนาต่อได้ง่ายที่สุด ต่อไปนี้คือวิธีใช้ฟีเจอร์สำคัญที่ผมเพิ่มเข้ามาครับ:

### 1. การสร้างปุ่มใหม่และเชื่อมโยงระบบ (Adding New UI & Sync)
**โจทย์:** หากคุณอยากเพิ่มเมนูใหม่ในฟาร์ม (เช่น ปุ่ม "Auto Water")
1.  **ไปที่ไฟล์โมดูล:** เปิด `Farming.lua` และหาฟังก์ชัน `Farming.BuildUI()`
2.  **เพิ่มโค้ดปุ่ม:** ใช้คำสั่งสร้าง Toggle และต้องมี `Sync()` เสมอ เพื่อให้สัญญาณถูกส่งไปที่ `Main.lua`
    ```lua
    local Sync = function() if UI.SyncBackgroundTasks then UI.SyncBackgroundTasks() end end

    Section:AddToggle("tgAutoWater", { 
        Title = "รดน้ำอัตโนมัติ", 
        Default = false, 
        Callback = function(Value) 
            Core.QuickSave() -- บันทึกค่าลงเครื่อง
            Sync()           -- ส่งสัญญาณบอก Main.lua ว่าค่าเปลี่ยนแล้ว!
        end 
    })
    ```
3.  **ไปที่ Main.lua:** เพิ่มงานที่ต้องการให้ทำเมื่อเปิดปุ่มนี้ในฟังก์ชัน `SyncBackgroundTasks`
    ```lua
    Core.ToggleTask("Watering", Options.tgAutoWater.Value, function()
        print("กำลังรดน้ำ...")
        task.wait(1)
    end)
    ```

### 2. ระบบ Real-time Response (ระบบ Sync)
**คืออะไร:** ระบบที่ทำให้บอท "ตอบสนองทันที" ไม่ต้องรอรอบ Loop
*   **วิธีใช้ในโค้ด:** 
    ทุกครั้งที่คุณสร้าง Toggle หรือ Dropdown ใหม่ คุณต้องเรียกฟังก์ชัน `Sync()` ใน `Callback` เสมอ
    ```lua
    local Sync = function() if UI.SyncBackgroundTasks then UI.SyncBackgroundTasks() end end
    
    Section:AddToggle("MyToggle", {
        Title = "ลองใช้ดู",
        Callback = function(Value)
            Core.QuickSave() -- บันทึกค่า
            Sync()           -- สั่งให้ Main.lua อัปเดตการทำงานทันที
        end
    })
    ```

### 2. ระบบจัดการงานอัตโนมัติ (Core.ToggleTask)
**คืออะไร:** ตัวช่วยที่คอยเช็คสถานะปุ่มและเปิด/ปิด Task ให้เราเอง ลดปัญหาการรัน Task ซ้ำซ้อน
*   **วิธีใช้ใน Main.lua:** 
    ใช้คำสั่ง `Core.ToggleTask(ชื่อ, เงื่อนไข, ฟังก์ชัน)`
    ```lua
    -- ระบบจะรันฟังก์ชันนี้ "วนลูป" ให้เองตราบใดที่ปุ่มเป็นจริง
    Core.ToggleTask("Feeding", Options.AutoFeedPet.Value, function()
        Pet.FeedPet()
        task.wait(10) -- ใส่เวลาพักที่เหมาะสม
    end)
    ```

### 3. การเข้าถึงฐานข้อมูลสัตว์เลี้ยง (Smart Caching)
**คืออะไร:** ผมเขียนระบบให้โหลดข้อมูลจาก Server มาเก็บไว้ในเครื่องเพื่อความไว
*   **วิธีใช้ใน Pet.lua:**
    *   `Pet.HungerTable["Cat"]`: จะคืนค่า Hunger สูงสุดของแมวออกมาทันทีโดยไม่ต้องไป Get จาก Server ใหม่
    *   `Pet.EnumToNameCache[รหัสเลข]`: ใส่เลข Mutation ลงไป ระบบจะคืนชื่อภาษาอังกฤษออกมาให้เลย
*   **วิธีใช้งานต่อ:** คุณสามารถเอาค่าพวกนี้ไปคำนวณในฟังก์ชันใหม่ๆ เช่น "ถ้าความหิว > 50% ให้หยุดทำงาน"

### 4. การเลือกไอเทมแบบ Advanced (UI.GetSelectedItems)
**คืออะไร:** ฟังก์ชันช่วยดึงค่าจาก Dropdown แบบที่เลือกได้หลายอัน (Multi-Select)
*   **วิธีใช้:**
    ```lua
    local Selection = UI.GetSelectedItems(Options.MyDropdown.Value)
    -- ผลลัพธ์ที่ได้จะเป็น Table (Array) ที่มีแต่ชื่อไอเทมที่คุณเลือกจริงๆ เท่านั้น
    if table.find(Selection, "Golden Egg") then
        print("คุณเลือกไข่ทองไว้!")
    end
    ```

### 5. ระบบจัดการไข่แบบกลุ่ม (Grouped Egg Management)
**คืออะไร:** การรวมงาน Egg Place, Hatch และ Sell ไว้ใน Task เดียวกัน
*   **วิธีพัฒนาต่อ:** 
    หากคุณอยากเพิ่มฟังก์ชัน "ทำความสะอาดไข่" (Clean Egg) ให้เอาไปใส่รวมไว้ใน Task `EggManagement` ใน `Main.lua` เพื่อให้มันทำงานเรียงลำดับกัน ไม่แย่งกันทำงานครับ

---

## ⚠️ ข้อควรระวัง (Best Practices)
*   **Pcall เสมอ**: เมื่อส่งคำสั่งไปยัง RemoteEvent ให้ใช้ `pcall` ครอบเพื่อป้องกันสคริปต์หยุดทำงานเมื่อเกิด Error
*   **Task Wait**: ในทุกๆ Task ต้องมี `task.wait()` เพื่อไม่ให้ CPU ทำงานหนักเกินไป
*   **Modular Thinking**: หากจะเพิ่มระบบใหม่ ให้สร้างไฟล์ `.lua` ใหม่ในโฟลเดอร์ `Modules` เสมอ

---
**พัฒนาโดย**: Antigravity (AI Coding Assistant)
**ปรับปรุงล่าสุด**: 13 มีนาคม 2026
