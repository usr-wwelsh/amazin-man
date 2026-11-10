local world = require("src.world")
local assets = require("src.assets")
local game = require("src.game")
local audio = require("src.audio")
local view = require("src.view")
local scene = require("src.scene")
local pad = require("src.pad")
local input = require("src.input")

function love.load()
    local loaded = assets.load()
    game.vanImage = loaded.van
    game.oilVanImage = loaded.oilVan
    view.load(loaded)
    audio.load()
    world.init({ images = loaded.world, mask = loaded.mask, random = love.math.random })
    love.graphics.setBackgroundColor(0.75, 0.75, 0.75)
    game.resetRun()
    love.mouse.setVisible(false)
    pad.refresh()
    scene.go("intro")
end

function love.joystickadded() pad.refresh() end

function love.joystickremoved() pad.refresh() end

function love.gamepadpressed(_, button)
    local key = input.button(button)
    if key then love.keypressed(key) end
end

function love.update(dt)
    for _, key in ipairs(pad.stickKeys()) do love.keypressed(key) end
    scene.current.update(dt)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" and scene.id ~= "name" and scene.id ~= "intro" then
        game.resetRun()
        scene.go("play")
        return
    end
    scene.current.keypressed(key)
end

function love.draw()
    view.frame(scene.current)
end
