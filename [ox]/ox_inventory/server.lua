if not lib then return end

require 'modules.bridge.server'
require 'modules.crafting.server'
require 'modules.placeable_stashes.server'
require 'modules.shops.server'
require 'modules.pefcl.server'

if GetConvar('inventory:versioncheck', 'true') == 'true' then
    lib.versionCheck('overextended/ox_inventory')
end

local TriggerEventHooks = require 'modules.hooks.server'
local db = require 'modules.mysql.server'
local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

---@param player table
---@param data table?
--- player requires source, identifier, and name
--- optionally, it should contain jobs/groups, sex, and dateofbirth
function server.setPlayerInventory(player, data)
    while not shared.ready do Wait(0) end

    if not data then
        data = db.loadPlayer(player.identifier)
    end

    local inventory = {}
    local totalWeight = 0

    if type(data) == 'table' then
        local ostime = os.time()

        for _, v in pairs(data) do
            if type(v) == 'number' or not v.count or not v.slot then
                if server.convertInventory then
                    inventory, totalWeight = server.convertInventory(player.source, data)
                    break
                else
                    return error(('Inventory for player.%s (%s) contains invalid data. Ensure you have converted inventories to the correct format.')
                    :format(player.source, GetPlayerName(player.source)))
                end
            else
                local item = Items(v.name)

                if item then
                    v.metadata = Items.CheckMetadata(v.metadata or {}, item, v.name, ostime)
                    local weight = Inventory.SlotWeight(item, v)
                    totalWeight = totalWeight + weight

                    inventory[v.slot] = { name = item.name, label = item.label, weight = weight, slot = v.slot, count = v
                    .count, description = item.description, metadata = v.metadata, stack = item.stack, close = item
                    .close }
                end
            end
        end
    end

    player.source = tonumber(player.source)
    local inv = Inventory.Create(player.source, player.name, 'player', shared.playerslots, totalWeight,
        shared.playerweight, player.identifier, inventory)

    if inv then
        inv.player = server.setPlayerData(player)
        inv.player.ped = GetPlayerPed(player.source)

        if server.syncInventory then server.syncInventory(inv) end
        TriggerClientEvent('ox_inventory:setPlayerInventory', player.source, Inventory.Drops, inventory, totalWeight,
            inv.player)
    end
end

exports('setPlayerInventory', server.setPlayerInventory)
AddEventHandler('ox_inventory:setPlayerInventory', server.setPlayerInventory)

local registeredDumpsters = {}

---@param coords vector3
---@return string?
local function getDumpsterFromCoords(coords)
    local found

    for i = 1, #registeredDumpsters do
        local distance = #(coords - registeredDumpsters[i])

        if distance < 0.1 then
            found = i
            break
        end
    end

    return found
end

---@param playerPed number
---@param stash OxInventory
---@return vector3?
local function getClosestStashCoords(playerPed, stash)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = stash.distance or 10
    local coordinates = stash.coords

    if not coordinates then return end

    if type(coordinates) == 'table' then
        for i = 1, #coordinates do
            local coords = coordinates[i] --[[@as vector3]]

            if #(coords - playerCoords) < distance then
                return coords
            end
        end

        return
    end

    return #(coordinates - playerCoords) < distance and coordinates or nil
end

local utilityConfig = lib.load('data.utility') or {}

local function normalizeItemFilterSet(items)
	if type(items) ~= 'table' then return nil end

	local normalized = {}
	local itemType = table.type(items)

	if itemType == 'array' then
		for i = 1, #items do
			local itemName = items[i]

			if type(itemName) == 'string' and itemName ~= '' then
				normalized[itemName:lower()] = true
			end
		end
	else
		for itemName, allowed in pairs(items) do
			if allowed and type(itemName) == 'string' and itemName ~= '' then
				normalized[itemName:lower()] = true
			end
		end
	end

	return next(normalized) and normalized or nil
end

local function itemAllowedByFilters(itemName, whitelist, blacklist)
	if type(itemName) ~= 'string' then
		return true
	end

	itemName = itemName:lower()

	if whitelist and not whitelist[itemName] then
		return false
	end

	if blacklist and blacklist[itemName] then
		return false
	end

	return true
end

local function getIncomingInventoryItemName(payload, inventoryId)
	if not payload or not inventoryId or payload.fromInventory == payload.toInventory then return end

	inventoryId = tostring(inventoryId)

	if payload.toInventory and tostring(payload.toInventory) == inventoryId then
		return type(payload.fromSlot) == 'table' and payload.fromSlot.name or nil
	end

	if payload.action == 'swap' and payload.fromInventory and tostring(payload.fromInventory) == inventoryId then
		return type(payload.toSlot) == 'table' and payload.toSlot.name or nil
	end
end

if utilityConfig.backpackItems then
	for name, props in pairs(utilityConfig.backpackItems) do
		props.blacklistLookup = normalizeItemFilterSet(props.blacklist)
		props.whitelistLookup = normalizeItemFilterSet(props.whitelist)

		Items.containers.setContainerProperties(name, {
			slots = props.slots,
			maxWeight = props.maxWeight or props.weight,
			blacklist = props.blacklistLookup,
			whitelist = props.whitelistLookup,
		})
	end
