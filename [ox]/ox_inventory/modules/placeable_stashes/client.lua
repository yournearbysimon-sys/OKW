if not lib then return end
lib.locale()

local Utils = require 'modules.utils.client'
local createBlip = Utils.CreateBlip

local StashConfig = lib.load('data.placeable_stashes') or {}
local StashTypes = StashConfig.types or {}

local DynamicStashes = {}
local StashProps = {}
local StashPoints = {}
local StashZones = {}
local StashTargetEntities = {}
local StashMoving = {}
local StashPermissions = {}
local markerColour = { 150, 150, 30 }
local currentResource = cache and cache.resource or GetCurrentResourceName()

local prompt = {
	options = { icon = 'fa-box-archive' },
	message = ('**%s**  \n%s'):format(
		locale('open_stash'),
		locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3))
	)
}

local function shallowCopy(tbl)
	if not tbl then return {} end
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

local function getStashPermissions(id)
	return StashPermissions[id]
end

local function setStashPermissionsCache(id, data)
	if not id or type(data) ~= 'table' then
		return
	end

	StashPermissions[id] = {
		canUse = data.canUse ~= false,
		canMove = data.canMove == true,
		canPack = data.canPack == true,
		canManage = data.canManage == true,
		isOwner = data.isOwner == true,
		roleId = data.roleId,
		roleName = data.roleName,
	}
end

local function stashHasPermission(id, flag)
	local perms = getStashPermissions(id)

	if not perms then
		return flag == 'use'
	end

	if perms.isOwner then
		return true
	end

	if flag == 'use' then
		return perms.canUse or false
	elseif flag == 'move' then
		return perms.canMove or false
	elseif flag == 'pack' then
		return perms.canPack or false
	elseif flag == 'manage' then
		return perms.canManage or false
	end

	return false
end

local function notifyError(message)
	lib.notify({
		type = 'error',
		description = message,
	})
end

local function notifySuccess(message)
	lib.notify({
		type = 'success',
		description = message,
	})
end

local function attemptOpenStash(id)
	if not stashHasPermission(id, 'use') then
		notifyError(locale('crafting_no_permission') or 'No permission')
		return
	end

	client.openInventory('stash', id)
end

local function fetchStashPermissionsPayload(id)
	local payload, err = lib.callback.await('ox_inventory:stashes:getPermissions', false, id)

	if not payload then
		notifyError(locale(err or 'crafting_no_permission') or tostring(err or 'No permission'))
		return nil
	end

	if payload.playerPermissions then
		setStashPermissionsCache(id, payload.playerPermissions)
	end

	return payload
end

local function openStashPermissionsUI(id, options)
	options = options or {}

	if not stashHasPermission(id, 'manage') then
		notifyError(locale('crafting_no_permission') or 'No permission')
		return nil, 'stash_no_permission'
	end

	local payload, err = fetchStashPermissionsPayload(id)
	if not payload then
		return nil, err or 'stash_no_permission'
	end

	SendNUIMessage({
		action = 'openStashPermissions',
		data = payload,
	})

	if options.focus ~= false then
		SetNuiFocus(true, true)
	end

	return payload
end

local function buildStashTargetOptions(id, stash, distance, includeOpen, includeExtras)
	local options = {}
	local optionDistance = distance or stash.targetDistance or 2.0

	if includeOpen ~= false then
		options[#options + 1] = {
			label = stash.label or locale('open_stash'),
			icon = stash.targetIcon or 'fas fa-box-archive',
			distance = optionDistance,
			canInteract = function()
				return stashHasPermission(id, 'use')
			end,
			onSelect = function()
				attemptOpenStash(id)
			end,
		}
	end

	if includeExtras ~= false then
		options[#options + 1] = {
			icon = 'fas fa-arrows-alt',
			label = 'Move Stash',
			distance = optionDistance,
			canInteract = function()
				return stashHasPermission(id, 'move')
			end,
			onSelect = function()
				TriggerServerEvent('ox_inventory:stashes:requestMoveStash', id)
			end,
		}

		options[#options + 1] = {
			icon = 'fas fa-box-open',
			label = 'Pack Stash',
			distance = optionDistance,
			canInteract = function()
				return stashHasPermission(id, 'pack')
			end,
			onSelect = function()
				TriggerServerEvent('ox_inventory:stashes:packStash', id)
			end,
		}
	end

	return options
end

