--- OKW: after editing layout in /hud, run `hudexport` (F8 console) or your keybind to print saved layout/settings for copying into default-settings.json.

local function printLong(label, text)
    if not text or text == "" then return end
    print(("^3[%s]^7"):format(label))
    local chunk = 3800
    for i = 1, #text, chunk do
        print(text:sub(i, i + chunk - 1))
    end
end

local function tryPrintKvp()
    local prefix = Config.DefaultSettingsKvpPrefix or "hud-"
    local keys = {
        prefix .. "settings",
        prefix .. "data",
        prefix .. "layout",
        prefix .. "userSettings",
        prefix .. "saved",
        "jg-hud-settings",
        "jg_hud_settings",
        "okw-ecg-layout",
    }
    local any = false
    for _, key in ipairs(keys) do
        local v = GetResourceKvpString(key)
        if v and v ~= "" then
            any = true
            printLong("KVP:" .. key, v)
        end
    end
    if not any then
        print("^3[HUD export]^7 No matching resource KVP strings (jg-hud may use different key names). Check localStorage block below.")
    end
end

RegisterNUICallback("okwHudSettingsDump", function(data, cb)
    cb("ok")
    if type(data) ~= "table" then return end
    local ls = data.localStorage
    if type(ls) == "table" and next(ls) then
        local ok, encoded = pcall(json.encode, ls)
        if ok and encoded then
            printLong("NUI localStorage (copy inner JSON if this is your layout)", encoded)
        end
    else
        print("^3[NUI localStorage]^7 empty — settings may live only in KVP or in-memory until save.")
    end
    local ss = data.sessionStorage
    if type(ss) == "table" and next(ss) then
        local ok, encoded = pcall(json.encode, ss)
        if ok and encoded then
            printLong("NUI sessionStorage", encoded)
        end
    end
end)

local function requestNuiDump()
    SendNUIMessage({ action = "okw-hud-export-request" })
end

local function runExport()
    print("^2========================================^7")
    print("^2[jg-hud]^7 Layout / settings export (^5hudexport^7)")
    print("^7Paste useful JSON into ^5data/default-settings.json^7 (layout + settings) as needed.")
    print("^2========================================^7")
    tryPrintKvp()
    requestNuiDump()
end

RegisterCommand("hudexport", function()
    runExport()
end, false)

CreateThread(function()
    local key = Config.HudExportKeybind
    if type(key) ~= "string" or key == "" or key == "false" then return end
    RegisterKeyMapping("okw_hud_export", "Dump HUD layout to console (hudexport)", "keyboard", key)
    RegisterCommand("okw_hud_export", function()
        runExport()
    end, false)
end)
