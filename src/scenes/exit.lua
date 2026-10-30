local world = require("src.world")
local game = require("src.game")
local van = require("src.van")
local audio = require("src.audio")
local view = require("src.view")
local scene = require("src.scene")

local exit = {}

function exit.enter()
    if not game.startExit() then audio.exitVoice() end
end

function exit.update(dt)
    local v = game.van
    world.updateCars(dt, math.floor(-v.y / world.CHUNK_H))
    local gone = van.exitUpdate(v, dt)
    audio.engine(v)
    if gone then
        game.finishLevel(not game.exitComplete)
        scene.go("zoom")
    end
end

function exit.keypressed() end

function exit.draw()
    view.counter()
end

return exit
