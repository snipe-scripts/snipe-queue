Config = Config or {}

-- queue debug?
Config.Debug = false

-- this is the identifier which is required to join server
Config.RequiredIdentifiers = { 'license', 'discord' }

-- this identifier will be used to perform actions / store data
Config.Identifier = 'discord'

-- disables hardcap, should keep this true
Config.DisableHardCap = true

-- this makes person wait before even they initialize connection to prevent exploits
Config.AntiSpam = {
    enabled = true,
    time = 10 * 1000 -- 10 secs
}

-- timeout connection when they cross below time while they try connnecting
Config.Timeout = 300 -- 5 mins (300 secs)

-- server join delay even if slots are free you cannot join server deu to this delay
Config.JoinDelay = 3 * 60 * 1000 -- 3 mins (miliseconds)

-- assign temporary power when someone crashes/reconnects
Config.ReconnectPrio = {
    enabled = true,
    points = 1000, -- this gets added to existing points
    time = 5 -- 5 mins
}