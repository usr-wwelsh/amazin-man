local intro = {}

function intro.slides(throw, move)
    return {
        { "YOUR GOAL" },
        { "DELIVER PACKAGES", "TO DOORS", "OR MAILBOXES" },
        { throw .. " TO THROW", move .. " TO MOVE" },
    }
end

intro.COUNT = 3

function intro.new()
    return { index = 1 }
end

function intro.done(s)
    return s.index > intro.COUNT
end

function intro.advance(s)
    if intro.done(s) then return end
    s.index = s.index + 1
end

return intro
