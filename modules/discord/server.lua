if Config.Discord then
CreateThread(function ()

function GetUserRoles(discordid)
    local data = nil
    local colonIndex = string.find(discordid, ":")
    discordid = string.sub(discordid, colonIndex + 1)
    PerformHttpRequest(string.format("https://discordapp.com/api/guilds/%s/members/%s", Config.Discord.serverid, discordid), function(statusCode, response, headers)
        if statusCode == 200 then
		    response = json.decode(response)
            data = response['roles']
        end
        if statusCode == 404 then
            data = false
        end
    end, 'GET', "", {["Content-Type"] = "application/json", ["Authorization"] = "Bot "..Config.Discord.bottoken})

    while data == nil do
        Wait(0)
    end

    return data
end exports('GetUserRoles', GetUserRoles)

end)

end