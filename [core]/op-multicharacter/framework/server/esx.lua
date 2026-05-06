ESX = GetResourceState('es_extended') == 'started' and true or false

if not ESX then return end
Framework = nil

local ok, result = pcall(function()
    return exports["es_extended"]:getSharedObject()
end)

if ok and result then
    Framework = result
else
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

Fr.usersTable = "users"
Fr.identificatorTable = "identifier"
Fr.Table = 'owned_vehicles'
Fr.VehProps = 'vehicle'
Fr.OwnerTable = "owner"
Fr.StoredTable = "stored"
Fr.PlayerLoaded = 'esx:playerLoaded'
Fr.identifierType = GetConvar("esx:identifier", "license") or "license"
Fr.Prefix = "char"

Fr.ValidateCharacterDetails = function(data)
    local formattedFirstName = formatName(data.name)
    local formattedLastName = formatName(data.lastname)

    local query = 'SELECT 1 FROM users WHERE firstname = ? AND lastname = ? LIMIT 1'
    local result = MySQL.query.await(query, { formattedFirstName, formattedLastName })
    return result[1] ~= nil
end

lib.callback.register('op-multicharacter:validateInfo', function(source, data)
    local validated = Fr.ValidateCharacterDetails(data)
    return {status = validated}
end)

Fr.CanLogout = function(playerId)
    if inMultiChar[tostring(playerId)] then return false end
    
    return true
end

Fr.LogOut = function(playerId, cb)
    if not Fr.CanLogout(playerId) then return cb(false) end

    if not ServerConfig.Commands.logout.enable then 
        cb(false)
    end 

    local xPlayer = Fr.getPlayerFromId(tonumber(playerId))
    local data = Fr.GetPlayerBasicDataForLog(xPlayer)

    TriggerEvent('esx:playerLogout', tonumber(playerId), function()
        debugPrint("Player " .. playerId .. " Just logged out using command!")

        cb(true)
        ServerConfig.formatWebHook("character_unloaded", data.name, data.id, json.encode(data.ids))
    end)
end

Fr.getPlayerFromId = function(...)
    return Framework.GetPlayerFromId(...)
end

Fr.addItem = function(xPlayer, itemname, quantity)
    if not xPlayer then return nil end

    return xPlayer.addInventoryItem(itemname, quantity)
end

Fr.PlayCharacter = function(playerId, charId)
    TriggerEvent("esx:onPlayerJoined", playerId, charId)
    Framework.Players[Framework.GetIdentifier(playerId)] = charId
end

Fr.NewCharacter = function(playerId, charId, data)
    TriggerEvent('esx:onPlayerJoined', playerId, charId, data)
end

Fr.GetPlayerBasicDataForLog = function(xPlayer)
    if not xPlayer then
        return nil
    end

    local name = xPlayer.name
    if name == GetPlayerName(xPlayer.source) then
        name = xPlayer.get('firstName') .. ' ' .. xPlayer.get('lastName')
    end

    local idTable = Fr.getIdents(xPlayer.source)

    local data = {
        name = name,
        id = xPlayer.identifier,
        ids = idTable
    }

    return data
end

Fr.DeleteChar = function(src, login)
    local identifier = GetPlayerIdentifierByType(src, Fr.identifierType)
    identifier = identifier:gsub(("%s:"):format(Fr.identifierType), "") 
    local finalChar = login .. ":" .. identifier

    local query = "DELETE FROM `users` WHERE `identifier` = '"..finalChar.."'"
    MySQL.query.await(query)
end

