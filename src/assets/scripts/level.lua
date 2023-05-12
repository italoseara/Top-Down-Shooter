local Class = require "libs.classic"
local STI = require "libs.sti"
local WF = require "libs.windfield"

local Level = Class:extend()

function Level:new(map)
    self.map = STI(map)
    self.world = WF.newWorld(0, 0)

    self.world:addCollisionClass("Player")
    self.world:addCollisionClass("Solid")
    self.world:addCollisionClass("Bullet", {ignores = {"Player", "Bullet"}})

    self.colliders = {}

    if self.map.layers["Collide"] then
        for _, obj in ipairs(self.map.layers["Collide"].objects) do
            local collider = self.world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            collider:setCollisionClass("Solid")
            collider:setType("static")
            collider:setFriction(1)
            collider:setRestitution(0)
            collider:setObject(obj)
            table.insert(self.colliders, collider)
        end
    end
end

function Level:update(dt)
    self.world:update(dt)
end

function Level:draw()
    love.graphics.setBackgroundColor(34 / 255, 32 / 255, 52 / 255)
    self.map:drawLayer(self.map.layers["Map"])

    if Config.debug then
        self.world:draw()
    end
end

return Level