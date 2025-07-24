fx_version 'cerulean'
game 'gta5'

author 'Rowden'
description 'Metabolism System'
version '1.0.0'

dependencies {
    'r_coma'
} 

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}