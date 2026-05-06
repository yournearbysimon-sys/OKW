ESX = GetResourceState('es_extended') == 'started' and true or false

if not ESX then return end

Fr = {}

Framework = exports["es_extended"]:getSharedObject()
Fr.PlayerLoaded = 'esx:playerLoaded'
Fr.VehicleEncode = "vehicle"
Fr.identificatorTable = "identifier"
Fr.StoredTable = 'stored'
Fr.JobUpdateEvent = "esx:setJob"
Fr.OwnerTable = "owner"

function getGangName()
    if GetResourceState('op-crime') == 'started' then
        local orgData = exports['op-crime']:getPlayerOrganisation()

        if not orgData then return nil end

        return tostring(orgData.id)
    elseif GetResourceState('rcore_gangs') == 'started' then
        local gang = exports.rcore_gangs:GetPlayerGang()
        if not gang then return nil end

        return gang.name
    else
        if (PlayerData ~= nil and PlayerData.job ~= nil and PlayerData.job.name ~= nil) then
            return PlayerData.job.name
        end
        return nil
    end
end

function getGangGrade(cb) 
    if GetResourceState('op-crime') == 'started' then
        exports['op-crime']:playerGaragePermission(function(canOpen)
            if Config.ReverseGradeCheck then
                if canOpen then 
                    cb(50)
                else
                    cb(0)
                end
            else
                if canOpen then 
                    cb(0)
                else
                    cb(50)
                end
            end
        end)
    elseif GetResourceState('rcore_gangs') == 'started' then
        local gang = exports.rcore_gangs:GetPlayerGang()
        if not gang then return cb(nil) end
        cb(0)
    else
        if (PlayerData ~= nil and PlayerData.job ~= nil and PlayerData.job.grade ~= nil) then
            cb(type(PlayerData.job.grade) == "table" and PlayerData.job.grade.level or PlayerData.job.grade) 
        end
        return cb(nil)
    end
end

AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
    reloadGangGarages(job)
end)

Fr.TriggerServerCallback = function(...)
    return Framework.TriggerServerCallback(...)
end
Fr.GetVehicleProperties = function(vehicle) 
    return Framework.Game.GetVehicleProperties(vehicle)
    --return lib.getVehicleProperties(vehicle)
end
Fr.DeleteVehicle = function(vehicle, notNetworked)
    if Config.Addons.AdvancedParking and not notNetworked then
        return exports["AdvancedParking"]:DeleteVehicle(vehicle, false)
    end
    return Framework.Game.DeleteVehicle(vehicle)
end
Fr.SpawnVehicle = function(vehicleModel, coords, heading, networked, cb)
    local model = type(vehicleModel) == 'number' and vehicleModel or joaat(vehicleModel)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    networked = networked == nil and true or networked

    if not vector then return end

    CreateThread(function()
        ScriptFunctions.RequestModel(model)

        local vehicle = CreateVehicle(model, vector.xyz, heading or 0.0, networked, true)

        if not DoesEntityExist(vehicle) then
            SetModelAsNoLongerNeeded(model)
            if cb then cb(nil) end
            return
        end

        if networked then
            local id = NetworkGetNetworkIdFromEntity(vehicle)
            SetNetworkIdCanMigrate(id, true)
            SetEntityAsMissionEntity(vehicle, true, true)
        end

        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetModelAsNoLongerNeeded(model)
        SetVehRadioStation(vehicle, 'OFF')

        RequestCollisionAtCoord(vector.x, vector.y, vector.z)

        local timeout = GetGameTimer() + 5000
        while not HasCollisionLoadedAroundEntity(vehicle) do
            Wait(0)

            if GetGameTimer() > timeout then
                break
            end

            if not DoesEntityExist(vehicle) then
                if cb then cb(nil) end
                return
            end
        end

        if cb then
            cb(vehicle)
        end
    end)
end
Fr.SetVehicleProperties = function(...) 
    return Framework.Game.SetVehicleProperties(...)
    --return lib.setVehicleProperties(...)
end
Fr.GetPlayerData = function()
    return Framework.GetPlayerData()
end