-- Editable custom revive logic
-- This function is where you can insert custom behavior to handle a player's revival. 
-- If you need to trigger specific animations, effects, or use external resources for reviving a player,
-- you should add your logic here. 
-- By default, we handle several major ambulance scripts (e.g., ESX, QB, WASABI, BRUTAL, AK47.), but if you're using an unsupported system,
local function customReviveLogic(extraVars)
    -- Place your custom revive logic here
    -- For example, you can add a custom animation, notify other players, or trigger other events related to revival.
    print("Using custom revive logic for a custom ambulance jobs script.")
    print("Please go to the client/editable-main.lua to add ur revive logic.")
end

-- Editable custom dead check logic
-- If you want to customize how the system checks whether the player is dead (e.g., you have a custom state or flag),
-- this is where you can insert your logic.
-- By default, we handle several major ambulance scripts (e.g., ESX, QB, WASABI, BRUTAL, AK47.), but if you're using an unsupported system,
-- you should modify this function.
-- You may need to call a custom variable, or function here to properly detect if the player is dead.
local function isDeadCustom()
    -- This function is useful if you have a custom death state or script that isn't covered by default.
    -- For example, if your server uses a custom state variable for "death" or has a unique condition to check,
    -- implement it here and return `true` or `false` based on whether the player is dead.
    print("Using custom death check logic for a custom ambulance jobs script.")
    print("Please go to the client/editable-main.lua to add ur death check logic.")
    
    -- Example: Custom logic (returning a boolean indicating the death state)
    local customDeathState = exports.wasabi_ambulance:isPlayerDead(GetPlayerServerId(PlayerId()))  -- Replace this with your actual custom death check logic.
    return customDeathState
end

-- Billing logic function
-- This is used ..to charge the player for the revival process, and it's dependent on the framework your server uses.
-- By default, we handle billing with the ESX and QBcore frameworks. If you're using a different system or framework,
-- you might need to modify this to fit your server's structure.
-- The `sendBill` function sends the bill amount to the server for processing and deduction from the player’s account.
function sendBill(amount, reason)
    -- Place your billing logic here
    if Config.Bill > 0 then
        if Config.core == "ESX" then
            -- ESX framework billing trigger (calls server to remove money from the player's account)
            TriggerServerEvent('enyo-aiambulance:esx_billing:sendBill', amount, reason)
        else
            -- QBcore framework billing trigger (calls server to remove money from the player's account)
            TriggerServerEvent('enyo-aiambulance:qb-billing:sendBill', amount, reason)
        end
    end
end














------------------------------------------------------------------------------------
------------------------------- ADVANCED -------------------------------------------
------------------------------------------------------------------------------------


-- Automatically detect ambulance script
function detectAmbulanceScript()
    if GetResourceState("wasabi_ambulance") == "started" then
        return "WASABI"
    elseif GetResourceState("brutal_ambulancejob") == "started" then
        return "BRUTAL"
    elseif GetResourceState("ak47_ambulancejob") == "started" or GetResourceState("ak47_qb_ambulancejob") == "started" or GetResourceState("ak47_esx_ambulancejob") == "started" then
        return "AK47"
    elseif GetResourceState("qb-ambulancejob") == "started" then
        return "QB"
    elseif GetResourceState("qbx_medical") == "started" then
        return "QBX"
    elseif GetResourceState("esx_ambulancejob") == "started" then
        return "ESX"
    elseif GetResourceState("osp_ambulance") == "started" then
        return "OSP"    
    else
        return "OTHER"
    end
end



-- Helper to get server ID from player ID
local function getServerIdFromPlayerId(playerId)
    return GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPlayerPed(playerId)))
end

-- General revive function
local function handleRevive(extraVars)
    local playerPed = PlayerPedId()
    local reviveCutscene = extraVars.ReviveCutSceneVideo
    local CheckInPoint = extraVars.CheckInPoint
    sendBill(Config.Bill, "hospital")
    -- Make the player invisible before fade-out
    SetEntityVisible(playerPed, false, false)
    DoScreenFadeOut(700)
    Wait(700)

    local ambulanceJob = detectAmbulanceScript()
    -- Perform revive based on detected ambulance script
    if ambulanceJob == "QB" then
        SetEntityCoords(playerPed, CheckInPoint.x, CheckInPoint.y, CheckInPoint.z, false, false, false, false)
        TriggerEvent('qb-ambulancejob:checkin')
    elseif ambulanceJob == "QBX" then
        TriggerEvent('qbx_medical:client:playerRevived') 
    elseif ambulanceJob == "ESX" then
        TriggerEvent('esx_ambulancejob:revive')
        clearAfterRevive()
    elseif ambulanceJob == "WASABI" then
        TriggerServerEvent('enyo-aiambulance:reviveme-wasabi')
        clearAfterRevive()
    elseif ambulanceJob == "BRUTAL" then
        TriggerEvent('brutal_ambulancejob:revive')
        clearAfterRevive()
    elseif ambulanceJob == "AK47" then
        TriggerEvent('ak47_ambulancejob:revive')
        TriggerEvent('ak47_ambulancejob:skellyfix')
        clearAfterRevive()
    elseif ambulanceJob == "OSP" then 
        local playerId = GetPlayerServerId(PlayerId())
        TriggerServerEvent('osp_ambulance:revive', playerId)  
        clearAfterRevive()
    elseif ambulanceJob == "OTHER" then
        customReviveLogic(extraVars)
    end

    -- Play cutscene if provided
    if reviveCutscene then
        playVideoCutscene(reviveCutscene)
    end

    -- Restore visibility and fade-in
    SetEntityVisible(playerPed, true, false)
    DoScreenFadeIn(700)

    -- Handle optional teleportation
    if extraVars.teleportTo then
        local core = nil
        if Config.core:lower() ~= "esx" then core = exports[Config.core]:GetCoreObject() end
        while isdead(core) do Citizen.Wait(250) end
        teleportPlayerIfNeeded(extraVars.teleportTo)
    end
