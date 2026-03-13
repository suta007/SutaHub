# Project SutaHub (AI_Code) - Context & Architecture

This document defines the structure, rules, and relationships for the SutaHub project. **Read this before modifying code.**

## 1. Project Identity
*   **Name**: SutaHub (AI_Code)
*   **Type**: Modular Roblox Script Automation (Grow a Garden).
*   **Architecture**: Modular (Central Controller + Specialized Modules).
*   **Entry Point**: `Main.lua`

## 2. The "Reference" Code (IMPORTANT)
*   **File**: `f:\LuaCode\SutaHub\RefCode\EfHub.lua`
*   **Status**: 🔴 **LEGACY / READ-ONLY** 🔴
*   **Purpose**: 
    *   This is the original working prototype (Monolithic).
    *   It contains the "Source of Truth" for game logic, RemoteEvent arguments, and algorithms.
    *   **DO NOT EDIT** this file. Use it only to copy/study logic when porting to Modules.
    *   If a feature works in `EfHub.lua` but not in `SutaHub`, compare the logic here.

## 3. Module Mapping (Refactoring Strategy)
We are moving logic from the monolithic `EfHub.lua` into specific modules in `Modules/`:

| Logic Category | Legacy (`EfHub.lua`) | Modern (`SutaHub/Modules/`) |
| :--- | :--- | :--- |
| **Core System** | `ToggleTask`, `DataStream`, `DevLog` | **`Core.lua`** (Handles Logging, Tasks, Services) |
| **User Interface** | `Fluent`, `Window`, `Tabs` | **`UI.lua`** (Handles GUI creation & SaveManager) |
| **Farming** | `CollectFruitWorker`, `AutoPlant`, `ShovelPlant` | **`Farming.lua`** |
| **Pets** | `HatchEgg`, `PlaceEggs`, `FeedPet`, `Mutation` | **`Pet.lua`** |
| **Shop** | `ProcessBuy`, `BuyList` table | **`Shop.lua`** |
| **Events** | `AlienEvent`, `CatchAlien` | **`Event.lua`** |

## 4. Coding Standards & Rules

### A. Task Management
*   **Legacy**: Used `task.spawn` inside functions or local `ToggleTask`.
*   **Modern**: Use **`Core.ToggleTask(Name, Boolean, Function)`** inside `Main.lua`.
    *   *Why?* It automatically handles loop creation, cancellation, and error handling.

### B. Dependency Injection
*   Modules must not `require` each other at the top level to avoid circular dependencies.
*   Use the `Init` function to pass dependencies.
    *   *Example*: `Pet.Init(Core, UI, Farming)` allows Pet module to access Farming functions.

### C. Reactive Data (DataStream)
*   **Legacy**: Hooked `DataStream.OnClientEvent` mixed in the main file.
*   **Modern**: Hook `Core.DataStream` in `Main.lua` (or inside Module Init) and dispatch to specific module functions like `Shop.ProcessBuy`.

### D. UI Synchronization
*   When a UI Toggle changes, it must trigger `UI.SyncBackgroundTasks()` (if passed via Init) or `Main.SyncBackgroundTasks()` to update the active `Core.ToggleTask` state immediately.

## 5. Development Workflow
1.  **Analyze**: Check `EfHub.lua` for how a specific feature (e.g., "Auto Water") was implemented.
2.  **Port**: Move that logic into the appropriate Module (e.g., `Farming.lua`).
3.  **Clean**: Replace global variables with Module-scoped variables (e.g., `FruitQueue` -> `Farming.FruitQueue`).
4.  **Connect**: Register the task in `Main.SyncBackgroundTasks`.

---
*Use this context to ensure all code generated maintains the modular architecture and does not regress to the monolithic style.*