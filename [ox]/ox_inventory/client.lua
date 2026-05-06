if not lib then return end

require 'modules.bridge.client'
require 'modules.interface.client'
require 'modules.injury.client'
require 'modules.placeable_stashes.client'
local Items = require 'modules.items.client'

local Utils = require 'modules.utils.client'
local Weapon = require 'modules.weapon.client'
local currentWeapon
local weaponTimer = 0

client.utility = client.utility or lib.load('data.utility') or {}
client.rarity = client.rarity or lib.load('data.rarity') or {}


exports('getCurrentWeapon', function()
	return currentWeapon
end)

RegisterNetEvent('ox_inventory:disarm', function(noAnim)
	currentWeapon = Weapon.Disarm(currentWeapon, noAnim)
end)

RegisterNetEvent('ox_inventory:clearWeapons', function()
	Weapon.ClearAll(currentWeapon)
end)

local StashTarget

exports('setStashTarget', function(id, owner)
	StashTarget = id and {id=id, owner=owner}
end)

---@type boolean | number
local invBusy = true

---@type boolean?
local invOpen = false
local plyState = LocalPlayer.state
local IsPedCuffed = IsPedCuffed
local playerPed = cache.ped
local dropObjects = {}
local dropObjectsByNetId = {}
client.dropObjects = dropObjects
client.dropObjectsByNetId = dropObjectsByNetId

local function slotMatchesUtility(itemName, slot)
	if not itemName then return true end

	local util = client.utility or {}
	local maxSlots = util.slots or 0

	if maxSlots > 0 and (not slot or slot > maxSlots) then
		return true
	end

	local allowed = util.items and util.items[slot]

	if not allowed or next(allowed) == nil then
		return true
	end

	itemName = itemName:lower()

	for i = 1, #allowed do
		if itemName == allowed[i]:lower() then
			return true
		end
	end

	return false
end

local lastArmour = 0
local backpackAppearanceState = {
	applied = false,
	itemName = nil,
}
local syncPlayerBackpackAppearance

lib.onCache('ped', function(ped)
	playerPed = ped
	Utils.WeaponWheel()
    lastArmour = GetPedArmour(playerPed)

	CreateThread(function()
		Wait(250)
		if syncPlayerBackpackAppearance then
			syncPlayerBackpackAppearance(true)
		end
	end)
end)

CreateThread(function()
	while true do
		local intervals = client.utility and client.utility.backpackAppearancePollInterval or {}
		Wait(backpackAppearanceState.applied and (tonumber(intervals.equipped) or 1000) or (tonumber(intervals.idle) or 2500))

		if PlayerData.loaded and syncPlayerBackpackAppearance then
			syncPlayerBackpackAppearance()
		end
	end
end)

CreateThread(function()
    while true do
        Wait(tonumber(client.utility and client.utility.armorDamagePollInterval) or 200)
        local currentArmour = GetPedArmour(playerPed)
        
        if currentArmour < lastArmour then
            TriggerServerEvent('ox_inventory:damageArmour', currentArmour)
        end
        
        lastArmour = currentArmour
    end
end)

plyState:set('invBusy', true, true)
plyState:set('invHotkeys', false, false)
plyState:set('canUseWeapons', false, false)

local function syncEsxAliveDesync()
	-- PlayerData.dead is normally synced from the state bag; if the bag stays true while ESX already cleared
	-- death after revive/spawn, inventory stays blocked until bag matches. Align when ESX + ped agree you're alive.
	if shared.framework ~= 'esx' then return end
	local ok, esx = pcall(function()
		return exports['es_extended']:getSharedObject()
	end)
	if not ok or not esx or not esx.PlayerData or esx.PlayerData.dead then return end
	if IsPedFatallyInjured(playerPed) or IsPedDeadOrDying(playerPed, true) then return end
	if PlayerData.dead then
		PlayerData.dead = false
		pcall(function()
			LocalPlayer.state:set('dead', false, true)
		end)
	end
end

local function canOpenInventory()
    if not PlayerData.loaded then
        return shared.info('cannot open inventory', '(player inventory has not loaded)')
    end

    if IsPauseMenuActive() then return end

    if invBusy or invOpen == nil or (currentWeapon?.timer or 0) > 0 then
        return shared.info('cannot open inventory', '(is busy)')
    end

	syncEsxAliveDesync()

    if PlayerData.dead or IsPedFatallyInjured(playerPed) then
        return shared.info('cannot open inventory', '(fatal injury)')
    end

    if PlayerData.cuffed or IsPedCuffed(playerPed) then
        return shared.info('cannot open inventory', '(cuffed)')
    end

    return true
end

---@param ped number
---@return boolean
local function canOpenTarget(ped)
	return IsPedFatallyInjured(ped)
	or IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3)
	or IsPedCuffed(ped)
	or IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
	or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 3)
	or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_enter', 3)
	or IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3)
end

local defaultInventory = {
	type = 'newdrop',
	slots = shared.dropslots,
	weight = 0,
	maxWeight = shared.dropweight,
	items = {}
}

local currentInventory = defaultInventory
local lastOwnerBackpackInventoryId = nil
local lastTargetBackpackInventoryId = nil
local giveDragState = {
	active = false,
	targetPed = nil,
	targetServerId = nil,
}
local giveDragDistance = 3.0
local giveDragMinHalfWidth = 0.03
local giveDragMinHalfHeight = 0.05
local weaponEditorSlotMeta = {
	ammo = { label = 'Ammo', icon = 'local_fire_department', order = 10 },
	flashlight = { label = 'Flashlight', icon = 'flashlight_on', order = 20 },
	muzzle = { label = 'Muzzle', icon = 'adjust', order = 30 },
	grip = { label = 'Grip', icon = 'back_hand', order = 40 },
	barrel = { label = 'Barrel', icon = 'swap_horiz', order = 50 },
	magazine = { label = 'Magazine', icon = 'view_agenda', order = 60 },
	sight = { label = 'Sight', icon = 'center_focus_strong', order = 70 },
}

local function titleCase(value)
	return value and value:gsub('^%l', string.upper) or value
end

local function getWeaponEditorSpecialClip(model, ammoType)
	if type(ammoType) ~= 'string' then return end

	local clipComponentKey = ('%s_CLIP'):format((model or ''):gsub('WEAPON_', 'COMPONENT_'))

	return ('%s_%s'):format(clipComponentKey, ammoType:upper())
end

local function getWeaponEditorComponentHash(weaponHash, componentName)
	local componentData = Items(componentName)
	local components = componentData?.client?.component

	if not components then return end

	for i = 1, #components do
		local componentHash = components[i]

		if DoesWeaponTakeWeaponComponent(weaponHash, componentHash) then
			return componentHash
		end
	end
end

local function buildWeaponEditorSlots(weaponData)
	local slots = {}
	local grouped = {}

	if weaponData.ammoname then
		slots[#slots + 1] = {
			key = 'ammo',
			kind = 'ammo',
			label = weaponEditorSlotMeta.ammo.label,
			icon = weaponEditorSlotMeta.ammo.icon,
			ammoName = weaponData.ammoname,
			order = weaponEditorSlotMeta.ammo.order,
		}
	end

	for _, itemData in pairs(Items()) do
		if itemData.component and itemData.type and itemData.client?.component then
			for i = 1, #itemData.client.component do
				if DoesWeaponTakeWeaponComponent(weaponData.hash, itemData.client.component[i]) then
					local slotMeta = weaponEditorSlotMeta[itemData.type] or {
						label = titleCase(itemData.type),
						icon = 'extension',
						order = 80,
					}

					if not grouped[itemData.type] then
						grouped[itemData.type] = {
							key = itemData.type,
							kind = 'component',
							label = slotMeta.label,
							icon = slotMeta.icon,
							componentType = itemData.type,
							compatible = {},
							order = slotMeta.order,
						}
					end

					grouped[itemData.type].compatible[#grouped[itemData.type].compatible + 1] = itemData.name
					break
				end
			end
		end
	end

	for _, slotData in pairs(grouped) do
		table.sort(slotData.compatible, function(a, b)
			local aData = Items(a)
			local bData = Items(b)
			local aLabel = aData and aData.label or a
			local bLabel = bData and bData.label or b

			return aLabel < bLabel
		end)

		slots[#slots + 1] = slotData
	end

	table.sort(slots, function(a, b)
		if a.order == b.order then
			return a.label < b.label
		end

		return a.order < b.order
	end)

	for i = 1, #slots do
		slots[i].order = nil
	end

	return slots
end

local function getWeaponEditorAmmoCapacity(weapon, weaponData)
	if not weaponData.ammoname then return 0 end

	local selectedWeapon = GetSelectedPedWeapon(playerPed)

	if currentWeapon and currentWeapon.slot == weapon.slot then
		local clipSize = GetMaxAmmoInClip(playerPed, weaponData.hash, true)
		local _, maxAmmo = GetMaxAmmo(playerPed, weaponData.hash)

		if maxAmmo and maxAmmo > 0 and (clipSize == 0 or maxAmmo < clipSize) then
			clipSize = maxAmmo
		end

		return clipSize
	end

	if currentWeapon and currentWeapon.hash == weaponData.hash then
		local clipSize = GetMaxAmmoInClip(playerPed, weaponData.hash, true)
		local _, maxAmmo = GetMaxAmmo(playerPed, weaponData.hash)

		if maxAmmo and maxAmmo > 0 and (clipSize == 0 or maxAmmo < clipSize) then
			clipSize = maxAmmo
		end

		return clipSize
	end

	local hadWeapon = HasPedGotWeapon(playerPed, weaponData.hash, false)
	local previousAmmo = hadWeapon and GetAmmoInPedWeapon(playerPed, weaponData.hash) or 0
	local addedWeapon = false
	local addedComponents = {}
	local addedSpecialClip

	if not hadWeapon then
		GiveWeaponToPed(playerPed, weaponData.hash, 0, false, false)
		addedWeapon = true
	end

	if weapon.metadata?.components then
		for i = 1, #weapon.metadata.components do
			local componentHash = getWeaponEditorComponentHash(weaponData.hash, weapon.metadata.components[i])

			if componentHash and not HasPedGotWeaponComponent(playerPed, weaponData.hash, componentHash) then
				GiveWeaponComponentToPed(playerPed, weaponData.hash, componentHash)
				addedComponents[#addedComponents + 1] = componentHash
			end
		end
	end

	if weapon.metadata?.specialAmmo then
		local specialClip = getWeaponEditorSpecialClip(weaponData.model or weapon.name, weapon.metadata.specialAmmo)

		if specialClip and DoesWeaponTakeWeaponComponent(weaponData.hash, specialClip) and not HasPedGotWeaponComponent(playerPed, weaponData.hash, specialClip) then
			GiveWeaponComponentToPed(playerPed, weaponData.hash, specialClip)
			addedSpecialClip = specialClip
		end
	end

	local clipSize = GetMaxAmmoInClip(playerPed, weaponData.hash, true)
	local _, maxAmmo = GetMaxAmmo(playerPed, weaponData.hash)

	if maxAmmo and maxAmmo > 0 and (clipSize == 0 or maxAmmo < clipSize) then
		clipSize = maxAmmo
	end

	for i = 1, #addedComponents do
		RemoveWeaponComponentFromPed(playerPed, weaponData.hash, addedComponents[i])
	end

	if addedSpecialClip then
		RemoveWeaponComponentFromPed(playerPed, weaponData.hash, addedSpecialClip)
	end

	if addedWeapon then
		RemoveWeaponFromPed(playerPed, weaponData.hash)
	elseif previousAmmo then
		SetPedAmmo(playerPed, weaponData.hash, previousAmmo)
	end

	if selectedWeapon then
		SetCurrentPedWeapon(playerPed, selectedWeapon, true)
	end

	return clipSize
end

local function applyWeaponEditorSpecialAmmo(weaponData, weaponSlot, previousType, nextType)
	if not currentWeapon or currentWeapon.slot ~= weaponSlot or previousType == nextType then return end

	local previousClip = getWeaponEditorSpecialClip(weaponData.model or weaponData.name, previousType)

	if previousClip and HasPedGotWeaponComponent(playerPed, currentWeapon.hash, previousClip) then
		RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, previousClip)
	end

	local nextClip = getWeaponEditorSpecialClip(weaponData.model or weaponData.name, nextType)

	if nextClip and DoesWeaponTakeWeaponComponent(currentWeapon.hash, nextClip) and not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, nextClip) then
		GiveWeaponComponentToPed(playerPed, currentWeapon.hash, nextClip)
	end
end

local function sendGiveDragState(serverId, targetName)
	if serverId and not targetName then
		local playerId = GetPlayerFromServerId(serverId)

		if playerId and playerId ~= -1 then
			targetName = GetPlayerName(playerId)
		end
	end

	SendNUIMessage({
		action = 'giveDragTarget',
		data = {
			active = giveDragState.active,
			valid = serverId ~= nil,
			targetId = serverId,
			targetName = targetName,
		}
	})
end

local function clearGiveDragTarget(ped)
	if ped and DoesEntityExist(ped) then
		ResetEntityAlpha(ped)
		SetEntityDrawOutline(ped, false)
		pcall(function()
			SetEntityDrawOutlineShader(0)
		end)
	end
end

local function setGiveDragTarget(serverId, ped, targetName)
	if giveDragState.targetServerId == serverId and giveDragState.targetPed == ped then
		sendGiveDragState(serverId, targetName)
		return
	end

	clearGiveDragTarget(giveDragState.targetPed)

	giveDragState.targetServerId = serverId
	giveDragState.targetPed = ped

	if ped and DoesEntityExist(ped) then
		SetEntityAlpha(ped, 150, false)
	end

	sendGiveDragState(serverId, targetName)
end

local function canHoverGiveTarget(ped)
	if not ped or ped == 0 or not DoesEntityExist(ped) or not IsEntityVisible(ped) then
		return false
	end

	if cache.vehicle and GetVehiclePedIsIn(ped, false) == cache.vehicle then
		return true
	end

	return HasEntityClearLosToEntity(playerPed, ped, 17)
end

local function getPedScreenBounds(ped)
	local headCoords = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.15)
	local feetCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -1.0)
	local headVisible, headX, headY = GetScreenCoordFromWorldCoord(headCoords.x, headCoords.y, headCoords.z)
	local feetVisible, feetX, feetY = GetScreenCoordFromWorldCoord(feetCoords.x, feetCoords.y, feetCoords.z)

	if not headVisible or not feetVisible then return end

	local centerX = (headX + feetX) * 0.5
	local centerY = (headY + feetY) * 0.5
	local halfHeight = math.max(math.abs(feetY - headY) * 0.55, giveDragMinHalfHeight)
	local halfWidth = math.max(halfHeight * 0.55, giveDragMinHalfWidth)

	return centerX, centerY, halfWidth, halfHeight
