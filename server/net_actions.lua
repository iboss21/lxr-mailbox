--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — Server Net Actions

    lxr-mailbox:req dispatcher, LuaLXRMailbox.NetActions handlers, registration refunds,
    net rate limiting, mail/contacts APIs.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

LXRMailbox = LXRMailbox or {}
LXRMailbox.NetActions = LXRMailbox.NetActions or {}

local Framework = LXRMailbox.Framework
local MailboxAPI = MailboxAPI or exports['lxr-mailbox']:getMailboxAPI()

local sendSpamState = {}

local function normalizeMailCategory(raw)
    local c = raw and tostring(raw):lower() or 'personal'
    for _, def in ipairs(Config.MailCategories or {}) do
        if def.id == c then return c end
    end
    return 'personal'
end

local function resolveLetterhead(src, key)
    if not key or tostring(key) == '' then
        return nil, 0
    end
    key = string.lower(tostring(key))
    local cfgHead = Config.Letterheads and Config.Letterheads[key]
    if not cfgHead then
        return nil, 2
    end
    local jobs = cfgHead.jobs
    if not jobs or next(jobs) == nil then
        return key, 0
    end
    local info = Framework.GetJobInfo(src)
    if not info or not info.name or info.name == '' then
        return nil, 1
    end
    for jobName, minGrade in pairs(jobs) do
        if string.lower(tostring(jobName)) == info.name and (info.grade >= (tonumber(minGrade) or 0)) then
            return key, 0
        end
    end
    return nil, 1
end

local function mailPriority(raw)
    local p = raw and tostring(raw):lower() or 'normal'
    if p == 'low' or p == 'high' then return p end
    return 'normal'
end

local function isOfficialLetterheadKey(key)
    if not key then return false end
    local c = Config.Letterheads and Config.Letterheads[key]
    if not c or not c.jobs then return false end
    return next(c.jobs) ~= nil
end

local function djb2Hash(s)
    local hash = 5381
    s = s or ''
    for i = 1, #s do
        hash = ((hash * 33) + string.byte(s, i)) % 2147483647
    end
    return hash
end

