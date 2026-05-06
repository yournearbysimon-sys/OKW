Citizen.CreateThread(function()
    RemoveIpl("gn_bh1_40_blg02_blocker_ipl")
end)

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    
    local doorHash = GetHashKey("h4_p_mp_yacht_door")
    
    AddDoorToSystem(1, doorHash, -1192.1785888672, -190.56326293945, 39.477210998535, false, false, false)
    AddDoorToSystem(2, doorHash, -1190.9626464844, -188.28924560547, 39.477210998535, false, false, false)
    
    DoorSystemSetDoorState(1, 0, false, false)
    DoorSystemSetDoorState(2, 0, false, false)
    
    -- print("^2[Rockford Hills Casino]^7 Doors registered and unlocked")
end)
