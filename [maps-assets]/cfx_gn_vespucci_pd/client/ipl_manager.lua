local interiorsRulesById = {}
local appliedStates = {}
local radiusEntries = (Config.RadiusIpls and Config.RadiusIpls.entries) or {}
local radiusEnableNotifications = Config.RadiusIpls and Config.RadiusIpls.enableNotifications and Config.Notify and
Config.Notify.debug
local hasRadiusCfg = {}
for i = 1, #radiusEntries do
	local e = radiusEntries[i]
	if e and e.ipl then
		hasRadiusCfg[e.ipl] = e
	end
end
local radiusApplied = {}
local iplLodMapping = Config.IplLodMapping or {}
local activeLodIpls = {}
local mainIplStates = {}
local staticElevatorsEnabled = Config.StaticElevators == true
local staticElevatorEntries = {
	{
		pos = vector3(-1096.30676, -850.5642, 20.71751),
		entitySets = { 'lift_01_cage' },
	},
	{
		pos = vector3(-1066.19385, -833.6211, 14.7454481),
		entitySets = { 'lift_02_cage' },
	},
}
local staticElevatorState = {}
local staticElevatorWarnings = {}
local NOOSE_GARAGE_POS = vector3(-1095.64331, -831.7493, 10.7244015)
local function isPlayerInsideEntry(entry)
	local ped = PlayerPedId()
	local playerInterior = GetInteriorFromEntity(ped)
	if playerInterior ~= 0 then
		local targetInterior = GetInteriorAtCoords(entry.pos.x, entry.pos.y, entry.pos.z)
		if targetInterior ~= 0 and playerInterior == targetInterior then
			return true
		end
	end
	return false
end

local function notify(msg)
	local cfg = Config.Notify or { mode = 'none' }
	local text = (cfg.prefix and (cfg.prefix .. ' ') or '') .. msg
	if cfg.mode == 'chat' then
		TriggerEvent('chat:addMessage', { args = { text } })
	elseif cfg.mode == 'feed' then
		BeginTextCommandThefeedPost('STRING')
		AddTextComponentSubstringPlayerName(text)
		EndTextCommandThefeedPostTicker(false, false)
	end
end

local function addHash(set, h)
	if h and h ~= 0 then set[h] = true end
end

local function resolveInteriorIdsFromConfig()
	for name, v in pairs(Config.INTERIORS or {}) do
		if v.locations and #v.locations > 0 then
			for i = 1, #v.locations do
				local coords = v.locations[i]
				local interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)

				if interior ~= 0 then
					if not interiorsRulesById[interior] then
						interiorsRulesById[interior] = { rules = {} }
						appliedStates[interior] = {}
					end

					if v.iplRules then
						for _, rule in ipairs(v.iplRules) do
							local roomHashSet = {}

							if rule.room then
								local h = rule.room.hash or (rule.room.name and GetHashKey(rule.room.name)) or 0
								addHash(roomHashSet, h)
							end
							if rule.rooms then
								for _, rr in ipairs(rule.rooms) do
									local h = rr.hash or (rr.name and GetHashKey(rr.name)) or 0
									addHash(roomHashSet, h)
								end
							end

							table.insert(interiorsRulesById[interior].rules, {
								label = rule.label,
								ipls = rule.ipls or {},
								_roomHashSet = roomHashSet,
							})
						end
					end
				else
					if Config.Notify and Config.Notify.debug then
						print(("^3[WARN] Cannot find interior '%s' at coords %s^7"):format(name,
							coords.x .. ", " .. coords.y .. ", " .. coords.z .. "^7"))
					end
				end
			end
		end
	end
end


local function matchesAnyRoom(rule, playerRoomHash)
	if not rule._roomHashSet or next(rule._roomHashSet) == nil then
		return true
	end
	return rule._roomHashSet[playerRoomHash] == true
end