local function allowPlayerSendAntiSpam(src, targetMailboxId, subject, message)
    local cfg = Config.MailAntiSpam
    if not cfg or not cfg.Enabled then return true end
    if not sendSpamState[src] then
        sendSpamState[src] = { sends = {}, lastTo = {}, recentHash = {} }
    end
    local b = sendSpamState[src]
    local now = os.time()
    local cutoff = now - 60
    local newSends = {}
    for _, t in ipairs(b.sends) do
        if t > cutoff then newSends[#newSends + 1] = t end
    end
    b.sends = newSends
    local maxPerMin = tonumber(cfg.MaxSendsPerMinute) or 20
    if #b.sends >= maxPerMin then return false, 'spam_rate' end

    local tid = tostring(targetMailboxId)
    local cd = tonumber(cfg.SameRecipientCooldownSec) or 0
    if cd > 0 and b.lastTo[tid] and (now - b.lastTo[tid]) < cd then
        return false, 'spam_recipient_cooldown'
    end

    local dupWin = tonumber(cfg.DuplicateMessageWindowSec) or 0
    if dupWin > 0 then
        local h = djb2Hash(subject .. '\0' .. message)
        local prev = b.recentHash[h]
        if prev and (now - prev) < dupWin then
            return false, 'spam_duplicate'
        end
        b.recentHash[h] = now
    end

    b.sends[#b.sends + 1] = now
    b.lastTo[tid] = now
    return true
end

local function shapeContacts(rows)
    local contacts = {}
    for _, r in ipairs(rows or {}) do
        local fullName = TrimWhitespace((r.first_name or '') .. ' ' .. (r.last_name or ''))
        local alias = r.contact_alias and TrimWhitespace(r.contact_alias) or nil
        local display = (alias and alias ~= '' and alias)
            or (fullName ~= '' and fullName)
            or tostring(r.postal_code)

        contacts[#contacts + 1] = {
            id = r.id,
            displayName = display,
            mailboxId = tostring(r.mailbox_id),
            postalCode = r.postal_code and tostring(r.postal_code) or nil,
            firstName = r.first_name,
            lastName = r.last_name,
        }
    end
    return contacts
end

LXRMailbox.NetActions.SendMail = function(src, params)
    local _source = src
    local recipientPostalCode = params and params.recipientPostalCode
    local subject = params and params.subject
    local message = params and params.message

    local response = { ok = true, success = false }

    local User = Framework.GetUser(_source)
    if not User then
        response.reason = 'user_not_found'
        response.ok = false
        return response
    end

    local Character = Framework.GetCharacter(User)
    if not Character then
        response.reason = 'character_not_found'
        response.ok = false
        return response
    end

    local availableMoney = Framework.GetMoney(User)
    if availableMoney < Config.SendMessageFee then
        NotifyClient(_source, _U('NotEnoughMoney'), 'error', 5000)
        response.reason = 'insufficient_funds'
        response.ok = false
        return response
    end

    local rawCode = recipientPostalCode and tostring(recipientPostalCode) or ''
    local normalizedCode = NormalizePostalCode(recipientPostalCode)
    if not normalizedCode then
        NotifyClient(_source, _U('InvalidRecipient'), 'error', 5000)
        response.reason = 'invalid_recipient'
        response.ok = false
        return response
    end

    local targetMailbox = MailboxAPI:GetMailboxByPostalCode(normalizedCode)
    if not targetMailbox then
        local potentialId = tonumber(normalizedCode)
        if potentialId then
            targetMailbox = MailboxAPI:GetMailboxById(potentialId)
        end
    end
    if not targetMailbox and rawCode ~= '' then
        targetMailbox = MailboxAPI:GetMailboxByCharIdentifier(rawCode)
    end
    if not targetMailbox and normalizedCode ~= rawCode then
        targetMailbox = MailboxAPI:GetMailboxByCharIdentifier(normalizedCode)
    end
    if not targetMailbox then
        NotifyClient(_source, _U('InvalidRecipient'), 'error', 5000)
        response.reason = 'invalid_recipient'
        response.ok = false
        return response
    end

    local spamOk, spamReason = allowPlayerSendAntiSpam(_source, targetMailbox.mailbox_id, subject, message)
    if not spamOk then
        NotifyClient(_source, _U('MailAntiSpamCooldown'), 'error', 4500)
        response.reason = spamReason or 'spam'
        response.ok = false
        return response
    end

    local senderMailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(Character))
    if not senderMailbox then
        NotifyClient(_source, _U('MailboxNotFound'), 'error', 5000)
        response.reason = 'sender_mailbox_not_found'
        response.ok = false
        return response
    end

    local senderName = Framework.GetFirstName(Character) .. ' ' .. Framework.GetLastName(Character)
    local lhKey, lhErr = resolveLetterhead(_source, params and params.letterheadKey)
    if lhErr == 2 then
        NotifyClient(_source, _U('LetterheadInvalid'), 'error', 5000)
        response.reason = 'invalid_letterhead'
        response.ok = false
        return response
    end
    if lhErr == 1 then
        NotifyClient(_source, _U('LetterheadNotPermitted'), 'error', 5000)
        response.reason = 'letterhead_denied'
        response.ok = false
        return response
    end

    local cat = normalizeMailCategory(params and params.mailCategory)
    local pri = mailPriority(params and params.priority)
    local official = lhKey ~= nil and isOfficialLetterheadKey(lhKey)

    local charId = Framework.GetCharIdentifier(Character)
    local options = {
        fromChar = senderMailbox.postal_code,
        fromName = senderName,
        senderMailboxId = senderMailbox.mailbox_id,
        mailCategory = cat,
        letterheadKey = lhKey,
        priority = pri,
        isOfficial = official,
        auditPlayerSource = _source,
        auditCharIdentifier = charId and tostring(charId) or nil,
    }

    local ok, result = MailboxAPI:SendMailToMailbox(targetMailbox.mailbox_id, subject, message, options)

    if ok then
        Framework.RemoveMoney(User, Config.SendMessageFee)
        local draftId = params and tonumber(params.draftId)
        if draftId and senderMailbox.mailbox_id then
            DeleteDraftForOwner(draftId, senderMailbox.mailbox_id)
        end
        local recipientLabel = TrimWhitespace((targetMailbox.first_name or '') .. ' ' .. (targetMailbox.last_name or ''))
        if recipientLabel == '' then
            recipientLabel = targetMailbox.postal_code or tostring(targetMailbox.mailbox_id)
        end
        NotifyClient(_source, _U('MessageSent') .. recipientLabel, 'success', 5000)
        response.success = true
        response.mailboxId = targetMailbox.mailbox_id
        response.recipientLabel = recipientLabel
        response.ok = true
        return response
    end

    if result == 'invalid_content' then
        NotifyClient(_source, _U('InvalidRecipient'), 'error', 5000)
    elseif result == 'subject_too_long' then
        NotifyClient(_source, _U('MailSubjectTooLong'), 'error', 5000)
    elseif result == 'message_too_long' then
        NotifyClient(_source, _U('MailMessageTooLong'), 'error', 5000)
    elseif result == 'invalid_mailbox' or result == 'mailbox_not_found' then
        NotifyClient(_source, _U('InvalidRecipient'), 'error', 5000)
    else
        NotifyClient(_source, _U('MessageFailed'), 'error', 5000)
    end
    response.reason = result or 'unknown'
    response.ok = false
    response.success = false
    return response
end

LXRMailbox.NetActions.UpdateMailboxInfo = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local charIdentifier = Framework.GetCharIdentifier(char)
    local firstName = Framework.GetFirstName(char)
    local lastName = Framework.GetLastName(char)

    local affectedRows = UpdateMailboxNames(charIdentifier, firstName, lastName)

    if affectedRows > 0 then
        local mailbox = MailboxAPI:GetMailboxByCharIdentifier(charIdentifier)
        if mailbox then
            return {
                ok = true,
                mailboxId = mailbox.mailbox_id,
                postalCode = mailbox.postal_code,
            }
        end
        return { ok = true }
    end

    return { ok = false }
end

LXRMailbox.NetActions.CheckMailbox = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local charIdentifier = Framework.GetCharIdentifier(char)
    local fullName = (Framework.GetFirstName(char) or '') .. ' ' .. (Framework.GetLastName(char) or '')

    local mailboxRow = GetMailboxByCharIdentifier(charIdentifier)

    if mailboxRow then
        return {
            ok = true,
            fullName = TrimWhitespace(fullName),
            hasMailbox = true,
            mailboxId = mailboxRow.mailbox_id,
            postalCode = mailboxRow.postal_code,
        }
    end

    return {
        ok = true,
        fullName = TrimWhitespace(fullName),
        hasMailbox = false,
    }
end

LXRMailbox.NetActions.FetchMail = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local mailboxRow = GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailboxRow then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false }
    end

    local recipientMailboxId = mailboxRow.mailbox_id
    local recipientPostal = mailboxRow.postal_code
    local charIdentifier = tostring(Framework.GetCharIdentifier(char))

    local mails = GetMailsForRecipient(recipientMailboxId, recipientPostal, charIdentifier)

    if #mails == 0 then
        NotifyClient(src, _U('NoMailsFound'), 'info', 5000)
        return { ok = true, mails = {}, count = 0 }
    end

    return { ok = true, mails = mails, count = #mails }
end

LXRMailbox.NetActions.FetchSentMail = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local mailboxRow = GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailboxRow then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false }
    end

    local mails = GetSentMailsForSender(mailboxRow.mailbox_id, mailboxRow.postal_code)
    return { ok = true, mails = mails, count = #mails }
end

LXRMailbox.NetActions.GetDrafts = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local mailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false }
    end

    local rows = GetDraftsForOwner(mailbox.mailbox_id)
    return { ok = true, drafts = rows, count = #rows }
end

LXRMailbox.NetActions.SaveDraft = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end

    local mailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false, reason = 'mailbox_not_found' }
    end

    local ml = Config.MailLimits or {}
    local maxSub = tonumber(ml.MaxSubjectLength) or 200
    local maxMsg = tonumber(ml.MaxMessageLength) or 8000
    local subject = params and params.subject and tostring(params.subject) or ''
    local message = params and params.message and tostring(params.message) or ''
    if utf8 and utf8.len then
        local okS, ns = pcall(utf8.len, subject)
        local okM, nm = pcall(utf8.len, message)
        if okS and ns and ns > maxSub then
            NotifyClient(src, _U('MailSubjectTooLong'), 'error', 5000)
            return { ok = false, reason = 'subject_too_long' }
        end
        if okM and nm and nm > maxMsg then
            NotifyClient(src, _U('MailMessageTooLong'), 'error', 5000)
            return { ok = false, reason = 'message_too_long' }
        end
    else
        if #subject > maxSub then
            NotifyClient(src, _U('MailSubjectTooLong'), 'error', 5000)
            return { ok = false, reason = 'subject_too_long' }
        end
        if #message > maxMsg then
            NotifyClient(src, _U('MailMessageTooLong'), 'error', 5000)
            return { ok = false, reason = 'message_too_long' }
        end
    end

    local recipient = params and params.recipientPostal and TrimWhitespace(tostring(params.recipientPostal)) or nil
    if recipient == '' then recipient = nil end
    local cat = normalizeMailCategory(params and params.mailCategory)
    local lhRaw = params and params.letterheadKey
    local lhKey = nil
    if lhRaw and tostring(lhRaw) ~= '' then
        lhKey = string.lower(tostring(lhRaw))
        if not Config.Letterheads or not Config.Letterheads[lhKey] then
            lhKey = nil
        end
    end

    local draftId = params and tonumber(params.draftId)
    if draftId then
        local n = UpdateDraftForOwner(draftId, mailbox.mailbox_id, recipient, subject, message, cat, lhKey)
        if n <= 0 then
            return { ok = false, reason = 'update_failed' }
        end
        local rows = GetDraftsForOwner(mailbox.mailbox_id)
        return { ok = true, draftId = draftId, drafts = rows, count = #rows }
    end

    local insertId = InsertDraft(mailbox.mailbox_id, recipient, subject, message, cat, lhKey)
    if not insertId then
        return { ok = false, reason = 'insert_failed' }
    end
    local rows = GetDraftsForOwner(mailbox.mailbox_id)
    return { ok = true, draftId = insertId, drafts = rows, count = #rows }
end

LXRMailbox.NetActions.DeleteDraft = function(src, params)
    local draftId = params and tonumber(params.draftId)
    if not draftId then
        return { ok = false, reason = 'invalid_id' }
    end
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end
    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end
    local mailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false, reason = 'mailbox_not_found' }
    end
    local n = DeleteDraftForOwner(draftId, mailbox.mailbox_id)
    if n <= 0 then
        return { ok = false, reason = 'delete_failed' }
    end
    local rows = GetDraftsForOwner(mailbox.mailbox_id)
    return { ok = true, drafts = rows, count = #rows }
end

LXRMailbox.NetActions.PollUnread = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false }
    end

    local mailbox = GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false }
    end

    local mailboxIdStr = tostring(mailbox.mailbox_id)
    local postalCodeStr = mailbox.postal_code and tostring(mailbox.postal_code) or ''
    local charIdStr = tostring(Framework.GetCharIdentifier(char))

    local unreadCount = CountUnreadForRecipient(mailboxIdStr, postalCodeStr, charIdStr)

    return { ok = true, unread = unreadCount }
