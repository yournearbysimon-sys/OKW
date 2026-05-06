if not lib then return end
lib.locale()

local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

local StashConfig = lib.load('data.placeable_stashes') or {}
local StashTypes = StashConfig.types or {}

local DynamicStashes = {}
local PlacementItems = {}
local PendingPlacement = {}
local PlacedStashes = {}

local function asBool(value)
	return value == true or value == 1 or value == '1'
end

local function localizeDefaultRoleName(name)
	if name == 'Member' then
		return locale('crafting_role_member') or name
	end

	if name == 'Manager' then
		return locale('crafting_role_manager') or name
	end

	return name
end

local function trim(value)
	if type(value) ~= 'string' then return nil end
	local trimmed = value:gsub('^%s+', ''):gsub('%s+$', '')
	return trimmed ~= '' and trimmed or nil
end

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

local function toVector3(value)
	if not value then return nil end
	local valueType = type(value)

	if valueType == 'vector3' then
		return value
	end

	if valueType == 'table' then
		if value.coords then
			return toVector3(value.coords)
		end

		if value.x or value.y or value.z then
			return vec3(value.x or 0.0, value.y or 0.0, value.z or 0.0)
		end

		if value[1] or value[2] or value[3] then
			return vec3(value[1] or 0.0, value[2] or 0.0, value[3] or 0.0)
		end
	end

	return nil
end

local function getDefaultRoleDefinitions()
	return {
		{
			name = locale('crafting_role_member') or 'Member',
			can_use = 1,
			can_move = 0,
			can_pack = 0,
			can_manage = 0,
		},
		{
			name = locale('crafting_role_manager') or 'Manager',
			can_use = 1,
			can_move = 1,
			can_pack = 1,
			can_manage = 1,
		},
	}
end

local function buildPlacedStashId(id)
	return ('placed_stash:%s'):format(id)
end

local function getStashRecord(stashId)
	return PlacedStashes[stashId]
end

local function getPlayerIdentifier(source)
	local inv = Inventory(source)
	if inv and inv.owner then
		return inv.owner
	end

	return ('player:%s'):format(source)
end

local function getOnlineSourceByIdentifier(identifier)
	if not identifier then return nil end

	for _, playerId in ipairs(GetPlayers()) do
		local src = tonumber(playerId)
		if src then
			local inv = Inventory(src)
			if inv and inv.owner == identifier then
				return src
			end
		end
	end
end

local function resolveIdentifier(input)
	if type(input) == 'number' then
		local inv = Inventory(input)
		return inv and inv.owner or nil, input
	end

	if type(input) == 'string' then
		local cleaned = trim(input)
		if not cleaned then return nil end

		if cleaned:match('^%d+$') then
			local src = tonumber(cleaned)
			if src then
				local inv = Inventory(src)
				if inv and inv.owner then
					return inv.owner, src
				end
			end
		end

		return cleaned, nil
	end

	return nil
end

local function collectOnlinePlayers(originCoords, radius)
	local players = {}
	local useRadius = originCoords and radius and radius > 0

	for _, playerId in ipairs(GetPlayers()) do
		local src = tonumber(playerId)
		if src then
			local inv = Inventory(src)
			if inv and inv.owner then
				local include = true

				if useRadius then
					local ped = GetPlayerPed(src)
					if ped and ped ~= 0 then
						local pedCoords = GetEntityCoords(ped)
						if #(pedCoords - originCoords) > radius then
							include = false
						end
					else
						include = false
					end
				end

				if include then
					players[#players + 1] = {
						source = src,
						identifier = inv.owner,
						name = inv.player and inv.player.name or GetPlayerName(src),
					}
				end
			end
		end
	end

	return players
end

local function ensureDefaultRoles(persistentId)
	if not persistentId then return end

	local existing = MySQL.scalar.await('SELECT COUNT(*) FROM ox_placeable_stash_roles WHERE stash_id = ?', { persistentId })
	if existing and existing > 0 then
		return
	end

	for _, roleData in ipairs(getDefaultRoleDefinitions()) do
		MySQL.insert.await(
			'INSERT INTO ox_placeable_stash_roles (stash_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)',
			{ persistentId, roleData.name, roleData.can_use, roleData.can_move, roleData.can_pack, roleData.can_manage }
		)
	end
