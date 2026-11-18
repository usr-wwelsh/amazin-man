local scene = {}

function scene.go(id)
    scene.id = id
    scene.current = require("src.scenes." .. id)
    if scene.current.enter then scene.current.enter() end
end

function scene.push(id)
    local prev = { id = scene.id, current = scene.current }
    scene.go(id)
    scene.prev = prev
end

function scene.pop()
    scene.id, scene.current = scene.prev.id, scene.prev.current
    scene.prev = nil
end

return scene
