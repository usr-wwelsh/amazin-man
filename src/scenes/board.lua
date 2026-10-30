local world = require("src.world")
local game = require("src.game")
local view = require("src.view")
local scene = require("src.scene")

local board = { overview = true }

function board.update() end

function board.keypressed(key)
    if key == "space" or key == "return" then
        game.resetRun()
        scene.go("play")
    end
end

function board.draw()
    local fonts = view.fonts
    local width, height = world.CHUNK_W, world.CHUNK_H
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.title)
    love.graphics.printf("LEADERBOARD", 0, 130, width, "center")
    love.graphics.setFont(fonts.body)
    for i, e in ipairs(game.board) do
        if i == game.boardRank then love.graphics.setColor(view.hue((love.timer.getTime() * 0.15) % 1)) else love.graphics.setColor(1, 1, 1) end
        love.graphics.printf(string.format("%2d.  %s", i, e.name), 600, 230 + (i - 1) * 54, 400, "left")
        love.graphics.printf(tostring(e.score), 900, 230 + (i - 1) * 54, 300, "right")
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("space - new run", 0, 850, width, "center")
    love.graphics.setFont(fonts.default)
end

return board
