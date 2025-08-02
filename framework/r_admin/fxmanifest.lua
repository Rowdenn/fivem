fx_version 'cerulean'
game 'gta5'

author 'Rowden'
description 'Admin System'
version '1.0.0'

shared_script "shared/config.lua"

shared_scripts {
    'shared/config.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_scripts {
    '@menuv/menuv.lua',
    'client/utils/*.lua',
    'client/*.lua',
    'client/modules/*.lua',
    'client/modules/vehicles/*.lua'
}

server_scripts {
    'server/*.lua',
    'server/modules/*.lua'
}

dependencies {
    'framework',
    'menuv',
    'r_notify',
    'r_metabolism'
}
