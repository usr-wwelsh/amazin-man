local idle = dofile("src/idle.lua")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

local s = idle.new(180)
eq(idle.tick(s, 179), false, "not idle before the limit")
eq(idle.tick(s, 1), true, "idle once the limit is reached")

s = idle.new(180)
idle.tick(s, 170)
idle.touch(s)
eq(idle.tick(s, 170), false, "input resets the clock")
eq(idle.tick(s, 10), true, "idle again a full limit after input")

eq(idle.TIMEOUT, 180, "default timeout is three minutes")
