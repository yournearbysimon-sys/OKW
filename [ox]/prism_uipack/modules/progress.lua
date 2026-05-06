---@diagnostic disable: duplicate-doc-alias
---@diagnostic disable: duplicate-doc-field

local progress
local DisableControlAction = DisableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local playerState = LocalPlayer.state
local createdProps = {}
local maxProps = GetConvarInt('ox:progressPropLimit', 2)

---@class ProgressPropProps
---@field model string
---@field bone? number
---@field pos vector3
---@field rot vector3
---@field rotOrder? number

---@class ProgressProps
---@field variant? 'primary' | 'secondary' -- Defaults to "primary"
---@field label? string
---@field duration number
---@field position? 'top-center' | 'bottom-center' | 'right-center' | 'left-center'
---@field useWhileDead? boolean
---@field allowRagdoll? boolean
---@field allowCuffed? boolean
---@field allowFalling? boolean
---@field allowSwimming? boolean
---@field canCancel? boolean
---@field cancelKey? string
---@field anim? { dict?: string, clip: string, flag?: number, blendIn?: number, blendOut?: number, duration?: number, playbackRate?: number, lockX?: boolean, lockY?: boolean, lockZ?: boolean, scenario?: string, playEnter?: boolean }
---@field prop? ProgressPropProps | ProgressPropProps[]
---@field disable? { move?: boolean, sprint?: boolean, car?: boolean, combat?: boolean, mouse?: boolean }

local function createProp(ped, prop)
    Utils.requestModel(prop.model)
    local coords = GetEntityCoords(ped)
    local object = CreateObject(prop.model, coords.x, coords.y, coords.z, false, false, false)

    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, prop.bone or 60309), prop.pos.x, prop.pos.y, prop.pos.z,
        prop.rot.x, prop.rot.y, prop.rot.z, true,
        true, false, true, prop.rotOrder or 0, true)
    SetModelAsNoLongerNeeded(prop.model)

    return object
end

local function interruptProgress(data)
    local ped = PlayerPedId()
    if not data.useWhileDead and IsEntityDead(ped) then return true end
    if not data.allowRagdoll and IsPedRagdoll(ped) then return true end
    if not data.allowCuffed and IsPedCuffed(ped) then return true end
    if not data.allowFalling and IsPedFalling(ped) then return true end
    if not data.allowSwimming and IsPedSwimming(ped) then return true end
end

local controls = {
    INPUT_LOOK_LR = 1,
    INPUT_LOOK_UD = 2,
    INPUT_SPRINT = 21,
    INPUT_AIM = 25,
    INPUT_MOVE_LR = 30,
    INPUT_MOVE_UD = 31,
    INPUT_DUCK = 36,
    INPUT_VEH_MOVE_LEFT_ONLY = 63,
    INPUT_VEH_MOVE_RIGHT_ONLY = 64,
    INPUT_VEH_ACCELERATE = 71,
    INPUT_VEH_BRAKE = 72,
    INPUT_VEH_EXIT = 75,
    INPUT_VEH_MOUSE_CONTROL_OVERRIDE = 106
}

