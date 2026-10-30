local world = require("src.world")

local parcels = {
    SPEED = 650,
    LIFE = 2.2,
    SIZE = 72,
    COOLDOWN = 0.6,
}

local function inRect(px, py, left, top, right, bottom)
    return px >= left and px <= right and py >= top and py <= bottom
end

function parcels.new(v)
    return { x = v.x, y = v.y, vx = -parcels.SPEED, vy = -v.speed, life = parcels.LIFE }
end

function parcels.update(list, dt)
    local events = {}
    for i = #list, 1, -1 do
        local pk = list[i]
        pk.x = pk.x + pk.vx * dt
        pk.y = pk.y + pk.vy * dt
        pk.life = pk.life - dt
        local gone = pk.life <= 0
        local n = math.floor(-pk.y / world.CHUNK_H)
        if n >= 0 then
            local c = world.chunkAt(n)
            for _, w in ipairs(c.windows) do
                if not w.broken and inRect(pk.x, pk.y, w.left, w.y - w.h / 2, w.right, w.y + w.h / 2) then
                    w.broken = true
                    events[#events + 1] = "window"
                    gone = true
                end
            end
            local d = c.door
            if d and inRect(pk.x, pk.y, d.x, d.y, d.x + d.w, d.y + d.h) then
                d.delivered = true
                if not c.delivered then
                    c.delivered = true
                    events[#events + 1] = "door"
                end
                gone = true
            end
            local m = c.mailbox
            if m and not m.down and not m.delivered and world.circleHitsMailbox(m, pk.x, pk.y, parcels.SIZE / 2) then
                m.delivered = true
                if not c.delivered then
                    c.delivered = true
                    events[#events + 1] = "mailbox"
                end
                gone = true
            end
        end
        if gone then table.remove(list, i) end
    end
    return events
end

return parcels
