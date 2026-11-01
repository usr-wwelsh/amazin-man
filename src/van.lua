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
    SLIP_TIME = 0.6,
    OIL_SPEED = 60,
    OIL_CRAWL_TIME = 1.5,
    STAIN_FADE = 2,
    SPIN_TIME = 1.2,
    SPIN = 2 * math.pi,
}

function van.new(image, oilImage)
    return { x = 1550 + DRIFT * van.START_Y / CHUNK_H, y = -van.START_Y, speed = van.MIN_SPEED, angle = 0, slowT = 0, oilImage = oilImage, slipT = 0, crawlT = 0, stain = 0, spinT = 0, spin = 0, slipSteer = 0, image = image }
end

function van.update(v, dt, throttle, steer)
    v.slowT = math.max(0, v.slowT - dt)
    local spill = world.oilAt(v.x, v.y)
    if spill then
        if v.slipT <= 0 then
            v.spinT = van.SPIN_TIME
            v.crawlT = 0
            v.slipSteer = steer ~= 0 and steer or (v.x >= spill.x and 1 or -1)
        end
        v.slipT = van.SLIP_TIME
        v.stain = 1
    else
        local sliding = v.slipT > 0
        v.slipT = math.max(0, v.slipT - dt)
        if sliding and v.slipT <= 0 then v.crawlT = van.OIL_CRAWL_TIME end
    end
    if v.slipT > 0 then steer = v.slipSteer end
    if v.spinT > 0 then
        v.spinT = math.max(0, v.spinT - dt)
        v.spin = v.spinT > 0 and van.SPIN * (1 - v.spinT / van.SPIN_TIME) or 0
    end
    if throttle > 0 then
        v.speed = math.min(van.MAX_SPEED, v.speed + van.ACCEL * dt)
    elseif throttle < 0 then
        v.speed = math.max(van.MIN_SPEED, v.speed - van.BRAKE * dt)
    else
        v.speed = math.max(van.MIN_SPEED, v.speed - van.ACCEL * 0.3 * dt)
    end
    if v.slowT > 0 then v.speed = math.min(v.speed, van.SLOW_SPEED) end
    if v.crawlT > 0 then
        v.crawlT = math.max(0, v.crawlT - dt)
        v.speed = math.min(v.speed, van.OIL_SPEED)
    elseif v.slipT <= 0 then
        v.stain = math.max(0, v.stain - dt / van.STAIN_FADE)
    end
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
