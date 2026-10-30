local world = require("world")
local assets = require("assets")
local game = require("game")
local audio = require("audio")
local view = require("view")
local scene = require("scene")

function love.load()
    local loaded = assets.load()
    game.vanImage = loaded.van
    view.load(loaded)
    audio.load()
    world.init({ images = loaded.world, mask = loaded.mask, random = love.math.random })
    love.graphics.setBackgroundColor(0.75, 0.75, 0.75)
    game.resetRun()
    scene.go("play")
end

function love.update(dt)
    scene.current.update(dt)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" and scene.id ~= "name" then
        game.resetRun()
        scene.go("play")
        return
    end
    scene.current.keypressed(key)
end

function love.draw()
    view.frame(scene.current)
end
