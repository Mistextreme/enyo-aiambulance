-- enyo-aiambulance | client/main.lua
-- Core client logic: framework init, dispatch flow, NPC spawning, NUI handling

--------------------------------------------------------------
-- FRAMEWORK INITIALIZATION
--------------------------------------------------------------

ESX = nil
QB  = nil

if Config.core == "ESX" then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
else
    QB = exports[Config.core]:GetCoreObject()
end

--------------------------------------------------------------
-- STATE
--------------------------------------------------------------

local dispatchActive  = false
local cancelDispatch  = false
local ambulanceCount  = 0

--------------------------------------------------------------
-- NUI: VIDEO CUTSCENE
--------------------------------------------------------------

-- Called from editable-main.lua > handleRevive()
function playVideoCutscene(url)
    if not url or url == "" then return end

    local videoType = "local"
    if string.find(url, "youtu") then
        videoType = "youtube"
    end

    SetNuiFocus(false, false)
    SendNUIMessage({
        action    = "playVideo",
        videoType = videoType,
        url       = url
    })
end

RegisterNUICallback('videoEnded', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideUI" })
    cb('ok')
end)

--------------------------------------------------------------
-- TELEPORT HELPER
--------------------------------------------------------------

-- Called from editable-main.lua > handleRevive()
function teleportPlayerIfNeeded(coords)
    if not coords then return end
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
end

--------------------------------------------------------------
-- ZONE HELPERS
--------------------------------------------------------------

local function isInsideRect(zone, coords)
    local minX = math.min(zone.northwest.x, zone.southeast.x)
    local maxX = math.max(zone.northwest.x, zone.southeast.x)
    local minY = math.min(zone.northwest.y, zone.southeast.y)
    local maxY = math.max(zone.northwest.y, zone.southeast.y)
    return  coords.x >= minX and coords.x <= maxX
        and coords.y >= minY and coords.y <= maxY
        and coords.z >= zone.minZ and coords.z <= zone.maxZ
end

local function isInBlacklistedZone(coords)
    if not Config.useBlacklistedZones then return false end
    for _, zone in ipairs(Config.blacklistedZones) do
        if isInsideRect(zone, coords) then return true end
    end
    return false
end

local function isInOnlyAirZone(coords)
    if Config.useOnlyAirZones then
        for _, zone in ipairs(Config.OnlyAirZones) do
            if isInsideRect(zone, coords) then return true end
        end
    end
    -- Hard-coded Cayo Perico island detection
    if Config.cayoAirAmbulance then
        local minX, maxX = 3667.6230, 5863.0356
        local minY, maxY = -6076.5122, -4227.0049
        if coords.x >= minX and coords.x <= maxX and coords.y >= minY and coords.y <= maxY then
            return true
        end
    end
    return false
end

--------------------------------------------------------------
-- HOSPITAL HELPERS
--------------------------------------------------------------

local function getNearestHospital(playerCoords)
    local nearest, nearestDist = nil, math.huge
    for _, hospital in ipairs(Config.hospitals) do
        local dist = #(playerCoords - hospital.parking)
        if dist < nearestDist then
            nearestDist = dist
            nearest     = hospital
        end
    end
    return nearest
end

--------------------------------------------------------------
-- DISPATCH TYPE
--------------------------------------------------------------

local function determineDispatchType(playerCoords)
    if Config.onlyAirAmbulance              then return "heli" end
    if isInOnlyAirZone(playerCoords)        then return "heli" end
    if IsEntityInWater(PlayerPedId())        then return "boat" end
    return "ambulance"
end

--------------------------------------------------------------
-- MODEL LOADER
--------------------------------------------------------------

local function loadModel(modelHash)
    if not IsModelValid(modelHash) then
        if Config.debug then print("[enyo-aiambulance] Invalid model hash: " .. tostring(modelHash)) end
        return false
    end
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            if Config.debug then print("[enyo-aiambulance] Model load timeout: " .. tostring(modelHash)) end
            return false
        end
    end
    return true
end

--------------------------------------------------------------
-- PED / VEHICLE SPAWN HELPERS
--------------------------------------------------------------

