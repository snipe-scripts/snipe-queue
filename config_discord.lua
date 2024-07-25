Config = Config or {}

Config.Discord = {
    enabled = true, -- you want whitelist/priority modules?
    bottoken = '', -- bot token
    serverid = '', -- discord serverid
    roles = {
        -- roleid = table (name, points)
        ['<role_id>'] = {name = "Guest", points = 0},
        ['<role_id2>'] = {name = "Member", points = 1000},
        ['<role_id3>'] = {name = "VIP", points = 2000},
        ['<role_id4>'] = {name = "Moderator", points = 3000},
        ['<role_id5>'] = {name = "Admin", points = 4000},
    }
}
