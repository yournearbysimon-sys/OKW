while Framework == nil do Wait(5) end

local scriptName = GetCurrentResourceName()
if scriptName ~= "op-multicharacter" then return print('[OTHERPLANET.DEV] Required resource name: op-multicharacter (needed for proper functionality)') end

-- NOT USED ANYMORE
--if ESX then
--    CreateThread(function()
--        while not Framework.PlayerLoaded do
--            Wait(100)
--            if NetworkIsPlayerActive(Framework.playerId) then
--                Framework.DisableSpawnManager()
--                setupCharacterSelection()
--                break
--            end
--        end
--    end)
--end

CreateThread(function()
    while true do
        Wait(100)
        if NetworkIsSessionStarted() then
            setupCharacterSelection()
            return
        end
    end
end)