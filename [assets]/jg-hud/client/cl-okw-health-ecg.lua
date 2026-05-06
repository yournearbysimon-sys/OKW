--[[

  OKW — BPM / ECG strip (web/dist okw-health-ecg.*). Not a jg-hud React widget, so /hud layout editor

  will not give a clean drag box. Use Config.HealthEcg.LayoutCommand (default ecglayout) for px layout.

  Strip follows sprint stamina; optional faint when drained while running (no death).

]]



local function healthPercent(ped)

    local maxH = GetEntityMaxHealth(ped)

    local h = GetEntityHealth(ped)

    if maxH <= 0 then

        return 100.0

    end

    return math.max(0.0, math.min(100.0, (h / maxH) * 100.0))

end



--- Sprint stamina as 0–100 (100 = full reserve). Some builds expose the native as “fatigue” (high when tired);
--- default invert so fresh = green / depleted = red.
local function sprintStaminaPercent(playerId, staminaMax, invert)
    staminaMax = tonumber(staminaMax) or 40.0
    if staminaMax <= 0.0 then
        staminaMax = 40.0
    end
    local rem = GetPlayerSprintStaminaRemaining(playerId)
    if rem == nil then
        return 100.0
    end
    local raw = math.max(0.0, math.min(100.0, (rem / staminaMax) * 100.0))
    if invert ~= false then
        raw = 100.0 - raw
    end
    return raw
end



if not Config.HealthEcg then

    return

end



local ecg = Config.HealthEcg

local prefix = Config.DefaultSettingsKvpPrefix or "hud-"

local kvpLayout = prefix .. "layout"

local kvpDedicated = ecg.dedicatedLayoutKvpKey or "okw-ecg-layout"

local lastApplySig = "\0okw-ecg-sig-unread"



--- Faint state (read from vitals thread for NUI).

local faintEndTime = 0

local faintExhaustMs = 0



local function decodeJson(raw)

    if not raw or raw == "" then

        return nil

    end

    local ok, t = pcall(json.decode, raw)

    if not ok or type(t) ~= "table" then

        return nil

    end

    return t

end



--- Flat okw-ecg-layout KVP → same shape as hud layout entries for sendEcgLayout.

local function entryFromDedicated(t)

    if type(t) ~= "table" then

        return nil

    end

    return {

        hidden = t.hidden,

        dimensions = {

            width = t.width,

            height = t.height,

        },

        offset = {

            left = t.left,

            bottom = t.bottom,

            x = t.left,

            right = t.right,

            top = t.top,

            offsetX = t.offsetX,

            offsetY = t.offsetY,

        },

    }

end



local function npx(n)

    if n == nil then

        return nil

    end

    return string.format("%s", n) .. "px"

end



local function sendEcgLayout(entry, fallbackConfig)

    if entry and entry.hidden == true then

        SendNUIMessage({

            action = "okwHealthEcgLayout",

            data = {

                enabled = false,

                hidden = true,

            },

        })

        return

    end



    local o = entry and entry.offset or {}

    local dim = entry and entry.dimensions or {}

    local left = o.left or o.x

    local right = o.right

    local bottom = o.bottom

    local top = o.top

    local tx = o.offsetX

    local ty = o.offsetY



    local data = {

        enabled = ecg.Enabled ~= false,

        hidden = false,

        offsetLeft = left ~= nil and npx(left) or (fallbackConfig and fallbackConfig.offsetLeft) or nil,

        offsetRight = right ~= nil and npx(right) or nil,

        offsetBottom = bottom ~= nil and npx(bottom) or (fallbackConfig and fallbackConfig.offsetBottom) or nil,

        offsetTop = top ~= nil and npx(top) or nil,

        stripWidth = dim.width ~= nil and npx(dim.width) or (fallbackConfig and fallbackConfig.stripWidth) or nil,

        translateX = tx ~= nil and npx(tx) or npx(0),

        translateY = ty ~= nil and npx(ty) or npx(0),

    }



    SendNUIMessage({

        action = "okwHealthEcgLayout",

        data = data,

    })

end



local function sendConfigOnly()

    SendNUIMessage({

        action = "okwHealthEcgLayout",

        data = {

            enabled = ecg.Enabled ~= false,

            hidden = false,

            offsetLeft = ecg.offsetLeft or "0.55vw",

            offsetBottom = ecg.offsetBottom or "2.75vh",

            stripWidth = ecg.stripWidth or "clamp(268px, 34vw, 440px)",

            translateX = "0px",

            translateY = "0px",

        },

    })

end



local fallbackConfig = {

    offsetLeft = ecg.offsetLeft,

    offsetBottom = ecg.offsetBottom,

    stripWidth = ecg.stripWidth,

}



local function applyEcgLayoutFromSources()

    if ecg.syncLayoutFromKvp == false then

        return

    end



    local dedRaw = GetResourceKvpString(kvpDedicated)

    local layoutRaw = GetResourceKvpString(kvpLayout)

    local sig = (dedRaw or "") .. "\n" .. (layoutRaw or "")

    if sig == lastApplySig then

        return

    end

    lastApplySig = sig



    local entry = nil

    if dedRaw and dedRaw ~= "" then

        entry = entryFromDedicated(decodeJson(dedRaw))

    end

    if not entry and ecg.useLegacyHudLayoutKey ~= false then

        local layout = decodeJson(layoutRaw)

        if layout and layout.okwHealthEcg then

            entry = layout.okwHealthEcg

        end

    end



    if not entry then

        sendConfigOnly()

        return

    end

    sendEcgLayout(entry, fallbackConfig)

end



