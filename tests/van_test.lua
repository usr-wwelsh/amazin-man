local world = require("src.world")
local camera = require("src.camera")
local van = require("src.van")

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
        images = { chunks = { "house" }, cross = "cross", start = "start", grass = "grass", cars = { "car" }, oil = { "o1", "o2" } },
    })
    world.reset(level, len)
end

setup(1, 10)

local v = van.new("img")
eq(v.speed, van.MIN_SPEED, "van starts at minimum speed")
eq(v.image, "img", "van keeps its image")
local oiled = van.new("img", "oil")
eq(oiled.oilImage, "oil", "van keeps its oily image")

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

setup(world.OIL_LEVEL, 20)
local spill = world.chunkAt(1).oil[1]
v = van.new()
v.x, v.y = spill.x, spill.y
local x1 = v.x
van.update(v, 0.1, 0, 1)
van.update(v, 0.1, 0, -1)
eq(v.slipT > 0, true, "driving over oil starts a slip")
eq(v.x > x1, true, "slipping van ignores steering and keeps sliding")

v = van.new()
v.x, v.y = spill.x, spill.y
v.slipT = 0
v.speed = van.MAX_SPEED
for _ = 1, 3 do van.update(v, 0.1, 0, 0) end
eq(v.x > spill.x, true, "unsteered van slides away from the spill center")
v.x, v.y = spill.x + 3000, spill.y
v.slipT = 0.05
van.update(v, 0.1, 0, 1)
eq(v.slipT, 0, "slip timer runs out off the oil")

v = van.new()
v.x, v.y = spill.x, spill.y
eq(v.spin, 0, "van starts without spin")
van.update(v, 0.1, 0, 0)
eq(math.abs(v.spin - van.SPIN * 0.1 / van.SPIN_TIME) < 1e-9, true, "spin advances at a steady rate")
eq(van.SPIN_TIME > van.SLIP_TIME, true, "the spin outlasts the slip")
v.x, v.y = spill.x + 3000, spill.y
for _ = 1, 8 do van.update(v, 0.1, 0, 0) end
eq(v.slipT, 0, "slip is over before the spin")
eq(v.spin > 0, true, "spin keeps going after the slip ends")
for _ = 1, 10 do van.update(v, 0.1, 0, 0) end
eq(v.spin, 0, "spin resets once it completes")

v = van.new()
v.x, v.y = spill.x, spill.y
v.speed = van.MAX_SPEED
van.update(v, 0.1, 1, 0)
eq(v.speed, van.MAX_SPEED, "the van keeps its speed while sliding across oil")
v.x, v.y = spill.x + 3000, spill.y
local steps = 0
repeat
    van.update(v, 0.1, 1, 0)
    steps = steps + 1
until v.slipT == 0 or steps > 50
eq(v.speed, van.OIL_SPEED, "the van crawls once the slide ends")
for _ = 1, 25 do van.update(v, 0.1, 1, 0) end
eq(v.speed > van.OIL_SPEED, true, "the van speeds up again after the crawl")

v = van.new()
eq(v.stain, 0, "a clean van has no stain")
v.x, v.y = spill.x, spill.y
van.update(v, 0.1, 0, 0)
eq(v.stain, 1, "hitting oil stains the van")
v.x, v.y = spill.x + 3000, spill.y
local held = true
for _ = 1, 40 do
    van.update(v, 0.1, 0, 0)
    if v.slipT > 0 or v.crawlT > 0 then held = held and v.stain == 1 end
end
eq(held, true, "the stain stays full through the slide and crawl")
v.x, v.y = spill.x + 3000, spill.y
v.stain, v.slipT, v.crawlT = 1, 0, 0
van.update(v, 0.1, 0, 0)
eq(v.stain < 1 and v.stain > 0, true, "the stain fades after the crawl")
for _ = 1, 40 do van.update(v, 0.1, 0, 0) end
eq(v.stain, 0, "the stain fades away completely")
