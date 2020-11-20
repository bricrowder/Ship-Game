-- set new prefixes for easier typing...
gfx = love.graphics
ph = love.physics
kb = love.keyboard
ms = love.mouse
fs = love.filesystem
js = love.joystick

-- load modules/classes
json = require "dkjson"
helper = require "helper"
camera_cls = require "Camera"
player_cls = require "Player"
bulletcontroller_cls = require "BulletController"
bullet_cls = require "Bullet"
enemycontroller_cls = require "EnemyController"
enemy_cls = require "Enemy"
dropcontroller_cls = require "DropController"
drop_cls = require "Drop"
level_cls = require "Level"
gun_cls = require "Gun"
engine_cls = require "Engine"
planet_cls = require "Planet"
radar_cls = require "Radar"
explosionctlr_cls = require "ExplosionController"
explosion_cls = require "Explosion"
textureatlas_cls = require "TextureAtlas"
particle_cls = require "Particle"
screen_mainmenu_cls = require "Screen_MainMenu"
screen_base_cls = require "Screen_Base"
screen_options_cls = require "Screen_Options"
screen_controls_cls = require "Screen_Controls"
screen_quit_cls = require "Screen_Quit"
screen_gameover_cls = require "Screen_GameOver"
screen_paused_cls = require "Screen_Paused"

-- declare/init global variables
-- screen the game is on
screen = "mainmenu"     -- mainmenu, options, quit, newgame, game, endgame
-- game screen sub screens
paused = false      -- paused screen
gameover = false    -- game over screen
inbasefirst = false     -- if this is the opening base select
inbase = false      -- if the player is in thier base
-- level #
currentlevel = 1
-- config data
config = json.opendecode("config/config.json")
-- particle data
particles = json.opendecode("config/particles.json")
-- gamepad mappings
js.loadGamepadMappings("config/gamecontrollerdb.txt")


-- make shorter reference to input config
kbm = config.controls.kbmouse
gp = config.controls.gamepad

-- table of joysticks
gamepads = {}

-- shader code when a player is hit
chromashadercode = [[
    extern number t;
    extern number reswidth;
    extern number intensity;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)    
    {   
        number amt = intensity/reswidth;
        number mult = sin(t);

        vec3 col;
        col.r = Texel(texture, vec2(texture_coords.x + amt*mult, texture_coords.y) ).r;
        col.g = Texel(texture, vec2(texture_coords.x - amt*mult, texture_coords.y) ).g;
        col.b = Texel(texture, vec2(texture_coords.x, texture_coords.y - amt*mult) ).b;
        
        return vec4(col,1.0) * color;
    }  
]]

-- not used... 
bloomshadercode = [[
    extern vec2 size = vec2(192,192);
    extern int samples = 5; // pixels per axis; higher = bigger glow, worse performance
    extern float quality = 30.5; // lower = smaller glow, better quality
    
    vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
    {
      vec4 source = Texel(tex, tc);
      vec4 sum = vec4(0);
      int diff = (samples - 1) / 2;
      vec2 sizeFactor = vec2(1) / size * quality;
      
      for (int x = -diff; x <= diff; x++)
      {
        for (int y = -diff; y <= diff; y++)
        {
          vec2 offset = vec2(x, y) * sizeFactor;
          sum += Texel(tex, tc + offset);
        }
      }
      
      return ((sum / (samples * samples)) + source) * colour;
    }
]]

-- shader for game colour overlay
colourshadercode = [[
    extern vec3 col;
    vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
    {
        return Texel(tex, tc) * colour + vec4(col,0.0);
    }    
]]

function love.load()
    -- setup the randomize!
    local s = os.time()
    math.randomseed(s)
    print(s)
    -- need to pop a few... wierd mac thing
    math.random()
    math.random()
    math.random()

    -- get window width/height
    window = {}
    window.width, window.height, window.flags = love.window.getMode()

    -- setup the fonts
    debugfont = gfx.newFont("assets/PressStart2P.ttf", 8)
    gamefont = gfx.newFont("assets/PressStart2P.ttf", 24)

    -- load textures
    textureatlas = textureatlas_cls.new("assets/textureatlas.png","assets/textureatlas.json")

    -- create screens
    screen_mainmenu = screen_mainmenu_cls.new()
    screen_base = screen_base_cls.new()
    screen_options = screen_options_cls.new()
    screen_controls = screen_controls_cls.new()
    screen_quit = screen_quit_cls.new()
    screen_gameover = screen_gameover_cls.new()
    screen_paused = screen_paused_cls.new()

    -- create the camera
    camera = camera_cls.new()
    
    -- setup shaders
    chromashader = gfx.newShader(chromashadercode)
    chromashader:send("reswidth", config.camera.VirtualResolutionWidth)
    chromashader:send("intensity", config.camera.chromaintensity)
    bloomshader = gfx.newShader(bloomshadercode)
    colourshader = gfx.newShader(colourshadercode)
    shadertime = 0

    -- setup main game drawing canvas
    canvas = gfx.newCanvas(1920,1080)
    -- setup filtering for scaling/rotating
    gfx.setDefaultFilter("nearest","nearest",1)

    -- setup the game starting point / screen
    screen = "mainmenu"
