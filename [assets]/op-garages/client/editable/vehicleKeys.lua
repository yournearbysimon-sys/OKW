function giveKeys(vehicle, model, plate, net, isSpawner)
    plate = plate:match("^%s*(.-)%s*$")
    debugPrint('Adding keys to vehicle with plate', plate, model, vehicle)

    if Config.KeysDependency == "qs-keys" then
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
    elseif Config.KeysDependency == "qb-keys" or Config.KeysDependency ==
        "sna-vehiclekeys" or Config.KeysDependency == "qbx_vehiclekeys" then
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    elseif Config.KeysDependency == "wasabi_carlock" then
        exports.wasabi_carlock:GiveKey(plate)
    elseif Config.KeysDependency == "dusa_vehiclekeys" then
        exports['dusa_vehiclekeys']:AddKey(plate)
    elseif Config.KeysDependency == "velia_carkeys" then
        exports["velia_carkeys"]:AddKey(plate)
    elseif Config.KeysDependency == "Renewed-Vehiclekeys" then
        exports['Renewed-Vehiclekeys']:addKey(plate)
    elseif Config.KeysDependency == "tgiann-keys" then
        exports["tgiann-hotwire"]:CheckKeyInIgnitionWhenSpawn(vehicle, plate)
        if isSpawner then
            exports["tgiann-hotwire"]:GiveKeyPlate(plate, true)
        end
    elseif Config.KeysDependency == "ak47_vehiclekeys" then
        exports['ak47_vehiclekeys']:GiveKey(plate, false)
    elseif Config.KeysDependency == "ak47_qb_vehiclekeys" then
        exports['ak47_qb_vehiclekeys']:GiveKey(plate, false)
    elseif Config.KeysDependency == "p_carkeys" then
        TriggerServerEvent('p_carkeys:CreateKeys', plate)
    elseif Config.KeysDependency == "MrNewbVehicleKeys" then
        exports.MrNewbVehicleKeys:GiveKeysByPlate(plate)
    elseif Config.KeysDependency == "brutal_keys" then 
        exports.brutal_keys:addVehicleKey(plate, plate)
    elseif Config.KeysDependency == "sy_carkeys" then 
        TriggerServerEvent('sy_carkeys:KeyOnBuy', plate, model) 
    elseif Config.KeysDependency == "mVehicle" then 
        exports.mVehicle:ItemCarKeysClient('add', plate)
    elseif Config.KeysDependency == "old-qb-keys" then
        TriggerServerEvent('vehiclekeys:server:GiveVehicleKeys', plate, GetPlayerServerId(PlayerId()))
    elseif Config.KeysDependency == "custom-qb-keys" then
        TriggerServerEvent('vehiclekeys:server:SetVehicleOwner', plate)
    elseif Config.KeysDependency == "wx_carlock" then
        TriggerServerEvent('op-garages:wxCarlock', vehicle, model, plate)
    elseif Config.KeysDependency == "jaksam_keys" then
        TriggerServerEvent("vehicles_keys:selfGiveCurrentVehicleKeys")
    elseif Config.KeysDependency == "0r-vehiclekeys" then
        local rplate = GetVehicleNumberPlateText(vehicle)
        exports['0r-vehiclekeys']:GiveKeys(rplate)
    elseif Config.KeysDependency =="msk_vehiclekeys" then 
        exports.msk_vehiclekeys:AddKey(vehicle, type)
    end
end

function removeKeys(vehicle, model, plate, net)
    debugPrint('removing keys to vehicle with plate', plate, model, vehicle)
    plate = plate:match("^%s*(.-)%s*$")
    if Config.KeysDependency == "qs-keys" then
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        exports['qs-vehiclekeys']:RemoveKeys(plate, model)
    elseif Config.KeysDependency == "jaksam_keys" then
        TriggerServerEvent("vehicles_keys:selfRemoveKeys", plate)
    elseif Config.KeysDependency == "qb-keys" or Config.KeysDependency ==
        "sna-vehiclekeys" or Config.KeysDependency == "qbx_vehiclekeys" then
        TriggerServerEvent('qb-vehiclekeys:server:RemoveKey', plate)
    elseif Config.KeysDependency == "wasabi_carlock" then
        exports.wasabi_carlock:RemoveKey(plate)
    elseif Config.KeysDependency == "dusa_vehiclekeys" then
        exports['dusa_vehiclekeys']:RemoveKey(plate)
    elseif Config.KeysDependency == "velia_carkeys" then
        exports["velia_carkeys"]:RemoveKey(plate)
    elseif Config.KeysDependency == "Renewed-Vehiclekeys" then
        exports['Renewed-Vehiclekeys']:removeKey(plate)
    elseif Config.KeysDependency == "tgiann-keys" then
        exports["tgiann-hotwire"]:CheckKeyInIgnitionWhenSpawn(vehicle, plate)
    elseif Config.KeysDependency == "ak47_vehiclekeys" then
        exports['ak47_vehiclekeys']:RemoveKey(plate, false)
    elseif Config.KeysDependency == "ak47_qb_vehiclekeys" then
        exports['ak47_qb_vehiclekeys']:RemoveKey(plate, false)
    elseif Config.KeysDependency == "p_carkeys" then
        TriggerServerEvent('p_carkeys:RemoveKeys', plate)
    elseif Config.KeysDependency == "MrNewbVehicleKeys" then
        exports.MrNewbVehicleKeys:RemoveKeysByPlate(plate)
    elseif Config.KeysDependency == "sy_carkeys" then 
    elseif Config.KeysDependency == "mVehicle" then 
        exports.mVehicle:ItemCarKeysClient('delete', plate)
    elseif Config.KeysDependency == "brutal_keys" then 
        exports.brutal_keys:removeKey(plate, true)
    elseif Config.KeysDependency == "old-qb-keys" then
    elseif Config.KeysDependency == "custom-qb-keys" then
        local playerData = Fr.GetPlayerData()
        local identifier = trim(playerData[Fr.identificatorTable])
        TriggerServerEvent('vehiclekeys:server:RemoveKeys', plate, identifier)
    elseif Config.KeysDependency == "wx_carlock" then
    elseif Config.KeysDependency == "0r-vehiclekeys" then
        local rplate = GetVehicleNumberPlateText(vehicle)
        exports['0r-vehiclekeys']:RemoveKeys(rplate)
    elseif Config.KeysDependency == "msk_vehiclekeys" then 
        exports.msk_vehiclekeys:RemoveKey(vehicle, type)
    end
end