local interiors = {
    {
        ipl = 'int_gn_necromance_wh_milo_',
        coords = { x = -301.346619, y = 6179.04248, z = 34.58590 },
        entitySets = {
            { name = 'gn_necro_wh_empty', enable = false }, --Empty warehouse (useful for creating your own setups in-game)
            { name = 'gn_necro_wh_meth', enable = false }, --Meth lab setup
            { name = 'gn_necro_wh_weed', enable = false }, --Weed base setup
            { name = 'gn_necro_wh_dry', enable = false }, --Added drying weed props (requires gn_necro_wh_weed to be active)
            { name = 'gn_necro_wh_stage', enable = false }, --Added plantings in soil containers (requires gn_necro_wh_weed to be active)
            { name = 'gn_necro_wh_poaching', enable = true } --Poaching setup
        }
    }
}

CreateThread(function()
    for _, interior in ipairs(interiors) do
        RequestIpl(interior.ipl)
        local interiorID = GetInteriorAtCoords(interior.coords.x, interior.coords.y, interior.coords.z)
        if IsValidInterior(interiorID) then
            for __, entitySet in ipairs(interior.entitySets) do
                if entitySet.enable then
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
    end
end)