end

local function resolveGiveDragTarget()
	if not invOpen or not IsNuiFocused() then return end

	local cursorX, cursorY = GetNuiCursorPosition()
	local screenWidth, screenHeight = GetActiveScreenResolution()

	if not cursorX or not cursorY or not screenWidth or not screenHeight or screenWidth == 0 or screenHeight == 0 then
		return
	end

	local targetX = cursorX / screenWidth
	local targetY = cursorY / screenHeight
	local nearbyPlayers = GetActivePlayers()
	local bestScore, bestServerId, bestPed, bestName

	for i = 1, #nearbyPlayers do
		local playerId = nearbyPlayers[i]

		if playerId ~= cache.playerId then
			local ped = GetPlayerPed(playerId)

			if ped ~= 0 and DoesEntityExist(ped) then
				local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(ped))

				if distance <= giveDragDistance and canHoverGiveTarget(ped) then
					local centerX, centerY, halfWidth, halfHeight = getPedScreenBounds(ped)

					if centerX
						and targetX >= centerX - halfWidth
						and targetX <= centerX + halfWidth
						and targetY >= centerY - halfHeight
						and targetY <= centerY + halfHeight then
						local score = math.abs(targetX - centerX) + math.abs(targetY - centerY) + (distance * 0.01)

						if not bestScore or score < bestScore then
							bestScore = score
							bestServerId = GetPlayerServerId(playerId)
							bestPed = ped
							bestName = GetPlayerName(playerId)
						end
					end
				end
			end
		end
	end

	return bestServerId, bestPed, bestName
end

local function stopGiveDragTargeting()
	if not giveDragState.active and not giveDragState.targetPed then return end

	giveDragState.active = false
	clearGiveDragTarget(giveDragState.targetPed)
	giveDragState.targetPed = nil
	giveDragState.targetServerId = nil
	sendGiveDragState()
end

local function startGiveDragTargeting()
	if giveDragState.active then return end

	giveDragState.active = true
	sendGiveDragState()

	CreateThread(function()
		while giveDragState.active and invOpen do
			local serverId, ped, targetName = resolveGiveDragTarget()
			setGiveDragTarget(serverId, ped, targetName)
			Wait(0)
		end

		if giveDragState.active then
			stopGiveDragTargeting()
		end
	end)
end

local function closeTrunk()
	if currentInventory?.type == 'trunk' then
		local coords = GetEntityCoords(playerPed, true)
		---@todo animation for vans?
		Utils.PlayAnimAdvanced(0, 'anim@heists@fleeca_bank@scope_out@return_case', 'trevor_action', coords.x, coords.y, coords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, 1000, 49, 0.25)

		CreateThread(function()
			local entity = currentInventory.entity
			local door = currentInventory.door
			Wait(900)

			if type(door) == 'table' then
				for i = 1, #door do
					SetVehicleDoorShut(entity, door[i], false)
				end
			else
				SetVehicleDoorShut(entity, door, false)
			end
		end)
	end
end

local CraftingBenches = require 'modules.crafting.client'
local Vehicles = lib.load('data.vehicles')
local Inventory = require 'modules.inventory.client'

---@param inv string?
---@param data any?
---@return boolean?
function client.openInventory(inv, data)
	if invOpen then
		if not inv and currentInventory.type == 'newdrop' then
			return client.closeInventory()
		end

		if IsNuiFocused() then
			if inv == 'container' and currentInventory.id == PlayerData.inventory[data].metadata.container then
				return client.closeInventory()
			end

			if currentInventory.type == 'drop' and (not data or currentInventory.id == (type(data) == 'table' and data.id or data)) then
				return client.closeInventory()
			end

			if inv ~= 'drop' and inv ~= 'container' then
				if (data?.id or data) == currentInventory?.id then
					return warn(("script tried to open inventory, but it is already open\n%s"):format(Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())))
				else
					return client.closeInventory()
				end
			end
		end
	elseif IsNuiFocused() then
		Wait(100)

	end

	if inv == 'dumpster' and cache.vehicle then
		return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
	end

	if not canOpenInventory() then
        return lib.notify({ id = 'inventory_player_access', type = 'error', description = locale('inventory_player_access') })
    end

    local left, right, backpacks, accessError

    if inv == 'player' and data ~= cache.serverId then
        local targetId, targetPed, serverId

        if not data then
            targetId, targetPed = Utils.GetClosestPlayer()
            serverId = targetId and GetPlayerServerId(targetId)
            data = serverId
        else
            serverId = type(data) == 'table' and data.id or data
            targetId = serverId and GetPlayerFromServerId(serverId)
            targetPed = targetId and GetPlayerPed(targetId)
        end

        if serverId == cache.serverId then return end

        local targetCoords = targetPed and GetEntityCoords(targetPed)

        if not targetCoords or #(targetCoords - GetEntityCoords(playerPed)) > 1.8 or (not client.hasGroup(shared.police) and not Player(serverId).state.canSteal) then
            return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
        end
    end

    if inv == 'shop' and invOpen == false then
        if cache.vehicle then
            return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
        end

        left, right, accessError = lib.callback.await('ox_inventory:openShop', 200, data)
    elseif inv == 'crafting' then
        if cache.vehicle then
            return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
        end

        left, right, accessError = lib.callback.await('ox_inventory:openCraftingBench', 200, data.id, data.index)

        if left then
            backpacks = {
                backpackInventory = lib.callback.await('ox_inventory:getBackpack', false) or false,
                targetBackpackInventory = false
            }

            right = CraftingBenches[data.id]

            if not right?.items then return end

            local coords, distance

            if not right.zones and not right.points then
                coords = GetEntityCoords(cache.ped)
                distance = 2
            else
                coords = shared.target and right.zones and right.zones[data.index].coords or right.points and right.points[data.index]
                distance = coords and shared.target and right.zones[data.index].distance or 2
            end

            right = {
                type = 'crafting',
                id = data.id,
                label = right.label or locale('crafting_bench'),
                index = data.index,
                slots = right.slots,
                items = right.items,
                crafting = left.crafting,
                coords = coords,
                distance = distance
            }
        end
    elseif invOpen ~= nil then
        if inv == 'policeevidence' then
            if not data then
                local input = lib.inputDialog(locale('police_evidence'), {
                    { label = locale('locker_number'), type = 'number', required = true, icon = 'calculator' }
                }) --[[@as number[]? ]]

                if not input then return end

                data = input[1]
            end
        end

        left, right, backpacks, accessError = lib.callback.await('ox_inventory:openInventory', false, inv, data)

        if left == false then
            accessError = backpacks
            backpacks = nil
        end
    end

    if accessError then
        return lib.notify({ id = accessError, type = 'error', description = locale(accessError) })
    end

    if left and left.id and left.id ~= cache.serverId then
        return
    end

    -- Stash does not exist
    if not left then
        if left == false then return false end

        if invOpen == false then
            return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
        end

        if invOpen then return client.closeInventory() end
    end


    if not cache.vehicle then
        if inv == 'player' then
            Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 8.0, 1.0, 2000, 50, 0.0, 0, 0, 0)
        elseif inv ~= 'trunk' then
            Utils.PlayAnim(0, 'pickup_object', 'putdown_low', 5.0, 1.5, 1000, 48, 0.0, 0, 0, 0)
        end
    end

    plyState.invOpen = true

    SetInterval(client.interval, 100)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    closeTrunk()

    if client.screenblur then Utils.blurIn() end

    currentInventory = right or defaultInventory
    if currentInventory and (currentInventory.type == 'shop' or currentInventory.type == 'crafting') then
        currentInventory.ignoreSecurityChecks = true
    end
    left.items = PlayerData.inventory
    left.groups = PlayerData.groups

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory,
			backpackInventory = backpacks and backpacks.backpackInventory or false,
			targetBackpackInventory = backpacks and backpacks.targetBackpackInventory or false
		}
	})
	lastOwnerBackpackInventoryId = backpacks and backpacks.backpackInventory and backpacks.backpackInventory.id or nil
	lastTargetBackpackInventoryId = backpacks and backpacks.targetBackpackInventory and backpacks.targetBackpackInventory.id or nil

	if GetResourceState('qbx_core') == 'started' then
        local pData = exports.qbx_core:GetPlayerData()
        if pData then
            SendNUIMessage({
                action = 'setPlayerData',
                data = {
                    name = (pData.charinfo and pData.charinfo.firstname and pData.charinfo.lastname) and (pData.charinfo.firstname .. ' ' .. pData.charinfo.lastname) or (pData.name or 'Unknown'),
                    job = pData.job and pData.job.label or 'Unemployed',
                    gang = pData.gang and pData.gang.label or 'none',
                    cash = pData.money and pData.money.cash or 0,
                    bank = pData.money and pData.money.bank or 0
                }
            })
        end
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local pData = QBCore.Functions.GetPlayerData()
        if pData then
            SendNUIMessage({
                action = 'setPlayerData',
                data = {
                    name = (pData.charinfo and pData.charinfo.firstname and pData.charinfo.lastname) and (pData.charinfo.firstname .. ' ' .. pData.charinfo.lastname) or (pData.name or 'Unknown'),
                    job = pData.job and pData.job.label or 'Unemployed',
                    gang = pData.gang and pData.gang.label or 'none',
                    cash = pData.money and pData.money.cash or 0,
                    bank = pData.money and pData.money.bank or 0
                }
            })
        end
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local pData = ESX.GetPlayerData()
        if pData then
            local cash, bank = 0, 0
            if pData.accounts then
                for _, acc in ipairs(pData.accounts) do
                    if acc.name == 'money' then cash = acc.money end
                    if acc.name == 'bank' then bank = acc.money end
                end
            end
            SendNUIMessage({
                action = 'setPlayerData',
                data = {
                    name = (pData.firstName and pData.lastName) and (pData.firstName .. ' ' .. pData.lastName) or pData.name or 'Unknown',
                    job = pData.job and pData.job.label or 'Unemployed',
                    gang = 'none',
                    cash = cash,
                    bank = bank
                }
            })
        end
    end

    if not currentInventory.coords and not inv == 'container' then
        currentInventory.coords = GetEntityCoords(playerPed)
    end

    if inv == 'trunk' then
        SetTimeout(200, function()
            ---@todo animation for vans?
            Utils.PlayAnim(0, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 3.0, 3.0, -1, 49, 0.0, 0, 0, 0)

            local entity = data.entity or NetworkGetEntityFromNetworkId(data.netid)
            currentInventory.entity = entity
            currentInventory.door = data.door

            if not currentInventory.door then
                local vehicleHash = GetEntityModel(entity)
                local vehicleClass = GetVehicleClass(entity)
                currentInventory.door = vehicleClass == 12 and { 2, 3 } or Vehicles.Storage[vehicleHash] and 4 or 5
            end

            while currentInventory?.entity == entity and invOpen and DoesEntityExist(entity) and Inventory.CanAccessTrunk(entity) do
                Wait(100)
            end

            if invOpen then client.closeInventory() end
        end)
    end

    return true
