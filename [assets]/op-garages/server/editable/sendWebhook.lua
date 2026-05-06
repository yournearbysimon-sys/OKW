function SendWebHook(title, color, message)
    local embedMsg = {}
    timestamp = os.date("%c")
    embedMsg = {
        {
            ["color"] = color,
            ["title"] = title,
            ["description"] =  message,
            ["footer"] ={
                ["text"] = timestamp.." (Server Time).",
            },
        }
    }
    PerformHttpRequest(ServerConfig.WebHook,
    function(err, text, headers)end, 'POST', json.encode({username = "OP Garages", embeds = embedMsg}), { ['Content-Type']= 'application/json' })
end

WHData = {
    carAdded = {
        head = "CAR ADDED TO DATABASE",
        desc = "**Model:** `%s`\n**Plate:** `%s`\n**Player/Job/Gang:** `%s`\n**Administrator:** `%s`"
    },
    vehDel = {
        head = "CAR DELETED",
        desc = "**Plate:** `%s`\n**Administrator:** `%s`"
    },
    subOwnerAdded = {
        head = "SUBOWNER ADDED",
        desc = "**Plate:** `%s`\n**Owner:** `%s`\n**Assigned To:** `%s`"
    },
    subOwnerDel = {
        head = "SUBOWNER DELETED",
        desc = "**Plate:** `%s`\n**Owner:** `%s`"
    },
}