function OkwHealthEcg_ApplyLayoutNow()

    lastApplySig = "\0okw-ecg-sig-unread"

    applyEcgLayoutFromSources()

end



CreateThread(function()

    Wait(400)

    if ecg.Enabled == false then

        SendNUIMessage({

            action = "okwHealthEcgLayout",

            data = { enabled = false, hidden = true },

        })

        return

    end



    if ecg.syncLayoutFromKvp == false then

        sendConfigOnly()

        return

    end



    applyEcgLayoutFromSources()



    local pollMs = tonumber(ecg.layoutPollMs) or 500

    while ecg.Enabled ~= false and ecg.syncLayoutFromKvp ~= false do

        Wait(pollMs)

        applyEcgLayoutFromSources()

    end

end)



--- ox_lib: pixel layout (jg /hud cannot drag this NUI subtree as one unit).

local layoutCmd = ecg.LayoutCommand

if type(layoutCmd) == "string" and layoutCmd ~= "" and layoutCmd ~= "false" then

    RegisterCommand(layoutCmd, function()

        if ecg.Enabled == false then

            return

        end

        local cur = decodeJson(GetResourceKvpString(kvpDedicated)) or {}

        local input = lib.inputDialog("OKW — ECG / BPM strip (px)", {

            { type = "number", label = "From left",       default = tonumber(cur.left) or tonumber(cur.x) or 11,  min = 0 },

            { type = "number", label = "From bottom",     default = tonumber(cur.bottom) or 30, min = 0 },

            { type = "number", label = "Width",           default = tonumber(cur.width) or 400,  min = 80 },

            { type = "number", label = "Nudge X",         default = tonumber(cur.offsetX) or 0 },

            { type = "number", label = "Nudge Y",         default = tonumber(cur.offsetY) or 0 },

        })

        if not input then

            return

        end

        local t = {

            left = input[1],

            bottom = input[2],

            width = input[3],

            offsetX = input[4],

            offsetY = input[5],

            hidden = false,

        }

        local ok, encoded = pcall(json.encode, t)

        if not ok or not encoded then

            return

        end

        SetResourceKvp(kvpDedicated, encoded)

        OkwHealthEcg_ApplyLayoutNow()

        lib.notify({ title = "ECG strip", description = "Position saved.", type = "success" })

    end, false)

end



--- Collapse when stamina empty while sprinting/running; wake after configured delay (no kill).

CreateThread(function()

    Wait(2600)

    local step = tonumber(ecg.faintCheckIntervalMs) or 120

    while true do

        if ecg.Enabled == false then

            return

        end

        Wait(step)

        if ecg.FaintEnabled == false then

            goto continue

        end



        local now = GetGameTimer()

        local ped = PlayerPedId()

        local pid = PlayerId()



        if now < faintEndTime then

            DisableControlAction(0, 21, true)

            DisableControlAction(0, 22, true)

            if ped ~= 0 and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then

                SetPedToRagdoll(ped, 4000, 4000, 0, false, false, false)

            end

            goto continue

        end



        if faintEndTime > 0 and now >= faintEndTime then

            faintEndTime = 0

            faintExhaustMs = 0

            if ped ~= 0 then

                ClearPedTasksImmediately(ped)

                local rec = tonumber(ecg.faintRecoverStamina) or 0.42

                RestorePlayerStamina(pid, math.max(0.05, math.min(1.0, rec)))

            end

            DoScreenFadeIn(700)

            goto continue

        end



        local stMax = tonumber(ecg.staminaMax) or 40.0

        local st = sprintStaminaPercent(pid, stMax, ecg.staminaInvertPercent)

        local thr = tonumber(ecg.faintStaminaThresholdPct) or 4.0

        local moving = IsPedSprinting(ped) or IsPedRunning(ped)



        if moving and ped ~= 0 and not IsPedInAnyVehicle(ped, false) and st <= thr then

            faintExhaustMs = faintExhaustMs + step

        else

            faintExhaustMs = math.max(0, faintExhaustMs - step * 2)

        end



        local hold = tonumber(ecg.faintHoldSprintMs) or 1000

        local dur = tonumber(ecg.faintDurationMs) or 10000

        if faintExhaustMs >= hold and faintEndTime == 0 and st <= thr and ped ~= 0 and not IsPedInAnyVehicle(ped, false) then

            faintExhaustMs = 0

            faintEndTime = now + dur

            CreateThread(function()

                DoScreenFadeOut(400)

                Wait(450)

                local p = PlayerPedId()

                if p ~= 0 and not IsPedInAnyVehicle(p, false) then

                    local rag = math.min(dur, 12000)

                    SetPedToRagdoll(p, rag, rag, 0, false, false, false)

                end

            end)

        end



        ::continue::

    end

end)



CreateThread(function()

    Wait(2200)

    if ecg.Enabled == false then

        return

    end

    local interval = tonumber(ecg.updateIntervalMs) or 100

    local useStam = ecg.useStaminaForStrip ~= false

    while true do

        if ecg.Enabled == false then

            return

        end

        local ped = PlayerPedId()

        local pid = PlayerId()

        local pct = 100.0

        if ped and ped ~= 0 then

            if useStam then

                pct = sprintStaminaPercent(pid, tonumber(ecg.staminaMax) or 40.0, ecg.staminaInvertPercent)

            else

                pct = healthPercent(ped)

            end

        end

        local now = GetGameTimer()

        local faintOn = faintEndTime > now

        SendNUIMessage({

            action = "okwHealthEcgVitals",

            stamina = pct,

            health = useStam and pct or healthPercent(ped),

            faint = faintOn,

        })

        Wait(interval)

    end

end)
