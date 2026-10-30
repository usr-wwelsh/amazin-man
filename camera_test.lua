local world = require("world")
local camera = require("camera")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

eq(camera.x(0), -(camera.VIEW_W - world.CHUNK_W) / 2, "camera centers the road at the start")
eq(camera.x(-world.CHUNK_H) - camera.x(0), world.DRIFT, "camera drifts one chunk with the road")

local z, x, y, t = camera.view(-540, 10)
eq(z, camera.ZOOM, "following camera uses the play zoom")
eq(t, 0, "following camera has no overview blend")
eq(x, camera.x(-540), "following camera tracks the van")
eq(y, -540 - camera.VIEW_H * 0.65, "following camera sits behind the van")

local zEnd, _, _, tEnd = select(1, camera.view(-540, 10, 1)), nil, nil, select(4, camera.view(-540, 10, 1))
local width, height = world.DRIFT * 9 + world.CHUNK_W, 10 * world.CHUNK_H
eq(tEnd, 1, "finished overview is fully blended")
eq(zEnd, math.min(camera.OVERVIEW_H / height, 1700 / width), "finished overview fits the whole level")
local zStart, _, _, tStart = camera.view(-540, 10, 0)
eq(tStart, 0, "overview starts unblended")
eq(zStart, camera.ZOOM, "overview starts at the play zoom")
