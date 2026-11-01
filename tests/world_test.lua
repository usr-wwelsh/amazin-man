local world = require("src.world")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

local function lowest(a)
    if not a then return 0 end
    return a
end

local pixel = { 0, 1, 0 }

local function setup(level, len)
    world.init({
        random = lowest,
        mask = { getPixel = function() return pixel[1], pixel[2], pixel[3] end },
        images = { chunks = { "house" }, cross = "cross", start = "start", grass = "grass", cars = { "car" }, oil = { "o1", "o2" } },
    })
    world.reset(level, len)
end

local box = { x = 100, y = 100, w = 40, h = 20 }
eq(world.circleHitsMailbox(box, 100, 100, 5), true, "circle inside box hits")
eq(world.circleHitsMailbox(box, 100, 150, 5), false, "circle far from box misses")
eq(world.circleHitsMailbox(box, 125, 100, 5), true, "circle touching box edge hits")

setup(1, 10)
local houseX = world.DRIFT + 100
local houseY = -1500
pixel = { 0, 1, 0 }
eq(world.blocked(houseX, houseY), false, "lawn is drivable")
pixel = { 0.5, 0.5, 0.5 }
eq(world.blocked(houseX, houseY), false, "pavement is drivable")
pixel = { 1, 0, 0 }
local hit, house = world.blocked(houseX, houseY)
eq(hit, true, "house wall blocks")
eq(house, true, "house wall reports a house")
local behind, behindHouse = world.blocked(houseX, 50)
eq(behind, true, "below the start blocks")
eq(behindHouse, false, "below the start is not a house")
local left, leftHouse = world.blocked(-10, -100)
eq(left, true, "left of the road blocks")
eq(leftHouse, false, "left of the road is not a house")
eq(world.blocked(100, -100), false, "start chunk is bare and drivable")
eq(world.vanBlocked(houseX, houseY), true, "van blocked by house wall")
pixel = { 0, 1, 0 }
eq(world.vanBlocked(houseX, houseY), false, "van free on lawn")

eq(world.chunkAt(1), world.chunkAt(1), "chunks are cached")
local first = world.chunkAt(1)
world.reset(1, 10)
eq(world.chunkAt(1) == first, false, "reset regenerates chunks")

setup(2, 20)
local cross = world.chunkAt(6)
eq(cross.cross, true, "cross chunk appears on level 2")
world.updateCars(0, 6)
local lane = cross.lanes[1]
eq(#lane.cars, 1, "lane spawns a car")
local car = lane.cars[1]
eq(world.carHit(car.x, car.y), true, "van touching a car is hit")
eq(world.carHit(car.x + 5000, car.y), false, "van away from cars is clear")
world.updateCars(100, 6)
eq(#lane.cars, 0, "cars leave past the lane end")

setup(1, 20)
eq(not world.chunkAt(6).cross, true, "no cross chunks on level 1")

local dog = dofile("src/dog.lua")

setup(1, 10)
local before = world.stats()
local doorChunk
for n = 0, 9 do
    if world.chunkAt(n).door then doorChunk = world.chunkAt(n) break end
end
doorChunk.delivered = true
doorChunk.windows[1].broken = true
local after = world.stats()
eq(after.housesDone, before.housesDone + 1, "stats counts delivered houses")
eq(after.windows, before.windows + 1, "stats counts broken windows")
eq(after.crushed, 0, "stats starts with no crushed mailboxes")

setup(1, 10)
local mailbox = world.chunkAt(1).mailbox
eq(world.crush(mailbox.x, mailbox.y), 1, "van over a mailbox crushes it")
eq(mailbox.down, true, "crushed mailbox is down")
eq(world.crush(mailbox.x, mailbox.y), 0, "a crushed mailbox is not crushed twice")
eq(world.stats().crushed, 1, "stats counts crushed mailboxes")

eq(world.provokes(1000, -540), true, "van near the sidewalk provokes dogs")
eq(world.provokes(1600, -540), false, "van far from the sidewalk leaves dogs alone")

setup(1, 10)
local vx, vy = world.DRIFT + 500, -1500
world.chunkAt(1).dog = dog.new(vx + 100, vy, vx + 100, vy)
local events = world.updateDogs(1 / 60, vx, vy, false)
eq(events[1], "bark", "nearby dog barks")
world.chunkAt(1).dog.state = "chase"
events = world.updateDogs(1 / 60, vx, vy, false)
eq(events[1], "bite", "chasing dog bites when close")
world.chunkAt(1).dog = dog.new(vx + 100, vy, vx + 100, vy)
eq(#world.updateDogs(1 / 60, vx, vy + 1080 * 5, false), 0, "far dogs stay asleep")

setup(world.OIL_LEVEL, 20)
local spills = world.chunkAt(1).oil
eq(#spills, 2, "oil spawns on a plain chunk at the oil level")
eq(world.chunkAt(0).oil, nil, "start chunk has no oil")
setup(math.max(world.OIL_LEVEL, 2), 20)
eq(world.chunkAt(6).cross, true, "chunk 6 is a cross chunk")
eq(world.chunkAt(6).oil, nil, "cross chunk has no oil")
setup(world.OIL_LEVEL, 20)
spills = world.chunkAt(1).oil
eq(spills[1].image, "o2", "spill takes an oil image")
if world.OIL_LEVEL > 1 then
    setup(world.OIL_LEVEL - 1, 20)
    eq(world.chunkAt(1).oil, nil, "no oil below the oil level")
    setup(world.OIL_LEVEL, 20)
    spills = world.chunkAt(1).oil
end
eq(world.oilAt(spills[1].x, spills[1].y), spills[1], "van on a spill is over oil")
eq(world.oilAt(spills[1].x + 3000, spills[1].y), nil, "van away from spills is clear")

local function real(a, b)
    if not a then return math.random() end
    if not b then return math.random(a) end
    return math.random(a, b)
end
local minLx, maxLx = math.huge, -math.huge
for seed = 1, 20 do
    math.randomseed(seed)
    world.init({
        random = real,
        mask = { getPixel = function() return 0, 1, 0 end },
        images = { chunks = { "house" }, cross = "cross", start = "start", grass = "grass", cars = { "car" }, oil = { "o1", "o2" } },
    })
    world.reset(8, 200)
    for n = 0, 199 do
        local c = world.chunkAt(n)
        local list = c.oil or {}
        for i, a in ipairs(list) do
            local lx = a.x - world.DRIFT * n
            minLx, maxLx = math.min(minLx, lx - a.r), math.max(maxLx, lx + a.r)
            eq(a.r >= 140, true, "spills are big")
            eq(a.y - a.r >= -(n + 1) * world.CHUNK_H and a.y + a.r <= -n * world.CHUNK_H, true, "spill stays inside its chunk")
            eq(lx - a.r >= 1000, true, "spill stays right of the sidewalk's left edge")
            eq(lx + a.r <= 2300, true, "spill stays on screen")
            for j = i + 1, #list do
                local b = list[j]
                eq(math.abs(a.y - b.y) >= a.r + b.r, true, "spills in a chunk never share a row")
            end
        end
    end
end
eq(minLx < 1300, true, "spills reach onto the sidewalk")
eq(maxLx > 2200, true, "spills reach the right side of the screen")
