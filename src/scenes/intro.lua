local world = require("src.world")
local game = require("src.game")
local introState = require("src.intro")
local view = require("src.view")
local scene = require("src.scene")
local pad = require("src.pad")
local audio = require("src.audio")

local intro = { overview = false }
local state

local function finish()
    game.resetRun()
    scene.go("play")
end

function intro.enter()
    state = introState.new()
    audio.resume()
end

function intro.update() end

function intro.keypressed(key)
    if key ~= "space" and key ~= "return" then return end
    introState.advance(state)
    if introState.done(state) then finish() end
end

function intro.draw()
    local width, height = world.CHUNK_W, world.CHUNK_H
    love.graphics.setColor(0, 0, 0, 0.92)
    love.graphics.rectangle("fill", 0, 0, width, height)
    local lines = introState.slides(pad.label("throw"), pad.label("move"))[state.index]
    local font = view.fonts.huge
    local lineH = font:getHeight()
    local y = (height - lineH * #lines) / 2
    love.graphics.setFont(font)
    love.graphics.setColor(view.hue((love.timer.getTime() * 0.15) % 1))
    for i, line in ipairs(lines) do
        love.graphics.printf(line, 0, y + (i - 1) * lineH, width, "center")
    end
    local pulse = 0.35 + 0.35 * math.sin(love.timer.getTime() * 4)
    love.graphics.setColor(1, 1, 1, pulse)
    love.graphics.setFont(view.fonts.counter)
    love.graphics.printf("press " .. string.lower(pad.label("throw")), 0, y + #lines * lineH + 30, width, "center")
    love.graphics.setFont(view.fonts.default)
    love.graphics.setColor(1, 1, 1)
end

return intro