end

LXRMailbox.NetActions.MarkMailRead = function(src, params)
    local numericId = params and tonumber(params.mailId)
    if not numericId then
        return { ok = false, reason = 'invalid_id' }
    end

    local markRead = (params and params.read)
    if markRead == nil then markRead = true end
    local desiredState = markRead and 1 or 0

    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end

    local mailbox = GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false, reason = 'mailbox_not_found' }
    end

    local mail = GetMailById(numericId)
    if not mail then
        return { ok = false, reason = 'mail_not_found' }
    end

    local toChar = mail.to_char and tostring(mail.to_char) or ''
    local authorized = (toChar ~= '') and (
        toChar == tostring(mailbox.mailbox_id)
        or toChar == tostring(mailbox.postal_code)
        or toChar == tostring(mailbox.char_identifier)
    )

    if not authorized then
        return { ok = false, reason = 'not_authorized' }
    end

    local currentState = tonumber(mail.is_read or 0) or 0
    if currentState == desiredState then
        return { ok = true, alreadySet = true, readState = desiredState }
    end

    local updated = UpdateMailReadState(
        desiredState,
        numericId,
        tostring(mailbox.mailbox_id),
        mailbox.postal_code and tostring(mailbox.postal_code) or '',
        mailbox.char_identifier and tostring(mailbox.char_identifier) or ''
    )

    if updated > 0 then
        RefreshMailboxHud(Framework.GetCharIdentifier(char))
        return { ok = true, readState = desiredState }
    end

    return { ok = false, reason = 'update_failed' }
