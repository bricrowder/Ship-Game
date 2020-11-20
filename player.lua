Player = {}
Player.__index = Player

function Player.new()
    -- Create the camera object
    local p = {}
    setmetatable(p, Player)
    --
    -- load general player config
    --
    -- available energy
    p.energy = config.player.energy
    -- damage taken/dealt if it collides with an enemy
    p.collisiondamage = config.player.collisiondamage
    -- explosion
    p.explosion = config.player.explosion
    -- how long player is invincible for after a hit
    p.hitinvisibilityamount = config.player.hitinvisibilityamount
    p.collinvisibilityamount = config.player.collinvisibilityamount
    -- shield point refill rate
    p.shieldrefill = config.player.shieldrefill
    -- guns: declare table
    p.guns = {}
    for i, v in ipairs(config.player.guns) do
        table.insert(p.guns, gun_cls.new(v.angle, v.radius, v.direction, 0, v.bullet, v.level, v.cooldown))
    end

    -- trails: declare table
    p.engines = {}
    -- trails: init trail data
    for i, v in ipairs(config.player.engines) do
        table.insert(p.engines, engine_cls.new(v.angle, v.radius, v.direction, v.type, 0.25, v.texture))
    end

    --
    -- initialize all the player variables
    -- 
    -- position
    p.position = {x=0, y=0}
    -- player directional angle
    p.angle = 0
    -- positional angle in the world
    p.posangle = 0
    -- direction of gun
    p.shootangle = 0
    -- mag of player from 0,0
    p.mag = 0
    -- if the player has moved at all
    p.moved = false
    -- number of points
    p.points = 0
    -- number of resources
    p.resources = 0
    -- current shield points
    p.shield = 0
    -- total shield points
    p.maxshield = 0
    -- current hit points
    p.hp = 0
    -- total HP
    p.maxhp = 0
    -- hull texture offset
    p.offset = {w=0,h=0}
    -- hull collider size
    p.size = 0
    -- where the end of the gun is
    p.gunlength = 0
    -- invincibility flag
    p.invincible = false
    -- invincibility timer
    p.invincibilitytimer = 0

    -- setup hp/shield
    p.hp = config.player.hp
    p.maxhp = p.hp
    -- self.maxshield = what is remaining
    p.maxshield = 3
    p.shield = p.maxshield

    -- setup hull texture offsets
    p.texture = config.player.texture
    local qx, qy, qw, qh = textureatlas:getQuadbyName(p.texture):getViewport()
    p.offset = {w=qw/2, h=qh/2}

    -- setup collider
    p.size = qh/2
    -- setup gun lenght
    p.gunlength = qw/2
    -- reset shooting angle
    p.shootangle = 0
    -- player speed
    p.speed = config.player.speed
    p.angularspeed = config.player.angularspeed

    -- load special data
    p.special = config.player.special
    p.currentspecialcooldown = {0,0}

    -- the animation that is being played
    p.animation = ""
    -- if the player is in interactive mode or not
    p.interactive = true

    -- animation variables
    p.bosstransition = {targetdist=0, currentdist=0, dir=0, magrate=0, magdir=0}
    p.endtransition = {targetdist=0, currentdist=0}
    p.landtransition = {targetdist=0, currentdist=0, angle=0}


    -- current player gun
    p.gunlevel = 1
    -- max gun
    p.maxgunlevel = 4

    -- current powerup
    p.powerup = 1

    return p
end

