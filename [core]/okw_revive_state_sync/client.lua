local function clientClearBody()
    local ped = PlayerPedId()

    if IsPedFatallyInjured(ped) or IsPedDeadOrDying(ped, true) then
        local c = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, h, true, false, false)
        SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
        ClearPedBloodDamage(ped)
        SetPedCanRagdoll(ped, true)
    end

    -- ox_inventory blocks when invBusy is true (e.g. left over after revive); do not clear if actually cuffed.
    if not IsPedCuffed(ped) then
        LocalPlayer.state:set('invBusy', false, true)
    end

    if GetResourceState('es_extended') ~= 'started' then
        return
    end

    local ESX = exports['es_extended']:getSharedObject()
    if ESX and ESX.SetPlayerData then
        ESX.SetPlayerData('dead', false)
    end
end

RegisterNetEvent('okw_revive_state_sync:clientClear', clientClearBody)

-- Keeps server state bag `dead` in sync with ESX spawn (fixes stuck ox_inventory without EMS export).
AddEventHandler('esx:onPlayerSpawn', function()
    TriggerServerEvent('okw_revive_state_sync:syncFromSpawn')
end)
