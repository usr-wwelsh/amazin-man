local scene = {}

function scene.go(id)
    scene.id = id
    scene.current = require("scenes." .. id)
    if scene.current.enter then scene.current.enter() end
end

return scene
