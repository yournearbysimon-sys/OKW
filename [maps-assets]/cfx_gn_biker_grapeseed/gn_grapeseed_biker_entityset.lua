local interiors = {
    {
        ipl = 'gn_biker_barn_grapeseed_milo_',
        coords = { x = 1928.359, y = 4621.976, z = 39.340 },
        entitySets = {
            { name = 'main', enable = true }, --Do not modify
            { name = 'workshop', enable = true }, --Activate the mechanic workshop
            { name = 'biker_a', enable = false }, --Activate the lost legal
            { name = 'gunrunning', enable = true }, --Activate the lost illegal arms dealing
        }
    },
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
