local Class = require "libs.classic"
local STI = require "libs.sti"
local WF = require "libs.windfield"

local Ghost = require "assets.scripts.ghost"

local Level = Class:extend()

function Level:new(map)
    self.map = STI(map)
    self.world = WF.newWorld(0, 0)

    self.world:addCollisionClass("Player")
    self.world:addCollisionClass("Heal")
    self.world:addCollisionClass("Solid", {ignores = {"Heal", "Solid"}})
    self.world:addCollisionClass("Enemy", {ignores = {"Heal"}})
    self.world:addCollisionClass("Bullet", {ignores = {"Player", "Bullet", "Heal"}})

    self.colliders = {}
    self.enemies = {
        Ghost(self, 60, 150),
        Ghost(self, 125, 160),
        Ghost(self, 125, 110),
    }
    self.objects = {}

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
            enemy.collider:destroy()
        end
    end
end

function Level:addObject(item)
    table.insert(self.objects, item)
end

function Level:removeObject(item)
    for i, e in ipairs(self.objects) do
        if e == item then
            table.remove(self.objects, i)
            item.collider:destroy()
        end
    end
end

function Level:update(dt)
    self.world:update(dt)

    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end

    for _, obj in ipairs(self.objects) do
        obj:update(dt)
    end
end

function Level:draw()
    love.graphics.setBackgroundColor(34 / 255, 32 / 255, 52 / 255)
    self.map:drawLayer(self.map.layers["Map"])

    for _, item in ipairs(self.objects) do
        item:draw()
    end

    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

    if Config.debug then
        self.world:draw()
    end
end

return Level