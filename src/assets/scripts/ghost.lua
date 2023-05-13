local Class = require("libs.classic")
local Vector = require("libs.vector")
local AStar = require("libs.astar")

local Heal = require("assets.scripts.heal")

local Ghost = Class:extend()

function Ghost:new(level, x, y)
    -- Movement
    self.position = Vector(x, y)
    self.velocity = Vector(0, 0)
    self.friction = 10
    self.speed = math.random(300, 800)

    self.level = level

    -- Sprite
    self.sprite = love.graphics.newImage(Config.sprites.ghost)

    -- Health
    self.health = 100
    self.lastHit = 0

    -- Collider
    self.collider = self.level.world:newCircleCollider(
        self.position.x - self.sprite:getWidth() / 2 + 1,
        self.position.y - self.sprite:getHeight(), 3
    )
    self.collider:setCollisionClass("Enemy")
    self.collider:setFixedRotation(true)
    self.collider:setObject(self)

    -- Pathfinding
    self.path = nil
    self.lastSearch = 0
    self.nextPosition = nil
end

function Ghost:searchPath()
    local map = self.level.map

    local start = {}
    local goal = {}
    start.x, start.y = map:convertPixelToTile(self.position.x, self.position.y)
    goal.x, goal.y = map:convertPixelToTile(player.position.x, player.position.y)

    goal.x = math.ceil(goal.x - 0.5)
    goal.y = math.ceil(goal.y - 0.5)
    start.x = math.ceil(start.x)
    start.y = math.ceil(start.y)

    self.path = AStar:find(map.width, map.height, start, goal, function(x, y)
        return self.level:isFloor(x, y)
    end, false, false)
end

function Ghost:move(dt)

    if not self.path or (self.position - player.position):len() < 20 then
        self.nextPosition = nil
        local direction = (player.position - self.position):normalized()
        self.velocity = self.velocity + direction * self.speed * dt
    elseif self.path then
        local next = self.path[1]

        if next then
            self.nextPosition = Vector(
                next.x * self.level.map.tilewidth - self.level.map.tilewidth / 2,
                next.y * self.level.map.tileheight - self.level.map.tileheight / 2
            )

            local direction = (self.nextPosition - self.position):normalized()
            self.velocity = self.velocity + direction * self.speed * dt

            if (self.nextPosition - self.position):len() < 10 then
                table.remove(self.path, 1)
            end
        end
    end

    -- Search for path
    if love.timer.getTime() - self.lastSearch > 0.2 then
        self:searchPath()
        self.lastSearch = love.timer.getTime()
    end
end

function Ghost:physics(dt)
    -- Physics
    self.collider:setLinearVelocity(self.velocity.x, self.velocity.y)

    self.position.x = self.collider:getX()
    self.position.y = self.collider:getY() + 4
    self.velocity = self.velocity * (1 - math.min(dt * self.friction, 1))

    if self.collider:enter("Bullet") then
        self:hit(dt)
    end
end

function Ghost:hit(dt)
    -- Apply knockback
    local bullet = self.collider:getEnterCollisionData("Bullet").collider:getObject()
    self.velocity = self.velocity + -bullet.velocity:normalized() * math.exp(dt * 10) * bullet.velocity:len() * 3

    -- Take damage
    self.lastHit = love.timer.getTime()
    self.health = self.health - player:getHand().damage

    -- Sound
    love.audio.play(Config.sounds.hurtEnemy)
end

function Ghost:die()
    self.level:removeEnemy(self)

    if math.random() < 0.75 then
        self.level:addObject(Heal(self.level, self.position.x, self.position.y))
    end
end

function Ghost:update(dt)
    -- Movement
    self:move(dt)

    -- Physics
    self:physics(dt)

    -- Health
    if self.health <= 0 then
        self:die()
    end
end

function Ghost:drawSprite()
    love.graphics.draw(self.sprite, self.position.x, self.position.y, 0, 1, 1, self.sprite:getWidth() / 2, self.sprite:getHeight())
    
    if love.timer.getTime() - self.lastHit < 0.1 then
        love.graphics.setColor(1, 0, 0, 0.85)
        love.graphics.setShader(Config.shaders.damage)
        love.graphics.draw(self.sprite, self.position.x, self.position.y, 0, 1, 1, self.sprite:getWidth() / 2, self.sprite:getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.setShader()
    end
end

function Ghost:draw()
    love.graphics.setColor(1, 1, 1)
    self:drawSprite()

    -- draw path connecting dots with lines
    if Config.debug then
        if self.path then
            local map = self.level.map
            local tileSize = map.tilewidth
            local tileoffset = Vector(map.tilewidth / 2, map.tileheight / 2)

            love.graphics.setColor(1, 0, 0)
            for i = 1, #self.path - 1 do
                local x1 = self.path[i].x * tileSize - tileoffset.x
                local y1 = self.path[i].y * tileSize - tileoffset.y
                local x2 = self.path[i + 1].x * tileSize - tileoffset.x
                local y2 = self.path[i + 1].y * tileSize - tileoffset.y
                love.graphics.line(x1, y1, x2, y2)
            end
            love.graphics.setColor(1, 1, 1)
        end
        
        -- draw next position
        if self.nextPosition then
            love.graphics.setColor(0, 1, 0)
            love.graphics.circle("fill", self.nextPosition.x, self.nextPosition.y, 2)
            love.graphics.setColor(1, 1, 1)
        end
    end
end

return Ghost