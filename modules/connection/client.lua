CreateThread(function()
    while true do
        Wait(1)
        if NetworkIsSessionStarted() then
            TriggerServerEvent("queue:playerInitiated")
            return
        end
    end
end)