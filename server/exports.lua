--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — Resource exports

    Thin wrappers over MailboxAPI for other resources (postal code, official notices).

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

local MailboxAPI = MailboxAPI or exports['lxr-mailbox']:getMailboxAPI()

--- Send to a mailbox by postal code (e.g. AB123). `options` same as MailboxAPI:SendMailToMailbox.
exports('SendMailToPostalCode', function(postalCode, subject, message, options)
    if not postalCode then return false, 'invalid_postal' end
    local mb = MailboxAPI:GetMailboxByPostalCode(postalCode)
    if not mb then return false, 'mailbox_not_found' end
    return MailboxAPI:SendMailToMailbox(mb.mailbox_id, subject, message, options or {})
end)

--- Alias for scripts that prefer this name.
exports('SendPostalMail', function(postalCode, subject, message, options)
    if not postalCode then return false, 'invalid_postal' end
    local mb = MailboxAPI:GetMailboxByPostalCode(postalCode)
    if not mb then return false, 'mailbox_not_found' end
    return MailboxAPI:SendMailToMailbox(mb.mailbox_id, subject, message, options or {})
end)

--- Structured government / faction notice. `payload`: subject, body, fromName, letterheadKey,
--- isOfficial (default true), priority, category ('government' default), skipNotify, skipAudit.
exports('SendOfficialNotice', function(charIdentifier, payload)
    if not charIdentifier then return false, 'invalid_character' end
    payload = payload or {}
    local subject = payload.subject or 'Official Notice'
    local body = payload.body or ''
    local category = NormalizeMailCategory(payload.category or payload.mailCategory or 'government')
    local opts = {
        fromName = payload.fromName or payload.department or 'Office',
        mailCategory = category,
        letterheadKey = payload.letterheadKey,
        isOfficial = payload.isOfficial ~= false,
        priority = payload.priority or 'high',
        skipNotify = payload.skipNotify,
        skipAudit = payload.skipAudit,
        etaTimestamp = payload.etaTimestamp,
        location = payload.location,
        fromChar = payload.fromChar,
    }
    return MailboxAPI:SendMailToCharacter(charIdentifier, subject, body, opts)
end)
