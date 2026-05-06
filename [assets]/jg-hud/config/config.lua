Config = {}
Config.Locale = "en"
Config.Currency = "$"
Config.NumberFormat = "en-US" -- follows [language]-[country code]

-- Integrations
Config.Framework = "auto" -- or "QBCore", "Qbox", "ESX"
Config.FuelSystem = "ox_fuel" -- or "LegacyFuel", "lc_fuel", "ps-fuel", "lj-fuel", "ox_fuel", "cdn-fuel", "hyon_gas_station", "okokGasStation", "nd_fuel", "myFuel", "ti_fuel", "Renewed-Fuel", "rcore_fuel", "none"

-- Measurements
Config.SpeedMeasurement = "mph" -- or "kph"
Config.DistanceMeasurement = "feet" -- or "meters"

-- Cruise Control
Config.EnableCruiseControl = true
Config.CruiseControlKeybind = "J"

-- Seatbelt
Config.EnableSeatbelt = true
Config.UseCustomSeatbeltIntegration = false -- Enable to use a third-party seatbelt script via Framework.Client.ToggleSeatbelt (in framework/cl-functions.lua)
Config.SeatbeltKeybind = "B"
Config.PreventExitWhileBuckled = true
Config.DisablePassengerSeatbelts = false
Config.MinSpeedMphEjectionSeatbeltOff = 20.0
Config.MinSpeedMphEjectionSeatbeltOn = 100.0
Config.DisableSeatbeltInEmergencyVehicles = true

-- Default component displays
Config.ShowMinimapOnFoot = false
Config.ShowCompassOnFoot = true
Config.ShowComponents = {
  pedAvatar = false, -- Seems to be unstable with some clients, best to leave disabled for now
  voiceOrRadio = true,
  serverId = false,
  time = false,
  job = false,
  gang = false,
  bankBalance = false,
  cashBalance = false,
  dirtyMoneyBalance = false,
  weapon = false,
  serverLogo = true -- You can enable this and then change the server-logo.png in the root folder
}

-- If ShowComponents.serverLogo & Config.AllowUsersToEditLayout are enabled, should players be able to edit the logo's visibility/position?
Config.AllowServerLogoEditing = true

-- Vehicle Control
Config.VehicleControlKeybind = "F6"
Config.AllowPassengersToUseVehicleControl = true -- Passengers are only able to toggle their own window, door or change seats

-- Other keybinds; set them to false to disable
Config.EngineToggleKeybind = false
Config.BoatAnchorKeybind = "J"
Config.IndicatorLeftKeybind = "LEFT"
Config.IndicatorRightKeybind = "RIGHT"
Config.IndicatorHazardsKeybind = "UP"

-- Commands
Config.OpenSettingsCommand = "hud"
Config.ToggleHudCommand = "hudoff"

-- Nearest postal
-- Credit to https://github.com/DevBlocky/nearest-postal - see license in data/nearest-postal/LICENSE
Config.ShowNearestPostal = true
Config.NearestPostalsData = "data/nearest-postal/ocrp-postals.json"

-- Learn more about configuring default settings: https://docs.jgscripts.com/hud/default-settings
Config.DefaultSettingsData = "data/default-settings.json"
Config.DefaultSettingsKvpPrefix = "hud-" -- This is really useful for essentially "resetting" everyone's currently saved settings, especially if you've added a new default-settings.json profile. You can set this to like "hud-v2-" for example so that everyone's existing data starts fresh with your new profile.
Config.AllowPlayersToEditSettings = true
Config.AllowUsersToEditLayout = true

-- Dev/debug settings
Config.UpdateRadarZoom = true -- Enable this if radar is flicking/disappearing
Config.DevDeleteAllUserSettingsOnStart = true -- Delete player existing KVP when they log in?
Config.Debug = false

-- OKW cardiac strip: lives outside jg-hud React — /hud cannot drag it as one box (fragmented handles).
-- Use /ecglayout (ox_lib) to set px position; Confirm writes resource KVP (persistent across restarts). /hud + hudexport still apply to native widgets only.
Config.HealthEcg = {
    Enabled = true,
    offsetLeft = "0.55vw",
    offsetBottom = "2.75vh",
    stripWidth = "clamp(268px, 34vw, 440px)",
    updateIntervalMs = 100,
    syncLayoutFromKvp = true,
    layoutPollMs = 500,
    --- Dedicated KVP JSON: {"left":11,"bottom":30,"width":400,"offsetX":0,"offsetY":0,"hidden":false}
    dedicatedLayoutKvpKey = "okw-ecg-layout",
    --- Still read legacy hud-layout.okwHealthEcg if dedicated KVP is empty (old installs).
    useLegacyHudLayoutKey = true,
    --- ox_lib dialog to edit position (set false to disable the command).
    LayoutCommand = "ecglayout",

    useStaminaForStrip = true,
    staminaMax = 40.0,

    FaintEnabled = true,
    faintStaminaThresholdPct = 4.0,
    faintHoldSprintMs = 1000,
    faintDurationMs = 10000,
    faintRecoverStamina = 0.42,
    faintCheckIntervalMs = 120,
}

-- OKW: print HUD layout/settings to the client console (open with F8, then type hudexport). Optional keybind below (F8 often opens console, so default is F9).
Config.HudExportKeybind = "F9"