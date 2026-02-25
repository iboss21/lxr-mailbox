--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System - FiveM Resource Manifest

    ═══════════════════════════════════════════════════════════════════════════════
    RESOURCE INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Resource Name:  lxr-mailbox
    Version:        1.2.0
    Author:         iBoss21 / The Lux Empire
    Description:    Multi-framework in-game mailbox system for RedM with postal
                    codes, contacts, letter durability, and pigeon animation.

    Server:         The Land of Wolves 🐺
    Website:        https://www.wolves.land
    Discord:        https://discord.gg/CrKcWdfd3A

    ═══════════════════════════════════════════════════════════════════════════════
    FRAMEWORK SUPPORT
    ═══════════════════════════════════════════════════════════════════════════════

    Primary:
    - LXR Core (lxr-core)
    - RSG Core (rsg-core)

    Supported:
    - VORP Core (vorp_core)

    ═══════════════════════════════════════════════════════════════════════════════

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

lua54 'yes'
author 'iBoss21 / The Lux Empire'
description '🐺 LXR Mailbox System - wolves.land | Multi-framework in-game mailbox for RedM'
version '1.2.0'

shared_scripts {
    'config.lua',
    'shared/framework.lua',
    'shared/locale.lua',
    'languages/*.lua',
}

client_scripts {
    'client/client.lua',
    'client/controllers/*.lua',
    'client/services/*.lua',
    'client/menus/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/API.lua',
    'server/controllers.lua',
    'server/helpers.lua',
    'server/dbUpdater.lua',
    'server/server.lua',
}

dependency {
    'oxmysql',
    'feather-menu',
    'bcc-utils',
}
