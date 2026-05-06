--[[
  While a non-unarmed weapon is selected (drawn):
  - Ragdoll disabled (stumble / impact).
  - While aiming: combat roll is hard-blocked — all control groups + killing roll anims if they start.
]]

local UNARMED = `WEAPON_UNARMED`

--- https://docs.fivem.net/docs/game-references/controls/
local INPUT_JUMP = 22
local INPUT_AIM = 25

--- Known strafe combat-roll clips (Jump while ADS). Killed if spam bypasses DisableControlAction.
local ROLL_ANIMS = {
    { "move_strafe@roll",      "roll_fwd" },
    { "move_strafe@roll",      "roll_bwd" },
    { "move_strafe@roll_fps", "roll_fwd" },
    { "move_strafe@roll_fps", "roll_bwd" },
}

--- SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT
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

--- Free aim, held ADS, or soft-aim — IsPlayerFreeAiming alone misses some camera/bind setups.
---@return boolean
local function isPlayerAiming()
    local pid = PlayerId()
    if IsPlayerFreeAiming(pid) then
        return true
    end
    if IsPlayerTargettingAnything(pid) then
        return true
    end
    -- Right mouse / LT — use "IsPressed" so we still see input even if another script disabled it.
    if IsControlPressed(0, INPUT_AIM) or IsDisabledControlPressed(0, INPUT_AIM) then
        return true
    end
    return false
end

---@param ped number
local function stopAnyCombatRollAnim(ped)
    for i = 1, #ROLL_ANIMS do
        local dict = ROLL_ANIMS[i][1]
        local clip = ROLL_ANIMS[i][2]
        if IsEntityPlayingAnim(ped, dict, clip, 3) then
            StopAnimTask(ped, dict, clip, 8.0)
            -- Roll often sits on secondary slot; strip it without nuking weapon task.
            ClearPedSecondaryTask(ped)
            break
        end
    end
end

--- Jump blocked on every input group; spam can't route around group 0 only.
---@param enabled boolean false = fully block jump input
local function setJumpBlockedAllGroups(enabled)
    if enabled then
        for group = 0, 2 do
            DisableControlAction(group, INPUT_JUMP, true)
        end
    end
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

                if isPlayerAiming() then
                    setJumpBlockedAllGroups(true)
                    stopAnyCombatRollAnim(ped)
                    -- Extra nuke: if jump is still being eaten into movement, cut secondary motion.
                    if IsPedJumping(ped) then
                        ClearPedSecondaryTask(ped)
                    end
                end
            else
                SetPedCanRagdoll(ped, true)
                setCanRagdollFromPlayerImpact(ped, true)
            end
        end

        Wait(sleep)
    end
end)
