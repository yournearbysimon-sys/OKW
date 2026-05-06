tempGaragesIndex = 5000

while Framework == nil do Wait(5) end

function addTempPrivateGarage(Label, Type, Coords, Radius, PrivatePlayersList)
    garages[tostring(tempGaragesIndex)] = {
        Index = tempGaragesIndex,
        Label = Label,
        Type = Type,
        CenterOfZone = vec4(Coords.CenterOfZone.x, Coords.CenterOfZone.y, Coords.CenterOfZone.z, Coords.CenterOfZone.w),
        AccessPoint = vec4(Coords.AccessPoint.x, Coords.AccessPoint.y, Coords.AccessPoint.z, Coords.AccessPoint.w),
        Radius = Radius,
        IsPrivate = true,
        PrivatePlayersList = PrivatePlayersList,
        zPoints = {
            minZ = 0.0, 
            maxZ = 0.0
        },
        onespawn = vec4(0.0, 0.0, 0.0, 0.0),
        blipDisabled = false,
    }
    tempGaragesIndex = tempGaragesIndex + 1
    return tempGaragesIndex - 1
end
exports('addTempPrivateGarage', addTempPrivateGarage)

function removeTempPrivateGarage(index)
    garages[tostring(index)] = nil
end
exports('removeTempPrivateGarage', removeTempPrivateGarage)

RegisterServerEvent('op-garages:deregisterGarage')
AddEventHandler('op-garages:deregisterGarage', function(id)
    id = tonumber(id)
    if id < 5000 then return end
    removeTempPrivateGarage(id)
end)

Fr.RegisterServerCallback('op-garages:registerGarage', function(source, cb, data)
    local id = addTempPrivateGarage(data.Label, data.Type, data.Coords, data.Radius, data.PrivatePlayersList)
    cb(id)
end)

Fr.RegisterServerCallback('op-garages:addTempGangGarage', function(source, cb, data)
    local id = addTempGangGarage(data.Label, data.Type, data.Coords, data.Radius, data.GangName, data.GangGrade, data.Mode, data.zPoints, data.onespawn)
    cb(id)
end)

function addTempGangGarage(Label, Type, Coords, Radius, GangName, GangGrade, Mode, zPoints, onespawn)
    local finalZ = {
        minZ = 0.0,
        maxZ = 0.0
    }

    if zPoints then
        finalZ = {
            minZ = zPoints.minZ,
            maxZ = zPoints.maxZ
        }
    end

    garages[tostring(tempGaragesIndex)] = {
        Index = tempGaragesIndex,
        Label = Label,
        Type = Type,
        CenterOfZone = vec4(Coords.CenterOfZone.x, Coords.CenterOfZone.y, Coords.CenterOfZone.z, Coords.CenterOfZone.w),
        AccessPoint = vec4(Coords.AccessPoint.x, Coords.AccessPoint.y, Coords.AccessPoint.z, Coords.AccessPoint.w),
        Radius = Radius,
        IsPrivate = false,
        PrivatePlayersList = {},
        zPoints = {
            minZ = finalZ.minZ, 
            maxZ = finalZ.maxZ
        },
        onespawn = onespawn or vec4(0.0, 0.0, 0.0, 0.0),
        blipDisabled = false,
        Gang = {
            name = GangName,
            grade = GangGrade,
            type = Mode,
        }
    }
    tempGaragesIndex = tempGaragesIndex + 1
    return tempGaragesIndex - 1
end
exports('addTempGangGarage', addTempGangGarage)

function removeTempGangGarage(index)
    garages[tostring(index)] = nil
end
exports('removeTempGangGarage', removeTempGangGarage)

function removeTempPrivateGarage(index)
    garages[tostring(index)] = nil
end
exports('removeTempPrivateGarage', removeTempPrivateGarage)