local input = dofile("src/input.lua")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

local none = {}

local t, s = input.drive(none, 0, 0)
eq(t, 0, "idle throttle")
eq(s, 0, "idle steer")

t, s = input.drive({ w = true, d = true }, 0, 0)
eq(t, 1, "w throttles")
eq(s, 1, "d steers right")

t, s = input.drive({ down = true, left = true }, 0, 0)
eq(t, -1, "down brakes")
eq(s, -1, "left steers left")

t, s = input.drive(none, 0.1, -0.1)
eq(t, 0, "stick inside deadzone ignored for throttle")
eq(s, 0, "stick inside deadzone ignored for steer")

t, s = input.drive(none, 1, -1)
eq(t, 1, "stick up throttles")
eq(s, 1, "full stick right steers fully")

t, s = input.drive(none, -1, 1)
eq(t, -1, "stick down brakes")
eq(s, -1, "full stick left steers fully")

t, s = input.drive(none, 0.6, 0)
assert(s > 0 and s < 1, "partial stick steers partially")

t, s = input.drive({ a = true }, 1, 0)
eq(s, 0, "opposing keyboard and stick cancel")

local state = input.newStick()
eq(#input.stickKeys(state, 0, 0), 0, "centered stick emits nothing")
local keys = input.stickKeys(state, 0, -1)
eq(keys[1], "w", "stick up emits w once")
eq(#input.stickKeys(state, 0, -1), 0, "held stick does not repeat")
eq(#input.stickKeys(state, 0, 0), 0, "release emits nothing")
eq(input.stickKeys(state, 0, -1)[1], "w", "re-push emits again")
input.stickKeys(state, 0, 0)
eq(input.stickKeys(state, 1, 0)[1], "d", "stick right emits d")
input.stickKeys(state, 0, 0)
eq(input.stickKeys(state, -1, 0)[1], "a", "stick left emits a")
input.stickKeys(state, 0, 0)
eq(input.stickKeys(state, 0, 1)[1], "s", "stick down emits s")

eq(input.button("a"), "space", "A confirms")
eq(input.button("dpadup"), "up", "dpad up")
eq(input.button("dpaddown"), "down", "dpad down")
eq(input.button("dpadleft"), "left", "dpad left")
eq(input.button("dpadright"), "right", "dpad right")
eq(input.button("x"), nil, "other buttons unmapped")

eq(input.label("throw", false), "SPACE", "keyboard throw label")
eq(input.label("throw", true), "A", "pad throw label")
eq(input.label("move", false), "WASD", "keyboard move label")
eq(input.label("move", true), "LEFT STICK", "pad move label")

eq(input.button("start"), "start", "start opens the restart prompt")