end

local function getBackpackSlotId()
	local backpackSlotId = utilityConfig.backpackSlotFallback or 6

	if utilityConfig.items then
		for i, items in pairs(utilityConfig.items) do
			for _, itemName in ipairs(items) do
				if utilityConfig.backpackItems and utilityConfig.backpackItems[itemName] then
					backpackSlotId = i
					break
				end
			end
		end
	end

	return backpackSlotId
end

local function getBackpackProperties(itemName)
	return utilityConfig.backpackItems and utilityConfig.backpackItems[itemName]
end

local function getBackpackContainerSize(itemName, metadata)
	local props = getBackpackProperties(itemName)

	if metadata and metadata.size and metadata.size[1] and metadata.size[2] then
		return metadata.size[1], metadata.size[2], props
	end

	return props and props.slots, props and (props.weight or props.maxWeight), props
end

local function buildBackpackMetadata(itemName, metadata)
	local slots, weight = getBackpackContainerSize(itemName, metadata)

	if not slots or not weight then
		return metadata, nil
	end

	metadata.container = metadata.container or (string.upper(lib.string.random(math.max(1, tonumber(utilityConfig.backpackIdPrefixLength) or 3))) .. os.time())

	if utilityConfig.persistBackpackSizeMetadata ~= false or not metadata.size then
		metadata.size = { slots, weight }
	end

	return metadata, { slots = slots, weight = weight }
end

---@param owner OxInventory
---@return OxInventory?
local function resolveBackpackInventory(owner)
	if not owner or not utilityConfig.backpackItems then return end

	local backpackSlotId = getBackpackSlotId()
	local item = owner.items[backpackSlotId]

	if item and getBackpackProperties(item.name) then
		if not item.metadata or type(item.metadata) ~= 'table' or not item.metadata.container then
			local metadata = item.metadata and parseJson(json.encode(item.metadata)) or {}
			local props

			metadata, props = buildBackpackMetadata(item.name, metadata)
			item = Inventory.SetSlot(owner, item, item.count, metadata, backpackSlotId)
		end

		local backpack = Inventory(item.metadata.container)

		if not backpack then
			local slots, weight, props = getBackpackContainerSize(item.name, item.metadata)

			if props and slots and weight then
				backpack = Inventory.Create(item.metadata.container, item.label, 'container', slots, 0, weight, false)
			end
		end

		return backpack
	end
end

---@param backpack OxInventory?
---@return table | false
local function backpackToData(backpack)
	if not backpack then return false end

	return {
		id = backpack.id,
		label = backpack.label,
		type = 'backpack',
		slots = backpack.slots,
		weight = backpack.weight,
		maxWeight = backpack.maxWeight,
		items = backpack.items
	}
end

local function resolveBackpackContext(ownerInventory, backpackInventoryId)
	if not ownerInventory or not utilityConfig.backpackItems then return end

	local backpackSlotId = getBackpackSlotId()
	local item = ownerInventory.items[backpackSlotId]

	if not item or not item.name or not item.metadata or not item.metadata.container then
		return
	end

	local props = utilityConfig.backpackItems[item.name]

	if not props then
		return
	end

	if backpackInventoryId and item.metadata.container ~= backpackInventoryId then
		return
	end

	return ownerInventory, item, props
end

local function resolveAccessibleBackpackContext(source, backpackInventoryId)
	if not backpackInventoryId then return end

	local playerInventory = Inventory(source)
	if not playerInventory then return end

	local ownerInventory, backpackItem, backpackConfig = resolveBackpackContext(playerInventory, backpackInventoryId)

	if ownerInventory then
		return ownerInventory, backpackItem, backpackConfig
	end

	local openedInventory = playerInventory.open and Inventory(playerInventory.open)

	if openedInventory and openedInventory.player and openedInventory ~= playerInventory then
		return resolveBackpackContext(openedInventory, backpackInventoryId)
	end
end

local function notifyBlockedStorage(source, itemName, containerLabel)
	local item = Items(itemName)

	lib.notify(source, {
		type = 'error',
		description = ('%s cannot be stored in %s.'):format(item and item.label or itemName, containerLabel or 'this container'),
	})
end

