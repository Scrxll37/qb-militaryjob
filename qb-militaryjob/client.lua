local PlayerData = {}
local currentMission = nil
local enemyPeds = {}
local bombTarget = nil
local inService = false
local missionBlip = nil
local warActive = false
local warPlanes = {}
local warSiren = nil

-- Threads
CreateThread(function()
    while not QBCore do Wait(1000) end
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Enlistment Ped
    local pedModel = `s_m_y_marine_03`
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(0) end
    
    local enlistPed = CreatePed(4, pedModel, Config.EnlistLocation.x, Config.EnlistLocation.y, Config.EnlistLocation.z -1, 180.0, false, true)
    FreezeEntityPosition(enlistPed, true)
    SetEntityInvincible(enlistPed, true)
    SetBlockingOfNonTemporaryEvents(enlistPed, true)
    
    exports['qb-target']:AddTargetEntity(enlistPed, {
        options = {
            {
                type = "client",
                event = "qb-militaryjob:client:enlistMenu",
                icon = "fas fa-clipboard",
                label = "Enlist in Military",
                job = nil
            }
        },
        distance = 2.5
    })
    
    -- Base Security
    if Config.BaseRestricted then
        CreateThread(function()
            while true do
                Wait(3000)
                local playerCoords = GetEntityCoords(PlayerPedId())
                for _, zone in ipairs(Config.RestrictedZones) do
                    if #(playerCoords - zone.coords) < zone.radius then
                        if PlayerData.job and PlayerData.job.name ~= Config.JobName then
                            QBCore.Functions.Notify(zone.message, "error")
                            SetEntityCoords(PlayerPedId(), zone.coords.x + math.random(-100,100), zone.coords.y + math.random(-100,100), zone.coords.z)
                        end
                    end
                end
            end
        end)
    end
    
    -- Main job loop
    CreateThread(function()
        while true do
            if PlayerData.job and PlayerData.job.name == Config.JobName then
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                
                -- Auto-equip parachute in aircraft
                if IsPedInFlyingVehicle(playerPed) then
                    local vehicle = GetVehiclePedIsIn(playerPed)
                    if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                        local height = GetEntityHeightAboveGround(playerPed)
                        if height > 50.0 and GetPedParachuteState(playerPed) == -1 then
                            GiveWeaponToPed(playerPed, "GADGET_PARACHUTE", 1, false, true)
                        end
                    end
                end
                
                -- Mission terminal
                if #(playerCoords - vector3(-2355.0, 3240.0, 32.8)) < 2.0 then
                    DrawText3D(-2355.0, 3240.0, 32.8, "[E] Mission Terminal")
                    if IsControlJustPressed(0, 38) then
                        OpenMissionMenu()
                    end
                end
            end
            Wait(5)
        end
    end)
end)

