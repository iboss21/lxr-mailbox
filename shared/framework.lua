--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System - Framework Adapter Layer

    This file provides a unified interface for interacting with multiple frameworks.
    It automatically detects the active framework and maps function calls to the
    correct framework-specific implementations.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Tagline:     Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!
    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    GitHub:      https://github.com/iBoss21

    ═══════════════════════════════════════════════════════════════════════════════

    Version: 1.2.0

    Framework Support:
    - LXR Core (Primary)   — Fully supported
    - RSG Core (Primary)   — Fully supported
    - VORP Core (Legacy)   — Fully supported

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Framework Adapter Author: iBoss21 / The Lux Empire for The Land of Wolves

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK DETECTION ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Framework       = {}
Framework.Type   = nil
Framework.Object = nil

local function DetectFramework()
    if Config.Framework and Config.Framework ~= 'auto' then
        Framework.Type = Config.Framework
        if Config.Debug then
            print('^3[LXR Mailbox]^7 Framework manually set to: ^2' .. Framework.Type .. '^7')
        end
        return Framework.Type
    end

    -- Auto-detection: priority order LXR → RSG → VORP
    local order = { 'lxr-core', 'rsg-core', 'vorp_core' }
    for _, fw in ipairs(order) do
        if GetResourceState(fw) == 'started' or GetResourceState(fw) == 'starting' then
            Framework.Type = fw
            if Config.Debug then
                print('^3[LXR Mailbox]^7 Auto-detected framework: ^2' .. fw .. '^7')
            end
            return Framework.Type
        end
    end

    -- Fallback
    Framework.Type = 'vorp_core'
    if Config.Debug then
        print('^3[LXR Mailbox]^7 No framework detected, defaulting to ^2vorp_core^7')
    end
    return Framework.Type
end

local function InitializeFramework()
    local fwType = DetectFramework()

    if fwType == 'lxr-core' then
        Framework.Object = exports['lxr-core']:GetCoreObject()
    elseif fwType == 'rsg-core' then
        Framework.Object = exports['rsg-core']:GetCoreObject()
    elseif fwType == 'vorp_core' then
        Framework.Object = exports.vorp_core:GetCore()
    end

    if Config.Debug then
        print('^3[LXR Mailbox]^7 Framework initialized: ^2' .. (fwType or 'none') .. '^7')
    end
end

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK AUTO-DETECTION ██████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config = Config or {}

if not Config.Framework or Config.Framework == 'auto' then
    if GetResourceState('lxr-core') == 'started' then
        Config.Framework = 'lxr-core'
    elseif GetResourceState('rsg-core') == 'started' then
        Config.Framework = 'rsg-core'
    elseif GetResourceState('vorp_core') == 'started' then
        Config.Framework = 'vorp'
    else
        -- Fallback: keep 'vorp' as the default for backward compatibility
        Config.Framework = 'vorp'
    end
end

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SHARED (CLIENT + SERVER) ██████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