local function safeParseId(identifier, prefix)
    if type(identifier) ~= "string" then return nil end

    local colon = string.find(identifier, ":")
    if not colon then return nil end

    local idString = string.sub(identifier, #prefix + 1, colon - 1)
    return tonumber(idString) or nil
end

Fr.GetCharactersList = function(playerId)
    local identifier = GetPlayerIdentifierByType(playerId, Fr.identifierType)
    identifier = identifier:gsub(("%s:"):format(Fr.identifierType), "")

    local slots = Fr.GetPlayerSlots(identifier, playerId)
    local rawCharacters = Fr.GetPlayerInfo(identifier, slots)

    debugPrint("Player RAW Characters", json.encode(rawCharacters))

    identifier = Fr.Prefix .. "%:" .. identifier

    local characters = nil
    local newCharId = 1

    if rawCharacters then
        local characterCount = #rawCharacters
        characters = {}

        local usedIds = {}

        for i = 1, characterCount, 1 do
            local v = rawCharacters[i]
            local accounts = {}

            if type(v.accounts) == "string" then
                local ok, decoded = pcall(json.decode, v.accounts)
                if ok and type(decoded) == "table" then
                    accounts = decoded
                else
                    accounts = { bank = 0, money = 0 }
                end
            end

            local id = safeParseId(v.identifier, Fr.Prefix)

            if id then
                usedIds[id] = true

                local job, grade = v.job or "unemployed", tostring(v.job_grade)
                local jobsList = Framework.GetJobs()

                if jobsList[job] and jobsList[job].grades[grade] then
                    if job ~= "unemployed" then
                        grade = jobsList[job].grades[grade].label
                    else
                        grade = ""
                    end
                    job = jobsList[job].label
                end

                local skin = {}

                if type(convertSkin) == "function" then
                    skin = convertSkin(v.identifier)
                else
                    print("^3[WARN]^0 Compatible appearance script not found! Skipped convert ped appearance.")
                end

                if type(skin) == "table" then
                    if type(getTattoos) == "function" then
                        skin.tattoos = getTattoos(v.identifier)
                    end
                else
                    print("^1[WARN]^0 Expected 'skin' to be a table, got:", type(skin))
                    skin = {}
                end

                local position = nil

                if v.position and type(v.position) == "string" then
                    local ok, decoded = pcall(json.decode, v.position)
                    if ok and type(decoded) == "table" then
                        position = decoded
                    end
                end

                if type(Fr.GetCharacterGang) == "function" then
                    local returnedGang = Fr.GetCharacterGang(v.identifier)
                    if returnedGang then
                        gang = returnedGang.name
                        gangGradeName = returnedGang.rank
                    end
                end

                local pos = position or {}

                table.insert(characters, {
                    id = v.identifier,                              
                    login = Fr.Prefix .. tostring(id),             
                    bank = accounts.bank or 0,
                    money = accounts.money or 0,
                    job = job,
                    job_grade = grade,
                    gang = gang or "None",
                    gangName = gangGradeName or "None",
                    firstname = v.firstname,
                    lastname = v.lastname,
                    dateofbirth = v.dateofbirth,
                    skin = skin,
                    disabled = v.disabled,
                    sex = v.sex == "m" and "male" or "female",
                    lastPos = vec4(pos.x or 0.0, pos.y or 0.0, pos.z or 0.0, pos.heading or 0.0)
                })
            else
                print("^1[WARNING] Failed to parse identifier → " .. tostring(v.identifier) .. "^0 Skipping..")
            end
        end

        newCharId = 1
        while usedIds[newCharId] do
            newCharId = newCharId + 1
        end
    end

    debugPrint(
        tostring(playerId) .. " | Final player data:",
        json.encode({ chars = characters, slots = slots, newCharId = newCharId })
    )

    return { chars = characters, slots = slots, newCharId = newCharId }
end

Fr.GetPlayerSlots = function(identifier, src)
    if not ServerConfig.DiscordRanks.enable then
        local slots = MySQL.scalar.await("SELECT slots FROM multicharacter_slots WHERE identifier = ?", { identifier })
            or Config.Misc.DefaultCharsAmount

        debugPrint("[01] Player " .. identifier .. " Slots:", slots)
        return slots
    end

    local finalSlots = Config.Misc.DefaultCharsAmount
    local playerDiscord = Fr.GetDiscordId(src)

    debugPrint("Player " .. src .. " discord id:", playerDiscord)

    if not playerDiscord then
        debugPrint("[04] Player " .. src .. " Slots:", finalSlots)
        return finalSlots
    end

    local roles = DiscordGetMemberSync(tostring(playerDiscord))

    if not roles or #roles == 0 then
        debugPrint("[02] Player " .. src .. " Slots:", finalSlots)
        return finalSlots
    end

    local roleSlots = ServerConfig.DiscordRanks.ranks or {}
    local bestRole, bestSlots = nil, finalSlots

    for _, roleId in ipairs(roles) do
        roleId = tostring(roleId)
        local slotsForRole = tonumber(roleSlots[roleId])

        if slotsForRole and slotsForRole > bestSlots then
            bestSlots = slotsForRole
            bestRole = roleId
        end
    end

    finalSlots = bestSlots

    if bestRole then
        debugPrint(("[03] Player %s Slots: %s (best role: %s)"):format(src, finalSlots, bestRole))
    else
        debugPrint("[03] Player " .. src .. " Slots:", finalSlots)
    end

    return finalSlots
end

Fr.GetPlayerInfo = function(identifier, slots)
    identifier = tostring(identifier)

    local sql = [[
        SELECT * FROM users
        WHERE identifier LIKE ?
        LIMIT ]] .. slots

    return MySQL.query.await(sql, { "%" .. identifier .. "%" })
end

Fr.GetIdentifier = function(source)
    local xPlayer = Fr.getPlayerFromId(source)
    if not xPlayer then return nil end
    return xPlayer.identifier
end

Fr.VehiclePurchased = function(model, playerId)
    local readyModel = joaat(model)
    local ident = Fr.GetIdentifier(playerId)

    if not ident then return print('[ERROR] Unable to assign vehicle to player with id:', playerId) end

    local plate = generatePlate()

    local query = [[
        INSERT INTO `owned_vehicles`
        (`owner`, `plate`, `vehicle`)
        VALUES (?, ?, ?)
    ]]

    local params = {
        ident,
        plate,
        json.encode({ model = readyModel, plate = plate })
    }

    MySQL.Async.insert(query, params, function(insertId)
        if not insertId then
            print(("[^1ERROR^7] Failed to insert vehicle with plate %s into owned_vehicles"):format(plate))
        else
            local insertInfo = ("[^2INFO^7] Inserted vehicle into owned_vehicles. ID: %s, Plate: %s"):format(insertId, plate)
            debugPrint(insertInfo)
        end
    end)
end

Fr.IsPlateTaken = function(plate)
    local p = promise.new()
    
    MySQL.scalar('SELECT plate FROM owned_vehicles WHERE plate = ?', {plate},
    function(result)
        p:resolve(result ~= nil)
    end)

    return Citizen.Await(p)
end

Fr.AddMoney = function(xPlayer, account, amount)
    if not xPlayer then return end
    return xPlayer.addAccountMoney(account, amount)
end

Fr.FormatNewCharId = function(charId)
    return Fr.Prefix .. charId
end

if not ServerConfig.EnableDiscordRanks then
    if ServerConfig.Commands.setslots.enable then 
        Framework.RegisterCommand(ServerConfig.Commands.setslots.command, ServerConfig.Commands.setslots.allowed, 
        function(xPlayer, args)
            local identifier = args.player
            local amount = tonumber(args.slots)
            setSlots(identifier, amount, xPlayer.source) 

            TriggerClientEvent('op-multicharacter:sendNotify', xPlayer.source, TranslateIt('command_setslots_success', amount), "success", 5)
        end, true, {
            help = TranslateIt('command_setslots_help'),
            validate = true,
            arguments = {
                { name = "player", help = TranslateIt('command_setslots_player'), type = "string" },
                { name = "slots", help = TranslateIt('command_setslots_slots'), type = "number" },
            },
        })
    end
end

if ServerConfig.Commands.logout.enable then 
    Framework.RegisterCommand(ServerConfig.Commands.logout.command, ServerConfig.Commands.logout.allowed, 
    function(xPlayer, args)
        if not xPlayer then return end

        Fr.LogOut(tostring(xPlayer.source), function(res)
            if res then 
                TriggerClientEvent('op-multicharacter:sendNotify', xPlayer.source, TranslateIt('command_logout_success'), "success", 5)
                TriggerClientEvent('op-multicharacter:completeLogout', xPlayer.source)
            else 
                TriggerClientEvent('op-multicharacter:sendNotify', xPlayer.source, TranslateIt('command_logout_error'), "error", 5)
            end
        end)
    end, true, {
        help = TranslateIt('command_logout_help'),
        validate = false,
        arguments = {},
    })
end