local function buildStashContextOptions(id, stash)
	local options = {}

	if stashHasPermission(id, 'use') then
		options[#options + 1] = {
			title = stash.label or locale('open_stash'),
			icon = 'fas fa-box-archive',
			description = 'Open this placed stash.',
			onSelect = function()
				attemptOpenStash(id)
			end,
		}
	end

	if stashHasPermission(id, 'move') then
		options[#options + 1] = {
			title = 'Move Stash',
			icon = 'fas fa-arrows-alt',
			description = 'Reposition this stash.',
			onSelect = function()
				TriggerServerEvent('ox_inventory:stashes:requestMoveStash', id)
			end,
		}
	end

	if stashHasPermission(id, 'pack') then
		options[#options + 1] = {
			title = 'Pack Stash',
			icon = 'fas fa-box-open',
			description = 'Pack this stash back into an item.',
			onSelect = function()
				TriggerServerEvent('ox_inventory:stashes:packStash', id)
			end,
		}
	end

	return options
end

local function handleStashInteraction(id)
	local stash = DynamicStashes[id]
	if not stash then
		notifyError('Stash not found.')
		return
	end

	local options = buildStashContextOptions(id, stash)

	if #options == 0 then
		notifyError(locale('crafting_no_permission') or 'No permission')
		return
	end

	if #options == 1 then
		local entry = options[1]
		if entry and entry.onSelect then
			entry.onSelect()
		end
		return
	end

	local contextId = ('ox_inventory:stash:actions:%s'):format(id)
	lib.hideTextUI()
	lib.registerContext({
		id = contextId,
		title = stash.label or 'Placed Stash',
		options = options,
	})
	lib.showContext(contextId)
end

local function removeStashTarget(id)
	local entity = StashTargetEntities[id]
	if entity and DoesEntityExist(entity) then
		pcall(function()
			exports.ox_target:removeLocalEntity(entity)
		end)
	end

	StashTargetEntities[id] = nil
end

local function attachTargetToStash(id, stash, entity)
	if not shared.target or entity == 0 then return end
	if StashZones[id] then return end

	removeStashTarget(id)

	local options = buildStashTargetOptions(id, stash, stash.targetDistance, true, true)
	if next(options) then
		exports.ox_target:addLocalEntity(entity, options)
		StashTargetEntities[id] = entity
	end
end

local function removeTargetZone(id)
	local zoneHandles = StashZones[id]
	if not zoneHandles then return end

	for _, zoneName in ipairs(zoneHandles) do
		if zoneName then
			pcall(function()
				exports.ox_target:removeZone(zoneName)
			end)
		end
	end

	StashZones[id] = nil
end

local function removeStashPoint(id)
	local points = StashPoints[id]
	if not points then return end

	for _, point in ipairs(points) do
		if point and point.remove then
			point:remove()
		end
	end

	StashPoints[id] = nil
end

local function deleteStashProp(id)
	removeStashTarget(id)

	local entity = StashProps[id]
	if not entity or not DoesEntityExist(entity) then
		StashProps[id] = nil
		return
	end

	DeleteEntity(entity)
	StashProps[id] = nil
end

local function ensureStashProp(id, stash)
	if StashMoving[id] then return end
	if not stash.model or not stash.spawnRange then return end
	if not stash.coords then return end

	local playerCoords = GetEntityCoords(cache.ped)
	local coords = stash.coords
	local distance = #(playerCoords - coords)
	local existing = StashProps[id]

	if distance <= stash.spawnRange then
		if existing and DoesEntityExist(existing) then
			if not StashTargetEntities[id] then
				attachTargetToStash(id, stash, existing)
			end
			return
		end

		local model = lib.requestModel(stash.model)
		if not model then return end

		local object = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
		if object == 0 then
			return
		end

		SetEntityHeading(object, stash.heading or 0.0)
		PlaceObjectOnGroundProperly(object)
		FreezeEntityPosition(object, true)
		SetEntityInvincible(object, true)
		SetModelAsNoLongerNeeded(model)

		StashProps[id] = object
		attachTargetToStash(id, stash, object)
		StashMoving[id] = nil
	elseif existing then
		deleteStashProp(id)
	end
end

CreateThread(function()
	while true do
		local ped = cache.ped

		if ped and ped ~= 0 then
			for id, stash in pairs(DynamicStashes) do
				if stash.spawnRange and stash.model then
					ensureStashProp(id, stash)
				end
			end
		end

		Wait(1000)
	end
end)

