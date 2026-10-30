local world = require("world")
local game = require("game")
local van = require("van")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

world.init({
    random = function(a) return a or 0 end,
    mask = { getPixel = function() return 0, 1, 0 end },
    images = { chunks = { "house" }, cross = "cross", start = "start", grass = "grass", cars = { "car" } },
})

game.startLevel(1)
eq(game.level, 1, "level one starts")
eq(game.levelLen, 10, "level one is ten chunks long")
eq(game.ammo, game.AMMO_START, "level one starts with full ammo")
eq(game.startDelay, game.START_DELAY, "level starts with a delay")
eq(#game.packages, 0, "no packages in flight")
eq(game.van.y, -van.START_Y, "van starts at the start line")
eq(game.score.delivered, 0, "score starts empty")

game.startLevel(8)
eq(game.levelLen, 24, "level eight is longer")
eq(game.ammo, math.max(world.stats().houses, game.AMMO_START + 1 - 8), "late levels give a package per house")

game.startLevel(1)
eq(game.throw(), true, "van throws a package")
eq(game.ammo, game.AMMO_START - 1, "throwing spends ammo")
eq(#game.packages, 1, "thrown package is in flight")
eq(game.throw(), false, "throw is on cooldown")
eq(game.ammo, game.AMMO_START - 1, "cooldown throw spends nothing")
game.cooldown = 0
game.ammo = 0
eq(game.throw(), false, "empty van cannot throw")

game.startLevel(1)
game.bite()
eq(game.ammo, game.AMMO_START - 1, "a bite costs a package")
eq(game.van.slowT, van.SLOW_TIME, "a bite slows the van")
game.ammo = 0
game.bite()
eq(game.ammo, 0, "ammo never goes negative")

game.startLevel(1)
eq(game.startExit(), false, "exit is incomplete before any delivery")
eq(game.exitComplete, false, "exit completeness is remembered")

game.resetRun()
game.finishLevel(true)
eq(game.early, true, "early finish is remembered")
eq(game.levelBonus, 0, "early finish has no time bonus")
eq(game.levelStars, 0, "early finish has no stars")
eq(game.zoomT, 0, "finish restarts the zoom")
eq(game.runTotal, game.levelPoints, "level points join the run total")

game.resetRun()
eq(game.runTotal, 0, "new run starts at zero")
eq(game.level, 1, "new run starts at level one")

game.enterName()
eq(table.concat(game.letters), "AAAAA", "name entry starts blank")
eq(game.cursor, 1, "name cursor starts at the left")

game.runTotal = 500
game.board = {}
game.recordScore("ZZZZZ")
eq(game.boardRank, 1, "first score ranks first")
eq(game.board[1].score, 500, "board keeps the score")
eq(game.board[1].name, "ZZZZZ", "board keeps the name")
