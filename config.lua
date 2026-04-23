-- Configures various settings and options for the backup system, including AI ambulance, player revival, and hospital details.
Config = {}

-- Specifies the core framework being used (e.g., 'ESX' or 'qb-core'). 
-- Change this value depending on your framework choice.
Config.core = 'qb-core'  -- 'ESX' or 'qb-core' supported

-- Enables or disables automatic assistance when no live players (human medics) are nearby.
Config.auto = false  -- true: Automatic help is triggered when no players are around

-- Command to request help from an AI-controlled ambulance.
Config.command = "ambulance"  -- Type this command to call for AI assistance

-- Command to cancel the AI ambulance before it completes the job.
Config.cancel_command = "cancelhelp"  -- Type this command to stop AI ambulance dispatch

-- Determines whether AI medics will revive the player directly or drop them at the hospital.
-- true: The AI will revive the player. 
-- false: The player will be dropped at the hospital, and a notification will be shown.
Config.revive = true  -- AI will revive players if true, otherwise just drop them at the hospital

-- Defines the billing amount for the medical services provided by the AI medic.
-- This value determines how much the player is charged for the medic's assistance.
Config.Bill = 0  -- Amount to be billed for the medic service (default = 0)

-- Defines the model name for the AI medic NPC. >> (Make Sure Its not Blacklisted by any script or anti-cheat)
-- This value refers to the character model used when an AI medic is dispatched.
Config.MedicModel = "s_m_m_paramedic_01"  -- NPC model for the medic (GTA V paramedic model)

-- Specifies the vehicle model used for AI ambulances. >> (Make Sure Its not Blacklisted by any script or anti-cheat)
-- This value refers to the vehicle that AI medics will use to respond to emergencies.
Config.AmbulanceModel = "hvfordems"  -- Vehicle model name for the ambulance (default GTA V ambulance)

-- Configures the livery of the AI ambulance vehicle.
-- Livery refers to the specific design or skin applied to the ambulance vehicle.
-- 0: Default livery, higher values correspond to custom or alternate skins if available.
Config.AmbulanceLivery = 0  -- Livery index for the ambulance (default = 0)

-- Configures the maximum speed for the AI ambulance vehicle.
-- This value determines the top speed that the ambulance can travel when responding to emergencies.
Config.MaxSpeed = 15.0  -- Maximum speed for the ambulance in miles per hour (default = 15.0)

-- Defines the model name for the AI boat used in water rescues.
-- This is the vehicle AI medics will use when water-based rescues are required (e.g., player drowning).
Config.BoatModel = "dinghy"  -- Boat model used for water-based AI rescue missions

-- Configures the livery of the AI boat.
-- Similar to the ambulance, this setting controls the design applied to the rescue boat.
-- 0: Default livery for the boat.
Config.BoatLivery = 0  -- Livery index for the boat (default = 0)

-- Specifies the model name for the AI helicopter used in air rescues.
-- This helicopter is dispatched when a helicopter-based rescue is required (e.g., difficult terrain or long distances).
Config.HelicopterModel = "hvheli"  -- Helicopter model used for air rescue operations

-- Configures the livery of the AI helicopter.
-- This value controls the design or skin applied to the helicopter used in medical rescues.
-- 0: Default helicopter livery, 1 or higher for alternate designs (if available).
Config.HelicopterLivery = 1  -- Livery index for the helicopter (default = 1, alternative skin)


-- Configures whether AI medical assistance is provided exclusively via air ambulances.
-- When set to true, the AI will only dispatch helicopters to provide medical assistance. 
-- No ground ambulances or stretchers will be used for player transport in this case.
-- If set to false, both air and ground ambulances may be used depending how hard the death location is to reach by AI medics.
Config.onlyAirAmbulance = false  -- If true, AI medical help will only arrive via helicopter, with no ground ambulance support.

Config.cayoAirAmbulance = true -- -- If true, AI medical help will only arrive via helicopter in Cayo Perico Island, make it false if you configurated a hospital in Cayo Perico.