local function setIpls(ipls, remove)
	if not ipls then return end
	for _, ipl in ipairs(ipls) do
		if remove then
			if Config.Notify and Config.Notify.debug then
				print("^1[IPL REMOVE] " .. ipl .. "^7")
			end
			RemoveIpl(ipl)
			mainIplStates[ipl] = false
			local lodIpl = iplLodMapping[ipl]
			if lodIpl then
				activeLodIpls[lodIpl] = true
				RequestIpl(lodIpl)
				if Config.Notify and Config.Notify.debug then
					print("^3[IPL LOD] Chargement de " .. lodIpl .. " (déchargement de " .. ipl .. ")^7")
				end
			end
		else
			if Config.Notify and Config.Notify.debug then
				print("^2[IPL REQUEST] " .. ipl .. "^7")
			end
			RequestIpl(ipl)
			mainIplStates[ipl] = true
			local lodIpl = iplLodMapping[ipl]
			if lodIpl then
			end
		end
	end
end

local function forceUnloadRadiusIpls()
	for i = 1, #radiusEntries do
		local entry = radiusEntries[i]
		if entry and entry.ipl then
			RemoveIpl(entry.ipl)
			radiusApplied[entry.ipl] = false
			mainIplStates[entry.ipl] = false
			if Config.Notify and Config.Notify.debug then
				print("^1[IPL FORCE UNLOAD] " .. entry.ipl .. " (connexion joueur)^7")
			end
			local lodIpl = iplLodMapping[entry.ipl]
			if lodIpl then
				activeLodIpls[lodIpl] = true
				RequestIpl(lodIpl)
				if Config.Notify and Config.Notify.debug then
					print("^3[IPL LOD] Chargement de " .. lodIpl .. " (déchargement de " .. entry.ipl .. ")^7")
				end
			end
		end
	end
	if Config.Notify and Config.Notify.debug and #radiusEntries > 0 then
		notify('Force unloaded ' .. #radiusEntries .. ' radius IPL(s) on player spawn')
	end
end
local function bootstrapAllIpls()
	local uniq = {}
	for _, data in pairs(interiorsRulesById) do
		for _, rule in ipairs(data.rules or {}) do
			for _, ipl in ipairs(rule.ipls or {}) do
				if not hasRadiusCfg[ipl] then
					uniq[ipl] = true
				end
			end
		end
	end
	for ipl, _ in pairs(uniq) do
		if Config.Notify and Config.Notify.debug then
			print("^3[IPL BOOTSTRAP] " .. ipl .. "^7")
		end
		RequestIpl(ipl)
	end
	if Config.Notify and Config.Notify.debug then
		notify('Bootstrap: requested all configured IPLs')
	end
end

local function updateStaticElevators()
	if not staticElevatorsEnabled then
		if next(staticElevatorState) then
			for idx, state in pairs(staticElevatorState) do
				if state.interior and state.entitySets then
					local refreshed = false
					for _, entitySet in ipairs(state.entitySets) do
						if IsInteriorEntitySetActive(state.interior, entitySet) then
							DeactivateInteriorEntitySet(state.interior, entitySet)
							refreshed = true
							if Config.Notify and Config.Notify.debug then
								print(("^1[STATIC ELEVATOR] Deactivated %s on interior %d^7"):format(entitySet,
									state.interior))
							end
						end
					end
					if refreshed then
						RefreshInterior(state.interior)
					end
				end
				staticElevatorState[idx] = nil
				staticElevatorWarnings[idx] = nil
			end
		end
		return
	end

	for idx = 1, #staticElevatorEntries do
		local entry = staticElevatorEntries[idx]
		local pos = entry.pos
		local entitySets = entry.entitySets

		if pos and entitySets and #entitySets > 0 then
			local interior = GetInteriorAtCoords(pos.x, pos.y, pos.z)

			if interior ~= 0 and IsValidInterior(interior) then
				staticElevatorWarnings[idx] = nil

				if not IsInteriorReady(interior) then
					LoadInterior(interior)
				end

				local refreshed = false
				for _, entitySet in ipairs(entitySets) do
					if not IsInteriorEntitySetActive(interior, entitySet) then
						ActivateInteriorEntitySet(interior, entitySet)
						refreshed = true
						if Config.Notify and Config.Notify.debug then
							print(("^2[STATIC ELEVATOR] Activated %s on interior %d^7"):format(entitySet, interior))
						end
					end
				end

				if refreshed then
					RefreshInterior(interior)
				end

				staticElevatorState[idx] = {
					interior = interior,
					entitySets = entitySets,
				}
			else
				if not staticElevatorWarnings[idx] and Config.Notify and Config.Notify.debug then
					print(
						("^3[WARN] Static elevator #%d interior not found (coords %.2f, %.2f, %.2f)^7"):format(
							idx, pos.x, pos.y, pos.z))
					staticElevatorWarnings[idx] = true
				end
			end
		end
	end
end
local function updateNooseGarage()
	local interior = GetInteriorAtCoords(NOOSE_GARAGE_POS.x, NOOSE_GARAGE_POS.y, NOOSE_GARAGE_POS.z)
	if interior == 0 or not IsValidInterior(interior) then return end
	if not IsInteriorReady(interior) then LoadInterior(interior) end

	local toActivate = Config.NooseInterior and 'vspd_garage_noose_enabled' or 'vspd_garage_noose_disabled'
	local toDeactivate = Config.NooseInterior and 'vspd_garage_noose_disabled' or 'vspd_garage_noose_enabled'

	local refreshed = false
	if not IsInteriorEntitySetActive(interior, toActivate) then
		ActivateInteriorEntitySet(interior, toActivate)
		refreshed = true
	end
	if IsInteriorEntitySetActive(interior, toDeactivate) then
		DeactivateInteriorEntitySet(interior, toDeactivate)
		refreshed = true
	end
	if refreshed then RefreshInterior(interior) end
end
AddEventHandler('onClientResourceStart', function(res)
	if res == GetCurrentResourceName() then
		resolveInteriorIdsFromConfig()
		bootstrapAllIpls()
		CreateThread(function()
			-- Attendre que le jeu charge ses IPL par défaut
			Wait(1000)
			-- Forcer le déchargement plusieurs fois pour s'assurer qu'il prend effet
			for i = 1, 3 do
				forceUnloadRadiusIpls()
				Wait(500)
			end
		end)
		updateStaticElevators()
		updateNooseGarage()
	end
end)

CreateThread(function()
	if next(interiorsRulesById) == nil then
		resolveInteriorIdsFromConfig()
		bootstrapAllIpls()
	end
	-- Attendre que le jeu charge ses IPL par défaut
	Wait(1000)
	-- Forcer le déchargement plusieurs fois pour s'assurer qu'il prend effet
	for i = 1, 3 do
		forceUnloadRadiusIpls()
		Wait(500)
	end
	updateStaticElevators()
	updateNooseGarage()

	-- Attendre un peu avant de démarrer la boucle de vérification des radius
	-- pour s'assurer que les IPL sont bien déchargés
	Wait(2000)
	while true do
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		local playerInterior = GetInteriorFromEntity(ped)
		local playerRoomHash = 0

		if playerInterior ~= 0 and IsValidInterior(playerInterior) then
			playerRoomHash = GetRoomKeyFromEntity(ped) or 0
		end

		local decisions = {}
		local removeSet = {}

		for interiorId, data in pairs(interiorsRulesById) do
			local rules = data.rules or {}
			decisions[interiorId] = decisions[interiorId] or {}

			for idx, rule in ipairs(rules) do
				local apply = false
				if playerInterior == interiorId then
					if matchesAnyRoom(rule, playerRoomHash) then
						apply = true
					end
				end
				decisions[interiorId][idx] = apply

				if apply and rule.ipls then
					for _, ipl in ipairs(rule.ipls) do
						removeSet[ipl] = true
					end
				end
			end
		end

		for interiorId, rules in pairs(interiorsRulesById) do
			for idx, rule in ipairs(rules.rules or {}) do
				local apply = decisions[interiorId] and decisions[interiorId][idx]
				local already = appliedStates[interiorId][idx] == true
				if apply and not already then
					setIpls(rule.ipls, true)
					if Config.Notify and Config.Notify.debug then
						notify((rule.label or 'Rule') .. ': removed ' .. tostring(#(rule.ipls or {})) .. ' IPL(s)')
					end
					appliedStates[interiorId][idx] = true
				end
			end
		end

		for interiorId, rules in pairs(interiorsRulesById) do
			for idx, rule in ipairs(rules.rules or {}) do
				local apply = decisions[interiorId] and decisions[interiorId][idx]
				local already = appliedStates[interiorId][idx] == true

				if (not apply) and already then
					local toRequest = {}
					for _, ipl in ipairs(rule.ipls or {}) do
						if not removeSet[ipl] then
							toRequest[#toRequest + 1] = ipl
						end
					end
					if #toRequest > 0 then
						setIpls(toRequest, false)
						if Config.Notify and Config.Notify.debug then
							notify((rule.label or 'Rule') .. ': requested ' .. tostring(#toRequest) .. ' IPL(s)')
						end
					end
					appliedStates[interiorId][idx] = false
				end
			end
		end

		local radius = Config.RadiusIpls
		if radius and radius.entries and #radius.entries > 0 then
			local camCoords = GetFinalRenderedCamCoord()
			for i = 1, #radius.entries do
				local entry = radius.entries[i]
				local pos = entry.pos
				local dist = #(vector3(camCoords.x, camCoords.y, camCoords.z) - vector3(pos.x, pos.y, pos.z))
				-- local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(pos.x, pos.y, pos.z))
				local isLoaded = radiusApplied[entry.ipl] == true
				if dist <= (entry.radius or 0) then
					if not isLoaded then
						RequestIpl(entry.ipl)
						radiusApplied[entry.ipl] = true
						mainIplStates[entry.ipl] = true
						if radiusEnableNotifications then
							notify(('[PullSizePatch] request %s (%.1fm)'):format(entry.ipl, dist))
						end
					end
				else
					if isLoaded then
						if isPlayerInsideEntry(entry) then
							if radiusEnableNotifications then
								notify(('[PullSizePatch] joueur à l\'intérieur, %s non retiré (%.1fm)'):format(entry.ipl,
									dist))
							end
						else
							RemoveIpl(entry.ipl)
							radiusApplied[entry.ipl] = false
							mainIplStates[entry.ipl] = false
							local lodIpl = iplLodMapping[entry.ipl]
							if lodIpl then
								activeLodIpls[lodIpl] = true
								RequestIpl(lodIpl)
								if Config.Notify and Config.Notify.debug then
									print("^3[IPL LOD] Chargement de " ..
										lodIpl .. " (déchargement de " .. entry.ipl .. ")^7")
								end
							end
							if radiusEnableNotifications then
								notify(('[PullSizePatch] remove %s (%.1fm)'):format(entry.ipl, dist))
							end
						end
					end
				end
			end
		end
		local requiredIpls = {}
		for interiorId, data in pairs(interiorsRulesById) do
			local rules = data.rules or {}
			for idx, rule in ipairs(rules) do
				local apply = decisions[interiorId] and decisions[interiorId][idx]
				if apply and rule.ipls then
					for _, ipl in ipairs(rule.ipls) do
						requiredIpls[ipl] = true
					end
				end
			end
		end
		for ipl, isLoaded in pairs(radiusApplied) do
			if isLoaded then
				requiredIpls[ipl] = true
			end
		end

		for lodIpl, isActive in pairs(activeLodIpls) do
			if isActive then
				local mainIplUnloaded = false
				for mainIpl, lodIplCheck in pairs(iplLodMapping) do
					if lodIplCheck == lodIpl then
						if not requiredIpls[mainIpl] then
							mainIplUnloaded = true
							break
						end
					end
				end

				if mainIplUnloaded then
					RequestIpl(lodIpl)
					if Config.Notify and Config.Notify.debug then
						print("^3[IPL LOD] Rechargement forcé de " .. lodIpl .. "^7")
					end
				else
					activeLodIpls[lodIpl] = nil
					if Config.Notify and Config.Notify.debug then
						print("^3[IPL LOD] Désactivation de " .. lodIpl .. " (IPL principal rechargé)^7")
					end
				end
			end
		end
		updateStaticElevators()
		updateNooseGarage()
		Wait(Config.IPL_POLL_INTERVAL or 1000)
	end
end)
