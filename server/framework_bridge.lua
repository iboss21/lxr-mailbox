--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗      ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║      ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║      ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║      ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗ ██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — server/framework_bridge.lua
    Server-side multi-framework bridge: LXR-Core | RSG-Core | VORP

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    Store:       https://theluxempire.tebex.io
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER FRAMEWORK BRIDGE ███████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

LXRMailbox          = LXRMailbox or {}
LXRMailbox.Framework = {}
local Framework      = LXRMailbox.Framework

local fw = Config.Framework or 'vorp'

-- ─── LXR-Core (Primary) ────────────────────────────────────────────────────────
if fw == 'lxr-core' then

    local Core = exports['lxr-core']:GetCore()

    function Framework.GetUser(src)
        return Core.Functions.GetPlayer(src)
    end

    function Framework.GetCharacter(player)
        return player and player.PlayerData or nil
    end

    function Framework.GetCharIdentifier(char)
        return char and char.citizenid or nil
    end

    function Framework.GetFirstName(char)
        return char and char.charinfo and char.charinfo.firstname or ''
    end

    function Framework.GetLastName(char)
        return char and char.charinfo and char.charinfo.lastname or ''
    end

    function Framework.GetMoney(player)
        return player and player.PlayerData.money and tonumber(player.PlayerData.money.cash) or 0
    end

    function Framework.RemoveMoney(player, amount)
        player.Functions.RemoveMoney('cash', tonumber(amount) or 0)
    end

    function Framework.AddMoney(player, amount)
        local a = tonumber(amount) or 0
        if a <= 0 or not player then return end
        player.Functions.AddMoney('cash', a)
    end

    function Framework.RegisterItemUse(itemName, callback)
        Core.Functions.CreateUseableItem(itemName, callback)
    end

    function Framework.CanCarryItem(src, itemName, amount, callback)
        local canCarry = true
        if GetResourceState('ox_inventory') == 'started' then
            local weight    = exports.ox_inventory:GetWeight(src) or 0
            local maxWeight = exports.ox_inventory:GetMaxWeight(src) or 30000
            canCarry = (maxWeight - weight) > 0
        end
        callback(canCarry)
    end

    function Framework.AddItem(src, itemName, amount, metadata)
        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:AddItem(src, itemName, tonumber(amount) or 1, metadata)
        end
    end

    function Framework.GetItem(src, itemName)
        if GetResourceState('ox_inventory') == 'started' then
            local slots = exports.ox_inventory:Search(src, 'slots', itemName)
            return slots and slots[1] or nil
        end
        return nil
    end

    function Framework.RemoveItemBySlot(src, slot, itemName, amount)
        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:RemoveItem(src, itemName, tonumber(amount) or 1, nil, slot)
        end
    end

    function Framework.RemoveItem(src, itemName, amount)
        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:RemoveItem(src, itemName, tonumber(amount) or 1)
        end
    end

    function Framework.SetItemMetadata(src, slot, meta, count)
        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:SetMetadata(src, slot, meta)
        end
    end

    function Framework.CloseInventory(src)
        -- ox_inventory handles UI closure client-side automatically
    end

