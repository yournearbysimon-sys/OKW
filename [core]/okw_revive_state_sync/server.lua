--- Clears player state bag `dead` (ox_inventory reads this) and tells the client to fix GTA fatal-injury ped state.
--- Call from your ambulance/revive script on the server after you heal/revive someone, e.g.:
---   exports.okw_revive_state_sync:clearForPlayer(targetServerId)
---
--- ESX often clears client `dead` on spawn but does not reset the `dead` state bag; ox_inventory listens to the bag.
--- Clients also request a sync on `esx:onPlayerSpawn` so you do not depend on EMS hooks alone.

local function clearForPlayer(playerId)
    playerId = tonumber(playerId)
    if not playerId or playerId < 1 then
        return false
    end

    Player(playerId).state:set('dead', false, true)
    TriggerClientEvent('okw_revive_state_sync:clientClear', playerId)
    return true
end

exports('clearForPlayer', clearForPlayer)

RegisterNetEvent('okw_revive_state_sync:syncFromSpawn', function()
    clearForPlayer(source)
end)
