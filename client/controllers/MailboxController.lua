--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — Client Mailbox Controller

    Proximity detection for postal locations: tiered Wait(), squared distance checks,
    throttled help text, unread reminders, optional pigeon spawn.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

Mailbox = Mailbox or {}
local devPrint = Mailbox.devPrint or function() end

local INPUT_MAILBOX = 0x4CC0E2FE

local INTERACT_R2 = 4.0
local IDLE_WAIT_MS = 850
local NEAR_POLL_MS = 45
local HELP_REFRESH_MS = 220

local mailboxCoords = {}
do
    for _, location in pairs(Config.MailboxLocations or {}) do
        local c = location.coords
        if c then
            mailboxCoords[#mailboxCoords + 1] = c
        end
    end
end

local function OpenMailboxNuiProxy(hasMailbox)
    if Mailbox.OpenNui then
        Mailbox.OpenNui({
            hasMailbox = hasMailbox ~= false,
            nearMailbox = Mailbox.State.nearMailbox,
            postalCode = Mailbox.State.playerPostalCode,
            mailboxId = Mailbox.State.playermailboxId,
        })
    end
end

local function applyMailboxStatus(data, opts)
    if not data then return end
    if data.hasMailbox == false then
        Mailbox.State.playermailboxId = nil
        Mailbox.State.playerPostalCode = nil
    else
        Mailbox.State.playermailboxId = data.mailboxId or Mailbox.State.playermailboxId
        Mailbox.State.playerPostalCode = data.postalCode or Mailbox.State.playerPostalCode
    end
    if opts and opts.openMenu then
        OpenMailboxNuiProxy(data.hasMailbox ~= false)
    end
end

Mailbox.ApplyMailboxStatus = applyMailboxStatus

local function applyMailList(mails, opts)
    Mailbox.State.lastMails = mails or {}
    local skipNotify = (opts and opts.skipNotify) or Mailbox.State.suppressMailNotify
    Mailbox.State.suppressMailNotify = false

    if not skipNotify then
        local hasUnread = false
        for _, mail in ipairs(Mailbox.State.lastMails) do
            if tonumber(mail.is_read or 0) ~= 1 then
                hasUnread = true
                break
            end
        end
        if hasUnread then
            Notify(_U('NewMailNotification'), 'info', 5000)
        end
    end
end

Mailbox.ApplyMailList = applyMailList

CreateThread(function()
    local lastHelpAt = 0
    while true do
        local playerPed = PlayerPedId()

        if IsEntityDead(playerPed) then
            Mailbox.State.nearMailbox = false
            Wait(900)
        elseif #mailboxCoords == 0 then
            Mailbox.State.nearMailbox = false
            Wait(IDLE_WAIT_MS)
        else
            local coords = GetEntityCoords(playerPed)
            local px, py, pz = coords.x, coords.y, coords.z
            local nearMailbox = false

            for i = 1, #mailboxCoords do
                local c = mailboxCoords[i]
                local dx = px - c.x
                local dy = py - c.y
                local dz = pz - c.z
                if (dx * dx + dy * dy + dz * dz) < INTERACT_R2 then
                    nearMailbox = true
                    break
                end
            end

            Mailbox.State.nearMailbox = nearMailbox

            if nearMailbox then
                local now = GetGameTimer()
                if now - lastHelpAt >= HELP_REFRESH_MS then
                    lastHelpAt = now
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(_U('NearMailbox'))
                    EndTextCommandDisplayHelp(0, false, false, -1)
                end

                if IsControlJustPressed(0, INPUT_MAILBOX) then
                    devPrint(_U('MailboxPromptCompleted'))

                    local data = Mailbox.ServerCall('CheckMailbox', {})
                    if data and data.ok ~= false then
                        applyMailboxStatus({
                            hasMailbox = data.hasMailbox,
                            mailboxId = data.mailboxId,
                            postalCode = data.postalCode,
                            fullName = data.fullName,
                        }, { openMenu = true })
                    else
                        applyMailboxStatus({
                            mailboxId = Mailbox.State.playermailboxId,
                            postalCode = Mailbox.State.playerPostalCode,
                            hasMailbox = false,
                        }, { openMenu = true })
                    end
                    Wait(250)
                else
                    Wait(NEAR_POLL_MS)
                end
            else
                Wait(IDLE_WAIT_MS)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(60000)
        local data = Mailbox.ServerCall('UpdateMailboxInfo', {})
        if data and data.ok ~= false then
            applyMailboxStatus({
                mailboxId = data.mailboxId or Mailbox.State.playermailboxId,
                postalCode = data.postalCode or Mailbox.State.playerPostalCode,
            }, { openMenu = false })
        end
    end
end)

CreateThread(function()
    local intervalMinutes = tonumber(Config.UnreadReminderIntervalMinutes or 15) or 15
    local intervalMs = math.max(60000, math.floor(intervalMinutes * 60000))
    Wait(30000)
    while true do
        local poll = Mailbox.ServerCall('PollUnread', {})
        local unread = poll and tonumber(poll.unread or 0) or 0
        if poll and poll.ok ~= false and unread > 0 then
            Notify(_U('NewMailNotification'), 'info', 5000)
            local result = Mailbox.ServerCall('FetchMail', {})
            if result and result.mails then
                Mailbox.ApplyMailList(result.mails, { skipNotify = true, openPage = false })
            end
        end
        Wait(intervalMs)
    end
end)

function SpawnPigeon()
    devPrint('spawnPigeon')
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local spawnCoords = vector3(playerCoords.x + 0.0, playerCoords.y + 0.0, playerCoords.z + 0.0)

    local model = GetHashKey('A_C_Pigeon')
    RequestModel(model, false)
    local deadline = GetGameTimer() + 8000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do
        Wait(25)
    end
    if not HasModelLoaded(model) then return end

    local pigeon = CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false, true, true)

    TaskFlyAway(pigeon, playerPed)
    SetModelAsNoLongerNeeded(model)
end
