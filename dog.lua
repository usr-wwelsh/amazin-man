local dog = {
    BARK_RANGE = 2200,
    CHASE_RANGE = 1500,
    BARK_TIME = 0.6,
    CHASE_TIME = 8,
    SPEED = 450,
    BITE_RANGE = 120,
}

function dog.new(x, y, homeX, homeY)
    return { x = x, y = y, homeX = homeX or x, homeY = homeY or y, state = "sleep", timer = 0, dir = 1 }
end

local function distance(d, vx, vy)
    return math.sqrt((vx - d.x) ^ 2 + (vy - d.y) ^ 2)
end

local function moveToward(d, tx, ty, dt)
    local dx, dy = tx - d.x, ty - d.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return 0 end
    local step = math.min(dist, dog.SPEED * dt)
    d.x = d.x + dx / dist * step
    d.y = d.y + dy / dist * step
    if dx ~= 0 then d.dir = dx > 0 and 1 or -1 end
    return dist - step
end

function dog.update(d, dt, vx, vy, provoked)
    local dist = distance(d, vx, vy)
    if (d.state == "sleep" or d.state == "bark") and provoked and dist <= dog.CHASE_RANGE then d.alerted = true end
    if d.state == "sleep" then
        if dist <= dog.BARK_RANGE then
            d.state = "bark"
            d.timer = 0
            return "bark"
        end
    elseif d.state == "bark" then
        d.timer = d.timer + dt
        if d.alerted then
            if d.timer >= dog.BARK_TIME then
                d.state = "chase"
                d.timer = 0
            end
        elseif dist > dog.BARK_RANGE then
            d.state = "sleep"
        end
    elseif d.state == "chase" then
        d.timer = d.timer + dt
        moveToward(d, vx, vy, dt)
        if distance(d, vx, vy) <= dog.BITE_RANGE then
            d.state = "home"
            return "bite"
        end
        if d.timer >= dog.CHASE_TIME then d.state = "home" end
    elseif d.state == "home" then
        if moveToward(d, d.homeX, d.homeY, dt) == 0 then
            d.state = "done"
            d.dir = 1
        end
    end
end

return dog
