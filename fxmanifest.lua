--[[
    🐺 LXR Mailbox System — fxmanifest.lua
]]

fx_version 'cerulean'
game       'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lxr-mailbox'
description '🐺 LXR Mailbox System — standalone postal UI | wolves.land'
author      'iBoss21 / The Lux Empire'
version     '1.3.0'
url         'https://www.wolves.land'

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

shared_scripts {
    'config.lua',
    'shared/framework.lua',
    'shared/locale.lua',
    'languages/*.lua',
}

client_scripts {
    'client/client.lua',
    'client/services/helpers.lua',
    'client/nui.lua',
    'client/controllers/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework_bridge.lua',
    'server/controllers.lua',
    'server/helpers.lua',
    'server/API.lua',
    'server/dbUpdater.lua',
    'server/items.lua',
    'server/net_actions.lua',
}

dependency {
    'oxmysql',
}
