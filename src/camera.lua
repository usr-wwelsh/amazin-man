local world = require("src.world")

local ZOOM = 0.7
local camera = {
    ZOOM = ZOOM,
    VIEW_W = world.CHUNK_W / ZOOM,
    VIEW_H = world.CHUNK_H / ZOOM,
    OVERVIEW_H = 840,
}

function camera.x(y)
    return world.DRIFT * -y / world.CHUNK_H - (camera.VIEW_W - world.CHUNK_W) / 2
end

function camera.view(vanY, levelLen, zoomT)
    local z, x, y = ZOOM, camera.x(vanY), vanY - camera.VIEW_H * 0.65
    if not zoomT then return z, x, y, 0 end
    local t = zoomT * zoomT * (3 - 2 * zoomT)
    local width, height = world.DRIFT * (levelLen - 1) + world.CHUNK_W, levelLen * world.CHUNK_H
    local zEnd = math.min(camera.OVERVIEW_H / height, 1700 / width)
    local cx0, cy0 = x + camera.VIEW_W / 2, y + camera.VIEW_H / 2
    local cx, cy = cx0 + (width / 2 - cx0) * t, cy0 + (-height / 2 - cy0) * t
    z = ZOOM * (zEnd / ZOOM) ^ t
    return z, cx - world.CHUNK_W / (2 * z), cy - world.CHUNK_H / (2 * z), t
end

return camera
