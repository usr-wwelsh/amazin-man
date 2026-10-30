local scoring = require("src.scoring")

local BOARD_FILE = "scores.txt"

local leaderboard = {}

function leaderboard.load()
    local text = love.filesystem.read(BOARD_FILE)
    return text and scoring.decode(text) or {}
end

function leaderboard.save(board)
    love.filesystem.write(BOARD_FILE, scoring.encode(board))
end

return leaderboard