end

RegisterNetEvent('ox_inventory:openInventory', client.openInventory)
exports('openInventory', client.openInventory)

RegisterNetEvent('ox_inventory:forceOpenInventory', function(left, right, backpacks)
	if source == '' then return end

	if left and left.id ~= cache.serverId then return end

	plyState.invOpen = true

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	if client.screenblur then Utils.blurIn() end

	currentInventory = right or defaultInventory
	currentInventory.ignoreSecurityChecks = true
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory,
			backpackInventory = backpacks and backpacks.backpackInventory or false,
			targetBackpackInventory = backpacks and backpacks.targetBackpackInventory or false
		}
	})
	lastOwnerBackpackInventoryId = backpacks and backpacks.backpackInventory and backpacks.backpackInventory.id or nil
	lastTargetBackpackInventoryId = backpacks and backpacks.targetBackpackInventory and backpacks.targetBackpackInventory.id or nil
end)

local Animations = lib.load('data.animations')
local usingItem = false

---@param data { name: string, label: string, count: number, slot: number, metadata: table<string, any>, weight: number }
lib.callback.register('ox_inventory:usingItem', function(data, noAnim)
	local item = Items[data.name]

	if item and usingItem then
		if not item.client then return true end
		---@cast item +OxClientProps
		item = item.client

		if type(item.anim) == 'string' then
			item.anim = Animations.anim[item.anim]
		end

		if item.prop then
			if item.prop[1] then
				for i = 1, #item.prop do
					if type(item.prop) == 'string' then
						item.prop = Animations.prop[item.prop[i]]
					end
				end
			elseif type(item.prop) == 'string' then
				item.prop = Animations.prop[item.prop]
			end
		end

		if not item.disable then
			item.disable = { combat = true }
		elseif item.disable.combat == nil then
			item.disable.combat = true
		end

		local success = (not item.usetime or noAnim or lib.progressBar({
			duration = item.usetime,
			label = item.label or locale('using', data.metadata.label or data.label),
			useWhileDead = item.useWhileDead,
			canCancel = item.cancel,
			disable = item.disable,
			anim = item.anim or item.scenario,
			prop = item.prop --[[@as ProgressProps]]
		})) and not PlayerData.dead

		if success then
			if item.notification then
				lib.notify({ description = item.notification })
			end

			if item.status then
				if client.setPlayerStatus then
					client.setPlayerStatus(item.status)
				end
			end

			return true
		end
	end
end)

local function canUseItem(isAmmo)
	local ped = cache.ped

	return not usingItem
    and (not isAmmo or currentWeapon)
	and PlayerData.loaded
	and not PlayerData.dead
	and not invBusy
	and not lib.progressActive()
	and not IsPedRagdoll(ped)
	and not IsPedFalling(ped)
    and not IsPedShooting(playerPed)
end

---@param data table
---@param cb fun(response: SlotWithItem | false)?
---@param noAnim? boolean
local function useItem(data, cb, noAnim)
	local slotData
    if data.inventoryId and data.inventoryId ~= cache.serverId then
        if currentInventory and currentInventory.id == data.inventoryId then
            slotData = currentInventory.items[data.slot]
        end
    else
	    slotData = PlayerData.inventory[data.slot]
    end
	if (not slotData and not data.inventoryId) or not canUseItem(data.ammo and true) then
        if currentWeapon then
            return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
        end

        return
    end

	if currentWeapon and currentWeapon.timer ~= 0 then
        if not currentWeapon.timer or currentWeapon.timer - GetGameTimer() > 100 then return end

        DisablePlayerFiring(cache.playerId, true)
    end

    if invOpen and data.close then client.closeInventory() end

    if not data.inventoryId and not slotMatchesUtility(data.name, data.slot) then
		return
	end 

    usingItem = true
    ---@type boolean?
    local result = lib.callback.await('ox_inventory:useItem', 200, data.name, data.slot, slotData and slotData.metadata, noAnim, data.inventoryId)

	if result and cb then
		local success, response = pcall(cb, result and (slotData or data))

		if not success and response then
			warn(('^1An error occurred while calling item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(data.name, response))
		end
	end

    if result then
        TriggerEvent('ox_inventory:usedItem', data.name, data.slot, slotData and next(slotData.metadata) and slotData.metadata, data.inventoryId)
    end

	Wait(500)
    usingItem = false
end

AddEventHandler('ox_inventory:usedItem', function(name, slot, metadata, inventoryId)
    TriggerServerEvent('ox_inventory:usedItemInternal', slot, inventoryId)
end)

AddEventHandler('ox_inventory:item', useItem)
exports('useItem', useItem)

---@param slot number
---@return boolean?
local function useSlot(slot, noAnim)
    local item, inventoryId
    if type(slot) == 'table' then
        inventoryId = slot.inventoryId
        item = (inventoryId and inventoryId ~= cache.serverId and currentInventory and currentInventory.id == inventoryId) and currentInventory.items[slot.slot] or PlayerData.inventory[slot.slot]
        slot = slot.slot
    else
        item = PlayerData.inventory[slot]
    end

	if not item then return end

	local data = Items[item.name]
	if not data then return end

	if canUseItem(data.ammo and true) then
		if data.component and not currentWeapon then
			return lib.notify({ id = 'weapon_hand_required', type = 'error', description = locale('weapon_hand_required') })
		end

		local durability = item.metadata.durability --[[@as number?]]
		local consume = data.consume --[[@as number?]]
		local label = item.metadata.label or item.label --[[@as string]]

		if durability and durability <= 100 and consume then
			if durability <= 0 then
				return lib.notify({ type = 'error', description = locale('no_durability', label) })
			elseif consume ~= 0 and consume < 1 and durability < consume * 100 then
				return lib.notify({ type = 'error', description = locale('not_enough_durability', label) })
			end
		end

		data.slot = slot
        data.inventoryId = inventoryId

		if item.metadata.container then
			return client.openInventory('container', item.slot)
		elseif data.client then
			if invOpen and data.close then client.closeInventory() end

			if data.export then
				return data.export(data, {name = item.name, slot = item.slot, metadata = item.metadata})
			elseif data.client.event then -- re-add it, so I don't need to deal with morons taking screenshots of errors when using trigger event
				return TriggerEvent(data.client.event, data, {name = item.name, slot = item.slot, metadata = item.metadata})
			end
		end

		if data.effect then
			data:effect({name = item.name, slot = item.slot, metadata = item.metadata})
		elseif data.weapon then
			if EnableWeaponWheel or not plyState.canUseWeapons then return end

			if IsCinematicCamRendering() then SetCinematicModeActive(false) end

			if currentWeapon then
                if not currentWeapon.timer or currentWeapon.timer ~= 0 then return end

				local weaponSlot = currentWeapon.slot
				currentWeapon = Weapon.Disarm(currentWeapon)

				if weaponSlot == data.slot then return end
			end

            GiveWeaponToPed(playerPed, data.hash, 0, false, true)
            SetCurrentPedWeapon(playerPed, data.hash, false)

            if data.hash ~= GetSelectedPedWeapon(playerPed) then
                lib.print.info(('failed to equip %s (cause unknown)'):format(item.name))
                return lib.notify({ type = 'error', description = locale('cannot_use', data.label) })
            end

            RemoveWeaponFromPed(cache.ped, data.hash)

			useItem(data, function(result)
				if result then
                    local sleep
					currentWeapon, sleep = Weapon.Equip(item, data, noAnim)

					if sleep then Wait(sleep) end
				end
			end, noAnim)
		elseif currentWeapon then
			if data.ammo then
				if EnableWeaponWheel or currentWeapon.metadata.durability <= 0 then return end

				local clipSize = GetMaxAmmoInClip(playerPed, currentWeapon.hash, true)
				local currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
				local _, maxAmmo = GetMaxAmmo(playerPed, currentWeapon.hash)

				if maxAmmo < clipSize then clipSize = maxAmmo end

				if currentAmmo == clipSize then return end

				useItem(data, function(resp)
					if not resp or resp.name ~= currentWeapon?.ammo then return end

					if currentWeapon.metadata.specialAmmo ~= resp.metadata.type and type(currentWeapon.metadata.specialAmmo) == 'string' then
						local clipComponentKey = ('%s_CLIP'):format(Items[currentWeapon.name].model:gsub('WEAPON_', 'COMPONENT_'))
						local specialClip = ('%s_%s'):format(clipComponentKey, (resp.metadata.type or currentWeapon.metadata.specialAmmo):upper())

						if type(resp.metadata.type) == 'string' then
							if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, specialClip) then
								if not DoesWeaponTakeWeaponComponent(currentWeapon.hash, specialClip) then
									warn('cannot use clip with this weapon')
									return
								end

								local defaultClip = ('%s_01'):format(clipComponentKey)

								if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, defaultClip) then
									warn('cannot use clip with currently equipped clip')
									return
								end

								if currentAmmo > 0 then
									warn('cannot mix special ammo with base ammo')
									return
								end

								currentWeapon.metadata.specialAmmo = resp.metadata.type

								GiveWeaponComponentToPed(playerPed, currentWeapon.hash, specialClip)
							end
						elseif HasPedGotWeaponComponent(playerPed, currentWeapon.hash, specialClip) then
							if currentAmmo > 0 then
								warn('cannot mix special ammo with base ammo')
								return
							end

							currentWeapon.metadata.specialAmmo = nil

							RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, specialClip)
						end
					end

					if maxAmmo > clipSize then
						clipSize = GetMaxAmmoInClip(playerPed, currentWeapon.hash, true)
					end

					currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
					local missingAmmo = clipSize - currentAmmo
					local addAmmo = resp.count > missingAmmo and missingAmmo or resp.count
					local newAmmo = currentAmmo + addAmmo

					if newAmmo == currentAmmo then return end

                    AddAmmoToPed(playerPed, currentWeapon.hash, addAmmo)

					if cache.vehicle then
						if cache.seat > -1 or IsVehicleStopped(cache.vehicle) then
							TaskReloadWeapon(playerPed, true)
                        else
                            lib.waitFor(function()
                                RefillAmmoInstantly(playerPed)

                                local _, ammo = GetAmmoInClip(playerPed, currentWeapon.hash)
                                return ammo == newAmmo or nil
                            end)
                        end
					else
						Wait(100)
						MakePedReload(playerPed)

						SetTimeout(100, function()
							while IsPedReloading(playerPed) do
								DisableControlAction(0, 22, true)
								Wait(0)
							end
						end)
					end

					lib.callback.await('ox_inventory:updateWeapon', false, 'load', newAmmo, false, currentWeapon.metadata.specialAmmo)
				end)
			elseif data.component then
				local components = data.client.component

                if not components then return end

				local componentType = data.type
				local weaponComponents = PlayerData.inventory[currentWeapon.slot].metadata.components

				for componentIndex = 1, #weaponComponents do
					if componentType == Items[weaponComponents[componentIndex]].type then
						return lib.notify({ id = 'component_slot_occupied', type = 'error', description = locale('component_slot_occupied', componentType) })
					end
				end

				for i = 1, #components do
					local component = components[i]

					if DoesWeaponTakeWeaponComponent(currentWeapon.hash, component) then
						if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
							lib.notify({ id = 'component_has', type = 'error', description = locale('component_has', label) })
						else
							useItem(data, function(data)
								if data then
									local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', tostring(data.slot), currentWeapon.slot)

									if success then
										GiveWeaponComponentToPed(playerPed, currentWeapon.hash, component)
										TriggerEvent('ox_inventory:updateWeaponComponent', 'added', component, data.name)
									end
								end
							end)
						end
						return
					end
				end
				lib.notify({ id = 'component_invalid', type = 'error', description = locale('component_invalid', label) })
			elseif data.allowArmed then
				useItem(data)
            else
                return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
			end
		elseif not data.ammo and not data.component then
			useItem(data)
		end
    end
end
exports('useSlot', useSlot)
RegisterNetEvent('ox_inventory:useSlot', useSlot)