end

local function loadStashRoles(stashId, persistentId)
	if not persistentId then return end

	ensureDefaultRoles(persistentId)

	local roleRows = MySQL.query.await('SELECT * FROM ox_placeable_stash_roles WHERE stash_id = ? ORDER BY id ASC', { persistentId }) or {}
	local roles = {}
	local memberIndex = {}

	for _, row in ipairs(roleRows) do
		roles[row.id] = {
			id = row.id,
			stashId = row.stash_id,
			name = localizeDefaultRoleName(row.name),
			canUse = asBool(row.can_use),
			canMove = asBool(row.can_move),
			canPack = asBool(row.can_pack),
			canManage = asBool(row.can_manage),
			members = {},
		}
	end

	if next(roles) then
		local memberRows = MySQL.query.await('SELECT * FROM ox_placeable_stash_role_members WHERE stash_id = ?', { persistentId }) or {}

		for _, row in ipairs(memberRows) do
			local role = roles[row.role_id]
			if role then
				local memberEntry = {
					id = row.id,
					identifier = row.identifier,
					addedBy = row.added_by,
				}
				role.members[#role.members + 1] = memberEntry
				memberIndex[row.identifier] = row.role_id
			end
		end
	end

	local record = getStashRecord(stashId)
	if record then
		record.roles = {
			list = roles,
			memberIndex = memberIndex,
		}
	end

	return roles, memberIndex
end

local function getStashRolesCache(stashId)
	local record = getStashRecord(stashId)
	if not record or not record.id then return nil end

	if not record.roles then
		loadStashRoles(stashId, record.id)
	end

	return record.roles
end

local function computeStashPermissions(stashId, identifier)
	local permissions = {
		canUse = true,
		canMove = false,
		canPack = false,
		canManage = false,
		isOwner = false,
		roleId = nil,
		roleName = nil,
	}

	if not stashId then
		return permissions
	end

	local record = getStashRecord(stashId)
	if not record then
		return permissions
	end

	if identifier and record.owner == identifier then
		permissions.canMove = true
		permissions.canPack = true
		permissions.canManage = true
		permissions.isOwner = true
		return permissions
	end

	local rolesCache = getStashRolesCache(stashId)
	if not rolesCache then
		permissions.canUse = false
		return permissions
	end

	local roleId = identifier and rolesCache.memberIndex and rolesCache.memberIndex[identifier] or nil
	local role = roleId and rolesCache.list and rolesCache.list[roleId]
	if not role then
		permissions.canUse = false
		return permissions
	end

	permissions.canUse = role.canUse
	permissions.canMove = role.canMove
	permissions.canPack = role.canPack
	permissions.canManage = role.canManage
	permissions.roleId = role.id
	permissions.roleName = localizeDefaultRoleName(role.name)

	return permissions
end

local function hasStashPermission(subject, stashId, permission)
	if permission == 'use' and not stashId then
		return true
	end

	local identifier = subject
	if type(subject) ~= 'string' then
		identifier = getPlayerIdentifier(subject)
	end

	local record = getStashRecord(stashId)
	if not record then
		return permission == 'use'
	end

	if identifier and record.owner == identifier then
		return true
	end

	local perms = computeStashPermissions(stashId, identifier)

	if permission == 'use' then
		return perms.canUse
	elseif permission == 'move' then
		return perms.canMove
	elseif permission == 'pack' then
		return perms.canPack
	elseif permission == 'manage' then
		return perms.canManage
	elseif permission == 'owner' then
		return perms.isOwner
	end

	return false
end

local function canManageStash(source, stashId)
	local record = getStashRecord(stashId)
	if not record then return false, nil end

	local identifier = getPlayerIdentifier(source)
	if not identifier then return false, record end

	if record.owner == identifier then
		return true, record
	end

	if hasStashPermission(identifier, stashId, 'manage') then
		return true, record
	end

	return false, record
end

local function buildStashPermissionsPayload(source, stashId)
	local stash = DynamicStashes[stashId]
	local record = getStashRecord(stashId)
	if not stash or not record then
		return nil, 'stash_not_found'
	end

	local identifier = getPlayerIdentifier(source)
	if not identifier then
		return nil, 'stash_no_permission'
	end

	local isOwner = record.owner == identifier
	if not isOwner and not hasStashPermission(identifier, stashId, 'manage') then
		return nil, 'stash_no_permission'
	end

	local rolesCache = getStashRolesCache(stashId) or { list = {}, memberIndex = {} }
	local onlinePlayers = collectOnlinePlayers()
	local onlineIndex = {}

	for i = 1, #onlinePlayers do
		local player = onlinePlayers[i]
		player.roleId = rolesCache.memberIndex and rolesCache.memberIndex[player.identifier]
		onlineIndex[player.identifier] = player
	end

	local roles = {}
	for _, role in pairs(rolesCache.list or {}) do
		local members = {}

		for _, member in ipairs(role.members or {}) do
			local online = onlineIndex[member.identifier]
			members[#members + 1] = {
				id = member.id,
				identifier = member.identifier,
				name = online and online.name or member.identifier,
				online = online and true or false,
				serverId = online and online.source or nil,
				addedBy = member.addedBy,
			}
		end

		table.sort(members, function(a, b)
			return a.identifier < b.identifier
		end)

		roles[#roles + 1] = {
			id = role.id,
			name = role.name,
			canUse = role.canUse,
			canMove = role.canMove,
			canPack = role.canPack,
			canManage = role.canManage,
			memberCount = #members,
			members = members,
		}
	end

	table.sort(roles, function(a, b)
		return a.id < b.id
	end)

	local ownerInfo = record.owner and onlineIndex[record.owner] or nil
	local nearbyPlayers = collectOnlinePlayers(stash.coords, stash.nearbyRadius or 10.0)

	return {
		stashId = stashId,
		stashLabel = stash.label or stashId,
		owner = {
			identifier = record.owner,
			name = ownerInfo and ownerInfo.name or record.owner,
			online = ownerInfo and true or false,
			serverId = ownerInfo and ownerInfo.source or nil,
		},
		roles = roles,
		onlinePlayers = nearbyPlayers,
		canTransfer = isOwner,
		isOwner = isOwner,
		playerPermissions = computeStashPermissions(stashId, identifier),
	}, nil
end

function server.getPlaceableStashInventoryContext(source, stashId)
	if type(stashId) ~= 'string' or not PlacedStashes[stashId] then
		return nil
	end

	return {
		permissions = computeStashPermissions(stashId, getPlayerIdentifier(source)),
	}
end

local function sendStashPermissions(playerId, stashId)
	local stash = DynamicStashes[stashId]
	if not stash then return end

	local identifier = getPlayerIdentifier(playerId)
	local perms = computeStashPermissions(stashId, identifier)

	TriggerClientEvent('ox_inventory:stashes:updatePermissions', playerId, {
		id = stashId,
		canUse = perms.canUse,
		canMove = perms.canMove,
		canPack = perms.canPack,
		canManage = perms.canManage,
		isOwner = perms.isOwner,
		roleId = perms.roleId,
		roleName = perms.roleName,
	})
end

local function notifyStashMembers(stashId, includeOwner)
	local record = getStashRecord(stashId)
	if not record then return end

	local identifiers = {}

	if includeOwner and record.owner then
		identifiers[record.owner] = true
	end

	local cache = getStashRolesCache(stashId)
	if cache and cache.memberIndex then
		for identifier in pairs(cache.memberIndex) do
			identifiers[identifier] = true
		end
	end

	for identifier in pairs(identifiers) do
		local targetSrc = getOnlineSourceByIdentifier(identifier)
		if targetSrc then
			sendStashPermissions(targetSrc, stashId)
		end
	end
end

local function clearStashRoles(stashId)
	local record = getStashRecord(stashId)
	if record then
		record.roles = nil
	end
end

local function buildStashDefinition(id, stashData)
	local typeId = stashData.type or stashData.typeId
	local typeConfig = typeId and StashTypes[typeId]

	if not typeConfig then
		warn(('failed to create placeable stash "%s" - unknown type "%s"'):format(id, tostring(typeId)))
		return
	end

	local built = table.clone(stashData) or {}
	built.id = id
	built.typeId = typeId
	built.typeConfig = typeConfig
	built.label = built.label or typeConfig.label or id
	built.model = built.model or typeConfig.model
	built.spawnRange = built.spawnRange or typeConfig.spawnRange or 45.0
	built.targetRadius = built.targetRadius or typeConfig.targetRadius or 1.5
	built.targetDistance = built.targetDistance or typeConfig.targetDistance or 2.0
	built.accessDistance = built.accessDistance or typeConfig.accessDistance or 10.0
	built.nearbyRadius = built.nearbyRadius or typeConfig.nearbyRadius or 10.0
	built.slots = built.slots or typeConfig.slots or 25
	built.maxWeight = built.maxWeight or typeConfig.weight or 25000
	built.placement = built.placement or typeConfig.placement
	built.blacklist = built.blacklist or typeConfig.blacklist
	built.whitelist = built.whitelist or typeConfig.whitelist
	built.blacklistLookup = normalizeItemFilterSet(built.blacklist)
	built.whitelistLookup = normalizeItemFilterSet(built.whitelist)

	if built.coords then
		built.coords = toVector3(built.coords)
	end

	return built
end

local function registerRuntimeInventory(stash)
	if not stash or not stash.id then return end

	exports.ox_inventory:RegisterStash(
		stash.id,
		stash.label or stash.id,
		stash.slots,
		stash.maxWeight,
		false,
		nil,
		stash.coords,
		stash.accessDistance or 10.0
	)
end

local function sanitiseStashForClient(stash)
	local payload = table.clone(stash) or {}
	payload.typeConfig = nil
	payload.blacklistLookup = nil
	payload.whitelistLookup = nil

	if payload.coords and type(payload.coords) == 'vector3' then
		payload.coords = {
			x = payload.coords.x,
			y = payload.coords.y,
			z = payload.coords.z,
		}
	end

	return payload
end

local function registerDynamicStash(id, stashData)
	local built = buildStashDefinition(id, stashData)
	if not built then return end

	DynamicStashes[id] = built
	registerRuntimeInventory(built)

	return built
end

local function ensureDatabase()
	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `ox_placeable_stashes` (
			`id` INT NOT NULL AUTO_INCREMENT,
			`type` VARCHAR(64) NOT NULL,
			`owner` VARCHAR(64) NULL,
			`label` VARCHAR(64) NULL,
			`coords` JSON NOT NULL,
			`metadata` JSON NULL,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])

	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `ox_placeable_stash_roles` (
			`id` INT NOT NULL AUTO_INCREMENT,
			`stash_id` INT NOT NULL,
			`name` VARCHAR(64) NOT NULL,
			`can_use` TINYINT(1) NOT NULL DEFAULT 1,
			`can_move` TINYINT(1) NOT NULL DEFAULT 0,
			`can_pack` TINYINT(1) NOT NULL DEFAULT 0,
			`can_manage` TINYINT(1) NOT NULL DEFAULT 0,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			KEY `idx_stash_roles_stash` (`stash_id`),
			CONSTRAINT `fk_stash_roles_stash` FOREIGN KEY (`stash_id`) REFERENCES `ox_placeable_stashes`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])

	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `ox_placeable_stash_role_members` (
			`id` INT NOT NULL AUTO_INCREMENT,
			`stash_id` INT NOT NULL,
			`role_id` INT NOT NULL,
			`identifier` VARCHAR(64) NOT NULL,
			`added_by` VARCHAR(64) NULL,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			KEY `idx_stash_role_members_stash` (`stash_id`),
			KEY `idx_stash_role_members_role` (`role_id`),
			CONSTRAINT `fk_stash_role_members_role` FOREIGN KEY (`role_id`) REFERENCES `ox_placeable_stash_roles`(`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_stash_role_members_stash` FOREIGN KEY (`stash_id`) REFERENCES `ox_placeable_stashes`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
end

local function registerPlacementItems()
	for typeName, typeConfig in pairs(StashTypes) do
		local placement = typeConfig.placement
		if placement and placement.item and not PlacementItems[placement.item] then
			PlacementItems[placement.item] = typeName
		end
	end
end

local function broadcastDynamicStash(stash)
	local payload = sanitiseStashForClient(stash)
	TriggerClientEvent('ox_inventory:stashes:addStash', -1, payload)

	for _, playerId in ipairs(GetPlayers()) do
		local src = tonumber(playerId)
		if src then
			sendStashPermissions(src, stash.id)
		end
	end
end

local function loadPersistentStashes()
	local rows = MySQL.query.await('SELECT * FROM ox_placeable_stashes') or {}

	for _, row in ipairs(rows) do
		local coords = type(row.coords) == 'string' and json.decode(row.coords) or row.coords or {}
		local metadata = type(row.metadata) == 'string' and json.decode(row.metadata) or row.metadata or {}
		local stashId = buildPlacedStashId(row.id)
		local stashData = {
			type = row.type,
			label = row.label or metadata.name,
			coords = vec3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0),
			heading = coords.w or metadata.heading or 0.0,
			owner = row.owner,
			dynamic = true,
			persistentId = row.id,
		}

		local stash = registerDynamicStash(stashId, stashData)
		if stash then
			PlacedStashes[stashId] = {
				id = row.id,
				owner = row.owner,
				type = stash.typeId,
				coords = stash.coords,
			}

			loadStashRoles(stashId, row.id)
			broadcastDynamicStash(stash)
		end
	end
end

local function validatePlacementItem(typeName, itemName)
	local typeConfig = StashTypes[typeName]
	if not typeConfig or not typeConfig.placement then
		return false
	end

	return typeConfig.placement.item == itemName
end

CreateThread(function()
	ensureDatabase()
	registerPlacementItems()
	loadPersistentStashes()

	exports.ox_inventory:registerHook('openInventory', function(payload)
		local stashId = payload.inventoryId
		local record = stashId and PlacedStashes[stashId]
		if not record then return true end

		if not hasStashPermission(payload.source, stashId, 'use') then
			lib.notify(payload.source, {
				type = 'error',
				description = locale('crafting_no_permission') or 'No permission',
			})
			return false
		end

		return true
	end, {
		inventoryFilter = { '^placed_stash:' },
		typeFilter = {
			stash = true,
		},
	})

	exports.ox_inventory:registerHook('swapItems', function(payload)
		if payload.fromInventory == payload.toInventory then
			return true
		end

		local function validateStash(stashId)
			if not stashId then
				return true
			end

			stashId = tostring(stashId)

			local stash = DynamicStashes[stashId]
			if not stash then
				return true
			end

			local incomingItem = getIncomingInventoryItemName(payload, stashId)

			if not incomingItem or itemAllowedByFilters(incomingItem, stash.whitelistLookup, stash.blacklistLookup) then
				return true
			end

			local item = Items(incomingItem)

			lib.notify(payload.source, {
				type = 'error',
				description = ('%s cannot be stored in %s.'):format(item and item.label or incomingItem, stash.label or 'this stash'),
			})

			return false
		end

		if validateStash(payload.toInventory) == false then
			return false
		end

		if payload.action == 'swap' and validateStash(payload.fromInventory) == false then
			return false
		end

		return true
	end, {
		inventoryFilter = { '^placed_stash:' },
	})
end)

AddEventHandler('ox_inventory:usedItem', function(invId, itemName, slot, metadata, source)
	local typeName = PlacementItems[itemName]
	if not typeName then return end

	local typeConfig = StashTypes[typeName]
	if not typeConfig then return end

	PendingPlacement[invId] = {
		type = typeName,
		item = itemName,
		slot = slot,
	}

	TriggerClientEvent('ox_inventory:stashes:startPlacement', source, {
		type = typeName,
		item = itemName,
		slot = slot,
		model = typeConfig.model,
		label = typeConfig.label or typeName,
		inventory = invId,
	})
end)

RegisterNetEvent('ox_inventory:stashes:requestStashes', function()
	local src = source

	for stashId, stash in pairs(DynamicStashes) do
		TriggerClientEvent('ox_inventory:stashes:addStash', src, sanitiseStashForClient(stash))
		sendStashPermissions(src, stashId)
	end
end)

RegisterNetEvent('ox_inventory:stashes:refreshPermissions', function()
	local src = source

	for stashId in pairs(DynamicStashes) do
		sendStashPermissions(src, stashId)
	end
end)

RegisterNetEvent('ox_inventory:stashes:placementCancelled', function(inventoryId)
	PendingPlacement[inventoryId or source] = nil
end)

RegisterNetEvent('ox_inventory:stashes:placeStash', function(data)
	local src = source
	if type(data) ~= 'table' then return end

	local pending = PendingPlacement[data.inventory]
	if not pending then return end

	local typeName = data.type
	if not validatePlacementItem(typeName, pending.item) then
		PendingPlacement[data.inventory] = nil
		return
	end

	local typeConfig = StashTypes[typeName]
	if not typeConfig then
		PendingPlacement[data.inventory] = nil
		return
	end

	local coords = data.coords
	if type(coords) ~= 'table' then
		PendingPlacement[data.inventory] = nil
		return
	end

	local vec = vec3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
	local heading = data.heading or 0.0
	local removed = Inventory.RemoveItem(data.inventory, pending.item, 1, nil, pending.slot)

	if not removed then
		PendingPlacement[data.inventory] = nil
		lib.notify(src, { type = 'error', description = locale('cannot_perform') or 'Cannot perform' })
		return
	end

	local identifier = getPlayerIdentifier(src)
	local label = data.label or typeConfig.label or typeName
	local dbId = MySQL.insert.await('INSERT INTO ox_placeable_stashes (type, owner, label, coords, metadata) VALUES (?, ?, ?, ?, ?)', {
		typeName,
		identifier,
		label,
		json.encode({ x = vec.x, y = vec.y, z = vec.z, w = heading }),
		json.encode({ name = label }),
	})

	if not dbId or dbId < 1 then
		Inventory.AddItem(src, pending.item, 1)
		PendingPlacement[data.inventory] = nil
		lib.notify(src, { type = 'error', description = locale('cannot_perform') or 'Cannot perform' })
		return
	end

	local stashId = buildPlacedStashId(dbId)
	local stash = registerDynamicStash(stashId, {
		type = typeName,
		label = label,
		coords = vec,
		heading = heading,
		owner = identifier,
		dynamic = true,
		persistentId = dbId,
	})

	if not stash then
		MySQL.update.await('DELETE FROM ox_placeable_stashes WHERE id = ?', { dbId })
		Inventory.AddItem(src, pending.item, 1)
		PendingPlacement[data.inventory] = nil
		lib.notify(src, { type = 'error', description = locale('cannot_perform') or 'Cannot perform' })
		return
	end

	PlacedStashes[stashId] = {
		id = dbId,
		owner = identifier,
		type = stash.typeId,
		coords = vec,
	}

	loadStashRoles(stashId, dbId)
	broadcastDynamicStash(stash)

	PendingPlacement[data.inventory] = nil
	lib.notify(src, {
		type = 'success',
		description = 'Stash placed.',
	})
end)

RegisterNetEvent('ox_inventory:stashes:requestMoveStash', function(stashId)
	local src = source
	local stash = stashId and DynamicStashes[stashId]
	if not stash or not stash.dynamic then return end
	if not hasStashPermission(src, stashId, 'move') then return end

	TriggerClientEvent('ox_inventory:stashes:startMove', src, {
		id = stashId,
		model = stash.model,
		coords = {
			x = stash.coords.x,
			y = stash.coords.y,
			z = stash.coords.z,
		},
		heading = stash.heading or 0.0,
		label = stash.label or stashId,
	})
end)

RegisterNetEvent('ox_inventory:stashes:moveStash', function(stashId, payload)
	local src = source
	local stash = stashId and DynamicStashes[stashId]
	local record = stashId and PlacedStashes[stashId]
	if not stash or not record then return end
	if not hasStashPermission(src, stashId, 'move') then return end
	if type(payload) ~= 'table' or type(payload.coords) ~= 'table' then return end

	local vec = vec3(payload.coords.x or 0.0, payload.coords.y or 0.0, payload.coords.z or 0.0)
	local heading = payload.heading or 0.0

	stash.coords = vec
	stash.heading = heading
	record.coords = vec

	registerRuntimeInventory(stash)

	MySQL.update.await('UPDATE ox_placeable_stashes SET coords = ? WHERE id = ?', {
		json.encode({ x = vec.x, y = vec.y, z = vec.z, w = heading }),
		record.id,
	})

	broadcastDynamicStash(stash)
end)

RegisterNetEvent('ox_inventory:stashes:packStash', function(stashId)
	local src = source
	local stash = stashId and DynamicStashes[stashId]
	local record = stashId and PlacedStashes[stashId]
	if not stash or not record then return end
	if not hasStashPermission(src, stashId, 'pack') then return end

	local stashInventory = Inventory(stashId)
	if stashInventory and next(stashInventory.items) then
		lib.notify(src, {
			type = 'error',
			description = 'Empty the stash before packing it.',
		})
		return
	end

	local typeConfig = stash.typeConfig or (stash.typeId and StashTypes[stash.typeId])
	local placementItem = typeConfig and typeConfig.placement and typeConfig.placement.item
	if not placementItem then return end

	local added = Inventory.AddItem(src, placementItem, 1)
	if not added then
		lib.notify(src, { type = 'error', description = locale('cannot_perform') or 'Cannot perform' })
		return
	end

	exports.ox_inventory:RemoveStash(stashId)
	DynamicStashes[stashId] = nil
	PlacedStashes[stashId] = nil
	clearStashRoles(stashId)

	MySQL.update.await('DELETE FROM ox_placeable_stashes WHERE id = ?', { record.id })

	TriggerClientEvent('ox_inventory:stashes:removeStash', -1, stashId)
	TriggerClientEvent('ox_inventory:stashes:updatePermissions', -1, { id = stashId, removed = true })

	lib.notify(src, {
		type = 'success',
		description = 'Stash packed up.',
	})
end)

lib.callback.register('ox_inventory:stashes:getPermissions', function(source, stashId)
	if type(stashId) ~= 'string' then
		return false, 'stash_not_found'
	end

	local payload, err = buildStashPermissionsPayload(source, stashId)
	if not payload then
		return false, err or 'stash_no_permission'
	end

	return payload
end)

lib.callback.register('ox_inventory:stashes:createRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local stashId = data.stashId
	local name = trim(data.name) or (locale('crafting_role_new') or 'Role')
	local permissions = data.permissions or {}

	if type(stashId) ~= 'string' then
		return false, 'stash_not_found'
	end

	local allowed, record = canManageStash(source, stashId)
	if not allowed or not record or not record.id then
		return false, 'stash_no_permission'
	end

	MySQL.insert.await(
		'INSERT INTO ox_placeable_stash_roles (stash_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)',
		{
			record.id,
			name,
			permissions.use and 1 or 0,
			permissions.move and 1 or 0,
			permissions.pack and 1 or 0,
			permissions.manage and 1 or 0,
		}
	)

	loadStashRoles(stashId, record.id)
	notifyStashMembers(stashId, true)

	return buildStashPermissionsPayload(source, stashId)
end)

lib.callback.register('ox_inventory:stashes:updateRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local stashId = data.stashId
	local roleId = data.roleId
	local name = trim(data.name) or (locale('crafting_role_new') or 'Role')
	local permissions = data.permissions or {}

	if type(stashId) ~= 'string' or type(roleId) ~= 'number' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageStash(source, stashId)
	if not allowed or not record or not record.id then
		return false, 'stash_no_permission'
	end

	local roleRow = MySQL.single.await('SELECT stash_id FROM ox_placeable_stash_roles WHERE id = ?', { roleId })
	if not roleRow or roleRow.stash_id ~= record.id then
		return false, 'stash_not_found'
	end

	MySQL.update.await(
		'UPDATE ox_placeable_stash_roles SET name = ?, can_use = ?, can_move = ?, can_pack = ?, can_manage = ? WHERE id = ?',
		{
			name,
			permissions.use and 1 or 0,
			permissions.move and 1 or 0,
			permissions.pack and 1 or 0,
			permissions.manage and 1 or 0,
			roleId,
		}
	)

	loadStashRoles(stashId, record.id)
	notifyStashMembers(stashId, true)

	return buildStashPermissionsPayload(source, stashId)
end)

lib.callback.register('ox_inventory:stashes:deleteRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local stashId = data.stashId
	local roleId = data.roleId
	if type(stashId) ~= 'string' or type(roleId) ~= 'number' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageStash(source, stashId)
	if not allowed or not record or not record.id then
		return false, 'stash_no_permission'
	end

	local rolesCache = getStashRolesCache(stashId)
	local role = rolesCache and rolesCache.list and rolesCache.list[roleId]
	if not role then
		return false, 'stash_not_found'
	end

	if role.members and #role.members > 0 then
		return false, 'stash_role_has_members'
	end

	MySQL.update.await('DELETE FROM ox_placeable_stash_roles WHERE id = ? AND stash_id = ?', { roleId, record.id })

	loadStashRoles(stashId, record.id)
	notifyStashMembers(stashId, true)

	return buildStashPermissionsPayload(source, stashId)
end)

lib.callback.register('ox_inventory:stashes:setMemberRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local stashId = data.stashId
	local roleId = data.roleId
	local target = data.target
	if type(stashId) ~= 'string' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageStash(source, stashId)
	if not allowed or not record or not record.id then
		return false, 'stash_no_permission'
	end

	local identifier, resolvedSource = resolveIdentifier(target)
	if not identifier then
		return false, 'stash_invalid_member'
	end

	if identifier == record.owner then
		return false, 'stash_invalid_member'
	end

	local rolesCache = getStashRolesCache(stashId)
	local previousRoleId = rolesCache and rolesCache.memberIndex and rolesCache.memberIndex[identifier]

	MySQL.update.await('DELETE FROM ox_placeable_stash_role_members WHERE stash_id = ? AND identifier = ?', { record.id, identifier })

	if roleId and type(roleId) == 'number' then
		local role = rolesCache and rolesCache.list and rolesCache.list[roleId]
		if not role then
			return false, 'stash_not_found'
		end

		MySQL.insert.await(
			'INSERT INTO ox_placeable_stash_role_members (stash_id, role_id, identifier, added_by) VALUES (?, ?, ?, ?)',
			{ record.id, roleId, identifier, getPlayerIdentifier(source) }
		)
	end

	loadStashRoles(stashId, record.id)
	notifyStashMembers(stashId, true)

	local payload, err = buildStashPermissionsPayload(source, stashId)
	if resolvedSource then
		sendStashPermissions(resolvedSource, stashId)
	elseif previousRoleId then
		local targetSrc = getOnlineSourceByIdentifier(identifier)
		if targetSrc then
			sendStashPermissions(targetSrc, stashId)
		end
	end

	return payload, err
end)

lib.callback.register('ox_inventory:stashes:transferOwnership', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local stashId = data.stashId
	local target = data.target
	if type(stashId) ~= 'string' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageStash(source, stashId)
	local identifier = getPlayerIdentifier(source)
	if not allowed or not record or record.owner ~= identifier then
		return false, 'stash_no_permission'
	end

	local newIdentifier, resolvedSource = resolveIdentifier(target)
	if not newIdentifier or newIdentifier == record.owner then
		return false, 'stash_invalid_member'
	end

	MySQL.update.await('UPDATE ox_placeable_stashes SET owner = ? WHERE id = ?', { newIdentifier, record.id })
	record.owner = newIdentifier

	if DynamicStashes[stashId] then
		DynamicStashes[stashId].owner = newIdentifier
	end

	MySQL.update.await('DELETE FROM ox_placeable_stash_role_members WHERE stash_id = ? AND identifier = ?', { record.id, newIdentifier })

	loadStashRoles(stashId, record.id)

	local oldOwnerSource = getOnlineSourceByIdentifier(identifier)
	if oldOwnerSource then
		sendStashPermissions(oldOwnerSource, stashId)
	end

	if resolvedSource then
		sendStashPermissions(resolvedSource, stashId)
	end

	notifyStashMembers(stashId, true)

	return buildStashPermissionsPayload(source, stashId)
end)

AddEventHandler('playerDropped', function()
	PendingPlacement[source] = nil
end)
