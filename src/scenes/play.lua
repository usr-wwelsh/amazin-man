local world = require("src.world")
local game = require("src.game")
local van = require("src.van")
local parcels = require("src.parcels")
local audio = require("src.audio")
local view = require("src.view")
local scene = require("src.scene")

local play = {}

local function finish(early)
    game.finishLevel(early)
    scene.go("zoom")
end

function play.enter()
    audio.levelStart()
end

function play.update(dt)
    if game.startDelay > 0 then
        game.startDelay = game.startDelay - dt
        return
    end
    local v = game.van
    game.elapsed = game.elapsed + dt
    game.cooldown = math.max(0, game.cooldown - dt)
    world.updateCars(dt, math.floor(-v.y / world.CHUNK_H))
    local down = love.keyboard.isDown
    local throttle = down("up", "w") and 1 or down("down", "s") and -1 or 0
    local steer = (down("right", "d") and 1 or 0) - (down("left", "a") and 1 or 0)
    local crash = van.update(v, dt, throttle, steer)
    if crash then
        audio.event(crash)
        finish(true)
        return
    end
    audio.engine(v)

    for _ = 1, world.crush(v.x, v.y) do
        audio.event("crush")
        game.score.mailboxes = game.score.mailboxes + 1
    end

    for _, event in ipairs(world.updateDogs(dt, v.x, v.y, world.provokes(v.x, v.y))) do
        if event == "bark" then audio.event("bark") end
        if event == "bite" then game.bite() end
    end

    for _, event in ipairs(parcels.update(game.packages, dt)) do
        audio.event(event)
        if event == "window" then
            game.score.windows = game.score.windows + 1
        else
            game.score.delivered = game.score.delivered + 1
        end
    end

    if v.y <= -game.levelLen * world.CHUNK_H then
        finish(false)
    elseif game.ammo == 0 and #game.packages == 0 then
        scene.go("exit")
    end
end

function play.keypressed(key)
    if key == "space" then game.throw() end
end

function play.draw()
    view.counter()
end

return play