-- ─── RSG-Core (Primary) ────────────────────────────────────────────────────────
elseif fw == 'rsg-core' then

    local Core = exports['rsg-core']:GetCoreObject()

    function Framework.GetUser(src)
        return Core.Functions.GetPlayer(src)
    end

    function Framework.GetCharacter(player)
        return player and player.PlayerData or nil
    end

    function Framework.GetCharIdentifier(char)
        return char and char.citizenid or nil
    end

    function Framework.GetFirstName(char)
        return char and char.charinfo and char.charinfo.firstname or ''
    end

    function Framework.GetLastName(char)
        return char and char.charinfo and char.charinfo.lastname or ''
    end

    function Framework.GetMoney(player)
        return player and player.PlayerData.money and tonumber(player.PlayerData.money.cash) or 0
    end

    function Framework.RemoveMoney(player, amount)
        player.Functions.RemoveMoney('cash', tonumber(amount) or 0)
    end

    function Framework.RegisterItemUse(itemName, callback)
        Core.Functions.CreateUseableItem(itemName, callback)
    end

    function Framework.CanCarryItem(src, itemName, amount, callback)
        local player = Core.Functions.GetPlayer(src)
        if player then
            callback(player.Functions.CanCarryItem(itemName, tonumber(amount) or 1))
        else
            callback(false)
        end
    end

    function Framework.AddItem(src, itemName, amount, metadata)
        local player = Core.Functions.GetPlayer(src)
        if player then
            player.Functions.AddItem(itemName, tonumber(amount) or 1, false, metadata)
        end
    end

    function Framework.GetItem(src, itemName)
        local player = Core.Functions.GetPlayer(src)
        if player then
            return player.Functions.GetItemByName(itemName)
        end
        return nil
    end

    function Framework.RemoveItemBySlot(src, slot, itemName, amount)
        local player = Core.Functions.GetPlayer(src)
        if player then
            player.Functions.RemoveItem(itemName, tonumber(amount) or 1, slot)
        end
    end

    function Framework.RemoveItem(src, itemName, amount)
        local player = Core.Functions.GetPlayer(src)
        if player then
            player.Functions.RemoveItem(itemName, tonumber(amount) or 1)
        end
    end

    function Framework.SetItemMetadata(src, slot, meta, count)
        local player = Core.Functions.GetPlayer(src)
        if player then
            player.Functions.SetItemMetaData(slot, meta)
        end
    end

    function Framework.CloseInventory(src)
        -- RSG inventory closure is managed by the client UI
    end

-- ─── VORP (Legacy / Default) ───────────────────────────────────────────────────
else -- fw == 'vorp'

    local VORPcore = exports.vorp_core:GetCore()

    function Framework.GetUser(src)
        return VORPcore.getUser(src)
    end

    function Framework.GetCharacter(player)
        return player and player.getUsedCharacter or nil
    end

    function Framework.GetCharIdentifier(char)
        return char and char.charIdentifier or nil
    end

    function Framework.GetFirstName(char)
        return char and char.firstname or ''
    end

    function Framework.GetLastName(char)
        return char and char.lastname or ''
    end

    function Framework.GetMoney(player)
        local char = player and player.getUsedCharacter
        return tonumber(char and char.money or 0) or 0
    end

    function Framework.RemoveMoney(player, amount)
        local char = player and player.getUsedCharacter
        if char then
            char.removeCurrency(0, tonumber(amount) or 0)
        end
    end

    function Framework.RegisterItemUse(itemName, callback)
        exports.vorp_inventory:registerUsableItem(itemName, callback, GetCurrentResourceName())
    end

    function Framework.CanCarryItem(src, itemName, amount, callback)
        exports.vorp_inventory:canCarryItem(src, itemName, amount, callback)
    end

    function Framework.AddItem(src, itemName, amount, metadata)
        if metadata then
            exports.vorp_inventory:addItem(src, itemName, tonumber(amount) or 1, metadata)
        else
            exports.vorp_inventory:addItem(src, itemName, tonumber(amount) or 1)
        end
    end

    function Framework.GetItem(src, itemName)
        return exports.vorp_inventory:getItem(src, itemName)
    end

    function Framework.RemoveItemBySlot(src, itemId, itemName, amount)
        if itemId and exports.vorp_inventory.subItemID then
            exports.vorp_inventory:subItemID(src, itemId)
        else
            exports.vorp_inventory:subItem(src, itemName, tonumber(amount) or 1)
        end
    end

    function Framework.RemoveItem(src, itemName, amount)
        exports.vorp_inventory:subItem(src, itemName, tonumber(amount) or 1)
    end

    function Framework.SetItemMetadata(src, itemId, meta, count)
        exports.vorp_inventory:setItemMetadata(src, itemId, meta, tonumber(count) or 1)
    end

    function Framework.CloseInventory(src)
        exports.vorp_inventory:closeInventory(src)
    end

end

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ END OF FRAMEWORK BRIDGE ██████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
