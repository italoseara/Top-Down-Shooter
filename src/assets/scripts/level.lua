local Class = require "libs.classic"
local STI = require "libs.sti"
local WF = require "libs.windfield"

local Ghost = require "assets.scripts.ghost"

local Level = Class:extend()

function Level:new(map)
    self.map = STI(map)
    self.world = WF.newWorld(0, 0)

    self.world:addCollisionClass("Player")
    self.world:addCollisionClass("Solid")
    self.world:addCollisionClass("Enemy")
    self.world:addCollisionClass("Bullet", {ignores = {"Player", "Bullet"}})

    self.colliders = {}
    self.enemies = {
        Ghost(self, 100, 150),
        Ghost(self, 110, 150),
        Ghost(self, 120, 150),
    }

    if self.map.layers["Collide"] then
        for _, obj in ipairs(self.map.layers["Collide"].objects) do
            local collider = self.world:newBSGRectangleCollider(obj.x, obj.y, obj.width, obj.height, 2)
            collider:setCollisionClass("Solid")
            collider:setType("static")
            collider:setFriction(1)
            collider:setRestitution(0)
            collider:setObject(obj)
            table.insert(self.colliders, collider)
        end
    end
end

function Level:isFloor(x, y)
    local tile = self.map.layers["Map"].data[y][x]

    return tile ~= nil and
    tile.id ~= 14 and
    tile.id ~= 6 and
    tile.id ~= 16 and
    tile.id ~= 17 and
    tile.id ~= 3 and
    tile.id ~= 23
end

function Level:removeEnemy(enemy)
    for i, e in ipairs(self.enemies) do
        if e == enemy then
            table.remove(self.enemies, i)
        end
    end
end

function Level:update(dt)
    self.world:update(dt)

    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end
end

function Level:draw()
    love.graphics.setBackgroundColor(34 / 255, 32 / 255, 52 / 255)
    self.map:drawLayer(self.map.layers["Map"])

    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

    if Config.debug then
        self.world:draw()
    end
end

return Level