---@param source number
---@param invType string
---@param data? string|number|table
---@param ignoreSecurityChecks boolean?
---@return table | false | nil, table | false | nil, table?, string?
local function openInventory(source, invType, data, ignoreSecurityChecks)
	if Inventory.Lock then return false end

	local left = Inventory(source)
	local right, closestCoords, ownerBackpack, targetBackpack

    if not left then return end

    left:closeInventory(true)
    Inventory.CloseAll(left, source)

    if left then
        ownerBackpack = resolveBackpackInventory(left)
    end

    if invType == 'player' and data == source then
        data = nil
    end

    local playerPed = left.player.ped

    if data then
        local isDataTable = type(data) == 'table'

        if invType == 'stash' then
            right = Inventory(data, left, ignoreSecurityChecks)
            if right == false then return false end
        elseif isDataTable then
            if data.netid then
                local entity = NetworkGetEntityFromNetworkId(data.netid)

                if not entity then return end

                if not ignoreSecurityChecks then
                    if #(GetEntityCoords(playerPed) - GetEntityCoords(entity)) > 16 then return end
                end

                if invType == 'glovebox' then
                    if not ignoreSecurityChecks and GetVehiclePedIsIn(playerPed, false) ~= entity then
                        return
                    end
                end

                if invType == 'trunk' then
                    local lockStatus = ignoreSecurityChecks and 0 or GetVehicleDoorLockStatus(entity)

                    -- 0: no lock; 1: unlocked; 8: boot unlocked
                    if lockStatus > 1 and lockStatus ~= 8 then
                        return false, false, 'vehicle_locked'
                    end
                end

                local plate = (invType == 'glovebox' or invType == 'trunk') and GetVehicleNumberPlateText(entity)

                if plate then
                    if server.trimplate then plate = string.strtrim(plate) end

                    if not data.id then
                        data.id = (invType == 'glovebox' and 'glove' or 'trunk') .. plate
                    end
                end

                data.type = invType
                right = Inventory(data)

                if right and data.netid ~= right.netid then
                    local invEntity = NetworkGetEntityFromNetworkId(right.netid)

                    if not (invEntity > 0 and DoesEntityExist(invEntity)) or (plate and not string.match(GetVehicleNumberPlateText(invEntity) or '', plate)) then
                        Inventory.Remove(right)
                        right = Inventory(data)
                    end
                end
            elseif invType == 'drop' then
                right = Inventory(data.id)
            else
                return
            end
        elseif invType == 'policeevidence' then
            if ignoreSecurityChecks or server.hasGroup(left, shared.police) then
                right = Inventory(('evidence-%s'):format(data))
            end
        elseif invType == 'dumpster' then
            if shared.networkdumpsters then
                local dumpsterId = getDumpsterFromCoords(data)
                right = dumpsterId and Inventory(('dumpster-%s'):format(dumpsterId))

                if not right then
                    dumpsterId = #registeredDumpsters + 1
                    right = Inventory.Create(('dumpster-%s'):format(dumpsterId), locale('dumpster'), invType, 15, 0, 100000, false)
                    registeredDumpsters[dumpsterId] = data
                end
            else
                ---@cast data string
                right = Inventory(data)

                if not right then
                    local netid = tonumber(data:sub(9))
                    if netid and NetworkGetEntityFromNetworkId(netid) > 0 then
                        right = Inventory.Create(data, locale('dumpster'), invType, 15, 0, 100000, false)
                    end
                end
            end
        elseif invType == 'container' then
			left.containerSlot = data --[[@as number]]
			data = left.items[data]

			if data then
				if not data.metadata or not data.metadata.container then
					if getBackpackProperties(data.name) then
						local metadata = data.metadata and parseJson(json.encode(data.metadata)) or {}
						metadata = buildBackpackMetadata(data.name, metadata)
						data = Inventory.SetSlot(left, data, data.count, metadata, left.containerSlot)
					end
				end

				right = Inventory(data.metadata.container)

				if not right then
					local slots, weight = getBackpackContainerSize(data.name, data.metadata)

					if not slots or not weight then return end
					right = Inventory.Create(data.metadata.container, data.label, invType, slots, 0, weight, false)
				end
			else left.containerSlot = nil end
        else right = Inventory(data) end

        if not right then return end

        if right.type ~= invType and not (right.type == 'temp' and invType == 'stash') then
            DropPlayer(source, 'sussy')
            return
        end

        if not ignoreSecurityChecks and right.groups and not server.hasGroup(left, right.groups) then return end

        local hookPayload = {
            source = source,
            inventoryId = right.id,
            inventoryType = right.type,
        }

        if invType == 'container' then hookPayload.slot = left.containerSlot end
        if isDataTable and data.netid then hookPayload.netId = data.netid end

        if not TriggerEventHooks('openInventory', hookPayload) then return end

        if left == right then return end

        if right.player then
            if right.open then return end

            right.coords = not ignoreSecurityChecks and GetEntityCoords(right.player.ped) or nil
            targetBackpack = resolveBackpackInventory(right)
        end

        if not ignoreSecurityChecks and right.coords then
            closestCoords = getClosestStashCoords(playerPed, right)

            if not closestCoords then return end
        end

        left:openInventory(right)
    else
        left:openInventory(left)
    end

	local placeableStashContext = right
		and right.type == 'stash'
		and server.getPlaceableStashInventoryContext
		and server.getPlaceableStashInventoryContext(source, right.id)

	return {
		id = left.id,
		label = left.label,
		type = left.type,
		slots = left.slots,
		weight = left.weight,
		maxWeight = left.maxWeight
	}, right and {
		id = right.id,
		label = right.player and (right.player.name or right.label) or right.label,
		type = right.player and 'otherplayer' or right.type,
		slots = right.slots,
		weight = right.weight,
		maxWeight = right.maxWeight,
		items = right.items,
		coords = closestCoords or right.coords,
		distance = right.distance,
		permissions = placeableStashContext and placeableStashContext.permissions or nil,
	}, {
		backpackInventory = backpackToData(ownerBackpack),
		targetBackpackInventory = backpackToData(targetBackpack)
	}