-- Limits the number of human EMS players that can trigger the AI medics.
-- When the number of online EMS reaches the defined limit, AI medics will no longer respond.
Config.useMaxEMS = true  -- Enable the limit on the number of EMS players
Config.maxEMS = 5  -- The maximum number of EMS players before AI ambulance is disabled

-- Specifies the job name for the Emergency Medical Services (EMS) profession.
Config.JobEMS = 'ambulance'  -- Job name for EMS (used by the script to identify players with EMS roles)

-- Defines hospital locations and related settings for AI medics to use.
Config.hospitals = {
    -- PillBox Hill Medical Center
    {
        waterPoint      = vector3(-779.68, -1440.69, 1.6),  -- Location where the boat NPC drops the player in case of drowning
        parking         = vector3(1156.4093, -1512.8544, 34.6928),  -- Ambulance parking spot in front of the hospital
        door            = vector3(1151.2186, -1529.6333, 35.3697),  -- Entrance to the hospital
        helipad         = vector3(1186.2970, -1551.9998, 39.4011),
        goInside        = true,  -- true: AI will take the player inside the hospital
        
        -- Path used by AI to navigate inside the hospital (e.g., for custom interiors or maps).
        -- Each point represents a location the AI follows to reach the designated area (like a bed).
        pathInside  = { 
            ["1"] = vector3(1151.2186, -1529.6333, 35.3697),  -- Hospital entrance
            ["2"] = vector3(1147.1335, -1535.6603, 35.0330),  
            ["3"] = vector3(1146.7673, -1563.2756, 35.0330),  
            ["4"] = vector3(1132.5197, -1563.6947, 35.0330),  
            ["5"] = vector3(1124.9155, -1556.0681, 35.0330),  -- Bedside location
        },

        -- Additional variables (optional) passed to the revive and notification functions.
        ExtraVariables  = { 
            ["CheckInPoint"] = vector3(308.4696, -595.0331, 43.2918),  -- Coordinates for player check-in (triggered during a revive event)
            ["ReviveCutSceneVideo"] = "https://youtu.be/JfNRjFB9tBI",  -- URL for a cutscene video (Supports youtube and local files)
            --["teleportTo"] = vector3(347.0469, -583.8239, 43.3150), -- Teleport here after everything is done

        }
    },
    
    -- Paletto Bay Medical Center
    {
        parking    = vector3(-225.1457, 6318.7871, 31.2972),  -- Ambulance parking spot
        door       = vector3(-247.5973, 6331.4399, 32.4263),  -- Entrance to the hospital
        waterPoint = vector3(-664.76, 6170.7, 0.89),  -- Drop-off point in case of drowning
        helipad    = vector3(-226.6698, 6315.6250, 31.2966),
        goInside   = true,  -- true: AI will take the player inside
        
        pathInside  = {  -- Path the AI takes inside the hospital (for navigation without navmesh)
            ["1"] = vector3(-248.2072, 6332.6167, 32.4262),  
            ["2"] = vector3(-253.2790, 6335.7046, 32.4315),  
            ["3"] = vector3(-261.7462, 6327.0161, 32.4315),  
            ["4"] = vector3(-257.8949, 6322.7251, 32.4315),  
            ["5"] = vector3(-255.7238, 6318.4048, 32.4315),  
            ["6"] = vector3(-251.4382, 6314.2876, 32.4315),  
            ["7"] = vector3(-253.3137, 6312.3911, 32.4315),  -- Bedside location
        },
        
        ExtraVariables  = { 
            ["CheckInPoint"] = vector3(-254.54, 6331.78, 32.43),  -- Check-in point for reviving the player
            ["ReviveCutSceneVideo"] = "videos/cutscene.mp4",  -- Optional video during revive (Supports youtube and local files)
            --["teleportTo"] = vector3(-253.3137, 6312.3911, 32.4315), -- Teleport here after everything is done 

        }
    },
    
    -- Central Los Santos Medical Center (No indoor navigation)
    --{
    --    parking    = vector3(311.3947, -1373.7687, 31.8476),  -- Ambulance parking spot
    --    door       = vector3(339.9474, -1395.9956, 32.5092),  -- Hospital entrance
    --    waterPoint = vector3(-779.68, -1440.69, 1.6),  -- Drowning drop-off point
    --    helipad    = vector3(299.8337, -1453.4944, 46.5095),
    --    goInside   = false,  -- AI does not go inside this hospital
    --    pathInside = {},  -- No path required as AI stays outside
    --    ExtraVariables  = {
    --        ["teleportTo"] = vector3(339.9474, -1395.9956, 32.5092), 
    --    }  
    --}
    
    -- Add more hospital locations as needed
}