end

LXRMailbox.NetActions.PurchaseLetter = function(src, params, reqId)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = 'user_not_found' })
        return
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = 'character_not_found' })
        return
    end

    local ped = GetPlayerPed(src)
    if not ped or ped <= 0 then
        TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = 'invalid_ped' })
        return
    end

    local pedCoords = GetEntityCoords(ped)
    local radius = tonumber(Config.LetterPurchaseRadius or 3.0) or 3.0
    local nearMailbox = false

    if Config.MailboxLocations then
        for _, location in pairs(Config.MailboxLocations) do
            local loc = location and location.coords
            if loc then
                local dx = pedCoords.x - loc.x
                local dy = pedCoords.y - loc.y
                local dz = pedCoords.z - loc.z
                local distanceSquared = dx * dx + dy * dy + dz * dz
                if distanceSquared <= (radius * radius) then
                    nearMailbox = true
                    break
                end
            end
        end
    end

    if not nearMailbox then
        NotifyClient(src, _U('LetterPurchaseNotNear'), 'error', 5000)
        TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = 'not_near_mailbox' })
        return
    end

    local cost = tonumber(Config.LetterPurchaseCost or 0) or 0
    local balance = Framework.GetMoney(user)
    if cost > 0 and balance < cost then
        NotifyClient(src, _U('LetterPurchaseNoFunds'), 'error', 5000)
        TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = 'insufficient_funds' })
        return
    end

    local itemName = Config.MailboxItem or 'letter'

    Framework.CanCarryItem(src, itemName, 1, function(canCarry)
        if not canCarry then
            NotifyClient(src, _U('LetterInventoryFull'), 'error', 5000)
            TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = 'cannot_carry' })
            return
        end

        if cost > 0 then
            Framework.RemoveMoney(user, cost)
        end

        local metadata
        local durCfg = Config.LetterDurability
        if durCfg and durCfg.Enabled then
            local maxValue = tonumber(durCfg.Max or 100) or 100
            metadata = {
                durability = maxValue,
                description = _U('LetterDurabilityDescription', maxValue),
            }
        end

        Framework.AddItem(src, itemName, 1, metadata)

        NotifyClient(src, _U('LetterPurchased'), 'success', 5000)
        TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = true, success = true })
    end)
