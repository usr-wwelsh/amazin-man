local input = require("src.input")

local pad = {}

local active
local stick = input.newStick()

local function find()
    for _, js in ipairs(love.joystick.getJoysticks()) do
        if js:isGamepad() then return js end
    end
end

function pad.refresh()
    if active and not active:isConnected() then active = nil end
    active = active or find()
end

function pad.connected()
    return active ~= nil
end

function pad.label(name)
    return input.label(name, active ~= nil)
end

function pad.axes()
    if not active then return 0, 0 end
    return active:getGamepadAxis("leftx"), active:getGamepadAxis("lefty")
end

function pad.drive()
    local keys = {}
    for _, k in ipairs({ "up", "down", "left", "right", "w", "a", "s", "d" }) do
        keys[k] = love.keyboard.isDown(k)
    end
    local x, y = pad.axes()
    return input.drive(keys, x, y)
end

function pad.stickKeys()
    return input.stickKeys(stick, pad.axes())
end

return pad
