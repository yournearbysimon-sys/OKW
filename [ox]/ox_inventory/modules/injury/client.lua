local BoneMapping = {
    [31086] = { 'HEAD' },
    [39317] = { 'HEAD' },
    [7019]  = { 'HEAD' },

    [52301] = { 'RIGHT_LEG' },
    [14201] = { 'LEFT_LEG' },

    [57005] = { 'RIGHT_ARM' },
    [60309] = { 'RIGHT_ARM' },
    [18905] = { 'LEFT_ARM' },

    [36864] = { 'RIGHT_LEG' },
    [51826] = { 'RIGHT_LEG' },

    [63931] = { 'LEFT_LEG' },
    [58271] = { 'LEFT_LEG' },

    [28252] = { 'RIGHT_ARM' },
    [40269] = { 'RIGHT_ARM' },
    [2992]  = { 'RIGHT_ARM' },

    [61163] = { 'LEFT_ARM' },
    [45509] = { 'LEFT_ARM' },
    [32139] = { 'LEFT_ARM' },

    [23553] = { 'TORSO' },
    [24816] = { 'TORSO' },
    [24817] = { 'TORSO' },
    [24818] = { 'TORSO' },
    [10706] = { 'LEFT_ARM' },
    [64729] = { 'RIGHT_ARM' },
}

local FallInjuryWeaponHashes = {
    [-842959696] = true,
    [3452007600] = true,
}

local FallInjuries = {
    'LEFT_LEG',
    'RIGHT_LEG',
}

local ValidInjuryNames = {
    'HEAD',
    'TORSO',
    'RIGHT_ARM',
    'LEFT_ARM',
    'RIGHT_LEG',
    'LEFT_LEG',
}

local InjuryAliases = {
    HEAD = 'HEAD',
    SKULL = 'HEAD',

    TORSO = 'TORSO',
    SPINE = 'TORSO',
    RIBS_STERNUM = 'TORSO',
    PELVIS = 'TORSO',

    RIGHT_ARM = 'RIGHT_ARM',
    R_CLAVICLE = 'RIGHT_ARM',
    R_SCAPULA = 'RIGHT_ARM',
    R_HUMERUS = 'RIGHT_ARM',
    R_RADIUS_ULNA = 'RIGHT_ARM',
    R_HAND = 'RIGHT_ARM',

    LEFT_ARM = 'LEFT_ARM',
    L_CLAVICLE = 'LEFT_ARM',
    L_SCAPULA = 'LEFT_ARM',
    L_HUMERUS = 'LEFT_ARM',
    L_RADIUS_ULNA = 'LEFT_ARM',
    L_HAND = 'LEFT_ARM',

    RIGHT_LEG = 'RIGHT_LEG',
    R_FEMUR_PATELLA = 'RIGHT_LEG',
    R_TIBIA_FIBULA = 'RIGHT_LEG',
    R_FOOT = 'RIGHT_LEG',

    LEFT_LEG = 'LEFT_LEG',
    L_FEMUR_PATELLA = 'LEFT_LEG',
    L_TIBIA_FIBULA = 'LEFT_LEG',
    L_FOOT = 'LEFT_LEG',
}

local InjuryDisplayNames = {
    HEAD = 'Head',
    TORSO = 'Torso',
    RIGHT_ARM = 'Right Arm',
    LEFT_ARM = 'Left Arm',
    RIGHT_LEG = 'Right Leg',
    LEFT_LEG = 'Left Leg',
}

local ValidInjuryLookup = {}
local InjuryDebugEnabled = false
local Injuries = {}
local InjuryPreviewState = {
    active = false,
    injuries = {},
    index = 1,
    token = 0,
}

for i = 1, #ValidInjuryNames do
    ValidInjuryLookup[ValidInjuryNames[i]] = true
end

local function NormalizeInjuryName(injuryName)
    if not injuryName then return end
    return InjuryAliases[string.upper(injuryName)]
end

