--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System - Client Helpers

    Shared client-side state table and utility helpers (postal code sanitization,
    dev print, date formatting).

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

Mailbox = Mailbox or {}

-- shared client state, safe to load multiple times
Mailbox.State = Mailbox.State or {
    playermailboxId = nil,
    playerPostalCode = nil,
    selectedPostalCode = nil,
    selectedContactName = nil,
    contacts = {},
    lastMails = {},
    MailboxDisplay = nil,
    suppressMailNotify = false,
    nearMailbox = false,
}

-- helpers (no side effects)
function Mailbox.sanitizePostalCodeInput(value)
    if not value then return '' end
    local sanitized = tostring(value):gsub('%s+', '')
    return sanitized:upper()
end

if Config and Config.devMode then
    function Mailbox.devPrint(...)
        local parts = {}
        for i = 1, select('#', ...) do
            local v = select(i, ...)
            if type(v) == 'table' then v = json.encode(v) end
            parts[#parts+1] = tostring(v)
        end
        print(table.concat(parts, ' '))
    end
else
    function Mailbox.devPrint(...) end
end

function Mailbox.FormatDate(timestamp)
    return timestamp
end
