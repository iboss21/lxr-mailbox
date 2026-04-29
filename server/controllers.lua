--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System - Server Controllers (Database Layer)

    Raw database query wrappers: mailbox CRUD, mail CRUD, contacts, read-state updates.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

function UpdateMailboxNames(charIdentifier, firstName, lastName)
    local affected = MySQL.update.await(
        'UPDATE bcc_mailboxes SET first_name = ?, last_name = ? WHERE char_identifier = ?',
        { firstName, lastName, charIdentifier }
    )
    return affected or 0
end

function GetMailboxByCharIdentifier(charIdentifier)
    local row = MySQL.single.await(
        'SELECT mailbox_id, postal_code, char_identifier FROM bcc_mailboxes WHERE char_identifier = ? LIMIT 1',
        { charIdentifier }
    )
    return row or nil
end

function GetMailsForRecipient(recipientMailboxId, recipientPostal, charIdentifier)
    local results = MySQL.query.await([[
        SELECT *
        FROM bcc_mailbox_messages
        WHERE to_char = ? OR to_char = ? OR to_char = ?
        ORDER BY id DESC
    ]], {
        tostring(recipientMailboxId),
        tostring(recipientPostal),
        tostring(charIdentifier)
    }) or {}

    for _, mail in ipairs(results) do
        if type(mail.timestamp) == "number" then
            mail.timestamp = os.date('%Y-%m-%d %H:%M:%S', mail.timestamp)
        end
    end

    return results
end

function GetSentMailsForSender(senderMailboxId, senderPostalCode)
    local mid = tonumber(senderMailboxId)
    if not mid then return {} end
    local results = MySQL.query.await([[
        SELECT *
        FROM bcc_mailbox_messages
        WHERE sender_mailbox_id = ? OR (sender_mailbox_id IS NULL AND (from_char = ? OR from_char = ?))
        ORDER BY id DESC
    ]], {
        mid,
        tostring(senderPostalCode or ''),
        tostring(mid),
    }) or {}

    for _, mail in ipairs(results) do
        if type(mail.timestamp) == "number" then
            mail.timestamp = os.date('%Y-%m-%d %H:%M:%S', mail.timestamp)
        end
    end

    return results
end
function CountUnreadForRecipient(mailboxIdStr, postalCodeStr, charIdStr)
    local unread = MySQL.scalar.await(
        'SELECT COUNT(*) FROM bcc_mailbox_messages WHERE is_read = 0 AND (to_char = ? OR to_char = ? OR to_char = ?)',
        { tostring(mailboxIdStr), tostring(postalCodeStr or ''), tostring(charIdStr) }
    )
    return tonumber(unread) or 0
end
function GetMailById(id)
    local row = MySQL.single.await(
        'SELECT id, to_char, is_read FROM bcc_mailbox_messages WHERE id = ? LIMIT 1',
        { id }
    )
    return row or nil
end

local function normalizeAffectedRows(updated)
    if type(updated) == 'table' then
        return tonumber(updated.affectedRows or updated.affected_rows or updated[1] or 0) or 0
    end
    return tonumber(updated) or 0
end

function UpdateMailReadState(desiredState, id, mailboxIdStr, postalCodeStr, charIdStr)
    local updated = MySQL.update.await([[
        UPDATE bcc_mailbox_messages
        SET is_read = ?
        WHERE id = ? AND (to_char = ? OR to_char = ? OR to_char = ?)
    ]], {
        desiredState,
        id,
        tostring(mailboxIdStr),
        tostring(postalCodeStr or ''),
        tostring(charIdStr or '')
    })
    return normalizeAffectedRows(updated)
end

function CreateMailbox(charIdentifier, firstName, lastName, postalCode)
    local insertId = MySQL.insert.await(
        'INSERT INTO bcc_mailboxes (char_identifier, first_name, last_name, postal_code) VALUES (?, ?, ?, ?)',
        { charIdentifier, firstName, lastName, postalCode }
    )
    return insertId
end

function GetMailboxById(mailboxId)
    local row = MySQL.single.await(
        'SELECT mailbox_id FROM bcc_mailboxes WHERE mailbox_id = ? LIMIT 1',
        { mailboxId }
    )
    return row or nil
end

function DeleteMailById(mailId)
    local affected = MySQL.update.await('DELETE FROM bcc_mailbox_messages WHERE id = ?', { mailId })
    return normalizeAffectedRows(affected)
end

