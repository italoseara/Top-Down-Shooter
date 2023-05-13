local Class = require "libs.classic"
local Vector = require "libs.vector"

local Direction = {
    LEFT = -1,
    RIGHT = 1,
}

local Items = {
    BLUE_GUN = {
        name = "Blue",
        damage = 6,
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
        damage = 5,
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
        damage = 3,
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

    -- Sprite
    self.sprite = love.graphics.newImage(Config.sprites.player)
    self.bulletSprite = love.graphics.newImage(Config.sprites.bullet)

    -- Gun
    self.lastUse = 0
    self.handDistortion = 0

    self.isShooting = false
    self.isHoldingFire = false

    -- Inventory
    self.slot = 1
    self.inventory = {
        Items.BLUE_GUN,
        Items.GOLD_GUN,
        Items.RED_GUN
    }
    self.inventory[self.slot].image = love.graphics.newImage(Config.sprites[string.lower(self:getHand().name)])

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
        self.position.x - self.sprite:getWidth() / 2 + 1,
        self.position.y - self.sprite:getHeight(),
        6, 8, 2
    )
    self.collider:setCollisionClass("Player")
    self.collider:setFixedRotation(true)
    self.collider:setObject(self)

    self.bullets = {}

    -- Health
    self.health = 150
    self.maxHealth = 150
    self.lastHit = 0

    self.isDead = false

    self.healthBar = love.graphics.newImage(Config.sprites.healthBar)
end

function Player:getHand()
    return self.inventory[self.slot]
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

function Player:updateBullets()
    for i = #self.bullets, 1, -1 do
        local bullet = self.bullets[i]
        if love.timer.getTime() - bullet.creationTime > 2 then
            bullet:destroy()
            table.remove(self.bullets, i)
        end

        if bullet:enter("Solid") or bullet:enter("Enemy") then
            bullet:destroy()
            table.remove(self.bullets, i)
        end
    end
end

function Player:shoot(dt)
    -- Shoot bullets
    if love.mouse.isDown(Config.keybinds.shoot) then
        if self:getHand().ammo <= 0 then return end
        if self.isReloading then return end
        if not self:getHand().automatic and self.isHoldingFire then return end
        if not self.isHoldingFire then self.isHoldingFire = true end
        if not self.isShooting then self.isShooting = true end
        if love.timer.getTime() - self.lastUse < self:getHand().cooldown then return end

        local direction = Vector(mouse.x, mouse.y) - self.position
        direction = direction:normalized()

        -- Apply a recoil force to the player
        self.velocity = self.velocity - direction * self:getHand().bulletSpeed * math.exp(dt) / 5

        direction = direction + Vector(math.random() * self:getHand().spread - self:getHand().spread / 2, math.random() * self:getHand().spread - self:getHand().spread / 2)

        local bullet = level.world:newCircleCollider(
            self.collider:getX() + direction.x * 10,
            self.collider:getY() + direction.y * 10,
            2
        )

        self.lastUse = love.timer.getTime()
        bullet.creationTime = love.timer.getTime()

        bullet.linearVelocityX, bullet.linearVelocityY = direction.x * self:getHand().bulletSpeed, direction.y * self:getHand().bulletSpeed
        bullet:setLinearVelocity(bullet.linearVelocityX, bullet.linearVelocityY)
        bullet:setCollisionClass("Bullet")
        bullet:setFixedRotation(true)
        bullet:setObject(self)

        table.insert(self.bullets, bullet)
        love.audio.play(Config.sounds.shoot)

        self:getHand().ammo = self:getHand().ammo - 1
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
    self:getHand().image = love.graphics.newImage(Config.sprites[string.lower(self:getHand().name)])
end

function Player:reloadWeapon()

    if self.isHoldingReload and not love.keyboard.isDown(Config.keybinds.reload) then self.isHoldingReload = false end

    if self.isReloading and love.timer.getTime() - self.lastReload > self:getHand().reloadTime then
        self.isReloading = false
        self:getHand().ammo = self:getHand().maxAmmo
    end

    if love.keyboard.isDown(Config.keybinds.reload) then
        if self.isHoldingReload then return end
        if not self.isHoldingReload then self.isHoldingReload = true end

        if self:getHand().ammo == self:getHand().maxAmmo then return end
        if love.timer.getTime() - self.lastReload < self:getHand().reloadTime then return end

        self.isReloading = true
        self.lastReload = love.timer.getTime()

        love.audio.play(Config.sounds.reload)
    end
end

function Player:physics(dt)
    self:updateBullets()

    -- Move the Collider
    self.collider:setLinearVelocity(self.velocity.x, self.velocity.y)

    self.position.x = self.collider:getX()
    self.position.y = self.collider:getY() + 4
    self.velocity = self.velocity * (1 - math.min(dt * self.friction, 1))

    -- Check for hit
    if self.collider:enter("Enemy") then
        self:hit(dt)
    end
end

function Player:animate()
    if self.isDead then
        self.distortion = 0
        self.handDistortion = 0
        self.rotation = math.rad(-90)
        self.direction = Direction.RIGHT
        return
    end

    if self.isShooting then
        -- Shake the camera when shooting
        camera:move(-math.random() * self:getHand().cameraShake, -math.random() * self:getHand().cameraShake)

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

function Player:hit(dt)
    -- Apply knockback
    local enemy = self.collider:getEnterCollisionData("Enemy").collider:getObject()
    local direction = Vector(self.position.x - enemy.position.x, self.position.y - enemy.position.y):normalized()

    self.velocity = self.velocity + direction * math.exp(dt * 10) * 200

    if love.timer.getTime() - self.lastHit < 0.2 then return end

    self.lastHit = love.timer.getTime()
    self.health = self.health - math.random(10, 30)

    if self.health <= 0 then
        self.health = 0
        self.isDead = true
    end

    love.audio.play(Config.sounds.hurt)
end

function Player:update(dt)
    self.dust:update(dt)

    self:animate()
    self:physics(dt)

    if self.isDead then return end

    self:move(dt)

    self:swapWeapon()
    self:reloadWeapon()
    self:shoot(dt)
end

function Player:getGunAngle()
    if self.isDead then return math.rad(-90) end

    local angle1 = math.rad(135)
    local angle2 = math.rad(-225)
    local angle3 = math.rad(45)

    local gunAngle = math.atan2(mouse.y - self.position.y + self.sprite:getHeight() / 2, mouse.x - self.position.x)

    if not self.isReloading then
        return gunAngle
    end

    if self.direction == Direction.LEFT then
        if gunAngle > math.rad(225) or gunAngle < -math.rad(90) then
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
            self.bulletSprite,
            bullet:getX(),
            bullet:getY(),
            angle,
            1,
            1,
            self.bulletSprite:getWidth() / 2,
            self.bulletSprite:getHeight() / 2
        )
    end
