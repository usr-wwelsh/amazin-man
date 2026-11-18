local attract = {}

local W, H = 32, 64
local FPS = 30
local PERIOD = 10
local SPEED = { 0.2, 1, 1.5 }

local PALETTES = {
    { 0x03045E, 0x0077B6, 0x00B4D8, 0x48CAE4, 0x90E0EF, 0xCAF0F8 },
    { 0x1A0500, 0x4A0E0E, 0xB71C1C, 0xFF3D00, 0xFF9100, 0xFFEA00 },
    { 0x0D0221, 0x261447, 0x631879, 0xB41396, 0xFF0054, 0xFF9E00 },
    { 0x001100, 0x003300, 0x006600, 0x00CC00, 0x66FF66, 0xFFFFFF },
    { 0x000000, 0x333333, 0x666666, 0x999999, 0xCCCCCC, 0xFFFFFF },
}

local BLACK = { 0, 0, 0 }

local function rgb(hex)
    return { math.floor(hex / 65536) / 255, math.floor(hex / 256) % 256 / 255, hex % 256 / 255 }
end

local function finite(...)
    for _, v in ipairs({ ... }) do
        if v ~= v or v == math.huge or v == -math.huge then return false end
    end
    return true
end

local function trunc(v)
    return v < 0 and math.ceil(v) or math.floor(v)
end

local function roll(seed, palette)
    local rng = love.math.newRandomGenerator(seed)
    local colors = PALETTES[palette % #PALETTES + 1]
    local function pick() return rgb(colors[rng:random(#colors)]) end
    local s = { seed = seed, ball = pick(), size = rng:random(4, 10) }
    for i = 1, 6 do s[i] = pick() end
    s.velX, s.velY = 0.4 + rng:random() * 0.6, 0.3 + rng:random() * 0.5
    return s
end

local function stroke(color, width)
    love.graphics.setColor(color)
    love.graphics.setLineWidth(width)
end

local function triangle(fill, edge, ...)
    love.graphics.setColor(fill)
    love.graphics.polygon("fill", ...)
    love.graphics.setColor(edge)
    love.graphics.polygon("line", ...)
end

local function draw1(s, frame)
    local t, seed = frame / 60, s.seed
    local x = W / 2 + math.cos(t) * 4 * 400 * seed + seed
    local y = H / 3 + math.sin(t * 1.8) / 2 * 100 * seed + seed
    local x2 = W / 8 + math.sin(t) * 400 * seed + seed
    local y2 = H / 4 + math.cos(t * 1.8) * seed + seed
    stroke(s[1], 20)
    love.graphics.line(x, y / 2, W - x2, H - y)
    stroke(s[2], 60)
    love.graphics.line(W + x, H + y2, x, y2)
    stroke(s[3], 80)
    love.graphics.line(x, y2, W, H)
    stroke(s[4], 60)
    love.graphics.line(seed * 4, seed * 4, x, y / 2)
    stroke(s[5], 50)
    love.graphics.line(0, 0, W - x, H - y2)
    love.graphics.setLineWidth(5)
    love.graphics.setColor(s[6])
    if finite(x, y) then love.graphics.ellipse("fill", W - x2, H - x2, math.abs(x) / 2, math.abs(y) / 2) end
    triangle(s[1], s[2], x, y / 2, W - x, H - y2, 0, 0)
    triangle(s[3], s[2], W * x2, H * y, x, y2, W, H)
    love.graphics.setColor(s.ball)
    love.graphics.circle("fill", x + s.velX, y + s.velY, s.size / 2)
end

local function draw2(s, frame)
    local t, seed = frame / 60, s.seed
    local x = W / 2 + math.cos(t) * 4
    local y = H / 3 + math.sin(t * 1.8) / 2
    local x2 = W / 8 + math.sin(t)
    local y2 = H / 4 + math.cos(t * 1.8)
    local x3 = W + math.cos(t * 4)
    local y3 = H + math.cos(t * 3)
    local x4 = W / math.tan(t * 0.5)
    local y4 = H / 2 / math.tan(t * 0.25)
    local angle = math.rad(seed + x + y + math.floor(frame / 4))
    love.graphics.setLineWidth(1)
    for x5 = 0, W - 1, 10 do
        for y5 = 0, H - 1, 10 do
            local px = x5 + trunc(math.cos(angle) * 50)
            local py = x5 + trunc(math.sin(angle) * 50)
            love.graphics.setColor(s[2])
            love.graphics.line(x5, y5, px, px)
            love.graphics.setColor(BLACK)
            love.graphics.line(x5, y5, py, py)
        end
    end
    if finite(x, y, x2, y2, W / t, H / t) then
        local curve = love.math.newBezierCurve(W / 2, H / 2, x, y, x2, y2, W / t, H / t)
        local second = love.math.newBezierCurve(W / t, H / t, x2, x, (seed % 12) * x, (seed % 9) * y, x3, y3)
        local pts = curve:render()
        for i = 3, #second:render() do pts[#pts + 1] = second:render()[i] end
        love.graphics.setColor(s[3])
        local ok, tris = pcall(love.math.triangulate, pts)
        if ok then
            for _, tri in ipairs(tris) do love.graphics.polygon("fill", tri) end
        end
    end
    if finite(x4, y4) then
        stroke(s[6], 1)
        love.graphics.line(0, 0, W - x4, H - y4)
    end
end

local function draw3(s, frame)
    local angle = math.rad(s.seed + math.floor(frame / 6))
    love.graphics.setLineWidth(1)
    for x = 0, W - 1, 2 do
        for y = 0, H - 1, 2 do
            local a = angle + math.rad(x + y)
            local px = x + trunc(math.cos(a) * 50)
            local py = x + trunc(math.sin(a) * 50)
            love.graphics.setColor(s[2])
            love.graphics.rectangle("fill", x, y, px, px)
            love.graphics.setColor(s[1])
            love.graphics.rectangle("line", x, y, px, px)
            love.graphics.setColor(BLACK)
            love.graphics.rectangle("fill", x, y, py, py)
            love.graphics.setColor(s[1])
            love.graphics.rectangle("line", x, y, py, py)
        end
    end
end

local DRAW = { draw1, draw2, draw3 }

function attract.new()
    local a = { time = 0, round = -1 }
    for i = 1, 3 do
        a[i] = { canvas = love.graphics.newCanvas(W, H) }
        a[i].canvas:setFilter("nearest", "nearest")
    end
    return a
end

local function reroll(a, round)
    a.round = round
    for i = 1, 3 do
        a[i].state = roll(3 * (round % 8) + i + 2, round)
    end
end

function attract.update(a, dt)
    a.time = a.time + dt
    local round = math.floor(a.time / PERIOD)
    if round ~= a.round then reroll(a, round) end
end

function attract.draw(a, width, height)
    local rowH = height / 3
    local lineStyle = love.graphics.getLineStyle()
    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setScissor()
    love.graphics.setLineStyle("rough")
    for i = 1, 3 do
        love.graphics.setCanvas(a[i].canvas)
        love.graphics.clear(0, 0, 0, 1)
        DRAW[i](a[i].state, a.time * FPS * SPEED[i])
        love.graphics.setCanvas()
    end
    love.graphics.setLineStyle(lineStyle)
    love.graphics.setLineWidth(1)
    love.graphics.pop()
    love.graphics.setScissor(sx, sy, sw, sh)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(1, 1, 1)
    for i = 1, 3 do
        love.graphics.draw(a[i].canvas, 0, (4 - i) * rowH, -math.pi / 2, rowH / W, width / H)
    end
end

return attract
