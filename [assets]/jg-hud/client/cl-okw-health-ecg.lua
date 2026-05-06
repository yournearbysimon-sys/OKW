--[[
  OKW — BPM / ECG strip inside jg-hud NUI (see web/dist/index.html + assets/okw-health-ecg.*).
  Toggle in config/config.lua → Config.HealthEcg.Enabled
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

CreateThread(function()
    Wait(2000)

    SendNUIMessage({
        action = "okwHealthEcgInit",
        data = {
            enabled = ecg.Enabled ~= false,
            offsetLeft = ecg.offsetLeft or "0.55vw",
            offsetBottom = ecg.offsetBottom or "2.75vh",
            stripWidth = ecg.stripWidth or "clamp(268px, 34vw, 440px)",
        },
    })

    if ecg.Enabled == false then
        return
    end

    local interval = tonumber(ecg.updateIntervalMs) or 100
    while true do
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
