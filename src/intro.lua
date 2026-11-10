local intro = {}

intro.SLIDES = {
    { "YOUR GOAL" },
    { "DELIVER PACKAGES", "TO DOORS", "OR MAILBOXES" },
    { "SPACE TO THROW", "WASD TO MOVE" },
}

function intro.new()
    return { index = 1 }
end

function intro.done(s)
    return s.index > #intro.SLIDES
end

function intro.advance(s)
    if intro.done(s) then return end
    s.index = s.index + 1
end

return intro
