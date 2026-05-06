if Config.Clothing ~= "origen_clothing" then return end

function applySkinToPed(ped, skin)
    if type(skin) ~= "table" then
        print("^1[applySkinToPed]^0 Invalid skin data (expected table, got " .. type(skin) .. ").")
        return
    end

    local ok, err = pcall(function()
        exports['origen_clothing']:SetAppearance(ped, skin.skin)
    end)
end

function openCreationMenu(isMale)
    local model = isMale and `mp_m_freemode_01` or `mp_f_freemode_01`
    lib.requestModel(model, 30000)
    SetPlayerModel(PlayerId(), model)
    Wait(150)
    SetModelAsNoLongerNeeded(model)

    local playerPed = PlayerPedId()
    SetPedDefaultComponentVariation(playerPed)
    if model == `mp_m_freemode_01` then
        SetPedHeadBlendData(playerPed, 0, 0, 0, 0, 0, 0, 0, 0, 0, false)
    elseif model == `mp_f_freemode_01` then
        SetPedHeadBlendData(playerPed, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0, false)
    end

    local gender = isMale and "male" or "female"
    local currentCoords = GetEntityCoords(PlayerPedId())
    exports['origen_clothing']:startPedCreation(currentCoords, gender, PlayerPedId(), false, function()
        Fr.CharacterCreated()
    end)
end