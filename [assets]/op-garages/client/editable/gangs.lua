gangName = nil
gangGrade = 0
oldGangName = nil
oldGangGrade = nil

---------------------------------------------------
-- GANGS
---------------------------------------------------

while Framework == nil do Wait(5) end

RegisterNetEvent("op-crime:jobChanged", function(jobId, jobLabel, rankName)
  reloadGangGarages()
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
    reloadGangGarages()
end)

RegisterNetEvent('rcore_gangs:client:set_gang', function()
    reloadGangGarages()
end)

RegisterNetEvent('rcore_gangs:client:set_finished_rivalry', function()
    reloadGangGarages()
end)

RegisterNetEvent('esx:updatePlayerData', function()
    reloadGangGarages()
end)

function loadGang()
    while (Fr.GetPlayerData() == nil) do
        Wait(100)
    end

    PlayerData = Fr.GetPlayerData()
    oldGangGrade = gangGrade
    oldGangName = gangName
    gangName = getGangName()
    getGangGrade(function(gr)
        gangGrade = gr

        if oldGangName then
            for k, v in pairs(createdGarages) do
                local cfg = garages[tostring(k)]
                if cfg.Gang then
                    if cfg.Gang.name == oldGangName then
                        RemoveBlip(v.Blip)
                    end
                end
            end
        end

        if gangName then
            for k, v in pairs(createdGarages) do
                local cfg = garages[tostring(k)]
                if cfg.Gang then
                    if cfg.Gang.name == gangName and gangGrade >= cfg.Gang.grade then
                        local coords 
                        if cfg.Type ~= "car" then
                            coords = vec3(cfg.AccessPoint.x, cfg.AccessPoint.y, cfg.AccessPoint.z)
                        else
                            coords = vec3(cfg.CenterOfZone.x, cfg.CenterOfZone.y, cfg.CenterOfZone.z)
                        end

                        if cfg.blipDisabled == 0 or not cfg.blipDisabled then
                            createdGarages[k].Blip = SH.addBlip(coords, Config.Blips[cfg.Type].blipId, Config.Blips[cfg.Type].blipColor, TranslateIt('blip_type_' .. cfg.Type) .. ": " .. capitalizeWords(gangName))
                        end
                    end
                end
            end
        end
    end)
end

function reloadGangGarages()
    oldGangGrade = gangGrade
    oldGangName = gangName
    gangName = getGangName()
    getGangGrade(function(gr)
        gangGrade = gr
        hideTextUI() 

        if oldGangName then
            for k, v in pairs(createdGarages) do
                local cfg = garages[tostring(k)]
                if cfg and cfg.Gang then
                    if cfg.Gang.name == oldGangName then
                        RemoveBlip(v.Blip)
                    end
                end
            end
        end

        if gangName then
            for k, v in pairs(createdGarages) do
                local cfg = garages[tostring(k)]
                if cfg and cfg.Gang then
                    if cfg.Gang.name == gangName and gangGrade >= cfg.Gang.grade then
                        local coords 
                        if cfg.Type ~= "car" then
                            coords = vec3(cfg.AccessPoint.x, cfg.AccessPoint.y, cfg.AccessPoint.z)
                        else
                            coords = vec3(cfg.CenterOfZone.x, cfg.CenterOfZone.y, cfg.CenterOfZone.z)
                        end

                        if cfg.blipDisabled == 0 or not cfg.blipDisabled then
                            createdGarages[k].Blip = SH.addBlip(coords, Config.Blips[cfg.Type].blipId, Config.Blips[cfg.Type].blipColor, TranslateIt('blip_type_' .. cfg.Type) .. ": " .. capitalizeWords(gangName))
                        end
                    end
                end
            end
        end
    end)
end