local prompt = {}

function prompt.new()
    return { yes = false }
end

function prompt.key(state, key)
    if key == "a" or key == "left" then state.yes = false end
    if key == "d" or key == "right" then state.yes = true end
    if key == "start" then return "no" end
    if key == "space" or key == "return" then return state.yes and "yes" or "no" end
end

return prompt
