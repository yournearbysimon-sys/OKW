-- This is a heavily modified & highly simplified version of nearest postal from @DevBlocky: https://github.com/DevBlocky/nearest-postal
-- just for the purposes of displaying it in the HUD, as the exports for getting distance to nearest postal wasn't available.
-- This IS NOT designed to be a replacement for nearest-postal, as it does not include commands for waypoints etc. I recommend still
-- using nearest-postal alongside JG HUD!

---- ORIGINAL LICENSE ----

-- Copyright (c) 2019 BlockBa5her

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

NearestPostal = NearestPostal or {}
NearestPostal.Client = NearestPostal.Client or {}

---@type boolean
local postalsLoaded = false

CreateThread(function()
  if not Config.ShowNearestPostal then return end

  local jsonData = LoadResourceFile(GetCurrentResourceName(), Config.NearestPostalsData)
  if not jsonData then
    return Utils.Client.DebugPrint(("[ERROR] Could not find postals data file: %s"):format(Config.NearestPostalsData))
  end

  local postals = json.decode(jsonData)

  if not postals then
    return Utils.Client.DebugPrint("[ERROR] Failed to decode postals JSON data")
  end

  for i = 1, #postals do
    local postal = postals[i]
    lib.grid.addEntry({
      coords = vec(postal.x, postal.y),
      code = postal.code,
      radius = 1
    })
  end

  postalsLoaded = true
  Utils.Client.DebugPrint(("Loaded %d postal codes into ox_lib grid system"):format(#postals))
end)

---@param pos vector
---@return {code: string, dist: number} | false
function NearestPostal.Client.Get(pos)
  if not Config.ShowNearestPostal or not postalsLoaded then
    return false
  end

  local nearbyEntries = lib.grid.getNearbyEntries(pos)
  if not nearbyEntries or #nearbyEntries == 0 then
    return false
  end

  local closestEntry, minDist

  -- Check only nearby entries from grid
  for i = 1, #nearbyEntries do
    local entry = nearbyEntries[i]
    local dx = pos.x - entry.coords.x
    local dy = pos.y - entry.coords.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if not minDist or dist < minDist then
      closestEntry = entry
      minDist = dist
    end
  end

  if not closestEntry then
    return false
  end

  return {
    code = closestEntry.code,
    dist = math.round(Framework.Client.ConvertDistance(minDist, UserSettings.Client.Get("distanceMeasurement")))
  }
end
