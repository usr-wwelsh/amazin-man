local world = require("src.world")
local camera = require("src.camera")
local game = require("src.game")
local parcels = require("src.parcels")

local CHUNK_W, CHUNK_H, DRIFT, EDGE, CAR_W, CAR_H = world.CHUNK_W, world.CHUNK_H, world.DRIFT, world.EDGE, world.CAR_W, world.CAR_H
local VAN_SCALE = 3.5
local DOG_SIZE, DOG_HOME_SIZE = 200, 240
local BORDER_TOP, BORDER_RIGHT = 90, 1823

local view = {}
local edgeQuad, dogImages, art, fonts, border, borderShader

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

local function drawFit(img, cx, cy, w, h, rotation)
    love.graphics.draw(img, cx, cy, rotation or 0, w / img:getWidth(), h / img:getHeight(), img:getWidth() / 2, img:getHeight() / 2)
end

function view.hue(h)
    local function ch(o)
        return math.max(0, math.min(1, math.abs((h * 6 + o) % 6 - 3) - 1))
    end
    return ch(0), ch(4), ch(2)
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

function view.drawStar(cx, cy, r, filled, color)
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

local function drawChunk(n, t, z)
    love.graphics.setColor(1, 1, 1)
    local c = world.chunkAt(n)
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
        drawFit(art.box, d.x + d.w, d.y + d.h * 0.6, parcels.SIZE, parcels.SIZE * art.box:getHeight() / art.box:getWidth())
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

local function drawDogs()
    for _, c in pairs(world.layout()) do
        local d = c.dog
        if d then
            local frame = d.state == "bark" and "dogbark" or (d.state == "chase" or d.state == "home") and (math.floor(love.timer.getTime() * 10) % 2 == 0 and "dogrun1" or "dogrun2") or "dogsleep"
            drawFit(dogImages[frame], d.x, d.y, DOG_SIZE * d.dir, DOG_SIZE)
        end
    end
end

local function drawPackages()
    for _, pk in ipairs(game.packages) do
        drawFit(art.box, pk.x, pk.y, parcels.SIZE, parcels.SIZE * art.box:getHeight() / art.box:getWidth())
    end
    love.graphics.setColor(1, 1, 1)
end

local function drawVan()
    local van = game.van
    if van.slowT and van.slowT > 0 then love.graphics.setColor(1, 0.55, 0.55) end
    if not van.gone then love.graphics.draw(van.image, van.x, van.y, van.angle, VAN_SCALE, VAN_SCALE, van.image:getWidth() / 2, van.image:getHeight() / 2) end
end

local function drawBorder()
    love.graphics.setShader(borderShader)
    borderShader:send("time", love.timer.getTime())
    love.graphics.draw(border, 0, 0, 0, CHUNK_W / border:getWidth(), CHUNK_H / border:getHeight())
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1)
end

function view.counter()
    local label = "packages  " .. game.ammo
    local tw, th, pad, right, top = fonts.counter:getWidth(label), fonts.counter:getHeight(), 16, BORDER_RIGHT, BORDER_TOP
    love.graphics.setFont(fonts.counter)
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", right - tw - pad * 2, top, tw + pad * 2, th + pad)
    if game.ammo == 0 then love.graphics.setColor(0.9, 0.15, 0.15) else love.graphics.setColor(view.hue((love.timer.getTime() * 0.15) % 1)) end
    love.graphics.print(label, right - tw - pad, top + pad / 2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.default)
end

function view.load(loaded)
    dogImages, art, fonts = loaded.dogs, loaded.art, loaded.fonts
    view.fonts = fonts
    edgeQuad = love.graphics.newQuad(-EDGE, 0, CHUNK_W + EDGE, CHUNK_H, CHUNK_W, CHUNK_H)
    border = love.graphics.newImage("assets/img/border.png")
    borderShader = love.graphics.newShader(BORDER_SHADER)
    borderShader:send("size", { border:getWidth(), border:getHeight() })
end

function view.frame(scene)
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / CHUNK_W, h / CHUNK_H)
    love.graphics.translate((w - CHUNK_W * scale) / 2, (h - CHUNK_H * scale) / 2)
    love.graphics.scale(scale)
    love.graphics.setScissor((w - CHUNK_W * scale) / 2, (h - CHUNK_H * scale) / 2, CHUNK_W * scale, CHUNK_H * scale)

    local z, camX, camY, t = camera.view(game.van.y, game.levelLen, scene.overview and game.zoomT or nil)
    love.graphics.scale(z)
    love.graphics.translate(-camX, -camY)
    if t > 0 then
        love.graphics.setColor(0.08, 0.08, 0.1, t)
        love.graphics.rectangle("fill", camX, camY, CHUNK_W / z, CHUNK_H / z)
    end

    local first = math.max(0, math.floor(-(camY + CHUNK_H / z) / CHUNK_H))
    for n = first, math.min(game.levelLen - 1, math.floor(-camY / CHUNK_H)) do
        drawChunk(n, t, z)
    end
    drawDogs()
    drawPackages()
    drawVan()

    love.graphics.origin()
    love.graphics.translate((w - CHUNK_W * scale) / 2, (h - CHUNK_H * scale) / 2)
    love.graphics.scale(scale)
    drawBorder()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.default)
    scene.draw()
    love.graphics.origin()
    love.graphics.setScissor()
end

return view
