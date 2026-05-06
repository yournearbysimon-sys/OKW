--[[
  OKW — BPM / ECG strip (web/dist okw-health-ecg.*). Not a jg-hud React widget, so /hud layout editor
  will not give a clean drag box. Use Config.HealthEcg.LayoutCommand (default ecglayout) for px layout.
]]

local function healthPercent(ped)
    local maxH = GetEntityMaxHealth(ped)
    local h = GetEntityHealth(ped)
    if maxH <= 0 then
        return 100.0
    end
    return math.max(0.0, math.min(100.0, (h / maxH) * 100.0))
end

if not Config.HealthEcg then
    return
end

local ecg = Config.HealthEcg
local prefix = Config.DefaultSettingsKvpPrefix or "hud-"
local kvpLayout = prefix .. "layout"
local kvpDedicated = ecg.dedicatedLayoutKvpKey or "okw-ecg-layout"
local lastApplySig = "\0okw-ecg-sig-unread"

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
    Wait(1600)
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

CreateThread(function()
    Wait(2200)
    if ecg.Enabled == false then
        return
    end
    local interval = tonumber(ecg.updateIntervalMs) or 100
    while true do
        if ecg.Enabled == false then
            return
        end
        local ped = PlayerPedId()
        local pct = 100.0
        if ped and ped ~= 0 then
            pct = healthPercent(ped)
        end
        SendNUIMessage({
            action = "okwHealthEcgVitals",
            health = pct,
        })
        Wait(interval)
    end
end)

