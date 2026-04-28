--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — Client Bootstrap

    Notifications, map blips for mailbox locations, resource lifecycle hooks.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

local VORPcore = nil
if Config.Framework == 'vorp' then
    pcall(function()
        VORPcore = exports.vorp_core:GetCore()
    end)
end

Config.Notify = Config.Notify or 'nui'

function Notify(message, typeOrDuration, maybeDuration)
    if not message then return end

    local notifyType = 'info'
    local notifyDuration = 6000

    if type(typeOrDuration) == 'string' then
        notifyType = typeOrDuration
        notifyDuration = tonumber(maybeDuration) or notifyDuration
    elseif type(typeOrDuration) == 'number' then
        notifyDuration = typeOrDuration
    end

    if Config.Notify == 'nui' then
        SendNUIMessage({
            action = 'toast',
            message = message,
            type = notifyType,
        })
    elseif Config.Notify == 'vorp-core' and VORPcore and VORPcore.NotifyRightTip then
        VORPcore.NotifyRightTip(message, notifyDuration)
    else
        print(('^3[lxr-mailbox]^7 %s'):format(tostring(message)))
    end
end

local BlipsCreated = {}

local function tryAddMailboxBlip(coords, sprite)
    local ok, handle = pcall(function()
        return Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    end)
    if ok and handle and handle ~= 0 then
        pcall(function()
            SetBlipSprite(handle, sprite, true)
            SetBlipScale(handle, 0.22)
        end)
        return handle
    end
    return nil
end

CreateThread(function()
    Wait(600)
    for _, v in pairs(Config.MailboxLocations or {}) do
        local c = v.coords
        if c then
            local h = tryAddMailboxBlip(c, v.BlipSprite or 1861010125)
            if h then BlipsCreated[#BlipsCreated + 1] = h end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, h in ipairs(BlipsCreated) do
        pcall(function()
            RemoveBlip(h)
        end)
    end
end)
