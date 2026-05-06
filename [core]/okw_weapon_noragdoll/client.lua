--[[
  While a non-unarmed weapon is selected (drawn), ragdoll is disabled.
  Prevents weapon-in-hand stumble / weapon-impact ragdoll. Unarmed restores defaults.
]]

local UNARMED = `WEAPON_UNARMED`

--- SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT — older names/doc typos used *Weapon* and crashed.
local function setCanRagdollFromPlayerImpact(ped, toggle)
    local fn = SetPedCanRagdollFromPlayerImpact
    if fn then
        fn(ped, toggle)
    end
end

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
                setCanRagdollFromPlayerImpact(ped, false)
                if IsPedRagdoll(ped) then
                    ResetPedRagdollTimer(ped)
                end
            else
                SetPedCanRagdoll(ped, true)
                setCanRagdollFromPlayerImpact(ped, true)
            end
        end

        Wait(sleep)
    end
end)