local function GetInjuryList()
    local injuryList = {}

    for i = 1, #ValidInjuryNames do
        local injuryName = ValidInjuryNames[i]

        if Injuries[injuryName] then
            injuryList[#injuryList + 1] = injuryName
        end
    end

    return injuryList
end

local function GetDisplayedInjuryList()
    if InjuryPreviewState.active then
        return InjuryPreviewState.injuries
    end

    return GetInjuryList()
end

local function SendDisplayedInjuries(injuryList)
    SendNUIMessage({
        action = 'setInjuries',
        data = injuryList
    })
end

local function ApplyInjuries(boneNames)
    if not boneNames then return end

    for i = 1, #boneNames do
        local normalized = NormalizeInjuryName(boneNames[i])

        if normalized then
            Injuries[normalized] = true
        end
    end
end

local function UpdateInventoryInjuries()
    SendDisplayedInjuries(GetDisplayedInjuryList())
end

local function StopInjuryPreview(silent)
    if not InjuryPreviewState.active then return end

    InjuryPreviewState.active = false
    InjuryPreviewState.injuries = {}
    InjuryPreviewState.index = 1
    InjuryPreviewState.token += 1

    lib.hideTextUI()
    UpdateInventoryInjuries()

    if not silent then
        lib.notify({
            type = 'inform',
            description = 'Injury preview disabled.',
        })
    end
end

local function StartInjuryPreview()
    if InjuryPreviewState.active then return end

    InjuryPreviewState.active = true
    InjuryPreviewState.injuries = {}
    InjuryPreviewState.index = 1
    InjuryPreviewState.token += 1

    local previewToken = InjuryPreviewState.token

    lib.notify({
        type = 'inform',
        description = 'Injury preview enabled. Use /injurypreview again to stop.',
    })

    CreateThread(function()
        while InjuryPreviewState.active and previewToken == InjuryPreviewState.token do
            local injuryName = ValidInjuryNames[InjuryPreviewState.index]
            local displayName = InjuryDisplayNames[injuryName] or injuryName

            InjuryPreviewState.injuries = { injuryName }
            SendDisplayedInjuries(InjuryPreviewState.injuries)
            lib.showTextUI(('Injury Preview\n%s'):format(displayName), { position = 'right-center' })

            if InjuryDebugEnabled then
                print(('[ox_inventory] Preview injury: %s'):format(injuryName))
            end

            Wait(900)

            if not InjuryPreviewState.active or previewToken ~= InjuryPreviewState.token then
                break
            end

            InjuryPreviewState.injuries = {}
            SendDisplayedInjuries(InjuryPreviewState.injuries)

            Wait(260)

            InjuryPreviewState.index += 1

            if InjuryPreviewState.index > #ValidInjuryNames then
                InjuryPreviewState.index = 1
            end
        end
    end)
end

local function TryApplyBoneInjury(lastBone)
    if not lastBone or lastBone == 0 then return false end

    local boneNames = BoneMapping[lastBone]

    if not boneNames then
        if InjuryDebugEnabled then
            print(('[ox_inventory] Unmapped damage bone: %s'):format(lastBone))
        end

        return false
    end

    ApplyInjuries(boneNames)
    UpdateInventoryInjuries()
    ClearEntityLastWeaponDamage(cache.ped)

    if InjuryDebugEnabled then
        print(('[ox_inventory] Damage bone %s -> %s'):format(lastBone, table.concat(boneNames, ', ')))
    end

    return true
end

local function TryApplyFallInjury(weaponHash)
    if not FallInjuryWeaponHashes[weaponHash] then return false end
    if not (IsPedFalling(cache.ped) or IsPedRagdoll(cache.ped)) then return false end

    ApplyInjuries(FallInjuries)
    UpdateInventoryInjuries()

    if InjuryDebugEnabled then
        print(('[ox_inventory] Applied fall injuries from weapon hash %s'):format(weaponHash))
    end

    return true
end

AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventNetworkEntityDamage' then
        local victim = data[1]
        
        if tonumber(victim) == tonumber(cache.ped) then
            
            
            
            
            
            
            local weaponHash = data[7]

            
            local found, lastBone = GetPedLastDamageBone(cache.ped)

            
            if found and TryApplyBoneInjury(lastBone) then
                return
            end
            
            
            CreateThread(function()
                for i=1, 10 do 
                    Wait(100) 
                    found, lastBone = GetPedLastDamageBone(cache.ped)
                    if found and lastBone ~= 0 then break end
                end
                
                if found and TryApplyBoneInjury(lastBone) then
                    return
                end

                if TryApplyFallInjury(weaponHash) then
                    return
                end

                if InjuryDebugEnabled then
                    print(('[ox_inventory] Damage event without mapped bone. weaponHash=%s found=%s lastBone=%s'):format(
                        tostring(weaponHash),
                        tostring(found),
                        tostring(lastBone)
                    ))
                end
            end)
        end
    end
end)

