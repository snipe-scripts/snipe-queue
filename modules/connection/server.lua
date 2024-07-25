local Debug = Config.Debug
local JoinDelay = GetGameTimer() + tonumber(Config.JoinDelay)
local MaxPlayers = GetConvarInt('sv_maxclients')
local HostName = GetConvar("sv_hostname") ~= "default FXServer" and GetConvar("sv_hostname") or false
local jsonCard = json.decode(LoadResourceFile(GetCurrentResourceName(), 'presentCard.json'))[1]

local prioritydata = {}
local queuelist = {}
local queuepositions = {}
local connectinglist = {}
local reconnectlist = {}
local playercount = 0


local randomEmojiStrings = {"🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐻", "🐨", "🐯", "🦁", "🐮", "🐷", "🐽", "🐸", "🐵"}

local function ChooseThreeRandomEmojis()
    local emojis = {}
    for i = 1, 3 do
        emojis[i] = randomEmojiStrings[math.random(1, #randomEmojiStrings)]
    end
    return emojis[1] .. emojis[2] .. emojis[3]
end

local function updateCard(data)
    local pCard = jsonCard
    local date = os.date( "%a %b %d, %H:%M")
    pCard.body[1]["columns"][1]["items"][2]["columns"][1]["items"][1].text = string.format('Queue: %d/%d', data.pos, data.maxpos)
    pCard.body[1]["columns"][1]["items"][3].text = ChooseThreeRandomEmojis()
    pCard.body[1]["columns"][2]["items"][2]["columns"][1]["items"][1].text = date.." EST" -- change the timezone based on your server machine timezone
    pCard.body[1]["columns"][2]["items"][2]["columns"][2]["items"][1].text = "Points: "..tostring(data.points)
    return pCard
end

local function getPrioData(identifier)
    return prioritydata[identifier]
end exports('getPrioData', getPrioData)

local function isInQueue(ids)
    local identifier = ids[Config.Identifier]
    local qpos, qdata = nil, nil
    for pos, data in ipairs(queuelist) do
        if data.id == identifier then
            qpos, qdata = pos, data
            break
        end
    end
    return qpos, qdata
end exports('isInQueue', isInQueue)

local function setQueuePos(identifier, newPos)
    if newPos <= 0 or newPos > #queuelist then return false end
    if not queuepositions[identifier] then return false end
    local currentPos = queuepositions[identifier]
    local data = queuelist[currentPos]
    if not data then return false end
    table.remove(queuelist, currentPos)
    table.insert(queuelist, newPos, data)
    queuepositions[identifier] = newPos

    return true
end exports('setQueuePos', setQueuePos)

local function getQueuePos(identifier)
    return queuepositions[identifier]
end exports('getQueuePos', getQueuePos)

local function updateQueuePositions()
    for k, v in ipairs(queuelist) do
        if k ~= queuepositions[v.id] then
            queuepositions[v.id] = k
        end
    end
    return true
end

local function addToQueue(ids, points)
    local index = #queuelist + 1
    local currentTime = os.time()
    local data = { id = ids[Config.Identifier], ids = ids, points = points, qTime = function() return (os.time()-currentTime) end }
    local newPos = index
    for pos, data in ipairs(queuelist) do
        if data.points >= points then
            newPos = pos + 1
        else
            newPos = pos
            break
        end
    end
    table.insert(queuelist, newPos, data)
    updateQueuePositions()

    return data
end

local function removeFromQueue(ids)
    local identifier = ids[Config.Identifier]
    for pos, data in ipairs(queuelist) do
        if identifier == data.id then
            queuepositions[identifier] = nil
            table.remove(queuelist, pos)
            updateQueuePositions()
            return true
        end
    end

    return false
end

local function isInConnecting(identifier)
    for pos, data in ipairs(connectinglist) do
        if identifier == data.id then
            return true, pos
        end
    end
    return false, false
end

local function addToConnecting(source, identifiers)
    if not source or not identifiers then return end
    local currentTime = os.time()
    local identifier = identifiers[Config.Identifier]
    local isConnecting, position = isInConnecting(identifier)
    if isConnecting then
        connectinglist[position] = {
            source = source,
            id = identifier,
            timeout = 0,
            cTime = function() return (os.time()-currentTime) end
        }
    else
        local index = #connectinglist + 1
        local cData = {
            source = source,
            id = identifier,
            timeout = 0,
            cTime = function() return (os.time()-currentTime) end
        }
        table.insert(connectinglist, index, cData)
    end
    removeFromQueue(identifiers)
end

local function removeFromConnecting(identifier)
    for pos, data in ipairs(connectinglist) do
        if identifier == data.id then
            table.remove(connectinglist, pos)
            break
        end
    end
end

local function canJoin()
    return (((#connectinglist + playercount) < MaxPlayers) and (JoinDelay <= GetGameTimer()))
end exports('canJoin', canJoin)

local function getIdentifiers(src)
    if not src then return nil end
    local identifiers = {}
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        local index = tostring(id:match("(%w+):"))
        identifiers[index] = id
    end
    return identifiers
end

AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
    deferrals.defer()
    local source = source
    local identifiers = getIdentifiers(source)
    -- if in connecting then drop from connecting
    if isInConnecting(identifiers[Config.Identifier]) then
        removeFromConnecting(identifiers[Config.Identifier])
        Wait(500)
    end
    -- this disallows player from spamming the connect button after canceling
    if Config.AntiSpam.enabled then
        deferrals.update(Lang.please_wait)
        Wait(math.random(Config.AntiSpam.time, Config.AntiSpam.time + 5000))
    end
    Wait(0)
    deferrals.update(Lang.checking_identifiers)
    -- if identifiers is null then reject connection
    if not identifiers then
        deferrals.done(Lang.ids_doesnt_exist)
        CancelEvent()
        return
    end
    Wait(0)
    -- checks all mentioned identifier which is needed to connect to server
    for _, id in ipairs(Config.RequiredIdentifiers) do
        if not identifiers[id] then
            deferrals.done(string.format(Lang.id_doesnt_exist, id))
            CancelEvent()
            return
        end
    end
    Wait(0)
    deferrals.update(Lang.checking_roles)
    -- checks if player is whitelisted and assigns points based on discord roles
    if Config.Discord.enabled then
        -- gets player's all roles on discord guild
        local playerroles = GetUserRoles(identifiers['discord'])
        if not playerroles then
            deferrals.done(Lang.join_discord)
            CancelEvent()
            return
        end
        local whitelisted = false
        local cIdentifier = identifiers[Config.Identifier]
        -- clear previous data to add new data
        if prioritydata[cIdentifier] then prioritydata[cIdentifier] = {} end
        -- add/update prio data for a identifier
        for _, role in pairs(playerroles) do
            if Config.Discord.roles[role] then
                if whitelisted then
                    prioritydata[cIdentifier].points = prioritydata[cIdentifier].points + Config.Discord.roles[role].points
                else
                    whitelisted = true
                    prioritydata[cIdentifier] = {}
                    prioritydata[cIdentifier].points  = Config.Discord.roles[role].points
                    prioritydata[cIdentifier].name = Config.Discord.roles[role].name
                end
            end
        end
        if not whitelisted then
            deferrals.done(Lang.not_whitelisted)
            CancelEvent()
            return
        end
        if Config.ReconnectPrio.enabled then
            if reconnectlist[cIdentifier] then
                prioritydata[cIdentifier].points = prioritydata[cIdentifier].points + Config.ReconnectPrio.points
            end
        end
    end
    Wait(0)
    -- allow in server if server is not full, instead of putting in queue
    if canJoin() then
        addToConnecting(source, identifiers)
        deferrals.done()
        CancelEvent()
        return
    end
    Wait(0)
    if isInQueue(identifiers) then
        deferrals.done(Lang.already_in_queue)
        CancelEvent()
        return
    end
    Wait(0)
    -- place player in queue if server is full
    local data = addToQueue(identifiers, prioritydata[identifiers[Config.Identifier]].points)
    if not data then
        deferrals.done(Lang.could_not_connect)
        CancelEvent()
        return
    end
    Wait(0)
    while data and queuepositions[data.id] do
        Wait(3000)
        -- allow player inside server if slots are empty
        if queuepositions[data.id] <= 1 and canJoin() then
            addToConnecting(source, data.ids)
            deferrals.update(Lang.joining_now)
            Wait(1000)
            deferrals.done()
            CancelEvent()
            return
        end

        -- checks if player has left queue
        local endpoint = GetPlayerEndpoint(source)
        if not endpoint then
            removeFromQueue(data.ids)
            deferrals.done(Lang.timed_out)
            CancelEvent()
            return
        end

        -- add your deferrals present card here
        local displayCard = updateCard({pos=queuepositions[data.id], maxpos=#queuelist, qTime = data.qTime, points = data.points})
        deferrals.presentCard(displayCard, function(data, rawdata) end)
    end
    deferrals.done()
end)

CreateThread(function()
    while true do
        Wait(5000)
        if #connectinglist < 1 then goto skipLoop end
        for pos, data in ipairs(connectinglist) do
            local endpoint = GetPlayerEndpoint(data.source)
            if not endpoint or data.cTime() >= Config.Timeout then
                removeFromConnecting(data.id)
                DebugPrint(string.format('%s has been timed out while connecting to server', data.id))
            end
        end
        ::skipLoop::
        local currentTime = os.time()
        for identifier, expire in pairs(reconnectlist) do
            if expire < currentTime then
                reconnectlist[identifier] = nil
            end
        end
    end
end)

AddEventHandler("playerJoining", function(source, oldid)
    local identifiers = getIdentifiers(source)

    playercount = playercount + 1
    removeFromConnecting(identifiers[Config.Identifier])
end)

AddEventHandler("playerDropped", function()
    local source = source
    local identifiers = getIdentifiers(source)
    playercount = playercount - 1

    if Config.ReconnectPrio.enabled then
        reconnectlist[identifiers[Config.Identifier]] = os.time() + (Config.ReconnectPrio.time * 60)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local playerPool = GetPlayers()
    playercount = #playerPool
    DebugPrint('Players: '..playercount)
end)

local function getQueueCount()
    return queuelist
end exports('getQueueCount', getQueueCount)