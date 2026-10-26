local scoring = require("scoring")
local dog = require("dog")

local CHUNK_W, CHUNK_H = 1920, 1080
local HOUSE_W = 800
local VAN_RADIUS = 80
local MARGIN = 160
local DRIFT = 402
local MAX_SPEED, MIN_SPEED, ACCEL, BRAKE, STEER = 480, 160, 320, 600, 340
local ZOOM = 0.7
local MAX_TILT, TILT_RATE = 0.35, 8
local START_Y = 540
local VIEW_W, VIEW_H = CHUNK_W / ZOOM, CHUNK_H / ZOOM
local VAN_SCALE = 3.5
local PACKAGE_SPEED, PACKAGE_LIFE, PACKAGE_SIZE, THROW_COOLDOWN = 650, 2.2, 72, 0.6
local AMMO_START = 15
local RUN_LEVELS = 8
local EXIT_SPEED = 700
local NAME_LEN = 5
local BOARD_FILE = "scores.txt"
local MAILBOX_CHANCE = 0.2
local DOG_LEVEL = 3
local DOG_GAP_MIN, DOG_GAP_MAX = 3, 8
local SIDEWALK_LEFT = { top = 1430, bottom = 1030 }
local SIDEWALK_RIGHT = { top = 1620, bottom = 1250 }
local DOG_HOME = { x = 300, y = 1005 }
local DOG_REST = { x = 440, y = 1012 }
local DOG_SIZE, DOG_HOME_SIZE = 200, 240
local SLOW_TIME, SLOW_SPEED = 2.5, 256
local MAILBOX = { x = 1000, y = 430, w = 66, h = 104 }
local DOOR = { x = 475, y = 425, w = 75, h = 205 }
local WINDOWS = { { x = 480, y = 290, w = 80, h = 100 }, { x = 190, y = 700, w = 80, h = 110 } }

local BORDER_TOP, BORDER_RIGHT = 90, 1823
local CROSS_MIN, CROSS_MAX = 6, 10
local GRASS_MIN, GRASS_MAX = 3, 8
local DOUBLE_CROSS_LEVEL, DOUBLE_CROSS_CHANCE = 4, 0.35
local CROSS_SPAN = 2800
local EDGE = 512
local LEVEL_BASE, LEVEL_STEP = 8, 2
local ZOOM_TIME = 2
local START_DELAY = 2
local OVERVIEW_H = 840
local CAR_W, CAR_H = 300, 150
local CAR_SPEED_MIN, CAR_SPEED_MAX = 420, 580
local CAR_GAP_MIN, CAR_GAP_MAX = 1.3, 3.2
local CAR_LANES = { { y = 365, dir = -1 }, { y = 650, dir = 1 } }

local chunkImages = {}
local crossImage
local startImage
local edgeQuad
local carImages = {}
local dogImages = {}
local crossChunks = {}
local lastCross = 0
local grassChunks = {}
local lastGrass = 0
local dogChunks = {}
local lastDog = 0
local grassImage
local layout = {}
local van = {}
local mask
local border
local borderShader
local art = {}
local packages = {}
local score = {}
local runTotal = 0
local levelPoints = 0
local levelGrade = "F"
local levelBonus = 0
local elapsed = 0
local levelPar = 0
local levelStars = 0
local exitComplete = false
local name = {}
local nameCursor = 1
local board = {}
local boardRank
local cooldown = 0
local startDelay = 0
local state = "play"
local zoomT = 0
local level, levelLen = 1, 10
local ammo = 0
local fonts = {}
local sounds = {}
local DELIVER_VOICES = { "hello", "thank_you_1" }
local WINDOW_VOICES = { "my_window_1", "my_leg" }
local EXIT_VOICES = { "out_of_packages_1", "out_of_packages_2", "out_of_packages_3" }
local exitVoices = {}
local HOUSE_CRASH_VOICES = { "house_crash" }
local houseCrashVoices = {}

local function crossAt(n)
    while lastCross < n do
        lastCross = lastCross + love.math.random(CROSS_MIN, CROSS_MAX)
        crossChunks[lastCross] = true
        if level >= DOUBLE_CROSS_LEVEL and love.math.random() < DOUBLE_CROSS_CHANCE then
            lastCross = lastCross + 1
            crossChunks[lastCross] = true
        end
    end
    return crossChunks[n]
