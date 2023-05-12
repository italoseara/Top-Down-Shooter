local Class = require "libs.classic"
local Vector = require "libs.vector"

local Direction = {
    LEFT = -1,
    RIGHT = 1,
}

local Items = {
    BLUE_GUN = {
        name = "Blue",
        cooldown = 0.15,
        automatic = false,
        bulletSpeed = 150,
        spread = 0.2,
        cameraShake = 0.2,
        maxAmmo = 12,
        ammo = 12,
        reloadTime = 1,
    },
    GOLD_GUN = {
        name = "Gold",
        cooldown = 0.1,
        automatic = true,
        bulletSpeed = 200,
        spread = 0.5,
        cameraShake = 0.3,
        maxAmmo = 30,
        ammo = 30,
        reloadTime = 1,
    },
    RED_GUN = {
        name = "Red",
        cooldown = 0.05,
        automatic = true,
        bulletSpeed = 300,
        spread = 0.05,
        cameraShake = 1,
        maxAmmo = 100,
        ammo = 100,
        reloadTime = 1,
    }
}

local Player = Class:extend()

function Player:new(x, y)
    -- Movement
    self.position = Vector(x, y)
    self.velocity = Vector(0, 0)
    self.friction = 10
    self.speed = 1000

    -- Image
    self.image = love.graphics.newImage(Config.sprites.player)
    self.bulletImage = love.graphics.newImage(Config.sprites.bullet)

    -- Gun
    self.lastUse = 0
    self.handDistortion = 0

    self.isShooting = false
    self.isHoldingFire = false

    -- Inventory
    self.slot = 2
    self.inventory = {
        Items.BLUE_GUN,
        Items.GOLD_GUN,
        Items.RED_GUN
    }
    self.inventory[self.slot].image = love.graphics.newImage(Config.sprites[string.lower(self.inventory[self.slot].name)])
    self.lastSwap = 0
    self.lastReload = 0
    self.isReloading = false
    self.isHoldingSwap = false
    self.isHoldingReload = false

    -- Animation
    self.distortion = 0
    self.rotation = 0
    self.direction = Direction.RIGHT

    self.dust = love.graphics.newParticleSystem(love.graphics.newImage(Config.sprites.dust), 4)

    -- Colliders
    self.collider = level.world:newBSGRectangleCollider(
        self.position.x - self.image:getWidth() / 2 + 1,
        self.position.y - self.image:getHeight(),
        6, 8, 2
    )
    self.collider:setCollisionClass("Player")
    self.collider:setFixedRotation(true)

    self.bullets = {}
end

function Player:move(dt)
    local direction = Vector(0, 0)

    if love.keyboard.isDown(Config.keybinds.up) then direction.y = direction.y - 1 end
    if love.keyboard.isDown(Config.keybinds.down) then direction.y = direction.y + 1 end
    if love.keyboard.isDown(Config.keybinds.left) then direction.x = direction.x - 1 end
    if love.keyboard.isDown(Config.keybinds.right) then direction.x = direction.x + 1 end

    if direction:len() > 0 then direction = direction:normalized() end

    self.velocity = self.velocity + direction * self.speed * dt
end

function Player:shoot()
    -- Destroy bullets after 2 seconds or when they hit a wall
    for i = #self.bullets, 1, -1 do
        local bullet = self.bullets[i]
        if love.timer.getTime() - bullet.creationTime > 2 then
            bullet:destroy()
            table.remove(self.bullets, i)
        end

        if bullet:enter("Solid") then
            bullet:destroy()
            table.remove(self.bullets, i)
        end
    end

    -- Shoot bullets
    if love.mouse.isDown(Config.keybinds.shoot) then
        if self.inventory[self.slot].ammo <= 0 then return end
        if self.isReloading then return end
        if not self.inventory[self.slot].automatic and self.isHoldingFire then return end
        if not self.isHoldingFire then self.isHoldingFire = true end
        if not self.isShooting then self.isShooting = true end
        if love.timer.getTime() - self.lastUse < self.inventory[self.slot].cooldown then return end

        local direction = Vector(mouse.x, mouse.y) - self.position
        direction = direction:normalized()

        -- Apply a recoil force to the player
        self.velocity = self.velocity - direction * self.inventory[self.slot].bulletSpeed / 5

        direction = direction + Vector(math.random() * self.inventory[self.slot].spread - self.inventory[self.slot].spread / 2, math.random() * self.inventory[self.slot].spread - self.inventory[self.slot].spread / 2)

        local bullet = level.world:newCircleCollider(
            self.collider:getX() + direction.x * 10,
            self.collider:getY() + direction.y * 10,
            2
        )

        self.lastUse = love.timer.getTime()
        bullet.creationTime = love.timer.getTime()

        bullet.linearVelocityX, bullet.linearVelocityY = direction.x * self.inventory[self.slot].bulletSpeed, direction.y * self.inventory[self.slot].bulletSpeed
        bullet:setLinearVelocity(bullet.linearVelocityX, bullet.linearVelocityY)
        bullet:setCollisionClass("Bullet")
        bullet:setFixedRotation(true)

        table.insert(self.bullets, bullet)
        love.audio.play(Config.sounds.shoot)

        self.inventory[self.slot].ammo = self.inventory[self.slot].ammo - 1
    end

    if self.isHoldingFire and not love.mouse.isDown(Config.keybinds.shoot) then self.isHoldingFire = false end
