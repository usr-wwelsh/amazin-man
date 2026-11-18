local idle = { TIMEOUT = 180 }

function idle.new(limit)
    return { limit = limit, elapsed = 0 }
end

function idle.touch(s)
    s.elapsed = 0
end

function idle.tick(s, dt)
    s.elapsed = s.elapsed + dt
    return s.elapsed >= s.limit
end

return idle