end

---@param source number
---@param invType string
---@param data string|number|table
lib.callback.register('ox_inventory:openInventory', function(source, invType, data)
    if invType == 'player' and source ~= data then
        local serverId = type(data) == 'table' and data.id or data

        if source == serverId or type(serverId) ~= 'number' then return end

        local left = Inventory(source)
        if not left then return end

        local isPolice = server.hasGroup(left, shared.police)
        local isTargetStealable = Player(serverId).state.canSteal

        if not isPolice and not isTargetStealable then return end
    end

    return openInventory(source, invType, data)
end)

lib.callback.register('ox_inventory:getBackpack', function(source, target)
	local left = Inventory(source)
    if not left then return end

    local owner = left

    if target and target ~= source then
        local openInventoryId = left.open

        if not openInventoryId then return end

        owner = Inventory(target)

        if not owner or not owner.player or owner.id ~= openInventoryId then
            return
        end
    end

    return backpackToData(resolveBackpackInventory(owner))
end)

---@param netId number
lib.callback.register('ox_inventory:isVehicleATrailer', function(source, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local retval = GetVehicleType(entity)
    return retval == 'trailer'
end)

---@param playerId number
---@param invType string
---@param data string|number|table
function server.forceOpenInventory(playerId, invType, data)
	local left, right, backpacks = openInventory(playerId, invType, data, true)

	if left and right then
		TriggerClientEvent('ox_inventory:forceOpenInventory', playerId, left, right, backpacks)
		return right.id
	end
end

exports('forceOpenInventory', server.forceOpenInventory)

local Licenses = lib.load('data.licenses')

lib.callback.register('ox_inventory:buyLicense', function(source, id)
    local license = Licenses[id]
    if not license then return end

    local inventory = Inventory(source)
    if not inventory then return end

    return server.buyLicense(inventory, license)
end)

lib.callback.register('ox_inventory:getItemCount', function(source, item, metadata, target)
    local inventory = target and Inventory(target) or Inventory(source)
    return (inventory and Inventory.GetItemCount(inventory, item, metadata, true))
end)

lib.callback.register('ox_inventory:getInventory', function(source, id)
    local inventory = Inventory(id or source)
    return inventory and {
        id = inventory.id,
        label = inventory.label,
        type = inventory.type,
        slots = inventory.slots,
        weight = inventory.weight,
        maxWeight = inventory.maxWeight,
        owned = inventory.owner and true or false,
        items = inventory.items
    }
end)

RegisterNetEvent('ox_inventory:usedItemInternal', function(slot, inventoryId)
    local playerInventory = Inventory(source)
    if not playerInventory then return end

    local item = playerInventory.usingItem
    if not item or item.slot ~= slot then
        return
    end

    local targetInventory = inventoryId and Inventory(inventoryId) or playerInventory
    
    TriggerEvent('ox_inventory:usedItem', targetInventory.id, item.name, item.slot, next(item.metadata) and item.metadata, source)

    playerInventory.usingItem = nil
end)

---@param source number
---@param itemName string
---@param slot number?
---@param metadata { [string]: any }?
---@return table | boolean | nil
lib.callback.register('ox_inventory:useItem', function(source, itemName, slot, metadata, noAnim, inventoryId)
	local playerInventory = Inventory(source) --[[@as OxInventory]]
    local inventory = inventoryId and Inventory(inventoryId) or playerInventory

	if playerInventory and inventory and playerInventory.player then
		local item = Items(itemName)
		local data = item and (slot and inventory.items[slot] or Inventory.GetSlotWithItem(inventory, item.name, metadata, true))

        if not data then return end

        slot = data.slot
        local durability = data.metadata.durability --[[@as number|boolean|nil]]
        local consume = item.consume
        local label = data.metadata.label or item.label

        if durability and consume then
            if durability > 100 then
                local ostime = os.time()

                if ostime > durability then
                    Items.UpdateDurability(inventory, data, item, 0)
                    return TriggerClientEvent('ox_lib:notify', source,
                        { type = 'error', description = locale('no_durability', label) })
                elseif consume ~= 0 and consume < 1 then
                    local degrade = (data.metadata.degrade or item.degrade) * 60
                    local percentage = ((durability - ostime) * 100) / degrade

                    if percentage < consume * 100 then
                        return TriggerClientEvent('ox_lib:notify', source,
                            { type = 'error', description = locale('not_enough_durability', label) })
                    end
                end
            elseif durability <= 0 then
                return TriggerClientEvent('ox_lib:notify', source,
                    { type = 'error', description = locale('no_durability', label) })
            elseif consume ~= 0 and consume < 1 and durability < consume * 100 then
                return TriggerClientEvent('ox_lib:notify', source,
                    { type = 'error', description = locale('not_enough_durability', label) })
            end

            if data.count > 1 and consume < 1 and consume > 0 and not Inventory.GetEmptySlot(inventory) then
                return TriggerClientEvent('ox_lib:notify', source,
                    { type = 'error', description = locale('cannot_use', label) })
            end
        end

        if item and data and data.count > 0 and data.name == item.name then
            data = { name = data.name, label = label, count = data.count, slot = slot, metadata = data.metadata, weight =
            data.weight }

			if item.ammo then
				if playerInventory.weapon then
					local weapon = playerInventory.items[playerInventory.weapon]

                    if weapon and weapon?.metadata.durability > 0 then
                        consume = nil
                    end
                else
                    return false
                end
            elseif item.component or item.tint then
                consume = 1
                data.component = true
            elseif consume then
                if data.count >= consume then
                    local result = item.cb and item.cb('usingItem', item, inventory, slot)

                    if result == false then return end

					if result ~= nil then
						data.server = result
					end
				else
					return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('item_not_enough', item.name) })
				end
			elseif not item.weapon and server.UseItem then


                playerInventory.usingItem = data
				-- This is used to call an external useItem function, i.e. ESX.UseItem
				-- If an error is being thrown on item use there is no internal solution. We previously kept a list
				-- of usable items which led to issues when restarting resources (for obvious reasons), but config
				-- developers complained the inventory broke their items. Safely invoking registered item callbacks
				-- should resolve issues, i.e. https://github.com/esx-framework/esx-legacy/commit/9fc382bbe0f5b96ff102dace73c424a53458c96e
				local status, result = pcall(server.UseItem, source, data.name, data)
				return status, result
			end

            data.consume = consume

            if not TriggerEventHooks('usingItem', {
                    source = source,
                    inventoryId = inventory and inventory.id,
                    item = inventory.items[slot],
                    consume = consume
                }) then
                return false
            end

            ---@type boolean
            local success = lib.callback.await('ox_inventory:usingItem', source, data, noAnim)

			if item.weapon then
				playerInventory.weapon = success and slot or nil
			end

            if not success then return end

            playerInventory.usingItem = data

            if consume and consume ~= 0 and not data.component then
                data = inventory.items[data.slot]

                if not data then return end

                durability = consume ~= 0 and consume < 1 and data.metadata.durability --[[@as number | false]]

                if durability then
                    if durability > 100 then
                        local degrade = (data.metadata.degrade or item.degrade) * 60
                        durability -= degrade * consume
                    else
                        durability -= consume * 100
                    end

                    if data.count > 1 then
                        local emptySlot = Inventory.GetEmptySlot(inventory)

                        if emptySlot then
                            local newItem = Inventory.SetSlot(inventory, item, 1, table.deepclone(data.metadata),
                                emptySlot)

                            if newItem then
                                Items.UpdateDurability(inventory, newItem, item, durability)
                            end
                        end

                        durability = 0
                    else
                        Items.UpdateDurability(inventory, data, item, durability)
                    end

                    if durability <= 0 then
                        durability = false
                    end
                end

                if not durability then
                    Inventory.RemoveItem(inventory.id, data.name, consume < 1 and 1 or consume, nil, data.slot)
                else
                    inventory.changed = true

                    if server.syncInventory then server.syncInventory(inventory) end
                end

                if item?.cb then
                    item.cb('usedItem', item, inventory, data.slot)
                end
            end

            return true
        end
    end
