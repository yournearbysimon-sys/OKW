--[[
  OKW — BPM / ECG strip inside jg-hud NUI (see web/dist/index.html + assets/okw-health-ecg.*).
  Toggle in config/config.lua → Config.HealthEcg.Enabled

  Layout: add "okwHealthEcg" to data/default-settings.json (included). On start we merge that
  block into hud-layout KVP if missing so /hud can list and move it like other widgets.
  Position syncs from KVP while the resource runs.
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
--- Sentinel so the first poll runs even when KVP is empty (nil ~= sentinel).
local lastLayoutRaw = "\0okw-ecg-layout-unread"

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

--- If hud-layout already exists but has no okwHealthEcg, inject the block from default-settings.json.
--- Never write when KVP is empty — that would wipe the full layout; jg-hud will hydrate from default-settings.json first.
local function mergeOkwLayoutFromDefaultsIfMissing()
    local raw = GetResourceKvpString(kvpLayout)
    if not raw or raw == "" then
        return
    end
    local layout = decodeJson(raw)
    if not layout or type(layout) ~= "table" then
        return
    end
    if layout.okwHealthEcg ~= nil then
        return
    end
    local path = Config.DefaultSettingsData or "data/default-settings.json"
    local defRaw = LoadResourceFile(GetCurrentResourceName(), path)
    if not defRaw then
        return
    end
    local def = decodeJson(defRaw)
    if not def or type(def.layout) ~= "table" or def.layout.okwHealthEcg == nil then
        return
    end
    layout.okwHealthEcg = def.layout.okwHealthEcg
    local ok, encoded = pcall(json.encode, layout)
    if ok and encoded then
        SetResourceKvpString(kvpLayout, encoded)
    end
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

local function tryApplyLayoutFromKvp()
    if ecg.syncLayoutFromKvp == false then
        return
    end
    local raw = GetResourceKvpString(kvpLayout)
    if raw == lastLayoutRaw then
        return
    end
    lastLayoutRaw = raw

    local layout = decodeJson(raw)
    if not layout or layout.okwHealthEcg == nil then
        sendConfigOnly()
        return
    end
    sendEcgLayout(layout.okwHealthEcg, {
        offsetLeft = ecg.offsetLeft,
        offsetBottom = ecg.offsetBottom,
        stripWidth = ecg.stripWidth,
    })
end

CreateThread(function()
    Wait(400)
    if ecg.syncLayoutFromKvp ~= false and ecg.mergeDefaultLayout ~= false then
        mergeOkwLayoutFromDefaultsIfMissing()
    end

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

    tryApplyLayoutFromKvp()

    local pollMs = tonumber(ecg.layoutPollMs) or 750
    while ecg.Enabled ~= false and ecg.syncLayoutFromKvp ~= false do
        Wait(pollMs)
        tryApplyLayoutFromKvp()
    end
end)

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
