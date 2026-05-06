--- Clears player state bag `dead` (ox_inventory reads this) and tells the client to fix GTA fatal-injury ped state.
--- Call from your ambulance/revive script on the server after you heal/revive someone, e.g.:
---   exports.okw_revive_state_sync:clearForPlayer(targetServerId)

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
