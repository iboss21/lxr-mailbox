--[[
    Server-only guard: this resource must run as folder name "lxr-mailbox".
    Loaded before other server scripts so startup aborts immediately if renamed.
]]

local REQUIRED = 'lxr-mailbox'
local current = GetCurrentResourceName()

if current ~= REQUIRED then
    error(
        ('[lxr-mailbox] Resource folder must be named "%s". Current name: "%s". Rename the folder and restart.'):format(
            REQUIRED,
            current
        ),
        0
    )
end