end

LXRMailbox.NetActions.RegisterMailbox = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end

    local charIdentifier = Framework.GetCharIdentifier(char)
    if GetMailboxByCharIdentifier(charIdentifier) then
        NotifyClient(src, _U('MailboxAlreadyRegistered'), 'error', 5000)
        return { ok = false, reason = 'already_registered' }
    end

    local fee = tonumber(Config.RegistrationFee) or 0
    local balance = Framework.GetMoney(user)
    if balance < fee then
        NotifyClient(src, _U('MailboxRegistrationFee'), 'error', 5000)
        return { ok = false, reason = 'insufficient_funds' }
    end

    Framework.RemoveMoney(user, fee)

    local firstName = Framework.GetFirstName(char)
    local lastName = Framework.GetLastName(char)
    local postalCode = GenerateUniquePostalCode()

    local insertId = CreateMailbox(charIdentifier, firstName, lastName, postalCode)
    if not insertId then
        if fee > 0 then
            Framework.AddMoney(user, fee)
        end
        NotifyClient(src, _U('MailboxRegistrationFailed'), 'error', 5000)
        return { ok = false, reason = 'insert_failed' }
    end

    local result = GetMailboxById(insertId)
    if not result then
        if fee > 0 then
            Framework.AddMoney(user, fee)
        end
        NotifyClient(src, _U('RegistrationError'), 'error', 5000)
        return { ok = false, reason = 'registration_error' }
    end

    NotifyClient(src, _U('MailboxRegistered'), 'success', 5000)
    if LXRMailbox.AppendMailAudit then
        LXRMailbox.AppendMailAudit('mailbox_register', {
            source_player = src,
            char_identifier = charIdentifier and tostring(charIdentifier) or nil,
            mailbox_id = result.mailbox_id,
            target_mailbox_id = nil,
            detail = 'postal=' .. tostring(postalCode),
        })
    end
    return {
        ok = true,
        mailboxId = result.mailbox_id,
        postalCode = postalCode,
    }
