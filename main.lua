local world = require("src.world")
local assets = require("src.assets")
local game = require("src.game")
local audio = require("src.audio")
local view = require("src.view")
local scene = require("src.scene")
local pad = require("src.pad")
local input = require("src.input")
local idle = require("src.idle")

local idleState = idle.new(idle.TIMEOUT)
local MODAL = { name = true, intro = true, restart = true, attract = true }

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
    scene.go("attract")
end

function love.joystickadded() pad.refresh() end

function love.joystickremoved() pad.refresh() end

function love.gamepadpressed(_, button)
    idle.touch(idleState)
    if scene.id == "attract" then
        scene.go("intro")
        return
    end
    local key = input.button(button)
    if key then love.keypressed(key) end
end

function love.update(dt)
    for _, key in ipairs(pad.stickKeys()) do love.keypressed(key) end
    local throttle, steer = pad.drive()
    if throttle ~= 0 or steer ~= 0 then idle.touch(idleState) end
    if scene.id ~= "attract" and idle.tick(idleState, dt) then
        scene.prev = nil
        scene.go("attract")
    end
    scene.current.update(dt)
end

function love.keypressed(key)
    if not pad.connected() then idle.touch(idleState) end
    if key == "escape" then love.event.quit() end
    if key == "start" and not MODAL[scene.id] then
        scene.push("restart")
        return
    end
    if key == "r" and not MODAL[scene.id] then
        game.resetRun()
        scene.go("play")
        return
    end
    scene.current.keypressed(key)
end

function love.draw()
    view.frame(scene.current)
end
