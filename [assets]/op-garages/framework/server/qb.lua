QBCore = GetResourceState('qb-core') == 'started' and true or false
local isQBox = GetResourceState('qbx_core') == 'started' and true or false

if not QBCore then return end
if isQBox then return end

Fr = {}

Framework = exports['qb-core']:GetCoreObject()
Fr.usersTable = "players"
Fr.identificatorTable = "citizenid"

Fr.Table = 'player_vehicles'
Fr.VehProps = 'mods'
Fr.OwnerTable = "citizenid"
Fr.StoredTable = 'state'

Fr.PlayerLoaded = 'QBCore:Client:OnPlayerLoaded'
Fr.IsPlayerDead = function(source)
    local Player = Fr.getPlayerFromId(source)
    local isLastStand = Player.PlayerData.metadata["inlaststand"]
    local isDead = Player.PlayerData.metadata["isdead"]
    if isDead and isLastStand then
        return true
    else
        return false
    end
end
Fr.RegisterServerCallback = function(...)
    return Framework.Functions.CreateCallback(...)
end
Fr.GetPlayerFromIdentifier = function(identifier)
    return Framework.Functions.GetPlayerByCitizenId(identifier)
end
Fr.getPlayerFromId = function(...)
    return Framework.Functions.GetPlayer(...)
end
Fr.GetMoney = function(Player, account)
    if account == "money" then account = "cash" end
    return Player.PlayerData.money[account]
end
Fr.ManageMoney = function(Player, account, action, amount)
    if account == "money" then account = "cash" end
    if action == "add" then
        return Player.Functions.AddMoney(account, amount)
    else
        return Player.Functions.RemoveMoney(account, amount)
    end
end
Fr.GetIndentifier = function(source)
    local xPlayer = Fr.getPlayerFromId(source)
    return xPlayer.PlayerData.citizenid
end
Fr.GetPlayerName = function(sourceOrIdentifier)
    local xPlayer = Fr.getPlayerFromId(sourceOrIdentifier)
    local name

    if xPlayer then
        name = xPlayer.PlayerData.charinfo.firstname .." ".. xPlayer.PlayerData.charinfo.lastname
    else
        local result = MySQL.Sync.fetchAll(
            "SELECT charinfo FROM players WHERE citizenid = @citizenid",
            {['@citizenid'] = trim(sourceOrIdentifier)}
        )
        if result and result[1] then
            result[1].charinfo = json.decode(result[1].charinfo)
            name = result[1].charinfo.firstname .. " " .. result[1].charinfo.lastname
        else
            name = "Unknown"
        end
    end

    return name
end
Fr.GetGroup = function(source)
    return "Admin"
end
Fr.GetSourceFromPlayerObject = function(xPlayer)
    if xPlayer then
        return xPlayer.PlayerData.source
    else
        return nil
    end
end
Fr.GetPlayerJob = function(xPlayer)
    local job = {
        name = xPlayer.PlayerData.job.name,
        grade = xPlayer.PlayerData.job.grade.level
    }
    return job
end
Fr.GetPlayerGang = function(xPlayer)
    if GetResourceState('op-crime') == 'started' then
        local xSource = Fr.GetSourceFromPlayerObject(xPlayer)
        local ident = Fr.GetIndentifier(xSource)
        local havePerms = exports['op-crime']:checkPermissions(ident, "garage_access")
        local grade = 0

        if Config.ReverseGradeCheck then 
            if havePerms then 
                grade = 50
            else
                grade = 0
            end
        else
            if havePerms then 
                grade = 0
            else
                grade = 50
            end
        end

        local gang = {
            name = tostring(Player(xSource).state.gangId),
            grade = grade,
        }
        return gang
    elseif GetResourceState('rcore_gangs') == 'started' then
        local xSource = Fr.GetSourceFromPlayerObject(xPlayer)
        local gang = exports.rcore_gangs:GetPlayerGang(xSource)
        if not gang then return {} end

        return {
            name = gang.name,
            grade = 0
        }
    else
        local gang = {
            name = xPlayer.PlayerData.gang.name,
            grade = xPlayer.PlayerData.gang.grade.level
        }
        return gang
    end
end