end

function love.joystickadded(g)
    table.insert(gamepads, g)
    print("inserted " .. g:getName())
    print("guid " .. g:getGUID())
end

function love.joystickremoved(g)
    local toremove = {}
    -- see which one was removed
    for i, v in ipairs(gamepads) do
        if not(v:isConnected()) then
            table.insert(toremove, i)
        end
    end
    -- remove them if there are any... 
    if #toremove > 0 then
        for i=#gamepads, 1, -1 do
            table.remove(gamepads, toremove[i])
        end
    end
end

function love.keypressed(key)
    if screen == "game" then
        -- temp
        if key == "z" then
            camera:setShake(0.5,5)
        end
        if key == "tab" then
            love.event.quit()
        end        
        if key == "n" then
           NextLevel()
        end    
        -- end temp    
        if paused then
            if key == kbm.up then
                screen_paused:move(-1)
            elseif key == kbm.down then
                screen_paused:move(1)
            elseif key == kbm.enter then
                screen_paused:action()
            elseif key == kbm.back then
                paused = false
                -- return here so it doesn't affect the next conditional statement
                return
            end
        end    
        if gameover then
            if key == kbm.up then
                screen_gameover:move(-1)
            elseif key == kbm.down then
                screen_gameover:move(1)
            elseif key == kbm.enter then
                screen_gameover:action()
            end                        
        end
        if inbase then
            -- move up and down
            if key == kbm.up then
                screen_base:moverow(-1)
            elseif key == kbm.down then
                screen_base:moverow(1)
            elseif key == kbm.enter then
                screen_base:action()
            elseif key == kbm.back then
                ingame = false
            end
        end            
        if not(gameover) and not(inbase) then
            if key == kbm.back then            
                paused = true
            end
            if key == kbm.enter and planet:canLand() then
                player:setAnimation("landtransition")
                player:setInteractive(false)
                -- setup the info for this animation
                player:setLandingInfo()                
            end
        end
    elseif screen == "mainmenu" then
        -- move up and down
        if key == kbm.up then
            screen_mainmenu:move(-1)
        elseif key == kbm.down then
            screen_mainmenu:move(1)
        elseif key == kbm.enter then
            screen_mainmenu:action()
        elseif key == kbm.back then
            screen = "quit"
        end
    elseif screen == "options" then
        -- move up and down
        if key == kbm.up then
            screen_options:move(-1)
        elseif key == kbm.down then
            screen_options:move(1)
        elseif key == kbm.left then
            screen_options:volume(-1)
        elseif key == kbm.right then
            screen_options:volume(1)
        elseif key == kbm.enter then
            screen_options:action()
        elseif key == kbm.back then
            screen = "mainmenu"
        end
    elseif screen == "controls" then
        -- move up and down
        if key == kbm.up then
            screen_controls:move(-1)
        elseif key == kbm.down then
            screen_controls:move(1)
        elseif key == kbm.enter then
            screen_controls:action()
        elseif key == kbm.back then
            if paused then
                screen = "game"
            else
                screen = "mainmenu"
            end
        end
    elseif screen == "quit" then
        -- move up and down
        if key == kbm.left then
            screen_quit:move(-1)
        elseif key == kbm.right then
            screen_quit:move(1)
        elseif key == kbm.enter then
            screen_quit:action()
        elseif key == kbm.back then
            screen = "mainmenu"
        end
    end
end

function love.wheelmoved(x, y)
    -- changes the index of the player powerup only in game... 
    if screen == "game" and not(paused or gameover or inbase) then
        if y > 0 then
            player:changePowerup(1)
        elseif y < 0 then
            player:changePowerup(-1)
        end
    end
end

function love.joystickaxis(g, a, v)
    -- print("gamepad: " .. g:getName())
    -- print("Axis: " .. a)
    -- print("Value: " .. v)

    -- left up & down = 2 .. -1 -> 1
    -- left left & right = 1 .. -1 -> 1

    -- right up & down = 4 .. -1 -> 1
    -- right left & right = 3 .. -1 -> 1

    -- ps4 = 2,1 & 3 & 6... what??
