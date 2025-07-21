fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Inventory system'
author 'Rowden'
version '0.0.1-al'
description 'Système d\'inventaire'

shared_script 'shared/config.lua'

server_scripts {
    'server/sv_inventory.lua',
    'server/sv_events.lua',
}

client_scripts {
    'client/cl_inventory.lua',
    'client/cl_nui.lua',
    'client/cl_threads.lua',
    'client/cl_events.lua',
    'client/cl_globals.lua'
}

ui_page 'html/index.html'
ui_page_preload 'yes'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/*.png'
}

dependencies {
    'framework'
}