function Player:update(dt)
    -- recalc posangle and mag
    self:recalcPAM()

    -- auto update position?
    if not(self.interactive) then
        if self.animation == "bosstransition" then
            -- update the posangle
            self.posangle = self.posangle + dt * math.pi/8 * self.bosstransition.dir
            self.bosstransition.currentdist = self.bosstransition.currentdist + dt * math.pi/8
            -- update the mag
            self.mag = self.mag + dt * self.bosstransition.magrate * self.bosstransition.magdir
            -- check for end
            if self.bosstransition.currentdist >= self.bosstransition.targetdist then
                local d = self.bosstransition.currentdist - self.bosstransition.targetdist
                -- correct the posangle if neceassary
                self.posangle = self.posangle - d * self.bosstransition.dir
                -- reset the interactive flag
                self.interactive = true
            end
            -- correct to 0-6.28
            if self.posangle < 0 then
                self.posangle = math.pi*2 + self.posangle
            elseif self.posangle >= math.pi*2 then
                self.posangle = self.posangle - math.pi*2
            end
            -- update shooting angle -- needs to be lerped!
            self.angle = self.posangle

            -- update position
            self:resetPosition()
        elseif self.animation == "endtransition" then
            -- need to add extra lerp for player angle...  

            -- update the mag
            self.mag = self.mag + dt * 200
            -- update the counter
            self.endtransition.currentdist = self.endtransition.currentdist + dt * 200
            -- check if we are done... send to next level!
            if self.endtransition.currentdist >= self.endtransition.targetdist then
                self.interactive = true
                self.animation = ""
                NextLevel()
            end
            -- update position
            self:resetPosition()
        elseif self.animation == "landtransition" then
            self.position.x = self.position.x + math.cos(self.landtransition.angle) * dt * 100
            self.position.y = self.position.y + math.sin(self.landtransition.angle) * dt * 100
            self:moveGunsandEngines()    
            self.posangle = math.atan2(self.position.y, self.position.x)
            self.mag = math.sqrt(self.position.x*self.position.x + self.position.y*self.position.y)
            local inner, outer, p = planet:getRings()
            if self.mag <= inner + 150 then     -- 150 is used in a couple other spots... update this with the others when you configify
                inbase = true
                self.animation = ""
                self.interactive = true
            end
        end
    end

    -- update guns
    for i, v in ipairs(self.guns) do
        v:update(dt)
    end

    -- refill shield points
    if self.shield < self.maxshield then
        self.shield = self.shield + self.shieldrefill * dt
        if self.shield > self.maxshield then
            self.shield = self.maxshield
        end
    end

    -- update invincibity
    if self.invincible then
        self.invincibilitytimer = self.invincibilitytimer - dt
        if self.invincibilitytimer <= 0 then
            self.invincibilitytimer = 0
            self.invincible = false
        end
    end
end

function Player:draw()
    -- draw the engine trail, currently it is always drawn opposite angle to direction, scale x by speed!
    for i, v in ipairs(self.engines) do
        v:draw()
    end

    -- change colour if you are invincible... temp
    local r,g,b,a = gfx.getColor()
    if self.invincible then
        gfx.setColor(255,128,128,255)
    end
    
    -- draw texture
    gfx.draw(textureatlas:getImage(), textureatlas:getQuadbyName(self.texture), self.position.x, self.position.y, self.angle, 1, self.flip, self.offset.w, self.offset.h)

    -- reset color
    gfx.setColor(r,g,b,a)    

end

function Player:hit(a, collide)
    -- this is where the player get hit!
    if not(self.invincible) then
        -- if they have a shield
        if math.floor(self.shield) > 0 then
            self.shield = self.shield - a
        else
            -- no shield - take hit points away
            self.hp = self.hp - a
            if self.hp <= 0 then
                self:death()
            end
            -- only make inv. if your HP is being reduced (not shield)
            if not(collide) then
                self:setInvincible(self.hitinvisibilityamount)
            end                
        end
        -- always make inv. if you are colliding with enemy... to avoid a million hits from happening...
        if collide then
            self:setInvincible(self.collinvisibilityamount)
        end
        camera:setShake(0.25,5)    

        -- decrease weapon level
        if self.gunlevel > 1 then
            self.gunlevel = self.gunlevel - 1
        else
            -- decrease max gun level
            if self.maxgunlevel > 1 then
                self.maxgunlevel = self.maxgunlevel - 1
            end
        end
    end
end

function Player:death()
    -- this is temp/debug stuff
    -- other cleanup?
    -- gameover = true
    self.hp = 3
    local x, y = self:getPosition()
    explosionctlr:add(explosion_cls.new(self.explosion, x, y))

end

