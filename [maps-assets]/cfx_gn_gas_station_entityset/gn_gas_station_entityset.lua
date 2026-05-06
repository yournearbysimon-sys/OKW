local interiors = {
    {
        -- Route 38 location
        ipl = 'int_gn_gas_route68_milo',
        coords = { x = 49.05748, y = 2795.029, z = 58.6707344 },
        entitySets = {
            { name = 'entityset_xer', enable = false, additionalIPL = 'gn_gas_xero_strm_0' },     --Xero gas station
            { name = 'entityset_gb',  enable = true,  additionalIPL = 'gn_gas_globeoil_strm_0' }, --Globe Oil gas station
            { name = 'entityset_abn', enable = false },                                           --Abandoned gas station (no additional IPL)
        }
    }
}

CreateThread(function()
    for _, interior in ipairs(interiors) do
        RequestIpl(interior.ipl)
        -- First, remove all additional IPLs to avoid conflicts
        for __, entitySet in ipairs(interior.entitySets) do
            if entitySet.additionalIPL then
                RemoveIpl(entitySet.additionalIPL)
            end
        end
        local interiorID = GetInteriorAtCoords(interior.coords.x, interior.coords.y, interior.coords.z)
        if IsValidInterior(interiorID) then
            for __, entitySet in ipairs(interior.entitySets) do
                if entitySet.enable then
                    EnableInteriorProp(interiorID, entitySet.name)
                    if entitySet.color then
                        SetInteriorPropColor(interiorID, entitySet.name, entitySet.color)
                    end
                    -- Request additional IPL if specified
                    if entitySet.additionalIPL then
                        RequestIpl(entitySet.additionalIPL)
                    end
                else
                    DisableInteriorProp(interiorID, entitySet.name)
                end
            end
            RefreshInterior(interiorID)
        end
    end
end)