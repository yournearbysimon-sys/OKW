for labName, lab in pairs(Config.Superlabs) do
    if labName == 'Underground' then
        lab.WithAccess = false
    else
        lab.WithAccess = true
    end
end

local requestIpl = function(name)
    RequestIpl(name)
    while not IsIplActive(name) do
        Wait(0)
    end
end

local function InitializeSuperlabs()
    for name, lab in pairs(Config.Superlabs) do
        local interiorID = GetInteriorAtCoords(lab.pos[1], lab.pos[2], lab.pos[3])
        
        if lab.Enabled then
            requestIpl(lab.ipl)

            if lab.WithAccess then
                DeactivateInteriorEntitySet(interiorID, lab.EntitySet.Off)
                ActivateInteriorEntitySet(interiorID, lab.EntitySet.On)
            else
                DeactivateInteriorEntitySet(interiorID, lab.EntitySet.On)
                ActivateInteriorEntitySet(interiorID, lab.EntitySet.Off)
            end

            if lab.Laundry then
                local laundryInteriorID = GetInteriorAtCoords(lab.Laundry.pos[1], lab.Laundry.pos[2], lab.Laundry.pos[3])
    
                if lab.WithAccess then
                    DeactivateInteriorEntitySet(laundryInteriorID, lab.Laundry.EntitySet.Off)
                    ActivateInteriorEntitySet(laundryInteriorID, lab.Laundry.EntitySet.On)
                else
                    DeactivateInteriorEntitySet(laundryInteriorID, lab.Laundry.EntitySet.On)
                    ActivateInteriorEntitySet(laundryInteriorID, lab.Laundry.EntitySet.Off)
                end

                RefreshInterior(laundryInteriorID)

            end

            RefreshInterior(interiorID)

        else

            RemoveIpl(lab.ipl)

            if lab.Laundry then
                local laundryInteriorID = GetInteriorAtCoords(lab.Laundry.pos[1], lab.Laundry.pos[2], lab.Laundry.pos[3])
    
                DeactivateInteriorEntitySet(laundryInteriorID, lab.Laundry.EntitySet.On)
                ActivateInteriorEntitySet(laundryInteriorID, lab.Laundry.EntitySet.Off)

                RefreshInterior(laundryInteriorID)

            end

        end

    end
end

CreateThread(InitializeSuperlabs)
