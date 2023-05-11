local Class = require "libs.classic"
local Vector = require "libs.vector"

local Player = Class:extend()
local scale = 7.5

function Player:new(x, y, path)
    self.position = Vector(x, y)
    self.velocity = Vector(0, 0)
    self.friction = 10
    self.speed = 5000

    self.image = love.graphics.newImage(path .. "/player.png")
    self.gun = love.graphics.newImage(path .. "/gun.png")

    self.imageDistortion = Vector(0, 0)
    self.imageRotation = 0
    self.direction = 1

    self.dustParticles = love.graphics.newParticleSystem(love.graphics.newImage("assets/sprites/particles/dust.png"), 4)
end

function Player:move(dt)
    local speed = self.speed

    if (love.keyboard.isDown("w") and love.keyboard.isDown("a")) or
    (love.keyboard.isDown("w") and love.keyboard.isDown("d")) or
    (love.keyboard.isDown("s") and love.keyboard.isDown("a")) or
    (love.keyboard.isDown("s") and love.keyboard.isDown("d")) then
        speed = speed * 0.7071
    end

    if love.keyboard.isDown("d") then
        self.velocity.x = self.velocity.x + speed * dt
    end

    if love.keyboard.isDown("a") then
        self.velocity.x = self.velocity.x - speed * dt
    end

    if love.keyboard.isDown("s") then
        self.velocity.y = self.velocity.y + speed * dt
    end

    if love.keyboard.isDown("w") then
        self.velocity.y = self.velocity.y - speed * dt
    end
end

function Player:physics(dt)
    self.position = self.position + self.velocity * dt
    self.velocity = self.velocity * (1 - math.min(dt * self.friction, 1))
end

function Player:animate()
    -- Make idle animation using imageDistortion and sin function
    self.direction = 1
    self.imageDistortion.x = 0
    self.imageDistortion.y = math.sin(love.timer.getTime() * 10) / 5

    -- If the player is moving, make the player wobble
    if self.velocity.x > 70 or self.velocity.x < -70 or
    self.velocity.y > 70 or self.velocity.y < -70 then
        self.imageRotation = math.sin(love.timer.getTime() * 12) / 12
        self.imageDistortion.y = math.sin(love.timer.getTime() * 20)

        if self.imageDistortion.y < 0 then
            self.imageDistortion.y = self.imageDistortion.y * 0.25
        end
        self.dustParticles:emit(1)
    else
        self.imageRotation = self.imageRotation * 0.9
    end

    -- If the player is moving to the left or right, flip the image
    if self.velocity.x < 0 then
        self.direction = -1
    end
end

function Player:update(dt)
    self.dustParticles:update(dt)
    self:animate()
    self:move(dt)
    self:physics(dt)
end

function Player:draw()
    -- Draw dust particles
    self.dustParticles:setPosition(self.position.x, self.position.y)
    self.dustParticles:setDirection(math.pi / 2 + (math.pi / 2 * self.direction))
    self.dustParticles:setSpread(math.pi / 8)
    self.dustParticles:setSpeed(100, 200)
    self.dustParticles:setSizes(scale, scale / 2, scale / 4)
    self.dustParticles:setParticleLifetime(0.2, 0.2)

    love.graphics.draw(self.dustParticles)

    -- Draw gun in the center of the player
    local mouseX, mouseY = love.mouse.getPosition()
    local angle = math.atan2(mouseY - self.position.y, mouseX - self.position.x)

    local gunScaleY = scale
    if angle > math.pi / 2 or angle < -math.pi / 2 then
        gunScaleY = -scale
    end

    love.graphics.draw(
        self.gun,
        self.position.x,
        self.position.y - self.image:getHeight() * scale / 2,
        angle,
        scale,
        gunScaleY,
        self.gun:getWidth() / 2 - 4,
        self.gun:getHeight() / 2
    )

    -- Draw player, apply the image distortion to the scale and position
    love.graphics.draw(
        self.image,
        self.position.x,
        self.position.y,
        self.imageRotation,
        scale * self.direction + self.imageDistortion.x,
        scale + self.imageDistortion.y,
        self.image:getWidth() / 2,
        self.image:getHeight()
    )
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("Image distortion: " .. self.imageDistortion.x .. ", " .. self.imageDistortion.y, 10, 10)
    love.graphics.print("Image rotation: " .. self.imageRotation, 10, 30)
    love.graphics.print("Velocity: " .. self.velocity.x .. ", " .. self.velocity.y, 10, 50)
    love.graphics.setColor(1, 1, 1, 1)
end

return Player