-- enyo-aiambulance | server/main.lua
-- Core server logic: dispatch coordination, revive triggering, EMS notification routing

--------------------------------------------------------------
-- REVIVE PLAYER
-- Triggered by the client after the AI medic completes its sequence.
-- Routes the revive event back to the requesting player.
--------------------------------------------------------------

RegisterNetEvent('enyo-aiambulance:server:revivePlayer')
AddEventHandler('enyo-aiambulance:server:revivePlayer', function(extraVars)
    local src = source
    if Config.debug then
        print("[enyo-aiambulance] Reviving player: " .. tostring(src))
    end
    TriggerClientEvent('enyo-aiambulance:client:revivehandle', src, extraVars or {})
end)

--------------------------------------------------------------
-- NOTIFY EMS
-- Triggered by the client when the ambulance reaches the hospital
-- OR when Config.revive is false (drop-off mode).
-- Sends the EMS alert to the requesting player's client.
--------------------------------------------------------------

RegisterNetEvent('enyo-aiambulance:server:notifyEMS')
AddEventHandler('enyo-aiambulance:server:notifyEMS', function(extraVars)
    local src = source
    if Config.debug then
        print("[enyo-aiambulance] Notifying EMS for player: " .. tostring(src))
    end
    TriggerClientEvent('enyo-aiambulance:client:notifyEMS', src, extraVars or {})
end)

--------------------------------------------------------------
-- DISPATCH ALLOWED CHECK
-- Optional server-side hook. Clients can request a validation
-- check before the dispatch proceeds. Useful for future
-- server-authoritative restrictions (e.g., during events, jail).
--------------------------------------------------------------

RegisterNetEvent('enyo-aiambulance:server:checkDispatchAllowed')
AddEventHandler('enyo-aiambulance:server:checkDispatchAllowed', function()
    local src = source
    TriggerClientEvent('enyo-aiambulance:client:isAmbulanceDispatchAllowed', src)
end)

-- Receives the allowed/denied response from the client and logs it when debug is on
RegisterNetEvent('enyo-aiambulance:client:isAmbulanceDispatchAllowedResponse')
AddEventHandler('enyo-aiambulance:client:isAmbulanceDispatchAllowedResponse', function(allowed)
    local src = source
    if Config.debug then
        print("[enyo-aiambulance] Dispatch allowed response from player "
            .. tostring(src) .. ": " .. tostring(allowed))
    end
end)

--------------------------------------------------------------
-- DEBUG: Resource Start Log
--------------------------------------------------------------

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("[enyo-aiambulance] Server-side resource started. Framework: " .. tostring(Config.core))
    end
end)