local function setupTargetInteractions(id, stash)
	removeTargetZone(id)
	removeStashTarget(id)
	removeStashPoint(id)

	local handles = {}

	if shared.target then
		local coords = stash.coords
		if coords then
			local zoneName = ('placedstash_%s:dynamic'):format(id)
			local radius = stash.targetRadius or 1.5

			exports.ox_target:addSphereZone({
				name = zoneName,
				coords = coords,
				radius = radius,
				debug = stash.debugTarget,
				options = buildStashTargetOptions(id, stash, radius, true, true),
			})

			handles[#handles + 1] = zoneName

			if stash.blip then
				createBlip(stash.blip, coords)
			end
		end
	else
		if stash.coords then
			local point = lib.points.new({
				coords = stash.coords,
				distance = 16,
				inv = 'stash',
				invId = id,
				prompt = prompt,
				marker = markerColour,
				nearby = Utils.nearbyMarker,
				onInteract = function()
					handleStashInteraction(id)
				end,
			})

			StashPoints[id] = { point }
		end
	end

	if next(handles) then
		StashZones[id] = handles
	else
		StashZones[id] = nil
	end
end

local function registerStash(id, stashData)
	if DynamicStashes[id] then
		removeTargetZone(id)
		removeStashTarget(id)
		removeStashPoint(id)
		deleteStashProp(id)
	end

	local typeId = stashData.type or stashData.typeId
	local typeConfig = typeId and StashTypes[typeId]
	if typeConfig then
		stashData.label = stashData.label or typeConfig.label
		stashData.model = stashData.model or typeConfig.model
		stashData.spawnRange = stashData.spawnRange or typeConfig.spawnRange
		stashData.targetRadius = stashData.targetRadius or typeConfig.targetRadius
		stashData.targetDistance = stashData.targetDistance or typeConfig.targetDistance
		stashData.nearbyRadius = stashData.nearbyRadius or typeConfig.nearbyRadius
		stashData.slots = stashData.slots or typeConfig.slots
		stashData.maxWeight = stashData.maxWeight or typeConfig.weight
	end

	if stashData.coords then
		if type(stashData.coords) == 'vector3' then
			stashData.coords = vec3(stashData.coords.x, stashData.coords.y, stashData.coords.z)
		elseif type(stashData.coords) == 'table' then
			stashData.coords = vec3(stashData.coords.x or 0.0, stashData.coords.y or 0.0, stashData.coords.z or 0.0)
		end
	end

	DynamicStashes[id] = stashData

	if stashData.permissions then
		setStashPermissionsCache(id, stashData.permissions)
		stashData.permissions = nil
	end

	setupTargetInteractions(id, stashData)
	StashMoving[id] = nil
end

local function removeStash(id)
	removeTargetZone(id)
	removeStashPoint(id)
	removeStashTarget(id)
	deleteStashProp(id)
	StashPermissions[id] = nil
	DynamicStashes[id] = nil
end

local function waitPlacementConfirmation(message)
	lib.showTextUI(message, { position = 'bottom-center' })

	local confirmed = false

	while true do
		if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
			confirmed = true
			break
		end

		if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) then
			break
		end

		Wait(0)
	end

	lib.hideTextUI()

	return confirmed
end

local function usePlacementGizmo(ghost, options, fallbackMessage)
	if GetResourceState('Preload-gizmo') == 'started' then
		local result = exports['Preload-gizmo']:useGizmo(ghost, options or {})
		if result then
			return result.confirmed == true, result
		end
	end

	if GetResourceState('object_gizmo') == 'started' then
		exports.object_gizmo:useGizmo(ghost)
	else
		PlaceObjectOnGroundProperly(ghost)
		FreezeEntityPosition(ghost, true)
	end

	local confirmed = waitPlacementConfirmation(fallbackMessage)

	return confirmed, {
		handle = ghost,
		position = DoesEntityExist(ghost) and GetEntityCoords(ghost) or nil,
		rotation = DoesEntityExist(ghost) and GetEntityRotation(ghost, 2) or nil,
		heading = DoesEntityExist(ghost) and GetEntityHeading(ghost) or 0.0,
		confirmed = confirmed,
		cancelled = not confirmed,
	}
end

