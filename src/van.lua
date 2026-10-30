local world = require("src.world")
local camera = require("src.camera")

local CHUNK_H, DRIFT = world.CHUNK_H, world.DRIFT

local van = {
    MAX_SPEED = 480,
    MIN_SPEED = 160,
    ACCEL = 320,
    BRAKE = 600,
    STEER = 340,
    MAX_TILT = 0.35,
    TILT_RATE = 8,
    MARGIN = 160,
    EXIT_SPEED = 700,
    SLOW_TIME = 2.5,
    SLOW_SPEED = 256,
    START_Y = 540,
}

function van.new(image)
    return { x = 1550 + DRIFT * van.START_Y / CHUNK_H, y = -van.START_Y, speed = van.MIN_SPEED, angle = 0, slowT = 0, image = image }
end

function van.update(v, dt, throttle, steer)
    v.slowT = math.max(0, v.slowT - dt)
    if throttle > 0 then
        v.speed = math.min(van.MAX_SPEED, v.speed + van.ACCEL * dt)
    elseif throttle < 0 then
        v.speed = math.max(van.MIN_SPEED, v.speed - van.BRAKE * dt)
    else
        v.speed = math.max(van.MIN_SPEED, v.speed - van.ACCEL * 0.3 * dt)
    end
    if v.slowT > 0 then v.speed = math.min(v.speed, van.SLOW_SPEED) end
    v.angle = v.angle + (steer * van.MAX_TILT - v.angle) * math.min(1, van.TILT_RATE * dt)
    local nx = v.x + steer * van.STEER * dt + DRIFT * v.speed * dt / CHUNK_H
    local ny = v.y - v.speed * dt
    local cx = camera.x(ny)
    nx = math.max(cx + van.MARGIN, math.min(cx + camera.VIEW_W - van.MARGIN, nx))
    local hitX = world.carHit(nx, v.y)
    local blockedX, houseX = world.vanBlocked(nx, v.y)
    if not blockedX and not hitX then v.x = nx end
    local hitY = world.carHit(v.x, ny)
    local blockedY, houseY = world.vanBlocked(v.x, ny)
    if hitX or hitY then return "car" end
    if houseX or houseY then return "house" end
    if blockedY then
        v.speed = van.MIN_SPEED
    else
        v.y = ny
    end
end

function van.exitUpdate(v, dt)
    v.angle = v.angle + (van.MAX_TILT - v.angle) * math.min(1, van.TILT_RATE * dt)
    v.x = v.x + van.EXIT_SPEED * dt + DRIFT * v.speed * dt / CHUNK_H
    v.y = v.y - v.speed * dt
    if v.x > camera.x(v.y) + camera.VIEW_W + world.VAN_RADIUS * 2 then
        v.gone = true
        return true
    end
    return false
end

function van.pitch(v)
    return 0.6 + 0.8 * v.speed / van.MAX_SPEED
end

return van
