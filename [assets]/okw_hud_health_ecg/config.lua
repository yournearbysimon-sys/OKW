--[[
  Placement is fixed on screen. If the strip does not sit under jg-hud circles,
  tweak offsetLeft / offsetBottom / stripWidth (vw/vh/px all work).
]]
Config = {
    offsetLeft   = "0.55vw",
    offsetBottom = "20.8vh",
    stripWidth   = "clamp(268px, 34vw, 440px)",
    -- Poll interval for health natives (ms).
    updateIntervalMs = 100,
}