end

LXRMailbox.NetActions.DeleteMail = function(src, params)
    local mailId = params and tonumber(params.mailId)
    if not mailId then
        return { ok = false, reason = 'invalid_id' }
    end

    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end
    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end

    local mailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false, reason = 'mailbox_not_found' }
    end

    local charIdStr = tostring(Framework.GetCharIdentifier(char))
    local affected = DeleteMailForRecipient(
        mailId,
        mailbox.mailbox_id,
        mailbox.postal_code,
        charIdStr
    )
    if affected > 0 then
        RefreshMailboxHud(Framework.GetCharIdentifier(char))
        NotifyClient(src, _U('MailDeleted'), 'success', 5000)
        if LXRMailbox.AppendMailAudit then
            LXRMailbox.AppendMailAudit('mail_delete', {
                source_player = src,
                char_identifier = charIdStr,
                mailbox_id = mailbox.mailbox_id,
                target_mailbox_id = nil,
                detail = 'mailId=' .. tostring(mailId),
            })
        end
        return { ok = true }
    end

    NotifyClient(src, _U('MailDeletionFailed'), 'error', 5000)
    return { ok = false, reason = 'delete_failed' }
end

LXRMailbox.NetActions.GetRecipients = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end

    local mailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false, reason = 'mailbox_not_found' }
    end

    local rows = FetchContactsRows(mailbox.mailbox_id) or {}
    local contacts = shapeContacts(rows)

    return { ok = true, contacts = contacts, count = #contacts }
end

LXRMailbox.NetActions.GetContacts = function(src, params)
    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end

    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end

    local mailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not mailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false, reason = 'mailbox_not_found' }
    end

    local rows = FetchContactsRows(mailbox.mailbox_id)
    local contacts = shapeContacts(rows)

    return { ok = true, contacts = contacts, count = #contacts }
end

LXRMailbox.NetActions.AddContact = function(src, params)
    local contactCode = params and params.contactCode
    local contactAlias = params and params.contactAlias

    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end
    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end

    local ownerMailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not ownerMailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false, reason = 'mailbox_not_found' }
    end

    local normalized = NormalizePostalCode(contactCode)
    if not normalized then
        NotifyClient(src, _U('InvalidContactCode'), 'error', 5000)
        return { ok = false, reason = 'invalid_code' }
    end

    local targetMailbox = MailboxAPI:GetMailboxByPostalCode(normalized)
    if not targetMailbox then
        NotifyClient(src, _U('InvalidContactCode'), 'error', 5000)
        return { ok = false, reason = 'target_not_found' }
    end

    if targetMailbox.mailbox_id == ownerMailbox.mailbox_id then
        NotifyClient(src, _U('CannotAddSelf'), 'error', 5000)
        return { ok = false, reason = 'self_not_allowed' }
    end

    local existing = FindContactByOwnerAndTarget(ownerMailbox.mailbox_id, targetMailbox.mailbox_id)
    if existing then
        NotifyClient(src, _U('ContactAlreadyExists'), 'error', 5000)
        return { ok = false, reason = 'duplicate' }
    end

    local insertId = InsertContact(ownerMailbox.mailbox_id, targetMailbox.mailbox_id, contactAlias)
    if not insertId then
        NotifyClient(src, _U('ContactAddFailed') or _U('MailboxRegistrationFailed'), 'error', 5000)
        return { ok = false, reason = 'insert_failed' }
    end

    local rows = FetchContactsRows(ownerMailbox.mailbox_id)
    local contacts = shapeContacts(rows)

    NotifyClient(src, _U('ContactAdded'), 'success', 5000)
    return { ok = true, contacts = contacts, count = #contacts }
end

LXRMailbox.NetActions.RemoveContact = function(src, params)
    local contactId = params and tonumber(params.contactId)

    local user = Framework.GetUser(src)
    if not user then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'user_not_found' }
    end
    local char = Framework.GetCharacter(user)
    if not char then
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        return { ok = false, reason = 'character_not_found' }
    end

    local ownerMailbox = MailboxAPI:GetMailboxByCharIdentifier(Framework.GetCharIdentifier(char))
    if not ownerMailbox then
        NotifyClient(src, _U('MailboxNotFound'), 'error', 5000)
        return { ok = false, reason = 'mailbox_not_found' }
    end

    if not contactId then
        NotifyClient(src, _U('InvalidContactRemoval'), 'error', 5000)
        return { ok = false, reason = 'invalid_id' }
    end

    local affected = DeleteContact(ownerMailbox.mailbox_id, contactId)
    if affected <= 0 then
        NotifyClient(src, _U('InvalidContactRemoval'), 'error', 5000)
        return { ok = false, reason = 'remove_failed' }
    end

    local rows = FetchContactsRows(ownerMailbox.mailbox_id)
    local contacts = shapeContacts(rows)

    NotifyClient(src, _U('ContactRemoved'), 'success', 5000)
    return { ok = true, contacts = contacts, count = #contacts }
end

AddEventHandler('playerDropped', function()
    local src = source
    sendSpamState[src] = nil
    if LXRMailbox.NetRate and LXRMailbox.NetRate.ClearPlayer then
        LXRMailbox.NetRate.ClearPlayer(src)
    end
end)

RegisterNetEvent('lxr-mailbox:req', function(reqId, action, payload)
    local src = source
    if LXRMailbox.NetRate and LXRMailbox.NetRate.AllowRequest then
        local okRl, reasonRl = LXRMailbox.NetRate.AllowRequest(src, action)
        if not okRl then
            NotifyClient(src, _U('NetRateLimited'), 'error', 3500)
            TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = reasonRl or 'rate_limited' })
            return
        end
    end
    local fn = LXRMailbox.NetActions[action]
    if not fn then
        TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = 'unknown_action' })
        return
    end

    if action == 'PurchaseLetter' then
        fn(src, payload or {}, reqId)
        return
    end

    local pok, result = pcall(fn, src, payload or {})
    if not pok then
        DevPrint('lxr-mailbox net action error:', action, result)
        TriggerClientEvent('lxr-mailbox:res', src, reqId, { ok = false, reason = 'exception', detail = tostring(result) })
        return
    end

    TriggerClientEvent('lxr-mailbox:res', src, reqId, result or { ok = true })
end)

function GetPlayers()
    local players = {}
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = tonumber(GetPlayerFromIndex(i))
        if player then
            table.insert(players, player)
        end
    end
    return players
end
