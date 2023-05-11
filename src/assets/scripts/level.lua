local Class = require "libs.classic"
local STI = require "libs.sti"

local Level = Class:extend()

function Level:new(map)
    self.map = STI(map)
end

function Level:update(dt)

end

function Level:draw()
    love.graphics.setBackgroundColor(34 / 255, 32 / 255, 52 / 255)
    self.map:draw(0, 0, 7.5, 7.5)
end

return Level