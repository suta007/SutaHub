local EF = {}
local Core = nil
function EF.Init(RefCore)
	Core = RefCore
end

function EF.Teleport_UI()
	local TeleportUI = Core.LocalPlayer.PlayerGui:WaitForChild("Teleport_UI"):WaitForChild("Frame")
	local PetButton = TeleportUI:WaitForChild("Pets")
	local GearButton = TeleportUI:WaitForChild("Gear")
	PetButton.Visible = true
	GearButton.Visible = true
end

return EF
