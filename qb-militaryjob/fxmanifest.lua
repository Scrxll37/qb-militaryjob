fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Fort Zancudo Military Job'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

files {
    'sounds/air_raid_siren.ogg',
    'stream/props/military.ytyp'
}

data_file 'AUDIO_WAVEPACK' 'sounds'
data_file 'DLC_ITYP_REQUEST' 'stream/props/military.ytyp'

dependencies {
    'qb-core',
    'qb-target',
    'qb-menu',
    'InteractSound'
}