local function spawnMedicPed(vehicle, seat)
    seat = seat or -1
    local medicHash = GetHashKey(Config.MedicModel)
    if not loadModel(medicHash) then return nil end

    local ped = CreatePedInsideVehicle(vehicle, 26, medicHash, seat, true, false)
    SetPedAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedDiesWhenInjured(ped, false)
    SetEntityInvincible(ped, true)
    SetModelAsNoLongerNeeded(medicHash)
    return ped
end

-- Ground ambulance spawn at a random point Config.maxSpawnDistance away
local function spawnAmbulance(playerCoords)
    local angle   = math.random(0, 360)
    local dist    = math.random(math.floor(Config.maxSpawnDistance * 0.55), Config.maxSpawnDistance)
    local rad     = math.rad(angle)
    local sx      = playerCoords.x + dist * math.cos(rad)
    local sy      = playerCoords.y + dist * math.sin(rad)
    local sz      = playerCoords.z
    local gz, ok  = GetGroundZFor_3dCoord(sx, sy, sz + 50.0, false)
    if ok then sz = gz end
    local spawnCoords = vector3(sx, sy, sz)

    local modelHash = GetHashKey(Config.AmbulanceModel)
    if not loadModel(modelHash) then return nil, nil end

    local heading = GetHeadingFromVector_2d(playerCoords.x - sx, playerCoords.y - sy)
    local vehicle = CreateVehicle(modelHash, sx, sy, sz, heading, true, false)
    SetVehicleAsNoLongerNeeded(vehicle)
    SetVehicleLivery(vehicle, Config.AmbulanceLivery)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    fillFuel(vehicle)
    SetModelAsNoLongerNeeded(modelHash)

    local ped = spawnMedicPed(vehicle, -1)
    if not ped then DeleteVehicle(vehicle) return nil, nil end

    if Config.debug then print("[enyo-aiambulance] Ambulance spawned at " .. tostring(spawnCoords)) end
    return ped, vehicle
end

-- Helicopter spawn above the player
local function spawnHeli(playerCoords)
    local sx = playerCoords.x + math.random(-100, 100)
    local sy = playerCoords.y + math.random(-100, 100)
    local sz = playerCoords.z + 150.0

    local modelHash = GetHashKey(Config.HelicopterModel)
    if not loadModel(modelHash) then return nil, nil end

    local heading = GetHeadingFromVector_2d(playerCoords.x - sx, playerCoords.y - sy)
    local vehicle = CreateVehicle(modelHash, sx, sy, sz, heading, true, false)
    SetVehicleAsNoLongerNeeded(vehicle)
    SetVehicleLivery(vehicle, Config.HelicopterLivery)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetHeliBladesFullSpeed(vehicle)
    SetModelAsNoLongerNeeded(modelHash)

    local ped = spawnMedicPed(vehicle, -1)
    if not ped then DeleteVehicle(vehicle) return nil, nil end

    if Config.debug then print("[enyo-aiambulance] Helicopter spawned") end
    return ped, vehicle
end

-- Boat spawn at the hospital's waterPoint
local function spawnBoat(waterPoint, playerCoords)
    local modelHash = GetHashKey(Config.BoatModel)
    if not loadModel(modelHash) then return nil, nil end

    local heading = GetHeadingFromVector_2d(playerCoords.x - waterPoint.x, playerCoords.y - waterPoint.y)
    local vehicle = CreateVehicle(modelHash, waterPoint.x, waterPoint.y, waterPoint.z, heading, true, false)
    SetVehicleAsNoLongerNeeded(vehicle)
    SetVehicleLivery(vehicle, Config.BoatLivery)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    local ped = spawnMedicPed(vehicle, -1)
    if not ped then DeleteVehicle(vehicle) return nil, nil end

    if Config.debug then print("[enyo-aiambulance] Boat spawned at waterPoint") end
    return ped, vehicle
end

--------------------------------------------------------------
-- WAIT HELPERS
--------------------------------------------------------------