end

function love.gamepadpressed(g, b)
    if screen == "game" then  
        -- end temp    
        if paused then
            if b == gp.up then
                screen_paused:move(-1)
            elseif b == gp.down then
                screen_paused:move(1)
            elseif b == gp.enter then
                screen_paused:action()
            elseif b == gp.back then
                paused = false
                -- return here so it doesn't affect the next conditional statement
                return
            end
        end    
        if gameover then
            if b == gp.up then
                screen_gameover:move(-1)
            elseif b == gp.down then
                screen_gameover:move(1)
            elseif b == gp.enter then
                screen_gameover:action()
            end                        
        end
        if inbase then
            -- move up and down
            if b == gp.up then
                screen_base:moverow(-1)
            elseif b == gp.down then
                screen_base:moverow(1)
            elseif b == gp.enter then
                screen_base:action()
            elseif b == gp.back then
                ingame = false
            end
        end            
        if not(gameover) and not(inbase) then
            if b == gp.back then            
                paused = true
            end
            if b == gp.changepowerup then
                player:changePowerup(1)
            end            
            if b == gp.land and planet:canLand() then
                player:setAnimation("landtransition")
                player:setInteractive(false)
                -- setup the info for this animation
                player:setLandingInfo()                
            end
        end
    elseif screen == "mainmenu" then
        -- move up and down
        if b == gp.up then
            screen_mainmenu:move(-1)
        elseif b == gp.down then
            screen_mainmenu:move(1)
        elseif b == gp.enter then
            screen_mainmenu:action()
        elseif b == gp.back then
            screen = "quit"
        end
    elseif screen == "options" then
        -- move up and down
        if b == gp.up then
            screen_options:move(-1)
        elseif b == gp.down then
            screen_options:move(1)
        elseif b == gp.left then
            screen_options:volume(-1)
        elseif b == gp.right then
            screen_options:volume(1)
        elseif b == gp.enter then
            screen_options:action()
        elseif b == gp.back then
            screen = "mainmenu"
        end
    elseif screen == "controls" then
        -- move up and down
        if b == gp.up then
            screen_controls:move(-1)
        elseif b == gp.down then
            screen_controls:move(1)
        elseif b == gp.enter then
            screen_controls:action()
        elseif b == gp.back then
            if paused then
                screen = "game"
            else
                screen = "mainmenu"
            end
        end
    elseif screen == "quit" then
        -- move up and down
        if b == gp.left then
            screen_quit:move(-1)
        elseif b == gp.right then
            screen_quit:move(1)
        elseif b == gp.enter then
            screen_quit:action()
        elseif b == gp.back then
            screen = "mainmenu"
        end
    end
end

