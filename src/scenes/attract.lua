local world = require("src.world")
local game = require("src.game")
local view = require("src.view")
local scene = require("src.scene")
local pad = require("src.pad")
local audio = require("src.audio")
local art = require("src.attract")

local attract = { overview = false }
local state

local OFFSETS = { { -6, 0 }, { 6, 0 }, { 0, -6 }, { 0, 6 }, { -4, -4 }, { 4, -4 }, { -4, 4 }, { 4, 4 } }

function attract.enter()
    state = state or art.new()
    game.resetRun()
    audio.silence()
end

function attract.update(dt)
    art.update(state, dt)
end

function attract.keypressed()
    if pad.connected() then return end
    scene.go("intro")
end

function attract.draw()
    local width, height = world.CHUNK_W, world.CHUNK_H
    art.draw(state, width, height)
    local font = view.fonts.attract
    local y = (height - font:getHeight()) / 2
    love.graphics.setFont(font)
    love.graphics.setColor(0, 0, 0)
    for _, o in ipairs(OFFSETS) do
        love.graphics.printf("AMAZIN MAN", o[1], y + o[2], width, "center")
    end
    love.graphics.setColor(view.hue((love.timer.getTime() * 0.15) % 1))
    love.graphics.printf("AMAZIN MAN", 0, y, width, "center")
    local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 4)
    love.graphics.setFont(view.fonts.counter)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", width / 2 - 260, height - 150, 520, 70)
    love.graphics.setColor(1, 1, 1, 0.4 + 0.6 * pulse)
    love.graphics.printf("press " .. string.lower(pad.label("throw")), 0, height - 140, width, "center")
    love.graphics.setFont(view.fonts.default)
    love.graphics.setColor(1, 1, 1)
end

return attract
