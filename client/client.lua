--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System - Client Entry Point

    Initializes the FeatherMenu integration, notification system, blips, and
    RPC notification handlers.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

local VORPcore = nil
if Config.Framework == 'vorp' then
    pcall(function() VORPcore = exports.vorp_core:GetCore() end)
end
local FeatherMenu = exports['feather-menu'].initiate()
local BccUtils = exports['bcc-utils'].initiate()
local BlipsCreated = {}

Config = Config or {}
Config.Notify = Config.Notify or "feather-menu"

function Notify(message, typeOrDuration, maybeDuration)
    if not message then return end

    local notifyType = "info"
    local notifyDuration = 6000

    if type(typeOrDuration) == "string" then
        notifyType = typeOrDuration
        notifyDuration = tonumber(maybeDuration) or notifyDuration
    elseif type(typeOrDuration) == "number" then
        notifyDuration = typeOrDuration
    end

    if Config.Notify == "feather-menu" and FeatherMenu and FeatherMenu.Notify then
        FeatherMenu:Notify({
            message = message,
            type = notifyType,
            autoClose = notifyDuration,
            position = "top-center",
            transition = "slide",
            icon = true,
            hideProgressBar = false,
            rtl = false,
            style = {},
            toastStyle = {},
            progressStyle = {}
        })
    elseif Config.Notify == "vorp-core" and VORPcore and VORPcore.NotifyRightTip then
        VORPcore.NotifyRightTip(message, notifyDuration)
    else
        print("^1[lxr-mailbox] Notify called with invalid Config.Notify: " .. tostring(Config.Notify))
    end
end

BccUtils.RPC:Register("lxr-mailbox:NotifyClient", function(data)
    if not data then return end
    Notify(data.message, data.type, data.duration)
end)

function CreateBlips()
    for _, v in pairs(Config.MailboxLocations) do
        local blip = BccUtils.Blips:SetBlip('Mail Office', v.BlipSprite, 3.2,
            v.coords.x, v.coords.y, v.coords.z)
        BlipsCreated[#BlipsCreated + 1] = blip
    end
end

CreateBlips()

AddEventHandler('onResourceStop', function(resourceName)
    for _, blips in ipairs(BlipsCreated) do blips:Remove() end
    DevPrint('Removed blips')
end)