end)

local function conversionScript()
    shared.ready = false

    local file = 'setup/convert.lua'
    local import = LoadResourceFile(shared.resource, file)
    local func = load(import, ('@@%s/%s'):format(shared.resource, file)) --[[@as function]]

    conversionScript = func()
end

RegisterCommand('convertinventory', function(source, args)
    if source ~= 0 then return warn('This command can only be executed with the server console.') end
    if type(conversionScript) == 'function' then conversionScript() end
    local arg = args[1]

    local convert = arg and conversionScript[arg]

    if not convert then
        return warn('Invalid conversion argument. Valid options: esx, esxproperty')
    end

    CreateThread(convert)
end, true)


lib.addCommand({ 'additem', 'giveitem' }, {
    help = 'Gives an item to a player with the given id',
    params = {
        { name = 'target', type = 'playerId',                              help = 'The player to receive the item' },
        { name = 'item',   type = 'string',                                help = 'The name of the item' },
        { name = 'count',  type = 'number',                                help = 'The amount of the item to give', optional = true },
        { name = 'type',   help = 'Sets the "type" metadata to the value', optional = true },
    },
    restricted = 'group.admin',
}, function(source, args)
    local item = Items(args.item)

    if item then
        local inventory = Inventory(args.target) --[[@as OxInventory]]
        local count = args.count and math.max(args.count, 1) or 1

        local success, response = Inventory.AddItem(inventory, item.name, count,
            args.type and { type = tonumber(args.type) or args.type })

        if not success then
            return Citizen.Trace(('Failed to give %sx %s to player %s (%s)'):format(count, item.name, args.target,
                response))
        end

        source = Inventory(source) or { label = 'console', owner = 'console' }

        if server.loglevel > 0 then
            lib.logger(source.owner, 'admin',
                ('"%s" gave %sx %s to "%s"'):format(source.label, count, item.name, inventory.label))
        end
    end
end)

