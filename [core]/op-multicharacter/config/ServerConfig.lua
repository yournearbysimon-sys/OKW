ServerConfig = {}
ServerConfig.LogsWebhook = "https://discord.com/api/webhooks/" -- Discord webhook.

ServerConfig.DisableBuckets = false -- Disable routing bucket change

ServerConfig.DiscordRanks = {
    enable = false,
    botToken = "", -- Discord Bot Token.
    serverId = "988478565790122095",
    ranks = {
        -- SCHEMA: ["role_discord_id"] = amount of available slots
        ["1438914499506733310"] = 3,
        ["1438914514279071834"] = 2,
        ["1438914530141798400"] = 5,
    }
}

ServerConfig.DisableAutoSql = false -- Enable/Disable auto sql injection for slots data!

ServerConfig.Commands = {
    logout = {
        enable = true, 
        command = "logout",
        allowed = "user"
    },
    setslots = {
        enable = true, 
        command = "setslots",
        allowed = "admin"
    },
}

ServerConfig.LogsData = {
    ['character_loaded'] = {
        color = 706333,
        header = "Player Connected",
        desc = "**Character Name:** `%s`\n**Character ID:** `%s`\n**Player Identifiers:** ```%s```"
    },
    ['character_created'] = {
        color = 706333,
        header = "Character Created",
        desc = "**Name:** `%s`\n**ID:** `%s`\n**Nationality:** `%s`\n**Birthday:** `%s`\n**Gender:** `%s`\n**Height:** `%s`\n**Player Identifiers:** ```%s```\n**Starting Items:** ```%s```"
    },
    ['character_unloaded'] = {
        color = 13044234,
        header = "Character Log Out",
        desc = "**Character Name:** `%s`\n**Character ID:** `%s`\n**Player Identifiers:** ```%s```"
    },
    ['slotsadded'] = {
        color = 706333,
        header = "Slots Added",
        desc = "**Admin:** `%s`\n**License:** `%s`\n**Amount:** `%s`"
    },
}

-- ──────────────────────────────────────────────────────────────────────────────
-- (Information) ► Formats webhook message based on LogsData entry and sends it.
-- (Information) ► Usage example:
--                 ServerConfig.formatWebHook("character_created", arg1, arg2, ...)
-- ──────────────────────────────────────────────────────────────────────────────
---@param logType string   -- key in ServerConfig.LogsData
---@param ... any          -- formatting params for desc
---@return table           -- { title = "", color = 0, message = "" }
ServerConfig.formatWebHook = function(logType, ...)
    local log = ServerConfig.LogsData[logType]
    if not log then
        print("^1[OP-MULTICHARACTER] Invalid logType: " .. tostring(logType))
        return false
    end

    local formattedDesc = string.format(log.desc, ...)

    local embed = {{
        ["color"] = log.color,
        ["title"] = log.header,
        ["description"] = formattedDesc,
        ["footer"] = { text = os.date("%c") .. " (Server Time)." }
    }}

    PerformHttpRequest(ServerConfig.LogsWebhook,
        function(err, text, headers) end,
        "POST",
        json.encode({ username = "OP Multicharacter", embeds = embed }),
        { ["Content-Type"] = "application/json" }
    )
end