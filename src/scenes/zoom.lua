local game = require("src.game")
local audio = require("src.audio")
local scene = require("src.scene")

local zoom = { overview = true }

function zoom.enter()
    audio.levelEnd(game.early)
end

function zoom.update(dt)
    game.zoomT = math.min(1, game.zoomT + dt / game.ZOOM_TIME)
    if game.zoomT == 1 then scene.go("summary") end
end

function zoom.keypressed() end

function zoom.draw() end

return zoom