function Player:shoot(w)
    -- are we shooting the weapon or special?
    if w == 0 then
        -- create a bullet for each gun
        for i, v in ipairs(self.guns) do
            if v.level <= self.gunlevel then
                if v:getCooldown() == 0 then
                    -- angle is the player angle + general gun angle direction + individual gun angle
                    bulletctlr:add(bullet_cls.new(v.bullet, v.x, v.y, self.angle + v.direction, "player"))
                    v:resetCooldown()
                end
            end
        end                
    else
        if self.currentspecialcooldown[w] == 0 then
            -- we are shooting a special!
            if self.special[w].name == "Invincibility" then
                self.invincible = true
                self.invincibilitytimer = self.special[w].duration
            elseif self.special[w].name == "Bomb" then
                -- just flag the enemy controller to destroy all enemies
                enemyctlr:killAll()
                -- shake the camera for effect
                camera:setShake(0.25,5)     
            elseif self.special[w].name == "Boost" then
                -- set the player speed to boost!!
                -- uses shield power!
                -- shake the camera for effect
                camera:setShake(0.25,5)                                            
            end
            -- reset cooldown
            self.currentspecialcooldown[w] = self.special[w].cooldown       
        end 
    end
end

function Player:addGunLevel(g)
    -- adds levels to guns up to the max
    self.gunlevel = self.gunlevel + g
    if self.gunlevel > self.maxgunlevel then
        self.gunlevel = self.maxgunlevel
    end
end

function Player:addMaxGunLevel(g)
    -- adds levels to guns up to the max
    self.maxgunlevel = self.maxgunlevel + g
    if self.maxgunlevel > 10 then
        self.maxgunlevel = 10
    end
end

function Player:changePowerup(p)
    self.powerup = self.powerup + 1
    if self.powerup > #self.special then
        self.powerup = 1
    elseif self.powerup < 1 then
        self.powerup = #self.special
    end
end

function Player:getPowerup()
    return self.powerup
end

-- sets the player to invincible for t seconds
function Player:setInvincible(t)
    self.invincible = true
    self.invincibilitytimer = t
end

function Player:getInvincible()
    return self.invincible
end

function Player:getPosition()
    return self.position.x, self.position.y
end

function Player:setMag(m)
    -- direction set the mag
    self.mag = m
end

function Player:resetPosition()
    self.position.x = math.cos(self.posangle) * self.mag
    self.position.y = math.sin(self.posangle) * self.mag
end

function Player:setPosAngle(p)
    -- directly modify the posangle
    self.posangle = p
end

function Player:changeAngle(s)
    -- increment the shooting angle
    self.angle = self.angle + s
    if self.angle < 0 then
        self.angle = self.angle + math.pi*2
    elseif self.angle > math.pi*2 then
        self.angle = math.pi*2 - self.angle
    end
    -- update guns/engine pos
    self:moveGunsandEngines()    
end

function Player:recalcPAM()
    -- update pos angle
    self.posangle = math.atan2(self.position.y, self.position.x)
    -- correct to 0-6.28
    if self.posangle < 0 then
        self.posangle = math.pi*2 + self.posangle
    elseif self.posangle >= math.pi*2 then
        self.posangle = self.posangle - math.pi*2
    end   
    -- update mag 
    self.mag = math.sqrt(self.position.x * self.position.x + self.position.y * self.position.y)
end

function Player:addPosition(m, angle, gp)
    -- update the position
    local x, y = 0, 0
    if not(gp) then
        -- with mouse/keyboard, you want to add your directional angle and shooting angle...
        x = self.position.x + math.cos(self.angle+angle) * m * self.speed
        y = self.position.y + math.sin(self.angle+angle) * m * self.speed
    else
        -- gamepade, just direcitonal angle
        x = self.position.x + math.cos(angle) * m * self.speed
        y = self.position.y + math.sin(angle) * m * self.speed
    end

    -- clamp to planet or bosszone depending on mode
    if enemyctlr.bossmode then
        self:recalcPAM()
        self.position.x, self.position.y = level:ClampToBossZone(x, y)
    else
        local inner, outer, p = planet:getRings()
        self.position.x, self.position.y = ClampToPlanet(x, y, p, outer)
    end

    -- update guns/engine pos
    self:moveGunsandEngines()
end

function Player:moveGunsandEngines()
    -- set gun positions
    for i, v in ipairs(self.guns) do
        v:updatePosition(self.angle, self.position.x, self.position.y)
    end

    -- set engine positions
    for i, v in ipairs(self.engines) do
        v:updatePosition(self.angle, self.position.x, self.position.y)
    end
end

function Player:setAngle(a)
    self.angle = a
    -- update guns/engine pos
    self:moveGunsandEngines()    
end

-- returns angle of x,y and angle of x,y at radius
function Player:getAngle()    
    return self.angle
