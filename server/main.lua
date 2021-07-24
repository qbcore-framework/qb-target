RegisterServerEvent("bt-target:loginvalidcall")
AddEventHandler("bt-target:loginvalidcall", function(event)
    print(("^1 [%s, %s] attempted to call invalid event %s^0"):format(GetPlayerName(source), GetPlayerIdentifier(source, 0), event))
    if Config.DropPlayer then
        DropPlayer(source, ("Attemping to call an invalid event through %s"):format(GetCurrentResourceName()))
    end
end)