---@param id number
---@param slot number
local function useButton(id, slot)
	if PlayerData.loaded and not invBusy and not lib.progressActive() then
		local item = PlayerData.inventory[slot]
		if not item then return end

		local data = Items[item.name]
		local buttons = data?.buttons

		if buttons and buttons[id]?.action then
			buttons[id].action(slot)
		end
	end
end

local function openNearbyInventory() client.openInventory('player') end

exports('openNearbyInventory', openNearbyInventory)

local currentInstance
local playerCoords
local Shops = require 'modules.shops.client'

---@todo remove or replace when the bridge module gets restructured
function OnPlayerData(key, val)
	if key ~= 'groups' and key ~= 'ped' and key ~= 'dead' then return end

	if key == 'groups' then
		Inventory.Stashes()
		Inventory.Evidence()
		Shops.refreshShops()
	elseif key == 'dead' and val then
		currentWeapon = Weapon.Disarm(currentWeapon)
		client.closeInventory()
	end

	Utils.WeaponWheel()
end

-- People consistently ignore errors when one of the "modules" failed to load
if not Utils or not Weapon or not Items or not Inventory then return end

local invHotkeys = false

---@type function?
local function registerCommands()
	if client.enablestealcommand then
		RegisterCommand('steal', openNearbyInventory, false)
	end

	local function openGlovebox(vehicle)
		if not IsPedInAnyVehicle(playerPed, false) or not NetworkGetEntityIsNetworked(vehicle) then return end

		if IsEntityDead(vehicle) then return end

		local vehicleHash = GetEntityModel(vehicle)
		local vehicleClass = GetVehicleClass(vehicle)
		local checkVehicle = Vehicles.Storage[vehicleHash]

		-- No storage or no glovebox
		if (checkVehicle == 0 or checkVehicle == 2) or (not Vehicles.glovebox[vehicleClass] and not Vehicles.glovebox.models[vehicleHash]) then return end

		local isOpen = client.openInventory('glovebox', { netid = NetworkGetNetworkIdFromEntity(vehicle) })

		if isOpen then
			currentInventory.entity = vehicle
		end
	end

	local primary = lib.addKeybind({
		name = 'inv',
		description = locale('open_player_inventory'),
		defaultKey = client.keys[1],
		onPressed = function()
			if invOpen then
				return client.closeInventory()
			end

			if cache.vehicle then
				return openGlovebox(cache.vehicle)
			end

			local closest = lib.points.getClosestPoint()

			if closest and closest.currentDistance < 1.2 and (not closest.instance or closest.instance == currentInstance) then
				if closest.inv == 'crafting' then
					return client.openInventory('crafting', { id = closest.id, index = closest.index })
				elseif closest.inv ~= 'license' and closest.inv ~= 'policeevidence' then
					return client.openInventory(closest.inv or 'drop', { id = closest.invId, type = closest.type })
				end
			end

			return client.openInventory()
		end
	})

	lib.addKeybind({
		name = 'inv2',
		description = locale('open_secondary_inventory'),
		defaultKey = client.keys[2],
		onPressed = function(self)
            if primary:getCurrentKey() == self:getCurrentKey() then
                return warn(("secondary inventory keybind '%s' disabled (keybind cannot match primary inventory keybind)"):format(self:getCurrentKey()))
            end

			if invOpen then
				return client.closeInventory()
			end

			if invBusy or not canOpenInventory() then
				return lib.notify({ id = 'inventory_player_access', type = 'error', description = locale('inventory_player_access') })
			end

			if StashTarget then
				return client.openInventory('stash', StashTarget)
			end

			if cache.vehicle then
				return openGlovebox(cache.vehicle)
			end

			local entity, entityType = Utils.Raycast(2|16)

			if not entity then return end

			if not shared.target and entityType == 3 then
				local model = GetEntityModel(entity)

				if Inventory.Dumpsters:includes(model) then
					return Inventory.OpenDumpster(entity)
				end
			end

			if entityType ~= 2 then return end

			Inventory.OpenTrunk(entity)
		end
	})

	lib.addKeybind({
		name = 'reloadweapon',
		description = locale('reload_weapon'),
		defaultKey = 'r',
		onPressed = function(self)
			if not currentWeapon or EnableWeaponWheel or not canUseItem(true) then return end

			if currentWeapon.ammo then
				if currentWeapon.metadata.durability > 0 then
					local slotId = Inventory.GetSlotIdWithItem(currentWeapon.ammo, { type = currentWeapon.metadata.specialAmmo }, false)

					if slotId then
						useSlot(slotId)
					end
				else
					lib.notify({ id = 'no_durability', type = 'error', description = locale('no_durability', currentWeapon.label) })
				end
			end
		end
	})

	lib.addKeybind({
		name = 'hotbar',
		description = locale('disable_hotbar'),
		defaultKey = client.keys[3],
		onPressed = function()
			if EnableWeaponWheel or not invHotkeys or IsNuiFocused() or lib.progressActive() then return end
			SendNUIMessage({ action = 'toggleHotbar' })
		end
	})

	for i = 1, 5 do
		lib.addKeybind({
			name = ('hotkey%s'):format(i),
			description = locale('use_hotbar', i),
			defaultKey = tostring(i),
			onPressed = function()
				if invOpen or EnableWeaponWheel or not invHotkeys or IsNuiFocused() then return end
				useSlot(i + 9)
			end
		})
	end

	registerCommands = nil
end

function client.closeInventory(server)
	stopGiveDragTargeting()

	if not client.interval then return end

	if invOpen then
		invOpen = nil
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
		Utils.blurOut()
		closeTrunk()
		SendNUIMessage({ action = 'closeInventory' })
		SetInterval(client.interval, 200)
		Wait(200)

		if invOpen ~= nil then return end

		if not server and currentInventory then
			TriggerServerEvent('ox_inventory:closeInventory')
		end

		currentInventory = nil
		lastOwnerBackpackInventoryId = nil
		lastTargetBackpackInventoryId = nil
		plyState.invOpen = false
		defaultInventory.coords = nil
	end
end

RegisterNetEvent('ox_inventory:closeInventory', client.closeInventory)
exports('closeInventory', client.closeInventory)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		stopGiveDragTargeting()
	end
end)

---@param data updateSlot[]
---@param weight number
local function getConfiguredBackpackSlotId()
	local backpackSlotId = client.utility and client.utility.backpackSlotFallback or 6

	if client.utility and client.utility.items and client.utility.backpackItems then
		for i, items in pairs(client.utility.items) do
			for _, itemName in ipairs(items) do
				if client.utility.backpackItems[itemName] then
					backpackSlotId = i
					break
				end
			end
		end
	end

	return backpackSlotId
end

local backpackAppearanceResource = client.utility and client.utility.backpackAppearanceResource or 'illenium-appearance'
local backpackComponentId = tonumber(client.utility and client.utility.backpackComponentId) or 5
local backpackBaseStateKey = 'oxInventoryBackpackBaseComponent'

local function isFreemodeAppearancePed(ped)
	local model = GetEntityModel(ped)
	return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

local function getBackpackAppearanceGender(ped)
	return GetEntityModel(ped) == `mp_f_freemode_01` and 'female' or 'male'
end

local function getStoredBackpackBaseComponent()
	local component = plyState[backpackBaseStateKey]

	if type(component) == 'table' and component.component_id == backpackComponentId then
		return {
			component_id = backpackComponentId,
			drawable = component.drawable or 0,
			texture = component.texture or 0,
		}
	end
end

local function setStoredBackpackBaseComponent(component)
	if component then
		plyState:set(backpackBaseStateKey, {
			component_id = backpackComponentId,
			drawable = component.drawable or 0,
			texture = component.texture or 0,
		}, false)
	else
		plyState:set(backpackBaseStateKey, false, false)
	end
end

local function getCurrentBackpackComponent(ped)
	if GetResourceState(backpackAppearanceResource) == 'started' then
		local ok, components = pcall(function()
			return exports[backpackAppearanceResource]:getPedComponents(ped)
		end)

		if ok and components then
			for i = 1, #components do
				local component = components[i]

				if component.component_id == backpackComponentId then
					return {
						component_id = backpackComponentId,
						drawable = component.drawable or 0,
						texture = component.texture or 0,
					}
				end
			end
		end
	end

	return {
		component_id = backpackComponentId,
		drawable = GetPedDrawableVariation(ped, backpackComponentId),
		texture = GetPedTextureVariation(ped, backpackComponentId),
	}
end

local function setCurrentBackpackComponent(ped, component)
	if not component then return end

	component = {
		component_id = backpackComponentId,
		drawable = component.drawable or 0,
		texture = component.texture or 0,
	}

	local applied = false

	if GetResourceState(backpackAppearanceResource) == 'started' then
		applied = pcall(function()
			exports[backpackAppearanceResource]:setPedComponent(ped, component)
		end)
	end

	if not applied then
		SetPedComponentVariation(ped, backpackComponentId, component.drawable, component.texture, 0)
	end
end

local function backpackComponentsEqual(componentA, componentB)
	return componentA
		and componentB
		and (componentA.component_id or backpackComponentId) == (componentB.component_id or backpackComponentId)
		and (componentA.drawable or 0) == (componentB.drawable or 0)
		and (componentA.texture or 0) == (componentB.texture or 0)
end

local function getConfiguredBackpackAppearance(itemName, ped)
	local backpackConfig = client.utility and client.utility.backpackItems and client.utility.backpackItems[itemName]
	local appearance = backpackConfig and backpackConfig.appearance

	if not appearance then return end

	local gender = getBackpackAppearanceGender(ped)
	local component = appearance[gender] or appearance.default or appearance

	if type(component) ~= 'table' then return end

	return {
		component_id = backpackComponentId,
		drawable = component.drawable or 0,
		texture = component.texture or 0,
	}
end

syncPlayerBackpackAppearance = function(forceApply)
	if not PlayerData.loaded or not PlayerData.inventory or not client.utility or not client.utility.backpackItems then return end
	if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) or not isFreemodeAppearancePed(playerPed) then return end

	local backpackSlotId = getConfiguredBackpackSlotId()
	local slotItem = PlayerData.inventory[backpackSlotId]
	local desiredComponent = slotItem and slotItem.name and client.utility.backpackItems[slotItem.name] and getConfiguredBackpackAppearance(slotItem.name, playerPed)

	if desiredComponent then
		local storedBaseComponent = getStoredBackpackBaseComponent()
		local currentComponent = getCurrentBackpackComponent(playerPed)

		if not storedBaseComponent then
			if backpackComponentsEqual(currentComponent, desiredComponent) then
				storedBaseComponent = {
					component_id = backpackComponentId,
					drawable = 0,
					texture = 0,
				}
			else
				storedBaseComponent = currentComponent
			end

			setStoredBackpackBaseComponent(storedBaseComponent)
		end

		if forceApply or not backpackComponentsEqual(currentComponent, desiredComponent) then
			setCurrentBackpackComponent(playerPed, desiredComponent)
		end

		backpackAppearanceState.applied = true
		backpackAppearanceState.itemName = slotItem.name
		return
	end

	local storedBaseComponent = getStoredBackpackBaseComponent()

	if storedBaseComponent then
		local currentComponent = getCurrentBackpackComponent(playerPed)

		if forceApply or not backpackComponentsEqual(currentComponent, storedBaseComponent) then
			setCurrentBackpackComponent(playerPed, storedBaseComponent)
		end
	end

	backpackAppearanceState.applied = false
	backpackAppearanceState.itemName = nil
	setStoredBackpackBaseComponent(nil)
end

local function syncOwnerBackpackPanel()
	if not invOpen or not client.utility or not client.utility.backpackItems then return end

	local backpackSlotId = getConfiguredBackpackSlotId()
	local item = PlayerData.inventory[backpackSlotId]

	if item and item.name and client.utility.backpackItems[item.name] then
		if not item.metadata or not item.metadata.container then
			return
		end

		if lastOwnerBackpackInventoryId == item.metadata.container then
			return
		end

		lib.callback('ox_inventory:getBackpack', false, function(backpack)
			if not invOpen then return end
			lastOwnerBackpackInventoryId = backpack and backpack.id or nil

			SendNUIMessage({
				action = 'setupInventory',
				data = {
					backpackInventory = backpack or false
				}
			})
		end)
	else
		lastOwnerBackpackInventoryId = nil
		SendNUIMessage({
			action = 'setupInventory',
			data = {
				backpackInventory = false
			}
		})
	end
end

