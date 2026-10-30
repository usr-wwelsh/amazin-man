local dog = require("dog")

local world = {
    CHUNK_W = 1920,
    CHUNK_H = 1080,
    DRIFT = 402,
    VAN_RADIUS = 80,
    EDGE = 512,
    CAR_W = 300,
    CAR_H = 150,
}

local CHUNK_H, DRIFT, VAN_RADIUS, EDGE, CAR_W, CAR_H = world.CHUNK_H, world.DRIFT, world.VAN_RADIUS, world.EDGE, world.CAR_W, world.CAR_H
local HOUSE_W = 800
local MAILBOX_CHANCE = 0.2
local DOG_LEVEL = 3
local DOG_GAP_MIN, DOG_GAP_MAX = 3, 8
local DOG_HOME = { x = 300, y = 1005 }
local DOG_REST = { x = 440, y = 1012 }
local MAILBOX = { x = 1000, y = 430, w = 66, h = 104 }
local DOOR = { x = 475, y = 425, w = 75, h = 205 }
local WINDOWS = { { x = 480, y = 290, w = 80, h = 100 }, { x = 190, y = 700, w = 80, h = 110 } }
local CROSS_LEVEL = 2
local CROSS_MIN, CROSS_MAX = 6, 10
local GRASS_MIN, GRASS_MAX = 3, 8
local DOUBLE_CROSS_LEVEL, DOUBLE_CROSS_CHANCE = 4, 0.35
local SIDEWALK_RIGHT = { top = 1620, bottom = 1250 }
local CROSS_SPAN = 2800
local CAR_SPEED_MIN, CAR_SPEED_MAX = 420, 580
local CAR_GAP_MIN, CAR_GAP_MAX = 1.3, 3.2
local CAR_LANES = { { y = 365, dir = -1 }, { y = 650, dir = 1 } }

local images, mask, random
local layout, crossChunks, grassChunks, dogChunks = {}, {}, {}, {}
local lastCross, lastGrass, lastDog = 0, 0, 0
local level, levelLen = 1, 10

function world.init(cfg)
    images, mask, random = cfg.images, cfg.mask, cfg.random
end

function world.reset(n, len)
    level, levelLen = n, len
    layout, crossChunks, grassChunks, dogChunks = {}, {}, {}, {}
    lastCross, lastGrass, lastDog = 0, 0, 0
end

function world.layout()
    return layout
end

local function crossAt(n)
    while lastCross < n do
        lastCross = lastCross + random(CROSS_MIN, CROSS_MAX)
        crossChunks[lastCross] = true
        if level >= DOUBLE_CROSS_LEVEL and random() < DOUBLE_CROSS_CHANCE then
            lastCross = lastCross + 1
            crossChunks[lastCross] = true
        end
    end
    return crossChunks[n]
end

local function grassAt(n)
    while lastGrass < n do
        lastGrass = lastGrass + random(GRASS_MIN, GRASS_MAX)
        grassChunks[lastGrass] = true
    end
    return grassChunks[n]
end

local function dogAt(n)
    while lastDog < n do
        lastDog = lastDog + random(DOG_GAP_MIN, DOG_GAP_MAX)
        dogChunks[lastDog] = true
    end
    return dogChunks[n]
end

