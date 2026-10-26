local scoring = dofile("scoring.lua")

local function eq(a, b, name)
    if a ~= b then
        io.stderr:write(string.format("FAIL %s: expected %s got %s\n", name, tostring(b), tostring(a)))
        os.exit(1)
    end
end

eq(scoring.points(0, 0, 0), 0, "nothing scores zero")
eq(scoring.points(3, 0, 0), 3 * scoring.DELIVERY, "deliveries multiply")
eq(scoring.points(3, 1, 0), 3 * scoring.DELIVERY - scoring.WINDOW, "windows subtract")
eq(scoring.points(3, 0, 2), 3 * scoring.DELIVERY - 2 * scoring.MAILBOX, "mailboxes subtract")
eq(scoring.points(0, 5, 5), 0, "level score never negative")

eq(scoring.cycle("A", 1), "B", "cycle up")
eq(scoring.cycle("Z", 1), "0", "cycle enters digits")
eq(scoring.cycle("|", 1), "A", "cycle wraps up")
eq(scoring.cycle("A", -1), "|", "cycle wraps down")

local list = {}
for i = 1, scoring.BOARD_SIZE do list = scoring.insert(list, "AAAAA", i * 100) end
eq(#list, scoring.BOARD_SIZE, "board capped")
eq(list[1].score, scoring.BOARD_SIZE * 100, "board sorted descending")
list = scoring.insert(list, "BBBBB", 1)
eq(#list, scoring.BOARD_SIZE, "low score falls off")
eq(list[#list].score, 100, "low score not admitted")

local decoded = scoring.decode(scoring.encode({ { name = "WILLY", score = 9000 }, { name = "ABCDE", score = 12 } }))
eq(#decoded, 2, "roundtrip count")
eq(decoded[1].name, "WILLY", "roundtrip name")
eq(decoded[2].score, 12, "roundtrip score")

local symbols = scoring.decode(scoring.encode({ { name = "!@#$%", score = 5 }, { name = "-_=+[", score = 4 }, { name = "\\|`~?", score = 3 } }))
eq(#symbols, 3, "symbol names roundtrip")
eq(symbols[1].name, "!@#$%", "symbol name kept")

local hostile = scoring.decode("evil; rm -rf /\nlower 5\nTOOLONGNAME 5\nGOODa 5\nGOODA -3\nGOODB 99\n")
eq(#hostile, 1, "decode keeps only allowlisted lines")
eq(hostile[1].name, "GOODB", "decode valid line")

local DIST, TOP = 10000, 500
local par = scoring.par(DIST, TOP)
local fastest = DIST / TOP

eq(par > fastest, true, "par is slower than top speed")
eq(scoring.bonus(par, DIST, TOP, 5, 5), 0, "no bonus at par")
eq(scoring.bonus(par + 10, DIST, TOP, 5, 5), 0, "no bonus when slower than par")
eq(scoring.bonus(fastest, DIST, TOP, 5, 5), scoring.bonus(fastest - 3, DIST, TOP, 5, 5), "bonus capped at top speed")
eq(scoring.bonus(fastest, DIST, TOP, 5, 5) > scoring.bonus((par + fastest) / 2, DIST, TOP, 5, 5), true, "faster earns more")
eq(scoring.bonus(fastest, DIST, TOP, 0, 5), 0, "no deliveries no bonus")
eq(scoring.bonus(fastest, DIST, TOP, 5, 0), 0, "no houses no bonus")
eq(scoring.bonus(fastest, DIST, TOP, 3, 6) * 2, scoring.bonus(fastest, DIST, TOP, 6, 6), "bonus scales with deliveries")
eq(scoring.points(2, 0, 0, 50), 2 * scoring.DELIVERY + 50, "bonus adds to points")
eq(scoring.points(0, 3, 0, 50), 50, "bonus survives penalties floor")

eq(scoring.stars(par + 1, DIST, TOP), 0, "slower than par earns no stars")
eq(scoring.stars(par - 0.1, DIST, TOP), 1, "beating par earns one star")
eq(scoring.stars((par + fastest) / 2, DIST, TOP), 2, "halfway earns two stars")
eq(scoring.stars(fastest + 0.1, DIST, TOP), 3, "near fastest earns three stars")
eq(scoring.stars(fastest, DIST, TOP), 3, "fastest earns three stars")

local function g(houses, delivered, windows, mailboxes, elapsed)
    local bonus = scoring.bonus(elapsed or par, DIST, TOP, delivered, houses)
    return scoring.grade(scoring.best(houses, DIST, TOP), scoring.points(delivered, windows, mailboxes, bonus), windows + mailboxes)
end

eq(g(9, 9, 0, 0, fastest), "S", "flawless and fastest is S")
eq(g(9, 9, 0, 0, par), "A", "flawless but slow is A")
eq(g(10, 9, 0, 0, (par + fastest) / 2), "A", "one miss at mid speed is A")
eq(g(9, 9, 1, 0, fastest), "A", "fast with one penalty is A")
eq(g(24, 24, 0, 1, fastest), "A", "one penalty is never S on long levels")
eq(g(9, 9, 4, 4, par), "D", "heavy penalties drop the grade")
eq(g(10, 8, 0, 0, par), "C", "missed houses drop the grade")
eq(g(10, 6, 0, 0, par), "D", "missing four houses is D")
eq(g(10, 3, 0, 0, par), "F", "mostly missed is F")
eq(g(10, 1, 2, 0, par), "F", "no net score is F")
eq(g(10, 0, 0, 0, fastest), "F", "nothing delivered is F")
eq(g(0, 0, 0, 0, fastest), "F", "no houses is F")

print("ok")
