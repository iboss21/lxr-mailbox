--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System - Server API

    Public API exposed via exports('getMailboxAPI') for use by other resources.
    Provides programmatic access to mailbox lookups and mail sending.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

MailboxAPI = {}

exports("getMailboxAPI", function()
    return MailboxAPI
end)

local Framework = LXRMailbox.Framework
local DEFAULT_SYSTEM_SENDER = 'Postmaster'

local function sanitizeString(value)
    if value == nil then return nil end
    value = tostring(value)
    if value:match("%S") then
        return value
    end
    return nil
end

local function utf8CharCount(str)
    str = str ~= nil and tostring(str) or ''
    if utf8 and utf8.len then
        local ok, n = pcall(utf8.len, str)
        if ok and type(n) == 'number' then
            return n
        end
    end
    return #str
end

local function normalizePriority(p)
    p = p and tostring(p):lower() or 'normal'
    if p == 'low' or p == 'high' then return p end
    return 'normal'
end

local function findPlayerByCharIdentifier(charIdentifier)
    if not charIdentifier then return nil end
    for _, playerId in ipairs(GetPlayers and GetPlayers() or {}) do
        local src = tonumber(playerId)
        local player = Framework.GetUser(src)
        if player then
            local char = Framework.GetCharacter(player)
            if char and tostring(Framework.GetCharIdentifier(char)) == tostring(charIdentifier) then
                return src
            end
        end
    end
    return nil
end

function MailboxAPI:GetMailboxByCharIdentifier(charIdentifier)
    if not charIdentifier then return nil end
    local rows = MySQL.query.await('SELECT * FROM bcc_mailboxes WHERE char_identifier = ? LIMIT 1', { charIdentifier })
    return rows and rows[1] or nil
end

function MailboxAPI:GetMailboxIdByCharIdentifier(charIdentifier)
    local mailbox = self:GetMailboxByCharIdentifier(charIdentifier)
    return mailbox and mailbox.mailbox_id or nil
end

function MailboxAPI:GetMailboxById(mailboxId)
    if not mailboxId then return nil end
    local rows = MySQL.query.await('SELECT * FROM bcc_mailboxes WHERE mailbox_id = ? LIMIT 1', { mailboxId })
    return rows and rows[1] or nil
end

function MailboxAPI:GetMailboxByPostalCode(postalCode)
    if not postalCode then return nil end
    local normalized = tostring(postalCode):gsub('%s+', '')
    if normalized == '' then return nil end
    normalized = string.upper(normalized)
    local rows = MySQL.query.await('SELECT * FROM bcc_mailboxes WHERE postal_code = ? LIMIT 1', { normalized })
    return rows and rows[1] or nil
end

function MailboxAPI:GetPlayerSourceByMailboxId(mailboxId)
    local mailbox = self:GetMailboxById(mailboxId)
    if not mailbox then return nil end
    return findPlayerByCharIdentifier(mailbox.char_identifier)
end

function MailboxAPI:GetPlayerSourceByCharIdentifier(charIdentifier)
    return findPlayerByCharIdentifier(charIdentifier)
end