end

function Player:getPosAngle()
    return self.posangle
end

function Player:getMag()
    return self.mag
end

-- gets the two angles at the diameter of the player collider/size and returns them
function Player:getAnglesatDiameter()
    -- get positional angle
    local a = math.atan2(self.position.y, self.position.x)
    -- rotate pi/2
    local posa = a + math.pi/2
    local nega = a - math.pi/2
    -- calculate positions at the radius of collider
    local px = math.cos(posa) * self.size + self.position.x
    local py = math.sin(posa) * self.size + self.position.y
    local nx = math.cos(nega) * self.size + self.position.x
    local ny = math.sin(nega) * self.size + self.position.y
    
    -- get positional angles of each
    local pa = math.atan2(py, px)
    local na = math.atan2(ny, nx)

    -- normalize to 0-6.28
    if pa < 0 then pa = pa + math.pi*2 end
    if na < 0 then na = na + math.pi*2 end

    -- return the two angles
    return pa, na
end

function Player:getSize()
    return self.size
end

function Player:addResources(c)
    self.resources = self.resources + c
end

function Player:getResources()
    return self.resources
end

function Player:addPoints(p)
    self.points = self.points + p
end

function Player:getPoints()
    return self.points
end

function Player:getCollisionDamage()
    return self.collisiondamage
end

function Player:getHP()
    return self.hp
end

function Player:setHP(h)
    self.hp = h
end

function Player:getMaxHP()
    return self.maxhp
end

function Player:getShield()
    return self.shield
end

function Player:getMaxShield()
    return self.maxshield
end

function Player:resetSpeed()
    for i, v in ipairs(self.engines) do
        v.trailscale = 0.25
    end    
end

function Player:setSpeed(t, s)
    for i, v in ipairs(self.engines) do
        if v.type == t then
            v.trailscale = s
        end
    end
end

function Player:setAnimation(a)
    self.animation = a
end

function Player:isInteractive()
    return self.interactive
end

function Player:setInteractive(i)
    self.interactive = i
end

function Player:getAnimation()
    return self.animation
end

function Player:setLandingInfo()
    -- get the posangle of the base... 
    local ba = planet:getBasePosAngle()
    local inner, outer, p = planet:getRings()
    local bm = inner + 150  -- this is also done in main... remember to use the same config var for both

    -- set the target x, y
    local lx = math.cos(ba) * bm
    local ly = math.sin(ba) * bm

    -- get the angle from player to base
    local angle = math.atan2(ly-self.position.y, lx-self.position.x)
    -- get the distance (player will always be above)
    local dx = self.position.x-lx
    local dy = self.position.y-ly
    local dist = math.sqrt(dx*dx + dy*dy)

    self.landtransition.targetdist = dist
    self.landtransition.currentdist = 0
    self.landtransition.angle = angle
end

function Player:setEndLevelInfo()
    -- get distance between player mag and exit
    local inner, outer, p = planet:getRings()
    self.endtransition.targetdist = outer - self.mag + config.camera.VirtualResolutionHeight/2
    self.endtransition.currentdist = 0
end

function Player:setBossTransitionInfo(pa)
    -- get distance between angles
    local d = math.abs(self.posangle - pa)
    local dorg = d
    -- get less of the two        
    if d > math.pi then
        d = math.pi*2 - d
    end
    -- determine the direction of travel
    local dir = 1
    if self.posangle < pa and dorg > math.pi then
        dir = -1
    elseif self.posangle > pa and dorg <= math.pi then
        dir = -1
    end

    -- how long will it take to travel to target?
    local timeinseconds = d / (math.pi/8)
    -- target mag
    local inner, outer, p = planet:getRings()
    local targetmag = outer - 1000
    -- difference betwen mags
    local dmag = math.abs(targetmag - self.mag)
    -- direction of travel
    local magdir = 1
    if self.mag > targetmag then
        magdir = -1
    end
    -- rate of update
    local magrate = dmag / timeinseconds

    self.bosstransition.targetdist = d
    self.bosstransition.currentdist = 0
    self.bosstransition.dir = dir
    self.bosstransition.magrate = magrate
    self.bosstransition.magdir = magdir
end

function Player:getGunLevel()
    return self.gunlevel
end

function Player:getMaxGunLevel()
    return self.maxgunlevel
end

return Player