end

function Player:drawDust()
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
end

function Player:drawGun()
    if self.isDead then return end

    -- Draw gun
    love.graphics.draw(
        self:getHand().image,
        self.position.x,
        self.position.y - self.sprite:getHeight() / 2,
        self:getGunAngle(),
        1 + self.handDistortion,
        self.direction,
        self:getHand().image:getWidth() / 2 - 4,
        self:getHand().image:getHeight() / 2
    )

    if love.timer.getTime() - self.lastHit < 0.1 then
        love.graphics.setColor(1, 0, 0, 0.65)
        love.graphics.setShader(Config.shaders.damage)
        
        love.graphics.draw(
            self:getHand().image,
            self.position.x,
            self.position.y - self.sprite:getHeight() / 2,
            self:getGunAngle(),
            1 + self.handDistortion,
            self.direction,
            self:getHand().image:getWidth() / 2 - 4,
            self:getHand().image:getHeight() / 2
        )

        love.graphics.setColor(1, 1, 1)
        love.graphics.setShader()
    end
end

function Player:drawSprite()
    local posX, posY = self.position.x, self.position.y

    if self.isDead then
        posX = posX + self.sprite:getWidth() / 2
        posY = posY - self.sprite:getHeight() / 2
    end

    -- Draw player
    love.graphics.draw(
        self.sprite,
        posX,
        posY,
        self.rotation,
        self.direction,
        1 + self.distortion,
        self.sprite:getWidth() / 2,
        self.sprite:getHeight()
    )

    if love.timer.getTime() - self.lastHit < 0.1 then
        love.graphics.setColor(1, 0, 0, 0.65)
        love.graphics.setShader(Config.shaders.damage)
        
        love.graphics.draw(
            self.sprite,
            posX,
            posY,
            self.rotation,
            self.direction,
            1 + self.distortion,
            self.sprite:getWidth() / 2,
            self.sprite:getHeight()
        )

        love.graphics.setColor(1, 1, 1)
        love.graphics.setShader()
    end
end

function Player:draw()
    self:drawDust()
    self:drawGun()
    self:drawSprite()
    self:drawBullets()
end

function Player:hud()
    -- Draw the bullet count
    love.graphics.setColor(1, 1, 1, 1)
    local ammoCount = love.graphics.newText(
        love.graphics:getFont(), self:getHand().ammo .. "/" .. self:getHand().maxAmmo
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

    -- Draw the health bar
    local barScale = 6
    local paddingX, paddingY = 2, 2
    local marginX, marginY = 10, 10

    if not (love.timer.getTime() - self.lastHit < 0.1) then
        love.graphics.setColor(1, 0, 0, 1)
    end
    -- Fill the health bar with 2px padding vertical and 3px padding horizontal (6x scale)
    love.graphics.rectangle(
        "fill",
        marginX + paddingX * barScale,
        marginY + paddingY * barScale,
        (self.health / self.maxHealth) * (self.healthBar:getWidth() * 6 - (2 * paddingX) * barScale),
        self.healthBar:getHeight() * barScale - (2 * paddingY) * barScale
    )

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.healthBar, marginX, marginY, 0, barScale, barScale)
end

return Player