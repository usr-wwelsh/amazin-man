local dog = dofile("dog.lua")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

local function fresh()
    return dog.new(1000, 0, 900, 0)
end

local function step(d, secs, vx, vy, provoked)
    local event
    for _ = 1, math.floor(secs * 60 + 0.5) do
        event = dog.update(d, 1 / 60, vx, vy, provoked) or event
    end
    return event
end

local d = fresh()
step(d, 5, 1000 + dog.BARK_RANGE + 50, 0)
eq(d.state, "sleep", "sleeps while van is far")

step(d, 0.1, 1000 + dog.BARK_RANGE - 10, 0)
eq(d.state, "bark", "barks when van enters range")
eq(dog.update(fresh(), 1 / 60, 1000 + dog.BARK_RANGE - 10, 0), "bark", "announces the start of a bark")
eq(step(d, 0.5, 1000 + dog.BARK_RANGE - 10, 0), nil, "announces the bark only once")

d = fresh()
step(d, 0.1, 1000 + dog.BARK_RANGE - 10, 0)
step(d, 0.1, 1000 + dog.CHASE_RANGE - 10, 0, true)
eq(d.state, "bark", "warns before chasing")

d = fresh()
step(d, dog.BARK_TIME + 0.1, 1000 + dog.CHASE_RANGE - 10, 0, true)
eq(d.state, "chase", "chases once warned and van is close")

d = fresh()
step(d, dog.BARK_TIME + 1, 1000 + dog.CHASE_RANGE - 10, 0, false)
eq(d.state, "bark", "keeps barking but never chases an unprovoking van")

d = fresh()
step(d, dog.BARK_TIME + 1, 1000 + dog.CHASE_RANGE + 10, 0, true)
eq(d.state, "bark", "does not chase a provoking van beyond chase range")

d = fresh()
step(d, 1 / 60, 1000 + dog.CHASE_RANGE - 10, 0, true)
step(d, dog.BARK_TIME + 0.1, 1000 + dog.BARK_RANGE + 500, 0, false)
eq(d.state, "chase", "provoking the dog commits it to the chase even if the van speeds away")

d = fresh()
step(d, 0.1, 1000 + dog.BARK_RANGE - 10, 0)
step(d, 0.1, 1000 + dog.BARK_RANGE + 50, 0)
eq(d.state, "sleep", "goes back to sleep when van leaves")

d = fresh()
step(d, dog.BARK_TIME + 0.1, 1000 + dog.CHASE_RANGE - 10, 0, true)
local x0 = d.x
step(d, 0.2, 1000 + dog.CHASE_RANGE - 10, 0, true)
eq(d.x > x0, true, "chasing dog closes on the van")

d = fresh()
step(d, dog.BARK_TIME + 0.1, 1000 + dog.CHASE_RANGE - 10, 0, true)
local bite
repeat bite = dog.update(d, 1 / 60, 1000 + dog.CHASE_RANGE - 10, 0, true) until bite or d.timer > dog.CHASE_TIME
eq(bite, "bite", "dog catches a stationary van")
eq(d.state, "home", "dog heads home after biting")

d = fresh()
step(d, dog.BARK_TIME + 0.1, 1000 + dog.CHASE_RANGE - 10, 0, true)
local fleeing = 1000 + dog.CHASE_RANGE - 10
local event
for _ = 1, math.floor((dog.CHASE_TIME + 0.5) * 60) do
    fleeing = fleeing + dog.SPEED / 60 * 1.5
    event = dog.update(d, 1 / 60, fleeing, 0, true) or event
end
eq(event, nil, "no bite on a van that outruns the dog")
eq(d.state == "home" or d.state == "done", true, "dog gives up the chase")

d = fresh()
step(d, dog.BARK_TIME + 0.1, 1000 + dog.CHASE_RANGE - 10, 0, true)
step(d, dog.CHASE_TIME + 0.1, 5000, 0)
step(d, 10, 5000, 0)
eq(d.state, "done", "dog sleeps again once home")
eq(d.x, d.homeX, "dog rests at home")

step(d, 1, 1000, 0)
eq(d.state, "done", "a retired dog stays asleep")

print("ok")
