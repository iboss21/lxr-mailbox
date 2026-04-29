--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System — Server rate limiting

    Global minimum interval plus optional per-action sliding windows for `lxr-mailbox:req`.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

LXRMailbox = LXRMailbox or {}
LXRMailbox.NetRate = LXRMailbox.NetRate or {}

local perActionState = {}
local globalLastTick = {}

local function bucketFor(src, action)
    local sid = tostring(src)
    if not perActionState[sid] then
        perActionState[sid] = {}
    end
    if not perActionState[sid][action] then
        perActionState[sid][action] = { windowStart = 0, count = 0 }
    end
    return perActionState[sid][action]
end

function LXRMailbox.NetRate.ClearPlayer(src)
    perActionState[tostring(src)] = nil
    globalLastTick[src] = nil
end

--- Returns ok, reason ('global_throttle' | 'action_limit')
function LXRMailbox.NetRate.AllowRequest(src, action)
    local rl = Config.NetRateLimit
    if not rl or not rl.Enabled then
        return true
    end

    local now = GetGameTimer()
    local interval = tonumber(rl.MinIntervalMs) or 0
    if interval > 0 then
        local last = globalLastTick[src]
        if last and (now - last) < interval then
            return false, 'global_throttle'
        end
    end

    local pa = rl.PerAction and rl.PerAction[action]
    if pa then
        local limit = tonumber(pa.limit) or 0
        local windowMs = tonumber(pa.windowMs) or 10000
        if limit > 0 and windowMs > 0 then
            local b = bucketFor(src, action)
            if not b.windowStart or (now - b.windowStart) >= windowMs then
                b.windowStart = now
                b.count = 0
            end
            if b.count >= limit then
                return false, 'action_limit'
            end
            b.count = b.count + 1
        end
    end

    if interval > 0 then
        globalLastTick[src] = now
    end
    return true
end