lib.addCommand('removeitem', {
    help = 'Removes an item to a player with the given id',
    params = {
        { name = 'target', type = 'playerId',                                          help = 'The player to remove the item from' },
        { name = 'item',   type = 'string',                                            help = 'The name of the item' },
        { name = 'count',  type = 'number',                                            help = 'The amount of the item to take',    optional = true },
        { name = 'type',   help = 'Only remove items with a matching metadata "type"', optional = true },
    },
    restricted = 'group.admin',
}, function(source, args)
    local item = Items(args.item)

    if item then
        local inventory = Inventory(args.target) --[[@as OxInventory]]
        local count = args.count and math.max(args.count, 1) or 1

        local success, response = Inventory.RemoveItem(inventory, item.name, count,
            args.type and { type = tonumber(args.type) or args.type }, nil, true)

        if not success then
            return Citizen.Trace(('Failed to remove %sx %s from player %s (%s)'):format(count, item.name, args.target,
                response))
        end

        source = Inventory(source) or { label = 'console', owner = 'console' }

        if server.loglevel > 0 then
            lib.logger(source.owner, 'admin',
                ('"%s" removed %sx %s from "%s"'):format(source.label, count, item.name, inventory.label))
        end
    end
end)

lib.addCommand('setitem', {
    help = 'Sets the item count for a player, removing or adding as needed',
    params = {
        { name = 'target', type = 'playerId',                                     help = 'The player to set the items for' },
        { name = 'item',   type = 'string',                                       help = 'The name of the item' },
        { name = 'count',  type = 'number',                                       help = 'The amount of items to set',     optional = true },
        { name = 'type',   help = 'Add or remove items with the metadata "type"', optional = true },
    },
    restricted = 'group.admin',
}, function(source, args)
    local item = Items(args.item)

    if item then
        local inventory = Inventory(args.target) --[[@as OxInventory]]
        local count = args.count and math.max(args.count, 0) or 0

        local success, response = Inventory.SetItem(inventory, item.name, count or 0,
            args.type and { type = tonumber(args.type) or args.type })

        if not success then
            return Citizen.Trace(('Failed to set %s count to %sx for player %s (%s)'):format(item.name, count,
                args.target, response))
        end

        source = Inventory(source) or { label = 'console', owner = 'console' }

        if server.loglevel > 0 then
            lib.logger(source.owner, 'admin',
                ('"%s" set "%s" %s count to %sx'):format(source.label, inventory.label, item.name, count))
        end
    end
end)

lib.addCommand('clearevidence', {
    help = 'Clears a police evidence locker with the given id',
    params = {
        { name = 'locker', type = 'number', help = 'The locker id to clear' },
    },
}, function(source, args)
    if not server.isPlayerBoss then return end

    local inventory = Inventory(source)
    if not inventory then return end

    local group, grade = server.hasGroup(inventory, shared.police)
    local hasPermission = group and server.isPlayerBoss(source, group, grade)

    if hasPermission then
        MySQL.query('DELETE FROM ox_inventory WHERE name = ?', { ('evidence-%s'):format(args.locker) })
    end
end)

lib.addCommand('takeinv', {
    help = 'Confiscates the target inventory, to restore with /restoreinv',
    params = {
        { name = 'target', type = 'playerId', help = 'The player to confiscate items from' },
    },
    restricted = 'group.admin',
}, function(source, args)
    Inventory.Confiscate(args.target)
end)

lib.addCommand({ 'restoreinv', 'returninv' }, {
    help = 'Restores a previously confiscated inventory for the target',
    params = {
        { name = 'target', type = 'playerId', help = 'The player to restore items to' },
    },
    restricted = 'group.admin',
}, function(source, args)
    Inventory.Return(args.target)
end)

lib.addCommand('clearinv', {
    help = 'Wipes all items from the target inventory',
    params = {
        { name = 'invId', help = 'The inventory to wipe items from' },
    },
    restricted = 'group.admin',
}, function(source, args)
    Inventory.Clear(tonumber(args.invId) or args.invId == 'me' and source or args.invId)
end)

lib.addCommand('saveinv', {
    help = 'Save all pending inventory changes to the database',
    params = {
        { name = 'lock', help = 'Lock inventory access, until restart or saved without a lock', optional = true },
    },
    restricted = 'group.admin',
}, function(source, args)
    Inventory.SaveInventories(args.lock == 'true', false)
end)