if IsDuplicityVersion() then

    -- ── SERVER SIDE ──────────────────────────────────────────────────────────────

    CreateThread(function()
        Wait(100)
        InitializeFramework()
    end)

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.GetUser(source)
    -- Returns the raw framework user/player object.
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.GetUser(source)
        if not Framework.Object then return nil end
        if Framework.Type == 'lxr-core' or Framework.Type == 'rsg-core' then
            return Framework.Object.Functions.GetPlayer(source)
        elseif Framework.Type == 'vorp_core' then
            return Framework.Object.getUser(source)
        end
        return nil
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.GetCharacterData(source)
    -- Returns a normalized character data table:
    --   { charIdentifier, firstname, lastname, money, _raw (framework char obj) }
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.GetCharacterData(source)
        local user = Framework.GetUser(source)
        if not user then return nil end

        if Framework.Type == 'lxr-core' or Framework.Type == 'rsg-core' then
            local pd = user.PlayerData
            if not pd then return nil end
            return {
                charIdentifier = pd.citizenid or pd.charIdentifier or tostring(source),
                firstname      = pd.charinfo and pd.charinfo.firstname or '',
                lastname       = pd.charinfo and pd.charinfo.lastname  or '',
                money          = pd.money and (pd.money.cash or 0) or 0,
                _raw           = user,
            }
        elseif Framework.Type == 'vorp_core' then
            local char = user.getUsedCharacter
            if not char then return nil end
            return {
                charIdentifier = char.charIdentifier,
                firstname      = char.firstname,
                lastname       = char.lastname,
                money          = tonumber(char.money or 0) or 0,
                _raw           = char,
            }
        end
        return nil
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.RemoveCurrency(source, amount)
    -- Deducts cash/currency from the player's character.
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.RemoveCurrency(source, amount)
        if not amount or amount <= 0 then return end
        local user = Framework.GetUser(source)
        if not user then return end

        if Framework.Type == 'lxr-core' or Framework.Type == 'rsg-core' then
            user.Functions.RemoveMoney('cash', amount)
        elseif Framework.Type == 'vorp_core' then
            local char = user.getUsedCharacter
            if char then char.removeCurrency(0, amount) end
        end
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.RegisterUsableItem(itemName, callback)
    -- Registers an item as usable so players can activate it from their inventory.
    -- callback(source) is called when the item is used.
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.RegisterUsableItem(itemName, callback)
        if Framework.Type == 'lxr-core' or Framework.Type == 'rsg-core' then
            Framework.Object.Functions.CreateUseableItem(itemName, function(source)
                callback({ source = source })
            end)
        elseif Framework.Type == 'vorp_core' then
            exports.vorp_inventory:registerUsableItem(itemName, callback, GetCurrentResourceName())
        end
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.CloseInventory(source)
    -- Closes the inventory UI for the given player (VORP-specific; no-op for others).
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.CloseInventory(source)
        if Framework.Type == 'vorp_core' then
            exports.vorp_inventory:closeInventory(source)
        end
        -- LXR/RSG do not require an explicit close call
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.GetItem(source, itemName)
    -- Returns item data table (id, metadata, etc.) for the named item.
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.GetItem(source, itemName)
        if Framework.Type == 'lxr-core' or Framework.Type == 'rsg-core' then
            local Player = Framework.GetUser(source)
            if not Player then return nil end
            return Player.Functions.GetItemByName(itemName)
        elseif Framework.Type == 'vorp_core' then
            return exports.vorp_inventory:getItem(source, itemName)
        end
        return nil
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.SubItem(source, itemId, itemName, count)
    -- Removes an item from the player's inventory.
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.SubItem(source, itemId, itemName, count)
        count = count or 1
        if Framework.Type == 'lxr-core' or Framework.Type == 'rsg-core' then
            local Player = Framework.GetUser(source)
            if not Player then return end
            Player.Functions.RemoveItem(itemName, count)
        elseif Framework.Type == 'vorp_core' then
            if itemId and exports.vorp_inventory.subItemID then
                exports.vorp_inventory:subItemID(source, itemId)
            else
                exports.vorp_inventory:subItem(source, itemName, count)
            end
        end
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.SetItemMetadata(source, itemId, metadata, count)
    -- Updates metadata on an inventory item (VORP-specific; LXR/RSG use AddItem with meta).
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.SetItemMetadata(source, itemId, metadata, count)
        if Framework.Type == 'vorp_core' then
            exports.vorp_inventory:setItemMetadata(source, itemId, metadata, count or 1)
        end
        -- LXR/RSG handle metadata differently (via AddItem options); no direct setMetadata call
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.CanCarryItem(source, itemName, count, callback)
    -- Calls callback(bool) with whether the player can carry the item.
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.CanCarryItem(source, itemName, count, callback)
        if Framework.Type == 'lxr-core' or Framework.Type == 'rsg-core' then
            -- LXR/RSG typically don't block carries; assume true
            callback(true)
        elseif Framework.Type == 'vorp_core' then
            exports.vorp_inventory:canCarryItem(source, itemName, count, callback)
        else
            callback(true)
        end
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Framework.AddItem(source, itemName, count, metadata)
    -- Adds an item to the player's inventory.
    -- ────────────────────────────────────────────────────────────────────────────
    function Framework.AddItem(source, itemName, count, metadata)
        count = count or 1
        if Framework.Type == 'lxr-core' or Framework.Type == 'rsg-core' then
            local Player = Framework.GetUser(source)
            if not Player then return end
            Player.Functions.AddItem(itemName, count, false, metadata or {})
        elseif Framework.Type == 'vorp_core' then
            if metadata then
                exports.vorp_inventory:addItem(source, itemName, count, metadata)
            else
                exports.vorp_inventory:addItem(source, itemName, count)
            end
        end
    end

else

    -- ── CLIENT SIDE ──────────────────────────────────────────────────────────────

    CreateThread(function()
        Wait(100)
        DetectFramework()
        if Config.Debug then
            print('^3[LXR Mailbox]^7 Client framework type: ^2' .. (Framework.Type or 'none') .. '^7')
        end
    end)

end

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ END OF FRAMEWORK ADAPTER ██████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ GLOBAL NAMESPACE ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

LXRMailbox          = LXRMailbox or {}
LXRMailbox.Version  = '1.3.0'
LXRMailbox.Resource = 'lxr-mailbox'
