if Config.Clothing ~= "skinchanger" then
    return
end

function applySkinToPed(ped, skin)
    if type(skin) ~= "table" then
        print("^1[applySkinToPed]^0 Invalid skin data (expected table, got " .. type(skin) .. ").")
        return
    end

    TriggerEvent("skinchanger:loadSkinOnPed", ped, skin.skin)
end

function openCreationMenu(isMale)
    local model = `mp_m_freemode_01`

    lib.requestModel(model, 30000)
    SetPlayerModel(PlayerId(), model)

    Wait(150)
    SetModelAsNoLongerNeeded(model)

    local playerPed = PlayerPedId()
    SetPedDefaultComponentVariation(playerPed)
    SetPedHeadBlendData(playerPed, 0, 0, 0, 0, 0, 0, 0, 0, 0, false)

    TriggerEvent('esx_skin:openSaveableMenu', function() 
        Fr.CharacterCreated()
    end, function()
        Fr.CharacterCreated()
    end)
end