local function syncTargetBackpackPanel()
	if not invOpen or currentInventory?.type ~= 'otherplayer' or not client.utility or not client.utility.backpackItems then return end

	local backpackSlotId = getConfiguredBackpackSlotId()
	local playerInventory = currentInventory.items
	local item = playerInventory and playerInventory[backpackSlotId]

	if item and item.name and client.utility.backpackItems[item.name] then
		if not item.metadata or not item.metadata.container then
			return
		end

		if lastTargetBackpackInventoryId == item.metadata.container then
			return
		end

		lib.callback('ox_inventory:getBackpack', false, function(backpack)
			if not invOpen or currentInventory?.type ~= 'otherplayer' then return end
			lastTargetBackpackInventoryId = backpack and backpack.id or nil

			SendNUIMessage({
				action = 'setupInventory',
				data = {
					targetBackpackInventory = backpack or false
				}
			})
		end, currentInventory.id)
	else
		lastTargetBackpackInventoryId = nil
		SendNUIMessage({
			action = 'setupInventory',
			data = {
				targetBackpackInventory = false
			}
		})
	end
end

local function updateInventory(data, weight)
	local changes = {}
    ---@type table<string, number>
	local itemCount = {}
	local playerInventoryUpdated = false
	local otherPlayerInventoryUpdated = false

	for i = 1, #data do
		local v = data[i]

		if not v.inventory or v.inventory == cache.serverId then
			v.inventory = 'player'
			playerInventoryUpdated = true
			local item = v.item

			if currentWeapon?.slot == item?.slot then
                if item.metadata then
				    currentWeapon.metadata = item.metadata
				    TriggerEvent('ox_inventory:currentWeapon', currentWeapon)
                else
                    currentWeapon = Weapon.Disarm(currentWeapon, true)
                end
			end

			local curItem = PlayerData.inventory[item.slot]

			if curItem and curItem.name then
				itemCount[curItem.name] = (itemCount[curItem.name] or 0) - curItem.count
			end

			if item.count then
				itemCount[item.name] = (itemCount[item.name] or 0) + item.count
			end

			changes[item.slot] = item.count and item or false
			if not item.count then item.name = nil end
			PlayerData.inventory[item.slot] = item.name and item or nil
		elseif currentInventory?.type == 'otherplayer' and v.inventory == currentInventory.id and client.utility and client.utility.backpackItems then
			otherPlayerInventoryUpdated = true
			local item = v.item
			currentInventory.items[item.slot] = item.name and item or nil
		end
	end

	if playerInventoryUpdated then
		syncOwnerBackpackPanel()
		syncPlayerBackpackAppearance()
	end

	if otherPlayerInventoryUpdated then
		syncTargetBackpackPanel()
	end

	SendNUIMessage({ action = 'refreshSlots', data = { items = data, itemCount = itemCount} })

    if weight ~= PlayerData.weight then client.setPlayerData('weight', weight) end

	for itemName, count in pairs(itemCount) do
		local item = Items(itemName)

        if item then
            item.count += count

            TriggerEvent('ox_inventory:itemCount', item.name, item.count)

            if count < 0 then
                if shared.framework == 'esx' then
                    TriggerEvent('esx:removeInventoryItem', item.name, item.count)
                end

                if item.client?.remove then
                    item.client.remove(item.count)
                end
            elseif count > 0 then
                if shared.framework == 'esx' then
                    TriggerEvent('esx:addInventoryItem', item.name, item.count)
                end

                if item.client?.add then
                    item.client.add(item.count)
                end
            end
        end
	end

	client.setPlayerData('inventory', PlayerData.inventory)
	TriggerEvent('ox_inventory:updateInventory', changes)
end

RegisterNetEvent('ox_inventory:updateSlots', function(items, weights)
	if source ~= '' and next(items) then updateInventory(items, weights) end
end)

RegisterNetEvent('ox_inventory:inventoryReturned', function(data)
	if source == '' then return end
	if currentWeapon then currentWeapon = Weapon.Disarm(currentWeapon) end

	lib.notify({ description = locale('items_returned') })
	client.closeInventory()

	local num, items = 0, {}

	for _, slotData in pairs(data[1]) do
		num += 1
		items[num] = { item = slotData, inventory = cache.serverId }
	end

	updateInventory(items, data[3])
end)

RegisterNetEvent('ox_inventory:inventoryConfiscated', function(message)
	if source == '' then return end
	if message then lib.notify({ description = locale('items_confiscated') }) end
	if currentWeapon then currentWeapon = Weapon.Disarm(currentWeapon) end

	client.closeInventory()

	local num, items = 0, {}

	for slot in pairs(PlayerData.inventory) do
		num += 1
		items[num] = { item = { slot = slot }, inventory = cache.serverId }
	end

	updateInventory(items, 0)
end)


---@param point CPoint
local function nearbyDrop(point)
	if not point.instance or point.instance == currentInstance then
        DrawMarker(client.dropmarker.type, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, client.dropmarker.scale[1], client.dropmarker.scale[2], client.dropmarker.scale[3],
        ---@diagnostic disable-next-line: param-type-mismatch
        client.dropmarker.colour[1], client.dropmarker.colour[2], client.dropmarker.colour[3], 222, false, false, 0, true, false, false, false)
    end
end

---@param point CPoint
local function onEnterDrop(point)
	if not point.instance or point.instance == currentInstance and not point.entity then
		local model = point.prop or point.model or client.dropmodel

        -- Prevent breaking inventory on invalid point.model instead use default client.dropmodel
        if not IsModelValid(model) and not IsModelInCdimage(model) then
            model = client.dropmodel
        end
		lib.requestModel(model)

		local entity = CreateObject(model, point.coords.x, point.coords.y, point.coords.z, false, true, true)

		SetModelAsNoLongerNeeded(model)
		PlaceObjectOnGroundProperly(entity)
		FreezeEntityPosition(entity, true)
		SetEntityCollision(entity, false, true)

		point.entity = entity
	end
end

local function onExitDrop(point)
	local entity = point.entity

	if entity then
		Utils.DeleteEntity(entity)
		point.entity = nil
	end
end

local function createDrop(dropId, data)
	local point = lib.points.new({
		coords = data.coords,
		distance = 16,
		invId = dropId,
		instance = data.instance,
		model = data.model or data.prop
	})

	point.prop = data.prop or data.model
	point.hasPropObjects = data.hasPropObjects or false

	if point.prop then
		point.distance = 30
		point.onEnter = onEnterDrop
		point.onExit = onExitDrop
	elseif client.dropprops and not point.hasPropObjects then
		point.distance = 30
		point.onEnter = onEnterDrop
		point.onExit = onExitDrop
	else
		if client.dropprops then
			point.distance = 30
		end

		point.nearby = nearbyDrop
	end

	point.entities = point.entities or {}
	client.drops[dropId] = point
end

RegisterNetEvent('ox_inventory:createDrop', function(dropId, data, owner, slot)
	if client.drops then
		createDrop(dropId, data)
	end

	if owner == cache.serverId then
		if currentWeapon?.slot == slot then
			currentWeapon = Weapon.Disarm(currentWeapon)
		end

		if invOpen and #(GetEntityCoords(playerPed) - data.coords) <= 1 then
			if not cache.vehicle then
				client.openInventory('drop', dropId)
			else
				SendNUIMessage({
					action = 'setupInventory',
					data = { rightInventory = currentInventory }
				})
			end
		end
	end
end)

RegisterNetEvent('ox_inventory:updateDrop', function(dropId, items, instance)
	if client.drops then
        local point = client.drops[dropId]
        if point then
            point.items = items
            point.instance = instance
        end
    end
end)

local function removeDropObject(uniqueId, netId)
	local record = uniqueId and dropObjects[uniqueId]

	if not record and netId then
		local uid = dropObjectsByNetId[netId]

		if uid then
			uniqueId = uid
			record = dropObjects[uid]
		end
	end

	if record and netId and record.netId and record.netId ~= netId then
		record = nil
	end

	if record then
		local entity = record.entity

		if not entity or not DoesEntityExist(entity) then
			local resolvedNetId = record.netId or netId
			entity = resolvedNetId and NetworkGetEntityFromNetworkId(resolvedNetId) or entity
		end

		if entity and DoesEntityExist(entity) then
			Utils.DeleteEntity(entity)
		end

		if record.netId then
			dropObjectsByNetId[record.netId] = nil
		end

		if uniqueId then
			dropObjects[uniqueId] = nil
		end

		if record.dropId then
			local point = client.drops and client.drops[record.dropId]

			if point and point.entities then
				point.entities[uniqueId] = nil

				if not next(point.entities) then
					point.hasPropObjects = false
				end
			end
		end
	else
		if netId then
			dropObjectsByNetId[netId] = nil
			local entity = NetworkGetEntityFromNetworkId(netId)

			if entity and DoesEntityExist(entity) then
				Utils.DeleteEntity(entity)
			end
		end
	end
end

local function spawnDropProp(dropId, uniqueId, model, coords)
	if uniqueId and dropObjects[uniqueId] then
		removeDropObject(uniqueId)
	end

	if type(model) == 'string' then
		model = joaat(model)
	end

	if not model or model == 0 or (not IsModelValid(model) and not IsModelInCdimage(model)) then
		model = client.dropmodel
	end

	lib.requestModel(model)

	local entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)

	if not DoesEntityExist(entity) then
		SetModelAsNoLongerNeeded(model)
		return
	end

	SetEntityHeading(entity, math.random(0, 359))
	SetModelAsNoLongerNeeded(model)
	PlaceObjectOnGroundProperly(entity)
	FreezeEntityPosition(entity, true)
	SetEntityCollision(entity, false, true)

	local netId = NetworkGetNetworkIdFromEntity(entity)
	local record = {
		netId = netId,
		entity = entity,
		dropId = dropId
	}

	dropObjects[uniqueId] = record

	if netId and netId ~= 0 then
		dropObjectsByNetId[netId] = uniqueId
	end

	local point = client.drops and client.drops[dropId]

	if point then
		point.hasPropObjects = true
		point.entities = point.entities or {}

		if point.entity then
			Utils.DeleteEntity(point.entity)
			point.entity = nil
		end

		point.entities[uniqueId] = entity
	end

	return netId, entity
end

RegisterNetEvent('ox_inventory:createDropProp', function(data)
	if not data or not data.coords then return end

	local uniqueId = data.uniqueId
	if not uniqueId then return end

	local dropId = data.dropId
	local netId, entity = spawnDropProp(dropId, uniqueId, data.prop, data.coords)

	if entity then
		local finalCoords = GetEntityCoords(entity)
		TriggerServerEvent('ox_inventory:registerDropProp', uniqueId, netId or 0, finalCoords)
	end
end)

RegisterNetEvent('ox_inventory:removeDrop', function(dropId)
	if client.drops then
		local point = client.drops[dropId]

		if point then
			if point.entities then
				for uniqueId in pairs(point.entities) do
					removeDropObject(uniqueId)
				end
			end

			client.drops[dropId] = nil
			point:remove()

			if point.entity then Utils.DeleteEntity(point.entity) end
		end
	end
end)

RegisterNetEvent('ox_inventory:removeDropProp', function(netId, uniqueId)
	removeDropObject(uniqueId, netId)
end)

-- Resolve a model hash for drop props when the server requests it (weapons or custom props)
local function weaponModelFromName(name)
	if type(name) ~= 'string' then return nil end

	if name:upper():find('^WEAPON_') then
		local model = GetWeapontypeModel(joaat(name))
		return model
	end
end

lib.callback.register('ox_inventory:resolveModelOnClient', function(itemNameOrProps)
	if type(itemNameOrProps) == 'string' then
		return weaponModelFromName(itemNameOrProps)
	end

	if type(itemNameOrProps) == 'table' and itemNameOrProps.name then
		return weaponModelFromName(tostring(itemNameOrProps.name))
	end

	if type(itemNameOrProps) == 'table' and (itemNameOrProps.modelp or itemNameOrProps.prop) then
		local m = itemNameOrProps.modelp or itemNameOrProps.prop

		if type(m) == 'table' and m.modelp then
			return joaat(m.modelp)
		end

		if m then
			return joaat(m)
		end
	end

	return nil
end)

---@type function?
local function setStateBagHandler(stateId)
	AddStateBagChangeHandler('invOpen', stateId, function(_, _, value)
		invOpen = value
	end)

	AddStateBagChangeHandler('invBusy', stateId, function(_, _, value)
		invBusy = value
	end)

    AddStateBagChangeHandler('canUseWeapons', stateId, function(_, _, value)
        if not value and currentWeapon then
            currentWeapon = Weapon.Disarm(currentWeapon)
        end
    end)

	AddStateBagChangeHandler('instance', stateId, function(_, _, value)
		currentInstance = value

		if client.drops then
			-- Iterate over known drops and remove any points in a different instance (ignoring no instance)
			for dropId, point in pairs(client.drops) do
				if point.instance then
					if point.instance ~= value then
						if point.entity then
							Utils.DeleteEntity(point.entity)
							point.entity = nil
						end

						point:remove()
					else
						-- Recreate the drop using data from the old point
						createDrop(dropId, point)
					end
				end
			end
		end
	end)

	AddStateBagChangeHandler('dead', stateId, function(_, _, value)
		Utils.WeaponWheel()
		PlayerData.dead = value
	end)

	AddStateBagChangeHandler('invHotkeys', stateId, function(_, _, value)
		invHotkeys = value
	end)

	setStateBagHandler = nil
