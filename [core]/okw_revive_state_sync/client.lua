RegisterNetEvent('okw_revive_state_sync:clientClear', function()
    local ped = PlayerPedId()

    if IsPedFatallyInjured(ped) or IsPedDeadOrDying(ped, true) then
        local c = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, h, true, false, false)
        SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
        ClearPedBloodDamage(ped)
        SetPedCanRagdoll(ped, true)
    end

    if GetResourceState('es_extended') ~= 'started' then
        return
    end

    local ESX = exports['es_extended']:getSharedObject()
    if ESX and ESX.SetPlayerData then
        ESX.SetPlayerData('dead', false)
    end
end)
