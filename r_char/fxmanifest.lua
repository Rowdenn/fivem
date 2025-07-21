fx_version 'cerulean'
game 'gta5'

author 'Rowden'
description 'Character System'
version '1.0.0'

client_scripts {
    'client/character_utils.lua',
    'client/character_loader.lua',
    'client/character_creator.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js'
}