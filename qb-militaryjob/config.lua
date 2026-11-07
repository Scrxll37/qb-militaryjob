Config = {}

-- Job Settings
Config.JobName = "tuner"
Config.EnlistLocation = vector3(-2366.5, 3265.8, 32.8) -- Fort Zancudo gate
Config.BaseRestricted = true
Config.EnableRanks = true

-- Rank System
Config.Ranks = {
    [0] = {name = "Recruit", label = "Recruit", salary = 1500, minXP = 0},
    [1] = {name = "Private", label = "Private", salary = 2500, minXP = 500},
    [2] = {name = "Corporal", label = "Corporal", salary = 3500, minXP = 1500},
    [3] = {name = "Sergeant", label = "Sgt.", salary = 4500, minXP = 3000},
    [4] = {name = "Lieutenant", label = "Lt.", salary = 5500, minXP = 6000},
    [5] = {name = "Captain", label = "Capt.", salary = 6500, minXP = 10000},
    [6] = {name = "Major", label = "Maj.", salary = 7500, minXP = 15000},
    [7] = {name = "Colonel", label = "Col.", salary = 8500, minXP = 25000},
    [8] = {name = "General", label = "General", salary = 10000, minXP = 40000}
}

-- Role System
Config.Roles = {
    soldier = {label = "Soldier", weapons = {"WEAPON_COMBATRIFLE", "WEAPON_PISTOL"}},
    pilot = {label = "Pilot", vehicles = {"besra", "hydra", "buzzard"}},
    commander = {label = "Commander", permissions = {"startmissions", "startwar"}},
    intel = {label = "Intel", items = {"military_tablet", "binoculars"}}
}

-- Vehicles
Config.Vehicles = {
    land = {
        "crusader",    -- Military jeep
        "barracks",    -- Transport truck
        "rhino",       -- Tank
        "insurgent"    -- Armored vehicle
    },
    air = {
        "besra",       -- Jet
        "hydra",       -- VTOL Jet
        "buzzard",     -- Attack helicopter
        "valkyrie"     -- Armed helicopter
    }
}

-- Weapons
Config.DefaultWeapons = {
    "WEAPON_COMBATRIFLE",
    "WEAPON_PISTOL",
    "WEAPON_KNIFE"
}

-- Missions
Config.Missions = {
    {
        name = "defend_base",
        label = "Defend Fort Zancudo",
        minRank = 0,
        roles = {"soldier", "commander"},
        locations = {
            vector3(-2345.0, 3267.0, 32.8),
            vector3(-2400.0, 3280.0, 32.8)
        },
        reward = {xp = 100, cash = 5000}
    },
    {
        name = "bombing_run",
        label = "Bombing Run",
        minRank = 2,
        roles = {"pilot"},
        targetRadius = 50.0,
        reward = {xp = 200, cash = 8000}
    },
    {
        name = "vip_escort",
        label = "VIP Escort",
        minRank = 3,
        roles = {"soldier", "commander"},
        convoyRoute = {
            vector3(-2350.0, 3250.0, 32.8),
            vector3(1500.0, 3800.0, 34.0)
        },
        reward = {xp = 300, cash = 12000}
    },
    {
        name = "war_simulation",
        label = "War Games",
        minRank = 4,
        roles = {"commander"},
        reward = {xp = 500, cash = 20000}
    }
}

-- AI Settings
Config.AI = {
    maxEnemies = 20,
    accuracy = 30,
    weapons = {"WEAPON_ASSAULTRIFLE", "WEAPON_SMG", "WEAPON_PISTOL"},
    models = {
        "s_m_y_blackops_01",
        "s_m_y_blackops_02",
        "s_m_y_marine_01"
    }
}

-- Bombing System
Config.BombSettings = {
    bombType = "prop_ld_bomb_01",
    explosionFX = {
        name = "EXP_TAG_GRENADE",
        scale = 2.0
    },
    damageRadius = 30.0
}

-- Base Security
Config.RestrictedZones = {
    {
        coords = vector3(-2345.0, 3267.0, 32.8),
        radius = 400.0,
        message = "Restricted Military Area"
    }
}

-- War Simulation
Config.WarSimulation = {
    planeModels = {"besra", "hydra", "titan", "cargoplane", "miljet"},
    flightPath = {
        takeoff = vector3(-2260.0, 3240.0, 33.0),
        waypoints = {
            vector3(-2500.0, 3500.0, 1500.0),
            vector3(-3000.0, 4500.0, 2000.0),
            vector3(-5000.0, 6000.0, 2500.0) -- Ocean destination
        },
        planeCount = 12,
        spacing = 75.0
    },
    sirenSound = "air_raid_siren",
    duration = 300000, -- 5 minutes
    cooldown = 900000  -- 15 minutes
}

-- Blip Settings
Config.Blips = {
    base = {
        sprite = 557,
        color = 5,
        scale = 1.0,
        label = "Fort Zancudo"
    },
    mission = {
        sprite = 437,
        color = 1,
        scale = 0.8
    }
}