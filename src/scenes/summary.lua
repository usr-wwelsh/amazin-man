local world = require("src.world")
local scoring = require("src.scoring")
local game = require("src.game")
local view = require("src.view")
local scene = require("src.scene")

local summary = { overview = true }

function summary.update() end

function summary.keypressed(key)
    if key ~= "space" and key ~= "return" then return end
    if game.level >= game.RUN_LEVELS then
        game.enterName()
        scene.go("name")
    else
        game.startLevel(game.level + 1)
        scene.go("play")
    end
end

function summary.draw()
    local fonts = view.fonts
    local st = world.stats()
    love.graphics.setFont(fonts.title)
    love.graphics.print("LEVEL " .. game.level .. " COMPLETE", 130, 200)
    love.graphics.setFont(fonts.body)
    local rows = {
        { "deliveries", string.format("%d / %d", st.housesDone, st.houses), st.housesDone * scoring.DELIVERY, { 0.2, 0.9, 0.3 } },
        { "broken windows", tostring(st.windows), -st.windows * scoring.WINDOW, { 0.95, 0.25, 0.25 } },
        { "mailboxes crushed", tostring(st.crushed), -st.crushed * scoring.MAILBOX, { 1, 0.6, 0.1 } },
        { "time bonus", nil, game.levelBonus, { 0.3, 0.8, 1 } },
    }
    for i, r in ipairs(rows) do
        local y = 290 + (i - 1) * 44
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(r[1], 130, y)
        if r[2] then love.graphics.printf(r[2], 400, y, 170, "right") end
        if i == 4 then
            for k = 1, 3 do view.drawStar(460 + (k - 1) * 45, y + 17, 18, k <= game.levelStars, r[4]) end
        end
        love.graphics.setColor(r[4])
        love.graphics.printf(string.format("%+d", r[3]), 590, y, 160, "right")
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 130, 480, 620, 3)
    love.graphics.print("level score", 130, 495)
    love.graphics.printf(tostring(game.levelPoints), 590, 495, 160, "right")
    love.graphics.setFont(fonts.counter)
    love.graphics.setColor(view.hue((love.timer.getTime() * 0.15) % 1))
    love.graphics.print("TOTAL", 130, 555)
    love.graphics.printf(tostring(game.runTotal), 520, 555, 230, "right")
    love.graphics.setColor(view.hue((love.timer.getTime() * 0.15) % 1))
    love.graphics.setFont(fonts.title)
    love.graphics.printf("GRADE", 1100, 240, 700, "center")
    love.graphics.setFont(fonts.grade)
    love.graphics.printf(game.levelGrade, 1100, 290, 700, "center")
    love.graphics.setFont(fonts.body)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(game.level >= game.RUN_LEVELS and "space - enter name" or "space - next level", 130, 650)
    love.graphics.setFont(fonts.default)
end

return summary