-- Deletes only if this mail belongs to the recipient (mailbox id, postal code, or char id as stored in to_char).
function DeleteMailForRecipient(mailId, mailboxIdStr, postalCodeStr, charIdStr)
    local affected = MySQL.update.await([[
        DELETE FROM bcc_mailbox_messages
        WHERE id = ? AND (to_char = ? OR to_char = ? OR to_char = ?)
    ]], {
        mailId,
        tostring(mailboxIdStr),
        tostring(postalCodeStr or ''),
        tostring(charIdStr or ''),
    })
    return normalizeAffectedRows(affected)
end

--- Removes a message the player sent (same row as inbox — deletes for recipient too).
function DeleteMailForSender(mailId, senderMailboxId, senderPostalCode)
    local mid = tonumber(senderMailboxId)
    if not mid then return 0 end
    local postal = tostring(senderPostalCode or '')
    local affected = MySQL.update.await([[
        DELETE FROM bcc_mailbox_messages
        WHERE id = ?
          AND (
            sender_mailbox_id = ?
            OR (sender_mailbox_id IS NULL AND (from_char = ? OR from_char = ?))
          )
    ]], { mailId, mid, postal, tostring(mid) })
    return normalizeAffectedRows(affected)
end

function FetchContactsRows(ownerMailboxId)
    if not ownerMailboxId then return {} end
    local rows = MySQL.query.await([[
        SELECT
            c.id,
            c.contact_alias,
            m.mailbox_id,
            m.postal_code,
            m.first_name,
            m.last_name
        FROM bcc_mailbox_contacts c
        INNER JOIN bcc_mailboxes m ON c.contact_mailbox_id = m.mailbox_id
        WHERE c.owner_mailbox_id = ?
        ORDER BY COALESCE(c.contact_alias, m.first_name, '')
    ]], { ownerMailboxId })
    return rows or {}
end

function FindContactByOwnerAndTarget(ownerMailboxId, targetMailboxId)
    local rows = MySQL.query.await(
        'SELECT id FROM bcc_mailbox_contacts WHERE owner_mailbox_id = ? AND contact_mailbox_id = ? LIMIT 1',
        { ownerMailboxId, targetMailboxId }
    )
    return (rows and rows[1]) or nil
end

function InsertContact(ownerMailboxId, targetMailboxId, contactAlias)
    return MySQL.insert.await(
        'INSERT INTO bcc_mailbox_contacts (owner_mailbox_id, contact_mailbox_id, contact_alias) VALUES (?, ?, ?)',
        { ownerMailboxId, targetMailboxId, contactAlias }
    )
end

function DeleteContact(ownerMailboxId, contactId)
    local affected = MySQL.update.await(
        'DELETE FROM bcc_mailbox_contacts WHERE id = ? AND owner_mailbox_id = ?',
        { contactId, ownerMailboxId }
    )
    return normalizeAffectedRows(affected)
end

function GetDraftsForOwner(ownerMailboxId)
    if not ownerMailboxId then return {} end
    return MySQL.query.await([[
        SELECT id, recipient_postal, subject, message, mail_category, letterhead_key, updated_at
        FROM bcc_mailbox_drafts
        WHERE owner_mailbox_id = ?
        ORDER BY updated_at DESC
    ]], { ownerMailboxId }) or {}
end

function InsertDraft(ownerMailboxId, recipientPostal, subject, message, mailCategory, letterheadKey)
    return MySQL.insert.await(
        [[INSERT INTO bcc_mailbox_drafts (owner_mailbox_id, recipient_postal, subject, message, mail_category, letterhead_key)
          VALUES (?, ?, ?, ?, ?, ?)]],
        { ownerMailboxId, recipientPostal, subject, message, mailCategory, letterheadKey }
    )
end

function UpdateDraftForOwner(draftId, ownerMailboxId, recipientPostal, subject, message, mailCategory, letterheadKey)
    local updated = MySQL.update.await([[
        UPDATE bcc_mailbox_drafts
        SET recipient_postal = ?, subject = ?, message = ?, mail_category = ?, letterhead_key = ?
        WHERE id = ? AND owner_mailbox_id = ?
    ]], {
        recipientPostal,
        subject,
        message,
        mailCategory,
        letterheadKey,
        draftId,
        ownerMailboxId,
    })
    return normalizeAffectedRows(updated)
end

function DeleteDraftForOwner(draftId, ownerMailboxId)
    local affected = MySQL.update.await(
        'DELETE FROM bcc_mailbox_drafts WHERE id = ? AND owner_mailbox_id = ?',
        { draftId, ownerMailboxId }
    )
    return normalizeAffectedRows(affected)
end