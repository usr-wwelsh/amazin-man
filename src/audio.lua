local van = require("src.van")

local audio = { sounds = {} }
local sounds = audio.sounds

local DELIVER_VOICES = { "hello", "thank_you_1" }
local WINDOW_VOICES = { "my_window_1", "my_leg" }
local START_VOICES = { "start1", "start2", "start3", "start4", "start5" }
local EXIT_VOICES = { "out_of_packages_1", "out_of_packages_2", "out_of_packages_3" }
local HOUSE_CRASH_VOICES = { "house_crash" }
local exitVoices = {}
local houseCrashVoices = {}

local function play(name)
    local s = sounds[name]:clone()
    s:play()
end

local function playOneOf(names)
    play(names[love.math.random(#names)])
end

local handlers = {
    window = function()
        play("window_crash")
        playOneOf(WINDOW_VOICES)
    end,
    door = function()
        play("successful_package")
        playOneOf(DELIVER_VOICES)
    end,
    mailbox = function()
        play("successful_package")
        play("how_gonna_get_mail")
    end,
    crush = function() play("watchwheregoing") end,
    bark = function() play("dogbark") end,
    car = function() play("thatsmycar") end,
    house = function()
        if #houseCrashVoices > 0 then playOneOf(houseCrashVoices) end
    end,
}

function audio.event(kind)
    handlers[kind]()
end

function audio.load()
    for _, name in ipairs({ "car_startup", "hello", "how_gonna_get_mail", "my_leg", "my_window_1", "successful_package", "thank_you_1", "thatsmycar", "dogbark", "start1", "start2", "start3", "start4", "start5", "van_running", "watchwheregoing", "window_crash" }) do
        sounds[name] = love.audio.newSource("assets/sfx/" .. name .. ".ogg", "static")
    end
    for _, group in ipairs({ { EXIT_VOICES, exitVoices }, { HOUSE_CRASH_VOICES, houseCrashVoices } }) do
        for _, voice in ipairs(group[1]) do
            local path = "assets/sfx/" .. voice .. ".ogg"
            if love.filesystem.getInfo(path) then
                sounds[voice] = love.audio.newSource(path, "static")
                group[2][#group[2] + 1] = voice
            end
        end
    end
    sounds.dogbark:setVolume(0.3)
    sounds.ambience = love.audio.newSource("assets/sfx/ambience.ogg", "stream")
    sounds.ambience:setLooping(true)
    sounds.ambience:setVolume(0.5)
    sounds.ambience:play()
    sounds.theme = love.audio.newSource("assets/sfx/amazin.ogg", "stream")
    sounds.theme:setLooping(true)
    sounds.theme:setVolume(0.85)
    sounds.theme:setPitch(0.8)
    sounds.theme:play()
    sounds.summary = love.audio.newSource("assets/sfx/amazindrum.ogg", "stream")
    sounds.summary:setLooping(true)
    sounds.summary:setVolume(0.85)
    sounds.summary:setPitch(0.8)
    sounds.van_running:setLooping(true)
    sounds.van_running:setVolume(0.5)
    sounds.van_running:play()
end

function audio.levelStart()
    sounds.summary:stop()
    sounds.theme:play()
    sounds.ambience:play()
    play("car_startup")
    playOneOf(START_VOICES)
    if not sounds.van_running:isPlaying() then sounds.van_running:play() end
end

function audio.levelEnd(early)
    sounds.van_running:pause()
    sounds.theme:pause()
    sounds.ambience:pause()
    sounds.summary:play()
    if not early then play("successful_package") end
end

function audio.exitVoice()
    if #exitVoices > 0 then play(exitVoices[love.math.random(#exitVoices)]) end
end

function audio.engine(v)
    sounds.van_running:setPitch(van.pitch(v))
end

return audio
