--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — Mail audit log

    Best-effort inserts into `bcc_mailbox_audit`; failures never break mail flow.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

LXRMailbox = LXRMailbox or {}

function LXRMailbox.AppendMailAudit(action, opts)
    opts = opts or {}
    local cfg = Config.MailAuditLog
    if not cfg or not cfg.Enabled or not action then
        return
    end

    local detail = opts.detail
    if detail ~= nil then
        detail = tostring(detail)
        local maxLen = tonumber(cfg.MaxDetailLength) or 500
        if #detail > maxLen then
            detail = string.sub(detail, 1, maxLen)
        end
    end

    pcall(function()
        MySQL.insert.await(
            [[INSERT INTO bcc_mailbox_audit (action, source_player, char_identifier, mailbox_id, target_mailbox_id, detail)
              VALUES (?, ?, ?, ?, ?, ?)]],
            {
                tostring(action),
                opts.source_player,
                opts.char_identifier,
                opts.mailbox_id,
                opts.target_mailbox_id,
                detail,
            }
        )
    end)
end
