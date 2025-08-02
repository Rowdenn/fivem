fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Framework'
author 'Rowden'
version '0.0.1-al'
description 'Framework'

shared_scripts {
    'shared/config/config.lua',
    'shared/main.lua',
    'shared/utils/debug.lua',
    'shared/utils/events.lua',
    'shared/utils/utils.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core/*.lua',
    'server/modules/*.lua',
    'server/main.lua',
    'server/misc/*.lua'
}

client_scripts {
    'client/core/*.lua',
    'client/modules/*.lua',
    'client/main.lua'
}

dependencies {
    'oxmysql'
}

client_exports {
    'GetFramework'
}