-- Configuration for OnlyAir Zones
-- This section defines areas where only air ambulances are dispatched.
Config.useOnlyAirZones = false -- Advised to use only for addon mapping and map expantions with no navmesh

-- Define rectangular zones using compass corner points: northwest (top-left) and southeast (bottom-right).
-- Each zone is defined by the following parameters:
--   - name: A descriptive name for the zone (used for identification).
--   - northwest: Coordinates for the northwest corner (top-left).
--   - southeast: Coordinates for the southeast corner (bottom-right).
--   - minZ: The minimum height (z value) for the zone.
--   - maxZ: The maximum height (z value) for the zone.
Config.OnlyAirZones = {
    {
        name = "Cayo",  -- Name of the zone for easier identification
        northwest = {x = 3667.6230, y = -4227.0049},  -- Northwest corner (top-left)
        southeast = {x = 5863.0356, y = -6076.5122},  -- Southeast corner (bottom-right)
        minZ = 0.0,  -- Minimum height (z value)
        maxZ = 100.0 -- Maximum height (z value)
    },
    {
        name = "Roxwood",  -- Name of the zone for easier identification
        northwest = {x = -1298.5864, y = 7074.6636},  -- Northwest corner (top-left)
        southeast = {x = 845.3663, y = 5729.2217},  -- Southeast corner (bottom-right)
        minZ = 0.0,  -- Minimum height (z value)
        maxZ = 100.0 -- Maximum height (z value)
    }
}


-- Configuration for Blacklisted Zones
-- This section defines areas where AI ambulance are not allowed.
-- If a player dead in any of these zones, the AI Ambulance will not be dispatched.
Config.useBlacklistedZones = false

-- Define rectangular zones using compass corner points: northwest (top-left) and southeast (bottom-right).
-- Each zone is defined by the following parameters:
--   - name: A descriptive name for the zone (used for identification).
--   - northwest: Coordinates for the northwest corner (top-left).
--   - southeast: Coordinates for the southeast corner (bottom-right).
--   - minZ: The minimum height (z value) for the zone.
--   - maxZ: The maximum height (z value) for the zone.
Config.blacklistedZones = {
    {
        name = "Prison",  -- Name of the zone for easier identification
        northwest = {x = 1526.9114, y = 2719.1841},  -- Northwest corner (top-left)
        southeast = {x = 1774.7125, y = 2329.361},  -- Southeast corner (bottom-right)
        minZ = 0.0,  -- Minimum height (z value)
        maxZ = 100.0 -- Maximum height (z value)
    }

}


-- Notifications for different types of ambulance dispatches
Config.notifications = {
    ["Ambulance"] = "An ambulance has been dispatched to your location.", -- Message for standard ambulance dispatch
    ["Boat"] = "A water ambulance has been dispatched to your location.",  -- Message for water ambulance dispatch
    ["Heli"] = "An air ambulance has been dispatched to your location.",   -- Message for air ambulance dispatch
    }


-- Defines custom driving styles for NPC ambulance drivers.
-- Recommended not to change (0: the best driving style for the script).
-- To generate a different driving style, use this tool : https://vespura.com/fivem/drivingstyle/
Config.customDrivingStyle = 319  -- Driving style for AI ambulance drivers (use 0 for optimal behavior)

-- Configures the maximum distance from the player at which the ambulance will spawn.
-- Min: 20, Max: 160. Default is set to 160.
Config.maxSpawnDistance = 160  -- Maximum distance for ambulance spawn (in units)

-- Enables or disables debugging information in the console for developers.
Config.debug = false  -- true: Enables debugging output in the console