local function chunkAt(n)
    if not layout[n] then
        local ox, oy = DRIFT * n, -(n + 1) * CHUNK_H
        local cross = level >= CROSS_LEVEL and crossAt(n)
        local start = n == 0
        local grass = not start and not cross and grassAt(n)
        local c = { image = start and images.start or cross and images.cross or grass and images.grass or images.chunks[random(#images.chunks)], windows = {}, cross = cross, bare = start or cross or grass, delivered = false }
        if start or grass then
        elseif cross then
            c.lanes = {}
            for i, l in ipairs(CAR_LANES) do
                local from, to = ox - EDGE - CAR_W, ox + CROSS_SPAN
                if l.dir < 0 then from, to = to, from end
                c.lanes[i] = { y = oy + l.y, dir = l.dir, from = from, to = to, speed = random(CAR_SPEED_MIN, CAR_SPEED_MAX), timer = random() * CAR_GAP_MIN, cars = {} }
            end
        else
            c.door = { x = ox + DOOR.x, y = oy + DOOR.y, w = DOOR.w, h = DOOR.h, delivered = false }
            for i, w in ipairs(WINDOWS) do
                c.windows[i] = { x = ox + w.x, y = oy + w.y, w = w.w, h = w.h, left = ox + w.x - w.w / 2, right = ox + w.x + w.w / 2, broken = false }
            end
            if random() < MAILBOX_CHANCE then
                c.mailbox = { x = ox + MAILBOX.x, y = oy + MAILBOX.y, w = MAILBOX.w, h = MAILBOX.h, down = false, delivered = false }
            end
            if level >= DOG_LEVEL and n < levelLen and dogAt(n) then
                c.dog = dog.new(ox + DOG_REST.x, oy + DOG_REST.y, ox + DOG_REST.x, oy + DOG_REST.y)
                c.dogHome = { x = ox + DOG_HOME.x, y = oy + DOG_HOME.y }
            end
        end
        layout[n] = c
    end
    return layout[n]
end

local function blocked(x, y)
    local n = math.floor(-y / CHUNK_H)
    local lx = math.floor(x - DRIFT * n)
    local ly = math.floor(y + (n + 1) * CHUNK_H)
    if n < 0 or lx < 0 then return true, false end
    if lx >= HOUSE_W or chunkAt(n).bare then return false end
    local r, g, b = mask:getPixel(lx, ly)
    local lawn = g > 0.9 and r < 0.2 and b < 0.2
    local pavement = math.abs(r - g) < 0.06 and math.abs(g - b) < 0.06 and r > 0.4 and r < 0.85
    return not (lawn or pavement), true
end

local function vanBlocked(x, y)
    local hit, house = blocked(x, y)
    if hit then return true, house end
    for i = 0, 7 do
        local a = i * math.pi / 4
        hit, house = blocked(x + VAN_RADIUS * math.cos(a), y + VAN_RADIUS * math.sin(a))
        if hit then return true, house end
    end
    return false, false
end

local function circleHitsMailbox(m, cx, cy, r)
    local nx = math.max(m.x - m.w / 2, math.min(cx, m.x + m.w / 2))
    local ny = math.max(m.y - m.h / 2, math.min(cy, m.y + m.h / 2))
    return (cx - nx) ^ 2 + (cy - ny) ^ 2 <= r * r
end

local function updateCars(dt, vn)
    for n = math.max(0, vn - 1), vn + 1 do
        for _, lane in ipairs(chunkAt(n).lanes or {}) do
            lane.timer = lane.timer - dt
            if lane.timer <= 0 then
                lane.timer = CAR_GAP_MIN + random() * (CAR_GAP_MAX - CAR_GAP_MIN)
                lane.cars[#lane.cars + 1] = { x = lane.from, y = lane.y, w = CAR_W * 0.9, h = CAR_H * 0.7, image = images.cars[random(#images.cars)] }
            end
            for i = #lane.cars, 1, -1 do
                local car = lane.cars[i]
                car.x = car.x + lane.dir * lane.speed * dt
                if (car.x - lane.to) * lane.dir >= 0 then table.remove(lane.cars, i) end
            end
        end
    end
end

local function carHit(x, y)
    local vn = math.floor(-y / CHUNK_H)
    for n = math.max(0, vn - 1), vn + 1 do
        for _, lane in ipairs(chunkAt(n).lanes or {}) do
            for _, car in ipairs(lane.cars) do
                if circleHitsMailbox(car, x, y, VAN_RADIUS) then return true end
            end
        end
    end
    return false
end
world.chunkAt = chunkAt
world.blocked = blocked
world.vanBlocked = vanBlocked
world.circleHitsMailbox = circleHitsMailbox
world.updateCars = updateCars
world.carHit = carHit

function world.stats()
    local st = { houses = 0, housesDone = 0, windows = 0, crushed = 0 }
    for n = 0, levelLen - 1 do
        local c = chunkAt(n)
        if c.door then
            st.houses = st.houses + 1
            if c.delivered then st.housesDone = st.housesDone + 1 end
        end
        for _, win in ipairs(c.windows) do
            if win.broken then st.windows = st.windows + 1 end
        end
        if c.mailbox and c.mailbox.down then st.crushed = st.crushed + 1 end
    end
    return st
end

function world.provokes(x, y)
    local n = math.floor(-y / CHUNK_H)
    local lx = x - DRIFT * n
    local ly = y + (n + 1) * CHUNK_H
    local f = ly / CHUNK_H
    local right = SIDEWALK_RIGHT.top + (SIDEWALK_RIGHT.bottom - SIDEWALK_RIGHT.top) * f
    return lx - VAN_RADIUS <= right
end

function world.crush(x, y)
    local crushed = 0
    local vn = math.floor(-y / CHUNK_H)
    for n = math.max(0, vn - 1), vn + 1 do
        local m = chunkAt(n).mailbox
        if m and not m.down and circleHitsMailbox(m, x, y, VAN_RADIUS) then
            m.down = true
            crushed = crushed + 1
        end
    end
    return crushed
end

function world.updateDogs(dt, vx, vy, provoked)
    local events = {}
    local vn = math.floor(-vy / CHUNK_H)
    for n, c in pairs(layout) do
        local d = c.dog
        local event = d and (math.abs(n - vn) <= 1 or d.state == "chase" or d.state == "home") and dog.update(d, dt, vx, vy, provoked)
        if event then events[#events + 1] = event end
    end
    return events
end

return world