local function waitForVehicleToReach(vehicle, targetCoords, threshold, timeoutMs)
    threshold = threshold or 10.0
    timeoutMs = timeoutMs or 90000
    local elapsed = 0
    while elapsed < timeoutMs do
        if cancelDispatch                            then return false end
        if not DoesEntityExist(vehicle)              then return false end
        if #(GetEntityCoords(vehicle) - targetCoords) <= threshold then return true end
        Wait(500)
        elapsed = elapsed + 500
    end
    return false
end

local function waitForPedToReach(ped, targetCoords, threshold, timeoutMs)
    threshold = threshold or 3.0
    timeoutMs = timeoutMs or 20000
    local elapsed = 0
    while elapsed < timeoutMs do
        if cancelDispatch                          then return false end
        if not DoesEntityExist(ped)               then return false end
        if #(GetEntityCoords(ped) - targetCoords) <= threshold then return true end
        Wait(500)
        elapsed = elapsed + 500
    end
    return false
end

--------------------------------------------------------------
-- CARRY / PLACE PLAYER
--------------------------------------------------------------

local function attachPlayerToPed(medicPed)
    AttachEntityToEntity(
        PlayerPedId(), medicPed, 0,
        0.45, 0.0, 0.9,
        0.0,  0.0, 0.0,
        false, false, false, false, 2, true
    )
end

local function detachPlayer()
    DetachEntity(PlayerPedId(), true, false)
end

--------------------------------------------------------------
-- GROUND RESCUE SEQUENCE
--------------------------------------------------------------

local function groundRescueSequence(medicPed, vehicle, playerCoords, hospital)
    -- 1. Drive to player
    TaskVehicleDriveToCoordLongrange(
        medicPed, vehicle,
        playerCoords.x, playerCoords.y, playerCoords.z,
        Config.MaxSpeed, Config.customDrivingStyle, 6.0
    )
    if not waitForVehicleToReach(vehicle, playerCoords, 10.0, 90000) then return end
    if cancelDispatch then return end

    -- 2. Medic exits vehicle
    TaskLeaveVehicle(medicPed, vehicle, 0)
    Wait(2000)
    if cancelDispatch then return end

    -- 3. Medic walks to player
    TaskGoToCoordAnyMeans(medicPed, playerCoords.x, playerCoords.y, playerCoords.z, 1.4, 0, false, 786603, 0.0)
    waitForPedToReach(medicPed, playerCoords, 2.5, 12000)
    if cancelDispatch then return end

    -- 4. Attach player to medic (carry)
    attachPlayerToPed(medicPed)

    -- 5. Medic carries player back to vehicle
    local doorCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -1.8, 0.0)
    TaskGoToCoordAnyMeans(medicPed, doorCoords.x, doorCoords.y, doorCoords.z, 1.4, 0, false, 786603, 0.0)
    waitForPedToReach(medicPed, GetEntityCoords(vehicle), 5.0, 15000)
    if cancelDispatch then detachPlayer() return end

    -- 6. Place player into back seat, medic re-enters driver seat
    detachPlayer()
    SetPedIntoVehicle(PlayerPedId(), vehicle, 2)
    Wait(800)
    TaskEnterVehicle(medicPed, vehicle, 5000, -1, 1.0, 1, 0)
    Wait(3000)
    if cancelDispatch then return end

    -- 7. Drive to hospital parking
    TaskVehicleDriveToCoordLongrange(
        medicPed, vehicle,
        hospital.parking.x, hospital.parking.y, hospital.parking.z,
        Config.MaxSpeed, Config.customDrivingStyle, 3.0
    )
    if not waitForVehicleToReach(vehicle, hospital.parking, 12.0, 120000) then return end
    if cancelDispatch then return end

    -- 8. Medic exits vehicle then handles interior path or stays outside
    TaskLeaveVehicle(medicPed, vehicle, 0)
    Wait(2000)

    if hospital.goInside and hospital.pathInside then
        -- Remove player from vehicle
        TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
        Wait(2000)
        if cancelDispatch then return end

        -- Walk through each interior waypoint carrying the player
        local i = 1
        while true do
            local point = hospital.pathInside[tostring(i)]
            if not point then break end
            if cancelDispatch then detachPlayer() return end
            attachPlayerToPed(medicPed)
            TaskGoToCoordAnyMeans(medicPed, point.x, point.y, point.z, 1.2, 0, false, 786603, 0.0)
            waitForPedToReach(medicPed, point, 2.5, 15000)
            i = i + 1
        end
        detachPlayer()
    else
        -- Just remove player from vehicle outside
        TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
        Wait(2000)
    end