end

local function grassAt(n)
    while lastGrass < n do
        lastGrass = lastGrass + love.math.random(GRASS_MIN, GRASS_MAX)
        grassChunks[lastGrass] = true
    end
    return grassChunks[n]
end

local function dogAt(n)
    while lastDog < n do
        lastDog = lastDog + love.math.random(DOG_GAP_MIN, DOG_GAP_MAX)
        dogChunks[lastDog] = true
    end
    return dogChunks[n]
end

local function chunkAt(n)
    if not layout[n] then
        local ox, oy = DRIFT * n, -(n + 1) * CHUNK_H
        local cross = crossAt(n)
        local start = n == 0
        local grass = not start and not cross and grassAt(n)
        local c = { image = start and startImage or cross and crossImage or grass and grassImage or chunkImages[love.math.random(#chunkImages)], windows = {}, cross = cross, bare = start or cross or grass, delivered = false }
        if start or grass then
        elseif cross then
            c.lanes = {}
            for i, l in ipairs(CAR_LANES) do
                local from, to = ox - EDGE - CAR_W, ox + CROSS_SPAN
                if l.dir < 0 then from, to = to, from end
                c.lanes[i] = { y = oy + l.y, dir = l.dir, from = from, to = to, speed = love.math.random(CAR_SPEED_MIN, CAR_SPEED_MAX), timer = love.math.random() * CAR_GAP_MIN, cars = {} }
            end
        else
            c.door = { x = ox + DOOR.x, y = oy + DOOR.y, w = DOOR.w, h = DOOR.h, delivered = false }
            for i, w in ipairs(WINDOWS) do
                c.windows[i] = { x = ox + w.x, y = oy + w.y, w = w.w, h = w.h, left = ox + w.x - w.w / 2, right = ox + w.x + w.w / 2, broken = false }
            end
            if love.math.random() < MAILBOX_CHANCE then
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

local function play(name)
    local s = sounds[name]:clone()
    s:play()
end

local function playOneOf(names)
    play(names[love.math.random(#names)])
end

local function drift(y)
    return DRIFT * -y / CHUNK_H
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

local function inRect(px, py, left, top, right, bottom)
    return px >= left and px <= right and py >= top and py <= bottom
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
                lane.timer = CAR_GAP_MIN + love.math.random() * (CAR_GAP_MAX - CAR_GAP_MIN)
                lane.cars[#lane.cars + 1] = { x = lane.from, y = lane.y, w = CAR_W * 0.9, h = CAR_H * 0.7, image = carImages[love.math.random(#carImages)] }
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

local function drawFit(img, cx, cy, w, h, rotation)
    love.graphics.draw(img, cx, cy, rotation or 0, w / img:getWidth(), h / img:getHeight(), img:getWidth() / 2, img:getHeight() / 2)
end

local function cameraX(y)
    return drift(y) - (VIEW_W - CHUNK_W) / 2
end

local function vanOnSidewalk()
    local n = math.floor(-van.y / CHUNK_H)
    local lx = van.x - DRIFT * n
    local ly = van.y + (n + 1) * CHUNK_H
    local f = ly / CHUNK_H
    local left = SIDEWALK_LEFT.top + (SIDEWALK_LEFT.bottom - SIDEWALK_LEFT.top) * f
    local right = SIDEWALK_RIGHT.top + (SIDEWALK_RIGHT.bottom - SIDEWALK_RIGHT.top) * f
    return lx - VAN_RADIUS <= right and lx + VAN_RADIUS >= left
end

local function levelStats()
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

local function levelAmmo()
    return math.max(levelStats().houses, AMMO_START + 1 - level)
end

local function startLevel(n)
    level = n
    levelLen = LEVEL_BASE + LEVEL_STEP * n
    state = "play"
    layout = {}
    crossChunks = {}
    grassChunks = {}
    lastGrass = 0
    lastCross = 0
    dogChunks = {}
    lastDog = 0
    packages = {}
    ammo = levelAmmo()
    score = { delivered = 0, windows = 0, mailboxes = 0 }
    cooldown = 0
    startDelay = START_DELAY
    elapsed = 0
    sounds.summary:stop()
    sounds.theme:play()
    sounds.ambience:play()
    play("car_startup")
    if not sounds.van_running:isPlaying() then sounds.van_running:play() end
    van = { x = 1550 + DRIFT * START_Y / CHUNK_H, y = -START_Y, speed = MIN_SPEED, angle = 0, image = van.image }
end

local function reset()
    runTotal = 0
    startLevel(1)
end

local function levelDistance()
    return levelLen * CHUNK_H - START_Y
end

local function finishLevel(early)
    state = "zoom"
    zoomT = 0
    local houses = levelStats().houses
    levelPar = scoring.par(levelDistance(), MAX_SPEED)
    levelStars = early and 0 or scoring.stars(elapsed, levelDistance(), MAX_SPEED)
    levelBonus = early and 0 or scoring.bonus(elapsed, levelDistance(), MAX_SPEED, score.delivered, houses)
    levelPoints = scoring.points(score.delivered, score.windows, score.mailboxes, levelBonus)
    levelGrade = scoring.grade(scoring.best(houses, levelDistance(), MAX_SPEED), levelPoints, score.windows + score.mailboxes + houses - score.delivered)
    runTotal = runTotal + levelPoints
    sounds.van_running:pause()
    sounds.theme:pause()
    sounds.ambience:pause()
    sounds.summary:play()
    if not early then play("successful_package") end
end

local function startExit()
    state = "exit"
    local st = levelStats()
    exitComplete = st.housesDone == st.houses
    if not exitComplete and #exitVoices > 0 then play(exitVoices[love.math.random(#exitVoices)]) end
end

local function loadBoard()
    local text = love.filesystem.read(BOARD_FILE)
    board = text and scoring.decode(text) or {}
end

local function enterName()
    state = "name"
    name = { "A", "A", "A", "A", "A" }
    nameCursor = 1
end

local function submitName()
    local entry = table.concat(name)
    loadBoard()
    board = scoring.insert(board, entry, runTotal)
    boardRank = nil
    for i, e in ipairs(board) do
        if e.name == entry and e.score == runTotal then boardRank = i break end
    end
    love.filesystem.write(BOARD_FILE, scoring.encode(board))
    state = "board"
end

local function camera()
    local z, x, y = ZOOM, cameraX(van.y), van.y - VIEW_H * 0.65
    if state == "play" or state == "exit" then return z, x, y, 0 end
    local t = zoomT * zoomT * (3 - 2 * zoomT)
    local width, height = DRIFT * (levelLen - 1) + CHUNK_W, levelLen * CHUNK_H
    local zEnd = math.min(OVERVIEW_H / height, 1700 / width)
    local cx0, cy0 = x + VIEW_W / 2, y + VIEW_H / 2
    local cx, cy = cx0 + (width / 2 - cx0) * t, cy0 + (-height / 2 - cy0) * t
    z = ZOOM * (zEnd / ZOOM) ^ t
    return z, cx - CHUNK_W / (2 * z), cy - CHUNK_H / (2 * z), t
end

local function drawMarkers(c, r, alpha)
    local function dot(x, y, red, g, b)
        love.graphics.setColor(red, g, b, alpha)
        love.graphics.circle("fill", x, y, r)
    end
    if c.door then
        local d = c.door
        if c.delivered then dot(d.x + d.w / 2, d.y + d.h / 2, 0, 0.8, 0) else dot(d.x + d.w / 2, d.y + d.h / 2, 0.9, 0.15, 0.15) end
    end
    for _, win in ipairs(c.windows) do
        if win.broken then dot(win.x, win.y, 0.9, 0.15, 0.15) end
    end
    local m = c.mailbox
    if m and m.down then dot(m.x, m.y, 0.9, 0.15, 0.15) end
    love.graphics.setColor(1, 1, 1)
end

local function drawStar(cx, cy, r, filled, color)
    local pts = {}
    for i = 0, 9 do
        local a = -math.pi / 2 + i * math.pi / 5
        local d = i % 2 == 0 and r or r * 0.45
        pts[#pts + 1] = { cx + d * math.cos(a), cy + d * math.sin(a) }
    end
    if filled then
        love.graphics.setColor(color)
        for i = 1, 10 do
            local p, q = pts[i], pts[i % 10 + 1]
            love.graphics.polygon("fill", cx, cy, p[1], p[2], q[1], q[2])
        end
    else
        love.graphics.setColor(0.4, 0.4, 0.45)
        love.graphics.setLineWidth(2)
        for i = 1, 10 do
            local p, q = pts[i], pts[i % 10 + 1]
            love.graphics.line(p[1], p[2], q[1], q[2])
        end
    end
end

local function knockOutWhite(path)
    local data = love.image.newImageData(path)
    local w, h = data:getDimensions()
    local function white(x, y)
        local r, g, b, a = data:getPixel(x, y)
        return a > 0 and r > 0.9 and g > 0.9 and b > 0.9
    end
    local stack = {}
    for x = 0, w - 1 do stack[#stack + 1] = { x, 0 }; stack[#stack + 1] = { x, h - 1 } end
    for y = 0, h - 1 do stack[#stack + 1] = { 0, y }; stack[#stack + 1] = { w - 1, y } end
    while #stack > 0 do
        local p = table.remove(stack)
        local x, y = p[1], p[2]
        if x >= 0 and y >= 0 and x < w and y < h and white(x, y) then
            data:setPixel(x, y, 1, 1, 1, 0)
            stack[#stack + 1] = { x + 1, y }
            stack[#stack + 1] = { x - 1, y }
            stack[#stack + 1] = { x, y + 1 }
            stack[#stack + 1] = { x, y - 1 }
        end
    end
    return data
end

local BORDER_SHADER = [[
extern number time;
extern vec2 size;
vec3 hue(float h) {
    return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec2 p = uv * size;
    float x = p.x;
    if (p.y < 90.0) x = mod(p.x + time * 60.0, 499.0) + 499.0;
    else if (p.y >= 969.0) x = mod(p.x - time * 60.0, 499.0) + 499.0;
    vec4 t = Texel(tex, vec2(x, p.y) / size);
    float ink = t.b * (1.0 - max(t.r, t.g));
    return vec4(hue(fract(time * 0.15)) * ink, t.a) * color;
}
]]

local function hue(h)
    local function ch(o)
        return math.max(0, math.min(1, math.abs((h * 6 + o) % 6 - 3) - 1))
    end
    return ch(0), ch(4), ch(2)
end

function love.load()
    for i = 1, 4 do
        chunkImages[i] = love.graphics.newImage("assets/chunk" .. i .. ".png")
    end
    edgeQuad = love.graphics.newQuad(-EDGE, 0, CHUNK_W + EDGE, CHUNK_H, CHUNK_W, CHUNK_H)
    for _, name in ipairs({ "car_startup", "hello", "how_gonna_get_mail", "my_leg", "my_window_1", "successful_package", "thank_you_1", "thatsmycar", "dogbark", "van_running", "watchwheregoing", "window_crash" }) do
        sounds[name] = love.audio.newSource("sounds/" .. name .. ".ogg", "static")
    end
    for _, group in ipairs({ { EXIT_VOICES, exitVoices }, { HOUSE_CRASH_VOICES, houseCrashVoices } }) do
        for _, voice in ipairs(group[1]) do
            local path = "sounds/" .. voice .. ".ogg"
            if love.filesystem.getInfo(path) then
                sounds[voice] = love.audio.newSource(path, "static")
                group[2][#group[2] + 1] = voice
            end
        end
    end
    sounds.dogbark:setVolume(0.3)
    sounds.ambience = love.audio.newSource("sounds/ambience.ogg", "stream")
    sounds.ambience:setLooping(true)
    sounds.ambience:setVolume(0.5)
    sounds.ambience:play()
    sounds.theme = love.audio.newSource("sounds/amazin.ogg", "stream")
    sounds.theme:setLooping(true)
    sounds.theme:setVolume(0.85)
    sounds.theme:setPitch(0.8)
    sounds.theme:play()
    sounds.summary = love.audio.newSource("sounds/amazindrum.ogg", "stream")
    sounds.summary:setLooping(true)
    sounds.summary:setVolume(0.85)
    sounds.summary:setPitch(0.8)
    sounds.van_running:setLooping(true)
    sounds.van_running:setVolume(0.5)
    sounds.van_running:play()
    crossImage = love.graphics.newImage("assets/chunkCross.png")
    startImage = love.graphics.newImage("assets/chunk0.png")
    grassImage = love.graphics.newImage("assets/chunkG1.png")
    for i = 1, 4 do
        carImages[i] = love.graphics.newImage(knockOutWhite("assets/car" .. i .. ".png"))
    end
    van.image = love.graphics.newImage("assets/van.png")
    for _, name in ipairs({ "dogsleep", "dogbark", "dogrun1", "dogrun2", "doghome" }) do
        dogImages[name] = love.graphics.newImage(knockOutWhite("assets/" .. name .. ".png"))
    end
    for _, name in ipairs({ "window", "mailbox", "box" }) do
        art[name] = love.graphics.newImage("assets/" .. name .. ".png")
    end
    fonts.default = love.graphics.getFont()
    fonts.title = love.graphics.newFont(44)
    fonts.body = love.graphics.newFont(26)
    fonts.counter = love.graphics.newFont(40)
    fonts.grade = love.graphics.newFont(300)
    border = love.graphics.newImage("assets/border.png")
    borderShader = love.graphics.newShader(BORDER_SHADER)
    borderShader:send("size", { border:getWidth(), border:getHeight() })
    mask = love.image.newImageData("assets/chunk1.png")
    love.graphics.setBackgroundColor(0.75, 0.75, 0.75)
    loadBoard()
    reset()
end

function love.update(dt)
    if state == "exit" then
        updateCars(dt, math.floor(-van.y / CHUNK_H))
        van.angle = van.angle + (MAX_TILT - van.angle) * math.min(1, TILT_RATE * dt)
        van.x = van.x + EXIT_SPEED * dt + DRIFT * van.speed * dt / CHUNK_H
        van.y = van.y - van.speed * dt
        sounds.van_running:setPitch(0.6 + 0.8 * van.speed / MAX_SPEED)
        if van.x > cameraX(van.y) + VIEW_W + VAN_RADIUS * 2 then
            van.gone = true
            finishLevel(not exitComplete)
        end
        return
    end
    if state ~= "play" then
        if state == "zoom" then
            zoomT = math.min(1, zoomT + dt / ZOOM_TIME)
            if zoomT == 1 then state = "summary" end
        end
        return
    end
    if startDelay > 0 then
        startDelay = startDelay - dt
        return
    end
    elapsed = elapsed + dt
    cooldown = math.max(0, cooldown - dt)
    updateCars(dt, math.floor(-van.y / CHUNK_H))
    van.slowT = math.max(0, (van.slowT or 0) - dt)
    local down = love.keyboard.isDown
    if down("up", "w") then
        van.speed = math.min(MAX_SPEED, van.speed + ACCEL * dt)
    elseif down("down", "s") then
        van.speed = math.max(MIN_SPEED, van.speed - BRAKE * dt)
    else
        van.speed = math.max(MIN_SPEED, van.speed - ACCEL * 0.3 * dt)
    end
    if van.slowT > 0 then van.speed = math.min(van.speed, SLOW_SPEED) end
    local steer = (down("right", "d") and 1 or 0) - (down("left", "a") and 1 or 0)
    van.angle = van.angle + (steer * MAX_TILT - van.angle) * math.min(1, TILT_RATE * dt)
    local nx = van.x + steer * STEER * dt + DRIFT * van.speed * dt / CHUNK_H
    local ny = van.y - van.speed * dt
    local cx = cameraX(ny)
    nx = math.max(cx + MARGIN, math.min(cx + VIEW_W - MARGIN, nx))
    local hitX = carHit(nx, van.y)
    local blockedX, houseX = vanBlocked(nx, van.y)
    if not blockedX and not hitX then van.x = nx end
    local hitY = carHit(van.x, ny)
    local blockedY, houseY = vanBlocked(van.x, ny)
    if hitX or hitY then
        play("thatsmycar")
        finishLevel(true)
        return
    end
    if houseX or houseY then
        if #houseCrashVoices > 0 then playOneOf(houseCrashVoices) end
        finishLevel(true)
        return
    end
    sounds.van_running:setPitch(0.6 + 0.8 * van.speed / MAX_SPEED)
    if blockedY or hitY then
        van.speed = MIN_SPEED
    else
        van.y = ny
    end

    local vn = math.floor(-van.y / CHUNK_H)
    for n = math.max(0, vn - 1), vn + 1 do
        local m = chunkAt(n).mailbox
        if m and not m.down and circleHitsMailbox(m, van.x, van.y, VAN_RADIUS) then
            m.down = true
            play("watchwheregoing")
            score.mailboxes = score.mailboxes + 1
        end
    end

    local provoked = vanOnSidewalk()
    for n, c in pairs(layout) do
        local d = c.dog
        local event = d and (math.abs(n - vn) <= 1 or d.state == "chase" or d.state == "home") and dog.update(d, dt, van.x, van.y, provoked)
        if event == "bark" then play("dogbark") end
        if event == "bite" then
            ammo = math.max(0, ammo - 1)
            van.slowT = SLOW_TIME
        end
    end

    for i = #packages, 1, -1 do
        local pk = packages[i]
        pk.x = pk.x + pk.vx * dt
        pk.y = pk.y + pk.vy * dt
        pk.life = pk.life - dt
        local gone = pk.life <= 0
        local n = math.floor(-pk.y / CHUNK_H)
        if n >= 0 then
            local c = chunkAt(n)
            for _, w in ipairs(c.windows) do
                if not w.broken and inRect(pk.x, pk.y, w.left, w.y - w.h / 2, w.right, w.y + w.h / 2) then
                    w.broken = true
                    play("window_crash")
                    playOneOf(WINDOW_VOICES)
                    score.windows = score.windows + 1
                    gone = true
                end
            end
            local d = c.door
            if d and inRect(pk.x, pk.y, d.x, d.y, d.x + d.w, d.y + d.h) then
                d.delivered = true
                if not c.delivered then
                    c.delivered = true
                    play("successful_package")
                    playOneOf(DELIVER_VOICES)
                    score.delivered = score.delivered + 1
                end
                gone = true
            end
            local m = c.mailbox
            if m and not m.down and not m.delivered and circleHitsMailbox(m, pk.x, pk.y, PACKAGE_SIZE / 2) then
                m.delivered = true
                if not c.delivered then
                    c.delivered = true
                    play("successful_package")
                    play("how_gonna_get_mail")
                    score.delivered = score.delivered + 1
                end
                gone = true
            end
        end
        if gone then table.remove(packages, i) end
    end

    if van.y <= -levelLen * CHUNK_H then
        finishLevel()
    elseif ammo == 0 and #packages == 0 then
        startExit()
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" and state ~= "name" then reset() end
    if state == "summary" and (key == "space" or key == "return") then
        if level >= RUN_LEVELS then enterName() else startLevel(level + 1) end
        return
    end
    if state == "name" then
        if key == "w" or key == "up" then name[nameCursor] = scoring.cycle(name[nameCursor], -1) end
        if key == "s" or key == "down" then name[nameCursor] = scoring.cycle(name[nameCursor], 1) end
        if key == "a" or key == "left" then nameCursor = math.max(1, nameCursor - 1) end
        if key == "d" or key == "right" then nameCursor = math.min(NAME_LEN, nameCursor + 1) end
        if key == "return" or key == "space" then submitName() end
        return
    end
    if state == "board" then
        if key == "space" or key == "return" then reset() end
        return
    end
    if key == "space" and state == "play" and cooldown == 0 and ammo > 0 then
        cooldown = THROW_COOLDOWN
        ammo = ammo - 1
        packages[#packages + 1] = { x = van.x, y = van.y, vx = -PACKAGE_SPEED, vy = -van.speed, life = PACKAGE_LIFE }
    end
end

function love.draw()
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / CHUNK_W, h / CHUNK_H)
    love.graphics.translate((w - CHUNK_W * scale) / 2, (h - CHUNK_H * scale) / 2)
    love.graphics.scale(scale)
    love.graphics.setScissor((w - CHUNK_W * scale) / 2, (h - CHUNK_H * scale) / 2, CHUNK_W * scale, CHUNK_H * scale)

    local z, camX, camY, t = camera()
    love.graphics.scale(z)
    love.graphics.translate(-camX, -camY)
    if t > 0 then
        love.graphics.setColor(0.08, 0.08, 0.1, t)
        love.graphics.rectangle("fill", camX, camY, CHUNK_W / z, CHUNK_H / z)
    end

    local first = math.max(0, math.floor(-(camY + CHUNK_H / z) / CHUNK_H))
    for n = first, math.min(levelLen - 1, math.floor(-camY / CHUNK_H)) do
        love.graphics.setColor(1, 1, 1)
        local c = chunkAt(n)
        love.graphics.draw(c.image, edgeQuad, DRIFT * n - EDGE, -(n + 1) * CHUNK_H)
        for _, win in ipairs(c.windows) do
            if win.broken then love.graphics.setColor(0.4, 0.4, 0.45) end
            drawFit(art.window, win.x, win.y, win.w, win.h)
            love.graphics.setColor(1, 1, 1)
            if win.broken then
                love.graphics.setColor(0.1, 0.1, 0.1)
                love.graphics.setLineWidth(5)
                love.graphics.line(win.x - win.w / 2, win.y - win.h / 2, win.x, win.y, win.x + win.w / 4, win.y + win.h / 2)
                love.graphics.line(win.x + win.w / 2, win.y - win.h / 2, win.x, win.y, win.x - win.w / 3, win.y + win.h / 2)
                love.graphics.setColor(1, 1, 1)
            end
        end
        if c.cross then
            for _, lane in ipairs(c.lanes) do
                for _, car in ipairs(lane.cars) do
                    drawFit(car.image, car.x, car.y, CAR_W * lane.dir, CAR_H)
                end
            end
        end
        local d = c.door
        if d and d.delivered then
            drawFit(art.box, d.x + d.w, d.y + d.h * 0.6, PACKAGE_SIZE, PACKAGE_SIZE * art.box:getHeight() / art.box:getWidth())
            love.graphics.setColor(0, 0.8, 0)
            love.graphics.circle("fill", d.x + d.w / 2, d.y - 24, 14)
            love.graphics.setColor(1, 1, 1)
        end
        local m = c.mailbox
        if m then
            if m.down then
                drawFit(art.mailbox, m.x, m.y + m.h / 3, m.w, m.h, 1.4)
            else
                drawFit(art.mailbox, m.x, m.y, m.w, m.h)
                if m.delivered then
                    love.graphics.setColor(0, 0.8, 0)
                    love.graphics.circle("fill", m.x, m.y - m.h / 2 - 14, 10)
                end
            end
        end
        love.graphics.setColor(1, 1, 1)
        if c.dogHome then drawFit(dogImages.doghome, c.dogHome.x, c.dogHome.y, DOG_HOME_SIZE, DOG_HOME_SIZE) end
        if t > 0 then drawMarkers(c, 7 / z, t) end
    end
    for _, c in pairs(layout) do
        local d = c.dog
        if d then
            local frame = d.state == "bark" and "dogbark" or (d.state == "chase" or d.state == "home") and (math.floor(love.timer.getTime() * 10) % 2 == 0 and "dogrun1" or "dogrun2") or "dogsleep"
            drawFit(dogImages[frame], d.x, d.y, DOG_SIZE * d.dir, DOG_SIZE)
        end
    end

    for _, pk in ipairs(packages) do
        drawFit(art.box, pk.x, pk.y, PACKAGE_SIZE, PACKAGE_SIZE * art.box:getHeight() / art.box:getWidth())
    end
    love.graphics.setColor(1, 1, 1)

    if van.slowT and van.slowT > 0 then love.graphics.setColor(1, 0.55, 0.55) end
    if not van.gone then love.graphics.draw(van.image, van.x, van.y, van.angle, VAN_SCALE, VAN_SCALE, van.image:getWidth() / 2, van.image:getHeight() / 2) end

    love.graphics.origin()
    love.graphics.translate((w - CHUNK_W * scale) / 2, (h - CHUNK_H * scale) / 2)
    love.graphics.scale(scale)
    love.graphics.setShader(borderShader)
    borderShader:send("time", love.timer.getTime())
    love.graphics.draw(border, 0, 0, 0, CHUNK_W / border:getWidth(), CHUNK_H / border:getHeight())
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1)
    if state == "play" or state == "exit" then
        local label = "packages  " .. ammo
        local tw, th, pad, right, top = fonts.counter:getWidth(label), fonts.counter:getHeight(), 16, BORDER_RIGHT, BORDER_TOP
        love.graphics.setFont(fonts.counter)
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", right - tw - pad * 2, top, tw + pad * 2, th + pad)
        if ammo == 0 then love.graphics.setColor(0.9, 0.15, 0.15) else love.graphics.setColor(hue((love.timer.getTime() * 0.15) % 1)) end
        love.graphics.print(label, right - tw - pad, top + pad / 2)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.default)
    if state == "summary" then
        local st = levelStats()
        love.graphics.setFont(fonts.title)
        love.graphics.print("LEVEL " .. level .. " COMPLETE", 130, 200)
        love.graphics.setFont(fonts.body)
        local rows = {
            { "deliveries", string.format("%d / %d", st.housesDone, st.houses), st.housesDone * scoring.DELIVERY, { 0.2, 0.9, 0.3 } },
            { "broken windows", tostring(st.windows), -st.windows * scoring.WINDOW, { 0.95, 0.25, 0.25 } },
            { "mailboxes crushed", tostring(st.crushed), -st.crushed * scoring.MAILBOX, { 1, 0.6, 0.1 } },
            { "time bonus", nil, levelBonus, { 0.3, 0.8, 1 } },
        }
        for i, r in ipairs(rows) do
            local y = 290 + (i - 1) * 44
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(r[1], 130, y)
            if r[2] then love.graphics.printf(r[2], 400, y, 170, "right") end
            if i == 4 then
                for k = 1, 3 do drawStar(460 + (k - 1) * 45, y + 17, 18, k <= levelStars, r[4]) end
            end
            love.graphics.setColor(r[4])
            love.graphics.printf(string.format("%+d", r[3]), 590, y, 160, "right")
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", 130, 480, 620, 3)
        love.graphics.print("level score", 130, 495)
        love.graphics.printf(tostring(levelPoints), 590, 495, 160, "right")
        love.graphics.setFont(fonts.counter)
        love.graphics.setColor(hue((love.timer.getTime() * 0.15) % 1))
        love.graphics.print("TOTAL", 130, 555)
        love.graphics.printf(tostring(runTotal), 520, 555, 230, "right")
        love.graphics.setColor(hue((love.timer.getTime() * 0.15) % 1))
        love.graphics.setFont(fonts.title)
        love.graphics.printf("GRADE", 1100, 240, 700, "center")
        love.graphics.setFont(fonts.grade)
        love.graphics.printf(levelGrade, 1100, 290, 700, "center")
        love.graphics.setFont(fonts.body)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(level >= RUN_LEVELS and "space - enter name" or "space - next level", 130, 650)
        love.graphics.setFont(fonts.default)
    elseif state == "name" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, CHUNK_W, CHUNK_H)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonts.title)
        love.graphics.printf("RUN COMPLETE  " .. runTotal, 0, 220, CHUNK_W, "center")
        love.graphics.setFont(fonts.counter)
        local cell = 90
        local x0 = (CHUNK_W - cell * NAME_LEN) / 2
        for i = 1, NAME_LEN do
            if i == nameCursor then love.graphics.setColor(hue((love.timer.getTime() * 0.15) % 1)) else love.graphics.setColor(1, 1, 1) end
            love.graphics.printf(name[i], x0 + (i - 1) * cell, 440, cell, "center")
            if i == nameCursor then love.graphics.rectangle("fill", x0 + (i - 1) * cell + 15, 500, cell - 30, 6) end
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonts.body)
        love.graphics.printf("w/s letter - a/d move - space confirm", 0, 640, CHUNK_W, "center")
        love.graphics.setFont(fonts.default)
    elseif state == "board" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, CHUNK_W, CHUNK_H)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonts.title)
        love.graphics.printf("LEADERBOARD", 0, 130, CHUNK_W, "center")
        love.graphics.setFont(fonts.body)
        for i, e in ipairs(board) do
            if i == boardRank then love.graphics.setColor(hue((love.timer.getTime() * 0.15) % 1)) else love.graphics.setColor(1, 1, 1) end
            love.graphics.printf(string.format("%2d.  %s", i, e.name), 600, 230 + (i - 1) * 54, 400, "left")
            love.graphics.printf(tostring(e.score), 900, 230 + (i - 1) * 54, 300, "right")
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("space - new run", 0, 850, CHUNK_W, "center")
        love.graphics.setFont(fonts.default)
    end
    love.graphics.origin()
    love.graphics.setScissor()
end