lib.addCommand('viewinv', {
    help = 'Inspect the target inventory without allowing interactions',
    params = {
        { name = 'invId', help = 'The inventory to inspect' },
    },
    restricted = 'group.admin',
}, function(source, args)
    Inventory.InspectInventory(source, tonumber(args.invId) or args.invId)
end)



--- DROP CUSTOM PROP
local resourceName = GetCurrentResourceName()

local dropItems = (function()
	local Items = exports[resourceName]:Items()

	local items = {}

	for itemName, item in pairs(Items) do
		if item.prop then
			items[itemName] = item.prop
		end
	end

	return items
end)()

exports[resourceName]:registerHook('swapItems', function(payload)
	local item = payload.fromSlot

    if payload.toInventory ~= 'newdrop' or not dropItems[item.name] then return end

    local items = { { item.name, payload.count, item.metadata } }
    local dropId = exports[resourceName]:CustomDrop(item.label, items,
        GetEntityCoords(GetPlayerPed(payload.source)), 25, 30000, nil, dropItems[item.name])

    if not dropId then return end

    CreateThread(function()
        exports[resourceName]:RemoveItem(payload.source, item.name, payload.count, nil, item.slot)
        Wait(0)
        exports[resourceName]:forceOpenInventory(payload.source, 'drop', dropId)
    end)

    return false
end, {
    itemFilter = dropItems,
    typeFilter = { player = true }
})





local weaponHotbar = GetConvarInt('inventory:weaponslots', 1) == 1

