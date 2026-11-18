local prompt = dofile("src/prompt.lua")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

local s = prompt.new()
eq(s.yes, false, "prompt defaults to no")
eq(prompt.key(s, "space"), "no", "confirming the default answers no")

s = prompt.new()
eq(prompt.key(s, "right"), nil, "moving answers nothing")
eq(s.yes, true, "right selects yes")
eq(prompt.key(s, "space"), "yes", "confirming yes answers yes")

s = prompt.new()
prompt.key(s, "d")
eq(s.yes, true, "d selects yes")
prompt.key(s, "left")
eq(s.yes, false, "left selects no")
prompt.key(s, "a")
eq(s.yes, false, "a keeps no")

s = prompt.new()
prompt.key(s, "right")
eq(prompt.key(s, "start"), "no", "start cancels")
eq(prompt.key(s, "x"), nil, "other keys are ignored")
