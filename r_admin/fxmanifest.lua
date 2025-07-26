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
    'client/*.lua',
    'client/modules/*.lua'
}

server_scripts {
    'server/*.lua'
}

dependencies {
    'framework',
    'menuv',
    'r_notify'
}