local function startPlacement(data)
	if type(data) ~= 'table' then return end

	local typeName = data.type
	local typeConfig = typeName and StashTypes[typeName]
	if not typeConfig then return end

	local model = data.model or typeConfig.model
	if not model then
		notifyError(locale('cannot_perform') or 'Cannot perform')
		TriggerServerEvent('ox_inventory:stashes:placementCancelled', data.inventory)
		return
	end

	local hash = lib.requestModel(model)
	if not hash then
		notifyError(locale('cannot_perform') or 'Cannot perform')
		TriggerServerEvent('ox_inventory:stashes:placementCancelled', data.inventory)
		return
	end

	local ped = cache.ped
	local offset = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
	local ghost = CreateObject(hash, offset.x, offset.y, offset.z, false, false, false)

	if ghost == 0 then
		notifyError(locale('cannot_perform') or 'Cannot perform')
		TriggerServerEvent('ox_inventory:stashes:placementCancelled', data.inventory)
		return
	end

	SetEntityAlpha(ghost, 150, false)
	SetEntityCollision(ghost, false, false)
	SetEntityHeading(ghost, GetEntityHeading(ped))
	SetModelAsNoLongerNeeded(hash)

	local confirmed, gizmoResult = usePlacementGizmo(ghost, {
		title = typeConfig.label or 'PLACED STASH',
		subtitle = 'Move or rotate the stash, then confirm the placement.',
		confirmLabel = 'Place Stash',
		cancelLabel = 'Cancel',
	}, '[E] Confirm  |  [Backspace] Cancel')

	if not DoesEntityExist(ghost) then
		if not confirmed then
			TriggerServerEvent('ox_inventory:stashes:placementCancelled', data.inventory)
		end
		return
	end

	local coords = gizmoResult and gizmoResult.position or GetEntityCoords(ghost)
	local heading = gizmoResult and gizmoResult.heading or GetEntityHeading(ghost)
	DeleteObject(ghost)

	if confirmed then
		TriggerServerEvent('ox_inventory:stashes:placeStash', {
			type = typeName,
			coords = { x = coords.x, y = coords.y, z = coords.z },
			heading = heading,
			label = typeConfig.label,
			inventory = data.inventory,
		})
	else
		TriggerServerEvent('ox_inventory:stashes:placementCancelled', data.inventory)
	end
end

local function startMoveStash(data)
	if type(data) ~= 'table' then return end

	local stashId = data.id
	if not stashId then return end

	local stash = DynamicStashes[stashId]
	if not stash then return end

	StashMoving[stashId] = true

	local model = data.model or stash.model
	if not model then
		notifyError(locale('cannot_perform') or 'Cannot perform')
		ensureStashProp(stashId, stash)
		StashMoving[stashId] = nil
		return
	end

	deleteStashProp(stashId)

	local coordsData = data.coords or {}
	local coords = vec3(coordsData.x or 0.0, coordsData.y or 0.0, coordsData.z or 0.0)
	local heading = data.heading or 0.0

	local hash = lib.requestModel(model)
	if not hash then
		ensureStashProp(stashId, stash)
		StashMoving[stashId] = nil
		return
	end

	local ghost = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
	if ghost == 0 then
		ensureStashProp(stashId, stash)
		StashMoving[stashId] = nil
		return
	end

	SetEntityHeading(ghost, heading)
	SetEntityAlpha(ghost, 150, false)
	SetEntityCollision(ghost, false, false)
	SetModelAsNoLongerNeeded(hash)

	local confirmed, gizmoResult = usePlacementGizmo(ghost, {
		title = stash.label or 'PLACED STASH',
		subtitle = 'Move or rotate the stash, then confirm the new placement.',
		confirmLabel = 'Move Stash',
		cancelLabel = 'Cancel',
	}, '[E] Confirm  |  [Backspace] Cancel')

	if not DoesEntityExist(ghost) then
		if not confirmed then
			TriggerServerEvent('ox_inventory:stashes:placementCancelled')
		end
		ensureStashProp(stashId, stash)
		StashMoving[stashId] = nil
		return
	end

	local nextCoords = gizmoResult and gizmoResult.position or GetEntityCoords(ghost)
	local nextHeading = gizmoResult and gizmoResult.heading or GetEntityHeading(ghost)
	DeleteObject(ghost)

	if confirmed then
		TriggerServerEvent('ox_inventory:stashes:moveStash', stashId, {
			coords = { x = nextCoords.x, y = nextCoords.y, z = nextCoords.z },
			heading = nextHeading,
		})
	else
		ensureStashProp(stashId, stash)
		StashMoving[stashId] = nil
	end
end