end

lib.onCache('seat', function(seat)
	if seat then
		local hasWeapon = GetCurrentPedVehicleWeapon(cache.ped)

		if hasWeapon then
			return Utils.WeaponWheel(true)
		end
	end

	Utils.WeaponWheel(false)
end)

lib.onCache('vehicle', function()
	if invOpen and (not currentInventory.entity or currentInventory.entity == cache.vehicle) then
		return client.closeInventory()
	end
end)

RegisterNetEvent('ox_inventory:setPlayerInventory', function(currentDrops, inventory, weight, player)
	if source == '' then return end

    ---@class PlayerData
    ---@field inventory table<number, SlotWithItem?>
    ---@field weight number
    ---@field groups table<string, number>
	PlayerData = player
	PlayerData.id = cache.playerId
	PlayerData.source = cache.serverId
    PlayerData.maxWeight = shared.playerweight

	setmetatable(PlayerData, {
		__index = function(self, key)
			if key == 'ped' then
				return PlayerPedId()
			end
		end
	})

	if setStateBagHandler then setStateBagHandler(('player:%s'):format(cache.serverId)) end

	local ItemData = table.create(0, #Items)

	for _, v in pairs(Items --[[@as table<string, OxClientItem>]]) do
		local buttons = v.buttons and {} or nil
		local weaponEditorSlots = v.weapon and buildWeaponEditorSlots(v) or nil

		if buttons then
			for i = 1, #v.buttons do
				buttons[i] = {label = v.buttons[i].label, group = v.buttons[i].group}
			end
		end

		ItemData[v.name] = {
			label = v.label,
			stack = v.stack,
			close = v.close,
			rarity = v.rarity or 'common',
			count = 0,
			description = v.description,
			category = v.category,
			buttons = buttons,
			ammoName = v.ammoname,
			image = v.client?.image,
			weapon = v.weapon or nil,
			component = v.component or nil,
			componentType = v.type,
			weaponEditorSlots = weaponEditorSlots and next(weaponEditorSlots) and weaponEditorSlots or nil,
		}
	end

	for _, data in pairs(inventory) do
		local item = Items[data.name]

		if item then
			item.count += data.count
			ItemData[data.name].count += data.count
			local add = item.client?.add

			if add then
				add(item.count)
			end
		end
	end

	local phone = Items.phone

	if phone and phone.count < 1 then
		pcall(function()
			return exports.npwd:setPhoneDisabled(true)
		end)
	end

	client.setPlayerData('inventory', inventory)
	client.setPlayerData('weight', weight)
	currentWeapon = nil
	Weapon.ClearAll()

	local locales = lib.getLocales()
	local uiLocales = {}

	for k, v in pairs(locales) do
		uiLocales[k] = v
	end

	client.drops = currentDrops

	for dropId, data in pairs(currentDrops) do
		createDrop(dropId, data)
	end

	for dropId, data in pairs(currentDrops) do
		local props = data.itemProps

		if props then
			for i = 1, #props do
				local entry = props[i]
				local uniqueId = entry.uniqueId

				if uniqueId then
					local coords = entry.coords or data.coords
					local model = entry.prop or data.prop
					local netId = entry.netId
					local entity

					if netId and NetworkDoesNetworkIdExist(netId) then
						entity = NetworkGetEntityFromNetworkId(netId)
					end

					if entity and DoesEntityExist(entity) then
						dropObjects[uniqueId] = {
							netId = netId,
							entity = entity,
							dropId = dropId
						}

						if netId and netId ~= 0 then
							dropObjectsByNetId[netId] = uniqueId
						end

						local point = client.drops and client.drops[dropId]

						if point then
							point.hasPropObjects = true
							point.entities = point.entities or {}
							point.entities[uniqueId] = entity
						end
					elseif coords then
						local newNetId, newEntity = spawnDropProp(dropId, uniqueId, model, coords)

						if newEntity then
							local finalCoords = GetEntityCoords(newEntity)
							TriggerServerEvent('ox_inventory:registerDropProp', uniqueId, newNetId or 0, finalCoords)
						end
					end
				end
			end
		end
	end

	local hasTextUi
	local uiOptions = { icon = 'fa-id-card' }

	---@param point CPoint
	local function nearbyLicense(point)
		---@diagnostic disable-next-line: param-type-mismatch
		DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 30, 150, 30, 222, false, false, 0, true, false, false, false)

		if point.isClosest and point.currentDistance < 1.2 then
			if not hasTextUi then
				hasTextUi = point
				lib.showTextUI(point.message, uiOptions)
			end

			if IsControlJustReleased(0, 38) then
				lib.callback('ox_inventory:buyLicense', 1000, function(success, message)
					if success ~= nil then
						lib.notify({
							id = message,
							type = success == false and 'error' or 'success',
							description = locale(message, locale('license', point.type:gsub("^%l", string.upper)))
						})
					end
				end, point.invId)
			end
		elseif hasTextUi == point then
			hasTextUi = false
			lib.hideTextUI()
		end
	end

	for id, data in pairs(lib.load('data.licenses') or {}) do
		lib.points.new({
			coords = data.coords,
			distance = 16,
			inv = 'license',
			type = data.name,
			price = data.price,
			invId = id,
			nearby = nearbyLicense,
			message = ('**%s**  \n%s'):format(locale('purchase_license', data.name), locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3)))
		})
	end

	while not client.uiLoaded do Wait(50) end

	SendNUIMessage({
		action = 'init',
		data = {
			serverId = cache.serverId,
			locale = uiLocales,
			items = ItemData,
			leftInventory = {
				id = cache.playerId,
				slots = shared.playerslots,
				items = PlayerData.inventory,
				maxWeight = shared.playerweight,
			},
			imagepath = client.imagepath,
			utility = client.utility,
			rarity = client.rarity,
			ui = shared.ui
		}
	})

	PlayerData.loaded = true
	syncPlayerBackpackAppearance(true)

	if not client.disablesetupnotification then
		lib.notify({ description = locale('inventory_setup') })
	end

	Shops.refreshShops()
	Inventory.Stashes()
	Inventory.Evidence()

	if registerCommands then registerCommands() end

	TriggerEvent('ox_inventory:updateInventory', PlayerData.inventory)

	client.interval = SetInterval(function()
        local canSteal = canOpenTarget(playerPed)

        if canSteal ~= plyState.canSteal then
            plyState:set('canSteal', canSteal, true)
        end

		if invOpen == false then
			playerCoords = GetEntityCoords(playerPed)

			if currentWeapon and IsPedUsingActionMode(playerPed) then
				SetPedUsingActionMode(playerPed, false, -1, 'DEFAULT_ACTION')
			end

		elseif invOpen == true then
			if not canOpenInventory() then
				client.closeInventory()
			else
				playerCoords = GetEntityCoords(playerPed)

				if currentInventory and not currentInventory.ignoreSecurityChecks then
                    local maxDistance = (currentInventory.distance or currentInventory.type == 'stash' and 4.8 or 1.8) + 0.2

					if currentInventory.type == 'otherplayer' then
						local id = GetPlayerFromServerId(currentInventory.id)
						local ped = GetPlayerPed(id)
						local pedCoords = GetEntityCoords(ped)

						if not id or #(playerCoords - pedCoords) > maxDistance or (not client.hasGroup(shared.police) and not Player(currentInventory.id).state.canSteal) then
							client.closeInventory()
							lib.notify({ id = 'inventory_lost_access', type = 'error', description = locale('inventory_lost_access') })
						else
							TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 50)
						end

					elseif currentInventory.coords and (#(playerCoords - currentInventory.coords) > maxDistance or canSteal) then
						client.closeInventory()
						lib.notify({ id = 'inventory_lost_access', type = 'error', description = locale('inventory_lost_access') })
					end
				end
			end
		end

		if client.parachute and GetPedParachuteState(playerPed) ~= -1 then
			Utils.DeleteEntity(client.parachute[1])
			client.parachute = false
		end

		if EnableWeaponWheel then return end

		local weaponHash = GetSelectedPedWeapon(playerPed)

		if currentWeapon then
			if weaponHash ~= currentWeapon.hash and currentWeapon.timer then
				local weaponCount = Items[currentWeapon.name]?.count

				if weaponCount > 0 then
					SetCurrentPedWeapon(playerPed, currentWeapon.hash, true)
					SetAmmoInClip(playerPed, currentWeapon.hash, currentWeapon.metadata.ammo)
					SetPedCurrentWeaponVisible(playerPed, true, false, false, false)

					weaponHash = GetSelectedPedWeapon(playerPed)
				end

				if weaponHash ~= currentWeapon.hash then
                    lib.print.info(('%s was forcibly unequipped (caused by game behaviour or another resource)'):format(currentWeapon.name))
					currentWeapon = Weapon.Disarm(currentWeapon, true)
				end
			end
		elseif client.weaponmismatch and not client.ignoreweapons[weaponHash] then
			local weaponType = GetWeapontypeGroup(weaponHash)

			if weaponType ~= 0 and weaponType ~= `GROUP_UNARMED` then
				Weapon.Disarm(currentWeapon, true)
			end
		end
	end, 200)

	local playerId = cache.playerId
	local EnableKeys = client.enablekeys
	local DisablePlayerVehicleRewards = DisablePlayerVehicleRewards
	local DisableAllControlActions = DisableAllControlActions
	local HideHudAndRadarThisFrame = HideHudAndRadarThisFrame
	local EnableControlAction = EnableControlAction
	local DisablePlayerFiring = DisablePlayerFiring
	local HudWeaponWheelIgnoreSelection = HudWeaponWheelIgnoreSelection
	local DisableControlAction = DisableControlAction
	local IsPedShooting = IsPedShooting
	local IsControlJustReleased = IsControlJustReleased

	client.tick = SetInterval(function()
		DisablePlayerVehicleRewards(playerId)

		if invOpen then
			DisableAllControlActions(0)
			HideHudAndRadarThisFrame()

			for i = 1, #EnableKeys do
				EnableControlAction(0, EnableKeys[i], true)
			end

			if currentInventory.type == 'newdrop' then
				EnableControlAction(0, 30, true)
				EnableControlAction(0, 31, true)
			end
		else
			if invBusy then
				DisableControlAction(0, 23, true)
				DisableControlAction(0, 36, true)
			end

			if usingItem or invOpen or IsPedCuffed(playerPed) then
				DisablePlayerFiring(playerId, true)
			end

			if not EnableWeaponWheel then
				HudWeaponWheelIgnoreSelection()
				DisableControlAction(0, 37, true)
			end

			if currentWeapon and currentWeapon.timer then
				DisableControlAction(0, 80, true)
				DisableControlAction(0, 140, true)

				if currentWeapon.metadata.durability <= 0 or not currentWeapon.timer then
					DisablePlayerFiring(playerId, true)
				elseif client.aimedfiring and not currentWeapon.melee and currentWeapon.group ~= `GROUP_PETROLCAN` and not IsPlayerFreeAiming(playerId) then
					DisablePlayerFiring(playerId, true)
				end

				local weaponAmmo = currentWeapon.metadata.ammo

				if not invBusy and currentWeapon.timer ~= 0 and currentWeapon.timer < GetGameTimer() then
					currentWeapon.timer = 0

					if weaponAmmo then
						TriggerServerEvent('ox_inventory:updateWeapon', 'ammo', weaponAmmo)

						if client.autoreload and currentWeapon.ammo and GetAmmoInPedWeapon(playerPed, currentWeapon.hash) == 0 then
							local slotId = Inventory.GetSlotIdWithItem(currentWeapon.ammo, { type = currentWeapon.metadata.specialAmmo }, false)

							if slotId then
								CreateThread(function() useSlot(slotId) end)
							end
						end

					elseif currentWeapon.metadata.durability then
						TriggerServerEvent('ox_inventory:updateWeapon', 'melee', currentWeapon.melee)
						currentWeapon.melee = 0
					end
				elseif weaponAmmo then
					if IsPedShooting(playerPed) then
						local currentAmmo
						local durabilityDrain = Items[currentWeapon.name].durability

						if currentWeapon.group == `GROUP_PETROLCAN` or currentWeapon.group == `GROUP_FIREEXTINGUISHER` then
							currentAmmo = weaponAmmo - durabilityDrain < 0 and 0 or weaponAmmo - durabilityDrain
							currentWeapon.metadata.durability = currentAmmo
							currentWeapon.metadata.ammo = (weaponAmmo < currentAmmo) and 0 or currentAmmo

							if currentAmmo <= 0 then
								SetPedInfiniteAmmo(playerPed, false, currentWeapon.hash)
							end
						else
							currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)

							if currentAmmo < weaponAmmo then
								currentAmmo = (weaponAmmo < currentAmmo) and 0 or currentAmmo
								currentWeapon.metadata.ammo = currentAmmo
								currentWeapon.metadata.durability = currentWeapon.metadata.durability - (durabilityDrain * math.abs((weaponAmmo or 0.1) - currentAmmo))
							end
						end

						if currentAmmo <= 0 then
							if cache.vehicle then
								TaskSwapWeapon(playerPed, true)
							end

							currentWeapon.timer = GetGameTimer() + 200
						else currentWeapon.timer = GetGameTimer() + (GetWeaponTimeBetweenShots(currentWeapon.hash) * 1000) + 100 end
					end
				elseif currentWeapon.throwable then
					if not invBusy and IsControlPressed(0, 24) then
						invBusy = 1

						CreateThread(function()
							local weapon = currentWeapon

							while currentWeapon and (not IsPedWeaponReadyToShoot(cache.ped) or IsDisabledControlPressed(0, 24)) and GetSelectedPedWeapon(playerPed) == weapon.hash do
								Wait(0)
							end

							if GetSelectedPedWeapon(playerPed) == weapon.hash then Wait(700) end

							while IsPedPlantingBomb(playerPed) do Wait(0) end

							TriggerServerEvent('ox_inventory:updateWeapon', 'throw', nil, weapon.slot)
							plyState:set('invBusy', false, true)

							currentWeapon = nil

							RemoveWeaponFromPed(playerPed, weapon.hash)
							TriggerEvent('ox_inventory:currentWeapon')
						end)
					end
				elseif currentWeapon.melee and IsControlJustReleased(0, 24) and IsPedPerformingMeleeAction(playerPed) then
					currentWeapon.melee += 1
					currentWeapon.timer = GetGameTimer() + 200
				end
			end
		end
	end)

	plyState:set('invBusy', false, true)
	plyState:set('invOpen', false, false)
	plyState:set('invHotkeys', true, false)
	plyState:set('canUseWeapons', true, false)
	collectgarbage('collect')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if shared.resource == resourceName then
		client.onLogout()
	end
