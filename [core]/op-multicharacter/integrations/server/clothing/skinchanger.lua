if Config.Clothing ~= "skinchanger" and Config.Clothing ~= "p_appearance" then
    return
end

function convertSkin(identifier)
    if ESX then
        local result = MySQL.query.await("SELECT `skin` FROM `users` WHERE `identifier` = ?", {identifier})
        if result and result[1] and result[1].skin then
            return {skin = json.decode(result[1].skin)}
        end
    elseif QBCore or QBox then
        local result = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = ? AND active = 1", {identifier})
        if result and result[1] and result[1].skin then
            return {skin = json.decode(result[1].skin)}
        end
    end
end