function love.update(dt)
    if screen == "game" and not(paused or gameover or inbasefirst) then
        shadertime = shadertime + dt
        chromashader:send("t", shadertime)

        if not(inbase) then
            if player:isInteractive() then
                player:resetSpeed()
                local a = 0
                -- get position of mouse and centre pos of window
                local mx, my = ms.getPosition()
                local cx, cy, vx, vy = camera:getCamera()
                -- calculate relative difference
                local xd = mx-cx/2
                local yd = my-cy/2

                if not(xd == 0) then
                    player:changeAngle(xd*dt)
                end

                -- KB Mouse Input:

                -- set movement vector
                local moved = false
                local ma = 0
                if kb.isDown(kbm.up) then
                    moved = true
                    -- go straight
                end
                if kb.isDown(kbm.down) then
                    moved = true
                    -- go backwards
                    ma = math.pi
                end
                if kb.isDown(kbm.right) then
                    moved = true
                    -- go right
                    ma = math.pi/2
                end
                if kb.isDown(kbm.left) then
                    moved = true
                    -- go left
                    ma = (math.pi*3)/2
                end

                if (moved) then
                    player:addPosition(dt, ma)
                end

                -- shooting and powerups
                if ms.isDown(kbm.shoot) then
                    player:shoot(0)
                end
                if ms.isDown(kbm.powerup) then
                    player:shoot(player:getPowerup())
                end

                -- Gamepad input:

                -- movement/directional vector from gampad
                if gamepads[1] then
                    -- get input from the left/right axis
                    local x = gamepads[1]:getGamepadAxis(gp.movex)
                    local y = gamepads[1]:getGamepadAxis(gp.movey)
                    local dx = gamepads[1]:getGamepadAxis(gp.dirx)
                    local dy = gamepads[1]:getGamepadAxis(gp.diry)

                    -- calc the angles
                    local pa = math.atan2(y, x)
                    local da = math.atan2(dy, dx)

                    -- update the directional angle, add camera angle to five it that natural feel
                    if math.abs(dx) > gp.dirdeadzone or math.abs(dy) > gp.dirdeadzone then
                        player:setAngle(da + camera.angle)
                    else
                        -- even if the directional angle hasn't change, update it so the player doesn' just keep spinning...
                        local cad = camera.angle - camera.oldangle
                        player:changeAngle(cad)
                    end
                    -- update the positional angle, add camera angle to give it that natural feel
                    if math.abs(x) > gp.movedeadzone or math.abs(y) > gp.movedeadzone then
                        player:addPosition(dt, pa + camera.angle, true)
                    end
                    
                    -- shoot gun
                    if gamepads[1]:isGamepadDown(gp.shoot) then
                        player:shoot(0)
                    end
                    -- shoot powerups
                    if gamepads[1]:isGamepadDown(gp.powerup) then
                        player:shoot(player:getPowerup())
                    end
                end
            end

            -- update the player
            player:update(dt)

            -- get final position for camera move
            if not(player:getAnimation() == "endtransition") then
                camera:setPosition(camera.size.vw/2, camera.size.vh + player:getMag() -  (camera.size.vh/2), player:getPosAngle())
            end

            -- reset mouse position to centre of window
            local cx, cy, vx, vy = camera:getCamera()
            ms.setPosition(cx/2, cy/2)

        else
            -- update the screen if you are in the base
            screen_base:update(dt)
        end

        if camera:isShaking() then
            camera:shakeit(dt)
        end

        -- update planet controller
        planet:update(dt)

        -- update the enemies
        enemyctlr:update(dt)

        -- update the drops
        dropctlr:update(dt)

        -- update the bullets
        bulletctlr:update(dt)
        
        -- update the explosions
        explosionctlr:update(dt)
        
        -- update radar
        radar:update(dt)

        -- update level
        level:update(dt)
        
    elseif screen == "mainmenu" then
    elseif screen == "options" then
    elseif screen == "quit" then
    end
end

