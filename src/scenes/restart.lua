local world = require("src.world")
local game = require("src.game")
local prompt = require("src.prompt")
local view = require("src.view")
local scene = require("src.scene")

local restart = { overview = false }
local state

function restart.enter()
    state = prompt.new()
end

function restart.update() end

function restart.keypressed(key)
    local answer = prompt.key(state, key)
    if answer == "no" then
        scene.pop()
    elseif answer == "yes" then
        scene.prev = nil
        game.resetRun()
        scene.go("intro")
    end
end

function restart.draw()
    local width, height = world.CHUNK_W, world.CHUNK_H
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(view.fonts.title)
    love.graphics.printf("Restart?", 0, 380, width, "center")
    love.graphics.setFont(view.fonts.counter)
    local function choose(selected)
        if selected then love.graphics.setColor(view.hue((love.timer.getTime() * 0.15) % 1)) else love.graphics.setColor(1, 1, 1) end
    end
    choose(not state.yes)
    love.graphics.printf("no", width / 2 - 200, 520, 200, "center")
    choose(state.yes)
    love.graphics.printf("yes", width / 2, 520, 200, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(view.fonts.default)
end

return restart
