local Level = require "assets.scripts.level"
local Player = require "assets.scripts.player"

local gameLevel, player

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    gameLevel = Level("assets/maps/map.lua")
    player = Player(100, 100, "assets/sprites/player")
end

function love.update(dt)
    gameLevel:update(dt)
    player:update(dt)
end

function love.draw()
    gameLevel:draw()
    player:draw()
end