--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — Optional `/mailbox` command

    Opens postal NUI without using the letter item when `Config.AllowMailboxCommand` is true.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

CreateThread(function()
    Wait(800)
    if not Config.AllowMailboxCommand then return end

    local Framework = LXRMailbox.Framework
    local cmd = tostring(Config.MailboxCommandName or 'mailbox'):gsub('^/+', ''):gsub('/+$', '')
    if cmd == '' then cmd = 'mailbox' end

    RegisterCommand(cmd, function(source, args, rawCommand)
        local user = Framework.GetUser(source)
        if not user then return end
        local char = Framework.GetCharacter(user)
        if not char then
            NotifyClient(source, _U('error_invalid_character_data'), 'error', 4000)
            return
        end
        local charId = Framework.GetCharIdentifier(char)
        local row = GetMailboxByCharIdentifier(charId)
        if not row then
            NotifyClient(source, _U('MailboxNotFound'), 'error', 5000)
            return
        end
        TriggerClientEvent('lxr-mailbox:openRemote', source, {
            hasMailbox = true,
            mailboxId = row.mailbox_id,
            postalCode = row.postal_code,
        })
    end, false)
end)