local function getConfiguredUtilitySlotIds()
	local slotIds = {}

	if type(utilityConfig.slotIds) == 'table' and next(utilityConfig.slotIds) ~= nil then
		for i = 1, #utilityConfig.slotIds do
			local slotId = tonumber(utilityConfig.slotIds[i])
			if slotId and slotId > 0 then
				slotIds[#slotIds + 1] = slotId
			end
		end
	elseif type(utilityConfig.items) == 'table' then
		for slotId in pairs(utilityConfig.items) do
			slotId = tonumber(slotId)
			if slotId and slotId > 0 then
				slotIds[#slotIds + 1] = slotId
			end
		end
	end

	table.sort(slotIds)

	return slotIds
end

local utilitySlotIds = getConfiguredUtilitySlotIds()
local utilitySlotLookup = {}
local highestUtilitySlot = 0

for i = 1, #utilitySlotIds do
	local slotId = utilitySlotIds[i]
	utilitySlotLookup[slotId] = true

	if slotId > highestUtilitySlot then
		highestUtilitySlot = slotId
	end
end

local function isUtilitySlot(slot)
	return type(slot) == 'number' and utilitySlotLookup[slot] == true
end

local function slotAllowsItem(slot, name)
	if not name then return true end
	if not isUtilitySlot(slot) then return true end

	local allowed = utilityConfig.items and utilityConfig.items[slot]

	if not allowed or next(allowed) == nil then
		return true
	end

	name = name:lower()

	for i = 1, #allowed do
		if name == allowed[i]:lower() then
			return true
		end
	end

	return false
end

local function matchesConfiguredName(name, entries)
	if not name or type(entries) ~= 'table' then return false end

	name = name:lower()

	for i = 1, #entries do
		if name == entries[i]:lower() then
			return true
		end
	end

	return false
end

local function matchesNamePrefix(name, prefixes)
	if not name or type(prefixes) ~= 'table' then return false end

	name = name:lower()

	for i = 1, #prefixes do
		local prefix = prefixes[i] and prefixes[i]:lower()

		if prefix and prefix ~= '' and name:sub(1, #prefix) == prefix then
			return true
		end
	end

	return false
end

local function isArmorItem(name)
	if not name then return false end
	name = name:lower()

	if utilityConfig.armorItems and utilityConfig.armorItems[name] ~= nil then
		return true
	end

	return matchesNamePrefix(name, utilityConfig.legacyArmorPrefixes)
end

local function isParachuteItem(name)
	if matchesConfiguredName(name, utilityConfig.parachuteItems) then
		return true
	end

	return (not utilityConfig.parachuteItems or next(utilityConfig.parachuteItems) == nil)
		and name
		and name:lower():find('parachute') ~= nil
end

local function findArmourSlot(source)
	local inv = Inventory(source)
	local limit = tonumber(utilityConfig.armorSearchSlotLimit) or highestUtilitySlot or 9

	if inv and inv.items then
		for i = 1, limit do
			local slotItem = inv.items[i]

			if slotItem and isArmorItem(slotItem.name) then
				return i, slotItem
			end
		end
	end

	if utilityConfig.useLegacyArmorSlotFallback ~= false then
		local fallbackSlot = tonumber(utilityConfig.armorSlotFallback) or 7
		local legacy = inv and inv.items and inv.items[fallbackSlot] or exports[shared.resource]:GetSlot(source, fallbackSlot)

		if legacy and isArmorItem(legacy.name) then
			return fallbackSlot, legacy
		end
	end
end

local function getArmorDivider(itemName)
	local vest = Items(itemName)
	local divider = vest and vest.divider
	local config = utilityConfig.armorItems and utilityConfig.armorItems[itemName]

	if not divider and config and config.value then
		divider = 100 / config.value
	end

	if not divider or divider == 0 then
		divider = 1
	end

	return divider, vest, config
end

exports[resourceName]:registerHook('swapItems', function(payload)
	local slot = type(payload.toSlot) == 'number' and payload.toSlot or type(payload.toSlot) == 'table' and payload.toSlot.slot
	local fromSlot = type(payload.fromSlot) == 'number' and payload.fromSlot or type(payload.fromSlot) == 'table' and payload.fromSlot.slot
	if not slot or not fromSlot then return false end

	local ped = GetPlayerPed(payload.source)
	local itemName = payload.fromSlot.name

	if payload.toType ~= 'player' then
		if isArmorItem(itemName) and isUtilitySlot(fromSlot) then
			local divider, vest = getArmorDivider(itemName)
			local armour = GetPedArmour(ped)

			if vest and payload.fromSlot.metadata and payload.fromSlot.metadata.durability then
				SetPedArmour(ped, math.max(0, armour - math.floor(payload.fromSlot.metadata.durability / divider)))
			end
		end

		return true
	end

	if not slotAllowsItem(slot, itemName) then
		return false
	end

	if isArmorItem(itemName) then
		local divider, vest, config = getArmorDivider(itemName)

		if isUtilitySlot(fromSlot) and not isUtilitySlot(slot) then
			local armour = GetPedArmour(ped)

			if vest and payload.fromSlot.metadata and payload.fromSlot.metadata.durability and divider then
				SetPedArmour(ped, math.max(0, armour - math.floor(payload.fromSlot.metadata.durability / divider)))
			end
		end

		if isUtilitySlot(slot) then
			if config and config.jobs and next(config.jobs) then
				local player = Inventory(payload.source)
				local authorized = false

				for k, v in pairs(config.jobs) do
					local job = type(k) == 'string' and k or v

					if server.hasGroup(player, job) then
						authorized = true
						break
					end
				end

				if not authorized then
					return false
				end
			end

			local armour = GetPedArmour(ped)

			if vest and payload.fromSlot.metadata and payload.fromSlot.metadata.durability then
				local addAmount = math.floor(payload.fromSlot.metadata.durability / divider)
				SetPedArmour(ped, math.min(100, armour + addAmount))
			end

			return true
		end
	end

	if utilityConfig.autoUseParachuteOnEquip ~= false and isParachuteItem(itemName) and isUtilitySlot(slot) then
		SetTimeout(50, function()
			TriggerClientEvent('ox_inventory:useSlot', payload.source, slot)
		end)

		return true
	end

	return true
end, {
    typeFilter = { player = true }
})

exports[resourceName]:registerHook('swapItems', function(payload)
	if payload.fromInventory == payload.toInventory then
		return true
	end

	local function validateBackpack(backpackInventoryId)
		if not backpackInventoryId then
			return true
		end

		local incomingItem = getIncomingInventoryItemName(payload, backpackInventoryId)

		if not incomingItem then
			return true
		end

		local _, backpackItem, backpackConfig = resolveAccessibleBackpackContext(payload.source, tostring(backpackInventoryId))

		if not backpackConfig or itemAllowedByFilters(incomingItem, backpackConfig.whitelistLookup, backpackConfig.blacklistLookup) then
			return true
		end

		notifyBlockedStorage(payload.source, incomingItem, backpackItem and backpackItem.label or 'backpack')

		return false
	end

	if payload.toType == 'backpack' and validateBackpack(payload.toInventory) == false then
		return false
	end

	if payload.fromType == 'backpack' and payload.action == 'swap' and validateBackpack(payload.fromInventory) == false then
		return false
	end

	return true
end, {
	print = false
})

RegisterNetEvent('ox_inventory:damageArmour', function()
	local src = source

	local armourSlot, armour = findArmourSlot(src)

	if armour then
		local level = GetPedArmour(GetPlayerPed(src))
		local divider, vest = getArmorDivider(armour.name)

		if vest then
			exports[shared.resource]:SetDurability(src, armourSlot, math.min(100, level * divider))

			if armour.metadata.durability <= 0 then
				exports[shared.resource]:RemoveItem(src, armour.name, 1, nil, armourSlot)
			end
		end
	end
end)

RegisterNetEvent('ox_inventory:repairArmour', function(repairAmount)
	local src = source
    repairAmount = tonumber(repairAmount) or 0

	local armourSlot, armour = findArmourSlot(src)

	if armour then
		local divider, vest = getArmorDivider(armour.name)

		if vest then
			local currentDurability = armour.metadata.durability or 100

			if currentDurability >= 100 then 
                return 
            end

			local newDurability = math.min(100, currentDurability + repairAmount)
            
			exports[shared.resource]:SetDurability(src, armourSlot, newDurability)

            local newPedArmour = math.floor(newDurability / divider)
            local ped = GetPlayerPed(src)

			SetPedArmour(ped, newPedArmour)
		end
	end
end)
