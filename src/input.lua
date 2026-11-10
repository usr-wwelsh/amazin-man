local input = {}

local DEADZONE = 0.25
local PUSH = 0.5

local LABELS = {
    throw = { "SPACE", "A" },
    move = { "WASD", "LEFT STICK" },
}

local BUTTONS = {
    a = "space",
    dpadup = "up",
    dpaddown = "down",
    dpadleft = "left",
    dpadright = "right",
}

local function dead(v)
    if math.abs(v) < DEADZONE then return 0 end
    return v
end

local function clamp(v)
    return math.max(-1, math.min(1, v))
end

function input.drive(keys, x, y)
    local up = keys.up or keys.w
    local down = keys.down or keys.s
    local left = keys.left or keys.a
    local right = keys.right or keys.d
    local throttle = (up and 1 or 0) - (down and 1 or 0) - dead(y)
    local steer = (right and 1 or 0) - (left and 1 or 0) + dead(x)
    if throttle > 0 then throttle = 1 elseif throttle < 0 then throttle = -1 end
    return throttle, clamp(steer)
end

function input.newStick()
    return { w = false, a = false, s = false, d = false }
end

function input.stickKeys(state, x, y)
    local now = { w = y <= -PUSH, s = y >= PUSH, a = x <= -PUSH, d = x >= PUSH }
    local pressed = {}
    for _, key in ipairs({ "w", "a", "s", "d" }) do
        if now[key] and not state[key] then pressed[#pressed + 1] = key end
        state[key] = now[key]
    end
    return pressed
end

function input.button(name)
    return BUTTONS[name]
end

function input.label(name, connected)
    return LABELS[name][connected and 2 or 1]
end

return input
