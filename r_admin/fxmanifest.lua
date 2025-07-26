fx_version 'cerulean'
game 'gta5'

author 'Rowden'
description 'Admin System'
version '1.0.0'

shared_script "shared/config.lua"

client_scripts {
    'config.lua',
    '@menuv/menuv.lua',
    'client/*.lua'
}

server_scripts {
    'config.lua',
    'server/*.lua'
}

dependencies {
    'framework',
    'menuv',
    'r_notify'
}
