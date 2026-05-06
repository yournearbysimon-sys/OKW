local interiors = {
    {
        -- Motel Room 01L
        ipl = 'instance_int_gn_motel_room_01l_milo_',
        coords = vec3(-1179.14221, 1117.6582, 0.626481533),
        furnished = true, -- true = furnished | false = unfurnished (without furniture)
        entitySets = {
            { name = 'entityset_mtl_room_01l', category = 'furniture' },
            { name = 'entityset_mtl_room_01l_instance', category = 'required' },
        },
        doors = {
            {
                doorHash = "prop_gn_mtl_door_02r",
                doorCoords = vec3(-1176.9819335938, 1114.0999755859, 0.22755658626556),
                locked = true,
            }
        }
    },
    {
        -- Motel Room 01R
        ipl = 'instance_int_gn_motel_room_01r_milo_',
        coords = vec3(-1170.29736, 1117.6582, 0.626481533),
        furnished = true, -- true = furnished | false = unfurnished (without furniture)
        entitySets = {
            { name = 'entityset_mtl_room_01r', category = 'furniture' },
            { name = 'entityset_mtl_room_01r_instance', category = 'required' },
        },
        doors = {
            {
                doorHash = "prop_gn_mtl_door_02l",
                doorCoords = vec3(-1172.4576416016, 1114.0999755859, 0.22755658626556),
                locked = true,
            }
        }
    },
}

CreateThread(function()
    for _, interior in ipairs(interiors) do
        RequestIpl(interior.ipl)
        
        local interiorID = GetInteriorAtCoords(interior.coords.x, interior.coords.y, interior.coords.z)
        
        if IsValidInterior(interiorID) then
            for __, entitySet in ipairs(interior.entitySets) do
                local shouldEnable = false
                
                -- Logique d'activation selon la catégorie
                if entitySet.category == 'required' then
                    shouldEnable = true
                elseif entitySet.category == 'furniture' then
                    shouldEnable = interior.furnished
                else
                    shouldEnable = true
                end
                
                if shouldEnable then
                    EnableInteriorProp(interiorID, entitySet.name)
                    if entitySet.color then
                        SetInteriorPropColor(interiorID, entitySet.name, entitySet.color)
                    end
                else
                    DisableInteriorProp(interiorID, entitySet.name)
                end
            end
            
            RefreshInterior(interiorID)
        end
        
        if interior.doors then
            for __, door in ipairs(interior.doors) do
                local doorHash = type(door.doorHash) == "string" and GetHashKey(door.doorHash) or door.doorHash
                local doorCoords = door.doorCoords
                
                AddDoorToSystem(doorHash, doorHash, doorCoords.x, doorCoords.y, doorCoords.z, false, false, false)
                
                if door.locked then
                    DoorSystemSetDoorState(doorHash, 1, false, false)
                else
                    DoorSystemSetDoorState(doorHash, 0, false, false)
                end
            end
        end
    end
end)
