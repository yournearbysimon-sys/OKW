---@diagnostic disable: duplicate-doc-alias
---@diagnostic disable: duplicate-doc-field

local luaConfig = {}
local useConvars = false

local function loadLuaConfig()
    local configContent = LoadResourceFile(GetCurrentResourceName(), "config.lua")
    if configContent then
        local loadedConfig = load(configContent)()
        if loadedConfig then
            luaConfig = loadedConfig
            useConvars = loadedConfig.useConvars == true
        end
    end
end

local function getConfigValue(key, defaultValue)
    if useConvars then
        local convarValue = GetConvar("prism:" .. key, "")
        return convarValue ~= "" and convarValue or defaultValue
    end
    return luaConfig[key] ~= nil and luaConfig[key] or defaultValue
end

loadLuaConfig()

local contextMenus = {}
local openContextMenu = nil

---@class ContextMenuItem
---@field title? string
---@field menu? string
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string
---@field image? string
---@field progress? number
---@field onSelect? fun(args: any)
---@field arrow? boolean
---@field description? string
---@field metadata? string | { [string]: any } | string[]
---@field disabled? boolean
---@field readOnly? boolean
---@field event? string
---@field serverEvent? string
---@field args? any

---@class ContextMenuArrayItem : ContextMenuItem
---@field title string

---@class ContextMenuProps
---@field id string
---@field title string
---@field subtitle? string
---@field titleIcon? string
---@field sectionTitle? string
---@field sectionIcon? string
---@field footerLabel? string
---@field menu? string
---@field onExit? fun()
---@field onBack? fun()
---@field canClose? boolean
---@field position? "right" | "left"
---@field options { [string]: ContextMenuItem } | ContextMenuArrayItem[]

local function closeContext(_, cb, onExit)
    if cb then cb(1) end

    Utils.resetNuiFocus()

    if not openContextMenu then return end

    if (cb or onExit) and contextMenus[openContextMenu].onExit then contextMenus[openContextMenu].onExit() end

    TriggerEvent("prism_uipack:contextClosed")
    if not cb then SendNUIMessage({ action = 'hideContext' }) end

    openContextMenu = nil
end

---@param id string
function ShowContext(id)
    if not contextMenus[id] then error('No context menu of such id found.') end

    local data = contextMenus[id]
    openContextMenu = id

    Utils.setNuiFocus(false)
    TriggerEvent("prism_uipack:contextOpened")

    local position = data.position or getConfigValue("contextMenuPosition", "right")

    SendNuiMessage(json.encode({
        action = 'showContext',
        data = {
            title = data.title,
            subtitle = data.subtitle,
            titleIcon = data.titleIcon,
            sectionTitle = data.sectionTitle,
            sectionIcon = data.sectionIcon,
            footerLabel = data.footerLabel,
            canClose = data.canClose,
            menu = data.menu,
            position = position,
            options = Utils.sanitizeItems(data.options)
        }
    }, { sort_keys = true }))
end

---@param context ContextMenuProps | ContextMenuProps[]
function RegisterContext(context)
    for k, v in pairs(context) do
        if type(k) == 'number' then
            contextMenus[v.id] = v
        else
            contextMenus[context.id] = context
            break
        end
    end
end

---@return string?
function GetOpenContextMenu() return openContextMenu end

---@param onExit boolean?
function HideContext(onExit) closeContext(nil, nil, onExit) end

RegisterNUICallback('openContext', function(data, cb)
    if data.back and contextMenus[openContextMenu].onBack then contextMenus[openContextMenu].onBack() end
    cb(1)
    ShowContext(data.id)
end)

RegisterNUICallback('clickContext', function(id, cb)
    cb(1)

    if math.type(tonumber(id)) == 'float' then
        id = math.tointeger(id)
    elseif tonumber(id) then
        id += 1
    end

    local data = contextMenus[openContextMenu].options[id]

    if not data.event and not data.serverEvent and not data.onSelect then return end

    openContextMenu = nil

    SendNUIMessage({ action = 'hideContext' })
    Utils.resetNuiFocus()

    TriggerEvent("prism_uipack:contextClosed")

    if data.onSelect then data.onSelect(data.args) end
    if data.event then TriggerEvent(data.event, data.args) end
    if data.serverEvent then TriggerServerEvent(data.serverEvent, data.args) end
end)

RegisterNUICallback('closeContext', closeContext)