function love.draw()
    gfx.setFont(gamefont)        
    if screen == "game" then
        -- draw these before setting camera...

        -- start of camera draw
        camera:set()

        -- set the shader and canvas
        gfx.setCanvas(canvas)
        
        -- setup the clear colour (the background colour) based on the players position around the planet
        -- get player angle and init the starting value

        -- BUG
        -- there is a bug here if pa isn't between 0-math.pi*2... it can cause the calc to screw up.
        --
        local pa = player:getPosAngle()
        local c = 0
        local variance = planet:getDayNightVariance()
        -- see where the player is 0 = full day, pi = full night
        if pa >= 0 and pa <= math.pi then
            local n = 1-(pa/math.pi)
            c = variance - variance*n
        else
            local n = (pa-math.pi)/math.pi
            c = variance - variance*n
        end

        -- get the background colour
        local col = planet:getBackgroundColour()

        -- clear to the modified colour
        gfx.clear(col[1]-c, col[2]-c, col[3]-c, 255)

        -- get the overlay colour
        local overlay = planet:getOverlay()

        -- set overlay for planet
        gfx.setColor(overlay)

        -- draw planet
        planet:draw()

        -- set overlay for all other objects
        gfx.setColor(overlay[1]+64, overlay[2]+64, overlay[3]+64, 255)

        -- draw player
        player:draw()    

        -- draw enemies
        enemyctlr:draw()

        -- draw drops
        dropctlr:draw()

        -- draw bullets
        bulletctlr:draw()

        -- draw explosions
        explosionctlr:draw()

        -- draw level artifacts
        if enemyctlr.bossmode then
            level:draw()
        end

        -- reset shader
        gfx.setShader()        
        
        -- end of camera draw
        camera:unset()

        -- draw radar
        radar:draw()
        
        -- draw paused/game over screens if necessary
        if paused then
            screen_paused:draw()
        end
        if gameover then
            screen_gameover:draw()
        end
        if inbase then
            screen_base:draw()
        end

        -- done drawing on canvas
        gfx.setCanvas()

        -- set the chroma shader if the camera is shaking
        local inner, outer = planet:getRings()
        if camera:isShaking() and not(gameover or paused or inbase) then
            gfx.setShader(chromashader)
        end

        -- draw the main canvas
        gfx.setColor(255,255,255,255)
        gfx.draw(canvas,0,0)

        -- reset the shader
        gfx.setShader()
        
        -- debug stats
        gfx.setFont(debugfont)
        gfx.print("Res: " .. camera.size.w .. "x" .. camera.size.h, 10, 10)
        gfx.print("VRes: " .. camera.size.vw .. "x" .. camera.size.vh, 10, 25)
        gfx.print("Scale: " .. camera.scale.x .. "," .. camera.scale.y, 10, 40)
        gfx.print("FPS: " .. love.timer.getFPS(), 10, 55)
        local stats = gfx.getStats()
        gfx.print("Draws: " .. stats.drawcalls, 10, 70)
        local mem = string.format("Gfx Memory: %.2f MB", stats.texturememory/1024/1024)    
        gfx.print(mem, 10, 85)    
        local px, py = player:getPosition()
        gfx.print("Player: " .. math.floor(px) .. "," .. math.floor(py), 10, 100)
        gfx.print("Player angle: " .. player:getPosAngle(), 10, 115)
        gfx.print("Bullets: " .. bulletctlr:getCount(), 10, 130)
        gfx.print("Enemies: " .. enemyctlr:getCount(), 10, 145)
        gfx.print("Drops: " .. dropctlr:getCount(), 10, 160)
        gfx.print("Player Points: " .. player:getPoints(), 10, 175)
        gfx.print("Player Invincibility: " .. tostring(player:getInvincible()), 10, 190)        
        gfx.print("Player HP: " .. player:getHP() .. "/" .. player:getMaxHP(), 10, 205)
        gfx.print("Player Shield: " .. math.floor(player:getShield()) .. "/" .. player:getMaxShield(), 10, 220)
        gfx.print("Player Gun Level: " .. player:getGunLevel() .. "/" .. player:getMaxGunLevel(), 10, 235)
        gfx.print("Player Powerup: " .. player:getPowerup(), 10, 250)
    
        gfx.print("Can Land: " .. tostring(planet:canLand()), 10, 295)
        gfx.print("Resources: " .. player:getResources(), 10, 325)
        gfx.print("Time: " .. level:getDisplayTime(), 10, 340)
        gfx.print("Level: " .. level:getLevel(), 10, 355)
        gfx.print("name: " .. level:getName(), 10, 370)
        gfx.print("bossmode: " .. tostring(enemyctlr.bossmode), 10, 385)
        gfx.print("progress: " .. level:getProgress() .. "/" .. level:getMaxProgress(), 10, 400)
        gfx.print("Boss Zone - Player: " .. player:getPosAngle() + level.paoffset, 10, 415)
        gfx.print("Boss Zone - Left: " .. level.paleft, 10, 430)
        gfx.print("Boss Zone - Right: " .. level.paright, 10, 445)


    elseif screen == "mainmenu" then
        screen_mainmenu:draw()
    elseif screen == "options" then
        screen_options:draw()
    elseif screen == "controls" then
        screen_controls:draw()
    elseif screen == "quit" then
        screen_quit:draw()
    end
end

function SetupNewGame()
    -- gameover state
    gameover = false

    -- set the level
    currentlevel = 1

    -- create the player
    player = player_cls.new()    
end

function SetupNewLevel()
    -- create the game and planet
    planet = planet_cls.new()

    -- setup the level tracker
    level = level_cls.new(currentlevel)

    -- init game states
    inbase = true
    inbasefirst = true
    paused = false

    local inner, outer = planet:getRings()
    -- set position to inner + 150 mag basically
    player:setMag(inner + 150)
    -- set the player to the base
    local ba = planet:getBasePosAngle()
    player:setPosAngle(ba)
    -- reset player x, y based on set angle/mag
    player:resetPosition()
    -- Update the player -> update the initial camera position -> this is so the initial screen looks ok... 
    player:update(0)
    camera:setPosition(camera.size.vw/2, camera.size.vh + player:getMag() - (camera.size.vh/4), player:getPosAngle())
    camera:resetShake()
    -- reset this stuff
    player:setInteractive(true)
    player:setAnimation("")

    -- create the enemy controller
    enemyctlr = enemycontroller_cls.new()

    -- create the drop controller
    dropctlr = dropcontroller_cls.new()

    -- create the bullet controller
    bulletctlr = bulletcontroller_cls.new()

    -- create explosion controller
    explosionctlr = explosionctlr_cls.new()

    -- create the radar
    radar = radar_cls.new()
end

function NextLevel()
    -- increase level
    currentlevel = currentlevel + 1
    -- set it up!
    SetupNewLevel()
end