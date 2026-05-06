------------------------------------------------------------------
-- TARGETS FUNCTIONS, YOU CAN CONNECT YOUR OWN SYSTEM TO THIS ----
------------------------------------------------------------------


function removeTarget(target)
    if Config.Misc.Target == "ox-target" then
        exports.ox_target:removeZone(target)
    elseif Config.Misc.Target == "qb-target" then
        exports['qb-target']:RemoveZone(target)
    elseif Config.Misc.Target == "onex-radialmenu" then
        exports['onex-radialmenu']:onexRemoveRadialItem(target.parent, target.id)
    end
end

function addTargetTyped(name, coords, size, icon, label, onselect)
    if Config.Misc.Target == "ox-target" then
        return exports.ox_target:addBoxZone({
            name = name,
            coords = coords,
            size = size,
            options = {
                {
                    icon = icon,
                    label = label,
                    onSelect = function() onselect() end
                }
            }
        })
    elseif Config.Misc.Target == "qb-target" then
        exports['qb-target']:AddCircleZone(name, coords, size.x, {name = name, debugPoly = false, useZ = true}, {
            options = {
                {icon = icon, label = label, action = function()
                    onselect()
                end}
            },
            distance = size.x
        })
        return name
    elseif Config.Misc.Target == "onex-radialmenu" then
        exports['onex-radialmenu']:onexRadialItemAdd({
            title = label,
            closeRadialMenu = false,
            icon = {
                address = icon,
                width = "24px",
                height = "24px"
            },
            type = "nested",
            trigger = {
                onSelect = function()
                    onselect()
                end
            }
        }, name, 'main_menu')
        return {id = name, parent = "main_menu"}
    end
end