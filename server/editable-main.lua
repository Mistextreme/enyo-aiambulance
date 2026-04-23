RegisterNetEvent('enyo-aiambulance:esx_billing:sendBill', function(amount, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        -- Get player's bank account balance
        local bankAccount = xPlayer.getAccount('bank')
        -- Remove money from the player's bank account
        xPlayer.removeAccountMoney('bank', amount)
        TriggerClientEvent('esx:showNotification', source, "You have been billed $" .. amount .. " for: " .. reason)
    end
end)

RegisterNetEvent('enyo-aiambulance:qb-billing:sendBill', function(amount, reason)
    local src = source
    local QBCore = exports[Config.core]:GetCoreObject()
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.RemoveMoney('bank', amount)  -- Remove the money from the player
        TriggerClientEvent('QBCore:Notify', src, "You have been billed $" .. amount .. " for: " .. reason)
    end
end)

RegisterServerEvent('countAmbulancePlayers_QB')
AddEventHandler('countAmbulancePlayers_QB', function()
    -- Ensure QBCore is retrieved successfully
    local QBCore = exports[Config.core]:GetCoreObject()
    if not QBCore then
        if Config.debug then
            print("Error: Failed to retrieve QBCore")
        end
        return
    end

    local ambulanceCount = 0

    -- Get players and ensure the list is not nil
    local players = QBCore.Functions.GetPlayers()
    if players and #players > 0 then
        for _, playerId in ipairs(players) do
            -- Retrieve player and ensure it's valid
            local player = QBCore.Functions.GetPlayer(playerId)
            if player and player.PlayerData and player.PlayerData.job then
                local jobName = player.PlayerData.job.name
                local onduty = player.PlayerData.job.onduty

                -- Check if player is EMS, count them if 'onduty' is nil or true
                if jobName == Config.JobEMS and (onduty == nil or onduty == true) then
                    ambulanceCount = ambulanceCount + 1
                elseif onduty == false then
                    if Config.debug then
                        print("Player ID " .. playerId .. " is EMS but off-duty.")
                    end
                end
            else
                if Config.debug then
                    print("Error: Invalid player data for player ID:", playerId)
                end
            end
        end
    else
        if Config.debug then
            print("Error: No players found.")
        end
    end

    -- Send the ambulance count to all clients
    TriggerClientEvent('ambulancePlayerCount', -1, ambulanceCount)
end)

RegisterServerEvent('countAmbulancePlayers_ESX')
AddEventHandler('countAmbulancePlayers_ESX', function()
    local ambulanceCount = #ESX.GetExtendedPlayers('job', Config.JobEMS)
    TriggerClientEvent('ambulancePlayerCount', -1, ambulanceCount)
end)

RegisterServerEvent('enyo-aiambulance:reviveme-wasabi')
AddEventHandler('enyo-aiambulance:reviveme-wasabi', function()
    src = source
    exports.wasabi_ambulance:RevivePlayer(src)
end)