end

function Player:swapWeapon()

    if not (love.keyboard.isDown(Config.keybinds.swapLeft) or love.keyboard.isDown(Config.keybinds.swapRight)) then
        if self.isHoldingSwap then self.isHoldingSwap = false end
        return
    end

    if self.isHoldingSwap then return end
    if self.isReloading then return end
    if not self.isHoldingSwap then self.isHoldingSwap = true end
    if love.timer.getTime() - self.lastSwap < 0.1 then return end

    self.lastSwap = love.timer.getTime()

    if love.keyboard.isDown(Config.keybinds.swapLeft) then
        self.slot = self.slot - 1
        if self.slot < 1 then
            self.slot = #self.inventory
        end

        self.isHoldingSwap = true
    end

    if love.keyboard.isDown(Config.keybinds.swapRight) then
        self.slot = self.slot + 1
        if self.slot > #self.inventory then
            self.slot = 1
        end

        self.isHoldingSwap = true
    end

    -- Update the player's gun image
    self.inventory[self.slot].image = love.graphics.newImage(Config.sprites[string.lower(self.inventory[self.slot].name)])
end

function Player:reloadWeapon()

    if self.isHoldingReload and not love.keyboard.isDown(Config.keybinds.reload) then self.isHoldingReload = false end

    if self.isReloading and love.timer.getTime() - self.lastReload > self.inventory[self.slot].reloadTime then
        self.isReloading = false
        self.inventory[self.slot].ammo = self.inventory[self.slot].maxAmmo
    end

    if love.keyboard.isDown(Config.keybinds.reload) then
        if self.isHoldingReload then return end
        if not self.isHoldingReload then self.isHoldingReload = true end

        if self.inventory[self.slot].ammo == self.inventory[self.slot].maxAmmo then return end
        if love.timer.getTime() - self.lastReload < self.inventory[self.slot].reloadTime then return end

        self.isReloading = true
        self.lastReload = love.timer.getTime()

        love.audio.play(Config.sounds.reload)
    end
end

function Player:physics(dt)
    -- Move the Collider
    self.collider:setLinearVelocity(self.velocity.x, self.velocity.y)

    self.position.x = self.collider:getX()
    self.position.y = self.collider:getY() + 4
    self.velocity = self.velocity * (1 - math.min(dt * self.friction, 1))
end

function Player:animate()
    if self.isShooting then
        -- Shake the camera when shooting
        camera:move(-math.random() * self.inventory[self.slot].cameraShake, -math.random() * self.inventory[self.slot].cameraShake)

        -- Animate a recoil effect when shooting
        self.handDistortion = math.min(-math.sin((love.timer.getTime() - self.lastUse) * 20) * 2 / Config.scale, 0)
        
        if love.timer.getTime() - self.lastUse > 0.1 then
            self.isShooting = false
        end
    else
        -- Fade out the recoil effect when not shooting
        self.handDistortion = self.handDistortion * 0.9
    end

    -- Make idle animation using imageDistortion and sin function
    self.direction = Direction.RIGHT
    self.distortion = math.sin(love.timer.getTime() * 10) / 5 / Config.scale

    -- If the player is moving, make the player wobble
    if self.velocity:len() > 70 then
        self.rotation = math.sin(love.timer.getTime() * 12) / 12
        self.distortion = math.sin(love.timer.getTime() * 20) / Config.scale

        self.dust:emit(1)
    else
        self.rotation = self.rotation * 0.9
    end

    -- If the player is moving to the left or right, flip the image
    if mouse.x < self.position.x then self.direction = Direction.LEFT end
