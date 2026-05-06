ScriptFunctions = {}

ScriptFunctions.GetVehicleDeformation = function(vehicle)
    if GetResourceState('VehicleDeformation') ~= 'missing' then
        local deformation = exports["VehicleDeformation"]:GetVehicleDeformation(vehicle)
        return deformation
    end

    return {}
end

ScriptFunctions.SetVehicleDeformation = function(vehicle, deformation)
    if GetResourceState('VehicleDeformation') ~= 'missing' then
        exports["VehicleDeformation"]:SetVehicleDeformation(vehicle, deformation)
    end
end

ScriptFunctions.GetClosestPlayers = function(maxDistance)
    maxDistance = maxDistance or 10.0
    local playersInRange = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, playerId in ipairs(GetActivePlayers()) do
        local otherPed = GetPlayerPed(playerId)
        local playerServerId = GetPlayerServerId(playerId)
        if otherPed ~= playerPed then
            local otherCoords = GetEntityCoords(otherPed)
            local distance = #(playerCoords.xyz - otherCoords.xyz)
            if distance <= maxDistance then
                table.insert(playersInRange, { id = playerServerId, distance = distance })
            end
        end
    end

    return playersInRange
end

ScriptFunctions.RequestModel = function(modelHash, cb)
	modelHash = (type(modelHash) == 'number' and modelHash or joaat(modelHash))

	if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
		RequestModel(modelHash)

		while not HasModelLoaded(modelHash) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function getJobName()
    if (PlayerData ~= nil and PlayerData.job ~= nil and PlayerData.job.name ~= nil) then
        return PlayerData.job.name
    end
    return nil
end

function getJobGrade() 
    if (PlayerData ~= nil and PlayerData.job ~= nil and PlayerData.job.grade ~= nil) then
        return type(PlayerData.job.grade) == "table" and PlayerData.job.grade.level or PlayerData.job.grade
    end
    return nil
end