end

function clearAfterRevive()
    local core = nil
    if Config.core:lower() ~= "esx" then core = exports[Config.core]:GetCoreObject() end
    Citizen.CreateThread(function()
        while isdead(core) do Citizen.Wait(250) end
        ClearPedTasksImmediately(PlayerPedId())
    end)
end

-- Unified revive event handlers
RegisterNetEvent('enyo-aiambulance:client:revivehandle', function(extraVars)
    handleRevive(extraVars)
end)

-- Event triggered to notify EMS using the ESX framework
RegisterNetEvent('enyo-aiambulance:client:notifyEMS', function(ExtraVariables)

    if ExtraVariables["teleportTo"] then
        teleportPlayerIfNeeded(ExtraVariables["teleportTo"])
    end
    -- Wait before triggering the notification
    Wait(1000)
    if Config.core == "ESX" then
        -- If teleportTo is provided, move player to the specified location
        -- Trigger server event to notify EMS of player distress
        ESX.ShowNotification('Distress signal sent!')
        TriggerServerEvent('esx_ambulancejob:onPlayerDistress')
    else

        TriggerServerEvent('hospital:server:ambulanceAlert', 'Paramedics delivered a civilian to hospital.')
    end

end)




--- UTILS FUNCTIONS ---


-- Function to detect if the player is dead based on the ambulance job system
function isdead(QB)
    -- Automatically detect ambulance job
    local ambulanceJob = detectAmbulanceScript()
    local playerPed = PlayerPedId()
    if ambulanceJob == "QB" then
        -- For QB, we get the player data and check 'isdead' or 'inlaststand'
        local PlayerData = QB.Functions.GetPlayerData()
        if PlayerData and PlayerData.metadata then
            return PlayerData.metadata['isdead'] or PlayerData.metadata['inlaststand']
        else
            return false
        end
    elseif ambulanceJob == "QBX" then
        -- For QBOX, use their custom function to check if the player is dead
        return exports.qbx_medical:IsDead() or exports.qbx_medical:IsLaststand()
    elseif ambulanceJob == "ESX" then
        -- For ESX, check if the player is dead using the local player state
        return LocalPlayer.state.isDead
    elseif ambulanceJob == "WASABI" then
        -- For WASABI, use their custom function to check if the player is dead
        return exports.wasabi_ambulance:isPlayerDead() == "dead" or exports.wasabi_ambulance:isPlayerDead() == "laststand"
    elseif ambulanceJob == "BRUTAL" then
        -- For BRUTAL, use their function to check if the player is dead
        return exports.brutal_ambulancejob:IsDead()
    elseif ambulanceJob == "AK47" then
        -- For AK47, use their specific function to check if the player is dead
        return LocalPlayer.state.dead or LocalPlayer.state.down
    elseif ambulanceJob == "OSP" then
        -- For OSP, use their specific function to check if the player is dead
        local playerId = GetPlayerServerId(PlayerId())
        local ambulanceData = exports.osp_ambulance:GetAmbulanceData(playerId)
        if ambulanceData.isDead or ambulanceData.inLastStand then
            return true
        end
        return false
    elseif ambulanceJob == "OTHER" then
        -- For "OTHER", use the custom death check function
        return isDeadCustom()
    else
        -- Default return value if no ambulance job is detected
        return false
    end
end


-- Event to check if AI ambulance dispatch is allowed
-- Triggers a server event with the result (true if allowed, false if not)
RegisterNetEvent('enyo-aiambulance:client:isAmbulanceDispatchAllowed', function()
    local playerPed = PlayerPedId()  -- Get the player's ped (player model)
    local allowed = true  -- Default to true (dispatch allowed)

    -- Add any custom logic here if you want to implement conditions for allowing dispatch
    -- For example, you could check player location, current mission, or other conditions.

    -- Trigger server event with the dispatch allowed response
    TriggerEvent('enyo-aiambulance:client:isAmbulanceDispatchAllowedResponse', allowed)
end)

-- Function to send notifications to the player based on the framework (QB or ESX)
-- This function checks if the QB Framework is in use. If it is, it calls the QB notify function to display
function crossNotify(QB, MSG)
    if QB then
        -- If QB framework is active, show the message using QB's notify system
        QB.Functions.Notify(MSG, "success")
    else
        -- If ESX framework is active, show an advanced notification (styled as an EMS call)
        TriggerEvent('esx:showAdvancedNotification', '911', 'EMS', MSG, 'CHAR_CALL911', 3)
    end
end

function fillFuel(vehicle)
    SetVehicleFuelLevel(vehicle, 100 + 0.0)
	DecorSetFloat(vehicle, "_FUEL_LEVEL", GetVehicleFuelLevel(vehicle))
end