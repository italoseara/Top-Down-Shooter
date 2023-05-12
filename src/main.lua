local Vector = require "libs.vector"
local Camera = require "libs.camera"

local Level = require "assets.scripts.level"
local Player = require "assets.scripts.player"

local cameraSmoothness = 10

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Mouse
    mouse = Vector(0, 0)

    -- Load level and player
    level = Level(Config.maps[1])
    player = Player(100, 100)

    -- Camera
    camera = Camera(player.position.x, player.position.y, Config.scale)

    -- Audio
    Config.sounds = {}
    for key, value in pairs(Config.audio) do
        Config.sounds[key] = love.audio.newSource(value, "static")
    end
end

function love.update(dt)
    mouse.x, mouse.y = camera:mousePosition()

    level:update(dt)
    player:update(dt)

    -- Use lerp to smooth camera movement
    camera:lookAt(
        Lerp(camera.x, player.position.x, cameraSmoothness, dt),
        Lerp(camera.y, player.position.y, cameraSmoothness, dt)
    )
end

function love.draw()
    camera:attach()
    level:draw()
    player:draw()
    camera:detach()
end

function Lerp(a, b, x, dt) return a + (b - a) * (1.0 - math.exp(-x * dt)) end