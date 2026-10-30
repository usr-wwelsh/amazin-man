local world = require("world")
local camera = require("camera")
local van = require("van")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

local pixel = { 0, 1, 0 }

local function setup(level, len)
    world.init({
        random = function(a) return a or 0 end,
        mask = { getPixel = function() return pixel[1], pixel[2], pixel[3] end },
        images = { chunks = { "house" }, cross = "cross", start = "start", grass = "grass", cars = { "car" } },
    })
    world.reset(level, len)
end

setup(1, 10)

local v = van.new("img")
eq(v.speed, van.MIN_SPEED, "van starts at minimum speed")
eq(v.image, "img", "van keeps its image")

local startY = v.y
eq(van.update(v, 0.1, 1, 0), nil, "clear road gives no crash")
eq(v.speed > van.MIN_SPEED, true, "throttle speeds the van up")
eq(v.y < startY, true, "van drives up the road")

for _ = 1, 600 do van.update(v, 0.1, 1, 0) end
eq(v.speed, van.MAX_SPEED, "speed is capped")

for _ = 1, 600 do van.update(v, 0.1, -1, 0) end
eq(v.speed, van.MIN_SPEED, "braking stops at minimum speed")

v = van.new()
v.speed = van.MAX_SPEED
for _ = 1, 600 do van.update(v, 0.1, 0, 0) end
eq(v.speed, van.MIN_SPEED, "coasting settles at minimum speed")

v = van.new()
v.speed = van.MAX_SPEED
v.slowT = 1
van.update(v, 0.1, 1, 0)
eq(v.speed, van.SLOW_SPEED, "a bitten van is capped at slow speed")
eq(v.slowT < 1, true, "slow timer runs down")

v = van.new()
van.update(v, 0.5, 0, 1)
eq(v.angle > 0, true, "steering right tilts the van right")
v = van.new()
local x0 = v.x
van.update(v, 0.1, 0, -1)
eq(v.x < x0 + 402 * 160 * 0.1 / 1080, true, "steering left moves the van left")

pixel = { 1, 0, 0 }
v = van.new()
v.x, v.y = world.DRIFT + 502, -1500
eq(van.update(v, 1 / 60, 0, 0), "house", "driving into a house wall crashes")
pixel = { 0, 1, 0 }

setup(2, 20)
local lane = world.chunkAt(6).lanes[1]
v = van.new()
v.y = lane.y
v.x = camera.x(v.y) + 800
lane.cars[1] = { x = v.x, y = v.y, w = 270, h = 105 }
eq(van.update(v, 1 / 60, 0, 0), "car", "driving into a car crashes")

setup(1, 10)
v = van.new()
eq(van.exitUpdate(v, 1 / 60), false, "van exiting is still on screen at first")
v.x = 1e6
eq(van.exitUpdate(v, 1 / 60), true, "van exiting leaves the screen")
eq(v.gone, true, "gone van is flagged")
