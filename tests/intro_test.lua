local intro = dofile("src/intro.lua")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

local s = intro.new()
eq(s.index, 1, "starts on first slide")
eq(intro.done(s), false, "not done at start")

intro.advance(s)
eq(s.index, 2, "advance moves to next slide")

intro.advance(s)
eq(s.index, 3, "advance moves to last slide")
eq(intro.done(s), false, "last slide waits for input")

intro.advance(s)
eq(intro.done(s), true, "advancing past last slide finishes")
intro.advance(s)
eq(s.index, #intro.SLIDES + 1, "finished state is stable")
