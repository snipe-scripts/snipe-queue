function DebugPrint(msg)
    if Config.Debug then print('^1[Debug]: ^2'.. msg..'^0') end
end


if Config.DisableHardCap then
AddEventHandler("onResourceStarting", function(resource)
    if resource == "hardcap" then CancelEvent() return end
end)

CreateThread(function()
    Wait(2000)
    StopResource("hardcap")
    DebugPrint('Hardcap has been stopped')
end)
end