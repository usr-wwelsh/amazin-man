local scoring = {
    DELIVERY = 132,
    WINDOW = 57,
    MAILBOX = 83,
    BOARD_SIZE = 10,
    BONUS_PER_SEC = 40,
    PAR_FRACTION = 0.8,
}

function scoring.points(delivered, windows, mailboxes, bonus)
    return math.max(0, delivered * scoring.DELIVERY - windows * scoring.WINDOW - mailboxes * scoring.MAILBOX) + (bonus or 0)
end

function scoring.par(distance, topSpeed)
    return distance / (scoring.PAR_FRACTION * topSpeed)
end

local function maxBonus(distance, topSpeed)
    return math.floor((scoring.par(distance, topSpeed) - distance / topSpeed) * scoring.BONUS_PER_SEC)
end

function scoring.bonus(elapsed, distance, topSpeed, delivered, houses)
    if houses <= 0 then return 0 end
    local secs = math.min(scoring.par(distance, topSpeed) - elapsed, scoring.par(distance, topSpeed) - distance / topSpeed)
    if secs <= 0 then return 0 end
    return math.floor(secs * scoring.BONUS_PER_SEC * delivered / houses)
end

function scoring.stars(elapsed, distance, topSpeed)
    local par, fastest = scoring.par(distance, topSpeed), distance / topSpeed
    local f = (par - elapsed) / (par - fastest)
    if f >= 0.85 then return 3 end
    if f >= 0.5 then return 2 end
    if f > 0 then return 1 end
    return 0
end

function scoring.best(houses, distance, topSpeed)
    return houses * scoring.DELIVERY + maxBonus(distance, topSpeed)
end

local GRADES = { { "S", 0.95 }, { "A", 0.9 }, { "B", 0.8 }, { "C", 0.65 }, { "D", 0.4 } }

function scoring.grade(best, points, penalties)
    if best <= 0 or points <= 0 then return "F" end
    for _, g in ipairs(GRADES) do
        if (g[1] ~= "S" or penalties == 0) and points >= best * g[2] then return g[1] end
    end
    return "F"
end

local NAME_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{};:'\",.<>/?~`\\|"
local NAME_CLASS = "[" .. NAME_CHARS:gsub("%p", "%%%0") .. "]"
local NAME_PATTERN = "^(" .. string.rep(NAME_CLASS, 5) .. ") (%d+)$"

function scoring.cycle(char, dir)
    local i = NAME_CHARS:find(char, 1, true) or 1
    i = (i - 1 + dir) % #NAME_CHARS + 1
    return NAME_CHARS:sub(i, i)
end

function scoring.insert(list, name, score)
    local out = { { name = name, score = score } }
    for _, e in ipairs(list) do out[#out + 1] = e end
    table.sort(out, function(a, b) return a.score > b.score end)
    while #out > scoring.BOARD_SIZE do out[#out] = nil end
    return out
end

function scoring.encode(list)
    local lines = {}
    for _, e in ipairs(list) do lines[#lines + 1] = e.name .. " " .. e.score end
    return table.concat(lines, "\n") .. "\n"
end

function scoring.decode(text)
    local list = {}
    for line in text:gmatch("[^\n]+") do
        local name, score = line:match(NAME_PATTERN)
        if name and #list < scoring.BOARD_SIZE then list[#list + 1] = { name = name, score = tonumber(score) } end
    end
    table.sort(list, function(a, b) return a.score > b.score end)
    return list
end

return scoring
