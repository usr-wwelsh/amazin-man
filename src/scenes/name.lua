local world = require("src.world")
local scoring = require("src.scoring")
local game = require("src.game")
local leaderboard = require("src.leaderboard")
local view = require("src.view")
local scene = require("src.scene")

local name = { overview = true }

function name.update() end

function name.keypressed(key)
    local letters = game.letters
    if key == "w" or key == "up" then letters[game.cursor] = scoring.cycle(letters[game.cursor], -1) end
    if key == "s" or key == "down" then letters[game.cursor] = scoring.cycle(letters[game.cursor], 1) end
    if key == "a" or key == "left" then game.cursor = math.max(1, game.cursor - 1) end
    if key == "d" or key == "right" then game.cursor = math.min(game.NAME_LEN, game.cursor + 1) end
    if key == "return" or key == "space" then
        game.board = leaderboard.load()
        game.recordScore(table.concat(letters))
        leaderboard.save(game.board)
        scene.go("board")
    end
end

function name.draw()
    local fonts = view.fonts
    local width, height = world.CHUNK_W, world.CHUNK_H
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.title)
    love.graphics.printf("RUN COMPLETE  " .. game.runTotal, 0, 220, width, "center")
    love.graphics.setFont(fonts.counter)
    local cell = 90
    local x0 = (width - cell * game.NAME_LEN) / 2
    for i = 1, game.NAME_LEN do
        if i == game.cursor then love.graphics.setColor(view.hue((love.timer.getTime() * 0.15) % 1)) else love.graphics.setColor(1, 1, 1) end
        love.graphics.printf(game.letters[i], x0 + (i - 1) * cell, 440, cell, "center")
        if i == game.cursor then love.graphics.rectangle("fill", x0 + (i - 1) * cell + 15, 500, cell - 30, 6) end
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.body)
    love.graphics.printf("w/s letter - a/d move - space confirm", 0, 640, width, "center")
    love.graphics.setFont(fonts.default)
end

return name