end

--------------------------------------------------------------
-- HELICOPTER RESCUE SEQUENCE
--------------------------------------------------------------

local function heliRescueSequence(medicPed, vehicle, playerCoords, hospital)
    -- 1. Fly toward player
    TaskHeliMission(
        medicPed, vehicle, 0, 0,
        playerCoords.x, playerCoords.y, playerCoords.z + 30.0,
        4, 50.0, 8.0, -1.0, 40, 40, -1.0, 32
    )
    if not waitForVehicleToReach(vehicle, playerCoords, 40.0, 90000) then return end
    if cancelDispatch then return end

    -- 2. Descend and hover over player
    TaskHeliMission(
        medicPed, vehicle, 0, 0,
        playerCoords.x, playerCoords.y, playerCoords.z + 8.0,
        1, 10.0, 2.0, -1.0, 15, 15, -1.0, 32
    )
    Wait(5000)
    if cancelDispatch then return end

    -- 3. Load player into helicopter
    SetPedIntoVehicle(PlayerPedId(), vehicle, 2)
    Wait(1000)
    if cancelDispatch then return end

    -- 4. Fly to hospital helipad
    local helipad = hospital.helipad
    TaskHeliMission(
        medicPed, vehicle, 0, 0,
        helipad.x, helipad.y, helipad.z + 30.0,
        4, 60.0, 8.0, -1.0, 40, 40, -1.0, 32
    )
    if not waitForVehicleToReach(vehicle, helipad, 25.0, 120000) then return end
    if cancelDispatch then return end

    -- 5. Land on helipad
    TaskHeliMission(
        medicPed, vehicle, 0, 0,
        helipad.x, helipad.y, helipad.z,
        1, 5.0, 1.0, -1.0, 8, 8, -1.0, 32
    )
    Wait(5000)
    if cancelDispatch then return end

    -- 6. Remove player from helicopter
    TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
    Wait(2000)
end

--------------------------------------------------------------
-- BOAT RESCUE SEQUENCE
--------------------------------------------------------------

local function boatRescueSequence(medicPed, vehicle, playerCoords, hospital)
    -- 1. Navigate to player in water
    TaskVehicleDriveToCoordLongrange(
        medicPed, vehicle,
        playerCoords.x, playerCoords.y, playerCoords.z,
        Config.MaxSpeed, Config.customDrivingStyle, 8.0
    )
    if not waitForVehicleToReach(vehicle, playerCoords, 14.0, 90000) then return end
    if cancelDispatch then return end

    -- 2. Load player
    SetPedIntoVehicle(PlayerPedId(), vehicle, 2)
    Wait(1000)
    if cancelDispatch then return end

    -- 3. Navigate to hospital waterPoint
    local waterPoint = hospital.waterPoint
    TaskVehicleDriveToCoordLongrange(
        medicPed, vehicle,
        waterPoint.x, waterPoint.y, waterPoint.z,
        Config.MaxSpeed, Config.customDrivingStyle, 5.0
    )
    if not waitForVehicleToReach(vehicle, waterPoint, 18.0, 120000) then return end
    if cancelDispatch then return end

    -- 4. Remove player from boat
    TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
    Wait(2000)
end

--------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------

local function cleanupEntities(medicPed, vehicle)
    if DoesEntityExist(medicPed) then
        SetEntityAsMissionEntity(medicPed, false, true)
        DeletePed(medicPed)
    end
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, false, true)
        DeleteVehicle(vehicle)
    end
end

--------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------