-- War Simulation System
function StartWarSimulation()
    if warActive then return end
    warActive = true
    
    -- Play air raid siren
    warSiren = GetSoundId()
    PlaySoundFromCoord(warSiren, Config.WarSimulation.sirenSound, 
                      Config.EnlistLocation.x, Config.EnlistLocation.y, Config.EnlistLocation.z, 
                      "DLC_HEIST_HACKING_SNAKE_SOUNDS", true, 100.0, 0)
    
    -- Create formation of planes
    local flightPath = Config.WarSimulation.flightPath
    local leaderHeading = 90.0
    
    for i = 1, Config.WarSimulation.planeCount do
        local offsetX = (i-1) * Config.WarSimulation.spacing
        local spawnPos = flightPath.takeoff + vector3(0.0, offsetX, 0.0)
        
        CreateThread(function()
            local model = GetHashKey(Config.WarSimulation.planeModels[math.random(#Config.WarSimulation.planeModels)])
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end
            
            -- Create plane
            local plane = CreateVehicle(model, spawnPos.x, spawnPos.y, spawnPos.z, leaderHeading, true, false)
            SetEntityInvincible(plane, true)
            SetVehicleEngineOn(plane, true, true, false)
            SetVehicleForwardSpeed(plane, 60.0)
            table.insert(warPlanes, plane)
            
            -- Create pilot
            local pilotModel = `s_m_y_blackops_01`
            RequestModel(pilotModel)
            while not HasModelLoaded(pilotModel) do Wait(0) end
            
            local pilot = CreatePedInsideVehicle(plane, 6, pilotModel, -1, true, false)
            SetEntityInvincible(pilot, true)
            
            -- Add blip
            local blip = AddBlipForEntity(plane)
            SetBlipSprite(blip, 16)
            SetBlipColour(blip, 1)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, false)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("War Exercise Aircraft")
            EndTextCommandSetBlipName(blip)
            
            -- Flight path
            for _, waypoint in ipairs(flightPath.waypoints) do
                TaskVehicleDriveToCoordLongrange(pilot, plane, waypoint.x, waypoint.y, waypoint.z, 
                                                 100.0, 262668, 10.0)
                
                -- Wait until near waypoint
                while #(GetEntityCoords(plane) - waypoint) > 500.0 do
                    Wait(1000)
                end
            end
            
            -- Delete when far out to sea
            while #(GetEntityCoords(plane) - flightPath.waypoints[#flightPath.waypoints]) < 1000.0 do
                Wait(1000)
            end
            
            DeleteEntity(plane)
            DeleteEntity(pilot)
            RemoveBlip(blip)
        end)
        
        Wait(500) -- Stagger spawns
    end
    
    -- Radio chatter effects
    CreateThread(function()
        while warActive do
            PlaySoundFrontend(-1, "RADIO_CHATTER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            Wait(math.random(15000, 30000))
        end
    end)
    
    -- End war after duration
    SetTimeout(Config.WarSimulation.duration, function()
        EndWarSimulation()
    end)
end

function EndWarSimulation()
    if not warActive then return end
    
    -- Stop siren
    if warSiren then
        StopSound(warSiren)
        ReleaseSoundId(warSiren)
        warSiren = nil
    end
    
    -- Delete all planes
    for _, plane in ipairs(warPlanes) do
        if DoesEntityExist(plane) then
            DeleteEntity(plane)
        end
    end
    warPlanes = {}
    
    warActive = false
end

-- War commands
RegisterCommand('startwar', function()
    if PlayerData.job and PlayerData.job.name == Config.JobName then
        if PlayerData.job.grade.level >= 4 then -- Commander rank
            TriggerServerEvent('qb-militaryjob:server:startMission', 4) -- War simulation mission
        else
            QBCore.Functions.Notify("Rank too low! Must be Lieutenant or higher", "error")
        end
    end
end)

RegisterCommand('stopwar', function()
    if warActive then
        EndWarSimulation()
        QBCore.Functions.Notify("War simulation terminated", "primary")
    end
end)

-- Mission System
function OpenMissionMenu()
    local menu = {
        {
            header = "Fort Zancudo - Mission Terminal",
            isMenuHeader = true
        }
    }
    
    for i, mission in ipairs(Config.Missions) do
        if PlayerData.job.grade.level >= mission.minRank then
            menu[#menu+1] = {
                header = mission.label,
                txt = "Rank Required: "..Config.Ranks[mission.minRank].label,
                params = {
                    event = "qb-militaryjob:server:startMission",
                    args = i
                }
            }
        end
    end
    
    exports['qb-menu']:openMenu(menu)
end

RegisterNetEvent('qb-militaryjob:client:startMission', function(mission)
    currentMission = mission
    
    if mission.name == "defend_base" then
        StartDefenseMission(mission)
    elseif mission.name == "bombing_run" then
        PrepareBombingRun(mission)
    elseif mission.name == "vip_escort" then
        StartVIPEscort(mission)
    elseif mission.name == "war_simulation" then
        StartWarSimulation()
        QBCore.Functions.Notify("War simulation initiated! All units mobilize!", "success")
    end
end)

function StartDefenseMission(mission)
    -- Create mission blip
    missionBlip = AddBlipForCoord(mission.locations[1].x, mission.locations[1].y, mission.locations[1].z)
    SetBlipSprite(missionBlip, Config.Blips.mission.sprite)
    SetBlipColour(missionBlip, Config.Blips.mission.color)
    SetBlipScale(missionBlip, Config.Blips.mission.scale)
    SetBlipAsShortRange(missionBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Defense Mission")
    EndTextCommandSetBlipName(missionBlip)
    
    -- Spawn enemies
    for i=1, Config.AI.maxEnemies do
        local spawnLoc = mission.locations[math.random(#mission.locations)] + vector3(math.random(-20,20), math.random(-20,20), 0)
        SpawnEnemyPed(spawnLoc)
    end
    
    -- Mission objective
    exports['qb-core']:DrawText("[E] Activate Alarm", "left")
    while currentMission do
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - mission.locations[1]) < 2.0 then
            if IsControlJustPressed(0, 38) then
                TriggerEvent("qb-militaryjob:client:activateAlarm")
                exports['qb-core']:HideText()
                break
            end
        end
        Wait(0)
    end
end

function PrepareBombingRun(mission)
    local jetModel = `hydra`
    RequestModel(jetModel)
    while not HasModelLoaded(jetModel) do Wait(0) end
    
    local jet = CreateVehicle(jetModel, -2260.0, 3240.0, 33.0, 90.0, true, false)
    TaskWarpPedIntoVehicle(PlayerPedId(), jet, -1)
    
    QBCore.Functions.Notify("Fly to marked area and select target with BOMBSIGHT", "primary")
    
    -- Create target zone
    bombTarget = vector3(1500.0 + math.random(-500,500), 3800.0 + math.random(-500,500), 100.0)
    local targetBlip = AddBlipForRadius(bombTarget.x, bombTarget.y, bombTarget.z, mission.targetRadius)
    SetBlipColour(targetBlip, 1)
    SetBlipAlpha(targetBlip, 100)
    
    -- Bombing interface
    CreateThread(function()
        while bombTarget do
            local jet = GetVehiclePedIsIn(PlayerPedId())
            if jet ~= 0 and GetPedInVehicleSeat(jet, -1) == PlayerPedId() then
                if IsControlPressed(0, 74) then -- BOMBSIGHT key (H)
                    local hit, coords = RaycastFromCamera()
                    DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, nil, nil, false)
                    
                    if IsControlJustPressed(0, 24) then -- ATTACK key (LMB)
                        TriggerServerEvent('qb-militaryjob:server:dropBomb', coords)
                    end
                end
            end
            Wait(0)
        end
    end)
end

-- Bombing Functions
function RaycastFromCamera()
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(camRot)
    local destination = camCoord + (direction * 1000.0)
    
    local rayHandle = StartShapeTestRay(camCoord, destination, -1, PlayerPedId(), 0)
    local _, hit, hitCoords = GetShapeTestResult(rayHandle)
    return hit, hitCoords
end

function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    
    return vector3(
        (-math.sin(z) * num),
        (math.cos(z) * num),
        math.sin(x)
    )
end

RegisterNetEvent('qb-militaryjob:client:createExplosion', function(coords)
    AddExplosion(coords.x, coords.y, coords.z, Config.BombSettings.explosionFX.name, 
                 Config.BombSettings.explosionFX.scale, true, false, false)
    AddExplosion(coords.x, coords.y, coords.z, 9, 1.0, true, false, false)
    StartScriptFire(coords.x, coords.y, coords.z, 25, true)
    
    -- Damage nearby entities
    local nearbyEntities = GetGamePool('CPed')
    for _, entity in ipairs(nearbyEntities) do
        if #(coords - GetEntityCoords(entity)) < Config.BombSettings.damageRadius then
            ApplyDamageToPed(entity, 1000, false, true, true)
        end
    end
end)

-- AI System
function SpawnEnemyPed(coords)
    local model = GetHashKey(Config.AI.models[math.random(#Config.AI.models)])
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, 0.0, true, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAbility(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedCombatRange(ped, 2)
    SetPedAlertness(ped, 3)
    SetPedFleeAttributes(ped, 0, 0)
    
    local weapon = GetHashKey(Config.AI.weapons[math.random(#Config.AI.weapons)])
    GiveWeaponToPed(ped, weapon, 255, false, true)
    SetCurrentPedWeapon(ped, weapon, true)
    
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
    table.insert(enemyPeds, ped)
end

-- Alarm System
RegisterNetEvent('qb-militaryjob:client:activateAlarm', function()
    PlaySoundFrontend(-1, "BASE_JUMP_PASSED", "HUD_AWARDS", true)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "alarm", 0.3)
    
    CreateThread(function()
        while currentMission and currentMission.name == "defend_base" do
            SetArtificialLightsState(true)
            Wait(500)
            SetArtificialLightsState(false)
            Wait(500)
        end
        SetArtificialLightsState(false)
    end)
end)

-- Cleanup
RegisterNetEvent('qb-militaryjob:client:endMission', function()
    for _, ped in ipairs(enemyPeds) do
        DeleteEntity(ped)
    end
    enemyPeds = {}
    
    if missionBlip then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
    
    currentMission = nil
    bombTarget = nil
end)

-- Role Assignments
RegisterNetEvent('qb-militaryjob:client:openRoleMenu', function()
    local menu = {
        {
            header = "Military Roles",
            isMenuHeader = true
        }
    }
    
    for role, data in pairs(Config.Roles) do
        menu[#menu+1] = {
            header = data.label,
            txt = "Select this role",
            params = {
                event = "qb-militaryjob:client:selectRole",
                args = role
            }
        }
    end
    
    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('qb-militaryjob:client:selectRole', function(role)
    TriggerServerEvent('qb-militaryjob:server:assignRole', role)
end)

-- Equipment Handler
RegisterNetEvent('qb-militaryjob:client:equipGear', function()
    local playerPed = PlayerPedId()
    
    -- Set uniform
    SetPedComponentVariation(playerPed, 11, 55, 0, 0)  -- Jacket
    SetPedComponentVariation(playerPed, 4, 35, 0, 0)   -- Pants
    SetPedComponentVariation(playerPed, 6, 25, 0, 0)   -- Shoes
    SetPedComponentVariation(playerPed, 8, 58, 0, 0)   -- Undershirt
    
    -- Give weapons
    for _, weapon in ipairs(Config.DefaultWeapons) do
        GiveWeaponToPed(playerPed, GetHashKey(weapon), 255, false, true)
    end
end)

-- Utility Functions
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end