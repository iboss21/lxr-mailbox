--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — Client NUI Bridge

    mailboxApi callbacks, ServerCall RPC over lxr-mailbox:req / :res with bounded waits.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

Mailbox = Mailbox or {}

local pendingRes = {}

RegisterNetEvent('lxr-mailbox:res', function(reqId, body)
    local fn = pendingRes[reqId]
    if fn then
        pendingRes[reqId] = nil
        fn(body)
    end
end)

function Mailbox.ServerCall(action, payload)
    local reqId = ('%s-%s'):format(GetGameTimer(), math.random(100000, 999999))
    local result = nil
    local waiting = true
    pendingRes[reqId] = function(body)
        result = body
        waiting = false
    end
    TriggerServerEvent('lxr-mailbox:req', reqId, action, payload or {})
    local deadline = GetGameTimer() + 45000
    while waiting and GetGameTimer() < deadline do
        Wait(10)
    end
    pendingRes[reqId] = nil
    return result or { ok = false, reason = 'timeout' }
end

function Mailbox.PushLocales()
    SendNUIMessage({
        action = 'setLocales',
        localeStrings = Locales[Config.defaultlang] or {},
    })
end

local function BuildMailUiMeta()
    local cats = {}
    for _, c in ipairs(Config.MailCategories or {}) do
        cats[#cats + 1] = { id = c.id, label = c.label or c.id }
    end
    local heads = {}
    for k, v in pairs(Config.Letterheads or {}) do
        heads[#heads + 1] = { id = k, label = (v and v.label) or k }
    end
    table.sort(heads, function(a, b)
        return tostring(a.label) < tostring(b.label)
    end)
    return { categories = cats, letterheads = heads }
end

function Mailbox.OpenNui(opts)
    opts = opts or {}
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        hasMailbox = opts.hasMailbox ~= false,
        nearMailbox = opts.nearMailbox or false,
        postalCode = opts.postalCode,
        mailboxId = opts.mailboxId,
        localeStrings = Locales[Config.defaultlang] or {},
        mailMeta = BuildMailUiMeta(),
    })
end

function Mailbox.CloseNui()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('mailboxApi', function(data, cb)
    CreateThread(function()
        local action = data.action
        local payload = data.payload
        local result = Mailbox.ServerCall(action, payload)
        cb(result)
    end)
end)

RegisterNUICallback('closeUi', function(_, cb)
    Mailbox.CloseNui()
    cb('ok')
end)

RegisterNUICallback('spawnPigeon', function(_, cb)
    if Config.SendPigeon and SpawnPigeon then
        SpawnPigeon()
    end
    cb('ok')
end)

RegisterNetEvent('lxr-mailbox:notify', function(data)
    if not data then return end
    SendNUIMessage({
        action = 'toast',
        message = data.message,
        type = data.type or 'info',
    })
end)

RegisterNetEvent('lxr-mailbox:mailboxStatus', function(data)
    if Mailbox.ApplyMailboxStatus then
        Mailbox.ApplyMailboxStatus(data, { openMenu = true })
    end
end)

RegisterNetEvent('lxr-mailbox:checkMailNotification', function(data)
    local unreadCount = data and data.unreadCount
    local unreadTotal = tonumber(unreadCount or 0) or 0
    if unreadTotal > 0 then
        Notify(_U('NewMailNotification'), 'info', 5000)
    end
    local result = Mailbox.ServerCall('FetchMail', {})
    if result and result.mails and Mailbox.ApplyMailList then
        Mailbox.ApplyMailList(result.mails, { skipNotify = true, openPage = false })
    end
end)

CreateThread(function()
    Wait(800)
    Mailbox.PushLocales()
end)

RegisterNetEvent('lxr-mailbox:openRemote', function(data)
    data = data or {}
    if Mailbox.OpenNui then
        Mailbox.OpenNui({
            hasMailbox = data.hasMailbox ~= false,
            nearMailbox = false,
            postalCode = data.postalCode,
            mailboxId = data.mailboxId,
        })
    end
end)