local function dispatchAIAmbulance()
    if dispatchActive then
        crossNotify(QB, "~r~An AI ambulance is already on the way.")
        return
    end

    -- Ensure the player is actually incapacitated
    if not isdead(QB) then
        crossNotify(QB, "~r~You must be incapacitated to call for AI assistance.")
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())

    -- Blacklisted zone check
    if isInBlacklistedZone(playerCoords) then
        crossNotify(QB, "~r~AI ambulance is not available in this area.")
        return
    end

    -- Active EMS count check
    if Config.useMaxEMS and ambulanceCount >= Config.maxEMS then
        crossNotify(QB, "~y~There are enough EMS online. Please wait for a medic.")
        return
    end

    dispatchActive = true
    cancelDispatch = false

    local dispatchType = determineDispatchType(playerCoords)
    local hospital     = getNearestHospital(playerCoords)

    if not hospital then
        if Config.debug then print("[enyo-aiambulance] No hospital found in config.") end
        dispatchActive = false
        return
    end

    -- Player notification
    local notifKey = "Ambulance"
    if dispatchType == "heli" then notifKey = "Heli"
    elseif dispatchType == "boat" then notifKey = "Boat" end

    if Config.notifications[notifKey] then
        crossNotify(QB, Config.notifications[notifKey])
    end

    -- Inform server so EMS can be notified
    TriggerServerEvent('enyo-aiambulance:server:notifyEMS', hospital.ExtraVariables)

    Citizen.CreateThread(function()
        local medicPed, vehicle = nil, nil

        if dispatchType == "heli" then
            medicPed, vehicle = spawnHeli(playerCoords)
            if not medicPed then dispatchActive = false return end
            heliRescueSequence(medicPed, vehicle, playerCoords, hospital)

        elseif dispatchType == "boat" then
            medicPed, vehicle = spawnBoat(hospital.waterPoint, playerCoords)
            if not medicPed then dispatchActive = false return end
            boatRescueSequence(medicPed, vehicle, playerCoords, hospital)

        else
            medicPed, vehicle = spawnAmbulance(playerCoords)
            if not medicPed then dispatchActive = false return end
            groundRescueSequence(medicPed, vehicle, playerCoords, hospital)
        end

        if not cancelDispatch then
            if Config.revive then
                TriggerServerEvent('enyo-aiambulance:server:revivePlayer', hospital.ExtraVariables)
            else
                TriggerEvent('enyo-aiambulance:client:notifyEMS', hospital.ExtraVariables)
            end
        end

        cleanupEntities(medicPed, vehicle)
        dispatchActive = false
        cancelDispatch = false

        if Config.debug then print("[enyo-aiambulance] Dispatch sequence completed.") end
    end)
end

--------------------------------------------------------------
-- AUTO DISPATCH THREAD
--------------------------------------------------------------

if Config.auto then
    Citizen.CreateThread(function()
        while true do
            Wait(15000)
            if not dispatchActive and isdead(QB) then
                dispatchAIAmbulance()
            end
        end
    end)
end

--------------------------------------------------------------
-- COMMANDS
--------------------------------------------------------------

RegisterCommand(Config.command, function()
    dispatchAIAmbulance()
end, false)

RegisterCommand(Config.cancel_command, function()
    if dispatchActive then
        cancelDispatch = true
        dispatchActive = false
        crossNotify(QB, "~r~AI ambulance dispatch has been cancelled.")
    else
        crossNotify(QB, "~y~No AI ambulance is currently dispatched.")
    end
end, false)

--------------------------------------------------------------
-- EMS COUNT SYNC
--------------------------------------------------------------

RegisterNetEvent('ambulancePlayerCount', function(count)
    ambulanceCount = count
    if Config.debug then print("[enyo-aiambulance] EMS online count: " .. count) end
end)

local function refreshEMSCount()
    if Config.core == "ESX" then
        TriggerServerEvent('countAmbulancePlayers_ESX')
    else
        TriggerServerEvent('countAmbulancePlayers_QB')
    end
end

-- Refresh on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        refreshEMSCount()
    end
end)

-- Periodic refresh every 30 seconds
Citizen.CreateThread(function()
    while true do
        Wait(30000)
        refreshEMSCount()
    end
end)
