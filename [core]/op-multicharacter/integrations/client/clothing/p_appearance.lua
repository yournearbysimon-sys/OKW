if Config.Clothing ~= "p_appearance" then return end

function applySkinToPed(ped, skin)
    if type(skin) ~= "table" then
        print("^1[applySkinToPed]^0 Invalid skin data (expected table, got " .. type(skin) .. ").")
        return
    end

    TriggerEvent("p_appearance/applySkin", skin.skin, nil, ped)
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