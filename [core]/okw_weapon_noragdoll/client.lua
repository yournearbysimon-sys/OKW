--[[
  While a non-unarmed weapon is selected (drawn), ragdoll is disabled.
  Prevents weapon-in-hand stumble / weapon-impact ragdoll. Unarmed restores defaults.
]]

local UNARMED = `WEAPON_UNARMED`

---@param ped number
---@return boolean
local function isWeaponDrawn(ped)
    if not ped or ped == 0 then
        return false
    end
    local weapon = GetSelectedPedWeapon(ped)
    return weapon ~= 0 and weapon ~= UNARMED
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local sleep = 200

        if ped ~= 0 and not IsEntityDead(ped) then
            if isWeaponDrawn(ped) then
                sleep = 0
                SetPedCanRagdoll(ped, false)
                SetPedCanRagdollFromPlayerWeaponImpact(ped, false)
                if IsPedRagdoll(ped) then
                    ResetPedRagdollTimer(ped)
                end
            else
                SetPedCanRagdoll(ped, true)
                SetPedCanRagdollFromPlayerWeaponImpact(ped, true)
            end
        end

        Wait(sleep)
    end
end)