end)

RegisterNetEvent('ox_inventory:viewInventory', function(left, right)
	if source == '' then return end
	if left and left.id ~= cache.serverId then return end

	plyState.invOpen = true

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	if client.screenblur then Utils.blurIn() end

	currentInventory = right or defaultInventory
	currentInventory.ignoreSecurityChecks = true
    currentInventory.type = right and right.type or 'inspect'
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups



	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory,
			backpackInventory = false,
			targetBackpackInventory = false
		}
	})
end)

RegisterNUICallback('uiLoaded', function(_, cb)
	client.uiLoaded = true
	cb(1)
end)

RegisterNUICallback('getItemData', function(itemName, cb)
	cb(Items[itemName])
end)

RegisterNUICallback('removeComponent', function(data, cb)
	cb(1)

	if not currentWeapon then
		return TriggerServerEvent('ox_inventory:updateWeapon', 'component', data)
	end

	if data.slot ~= currentWeapon.slot then
		return lib.notify({ id = 'weapon_hand_wrong', type = 'error', description = locale('weapon_hand_wrong') })
	end

	local itemSlot = PlayerData.inventory[currentWeapon.slot]

    if not itemSlot then return end

	for _, component in pairs(Items[data.component].client.component) do
		if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
			for k, v in pairs(itemSlot.metadata.components) do
				if v == data.component then
					local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', k)

					if success then
						RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, component)
						TriggerEvent('ox_inventory:updateWeaponComponent', 'removed', component, data.component)
					end

					break
				end
			end
		end
	end
end)

RegisterNUICallback('removeAmmo', function(slot, cb)
	cb(1)
	local slotData = PlayerData.inventory[slot]

	if not slotData or not slotData.metadata.ammo or slotData.metadata.ammo == 0 then return end

	local success = lib.callback.await('ox_inventory:removeAmmoFromWeapon', false, slot)

	if success and slot == currentWeapon?.slot then
		SetPedAmmo(playerPed, currentWeapon.hash, 0)
	end
end)

RegisterNUICallback('weaponEditorAction', function(data, cb)
	local weaponSlot = tonumber(data?.weaponSlot)
	local action = data?.action

	if not weaponSlot or not action then
		return cb(false)
	end

	local weapon = PlayerData.inventory[weaponSlot]

	if not weapon then
		return cb(false)
	end

	local weaponData = Items(weapon.name)

	if not weaponData?.weapon then
		return cb(false)
	end

	if action == 'attachComponent' then
		local componentSlot = tonumber(data?.componentSlot)
		local component = componentSlot and PlayerData.inventory[componentSlot]

		if not component then
			return cb(false)
		end

		local componentData = Items(component.name)

		if not componentData?.component then
			return cb(false)
		end

		local componentHash = getWeaponEditorComponentHash(weaponData.hash, component.name)

		if not componentHash then
			lib.notify({ id = 'component_invalid', type = 'error', description = locale('component_invalid', componentData.label or component.name) })
			return cb(false)
		end

		weapon.metadata.components = weapon.metadata.components or {}

		for i = 1, #weapon.metadata.components do
			local installedComponent = Items(weapon.metadata.components[i])

			if installedComponent?.type == componentData.type then
				lib.notify({ id = 'component_slot_occupied', type = 'error', description = locale('component_slot_occupied', componentData.type) })
				return cb(false)
			end
		end

		local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', tostring(componentSlot), weaponSlot)

		if success and currentWeapon?.slot == weaponSlot then
			if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, componentHash) then
				GiveWeaponComponentToPed(playerPed, currentWeapon.hash, componentHash)
			end

			currentWeapon.metadata.components = currentWeapon.metadata.components or {}

			local hasComponent = false

			for i = 1, #currentWeapon.metadata.components do
				if currentWeapon.metadata.components[i] == component.name then
					hasComponent = true
					break
				end
			end

			if not hasComponent then
				currentWeapon.metadata.components[#currentWeapon.metadata.components + 1] = component.name
			end

			TriggerEvent('ox_inventory:updateWeaponComponent', 'added', componentHash, component.name)
		end

		return cb(success == true)
	elseif action == 'removeComponent' then
		local componentName = data?.componentName

		if type(componentName) ~= 'string' then
			return cb(false)
		end

		weapon.metadata.components = weapon.metadata.components or {}

		local removeIndex

		for i = 1, #weapon.metadata.components do
			if weapon.metadata.components[i] == componentName then
				removeIndex = i
				break
			end
		end

		if not removeIndex then
			return cb(false)
		end

		local componentHash = getWeaponEditorComponentHash(weaponData.hash, componentName)
		local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', removeIndex, weaponSlot)

		if success and currentWeapon?.slot == weaponSlot then
			if componentHash and HasPedGotWeaponComponent(playerPed, currentWeapon.hash, componentHash) then
				RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, componentHash)
			end

			currentWeapon.metadata.components = currentWeapon.metadata.components or {}
			table.remove(currentWeapon.metadata.components, removeIndex)

			if componentHash then
				TriggerEvent('ox_inventory:updateWeaponComponent', 'removed', componentHash, componentName)
			end
		end

		return cb(success == true)
	elseif action == 'loadAmmo' then
		local ammoSlot = tonumber(data?.ammoSlot)
		local ammoItem = ammoSlot and PlayerData.inventory[ammoSlot]

		if not ammoItem or ammoItem.name ~= weaponData.ammoname then
			return cb(false)
		end

		local clipSize = getWeaponEditorAmmoCapacity(weapon, weaponData)
		local currentAmmo = weapon.metadata.ammo or 0

		if clipSize <= 0 or currentAmmo >= clipSize then
			lib.notify({ id = 'weapon_ammo_full', type = 'error', description = 'Weapon ammo is already full' })
			return cb(false)
		end

		local previousSpecialAmmo = weapon.metadata.specialAmmo
		local nextSpecialAmmo = ammoItem.metadata?.type

		if previousSpecialAmmo ~= nextSpecialAmmo then
			if currentAmmo > 0 then
				lib.notify({ id = 'weapon_special_ammo_mix', type = 'error', description = 'Unload current ammo before changing ammo type' })
				return cb(false)
			end

			if nextSpecialAmmo then
				local specialClip = getWeaponEditorSpecialClip(weaponData.model or weapon.name, nextSpecialAmmo)

				if not specialClip or not DoesWeaponTakeWeaponComponent(weaponData.hash, specialClip) then
					lib.notify({ id = 'wrong_ammo', type = 'error', description = locale('wrong_ammo', weaponData.label, Items(ammoItem.name)?.label or ammoItem.name) })
					return cb(false)
				end
			end
		end

		local missingAmmo = clipSize - currentAmmo
		local addAmmo = ammoItem.count > missingAmmo and missingAmmo or ammoItem.count
		local newAmmo = currentAmmo + addAmmo

		if newAmmo <= currentAmmo then
			return cb(false)
		end

		local success = lib.callback.await('ox_inventory:updateWeapon', false, 'load', newAmmo, weaponSlot, nextSpecialAmmo)

		if success and currentWeapon?.slot == weaponSlot then
			applyWeaponEditorSpecialAmmo(weaponData, weaponSlot, previousSpecialAmmo, nextSpecialAmmo)
			currentWeapon.metadata.ammo = newAmmo
			currentWeapon.metadata.specialAmmo = nextSpecialAmmo
			SetPedAmmo(playerPed, currentWeapon.hash, newAmmo)
			SetTimeout(0, function() RefillAmmoInstantly(playerPed) end)
		end

		return cb(success == true)
	end

	cb(false)
end)


---@param slot number | { slot: number, inventoryId?: number | string, name?: string, metadata?: table }
---@param noAnim boolean?
---@param cb function?
local function useSlot(slot, noAnim, cb)
    local item, inventoryId, itemName, metadata, slotId

    if type(slot) == 'table' then
        inventoryId = slot.inventoryId
        slotId = slot.slot
        itemName = slot.name
        metadata = slot.metadata
        
        -- Try to resolve item locally if possible
        if not inventoryId then
             item = PlayerData.inventory[slotId]
        elseif currentInventory and currentInventory.id == inventoryId then
             item = currentInventory.items[slotId]
        end
        
        -- If unresolved but we have NUI data, treat as external/trust NUI
        if not item and itemName then
            item = { name = itemName, slot = slotId, metadata = metadata or {} }
        end
    else
        slotId = slot
        item = PlayerData.inventory[slotId]
        if item then itemName = item.name; metadata = item.metadata end
    end

    if not item or not itemName then return end

    local data = Items[itemName]
    -- Use item instance for slotData, but if it's a dummy object make sure it has what we need
    local slotData = item

    if not data or not canUseItem(data.ammo) then return end

    if data.weapon then
        if currentInventory and currentInventory.type == 'shop' then return end
        if weaponTimer > GetGameTimer() then return end
        weaponTimer = GetGameTimer() + 1000
    elseif string.match(itemName, '^WEAPON_') then
        if not noAnim then
	        Utils.PlayAnim(400, 'mp_common', 'givetake1_a', 1.0, 1.0, 48, 0, 0, 0, 0)
        end

        if data.ammoname then
			Utils.WeaponAnim(data.ammoname)
        end
    end

    usingItem = true
    ---@type boolean?
    result = lib.callback.await('ox_inventory:useItem', 200, itemName, slotId, metadata, noAnim, inventoryId)

	if result and cb then
		local success, response = pcall(cb, result and slotData)
		if not success then
			--
		end
	end

    usingItem = false

	return not usingItem
end

RegisterNUICallback('useItem', function(data, cb)
    cb(1)
    CreateThread(function()
	    useItem(data)
    end)
end)

lib.callback.register('ox_inventory:repairArmorProgress', function(duration)
    if lib.progressCircle({
        duration = duration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'clothingshirt',
            clip = 'try_shirt_positive_d'
        },
    }) then
        return true
    end
    return false
end)

