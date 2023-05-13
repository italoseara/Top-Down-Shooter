local Vector = require "libs.vector"
local Camera = require "libs.camera"

local Level = require "assets.scripts.level"
local Player = require "assets.scripts.player"

local cameraSmoothness = 10

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Generate random seed
    math.randomseed(os.time())

    -- Font
    Config.fonts = {
        default = love.graphics.newFont("assets/fonts/Quinquefive-ALoRM.ttf", 16),
        large = love.graphics.newFont("assets/fonts/Quinquefive-ALoRM.ttf", 32),
        small = love.graphics.newFont("assets/fonts/Quinquefive-ALoRM.ttf", 8),
    }

    love.graphics.setFont(Config.fonts.default)

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

    Config.sounds.reload:setPitch(1.5)

    -- Shaders
    Config.shaders.damage = love.graphics.newShader[[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(texture, texture_coords);
            if (pixel.a > 0.0) {
                pixel.r = 1.0;
                pixel.g = 0.0;
                pixel.b = 0.0;
            }
            return pixel * color;
        }
    ]]
end

function love.update(dt)
    mouse.x, mouse.y = camera:mousePosition()

    level:update(dt)
    player:update(dt)

    -- Use lerp to smooth camera movement
    camera:lookAt(
        LerpDt(camera.x, player.position.x, cameraSmoothness, dt),
        LerpDt(camera.y, player.position.y, cameraSmoothness, dt)
    )
end

function love.draw()
    camera:attach()

    -- Draw world
    level:draw()
    player:draw()

    camera:detach()

    -- Draw UI
    player:hud()
end

function LerpDt(a, b, x, dt) return a + (b - a) * (1.0 - math.exp(-x * dt)) end

function Lerp(a, b, x) return a + (b - a) * x end