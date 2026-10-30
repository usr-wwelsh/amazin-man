local scene = {}

function scene.go(id)
    scene.id = id
    scene.current = require("src.scenes." .. id)
    if scene.current.enter then scene.current.enter() end
end

return scene
