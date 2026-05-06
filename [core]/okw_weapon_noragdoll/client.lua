--[[
  Weapon drawn = no ragdoll, no combat roll / dodge.
  Combat roll is Jump (22). We block it for the whole time a gun is out — not only ADS — so space spam cannot roll.
]]

local UNARMED = `WEAPON_UNARMED`

local INPUT_JUMP = 22

--- Strafe roll + common variants; stripped every tick while armed.
local ROLL_ANIMS = {
    { "move_strafe@roll",         "roll_fwd" },
    { "move_strafe@roll",         "roll_bwd" },
    { "move_strafe@roll",         "roll_short" },
    { "move_strafe@roll",         "roll_long" },
    { "move_strafe@roll_fps",    "roll_fwd" },
    { "move_strafe@roll_fps",    "roll_bwd" },
    { "move_strafe@roll_fps",    "roll_short" },
    { "move_strafe@roll_fps",    "roll_long" },
    { "move_strafe@roll_stealth", "roll_fwd" },
    { "move_strafe@roll_stealth", "roll_bwd" },
}

local COMBAT_MOVEMENT_OFFENSIVE = 2
local COMBAT_MOVEMENT_STATIONARY = 0

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

---@param ped number
local function stopAnyCombatRollAnim(ped)
    for i = 1, #ROLL_ANIMS do
        local dict = ROLL_ANIMS[i][1]
        local clip = ROLL_ANIMS[i][2]
        if IsEntityPlayingAnim(ped, dict, clip, 3) then
            StopAnimTask(ped, dict, clip, 8.0)
            ClearPedSecondaryTask(ped)
            return
        end
    end
end

--- Block jump on every gameplay group every frame (spam cannot bypass a single group).
local function blockJumpEverywhere()
    for group = 0, 2 do
        DisableControlAction(group, INPUT_JUMP, true)
    end
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local sleep = 200

        if ped ~= 0 and not IsEntityDead(ped) then
            if isWeaponDrawn(ped) then
                sleep = 0

                -- Ragdoll
                SetPedCanRagdoll(ped, false)
                setCanRagdollFromPlayerImpact(ped, false)
                if IsPedRagdoll(ped) then
                    ResetPedRagdollTimer(ped)
                end

                -- No jump at all with weapon out = no combat roll / dodge from space.
                blockJumpEverywhere()

                -- Locks strafe dodge behaviour while still allowing shooting / movement tasks.
                SetPedCombatMovement(ped, COMBAT_MOVEMENT_STATIONARY)

                -- Strip roll clip if it already started (bypass / timing windows).
                stopAnyCombatRollAnim(ped)

                -- Space spam: secondary motion stack often holds the roll — clear it.
                if IsControlPressed(0, INPUT_JUMP)
                    or IsDisabledControlPressed(0, INPUT_JUMP)
                    or IsPedJumping(ped) then
                    ClearPedSecondaryTask(ped)
                end
            else
                SetPedCanRagdoll(ped, true)
                setCanRagdollFromPlayerImpact(ped, true)
                SetPedCombatMovement(ped, COMBAT_MOVEMENT_OFFENSIVE)
            end
        end

        Wait(sleep)
    end
end)
