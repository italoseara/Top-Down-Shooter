local Class = require "libs.classic"
local Vector = require "libs.vector"

local Heal = Class:extend()

function Heal:new(level, x, y)
    self.level = level

    -- Position
    self.position = Vector(x, y)

    -- Sprite
    self.sprite = love.graphics.newImage(Config.sprites.heal)

    -- Collider
    self.collider = self.level.world:newCircleCollider(
        self.position.x - self.sprite:getWidth() / 2 + 1,
        self.position.y - self.sprite:getHeight(), 3
    )
    self.collider:setCollisionClass("Heal")
    self.collider:setType("static")
    self.collider:setFixedRotation(true)
    self.collider:setObject(self)
    self.collider:setPosition(self.position:unpack())
end

function Heal:update(dt)
    if self.collider:enter("Player") then
        if player.isDead then return end

        player.health = player.health + 50
        if player.health > player.maxHealth then
            player.health = player.maxHealth
        end

        self.level:removeObject(self)

        love.audio.play(Config.sounds.pickup)
    end
end

function Heal:draw()
    love.graphics.draw(
        self.sprite, 
        self.position.x, 
        self.position.y, 
        0, 0.8, 0.8, 
        self.sprite:getWidth() / 2, 
        self.sprite:getHeight() / 2
    )
end

return Heal
