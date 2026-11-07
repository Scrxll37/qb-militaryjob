QBCore = exports['qb-core']:GetCoreObject()
local PlayerRoles = {}
local warCooldown = 0

-- Player Enlistment
RegisterNetEvent('qb-militaryjob:server:enlistPlayer', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.SetJob(Config.JobName, 0)
        TriggerClientEvent('QBCore:Notify', src, "You've enlisted in the military!", "success")
        TriggerClientEvent('qb-militaryjob:client:equipGear', src)
    end
end)

-- Role Management
RegisterNetEvent('qb-militaryjob:server:assignRole', function(role)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.job.name == Config.JobName then
        PlayerRoles[src] = role
        TriggerClientEvent('QBCore:Notify', src, "Assigned role: "..Config.Roles[role].label, "success")
        
        -- Give role-specific items
        if Config.Roles[role].items then
            for _, item in ipairs(Config.Roles[role].items) do
                Player.Functions.AddItem(item, 1)
            end
        end
    end
end)

-- Mission Handling
RegisterNetEvent('qb-militaryjob:server:startMission', function(missionIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local mission = Config.Missions[missionIndex]
    
    if Player and Player.job.name == Config.JobName then
        if Player.job.grade.level >= mission.minRank then
            TriggerClientEvent('qb-militaryjob:client:startMission', src, mission)
            
            -- War simulation cooldown
            if mission.name == "war_simulation" then
                if warCooldown > GetGameTimer() then
                    local remaining = (warCooldown - GetGameTimer()) / 60000
                    TriggerClientEvent('QBCore:Notify', src, "War simulation cooling down. Available in "..math.ceil(remaining).." minutes", "error")
                    return
                end
                warCooldown = GetGameTimer() + Config.WarSimulation.cooldown
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "Rank too low for this mission!", "error")
        end
    end
end)

-- Bombing System
RegisterNetEvent('qb-militaryjob:server:dropBomb', function(coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Validate player is in military jet
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped)
    
    if IsVehicleModel(vehicle, `hydra`) or IsVehicleModel(vehicle, `besra`) then
        TriggerClientEvent('qb-militaryjob:client:createExplosion', -1, coords)
        
        -- Reward player
        Player.Functions.AddMoney('cash', Config.Missions.bombing_run.reward.cash)
        Player.Functions.AddItem('military_xp', Config.Missions.bombing_run.reward.xp)
        TriggerClientEvent('QBCore:Notify', src, "Target destroyed! +"..Config.Missions.bombing_run.reward.xp.." XP", "success")
    end
end)

-- XP System
QBCore.Functions.CreateCallback('qb-militaryjob:server:getPlayerXP', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local xpItem = Player.Functions.GetItemByName('military_xp')
    cb(xpItem and xpItem.amount or 0)
end)

-- Rank Promotion Check
CreateThread(function()
    while true do
        Wait(60000 * 5) -- Check every 5 minutes
        for _, player in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(player)
            if Player and Player.job.name == Config.JobName then
                local xpItem = Player.Functions.GetItemByName('military_xp')
                local xp = xpItem and xpItem.amount or 0
                local currentRank = Player.job.grade.level
                
                -- Check for promotions
                for rank, data in pairs(Config.Ranks) do
                    if rank > currentRank and xp >= data.minXP then
                        Player.Functions.SetJob(Config.JobName, rank)
                        TriggerClientEvent('QBCore:Notify', player, 
                            "Promoted to "..data.label.."!", "success")
                    end
                end
            end
        end
    end
end)

-- End Mission
RegisterNetEvent('qb-militaryjob:server:endMission', function()
    TriggerClientEvent('qb-militaryjob:client:endMission', source)
end)