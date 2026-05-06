if Config.Clothing ~= "origen_clothing" then return end

function convertSkin(identifier)
    if ESX then
        local skinData = exports.origen_clothing:getAppearance(identifier)
        return {skin = skinData.skin, model = skinData.model or skinData.skin.model}
    elseif QBCore or QBox then
        local skinData = exports.origen_clothing:getAppearance(identifier)
        return {skin = skinData.skin, model = skinData.model or skinData.skin.model}
    end
end