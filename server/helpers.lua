--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System - Server Helpers

    Utility functions: DevPrint, NotifyClient, postal code generation and normalization,
    string trimming, and helper wrappers.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

if Config.devMode then
    function DevPrint(...)
        local parts = {}
        for i = 1, select('#', ...) do
            parts[i] = tostring(select(i, ...))
        end
        print("^1[DEV | lxr-mailbox] ^4" .. table.concat(parts, ' ') .. "^0")
    end
else
    function DevPrint(...) end -- no-op when devMode is off
end

function RefreshMailboxHud(charIdentifier)
    if not charIdentifier then return end
    if not Config.CoreHudIntegration or not Config.CoreHudIntegration.enabled then return end
    if GetResourceState('bcc-corehud') == 'started' then
        pcall(function()
            exports['bcc-corehud']:RefreshMailboxCore(charIdentifier)
        end)
    elseif GetResourceState('lxr-corehud') == 'started' then
        pcall(function()
            exports['lxr-corehud']:RefreshMailboxCore(charIdentifier)
        end)
    end
end

function NotifyClient(src, message, type, duration)
    TriggerClientEvent('lxr-mailbox:notify', src, {
        message = message,
        type = type or 'info',
        duration = duration or 4000,
    })
end

local function generatePostalCode()
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local function randomLetter()
        local idx = math.random(1, #letters)
        return letters:sub(idx, idx)
    end
    local function randomDigit()
        return tostring(math.random(0, 9))
    end
    return randomLetter() .. randomLetter() .. randomDigit() .. randomDigit() .. randomDigit()
end

function GenerateUniquePostalCode()
    while true do
        local candidate = generatePostalCode()
        local exists = MySQL.scalar.await('SELECT 1 FROM bcc_mailboxes WHERE postal_code = ? LIMIT 1', { candidate })
        if not exists then
            return candidate
        end
    end
end

function NormalizePostalCode(code)
    if not code then return nil end
    local raw = tostring(code)
    local parts = {}
    for i = 1, #raw do
        local ch = raw:sub(i, i)
        if ch ~= ' ' and ch ~= '\t' and ch ~= '\n' and ch ~= '\r' then
            parts[#parts + 1] = ch
        end
    end
    local collapsed = table.concat(parts)
    if collapsed == '' then return nil end
    return string.upper(collapsed)
end

function TrimWhitespace(value)
    local str = value or ''
    local first = 1
    local last = #str

    while first <= last do
        local c = str:sub(first, first)
        if c ~= ' ' and c ~= '\t' and c ~= '\n' and c ~= '\r' then
            break
        end
        first = first + 1
    end

    while last >= first do
        local c = str:sub(last, last)
        if c ~= ' ' and c ~= '\t' and c ~= '\n' and c ~= '\r' then
            break
        end
        last = last - 1
    end

    if first > last then
        return ''
    end

    return str:sub(first, last)
end

--- Whitelist mail category against `Config.MailCategories`; default `personal`.
function NormalizeMailCategory(raw)
    local c = raw and tostring(raw):lower() or 'personal'
    for _, def in ipairs(Config.MailCategories or {}) do
        if def.id == c then return c end
    end
    return 'personal'
end
