function love.conf(t)
    t.window.width = 1280
    t.window.height = 720

    Config = {
        debug = false,
        scale = 7.5,
        sprites = {
            player = "assets/sprites/player/player.png",
            blue = "assets/sprites/player/blue.png",
            gold = "assets/sprites/player/gold.png",
            red = "assets/sprites/player/red.png",
            bullet = "assets/sprites/player/bullet.png",
            dust = "assets/sprites/particles/dust.png"
        },
        audio = {
            hurt_enemy = "assets/audio/Hurt_enemy.wav",
            hurt = "assets/audio/Hurt.wav",
            pickup = "assets/audio/Pickup.wav",
            shoot = "assets/audio/Shoot.wav",
        },
        maps = {
            "assets/maps/map.lua"
        },
        keybinds = {
            up = "w",
            down = "s",
            left = "a",
            right = "d",
            shoot = 1,
            reload = "r",
            swapLeft = "q",
            swapRight = "e"
        }
    }
end