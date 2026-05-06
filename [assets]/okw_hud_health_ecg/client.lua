local Config = Config ---@type table

local function healthPercent(ped)
    local maxH = GetEntityMaxHealth(ped)
    local h = GetEntityHealth(ped)
    if maxH <= 0 then
        return 100
    end
    return math.max(0.0, math.min(100.0, (h / maxH) * 100.0))
end

CreateThread(function()
    Wait(1500)
    SendNUIMessage({
        action = "config",
        offsetLeft = Config.offsetLeft,
        offsetBottom = Config.offsetBottom,
        stripWidth = Config.stripWidth,
    })

    local interval = tonumber(Config.updateIntervalMs) or 100
    while true do
        local ped = PlayerPedId()
        local pct = 100.0
        if ped and ped ~= 0 then
            pct = healthPercent(ped)
        end
        -- Stress model: lower health -> faster BPM for the readout (tunable in NUI).
        SendNUIMessage({
            action = "vitals",
            health = pct,
        })
        Wait(interval)
    end
end)
