fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Framework'
author 'Rowden'
version '0.0.1-al'
description 'Framework'

ui_page 'ui/loader.html'

dependencies {
    'oxmysql'
}

shared_scripts {
    'shared/config.lua',
    'r_admin/shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'core/server/core/*.lua',
    'core/server/modules/*.lua',
    'core/server/misc/*.lua',
    'r_notify/server/*.lua',
    'r_char/server/*.lua',
    'r_metabolism/server/*.lua',
    'r_inventory/server/*.lua',
    'r_banking/server/*.lua',
    'r_admin/server/*.lua',
    'r_admin/server/modules/*.lua'
}

client_scripts {
    '@menuv/menuv.lua',
    'core/client/*.lua',
    'r_notify/client/*.lua',
    'r_char/client/*.lua',
    'r_metabolism/client/*.lua',
    'r_inventory/client/*.lua',
    'r_coma/client/*.lua',
    'r_banking/client/*.lua',
    'r_admin/client/utils/*.lua',
    'r_admin/client/*.lua',
    'r_admin/client/modules/*.lua',
    'r_admin/client/modules/vehicles/*.lua'
}

files {
    'ui/loader.html',
    'ui/loader.js',
    'ui/loader.css',

    'r_char/html/**/*',
    'r_notify/html/**/*',
    'r_metabolism/html/**/*',
    'r_inventory/html/**/*',
    'r_coma/html/**/*',
    'r_banking/html/**/*',
    'r_admin/html/**/*',
}