local function giveItemToTarget(serverId, slotId, count, inventoryId)
    if type(slotId) ~= 'number' then return TypeError('slotId', 'number', type(slotId)) end
    if count and type(count) ~= 'number' then return TypeError('count', 'number', type(count)) end

    if slotId == currentWeapon?.slot then
        currentWeapon = Weapon.Disarm(currentWeapon)
    end

    Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 1.0, 1.0, 2000, 50, 0.0, 0, 0, 0)

    local notification = lib.callback.await('ox_inventory:giveItem', false, slotId, serverId, count or 0, inventoryId)

    if notification then
        lib.notify({ type = 'error', description = locale(table.unpack(notification)) })
    end
end

exports('giveItemToTarget', giveItemToTarget)

local function isGiveTargetValid(ped, coords)
    if cache.vehicle and GetVehiclePedIsIn(ped, false) == cache.vehicle then
        return true
    end

    local entity = Utils.Raycast(1|2|4|8|16, coords + vec3(0, 0, 0.5), 0.2)

    return entity == ped and IsEntityVisible(ped)
end

local function attemptGiveItemToNearbyTarget(slotId, count, inventoryId, notifyOnFail)
	if client.giveplayerlist then
		local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(playerPed), 3.0)
		local nearbyCount = #nearbyPlayers

		if nearbyCount == 0 then
			if notifyOnFail then
				lib.notify({ type = 'error', description = locale('nobody_nearby') })
			end

			return false
		end

		if nearbyCount == 1 then
			local option = nearbyPlayers[1]

			if not isGiveTargetValid(option.ped, option.coords) then
				if notifyOnFail then
					lib.notify({ type = 'error', description = locale('nobody_nearby') })
				end

				return false
			end

			giveItemToTarget(GetPlayerServerId(option.id), slotId, count, inventoryId)
			return true
		end

		local giveList, n = {}, 0

		for i = 1, #nearbyPlayers do
			local option = nearbyPlayers[i]

            if isGiveTargetValid(option.ped, option.coords) then
				local playerName = Utils.getPlayerName(option.id)
				option.id = GetPlayerServerId(option.id)
                ---@diagnostic disable-next-line: inject-field
				option.label = playerName
				n += 1
				giveList[n] = option
			end
		end

		if n == 0 then
			if notifyOnFail then
				lib.notify({ type = 'error', description = locale('nobody_nearby') })
			end

			return false
		end

		lib.registerMenu({
			id = 'ox_inventory:givePlayerList',
			title = 'Give item',
			options = giveList,
		}, function(selected)
			giveItemToTarget(giveList[selected].id, slotId, count, inventoryId)
		end)

		lib.showMenu('ox_inventory:givePlayerList')
		return true
	end

	if cache.vehicle then
		local seats = GetVehicleMaxNumberOfPassengers(cache.vehicle) - 1

		if seats >= 0 then
			local passenger = GetPedInVehicleSeat(cache.vehicle, cache.seat - 2 * (cache.seat % 2) + 1)

			if passenger ~= 0 and IsEntityVisible(passenger) then
				giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)), slotId, count, inventoryId)
				return true
			end
		end

		if notifyOnFail then
			lib.notify({ type = 'error', description = locale('nobody_nearby') })
		end

		return false
	end

	local targetEntity = Utils.Raycast(1|2|4|8|16, GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.5), 0.2)

	if targetEntity and IsPedAPlayer(targetEntity) and IsEntityVisible(targetEntity)
		and #(GetEntityCoords(playerPed, true) - GetEntityCoords(targetEntity, true)) < 3.0 then
		giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetEntity)), slotId, count, inventoryId)
		return true
	end

	if notifyOnFail then
		lib.notify({ type = 'error', description = locale('nobody_nearby') })
	end

	return false
end

RegisterNUICallback('startGiveItemDrag', function(_, cb)
	startGiveDragTargeting()
	cb(1)
end)

RegisterNUICallback('finishGiveItemDrag', function(data, cb)
	local targetId, targetPed, targetName

	if not data.didDrop then
		targetId, targetPed, targetName = resolveGiveDragTarget()
	end

	stopGiveDragTargeting()

	if not targetId or not targetPed or not DoesEntityExist(targetPed) then
		return cb(false)
	end

	cb({
		targetId = targetId,
		targetName = targetName or ('[%s]'):format(targetId),
	})
end)

RegisterNUICallback('confirmGiveItemDrag', function(data, cb)
	local targetId = tonumber(data.targetId)
	local slotId = tonumber(data.slot)
	local count = tonumber(data.count) or 1

	if not targetId or not slotId then
		return cb(false)
	end

	local playerId = GetPlayerFromServerId(targetId)

	if playerId == -1 then
		lib.notify({ type = 'error', description = locale('nobody_nearby') })
		return cb(false)
	end

	local targetPed = GetPlayerPed(playerId)

	if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) or #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed)) > giveDragDistance then
		lib.notify({ type = 'error', description = locale('nobody_nearby') })
		return cb(false)
	end

	giveItemToTarget(targetId, slotId, count, data.inventoryId)
	cb(true)
end)




RegisterNUICallback('giveItem', function(data, cb)
	cb(1)

    if usingItem then return end

	local item = lib.callback.await('ox_inventory:getItemFromSlot', false, data.slot, data.inventoryId)
	if not item then return end

	local props = Items[item.name]
	local propnode = props.prop or weaponModelFromName(item.name)
	if propnode and not props.disableThrow then
        local throwProps = setmetatable({ prop = propnode }, { __index = props })

		client.closeInventory()

		lib.showTextUI('[R] place\n[E] give\n[ESC] cancel', {
			position = 'bottom-center',  

		})

		local previewEntity = exports["Preload-ox_throwitems"]:throwItem(data.slot, throwProps, data.count or 0)

		if previewEntity and DoesEntityExist(previewEntity) then
			while DoesEntityExist(previewEntity) do
				DisableFrontendThisFrame()

				if IsControlJustReleased(2, 200) then
					DeleteEntity(previewEntity)
					RemoveWeaponFromPed(playerPed, 'WEAPON_BALL')
					SetCurrentPedWeapon(playerPed, 'WEAPON_UNARMED', true)
					lib.hideTextUI()
				elseif IsControlJustReleased(0, 45) then
					DeleteEntity(previewEntity)
					RemoveWeaponFromPed(playerPed, 'WEAPON_BALL')
					SetCurrentPedWeapon(playerPed, 'WEAPON_UNARMED', true)
					lib.hideTextUI()

					exports["Preload-ox_throwitems"]:placeItem(data.slot, throwProps, data.count or 0)
				elseif IsControlJustReleased(0, 38) then
					local hasGiven = attemptGiveItemToNearbyTarget(data.slot, data.count, data.inventoryId, true)

					if hasGiven then
						DeleteEntity(previewEntity)
						RemoveWeaponFromPed(playerPed, 'WEAPON_BALL')
						SetCurrentPedWeapon(playerPed, 'WEAPON_UNARMED', true)
						lib.hideTextUI()
					end
				end

				Wait(0)
			end

			return
		end

		lib.hideTextUI()
	end

	attemptGiveItemToNearbyTarget(data.slot, data.count, data.inventoryId)
end)

RegisterNUICallback('useButton', function(data, cb)
	useButton(data.id, data.slot)
	cb(1)
end)

RegisterNUICallback('exit', function(_, cb)
	client.closeInventory()
	cb(1)
end)

RegisterNUICallback('craftTree:open', function(data, cb)
	cb(true)

	if not currentInventory or currentInventory.type ~= 'crafting' then
		return
	end

	if GetResourceState('Preload-ox_crafttree') ~= 'started' then
		lib.notify({
			type = 'error',
			description = 'Preload-ox_crafttree is not started.',
		})
		return
	end

	local benchId = data?.benchId or currentInventory.id
	local benchIndex = data?.benchIndex or currentInventory.index or 1
	local payload = {
		benchId = benchId,
		benchIndex = benchIndex,
		benchLabel = currentInventory.label,
		benchType = currentInventory.crafting and currentInventory.crafting.type or nil,
		recipes = currentInventory.items,
		crafting = currentInventory.crafting,
		returnToBench = true,
	}

	client.closeInventory()

	SetTimeout(225, function()
		local ok, result = pcall(function()
			return exports['Preload-ox_crafttree']:openTree(payload)
		end)

		if ok and result then
			return
		end

		lib.notify({
			type = 'error',
			description = 'Failed to open blueprint tree.',
		})

		client.openInventory('crafting', {
			id = benchId,
			index = benchIndex,
		})
	end)
end)

lib.callback.register('ox_inventory:startCrafting', function(id, recipe)
	recipe = CraftingBenches[id].items[recipe]

	return lib.progressCircle({
		label = locale('crafting_item', recipe.metadata?.label or Items[recipe.name].label),
		duration = recipe.duration or 3000,
		canCancel = true,
		disable = {
			move = true,
			combat = true,
		},
		anim = {
			dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
			clip = 'machinic_loop_mechandplayer',
		}
	})
end)

local swapActive = false

RegisterNUICallback('swapItems', function(data, cb)
    if swapActive or not invOpen or invBusy or usingItem then return cb(false) end

    swapActive = true

	if data.toType == 'newdrop' then
		if cache.vehicle or IsPedFalling(playerPed) then
			swapActive = false
			return cb(false)
		end

		local coords = GetEntityCoords(playerPed)

		if IsEntityInWater(playerPed) then
			local destination = vec3(coords.x, coords.y, -200)
			local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, 511, cache.ped, 4)

			while true do
				Wait(0)
				local retval, hit, endCoords = GetShapeTestResult(handle)

				if retval ~= 1 then
					if not hit then return end

					data.coords = vec3(endCoords.x, endCoords.y, endCoords.z + 1.0)

					break
				end
			end
		else
			data.coords = coords
		end
    end

	if currentInstance then
		data.instance = currentInstance
	end

	if currentWeapon and data.fromType ~= data.toType then
		if (data.fromType == 'player' and data.fromSlot == currentWeapon.slot) or (data.toType == 'player' and data.toSlot == currentWeapon.slot) then
			currentWeapon = Weapon.Disarm(currentWeapon, true)
		end
	end

	local success, response, weaponSlot = lib.callback.await('ox_inventory:swapItems', false, data)
    swapActive = false

	cb(success or false)

	if success then
        if weaponSlot and currentWeapon then
            currentWeapon.slot = weaponSlot
        end

		if response then
			updateInventory(response.items, response.weight)
		end
	elseif response then
		if type(response) == 'table' then
			SendNUIMessage({ action = 'refreshSlots', data = { items = response } })
		else
			lib.notify({ type = 'error', description = locale(response) })
		end
	end
end)

RegisterNUICallback('buyItem', function(data, cb)
	---@type boolean, false | { [1]: number, [2]: SlotWithItem, [3]: SlotWithItem | false, [4]: number}, NotifyProps
	local response, data, message = lib.callback.await('ox_inventory:buyItem', false, data)

	if data then
		updateInventory({
			{
				item = data[2],
				inventory = cache.serverId
			}
		}, data[4])

		if data[3] then
			SendNUIMessage({
				action = 'refreshSlots',
				data = {
					items = {
						{
							item = data[3],
							inventory = 'shop'
						}
					}
				}
			})
		end
	end

	if message then
		lib.notify(message)
	end

	cb(response)
end)

RegisterNUICallback('craftItem', function(data, cb)
	cb(true)

	local id, index = data.benchId or currentInventory.id, data.benchIndex or currentInventory.index
	local fromSlot = data.recipeSlot or data.fromSlot
	local storageId = data.storageId

	local success, response = lib.callback.await('ox_inventory:craftItem', false, id, index, fromSlot, data.toSlot, storageId, data.count)

	if not success then
		if response then lib.notify({ type = 'error', description = locale(response or 'cannot_perform') }) end
	end
end)

lib.callback.register('ox_inventory:getVehicleData', function(netid)
	local entity = NetworkGetEntityFromNetworkId(netid)

	if entity then
		return GetEntityModel(entity), GetVehicleClass(entity)
	end
end)

RegisterNetEvent('ox_inventory:crafting:updateXp', function(newXp)
	if currentInventory and currentInventory.type == 'crafting' then
		currentInventory.crafting = currentInventory.crafting or {}
		currentInventory.crafting.xp = currentInventory.crafting.xp or { enabled = true, current = 0 }
		currentInventory.crafting.xp.current = newXp

		SendNUIMessage({
			action = 'refreshSlots',
			data = {
				craftingXp = {
					xp = newXp
				}
			}
		})
	end
end)

RegisterNetEvent('ox_inventory:updateCraftingQueue', function(queueData)
	SendNUIMessage({
		action = 'updateCraftingQueue',
		data = queueData
	})
end)
