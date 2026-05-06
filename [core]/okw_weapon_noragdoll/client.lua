--[[
  While a non-unarmed weapon is selected (drawn):
  - Ragdoll disabled (stumble / impact).
  - While aiming (ADS), combat roll is blocked (Jump in aim mode = roll).
]]

local UNARMED = `WEAPON_UNARMED`
--- https://docs.fivem.net/docs/game-references/controls/
local INPUT_JUMP = 22

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
                -- Space/Jump while aimed = combat roll — block only during ADS.
                if IsPlayerFreeAiming(PlayerId()) then
                    DisableControlAction(0, INPUT_JUMP, true)
                end
            else
                SetPedCanRagdoll(ped, true)
                setCanRagdollFromPlayerImpact(ped, true)
            end
        end

        Wait(sleep)
    end
end)