end

function Player:update(dt)
    self.dust:update(dt)

    self:animate()

    self:move(dt)
    self:physics(dt)

    self:swapWeapon()
    self:reloadWeapon()
    self:shoot()
end

function Player:getGunAngle()
    local angle1 = math.rad(135)
    local angle2 = math.rad(-225)
    local angle3 = math.rad(45)

    local gunAngle = math.atan2(mouse.y - self.position.y, mouse.x - self.position.x)

    if not self.isReloading then
        return gunAngle
    end

    if self.direction == Direction.LEFT then
        if gunAngle > math.rad(135) or gunAngle < -math.rad(90) then
        gunAngle = Lerp(gunAngle, angle2, math.min(love.timer.getTime() - self.lastReload, 0.2) / 0.2)
        else
        gunAngle = Lerp(gunAngle, angle1, math.min(love.timer.getTime() - self.lastReload, 0.2) / 0.2)
        end
    else
        gunAngle = Lerp(gunAngle, angle3, math.min(love.timer.getTime() - self.lastReload, 0.2) / 0.2)
    end

    return gunAngle
end

function Player:drawBullets()
    for _, bullet in ipairs(self.bullets) do
        local angle = math.atan2(bullet.linearVelocityY, bullet.linearVelocityX)
        local trail = 8

        -- Draw bullet trail
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.polygon(
            "fill", 
            bullet:getX() + math.cos(angle + math.pi / 2) * 2, bullet:getY() + math.sin(angle + math.pi / 2) * 2,
            bullet:getX() + math.cos(angle - math.pi / 2) * 2, bullet:getY() + math.sin(angle - math.pi / 2) * 2,
            bullet:getX() - math.cos(angle) * trail, bullet:getY() - math.sin(angle) * trail
        )
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.draw(
            self.bulletImage,
            bullet:getX(),
            bullet:getY(),
            angle,
            1,
            1,
            self.bulletImage:getWidth() / 2,
            self.bulletImage:getHeight() / 2
        )
    end
end

function Player:draw()
    -- Draw dust particles
    self.dust:setPosition(self.position.x, self.position.y)

    -- Get the direction of the velocity and set the direction of the particles
    local direction = self.velocity:normalized()
    local directionAngle = math.atan2(-direction.y, -direction.x)

    self.dust:setDirection(directionAngle)
    self.dust:setSpread(math.pi / 8)
    self.dust:setSpeed(20, 30)
    self.dust:setSizes(1, 1 / 2, 1 / 4)
    self.dust:setParticleLifetime(0.2, 0.2)

    love.graphics.draw(self.dust)

    -- Draw gun
    love.graphics.draw(
        self.inventory[self.slot].image,
        self.position.x,
        self.position.y - self.image:getHeight() / 2,
        self:getGunAngle(),
        1 + self.handDistortion,
        self.direction,
        self.inventory[self.slot].image:getWidth() / 2 - 4,
        self.inventory[self.slot].image:getHeight() / 2
    )

    -- Draw player
    love.graphics.draw(
        self.image,
        self.position.x,
        self.position.y,
        self.rotation,
        self.direction,
        1 + self.distortion,
        self.image:getWidth() / 2,
        self.image:getHeight()
    )

    -- Draw bullets
    self:drawBullets()
end

function Player:hud()
    -- Draw the bullet count
    love.graphics.setColor(1, 1, 1, 1)
    local ammoCount = love.graphics.newText(
        love.graphics:getFont(), self.inventory[self.slot].ammo .. "/" .. self.inventory[self.slot].maxAmmo
    )
    love.graphics.draw(
        ammoCount,
        love.graphics.getWidth() - ammoCount:getWidth() - 8,
        love.graphics.getHeight() - ammoCount:getHeight() - 8
    )

    -- Show if the player is reloading
    if self.isReloading then
        local reloadText = love.graphics.newText(love.graphics:getFont(), "Reloading...")
        love.graphics.draw(
            reloadText,
            8,
            love.graphics.getHeight() - reloadText:getHeight() - 8
        )
    end
end

return Player