---@param data ProgressProps
local function startProgress(data)
    playerState.invBusy = true
    progress = data
    local anim = data.anim

    if anim then
        if anim.dict then
            Utils.requestAnimDict(anim.dict)

            TaskPlayAnim(PlayerPedId(), anim.dict, anim.clip, anim.blendIn or 3.0, anim.blendOut or 1.0, anim.duration or -1,
                anim.flag or 49, anim.playbackRate or 0,
                anim.lockX, anim.lockY, anim.lockZ)
            RemoveAnimDict(anim.dict)
        elseif anim.scenario then
            TaskStartScenarioInPlace(PlayerPedId(), anim.scenario, 0,
                anim.playEnter == nil or anim.playEnter --[[@as boolean]])
        end
    end

    if data.prop then
        TriggerServerEvent('prism:progressProps', data.prop)
    end

    local disable = data.disable
    local startTime = GetGameTimer()
    local playerId = PlayerId()

    while progress do
        if disable then
            if disable.mouse then
                DisableControlAction(0, controls.INPUT_LOOK_LR, true)
                DisableControlAction(0, controls.INPUT_LOOK_UD, true)
                DisableControlAction(0, controls.INPUT_VEH_MOUSE_CONTROL_OVERRIDE, true)
            end

            if disable.move then
                DisableControlAction(0, controls.INPUT_SPRINT, true)
                DisableControlAction(0, controls.INPUT_MOVE_LR, true)
                DisableControlAction(0, controls.INPUT_MOVE_UD, true)
                DisableControlAction(0, controls.INPUT_DUCK, true)
            end

            if disable.sprint and not disable.move then
                DisableControlAction(0, controls.INPUT_SPRINT, true)
            end

            if disable.car then
                DisableControlAction(0, controls.INPUT_VEH_MOVE_LEFT_ONLY, true)
                DisableControlAction(0, controls.INPUT_VEH_MOVE_RIGHT_ONLY, true)
                DisableControlAction(0, controls.INPUT_VEH_ACCELERATE, true)
                DisableControlAction(0, controls.INPUT_VEH_BRAKE, true)
                DisableControlAction(0, controls.INPUT_VEH_EXIT, true)
            end

            if disable.combat then
                DisableControlAction(0, controls.INPUT_AIM, true)
                DisablePlayerFiring(playerId, true)
            end
        end

        if interruptProgress(progress) then
            progress = false
        end

        Wait(0)
    end

    if data.prop then
        TriggerServerEvent('prism:progressProps', nil)
    end

    if anim then
        if anim.dict then
            StopAnimTask(PlayerPedId(), anim.dict, anim.clip, 1.0)
            Wait(0) -- This is needed here otherwise the StopAnimTask is cancelled
        else
            ClearPedTasks(PlayerPedId())
        end
    end

    playerState.invBusy = false
    local duration = progress ~= false and GetGameTimer() - startTime + 100 -- give slight leeway

    if progress == false or duration <= data.duration then
        SendNUIMessage({ action = 'progressCancel' })
        return false
    end

    return true
end

---@param data ProgressProps
---@return boolean?
function ProgressBar(data)
    while progress ~= nil do Wait(0) end

    if not interruptProgress(data) then
        SendNUIMessage({
            action = 'progress',
            data = {
                label = data.label,
                duration = data.duration,
                position = data.position,
                variant = data.variant,
                canCancel = data.canCancel
            }
        })

        return startProgress(data)
    end
end

---left for compat
---@param data ProgressProps
---@return boolean?
function ProgressCircle(data)
    ProgressBar(data)
end

function CancelProgress()
    if not progress then
        error('No progress bar is active')
    end

    progress = false
end

---@return boolean
function ProgressActive()
    return progress and true
end

RegisterNUICallback('progressComplete', function(data, cb)
    cb(1)
    progress = nil
end)

RegisterCommand('cancelprogress_prism', function()
    if progress?.canCancel then progress = false end
end, false)

RegisterKeyMapping('cancelprogress_prism', 'Cancel Progressbar', 'keyboard', GetConvar('prism:progressCancelKey', 'X'))

local function deleteProgressProps(serverId)
    local playerProps = createdProps[serverId]

    if not playerProps then return end

    createdProps[serverId] = nil

    for i = 1, #playerProps do
        local prop = playerProps[i]

        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
end

RegisterNetEvent('onPlayerDropped', function(serverId)
    deleteProgressProps(serverId)
end)

AddStateBagChangeHandler('prism:progressProps', nil, function(bagName, key, value, reserved, replicated)
    if replicated then return end

    local ply = GetPlayerFromStateBagName(bagName)
    if ply == 0 then return end

    local ped = GetPlayerPed(ply)
    local serverId = GetPlayerServerId(ply)

    if not value or createdProps[serverId] then
        return deleteProgressProps(serverId)
    end

    local playerProps = {}

    if value.model then
        local prop = createProp(ped, value)

        if prop then
            playerProps[#playerProps + 1] = prop
        end
    else
        local propCount = math.min(maxProps, #value)

        for i = 1, propCount do
            local prop = createProp(ped, value[i])

            if prop then
                playerProps[#playerProps + 1] = prop
            end
        end
    end

    createdProps[serverId] = playerProps
end)