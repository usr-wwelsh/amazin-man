local assets = {}

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

function assets.load()
    local a = { world = { chunks = {}, cars = {} }, dogs = {}, art = {}, fonts = {} }
    for i = 1, 4 do
        a.world.chunks[i] = love.graphics.newImage("assets/chunk" .. i .. ".png")
    end
    a.world.cross = love.graphics.newImage("assets/chunkCross.png")
    a.world.start = love.graphics.newImage("assets/chunk0.png")
    a.world.grass = love.graphics.newImage("assets/chunkG1.png")
    for i = 1, 4 do
        a.world.cars[i] = love.graphics.newImage(knockOutWhite("assets/car" .. i .. ".png"))
    end
    a.van = love.graphics.newImage("assets/van.png")
    for _, name in ipairs({ "dogsleep", "dogbark", "dogrun1", "dogrun2", "doghome" }) do
        a.dogs[name] = love.graphics.newImage(knockOutWhite("assets/" .. name .. ".png"))
    end
    for _, name in ipairs({ "window", "mailbox", "box" }) do
        a.art[name] = love.graphics.newImage("assets/" .. name .. ".png")
    end
    a.fonts.default = love.graphics.getFont()
    a.fonts.title = love.graphics.newFont(44)
    a.fonts.body = love.graphics.newFont(26)
    a.fonts.counter = love.graphics.newFont(40)
    a.fonts.grade = love.graphics.newFont(300)
    a.mask = love.image.newImageData("assets/chunk1.png")
    return a
end

return assets