local function insertMailRow(fromChar, toMailbox, fromName, subject, message, location, etaTimestamp,
    mailCategory, letterheadKey, priority, isOfficial, senderMailboxId)
    local timestamp = os.date('%Y-%m-%d %H:%M:%S', os.time())
    return MySQL.insert.await([[
        INSERT INTO bcc_mailbox_messages (
            from_char, to_char, from_name, subject, message, location, timestamp, eta_timestamp, is_read,
            mail_category, letterhead_key, priority, is_official, sender_mailbox_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        fromChar,
        tostring(toMailbox),
        fromName,
        subject,
        message,
        location,
        timestamp,
        etaTimestamp,
        0,
        mailCategory or 'personal',
        letterheadKey,
        priority or 'normal',
        (isOfficial and 1) or 0,
        senderMailboxId,
    })
end

function MailboxAPI:SendMailToMailbox(mailboxId, subject, message, options)
    if not mailboxId then
        return false, 'invalid_mailbox'
    end

    local numericMailboxId = tonumber(mailboxId)
    if not numericMailboxId then
        return false, 'invalid_mailbox'
    end

    local mailbox = self:GetMailboxById(numericMailboxId)
    if not mailbox then
        return false, 'mailbox_not_found'
    end

    subject = subject ~= nil and tostring(subject) or ''
    message = message ~= nil and tostring(message) or ''

    local ml = Config.MailLimits or {}
    local maxSub = tonumber(ml.MaxSubjectLength) or 200
    local maxMsg = tonumber(ml.MaxMessageLength) or 8000
    if utf8CharCount(subject) > maxSub then
        return false, 'subject_too_long'
    end
    if utf8CharCount(message) > maxMsg then
        return false, 'message_too_long'
    end

    subject = sanitizeString(subject)
    message = sanitizeString(message)
    if not subject or not message then
        return false, 'invalid_content'
    end

    local fromChar = sanitizeString(options and options.fromChar)
    local fromName = sanitizeString(options and options.fromName) or DEFAULT_SYSTEM_SENDER
    local location = sanitizeString(options and options.location)
    local etaTimestamp = options and tonumber(options.etaTimestamp) or nil

    local mailCategory = NormalizeMailCategory(options and options.mailCategory)
    local letterheadKey = sanitizeString(options and options.letterheadKey)
    local priorityRaw = sanitizeString(options and options.priority) or 'normal'
    local priority = normalizePriority(priorityRaw)
    local isOfficial = (options and options.isOfficial) and true or false
    local senderMailboxId = options and tonumber(options.senderMailboxId) or nil

    local insertedId = insertMailRow(
        fromChar,
        numericMailboxId,
        fromName,
        subject,
        message,
        location,
        etaTimestamp,
        mailCategory,
        letterheadKey,
        priority,
        isOfficial,
        senderMailboxId
    )
    if not insertedId then
        return false, 'insert_failed'
    end

    if not (options and options.skipAudit) and LXRMailbox and LXRMailbox.AppendMailAudit then
        local cfg = Config.MailAuditLog
        if cfg and cfg.Enabled then
            local fromPlayer = options and options.auditPlayerSource
            if fromPlayer or cfg.LogApiSends then
                LXRMailbox.AppendMailAudit('mail_send', {
                    source_player = fromPlayer,
                    char_identifier = options and options.auditCharIdentifier,
                    mailbox_id = senderMailboxId,
                    target_mailbox_id = numericMailboxId,
                    detail = string.format('msg=%s cat=%s', tostring(insertedId), mailCategory),
                })
            end
        end
    end

    if not (options and options.skipNotify) then
        local notifTarget = findPlayerByCharIdentifier(mailbox.char_identifier)
        if notifTarget then
            local mailboxIdStr = tostring(mailbox.mailbox_id)
            local postalCodeStr = tostring(mailbox.postal_code or '')
            local charIdentifierStr = tostring(mailbox.char_identifier or '')
            local unreadCount = MySQL.scalar.await(
                'SELECT COUNT(*) FROM bcc_mailbox_messages WHERE is_read = 0 AND (to_char = ? OR to_char = ? OR to_char = ?)',
                { mailboxIdStr, postalCodeStr, charIdentifierStr }
            )

            if (unreadCount or 0) > 0 then
                TriggerClientEvent('lxr-mailbox:checkMailNotification', notifTarget, { unreadCount = unreadCount })
            end
        end
    end

    RefreshMailboxHud(mailbox.char_identifier)

    return true, insertedId
end

function MailboxAPI:SendMailToCharacter(charIdentifier, subject, message, options)
    if not charIdentifier then
        return false, 'invalid_character'
    end
    local mailbox = self:GetMailboxByCharIdentifier(charIdentifier)
    if not mailbox then
        return false, 'mailbox_not_found'
    end
    return self:SendMailToMailbox(mailbox.mailbox_id, subject, message, options)
end

function MailboxAPI:GetUnreadMessages(mailboxRef, opts)
    if not mailboxRef then return nil end

    local mailbox = nil
    if type(mailboxRef) == 'table' then
        mailbox = mailboxRef
    else
        local numericId = tonumber(mailboxRef)
        if numericId then
            mailbox = self:GetMailboxById(numericId)
        end
        if not mailbox then
            mailbox = self:GetMailboxByPostalCode(mailboxRef)
        end
        if not mailbox then
            mailbox = self:GetMailboxByCharIdentifier(mailboxRef)
        end
    end

    if not mailbox then
        return nil
    end

    local limit = tonumber(opts and opts.limit) or 0
    local query = [[
        SELECT *
        FROM bcc_mailbox_messages
        WHERE is_read = 0 AND (to_char = ? OR to_char = ? OR to_char = ?)
        ORDER BY id DESC
    ]]
    local params = {
        tostring(mailbox.mailbox_id),
        mailbox.postal_code and tostring(mailbox.postal_code) or '',
        mailbox.char_identifier and tostring(mailbox.char_identifier) or ''
    }

    if limit > 0 then
        query = query .. ' LIMIT ' .. tonumber(limit)
    end

    local rows = MySQL.query.await(query, params) or {}
    for _, row in ipairs(rows) do
        if type(row.timestamp) == 'number' then
            row.timestamp = os.date('%Y-%m-%d %H:%M:%S', row.timestamp)
        end
    end

    return rows
end
