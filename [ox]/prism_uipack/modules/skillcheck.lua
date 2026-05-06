---@diagnostic disable: duplicate-doc-alias
---@diagnostic disable: duplicate-doc-field

---@type promise?
local skillcheck

---@alias SkillCheckDifficulity 'easy' | 'medium' | 'hard' | { areaSize: number, speedMultiplier: number }

---@class SkillcheckOptions
---@field label string? Defaults to "Skillcheck"
---@field instruction string? Defaults to "Press the corresponding key"
---@field type 'circle' | 'rect' Defaults to circle

---@param difficulty SkillCheckDifficulity | SkillCheckDifficulity[]
---@param inputs string[]?
---@param options SkillcheckOptions?
---@return boolean?
function SkillCheck(difficulty, inputs, options)
    if skillcheck then return end
    skillcheck = promise:new()
    options = options or {}

    Utils.setNuiFocus(false, true)
    SendNUIMessage({
        action = 'startSkillCheck',
        data = {
            difficulty = difficulty or { 'easy' },
            keys = inputs or { 'e' },
            label = options.label,
            instruction = options.instruction,
            type = options.type
        }
    })

    return Citizen.Await(skillcheck)
end

function CancelSkillCheck()
    if not skillcheck then
        error('No skillCheck is active')
    end

    SendNUIMessage({action = 'skillCheckCancel'})
end

---@return boolean
function SkillCheckActive()
    return skillcheck ~= nil
end

RegisterNUICallback('skillCheckOver', function(success, cb)
    cb(1)

    if skillcheck then
        Utils.resetNuiFocus()

        skillcheck:resolve(success)
        skillcheck = nil
    end
end)