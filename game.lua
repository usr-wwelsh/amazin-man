local world = require("world")
local scoring = require("scoring")
local van = require("van")
local parcels = require("parcels")

local game = {
    AMMO_START = 15,
    RUN_LEVELS = 8,
    LEVEL_BASE = 8,
    LEVEL_STEP = 2,
    START_DELAY = 2,
    ZOOM_TIME = 2,
    NAME_LEN = 5,
    level = 1,
    levelLen = 10,
    runTotal = 0,
    board = {},
}

local function levelDistance()
    return game.levelLen * world.CHUNK_H - van.START_Y
end

function game.startLevel(n)
    game.level = n
    game.levelLen = game.LEVEL_BASE + game.LEVEL_STEP * n
    world.reset(n, game.levelLen)
    game.packages = {}
    game.ammo = math.max(world.stats().houses, game.AMMO_START + 1 - n)
    game.score = { delivered = 0, windows = 0, mailboxes = 0 }
    game.cooldown = 0
    game.startDelay = game.START_DELAY
    game.elapsed = 0
    game.zoomT = 0
    game.exitComplete = false
    game.early = false
    game.levelPoints, game.levelGrade, game.levelBonus, game.levelStars = 0, "F", 0, 0
    game.van = van.new(game.vanImage)
end

function game.resetRun()
    game.runTotal = 0
    game.startLevel(1)
end

function game.throw()
    if game.cooldown > 0 or game.ammo <= 0 then return false end
    game.cooldown = parcels.COOLDOWN
    game.ammo = game.ammo - 1
    game.packages[#game.packages + 1] = parcels.new(game.van)
    return true
end

function game.bite()
    game.ammo = math.max(0, game.ammo - 1)
    game.van.slowT = van.SLOW_TIME
end

function game.startExit()
    local st = world.stats()
    game.exitComplete = st.housesDone == st.houses
    return game.exitComplete
end

function game.finishLevel(early)
    game.early = early
    game.zoomT = 0
    local houses = world.stats().houses
    local distance = levelDistance()
    local s = game.score
    game.levelStars = early and 0 or scoring.stars(game.elapsed, distance, van.MAX_SPEED)
    game.levelBonus = early and 0 or scoring.bonus(game.elapsed, distance, van.MAX_SPEED, s.delivered, houses)
    game.levelPoints = scoring.points(s.delivered, s.windows, s.mailboxes, game.levelBonus)
    game.levelGrade = scoring.grade(scoring.best(houses, distance, van.MAX_SPEED), game.levelPoints, s.windows + s.mailboxes + houses - s.delivered)
    game.runTotal = game.runTotal + game.levelPoints
end

function game.enterName()
    game.letters = { "A", "A", "A", "A", "A" }
    game.cursor = 1
end

function game.recordScore(entry)
    game.board = scoring.insert(game.board, entry, game.runTotal)
    game.boardRank = nil
    for i, e in ipairs(game.board) do
        if e.name == entry and e.score == game.runTotal then game.boardRank = i break end
    end
end

return game