local lastHealth = 0

SetInterval(function()
    if not cache.ped then return end
    
    local health = GetEntityHealth(cache.ped)
    local maxHealth = GetEntityMaxHealth(cache.ped)

    if health >= (maxHealth - 2) and lastHealth < (maxHealth - 2) then
        Injuries = {}
        UpdateInventoryInjuries()
    end
    
    if IsPedFatallyInjured(cache.ped) then
    end

    lastHealth = health
end, 1000)

RegisterNUICallback('getInjuries', function(_, cb)
    cb(GetDisplayedInjuryList())
end)

AddStateBagChangeHandler('invOpen', nil, function(bagName, key, value, _reserved, replicated)
    if bagName ~= ('player:%s'):format(cache.serverId) then return end
    if value then
        UpdateInventoryInjuries()
    end
end)

RegisterCommand('testinjury', function(_, args)
    local firstArg = args[1] and string.upper(args[1]) or nil

    if not firstArg then
        print(('[ox_inventory] Available injuries: %s'):format(table.concat(ValidInjuryNames, ', ')))
        lib.notify({
            type = 'inform',
            description = 'Usage: /testinjury HEAD or /testinjury RIGHT_ARM LEFT_LEG or /testinjury clear',
        })
        return
    end

    if firstArg == 'CLEAR' or firstArg == 'RESET' then
        Injuries = {}
        UpdateInventoryInjuries()
        lib.notify({ type = 'success', description = 'Injuries cleared.' })
        return
    end

    local selected = {}
    local seen = {}
    local invalid = {}

    for i = 1, #args do
        for injuryName in string.gmatch(args[i], '([^,]+)') do
            local normalized = string.upper(injuryName)

            if normalized == 'ALL' then
                selected = {}

                for j = 1, #ValidInjuryNames do
                    selected[j] = ValidInjuryNames[j]
                end

                seen = {}
                break
            end

            local mappedInjury = NormalizeInjuryName(normalized)

            if mappedInjury and ValidInjuryLookup[mappedInjury] then
                if not seen[mappedInjury] then
                    seen[mappedInjury] = true
                    selected[#selected + 1] = mappedInjury
                end
            else
                invalid[#invalid + 1] = injuryName
            end
        end

        if args[i] and string.upper(args[i]) == 'ALL' then
            break
        end
    end

    if #invalid > 0 then
        lib.notify({
            type = 'error',
            description = ('Unknown injuries: %s'):format(table.concat(invalid, ', ')),
        })
        return
    end

    if #selected == 0 then
        lib.notify({
            type = 'error',
            description = 'No valid injuries provided.',
        })
        return
    end

    Injuries = {}
    ApplyInjuries(selected)
    UpdateInventoryInjuries()

    lib.notify({
        type = 'success',
        description = ('Applied injuries: %s'):format(table.concat(selected, ', ')),
    })
end, false)

RegisterCommand('injurydebug', function(_, args)
    local mode = args[1] and string.lower(args[1]) or nil

    if mode == 'on' then
        InjuryDebugEnabled = true
    elseif mode == 'off' then
        InjuryDebugEnabled = false
    else
        InjuryDebugEnabled = not InjuryDebugEnabled
    end

    lib.notify({
        type = 'inform',
        description = ('Injury debug %s'):format(InjuryDebugEnabled and 'enabled' or 'disabled'),
    })
end, false)

RegisterCommand('injurypreview', function(_, args)
    local mode = args[1] and string.lower(args[1]) or 'toggle'

    if mode == 'off' or mode == 'stop' then
        StopInjuryPreview()
        return
    end

    if mode == 'on' or mode == 'start' then
        if not InjuryPreviewState.active then
            StartInjuryPreview()
        end
        return
    end

    if InjuryPreviewState.active then
        StopInjuryPreview()
    else
        StartInjuryPreview()
    end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        lib.hideTextUI()
    end
end)
