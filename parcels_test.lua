local world = require("world")
local parcels = require("parcels")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

local function setup()
    world.init({
        random = function(a) return a or 0 end,
        mask = { getPixel = function() return 0, 1, 0 end },
        images = { chunks = { "house" }, cross = "cross", start = "start", grass = "grass", cars = { "car" } },
    })
    world.reset(1, 10)
end

local function parcel(x, y)
    return { x = x, y = y, vx = 0, vy = 0, life = 1 }
end

setup()
local thrown = parcels.new({ x = 5, y = -7, speed = 300 })
eq(thrown.x, 5, "parcel starts at the van x")
eq(thrown.vx, -parcels.SPEED, "parcel flies toward the houses")
eq(thrown.vy, -300, "parcel keeps the van's forward speed")
eq(thrown.life, parcels.LIFE, "parcel starts with full life")

local list = { { x = 0, y = -100, vx = 100, vy = -50, life = 1 } }
eq(#parcels.update(list, 0.5), 0, "flying parcel in the open makes no events")
eq(list[1].x, 50, "parcel moves by velocity")
eq(list[1].y, -125, "parcel moves forward")
parcels.update(list, 0.6)
eq(#list, 0, "parcels expire")

local chunk = world.chunkAt(1)
local window = chunk.windows[1]
list = { parcel(window.x, window.y) }
local events = parcels.update(list, 0.001)
eq(events[1], "window", "parcel breaks a window")
eq(window.broken, true, "window is marked broken")
eq(#list, 0, "parcel is spent on a window")

local door = chunk.door
list = { parcel(door.x + 10, door.y + 10) }
events = parcels.update(list, 0.001)
eq(events[1], "door", "parcel delivers to a door")
eq(chunk.delivered, true, "house is marked delivered")
eq(#list, 0, "parcel is spent on a door")
list = { parcel(door.x + 10, door.y + 10) }
eq(#parcels.update(list, 0.001), 0, "a house pays only once")
eq(#list, 0, "extra parcel at a delivered door is still spent")

setup()
chunk = world.chunkAt(1)
local mailbox = chunk.mailbox
list = { parcel(mailbox.x, mailbox.y) }
events = parcels.update(list, 0.001)
eq(events[1], "mailbox", "parcel delivers to a mailbox")
eq(mailbox.delivered, true, "mailbox is marked delivered")
list = { parcel(mailbox.x, mailbox.y) }
eq(#parcels.update(list, 0.001), 0, "a mailbox pays only once")

setup()
chunk = world.chunkAt(1)
chunk.mailbox.down = true
list = { parcel(chunk.mailbox.x, chunk.mailbox.y) }
eq(#parcels.update(list, 0.001), 0, "a crushed mailbox takes no delivery")
