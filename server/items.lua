--[[
    LXR Mailbox - usable letter item registration
]]

LXRMailbox = LXRMailbox or {}

local Framework = LXRMailbox.Framework

do
    local seed = os.time()
    if type(GetGameTimer) == 'function' then
        seed = seed + GetGameTimer()
    end
    math.randomseed(seed)
end

CreateThread(function()
    Wait(200)
    Framework.RegisterItemUse(Config.MailboxItem, function(data)
        local src = data.source
        DevPrint('MailboxItem used. src=', src)

        local user = Framework.GetUser(src)
        if not user then
            DevPrint('Error: User not found for source: ' .. tostring(src))
            Framework.CloseInventory(src)
            return
        end

        local char = Framework.GetCharacter(user)
        if not char then
            DevPrint('Error: Character data not found for user: ' .. tostring(src))
            Framework.CloseInventory(src)
            return
        end

        local charId = Framework.GetCharIdentifier(char)
        local fullName = (Framework.GetFirstName(char) .. ' ' .. Framework.GetLastName(char)):gsub('^%s*(.-)%s*$', '%1')
        local mailbox = GetMailboxByCharIdentifier(charId)

        if not mailbox then
            NotifyClient(src, _U('RegisterAtMailboxLocation'), 'error', 5000)
            Framework.CloseInventory(src)
            return
        end

        TriggerClientEvent('lxr-mailbox:mailboxStatus', src, {
            hasMailbox = true,
            mailboxId = mailbox.mailbox_id,
            playerName = fullName,
            postalCode = mailbox.postal_code,
        })

        Framework.CloseInventory(src)

        local durCfg = Config.LetterDurability
        if not durCfg or not durCfg.Enabled then return end

        local itemName = Config.MailboxItem or 'letter'
        local item = Framework.GetItem(src, itemName)
        if not item or not item.id then return end

        local maxValue = tonumber(durCfg.Max or 100) or 100
        local damage = tonumber(durCfg.DamagePerUse or 1) or 1
        local current = (item.metadata and item.metadata.durability) or maxValue
        local newVal = math.max(0, math.floor(current - damage))

        if newVal <= 0 then
            Framework.RemoveItemBySlot(src, item.id, itemName, 1)
            NotifyClient(src, _U('LetterDestroyed'), 'error', 4000)
            return
        end

        local meta = item.metadata or {}
        meta.durability = newVal
        meta.id = item.id
        meta.description = _U('LetterDurabilityDescription', newVal)

        Framework.SetItemMetadata(src, item.id, meta, 1)

        if durCfg.NotifyOnChange then
            NotifyClient(src, _U('LetterDurabilityUpdate', newVal), 'info', 3000)
        end
    end)
end)
