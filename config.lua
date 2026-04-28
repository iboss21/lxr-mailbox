--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗      ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║      ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║      ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║      ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗ ██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System
    In-game postal / mail system for RedM servers

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Tagline:     Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!
    Description: ისტორია ცოცხლდება აქ! (History Lives Here!)
    Type:        Serious Hardcore Roleplay
    Access:      Discord & Whitelisted

    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    GitHub:      https://github.com/iBoss21
    Store:       https://theluxempire.tebex.io
    Server:      https://servers.redm.net/servers/detail/8gj7eb

    ═══════════════════════════════════════════════════════════════════════════════

    Version:     1.3.0
    Tags:        RedM, Georgian, SeriousRP, Whitelist, Mailbox, Economy, RP

    Framework Support:
    - LXR Core  (Primary)
    - RSG Core  (Primary)
    - VORP Core (Legacy / Supported)

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Script Author:    iBoss21 / The Lux Empire for The Land of Wolves
    Original Base:    BCC Team (bcc-mailbox)
    Converted By:     iBoss21 — wolves.land LXR codebase standard

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ MAIN CONFIGURATION ████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config = {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER BRANDING & INFO ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.ServerInfo = {
    name        = 'The Land of Wolves 🐺',
    tagline     = 'Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!',
    description = 'ისტორია ცოცხლდება აქ!', -- History Lives Here!
    type        = 'Serious Hardcore Roleplay',
    access      = 'Discord & Whitelisted',

    -- Contact & Links
    website       = 'https://www.wolves.land',
    discord       = 'https://discord.gg/CrKcWdfd3A',
    github        = 'https://github.com/iBoss21',
    store         = 'https://theluxempire.tebex.io',
    serverListing = 'https://servers.redm.net/servers/detail/8gj7eb',

    -- Developer Info
    developer = 'iBoss21 / The Lux Empire',

    -- Tags
    tags = {'RedM', 'Georgian', 'SeriousRP', 'Whitelist', 'Mailbox', 'PostalSystem', 'Contacts'},
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK SELECTION ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
-- Options: 'lxr-core' | 'rsg-core' | 'vorp' | 'auto'
-- 'auto' will detect whichever framework is running (LXR > RSG > VORP priority)

Config.Framework = 'auto'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ GENERAL SETTINGS ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.defaultlang = "en_lang"               -- Language: "en_lang" | "ro_lang" | "pl_lang"
Config.RegistrationFee = 20                  -- Cost to register a mailbox
Config.SendMessageFee = 5                    -- Cost to send a message
Config.TimePerMile = 0.1                     -- Time in seconds per mile (for delivery ETA)
Config.SendPigeon = false                    -- Spawn a pigeon animation when sending mail
Config.Notify = 'nui'

Config.devMode = false                       -- Enable verbose debug prints

Config.MailboxItem = "letter"                -- Item name used to open the mailbox UI
Config.LetterPurchaseCost = 10               -- Cost to buy a replacement letter at a mailbox
Config.LetterPurchaseRadius = 2.0            -- Distance (m) from a mailbox required to buy a letter
Config.UnreadReminderIntervalMinutes = 15    -- Minutes between unread mail reminders

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LETTER DURABILITY █████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.LetterDurability = {
    Enabled       = true,    -- Toggle the letter durability system
    Max           = 100,     -- Maximum durability when the letter is fresh
    DamagePerUse  = 5,       -- Durability lost each time the letter is used
    NotifyOnChange = false,  -- Notify the player after each use
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ MAILBOX LOCATIONS █████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.MailboxLocations = {
    { name = "Annesburg",   coords = vector3(2939.24,  1286.93,   44.65), blip = true, BlipSprite = 1861010125 },
    { name = "Armadillo",   coords = vector3(-3732.36, -2597.82, -12.94), blip = true, BlipSprite = 1861010125 },
    { name = "Blackwater",  coords = vector3(-874.91,  -1328.74,  43.96), blip = true, BlipSprite = 1861010125 },
    { name = "Rhodes",      coords = vector3(1225.58,  -1293.97,  76.91), blip = true, BlipSprite = 1861010125 },
    { name = "Saint Denis", coords = vector3(2749.45,  -1399.73,  46.19), blip = true, BlipSprite = 1861010125 },
    { name = "Strawberry",  coords = vector3(-1765.2,   -384.26, 157.74), blip = true, BlipSprite = 1861010125 },
    { name = "Valentine",   coords = vector3(-177.97,    628.17, 114.09), blip = true, BlipSprite = 1861010125 },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ MISC SETTINGS █████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.PlayYear = "1900"

Config.CoreHudIntegration = {
    enabled = true   -- Refresh lxr-corehud / bcc-corehud on mail events
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG SETTINGS ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Debug = false -- Enable debug prints and extra logging

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ END OF CONFIGURATION ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 STARTUP BANNER — boot print (server + client shared)
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(500)
    print([[

        ═══════════════════════════════════════════════════════════════════════════════

            ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗      ██████╗  ██████╗ ██╗  ██╗
            ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║      ██╔══██╗██╔═══██╗╚██╗██╔╝
            ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║      ██████╔╝██║   ██║ ╚███╔╝
            ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║      ██╔══██╗██║   ██║ ██╔██╗
            ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗ ██████╔╝╚██████╔╝██╔╝ ██╗
            ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝

        ═══════════════════════════════════════════════════════════════════════════════
        🐺 LXR MAILBOX SYSTEM — LOADED SUCCESSFULLY
        ═══════════════════════════════════════════════════════════════════════════════

        Version:     1.3.0
        Server:      The Land of Wolves 🐺
        Framework:   Auto-detect enabled (LXR → RSG → VORP)
        Locations:   ]] .. #Config.MailboxLocations .. [[ mailbox locations
        Debug:       ]] .. (Config.Debug and 'ENABLED' or 'DISABLED') .. [[

        ═══════════════════════════════════════════════════════════════════════════════

        Developer:   iBoss21 / The Lux Empire
        Website:     https://www.wolves.land
        Discord:     https://discord.gg/CrKcWdfd3A

        ═══════════════════════════════════════════════════════════════════════════════

    ]])
end)