RegisterNetEvent('ox_inventory:stashes:startPlacement', startPlacement)
RegisterNetEvent('ox_inventory:stashes:startMove', startMoveStash)
RegisterNetEvent('ox_inventory:stashes:removeStash', removeStash)

RegisterNetEvent('ox_inventory:stashes:updatePermissions', function(data)
	if not data or not data.id then return end

	if data.removed then
		StashPermissions[data.id] = nil
		return
	end

	setStashPermissionsCache(data.id, data)
end)

RegisterNetEvent('ox_inventory:stashes:addStash', function(stash)
	if not stash or not stash.id then return end

	local existing = DynamicStashes[stash.id]
	if existing then
		local coordsChanged = false

		if stash.coords ~= nil then
			local nextCoords = vec3(stash.coords.x, stash.coords.y, stash.coords.z)
			local currentCoords = existing.coords

			coordsChanged = not currentCoords
				or currentCoords.x ~= nextCoords.x
				or currentCoords.y ~= nextCoords.y
				or currentCoords.z ~= nextCoords.z

			existing.coords = nextCoords
		end

		local headingChanged = false
		if stash.heading ~= nil then
			headingChanged = existing.heading ~= stash.heading
			existing.heading = stash.heading
		end

		existing.label = stash.label or existing.label
		existing.model = stash.model or existing.model
		existing.targetRadius = stash.targetRadius or existing.targetRadius
		existing.targetDistance = stash.targetDistance or existing.targetDistance
		existing.spawnRange = stash.spawnRange or existing.spawnRange
		existing.slots = stash.slots or existing.slots
		existing.maxWeight = stash.maxWeight or existing.maxWeight

		StashMoving[stash.id] = nil

		if coordsChanged or headingChanged then
			setupTargetInteractions(stash.id, existing)
			deleteStashProp(stash.id)
			ensureStashProp(stash.id, existing)
		end
	else
		registerStash(stash.id, stash)
	end
end)

CreateThread(function()
	TriggerServerEvent('ox_inventory:stashes:requestStashes')
end)

RegisterNetEvent('ox_inventory:setPlayerInventory', function()
	TriggerServerEvent('ox_inventory:stashes:requestStashes')
	TriggerServerEvent('ox_inventory:stashes:refreshPermissions')
end)

RegisterNUICallback('stashPermissions:open', function(data, cb)
	local payload, err = openStashPermissionsUI(data and data.stashId, { focus = false })
	cb({
		ok = payload ~= nil,
		error = err,
	})
end)

RegisterNUICallback('stashPermissions:createRole', function(data, cb)
	local payload = lib.callback.await('ox_inventory:stashes:createRole', false, data)
	if payload then
		cb('ok')
		SendNUIMessage({ action = 'openStashPermissions', data = payload })
	else
		cb('error')
	end
end)

RegisterNUICallback('stashPermissions:updateRole', function(data, cb)
	local payload = lib.callback.await('ox_inventory:stashes:updateRole', false, data)
	if payload then
		cb('ok')
		SendNUIMessage({ action = 'openStashPermissions', data = payload })
	else
		cb('error')
	end
end)

RegisterNUICallback('stashPermissions:deleteRole', function(data, cb)
	local payload = lib.callback.await('ox_inventory:stashes:deleteRole', false, data)
	if payload then
		cb('ok')
		SendNUIMessage({ action = 'openStashPermissions', data = payload })
	else
		cb('error')
	end
end)

RegisterNUICallback('stashPermissions:setMemberRole', function(data, cb)
	if data and data.identifier and not data.target then
		data.target = data.identifier
	end

	local payload = lib.callback.await('ox_inventory:stashes:setMemberRole', false, data)
	if payload then
		cb('ok')
		SendNUIMessage({ action = 'openStashPermissions', data = payload })
	else
		cb('error')
	end
end)

RegisterNUICallback('stashPermissions:transferOwnership', function(data, cb)
	local payload = lib.callback.await('ox_inventory:stashes:transferOwnership', false, data)
	if payload then
		cb('ok')
		SendNUIMessage({ action = 'openStashPermissions', data = payload })
	else
		cb('error')
	end
end)

RegisterNUICallback('stashPermissions:close', function(_, cb)
	SetNuiFocus(false, false)
	cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName ~= currentResource then return end

	for stashId in pairs(DynamicStashes) do
		removeTargetZone(stashId)
		removeStashPoint(stashId)
		removeStashTarget(stashId)
		deleteStashProp(stashId)
	end
end)
